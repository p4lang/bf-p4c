#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>


header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
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

header_type vxlan_t {
    fields {
        flags : 8;
        reserved : 24;
        vni : 24;
        reserved2 : 8;
    }
}

header ethernet_t ethernet;
header ethernet_t inner_ethernet;
header ipv4_t ipv4;
header vxlan_t vxlan;
header ipv4_t inner_ipv4;
header udp_t udp;
header tcp_t tcp;
header tcp_t inner_tcp;

parser start {
    extract(ethernet);
    return select(ethernet.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}

parser parse_ipv4 {
    extract(ipv4);
    return select(ipv4.fragOffset, ipv4.protocol) {
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
    return select(udp.dstPort) {
        0x1234 : parse_vxlan;
    }
}

parser parse_vxlan {
    extract(vxlan);
    return parse_inner_ethernet;
}

parser parse_inner_ethernet {
    extract(inner_ethernet);
    return parse_inner_ipv4;
}

parser parse_inner_ipv4 {
    extract(inner_ipv4);
    return parse_inner_tcp;
}

parser parse_inner_tcp {
    extract(inner_tcp);
    return ingress;
}

field_list inner_tcp_checksum_list {
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
    8'0;
    inner_ipv4.protocol;
    inner_tcp.srcPort;
    inner_tcp.dstPort;
    inner_tcp.seqNo;
    inner_tcp.ackNo;
    inner_tcp.dataOffset;
    inner_tcp.res;
    inner_tcp.flags;
    inner_tcp.window;
    inner_tcp.urgentPtr;
    payload;
}
//@pragma calculated_field_update_location ingress
field_list_calculation inner_tcp_checksum {
    input {
        inner_tcp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field inner_tcp.checksum {
    update inner_tcp_checksum if (udp.valid == 1);
}


field_list inner_ipv4_checksum_list {
    inner_ipv4.version;
    inner_ipv4.ihl;
    inner_ipv4.diffserv;
    inner_ipv4.totalLen;
    inner_ipv4.identification;
    inner_ipv4.flags;
    inner_ipv4.fragOffset;
    inner_ipv4.ttl;
    inner_ipv4.protocol;
    inner_ipv4.srcAddr;
    inner_ipv4.dstAddr;
}

field_list_calculation inner_ipv4_csum {
    input {
        inner_ipv4_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}

calculated_field inner_ipv4.hdrChecksum {
    update inner_ipv4_csum;
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
//@pragma calculated_field_update_location egress
field_list_calculation tcp_checksum {
    input {
        tcp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}


calculated_field tcp.checksum {
    update tcp_checksum if (ethernet.valid == 1);

}

field_list udp_checksum_list {
    ipv4.srcAddr;
    ipv4.dstAddr;
    8'0;
    ipv4.protocol;
    udp.srcPort;
    udp.dstPort;
    payload;
}
//@pragma calculated_field_update_location egress
field_list_calculation udp_checksum {
    input {
        udp_checksum_list;
    }
    algorithm : csum16;
    output_width : 16;
}


calculated_field udp.checksum {
    update udp_checksum;

}

action vxlan_ip_tcp_to_ali(){
    copy_header(ipv4, inner_ipv4);
    copy_header(tcp, inner_tcp);
    copy_header(ethernet, inner_ethernet);

 //modify_field(nat_metadata.inner_tcp_data_offset, nat_metadata.outer_tcp_data_offset);

    remove_header(inner_tcp);

    add_header(udp);
    modify_field(udp.dstPort, 4789);
    modify_field(udp.checksum, 0);

    add(udp.length_, ipv4.totalLen, 30);

    //add_to_field(nat_metadata.outer_l4_len, 50);

    add_header(vxlan);
    modify_field(vxlan.flags, 0x8);
    modify_field(vxlan.reserved, 0);

    modify_field(vxlan.vni, 1035);
    modify_field(vxlan.reserved2, 0x0);

    modify_field(ipv4.protocol, 17);

    add_to_field(ipv4.totalLen, 50);

}

action set_egr(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
    modify_field(inner_tcp.srcPort, 0xAB0B);
}

action nop() {
}

table forward {
    reads {
        udp.dstPort : exact;
    }
    actions {
        set_egr;
  nop;
    }
    size : 256;
}

table my_inner_process {
    reads {
        ipv4.dstAddr : exact;
    }

    actions {
        vxlan_ip_tcp_to_ali;
    }

    size : 256;
}

control ingress {
    apply(forward);
}
control egress {
//    apply(my_inner_process);
}
