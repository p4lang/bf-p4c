#include "tofino/intrinsic_metadata.p4"

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

header_type conga_state_layout {
    fields {
        next_hop : 8;
        utilization : 8;
    }
}

parser start {
    return parse_ethernet;
}

header pkt_t pkt;
//metadata conga_state_layout conga_state;

parser parse_ethernet {
    extract(pkt);
    return ingress;
}


register conga_state {
    layout : conga_state_layout;
    direct : conga_rd_next_hop_table;
    //instance_count : 256;
}

/*
stateful_alu conga_alu {
    register: conga_state_layout;
    output_expr: new_hi;
    output_dst: ingress_md.next_hop;
}

stateful_alu conga_update_alu {
    register: conga_state_layout;
    condition_a: register_lo >  conga_state_md.util
    condition_b: register_hi == conga_state_md.next_hop
    update_hi_1_predicate: a;
    update_hi_1_value: conga_state_md.next_hop;
    update_lo_1_predicate: a || b;
    update_lo_1_value: conga_state_md.util
    output_expr: new_hi;
    output_dst: ingress_md.next_hop;
}
*/

action get_preferred_next_hop(){
    //execute_stateful_alu(conga_alu);
}

action update_preferred_next_hop(){
    //execute_stateful_alu(conga_update_alu);
}


action do_nothing() { }


table conga_rd_next_hop_table {
    reads {
        //ingress_md.dst_tor_id : exact;
        pkt.field_e_16 : ternary;
    }
    actions {
       get_preferred_next_hop;

    }
    size : 256;
}
 
table conga_wr_next_hop_table {
    reads {
        //ingress_md.dst_tor_id : exact;
        pkt.field_f_16 : ternary;
    }
    actions {
        update_preferred_next_hop;
    }
    size : 256;
}


/* Main control flow */

control ingress {
    apply(conga_rd_next_hop_table);
    apply(conga_wr_next_hop_table);
}
