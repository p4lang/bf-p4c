/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>

typedef bit<48>     mac_addr_t;
typedef bit<32>     ipv4_addr_t;
typedef bit<128>    ipv6_addr_t;

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
    varbit<320>  options;
}

header ipv4_up_to_ihl_only_h {
    bit<4> version;
    bit<4> ihl;
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
    varbit<320>  options;
}

header tcp_upto_data_offset_only_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    // dataOffset in TCP hdr uses 4 bits but needs padding.
    // If 4 bits are used for it, p4c-bm2-ss complains the header
    // is not a multiple of 8 bits.
    bit<4>  dataOffset;
    bit<4>  dontCare;
}

struct ig_metadata_t {
	bool 		recirc;

	bit<9> 		rnd_port_for_recirc;
	bit<1> 		rnd_bit;
}

struct ig_header_t {
    ethernet_h  ethernet;
    ipv4_h      ipv4;
#if (TEST == 3) || (TEST == 4)
    ipv4_h      ipv4copy;
#endif
    ipv6_h      ipv6;
    udp_h       udp;
    tcp_h       tcp;
}

// ----------------------------------------------------------------------
//                                      INGRESS STAGE
// ----------------------------------------------------------------------

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
	//pkt.extract(ig_md.resubmit_data_read);
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
	transition parse_ethernet;
    }

    state parse_ethernet {
	pkt.extract(hdr.ethernet);
#if (TEST == 1) || (TEST == 2)
        pkt.extract(hdr.ipv4, (20 + (bit<32>)(pkt.lookahead<ipv4_up_to_ihl_only_h>().ihl - 5)*4)*8);
#if TEST == 2
        hdr.tcp.setValid();  /* expect error:
        "hdr.tcp.setValid: cannot set header that contains a varbit field as valid"
        */

        hdr.tcp.options = hdr.ipv4.options;
#endif
#endif
#if TEST == 3
        hdr.ipv4copy = hdr.ipv4;  /* expect error:
        "hdr.ipv4: cannot assign header that contains a varbit field."
        */
#endif
	transition accept;
    }
}


// --------------------------------------------------
//                  Ingress Control
// --------------------------------------------------
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
    apply {
#if TEST == 1
        hdr.tcp.setValid();  /* expect error:
        "hdr.tcp.setValid: cannot set header that contains a varbit field as valid"
        */
        hdr.tcp.options = hdr.ipv4.options;
#endif
#if TEST == 4
        hdr.ipv4copy = hdr.ipv4;  /* expect error:
        "hdr.ipv4: cannot assign header that contains a varbit field."
        */
#endif
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
#if !defined(TEST) || TEST == 0
        // expect warning @ +2: "hdr.ipv4: emitting a header hdr.ipv4 [(]type header ipv4_h[)] with varbit field"
#endif
	pkt.emit(hdr);
    }
}

// --------------------------------------------------------------------
//                           EGRESS STAGE
// --------------------------------------------------------------------


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
