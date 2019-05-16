#include <t2na.p4>

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct metadata { }

struct headers {
    data_t data;
}

header ingress_skip_t { bit<192> skip; };
parser ingressParser(packet_in packet, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        packet.extract(ig_intr_md);
        packet.extract(skip);
        transition data;
    }
    state data {
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md,
                in ghost_intrinsic_metadata_t gmd) {
    action trigger() {
	ig_intr_dprsr_md.pktgen = true;
	ig_intr_dprsr_md.pktgen_length = 10w512;
	ig_intr_dprsr_md.pktgen_address = 14w400;
    }
    table skip_packet {
        key = { hdr.data.f2 : exact; }
        actions = { trigger; } }

    apply {
	skip_packet.apply();
        ig_intr_tm_md.ucast_egress_port = 3;
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    Pktgen() pktgen;
    apply {
	if (ig_intr_md_for_dprs.pktgen)
	    pktgen.emit(hdr);
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(ingressParser(), ingress(), ingressDeparser(),
	 egressParser(), egress(), egressDeparser()) pipe0;

Switch(pipe0) main;
