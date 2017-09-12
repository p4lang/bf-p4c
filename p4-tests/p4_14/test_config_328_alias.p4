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

header_type meta_t {
    fields {
         mac_da : 48;
         x : 8;
         y : 8;
         z : 8;   
    }
}

parser start {
    return parse_ethernet;
}

@pragma pa_alias ingress ethernet.dstAddr meta.mac_da
header ethernet_t ethernet;
header ipv4_t ipv4;

@pragma pa_alias ingress meta.x meta.y
metadata meta_t meta;

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



action action_0(p){
    modify_field(meta.mac_da, ethernet.dstAddr);
    modify_field(ipv4.diffserv, p);
    modify_field(meta.x, ipv4.protocol);
}

action set_p(p){
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p); 
}

action do_nothing(){}

@pragma command_line --no-dead-code-elimination
table table_0 {
   reads {
     ethernet.etherType : ternary;
   }       
   actions {
     action_0;
     do_nothing;
   }
   default_action: action_0(5);
   size : 256;

}

table table_1 {
   reads {
     meta.mac_da : exact;
     meta.y : exact;   /* should have value of meta.x */
   }       
   actions {
     set_p;
     do_nothing;
   }
   default_action: set_p(7);
   size : 256;

}


/* Main control flow */

control ingress {
    if (ethernet.valid == 1){
        apply(table_0);
        apply(table_1);
    }
}
