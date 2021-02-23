#include "bf-p4c/phv/add_alias_allocation.h"

namespace PHV {

void AddAliasAllocation::addAllocation(
        PHV::Field* aliasSource,
        PHV::Field* aliasDest,
        le_bitrange range) {
    BUG_CHECK(aliasSource->size == range.size(), "Alias source (%1%b) and destination (%2%b) of "
              "different sizes", aliasSource->size, range.size());

    // Avoid adding allocation for the same field more than once.
    if (seen.count(aliasSource)) return;
    seen.insert(aliasSource);

    // Add allocation.
    aliasDest->foreach_alloc(range, [&](const PHV::AllocSlice& alloc) {
        PHV::AllocSlice new_slice(aliasSource, alloc.container(),
                                  alloc.field_slice().lo - range.lo,
                                  alloc.container_slice().lo,
                                  alloc.width(), alloc.getInitPoints());
        new_slice.setLiveness(alloc.getEarliestLiveness(), alloc.getLatestLiveness());
        // Workaround to ensure only one of the aliased fields has an always run instruction in the
        // last stage.
        new_slice.setShadowAlwaysRun(alloc.getInitPrimitive()->mustInitInLastMAUStage());
        LOG5("Adding allocation slice for aliased field: " << aliasSource << " " << new_slice);
        aliasSource->add_alloc(new_slice);
        phv.add_container_to_field_entry(alloc.container(), aliasSource);
    });

    aliasDest->aliasSource = aliasSource;
}

bool AddAliasAllocation::preorder(const IR::BFN::AliasMember* alias) {
    // Recursively add any aliases in the source.
    alias->source->apply(AddAliasAllocation(phv));

    // Then add this alias.
    PHV::Field* aliasSource = phv.field(alias->source);
    CHECK_NULL(aliasSource);
    PHV::Field* aliasDest = phv.field(alias);
    CHECK_NULL(aliasDest);
    addAllocation(aliasSource, aliasDest, StartLen(0, aliasSource->size));
    return true;
}

bool AddAliasAllocation::preorder(const IR::BFN::AliasSlice* alias) {
    // Recursively add any aliases in the source.
    alias->source->apply(AddAliasAllocation(phv));

    // Then add this alias.
    PHV::Field* aliasSource = phv.field(alias->source);
    CHECK_NULL(aliasSource);
    PHV::Field* aliasDest = phv.field(alias);
    CHECK_NULL(aliasDest);
    addAllocation(aliasSource, aliasDest, FromTo(alias->getL(), alias->getH()));
    return true;
}

void AddAliasAllocation::end_apply() {
    // Later passes assume that PHV allocation is sorted in field bit order
    // MSB first
    for (auto& f : phv)
        f.sort_alloc();
}

}  // namespace PHV
