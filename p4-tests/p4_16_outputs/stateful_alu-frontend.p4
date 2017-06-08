enum output_mode {
    PHV1,
    PHV2,
    STATE_1_ORIGINAL,
    STATE_2_ORIGINAL,
    VALUE_A,
    VALUE_B,
    CONDITION,
    CONDITION_COMBINED
}

enum op_num {
    INSTRUCTION_1,
    INSTRUCTION_2,
    INSTRUCTION_3,
    INSTRUCTION_4
}

extern StatefulALU<STATE_TYPE> {
    StatefulALU(bit<32> stateSize, bool dual_state, STATE_TYPE state1InitialValue, STATE_TYPE state2InitialValue, bit<32> p1, bit<32> p2, bit<32> p3, bit<32> p4);
    STATE_TYPE get_state_1(in bit<32> index);
    void set_state_1(in bit<32> index, in STATE_TYPE new_value);
    STATE_TYPE get_state_2(in bit<32> index);
    void set_state_2(in bit<32> index, in STATE_TYPE new_value);
    bit<32> getParam1();
    bit<32> getParam2();
    bit<32> getParam3();
    bit<32> getParam4();
    bool has_state_2();
    abstract bool condition1(in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
    abstract bool condition2(in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
    abstract bit<32> compute_value_a_1(in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
    abstract bit<32> compute_value_a_2(in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
    abstract bit<32> compute_value_b_1(in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
    abstract bit<32> compute_value_b_2(in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
    abstract bool run_a_1(in op_num instr, in bool c1, in bool c2);
    abstract bool run_a_2(in op_num instr, in bool c1, in bool c2);
    abstract bool run_b_1(in op_num instr, in bool c1, in bool c2);
    abstract bool run_b_2(in op_num instr, in bool c1, in bool c2);
    abstract bool output_filter(in op_num instr, in bool c1, in bool c2);
    bit<32> execute_instr(in op_num instr, in output_mode omode, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
}

struct Metadata {
    bit<32> result;
    bit<32> latency_digest;
}

