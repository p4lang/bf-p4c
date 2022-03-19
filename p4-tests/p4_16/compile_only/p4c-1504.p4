
#include <core.p4>
#include <tna.p4>


#ifdef CASE_FIX
@pa_container_size("egress", "hdr.ipv4.dscp", 8)
#endif
header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct local_metadata_t {
    bit<1>      unknown_pkt_err;
    bit<1>      do_clone;
    bit<6>      pad0;
}



struct headers_t {
    ipv4_t      ipv4;
}


// Ingress parser

parser ingress_parser(  packet_in packet,
                        out headers_t hdr,
                        out local_metadata_t ig_md,
                        out ingress_intrinsic_metadata_t ig_intr_md) 
{
    state start {
        packet.extract(hdr.ipv4);


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
        hdr.ipv4.dscp = hdr.ipv4.dscp + 3;
        hdr.ipv4.dscp[5:2] = hdr.ipv4.dscp[5:2] + 3;
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
