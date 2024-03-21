#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include <tofino/primitives.p4>

header_type global_meta_t {
    fields {
        padding: 8;
#ifdef CASE_FIX
        enable_checksum_update : 1;
#endif
    }
}
metadata global_meta_t global_meta;

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
        dscp : 6; /* ToS = DiffServ = | dscp (6 bytes) | ECN (2 bytes) |*/
        ecn : 2;
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
    }
}
header_type tcp_cksum_t{
    fields{
        checksum : 16;
        urgentPtr : 16;
    }
}
// Ethernet
header ethernet_t ethernet;
parser start {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

header ipv4_t ipv4;
parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.protocol) {
        0x6 : parse_tcp_v4;
        default: ingress;
    }
}

// TCP
field_list tcp_checksum_list_v4 {
        ipv4.srcAddr;
        ipv4.dstAddr;
        8'0;
        ipv4.protocol;
        ipv4.totalLen;
        tcp.srcPort;
        tcp.dstPort;
        tcp.seqNo;
        tcp.ackNo;
        tcp.dataOffset;
        tcp.res;
        tcp.ecn;
        tcp.ctrl;
        tcp.window;
        tcp_cksum_v4.urgentPtr;
        payload;
}

field_list_calculation tcp_checksum_v4 {
    input {
        tcp_checksum_list_v4;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field tcp_cksum_v4.checksum {
    update tcp_checksum_v4
#ifdef CASE_FIX
    if (global_meta.enable_checksum_update == 1)
#endif
    ;
}

header tcp_t tcp;
header tcp_cksum_t tcp_cksum_v4;
parser parse_tcp_v4 {
    extract(tcp);
    extract(tcp_cksum_v4);
    return ingress;
}

action set_output(){
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}
table set_output{
    actions {
        set_output;
    }
}
control ingress
{
    apply(set_output);
}

action clone(){
    drop();
    clone_e2e(1);
#ifdef CASE_FIX
    modify_field(global_meta.enable_checksum_update, 1);
#endif
}

table clone{
    actions{
        clone;
    }
}

control egress
{
    if (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED) {
       apply(clone);
    } 
}

