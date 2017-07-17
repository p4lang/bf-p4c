#include "tofino/intrinsic_metadata.p4"

header_type pkt_t {
    fields {
        srcAddr : 32;
        dstAddr : 32;
        protocol : 8;
        srcPort : 16;
        dstPort : 16;
    }
}

header_type meta_t {
     fields {
        x : 16;
        y : 16;
     }
}

parser start {
    return parse_1;
}


header pkt_t pkt;
metadata meta_t meta;

parser parse_1 {
    extract(pkt);
    return ingress;
}

action do_nothing(){}

action action1(p){ 
    modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

@pragma pack 3
@pragma dynamic_table_key_masks 1
table table1 {
   reads {
       pkt.srcAddr mask 0xff : exact;
       pkt.srcPort : exact;
       pkt.protocol : exact;
   }
   actions {
       action1;
       do_nothing;
   }
   size : 4096;
}

control ingress {
   if (valid(pkt)){
      apply(table1);
   }
}