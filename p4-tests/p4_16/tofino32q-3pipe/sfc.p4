/* -*- P4_16 -*- */
#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "common/util.p4"
#include "common/headers.p4"
#include "common/types.p4"
//#include "LoadBalancer.p4"
//#include "XGW.p4"
//#include "Router.p4"

struct metadata_t{
    /*empty*/
}

parser SfcIngressParser(
        packet_in pkt,
        out sfc_header_t hdr,
        out sfc_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_sfc_ethernet;
    }
    //assume that all headers are started with ethernet and followed by ipv4
    //sfc ingress parser only parse ethernet header

    state parse_sfc_ethernet {
        pkt.extract(hdr.sfc_ethernet);
        ig_md.controlCode = hdr.sfc_ethernet.controlCode;
        ig_md.nf0 = hdr.sfc_ethernet.nf0;
        ig_md.nf1 = hdr.sfc_ethernet.nf1;
        ig_md.nf2 = hdr.sfc_ethernet.nf2;
        ig_md.nf3 = hdr.sfc_ethernet.nf3;
        ig_md.nf4 = hdr.sfc_ethernet.nf4;
        transition accept;
    }

}

control SfcIngress(inout sfc_header_t hdr,
                  inout sfc_ingress_metadata_t ig_md,
                  in ingress_intrinsic_metadata_t ig_intr_md,
                  in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                  inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm){

    bit<9> outport_tmp = (bit<9>)ig_md.controlCode;
    apply{
        if(ig_md.controlCode >0){//controlCode should be the output port, including CPU port
            ig_intr_md_for_tm.bypass_egress = 1w1;
            ig_intr_md_for_tm.ucast_egress_port = outport_tmp;

        }else{
            if (ig_md.nf0 == SFC_LOAD_BALANCER_ID){
                ig_intr_md_for_tm.ucast_egress_port = LOAD_BALANCER_PORT;
            }
            else if(ig_md.nf0 == SFC_XGW_ID){
                ig_intr_md_for_tm.ucast_egress_port = XGW_PORT;
            }else if(ig_md.nf0 == SFC_ROUTER_ID){
                ig_intr_md_for_tm.ucast_egress_port = ROUTER_PORT;
            }
            else ig_intr_md_for_dprsr.drop_ctl = 0x1; //drop packet, shouldn't reach here

            hdr.sfc_ethernet.nf0 = hdr.sfc_ethernet.nf1;
            hdr.sfc_ethernet.nf1 = hdr.sfc_ethernet.nf2;
            hdr.sfc_ethernet.nf2 = hdr.sfc_ethernet.nf3;
            hdr.sfc_ethernet.nf3 = hdr.sfc_ethernet.nf4;
            hdr.sfc_ethernet.nf4 = 0;
        }
    }

}

control SfcIngressDeparser(
        packet_out pkt,
        inout sfc_header_t hdr,
        in sfc_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
        apply{
            pkt.emit(hdr);
        }
}

Pipeline(SfcIngressParser(),
         SfcIngress(),
         SfcIngressDeparser(),
         EmptyEgressParser<header_t, metadata_t>(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe_xgw;

Pipeline(SfcIngressParser(),
         SfcIngress(),
         SfcIngressDeparser(),
         EmptyEgressParser<header_t, metadata_t>(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe_lb;

Pipeline(SfcIngressParser(),
         SfcIngress(),
         SfcIngressDeparser(),
         EmptyEgressParser<header_t, metadata_t>(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe_router;

Pipeline(SfcIngressParser(),
         SfcIngress(),
         SfcIngressDeparser(),
         EmptyEgressParser<header_t, metadata_t>(),
         EmptyEgress<header_t, metadata_t>(),
         EmptyEgressDeparser<header_t, metadata_t>()) pipe_empty;

Switch(pipe_xgw, pipe_lb, pipe_router, pipe_empty) main;
