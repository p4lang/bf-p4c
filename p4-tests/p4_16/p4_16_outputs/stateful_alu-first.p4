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

const op_num PLT_BF_OP = op_num.INSTRUCTION_1;
typedef bit<16> StateType;
control PLT_bloom_filter_way_ctrl(in bit<32> index, in Metadata metadata, out bit<32> result) {
    StatefulALU<StateType>(32w262144, false, 16w0, 16w0, 32w0, 32w0, 32w0, 32w0) PLT_bloom_filter_way = {
        bool condition1(in op_num instr, in bit<32> index, in bit<32> digest, in bit<32> unused) {
            if (instr == op_num.INSTRUCTION_1) {
                StateType digest_in_state = this.get_state_1(index);
                return digest_in_state == (StateType)digest;
            }
            return false;
        }
        bool condition2(in op_num instr, in bit<32> index, in bit<32> unused1, in bit<32> unused2) {
            if (instr == op_num.INSTRUCTION_1) {
                StateType digest_in_state = this.get_state_1(index);
                return digest_in_state == 16w0;
            }
            return false;
        }
        bit<32> compute_value_a_1(in op_num instr, in bit<32> index, in bit<32> digest, in bit<32> unused) {
            if (instr == op_num.INSTRUCTION_1) 
                return digest;
            return 32w0;
        }
        bit<32> compute_value_a_2(in op_num instr, in bit<32> index, in bit<32> digest, in bit<32> unused) {
            return 32w0;
        }
        bit<32> compute_value_b_1(in op_num instr, in bit<32> index, in bit<32> unused1, in bit<32> unused2) {
            if (instr == op_num.INSTRUCTION_1) 
                return 32w1;
            return 32w0;
        }
        bit<32> compute_value_b_2(in op_num instr, in bit<32> index, in bit<32> unused1, in bit<32> unused2) {
            if (instr == op_num.INSTRUCTION_1) 
                return 32w2;
            return 32w0;
        }
        bool run_a_1(in op_num instr, in bool c1, in bool c2) {
            if (instr == op_num.INSTRUCTION_1) 
                return true;
            return false;
        }
        bool run_a_2(in op_num instr, in bool c1, in bool c2) {
            return false;
        }
        bool run_b_1(in op_num instr, in bool c1, in bool c2) {
            if (instr == op_num.INSTRUCTION_1) 
                return c1;
            return false;
        }
        bool run_b_2(in op_num instr, in bool c1, in bool c2) {
            if (instr == op_num.INSTRUCTION_1) 
                return c2;
            return false;
        }
        bool output_filter(in op_num instr, in bool c1, in bool c2) {
            if (instr == op_num.INSTRUCTION_1) 
                return c1 || c2;
            return false;
        }
    };
    apply {
        result = PLT_bloom_filter_way.execute_instr(op_num.INSTRUCTION_1, output_mode.VALUE_B, index, metadata.latency_digest, 32w0);
    }
}

control master(inout Metadata metadata) {
    PLT_bloom_filter_way_ctrl() way1;
    PLT_bloom_filter_way_ctrl() way2;
    PLT_bloom_filter_way_ctrl() way3;
    apply {
        bit<32> index1;
        bit<32> index2;
        bit<32> index3;
        bit<32> result1;
        bit<32> result2;
        bit<32> result3;
        way1.apply(index1, metadata, result1);
        way2.apply(index2, metadata, result2);
        way3.apply(index3, metadata, result3);
        metadata.result = result1 | result2 | result3;
    }
}

