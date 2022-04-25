#include "flatrock/parser.h"
#include "misc.h"

void check_range_state_subfield(value_t msb, value_t lsb, bool only8b) {
    check_range(msb, 0, Target::Flatrock::PARSER_STATE_WIDTH * 8 - 1);
    check_range(lsb, 0, Target::Flatrock::PARSER_STATE_WIDTH * 8 - 1);
    int _width = msb.i - lsb.i + 1;
    if (only8b) {
        if (_width != 8)
            error(msb.lineno, "width of the sub-state field must be 8 bits");
    } else if (_width != 16 && _width != 8 && _width != 4 && _width != 2)
        error(msb.lineno, "width of the sub-state field must be 16, 8, 4, or 2 bits");
}

void FlatrockParser::input_states(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(value, tMAP)) return;
    for (auto &kv : MapIterChecked(value.map, false)) {
        if (!CHECKTYPE2(kv.value, tINT, tMATCH)) return;
        match_t match;
        input_int_match(kv.value, match, Target::Flatrock::PARSER_STATE_WIDTH * 8);
        // Inserts if does not exist
        states[kv.key.s] = match;
    }
    states_init = true;
}

void FlatrockParser::PortMetadataItem::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tVEC)) return;
    value_t size = { .type = tINT, .lineno = data.lineno };
    size.i = data.vec.size;
    check_range(size, 0, Target::Flatrock::PARSER_PORT_METADATA_WIDTH);
    for (int i = 0; i < data.vec.size; i++) {
        check_range(data.vec[i], 0, Target::Flatrock::PARSER_PORT_METADATA_ITEM_MAX);
        this->data[i] = data.vec[i].i;
    }
}

void FlatrockParser::PortMetadataItem::write_config(RegisterSetBase &regs,
        json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    for (int i = 0; i < Target::Flatrock::PARSER_PORT_METADATA_WIDTH; i++)
        _regs.imem.port_md_tbl.port_md_mem[*port].md[i] = data[i];
}

void FlatrockParser::Profile::input_match(VECTOR(value_t) args,
        value_t key, value_t value) {
    if (key == "match_port") {
        if (!CHECKTYPE2(value, tINT, tMATCH)) return;
        input_int_match(value, match.port, Target::Flatrock::PARSER_PROFILE_PORT_BIT_WIDTH);
    } else if (key == "match_inband_metadata") {
        if (!CHECKTYPE2(value, tINT, tMATCH)) return;
        input_int_match(value, match.inband_metadata, Target::Flatrock::PARSER_STATE_WIDTH * 8);
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
                    error(kv.value.lineno, "unexpected opcode %s; "
                        "expected an opcode number or noop", kv.value.s);
                } else {
                    value_t noop_value = { .type = tINT, .lineno = kv.value.lineno };
                    noop_value.i = alu0_instruction::OPCODE_0_NOOP;
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
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
        }
    }
    check_range(*opcode, alu0_instruction::OPCODE_0, alu0_instruction::OPCODE_6);
    this->opcode = static_cast<alu0_instruction::opcode_enum>(opcode->i);
    switch (this->opcode) {
    case alu0_instruction::OPCODE_0_NOOP:
        // ptr += 0  ->  { opcode: noop }
        if (msb || lsb || shift || mask || add) {
            error(opcode->lineno, "unexpected: msb, lsb, shift, mask, or add");
        }
        value_t add_value;
        add_value.i = 0;
        add = add_value;
    case alu0_instruction::OPCODE_0:
        // opcode 0: ptr += imm8s  ->  { opcode: 0, add: <constant> }
    case alu0_instruction::OPCODE_1:
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
    case alu0_instruction::OPCODE_2:
        // opcode 2: ptr += state[MSB:LSB], MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 2, msb: <constant>, lsb: <constant>}
    case alu0_instruction::OPCODE_3:
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
    case alu0_instruction::OPCODE_4:
        // opcode 4: ptr += ((w2[7:0] & imm8u) << imm2u) + (imm2u << 2)
        //   -> { opcode: 4, mask: <constant>, shift: <constant>, add: <constant> }
    case alu0_instruction::OPCODE_5:
        // opcode 5: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        //   -> { opcode: 5, mask: <constant>, shift: <constant>, add: <constant> }
    case alu0_instruction::OPCODE_6:
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
            check_range(*shift, 0, 3);  // shift_imm2u
            check_range(*add, 0, 3);  // add_imm2u
            opcode_4_5_6.mask_imm8u = mask->i;
            opcode_4_5_6.shift_imm2u = shift->i;
            opcode_4_5_6.add_imm2u = add->i;
        }
        break;
    case alu0_instruction::INVALID:
    default:
        error(opcode->lineno, "invalid opcode for ALU0");
        break;
    }
}

uint32_t FlatrockParser::alu0_instruction::build_opcode() {
    uint32_t op0 = 0;
    switch (opcode) {
    case alu0_instruction::OPCODE_0_NOOP:
    case alu0_instruction::OPCODE_0:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE0_ENC;
        break;
    case alu0_instruction::OPCODE_1:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE1_ENC;
        break;
    case alu0_instruction::OPCODE_2:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE2_ENC;
        break;
    case alu0_instruction::OPCODE_3:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE3_ENC;
        break;
    case alu0_instruction::OPCODE_4:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE4_ENC;
        break;
    case alu0_instruction::OPCODE_5:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE5_ENC;
        break;
    case alu0_instruction::OPCODE_6:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE6_ENC;
        break;
    }
    int __len;
    uint8_t _len, _off, _mask, _shift, _add;
    switch (opcode) {
    case alu0_instruction::OPCODE_0_NOOP:
        break;
    case alu0_instruction::OPCODE_0:
    case alu0_instruction::OPCODE_1:
        // op0[7:0] : imm (signed)
        // op0[11:8] : reserved
        op0 |= opcode_0_1.add_imm8s & 0xff;
        break;
    case alu0_instruction::OPCODE_2:
    case alu0_instruction::OPCODE_3:
        // op0[7:6] : len
        // op0[5:0] : off
        // op0[11:8] : reserved
        __len = opcode_2_3.state_msb - opcode_2_3.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _off = opcode_2_3.state_lsb;
        op0 |= (_len & 0x3) << 6 | (_off & 0x3f);
        break;
    case alu0_instruction::OPCODE_4:
    case alu0_instruction::OPCODE_5:
    case alu0_instruction::OPCODE_6:
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
            if (!CHECKTYPE(kv.value, tINT)) return;
            opcode = kv.value;
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
    check_range(*opcode, alu1_instruction::OPCODE_0, alu1_instruction::OPCODE_7);
    this->opcode = static_cast<alu1_instruction::opcode_enum>(opcode->i);
    switch (this->opcode) {
    case alu1_instruction::OPCODE_0:
        // opcode 0: state[MSB:LSB] >>= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
        //  -> { opcode: 0, msb: <constant>, lsb: <constant>, shift: <constant> }
    case alu1_instruction::OPCODE_1:
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
    case alu1_instruction::OPCODE_2:
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
    case alu1_instruction::OPCODE_3:
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
    case alu1_instruction::OPCODE_4:
        // opcode 4:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 4, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case alu1_instruction::OPCODE_5:
        // opcode 5:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 5, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case alu1_instruction::OPCODE_6:
        // opcode 6:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 6, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case alu1_instruction::OPCODE_7:
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
    case alu0_instruction::INVALID:
    default:
        error(opcode->lineno, "invalid opcode for ALU1");
        break;
    }
}

uint32_t FlatrockParser::alu1_instruction::build_opcode() {
    uint32_t op1 = 0;
    switch (opcode) {
    case alu1_instruction::OPCODE_0:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE0_ENC;
        break;
    case alu1_instruction::OPCODE_1:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE1_ENC;
        break;
    case alu1_instruction::OPCODE_2:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE2_ENC;
        break;
    case alu1_instruction::OPCODE_3:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE3_ENC;
        break;
    case alu1_instruction::OPCODE_4:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE4_ENC;
        break;
    case alu1_instruction::OPCODE_5:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE5_ENC;
        break;
    case alu1_instruction::OPCODE_6:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE6_ENC;
        break;
    case alu1_instruction::OPCODE_7:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE7_ENC;
        break;
    }
    int __len;
    uint8_t _len, _off, _mask, _shift, _add;
    switch (opcode) {
    case alu1_instruction::OPCODE_0:
    case alu1_instruction::OPCODE_1:
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
    case alu1_instruction::OPCODE_2:
    case alu1_instruction::OPCODE_3:
        // op1[15:10] : offset
        // op1[9:8] : len
        // op1[7:0] : imm (signed)
        _off = opcode_2_3.state_lsb;
        __len = opcode_2_3.state_msb - opcode_2_3.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _add = opcode_2_3.add_set_imm8s;
        op1 |= (_off & 0x3f) << 10 | (_len & 0x3) << 8 | (_add & 0xff);
        break;
    case alu1_instruction::OPCODE_4:
    case alu1_instruction::OPCODE_5:
    case alu1_instruction::OPCODE_6:
    case alu1_instruction::OPCODE_7:
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
        op1 |= (_off & 0x3f) << 10 | (_mask_mode & 0x1) << 9 | (_shift_dir & 0x1) << 8
            | (_mask & 0xf) << 4 | (_shift & 0x3) << 2 | (_add & 0x3);
        break;
    }
    return op1;
}

void FlatrockParser::Profile::input_metadata_select(VECTOR(value_t) args,
        value_t key, value_t value) {
    if (!CHECKTYPE(value, tVEC)) return;
    value_t size = { .type = tINT, .lineno = value.lineno };
    size.i = value.vec.size;
    check_range(size, 0, Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM);
    for (int i = 0; i < value.vec.size; i++) {
        if (!CHECKTYPE3(value.vec[i], tINT, tSTR, tCMD)) return;
        if (value.vec[i].type == tINT) {
            metadata_select[i].type = metadata_select::CONSTANT;
            metadata_select[i].constant.value = value.vec[i].i;
        } else if (value.vec[i].type == tSTR) {
            if (value.vec[i] == "logical_port_number") {
                metadata_select[i].type = metadata_select::LOGICAL_PORT_NUMBER;
            } else {
                error(value.vec[i].lineno, "invalid key: %s", value.vec[i].s);
            }
        } else {
            if (value.vec[i].vec.size < 2)
                error(value.vec[i].lineno, "missing operand");
            if (value.vec[i] == "port_metadata") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PORT_METADATA_WIDTH - 1);
                metadata_select[i].type = metadata_select::PORT_METADATA;
                metadata_select[i].port_metadata.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "inband_metadata") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_INBAND_METADATA_WIDTH - 1);
                metadata_select[i].type = metadata_select::INBAND_METADATA;
                metadata_select[i].inband_metadata.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "timestamp") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_INDEX_MAX);
                metadata_select[i].type = metadata_select::TIMESTAMP;
                metadata_select[i].timestamp.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "counter") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PROFILE_MD_SEL_COUNTER_INDEX_MAX);
                metadata_select[i].type = metadata_select::COUNTER;
                metadata_select[i].timestamp.index = value.vec[i].vec[1].i;
            } else {
                error(value.vec[i].lineno, "invalid key: %s", value.vec[i].s);
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
            if (!CHECKTYPE2(kv.value, tBIGINT, tSTR)) return;
            if (kv.value.type == tBIGINT) {
                initial_state[0] = kv.value.bigi.data[0];
                initial_state[1] = kv.value.bigi.data[0] >> 8;
                initial_state[2] = kv.value.bigi.data[0] >> 16;
                initial_state[3] = kv.value.bigi.data[0] >> 24;
                initial_state[4] = kv.value.bigi.data[0] >> 32;
                initial_state[5] = kv.value.bigi.data[0] >> 40;
                initial_state[6] = kv.value.bigi.data[0] >> 48;
                initial_state[7] = kv.value.bigi.data[0] >> 56;
                initial_state[8] = kv.value.bigi.data[1];
                initial_state[9] = kv.value.bigi.data[1] >> 8;
            } else {
                match_t match = parser->state(kv.value);
                // All-match bits are initialized with zeros
                auto value = match.word1 & (match.word0 ^ match.word1);
                initial_state[0] = value;
                initial_state[1] = value >> 8;
                initial_state[2] = value >> 16;
                initial_state[3] = value >> 24;
                initial_state[4] = value >> 32;
                initial_state[5] = value >> 40;
                initial_state[6] = value >> 48;
                initial_state[7] = value >> 56;
                // Upper-most two bytes fixed 0
                initial_state[8] = 0;
                initial_state[9] = 0;
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
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
        }
    }
}

void FlatrockParser::Profile::write_config(RegisterSetBase &regs,
        json::map &json, bool legacy) {
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
    _regs.imem.md_prof_tcam.md_prof_tcam[*id].key_wh_0 = match.inband_metadata.word0 & 0xffffffff;
    _regs.imem.md_prof_tcam.md_prof_tcam[*id].key_wl_0 = match.inband_metadata.word1 & 0xffffffff;
      // 4Byte of inband metadata: inband_meta[0:3][7:0]
      // inband_metadata is in network byte order
    _regs.imem.md_prof_tcam.md_prof_tcam[*id].key_wh_1 = match.inband_metadata.word0 >> 32;
    _regs.imem.md_prof_tcam.md_prof_tcam[*id].key_wl_1 = match.inband_metadata.word1 >> 32;
      // 8bit port_info = {2'b0, logic_port#(6b)}
    _regs.imem.md_prof_tcam.md_prof_tcam[*id].key_wh_2 = match.port.word0 & 0x3f;
    _regs.imem.md_prof_tcam.md_prof_tcam[*id].key_wl_2 = match.port.word1 & 0x3f;
    // RAM
      // initial state
    _regs.imem.md_prof_ram.md_prof[*id].start_state_hi
        = initial_state[9] << 8 | initial_state[8];
    _regs.imem.md_prof_ram.md_prof[*id].start_state_mid
        = initial_state[7] << 24 | initial_state[6] << 16
          | initial_state[5] << 8 | initial_state[4];
    _regs.imem.md_prof_ram.md_prof[*id].start_state_lo
        = initial_state[3] << 24 | initial_state[2] << 16
          | initial_state[1] << 8 | initial_state[0];
      // initial flags
    _regs.imem.md_prof_ram.md_prof[*id].start_flags_hi
        = initial_flags[7] << 24 | initial_flags[6] << 16
          | initial_flags[5] << 8 | initial_flags[4];
    _regs.imem.md_prof_ram.md_prof[*id].start_flags_lo
        = initial_flags[3] << 24 | initial_flags[2] << 16
          | initial_flags[1] << 8 | initial_flags[0];
      // initial ptr
    _regs.imem.md_prof_ram.md_prof[*id].start_ptr = initial_ptr;
      // initial w0 offset
    _regs.imem.md_prof_ram.md_prof[*id].start_w0 = initial_w0_offset;
      // initial w1 offset
    _regs.imem.md_prof_ram.md_prof[*id].start_w1 = initial_w1_offset;
      // initial w2 offset
    _regs.imem.md_prof_ram.md_prof[*id].start_w2 = initial_w2_offset;
      // initial ALU0 instruction
    _regs.imem.md_prof_ram.md_prof[*id].start_op0 = initial_alu0_instruction.build_opcode();
      // initial ALU1 instruction
    _regs.imem.md_prof_ram.md_prof[*id].start_op1 = initial_alu1_instruction.build_opcode();
      // metadata select
    for (int i = 0; i < Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM; i++) {
        // Skip uninitialized fields
        if (metadata_select[i].type == metadata_select::INVALID) continue;
        _regs.imem.md_prof_ram.md_prof[*id].md_sel_const[i]
            = (metadata_select[i].type == metadata_select::CONSTANT);
        switch (metadata_select[i].type) {
        case metadata_select::CONSTANT:
            _regs.imem.md_prof_ram.md_prof[*id].md_sel[i] = metadata_select[i].constant.value;
            break;
        case metadata_select::LOGICAL_PORT_NUMBER:
            _regs.imem.md_prof_ram.md_prof[*id].md_sel[i]
                = Target::Flatrock::PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC
                  | Target::Flatrock::PARSER_PROFILE_MD_SEL_LOGICAL_PORT_NUMBER_INDEX;
            break;
        case metadata_select::PORT_METADATA:
            _regs.imem.md_prof_ram.md_prof[*id].md_sel[i]
                = Target::Flatrock::PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC
                  | metadata_select[i].port_metadata.index;
            break;
         case metadata_select::INBAND_METADATA:
            _regs.imem.md_prof_ram.md_prof[*id].md_sel[i]
                = Target::Flatrock::PARSER_PROFILE_MD_SEL_INBAND_METADATA_ENC
                  | metadata_select[i].inband_metadata.index;
            break;
         case metadata_select::TIMESTAMP:
            _regs.imem.md_prof_ram.md_prof[*id].md_sel[i]
                = Target::Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_ENC
                  | metadata_select[i].timestamp.index;
            break;
         case metadata_select::COUNTER:
            _regs.imem.md_prof_ram.md_prof[*id].md_sel[i]
                = Target::Flatrock::PARSER_PROFILE_MD_SEL_COUNTER_ENC
                  | metadata_select[i].counter.index;
            break;
        }
    }
}

void FlatrockParser::AnalyzerStage::input(VECTOR(value_t) args, value_t data) {
    // TODO
}

void FlatrockParser::AnalyzerStage::write_config(RegisterSetBase &regs,
        json::map &json, bool legacy) {
    // TODO
}

void FlatrockParser::PhvBuilderGroup::input(VECTOR(value_t) args, value_t data) {
    // TODO
}

void FlatrockParser::PhvBuilderGroup::write_config(RegisterSetBase &regs,
        json::map &json, bool legacy) {
    // TODO
}

void FlatrockParser::input_port_metadata(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tSTR) || !CHECKTYPE(value, tMAP)) return;
    for (auto &item : value.map) {
        check_range(item.key, 0, Target::Flatrock::PARSER_PORT_METADATA_ITEMS - 1);
        int port = item.key.i;
        port_metadata[port].port = port;
        port_metadata[port].input(args, item.value);
    }
}

void FlatrockParser::input_profile(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tCMD)) return;
    if (key.vec.size < 2)
        error(key.lineno, "profile ID missing");
    if (key.vec.size > 2)
        error(key.lineno, "too many parameters");
    check_range(key[1], 0, Target::Flatrock::PARSER_PROFILES - 1);
    int id = key[1].i;
    profiles[id].id = id;
    profiles[id].input(args, value);
}

void FlatrockParser::input_analyzer_stage(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tCMD) || !CHECKTYPE(value, tMAP)) return;
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
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
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
}

void FlatrockParser::output(json::map &json) {
    auto *regs = new Target::Flatrock::parser_regs;
    declare_registers(regs);
    write_config(*regs, json, false);
}

void FlatrockAsmParser::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno, "parser must specify ingress or egress;"
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
    parser.output(ctxt_json);
    ctxt_json["parser"]["egress"] = json::vector();
    pseudo_parser.output(ctxt_json);
}
