#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        field_a_32 : 32;
        field_b_32 : 32;
        field_c_32 : 32;
        field_d_32 : 32;

        field_e_16 : 16;
        field_f_16 : 16;
        field_g_16 : 16;
        field_h_16 : 16;

        field_i_8 : 8;
        field_j_8 : 8;
        field_k_8 : 8;
        field_l_8 : 8;

    }
}

parser start {
    return parse_ethernet;
}

header pkt_t pkt;

parser parse_ethernet {
    extract(pkt);
    return ingress;
}



register r_test {
    width : 8;
    direct : t_test;
}

blackbox stateful_alu b_test {
    reg: r_test;

    condition_lo: register_lo == 0x00;
    condition_hi: register_lo == 1;

    /* decrement the counter if offload is in effect */
    update_lo_1_predicate: not condition_lo;
    update_lo_1_value: register_lo - 1;

    /* 
     * This is an 8 bit register, the hi_1/2 values are
     * computed but not written back to the register, instead
     * alu_hi_1/2 outputs are OR-ed together and used as an output
     */
    update_hi_1_predicate: condition_hi;
    update_hi_1_value: 1; /* timeout  - bit 0 */

    update_hi_2_predicate: condition_lo;
    update_hi_2_value: 2; /* no offload  - bit 1 */

    output_dst: pkt.field_k_8;
    output_value: alu_hi; /* 'b00=Normal, 'b01=timeout, 'b10=drop, 'b11=NA */
}

action a_test(){
    b_test.execute_stateful_alu();
}

table t_test {
    reads {
        pkt.field_a_32 : exact;
    }
    
    actions {
        a_test;
    }
    size : 4096;
}

/* Main control flow */

control ingress {
    apply(t_test);
}
