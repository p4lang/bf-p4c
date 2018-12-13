#include "tofino/intrinsic_metadata.p4"

header_type ethernet_t {
    fields {
        dmac : 48;
        smac : 48;
        ethertype : 16;
    }
}
header ethernet_t ethernet;

header_type ipv4_t {
    fields {
        ver : 4;
        len : 4;
        diffserv : 8;
        totalLen : 16;
        id : 16;
        flags : 3;
        offset : 13;
        ttl : 8;
        proto : 8;
        csum : 16;
        sip : 32;
        dip : 32;
    }
}
header ipv4_t ipv4;

header_type tcp_t {
    fields {
        sPort : 16;
        dPort : 16;
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
header tcp_t tcp;

header_type user_metadata_t {
    fields {
        bf_tmp : 1;
    }
}
metadata user_metadata_t md;

parser start {
    return parse_ethernet;
}

parser parse_ethernet {
    extract(ethernet);
    return select(latest.ethertype) {
        0x0800 : parse_ipv4;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.proto) {
        6 : parse_tcp;
    }
}
parser parse_tcp {
    extract(tcp);
    return ingress;
}

field_list ip_fields {
    ipv4.proto;
    ipv4.sip;
    ipv4.dip;
}

field_list mirror_fields {
    ip_fields;
    tcp.sPort;
    tcp.dPort;
}

action mirror_packet() {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, 2);
    clone_ingress_pkt_to_egress(0, mirror_fields);
}

table test1 {
    actions { mirror_packet; }
    default_action : mirror_packet;
    size : 1;
}

control ingress {
    apply(test1);
}
