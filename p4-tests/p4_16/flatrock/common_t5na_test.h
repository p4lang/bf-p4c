parser ingressParser(packet_in packet, out headers hdrs,
                     out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md)
{
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdrs.data);
        transition accept;
    }
}

control ingress(in headers hdrs, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control egressDeparser(packet_out packet, inout headers hdrs, in metadata meta,
                       in egress_intrinsic_metadata_t eg_intr_md,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
        packet.emit(hdrs);
    }
}

Pipeline(ingressParser(), ingress(), egress(), egressDeparser()
) pipe;
Switch(pipe) main;
