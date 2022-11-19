/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

enum bit<16> ether_type_t {
    IPV4 = 0x0800,
    ARP  = 0x0806,
    TPID = 0x8100,
    IPV6 = 0x86DD,
    MPLS = 0x8847
}

const PortId_t CPU_PORT = 64;

/* Table Sizes */
/*
 * We use C preprocessor here so that we can easily overwrite
 * these constants from the command line
 */
#ifndef IPV4_HOST_SIZE
  #define IPV4_HOST_SIZE 65536
#endif

#ifndef IPV4_LPM_SIZE
  #define IPV4_LPM_SIZE 12288
#endif

const int IPV4_HOST_TABLE_SIZE = IPV4_HOST_SIZE;
const int IPV4_LPM_TABLE_SIZE  = IPV4_LPM_SIZE;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_h {
    mac_addr_t   dst_addr;
    mac_addr_t   src_addr;
    ether_type_t ether_type;
}

header vlan_tag_h {
    bit<3>       pri;
    bit<1>       dei;
    bit<12>      vid;
    ether_type_t ether_type;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_headers_t {
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_metadata_t {
}

    /***********************  P A R S E R  **************************/
parser Parser(packet_in        pkt,
    /* User */
    out my_headers_t          hdr,
    out my_metadata_t         meta
    /* Intrinsic */
    /* Skipped on purpose */)(bit gress = 0)
{
    ingress_intrinsic_metadata_t ig_intr_md;
    egress_intrinsic_metadata_t  eg_intr_md;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        if (gress == 0) {
            pkt.advance(ig_intr_md.minSizeInBits());
            pkt.advance(PORT_METADATA_SIZE);
        } else {
            pkt.advance(eg_intr_md.minSizeInBits());
        }
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID:  parse_vlan_tag;
            ether_type_t.IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ether_type_t.IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Ingress(
    /* User */
    inout my_headers_t                       hdr,
    inout my_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
        }
        size = IPV4_HOST_TABLE_SIZE;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }

        default_action = send(CPU_PORT);
        size           = IPV4_LPM_TABLE_SIZE;
    }

    apply {
        if (hdr.ipv4.isValid()) {
            if (ipv4_host.apply().miss) {
                ipv4_lpm.apply();
            }
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control Deparser(packet_out pkt,
    /* User */
    inout my_headers_t                       hdr,
    in    my_metadata_t                      meta
    /* Intrinsic */
    /* Skipped on purpose, since it's optional */)
{
    apply {
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/


    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_headers_t                          hdr,
    inout my_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}


/************ F I N A L   P A C K A G E ******************************/
Pipeline(
    Parser(gress=0),
    Ingress(),
    Deparser(),
    Parser(gress=1),
    Egress(),
    Deparser()
) pipe;

Switch(pipe) main;
