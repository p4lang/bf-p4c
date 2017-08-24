/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include "tofino/parde/checksum.h"

#include <boost/optional.hpp>
#include <map>

#include "ir/ir.h"
#include "lib/error.h"

namespace {

using ChecksumSources = IR::Vector<IR::Expression>;
using ChecksumSourceMap = std::map<cstring, const ChecksumSources*>;

void showComputeChecksumUsage() {
    ::warning("Computed checksum controls may include only code with this form:");
    ::warning("  if (header.isValid()) {");
    ::warning("    header.destField = checksumExternInstance.get({");
    ::warning("       header.sourceField1,");
    ::warning("       header.sourceField2");
    ::warning("    });");
    ::warning("  }");
}

/**
 * Analyze an assignment statement within a computed checksum control and try to
 * extract the destination field and the source field list.
 *
 * @param assignment  The assignment statement to analyze.
 * @param sourceHeader  The source header for the checksum, if we know it
 *                      already. (We'll know it if the assignment statement is
 *                      located within an `if (header.isValid())` check. Null if
 *                      we don't know the source header; in that case, we'll
 *                      infer it from the destination field.
 * @return a ChecksumSourceMap entry containing the checksum destination field
 * name and the source fields which will be used to compute the checksum, or
 * boost::none if the checksum code was invalid.
 */
boost::optional<ChecksumSourceMap::value_type>
analyzeComputedChecksumStatement(const IR::AssignmentStatement* assignment,
                                 const IR::HeaderRef* sourceHeader = nullptr) {
    auto* destField = assignment->left->to<IR::Member>();
    if (!destField || !destField->expr->is<IR::HeaderRef>()) {
        ::warning("Expected an assignment to a header field: %1%", assignment);
        return boost::none;
    }

    // The source header for this computed checksum may already be determined if
    // this assignment is inside an `if (header.isValid())` check; we require
    // that that check be consistent with the destination field. If this is a
    // bare assignment, not contained in an `if`, then we'll obtain the source
    // header from the destination field.
    if (!sourceHeader)
        sourceHeader = destField->expr->to<IR::HeaderRef>();
    if (!sourceHeader) {
        ::warning("Expected destination of checksum to be a header field: %1%",
                  destField);
        return boost::none;
    }

    if (sourceHeader && destField->expr->toString() != sourceHeader->toString()) {
        ::warning("Expected field of checksummed header %1%: %2%",
                  sourceHeader, destField);
        return boost::none;
    }
    if (destField->type->width_bits() != 16) {
        ::warning("Expected computed checksum output to be stored in a "
                  "16-bit field: %1%", destField);
        return boost::none;
    }
    LOG1("Would write computed checksum to field: " << destField);

    // The source of the assignment must be the result of a call to
    // Checksum16's `get()` method.
    // XXX(seth): There's currently a bug in MethodInstance that makes it
    // unsafe to use in code that is called from extract_maupipe. Until
    // that's tracked down, we need to do something hacky here. =(
    const IR::ListExpression* sourceList = nullptr;
    {
        auto* call = assignment->right->to<IR::MethodCallExpression>();
        if (!call || !call->method || !call->method->is<IR::Member>()) {
            ::warning("Expected Checksum16.get(): %1%", assignment->right);
            return boost::none;
        }
        auto* memberExpr = call->method->to<IR::Member>();
        if (memberExpr->member != "get") {
            ::warning("Expected Checksum16.get(): %1%", assignment->right);
            return boost::none;
        }
        if (!call->arguments || call->arguments->size() != 1) {
            ::warning("Expected a list of fields: %1%", call);
            return boost::none;
        }
        sourceList = (*call->arguments)[0]->to<IR::ListExpression>();
        if (!sourceList) {
            ::warning("Expected list of fields: %1%", call);
            return boost::none;
        }
    }

    // The get() method's argument must be a list of fields which are part
    // of the same source header as the destination field. These are the
    // fields that will be combined to produce the checksum.
    auto* sources = new ChecksumSources;
    for (auto* source : sourceList->components) {
        LOG1("Checksum would include field: " << source);
        auto* member = source->to<IR::Member>();
        if (!member || !member->expr->is<IR::HeaderRef>()) {
            ::warning("Expected field: %1%", source);
            return boost::none;
        }
        auto* headerRef = member->expr->to<IR::HeaderRef>();
        if (headerRef->toString() != sourceHeader->toString()) {
            ::warning("Expected field of checksummed header %1%: %2%",
                      sourceHeader, member);
            return boost::none;
        }
        sources->push_back(member);
    }

    if (sources->empty()) {
        ::warning("Expected at least one field: %1%", sources);
        return boost::none;
    }

    LOG1("Validated computed checksum for field: " << destField);
    return ChecksumSourceMap::value_type(destField->toString(), sources);
}

/**
 * Analyze an `if` statement within a computed checksum control and try to
 * extract the destination field and the source field list.
 *
 * @param ifStatement  The `if` statement to analyze.
 * @return a ChecksumSourceMap entry containing the checksum destination field
 * name and the source fields which will be used to compute the checksum, or
 * boost::none if the checksum code was invalid.
 */
boost::optional<ChecksumSourceMap::value_type>
analyzeComputedChecksumStatement(const IR::IfStatement* ifStatement) {
    const IR::HeaderRef* sourceHeader = nullptr;
    {
        auto* prim = ifStatement->condition->to<IR::Primitive>();
        if (!prim || prim->name != "isValid") {
            ::warning("Expected isValid() call: %1%", ifStatement->condition);
            return boost::none;
        }
        if (!prim->operands[0]->is<IR::HeaderRef>()) {
            ::warning("Expected isValid() operand to be a header: %1%",
                      prim->operands[0]);
            return boost::none;
        }
        sourceHeader = prim->operands[0]->to<IR::HeaderRef>();
    }
    LOG1("Considering computed checksum for header: " << sourceHeader);

    // The body of the `if` must assign the result to a field in the source
    // header.
    if (!ifStatement->ifTrue || ifStatement->ifFalse) {
        ::warning("Expected an `if` with no `else`: %1%", ifStatement);
        return boost::none;
    }
    auto* assignment = ifStatement->ifTrue->to<IR::AssignmentStatement>();
    if (!assignment) {
        ::warning("Expected a single assignment statement: %1%", assignment);
        return boost::none;
    }

    // At this point we've validated that the `if` statement is of the correct
    // form. The assignment statement contains all of the information needed to
    // generate computed checksum code, so at this point the analysis behaves
    // just as if we had a bare assignment with no enclosing `if`, except that
    // we'll enforce that the header the `if` is checking the validity of is the
    // same as the header referenced in the assignment statement.
    return analyzeComputedChecksumStatement(assignment, sourceHeader);
}

/**
 * Analyze the provided computed checksum control and determine the set of
 * checksums to be computed.
 *
 * @param control  A computed checksum control, patterned after v1model's
 *                 ComputedChecksum.
 * @return the checksums, represented as a map from the destination field of the
 * checksum to the list of source fields that the checksum is computed from.
 */
ChecksumSourceMap findChecksums(const IR::P4Control* control) {
    CHECK_NULL(control);
    ChecksumSourceMap checksums;

    // The code we allow in a computed checksum control is *very* constrained,
    // so it may be nonobvious to the user how to write their code correctly.
    // Record the existing diagnostic count so that if any warnings or errors
    // are reported in the body of this function, we can print a usage message
    // at the end.
    const auto existingDiagnostics = ::ErrorReporter::instance.getDiagnosticCount();

    for (auto* statement : control->body->components) {
        boost::optional<ChecksumSourceMap::value_type> checksum;

        // It only makes sense to compute a checksum against a valid header, so
        // ideally the program will include a check of the form `if
        // (header.isValid())`. We also allow a bare assignment without the
        // check. The effect at runtime is the same, since the destination field
        // of the checksum must be part of the header that contains the
        // checksummed fields and hence is controlled by the same POV bit.
        if (auto* ifStatement = statement->to<IR::IfStatement>()) {
            auto checksum = analyzeComputedChecksumStatement(ifStatement);
            if (checksum) checksums.insert(*checksum);
            continue;
        }
        if (auto* assignment = statement->to<IR::AssignmentStatement>()) {
            auto checksum = analyzeComputedChecksumStatement(assignment);
            if (checksum) checksums.insert(*checksum);
            continue;
        }
        ::warning("Unexpected statement: %1%", statement);
    }

    if (::ErrorReporter::instance.getDiagnosticCount() > existingDiagnostics) {
        ::warning("Encountered invalid code in computed checksum control: %1%",
                  control);
        showComputeChecksumUsage();
    }

    return checksums;
}

/// Substitute computed checksums into the deparser code by replacing Emits for
/// the destination field with EmitChecksums.
struct SubstituteComputeChecksums : public Transform {
    explicit SubstituteComputeChecksums(const ChecksumSourceMap& checksums)
        : checksums(checksums) { }

 private:
    IR::Tofino::DeparserPrimitive* preorder(IR::Tofino::Emit* emit) override {
        prune();
        if (!emit->source->is<IR::Member>()) return emit;
        auto* source = emit->source->to<IR::Member>();
        if (checksums.find(source->toString()) == checksums.end()) return emit;

        // The source field of this Emit will get its value from a computed
        // checksum. Replace it with an EmitChecksum that computes that checksum
        // and writes it to the output packet in a single step.
        LOG1("Substituting computed checksum for emitted value: " << emit);
        auto* sourceFields = checksums.at(source->toString());
        auto* emitChecksum =
          new IR::Tofino::EmitChecksum(*sourceFields, emit->povBit);

        return emitChecksum;
    }

    const ChecksumSourceMap& checksums;
};

}  // namespace

namespace Tofino {

IR::Tofino::Pipe*
extractComputeChecksum(const IR::P4Control* computeChecksumControl,
                       IR::Tofino::Pipe* pipe) {
    CHECK_NULL(pipe);

    if (!computeChecksumControl) return pipe;

    auto checksums = findChecksums(computeChecksumControl);
    if (checksums.empty()) return pipe;

    SubstituteComputeChecksums substituteChecksums(checksums);
    for (auto gress : { INGRESS, EGRESS }) {
        auto* substituted = pipe->thread[gress].deparser->apply(substituteChecksums);
        pipe->thread[gress].deparser = substituted;
    }

    return pipe;
}

}  // namespace Tofino
