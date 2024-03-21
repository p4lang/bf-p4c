/*******************************************************************************
 the main file
 include main process block
 
 ******************************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "data.p4"
#include "util.p4"


// Ingress parser
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
		
		//init metadata
        ig_md.checksum_err = false;
        ig_md.nsh_form_err = false;
        ig_md.nsh_ttl_err = false;
		ig_md.bAddNsh = false;
		ig_md.bChangeNsh = false;
		ig_md.bRemoveNsh = false;
		
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_ipv4;
			ETHERTYPE_IPV6 : parse_ipv6;
			ETHERTYPE_NSH : parse_nsh;
            default : accept;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        ig_md.checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }

    state parse_nsh {
        pkt.extract(hdr.nsh_base);
        pkt.extract(hdr.nsh_type1_context);
        transition accept;
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
		
	//temp var
	bit<16> src_port = 0;
	bit<16> dst_port = 0;
	ipv4_addr_t ipv4_src = 0;
	ipv4_addr_t ipv4_dst = 0;
	bit<8> next_protocol = 0;
	
	//set forward port
	action SetForwardPort(in PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
	}
	
	//deal error, transparent forward to the report port
	action DealError() {
		SetForwardPort(EXCEPTION_REPORT_PORT);
	}
	
	//transparent forward to port
    action TransparentForward(PortId_t port) {
        SetForwardPort(port);
    }
	
	//add nsh header and forward
	action AddNshForward(PortId_t port, nsh_spi_t spi) {
		//set forward port
		SetForwardPort(port);
		
		//construct ethernet header
		hdr.outer_ethernet.setValid();
		hdr.outer_ethernet.ether_type = ETHERTYPE_NSH;
		
		//construct nsh header
		hdr.nsh_base.setValid();
		hdr.nsh_base.version = 0;
		hdr.nsh_base.oam = 0;
		hdr.nsh_base.undefined_1 = 0;
		hdr.nsh_base.ttl = 6w0x3f;
		hdr.nsh_base.len = 6;
		hdr.nsh_base.undefined_2 = 0;
		hdr.nsh_base.md_type = 1;
		hdr.nsh_base.next_protocol = NSH_PROTOCOLS_ETHERNET;
		hdr.nsh_base.spi = spi;
		hdr.nsh_base.si = 8w0xff;
		
		hdr.nsh_type1_context.setValid();
		hdr.nsh_type1_context.context = 0;
		
		//change flag
		ig_md.bAddNsh = true;
	}
	
	//ipv4 apply this table
	table tblIpv4Forward {
		key = {
			ipv4_src : ternary;
			ipv4_dst : ternary;
			next_protocol : ternary;
			src_port : range;
			dst_port : range;
		}
		actions = {
			TransparentForward;
			AddNshForward;
		}
		size = IPV4_FORWARD_TABLE_SIZE;
		default_action = TransparentForward(DEFAULT_FORWARD_PORT);
	}
	
	//assegn mac to ethernet
	action AssignMac(mac_addr_t src_mac, mac_addr_t dst_mac) {
		hdr.outer_ethernet.src_addr = src_mac;
		hdr.outer_ethernet.dst_addr = dst_mac;
	}
	 
    apply {
		
		//init temp var
		if(hdr.ipv4.isValid()) {
			ipv4_src = hdr.ipv4.src_addr;
			ipv4_dst = hdr.ipv4.dst_addr;
			next_protocol = hdr.ipv4.protocol;
		}
		if(hdr.tcp.isValid()) {
			src_port = hdr.tcp.src_port;
			dst_port = hdr.tcp.dst_port;
		}
		else if(hdr.udp.isValid()) {
			src_port = hdr.udp.src_port;
			dst_port = hdr.udp.dst_port;
		}
		
		//apply forward table
		if(hdr.ipv4.isValid()) {
			//match
			tblIpv4Forward.apply();
		}
		
		AssignMac(DEFAULT_MAC_ADDR, DEFAULT_MAC_ADDR);
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    apply {
		pkt.emit(hdr);
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition accept;
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         EmptyEgress<header_t, egress_metadata_t>(),
         EmptyEgressDeparser<header_t, egress_metadata_t>()) pipe;

Switch(pipe) main;

