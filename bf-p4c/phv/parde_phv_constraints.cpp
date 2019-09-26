#include "bf-p4c/phv/parde_phv_constraints.h"

Visitor::profile_t PardePhvConstraints::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    return rv;
}

bool PardePhvConstraints::preorder(const IR::BFN::Extract* extract) {
    // The constant extract constraint is only valid for Tofino.
    if (Device::currentDevice() != Device::TOFINO) return true;
    BUG_CHECK(extract->source != nullptr, "Extract must have a source?");
    if (!extract->source->is<IR::BFN::ConstantRVal>()) return true;
    const IR::BFN::ConstantRVal* sourceVal = extract->source->to<IR::BFN::ConstantRVal>();
    const IR::Constant* sourceConstant = sourceVal->constant;
    BUG_CHECK(extract->dest != nullptr, "No destination for extract?");
    LOG2("\tConstant extract to " << extract->dest->field << " : " << sourceConstant);
    auto* field = phv.field(extract->dest->field);
    BUG_CHECK(field, "No field reference for %1%", extract->dest->field);
    const IR::BFN::ParserState* ps = findContext<IR::BFN::ParserState>();
    if (!sourceConstant->fitsLong()) {
        // If a constant does not fit a long value, then assign the field to 8b containers just to
        // be safe. If the field is made up of stack validity bits, then ignore this added
        // constraint, because stack validity bits cannot be split into multiple containers.
        // Instead, rely on split parser states to initialize this metadata container.
        if (field->size > 8 && field->pov) {
            LOG3("\tCannot add 8b restriction to stack validity field " << field->name << " of size"
                 << field->size << "b.");
            return true;
        }
        if (field->size > 8 && field->no_split()) {
            LOG3("\tCannot add 8b restriction to field " << field->name << " already marked "
                 "atomic");
            return true;
        }
        LOG1("\tAdding 8b container size constraint to field: " << field->name);
        bool constraintAdded = sizePragmas.check_and_add_constraint(field, { PHV::Size::b8 });
        ERROR_CHECK(constraintAdded, "Field %1% is set in parser state %2% using the constant %3%."
                " Tofino requires the field to go to 8b containers because of hardware constraints."
                " However, field %1% has been specified already to not be allocated to 8b "
                "containers.", field->name, ps->name, sourceConstant);
        return true;
    }
    long constant = sourceConstant->asLong();
    bitvec bv(constant);
    LOG3("\t  Constant as bitvec: " << bv);
    // The first bit of the bitvec requires special handling.
    int firstBit = -1;
    for (auto b : bv) {
        if (firstBit == -1) {
            firstBit = b;
            LOG3("\t\tFirst bit: " << b);
            continue;
        }
        int diff = b - firstBit;
        LOG3("\t\tSubsequent bit: " << b);
        LOG3("\t\t  Difference with first bit: " << diff << ", maximum allowed: " <<
             MAX_CONSTANT_WINDOW);

        // For other bits, calculate the difference.
        // XXX(Deep): Add ability to distinguish between the 3b limit for 32b containers and 4b
        // limit for 16b containers. This requires the implementation of a
        // `do-not-allocate-to-a-particular-container-size` constraint in PHV.
        if (diff > MAX_CONSTANT_WINDOW) {
            if (field->size > 8 && field->pov) {
                LOG3("\tCannot add 8b restriction to stack validity field " << field->name << " of "
                     "size " << field->size << "b.");
                return true;
            }
            if (field->size > 8 && field->no_split()) {
                LOG3("\tCannot add 8b restriction to field " << field->name << " already marked "
                     "atomic");
                return true;
            }
            LOG1("\tAdding 8b container size constraint to field: " << field->name);
            bool constraintAdded = sizePragmas.check_and_add_constraint(field, { PHV::Size::b8 });
            ERROR_CHECK(constraintAdded, "Field %1% is set in parser state %2% using the constant "
                    "%3%. Tofino requires the field to go to 8b containers because of hardware "
                    "constraints. However, field %1% has been specified already to not be "
                    "allocated to 8b containers.", field->name, ps->name, sourceConstant);
            break;
        }
    }

    return true;
}

bool PardePhvConstraints::preorder(const IR::BFN::Digest* digest) {
    // Currently only support these three digests.
    if (digest->name != "learning" && digest->name != "resubmit" && digest->name != "mirror")
        return true;
    PHV::Field* selector = phv.field(digest->selector->field);
    BUG_CHECK(selector, "Selector field not present in PhvInfo");
    // Selector field (rounded up to the nearest byte) is considered as part of the learning quanta
    // size. Note that this field is already assigned to an 8-bit container elsewhere in the
    // compiler.
    const unsigned selectorSize = 8 * ROUNDUP(static_cast<unsigned>(selector->size), 8);;

    for (auto fieldList : digest->fieldLists) {
        unsigned digestSize = selectorSize;
        unsigned nonExactContainerDigestSize = 0;
        // Fields used in the digest.
        ordered_set<PHV::Field*> digestFields;
        // Fields used in the digest with a non exact containers requirement. It is only these
        // fields for whom we need to set constraints to limit the size of their containers.
        ordered_set<PHV::Field*> nonExactDigestFields;
        for (auto flval : fieldList->sources) {
            PHV::Field* f = phv.field(flval->field);
            BUG_CHECK(f, "Digest field not present in PhvInfo");
            // The digest fields and digestSize objects are only maintained for logging purposes.
            // The constraints are all added over fields that do not have the exact_containers()
            // requirement.
            digestFields.insert(f);
            unsigned roundedUpSize = 8 * ROUNDUP(static_cast<unsigned>(f->size), 8);
            digestSize += roundedUpSize;
            if (f->exact_containers()) continue;
            nonExactDigestFields.insert(f);
            nonExactContainerDigestSize += roundedUpSize;
        }
        const unsigned digestSizeInBytes = digestSize / 8;

        if (digestSizeInBytes > Device::maxDigestSizeInBytes())
            ::error("Learning quanta requires %1% bytes, which is greater than the maximum "
                    "permissible %2% bytes.", digestSizeInBytes, Device::maxDigestSizeInBytes());

        if (LOGGING(3)) {
            LOG3("\tDigest size: " << digestSizeInBytes << "B.");
            LOG3("\t  Non exact containers digest size: " << (nonExactContainerDigestSize / 8) <<
                    "B.");
            LOG3("\t  Selector field: " << selector->name);
            for (PHV::Field* f : digestFields) {
                std::stringstream ss;
                ss << "\t\t";
                if (nonExactDigestFields.count(f))
                    ss << "* ";
                ss << f->name << " (" << f->size << "b)";
                LOG3(ss.str());
            }
        }

        // If the digest size is less than the defined threshold, we don't need to impose any
        // additional constraints.
        if (digestSizeInBytes < DIGEST_BYTES_THRESHOLD) continue;

        // Impose constraints for digest fields without the exact_containers requirement.
        for (PHV::Field* f : nonExactDigestFields) {
            // For fields whose sizes are multiples of bytes, we set exact_containers to true and
            // also set them to no_pack. This ensures that the containers with these fields do not
            // have any additional bits not occupied by slices of these fields.
            if (f->size % 8 == 0) {
                f->set_exact_containers(true);
                f->set_no_pack(true);
                LOG2("\tSetting " << f->name << " to exact containers.");
                continue;
            }
            // For non byte multiple fields of size less than 32b, there are additional constraints.
            if (f->size <= 32) {
                const unsigned roundedUpSizeInBytes = ROUNDUP(static_cast<unsigned>(f->size), 8);
                BUG_CHECK(roundedUpSizeInBytes <= 4, "The rounded up size of field %1% in bytes "
                          "here cannot be greater than 4.", f->name);
                if (roundedUpSizeInBytes == 1) {
                    if (!sizePragmas.check_and_add_constraint(f, { PHV::Size::b8})) {
                        ::error("To fit within learning quanta size constraints, the field %1% must"
                                " occupy an 8-bit container. However, there are conflicting "
                                "pa_container_size constraints on the field", f->name);
                        continue;
                    }
                    // Setting the fields to no split ensures that they will be assigned to the same
                    // container.
                    f->set_no_split(true);
                    LOG2("\tSetting " << f->name << " to 8-bit container and no-split");
                } else if (roundedUpSizeInBytes == 2) {
                    if (!sizePragmas.check_and_add_constraint(f, { PHV::Size::b16})) {
                        ::error("To fit within learning quanta size constraints, the field %1% must"
                                " occupy a 16-bit container. However, there are conficting "
                                "pa_container_size constraints on the field", f->name);
                        continue;
                    }
                    // Setting the fields to no split ensures that they will be assigned to the same
                    // container.
                    f->set_no_split(true);
                    LOG2("\tSetting " << f->name << " to 16-bit container and no-split");
                } else if (roundedUpSizeInBytes == 3) {
                    // We cannot set no-split for this case as a field between 17-24 bits in size
                    // must necessarily be split across multiple containers. We choose one 16-bit
                    // and one 8-bit container just to avoid using too many containers of one size.
                    if (!sizePragmas.check_and_add_constraint
                            (f, { PHV::Size::b16, PHV::Size::b8 })) {
                        ::error("To fit within learning quanta size constraints, the field %1% must"
                                " occupy a 16-bit and an 8-bit container. However, there are "
                                "conflicting pa_container_size constraints on the field", f->name);
                        continue;
                    }
                    LOG2("\tSetting " << f->name << " to 16-bit and 8-bit containers");
                } else {
                    if (!sizePragmas.check_and_add_constraint(f, { PHV::Size::b32 })) {
                        ::error("To fit within learning quanta size constraints, the field %1% must"
                                " occupy a 32-bit container. However, there are conflicting "
                                "pa_container_size constraints on the field", f->name);
                        continue;
                    }
                    LOG2("\tSetting " << f->name << " to 32-bit container");
                    // Setting the fields to no split ensures that they will be assigned to the same
                    // container.
                    f->set_no_split(true);
                    LOG2("\tSetting " << f->name << " to be no-split.");
                }
                continue;
            }
            // XXX(Deep): We do not have the ability to impose the right constraints on non byte
            // aligned fields of size greater than 32b. Maybe, the answer is to replace that single
            // field with multiple slices of the field and impose the constraints on those slices?
            ::warning("Cannot yet impose constraints on non byte aligned field, %1% greater than "
                      "32b.", f->name);
        }
    }
    return true;
}

Visitor::profile_t TofinoParserConstantExtract::init_apply(const IR::Node* root) {
    phv.clearConstantExtractionState();
    stateToPOVMap.clear();
    return Inspector::init_apply(root);
}

bool TofinoParserConstantExtract::preorder(const IR::BFN::Extract* e) {
    // The hardware constraints on extracting constants is not applicable to JBay.
    if (Device::currentDevice() != Device::TOFINO) return true;
    if (!e->dest) BUG("No destination for parser extract?");
    PHV::Field* field = phv.field(e->dest->field);
    if (!field) BUG("No field corresponding to parser extract destination?");
    // If the field is not being set to a constant value, ignore the extract.
    if (!e->source->to<IR::BFN::ConstantRVal>()) return true;
    // Only consider POV fields. For non POV fields, the parser should account for the extractors
    // correctly.
    if (!field->pov) return true;
    auto state = findContext<IR::BFN::ParserState>();
    if (!state) BUG("No parser state corresponding to extract?");
    LOG3("\t  Field extracted using constant: " << field->name << ", state: " << state->name);
    stateToPOVMap[state].insert(field);
    phv.insertConstantExtractField(field);
    return true;
}

void TofinoParserConstantExtract::end_apply() {
    for (auto kv : stateToPOVMap) {
        if (kv.second.size() == 1) continue;
        for (auto* f1 : kv.second) {
            for (auto* f2 : kv.second) {
                if (f1 == f2) continue;
                phv.mergeConstantExtracts(f1, f2); } } }

    if (!LOGGING(2)) return;

    LOG2("\tPrinting sets of fields extracted in the same state");
    UnionFind<PHV::Field*>& extracts = phv.getSameSetConstantExtraction();
    int i = 0;
    for (auto* set : extracts) {
        if (set->size() < 2) continue;
        LOG2("\t  Set " << i++);
        for (auto* f : *set)
            LOG2("\t\t" << f->name);
    }
}
