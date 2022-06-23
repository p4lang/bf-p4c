#include "action_data_bus.h"
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

int ActionDataBus::find_free_words(bitvec bits, size_t align, int *slots) {
    int bytes = bits.max().index()/8U + 1;
    if ((bytes & 3) == 1) --bytes;  // don't try for an odd single byte
    if (bytes == 0) {
        *slots = 0;
        return -1; }
    int best = -1, best_size = 0;
    for (int idx = 0; idx < IABUS32*4; idx += align/8) {
        int i;
        for (i = 0; i < bytes; i++) {
            if (bits.getrange(i*8, 8) == 0) continue;
            if (adb_use[idx+i]) {
                break; } }
        if (i > best_size) {
            best = idx;
            best_size = i; }
        if (best_size >= bytes)
            break; }
    if (best_size < 4 && best_size != bytes) {
        *slots = 0;
        return -1; }
    *slots = (best_size + 3)/4;
    return best;
}

int ActionDataBus::find_free_bytes(bitvec bits, size_t align, int offset, int *slots) {
    int bytes = bits.max().index()/8U + 1;
    for (int idx = IABUS32*4; idx < IABUS32*4 + IABUS8; idx += align/8) {
        bool ok = true;
        for (int i = offset; i < bytes; i++) {
            if (bits.getrange(i*8, 8) == 0) continue;
            if (adb_use[idx+i]) {
                ok = false;
                break; } }
        if (ok) {
            *slots = bytes - offset;
            return idx; } }
    *slots = 0;
    return -1;
}

/** allocation of the action data bus for a set of uses
 */
bool ActionDataBus::alloc_action_data_bus(const IR::MAU::Table *tbl,
        safe_vector<const ActionData::ALUPosition *> &alu_ops, TableResourceAlloc &alloc) {
    LOG2("  Initial Action Data Bus");
    LOG2("    " << hex(total_in_use.getrange(32, 32), 8, '0')
         << "|" << hex(total_in_use.getrange(0, 32), 8, '0'));

    if (alu_ops.empty()) return true;  // nothing needed on abus
    std::stable_sort(alu_ops.begin(), alu_ops.end(),
        [](const ActionData::ALUPosition *a, const ActionData::ALUPosition *b) {
            return a->alu_op->size() > b->alu_op->size(); });

    // pack all alu ouputs into a correctly aligned chunk for the phv to be written
    // best effect trying to get them into a compact space (which is why we sort based
    // on destination phv container size -- largest first as they are the most constrained)
    bitvec bit_pack;
    safe_vector<int> shift;
    size_t align = 0;
    for (auto *pos : alu_ops) {
        shift.push_back(0);
        while (bit_pack & (pos->alu_op->phv_bits() << shift.back()))
            shift.back() += pos->alu_op->size();
        align = std::max(align, pos->alu_op->size());
        bit_pack |= (pos->alu_op->phv_bits() << shift.back()); }
    int bytes = bit_pack.max().index()/8U + 1;

    int word_offset = -1, word_slots = 0, byte_offset = -1, byte_slots = 0;
    word_offset = find_free_words(bit_pack, align, &word_slots);
    if (bytes > word_slots * 4) {
        if ((byte_offset = find_free_bytes(bit_pack, align, word_slots*4, &byte_slots)) < 0)
            return false;
        BUG_CHECK(bytes == word_slots * 4 + byte_slots, "inconsistent adb allocation"); }

    auto &ad_xbar = getUse(alloc.action_data_xbar);
    ad_xbar.clear();
    int i = -1;
    for (auto *pos : alu_ops) {
        int byte = word_offset + shift[++i]/8;
        if (shift[i] >= word_slots * 32)
            byte = byte_offset + shift[i]/8;
        Loc loc(byte, ActionData::bits_to_slot_type(pos->alu_op->size()));
        ad_xbar.action_data_locs.emplace_back(loc, pos->start_byte, pos->alu_op->phv_bytes(),
                                              pos->loc);
    }

    LOG2(" Action data bus for " << tbl->name);
    for (auto &rs : ad_xbar.action_data_locs) {
        LOG2("    Reserved " << rs.location.byte << " for offset " << rs.byte_offset <<
             " of type " << rs.location.type);
    }
    for (auto &rs : ad_xbar.clobber_locs) {
        LOG2("    Reserved clobber " << rs.location.byte << " for offset "
             << rs.byte_offset << " of type " << rs.location.type);
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
            LOG2(" Action data bus shared on action profile " << ad->name);
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

    LOG1("Allocating action data bus for " << tbl->name << " for meter output of " << am->name);
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
    int byte_sz = ActionData::slot_type_to_bits(rs.location.type)/8;
    for (int i = rs.location.byte; i < rs.location.byte + byte_sz; i++) {
        if (rs.bytes_used.getbit(i - rs.location.byte) == false)
            continue;
        if (!adb_use[i].isNull() && adb_use[i] != name)
            BUG("Conflicting alloc on the action data bus between %s and %s at byte %d",
                name, adb_use[i], rs.location.byte);
        adb_use[i] = name; }
    total_in_use |= rs.bytes_used << rs.location.byte;
}

void ActionDataBus::update(const IR::MAU::Table *tbl) {
    ::ActionDataBus::update(tbl->name, tbl->resources, tbl);
}

std::unique_ptr<::ActionDataBus> ActionDataBus::clone() const {
    return std::unique_ptr<::ActionDataBus>(new ActionDataBus(*this));
}

}  // end namespace Flatrock
