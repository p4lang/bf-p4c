#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>


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
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;
    }
}

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        length_ : 16;
        checksum : 16;
    }
}

header ethernet_t ethernet;
header ipv4_t ipv4;
header ipv6_t ipv6;
header ipv6_t dummy;
header udp_t udp;
header tcp_t tcp;

parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x0800 : parse_ipv4;
        0x0600 : parse_ipv6;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return parse_dummy;
}

parser parse_ipv6 {
    extract(ipv6);
    return parse_dummy;
}

// Only for test purposes
parser parse_dummy {
    extract(dummy);
    return select(dummy.nextHdr) {
        0x000006 : parse_tcp;
        0x000011 : parse_udp;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return ingress;
}

field_list tcp_checksum_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    8'0;
    ipv4.protocol;
    tcp.srcPort;
    tcp.dstPort;
    tcp.seqNo;
    tcp.ackNo;
    tcp.dataOffset;
    tcp.res;
    tcp.flags;
    tcp.window;
    tcp.urgentPtr;
    payload;
}
field_list_calculation tcp_checksum {
    input {
        tcp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

field_list tcpv6_checksum_list {
    ipv6.srcAddr;
    ipv6.dstAddr;
    8'0;
    ipv6.nextHdr;
    tcp.seqNo;
    tcp.ackNo;
    tcp.dataOffset;
    tcp.res;
    tcp.flags;
    tcp.window;
    tcp.urgentPtr;
    payload;
}
field_list_calculation tcpv6_checksum {
    input {
        tcpv6_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}


calculated_field tcp.checksum {
    update tcpv6_checksum;
    update tcp_checksum;

}

action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}

table forward {
    reads {
        ethernet.dstAddr : exact;
    }
    actions {
        set_egr;
    }
    size : 256;
}

control ingress {
    apply(forward);
}

control egress {
}


