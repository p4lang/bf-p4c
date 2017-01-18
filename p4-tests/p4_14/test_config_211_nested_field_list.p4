
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

field_list l1 {
    pkt.field_e_16;
}

field_list l2 {
    l1;
    pkt.field_f_16;
    pkt.field_a_32;
}

field_list_calculation simple_hash {
    input { l2; }
    algorithm : crc16;
    output_width : 8;
}

action do_nothing(){ }

action action_0(){
    modify_field_with_hash_based_offset(pkt.field_i_8, 0, simple_hash, 256);
}

table table_0 {
    reads {
        pkt.field_a_32 : ternary;
    }
    actions {
        action_0;
        do_nothing;
    }
}

table table_1 {
    reads {
        pkt.field_b_32 : ternary;
    }
    actions {
        do_nothing;
    }
}


control ingress {
    apply(table_0);
}

