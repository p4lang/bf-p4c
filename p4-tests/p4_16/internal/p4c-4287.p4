#include <core.p4>
#include <tna.p4>

typedef bit<48>     mac_addr_t;
typedef bit<32>     ipv4_addr_t;
typedef bit<128>    ipv6_addr_t;
typedef bit<10>     nexthop_id_t;

header ethernet_h {
	mac_addr_t dst;
	mac_addr_t src;
	bit<16> etherType;
}

header ipv4_h {
	bit<4>       version;
	bit<4>       ihl;
	bit<8>       diffserv;
	bit<16>      totalLen;
	bit<16>      identification;
	bit<3>       flags;
	bit<13>      fragOffset;
	bit<8>       ttl;
	bit<8>       protocol;
	bit<16>      hdrChecksum;
	bit<32>      srcAddr;
	bit<32>      dstAddr;
}

header ipv6_h {
	bit<4>   version;
	bit<8>   trafficClass;
	bit<20>  flowLabel;
	bit<16>  payloadLen;
	bit<8>   nextHdr;
	bit<8>   hopLimit;
	bit<128> srcAddr;
	bit<128> dstAddr;
}

header udp_h {
	bit<16> srcPort;
	bit<16> dstPort;
	bit<16> len;
	bit<16> checksum;
}

header tcp_h {
	bit<16>      srcPort;
	bit<16>      dstPort;
	bit<32>      seqNo;
	bit<32>      ackNo;
	bit<4>       dataOffset;
	bit<3>       res;
	bit<3>       ecn;
	bit<6>       ctrl;
	bit<16>      window;
	bit<16>      checksum;
	bit<16>      urgentPtr;
}

header tcp_or_udp_port_h {
	bit<16> srcPort;
	bit<16> dstPort;
}


struct ig_metadata_t {
	bool 		recirc;
	
	bit<9> 		rnd_port_for_recirc;
	bit<1> 		rnd_bit;
}

struct ig_header_t {
	ethernet_h				ethernet;
	ipv4_h 					ipv4;
	ipv6_h 					ipv6;
	udp_h 					udp;
}


parser TofinoIngressParser(
			packet_in                                   pkt,
	inout   ig_metadata_t                               ig_md,
	out     ingress_intrinsic_metadata_t                ig_intr_md
) {
	state start {
		pkt.extract(ig_intr_md);
		transition select(ig_intr_md.resubmit_flag) {
			1 : parse_resubmit;
			0 : parse_port_metadata;
		}
	}

	state parse_resubmit {
		// Parse resubmitted packet here.
		pkt.advance(64);
		transition accept;
	}

	state parse_port_metadata {
		pkt.advance(64);  //tofino 1 port metadata size
		transition accept;
	}
}

parser IngressParser(
			packet_in                                   pkt,
	/* User */
	out     ig_header_t                                 hdr,
	out     ig_metadata_t                               ig_md,
	out     ingress_intrinsic_metadata_t                ig_intr_md
) {
	TofinoIngressParser() tofino_parser;

	state start {
		tofino_parser.apply(pkt, ig_md, ig_intr_md);
		transition init_metadata;
	}

	state init_metadata {
		transition parse_ethernet;
	}

	state parse_ethernet {
		pkt.extract(hdr.ethernet);
		transition select(ig_intr_md.ingress_port) {
			default: parse_underlay;
		}
	}

	state parse_underlay {
		transition select(hdr.ethernet.etherType) {
			0x0800: parse_ipv4;
			0x86dd: parse_ipv6;
			0x0806: parse_arp;
			default: reject;
		}
	}

	state parse_ipv4 {
		pkt.extract(hdr.ipv4);
		transition parse_ipv4_no_options;
	}

	state parse_ipv4_no_options {
		transition select(hdr.ipv4.protocol) {
			17: parse_udp;
			default: reject;
		}
	}

	state parse_ipv6 {
		pkt.extract(hdr.ipv6);
		transition select(hdr.ipv6.nextHdr) {
			17: parse_udp;
			default: reject;
		}
	}

	state parse_arp {
		transition accept;
	}

	state parse_udp {
		pkt.extract(hdr.udp);
		transition accept;
	}

}

control Ingress(
	/* User */
	inout   ig_header_t                                 hdr,
	inout   ig_metadata_t                               ig_md,
	/* Intrinsic */
	in      ingress_intrinsic_metadata_t                ig_intr_md,
	in      ingress_intrinsic_metadata_from_parser_t    ig_prsr_md,
	inout   ingress_intrinsic_metadata_for_deparser_t   ig_dprsr_md,
	inout   ingress_intrinsic_metadata_for_tm_t         ig_tm_md
) {
	bool use_table = false;
	action someaction_ipv4(bool dothings) {
		hdr.ipv4.ttl = hdr.ipv4.ttl |-| 1;
#ifndef CASE_FIX
	        if (dothings)
		    hdr.ipv6.setInvalid();
#endif
        }

        action someaction_ipv6(bool dothings) {
		hdr.ipv6.hopLimit = hdr.ipv6.hopLimit |-| 1;
	}
	table some_table {
		key = {
			use_table          : exact;
			hdr.ipv4.isValid() : exact;
			hdr.ipv6.isValid() : exact;
		}
		actions = {
			someaction_ipv4;
			someaction_ipv6;
			@defaultonly NoAction;
		}
		const default_action = NoAction();
		const entries = {
			(true, true, false) : someaction_ipv4(true);
			(true, false, true) : someaction_ipv6(false);
		}
		const size = 2;
	}

	apply {
		some_table.apply();
		ig_tm_md.ucast_egress_port = 2;
	}
}

control IngressDeparser(
			packet_out                                  pkt,
	/* User */
	inout   ig_header_t                                 hdr,
	in      ig_metadata_t                               ig_md,
	/* Intrinsic */
	in      ingress_intrinsic_metadata_for_deparser_t   ig_intr_dprsr_md
) {
	apply {
		pkt.emit(hdr);
	}
}

// ------------------------------------------------------------------------------------------
//                                      EGRESS STAGE
// ------------------------------------------------------------------------------------------


struct eg_metadata_t {
}


struct eg_headers_t {
}


parser EgressParser(
			packet_in                                   pkt,
	/* User */
	out     eg_headers_t                                hdr,
	out     eg_metadata_t                               meta,
	/* Intrinsic */
	out     egress_intrinsic_metadata_t                 eg_intr_md
)
{
	/* This is a mandatory state, required by Tofino Architecture */
	state start {
		pkt.extract(eg_intr_md);
		transition accept;
	}
}

// --------------------------------------------------
//                  Egress Control
// --------------------------------------------------
control Egress(
	/* User */
	inout   eg_headers_t                                hdr,
	inout   eg_metadata_t                               eg_md,
	/* Intrinsic */
	in      egress_intrinsic_metadata_t                 eg_intr_md,
	in      egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout   egress_intrinsic_metadata_for_deparser_t    ig_intr_dprs_md,
	inout   egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md
) {
	apply {
		// step 1 : ACL
		// step 2 : Accounting
	}
}


control EgressDeparser(
			packet_out                                  pkt,
	/* User */
	inout   eg_headers_t                                hdr,
	in      eg_metadata_t                               meta,
	/* Intrinsic */
	in      egress_intrinsic_metadata_for_deparser_t    eg_dprsr_md
) {
	apply {
		pkt.emit(hdr);
	}
}


Pipeline(
	IngressParser(),
	Ingress(),
	IngressDeparser(),
	EgressParser(),
	Egress(),
	EgressDeparser()
) pipe;

Switch(pipe) main;
