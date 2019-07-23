#include <tofino/intrinsic_metadata.p4>

header_type sample_t {
    fields {
        a : 16;
        b: 16;
        c : 16;
        csum : 16;
    }
}

header_type metadata_t {
    fields {
        meta_zeros_as_ones : 1;
        meta_no_zeros_as_ones : 1;
    }
}

header sample_t sample1;
header sample_t sample2;
metadata metadata_t meta;

field_list my_checksum_list {
        sample1.a;
        sample1.b;
        sample2.a;
        sample2.b;
        sample2.c;
        sample2.csum;
}

@pragma calculated_field_update_location ingress
field_list_calculation checksum_zeros_as_ones {
    input {
        my_checksum_list;
    }
    algorithm : csum16_udp;
    output_width : 16;
}

@pragma calculated_field_update_location ingress
field_list_calculation checksum_no_zeros_as_ones {
    input {
        my_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field sample1.csum  {
    update checksum_zeros_as_ones if (meta.meta_zeros_as_ones == 1);
    update checksum_no_zeros_as_ones if (meta.meta_no_zeros_as_ones == 1);
}

parser start {
    extract(sample1);
    extract(sample2);
    return ingress;
}

action act() {
    ig_intr_md_for_tm.ucast_egress_port = 1;
}

action set_zeros_as_ones() {
    meta.meta_zeros_as_ones = 1;
    meta.meta_no_zeros_as_ones= 0;
}

action set_no_zeros_as_ones() {
    meta.meta_zeros_as_ones = 0;
    meta.meta_no_zeros_as_ones = 1;
}

table test {
    reads {
        sample1.a : exact;
    }
    actions {
        act;
    }
}

table test_zeros_as_ones {
    reads {
        sample1.a : exact;
    }
    actions {
        set_zeros_as_ones;
        set_no_zeros_as_ones;
    }
}

control ingress {
    apply(test_zeros_as_ones);
    apply(test);
}

control egress {
}
