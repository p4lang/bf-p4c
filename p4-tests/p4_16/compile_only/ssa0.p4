#include <core.p4>
#include <tna.p4>

header hdr_h {
    bit<6> x;
    bit<2> y;
}

struct headers_t {
    hdr_h i;
    hdr_h o;
}

struct metadata_t {
    bit<6> x1;
    bit<6> x2;
}

parser IgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t meta,
                out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.i);
        transition accept;
    }
}

control Ingress(inout headers_t hdr,
                inout metadata_t meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action inc() {
        meta.x2 = meta.x1 + 1;
    }

    action def() {
        meta.x2 = meta.x1;
    }

    table t1 {
        key = { meta.x1 : exact; }
        actions = { def; inc; }
        default_action = def;
    }


    apply{
        meta.x1 = hdr.i.x;  // ssa+
        hdr.o.y = hdr.i.y;  // ssa+

        t1.apply();

        hdr.o.setValid();
        hdr.o.x = meta.x2;  // ssa+

        ig_intr_tm_md.bypass_egress = 1;
    }
}

control IgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t meta,
                   in ingress_intrinsic_metadata_for_deparser_t standard_metadata) {
    apply {
        packet.emit(hdr.o);
    }
}

parser EgParser(packet_in packet,
                out headers_t hdr,
                out metadata_t md,
                out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control Egress(inout headers_t hdr,
               inout metadata_t md,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control EgDeparser(packet_out packet,
                   inout headers_t hdr,
                   in metadata_t md,
                   in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
        packet.emit(hdr.i);
    }
}

Pipeline(IgParser(),
        Ingress(),
        IgDeparser(),
        EgParser(),
        Egress(),
        EgDeparser()) pipe0;

Switch(pipe0) main;
