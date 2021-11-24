#include <tna.p4>

@pa_auto_init_metadata
#if __TARGET_TOFINO__ > 1
@phv_limit(B0-12, H0-3, W0-3, -D, -M, -T)
#endif

struct metadata {
    bit<8>      a;
    bit<8>      b;
    bit<8>      c;
}

header data_t {
    bit<32> f1;
    bit<32> f2;
    bit<16> h1;
    bit<8>  b1;
    bit<8>  b2;
}

struct headers {
    data_t data;
}

parser ingressParser(packet_in packet, out headers hdr,
                  out metadata meta,
                  out ingress_intrinsic_metadata_t ig_intr_md
) {
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr.data);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action seta(bit<8> v) { meta.a = v; }
    action setb(bit<8> v) { meta.b = v; }
    action setc(bit<8> v) { meta.c = v; }
    action outa() { hdr.data.b1 = meta.a; }
    action outb() { hdr.data.b1 = meta.b; }
    action outc() { hdr.data.b1 = meta.c; }
    table t1 {
        key = { hdr.data.f1 : exact; }
        actions = { seta; setb; setc; }
        size = 1024; }
    table t2 {
        key = { hdr.data.f2 : exact; }
        actions = { outa; outb; outc; }
        size = 1024; }
    apply {
        ig_intr_tm_md.ucast_egress_port = 3;
        t1.apply();
        t2.apply();
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr.data);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    action seta(bit<8> v) { meta.a = v; }
    action setb(bit<8> v) { meta.b = v; }
    action setc(bit<8> v) { meta.c = v; }
    action outa() { hdr.data.b2 = meta.a; }
    action outb() { hdr.data.b2 = meta.b; }
    action outc() { hdr.data.b2 = meta.c; }
    table t3 {
        key = { hdr.data.f1 : exact; }
        actions = { seta; setb; setc; }
        size = 1024; }
    table t4 {
        key = { hdr.data.f2 : exact; }
        actions = { outa; outb; outc; }
        size = 1024; }
    apply {
        t3.apply();
        t4.apply();
    }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
        packet.emit(hdr);
    }
}

Pipeline(ingressParser(), ingress(), ingressDeparser(),
         egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
