#include "bf-p4c/phv/parde_phv_constraints.h"

Visitor::profile_t PardePhvConstraints::init_apply(const IR::Node* root) {
    profile_t rv = Inspector::init_apply(root);
    return rv;
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
