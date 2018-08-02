#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include <tofino/primitives.p4>

header_type special_header_t {
    fields {
        __padding: 96;
        etherType: 16;
    }
}
header_type special_stack_t {
    fields {
        field : 24;
        __padding: 7;
        bos: 1;
    }
}

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
        dscp : 6;
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


parser start {
    return select (current(96, 16)) {
        0x0104: parse_special_header;
        default: parse_ethernet;
    }
}




header special_header_t special_header;
header special_stack_t special_stack[3];
parser parse_special_header {
    extract(special_header);
    return parse_special_stack;
}
parser parse_special_stack {
    extract(special_stack[next]);
    return select(latest.bos) {
        1: parse_ethernet;
        default: parse_special_stack;
    }
}



header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        0x0800 : parse_ipv4;
        default: ingress;
    }
}



field_list ipv4_field_list {
    ipv4.version;
    ipv4.ihl;
    ipv4.dscp;
    ipv4.ecn;
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
    verify ipv4_chksum_calc;
    update ipv4_chksum_calc;
}

header ipv4_t ipv4;

parser parse_ipv4 {
    extract(ipv4);

    return select(latest.fragOffset, latest.protocol) {
        0x6 : parse_tcp_v4;
        default: ingress;
    }
}




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
    update tcp_checksum_v4 ;
}


header tcp_t tcp;
header tcp_cksum_t tcp_cksum_v4;

parser parse_tcp_v4 {
    extract(tcp);
    extract(tcp_cksum_v4);
    return ingress;
}



action output_inport()
{
    modify_field( ig_intr_md_for_tm.ucast_egress_port, ig_intr_md.ingress_port );
}
table table0 {
	actions {
		output_inport;
	}
}


control ingress {
    if (ig_intr_md_from_parser_aux.ingress_parser_err == 0 or
    	ig_intr_md_from_parser_aux.ingress_parser_err != 0)
    {
	     apply(table0);
    }
}

control egress {

}

