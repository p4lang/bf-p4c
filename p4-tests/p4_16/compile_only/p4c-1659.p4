/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */

#define SINGLE_IPV4_HEADER
#define SINGLE_IPV4_HEADER_SAFE

/* Standard ethernet header */
header ethernet_h {
    bit<48>  dst_addr;
    bit<48>  src_addr;
    bit<16>  ether_type;
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
#ifndef SINGLE_IPV4_HEADER
}

header ipv4_options_h {
#endif
    varbit<320> data;
}

#ifdef SINGLE_IPV4_HEADER
header ipv4_lookahead_h {
    bit<4>  version;
    bit<4>  ihl;
}
#endif

header ipv6_h {
    bit<4>   version;
    bit<8>   traffic_class;
    bit<20>  flow_label;
    bit<16>  payload_len;
    bit<8>   next_hdr;
    bit<8>   hop_limit;
    bit<128> src_addr;
    bit<128> dst_addr;
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
#ifndef SINGLE_IPV4_HEADER    
    ipv4_options_h     ipv4_options;
#endif
    ipv6_h             ipv6;
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

struct my_ingress_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
}

    /***********************  P A R S E R  **************************/

parser MyIngressParser(packet_in      pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
     state start {
        pkt.extract(ig_intr_md);
        pkt.advance(64);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        meta.l4_lookup  = { 0, 0 };
        meta.first_frag = 0;

        transition select(hdr.ethernet.ether_type) {
            0x8100 &&& 0xEFFF:  parse_vlan_tag;
            0x0800           :  parse_ipv4;
            0x86DD           :  parse_ipv6;
            default          :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100:  parse_vlan_tag;
            0x0800:  parse_ipv4;
            0x86DD:  parse_ipv6;
            default: accept;
        }
    }

#ifdef SINGLE_IPV4_HEADER
    state parse_ipv4 {
#ifdef SINGLE_IPV4_HEADER_SAFE        
        transition select(pkt.lookahead<ipv4_lookahead_h>().ihl) {
        // transition select((pkt.lookahead<bit<8>>())[3:0]) {
            0 &&& ~4w3: reject;
            4         : reject;
            _         : parse_ipv4_with_options;
        }
#else
        transition parse_ipv4_with_options;
#endif
    }

    state parse_ipv4_with_options {
        pkt.extract(hdr.ipv4, ((bit<32>)hdr.ipv4.ihl - 5) * 32);
        transition parse_layer4;
    }
#else
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
            0 &&& ~4w3: reject;
            4         : reject;
            5         : parse_layer4;
            _         : parse_ipv4_options;
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_options, ((bit<32>)hdr.ipv4.ihl - 5) * 32);
        transition parse_layer4;
    }    
#endif
    
    state parse_layer4 {
        meta.l4_lookup           = pkt.lookahead<l4_lookup_t>();
        
        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, 0x01 ) : parse_icmp;
            ( 0, 0x02 ) : parse_igmp;
            ( 0, 0x06 ) : parse_tcp;
            ( 0, 0x11 ) : parse_udp;
            ( 0, _    ) : parse_first_fragment;
            default     : accept;
        }
    }

    state parse_first_fragment {
        meta.first_frag = 1;
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        meta.l4_lookup  = pkt.lookahead<l4_lookup_t>();
        meta.first_frag = 1;
        
        transition select(hdr.ipv6.next_hdr) {
            0x01: parse_icmp;
            0x02: parse_igmp;
            0x06: parse_tcp;
            0x11: parse_udp;
            default: accept;
        }
    }
    
    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }
    
    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }
    
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
    
    state parse_udp {
        pkt.extract(hdr.udp);
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
    in    ingress_intrinsic_metadata_from_parser_t   ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t        ig_intr_md_for_tm)
{
    action send(PortId_t port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }

    action drop() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
    }

    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 65536;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }
        
        default_action = send(64);
        size           = 12288;
    }

    table ipv4_acl {
        key = {
            hdr.ipv4.src_addr     : ternary;
            hdr.ipv4.dst_addr     : ternary;
            hdr.ipv4.protocol     : ternary;
            meta.l4_lookup.word_1 : ternary;
            meta.l4_lookup.word_2 : ternary;
            meta.first_frag       : ternary;
        }
        actions = { NoAction; drop; }
        size    = 2048;
    }
    
    /* The algorithm */
    apply {
        if (hdr.ipv4.isValid() &&
            hdr.ipv4.ttl > 1) {
            if (!ipv4_host.apply().hit) {
                ipv4_lpm.apply();
            }
            ipv4_acl.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control MyIngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_intr_md_for_dprsr)
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

parser MyEgressParser(packet_in      pkt,
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
    in    egress_intrinsic_metadata_from_parser_t      eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t     eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t  eg_intr_md_for_oport)
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
    in    egress_intrinsic_metadata_for_deparser_t  eg_intr_md_for_dprsr)
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
