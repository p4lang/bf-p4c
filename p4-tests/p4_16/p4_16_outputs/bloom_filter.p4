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

const op_num PLT_BF_OP = op_num.INSTRUCTION_1;
typedef bit<32> StateType;
control PLT_bloom_filter_way_ctrl(in bit<32> index, in Metadata metadata, out bit<32> result) {
    StatefulALU<StateType>(256 * 1024, 0, 0, 0, 0, 0) PLT_bloom_filter_way = {
        bit<32> execute_instr(in op_num op, in bit<32> index, in bit<32> digest, in bit<32> not_used) {
            if (op == PLT_BF_OP) {
                StateType digest_in_state = this.get_state(index);
                this.set_state(index, (StateType)digest);
                bit<32> ret = 0;
                if (digest_in_state == (StateType)digest) 
                    ret = 1;
                if (digest_in_state == 0) 
                    ret = ret | 2;
                return ret;
            }
        }
    };
    apply {
        result = PLT_bloom_filter_way.execute_instr(PLT_BF_OP, index, metadata.latency_digest, 0);
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

