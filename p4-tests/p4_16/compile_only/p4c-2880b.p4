/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}

type bit<48> mac_addr_t;
type bit<32> ipv4_addr_t;

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

header vlan_tag_h {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<1> flag_rs;
    bit<1> flag_df;
    bit<1> flag_mf;
    bit<13>      frag_offset;
    bit<8>       ttl;
    ip_proto_t   protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

header option_word_h {
    bit<32> data;
}

header icmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header igmp_h {
    bit<16>  type_code;
    bit<16>  checksum;
}

header tcp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<32>  seq_no;
    bit<32>  ack_no;
    bit<4>   data_offset;
    bit<4>   res;
    bit<8>   flags;
    bit<16>  window;
    bit<16>  checksum;
    bit<16>  urgent_ptr;
}

header udp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
    bit<16>  checksum;
}

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    ethernet_h         ethernet;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    option_word_h      option_word_1;
    option_word_h      option_word_2;
    option_word_h      option_word_3;
    option_word_h      option_word_4;
    option_word_h      option_word_5;
    option_word_h      option_word_6;
    option_word_h      option_word_7;
    option_word_h      option_word_8;
    option_word_h      option_word_9;
    option_word_h      option_word_10;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    udp_h              udp;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct l4_lookup_t {
    bit<16>  word_1;
    bit<16>  word_2;
}

struct vlan_lookup_intermediate_t {
    bit<16> _payload;
    ether_type_t ether_type;
}

struct vlan_lookup_t {
    vlan_lookup_intermediate_t val;
}

struct my_ingress_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    ether_type_t ether_type;
    
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition meta_init;
    }

    state meta_init {
        meta.l4_lookup     = { 0, 0 };
        meta.first_frag    = 0;

        transition parse_ethernet;
    }
    
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            default :  accept;
        }
    }

    state parse_vlan_tag {
        ether_type = pkt.lookahead<vlan_lookup_t>().val.ether_type;
        pkt.extract(hdr.vlan_tag.next);
        transition select(ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.option_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        pkt.extract(hdr.option_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        pkt.extract(hdr.option_word_8);
        pkt.extract(hdr.option_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.option_word_1);
        pkt.extract(hdr.option_word_2);
        pkt.extract(hdr.option_word_3);
        pkt.extract(hdr.option_word_4);
        pkt.extract(hdr.option_word_5);
        pkt.extract(hdr.option_word_6);
        pkt.extract(hdr.option_word_7);
        pkt.extract(hdr.option_word_8);
        pkt.extract(hdr.option_word_9);
        pkt.extract(hdr.option_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.flag_mf, hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            (0, 0, ip_proto_t.ICMP ) : parse_icmp;
            (0, 0, ip_proto_t.IGMP ) : parse_igmp;
            (0, 0, ip_proto_t.TCP ) : parse_tcp;
            (0, 0, ip_proto_t.UDP ) : parse_udp;
            (_, _, _              ) : parse_first_fragment;
            default : accept;
        }
    }

    state parse_first_fragment {
        meta.first_frag = 1;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition parse_first_fragment;
    }
    
    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition parse_first_fragment;
    }
    
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition parse_first_fragment;
    }
    
    state parse_udp {
        pkt.extract(hdr.udp);
        transition parse_first_fragment;
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
    /* The algorithm */
    apply {
        if (hdr.ipv4.isValid() && meta.first_frag == 1) {
            ig_tm_md.ucast_egress_port = 2;
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
