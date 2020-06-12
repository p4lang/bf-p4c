#include "bf-p4c/mau/ixbar_realign.h"
#include "bf-p4c/mau/table_summary.h"
#include "bf-p4c/phv/phv_fields.h"
#include "lib/hex.h"

class IXBarVerify::GetCurrentUse : public MauInspector {
    IXBarVerify        &self;
    bool preorder(const IR::Expression *) override { return false; }
    bool preorder(const IR::MAU::Table *t) override {
        BUG_CHECK(t->is_always_run_action() || t->global_id(), "Table not placed");
        unsigned stage = t->stage();
        if (stage >= self.stage.size())
            self.stage.resize(stage + 1);
        self.stage[stage].update(t);
        return true; }
 public:
    explicit GetCurrentUse(IXBarVerify &s) : self(s) {}
};

/** For each ixbar byte, this verifies that each IXBar::Use::Byte coordinates to a single
 *  byte within a PHV container.  Furthermore it verifies that each byte is at it's correct
 *  alignment.  Currently the algorithm does not take advantage of the TCAM byte swizzle,
 *  and would have to be expanded, as TCAM bytes don't have to be at their alignment
 */
void IXBarVerify::verify_format(const IXBar::Use &use) {
    BUG_CHECK(currentTable, "No table context found for input crossbar use");
    for (auto &byte : use.use) {
        bitvec byte_use;
        PHV::Container container;
        size_t mod_4_offset = -1;
        bool container_set = false;
        for (auto fi : byte.field_bytes) {
            auto *field = phv.field(fi.field);
            bool byte_found = false;
            bool single_byte = true;
            PHV::FieldUse use(PHV::FieldUse::READ);
            auto slicesToProcess =
                field->get_combined_alloc_bytes(PHV::AllocContext::of_unit(currentTable), &use);
            for (const auto& alloc : slicesToProcess) {
                if (fi.lo < alloc.field_bit || fi.hi > alloc.field_hi())
                    continue;
                size_t potential_mod4_offset = alloc.container_bit / 8;
                if (!container_set) {
                    container = alloc.container;
                    mod_4_offset = potential_mod4_offset;
                } else if (container != alloc.container
                           || mod_4_offset != potential_mod4_offset) {
                    single_byte = false;
                    continue;
                }

                int container_start = (alloc.container_bit % 8) + fi.lo - alloc.field_bit;
                if (container_start != fi.cont_lo)
                    continue;
                byte_found = true;
                BUG_CHECK((byte_use & fi.cont_loc()).empty(), "Overlapping field bit "
                          "information on an input xbar byte: %s", byte);
                byte_use |= fi.cont_loc();
            }
            if (!byte_found || !single_byte)
                throw IXBar::failure(-1, byte.loc.group);
        }

        if (!use.ternary) {
            if ((byte.loc.byte % (container.size() / 8)) != mod_4_offset)
                throw IXBar::failure(-1, byte.loc.group);
        } else {
            size_t byte_offset = byte.loc.group * IXBar::TERNARY_BYTES_PER_GROUP;
            byte_offset += (byte.loc.group + 1) / 2;
            byte_offset += byte.loc.byte;
            if ((byte_offset % (container.size() / 8)) != mod_4_offset)
                throw IXBar::failure(-1, byte.loc.group);
        }
    }
}

Visitor::profile_t IXBarVerify::init_apply(const IR::Node *root) {
    auto rv = MauModifier::init_apply(root);
    stage.clear();
    currentTable = nullptr;
    root->apply(GetCurrentUse(*this));
    return rv;
}

void IXBarVerify::postorder(IR::MAU::Table *tbl) {
    currentTable = tbl;
    verify_format(tbl->resources->gateway_ixbar);
    verify_format(tbl->resources->match_ixbar);
    verify_format(tbl->resources->selector_ixbar);
    verify_format(tbl->resources->salu_ixbar);
    verify_format(tbl->resources->meter_ixbar);
    for (auto &hash_dist_use : tbl->resources->hash_dists) {
        for (auto &ir_alloc : hash_dist_use.ir_allocations) {
            verify_format(ir_alloc.use);
        }
    }
}
