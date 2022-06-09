#include "flatrock_parser.h"
#include "lib/exceptions.h"

using namespace Flatrock;

alu0_instruction::alu0_instruction(opcode_enum opcode, std::vector<int> ops) : opcode(opcode) {
    switch (opcode) {
    case OPCODE_NOOP:
        break;
    case OPCODE_0:
    case OPCODE_1:
        BUG_CHECK(ops.size() == 1, "Expected 1 operand for ALU0 opcode 0/1");
        opcode_0_1.add_imm8s = ops.at(0);
        break;
    case OPCODE_2:
    case OPCODE_3:
        BUG_CHECK(ops.size() == 2, "Expected 2 operands for ALU0 opcode 2/3");
        opcode_2_3.state_msb = ops.at(0);
        opcode_2_3.state_lsb = ops.at(1);
        break;
    case OPCODE_4:
    case OPCODE_5:
    case OPCODE_6:
        BUG_CHECK(ops.size() == 3, "Expected 3 operands for ALU0 opcode 4/5/6");
        opcode_4_5_6.mask_imm8u = ops.at(0);
        opcode_4_5_6.shift_imm2u = ops.at(1);
        opcode_4_5_6.add_imm2u = ops.at(2);
        break;
    default:
        BUG("Invalid ALU0 opcode");
    }
}

alu1_instruction::alu1_instruction(opcode_enum opcode, std::vector<int> ops) : opcode(opcode) {
    switch (opcode) {
    case OPCODE_NOOP:
        break;
    case OPCODE_0:
    case OPCODE_1:
        BUG_CHECK(ops.size() == 3, "Expected 3 operands for ALU1 opcode 0/1");
        opcode_0_1.state_msb = ops.at(0);
        opcode_0_1.state_lsb = ops.at(1);
        opcode_0_1.shift_imm4u = ops.at(2);
        break;
    case OPCODE_2:
    case OPCODE_3:
        BUG_CHECK(ops.size() == 3, "Expected 3 operands for ALU1 opcode 2/3");
        opcode_2_3.state_msb = ops.at(0);
        opcode_2_3.state_lsb = ops.at(1);
        opcode_2_3.add_set_imm8s = ops.at(2);
        break;
    case OPCODE_4:
    case OPCODE_5:
    case OPCODE_6:
    case OPCODE_7:
        BUG_CHECK(ops.size() == 7, "Expected 7 operands for ALU1 opcode 4/5/6/7");
        opcode_4_5_6_7.state_msb = ops.at(0);
        opcode_4_5_6_7.state_lsb = ops.at(1);
        opcode_4_5_6_7.mask_mode = ops.at(2);
        opcode_4_5_6_7.mask_imm4u = ops.at(3);
        opcode_4_5_6_7.shift_dir = ops.at(4);
        opcode_4_5_6_7.shift_imm2u = ops.at(5);
        opcode_4_5_6_7.add_imm2u = ops.at(6);
        break;
    default:
        BUG("Invalid ALU1 opcode");
    }
}

metadata_select::metadata_select(type_enum type, std::vector<int> ops) : type(type) {
    switch (type) {
    case CONSTANT:
        BUG_CHECK(ops.size() == 1, "Expected 1 operand for metadata constant");
        constant.value = ops.at(0);
        break;
    case LOGICAL_PORT_NUMBER:
        BUG_CHECK(ops.size() == 0, "Expected no operands for metadata logical port number");
        break;
    case PORT_METADATA:
        BUG_CHECK(ops.size() == 1, "Expected 1 operand for metadata port metadata");
        port_metadata.index = ops.at(0);
        break;
    case INBAND_METADATA:
        BUG_CHECK(ops.size() == 1, "Expected 1 operand for metadata inband metadata");
        inband_metadata.index = ops.at(0);
        break;
    case TIMESTAMP:
        BUG_CHECK(ops.size() == 1, "Expected 1 operand for metadata timestamp");
        timestamp.index = ops.at(0);
        break;
    case COUNTER:
        BUG_CHECK(ops.size() == 1, "Expected 1 operand for metadata counter");
        counter.index = ops.at(0);
        break;
    default:
        BUG("Invalid metadata type");
    }
}
