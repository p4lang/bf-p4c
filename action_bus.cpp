#include "action_bus.h"
#include "hex.h"
#include "misc.h"
#include "stage.h"

ActionBus::ActionBus(Table *tbl, VECTOR(pair_t) &data) {
    lineno = data.size ? data[0].key.lineno : -1;
    for (auto &kv : data) {
        if (!CHECKTYPE2(kv.key, tINT, tRANGE)) continue;
        if (!CHECKTYPE2M(kv.value, tSTR, tCMD, "field name or slice")) continue;
        const char *name = kv.value.s;
        unsigned off = 0, sz = 0;
        if (kv.value.type == tCMD) {
            assert(kv.value.vec.size > 0 && kv.value[0].type == tSTR);
            if (kv.value == "hash_dist") {
                if (!CHECKTYPE(kv.value[1], tINT))
                    continue;
                name = kv.value[0].s;
            } else {
                if (!PCHECKTYPEM(kv.value.vec.size == 2, kv.value[1], tRANGE,
                                 "field name or slice"))
                    continue;
                if ((kv.value[1].lo & 7) != 0 || (kv.value[1].hi & 7) != 7) {
                    error(kv.value.lineno, "Slice must be byte slice");
                    continue; }
                name = kv.value[0].s;
                off = kv.value[1].lo;
                sz = kv.value[1].hi - kv.value[1].lo + 1; } }
        Table::Format::Field *f = tbl->lookup_field(name, "*");
        Source src;
        const char *p = name-1;
        while (!f && (p = strchr(p+1, '.')))
            f = tbl->lookup_field(p+1, std::string(name, p-name));
        if (!f) {
            if (tbl->table_type() == Table::ACTION) {
                error(kv.value.lineno, "No field %s in format", name);
                continue;
            } else if (kv.value == "meter") {
                src = Source(MeterBus);
                // FIXME -- meter color could be ORed into any byte of the immediate?
                if (!sz) off = 24, sz = 8;
            } else if (kv.value == "stateful_alu") {
                src = Source(MeterBus);
                // FIXME -- should be getting the size from the attached stateful table,
                // FIXME -- but that would have to wait until pass1.
                // if (!sz) sz = 32;
            } else if (kv.value.type == tCMD && kv.value == "hash_dist") {
                if (auto hd = tbl->find_hash_dist(kv.value[1].i))
                    src = Source(hd);
                else {
                    error(kv.value.lineno, "No hash_dist %d in table %s", kv.value[1].i,
                          tbl->name());
                    continue; }
                sz = 16;
                for (int i = 2; i < kv.value.vec.size; ++i) {
                    if (kv.value[i] == "lo" || "low") {
                        src.hd->xbar_use |= HashDistribution::IMMEDIATE_LOW;
                    } else if (kv.value[i] == "hi" || "high") {
                        src.hd->xbar_use |= HashDistribution::IMMEDIATE_HIGH;
                        off += 16;
                    } else if (kv.value[i].type == tRANGE) {
                        if ((kv.value[i].lo & 7) != 0 || (kv.value[i].hi & 7) != 7)
                            error(kv.value.lineno, "Slice must be byte slice");
                        off += kv.value[i].lo;
                        sz = kv.value[1].hi - kv.value[1].lo + 1;
                    } else {
                        error(kv.value[i].lineno, "Unexpected hash_dist %s",
                              value_desc(kv.value[i]));
                        break; } }
            } else if (tbl->format) {
                error(kv.value.lineno, "No field %s in format", name);
                continue; }
        } else {
            src = Source(f);
            if (!sz) sz = f->size;
            if (off + sz > f->size)
                error(kv.value.lineno, "Invalid slice of %d bit field %s", f->size, name); }
        unsigned idx = kv.key.i;
        if (kv.key.type == tRANGE) {
            idx = kv.key.lo;
            unsigned size = (kv.key.hi-idx+1) * 8;
            if (!sz) sz = size;
            if (f && size != f->size) {
                error(kv.key.lineno, "Byte range doesn't match size %d of %s",
                      f->size, name);
                continue; }
        } else if (!sz)
            sz = idx < ACTION_DATA_8B_SLOTS ? 8 :
                 idx < ACTION_DATA_8B_SLOTS + 2*ACTION_DATA_16B_SLOTS ? 16 : 32;
        if (idx >= ACTION_DATA_BUS_BYTES) {
            error(kv.key.lineno, "Action bus index out of range");
            continue; }
        if (by_byte.count(idx)) {
            error(kv.key.lineno, "Multiple action bus entries at %d", idx);
            continue; }
        by_byte.emplace(idx, Slot(name, idx, sz, src, off));
        tbl->apply_to_field(name, [](Table::Format::Field *f){
            f->flags |= Table::Format::Field::USED_IMMED; });
    }
}

void ActionBus::pass1(Table *tbl) {
    LOG1("ActionBus::pass1(" << tbl->name() << ")");
    if (lineno < 0)
        lineno = tbl->format && tbl->format->lineno >= 0 ? tbl->format->lineno : tbl->lineno;
    Slot *use[ACTION_DATA_BUS_SLOTS] = { 0 };
    for (auto &slot : Values(by_byte)) {
        int slotno = Stage::action_bus_slot_map[slot.byte];
        for (unsigned byte = slot.byte; byte < slot.byte + slot.size/8U;
             byte += Stage::action_bus_slot_size[slotno++]/8U)
        {
            if (slotno >= ACTION_DATA_BUS_SLOTS) {
                error(lineno, "%s extends past the end of the actions bus",
                      slot.name.c_str());
                break; }
            if (tbl->stage->action_bus_use[slotno]) {
                if (tbl->stage->action_bus_use[slotno] != tbl)
                    error(lineno, "Action bus byte %d set in table %s and table %s", byte,
                          tbl->name(), tbl->stage->action_bus_use[slotno]->name());
                else {
                    assert(!slot.data.empty() && !use[slotno]->data.empty());
                    auto nsrc = slot.data.begin()->first;
                    unsigned nstart = 8*(byte - slot.byte);
                    if (nsrc.type == Source::Field)
                        nstart = nsrc.field->bit(nstart);
                    auto osrc = use[slotno]->data.begin()->first;
                    unsigned ostart = 8*(byte - use[slotno]->byte);
                    if (osrc.type == Source::Field)
                        ostart = osrc.field->bit(ostart);
                    if (nstart != ostart)
                        error(lineno, "Action bus byte %d used inconsistently for fields %s and "
                              "%s in table %s", byte, use[slotno]->name.c_str(),
                              slot.name.c_str(), tbl->name());
                    continue; } }
            tbl->stage->action_bus_use[slotno] = tbl;
            use[slotno] = &slot; } }
}

void ActionBus::need_alloc(Table *tbl, Table::Format::Field *f, unsigned off, unsigned size) {
    LOG3("need_alloc " << tbl->find_field(f) << " off=" << off << " size=0x" << hex(size));
    need_place[f][off] |= size;
}
void ActionBus::need_alloc(Table *tbl, HashDistribution *hd, unsigned off, unsigned size) {
    LOG3("need_alloc hash_dist " << hd->id << " off=" << off << " size=0x" << hex(size));
    need_place[hd][off] |= size;
}

static int find_free(Table *tbl, int min, int max, int step, int bytes) {
    int avail;
    LOG4("find_free(" << min << ", " << max << ", " << step << ", " << bytes << ")");
    for (int i = min; i + bytes - 1 <= max; i += step) {
        bool inuse = false;
        if (tbl->stage->action_bus_use[Stage::action_bus_slot_map[i]])
            inuse = true;
        /* FIXME -- this is a hack and probably incorrect -- need to figure out when an
         * allocation is going to copy adjacent data into adjacent slots and do the right
         * thing (use it if it is the right data, or use a different slot) */
        for (int j = i & -step; j < (i & -step) + step; ++j)
            if (tbl->stage->action_bus_use[Stage::action_bus_slot_map[j]] &&
                tbl->stage->action_bus_use[Stage::action_bus_slot_map[j]] != tbl)
                inuse = true;
        if (inuse) continue;
        for (avail = 1; avail < bytes; avail++)
            if (tbl->stage->action_bus_use[Stage::action_bus_slot_map[i+avail]])
                break;
        if (avail >= bytes)
            return i; }
    return -1;
}

int ActionBus::find_merge(int offset, int bytes, int use) {
    for (auto &alloc : by_byte) {
        if (use & 1) {
            if (alloc.first >= 32) break;
        } else if (use & 2) {
            if (alloc.first < 32) continue;
            if (alloc.first >= 96) break; }
        int slot = Stage::action_bus_slot_map[alloc.first];
        int slotsize = Stage::action_bus_slot_size[slot];
        int slotbyte = alloc.first & ~(slotsize/8U - 1);
        for (auto &d : alloc.second.data) {
            int slotoffset = d.second;
            if (d.first.type == Source::Field)
                slotoffset = d.first.field->bit(d.second);
            slotoffset &= ~(slotsize - 1);
            if (offset >= slotoffset && offset + bytes*8 <= slotoffset + slotsize)
                return slotbyte + (offset - slotoffset)/8U; } }
    return -1;
}

void ActionBus::do_alloc(Table *tbl, Source src, unsigned use, int lobyte,
                         int bytes, unsigned offset) {
    auto name = src.toString(tbl);
    LOG2("putting " << name << '(' << offset << ".." << (offset + bytes*8 - 1) <<
         ")[" << (lobyte*8) << ".." << ((lobyte+bytes)*8 - 1) << "] at action_bus " << use);
    while (bytes > 0) {
        int slot = Stage::action_bus_slot_map[use];
        int slotsize = Stage::action_bus_slot_size[slot];
        assert(!tbl->stage->action_bus_use[slot] || tbl->stage->action_bus_use[slot] == tbl);
        tbl->stage->action_bus_use[slot] = tbl;
        Slot &sl = by_byte.emplace(use, Slot(name, use, bytes*8U)).first->second;
        if (sl.size < bytes*8U) sl.size = bytes*8U;
        sl.data.emplace(src, offset);
        offset += slotsize;
        bytes -= slotsize/8U;
        use += slotsize/8U; }
}

static unsigned size_masks[8] = { 7, 7, 15, 15, 31, 31, 31, 31 };

void ActionBus::alloc_field(Table *tbl, Source src, unsigned offset, unsigned sizes_needed) {
    bool is_action_data = dynamic_cast<ActionTable *>(tbl) != nullptr;
    int immed_offset = tbl->format && tbl->format->immed ? tbl->format->immed->bit(0) : 0;
    assert(immed_offset == 0 || !is_action_data);
    int lo, hi, use;
    if (src.type == Source::Field) {
        lo = (src.field->bit(offset) - immed_offset) % 128U;
        hi = src.field->bit(src.field->size) - 1 - immed_offset;
    } else {
        lo = offset;
        hi = lo | size_masks[sizes_needed]; }
    if (lo/32U != hi/32U) {
        /* Can't go across 32-bit boundary so chop it down as needed */
        hi = lo|31U; }
    int bytes = hi/8U - lo/8U + 1;
    int step = lo < 32 && is_action_data ? 2 : lo < 64 ? 4 : 8;
    if (sizes_needed & 1) {
        /* need 8-bit */
        if ((lo % 8U) && (lo/8U != hi/8U)) {
            error(lineno, "%s not correctly aligned for 8-bit use on "
                  "action bus", src.toString(tbl).c_str());
            return; }
        unsigned start = (lo/8U) % step;
        if (!(sizes_needed & 4)) bytes = 1;
        if ((use = find_merge(lo, bytes, 1)) >= 0 ||
            (use = find_free(tbl, start, 31, step, bytes)) >= 0)
            do_alloc(tbl, src, use, lo/8U, bytes, offset); }
    step = lo < 64 ? 4 : 8;
    if (sizes_needed & 2) {
        /* need 16-bit */
        if (lo % 16U) {
            if (lo/16U != hi/16U) {
                error(lineno, "%s not correctly aligned for 16-bit use "
                      "on action bus", src.toString(tbl).c_str());
                return; }
            if ((use = find_merge(lo, bytes, 2)) >= 0) {
                do_alloc(tbl, src, use, lo/8U, bytes, offset);
                return; } }
        if (!(sizes_needed & 4) && bytes > 2) bytes = 2;
        unsigned start = 32 + (lo/8U) % step;
        if ((use = find_merge(lo, bytes, 2)) >= 0 ||
            (use = find_free(tbl, start, 63, step, bytes)) >= 0 ||
            (use = find_free(tbl, start+32, 95, 8, bytes)) >= 0)
            do_alloc(tbl, src, use, lo/8U, bytes, offset); }
    if (sizes_needed == 4) {
        /* need only 32-bit */
        unsigned odd = (lo/8U) & (4 & step);
        unsigned start = (lo/8U) % step;
        if (lo % 32U) {
            if ((use = find_merge(lo, bytes, 4)) >= 0) {
                do_alloc(tbl, src, use, lo/8U, bytes, 0);
                return; } }
        if ((use = find_merge(lo, bytes, 4)) >= 0 ||
            (use = find_free(tbl, 96+start+odd, 127, 8, bytes)) >= 0 ||
            (use = find_free(tbl, 64+start+odd, 95, 8, bytes)) >= 0 ||
            (use = find_free(tbl, 32+start, 63, step, bytes)) >= 0 ||
            (use = find_free(tbl, 0+start, 31, step, bytes)) >= 0)
            do_alloc(tbl, src, use, lo/8U, bytes, offset); }
}


void ActionBus::pass2(Table *tbl) {
    bool is_action_data = dynamic_cast<ActionTable *>(tbl) != nullptr;
    LOG1("ActionBus::pass2(" << tbl->name() << ") " << (is_action_data ? "[action]" : "[immed]"));
    for (auto &d : need_place)
        for (auto &bits : d.second)
            alloc_field(tbl, d.first, bits.first, bits.second);
}

static int slot_sizes[] = {
    5,  /* 8-bit or 32-bit */
    6,  /* 16-bit or 32-bit */
    6,  /* 16-bit or 32-bit */
    4   /* 32-bit only */
};

int ActionBus::find(Table::Format::Field *f, int off, int size /* in bytes */) {
    for (auto &slot : by_byte) {
        if (!slot.second.data.count(f)) continue;
        if ((int)slot.second.data[f] > off) continue;
        /* FIXME -- off < f->size check is wrong, but needed for old compiler broken asm */
        /* FIXME -- see test/action_bus1.p4 */
        if (off < (int)f->size && off - slot.second.data[f] >= slot.second.size) continue;
        if (!(size & slot_sizes[slot.first/32U])) continue;
        return slot.first + (off - slot.second.data[f])/8U; }
    return -1;
}
int ActionBus::find(const char *name, int off, int size, int *len) {
    for (auto &slot : by_byte)
        if (slot.second.name == name) {
            if (!(size & slot_sizes[slot.first/32U])) continue;
            if (len) *len = slot.second.size;
            return slot.first + off/8; }
    return -1;
}

int ActionBus::find(HashDistribution *hd, int off, int size) {
    for (auto &slot : by_byte)
        if (slot.second.data.count(hd)) {
            if (!(size & slot_sizes[slot.first/32U])) continue;
            // if (len) *len = slot.second.size;
            return slot.first + off/8; }
    return -1;
}

void ActionBus::write_action_regs(Table *tbl, unsigned home_row, unsigned action_slice) {
    LOG2("--- ActionBus write_action_regs(" << tbl->name() << ", " << home_row << ", " <<
         action_slice << ")");
    auto &action_hv_xbar = tbl->stage->regs.rams.array.row[home_row/2].action_hv_xbar;
    unsigned side = home_row%2;  /* 0 == left,  1 == right */
    for (auto &el : by_byte) {
        unsigned byte = el.first;
        assert(byte == el.second.byte);
        assert(el.second.data.begin()->first.type == Source::Field);
        Table::Format::Field *f = el.second.data.begin()->first.field;
        if ((f->bit(el.second.data.begin()->second) >> 7) != action_slice)
            continue;
        unsigned slot = Stage::action_bus_slot_map[byte];
        unsigned bit = f->bit(el.second.data.begin()->second) & 0x7f;
        unsigned size = std::min(el.second.size, f->size - el.second.data.begin()->second);
        LOG3("    byte " << byte << " (slot " << slot << "): field " << tbl->find_field(f) <<
             "(" << el.second.data.begin()->second << ".." << (el.second.data.begin()->second + size - 1) << ")" <<
             " [" << bit << ".." << (bit+size-1) << "]");
        if (bit + size > 128) {
            error(lineno, "Action bus setup can't deal with field %s split across "
                  "SRAM rows", el.second.name.c_str());
            continue; }
        unsigned bytemask = (1U << ((size+7)/8U)) - 1;
        switch (Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned sbyte = bit/8; sbyte <= (bit+size-1)/8; sbyte++, byte++, slot++) {
                unsigned code, mask;
                switch (sbyte >> 2) {
                case 0: code = sbyte>>1; mask = 1; break;
                case 1: code = 2; mask = 3; break;
                case 2: case 3: code = 3; mask = 7; break;
                default: assert(0); }
                if ((sbyte^byte) & mask) {
                    error(lineno, "Can't put field %s into byte %d on action xbar",
                          el.second.name.c_str(), byte);
                    break; }
                auto &ctl = action_hv_xbar.action_hv_ixbar_ctl_byte[side];
                switch (code) {
                case 0:
                    ctl.action_hv_ixbar_ctl_byte_1to0_ctl = slot/2;
                    ctl.action_hv_ixbar_ctl_byte_1to0_enable = 1;
                    break;
                case 1:
                    ctl.action_hv_ixbar_ctl_byte_3to2_ctl = slot/2;
                    ctl.action_hv_ixbar_ctl_byte_3to2_enable = 1;
                    break;
                case 2:
                    ctl.action_hv_ixbar_ctl_byte_7to4_ctl = slot/4;
                    ctl.action_hv_ixbar_ctl_byte_7to4_enable = 1;
                    break;
                case 3:
                    ctl.action_hv_ixbar_ctl_byte_15to8_ctl = slot/8;
                    ctl.action_hv_ixbar_ctl_byte_15to8_enable = 1;
                    break; }
                if (!(bytemask & 1))
                    WARNING(SrcInfo(lineno) << ": putting " << el.second.name << " on action bus "
                            "byte " << byte << " even though bit in bytemask is not set");
                action_hv_xbar.action_hv_ixbar_input_bytemask[side] |= 1 << sbyte;
                bytemask >>= 1; }
            break;
        case 16:
            byte &= ~1;
            slot -= ACTION_DATA_8B_SLOTS;
            bytemask <<= ((bit/8) & 1);
            for (unsigned word = bit/16; word <= (bit+size-1)/16; word++, byte+=2, slot++) {
                unsigned code, mask;
                switch (word >> 1) {
                case 0: code = 1; mask = 3; break;
                case 1: code = 2; mask = 3; break;
                case 2: case 3: code = 3; mask = 7; break;
                default: assert(0); }
                if (((word << 1)^byte) & mask) {
                    error(lineno, "Can't put field %s into byte %d on action xbar",
                          el.second.name.c_str(), byte);
                    break; }
                auto &ctl = action_hv_xbar.action_hv_ixbar_ctl_halfword[slot/8][side];
                unsigned subslot = slot%8U;
                switch (code) {
                case 1:
                    ctl.action_hv_ixbar_ctl_halfword_3to0_ctl = subslot/2;
                    ctl.action_hv_ixbar_ctl_halfword_3to0_enable = 1;
                    break;
                case 2:
                    ctl.action_hv_ixbar_ctl_halfword_7to4_ctl = subslot/2;
                    ctl.action_hv_ixbar_ctl_halfword_7to4_enable = 1;
                    break;
                case 3:
                    ctl.action_hv_ixbar_ctl_halfword_15to8_ctl = subslot/4;
                    ctl.action_hv_ixbar_ctl_halfword_15to8_enable = 1;
                    break; }
                action_hv_xbar.action_hv_ixbar_input_bytemask[side] |= (bytemask&3) << (word*2);
                bytemask >>= 2; }
            break;
        case 32: {
            byte &= ~3;
            slot -= ACTION_DATA_8B_SLOTS + ACTION_DATA_16B_SLOTS;
            unsigned word = bit/32;
            unsigned code = 1 + word/2;
            bit %= 32;
            bytemask <<= bit/8;
            if (((word << 2)^byte) & 7) {
                error(lineno, "Can't put field %s into byte %d on action xbar",
                      el.second.name.c_str(), byte);
                break; }
            auto &ctl = action_hv_xbar.action_hv_ixbar_ctl_word[slot/4][side];
            slot %= 4U;
            switch (code) {
            case 1:
                ctl.action_hv_ixbar_ctl_word_7to0_ctl = slot/2;
                ctl.action_hv_ixbar_ctl_word_7to0_enable = 1;
                break;
            case 2:
                ctl.action_hv_ixbar_ctl_word_15to8_ctl = slot/2;
                ctl.action_hv_ixbar_ctl_word_15to8_enable = 1;
                break; }
            action_hv_xbar.action_hv_ixbar_input_bytemask[side] |= (bytemask&15) << (word*4);
            bytemask >>= 4;
            break; }
        default:
            assert(0); }
        if (bytemask)
            WARNING(SrcInfo(lineno) << ": excess bits " << hex(bytemask) <<
                    " set in bytemask for " << el.second.name);
    }
}

void ActionBus::write_immed_regs(Table *tbl) {
    LOG2("--- ActionBus write_immed_regs(" << tbl->name() << ")");
    auto &adrdist = tbl->stage->regs.rams.match.adrdist;
    int tid = tbl->logical_id;
    for (auto &f : by_byte) {
        int slot = Stage::action_bus_slot_map[f.first];
        unsigned off = 0;
        if (!f.second.data.empty()) {
            off = f.second.data.begin()->second;
            if (f.second.data.begin()->first.type == Source::Field) {
                off += f.second.data.begin()->first.field->bits[0].lo;
                if (tbl->format) off -= tbl->format->immed->bits[0].lo; } }
        unsigned size = f.second.size;
        switch(Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned b = off/8; b <= (off + size - 1)/8; b++) {
                assert((b&3) == (slot&3));
                adrdist.immediate_data_8b_enable[tid/8] |= 1U << ((tid&7)*4 + b);
                // FIXME -- we write these ctl regs twice if we use both bytes in a pair
                setup_muxctl(adrdist.immediate_data_8b_ixbar_ctl[tid*2 + b/2], slot++/4); }
            break;
        case 16:
            slot -= ACTION_DATA_8B_SLOTS;
            for (unsigned w = off/16; w <= (off + size - 1)/16; w++) {
                assert((w&1) == (slot&1));
                setup_muxctl(adrdist.immediate_data_16b_ixbar_ctl[tid*2 + w], slot++/2); }
            break;
        case 32:
            slot -= ACTION_DATA_8B_SLOTS + ACTION_DATA_16B_SLOTS;
            setup_muxctl(adrdist.immediate_data_32b_ixbar_ctl[tid], slot);
            break;
        default:
            assert(0); } }
}

ActionBus::MeterBus_t ActionBus::MeterBus;

std::string ActionBus::Source::toString(Table *tbl) const {
    std::stringstream tmp;
    switch (type) {
    case None:
        return "<none source>";
    case Field:
        return tbl->find_field(field);
    case HashDist:
        tmp << "hash_dist " << hd->id;
        return tmp.str();
    case MeterBus:
        return "meter_bus";
    default:
        tmp << "<invalid source " << int(type) << ">";
        return tmp.str(); }
}
