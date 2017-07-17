#include "tofino/intrinsic_metadata.p4"

/* Sample P4 program */

header_type eth_t {
    fields {
         blah1 : 32;
         blah2 : 32;
         etype : 16;
         
   }
}

/*
header_type pkt_t {
    fields {
        a : 32;
        b : 32;
        c : 64;
        d : 8;
        e : 16;
        f : 16;
    }
}
*/

header_type pkt_t {
    fields {
        a : 8;
        b : 8;
        c : 8;
    }
}

header_type meta_t {
     fields {
        x : 8;
        y : 8;
     }
}

header eth_t eth;
@pragma pa_solitary ingress pkt_a.a
@pragma pa_container_size ingress pkt_a.b 16
header pkt_t pkt_a;
@pragma pa_solitary ingress pkt_b.a
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
    modify_field(meta.x, pkt_a.b);
}

action set_b(){
    modify_field(meta.x, pkt_b.b);
    modify_field(meta.y, pkt_a.c);  /* fields cannot coexist */

//    modify_field(pkt_b.b, meta.x);
//    modify_field(pkt_a.c, meta.y);  /* fields cannot coexist */
}

action set_blah(x){
    modify_field(eth.etype, x);
}

field_list flist {
    meta.x;
}

field_list_calculation hcalc {
    input {
        flist;
    }
    algorithm : crc32;
    output_width : 32;
}

action set_hash(){
    modify_field_with_hash_based_offset(eth.blah1, 0,
                                        hcalc, 4294967296);
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

table t_b {
    reads {
         pkt_b.a : exact;
    }
    actions {
         set_b;
         do_nothing;
    }
   
 size : 4096;
}

table t_last {
    reads {
         meta.x : ternary;
         meta.y : exact;
    }
    actions {
         set_blah;
         set_hash;
         do_nothing;
    }
   
 size : 512;
}

control ingress {
    if (pkt_a.valid == 1){
        apply(t_a);
    } else {
        apply(t_b);
    }
    apply(t_last);
}

control egress { }