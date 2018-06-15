#include "bf-p4c/parde/checksum.h"

#include <boost/optional.hpp>
#include <map>

#include "ir/ir.h"
#include "lib/error.h"

namespace {

using ChecksumSources = IR::Vector<IR::BFN::FieldLVal>;
using ChecksumSourceMap = std::map<cstring, const ChecksumSources*>;
using ParserStateChecksumMap = std::map<const IR::ParserState*,
    std::vector<const IR::MethodCallExpression*>>;

static bool checksumUpdateSanityCheck(const IR::AssignmentStatement* assignment) {
    auto destField = assignment->left->to<IR::Member>();
    auto methodCall = assignment->right->to<IR::MethodCallExpression>();
    if (!methodCall || !methodCall->method)
        return false;

    auto member = methodCall->method->to<IR::Member>();
    if (!member || member->member != "update")
        return false;

    if (!destField || !destField->expr->is<IR::HeaderRef>()) {
        ::error("Destination of checksum calculation must be a header field: %1%",
                destField);
        return false;
    }

    if (destField->type->width_bits() != 16) {
        ::error("Output of checksum calculation can only be stored in a 16-bit field: %1%",
                destField);
        return false;
    }
    LOG2("Would write computed checksum to field: " << destField);

    const IR::ListExpression* sourceList =
        (*methodCall->arguments)[0]->expression->to<IR::ListExpression>();

    if (!sourceList || sourceList->components.empty()) {
        ::error("Invalid list of fields for checksum calculation: %1%", methodCall);
            return false;
    }

    for (auto* source : sourceList->components) {
        LOG2("Checksum would include field: " << source);
        if (auto* member = source->to<IR::Member>()) {
            if (!member->expr->is<IR::HeaderRef>()) {
                ::error("Invalid field in the checksum calculation field list: %1%", source);
                return false;
            }
        } else if (source->is<IR::Constant>()) {
            // TODO can constant be any bit width? signed?
        }
    }

    if (sourceList->components.empty()) {
        ::error("Expected at least on field in the list for checksum calculation: %1%",
                methodCall);
        return false;
    }

    return true;
}

/**
 * Analyze an assignment statement within a deparser control and try to
 * extract the destination field and the source field list.
 *
 * @param assignment    The assignment statement to analyze.
 * @return a ChecksumSourceMap entry containing the checksum destination field
 * name and the source fields which will be used to compute the checksum, or
 * boost::none if the checksum code was invalid.
 */
boost::optional<ChecksumSourceMap::value_type>
analyzeUpdateChecksumStatement(const IR::AssignmentStatement* assignment) {
    if (!checksumUpdateSanityCheck(assignment))
        return boost::none;

    auto destField = assignment->left->to<IR::Member>();
    auto methodCall = assignment->right->to<IR::MethodCallExpression>();

    const IR::ListExpression* sourceList =
        (*methodCall->arguments)[0]->expression->to<IR::ListExpression>();

    auto* sources = new ChecksumSources;
    for (auto* source : sourceList->components) {
        if (auto* member = source->to<IR::Member>()) {
            LOG2("Checksum would include field: " << source);
            sources->push_back(new IR::BFN::FieldLVal(member));
        } else if (auto* constant = source->to<IR::Constant>()) {
            if (constant->asInt() != 0) {
                ::error("Non-zero constant entry in checksum calculation"
                        " not implemented yet: %1%", source);
            }
        }
    }

    LOG2("Validated computed checksum for field: " << destField);
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
analyzeUpdateChecksumStatement(const IR::IfStatement* ifStatement) {
    // TODO(msharif): add support for conditional checksum update and validate
    // the condition here.
    if (!ifStatement->ifTrue || ifStatement->ifFalse) {
        return boost::none;
    }

    auto* assignment = ifStatement->ifTrue->to<IR::AssignmentStatement>();
    if (!assignment)
        return boost::none;

    ::warning("Conditional checksum update is not yet supported and the condition "
              "will be ignored");

    // At this point we've validated that the `if` statement is of the correct
    // form. The assignment statement contains all of the information needed to
    // generate computed checksum code, so at this point the analysis behaves
    // just as if we had a bare assignment with no enclosing `if`, except that
    // we'll enforce that the header the `if` is checking the validity of is the
    // same as the header referenced in the assignment statement.
    return analyzeUpdateChecksumStatement(assignment);
}

/**
 * Analyze the provided tofino.p4 deparser and determine the set of checksums
 * to be computed.
 *
 * @param control A deparser control block.
 * @return the checksums, represented as a map from the destination field of the
 * checksum to the list of source fields that the checksum is computed from.
 *
 */
ChecksumSourceMap findUpdateChecksumsNative(const IR::IndexedVector<IR::StatOrDecl>& stmts) {
    ChecksumSourceMap checksums;

    for (auto *statement : stmts) {
        // It only makes sense to compute a checksum against a valid header, so
        // ideally the program will include a check of the form `if
        // (header.isValid())`. We also allow a bare assignment without the
        // check. The effect at runtime is the same, since the destination field
        // of the checksum must be part of the header that contains the
        // checksummed fields and hence is controlled by the same POV bit.
        if (auto* ifStatement = statement->to<IR::IfStatement>()) {
            if (auto update = analyzeUpdateChecksumStatement(ifStatement))
                checksums.insert(*update);
        } else if (auto *assignment =  statement->to<IR::AssignmentStatement>()) {
            if (auto update = analyzeUpdateChecksumStatement(assignment))
                checksums.insert(*update);
        }
    }

    return checksums;
}

/// Substitute computed checksums into the deparser code by replacing Emits for
/// the destination field with EmitChecksums.
struct SubstituteUpdateChecksums : public Transform {
    explicit SubstituteUpdateChecksums(const ChecksumSourceMap& checksums)
        : checksums(checksums) { }

 private:
    IR::BFN::DeparserPrimitive* preorder(IR::BFN::Emit* emit) override {
        if (!emit->source->field->is<IR::Member>()) return emit;
        auto* source = emit->source->field->to<IR::Member>();
        if (checksums.find(source->toString()) == checksums.end()) return emit;

        // The source field of this Emit will get its value from a computed
        // checksum. Replace it with an EmitChecksum that computes that checksum
        // and writes it to the output packet in a single step.
        LOG2("Substituting update checksum for emitted value: " << emit);
        auto* sourceFields = checksums.at(source->toString());
        auto* emitChecksum =
          new IR::BFN::EmitChecksum(*sourceFields, new IR::BFN::ExternLVal(source), emit->povBit);

        return emitChecksum;
    }

    const ChecksumSourceMap& checksums;
};

struct SubstituteExternLVal : public Transform {
    explicit SubstituteExternLVal(const ChecksumSourceMap& checksums)
        : checksums(checksums) { }

    IR::BFN::ParserPrimitive* preorder(IR::BFN::Extract* extract) override {
        prune();
        if (checksums.find(extract->dest->toString()) != checksums.end()) {
            if (auto lval = extract->dest->to<IR::BFN::FieldLVal>()) {
                return new IR::BFN::Extract(
                    new IR::BFN::ExternLVal(lval->field),
                    extract->source);
            }
        }

        return extract;
    }

    const ChecksumSourceMap& checksums;
};

}  // namespace

namespace BFN {

/// This function extracts checksum from the translated tofino.p4 checksum extern.
/// Error checking should be done during the translation, not in this function.
IR::BFN::Pipe*
extractChecksumFromDeparser(const IR::BFN::TranslatedP4Deparser* deparser, IR::BFN::Pipe* pipe) {
    CHECK_NULL(pipe);
    if (!deparser) return pipe;

    auto checksums = findUpdateChecksumsNative(deparser->body->components);
    if (checksums.empty()) return pipe;

    SubstituteUpdateChecksums substituteChecksums(checksums);
    SubstituteExternLVal substituteExternLVal(checksums);

    auto gress = deparser->thread;
    pipe->thread[gress].deparser = pipe->thread[gress].deparser->apply(substituteChecksums);
    pipe->thread[gress].parser = pipe->thread[gress].parser->apply(substituteExternLVal);

    return pipe;
}

}  // namespace BFN
