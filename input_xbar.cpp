#include "input_xbar.h"
#include "log.h"
#include "stage.h"

InputXbar::InputXbar(Table *t, bool tern, VECTOR(pair_t) &data)
: table(t), ternary(tern), lineno(data[0].key.lineno)
{
    int numgroups = ternary ? 16 : 8;
    for (auto &kv : data) {
	if (!CHECKTYPEM(kv.key, tCMD, "group or hash descriptor"))
	    continue;
	if (kv.key[0] == "group") {
	    if (kv.key.vec.size != 2 || kv.key[1].type != tINT || kv.key[1].i > numgroups) {
		error(kv.key.lineno, "invalid group descriptor");
		continue; }
            if (groups.count(kv.key[1].i)) {
                error(kv.key[1].lineno, "group %d duplicated", kv.key[1].i);
                continue; }
            auto &group = groups[kv.key[1].i];
            if (kv.value.type == tVEC) {
                for (auto &reg : kv.value.vec)
                    group.emplace_back(Phv::Ref(t->gress, reg));
            } else if (kv.value.type == tMAP) {
                for (auto &reg : kv.value.map) {
                    if (!CHECKTYPE2(reg.value, tINT, tRANGE)) continue;
                    if (reg.value.type == tINT)
                        group.emplace_back(Phv::Ref(t->gress, reg.key), reg.value.i);
                    else
                        group.emplace_back(Phv::Ref(t->gress, reg.key),
                                           reg.value.lo, reg.value.hi); }
            } else
                group.emplace_back(Phv::Ref(t->gress, kv.value));
	} else if (!ternary && kv.key[0] == "hash") {
	    if (kv.key.vec.size != 2 || kv.key[1].type != tINT || kv.key[1].i > numgroups) {
		error(kv.key.lineno, "invalid hash group descriptor");
		continue; }
            warning(kv.key.lineno, "FIXME -- hash tables not implemented");
	} else {
	    error(kv.key.lineno, "expecting a group %sdescriptor",
		  ternary ? "" : "or hash "); }
    }
}

bool InputXbar::conflict(std::vector<Input> &a, std::vector<Input> &b) {
    for (auto &i1 : a) {
        if (i1.lo < 0) continue;
        for (auto &i2 : b) {
            if (i2.lo < 0) continue;
            if (i1.lo < i2.lo) {
                if (i1.hi >= i2.lo) return true;
            } else if (i2.hi >= i1.lo) {
                if (i1.lo != i2.lo || i1.hi != i2.hi || i1.what != i2.what)
                    return true;
            }
        }
    }
    return false;
}

void InputXbar::pass1(Alloc1Dbase<std::vector<InputXbar *>> &use, int size) {
    for (auto &group : groups) {
        for (auto &input : group.second) {
            if (!input.what.check()) continue;
            table->stage->phv_use[table->gress][input.what->reg.index] = 1;
            if (input.lo >= 0) {
                if (input.hi >= 0) {
                    if (input.hi - input.lo != input.what->hi - input.what->lo)
                        error(input.what.lineno, "Input xbar size doesn't match register size");
                } else
                    input.hi = input.lo - input.what->lo + input.what->hi;
                if (input.hi >= size)
                    error(input.what.lineno, "placing %s off the top of the input xbar",
                          input.what.name()); } }
        for (InputXbar *other : use[group.first]) {
            if (conflict(other->groups[group.first], group.second)) {
                error(lineno, "Input xbar group %d conflict in stage %d", group.first,
                      table->stage->stageno);
                warning(other->lineno, "conflicting group definition here"); } }
        use[group.first].push_back(this);
    }
}

void InputXbar::add_use(unsigned &byte_use, std::vector<Input> &inputs) {
    for (auto &i : inputs) {
        if (i.lo < 0) continue;
        for (int byte = i.lo/8; byte <= i.hi/8; byte++)
            byte_use |= 1 << byte;;
    }
}

void InputXbar::pass2(Alloc1Dbase<std::vector<InputXbar *>> &use, int size) {
    for (auto &group : groups) {
        unsigned bytes_in_use = 0;
        for (auto &input : group.second) {
            if (input.lo >= 0) continue;
            if (bytes_in_use == 0)
                for (InputXbar *other : use[group.first])
                    add_use(bytes_in_use, other->groups[group.first]);
            int need = input.what->hi/8U - input.what->lo/8U + 1;
            unsigned mask = (1U << need)-1;
            int max = (size+7)/8 - need;
            for (int i = 0; i < max; i++, mask <<= 1)
                if (!(bytes_in_use & mask)) {
                    input.lo = i*8 + input.what->lo%8U;
                    input.hi = (i+need-1)*8 + input.what->hi%8U;
                    bytes_in_use |= mask;
                    LOG1("Putting " << input.what << " in bytes " << i << ".."
                         << i+need-1 << " of " << (ternary ? "tcam" : "exact")
                         << " ixbar group " << group.first << " in stage "
                         << table->stage->stageno);
                    break; }
            if (input.lo < 0)
                error(input.what.lineno, "No space in input xbar group for %s",
                      input.what.name());
        }
    }
}

void InputXbar::write_regs() {
    auto &xbar = table->stage->regs.dp.xbar;
    for (auto &group : groups) {
        unsigned group_base;
        unsigned half_byte = 0;
        if (ternary) {
            group_base = 128 + (group.first*9 + 1)/2U;
            half_byte = 133 + 9*(group.first/2U);
        } else
            group_base = group.first * 16U;
        for (auto &input : group.second) {
            assert(input.lo >= 0);
            unsigned word_group = input.what->reg.index / 16U;
            unsigned word_index = input.what->reg.index % 16U;
            unsigned swizzle_mask = 3;
            if (input.what->reg.index >= 128) {
                assert(input.what->reg.size == 16);
                word_group = (input.what->reg.index-128) / 24U;
                word_index = (input.what->reg.index-128) % 24U + 16;
                swizzle_mask = 1;
            } else if (input.what->reg.index >= 64)
                swizzle_mask = 0;
            unsigned phv_byte = input.what->lo/8U;
            for (unsigned byte = input.lo/8U; byte <= input.hi/8U; byte++, phv_byte++) {
                unsigned i = group_base + byte;
                if (half_byte && byte == 5) i = half_byte;
                if (input.what->reg.index < 64) {
                    assert(input.what->reg.size == 32);
                    xbar.match_input_xbar_32b_ctl[word_group][i]
                        .match_input_xbar_32b_ctl_address = word_index;
                    xbar.match_input_xbar_32b_ctl[word_group][i]
                        .match_input_xbar_32b_ctl_enable = 1;
                } else {
                    xbar.match_input_xbar_816b_ctl[word_group][i]
                        .match_input_xbar_816b_ctl_address = word_index;
                    xbar.match_input_xbar_816b_ctl[word_group][i]
                        .match_input_xbar_816b_ctl_enable = 1; }
                if ((i ^ phv_byte) & swizzle_mask)
                    LOG1("FIXME -- need swizzle for " << input.what); } } }
}

