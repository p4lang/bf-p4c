#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
header_type pkt_t {
    fields {
        field_a : 8;
        field_b : 8;
        field_c : 8;
        field_d : 8;

        field_e : 8;
        field_f : 8;
        field_g : 8;
        field_h : 8;

        field_i : 8;
        field_j : 8;
        field_k : 8;
        field_l : 8;

        field_m : 8;
        field_n : 8;
        field_o : 8;
        field_p : 8;

        field_q : 8;
        field_r : 8;
        field_s : 8;
        field_t : 8;

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

action do_nothing(){   
}

table table_2_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_3_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}


table table_4_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_d : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_5_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;
        pkt.field_f : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_6_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;
        pkt.field_f : exact;
        pkt.field_g : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_7_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;
        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_8_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_9_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_10_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_11_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b mask 0xF8 : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
        pkt.field_l : exact;
    }
    actions {
        do_nothing;
    }
    size : 65536;
}

table table_12_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
        pkt.field_l : exact;
        pkt.field_m : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_13_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
        pkt.field_l : exact;
        pkt.field_m : exact;

        pkt.field_n : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_14_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
        pkt.field_l : exact;
        pkt.field_m : exact;

        pkt.field_n : exact;
        pkt.field_o : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_15_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
        pkt.field_l : exact;
        pkt.field_m : exact;

        pkt.field_n : exact;
        pkt.field_o : exact;
        pkt.field_p : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}

table table_16_bytes {
    reads {
        pkt.field_a : exact;
        pkt.field_b : exact;
        pkt.field_c : exact;
        pkt.field_e : exact;

        pkt.field_f : exact;
        pkt.field_g : exact;
        pkt.field_h : exact;
        pkt.field_i : exact;

        pkt.field_j : exact;
        pkt.field_k : exact;
        pkt.field_l : exact;
        pkt.field_r : exact;

        pkt.field_n : exact;
        pkt.field_o : exact;
        pkt.field_p : exact;
        pkt.field_q : exact;
    }
    actions {
        do_nothing;
    }
    size : 1024;
}


/* Main control flow */

control ingress {

    apply(table_2_bytes);
    apply(table_3_bytes);
    apply(table_4_bytes);
    apply(table_5_bytes);

    apply(table_6_bytes);
    apply(table_7_bytes);
    apply(table_8_bytes);
    apply(table_9_bytes);

    apply(table_10_bytes);

    apply(table_11_bytes);

    apply(table_12_bytes);
    apply(table_13_bytes);

    apply(table_14_bytes);
    apply(table_15_bytes);
    apply(table_16_bytes);

}
