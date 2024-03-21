#include "core.p4"
#include "tna.p4"

typedef bit<16> index_t;

struct metadata_t {
    index_t index;
}

struct header_t {
    bit<32> dst_addr;
}

parser SwitchIngressParser(packet_in pkt,
                           out header_t hdr,
                           out metadata_t ig_md)  {
    state start {
    }
}

control SwitchIngress(inout header_t hdr,
                      inout metadata_t ig_md,
                      in ingress_intrinsic_metadata_t ig_intr_md,
                      in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md)
                      {
    
    apply {
    }
}

control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md)
                              {
    apply {
    }
}


parser SwitchEgressParser(packet_in pkt,
                          out header_t hdr,
                          out metadata_t eg_md)  {
    state start {
    }
}

control SwitchEgress(inout header_t hdr,
                     inout metadata_t eg_md,
                     in egress_intrinsic_metadata_t eg_intr_md,
                     in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
                     inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
                     {
    apply { }
}

control SwitchEgressDeparser(packet_out pkt,
                             inout header_t hdr,
                             in metadata_t eg_md)
                             {
    apply {
    }
}

Pipeline(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch(pipe) main;
