#include <config.h>

#include "action_bus.h"
#include "hex.h"
#include "misc.h"
#include "stage.h"

std::ostream &operator<<(std::ostream &out, const ActionBus::Source &src) {
    const char *sep = "";
    switch (src.type) {
    case ActionBus::Source::None:
        out << "None";
        break;
    case ActionBus::Source::Field:
        out << "Field(";
        for (auto &range : src.field->bits) {
            out << sep << range.lo << ".." << range.hi;
            sep = ", "; }
        out << ")";
        break;
    case ActionBus::Source::HashDist:
        out << "HashDist(" << src.hd->hash_group << ", " << src.hd->id << ")";
        break;
    case ActionBus::Source::TableOutput:
        out << "TableOutput(" << (src.table ? src.table->name() : "0") << ")";
        break;
    case ActionBus::Source::TableRefOutput:
        out << "TableRefOutput(" << (src.table_ref ? src.table_ref->name : "0") << ")";
        break;
    default:
        out << "<invalid type 0x" << hex(src.type) << ">";
        break;
    }
    return out;
}

/* identifes which bytes on the action bus are tied together in the hv_xbar input,
 * so must be routed together.  The second table here is basically just bitcount of
 * masks in the first table. */
static std::array<std::array<unsigned, 16>, ACTION_HV_XBAR_SLICES> action_hv_slice_byte_groups = {{
    { 0x3, 0x3, 0xc, 0xc, 0xf0, 0xf0, 0xf0, 0xf0,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xf, 0xf, 0xf, 0xf, 0xf0, 0xf0, 0xf0, 0xf0,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xf, 0xf, 0xf, 0xf, 0xf0, 0xf0, 0xf0, 0xf0,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xf, 0xf, 0xf, 0xf, 0xf0, 0xf0, 0xf0, 0xf0,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
    { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00, 0xff00 },
}};

static std::array<std::array<int, 16>, ACTION_HV_XBAR_SLICES> action_hv_slice_group_align = {{
    { 2, 2, 2, 2, 4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 4, 4, 4, 4, 4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 4, 4, 4, 4, 4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 4, 4, 4, 4, 4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 },
    { 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 }
}};

ActionBus::ActionBus(Table *tbl, VECTOR(pair_t) &data) {
    lineno = data.size ? data[0].key.lineno : -1;
    for (auto &kv : data) {
        if (!CHECKTYPE2(kv.key, tINT, tRANGE)) continue;
        if (!CHECKTYPE2M(kv.value, tSTR, tCMD, "field name or slice")) continue;
        const char *name = kv.value.s;
        value_t *name_ref = &kv.value;
        unsigned off = 0, sz = 0;
        if (kv.value.type == tCMD) {
            assert(kv.value.vec.size > 0 && kv.value[0].type == tSTR);
            if (kv.value == "hash_dist") {
                if (!CHECKTYPE(kv.value[1], tINT))
                    continue;
                name = kv.value[0].s;
                name_ref = nullptr;
            } else {
                if (!PCHECKTYPEM(kv.value.vec.size == 2, kv.value[1], tRANGE,
                                 "field name or slice"))
                    continue;
                //if ((kv.value[1].lo & 7) != 0 || (kv.value[1].hi & 7) != 7) {
                //    error(kv.value.lineno, "Slice must be byte slice");
                //    continue; }
                name = kv.value[0].s;
                name_ref = &kv.value[0];
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
            } else if (name_ref) {
                src = Source(new Table::Ref(*name_ref));
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
            //if (f && size != f->size) {
            //    error(kv.key.lineno, "Byte range doesn't match size %d of %s",
            //          f->size, name);
            //    continue; }
        } else if (!sz)
            sz = idx < ACTION_DATA_8B_SLOTS ? 8 :
                 idx < ACTION_DATA_8B_SLOTS + 2*ACTION_DATA_16B_SLOTS ? 16 : 32;
        if (idx >= ACTION_DATA_BUS_BYTES) {
            error(kv.key.lineno, "Action bus index out of range");
            continue; }
        if (by_byte.count(idx)) {
            auto &slot = by_byte.at(idx);
            if (sz > slot.size) {
                slot.name = name;
                slot.size = sz; }
            slot.data.emplace(src, off);
        } else {
            by_byte.emplace(idx, Slot(name, idx, sz, src, off)); }
        tbl->apply_to_field(name, [](Table::Format::Field *f){
            f->flags |= Table::Format::Field::USED_IMMED; });
    }
}

unsigned ActionBus::Slot::lo(Table *tbl) const {
    int rv = -1;
    int immed_offset = tbl->format && tbl->format->immed ? tbl->format->immed->bit(0) : 0;
    for (auto &src : data) {
        int off = src.second;
        if (src.first.type == Source::Field)
            off += src.first.field->bit(0) - immed_offset;
        assert(rv < 0 || rv == off);
        rv = off; }
    assert(rv >= 0);
    return rv;
}

bool ActionBus::compatible(const Source &a, unsigned a_off, const Source &b, unsigned b_off) {
    if (a.type != b.type) return false;
    switch (a.type) {
    case Source::Field:
        return a.field->bit(a_off) == b.field->bit(b_off);
    case Source::HashDist:
        return a.hd->hash_group == b.hd->hash_group && a.hd->id == b.hd->id && a_off == b_off;
    case Source::TableOutput:
        return a.table == b.table;
    default:
        return false; }
}

void ActionBus::pass1(Table *tbl) {
    bool is_immed_data = dynamic_cast<MatchTable *>(tbl) != nullptr;
    LOG1("ActionBus::pass1(" << tbl->name() << ")" << (is_immed_data ? " [immed]" : ""));
    if (lineno < 0)
        lineno = tbl->format && tbl->format->lineno >= 0 ? tbl->format->lineno : tbl->lineno;
    Slot *use[ACTION_DATA_BUS_SLOTS] = { 0 };
    for (auto &slot : Values(by_byte)) {
        bool ok = true;
        for (auto it = slot.data.begin(); it != slot.data.end();) {
            if (it->first.type == Source::TableRefOutput) {
                // Remove all TableRefOutputs and replace with TableOutputs
                if (it->first.table_ref) {
                    if (*it->first.table_ref)
                        slot.data[Source(*it->first.table_ref)] = it->second;
                    else {
                        error(it->first.table_ref->lineno, "No format field or table named %s",
                              it->first.table_ref->name.c_str());
                        ok = false; }
                } else {
                    auto att = tbl->get_attached();
                    if (!att || att->meter.empty())
                        error(lineno, "No meter table attached to %s", tbl->name());
                    else if (att->meter.size() > 1)
                        error(lineno, "Multiple meter tables attached to %s", tbl->name());
                    else
                        slot.data[Source(att->meter.at(0))] = it->second; }
                it = slot.data.erase(it);
            } else {
                ++it; } }
        if (!ok) continue;
        auto first = slot.data.begin();
        if (first != slot.data.end())
            for (auto it = next(first); it != slot.data.end(); ++it)
                if (!compatible(first->first, first->second, it->first, it->second))
                    error(lineno, "Incompatible action bus entries at offset %d", slot.byte);
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
                    unsigned noff = slot.data.begin()->second;
                    unsigned nstart = 8*(byte - slot.byte) + noff;
                    if (nsrc.type == Source::Field)
                        nstart = nsrc.field->bit(nstart);
                    auto osrc = use[slotno]->data.begin()->first;
                    unsigned ooff = use[slotno]->data.begin()->second;
                    unsigned ostart = 8*(byte - use[slotno]->byte) + ooff;
                    if (osrc.type == Source::Field) {
                        if (ostart < osrc.field->size)
                            ostart = osrc.field->bit(ostart);
                        else
                            ostart += osrc.field->bit(0); }
                    if (ostart != nstart)
                        error(lineno, "Action bus byte %d used inconsistently for fields %s and "
                              "%s in table %s", byte, use[slotno]->name.c_str(),
                              slot.name.c_str(), tbl->name()); }
            } else {
                tbl->stage->action_bus_use[slotno] = tbl;
                use[slotno] = &slot; }
            unsigned hi = slot.lo(tbl) + slot.size - 1;
            if (action_hv_slice_use.size() <= hi/128U)
                action_hv_slice_use.resize(hi/128U + 1);
            auto &hv_groups = action_hv_slice_byte_groups.at(slot.byte/16);
            for (unsigned byte = slot.lo(tbl)/8U; byte <= hi/8U; ++byte) {
                byte_use[byte] = 1;
                action_hv_slice_use.at(byte/16).at(slot.byte/16) |= hv_groups.at(byte%16); } } }
}

void ActionBus::need_alloc(Table *tbl, Table::Format::Field *f, unsigned off, unsigned size) {
    LOG3("need_alloc " << tbl->find_field(f) << " off=" << off << " size=0x" << hex(size));
    need_place[f][off] |= size;
    int immed_offset = tbl->format && tbl->format->immed ? tbl->format->immed->bit(0) : 0;
    byte_use.setrange((f->bit(0) - immed_offset + off)/8U, size);
}
void ActionBus::need_alloc(Table *tbl, HashDistribution *hd, unsigned off, unsigned size) {
    LOG3("need_alloc hash_dist " << hd->id << " off=" << off << " size=0x" << hex(size));
    need_place[hd][off] |= size;
    byte_use.setrange(off/8U, size);
}
void ActionBus::need_alloc(Table *tbl, Table *attached, unsigned off, unsigned size) {
    LOG3("need_alloc table " << attached->name() << " off=" << off << " size=0x" << hex(size));
    need_place[attached][off] |= size;
    byte_use.setrange(off/8U, size);
}

/**
 * find_free -- find a free slot on the action output bus for some data.  Looks through bytes
 * in the range min..max for a free space where we can put 'bytes' bytes from an action
 * input bus starting at 'lobyte'.  'step' is an optimization to only check every step bytes
 * as we know alignment restrictions mean those are the only possible aligned spots
 */
int ActionBus::find_free(Table *tbl, int min, int max, int step, int lobyte, int bytes) {
    int avail;
    LOG4("find_free(" << min << ", " << max << ", " << step << ", " << lobyte <<
         ", " << bytes << ")");
    for (int i = min; i + bytes - 1 <= max; i += step) {
        unsigned hv_slice = i / ACTION_HV_XBAR_SLICE_SIZE;
        auto &hv_groups = action_hv_slice_byte_groups.at(hv_slice);
        int mask1 = action_hv_slice_group_align.at(hv_slice).at(lobyte % 16U) - 1;
        int mask2 = action_hv_slice_group_align.at(hv_slice).at((lobyte + bytes - 1)% 16U) - 1;
        if ((i ^ lobyte) & mask1)
            continue;  // misaligned
        bool inuse = false;
        for (int byte = lobyte & ~mask1; byte <= ((lobyte+bytes-1) | mask2); ++byte) {
            if (!byte_use[byte]) continue;
            if (action_hv_slice_use.size() <= byte/16U)
                action_hv_slice_use.resize(byte/16U + 1);
            if (action_hv_slice_use.at(byte/16U).at(hv_slice) & hv_groups.at(byte%16U)) {
                LOG5("  input byte " << byte << " in use for hv_slice " << hv_slice);
                inuse = true;
                break; } }
        if (inuse) {
            // skip up to next hv_slice
            while ((i + step)/ACTION_HV_XBAR_SLICE_SIZE == hv_slice)
                i += step;
            continue; }
        for (int byte = i & ~mask1; byte <= ((i + bytes - 1) | mask2); ++byte)
            if (tbl->stage->action_bus_use[Stage::action_bus_slot_map[byte]]) {
                LOG5("  output byte " << byte << " in use by " <<
                     tbl->stage->action_bus_use[Stage::action_bus_slot_map[byte]]->name());
                inuse = true;
                break; }
        if (inuse) continue;
        for (avail = 1; avail < bytes; avail++)
            if (tbl->stage->action_bus_use[Stage::action_bus_slot_map[i+avail]])
                break;
        if (avail >= bytes)
            return i; }
    return -1;
}

/**
 * find_merge -- find any adjacent/overlapping data on the action input bus that means the
 * data at 'offset' actually already on the action output bus
 *   offset     offset (in bits) on the action input bus of the data we're interested in
 *   bytes      how many bytes of data on the action input bus
 *   use        bitmask of the sizes of phv that need to access this on the action output bus
 */
int ActionBus::find_merge(Table *tbl, int offset, int bytes, int use) {
    LOG4("find_merge(" << offset << ", " << bytes << ", " << use << ")");
    for (auto &alloc : by_byte) {
        if (use & 1) {
            if (alloc.first >= 32) break;
        } else if (use & 2) {
            if (alloc.first < 32) continue;
            if (alloc.first >= 96) break; }
        if (alloc.second.is_table_output()) continue;  // can't merge table output with immediate
        int inbyte = alloc.second.lo(tbl) / 8U;
        int align = action_hv_slice_group_align.at(alloc.first/16U).at(inbyte%16U);
        int outbyte = alloc.first & ~(align-1);
        inbyte &= ~(align-1);
        if (offset >= inbyte*8 && offset + bytes*8 <= (inbyte + align)*8)
            return outbyte + offset/8 - inbyte; }
    return -1;
}

void ActionBus::do_alloc(Table *tbl, Source src, unsigned use, int lobyte,
                         int bytes, unsigned offset) {
    auto name = src.toString(tbl);
    LOG2("putting " << name << '(' << offset << ".." << (offset + bytes*8 - 1) <<
         ")[" << (lobyte*8) << ".." << ((lobyte+bytes)*8 - 1) << "] at action_bus " << use);
    unsigned hv_slice = use / ACTION_HV_XBAR_SLICE_SIZE;
    auto &hv_groups = action_hv_slice_byte_groups.at(hv_slice);
    for (unsigned byte = lobyte; byte < unsigned(lobyte+bytes); ++byte) {
        if (action_hv_slice_use.size() <= byte/16)
            action_hv_slice_use.resize(byte/16 + 1);
        action_hv_slice_use.at(byte/16).at(hv_slice) |= hv_groups.at(byte%16); }
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
    LOG4("alloc_field(" << src << ", " << offset << ", " << sizes_needed << ")");
    int lineno = this->lineno;
    bool is_action_data = dynamic_cast<ActionTable *>(tbl) != nullptr;
    int immed_offset = tbl->format && tbl->format->immed ? tbl->format->immed->bit(0) : 0;
    assert(immed_offset == 0 || !is_action_data);
    int lo, hi, use;
    bool can_merge = true;
    if (src.type == Source::Field) {
        lo = (src.field->bit(offset) - immed_offset) % 128U;
        hi = src.field->bit(src.field->size) - 1 - immed_offset;
        lineno = tbl->find_field_lineno(src.field);
    } else {
        if (src.type == Source::TableOutput)
            can_merge = false;
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
        if ((can_merge && (use = find_merge(tbl, lo, bytes, 1)) >= 0) ||
            (use = find_free(tbl, start, 31, step, lo/8U, bytes)) >= 0)
            do_alloc(tbl, src, use, lo/8U, bytes, offset);
        else
            error(lineno, "Can't allocate space on 8-bit part of action bus for %s",
                  src.toString(tbl).c_str()); }
    step = lo < 64 ? 4 : 8;
    if (sizes_needed & 2) {
        /* need 16-bit */
        if (lo % 16U) {
            if (lo/16U != hi/16U) {
                error(lineno, "%s not correctly aligned for 16-bit use "
                      "on action bus", src.toString(tbl).c_str());
                return; }
            if (can_merge && (use = find_merge(tbl, lo, bytes, 2)) >= 0) {
                do_alloc(tbl, src, use, lo/8U, bytes, offset);
                return; } }
        if (!(sizes_needed & 4) && bytes > 2) bytes = 2;
        unsigned start = 32 + (lo/8U) % step;
        if ((can_merge && (use = find_merge(tbl, lo, bytes, 2)) >= 0) ||
            (use = find_free(tbl, start, 63, step, lo/8U, bytes)) >= 0 ||
            (use = find_free(tbl, start+32, 95, 8, lo/8U, bytes)) >= 0)
            do_alloc(tbl, src, use, lo/8U, bytes, offset);
        else
            error(lineno, "Can't allocate space on 16-bit part of action bus for %s",
                  src.toString(tbl).c_str()); }
    if (sizes_needed == 4) {
        /* need only 32-bit */
        unsigned odd = (lo/8U) & (4 & step);
        unsigned start = (lo/8U) % step;
        if (lo % 32U) {
            if (can_merge && (use = find_merge(tbl, lo, bytes, 4)) >= 0) {
                do_alloc(tbl, src, use, lo/8U, bytes, 0);
                return; } }
        if ((can_merge && (use = find_merge(tbl, lo, bytes, 4)) >= 0) ||
            (use = find_free(tbl, 96+start+odd, 127, 8, lo/8U, bytes)) >= 0 ||
            (use = find_free(tbl, 64+start+odd, 95, 8, lo/8U, bytes)) >= 0 ||
            (use = find_free(tbl, 32+start, 63, step, lo/8U, bytes)) >= 0 ||
            (use = find_free(tbl, 0+start, 31, step, lo/8U, bytes)) >= 0)
            do_alloc(tbl, src, use, lo/8U, bytes, offset);
        else
            error(lineno, "Can't allocate space on action bus for %s",
                  src.toString(tbl).c_str()); }
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

template<class REGS> void ActionBus::write_action_regs(REGS &regs, Table *tbl,
                                                       unsigned home_row, unsigned action_slice) {
    LOG2("--- ActionBus write_action_regs(" << tbl->name() << ", " << home_row << ", " <<
         action_slice << ")");
    bool is_action_data = dynamic_cast<ActionTable *>(tbl) != nullptr;
    auto &action_hv_xbar = regs.rams.array.row[home_row/2].action_hv_xbar;
    unsigned side = home_row%2;  /* 0 == left,  1 == right */
    for (auto &el : by_byte) {
        if (!is_action_data && !el.second.is_table_output()) {
            // Nasty hack -- meter/stateful output uses the action bus on the meter row,
            // so we need this routine to set it up, but we only want to do it for the
            // meter bus output; the rest of this ActionBus is for immediate data (set
            // up by write_immed_regs below)
            continue; }
        unsigned byte = el.first;
        assert(byte == el.second.byte);
        unsigned slot = Stage::action_bus_slot_map[byte];
        unsigned bit, size;
        std::string srcname;
        auto data = el.second.data.begin();
        if (data->first.type == Source::Field) {
            auto f = data->first.field;
            if ((f->bit(data->second) >> 7) != action_slice)
                continue;
            bit = f->bit(data->second) & 0x7f;
            size = std::min(el.second.size, f->size - data->second);
            srcname = "field " + tbl->find_field(f);
        } else if (data->first.type == Source::TableOutput) {
            bit = data->second;
            size = el.second.size;
            srcname = "table " + data->first.table->name_;
        } else {
            // HashDist only works in write_immed_regs
            assert(0); }
        LOG3("    byte " << byte << " (slot " << slot << "): " << srcname <<
             " (" << data->second << ".." << (data->second + size - 1) << ")" <<
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
template void ActionBus::write_action_regs(Target::Tofino::mau_regs &, Table *, unsigned, unsigned);
#if HAVE_JBAY
template void ActionBus::write_action_regs(Target::JBay::mau_regs &, Table *, unsigned, unsigned);
#endif // HAVE_JBAY

template<class REGS> void ActionBus::write_immed_regs(REGS &regs, Table *tbl) {
    LOG2("--- ActionBus write_immed_regs(" << tbl->name() << ")");
    auto &adrdist = regs.rams.match.adrdist;
    int tid = tbl->logical_id;
    for (auto &f : by_byte) {
        if (f.second.is_table_output()) continue;
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
template void ActionBus::write_immed_regs(Target::Tofino::mau_regs &, Table *);
#if HAVE_JBAY
template void ActionBus::write_immed_regs(Target::JBay::mau_regs &, Table *);
#endif // HAVE_JBAY

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
    case TableOutput:
        return table->name();
    case TableRefOutput:
        tmp <<  "tableref ";
        if (table_ref) tmp << table_ref->name;
        else tmp << "(meter)";
        return tmp.str();
    default:
        tmp << "<invalid source " << int(type) << ">";
        return tmp.str(); }
}
