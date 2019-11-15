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
header ethernet_t {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

header vlan_tag_t {
    bit<3>        pcp;
    bit<1>        cfi;
    bit<12>       vid;
    ether_type_t  ether_type;
}

header ipv4_t {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    ip_proto_t   protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

header ipv4_options_t {
    varbit<320> data;
}

header icmp_t {
    bit<16>  type_code;
    bit<16>  checksum;
}

header igmp_t {
    bit<16>  type_code;
    bit<16>  checksum;
}

header tcp_t {
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

header udp_t {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
    bit<16>  checksum;
}

/*************************************************************************
 ********   C O M M O N    P A C K E T    P R O C E S S I N G   **********
 *************************************************************************/
struct my_packet_headers_t {
    ethernet_t         ethernet;
    vlan_tag_t[2]      vlan_tag;
    ipv4_t             ipv4;
    ipv4_options_t     ipv4_options;
    icmp_t             icmp;
    igmp_t             igmp;
    tcp_t              tcp;
    udp_t              udp;
}

struct l4_lookup_t {
    bit<16>  word_1;
    bit<16>  word_2;
}

    /***********************  P A R S E R  **************************/

parser PacketParser(packet_in  pkt,
    out my_packet_headers_t    hdr,
    out l4_lookup_t            l4_lookup,
    out bit<1>                 first_frag)
{
    state start {
        l4_lookup     = { 0, 0 };
        first_frag    = 0;

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
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        
        transition select(hdr.ipv4.ihl) {
            0x5 : parse_ipv4_no_options;
            0x6 &&& 0xE : parse_ipv4_options;
            0x8 &&& 0x8 : parse_ipv4_options;
            default: accept; /* `we''ll deal with it in the control */
        }
    }

    state parse_ipv4_options {
        pkt.extract(
            hdr.ipv4_options,
            ((bit<32>)hdr.ipv4.ihl - 32w5) * 32);
        
        transition parse_ipv4_no_options;
    }

#ifdef P4C_1970_FIXED
    state parse_ipv4_no_options {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP  ) : parse_tcp;
            ( 0, ip_proto_t.UDP  ) : parse_udp;
            ( 0, _               ) : parse_first_fragment;
            default : accept;
        }
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

    state parse_first_fragment {
        first_frag = 1;
        transition accept;
    }
#else
    state parse_ipv4_no_options {    
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP  ) : parse_tcp;
            ( 0, ip_proto_t.UDP  ) : parse_udp;
            ( 0, _               ) : parse_first_fragment;
            default : parse_other_fragments;
        }
    }

    state parse_icmp {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.icmp);
        first_frag = 1;
        transition accept;
    }
    
    state parse_igmp {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.igmp);
        first_frag = 1;
        transition accept;
    }
    
    state parse_tcp {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.tcp);
        first_frag = 1;
        transition accept;
    }
    
    state parse_udp {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        pkt.extract(hdr.udp);
        first_frag = 1;
        transition accept;
    }

    state parse_first_fragment {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        first_frag = 1;
        transition accept;
    }
    
    state parse_other_fragments {
        l4_lookup = pkt.lookahead<l4_lookup_t>();
        transition accept;
    }
#endif   
}

    /*********************  D E P A R S E R  ************************/

control PacketDeparser(packet_out pkt,
                       inout my_packet_headers_t hdr)
{
    apply {
        pkt.emit(hdr);
    }
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

typedef my_packet_headers_t my_ingress_headers_t;

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
}

    /***********************  P A R S E R  **************************/


parser TofinoIngressParser(packet_in  pkt,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
     state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        TofinoIngressParser.apply(pkt, ig_intr_md);
        PacketParser.apply(pkt, hdr, meta.l4_lookup, meta.first_frag);
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
    apply {
        if (hdr.ipv4.isValid() && hdr.ipv4.ttl > 1) {
            ig_tm_md.ucast_egress_port = 1;
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
        PacketDeparser.apply(pkt, hdr);
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
parser TofinoEgressParser(packet_in pkt,
    out egress_intrinsic_metadata_t  eg_intr_md)
{   
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}
    parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    state start {
        TofinoEgressParser.apply(pkt, eg_intr_md);
        /* PacketParser.apply(pkt, ...); */
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
        /* PacketDeparser.apply(pkt, ... ); */
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
