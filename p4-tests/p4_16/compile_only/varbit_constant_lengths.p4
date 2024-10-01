#include <core.p4>
#include <tna.p4>

header variable_h {
    varbit<128> bits;
}

header realData_h {
    bit<8> counterIndex;
}

struct myHeaders {
    variable_h var;
    realData_h ctr;
}

struct portMetadata_t {
    bit<8> skipKey;
}

struct metadata {
    portMetadata_t portMetadata;
}

struct emetadata {}

parser IngressParser(packet_in        pkt,
    out myHeaders         hdr,
    out metadata         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        meta.portMetadata = port_metadata_unpack<portMetadata_t>(pkt);
        transition select(meta.portMetadata.skipKey) {
            1 : skip1Byte;
            2 : skip2Byte;
            3 : skip3Byte;
            4 : skip4Byte;
            5 : skip5Byte;
            6 : skip6Byte;
            7 : skip7Byte;
            8 : skip8Byte;
            default : accept;
        }
    }
    state skip1Byte {
        pkt.extract(hdr.var,8);
        transition dataExtract;
    }
    state skip2Byte {
        pkt.extract(hdr.var,16);
        transition dataExtract;
    }
    state skip3Byte {
        pkt.extract(hdr.var,24);
        transition dataExtract;
    }
    state skip4Byte {
        pkt.extract(hdr.var,32);
        transition dataExtract;
    }
    state skip5Byte {
        pkt.extract(hdr.var,40);
        transition dataExtract;
    }
    state skip6Byte {
        pkt.extract(hdr.var,48);
        transition dataExtract;
    }
    state skip7Byte {
        pkt.extract(hdr.var,56);
        transition dataExtract;
    }
    state skip8Byte {
        pkt.extract(hdr.var,64);
        transition dataExtract;
    }
    state dataExtract {
        pkt.extract(hdr.ctr);
        transition accept;
    }
}

control Ingress(
    inout myHeaders                       hdr,
    inout metadata                     meta,
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Counter<bit<64>,bit<8> >(256,CounterType_t.PACKETS_AND_BYTES) counters;
    apply {
        if(hdr.ctr.isValid()) {
            counters.count(hdr.ctr.counterIndex);
        }
    }
}

control IngressDeparser(
    packet_out pkt,
    inout myHeaders headers,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata
) {
#ifdef TOFINO2_CLONE_BUG
    Mirror() mirror;
#endif
    apply {
#ifdef TOFINO2_CLONE_BUG
        if(ingressDeparserMetadata.mirror_type == 1) {
            mirror.emit<CloningHeader_h>(meta.mirrorSession,{0,meta.portProperties.protocol_key,headers.sourceInformation.sourceId});
        }
#endif
        pkt.emit(headers);
    }
}

struct my_egress_headers_t {
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */    
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
