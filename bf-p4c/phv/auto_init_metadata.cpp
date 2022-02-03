#include "auto_init_metadata.h"
#include "bf-p4c/common/pragma/all_pragmas.h"
#include "bf-p4c/phv/pragma/pa_no_init.h"

bool DisableAutoInitMetadata::auto_init_metadata(const IR::BFN::Pipe* pipe) const {
    for (auto* anno : pipe->global_pragmas) {
        if (anno->name.name == PragmaAutoInitMetadata::name) {
            return true;
        }
    }

    return false;
}

const IR::Node* DisableAutoInitMetadata::preorder(IR::BFN::Pipe* pipe) {
    // If the user requested automatic metadata initialization, then don't do anything here.
    if (auto_init_metadata(pipe)) return Transform::preorder(pipe);

    prune();

    for (auto field : defuse.getUninitializedFields()) {
        // Ensure we have a non-POV metadata field.
        if (!field->metadata || field->pov) continue;

        // Ensure the metadata field is initially valid.
        if (field->is_invalidate_from_arch()) continue;

        // We have a metadata field that is not definitely initialized. Add an entry to the pipe's
        // global pragmas.
        auto gress = field->gress;
        auto field_name = stripThreadPrefix(field->name);

        // Pre tna specification section 5.5, ig_intr_md_for_dprsr.drop_ctl and
        // ig_intr_md_for_dprsr.mirror_type should be initialized to zero automatically even if
        // auto_init_metadata is not enabled. Therefore, these two fields should be excluded from
        // pa_no_init, unless users explicitly set it. And this only applies to tna arch, since
        // after t2na, phv containers do not come with a implicit validity bit. A explicit validity
        // bit is needed, see add_jbay_pov.h
        if (field->is_intrinsic()) {
            if (field->name.endsWith("ig_intr_md_for_dprsr.drop_ctl")) continue;
            if (field->name.endsWith("ig_intr_md_for_dprsr.mirror_type")) continue;
        }

        auto annotation = new IR::Annotation(PragmaNoInit::name,
                                             { new IR::StringLiteral(toString(gress)),
                                               new IR::StringLiteral(field_name),
                                             });
        LOG1("Added annotation @" << PragmaNoInit::name
            << "(\"" << gress << "\", \"" << field_name << "\")");
        pipe->global_pragmas.push_back(annotation);
    }

    return Transform::preorder(pipe);
}

bool RemoveMetadataInits::elim_assign(const IR::BFN::Unit* unit,
                                      const IR::Expression* left,
                                      const IR::Expression* right) {
    // Make sure the right side is the constant 0 or false.
    auto c = right->to<IR::Constant>();
    auto b = right->to<IR::BoolLiteral>();
    if (!c && !b) return false;
    if (c && c->value != 0) return false;
    if (b && b->value != false) return false;

    // Make sure the left side is a metadata field that is initially valid.
    auto field = phv.field(left);
    if (!field) return false;
    if (!field->metadata) {
        LOG4("Unable to remove initialization of " << field->name
             << ": not metadata");
        return false;
    }
    if (field->is_invalidate_from_arch()) {
        LOG4("Unable to remove initialization of " << field->name
             << ": not initially valid");
        return false;
    }

    // Make sure the metadata field is not annotated with @pa_no_init.
    if (pa_no_inits.count(field->name)) {
        LOG4("Unable to remove initialization of " << field->name
             << ": annotated @pa_no_init");
        return false;
    }

    // Make sure the assignment only overwrites ImplicitParserInit.
    auto& output_deps = defuse.getOutputDeps(unit, left);
    if (output_deps.size() != 1
            || !output_deps.front().second->to<ImplicitParserInit>()) {
        if (LOGGING(4)) {
            LOG4("Unable to remove initialization of " << field->name
                 << ". Overwrites the following:");
            for (auto& output_dep : output_deps)
                LOG4("  " << output_dep.second);
        }
        return false;
    }

    return true;
}

bool RemoveMetadataInits::elim_extract(const IR::BFN::Unit* unit,
                                       const IR::BFN::Extract* extract) {
    if (auto lval = extract->dest->to<IR::BFN::FieldLVal>()) {
        if (auto rval = extract->source->to<IR::BFN::ConstantRVal>()) {
            auto result = elim_assign(unit, lval->field, rval->constant);
            if (result) LOG1("Eliminated extract " << extract);
            return result;
        }
    }

    return false;
}

const IR::BFN::Pipe* RemoveMetadataInits::preorder(IR::BFN::Pipe* pipe) {
    pa_no_inits.clear();

    // Populate pa_no_inits.
    for (auto anno : pipe->global_pragmas) {
        if (anno->name != PragmaNoInit::name) continue;

        BUG_CHECK(anno->expr.size() == 2,
                  "%1% pragma expects two arguments, but got %2%: %3%",
                  PragmaNoInit::name, anno->expr.size(), anno);

        auto gress = anno->expr.at(0)->to<IR::StringLiteral>();
        BUG_CHECK(gress,
                  "First argument to %1% is not a string: %2%",
                  PragmaNoInit::name, anno->expr.at(0));

        auto field = anno->expr.at(1)->to<IR::StringLiteral>();
        BUG_CHECK(field,
                  "Second argument to %1% is not a string: %2%",
                  PragmaNoInit::name, anno->expr.at(1));

        pa_no_inits.insert(gress->value + "::" + field->value);
    }

    return pipe;
}

const IR::MAU::Instruction* RemoveMetadataInits::preorder(IR::MAU::Instruction* instr) {
    if (auto unit = findOrigCtxt<IR::BFN::Unit>()) {
        if (instr->name == "set" && elim_assign(unit, instr->operands[0], instr->operands[1])) {
            LOG1("Eliminated assignment " << instr);
            return nullptr;
        }
    }
    return instr;
}
