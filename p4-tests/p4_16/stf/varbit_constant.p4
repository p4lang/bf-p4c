#include <core.p4>
#include <tna.p4>

header variable_h {
    varbit<128> bits;
}

header sample_h {
    bit<8> counterIndex;
}

struct myHeaders {
    sample_h sample;
    sample_h sample2;
    variable_h var;
    sample_h sample3;
}


struct metadata {
}


parser IngressParser(packet_in        pkt,
    out myHeaders         hdr,
    out metadata         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.sample);
        transition select(hdr.sample.counterIndex) {
            1 : parse_1;
            2 : parse_2;
            3 : parse_3;
            4 : parse_4;
            default : parse_sample2;
        }
    }


    state parse_sample2 {
        pkt.extract(hdr.sample2);
        transition select(hdr.sample2.counterIndex) {
            1 : parse_5;
            2 : parse_6;
            3 : parse_7;
            4 : parse_8;
            default : accept;
        }
    }

    state parse_1 {
        pkt.extract(hdr.var,8);
        transition accept;
    }

    state parse_2 {
        pkt.extract(hdr.var,16);
        transition accept;
    }

    state parse_3 {
        pkt.extract(hdr.var,24);
        transition accept;
    }

    state parse_4 {
        pkt.extract(hdr.var,32);
        transition accept;
    }


    state parse_5 {
        pkt.extract(hdr.var,40);
        transition accept;
    }

    state parse_6 {
        pkt.extract(hdr.var,48);
        transition accept;
    }
    state parse_7 {
        pkt.extract(hdr.var,56);
        transition accept;
    }
    state parse_8 {
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
    apply {
        if (hdr.sample.isValid()) {
            ig_tm_md.ucast_egress_port = 0;
            hdr.sample3.setValid();
            hdr.sample3.counterIndex = 0;
        }
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

struct my_egress_headers_t {
    sample_h sample;
    sample_h sample2;
    variable_h var;
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
        pkt.extract(hdr.sample);
        transition select(hdr.sample.counterIndex) {
            1 : parse_1;
            2 : parse_2;
            3 : parse_3;
            4 : parse_4;
            default : parse_sample2;
        }
    }


    state parse_sample2 {
        pkt.extract(hdr.sample2);
        transition select(hdr.sample2.counterIndex) {
            1 : parse_5;
            2 : parse_6;
            3 : parse_7;
            4 : parse_8;
            default : accept;
        }
    }

    state parse_1 {
        pkt.extract(hdr.var,8);
        transition accept;
    }

    state parse_2 {
        pkt.extract(hdr.var,16);
        transition accept;
    }

    state parse_3 {
        pkt.extract(hdr.var,24);
        transition accept;
    }

    state parse_4 {
        pkt.extract(hdr.var,32);
        transition accept;
    }


    state parse_5 {
        pkt.extract(hdr.var,40);
        transition accept;
    }

    state parse_6 {
        pkt.extract(hdr.var,48);
        transition accept;
    }
    state parse_7 {
        pkt.extract(hdr.var,56);
        transition accept;
    }
    state parse_8 {
        pkt.extract(hdr.var,64);
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
