
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

action action_0(){ }
action action_1(){ }


table table_0 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_1 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_2 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_3 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_4 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_5 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_6 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_7 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_8 {
    reads { pkt.field_i_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_9 {
    reads { pkt.field_a_32 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 512;
}

@pragma ways 2
table table_a {
    reads { pkt.field_a_32 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 1024;
}

table table_b {
    reads { pkt.field_j_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_c {
    reads { pkt.field_k_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_d {
    reads { pkt.field_b_32 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 1024;
}

table table_e {
    reads { pkt.field_j_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

table table_f {
    reads { pkt.field_k_8 : exact; }
    actions {
        action_0;
        action_1;
    }
    size : 256;
}

control ingress {
    apply(table_0);
    apply(table_1);
    apply(table_2);
    apply(table_3);
    apply(table_4);
    apply(table_5);
    apply(table_6);
    apply(table_7);
    apply(table_8);
    apply(table_9);
    apply(table_a);
    apply(table_b);
    apply(table_c);
    apply(table_d);
    apply(table_e);
    apply(table_f);
}

