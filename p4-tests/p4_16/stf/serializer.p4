#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL = 1;
const pkt_type_t PKT_TYPE_MIRROR = 2;

/* Example 32Q program exercise bridge metadata packing at all pipeline boundaries.
 *
 * Bridging:
 * Pipe0 Ingress -> Pipe0 Egress
 * Pipe0 Ingress -> Pipe1 Egress
 * Pipe1 Egress -> Pipe1 Ingress
 * Pipe1 Ingress -> Pipe0 Egress
 *
 * Mirror:
 * Pipe0 Ingress -> Pipe0 Egress
 * Pipe1 Ingress -> Pipe1 Egress
 * Pipe0 Egress -> Pipe0 Egress
 * Pipe1 Egress -> pipe1 Egress
 *
 * Resubmit:
 * Pipe0 Ingress -> Pipe0 Ingress
 * Pipe1 Ingress -> Pipe1 Ingress
 *
 * CPU:
 * Pipe0 Egress -> CPU
 * Pipe1 Egress -> CPU
 *
 * Suppose a common header is used in all cases, which is possibly the worst case scenario.
 */

header sample_h{
    bit<16> a;
    bit<16> b;
    bit<16> c;
}

/* common header that is used in bridging, mirror, resubmit and copy_to_cpu. */
@flexible
header common_h {
    bit<9> port;
    bit<4> version;
    bit<5> qid;
    bit<16> aligned;
}

header mirror_h {
    bit<8> pkt_type;
}

struct headers_t{
    mirror_h mirror;
    common_h common;
    sample_h sample;
}

struct metadata_t{
}

header ingress_skip_t {
}

parser IgParserA(packet_in packet, out headers_t hdr, out metadata_t meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        //packet.extract(hdr.common);
        packet.extract(ig_intr_md);
        packet.advance(64);
        packet.extract(hdr.sample);
        transition accept;
    }
}

parser IgParserB(packet_in packet, out headers_t hdr, out metadata_t meta,
                  out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_skip_t skip;
    state start {
        packet.extract(hdr.common);
        packet.extract(ig_intr_md);
        packet.advance(64);
        packet.extract(hdr.sample);

        transition accept;
    }
}

control IngressA(inout headers_t hdr, inout metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action act1() {
        ig_intr_tm_md.ucast_egress_port = 1 << 7 /* pipe id */ | 1 /* port num*/;
    }

    table test {
        actions = { act1;NoAction; }
        key = { hdr.sample.a: exact; }
        default_action = act1();
    }

    apply {
        test.apply();
        hdr.common.port = ig_intr_md.ingress_port;
        hdr.common.version = hdr.sample.a[3:0];
        hdr.common.qid = ig_intr_tm_md.qid;
        hdr.common.aligned = hdr.sample.b;
    }
}

control IngressB(inout headers_t hdr, inout metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action act1() {
        ig_intr_tm_md.ucast_egress_port = 1;
    }

    table test {
        actions = { act1;NoAction; }
        key = { hdr.sample.a: exact; }
        default_action = act1();
    }

    apply {
        test.apply();
        hdr.common.port = ig_intr_md.ingress_port;
        hdr.common.version = hdr.sample.a[3:0];
        hdr.common.qid = ig_intr_tm_md.qid;
        hdr.common.aligned = hdr.sample.b;
    }
}

control IgDeparser(packet_out packet, inout headers_t hdr,in metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    Mirror() mirror;
    apply {
        if (ig_intr_dprsr_md.mirror_type == 2) {
            mirror.emit(0, hdr.mirror);
            mirror.emit(0, hdr.common);
        }
        packet.emit(hdr.common);
        packet.emit(hdr.sample);
    }
}

parser EgParserA(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_metadata;
    }

    state parse_metadata {
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
            PKT_TYPE_MIRROR : parse_mirror_md;
            PKT_TYPE_NORMAL : parse_bridged_md;
            default : accept;
        }
    }

    state parse_bridged_md {
        pkt.extract(hdr.common);
        transition parse_sample;
    }

    state parse_mirror_md {
        mirror_h mirror_md;
        pkt.extract(mirror_md);
        transition parse_sample;
    }

    state parse_sample {
        pkt.extract(hdr.sample);
        transition accept;
    }
}

parser EgParserB(
    packet_in pkt,
    out headers_t hdr,
    out metadata_t md,
    out egress_intrinsic_metadata_t eg_intr_md) {
	state start {
        pkt.extract(hdr.common);
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.sample);
        transition accept;
    }
}


control Egress(
    inout headers_t hdr,
    inout metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
        if (hdr.common.port == 9w0) {
            hdr.sample.a = 16w32;
        }
    }
}

control EgDeparserA(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
	apply {
	    pkt.emit(hdr.sample);
	}
}

control EgDeparserB(
    packet_out pkt,
    inout headers_t hdr,
    in metadata_t md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
	apply {
        pkt.emit(hdr.common);
	    pkt.emit(hdr.sample);
	}
}


Pipeline(IgParserA(),
        IngressA(),
        IgDeparser(),
        EgParserA(),
        Egress(),
        EgDeparserA()) pipe0;

Pipeline(IgParserB(),
        IngressB(),
        IgDeparser(),
        EgParserB(),
        Egress(),
        EgDeparserB()) pipe1;

Switch(pipe0, pipe1) main;
