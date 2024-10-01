enum op_num {
    INSTRUCTION_1,
    INSTRUCTION_2,
    INSTRUCTION_3,
    INSTRUCTION_4
}

extern StatefulALU<STATE_TYPE> {
    StatefulALU(bit<32> stateSize, STATE_TYPE stateInitialValue, bit<32> p1, bit<32> p2, bit<32> p3, bit<32> p4);
    STATE_TYPE get_state(in bit<32> index);
    void set_state(in bit<32> index, in STATE_TYPE new_value);
    bit<32> getParam1();
    bit<32> getParam2();
    bit<32> getParam3();
    bit<32> getParam4();
    abstract bit<32> execute_instr(in op_num op, in bit<32> index, in bit<32> phv1, in bit<32> phv2);
}

struct Metadata {
    bit<32> result;
    bit<32> latency_digest;
}

