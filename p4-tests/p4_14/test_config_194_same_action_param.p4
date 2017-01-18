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

        field_m_16 : 16;

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

action do_nothing(){}

action action_0(param_0) {
    bit_xor(pkt.field_f_16, pkt.field_g_16, param_0); 
    modify_field(pkt.field_e_16, param_0);
}

@pragma immediate 0
table table_0 {
    reads {
         pkt.field_l_8 : ternary;
         
         pkt.field_a_32 : ternary;
         pkt.field_b_32 : exact;
         pkt.field_c_32 : exact;
         pkt.field_e_16 : exact;
 
    }
    actions {
        action_0;
        do_nothing;
    }
    size : 256;
}

action action_1(param_1){
    bit_xor(pkt.field_a_32, pkt.field_a_32, param_1);
    modify_field(pkt.field_b_32, param_1);
}


@pragma immediate 0
table table_1 {
    reads {
         pkt.field_a_32 mask 0xff: ternary;
    }
    actions {
        action_1;
    }
    size : 256;
}

table table_2 {
    actions {
        action_1;
        //drop_me;
    }
}

@pragma random_seed 0x4567
table table_3 {
    reads {
        pkt.field_j_8 : exact;
    }
    actions {
       do_nothing;
    }
}    

action drop_me(){
   drop();
}

/*
action action_e(param0, param1){
    modify_field(pkt.field_a_32, param0);
    modify_field(pkt.field_b_32, param1);
}
*/

table table_e {
    reads { 
         pkt.field_a_32: ternary;
    }
    actions {
        do_nothing;
        drop_me;
    }
    size : 36864; //512;
}

action set_ifindex(){
    no_op();
}

table phase0 {
    reads {
        ig_intr_md.ingress_port : exact;
    }
    actions {
        set_ifindex;
    }
    size : 128;
}


control ingress {

    if (ig_intr_md.resubmit_flag == 0){
        //apply(phase0);
    }

    apply(table_0) {
       action_0 {
           apply(table_1);
           apply(table_2);
       }
    }
    apply(table_3);

/*
    if (pkt.field_j_8 == 1) {
        apply(table_0);
    } else {
        apply(table_1);
        apply(table_2);
    }
    apply(table_3);
*/

}


control egress {
    apply(table_e);
}
