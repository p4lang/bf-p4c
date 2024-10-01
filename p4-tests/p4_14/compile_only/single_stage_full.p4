@pragma command_line --disable-parse-max-depth-limit

#include "tofino/intrinsic_metadata.p4"

#define TCAM_TABLE_SIZE          12288

/* Sample P4 program */
header_type ethernet_t {
    fields {
        etherType : 16;
        exm_key1 : 904;
        exm_key2 : 520;
        tcam_key1 : 40;
    }
}

parser start {
    return parse_ethernet;
}


parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        default: ingress;
    }
}

header ethernet_t ethernet;

action do_nothing(){}

@pragma simul_lookups 10
table exm_table0 {
      reads {
        ethernet.exm_key1 : exact;
      }
      actions {
        do_nothing;
      }
      size : 10240;
}


table tcam_table0 {
      reads {
        ethernet.tcam_key1 : ternary;
      }
      actions {
        do_nothing;
      }
      size: TCAM_TABLE_SIZE;
}

control ingress {
    apply(exm_table0);
    apply(tcam_table0);
}
