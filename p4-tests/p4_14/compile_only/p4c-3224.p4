/* -*- P4_14 -*- */

#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>
#define DDOS_TEST_PORT 0x00
#define DDOS_OUT_PORT 0x01

header_type ethernet_t {
    fields {
        dstAddr: 48;
        srcAddr: 48;
        etherType: 16;
    }
}

header ethernet_t ethernet;

header_type ipv4_t {
    fields {
        version: 4;
        ihl: 4;
        diffserv: 8;
        totalLen: 16;
        identification: 16;
        flags: 3;
        fragOffset: 13;
        ttl: 8;
        protocol: 8;
        hdrChecksum: 16;
        srcAddr: 32;
        dstAddr: 32;
    }
}
header ipv4_t ipv4;

header_type tcp_t {
    fields {
        srcPort: 16;
        dstPort: 16;
        seqNo: 32;
        ackNo: 32;
        dataOffset: 4;
        res: 3;
        ecn: 3;
        ctrl: 6;
        window: 16;
        checksum: 16;
        urgentPtr: 16;
    }
}
header tcp_t tcp;

header_type udp_t {
    fields {
        srcPort: 16;
        dstPort: 16;
        pkt_length: 16;
        checksum: 16;
    }
}
header udp_t udp;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract (ethernet);
    return select (latest.etherType) {
        0x0800: parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract (ipv4);
    return select (latest.protocol) {
        6: parse_tcp;
        17: parse_udp;
        default: ingress;
    }
}

field_list ipv4_field_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.diffserv;
    ipv4.totalLen;
    ipv4.identification;
    ipv4.flags;
    ipv4.fragOffset;
    ipv4.ttl;
    ipv4.protocol;
    ipv4.srcAddr;
    ipv4.dstAddr;
}

field_list_calculation ipv4_chksum_calc {
    input {
        ipv4_field_list;
    }
    algorithm: csum16;
    output_width: 16;
}

calculated_field ipv4.hdrChecksum {
    update ipv4_chksum_calc;
}

parser parse_tcp {
    extract (tcp);
    return ingress;
}

parser parse_udp {
    extract (udp);
    return ingress;
}

header_type md_t {
    fields {
        temp:5;
        res_1: 1;
        res_2: 1;
        res_3: 1;
        res_4: 1;
        res_5: 1;
        index_1: 16;
        index_2: 16;
        index_3: 16;
        index_4: 16;
        index_5: 16;
        est_1: 32;
        est_2: 32;
        est_3: 32;
        est_4: 32;
        est_5: 32;
        threshold: 16;
        above_threshold: 1;
        hash_entry: 32;
        hash_hit: 1;
        match_hit: 1;
    }
}

field_list_calculation cs_index_hash_func_1 {
    input {
        key_fields;
    }
    algorithm : poly_0x11e12a711_init_0x00000000_xout_0ffffffff;
    output_width : 11;
}

register register_1 {
    width: 32;
    instance_count: 2048;
}

blackbox stateful_alu blackbox_1 {
    reg: register_1;
    condition_lo:          md.res_1 > 0;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value :    register_lo + 1;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value :    register_lo - 1;
    condition_hi:          md.res_1 > 0;
    update_hi_1_predicate: condition_hi;
    update_hi_1_value :    1+register_lo;
    update_hi_2_predicate: not condition_hi;
#ifdef CASE_FIX
    update_hi_2_value :    register_lo + 32w0xFFFF_FFFF;
#else 
    update_hi_2_value :    1-register_lo;
#endif
    output_value:          alu_hi;
    output_dst:            md.est_1;
}

table sketching_1_table {
    actions {
        sketching_1_act;
    }
    default_action: sketching_1_act;
}
action sketching_1_act () {
    blackbox_1.execute_stateful_alu_from_hash(cs_index_hash_func_1);
}

field_list key_fields {
    ipv4.srcAddr;
}

metadata md_t md;

control ingress {
    apply(sketching_1_table);
}

control egress {
}
