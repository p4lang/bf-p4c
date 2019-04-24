/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// This is P4 sample source for basic_switching

// Tirmazi: Implementation for DISTINCT with Multi-row LRU cache

#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include <tofino/stateful_alu_blackbox.p4>

#define VALUE_INT_MAX 2147483647 // INT_MAX

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pri     : 3;
        cfi     : 1;
        vlan_id : 12;
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

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo : 32;
        ackNo : 32;
        dataOffset : 4;
        res : 3;
        ecn : 3;
        ctrl : 6;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        hdr_length : 16;
        checksum : 16;
    }
}

/* Tirmazi: the cheetah header */
header_type cheetah_t {
    fields {
        flowId : 16;
        rowId : 32;
        value_hi : 32;
        value_lo : 32;
    }
}

/* Tirmazi: cheetah metadata is here */
header_type cheetah_md_t {
    fields {
        rowId : 32;
        prune : 8;
        replace_value_lo : 32;
        replace_value_hi : 32;
        equality_check_lo : 32;
        equality_check_hi : 32;
    }
}   

metadata cheetah_md_t cheetah_md;
metadata cheetah_md_t cheetah_md_2;

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x800 : parse_ipv4;
        default: ingress;
    }
}

#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        IP_PROTOCOLS_TCP : parse_tcp;
        IP_PROTOCOLS_UDP : parse_udp;
        default: ingress;
    }
}

header vlan_tag_t vlan_tag;

parser parse_vlan_tag {
    extract(vlan_tag);
    return select(latest.etherType) {
        0x800 : parse_ipv4;
        default : ingress;
    }
}

header tcp_t tcp;

parser parse_tcp {
    extract(tcp);
    return ingress;
}

header udp_t udp;

parser parse_udp {
    extract(udp);
    return parse_cheetah;
} 

/* Tirmazi: Adding cheetah parser */
header cheetah_t cheetah;

parser parse_cheetah {
    extract(cheetah);
    set_metadata(cheetah_md.rowId, cheetah.rowId);
    return ingress;
}   

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

action nop() {
}

action _drop() {
    drop();
}

action copy_to_metadata_action() {
    modify_field(cheetah_md.replace_value_lo, cheetah.value_lo);
    modify_field(cheetah_md.replace_value_hi, cheetah.value_hi);
}

@pragma stage 0
table metadata_copy_table {
    reads {
        cheetah.flowId : exact;
    }

    actions {
        copy_to_metadata_action;
    }

    default_action : copy_to_metadata_action();
}


/* Tirmazi: placeholder prune action */
action prune() {
    drop();
}

@pragma stage 3
table prune_check {
    reads {
        cheetah_md.equality_check_hi : exact;
        cheetah_md.equality_check_lo : exact;
    }

    actions {
        nop;
        prune;
    }

    default_action : nop;
}
table forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_egr; nop;
    }
    default_action: set_egr(40);
}

table acl {
    reads {
        ethernet.dstAddr : ternary;
        ethernet.srcAddr : ternary;
    }
    actions {
        nop;
        _drop;
    }
}

control ingress {
    apply(metadata_copy_table);
#ifdef CASE_FIX
    if ((cheetah_md.equality_check_hi  &  1 == 0) and 
        (cheetah_md.equality_check_lo  &  1 == 0)) {
#else
    if (cheetah_md.equality_check_hi & cheetah_md.equality_check_lo & 0x1 == 0) {
#endif
        apply(prune_check);
    }
    
    apply(forward);
}

control egress {
    // apply(cheetah_topn_t_three_table);  // stage 3
    // apply(debug_table_s3); // stage 3
    // apply(cheetah_topn_t_three_table_check); // stage 4
    apply(acl);
}
