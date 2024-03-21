#include <core.p4>
#include <tna.p4>

header ethernet_h {
	bit<16> etherType;
}

struct ig_metadata_t {
	PortId_t uninit;
}

struct ig_header_t {
	ethernet_h				ethernet;
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

    action uninit_read() {
        ig_tm_md.ucast_egress_port = ig_md.uninit;
    }

    action set_port() {
        ig_tm_md.ucast_egress_port = 0;
    }

    @stage(1) table t1 {
        key     = { hdr.ethernet.etherType : lpm; }
        actions = { set_port; NoAction;}
        
        default_action = NoAction();
        size           = 4;
    }

    @stage(2) table t2 {
        key     = { hdr.ethernet.etherType : lpm; }
        actions = { uninit_read; NoAction;}
        
        default_action = NoAction;
        size           = 4;
    }
    @stage(3) table t3 {
        key     = { hdr.ethernet.etherType : lpm; }
        actions = { set_port; NoAction;}
        
        default_action = NoAction;
        size           = 4;
    }
    @stage(4) table t4 {
        key     = { hdr.ethernet.etherType : lpm; }
        actions = { uninit_read; NoAction;}
        
        default_action = NoAction;
        size           = 4;
    }

	apply {
		if (t1.apply().hit) {
			if (t2.apply().hit) {
				if (t3.apply().hit) {
					t4.apply();
				}
			}
		}

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
