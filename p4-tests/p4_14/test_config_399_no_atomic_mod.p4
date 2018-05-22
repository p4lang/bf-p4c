#include "tofino/intrinsic_metadata.p4"

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}


header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;
header ipv4_t ipv4;

parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
  extract(ipv4);
  return ingress;
}

action do_nothing(){}

action set_pkt(m, p){
   modify_field(ethernet.dstAddr, m);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

@pragma disable_atomic_modify 1
table it0 {
   reads {
       ethernet.etherType: ternary;
   }
   actions {
       set_pkt;
       do_nothing;
   }
   size : 2048;
}


control ingress {
   apply(it0);
}

control egress {
}
