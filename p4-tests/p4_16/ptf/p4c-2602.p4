/* -*- P4_16 -*- */

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
typedef bit<8>  pkt_type_t;
const pkt_type_t PKT_TYPE_NORMAL  = 1;
const pkt_type_t PKT_TYPE_MIRROR  = 2;
const pkt_type_t PKT_TYPE_CAPTURE = 3;
const pkt_type_t PKT_TYPE_CAPTURE_FINAL = 5;

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
**************************************************************************/
const bit<16> ETHERTYPE_TPID = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IGMP = 2;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_OSPF = 89;
const ip_protocol_t IP_PROTOCOLS_GRE = 47;
/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/

/*  Define all the headers the program will recognize             */
/*  The actual sets of headers processed by each gress can differ */
/* Ingress mirroring information */



typedef bit<4> port_type_t;
const port_type_t FRONTPANEL_PORT = 1;
const port_type_t L23_PORT = 2;
const port_type_t L47_PORT = 3;
const port_type_t CAPTURE_PORT = 4;
const port_type_t RESUBMIT_PORT = 5;

#if __TARGET_TOFINO__ == 1
typedef bit<3> mirror_type_t;
#else
typedef bit<4> mirror_type_t;
#endif
const mirror_type_t MIRROR_TYPE_I2E = 1;
const mirror_type_t MIRROR_TYPE_E2E = 2;

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

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header l23signature_h {
    bit<32> signature_top;
    bit<32> signature_bot;
    bit<32> rx_timestamp;
    bit<32> pgid;
    bit<32> sequence;
    bit<32> txtstamp;
}

header capture_h {
    bit<32> seq_no;
    bit<32> timestamp;
}

header mirror_h {
   pkt_type_t pkt_type;
   bit<8> pad0;
#ifdef L47_BYTE
   bit<8> l47_port;
#else
   bit<4> l47_port;
   bit<4> pad1;
#endif  /* L47_BYTE */
   bit<8> pad2;
   bit<32> mac_timestamp;
}

#if __TARGET_TOFINO__ == 1
typedef bit<32> signature_t;
#else
typedef bit<64> signature_t;
#endif

struct port_metadata_t {
    //temporary since we have only 64-bits port metadata for tofino1
    // will be 192 bits in T2
    signature_t port_signature;
    port_type_t port_type;
    bit<8> capture_port;
}

//@flexible
header example_bridge_h {
   pkt_type_t pkt_type;
   bit<1> l47_timestamp_insert;
   bit<1> l23_txtstmp_insert;
   bit<1> l23_rxtstmp_insert;
   bit<1> rich_register_v;
   bit<4> pad0;
   bit<8> rich_register;
   bit<8> pad1;
}

struct my_ingress_headers_t {
    example_bridge_h  bridge;
    capture_h    capture;
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
    l23signature_h first_payload;
}

struct my_ingress_metadata_t {
    port_metadata_t port_properties;
    bit<16> l47_ib_ethertype;
    MirrorId_t  mirror_session;
    bit<32>  mac_timestamp;
    pkt_type_t pkt_type;

#ifdef CASE_FIX
    bit<8> pad0;
    bit<4> l47_port;
    bit<4> pad1;
    bit<8> pad2;
#endif
}

struct my_egress_headers_t {
    example_bridge_h  bridge;
    capture_h    capture;
    ethernet_h   ethernet;
    vlan_tag_h   vlan_tag;
    ipv4_h       ipv4;
    tcp_h        tcp;
    udp_h        udp;
    l23signature_h first_payload;
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    example_bridge_h  bridge;
    mirror_h  ing_port_mirror;
    MirrorId_t  mirror_session;
    pkt_type_t pkt_type;
}


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
    /***********************  P A R S E R  **************************/
parser IngressParser(packet_in        pkt,
    /* User */    
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
     state start {
        pkt.extract(ig_intr_md);
        meta.port_properties = port_metadata_unpack<port_metadata_t>(pkt);
        meta.pkt_type = PKT_TYPE_NORMAL;
        meta.mac_timestamp = 0;
        meta.mirror_session = 0;
        meta.l47_ib_ethertype = 0;
#ifdef CASE_FIX
        meta.pad0     = 0;
        meta.l47_port = 0;
        meta.pad1     = 0;
        meta.pad2     = 0;
#endif
        hdr.bridge.setValid();
        hdr.bridge.pkt_type = PKT_TYPE_NORMAL; 
        hdr.bridge.l47_timestamp_insert = 0;
        hdr.bridge.l23_txtstmp_insert = 0;
        hdr.bridge.l23_rxtstmp_insert = 0;
        hdr.bridge.rich_register = 0;
        hdr.bridge.rich_register_v = 1w0;
        transition select(meta.port_properties.port_type)
        {
            CAPTURE_PORT : parse_capture_depth; 
            RESUBMIT_PORT: parse_capture;
            default: parse_ethernet;
        }
    }

    state parse_capture_depth {
        pkt.extract(hdr.capture);
        transition accept;
    }

    state parse_capture {
        pkt.extract(hdr.capture);
        meta.pkt_type = PKT_TYPE_CAPTURE;
        hdr.bridge.pkt_type = PKT_TYPE_CAPTURE_FINAL; 
        transition accept;
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
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP: parseTcp;
            IP_PROTOCOLS_UDP: parseUdp;
            default: parseL23;
      }
    }

    state parseTcp {
      pkt.extract(hdr.tcp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseUdp {
      pkt.extract(hdr.udp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseL23 {
      pkt.extract(hdr.first_payload);
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
    bit<8> capture_port;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) identityHash32;
    bit<16> seq_no;

    action setEgPort(PortId_t egress_port)
    {
        ig_tm_md.ucast_egress_port = egress_port;
    }

    table setEgPortTbl{
        key = {
            ig_intr_md.ingress_port : exact;
        }
        actions = {
            setEgPort; 
            NoAction;
        }
        default_action = NoAction;
        size = 8;
    }

    action set_mirror_session_capture(MirrorId_t mirror_session) {
        ig_dprsr_md.mirror_type = MIRROR_TYPE_I2E;
        ig_tm_md.mcast_grp_a = 0;
        meta.mirror_session = mirror_session;
        meta.pkt_type = PKT_TYPE_CAPTURE;
        meta.mac_timestamp = identityHash32.get(ig_intr_md.ingress_mac_tstamp);
    }

    table ingressMirrorTbl {
        key = {
          ig_intr_md.ingress_port : exact;
        }
        actions = {
          set_mirror_session_capture;
          NoAction;
        }
        default_action = NoAction;
        size = 1;
    }
    
    action setCaptureEgPort(PortId_t egress_port)
    {
       ig_tm_md.ucast_egress_port = egress_port;
    }

    table setCaptureTbl {
        key = {
            hdr.capture.seq_no : exact;
        }
        actions = {
            setCaptureEgPort; 
            NoAction;
        }
        default_action = NoAction;
        size = 8;
    }
   
    /*********************  D E P A R S E R  ************************/

    apply {
        setEgPortTbl.apply();
        ingressMirrorTbl.apply();
        if (hdr.capture.isValid())
            setCaptureTbl.apply();
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
    Mirror() mirror;
    apply {
        if (ig_dprsr_md.mirror_type == MIRROR_TYPE_I2E) {
#ifdef CASE_FIX
            mirror.emit<mirror_h>(meta.mirror_session,
                {
                    meta.pkt_type[7:0],
                    meta.pad0,
                    meta.l47_port,
                    meta.pad1,
                    meta.pad2,
                    meta.mac_timestamp
                });
#else
            mirror.emit<mirror_h>(meta.mirror_session,
                {
                    meta.pkt_type[7:0],
                    8w0,
#ifdef L47_BYTE
                    8w0,
#else
                    4w0,
                    4w0,
#endif  /* L47_BYTE */
                    8w0,
                    meta.mac_timestamp
                });
#endif
        }
        pkt.emit(hdr);
    }
}


/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 ***********/
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
        mirror_h mirror_md = pkt.lookahead<mirror_h>();
        transition select(mirror_md.pkt_type) {
            PKT_TYPE_MIRROR : parse_mirror;
            PKT_TYPE_NORMAL : parse_bridge;
            PKT_TYPE_CAPTURE: parse_capture;
            PKT_TYPE_CAPTURE_FINAL : parse_capture_final;
        default : accept;
        }
    }
    
    state parse_capture {
        pkt.extract(meta.ing_port_mirror);
        hdr.capture.setValid();
        meta.pkt_type = PKT_TYPE_CAPTURE;
        transition accept;
    }

    state parse_capture_final {
        pkt.extract(meta.bridge);
        pkt.extract(hdr.capture);
        meta.pkt_type = PKT_TYPE_CAPTURE_FINAL;
        transition accept;
    }

    state parse_mirror {
        pkt.extract(meta.ing_port_mirror);
        pkt.extract(hdr.ethernet);
        meta.pkt_type = PKT_TYPE_NORMAL;
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_TPID:  parse_vlan_tag;
            ETHERTYPE_IPV4:  parse_ipv4;
            default: accept;
        }
    }

    state parse_bridge {
        pkt.extract(meta.bridge);
        meta.pkt_type = PKT_TYPE_NORMAL;
        meta.ing_port_mirror.pkt_type = PKT_TYPE_NORMAL;
        meta.ing_port_mirror.mac_timestamp = 0;
        meta.pkt_type = PKT_TYPE_NORMAL;
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
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP: parseTcp;
            IP_PROTOCOLS_UDP: parseUdp;
            default: parseL23;
      }
    }

    state parseTcp {
      pkt.extract(hdr.tcp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseUdp {
      pkt.extract(hdr.udp);
      pkt.extract(hdr.first_payload);
      transition accept;
    }

    state parseL23 {
      pkt.extract(hdr.first_payload);
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
    action insert_capture_port()
    {
        hdr.capture.seq_no = 1;
    }
    /******************************************************************/
    apply
    {
       if (hdr.capture.isValid())
        insert_capture_port();
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
