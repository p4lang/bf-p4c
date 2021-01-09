/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

/* Standard ethernet header */
header ethernet_t {
    bit<48>  dst_addr;
    bit<48>  src_addr;
    bit<16>  ether_type;
}

header vlan_tag_t {
    bit<3>   pcp;
    bit<1>   cfi;
    bit<12>  vid;
    bit<16>  ether_type;
}

header ipv4_t {
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

header ipv4_options_t {
    varbit<320> data;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_t         ethernet;
    vlan_tag_t[2]      vlan_tag;
    ipv4_t             ipv4;
    ipv4_options_t     ipv4_options;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    bool  ipv4_checksum_err;
    bit<32> hash;
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in      pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
    (bool do_ipv4_checksum)
{
    Checksum() ipv4_checksum;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }

    state meta_init {
        meta.ipv4_checksum_err = false;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID :  parse_vlan_tag;
            ETHERTYPE_IPV4 :  parse_ipv4;
            default        :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ETHERTYPE_TPID :  parse_vlan_tag;
            ETHERTYPE_IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);

        transition select(do_ipv4_checksum) {
            true: compute_ipv4_checksum;
            false: parse_ipv4_protocol;
        }
    }

    state compute_ipv4_checksum {
        ipv4_checksum.add(hdr.ipv4);
        transition parse_ipv4_protocol;
    }

    state parse_ipv4_protocol {
        transition select(hdr.ipv4.ihl) {
            0x5 : parse_ipv4_no_options;
            0x6 &&& 0xE : parse_ipv4_options;
            0x8 &&& 0x8 : parse_ipv4_options;
            default: reject;
        }
    }

    state parse_ipv4_options {
        pkt.extract(
            hdr.ipv4_options,
            ((bit<32>)hdr.ipv4.ihl - 32w5) * 32);

        transition select(do_ipv4_checksum) {
            true: compute_ipv4_options_checksum;
            false: parse_ipv4_no_options;
        }
    }

    state compute_ipv4_options_checksum {
        ipv4_checksum.add(hdr.ipv4_options);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(do_ipv4_checksum) {
            true: verify_ipv4_checksum;
            false: accept;   /*  meta.ipv4_checksum_err will be 0 */
        }
    }

    state verify_ipv4_checksum {
        meta.ipv4_checksum_err = ipv4_checksum.verify();
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
    Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash;
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        meta.hash = hash.get({ 32w0 ++ hdr.ethernet.src_addr[31:0] });
    }

    table ipv4_host {
        key = {
            hdr.ipv4.src_addr      : exact @name("hdr.ipv4.src_addr") ;
            hdr.ipv4.dst_addr      : exact @name("hdr.ipv4.dst_addr") ;
            hdr.ethernet.ether_type: exact @name("hdr.ethernet.ether_type") ;
            hdr.ipv4.protocol      : exact @name("hdr.ipv4.protocol") ;
        }
        actions = {
            send();
        }
        size = 2048;
    }

    /* The algorithm */
    apply {
        ipv4_host.apply();
        hdr.ethernet.dst_addr = hdr.ethernet.dst_addr[47:32] ++ meta.hash;
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

parser EgressParser(packet_in      pkt,
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
    IngressParser(do_ipv4_checksum=true),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;
