#ifndef BF_P4C_PARDE_FLATROCK_H_
#define BF_P4C_PARDE_FLATROCK_H_

#include "bf-p4c/common/flatrock_parser.h"
#include <iostream>

/*
 * Output ALU0 instruction in the form e.g. { opcode: 2, msb: 5, lsb: 2 }.
 * See bf-asm/SYNTAX.yaml for the list of ALU0 instructions.
 */
inline std::ostream& print_params(std::ostream& out,
        const Flatrock::alu0_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        out << "{ opcode: noop }";
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
    case Flatrock::alu0_instruction::OPCODE_1:
        out << "{ opcode: " << static_cast<int>(instruction.opcode);
        out << ", add: " << instruction.opcode_0_1.add_imm8s << " }";
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
    case Flatrock::alu0_instruction::OPCODE_3:
        out << "{ opcode: " << static_cast<int>(instruction.opcode);
        out << ", msb: " << instruction.opcode_2_3.state_msb
            << ", lsb: " << instruction.opcode_2_3.state_lsb << " }";
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
    case Flatrock::alu0_instruction::OPCODE_5:
    case Flatrock::alu0_instruction::OPCODE_6:
    {
        out << "{ opcode: " << static_cast<int>(instruction.opcode);
        auto original_flags = out.flags();
        out << ", mask: 0x" << std::hex << instruction.opcode_4_5_6.mask_imm8u;
        out.flags(original_flags);
        out << ", shift: " << instruction.opcode_4_5_6.shift_imm2u
            << ", add: " << instruction.opcode_4_5_6.add_imm2u << " }";
        break;
    }
    default:
        BUG("Invalid ALU0 opcode");
    }
    return out;
}

/*
 * Output ALU0 instruction in the form e.g. ptr += state[5:2].
 * See bf-asm/SYNTAX.yaml for the list of ALU0 instructions.
 */
inline std::ostream& print_pretty(std::ostream& out,
        const Flatrock::alu0_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        out << "noop";
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
        out << "ptr += " << instruction.opcode_0_1.add_imm8s;
        break;
    case Flatrock::alu0_instruction::OPCODE_1:
        out << "ptr += w2[7:0] + " << instruction.opcode_0_1.add_imm8s;
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
        out << "ptr += state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "]";
        break;
    case Flatrock::alu0_instruction::OPCODE_3:
        out << "ptr += (state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "] << 2)";
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
        out << "ptr += ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") << "
            << instruction.opcode_4_5_6.shift_imm2u << ") + ("
            << instruction.opcode_4_5_6.add_imm2u << " << 2)";
        break;
    case Flatrock::alu0_instruction::OPCODE_5:
        out << "ptr += ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ") + ("
            << instruction.opcode_4_5_6.add_imm2u << " << 2)";
        break;
    case Flatrock::alu0_instruction::OPCODE_6:
        out << "ptr += ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ") + ("
            << instruction.opcode_4_5_6.add_imm2u << " << 2)";
        out << ", ";
        out << "if ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ") != 0, then + 4 - ((w2[7:0] & "
            << instruction.opcode_4_5_6.mask_imm8u << ") >> "
            << instruction.opcode_4_5_6.shift_imm2u << ")";
        break;
    default:
        BUG("Invalid ALU0 opcode");
    }
    return out;
}

/*
 * Output ALU1 instruction in the form e.g.
 * { opcode: 4, msb: 9, lsb: 2, mask_mode: 0, mask: 0xa, shift_dir: 1, shift: 2, add: 3 }.
 * See bf-asm/SYNTAX.yaml for the list of ALU1 instructions.
 */
inline std::ostream& print_params(std::ostream& out,
        const Flatrock::alu1_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        out << "{ opcode: noop }";
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
        out << "{ opcode: 0, msb: " << instruction.opcode_0_1.state_msb
                       << ", lsb: " << instruction.opcode_0_1.state_lsb
                       << ", shift: " << instruction.opcode_0_1.shift_imm4u << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_1:
        out << "{ opcode: 1, msb: " << instruction.opcode_0_1.state_msb
                       << ", lsb: " << instruction.opcode_0_1.state_lsb
                       << ", shift: " << instruction.opcode_0_1.shift_imm4u << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        out << "{ opcode: 2, msb: " << instruction.opcode_2_3.state_msb
                       << ", lsb: " << instruction.opcode_2_3.state_lsb
                       << ", add: " << instruction.opcode_2_3.add_set_imm8s << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        out << "{ opcode: 3, msb: " << instruction.opcode_2_3.state_msb
                       << ", lsb: " << instruction.opcode_2_3.state_lsb
                       << ", value: " << instruction.opcode_2_3.add_set_imm8s << " }";
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
    case Flatrock::alu1_instruction::OPCODE_5:
    case Flatrock::alu1_instruction::OPCODE_6:
    case Flatrock::alu1_instruction::OPCODE_7:
    {
        out << "{ opcode: " << static_cast<int>(instruction.opcode)
            << ", msb: " << instruction.opcode_4_5_6_7.state_msb
            << ", lsb: " << instruction.opcode_4_5_6_7.state_lsb
            << ", mask_mode: " << instruction.opcode_4_5_6_7.mask_mode;
        auto original_flags = out.flags();
        out << ", mask: 0x" << std::hex << instruction.opcode_4_5_6_7.mask_imm4u;
        out.flags(original_flags);
        out << ", shift_dir: " << instruction.opcode_4_5_6_7.shift_dir
            << ", shift: " << instruction.opcode_4_5_6_7.shift_imm2u
            << ", add: " << instruction.opcode_4_5_6_7.add_imm2u << " }";
        break;
    }
    default:
        BUG("Invalid ALU1 opcode");
    }
    return out;
}

/*
 * Output ALU1 instruction in the form e.g. state[9:2] += ((w2[7:0] & 0xcc) >> 2) + (3 << 2).
 * See bf-asm/SYNTAX.yaml for the list of ALU1 instructions.
 */
inline std::ostream& print_pretty(std::ostream& out,
        const Flatrock::alu1_instruction& instruction) {
    switch (instruction.opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        out << "noop";
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
        out << "state["
            << instruction.opcode_0_1.state_msb << ":"
            << instruction.opcode_0_1.state_lsb << "] >>= "
            << instruction.opcode_0_1.shift_imm4u;
        break;
    case Flatrock::alu1_instruction::OPCODE_1:
        out << "state["
            << instruction.opcode_0_1.state_msb << ":"
            << instruction.opcode_0_1.state_lsb << "] <<= "
            << instruction.opcode_0_1.shift_imm4u;
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        out << "state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "] += "
            << instruction.opcode_2_3.add_set_imm8s;
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        out << "state["
            << instruction.opcode_2_3.state_msb << ":"
            << instruction.opcode_2_3.state_lsb << "] = "
            << instruction.opcode_2_3.add_set_imm8s;
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
    case Flatrock::alu1_instruction::OPCODE_5:
    case Flatrock::alu1_instruction::OPCODE_6:
    case Flatrock::alu1_instruction::OPCODE_7:
    {
        out << "state["
            << instruction.opcode_4_5_6_7.state_msb << ":"
            << instruction.opcode_4_5_6_7.state_lsb << "]";
        switch (instruction.opcode) {
        case Flatrock::alu1_instruction::OPCODE_4:
        case Flatrock::alu1_instruction::OPCODE_6:
            out << " += ";
            break;
        case Flatrock::alu1_instruction::OPCODE_5:
        case Flatrock::alu1_instruction::OPCODE_7:
            out << " -= ";
            break;
        default:
            break;
        }
        std::stringstream cond;
        cond << "((w2[7:0] & ";
        int mask = 0;
        if (instruction.opcode_4_5_6_7.mask_mode) {
            // if mask_mode == 1, then the mask is a full bit mask on the lower bits;
            // upper bits are 0xF
            mask = 0xf | instruction.opcode_4_5_6_7.mask_imm4u;
        } else {
            // if mask_mode == 0, then each bit is a half-nibble mask
            for (int i = 0, shift = 1; i < 4; i++) {
                mask |= (instruction.opcode_4_5_6_7.mask_imm4u << i) & shift;
                shift <<= 1;
                mask |= (instruction.opcode_4_5_6_7.mask_imm4u << (i + 1)) & shift;
                shift <<= 1;
            }
        }
        cond.fill('0');
        cond << "0x" << std::setw(2) << std::hex << mask;
        cond << ")";
        cond << (instruction.opcode_4_5_6_7.shift_dir ? " >> " : " << ");
        cond << instruction.opcode_4_5_6_7.shift_imm2u << ")";
        out << cond;
        out <<" + ("
            << instruction.opcode_4_5_6_7.add_imm2u << " << 2)";
        switch (instruction.opcode) {
        case Flatrock::alu1_instruction::OPCODE_6:
        case Flatrock::alu1_instruction::OPCODE_7:
            out << "if (" << cond << ") != 0, then + 4 - " << cond;
        default:
            break;
        }
        break;
    }
    default:
        BUG("Invalid ALU1 opcode");
    }
    return out;
}

/*
 * Output single metadata selection item.
 */
inline std::ostream& operator<<(std::ostream& out, const Flatrock::metadata_select& select) {
    switch (select.type) {
    case Flatrock::metadata_select::CONSTANT:
        out << select.constant.value;
        break;
    case Flatrock::metadata_select::LOGICAL_PORT_NUMBER:
        out << "logical_port_number";
        break;
    case Flatrock::metadata_select::PORT_METADATA:
        out << "port_metadata " << select.port_metadata.index;
        break;
    case Flatrock::metadata_select::INBAND_METADATA:
        out << "inband_metadata " << select.inband_metadata.index;
        break;
    case Flatrock::metadata_select::TIMESTAMP:
        out << "timestamp " << select.timestamp.index;
        break;
    case Flatrock::metadata_select::COUNTER:
        out << "counter " << select.counter.index;
        break;
    default:
        BUG("Invalid metadata selection");
    }
    return out;
}

#endif  /* BF_P4C_PARDE_FLATROCK_H_ */
