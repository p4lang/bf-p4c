#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>

header_type ethernet_t {
    fields {
        dstAddr   : 48;
        srcAddr   : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version        : 4;
        ihl            : 4;
        diffserv       : 8;
        totalLen       : 16;
        identification : 16;
        flags          : 3;
        fragOffset     : 13;
        ttl            : 8;
        protocol       : 8;
        hdrChecksum    : 16;
        srcAddr        : 32;
        dstAddr        : 32;
    }
}

header_type ipv4_option_word_t {
    fields {
        data           : 32;
    }
}

header_type icmp_t {
    fields {
        typeCode : 16;
        hdrChecksum : 16;
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

header ethernet_t          ethernet;
header ipv4_t              ipv4;
header ipv4_option_word_t  ipv4_options[10];
header icmp_t              icmp;
header tcp_t               tcp;
header udp_t               udp;

parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    set_metadata(ig_prsr_ctrl.parser_counter, ipv4.ihl - 5);
    return select(ipv4.ihl) {
        0, 1, 2, 3, 4 : bad_ipv4;
        5 : parse_layer4;
        default : parse_ipv4_options;
    }
}

parser parse_ipv4_options {
    extract(ipv4_options[next]);
    set_metadata(ig_prsr_ctrl.parser_counter, ig_prsr_ctrl.parser_counter - 1);
    return select(_parser_counter_) {
        0 : parse_layer4;
        default: parse_ipv4_options;
    }
}

parser parse_layer4 {
    return select(ipv4.fragOffset, ipv4.protocol) {
        0x000001: parse_icmp;
        0x000006: parse_tcp;
        0x000011: parse_udp;
        default:  ingress;
    }
}

parser parse_icmp {
    extract(icmp);
    return ingress;
}

parser parse_tcp {
    extract(tcp);
    return ingress;
}

parser parse_udp {
    extract(udp);
    return ingress;
}

parser bad_ipv4 {
    return ingress;
}

control ingress {
}
