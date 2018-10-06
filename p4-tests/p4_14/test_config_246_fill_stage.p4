#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */
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


parser parse_ethernet {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x800 : parse_ipv4;
        default: ingress;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

counter counter_0 {
    type : packets;
    static : simple_table;
    instance_count : 512;
}

counter counter_egress {
    type : packets;
    direct : simple_table_egress;
}

action do_nothing(){}

action set_dst_addr(idx){
   //modify_field(ipv4.dstAddr, dst);
   count(counter_0, idx);
}

action egress_action(idx){
    //count(counter_egress, idx);
}

@pragma use_identity_hash 1
@pragma immediate 0
table simple_table {
    reads {
        ethernet.srcAddr mask 0xFFFF : exact;
    }
    actions {
        do_nothing;
        set_dst_addr;
    }
    //size : 32768;
    size : 65536;
}

@pragma use_hash_action 1
table simple_table_egress {
    reads {
       ethernet.dstAddr mask 0x1FF : exact;        
    }
    actions {
        egress_action;
    }
    default_action : egress_action;
    size : 512;
}


control ingress {
  if (ethernet.valid == 1 and ipv4.valid == 1){
      apply(simple_table);
  }
}

control egress {
    apply(simple_table_egress);
}
