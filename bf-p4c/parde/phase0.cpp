#include "bf-p4c/parde/phase0.h"

#include <algorithm>
#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/device.h"
#include "bf-p4c/parde/field_packing.h"
#include "frontends/p4/coreLibrary.h"
#include "frontends/p4/fromv1.0/v1model.h"
#include "ir/ir.h"
#include "lib/cstring.h"
#include "lib/indent.h"

std::ostream& operator<<(std::ostream& out, const BFN::Phase0Info* info) {
    if (info == nullptr) return out;
    CHECK_NULL(info->packing);

    // Boilerplate. This is mostly just for the convenience of the assembler and
    // the driver; the only thing that varies is the table name.
    // XXX(seth): We can probably pare this down quite a bit, but for now this
    // reproduces what Glass produces.
    indent_t indent(1);
    out <<   indent << "phase0_match " << info->tableName << ":" << std::endl;
    out << ++indent << "p4:" << std::endl;
    out << ++indent << "name: " << info->tableName << std::endl;
    out <<   indent << "size: 288" << std::endl;
    out <<   indent << "preferred_match_type: exact" << std::endl;
    out <<   indent << "match_type: exact" << std::endl;
    out << --indent << "size: 288" << std::endl;

    // Write out the p4 parameter, which (for phase0) is always
    // For P4-14 = 'ig_intr_md.ingress_port'
    // For P4-16 = '$PORT' - consistent with bf-rt.json
    out <<   indent << "p4_param_order:" << std::endl;
    if (info->keyName.isNullOrEmpty())
        out << ++indent << "ig_intr_md.ingress_port:";
    else
        out << ++indent << "$PORT:";
    out << "{ type: exact, size: 9 }" << std::endl;

    // Write out the field packing format. We have to convert into the LSB-first
    // representation that the assembler uses.
    const nw_bitrange phase0Range =
      StartLen(0, Device::pardeSpec().bitPhase0Size());
    BUG_CHECK(int(info->packing->totalWidth) == phase0Range.size(),
              "Expected phase 0 field packing to allocate exactly %1% bits",
              phase0Range.size());
    bool wroteAtLeastOneField = false;
    int posBits = 0;
    out << --indent << "format: {";
    for (auto& field : *info->packing) {
        BUG_CHECK(field.width > 0, "Empty phase 0 field?");
        const nw_bitrange fieldRange(StartLen(posBits, field.width));
        BUG_CHECK(phase0Range.contains(fieldRange),
                  "Phase 0 allocation %1% overflows the phase 0 region %2% for "
                  "field %3%", fieldRange, phase0Range,
                  field.isPadding() ? "(padding)" : field.source);

        posBits += field.width;
        if (field.isPadding()) continue;
        if (wroteAtLeastOneField) out << ", ";
        wroteAtLeastOneField = true;

        const le_bitrange leFieldRange =
          fieldRange.toOrder<Endian::Little>(phase0Range.size());
        out << field.source << ": " << leFieldRange.lo << ".." << leFieldRange.hi;
    }
    out << "}" << std::endl;

    // Write out the constant value. This value is used by the driver to
    // initialize the phase 0 data before the bits assigned to fields are given
    // their user-provided values. Having this available gives us a little more
    // flexibility when packing phase 0 fields.
    // XXX(seth): The above isn't actually implemented, but it's planned. Right
    // now, the driver acts as if this is always set to zero.
    out << indent << "constant_value: 0" << std::endl;

    // Write out the actions block with the param order
    // XXX(amresh): This is a fake action block output in assembly to allow
    // generating context json as expected by driver. No instructions are
    // generated as,
    // 1. phase0 does not do any actual ALU operations
    // 2. This info is not needed in the context json (for now).
    // Glass does generate primitives (for model logging) which requires
    // setting ingress metadata fields as ALU ops but it is unclear if model
    // uses this info.
    out << indent << "actions:" << std::endl;
    out << ++indent << canon_name(info->actionName) << ":" << std::endl;
    // Phase0 action handle must be unique from all other action handles. While
    // this is never used, driver expects unique handles as phase0 is
    // represented as a table construct in context.json. We assign the starting
    // handle to phase0, all other action handles start at (0x20 << 24) + 1
    out <<   indent << "- handle: 0x" << hex(0x20 << 24) << std::endl;
    out <<   indent << "- p4_param_order: { ";
    wroteAtLeastOneField = false;
    for (auto& field : *info->packing) {
        if (field.isPadding()) continue;
        if (wroteAtLeastOneField) out << ", ";
        out << field.source << ": " << field.width;
        wroteAtLeastOneField = true;
    }
    out << " } " << std::endl;
    return out;
}

namespace BFN {

namespace {

/// Search for an @phase0 annotation and create a Phase0Info object if a valid
/// one is found.
struct FindPhase0Annotation : public Inspector {
    explicit FindPhase0Annotation(P4::ReferenceMap* refMap) : refMap(refMap) { }

    /// If non-null, the metadata from the program's @phase0 annotation which is
    /// needed to generate phase 0 assembly.
    Phase0Info* phase0Info = nullptr;

    bool preorder(const IR::P4Control* control) override {
        auto* annotation = control->type->annotations->getSingle("phase0");
        if (!annotation) {
            LOG4("No @phase0 annotation found on control " << control->name);
            return false;
        }

        auto phase0_warn = false;
        auto num_annots = annotation->expr.size();
        if (num_annots == 3 || num_annots == 4) {
            if (!annotation->expr[0]->is<IR::StringLiteral>() ||
                !annotation->expr[1]->is<IR::StringLiteral>() ||
                !annotation->expr[2]->is<IR::TypeNameExpression>())
                phase0_warn = true;
            // From TNA we get an additional (compiler generated) annotation for
            // keyName which is used in bf-rt.json.
            if (num_annots == 4 && !annotation->expr[3]->is<IR::StringLiteral>())
                phase0_warn = true;
        }
        if (phase0_warn) {
            DIAGNOSE_WARN("phase0_annotation", "Invalid @phase0 annotation: %1%",
                          annotation);
            showUsage();
            return false;
        }

        cstring tableName = annotation->expr[0]->to<IR::StringLiteral>()->value;
        cstring actionName = annotation->expr[1]->to<IR::StringLiteral>()->value;

        auto* typeName = annotation->expr[2]->to<IR::TypeNameExpression>()->typeName;
        auto* typeDecl = refMap->getDeclaration(typeName->path);
        if (!typeDecl) {
            DIAGNOSE_WARN("phase0_annotation", "No declaration for phase 0 type: %1%",
                          typeName);
            showUsage();
            return false;
        }
        auto* type = typeDecl->to<IR::Type_Header>();
        if (!type) {
            DIAGNOSE_WARN("phase0_annotation", "Phase 0 type must be a header: %1%",
                          typeDecl);
            showUsage();
            return false;
        }

        cstring keyName = "";
        if (num_annots == 4)
            keyName = annotation->expr[3]->to<IR::StringLiteral>()->value;

        // The phase 0 type defines the format of the phase 0 data (the static
        // per-port metadata, in other words). The driver exposes a table-like
        // API to the control plane, with the phase 0 data for each port exposed
        // as a table entry. The phase 0 type describes to the driver how the
        // fields in these table entries should be formatted so the parser can
        // interpret them correctly. It doesn't need to actually be used in the
        // program, although we do generate code that uses it when translating
        // v1model code to TNA.
        LOG4("Phase 0 fields for control " << control->name << ":");
        auto* packing = new FieldPacking;
        for (auto* field : type->fields) {
            auto isPadding = bool(field->annotations->getSingle("hidden"));

            LOG4("  - " << field->name << " (" << field->type->width_bits()
                        << "b)" << (isPadding ? " (padding)" : ""));

            if (isPadding)
                packing->appendPadding(field->type->width_bits());
            else
                packing->appendField(new IR::StringLiteral(field->name),
                                     field->name,
                                     field->type->width_bits());
        }

        if (packing->totalWidth != Device::pardeSpec().bitPhase0Size()) {
            DIAGNOSE_WARN("phase0_annotation",
                          "Phase 0 type is %1%b, but its size must be exactly "
                          "%2%b on %3%", packing->totalWidth,
                          Device::pardeSpec().bitPhase0Size(),
                          Device::name());
            return false;
        }

        phase0Info = new Phase0Info{tableName, actionName, keyName, packing};
        LOG3("Setting phase0 info to { " << tableName << ", " << actionName << ", "
                << keyName << ", " << packing << " } ");
        return false;
    }

 private:
    void showUsage() const {
        DIAGNOSE_WARN("phase0_annotation",
                      "Use: @phase0(\"TABLE_NAME\", \"ACTION_NAME\", Phase0Type)");
        DIAGNOSE_WARN("phase0_annotation",
                      "\"TABLE_NAME\":  The name which should be used for the "
                      "phase 0 table in the control plane API.");
        DIAGNOSE_WARN("phase0_annotation",
                      "\"ACTION_NAME\":  The name which should be used for the "
                      "phase 0 table's action in the control plane API.");
        DIAGNOSE_WARN("phase0_annotation",
                      "Phase0Type:  A header type describing the fields in the "
                      "phase 0 table entries and their layout on the wire. "
                      "Padding fields can be hidden from the control plane API "
                      "by marking them with the @hidden annotation.");
        DIAGNOSE_WARN("phase0_annotation",
                      "On %1%, Phase0Type's total size must be %2%b.",
                      Device::name(),
                      Device::pardeSpec().bitPhase0Size());
    }

    P4::ReferenceMap* refMap;
};

}  // namespace

void extractPhase0(const IR::P4Control* ingress, IR::BFN::Pipe* pipe,
                   P4::ReferenceMap* refMap) {
    CHECK_NULL(ingress);
    CHECK_NULL(pipe);
    CHECK_NULL(refMap);

    // Find the phase 0 annotation, and if it's present, save the Phase0Info
    // data structure so we can use it generate assembly at the end of the
    // compilation process.
    FindPhase0Annotation findPhase0(refMap);
    ingress->apply(findPhase0);
    if (findPhase0.phase0Info)
        pipe->phase0Info = findPhase0.phase0Info;
}

}  // namespace BFN
