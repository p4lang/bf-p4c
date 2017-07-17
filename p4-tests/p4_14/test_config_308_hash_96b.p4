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

        extra_field : 32;
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

/* Field lists */

field_list fl_1 {
    ethernet.etherType;
    ipv4.dstAddr;
    ipv4.srcAddr;
}

field_list fl_2 {
    ethernet.dstAddr;
    ipv4.ttl;
    ipv4.protocol;
}

field_list fl_3 {
    ethernet.srcAddr;
    ethernet.dstAddr;
}


/* Hash computations */

field_list_calculation calc_1 {
   input {
      fl_1;
   }
   algorithm : crc32;
   output_width : 32;
}

field_list_calculation calc_2 {
   input {
      fl_2;
   }
   algorithm : crc_32_bzip2;
   output_width : 32;
}

field_list_calculation calc_3 {
   input {
      fl_3;
   }
   algorithm : crc_32_mpeg;
   output_width : 32;
}


/* Actions */

action do_nothing(){}

action a_1(){
    modify_field_with_hash_based_offset(ipv4.srcAddr, 0, calc_1, 4294967296);
}

action a_2(){
    modify_field_with_hash_based_offset(ipv4.dstAddr, 0, calc_2, 4294967296);
}

action a_3(){
    modify_field_with_hash_based_offset(ipv4.extra_field, 0, calc_3, 4294967296);
}

action set_p(p) { 
    modify_field(ig_intr_md_for_tm.ucast_egress_port, p); 
}


/* Tables */

table t1 {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      a_1;
      do_nothing;
   }
   size : 512;
}

table t2 {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      a_2;
      do_nothing;
   }
   size : 512;
}

table t3 {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      a_3;
      do_nothing;
   }
   size : 512;
}

table tp {
   reads {
      ethernet.etherType : ternary;
   }
   actions {
      set_p;
      do_nothing;
   }
   size : 512;
}


/* Control */

control ingress {
    apply(t1);
    apply(t2);
    apply(t3);
    apply(tp);
}