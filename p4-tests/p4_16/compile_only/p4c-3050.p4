/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

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

header vlan_tag_h {
    bit<3>   pcp;
    bit<1>   cfi;
    bit<12>  vid;
    bit<16>  ether_type;
}

header ipv4_h {
    bit<4>   version;
    bit<4>   ihl;
    bit<8>   diffserv;
    bit<16>  total_len;
    bit<16>  identification;
    bit<3>   flags;
    bit<13>  frag_offset;
    bit<8>   ttl;
    bit<8>   protocol;
    bit<16>  hdr_checksum;
    bit<32>  src_addr;
    bit<32>  dst_addr;
}

@pa_alias("pipe1", "ingress", "meta.ingress_port", "ig_intr_md.ingress_port")
@pa_alias("pipe2", "egress", "meta.egress_port", "eg_intr_md.egress_port")

@pa_atomic("pipe2", "egress", "meta.egress_port")

@pa_container_size("pipe1", "ingress", "meta.ingress_port", 16)

@pa_container_type("pipe1", "ingress", "meta.ingress_port", "normal")

@pa_mutually_exclusive("pipe1", "ingress", "meta.ingress_port", "meta.ingress_port_2")

@pa_no_overlay("pipe1", "ingress", "meta.ingress_port")

@pa_solitary("pipe1", "ingress", "meta.ingress_port")

@not_parsed("pipe1", "hdr.ipv4")
@not_deparsed("pipe1", "hdr.ipv4")

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress1_metadata_t {
    PortId_t ingress_port;
    PortId_t ingress_port_2;
}

struct my_ingress2_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser IngressParser1(packet_in       pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress1_metadata_t        meta,
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
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

}

parser IngressParser2(packet_in       pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress2_metadata_t        meta,
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
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

}

    /***************** M A T C H - A C T I O N  *********************/

control Ingress1(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress1_metadata_t                     meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    apply {
        // If not assigned, it is not allocated
        ig_tm_md.ucast_egress_port = meta.ingress_port;
    }
}

control Ingress2(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress2_metadata_t                     meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    apply {
    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser1(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress1_metadata_t                     meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

control IngressDeparser2(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress2_metadata_t                     meta,
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

struct my_egress1_metadata_t {
}

struct my_egress2_metadata_t {
    PortId_t egress_port;
}

    /***********************  P A R S E R  **************************/

parser EgressParser1(packet_in       pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress1_metadata_t        meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

parser EgressParser2(packet_in       pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress2_metadata_t        meta,
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

control Egress1(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress1_metadata_t                        meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}

control Egress2(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress2_metadata_t                        meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
        // If not assigned, it is not allocated
        meta.egress_port = eg_intr_md.egress_port;
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser1(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress1_metadata_t                     meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

control EgressDeparser2(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress2_metadata_t                     meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    IngressParser1(),
    Ingress1(),
    IngressDeparser1(),
    EgressParser1(),
    Egress1(),
    EgressDeparser1()
) pipe1;

Pipeline(
    IngressParser2(),
    Ingress2(),
    IngressDeparser2(),
    EgressParser2(),
    Egress2(),
    EgressDeparser2()
) pipe2;

Switch(pipe1, pipe2) main;
