/* -*- P4_16 -*- */
#include <core.p4>
#include <tna.p4>

struct ingress_metadata_t {
}

header bridge_h {
    bit<9>  ingress_port;
    @padding bit<7>  _pad0;
}

struct header_t {
    bridge_h bridge;
}

parser IngressParser(
    packet_in                           pkt,
    out header_t                        hdr,
    out ingress_metadata_t              ig_md,
    out ingress_intrinsic_metadata_t    ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

control Ingress(
    inout header_t                                  hdr,
    inout ingress_metadata_t                        ig_md,
    in    ingress_intrinsic_metadata_t              ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t  ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t       ig_tm_md)
{
    apply {
        // add bridge header
        hdr.bridge.setValid();
        hdr.bridge._pad0 = 0;
        hdr.bridge.ingress_port = ig_intr_md.ingress_port;                
    }
}

control IngressDeparser(
    packet_out                                      pkt,
    inout header_t                                  hdr,
    in ingress_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

struct egress_metadata_t {
}

parser EgressParser(
    packet_in                       pkt,
    out header_t                    hdr,
    out egress_metadata_t           eg_md,
    out egress_intrinsic_metadata_t eg_intr_md)
{
    bridge_h bridge;

    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridge;
    }

    state parse_bridge {
        pkt.extract(bridge); 
        transition accept;
    }
}

control Egress(
    inout header_t                                      hdr,
    inout egress_metadata_t                             eg_md,
    in    egress_intrinsic_metadata_t                   eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t       eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t      eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t   eg_oport_md)
{
    apply {
    }
}

control EgressDeparser(
    packet_out                                      pkt,
    inout header_t                                  hdr,
    in    egress_metadata_t                         meta,
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    IngressParser(), Ingress(), IngressDeparser(),
    EgressParser(), Egress(), EgressDeparser()
) pipe;

Switch(pipe) main;
