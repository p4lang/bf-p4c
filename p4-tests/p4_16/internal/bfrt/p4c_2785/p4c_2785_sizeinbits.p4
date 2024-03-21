/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
typedef bit<48>   mac_addr_t;

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD,
    MPLS = 0x8847,
    TEST = 0xABCD
}

enum bit<8> header_type_t {
    UNKNOWN    = 0x0,
    RESUBMIT   = 0xA,   /* Again (i.e. parse again) */
    BRIDGE     = 0xB,   /* Bridge                   */
    ING_MIRROR = 0xC,   /* Clone                    */
    EGR_MIRROR = 0xD    /* D=C+1                    */
}

typedef bit<8> header_info_t;

/* The type of traffic a circuit is carrying */
enum bit<8> circuit_t {
    INVALID  = 0,
    ETHERNET = 1,
    IPV4     = 2,
    IPV6     = 3
}

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

/*** Internal Headers ***/

/*
 * This is a common "preamble" header that must be present in all internal
 * headers. The only time you do not need it is when you know that you are
 * not going to have more than one internal header type ever
 */

#define INTERNAL_HEADER         \
    header_type_t header_type;  \
    header_info_t header_info


header inthdr_h {
    INTERNAL_HEADER;
}

/* Resubmit information */
const bit<3> RESUBMIT = 0;

header resubmit_h {
    INTERNAL_HEADER;

    @flexible
    circuit_t circuit;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h ethernet;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    resubmit_h resubmit;
}

    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    inthdr_h inthdr;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        inthdr = pkt.lookahead<inthdr_h>();

        transition select(
            ig_intr_md.resubmit_flag,
            inthdr.header_type,
            inthdr.header_info)
        {
            (0, _, _)                                             : parse_original;
            (1, header_type_t.RESUBMIT, (header_info_t) RESUBMIT) : parse_resubmit;
            default                                               : accept;
        }
    }

    state parse_original {
        pkt.advance(PORT_METADATA_SIZE);

        transition parse_ethernet;
    }

    state parse_resubmit {
        /*
         * Resubmit header and PORT_METADATA occupy the same space (64 bits)
         * on Tofino. If resubmit header is smaller than PORT_METADATA_SIZE,
         * the remaining bits (bytes) must be consumed
         */
        pkt.extract(meta.resubmit);

        /*
         * TEST: sizeInBits(...) used in parser must be recognized as a compile-time constant
         */
        pkt.advance(PORT_METADATA_SIZE - sizeInBits(meta.resubmit));

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);

        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    action resubmit() {
        ig_dprsr_md.resubmit_type = RESUBMIT;
        meta.resubmit.header_type = header_type_t.RESUBMIT;
        meta.resubmit.header_info = (header_info_t)RESUBMIT;
        meta.resubmit.circuit = circuit_t.ETHERNET;
    }

    action dst_mac_check_err() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action dst_mac_check_ok() {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.ethernet.ether_type = ether_type_t.TEST;
    }

    table dst_mac_check {
        key = {
            hdr.ethernet.dst_addr : ternary;
        }
        actions = {
            dst_mac_check_ok;
            dst_mac_check_err;
        }
        size = 1;
        const default_action = dst_mac_check_err();
        const entries = {
            (0x5162738495A6 &&& 0xFFFFFFFFFFFF) : dst_mac_check_ok();
        }
    }

    apply {

        if (ig_intr_md.resubmit_flag == 0) {
            resubmit();
        } else {
            if (hdr.ethernet.isValid()) {
                dst_mac_check.apply();
            } else {
                dst_mac_check_err();
            }
        }

    }
}

   /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Resubmit() resubmit;

    apply {
        if (ig_dprsr_md.resubmit_type == RESUBMIT) {
            resubmit.emit(meta.resubmit);
        }

        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

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
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md,
    in    egress_intrinsic_metadata_t               eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t   eg_prsr_md)
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
