#include "action_bus.h"
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
            if (!PCHECKTYPEM(kv.value.vec.size == 2, kv.value[1], tRANGE, "field name or slice"))
                continue;
            if ((kv.value[1].lo & 7) != 0 || (kv.value[1].hi & 7) != 7) {
                error(kv.value.lineno, "Slice must be byte slice");
                continue; }
            name = kv.value[0].s;
            off = kv.value[1].lo >> 3;
            sz = (kv.value[1].hi - kv.value[1].lo + 1) >> 3; }
	Table::Format::Field *f = tbl->lookup_field(name, "*");
	if (!f && tbl->format) {
	    error(kv.value.lineno, "No field %s in format", name);
	    continue; }
        if (f && !sz) sz = f->size;
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
        if (getref(by_byte, idx)) {
            error(kv.key.lineno, "Multiple action bus entries at %d", idx);
            continue; }
        by_byte.emplace(idx, Slot{name, idx, sz, f, off});
	//by_name[name].push_back(&by_byte[idx]);
        tbl->apply_to_field(name, [](Table::Format::Field *f){
            f->flags |= Table::Format::Field::USED_IMMED; });
    }
}

void ActionBus::pass1(Table *tbl) {
    Slot *use[ACTION_DATA_BUS_SLOTS] = { 0 };
    for (auto &slot : Values(by_byte)) {
        int slotno = Stage::action_bus_slot_map[slot.byte];
        for (unsigned byte = slot.byte; byte < slot.byte + slot.size;
             byte += Stage::action_bus_slot_size[slotno++])
        {
            if (slotno >= ACTION_DATA_BUS_SLOTS) {
                error(lineno, "%s extends past the end of the actions bus",
                      slot.name.c_str());
                break; }
            if (tbl->stage->action_bus_use[slotno]) {
                if (tbl->stage->action_bus_use[slotno] != tbl)
                    error(lineno, "Action bus byte %d set in table %s and table %s", byte,
                          tbl->name(), tbl->stage->action_bus_use[slotno]->name());
                else if (slot.data->bit(8*(byte - slot.byte)) !=
                         use[slotno]->data->bit(8*(byte - use[slotno]->byte)))
                    error(lineno, "Action bus byte %d used inconsistently for fields %s and "
                          "%s in table %s", byte, use[slotno]->name.c_str(),
                          slot.name.c_str(), tbl->name());
                continue; }
            tbl->stage->action_bus_use[slotno] = tbl;
            use[slotno] = &slot; } }
}
void ActionBus::pass2(Table *tbl) {
    /* FIXME -- allocate action bus slots for things that need to be on the action bus
     * FIXME -- and aren't */
}

int ActionBus::find(Table::Format::Field *f, int off) {
    for (auto &slot : by_byte) {
        if (slot.second.data != f) continue;
        if ((int)slot.second.offset * 8 > off) continue;
        if (off/8 - slot.second.offset >= slot.second.size) continue;
        return slot.first + off/8 - slot.second.offset; }
    return -1;
}
int ActionBus::find(const char *name, int off, int *size) {
    for (auto &slot : by_byte)
        if (slot.second.name == name) {
            if (size) *size = slot.second.size;
            return slot.first + off/8 - slot.second.offset; }
    return -1;
}

void ActionBus::write_action_regs(Table *tbl, unsigned home_row, unsigned action_slice) {
    /* FIXME -- home_row is the wrong row to use for action_slice != 0 */
    auto &action_hv_xbar = tbl->stage->regs.rams.array.row[home_row/2].action_hv_xbar;
    unsigned side = home_row%2;  /* 0 == left,  1 == right */
    for (auto &el : by_byte) {
        unsigned byte = el.first;
        Table::Format::Field *f = el.second.data;
        if ((f->bits[0].lo >> 7) != action_slice)
            continue;
        unsigned bit = f->bits[0].lo & 0x7f;
        if (bit + f->size > 128) {
            error(lineno, "Action bus setup can't deal with field %s split across "
                  "SRAM rows", el.second.name.c_str());
            continue; }
        unsigned slot = Stage::action_bus_slot_map[byte];
        switch (Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned sbyte = bit/8; sbyte <= (bit+f->size-1)/8; sbyte++, byte++, slot++) {
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
                action_hv_xbar.action_hv_xbar_ctl_byte[side].set_subfield(code, slot*2, 2);
                action_hv_xbar.action_hv_xbar_ctl_byte_enable[side] |= 1 << slot; }
            break;
        case 16:
            slot -= ACTION_DATA_8B_SLOTS;
            for (unsigned word = bit/16; word <= (bit+f->size-1)/16; word++, byte+=2, slot++) {
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
                action_hv_xbar.action_hv_xbar_ctl_half[side][slot/4]
                        .set_subfield(code, (slot%4)*2, 2); }
            break;
        case 32: {
            slot -= ACTION_DATA_8B_SLOTS + ACTION_DATA_16B_SLOTS;
            unsigned word = bit/32;
            unsigned code = 1 + word/2;
            if (((word << 2)^byte) & 7)
                error(lineno, "Can't put field %s into byte %d on action xbar",
                      el.second.name.c_str(), byte);
            else
                action_hv_xbar.action_hv_xbar_ctl_word[side][slot/2]
                        .set_subfield(code, (slot%2)*2, 2);
            break; }
        default:
            assert(0); }
    }
}

void ActionBus::write_immed_regs(Table *tbl) {
    auto &adrdist = tbl->stage->regs.rams.match.adrdist;
    int tid = tbl->logical_id;
    for (auto &f : by_byte) {
        int slot = Stage::action_bus_slot_map[f.first];
        unsigned off = f.second.offset*8;
        if (f.second.data) off += f.second.data->bits[0].lo;
        if (tbl->format) off -= tbl->format->immed->bits[0].lo;
        unsigned size = f.second.size;
        switch(Stage::action_bus_slot_size[slot]) {
        case 8:
            for (unsigned b = off/8; b <= (off + size - 1)/8; b++) {
                assert((b&3) == (slot&3));
                adrdist.immediate_data_8b_enable[tid/8] |= 1U << ((tid&7)*4 + b);
                // FIXME -- we write these ctl regs twice if we use both nytes in a pair 
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

