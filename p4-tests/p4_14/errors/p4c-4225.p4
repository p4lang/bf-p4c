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

#include "tofino/intrinsic_metadata.p4"


/* Sample P4 program */
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}
//Modified by Jason

header_type vlan_tag_t {
    fields {
        pri : 3;
        cfi : 1;
        pad : 4;
        vlan_id : 24;
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

header_type ipv6_t {
    fields {
        version : 4;
        trafficClass : 8;
        flowLabel : 20;
        payloadLen : 16;
        nextHdr : 8;
        hopLimit : 8;
        srcAddr : 128;
        dstAddr : 128;
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

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x8100 : parse_vlan_tag;
        0x800 : parse_ipv4;
        0x86dd : parse_ipv6;
        default: ingress;
    }
}




header ipv4_t ipv4;
header ipv6_t ipv6;

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        6 : parse_tcp;
        17 : parse_udp;
        default: ingress;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        6 : parse_tcp;
        17 : parse_udp;
        default : ingress;
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
    return ingress;
}

header_type routing_metadata_t {
    fields {
        drop: 1;
    }
}

metadata routing_metadata_t /*metadata*/ routing_metadata;

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
    algorithm : csum16;
    output_width: 16;
}

calculated_field ipv4.hdrChecksum {
    update ipv4_chksum_calc;
}

counter cntr {
    type : packets;
    instance_count : 10240;
}

meter mtr {
    type : bytes;
    instance_count : 10240;
}

action tcp_sport_modify (sPort, port) {
    modify_field(tcp.srcPort, sPort);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action tcp_dport_modify (dPort, port) {
    modify_field(tcp.dstPort, dPort);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action ipsa_modify (ipsa, port, stat_idx, meter_idx) {
    modify_field(ipv4.srcAddr, ipsa);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
    count(cntr, stat_idx);
    execute_meter(mtr, meter_idx, ig_intr_md_for_tm.packet_color);
}

action ipda_modify (ipda, port) {
    modify_field(ipv4.dstAddr, ipda);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action ipds_modify(ds, port) {
    modify_field(ipv4.diffserv, ds);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action ipttl_modify(ttl, port) {
    modify_field(ipv4.ttl, ttl);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

// expect error@NO SOURCE: "The meter .* requires a stats address bus to return a color value, and no bus is available"
@pragma alpm 1
table match_tbl {
    reads {
        ipv4 : valid;
        ipv4.dstAddr : lpm;
        vlan_tag.vlan_id : exact;
    }

    actions {
        tcp_sport_modify;
        tcp_dport_modify;
        ipsa_modify;
        ipda_modify;
        ipds_modify;
        ipttl_modify;
    }

    size : 22528;
}

/* Main control flow */
control ingress {
    apply(match_tbl);
}

control egress {
}
