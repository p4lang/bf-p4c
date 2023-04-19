/* -*- P4_16 -*- */

#include <core.p4>
#include <t2na.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> TEST64_RW    = 0xBF01;
const bit<16> TEST64_RAC   = 0xBF02;
const bit<16> TEST128_RW   = 0xBF03;
const bit<16> TEST128_RAC  = 0xBF04;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    bit<48>   dst_addr;
    bit<48>   src_addr;
    bit<16>   ether_type;
}

header test64_h {
    bit<64>   a;
    bit<64>   b;
}

header test128_h {
    bit<128>   a;
    bit<128>   b;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    test64_h     test64;
    test128_h    test128;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser MyIngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
     state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            TEST64_RW  : parse_test64;
            TEST64_RAC : parse_test64;
            TEST128_RW : parse_test128;
            TEST128_RAC: parse_test128;
            default:    accept;
        }
    }

    state parse_test64 {
        pkt.extract(hdr.test64);
        transition accept;
    }

    state parse_test128 {
        pkt.extract(hdr.test128);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control MyIngress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    Register<bit<64>, bit<10>>(size= 1) rw64;
    Register<bit<64>, bit<10>>(size= 1) rac64;
    RegisterAction<bit<64>, bit<10>, bit<64>>(rac64) rmw64 = {
        void apply(inout bit<64> reg, out bit<64> res) {
            reg = hdr.test64.a;
            res = reg;
        }
    };

    Register<bit<128>, bit<10>>(size= 1) rw128;
    Register<bit<128>, bit<10>>(size= 1) rac128;
    RegisterAction<bit<128>, bit<10>, bit<128>>(rac128) rmw128 = {
        void apply(inout bit<128> reg, out bit<128> res) {
            reg = hdr.test128.a;
            res = reg;
        }
    };

    apply {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

        if (hdr.ethernet.ether_type == TEST64_RW) {
            rw64.write(0, hdr.test64.a);
            hdr.test64.b = hdr.test64.a;
        } else if (hdr.ethernet.ether_type == TEST64_RAC) {
            hdr.test64.b = rmw64.execute(0);
        } else if (hdr.ethernet.ether_type == TEST128_RW) {
            rw128.write(0, hdr.test128.a);
            hdr.test128.b = hdr.test128.a;
        } else if (hdr.ethernet.ether_type == TEST128_RAC) {
            hdr.test128.b = rmw128.execute(0);
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control MyIngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
     apply {
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

parser MyEgressParser(packet_in        pkt,
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

control MyEgress(
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

control MyEgressDeparser(packet_out pkt,
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
    MyIngressParser(),
    MyIngress(),
    MyIngressDeparser(),
    MyEgressParser(),
    MyEgress(),
    MyEgressDeparser()
) pipe;

Switch(pipe) main;
