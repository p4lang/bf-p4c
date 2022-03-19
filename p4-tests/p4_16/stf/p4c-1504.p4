
#include <core.p4>
#include <tna.p4>


struct local_metadata_t {
}

header headers_t {
    bit<6>  dscp;
    bit<2>  ecn;
}


// Ingress parser

parser ingress_parser(  packet_in packet,
                        out headers_t hdr,
                        out local_metadata_t ig_md,
                        out ingress_intrinsic_metadata_t ig_intr_md) 
{
    state start {
        packet.extract(ig_intr_md);
        packet.advance(PORT_METADATA_SIZE);
        packet.extract(hdr);
        transition accept;
    }

}

// Ingress control

control ingress_control(    inout headers_t hdr,
                            inout local_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) 

{
    apply {
        hdr.dscp = hdr.dscp + 1;
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }

}

// Ingress deparser

control ingress_deparser(   packet_out packet,
                            inout headers_t hdr,
                            in local_metadata_t ig_md,
                            in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    apply {
        // Transmit all valid headers.
        packet.emit(hdr);
    }
}

parser egress_parser(   packet_in packet,
                        out headers_t hdr,
                        out local_metadata_t eg_md,
                        out egress_intrinsic_metadata_t eg_intr_md)
{

    state start {
        packet.extract(eg_intr_md);
        packet.extract(hdr);
        transition accept;
    }
}
control egress_control( inout headers_t hdr,
                        inout local_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)


{
    apply {
    }

}

control egress_deparser(    packet_out packet,
                            inout headers_t hdr,
                            in local_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
apply {
    packet.emit(hdr);
}



}

// Pipeline definition.

Pipeline(ingress_parser(),
        ingress_control(),
         ingress_deparser(),
         egress_parser(),
         egress_control(),
         egress_deparser()
        ) pipeline;

Switch(pipeline) main;
