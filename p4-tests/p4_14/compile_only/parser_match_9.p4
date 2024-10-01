#define IP_PROTOCOLS_IPHL_TCP 0x506
#define IP_PROTOCOLS_IPHL_UDP 0x511
#define UDP_PORT_VXLAN 4789
#define UDP_PORT_GENV 6081

#define ETHERTYPE_IPV4         0x0800
#define ETHERTYPE_ETHERNET     0x6558

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ethernet;

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

header ipv4_t ipv4;
header ipv6_t ipv6;

header_type tcp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        seqNo   : 32;
        ackNo   : 32;
        dataOffset : 4;
        res : 4;
        flags : 8;
        window : 16;
        checksum : 16;
        urgentPtr : 16;

    }
}

header tcp_t tcp;

header_type udp_t {
    fields {
        srcPort : 16;
        dstPort : 16;
        len : 16;
        checksum : 16;
    }
}

header udp_t udp;

parser start {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800: parse_ipv4;
        0x86dd: parse_ipv6;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(latest.fragOffset, latest.ihl, latest.protocol) {
        IP_PROTOCOLS_IPHL_TCP: parse_tcp;
        IP_PROTOCOLS_IPHL_UDP: parse_udp;
        default: ingress;
    }
}

parser parse_ipv6 {
    extract(ipv6);
    return select(latest.nextHdr) {
        IP_PROTOCOLS_IPHL_TCP: parse_tcp;
        IP_PROTOCOLS_IPHL_UDP: parse_udp;
        default: ingress;
    }
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return select(latest.dstPort) {
        0x4118: parse_vxlan;
        default: ingress;
    }
}

header_type vxlan_t {
    fields {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}

header vxlan_t vxlan;

parser parse_vxlan {
    extract(vxlan);
    return ingress;
}

control ingress { }
