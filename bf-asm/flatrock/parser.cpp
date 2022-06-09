#include "flatrock/parser.h"

#include <cstring>

#include "flatrock/hdr.h"
#include "misc.h"
#include "top_level.h"

namespace {

void report_invalid_directive(const char *message, value_t key) {
    std::string key_name(": ");
    if (key.type == tSTR) {
        key_name += key.s;
    } else if (key.type == tCMD && key.vec.size > 0 && key[0].type == tSTR) {
        key_name += key[0].s;
    } else {
        key_name = "";
    }
    error(key.lineno, "%s%s", message, key_name.c_str());
}

bool input_match_constant(match_t &target, const value_t value, int bit_width) {
    if (!CHECKTYPE3(value, tINT, tBIGINT, tMATCH)) return false;
    return input_int_match(value, target, bit_width);
}

bool input_boolean(bool &target, const value_t value) {
    if (!CHECKTYPE(value, tSTR)) return false;
    if (value == "true") {
        target = true;
        return true;
    } else if (value == "false") {
        target = false;
        return true;
    } else {
        error(value.lineno, "invalid boolean literal: %s", value.s);
        return false;
    }
}

}  // namespace

bool check_range_state_subfield(value_t msb, value_t lsb, bool only8b) {
    /* -- The LSB equals the offset operand in the instruction. There are just 6 bits for
     *    the offset, hence the offset might be in the range <0, 63>. Two bits of the
     *    len operand can define subfield widths 2/4/8/16 bits. That means the MSB
     *    can be in the range <min{LSB} + min{len} - 1, max{LSB} + max{len} - 1>,
     *    i.e. <1, 78>. */
    if (!check_range(msb, 1, Target::Flatrock::PARSER_STATE_WIDTH * 8 - 2)) return false;
    if (!check_range(lsb, 0, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8 - 1)) return false;
    int _width = msb.i - lsb.i + 1;
    if (only8b) {
        if (_width != 8) {
            error(msb.lineno, "width of the sub-state field must be 8 bits");
            return false;
        }
    } else if (_width != 16 && _width != 8 && _width != 4 && _width != 2) {
        error(msb.lineno, "width of the sub-state field must be 16, 8, 4, or 2 bits");
        return false;
    }
    return true;
}

void FlatrockParser::input_states(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(value, tMAP)) return;
    for (auto &kv : MapIterChecked(value.map, false)) {
        if (!CHECKTYPE2(kv.value, tINT, tMATCH)) return;
        match_t match;
        input_int_match(kv.value, match, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8);
        // Inserts if does not exist
        states[kv.key.s] = match;
    }
    states_init = true;
}

void FlatrockParser::PortMetadataItem::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tVEC)) return;
    value_t size = {.type = tINT, .lineno = data.lineno};
    size.i = data.vec.size;
    if (!check_range(size, 0, Target::Flatrock::PARSER_PORT_METADATA_WIDTH)) return;
    for (int i = 0; i < data.vec.size; i++) {
        check_range(data.vec[i], 0, Target::Flatrock::PARSER_PORT_METADATA_ITEM_MAX);
        this->data[i] = data.vec[i].i;
    }
}

void FlatrockParser::PortMetadataItem::write_config(RegisterSetBase &regs, json::map &json,
                                                    bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    for (int i = 0; i < Target::Flatrock::PARSER_PORT_METADATA_WIDTH; i++)
        _regs.prsr_mem.port_md_tbl.port_md_mem[*port].md[i] = data[i];
}

void FlatrockParser::Profile::input_match(VECTOR(value_t) args, value_t key, value_t value) {
    if (key == "match_port") {
        if (!CHECKTYPE2(value, tINT, tMATCH)) return;
        input_int_match(value, match.port, Target::Flatrock::PARSER_PROFILE_PORT_BIT_WIDTH);
    } else if (key == "match_inband_metadata") {
        if (!CHECKTYPE2(value, tINT, tMATCH)) return;
        input_int_match(value, match.inband_metadata,
                        Target::Flatrock::PARSER_INBAND_METADATA_WIDTH * 8);
    }
}

void FlatrockParser::alu0_instruction::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    boost::optional<value_t> opcode, msb, lsb, shift, mask, add;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "opcode") {
            if (!CHECKTYPE2(kv.value, tINT, tSTR)) return;
            if (kv.value.type == tINT) {
                opcode = kv.value;
            } else {
                if (kv.value != "noop") {
                    error(kv.value.lineno,
                          "unexpected opcode %s; "
                          "expected an opcode number or noop",
                          kv.value.s);
                } else {
                    value_t noop_value = {.type = tINT, .lineno = kv.value.lineno};
                    noop_value.i = Flatrock::alu0_instruction::OPCODE_NOOP;
                    opcode = noop_value;
                }
            }
        } else if (kv.key == "msb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            msb = kv.value;
        } else if (kv.key == "lsb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            lsb = kv.value;
        } else if (kv.key == "shift") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            shift = kv.value;
        } else if (kv.key == "mask") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            mask = kv.value;
        } else if (kv.key == "add") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            add = kv.value;
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
    if (!check_range(*opcode, Flatrock::alu0_instruction::OPCODE_0,
        Flatrock::alu0_instruction::OPCODE_6)) return;
    this->opcode = static_cast<Flatrock::alu0_instruction::opcode_enum>(opcode->i);
    switch (this->opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        // ptr += 0  ->  { opcode: noop }
        if (msb || lsb || shift || mask || add) {
            error(opcode->lineno, "unexpected: msb, lsb, shift, mask, or add");
        }
        value_t add_value;
        add_value.i = 0;
        add = add_value;
    case Flatrock::alu0_instruction::OPCODE_0:
        // opcode 0: ptr += imm8s  ->  { opcode: 0, add: <constant> }
    case Flatrock::alu0_instruction::OPCODE_1:
        // opcode 1: ptr += w2[7:0] + imm8s  ->  { opcode: 1, add: <constant> }
        if (msb || lsb || shift || mask) {
            error(opcode->lineno, "unexpected: msb, lsb, shift, or mask");
        } else if (!add) {
            error(opcode->lineno, "missing: add");
        } else {
            check_range(*add, -128, 127);  // add_imm8s
            opcode_0_1.add_imm8s = add->i;
        }
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
        // opcode 2: ptr += state[MSB:LSB], MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 2, msb: <constant>, lsb: <constant>}
    case Flatrock::alu0_instruction::OPCODE_3:
        // opcode 3: ptr += (state[MSB:LSB] << 2), MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 3, msb: <constant>, lsb: <constant>}
        if (shift || mask || add) {
            error(opcode->lineno, "unexpected: shift, mask, or add");
        } else if (!msb || !lsb) {
            error(opcode->lineno, "missing one of: msb, lsb");
        } else {
            check_range_state_subfield(*msb, *lsb);
            opcode_2_3.state_msb = msb->i;
            opcode_2_3.state_lsb = lsb->i;
        }
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
        // opcode 4: ptr += ((w2[7:0] & imm8u) << imm2u) + (imm2u << 2)
        //   -> { opcode: 4, mask: <constant>, shift: <constant>, add: <constant> }
    case Flatrock::alu0_instruction::OPCODE_5:
        // opcode 5: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        //   -> { opcode: 5, mask: <constant>, shift: <constant>, add: <constant> }
    case Flatrock::alu0_instruction::OPCODE_6:
        // opcode 6: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        //           if ((w2[7:0] & imm8u) >> imm2u) != 0,
        //           then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   -> { opcode: 6, mask: <constant>, shift: <constant>, add: <constant> }
        if (msb || lsb) {
            error(opcode->lineno, "unexpected: msb, or lsb");
        } else if (!mask || !shift || !add) {
            error(opcode->lineno, "missing one of: mask, shift, add");
        } else {
            check_range(*mask, 0, 0xff);  // mask_imm8u
            check_range(*shift, 0, 3);    // shift_imm2u
            check_range(*add, 0, 3);      // add_imm2u
            opcode_4_5_6.mask_imm8u = mask->i;
            opcode_4_5_6.shift_imm2u = shift->i;
            opcode_4_5_6.add_imm2u = add->i;
        }
        break;
    case Flatrock::alu0_instruction::INVALID:
    default:
        error(opcode->lineno, "invalid opcode for ALU0");
        break;
    }
}

uint32_t FlatrockParser::alu0_instruction::build_opcode() const {
    uint32_t op0 = 0;
    switch (opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
    case Flatrock::alu0_instruction::OPCODE_0:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE0_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_1:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE1_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE2_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_3:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE3_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE4_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_5:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE5_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_6:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE6_ENC;
        break;
    }
    int __len;
    uint8_t _len, _off, _mask, _shift, _add;
    switch (opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
    case Flatrock::alu0_instruction::OPCODE_1:
        // op0[7:0] : imm (signed)
        // op0[11:8] : reserved
        op0 |= opcode_0_1.add_imm8s & 0xff;
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
    case Flatrock::alu0_instruction::OPCODE_3:
        // op0[7:6] : len
        // op0[5:0] : off
        // op0[11:8] : reserved
        __len = opcode_2_3.state_msb - opcode_2_3.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _off = opcode_2_3.state_lsb;
        op0 |= (_len & 0x3) << 6 | (_off & 0x3f);
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
    case Flatrock::alu0_instruction::OPCODE_5:
    case Flatrock::alu0_instruction::OPCODE_6:
        // op0[7:0] : mask
        // op0[11:10] : shift
        // op0[9:8] : imm (unsigned)
        _mask = opcode_4_5_6.mask_imm8u;
        _shift = opcode_4_5_6.shift_imm2u;
        _add = opcode_4_5_6.add_imm2u;
        op0 |= (_shift & 0x3) << 10 | (_add & 0x3) << 8 | (_mask & 0xff);
        break;
    }
    return op0;
}

void FlatrockParser::alu1_instruction::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    boost::optional<value_t> opcode, msb, lsb, shift_dir, shift, mask_mode, mask, add, set;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "opcode") {
            if (!CHECKTYPE2(kv.value, tINT, tSTR)) return;
            if (kv.value.type == tINT) {
                opcode = kv.value;
            } else {
                if (kv.value != "noop") {
                    error(kv.value.lineno,
                          "unexpected opcode %s; "
                          "expected an opcode number or noop",
                          kv.value.s);
                } else {
                    value_t noop_value = {.type = tINT, .lineno = kv.value.lineno};
                    noop_value.i = Flatrock::alu1_instruction::OPCODE_NOOP;
                    opcode = noop_value;
                }
            }
        } else if (kv.key == "msb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            msb = kv.value;
        } else if (kv.key == "lsb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            lsb = kv.value;
        } else if (kv.key == "shift_dir") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            shift_dir = kv.value;
        } else if (kv.key == "shift") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            shift = kv.value;
        } else if (kv.key == "mask_mode") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            mask_mode = kv.value;
        } else if (kv.key == "mask") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            mask = kv.value;
        } else if (kv.key == "add") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            add = kv.value;
        } else if (kv.key == "set") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            set = kv.value;
        } else {
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
        }
    }
    if (!check_range(*opcode, Flatrock::alu1_instruction::OPCODE_0,
        Flatrock::alu1_instruction::OPCODE_7)) return;
    this->opcode = static_cast<Flatrock::alu1_instruction::opcode_enum>(opcode->i);
    switch (this->opcode) {
    case Flatrock::alu1_instruction::OPCODE_0:
        // opcode 0: state[MSB:LSB] >>= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
        //  -> { opcode: 0, msb: <constant>, lsb: <constant>, shift: <constant> }
    case Flatrock::alu1_instruction::OPCODE_1:
        // opcode 1: state[MSB:LSB] <<= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
        //  -> { opcode: 1, msb: <constant>, lsb: <constant>, shift: <constant> }
        if (shift_dir || mask_mode || mask || add || set) {
            error(opcode->lineno, "unexpected: shift_dir, mask_mode, mask, add, or set");
        } else if (!msb || !lsb || !shift) {
            error(opcode->lineno, "missing one of: msb, lsb, shift");
        } else {
            check_range_state_subfield(*msb, *lsb);
            check_range(*shift, 0, 15);  // shift_imm4u
            opcode_0_1.state_msb = msb->i;
            opcode_0_1.state_lsb = lsb->i;
            opcode_0_1.shift_imm4u = shift->i;
        }
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        // opcode 2: state[MSB:LSB] += imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 2, msb: <constant>, lsb: <constant>, add: <constant> }
        if (shift_dir || shift || mask_mode || mask || set) {
            error(opcode->lineno, "unexpected: shift_dir, shift, mask_mode, mask, or set");
        } else if (!msb || !lsb || !add) {
            error(opcode->lineno, "missing one of: msb, lsb, add");
        } else {
            check_range_state_subfield(*msb, *lsb);
            check_range(*add, -128, 127);  // add_set_imm8s
            opcode_2_3.state_msb = msb->i;
            opcode_2_3.state_lsb = lsb->i;
            opcode_2_3.add_set_imm8s = add->i;
        }
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        // opcode 3: state[MSB:LSB] = imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> * { opcode: 3, msb: <constant>, lsb: <constant>, value: <constant> }
        if (shift_dir || shift || mask_mode || mask || add) {
            error(opcode->lineno, "unexpected: shift_dir, shift, mask_mode, mask, or add");
        } else if (!msb || !lsb || !set) {
            error(opcode->lineno, "missing one of: msb, lsb, set");
        } else {
            check_range_state_subfield(*msb, *lsb);
            check_range(*set, -128, 127);
            opcode_2_3.state_msb = msb->i;
            opcode_2_3.state_lsb = lsb->i;
            opcode_2_3.add_set_imm8s = set->i;
        }
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
        // opcode 4:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 4, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case Flatrock::alu1_instruction::OPCODE_5:
        // opcode 5:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 5, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case Flatrock::alu1_instruction::OPCODE_6:
        // opcode 6:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 6, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case Flatrock::alu1_instruction::OPCODE_7:
        // opcode 7:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 7, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
        if (set) {
            error(opcode->lineno, "unexpected: set");
        } else if (!msb || !lsb || !mask_mode || !mask || !shift_dir || !shift || !add) {
            error(opcode->lineno,
                  "missing one of: msb, lsb, mask_mode, mask, shift_dir, shift, add");
        } else {
            check_range_state_subfield(*msb, *lsb, true);
            check_range(*mask_mode, 0, 0x1);  // mask_mode
            check_range(*mask, 0, 0xf);  // mask_imm4u
            check_range(*shift_dir, 0, 1);  // shift_dir
            check_range(*shift, 0, 3);  // shift_imm2u
            check_range(*add, 0, 3);  // add_imm2u
            opcode_4_5_6_7.state_msb = msb->i;
            opcode_4_5_6_7.state_lsb = lsb->i;
            opcode_4_5_6_7.mask_imm4u = mask->i;
            opcode_4_5_6_7.shift_dir = shift_dir->i;
            opcode_4_5_6_7.shift_imm2u = shift->i;
            opcode_4_5_6_7.add_imm2u = add->i;
        }
        break;
    case Flatrock::alu0_instruction::INVALID:
    default:
        error(opcode->lineno, "invalid opcode for ALU1");
        break;
    }
}

uint32_t FlatrockParser::alu1_instruction::build_opcode() const {
    uint32_t op1 = 0;
    switch (opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
    case Flatrock::alu1_instruction::OPCODE_0:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE0_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_1:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE1_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE2_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE3_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE4_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_5:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE5_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_6:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE6_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_7:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE7_ENC;
        break;
    }
    int __len;
    uint8_t _len, _off, _mask, _shift, _add;
    switch (opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
    case Flatrock::alu1_instruction::OPCODE_1:
        // op1[15:10] : offset
        // op1[9:8] : len
        // op1[7:4] : reserved
        // op1[3:0] : imm
        _off = opcode_0_1.state_lsb;
        __len = opcode_0_1.state_msb - opcode_0_1.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _shift = opcode_0_1.shift_imm4u;
        op1 |= (_off & 0x3f) << 10 | (_len & 0x3) << 8 | (_shift & 0xf);
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
    case Flatrock::alu1_instruction::OPCODE_3:
        // op1[15:10] : offset
        // op1[9:8] : len
        // op1[7:0] : imm (signed)
        _off = opcode_2_3.state_lsb;
        __len = opcode_2_3.state_msb - opcode_2_3.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _add = opcode_2_3.add_set_imm8s;
        op1 |= (_off & 0x3f) << 10 | (_len & 0x3) << 8 | (_add & 0xff);
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
    case Flatrock::alu1_instruction::OPCODE_5:
    case Flatrock::alu1_instruction::OPCODE_6:
    case Flatrock::alu1_instruction::OPCODE_7:
        // op1[15:10] : offset
        // op1[9] : mask_mode
        // op1[8] : shift_dir
        // op1[7:4] : mask
        // op1[3:2] : shift
        // op1[1:0] : imm
        _off = opcode_4_5_6_7.state_lsb;
        uint8_t _mask_mode = opcode_4_5_6_7.mask_mode;
        uint8_t _shift_dir = opcode_4_5_6_7.shift_dir;
        _mask = opcode_4_5_6_7.mask_imm4u;
        _shift = opcode_4_5_6_7.shift_imm2u;
        _add = opcode_4_5_6_7.add_imm2u;
        op1 |= (_off & 0x3f) << 10 | (_mask_mode & 0x1) << 9 | (_shift_dir & 0x1) << 8 |
               (_mask & 0xf) << 4 | (_shift & 0x3) << 2 | (_add & 0x3);
        break;
    }
    return op1;
}

FlatrockParser::ParserStateVector::ParserStateVector() {
    std::memset(value, 0, sizeof(value));
    std::memset(mask, 0, sizeof(mask));
}

FlatrockParser::ParserStateVector::ParserStateVector(match_t match) {
    static_assert(sizeof(match.word0) == 8);
    static_assert(sizeof(match.word1) == 8);
    static_assert(Target::Flatrock::PARSER_STATE_WIDTH == 10);

    /* -- the all-match bits are initialized with zeros. We need that for the
     *    initial state value. */
    auto derived_value(match.word1 & (match.word0 ^ match.word1));
    value[0] = static_cast<uint8_t>(derived_value);
    value[1] = static_cast<uint8_t>(derived_value >> 8);
    value[2] = static_cast<uint8_t>(derived_value >> 16);
    value[3] = static_cast<uint8_t>(derived_value >> 24);
    value[4] = static_cast<uint8_t>(derived_value >> 32);
    value[5] = static_cast<uint8_t>(derived_value >> 40);
    value[6] = static_cast<uint8_t>(derived_value >> 48);
    value[7] = static_cast<uint8_t>(derived_value >> 56);

    auto derived_mask(match.word0 ^ match.word1);
    mask[0] = static_cast<uint8_t>(derived_mask);
    mask[1] = static_cast<uint8_t>(derived_mask >> 8);
    mask[2] = static_cast<uint8_t>(derived_mask >> 16);
    mask[3] = static_cast<uint8_t>(derived_mask >> 24);
    mask[4] = static_cast<uint8_t>(derived_mask >> 32);
    mask[5] = static_cast<uint8_t>(derived_mask >> 40);
    mask[6] = static_cast<uint8_t>(derived_mask >> 48);
    mask[7] = static_cast<uint8_t>(derived_mask >> 56);

    // Upper-most two bytes fixed 0
    value[8] = 0;
    mask[8] = 0;
    value[9] = 0;
    mask[9] = 0;
}

FlatrockParser::ParserStateVector::ParserStateVector(match_t hi, match_t lo)
    : ParserStateVector(lo) {
    static_assert(sizeof(match_t::word0) == 8);
    static_assert(sizeof(match_t::word1) == 8);
    static_assert(Target::Flatrock::PARSER_STATE_WIDTH == 10);

    /* -- the all-match bits are initialized with zeros. We need that for the
     *    initial state value. */
    auto derived_value(hi.word1 & (hi.word0 ^ hi.word1));
    value[8] = static_cast<uint8_t>(derived_value);
    value[9] = static_cast<uint8_t>(derived_value >> 8);

    auto derived_mask(hi.word0 ^ hi.word1);
    mask[8] = static_cast<uint8_t>(derived_mask);
    mask[9] = static_cast<uint8_t>(derived_mask >> 8);
}

bool FlatrockParser::ParserStateVector::input_state_value(
    uint8_t target[Target::Flatrock::PARSER_STATE_WIDTH * 8], const value_t value) {
    static_assert(sizeof(value.i) == 8);
    static_assert(Target::Flatrock::PARSER_STATE_WIDTH >= 8);

    /* -- small constants are parsed as tINT. Thus we must support both integer types. */
    if (!CHECKTYPE2(value, tINT, tBIGINT)) return false;

    if (value.type == tBIGINT) {
        if (!check_bigint_unsigned(value, Target::Flatrock::PARSER_STATE_WIDTH)) return false;

        int dword_index(0);
        int byte_mask(0);
        for (int i(0); i < Target::Flatrock::PARSER_STATE_WIDTH; ++i) {
            if (dword_index < value.bigi.size) {
                target[i] = static_cast<uint8_t>(value.bigi.data[dword_index] >> byte_mask);
            } else {
                target[i] = 0;
            }
            byte_mask += 8;
            if (byte_mask >= sizeof(value.bigi.data[0]) * 8) {
                byte_mask = 0;
                ++dword_index;
            }
        }
    } else {
        if (value.i < 0) {
            error(value.lineno, "the next_state constant is negative");
            return false;
        }
        target[0] = static_cast<uint8_t>(value.i);
        target[1] = static_cast<uint8_t>(value.i >> 8);
        target[2] = static_cast<uint8_t>(value.i >> 16);
        target[3] = static_cast<uint8_t>(value.i >> 24);
        target[4] = static_cast<uint8_t>(value.i >> 32);
        target[5] = static_cast<uint8_t>(value.i >> 40);
        target[6] = static_cast<uint8_t>(value.i >> 48);
        target[7] = static_cast<uint8_t>(value.i >> 56);

        for (int i(8); i < Target::Flatrock::PARSER_STATE_WIDTH; ++i) target[i] = 0;
    }

    return true;
}

void FlatrockParser::ParserStateVector::forceSetMask() {
    for (unsigned char & byte : mask)
        byte = 0xff;
}

void FlatrockParser::ParserStateVector::writeValue(ubits<16> &hi, ubits<32> &mid,
                                                   ubits<32> &lo) const {
    hi = (static_cast<uint16_t>(value[9]) << 8) | static_cast<uint16_t>(value[8]);
    mid = (static_cast<uint32_t>(value[7]) << 24) | (static_cast<uint32_t>(value[6]) << 16) |
          (static_cast<uint32_t>(value[5]) << 8) | static_cast<uint32_t>(value[4]);
    lo = (static_cast<uint32_t>(value[3]) << 24) | (static_cast<uint32_t>(value[2]) << 16) |
         (static_cast<uint32_t>(value[1]) << 8) | static_cast<uint32_t>(value[0]);
}

void FlatrockParser::ParserStateVector::writeMask(ubits<16> &hi, ubits<32> &mid,
                                                  ubits<32> &lo) const {
    hi = (static_cast<uint16_t>(mask[9]) << 8) | static_cast<uint16_t>(mask[8]);
    mid = (static_cast<uint32_t>(mask[7]) << 24) | (static_cast<uint32_t>(mask[6]) << 16) |
          (static_cast<uint32_t>(mask[5]) << 8) | static_cast<uint32_t>(mask[4]);
    lo = (static_cast<uint32_t>(mask[3]) << 24) | (static_cast<uint32_t>(mask[2]) << 16) |
         (static_cast<uint32_t>(mask[1]) << 8) | static_cast<uint32_t>(mask[0]);
}

bool FlatrockParser::ParserStateVector::parse_state_vector(ParserStateVector &target,
                                                           value_t value) {
    ParserStateVector tmp;

    if (value.type == tINT || value.type == tBIGINT) {
        if (!input_state_value(tmp.value, value)) return false;
        tmp.forceSetMask();
    } else if (value.type == tMATCH) {
        /* -- even though the match value is already parsed in value.m, check the correct range */
        match_t match;
        if (!input_int_match(value, match, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8))
            return false;
        tmp = ParserStateVector(match);
    } else if (value.type == tMAP) {
        match_t hi;
        match_t lo;
        std::memset(&hi, 0, sizeof(hi));
        std::memset(&lo, 0, sizeof(lo));
        for (const auto &kv : MapIterChecked(value.map, true)) {
            if (kv.key == "lo") {
                if (!input_int_match(kv.value, lo, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8))
                    return false;
            } else if (kv.key == "hi") {
                if (!input_int_match(kv.value, hi,
                                     (Target::Flatrock::PARSER_STATE_WIDTH -
                                      Target::Flatrock::PARSER_STATE_MATCH_WIDTH) *
                                         8))
                    return false;
            } else {
                report_invalid_directive("invalid specification of the state vector", kv.key);
                return false;
            }
        }
        tmp = ParserStateVector(hi, lo);
    } else {
        error(value.lineno, "invalid specification of the state vector");
        return false;
    }

    target = tmp; /* -- strong guarantee */
    return true;
}

void FlatrockParser::Profile::input_metadata_select(VECTOR(value_t) args, value_t key,
                                                    value_t value) {
    if (!CHECKTYPE(value, tVEC)) return;
    value_t size = {.type = tINT, .lineno = value.lineno};
    size.i = value.vec.size;
    if (!check_range(size, 0, Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM)) return;
    for (int i = 0; i < value.vec.size; i++) {
        if (!CHECKTYPE3(value.vec[i], tINT, tSTR, tCMD)) return;
        if (value.vec[i].type == tINT) {
            metadata_select[i].type = Flatrock::metadata_select::CONSTANT;
            metadata_select[i].constant.value = value.vec[i].i;
        } else if (value.vec[i].type == tSTR) {
            if (value.vec[i] == "logical_port_number") {
                metadata_select[i].type = Flatrock::metadata_select::LOGICAL_PORT_NUMBER;
            } else {
                error(value.vec[i].lineno, "invalid key: %s", value.vec[i].s);
            }
        } else {
            if (value.vec[i].vec.size < 2) error(value.vec[i].lineno, "missing operand");
            if (value.vec[i] == "port_metadata") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PORT_METADATA_WIDTH - 1);
                metadata_select[i].type = Flatrock::metadata_select::PORT_METADATA;
                metadata_select[i].port_metadata.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "inband_metadata") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_INBAND_METADATA_WIDTH - 1);
                metadata_select[i].type = Flatrock::metadata_select::INBAND_METADATA;
                metadata_select[i].inband_metadata.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "timestamp") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_INDEX_MAX);
                metadata_select[i].type = Flatrock::metadata_select::TIMESTAMP;
                metadata_select[i].timestamp.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "counter") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PROFILE_MD_SEL_COUNTER_INDEX_MAX);
                metadata_select[i].type = Flatrock::metadata_select::COUNTER;
                metadata_select[i].timestamp.index = value.vec[i].vec[1].i;
            } else {
                report_invalid_directive("invalid key", value.vec[i]);
            }
        }
    }
}

void FlatrockParser::Profile::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "match_port") {
            input_match(args, kv.key, kv.value);
        } else if (kv.key == "match_inband_metadata") {
            input_match(args, kv.key, kv.value);
        } else if (kv.key == "initial_pktlen") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_PROFILE_PKTLEN_MAX);
            initial_pktlen = kv.value.i;
        } else if (kv.key == "initial_seglen") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_PROFILE_SEGLEN_MAX);
            initial_seglen = kv.value.i;
        } else if (kv.key == "initial_state") {
            if (kv.value.type == tSTR) {
                match_t match = parser->state(kv.value);
                initial_state = ParserStateVector(match);
            } else {
                ParserStateVector tmp;
                if (!ParserStateVector::parse_state_vector(tmp, kv.value)) return;
                initial_state = tmp;
            }
        } else if (kv.key == "initial_flags") {
            if (!CHECKTYPE(kv.value, tBIGINT)) return;
            initial_flags[0] = kv.value.bigi.data[0];
            initial_flags[1] = kv.value.bigi.data[0] >> 8;
            initial_flags[2] = kv.value.bigi.data[0] >> 16;
            initial_flags[3] = kv.value.bigi.data[0] >> 24;
            initial_flags[4] = kv.value.bigi.data[0] >> 32;
            initial_flags[5] = kv.value.bigi.data[0] >> 40;
            initial_flags[6] = kv.value.bigi.data[0] >> 48;
            initial_flags[7] = kv.value.bigi.data[0] >> 56;
        } else if (kv.key == "initial_ptr") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_PTR_MAX);
            initial_ptr = kv.value.i;
        } else if (kv.key == "initial_w0_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            initial_w0_offset = kv.value.i;
        } else if (kv.key == "initial_w1_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            initial_w1_offset = kv.value.i;
        } else if (kv.key == "initial_w2_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            initial_w2_offset = kv.value.i;
        } else if (kv.key == "initial_alu0_instruction") {
            initial_alu0_instruction.input(args, kv.value);
        } else if (kv.key == "initial_alu1_instruction") {
            initial_alu1_instruction.input(args, kv.value);
        } else if (kv.key == "metadata_select") {
            input_metadata_select(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
}

void FlatrockParser::Profile::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    /*
     * TCAM:
     * WH  WL  Input  Hit
     * 1   0   0      Yes
     * 1   0   1      No
     * 0   1   0      No
     * 0   1   1      Yes
     * 1   1   *      Yes
     * 0   0   *      No
     */
    // 4Byte of inband metadata: inband_meta[4:7][7:0]
    // inband_metadata is in network byte order
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wh_0 =
        match.inband_metadata.word0 & 0xffffffff;
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wl_0 =
        match.inband_metadata.word1 & 0xffffffff;
    // 4Byte of inband metadata: inband_meta[0:3][7:0]
    // inband_metadata is in network byte order
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wh_1 = match.inband_metadata.word0 >> 32;
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wl_1 = match.inband_metadata.word1 >> 32;
    // 8bit port_info = {2'b0, logic_port#(6b)}
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wh_2 = match.port.word0 & 0x3f;
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wl_2 = match.port.word1 & 0x3f;
    // RAM
    // initial state
    initial_state.writeValue(_regs.prsr_mem.md_prof_ram.md_prof[*id].start_state_hi,
                             _regs.prsr_mem.md_prof_ram.md_prof[*id].start_state_mid,
                             _regs.prsr_mem.md_prof_ram.md_prof[*id].start_state_lo);
    // initial flags
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_flags_hi =
        initial_flags[7] << 24 | initial_flags[6] << 16 | initial_flags[5] << 8 | initial_flags[4];
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_flags_lo =
        initial_flags[3] << 24 | initial_flags[2] << 16 | initial_flags[1] << 8 | initial_flags[0];
    // initial ptr
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_ptr = initial_ptr;
    // initial w0 offset
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_w0 = initial_w0_offset;
    // initial w1 offset
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_w1 = initial_w1_offset;
    // initial w2 offset
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_w2 = initial_w2_offset;
    // initial ALU0 instruction
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_op0 = initial_alu0_instruction.build_opcode();
    // initial ALU1 instruction
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_op1 = initial_alu1_instruction.build_opcode();
    // metadata select
    for (int i = 0; i < Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM; i++) {
        // Skip uninitialized fields
        if (metadata_select[i].type == Flatrock::metadata_select::INVALID) continue;
        _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel_const[i] =
            (metadata_select[i].type == Flatrock::metadata_select::CONSTANT);
        switch (metadata_select[i].type) {
        case Flatrock::metadata_select::CONSTANT:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                metadata_select[i].constant.value;
            break;
        case Flatrock::metadata_select::LOGICAL_PORT_NUMBER:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC |
                Target::Flatrock::PARSER_PROFILE_MD_SEL_LOGICAL_PORT_NUMBER_INDEX;
            break;
        case Flatrock::metadata_select::PORT_METADATA:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC |
                metadata_select[i].port_metadata.index;
            break;
        case Flatrock::metadata_select::INBAND_METADATA:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_INBAND_METADATA_ENC |
                metadata_select[i].inband_metadata.index;
            break;
        case Flatrock::metadata_select::TIMESTAMP:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_ENC |
                metadata_select[i].timestamp.index;
            break;
        case Flatrock::metadata_select::COUNTER:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_COUNTER_ENC |
                metadata_select[i].counter.index;
            break;
        }
    }
}

bool FlatrockParser::AnalyzerStage::input_push_hdr(
    FlatrockParser::AnalyzerStage::Rule& rule,
    value_t value) {
    if (!CHECKTYPE(value, tMAP))
        return false;
    if (value.map.size != 2) {
        error(value.lineno, "invalid number of push_hdr_id parameters");
        return false;
    }

    Rule::PushHdrId push_hdr_id;
    for (const auto &kv_hdr : MapIterChecked(value.map, false)) {
        if (kv_hdr.key == "hdr") {
            if (kv_hdr.value.type == tSTR) {
                int hdr_id(Hdr::id(kv_hdr.value.lineno, kv_hdr.value.s));
                if (hdr_id < 0) return false;
                push_hdr_id.hdr_id = static_cast<uint8_t>(hdr_id);
            } else if (kv_hdr.value.type == tINT) {
                if (!check_range(kv_hdr.value, 0, 0xff)) return false;
                push_hdr_id.hdr_id = kv_hdr.value.i;
            } else {
                error(kv_hdr.value.lineno,
                    "id attribute of the push_hdr_id must be a symbolic header name "
                    "or a numeric id");
                return false;
            }
        } else if (kv_hdr.key == "offset") {
            if (!check_range(kv_hdr.value, 0, 0xfe)) {
                error(kv_hdr.value.lineno,
                    "offset attribute the push_hdr_id must be a numeric offset in the "
                    "interval <0, 0xff>.");
                return false;
            }
            push_hdr_id.offset = static_cast<int8_t>(kv_hdr.value.i);
        } else {
            report_invalid_directive("invalid attribute of push_hdr_id directive",
                kv_hdr.key);
            return false;
        }
    }
    rule.push_hdr_id = push_hdr_id;
    return true;
}

void FlatrockParser::AnalyzerStage::input_rule(VECTOR(value_t) args, value_t key, value_t data) {
    if (key.type == tSTR) {
        /* -- This is handled by the CHECKTYPE macro but I want nicer
         *    error message. */
        error(key.lineno, "index of the rule is missing");
        return;
    }
    if (!CHECKTYPE(key, tCMD))
        return;
    if (key.vec.size < 2) {
        error(key.lineno, "index of the rule is missing");
        return;
    }
    if (key.vec.size > 2) {
        error(key.lineno, "too many parameters of the analyzer rule");
        return;
    }
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_ANALYZER_STAGE_RULES - 1))
        return;
    const int rule_index(key[1].i);
    auto &rule(rules[rule_index]);

    /* -- If the rule is specified in the ASM file, the default matching values are
     *    "match everything". That's different than default rule "match nothing" if
     *    the rule is not written in the file. */
    std::memset(&rule.match.state, 0xff, sizeof(rule.match.state));
    std::memset(&rule.match.w0, 0xff, sizeof(rule.match.w0));
    std::memset(&rule.match.w1, 0xff, sizeof(rule.match.w1));

    /* -- if the analyzer stage is attached to a state, use the state */
    if (name) {
        if (!parser->get_state_match(rule.match.state, *name))
            return;
    }

    if (!CHECKTYPE(data, tMAP))
        return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE2(kv.key, tSTR, tCMD))
            continue;
        if (kv.key == "match_state") {
            if (name) {
                error(kv.key.lineno,
                      "named analyzer stage must not contain any rule with the match_state "
                      "attribute");
                continue;
            }
            if (kv.value.type == tSTR) {
                if (!parser->get_state_match(rule.match.state, kv.value))
                    continue;
            } else {
                input_match_constant(
                    rule.match.state, kv.value, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8);
            }
        } else if (kv.key == "match_w0") {
            input_match_constant(
                rule.match.w0, kv.value, Target::Flatrock::PARSER_W_WIDTH * 8);
        } else if (kv.key == "match_w1") {
            input_match_constant(
                rule.match.w1, kv.value, Target::Flatrock::PARSER_W_WIDTH * 8);
        } else if (kv.key == "next_state") {
            ParserStateVector next_state;
            if (kv.value.type == tSTR) {
                match_t state_match;
                if (parser->get_state_match(state_match, kv.value))
                    next_state = ParserStateVector(state_match);
            } else {
                ParserStateVector::parse_state_vector(next_state, kv.value);
            }
            rule.next_state = next_state;
        } else if (kv.key == "next_skip_extractions") {
            input_boolean(rule.next_skip_extraction, kv.value);
        } else if (kv.key == "next_w0_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            rule.next_w0_offset = kv.value.i;
        } else if (kv.key == "next_w1_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            rule.next_w1_offset = kv.value.i;
        } else if (kv.key == "next_w2_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            rule.next_w2_offset = kv.value.i;
        } else if (kv.key == "next_alu0_instruction") {
            rule.next_alu0_instruction.input(args, kv.value);
        } else if (kv.key == "next_alu1_instruction") {
            rule.next_alu1_instruction.input(args, kv.value);
        } else if (kv.key == "push_hdr_id") {
            input_push_hdr(rule, kv.value);
        } else {
            report_invalid_directive("invalid rule attribute", kv.key);
        }
    }

    /* -- There is no sensible default for next instructions. Check if they have been set. */
    if (rule.next_alu0_instruction.is_invalid()) {
        error(key.lineno, "mandatory rule's next_alu0_instruction field is missing");
    }
    if (rule.next_alu1_instruction.is_invalid()) {
        error(key.lineno, "mandatory rule's next_alu1_instruction field is missing");
    }
}

void FlatrockParser::AnalyzerStage::input(VECTOR(value_t) args, int stage_,
                                          boost::optional<value_t> name_, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;

    stage = stage_;
    name = name_;

    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE2(kv.key, tSTR, tCMD)) return;
        if (kv.key == "rule") {
            input_rule(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid analyzer directive", kv.key);
        }
    }
}

void FlatrockParser::AnalyzerStage::write_config(RegisterSetBase &regs, json::map &json,
                                                 bool legacy) {
    auto &fr_regs(dynamic_cast<Target::Flatrock::parser_regs &>(regs));

    if (!stage) return; /* -- the stage is not specified, leave the registers at defaults */

    for (unsigned int rule_idx(0); rule_idx < Target::Flatrock::PARSER_ANALYZER_STAGE_RULES;
         ++rule_idx) {
        const auto &rule(rules[rule_idx]);

        /*
         * TCAM:
         * WH  WL  Input  Hit
         * 1   0   0      Yes
         * 1   0   1      No
         * 0   1   0      No
         * 0   1   1      Yes
         * 1   1   *      Yes
         * 0   0   *      No
         */

        /* -- match state[63:0] */
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wh_0 =
            rule.match.state.word0 & 0xffffffff;
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wl_0 =
            rule.match.state.word1 & 0xffffffff;
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wh_1 =
            rule.match.state.word0 >> 32;
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wl_1 =
            rule.match.state.word1 >> 32;

        /* -- match w0 and w1 */
        fr_regs.prsr_mem.parser_key_w.key_w[*stage][rule_idx].key_wh =
            (rule.match.w0.word0 & 0xffff) | ((rule.match.w1.word0 & 0xffff) << 16);
        fr_regs.prsr_mem.parser_key_w.key_w[*stage][rule_idx].key_wl =
            (rule.match.w0.word1 & 0xffff) | ((rule.match.w1.word1 & 0xffff) << 16);

        /* -- w0, w1, w2 offsets */
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].exw_skip =
            rule.next_skip_extraction ? 1 : 0;
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].next_w0_offset = rule.next_w0_offset;
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].next_w1_offset = rule.next_w1_offset;
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].next_w2_offset = rule.next_w2_offset;

        /* -- next state value and mask */
        rule.next_state.writeValue(
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_val_79_64,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_val_63_32,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_val_31_0);
        rule.next_state.writeMask(
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_mask_79_64,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_mask_63_32,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_mask_31_0);

        /* -- ALU0 and ALU1 instructions */
        fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op0 =
            rule.next_alu0_instruction.build_opcode();
        const uint32_t next_op1(rule.next_alu1_instruction.build_opcode());
        fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op1_0 = next_op1;
        fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op1_1 = next_op1 >> 16;

        /* -- push extracted headers */
        if (rule.push_hdr_id) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].push_hdr_id =
                (static_cast<uint32_t>(1) << 16) /* vld == '1' => push hdr_id into next slot */ |
                (static_cast<uint32_t>(rule.push_hdr_id->hdr_id) << 8) |
                (static_cast<uint32_t>(rule.push_hdr_id->offset));
        }
    }
}

void FlatrockParser::PhvBuilderGroup::input(VECTOR(value_t) args, value_t data) {
    // TODO
}

void FlatrockParser::PhvBuilderGroup::write_config(RegisterSetBase &regs, json::map &json,
                                                   bool legacy) {
    // TODO
}

void FlatrockParser::input_port_metadata(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tSTR) || !CHECKTYPE(value, tMAP)) return;
    for (auto &item : value.map) {
        if (!check_range(item.key, 0, Target::Flatrock::PARSER_PORT_METADATA_ITEMS - 1)) return;
        int port = item.key.i;
        port_metadata[port].port = port;
        port_metadata[port].input(args, item.value);
    }
}

void FlatrockParser::input_profile(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tCMD)) return;
    if (key.vec.size < 2) error(key.lineno, "profile ID missing");
    if (key.vec.size > 2) error(key.lineno, "too many parameters");
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_PROFILES - 1)) return;
    int id = key[1].i;
    profiles[id].id = id;
    profiles[id].input(args, value);
}

void FlatrockParser::input_analyzer_stage(VECTOR(value_t) args, value_t key, value_t value) {
    if (key.type == tSTR) {
        /* -- The key is just one string -> no parameters. This situation
         *    can be handled by the CHECKTYPE macro, but I want to show
         *    a nicer error message. */
        error(key.lineno, "number of analyzer stage is missing");
        return;
    }
    if (!CHECKTYPE(key, tCMD)) return;
    if (key.vec.size < 2) {
        error(key.lineno, "number of analyzer stage is missing");
        return;
    }
    if (key.vec.size > 3) {
        error(key.lineno, "too many parameters of the analyzer_stage directive");
        return;
    }

    /* -- parse number of the stage */
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_ANALYZER_STAGES - 1)) return;
    const int stage_index(key[1].i);

    /* -- parse optional name */
    boost::optional<value_t> state_name;
    if (key.vec.size > 2) {
        if (!CHECKTYPE(key[2], tSTR)) return;
        state_name = key[2];
    }

    /* -- set the analyzer and parse its context */
    analyzer[stage_index].input(args, stage_index, state_name, value);
}

void FlatrockParser::input_phv_builder_group(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tCMD) || !CHECKTYPE(value, tMAP)) return;
}

void FlatrockParser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "states") {
            input_states(args, kv.key, kv.value);
        } else if (kv.key == "port_metadata") {
            input_port_metadata(args, kv.key, kv.value);
        } else if (kv.key == "profile") {
            input_profile(args, kv.key, kv.value);
        } else if (kv.key == "analyzer_stage") {
            input_analyzer_stage(args, kv.key, kv.value);
        } else if (kv.key == "phv_builder_group") {
            input_phv_builder_group(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
}

void FlatrockParser::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    for (unsigned int i = 0; i < Target::Flatrock::PARSER_PORT_METADATA_ITEMS; i++)
        if (port_metadata[i].port)
            // Process only initialized items
            port_metadata[i].write_config(regs, json, legacy);
    for (unsigned int i = 0; i < Target::Flatrock::PARSER_PROFILES; i++)
        if (profiles[i].id)
            // Process only initialized items
            profiles[i].write_config(regs, json, legacy);
    for (unsigned int i(0); i < Target::Flatrock::PARSER_ANALYZER_STAGES; ++i) {
        analyzer[i].write_config(regs, json, legacy);
    }
    if (auto *top = TopLevel::regs<Target::Flatrock>()) {
        top->mem_pipe.prsr_mem.set("mem.prsr_mem", &_regs.prsr_mem);
        top->reg_pipe.prsr.set("reg.prsr", &_regs.prsr);
    }
}

match_t FlatrockParser::state(value_t name) const {
    BUG_CHECK(name.type == tSTR, "invalid name type");

    match_t retval{};
    std::memset(&retval, 0, sizeof(retval));
    const auto *found_match(_state_mask(name.lineno, name.s));
    if (found_match != nullptr) {
        retval = *found_match;
    }
    return retval;
}

bool FlatrockParser::get_state_match(match_t &state_match, value_t name) const {
    BUG_CHECK(name.type == tSTR, "invalid name type");

    const auto *found_match(_state_mask(name.lineno, name.s));
    if (found_match != nullptr) {
        state_match = *found_match;
        return true;
    }
    return false;
}

FlatrockAsmParser::FlatrockAsmParser() : BaseAsmParser("parser") {
    /* -- register the register instance into the ubits *** singleton map */
    declare_registers(&cfg_registers);
}

FlatrockAsmParser::~FlatrockAsmParser() {
    /* -- unregister from the ubit *** singleton map */
    undeclare_registers(&cfg_registers);
}

const Target::Flatrock::parser_regs &FlatrockAsmParser::get_cfg_registers() const {
    return cfg_registers;
}

void FlatrockAsmParser::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno,
              "parser must specify ingress or egress;"
              " ingress represents parser and egress represents pseudo parser");
}

void FlatrockAsmParser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    if (args.size == 1 && args[0] == "ingress") {
        parser.input(args, data);
    } else {
        pseudo_parser.input(args, data);
    }
}

void FlatrockAsmParser::output(json::map &ctxt_json) {
    ctxt_json["parser"]["ingress"] = json::vector();
    parser.write_config(cfg_registers, ctxt_json, false);
    ctxt_json["parser"]["egress"] = json::vector();
    pseudo_parser.write_config(cfg_registers, ctxt_json, false);
}
