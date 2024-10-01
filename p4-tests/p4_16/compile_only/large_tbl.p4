#include <core.p4>
#include <tna.p4>

header data_t {
    bit<64> f1;
    bit<64> f2;
    bit<64> f3;
    bit<64> f4;
    bit<16> h1;
    bit<16> h2;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

struct metadata {
}

parser ParserI(packet_in b,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action noop() {}

    action first(bit<8> b1) {
        hdr.data.b1 = b1;
    }

    action second(bit<8> b2) {
        hdr.data.b2 = b2;
    }

    table large_match {
        actions = { first; noop; }
        key = { hdr.data.f1 : exact;
	        hdr.data.f2 : exact;
		//hdr.data.f3 : exact;
		//hdr.data.f4 : exact;
		hdr.data.h1 : exact;
	}
        default_action = noop();
	size = 450560;
    }

    table mid_match {
        actions = { second; noop; }
        key = { hdr.data.f1 : exact;
	        hdr.data.f2 : exact;
		//hdr.data.f3 : exact;
		//hdr.data.f4 : exact;
		hdr.data.h1 : exact;
	}
        default_action = noop();
        size = 100000;
    }

    table combine_match {
        actions = { first; second; noop; }
        key = { hdr.data.b1 : exact;
	        hdr.data.b2 : exact;
	}
        default_action = noop();
        size = 128;
    }

    apply {
        if (hdr.data.h2 == 0x1234) {
            large_match.apply();
	} else {
	    mid_match.apply();
	}
	combine_match.apply();
    }

}

control DeparserI(
        packet_out b,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { b.emit(hdr.data); }
}

parser ParserE(packet_in b,
               out headers hdr,
               out metadata meta,
               out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract(hdr.data);
        transition accept;
    }
}

control EgressP(
        inout headers hdr,
        inout metadata meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply { }
}

control DeparserE(packet_out b,
                  inout headers hdr,
                  in metadata meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { b.emit(hdr.data); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
