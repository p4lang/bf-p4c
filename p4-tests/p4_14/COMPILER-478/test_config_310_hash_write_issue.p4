#include "tofino/intrinsic_metadata.p4"
#include "tofino/stateful_alu_blackbox.p4"

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

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

header ethernet_t ethernet;
header ipv4_t ipv4;



field_list fl_1 {
    ethernet.etherType;
    ipv4.dstAddr;
    ipv4.srcAddr;
}

field_list_calculation fl_calc {
   input {
       fl_1;
   }
   algorithm : identity;
   output_width : 16;
}


action do_nothing(){}

action set_p(p){
   modify_field(ig_intr_md_for_tm.ucast_egress_port, p);
}

register reg_1 {
    width : 16;
    instance_count : 8192;
}

blackbox stateful_alu alu_1 {
    reg: reg_1;
    update_lo_1_value : register_lo + 2;
}

action run_reg() { 
     alu_1.execute_stateful_alu_from_hash(fl_calc);
}

table t1 {
    actions { 
        run_reg;
        do_nothing;
    }
    default_action: do_nothing();
    size: 1;
}

table t2 {
    actions {
       set_p;
    }
    default_action : set_p(0);
    size : 1;
}

control ingress {
   if (valid(ethernet)){
      apply(t1);
   }
   apply(t2);
}