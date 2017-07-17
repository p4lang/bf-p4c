#include "tofino/intrinsic_metadata.p4"

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return ingress;
}

header ethernet_t ethernet;

action do_nothing(){}
action set_t(){
   modify_field(ethernet.etherType, 2);
}

table t0 {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      set_t;
      do_nothing;
   }
   size : 512;
}

control ingress {
    apply(t0);
}