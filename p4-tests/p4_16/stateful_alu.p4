// Sample program using the stateful ALU
// Architectural definition

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
    // Constructor: Takes register size and initial value as well as the
    //              default/reset values of the parameters.
    //              All arguments but the register size are optional and
    //              default to zero.
    StatefulALU(bit<32> stateSize, bool dual_state,
                STATE_TYPE state1InitialValue,
                STATE_TYPE state2InitialValue,
                bit<32> p1, bit<32> p2, bit<32> p3, bit<32> p4);

    STATE_TYPE get_state_1( in bit<32> index );
    void       set_state_1( in bit<32> index, in STATE_TYPE new_value );
    STATE_TYPE get_state_2( in bit<32> index );
    void       set_state_2( in bit<32> index, in STATE_TYPE new_value );

    // Runtime (control plane) modifiable parameters.  Default value is
    // provided by the constructor, control plane will have set, reset, and get
    // functions.
    // Implementaions of condition1, condition2, and compute_update_* can read
    // these values as "this.getParam1()","this.getParam2()", etc. but they cannot be
    // written in the dataplane.
    bit<32> getParam1();
    bit<32> getParam2();
    bit<32> getParam3();
    bit<32> getParam4();

    // Used internally in execute_instr; returns the value of "dual_state"
    // passed in the constructor.
    bool has_state_2();

    // Virtual functions to optionally be implemented by the P4 author.  Note
    // that all of these take in an "instruction number" enum as the first
    // parameter.  This allows up to four implementations of each function to
    // provide a means for different actions to perform different operations on
    // the same state data.  Implementations should be structured as a switch
    // style statement on the instruction number and provide separate logic for
    // each case needed.

    // Two condition functions which follow the pattern of (+/-A) + (+/-B) op C
    // where op is standard boolean checks of <,<=,>,>=,!=, of ==, A is a phv
    // value, B is the register state, and C is a constant or parameter,
    // this.param1 for example.
    abstract bool condition1( in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2 ); // {return false;}
    abstract bool condition2( in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2 ); // {return false;}

    // Four functions following the pattern of A op B where A is a PHV or
    // parameter, B is the register state or parameter, and op is an
    // arithmetic or logical operator.
    abstract bit<32> compute_value_a_1( in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2 ); // {return 0;}
    abstract bit<32> compute_value_a_2( in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2 ); // {return 0;}
    abstract bit<32> compute_value_b_1( in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2 ); // {return 0;}
    abstract bit<32> compute_value_b_2( in op_num instr, in bit<32> index, in bit<32> phv1, in bit<32> phv2 ); // {return 0;}

    // Five condition functions.  Each implementation must be a boolean
    // expression of c1 and c2.  Examples include "not c1 and c2", "c2", "true".
    abstract bool run_a_1( in op_num instr, in bool c1, in bool c2 ); // {return false;}
    abstract bool run_a_2( in op_num instr, in bool c1, in bool c2 ); // {return false;}
    abstract bool run_b_1( in op_num instr, in bool c1, in bool c2 ); // {return false;}
    abstract bool run_b_2( in op_num instr, in bool c1, in bool c2 ); // {return false;}
    abstract bool output_filter( in op_num instr, in bool c1, in bool c2 ); // {return false}

    // The "run" function callable from an action with a fixed implementation
    // that uses the abstract functions above.  For documentation purposes the
    // fixed implementation is shown below in comments.
    bit<32> execute_instr( in op_num instr, in output_mode omode, in bit<32> index, in bit<32> phv1, in bit<32> phv2 );
    /*
    {
        bit<32> state_1 = get_state_1(index);
        bit<32> state_2 = 0;
        if ( has_state_2() )
            state_2 = get_state_2(index);

        bool c1 = condition1(instr, index, phv1, phv2);
        bool c2 = condition2(instr, index, phv1, phv2);

        bit<32> a_1 = 0, a_2 = 0; 
        bit<32> b_1 = 0, b_2 = 0; 

        bool do_a1 = run_a_1(instr, c1,c2);
        bool do_a2 = run_a_2(instr, c1,c2);
        if (do_a1) a_1 = compute_value_a_1(instr, index, phv1, phv2);
        if (do_a2) a_2 = compute_value_a_2(instr, index, phv1, phv2);

        bool do_b1 = run_b_1(instr, c1, c2);
        bool do_b2 = run_b_2(instr, c1, c2);
        if (do_b1) b_1 = compute_value_b_1(instr, index, phv1, phv2);
        if (do_b2) b_2 = compute_value_b_2(instr, index, phv1, phv2);

        if (do_a1 or do_a2)
            state1.set( index, a_1 | a_2 );
        if ((do_b1 or do_b2) and has_state_2() )
            state2.set( index, b_1 | b_2 );

        bit<32> ret = 0;
        if ( output_filter(instr, c1, c2) ) {
            if (PHV1 == omode) {
                ret =  phv1;
            } else if (PHV2 == omode) {
                ret =  phv2;
            } else if (STATE_1_ORIGINAL == omode) {
                ret =  state_a;
            } else if (STATE_2_ORIGINAL == omode) {
                ret =  state_b;
            } else if (VALUE_A == omode) {
                ret =  a_1 | a_2;
            } else if (VALUE_B == omode) {
                ret =  b_1 | b_2;
            } else if (CONDITION_COMBINED == omode) {
                ret =  1;
            } else if (CONDITION == omode) {
                if (    c1 and     c2) ret = 8;
                if (    c1 and not c2) ret = 4;
                if (not c1 and     c2) ret = 2;
                if (not c1 and not c2) ret = 1;
            }
        }
        return ret;
    }
    */
}

// user-defined part

struct Metadata {
    bit<32> result;
    bit<32> latency_digest;
}

const op_num PLT_BF_OP = op_num.INSTRUCTION_1;
typedef bit<16> StateType;

control PLT_bloom_filter_way_ctrl(in bit<32> index, in Metadata metadata, out bit<32> result) {

    StatefulALU<StateType>(256*1024, false, 0, 0, 0, 0, 0, 0) PLT_bloom_filter_way = {
        bool condition1( in op_num instr, in bit<32> index, in bit<32> digest, in bit<32> unused) {
            if (instr == PLT_BF_OP) {
                StateType digest_in_state = this.get_state_1( index );
                return digest_in_state == (StateType)digest;
            }
            return false;
        }
        bool condition2( in op_num instr, in bit<32> index, in bit<32> unused1, in bit<32> unused2 ) {
            if (instr == PLT_BF_OP) {
                StateType digest_in_state = this.get_state_1( index );
                return digest_in_state == 0;
            }
            return false;
        }
        bit<32> compute_value_a_1( in op_num instr, in bit<32> index, in bit<32> digest, in bit<32> unused ) {
            if (instr == PLT_BF_OP) return digest;
            return 0;
        }
        bit<32> compute_value_a_2( in op_num instr, in bit<32> index, in bit<32> digest, in bit<32> unused ) {
            return 0;
        }
        bit<32> compute_value_b_1( in op_num instr, in bit<32> index, in bit<32> unused1, in bit<32> unused2 ) {
            if (instr == PLT_BF_OP) return 1;
            return 0;
        }
        bit<32> compute_value_b_2( in op_num instr, in bit<32> index, in bit<32> unused1, in bit<32> unused2 ) {
            if (instr == PLT_BF_OP) return 2;
            return 0;
        }
        bool run_a_1( in op_num instr, in bool c1, in bool c2 ) {
            if (instr == PLT_BF_OP) return true;
            return false;
        }
        bool run_a_2( in op_num instr, in bool c1, in bool c2 ) { return false; }
        bool run_b_1( in op_num instr, in bool c1, in bool c2 ) {
            if (instr == PLT_BF_OP) return c1;
            return false;
        }
        bool run_b_2( in op_num instr, in bool c1, in bool c2 ) {
            if (instr == PLT_BF_OP) return c2;
            return false;
        }
        bool output_filter( in op_num instr, in bool c1, in bool c2 ) {
            if (instr == PLT_BF_OP) return c1 || c2;
            return false;
        }
    };

    apply {
        result = PLT_bloom_filter_way.execute_instr( PLT_BF_OP, output_mode.VALUE_B, index, metadata.latency_digest, 0 );
    }
}

control master(inout Metadata metadata) {
    PLT_bloom_filter_way_ctrl() way1;
    PLT_bloom_filter_way_ctrl() way2;
    PLT_bloom_filter_way_ctrl() way3;
    apply {
        // Other logic here to compute index with hashing.
        // Just assume index1, 2 and 3 have been set using three different
        // hashes of packet fields.
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
