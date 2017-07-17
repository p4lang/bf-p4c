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

@pragma pa_container_size ingress ipv4.hdrChecksum 32
@pragma pa_container_size ingress ipv4.identification 32
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

/* Hash computations */

field_list_calculation calc_1 {
   input {
      fl_1;
   }
   algorithm : crc16;
   output_width : 16;
}

field_list_calculation calc_2 {
   input {
      fl_2;
   }
   algorithm : crc_16_maxim;
   output_width : 16;
}


/* Actions */

action do_nothing(){}

action a_1(){
    modify_field_with_hash_based_offset(ipv4.identification, 0, calc_1, 65536);
}

action a_2(){
    modify_field_with_hash_based_offset(ipv4.hdrChecksum, 0, calc_2, 65536);
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
      a_2;
   }
   size : 512;
}

table t2 {
   actions {
      set_p;
   }
}

/* Control */

control ingress {
    apply(t1);
    apply(t2);
}