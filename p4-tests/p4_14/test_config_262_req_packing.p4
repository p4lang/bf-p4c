#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */

header_type eth_t {
    fields {
         blah1 : 32;
         blah2 : 32;
         etype : 16;
         
   }
}


header_type pkt_t {
    fields {
        a : 24;
        b : 24;
        c : 24;
        d : 24;
        e : 16;
    }
}

header_type meta_t {
     fields {
        x : 24;
        y : 24;
        z : 24;
     }
}

header eth_t eth;
@pragma pa_container_size ingress pkt_a.a 32
header pkt_t pkt_a;
header pkt_t pkt_b;
metadata meta_t meta;


parser start {
    return parse_eth;
}

parser parse_eth {
    extract(eth);
    return select(eth.etype) {
       0 : parse_a;
       default : parse_b;
    }
}


parser parse_a {
    extract(pkt_a);
    return ingress;
}

parser parse_b {
    extract(pkt_b);
    return ingress;
}


action do_nothing(){}

action set_a(){
    modify_field(meta.x, pkt_a.a);
    modify_field(meta.y, pkt_a.b);
    modify_field(meta.z, pkt_a.c);
}

action set_blah(x){
    modify_field(eth.etype, x);
}


table t_a {
    reads {
         pkt_a.a : exact;
    }
    actions {
         set_a;
         do_nothing;
    }
   
 size : 4096;
}

table t_last {
    reads {
         meta.x : ternary;
         meta.y : exact;
         meta.z : exact;
    }
    actions {
         set_blah;
         do_nothing;
    }
   
 size : 512;
}

control ingress {
    if (pkt_a.valid == 1){
        apply(t_a);
    }
    apply(t_last);
}

control egress { }