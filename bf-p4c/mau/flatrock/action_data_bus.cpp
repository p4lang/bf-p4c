#include "action_data_bus.h"
#include "bf-p4c/mau/action_format.h"
#include "bf-p4c/mau/resource.h"

namespace Flatrock {

void ActionDataBus::clear() {
    ::ActionDataBus::clear();
}

ActionDataBus::Use &ActionDataBus::getUse(autoclone_ptr<::ActionDataBus::Use> &ac) {
    Use *rv;
    if (ac) {
        rv = dynamic_cast<Use *>(ac.get());
        BUG_CHECK(rv, "Wrong kind of ActionDataBus::Use present");
    } else {
        ac.reset((rv = new Use)); }
    return *rv;
}

int ActionDataBus::find_free_bytes(const IR::MAU::Table *tbl, const ActionData::ALUPosition *pos,
            safe_vector<Use::ReservedSpace> &action_data_locs, ActionData::Location_t loc) {
    int byte_start = 0, byte_end = 0, align = 0;
    if (loc == ActionData::IMMEDIATE) {
        byte_start  = IMMEDIATE_BYTES_START;
        byte_end    = IMMEDIATE_BYTES_END;
        align       = (pos->alu_op->size() + 7) / 8;  // Byte align
    } else {
        byte_start  = WORD_BYTES_START;
        byte_end    = WORD_BYTES_END;
        align       = ((pos->alu_op->size() + 7) / 8) + 3 / 4;  // Word align
    }

    if (byte_start + align > byte_end) return false;

    LOG5("   Finding free bytes for table " << tbl->name << " loc: " << loc
            << " pos: " << *pos << " align: " << align);
    for (int idx = byte_start; idx < byte_end; idx += align) {
        if (total_in_use.getrange(idx, align) == 0) {
            total_in_use.setrange(idx, align);
            Loc loc(idx, ActionData::bits_to_slot_type(pos->alu_op->size()));
            action_data_locs.emplace_back(loc, pos->start_byte, pos->alu_op->phv_bytes(),
                                          pos->loc);
            if (LOGGING(5)) {
                std::string print_bytes = "{";
                for (int i = 0; i < align; i++) { print_bytes += (" " + std::to_string(i) + " "); }
                print_bytes += "}";
                LOG5("    Found on bytes " << print_bytes);
            }
            return true;
        }
    }
    LOG5("   No bytes found");
    return false;
}

/** Allocation of the action data bus for a set of uses
 * The adb as a whole is 64 bytes, with the first 16 byes being the 'byte' adb.  This is analogous
 * to the byte/halfword/word regions of the adb in tofino.  Basically we have a bit more alignment
 * freedom putting things into the first 16 bytes of the adb
 *
 * The immediate data extracted from the payload can ony go to the first 16 bytes of the adb
 *
 * There is a bit shift in the extract part of the immediate path (before the map/def table), so
 * this does not mean that the immediate data needs to be byte aligned in the overhead/match word
 * format. Generally the extract will shift the immediate data down to bit 0, which then goes
 * through the map/def, and is then byte rotated to the appropriate bytes on the (byte) adb.
 *
 * The alignment restrictions in PHVWRITE are matching the PHE size.  So the
 * adb source for a 32-bit PHE needs to be 32-bit aligned in the adb.
 */
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl,
        safe_vector<const ActionData::ALUPosition *> &alu_ops, TableResourceAlloc &alloc) {
    LOG2("  Initial Action Data Bus : " << *this);

    if (alu_ops.empty()) return true;  // nothing needed on abus
    std::stable_sort(alu_ops.begin(), alu_ops.end(),
        [](const ActionData::ALUPosition *a, const ActionData::ALUPosition *b) {
            return a->alu_op->size() > b->alu_op->size(); });

    if (LOGGING(4)) {
        LOG4("   Alu ops to pack:");
        for (auto *alu_op : alu_ops)
            LOG4("    " << *alu_op);
    }

    // Pack all alu ouputs into a correctly aligned chunk for the phv to be written
    // best effect trying to get them into a compact space (which is why we sort based
    // on destination phv container size -- largest first as they are the most constrained)
    // Allocation Algorithm:
    // 1. Allocate immediates in byte adb
    // 2. Allocate non immediates to word adb
    // 3. Allocate unallocated non immediates to byte adb

    // Work with a copy of adb usage to update for each alu op
    safe_vector<Use::ReservedSpace> action_data_locs;
    for (auto *pos : alu_ops) {
        if (pos->loc != ActionData::IMMEDIATE) continue;
        auto ok = find_free_bytes(tbl, pos, action_data_locs, ActionData::IMMEDIATE);
        if (!ok) {
            LOG4("  Cannot allocate " << *pos << " to action data bus ");
            return false;
        }
    }
    for (auto *pos : alu_ops) {
        if (pos->loc == ActionData::IMMEDIATE) continue;
        if (!find_free_bytes(tbl, pos, action_data_locs, pos->loc)
            || !find_free_bytes(tbl, pos, action_data_locs, ActionData::IMMEDIATE)) {
            LOG4("  Cannot allocate " << *pos << " to action data bus");
            return false;
        }
    }

    // All action data is allocated update xbar
    auto &ad_xbar = getUse(alloc.action_data_xbar);
    ad_xbar.clear();
    ad_xbar.action_data_locs = action_data_locs;

    LOG2(" Action data bus for " << tbl->name);
    for (auto &rs : ad_xbar.action_data_locs) {
        LOG2("    Reserved " << rs.location.byte << " for offset " << rs.byte_offset <<
             " of type " << rs.location.type << " " << rs.location);
    }
    for (auto &rs : ad_xbar.clobber_locs) {
        LOG2("    Reserved clobber " << rs.location.byte << " for offset "
             << rs.byte_offset << " of type " << rs.location.type << " " << rs.location);
    }

    return true;
}

/** allocation of the action unit(s) and action data bus for a particular table.
 */
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl,
        const ActionData::Format::Use *use, TableResourceAlloc &alloc) {
    LOG1("Allocating action data bus for " << tbl->name);
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;
        auto ad = at->to<IR::MAU::ActionData>();
        if (ad == nullptr) continue;

        auto pos = allocated_attached.find(ad);
        if (pos != allocated_attached.end()) {
            alloc.action_data_xbar.reset(pos->second.clone());
            LOG2(" Action data bus shared on action profile " << ad->name.toString());
            return true;
        }
    }

    auto alu_ops = use->all_alu_positions();
    if (alu_ops.empty()) return true;
    if (!alloc_action_data_bus(tbl, alu_ops, alloc)) return false;
    // FIXME -- big/complex tables/actions may need more than one action alu
    bool need_stm = std::any_of(alu_ops.begin(), alu_ops.end(),
            [](const ActionData::ALUPosition *p) {
                return p->loc == ActionData::ACTION_DATA_TABLE; });
    for (int alu = need_stm ? 1 : 0; alu < ALUS_PER_ACTION_UNIT; ++alu) {
        for (int unit = 0; unit < ACTION_UNITS; ++unit) {
            if (!action_alu_use.at(unit, alu)) {
                getUse(alloc.action_data_xbar).action_alus.emplace_back(unit, alu);
                return true; } } }

    return false;
}

/**
 * Implement the action data bus allocation logic here for meter alu output.
 *  should also allocate stateful/meter units here?
 */
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl,
        const MeterALU::Format::Use *use, TableResourceAlloc &alloc) {
    const IR::MAU::AttachedMemory* am = nullptr;
    const IR::MAU::StatefulAlu *salu = nullptr;
    for (auto back_at : tbl->attached) {
        auto at = back_at->attached;

        auto mtr = at->to<IR::MAU::Meter>();
        salu = at->to<IR::MAU::StatefulAlu>();

        if ((mtr && mtr->alu_output()) || salu) {
            am = at;
            break;
        }
    }

    if (am == nullptr)
        return true;

    LOG1("Allocating action data bus for " << tbl->name
            << " for meter output of " << am->name.toString());
    auto alu_ops = use->all_alu_positions();
    if (alu_ops.empty()) return true;
    if (!alloc_action_data_bus(tbl, alu_ops, alloc)) return false;
    return true;
}

void ActionDataBus::update(cstring name, const ::ActionDataBus::Use &alloc_) {
    const Use &alloc = dynamic_cast<const Use &>(alloc_);
    ::ActionDataBus::update(name, alloc);
    for (auto &alu : alloc.action_alus) {
        if (action_alu_use[alu] && action_alu_use[alu] != name)
            BUG("Conflicting use of basic action alu %c%d between %s and %s",
                alu.second ? 'B' : 'A', alu.first, action_alu_use[alu], name);
        action_alu_use[alu] = name; }
}

void ActionDataBus::update(cstring name, const Use::ReservedSpace &rs) {
    LOG3("Updating ADB for " << name << " rs: " << rs);
    int byte_sz = ActionData::slot_type_to_bits(rs.location.type)/8;
    for (int i = rs.location.byte; i < rs.location.byte + byte_sz; i++) {
        if (rs.bytes_used.getbit(i - rs.location.byte) == false)
            continue;
        if (!total_use[i].isNull() && total_use[i] != name)
            BUG("Conflicting alloc on the action data bus between %s and %s at byte %d",
                name, total_use[i], rs.location.byte);
        total_use[i] = name; }
    total_in_use |= rs.bytes_used << rs.location.byte;
    LOG4("  Updated Action Data Bus: " << *this);
}

void ActionDataBus::update(const IR::MAU::Table *tbl) {
    ::ActionDataBus::update(tbl->name, tbl->resources, tbl);
}

std::unique_ptr<::ActionDataBus> ActionDataBus::clone() const {
    return std::unique_ptr<::ActionDataBus>(new ActionDataBus(*this));
}

std::ostream &operator<<(std::ostream &out, const ActionDataBus &adb) {
    // Outputs as "Word ADB | Byte ADB"
    auto ABUS8 = ActionDataBus::ABUS8;
    auto ABUS32 = ActionDataBus::ABUS32;
    out << hex(adb.total_in_use.getrange(ABUS8, ABUS32), ABUS32/4, '0')
       << "|" << hex(adb.total_in_use.getrange(0, ABUS8), ABUS8/4, '0');
    return out;
}
}  // end namespace Flatrock
