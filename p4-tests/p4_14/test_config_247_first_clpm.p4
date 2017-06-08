/* #include "tofino/intrinsic_metadata.p4" */

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

action do_nothing(){}

action set_dst_addr(dst){
   modify_field(ipv4.dstAddr, dst);
}


@pragma clpm_prefix ipv4.dstAddr
@pragma clpm_prefix_length 8
@pragma clpm_prefix_length 16
@pragma clpm_prefix_length 24
@pragma clpm_prefix_length 32
table clpm_table {
    reads {
        ipv4.dstAddr : lpm;
        ipv4.ttl : exact;

    }
    actions {
        do_nothing;
        set_dst_addr;
    }
    size : 16384;
}

table blah {
    reads {
        ipv4.ttl : exact;
    }
    actions {
        do_nothing;
    }
    size : 256;
}


control ingress {
  //apply(blah);
  if (ethernet.valid == 1 and ipv4.valid == 1){
      apply(clpm_table);
  }
}

control egress {
}