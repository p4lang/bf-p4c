#include "action_bus.h"
#include "action_table.h"

void Flatrock::ActionBus::alloc_field(Table *tbl, ActionBusSource src,
                                      unsigned offset, unsigned sizes_needed) {
    LOG4("alloc_field(" << src << ", " << offset << ", " << sizes_needed << ")");
    unsigned size = size_masks[sizes_needed] + 1;
    switch (src.type) {
    case ActionBusSource::XcmpData: {
        int slot = src.xcmp_group*16 + src.xcmp_byte;  // FIXME -- for now just byte offset
        Slot &sl = by_byte.emplace(slot, Slot(src.name(tbl), slot, size)).first->second;
        if (sl.size < size) sl.size = size;
        sl.data.emplace(src, offset);
        LOG4("  slot " << sl.byte << "(" << sl.name << ") data += " <<
             src.toString(tbl) << " off=" << offset);
        break; }
    default:
        BUG("ActionBus::alloc_field(%s) not supported on flatrock", src.toString(tbl).c_str()); }
}

void Flatrock::ActionBus::write_regs(Target::Flatrock::mau_regs &regs, Table *tbl) {
    auto &opfifo = regs.ppu_opfifo.rf;
    auto &ealu = regs.ppu_ealu.rf;
    auto &mrd = regs.ppu_mrd;
    int immed_offset = -1;
    for (auto &el : by_byte) {
        BUG_CHECK(el.second.data.size() >= 1, "No data in Flatrock::ActionBus::write_regs");
        auto &src = el.second.data.begin()->first;
        switch (src.type) {
        case ActionBusSource::Field: {
            auto *atab = tbl->to<Target::Flatrock::ActionTable>();
            if (atab) {
                // mrd_aram_cfg already set up in Target::Flatrock::ActionTable::write_regs,
                // but perhaps should be here?
            } else {
                unsigned bit = src.field->immed_bit(0);
                if (immed_offset < 0) {
                    immed_offset = el.first - bit/8U;
                    mrd.rf.mrd_iad_cfg[tbl->physical_id].badb_start = immed_offset;
                    // FIXME -- need dconfig here
                    mrd.rf.mrd_iad_ext[tbl->physical_id].ext_size[0] = tbl->format->immed_size;
                } else if (immed_offset != el.first - bit/8U) {
                    error(lineno, "immediate field misalignment on action bus"); } }
            for (auto i = el.first; i < el.first + (el.second.size + 7)/8U; ++i) {
                if (i < 4) {
                    ealu.ealu_cfg.bypass_ealu |= 1U << i;
                } else if (i < 8) {
                    ealu.ealu_cfg.bypass_ealu |= 1U << (2 + i/2);
                } else if (i >= 16) {
                    if (i & 3) continue;
                    if (!atab) {
                        error(lineno, "immediate must be in the bottom 16 bytes of action "
                              "data bus");
                        continue; }
                    if (i < 23)
                        ealu.ealu_cfg.bypass_ealu |= 1U << (2 + i/4); }
                if (i < 16)
                    ealu.ealu_eb_xbar[i].en |= 1U << i;
                else if (i < 23)
                    ealu.ealu_ew_xbar_bot[i/4 - 4].inputword = i/4;
                else
                    ealu.ealu_ew_xbar_top[i/4 - 6].shift = 0; }
            break; }
        case ActionBusSource::XcmpData:
            if (src.xcmp_group) {
                BUG_CHECK(src.xcmp_group >= 1 && src.xcmp_group <= 4, "invalid XCMP group");
                unsigned wgroup = src.xcmp_group - 1;
                unsigned word = wgroup*4 + src.xcmp_byte/4U;
                opfifo.opfifo_adb_direct.wadb_en |= 1U << word;
                if (word < 2) {
                    // EALU has an OXBAR for the bottom two words that can select
                    // from any 4-byte chunk of the entire ADB
                    ealu.ealu_ew_xbar_bot[word].inputword = word+4;
                    ealu.ealu_cfg.bypass_ealu |= 1U << (word + 6);
                } else {
                    // can select word from n or n-1 or n-2
                    ealu.ealu_ew_xbar_top[word-2].shift = 0; }
            } else {
                for (int byte = src.xcmp_byte; byte < src.xcmp_byte + el.second.size/8; ++byte) {
                    opfifo.opfifo_adb_direct.badb_en |= 1U << byte;
                    // EALU has a full XBAR here so can rearrange badb in any way
                    // FIXME -- express/make use of this flexibility
                    ealu.ealu_eb_xbar[byte].en |= 1U << byte;
                    if (byte < 4)
                        ealu.ealu_cfg.bypass_ealu |= 1U << byte;
                    else if (byte < 8)
                        ealu.ealu_cfg.bypass_ealu |= 1U << (2 + byte/2U);
                }
            }
            break;
        default:
            BUG("%s not supported in Flatrock::ActionBus::write_regs", src.toString(tbl).c_str());
        }
    }
}
