#include <core.p4>
#include <tna.p4>

header variable_h {
    varbit<64> bits;
}

header realData_h {
    bit<8> length;
    bit<16> csum;
    bit<32> a;
    bit<32> b;
}

struct myHeaders {
    realData_h ctr;
    variable_h var;
}


struct metadata {}

parser IngressParser(packet_in        pkt,
    out myHeaders         hdr,
    out metadata         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE); 
        pkt.extract(hdr.ctr);
        transition select(hdr.ctr.length) {
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
        transition accept;
    }
    state skip2Byte {
        pkt.extract(hdr.var,16);
        transition accept;
    }
    state skip3Byte {
        pkt.extract(hdr.var,24);
        transition accept;
    }
    state skip4Byte {
        pkt.extract(hdr.var,32);
        transition accept;
    }
    state skip5Byte {
        pkt.extract(hdr.var,40);
        transition accept;
    }
    state skip6Byte {
        pkt.extract(hdr.var,48);
        transition accept;
    }
    state skip7Byte {
        pkt.extract(hdr.var,56);
        transition accept;
    }
    state skip8Byte {
        pkt.extract(hdr.var,64);
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
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ctr.b = 0x12345678;
    }
    apply {
        send(1);
    }
}

control IngressDeparser(
    packet_out pkt,
    inout myHeaders headers,
    in metadata meta,
    in ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata
) { 
    apply {
        pkt.emit(headers);
    }
}


    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in        pkt,
    /* User */
    out myHeaders          hdr,
    out metadata         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.ctr);
        transition select(hdr.ctr.length) {
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
        transition accept;
    }
    state skip2Byte {
        pkt.extract(hdr.var,16);
        transition accept;
    }
    state skip3Byte {
        pkt.extract(hdr.var,24);
        transition accept;
    }
    state skip4Byte {
        pkt.extract(hdr.var,32);
        transition accept;
    }
    state skip5Byte {
        pkt.extract(hdr.var,40);
        transition accept;
    }
    state skip6Byte {
        pkt.extract(hdr.var,48);
        transition accept;
    }
    state skip7Byte {
        pkt.extract(hdr.var,56);
        transition accept;
    }
    state skip8Byte {
        pkt.extract(hdr.var,64);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout myHeaders                          hdr,
    inout metadata                         meta,
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
    inout myHeaders                       hdr,
    in metadata                      meta,
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
