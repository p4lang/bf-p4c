#include "tofino/intrinsic_metadata.p4"
#include <tofino/stateful_alu_blackbox.p4>

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

header ethernet_t ethernet;
header ipv4_t ipv4;

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

/* Uses a register to do useless operations to test multiple instructions
 *    on a stateful ALU.
 */
register reg0 {
    width: 16;
    static: ipv4_lpm;
    instance_count: 512;
}

blackbox stateful_alu salu0 {
    initial_register_lo_value : 0;
    reg: reg0;
    update_lo_1_value: register_lo + 1;
}

/*
 * Comment out stats until memory issue is fixed
counter counter0 {
    type : packets;
    instance_count : 512;
}

counter counter1 {
    type : packets;
    direct : ipv4_lpm_stat;
}
 */

meter meter0 {
    type : bytes;
    static : ipv4_lpm;
    result : ipv4.diffserv;
    instance_count : 512;
}

action lpm_miss() {
    drop();
}

action lpm_hit(egress_port) {
   modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

/*
action lpm_hit_count(egress_port, idx) {
   count(counter0, idx);
   modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}
*/

action lpm_hit_stful(egress_port, index) {
    salu0.execute_stateful_alu(index);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
}

action lpm_hit_meter(egress_port, index) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_port);
    execute_meter(meter0, index, ipv4.diffserv);
}

@pragma clpm_prefix ipv4.dstAddr
@pragma clpm_prefix_length 1 7 512
@pragma clpm_prefix_length 8 1024
@pragma clpm_prefix_length 9 15 512
@pragma clpm_prefix_length 16 2048
@pragma clpm_prefix_length 17 23 512
@pragma clpm_prefix_length 24 2048
@pragma clpm_prefix_length 25 31 512
@pragma clpm_prefix_length 32 1024
table ipv4_lpm {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        lpm_hit;
        /* lpm_hit_count; */
        lpm_hit_stful;
        lpm_miss;
    }
    size : 8192;
}

@pragma clpm_prefix ipv4.dstAddr
@pragma clpm_prefix_length 1 15 8192
@pragma clpm_prefix_length 16 131072
@pragma clpm_prefix_length 17 23 8192
@pragma clpm_prefix_length 24 131072
@pragma clpm_prefix_length 25 31 8192
@pragma clpm_prefix_length 32 131072
table ipv4_lpm_large {
    reads {
        ipv4.dstAddr : lpm;
        ipv4.protocol : exact;
    }
    actions {
        lpm_hit;
        lpm_miss;
    }
    size : 417792;
}

/*
@pragma clpm_prefix ipv4.dstAddr
@pragma clpm_prefix_length 1 7 512
@pragma clpm_prefix_length 8 2048
@pragma clpm_prefix_length 9 23 512
@pragma clpm_prefix_length 24 2048
@pragma clpm_prefix_length 25 32 512
table ipv4_lpm_stat {
    reads {
        ipv4.dstAddr : lpm;
    }
    actions {
        lpm_hit;
    }
    size : 5632;
}
*/

action_profile lpm_actions {
    actions {
        lpm_hit;
        lpm_miss;
    }
    size : 512;
}

@pragma clpm_prefix ipv4.dstAddr
@pragma clpm_prefix_length 1 7 512
@pragma clpm_prefix_length 8 2048
@pragma clpm_prefix_length 9 23 512
@pragma clpm_prefix_length 24 2048
@pragma clpm_prefix_length 25 32 512
table ipv4_lpm_adt {
    reads {
        ipv4.dstAddr : lpm;
    }
    action_profile : lpm_actions;
    size : 5632;
}

@pragma clpm_prefix ipv4.dstAddr
@pragma clpm_prefix_length 1 7 512
@pragma clpm_prefix_length 8 2048
@pragma clpm_prefix_length 9 23 512
@pragma clpm_prefix_length 24 2048
@pragma clpm_prefix_length 25 32 512
table ipv4_lpm_idle {
    reads {
        ipv4.dstAddr: lpm;
    }
    actions {
        lpm_hit;
        lpm_miss;
    }
    size: 5632;
    support_timeout: true;
}

table non_ipv4 {
    actions { lpm_hit; }
    size: 1;
}

control ingress {
  if (valid(ethernet) and valid(ipv4)){
      apply(ipv4_lpm);
      apply(ipv4_lpm_large);
      /* apply(ipv4_lpm_stat); */
      apply(ipv4_lpm_adt);
      apply(ipv4_lpm_idle);
  } else {
      apply(non_ipv4);
  }
}

control egress {
}
