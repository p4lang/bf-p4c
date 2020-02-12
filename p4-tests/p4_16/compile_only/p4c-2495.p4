#include <core.p4>
#include <tofino2.p4>
#include <t2na.p4>

struct metadata_t {

    bit<1> sample1;
    bit<1> sample2;
}

header Sample_h {
    bit<24> dmacOui;
    bit<24> dmacStation;
    bit<24> smacOui;
    bit<24> smacStation;
}

struct header_t {
   Sample_h sample1;
   Sample_h sample2;
}

parser SwitchIngressParser(packet_in pkt, out header_t hdr, out metadata_t meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        pkt.extract( hdr.sample1 );
        pkt.extract( hdr.sample2 );
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in metadata_t meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

@pa_alias("ingress", "hdr.sample1.$valid", "meta.sample1")
@pa_alias("ingress", "hdr.sample2.$valid", "meta.sample2")
control ingress(inout header_t hdr, inout metadata_t meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action sample( bit<1> sample1, bit<1> sample2 ) {
    meta.sample1 = sample1;
    meta.sample2 = sample2;

    }

    table commit {
         key = {
            meta.sample1 :exact;
            meta.sample2 : exact;
         }
         actions = {
            sample;
         }
    }

    apply {

        commit.apply();

    }
}

control egress(inout header_t hdr, inout metadata_t meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

parser SwitchEgressParser(packet_in pkt, out header_t hdr, out metadata_t meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control SwitchEgressDeparser(packet_out pkt, inout header_t hdr, in metadata_t meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
       pkt.emit(hdr);
    }
}

@name(".pipe") Pipeline<header_t, metadata_t, header_t, metadata_t>(SwitchIngressParser(), ingress(), SwitchIngressDeparser(), SwitchEgressParser(), egress(), SwitchEgressDeparser()) pipe;

@name(".main") Switch<header_t, metadata_t, header_t, metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

