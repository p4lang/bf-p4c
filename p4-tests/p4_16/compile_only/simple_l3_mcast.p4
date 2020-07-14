/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

enum bit<8>  ip_proto_t {
    ICMP  = 1,
    IGMP  = 2,
    TCP   = 6,
    UDP   = 17
}

typedef bit<48>   mac_addr_t;
typedef bit<32>   ipv4_addr_t;
typedef bit<128>  ipv6_addr_t;

/******** TABLE SIZING **********/
const int IPV4_HOST_SIZE = 65536;
const int IPV4_LPM_SIZE  = 12288;
const int MCAST_MOD_SIZE = 32768;

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
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    ip_proto_t   protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}

header options_h {  /* Can be used for both IPv4 and TCP options */
    varbit<320> data;
}

header ipv6_h {
    bit<4>       version;
    bit<8>       traffic_class;
    bit<20>      flow_label;
    bit<16>      payload_len;
    ip_proto_t   next_hdr;
    bit<8>       hop_limit;
    ipv6_addr_t  src_addr;
    ipv6_addr_t  dst_addr;
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
}

header tcp_checksum_h {
    bit<16>  checksum;
    bit<16>  urgent_ptr;
}

header udp_h {
    bit<16>  src_port;
    bit<16>  dst_port;
    bit<16>  len;
}

header udp_checksum_h {
    bit<16>  checksum;
}

@flexible
header bridge_meta_h {
    bit<8>   ttl_dec;
    bit<1>   udp_checksum_update;
    bit<16>  l4_payload_checksum;
}

/*************************************************************************
 **********  C O M M O N    P A C K E T    P R O C E S S I N G ***********
 *************************************************************************/

struct packet_headers_t {
    ethernet_h         ethernet;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    options_h          ipv4_options;
    ipv6_h             ipv6;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    tcp_checksum_h     tcp_ipv4_checksum;
    tcp_checksum_h     tcp_ipv6_checksum;
    udp_h              udp;
    udp_checksum_h     udp_ipv4_checksum;
    udp_checksum_h     udp_ipv6_checksum;
}

struct l4_lookup_t {
    bit<16>  word_1;
    bit<16>  word_2;
}

struct packet_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
    bit<1>        ipv4_checksum_err;
    bit<16>       l4_payload_checksum;
    bool          udp_checksum_update;
}

parser PacketParser(packet_in  pkt,
    out packet_headers_t       hdr,
    out packet_metadata_t      meta)
    (bool do_checksums)
{
    Checksum() ipv4_checksum;

    Checksum() icmp_checksum;
    Checksum() igmp_checksum;
    Checksum() tcp_ipv4_checksum;
    Checksum() tcp_ipv6_checksum;
    Checksum() udp_ipv4_checksum;
    Checksum() udp_ipv6_checksum;
    
    /* Packet Parser Metadata Initialization */
    state start {
        meta.l4_lookup            = { 0, 0 };
        meta.first_frag           = 0;
        meta.ipv4_checksum_err    = 0;
        meta.l4_payload_checksum  = 0;
        meta.udp_checksum_update  = true;
        transition parse_ethernet;
    }

    /* Packet parsing */
    @name("parse_ethernet")
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            ether_type_t.IPV6 :  parse_ipv6;
            default :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            ether_type_t.IPV6 :  parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);

        /* Start computing residual checksums for TCP and UDP */
        tcp_ipv4_checksum.subtract({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                8w0, hdr.ipv4.protocol
            });
        udp_ipv4_checksum.subtract({
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                8w0, hdr.ipv4.protocol
            });
 
        transition select(hdr.ipv4.ihl) {
            5     : parse_ipv4_no_options;
            6..15 : parse_ipv4_options;
            /* Drop IPv4 packets with ipv4.ihl=0..4 */
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_options, ((bit<32>)hdr.ipv4.ihl - 5) * 32);

        /* Checksum Verification */
        ipv4_checksum.add(hdr.ipv4_options);

        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        /* Checksum Verification */
        meta.ipv4_checksum_err = (bit<1>)ipv4_checksum.verify();
        
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP  ) : parse_tcp_ipv4;
            ( 0, ip_proto_t.UDP  ) : parse_udp_ipv4;
            ( 0, _               ) : parse_first_fragment;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();

        /* Start Computing residual checksums for TCP and UDP */
        tcp_ipv6_checksum.subtract({
                hdr.ipv6.src_addr,
                hdr.ipv6.dst_addr,
                8w0, hdr.ipv6.next_hdr
            });
        udp_ipv6_checksum.subtract({
                hdr.ipv6.src_addr,
                hdr.ipv6.dst_addr,
                8w0, hdr.ipv6.next_hdr
            });
 
       transition select(hdr.ipv6.next_hdr) {
            ip_proto_t.ICMP : parse_icmp;
            ip_proto_t.IGMP : parse_igmp;
            ip_proto_t.TCP  : parse_tcp_ipv6;
            ip_proto_t.UDP  : parse_udp_ipv6;
            default : parse_first_fragment;
        }
    }
    
    state parse_first_fragment {
        meta.first_frag = 1;
        transition accept;
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);

        /* Calculate Payload checksum */
        icmp_checksum.subtract({hdr.icmp.type_code, hdr.icmp.checksum});
        meta.l4_payload_checksum = icmp_checksum.get();

        transition parse_first_fragment;
    }
    
    state parse_igmp {
        pkt.extract(hdr.igmp);

        /* Calculate Payload checksum */
        igmp_checksum.subtract({hdr.igmp.type_code, hdr.igmp.checksum});
        meta.l4_payload_checksum = igmp_checksum.get();

        transition parse_first_fragment;
    }
    
    state parse_tcp_ipv4 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_ipv4_checksum);

        /* Calculate Payload checksum */
       /* tcp_ipv4_checksum.subtract({
                hdr.tcp.src_port,
                hdr.tcp.dst_port,
                hdr.tcp.seq_no,
                hdr.tcp.ack_no,
                hdr.tcp.data_offset, hdr.tcp.res, hdr.tcp.flags,
                hdr.tcp.window,
                hdr.tcp_ipv4_checksum.checksum,
                hdr.tcp_ipv4_checksum.urgent_ptr
            });

        meta.l4_payload_checksum = tcp_ipv4_checksum.get();
         */   
        transition parse_first_fragment;
    }
    
    state parse_udp_ipv4 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_ipv4_checksum);
        meta.first_frag = 1;

        /* Calculate Payload checksum */
        /*
        udp_ipv4_checksum.subtract({
                hdr.udp.src_port,
                hdr.udp.dst_port,
                // hdr.udp.len, Do not subtract the length!!!!
                hdr.udp_ipv4_checksum.checksum
            });

        meta.l4_payload_checksum = udp_ipv4_checksum.get();*/
            
        transition parse_first_fragment;
    }

    state parse_tcp_ipv6 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_ipv6_checksum);

        /* Calculate Payload checksum */
        /*
        tcp_ipv6_checksum.subtract({
                hdr.tcp.src_port,
                hdr.tcp.dst_port,
                hdr.tcp.seq_no,
                hdr.tcp.ack_no,
                hdr.tcp.data_offset, hdr.tcp.res, hdr.tcp.flags,
                hdr.tcp.window,
                hdr.tcp_ipv6_checksum.checksum,
                hdr.tcp_ipv6_checksum.urgent_ptr
            });
        
        meta.l4_payload_checksum = tcp_ipv6_checksum.get();*/
        transition parse_first_fragment;
    }
    
    state parse_udp_ipv6 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_ipv6_checksum);

        /* Calculate Payload checksum */
       /*
        udp_ipv6_checksum.subtract({
                hdr.udp.src_port,
                hdr.udp.dst_port,
                hdr.udp.len,
                hdr.udp_ipv6_checksum.checksum
            });
        meta.l4_payload_checksum = udp_ipv6_checksum.get();*/
            
        transition parse_first_fragment;
    }
}   

/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/
 
    /***********************  H E A D E R S  ************************/

struct my_ingress_headers_t {
    bridge_meta_h      bridge;
    ethernet_h         ethernet;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    options_h          ipv4_options;
    ipv6_h             ipv6;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    tcp_checksum_h     tcp_ipv4_checksum;
    tcp_checksum_h     tcp_ipv6_checksum;
    udp_h              udp;
    udp_checksum_h     udp_ipv4_checksum;
    udp_checksum_h     udp_ipv6_checksum;
}

    /******  G L O B A L   I N G R E S S   M E T A D A T A  *********/

struct my_ingress_metadata_t {
    l4_lookup_t   l4_lookup;
    bit<1>        first_frag;
    bit<1>        ipv4_checksum_err;
    bit<16>       l4_payload_checksum;
    bool          udp_checksum_update;
}

    /***********************  P A R S E R  **************************/

parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    PacketParser(do_checksums=true) packet_parser;
    packet_headers_t  pkt_hdr;
    packet_metadata_t pkt_meta;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        
        /* Use the common parser */
        packet_parser.apply(pkt, pkt_hdr, pkt_meta);

        /* Copy the parsed values into our structures */
        hdr.ethernet           = pkt_hdr.ethernet;
        hdr.vlan_tag[0]        = pkt_hdr.vlan_tag[0];
        hdr.vlan_tag[1]        = pkt_hdr.vlan_tag[1];
        hdr.ipv4               = pkt_hdr.ipv4;
//        hdr.ipv4_options       = pkt_hdr.ipv4_options;
        hdr.ipv6               = pkt_hdr.ipv6;
        hdr.icmp               = pkt_hdr.icmp;
        hdr.igmp               = pkt_hdr.igmp;
        hdr.tcp                = pkt_hdr.tcp;
        hdr.tcp_ipv4_checksum  = pkt_hdr.tcp_ipv4_checksum;
        hdr.tcp_ipv6_checksum  = pkt_hdr.tcp_ipv6_checksum;
        hdr.udp                = pkt_hdr.udp;
        hdr.udp_ipv4_checksum  = pkt_hdr.udp_ipv4_checksum;
        hdr.udp_ipv6_checksum  = pkt_hdr.udp_ipv6_checksum;

        meta.l4_lookup.word_1    = pkt_meta.l4_lookup.word_1;
        meta.l4_lookup.word_2    = pkt_meta.l4_lookup.word_2;
        meta.first_frag          = pkt_meta.first_frag;
        meta.ipv4_checksum_err   = pkt_meta.ipv4_checksum_err;
        meta.l4_payload_checksum = pkt_meta.l4_payload_checksum;
        meta.udp_checksum_update = false;

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
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action multicast(MulticastGroupId_t mcast_grp) {
        ig_tm_md.mcast_grp_a = mcast_grp;
    }
    
    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop; multicast;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 65536;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; multicast; }
        
        default_action = drop();
        size           = 12288;
    }

    table ipv6_host {
        key = { hdr.ipv6.dst_addr : exact; }
        actions = {
            send; drop; multicast;
            @defaultonly NoAction;
        }
        const default_action = NoAction();
        size = 32768;
    }

    table ipv6_lpm {
        key     = { hdr.ipv6.dst_addr : lpm; }
        actions = { send; drop; multicast; }
        
        default_action = drop();
        size           = 4096;
    }

    /* The algorithm */
    apply {
        /* Prepare bridge metadata */
        hdr.bridge.setValid();
        hdr.bridge.l4_payload_checksum = meta.l4_payload_checksum;

        /* 
         * As per RFC... if UDP checksum is eqal to 0, it should be neither 
         * verified, nor recomputed
         */
        if ((hdr.udp_ipv4_checksum.isValid() &&
                hdr.udp_ipv4_checksum.checksum == 0) ||
            (hdr.udp_ipv6_checksum.isValid() &&
                hdr.udp_ipv6_checksum.checksum == 0)) {
            meta.udp_checksum_update = false;
        }

        /* 
         * As per RFC..., TCP checksum cannot be equal to 0. If we do not 
         * handle this case or do nothing, the incorrect checksum will be 
         * fixed. 
         */
        if ((hdr.tcp_ipv4_checksum.isValid() &&
                hdr.tcp_ipv4_checksum.checksum == 0) ||
            (hdr.tcp_ipv6_checksum.isValid() &&
                hdr.tcp_ipv6_checksum.checksum == 0)) {
            /* Handle packets with incorrect checksum */
            drop();
        }

        
        
        /* Actual processing */
        if (hdr.ipv4.isValid()) {
            if (meta.ipv4_checksum_err == 0 && hdr.ipv4.ttl > 1) {
                if (!ipv4_host.apply().hit) {
                    ipv4_lpm.apply();
                }
            }
        } else if (hdr.ipv6.isValid()) {
            if (hdr.ipv6.hop_limit > 1) {
                if (!ipv6_host.apply().hit) {
                    ipv6_lpm.apply();
                }
            }
        }

        /* Put the final values into the bridge metadata header */
        hdr.bridge.udp_checksum_update = (bit<1>)meta.udp_checksum_update;
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
    ethernet_h         ethernet;
    vlan_tag_h[2]      vlan_tag;
    ipv4_h             ipv4;
    options_h          ipv4_options;
    ipv6_h             ipv6;
    icmp_h             icmp;
    igmp_h             igmp;
    tcp_h              tcp;
    tcp_checksum_h     tcp_ipv4_checksum;
    tcp_checksum_h     tcp_ipv6_checksum;
    udp_h              udp;
    udp_checksum_h     udp_ipv4_checksum;
    udp_checksum_h     udp_ipv6_checksum;
}

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    l4_lookup_t  l4_lookup;
    bit<1>       first_frag;
    bit<16>      l4_payload_checksum;
    bool         udp_checksum_update;
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in      pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    bridge_meta_h bridge;
    
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition meta_init;
    }

        /* User Metadata Initialization */
    state meta_init {
        meta.l4_lookup         = { 0, 0 };
        meta.first_frag        = 0;
        transition parse_bridge;
    }

    state parse_bridge {
        pkt.extract(bridge);
        meta.l4_payload_checksum = bridge.l4_payload_checksum;
        meta.udp_checksum_update = (bool)bridge.udp_checksum_update;
        transition parse_ethernet;
    }

    /* Packet parsing */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            ether_type_t.IPV6 :  parse_ipv6;
            default :  accept;
        }
    }

    state parse_vlan_tag {
        pkt.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ether_type) {
            ether_type_t.TPID :  parse_vlan_tag;
            ether_type_t.IPV4 :  parse_ipv4;
            ether_type_t.IPV6 :  parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        
        transition select(hdr.ipv4.ihl) {
             5     : parse_ipv4_no_options;
             6..15 : parse_ipv4_options;
            /* Hopefully, there will drop all the bad ones at ingress */
        }
    }

    state parse_ipv4_options {
        pkt.extract(hdr.ipv4_options, ((bit<32>)hdr.ipv4.ihl - 5) * 32);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP  ) : parse_tcp_ipv4;
            ( 0, ip_proto_t.UDP  ) : parse_udp_ipv4;
            ( 0, _               ) : parse_first_fragment;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        meta.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv6.next_hdr) {
            ip_proto_t.ICMP : parse_icmp;
            ip_proto_t.IGMP : parse_igmp;
            ip_proto_t.TCP  : parse_tcp_ipv6;
            ip_proto_t.UDP  : parse_udp_ipv6;
            default : parse_first_fragment;
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
        meta.first_frag = 1;
        transition parse_first_fragment;
    }
    
    state parse_tcp_ipv4 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_ipv4_checksum);
        transition parse_first_fragment;
    }
    
    state parse_udp_ipv4 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_ipv4_checksum);
        transition parse_first_fragment;
    }

    state parse_tcp_ipv6 {
        pkt.extract(hdr.tcp);
        pkt.extract(hdr.tcp_ipv6_checksum);
        transition parse_first_fragment;
    }
    
    state parse_udp_ipv6 {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.udp_ipv6_checksum);
        transition parse_first_fragment;
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
    action modify_packet_vlan(bit<12> vlan_id, bit<48> dstmac,
                              bit<32> dstip)
    {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].vid        = vlan_id;
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.dst_addr   = dstmac;
        hdr.ethernet.ether_type = ether_type_t.TPID;

        hdr.ipv4.dst_addr       = dstip;        
    }

    action modify_packet_no_vlan(bit<48> dstmac, bit<32> dstip) {
        hdr.ethernet.dst_addr = dstmac;
        hdr.ipv4.dst_addr     = dstip;
    }

    table mcast_mods {
        key = {
            eg_intr_md.egress_rid : ternary;
            hdr.ipv4.dst_addr     : ternary;  /* This is optional */
        }
        actions = {
            modify_packet_vlan; modify_packet_no_vlan;
            NoAction;
        }
        size = 4096;
    }
    
    action modify_packet_ipv6_vlan(bit<12>  vlan_id, bit<48> dstmac,
                                   bit<128> dstip)
    {
        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].vid        = vlan_id;
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.dst_addr   = dstmac;
        hdr.ethernet.ether_type = ether_type_t.TPID;

        hdr.ipv6.dst_addr       = dstip;        
    }

    action modify_packet_ipv6_no_vlan(bit<48> dstmac, bit<128> dstip) {
        hdr.ethernet.dst_addr = dstmac;
        hdr.ipv6.dst_addr     = dstip;
    }

    table ipv6_mcast_mods {
        key = {
            eg_intr_md.egress_rid : ternary;
            hdr.ipv6.dst_addr     : ternary;  /* This is optional */
        }
        actions = {
            modify_packet_ipv6_vlan; modify_packet_ipv6_no_vlan;
            NoAction;
        }
        size = 4096;
    }
    
    apply {
        if (hdr.ipv4.isValid()) {
            mcast_mods.apply();
        } else if (hdr.ipv6.isValid()) {
            ipv6_mcast_mods.apply();
        }
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
    Checksum()  ipv4_checksum;
    Checksum()  icmp_checksum;
    Checksum()  igmp_checksum;
    Checksum()  tcp_checksum;
    Checksum()  udp_checksum;

    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                    hdr.ipv4.version,
                    hdr.ipv4.ihl,
                    hdr.ipv4.diffserv,
                    hdr.ipv4.total_len,
                    hdr.ipv4.identification,
                    hdr.ipv4.flags,
                    hdr.ipv4.frag_offset,
                    hdr.ipv4.ttl,
                    hdr.ipv4.protocol,
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    hdr.ipv4_options.data
                });
        }

        if (hdr.icmp.isValid()) {
             hdr.icmp.checksum = icmp_checksum.update({
                    hdr.icmp.type_code,
                    /* Any headers past ICMP */
                    meta.l4_payload_checksum
                });
        }
        

        if (hdr.igmp.isValid()) {
            hdr.igmp.checksum = igmp_checksum.update({
                    hdr.igmp.type_code,
                    /* Any headers past IGMP */
                    meta.l4_payload_checksum
               });
        }
        
        if (hdr.tcp_ipv4_checksum.isValid()) {
            hdr.tcp_ipv4_checksum.checksum = tcp_checksum.update({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    8w0, hdr.ipv4.protocol,
                    hdr.tcp.src_port,
                    hdr.tcp.dst_port,
                    hdr.tcp.seq_no,
                    hdr.tcp.ack_no,
                    hdr.tcp.data_offset, hdr.tcp.res, hdr.tcp.flags,
                    hdr.tcp.window,
                    hdr.tcp_ipv4_checksum.urgent_ptr,
                    /* Any headers past TCP */
                    meta.l4_payload_checksum
               });
        }
        
        if (hdr.tcp_ipv6_checksum.isValid()) {
            hdr.tcp_ipv4_checksum.checksum = tcp_checksum.update({
                    hdr.ipv6.src_addr,
                    hdr.ipv6.dst_addr, 
                    8w0, hdr.ipv6.next_hdr,
                    hdr.tcp.src_port,
                    hdr.tcp.dst_port,
                    hdr.tcp.seq_no,
                    hdr.tcp.ack_no,
                    hdr.tcp.data_offset, hdr.tcp.res, hdr.tcp.flags,
                    hdr.tcp.window,
                    hdr.tcp_ipv6_checksum.urgent_ptr,
                    /* Any headers past TCP */
                    meta.l4_payload_checksum
               });
        }

        if (meta.udp_checksum_update) {
            hdr.udp_ipv4_checksum.checksum = udp_checksum.update({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr, 
                    8w0, hdr.ipv4.protocol,
                    hdr.udp.src_port,
                    hdr.udp.dst_port,
                    /* Any headers past UDP */
                    meta.l4_payload_checksum
                },
                true);  /* zeros-as_ones=true */
            
             hdr.udp_ipv6_checksum.checksum = udp_checksum.update({
                    hdr.ipv6.src_addr,
                    hdr.ipv6.dst_addr, 
                    8w0, hdr.ipv6.next_hdr,
                    hdr.udp.src_port,
                    hdr.udp.dst_port,
                    /* Any headers past UDP */
                    meta.l4_payload_checksum
                },
                true);  /* zeros-as_ones=true */
        } 
        
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

