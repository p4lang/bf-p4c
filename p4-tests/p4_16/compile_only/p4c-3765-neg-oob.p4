/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

/*************************************************************************
 ************* C O N S T A N T S    A N D   T Y P E S  *******************
*************************************************************************/
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

enum bit<8> ip_proto_t {
    HOPOPT = 0,
    ICMP = 1,
    IGMP = 2,
    TCP = 6,
    UDP = 17,
    IPV6_ROUTE = 43,
    IPV6_FRAGMENT = 44,
    IPSEC_ESP = 50,
    IPSEC_AH = 51,
    IPV6_OPTS = 60,
    MOBILITY = 135,
    SHIM6 = 140,
    RESERVED_FD = 253,
    RESERVED_FE = 254
}

struct l4_lookup_t {
    bit<16> word_1;
    bit<16> word_2;
}

/*************************************************************************
 ***********************  H E A D E R S  *********************************
 *************************************************************************/
/*
 *  Define all the headers the program will recognize             
 *  The actual sets of headers processed by each gress can potentially differ 
 * 
 * In this particular case, the actual set of the processed headers will
 * be defined in the parser module as packet_headers_t
*/

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
}

header llc_h {
    bit<16> len;
    bit<8> dsap;
    bit<8> ssap;
    bit<8> ctrl;
}

header snap_h {
    bit<24> oui;
    ether_type_t ether_type;
}

header etherII_h {
    ether_type_t ether_type;
}

header vlan_tag_h {
    ether_type_t tpid;
    bit<3> pcp;
    bit<1> dei;
    bit<12> vid;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    ip_proto_t protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

/* 
 * Depending on the parser, only one of these two header types will
 * be used. We could've #ifdef'ed them, but decided not to.
 */
header ipv4_option_word_h {
    bit<32> data;
}

header ipv4_options_h {
    varbit<320> data;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    ip_proto_t next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

/* 
 * Depending on the parser, only one of these two header types will
 * be used. We could've #ifdef'ed them, but decided not to.
 */
header ipv6_ext_hdr_h {
    ip_proto_t next_hdr;
    bit<8> ext_len;
    bit<48> data;
}

/* 
 * Depending on the parser, only one of these two header types will
 * be used. We could've #ifdef'ed them, but decided not to.
 */
header ipv6_ext_block_h {
    bit<64> data;
}

header ipv6_ext_h {
    varbit<640> data;
}

/*
 * Layer 4 Headers 
 */
header icmp_h {
    bit<16> type_code;
    bit<16> checksum;
}

header igmp_h {
    bit<16> type_code;
    bit<16> checksum;
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
    bit<16> len;
    bit<16> checksum;
}

/*************************************************************************
 *********** C O M M O N    P A C K E T   P R O C E S S I N G ************
 *************************************************************************/

/* 
 * The implementation is supposed to provide a parser (PacketParser) and 
 * a deparser (PacketDeparser) that parse and deparse packet_headers_t and
 * also return parser_metadata_t. All are defined in the module.
 *
 * Here we provide two implementations: both parse IPv4, Layer 4 Headers and
 * Layer 4 User-Defined Fields (UDF)
 */



# 1 "../../p4c-3765/parde_no_varbit.p4" 1
/* -*- P4_16 -*- */

/*************************************************************************
 * C O M M O N   P A C K E T   P A R S I N G   A N D   D E P A R S I N G *
 *************************************************************************/

/*
 * This is the code for the common parser and deparser, used by simple_l3_acl.p4
 *
 * Given that the packet format is tightly couple with the parser code,
 * it makes sense to keep the structure of recognized headers here as well.
 *
 * Here is what the file defines:
 *
 * struct packet_headers_t  -- the list of parsed (and deparsed headers)
 * struct parser_metadata_t -- additional metadata that gets populated as a 
 *                             direct result of packet parsing
 * parser  PacketParser     -- the actual packet parsing code
 * control PacketDeparser   -- packet deparser code
 */

/* 
 * Additional types needed for lookahead()
 */
# 41 "../../p4c-3765/parde_no_varbit.p4"
/* The packet headers these parser recognizes */
struct packet_headers_t {
    ethernet_h ethernet;
    vlan_tag_h[3] vlan_tag;
    llc_h llc;
    snap_h snap;
    etherII_h etherII;
    ipv4_h ipv4;
    ipv4_option_word_h[10] ipv4_option_word;
    ipv6_h ipv6;
    ipv6_ext_hdr_h ipv6_ext_hdr;
    ipv6_ext_block_h[8] ipv6_ext_block;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    udp_h udp;
}

/* Additional metadata this parser can populate */

struct parser_metadata_t {
    ether_type_t l3_protocol;
    ip_proto_t l4_protocol;
    l4_lookup_t l4_lookup;
    bit<1> first_frag;
    bit<1> extra_vlan_tags;
}

    /***********************  P A R S E R  **************************/
parser PacketParser(packet_in pkt,
                    out packet_headers_t hdr,
                    out parser_metadata_t parser_md)
{
    llc_h llc;






    state start {
        parser_md.l3_protocol = (ether_type_t) 0;
        parser_md.l4_protocol = (ip_proto_t) 0;
        parser_md.l4_lookup = { 0, 0 };
        parser_md.first_frag = 0;
        parser_md.extra_vlan_tags = 0;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);

        llc = pkt.lookahead<llc_h>();
        transition select(llc.len, llc.dsap, llc.ssap) {




            (0x0000 &&& 0x0C00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0400 &&& 0x0E00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0000 &&& 0x0C00, _, _) : parse_llc_snap;
            (0x0400 &&& 0x0E00, _, _) : parse_llc_snap;

            (ether_type_t.TPID &&& 0xEFFF, _, _) : parse_vlan_tag;
            default : parse_etherII;
        }
    }
# 130 "../../p4c-3765/parde_no_varbit.p4"
    state parse_vlan_tag {
        transition parse_vlan_tag_0;
    }

    state parse_vlan_tag_0 {
        pkt.extract(hdr.vlan_tag[0]);

        llc = pkt.lookahead<llc_h>();
        transition select(llc.len, llc.dsap, llc.ssap) {




            (0x0000 &&& 0x0C00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0400 &&& 0x0E00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0000 &&& 0x0C00, _, _) : parse_llc;
            (0x0400 &&& 0x0E00, _, _) : parse_llc;

            (ether_type_t.TPID, _, _) : parse_vlan_tag_1;
            default : parse_etherII;
        }
    }
    state parse_vlan_tag_1 {
        pkt.extract(hdr.vlan_tag[1]);

        llc = pkt.lookahead<llc_h>();
        transition select(llc.len, llc.dsap, llc.ssap) {




            (0x0000 &&& 0x0C00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0400 &&& 0x0E00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0000 &&& 0x0C00, _, _) : parse_llc;
            (0x0400 &&& 0x0E00, _, _) : parse_llc;

            (ether_type_t.TPID, _, _) : parse_vlan_tag_2;
            default : parse_etherII;
        }
    }

    state parse_vlan_tag_2 {
        pkt.extract(hdr.vlan_tag[2]);

        llc = pkt.lookahead<llc_h>();
        transition select(llc.len, llc.dsap, llc.ssap) {




            (0x0000 &&& 0x0C00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0400 &&& 0x0E00, 0xAA, 0xAA) : parse_llc_snap;
            (0x0000 &&& 0x0C00, _, _) : parse_llc;
            (0x0400 &&& 0x0E00, _, _) : parse_llc;

            (ether_type_t.TPID, _, _) : parse_extra_vlan_tags;
            default : parse_etherII;
        }
    }

    state parse_extra_vlan_tags {
        parser_md.extra_vlan_tags = 1;
        transition parse_etherII;
    }


    state parse_llc {
        pkt.extract(hdr.llc);
        transition accept;
    }

    state parse_llc_snap {
        pkt.extract(hdr.llc);
        pkt.extract(hdr.snap);
        parser_md.l3_protocol = hdr.snap.ether_type;
        transition parse_l3;
    }

    state parse_etherII {
        pkt.extract(hdr.etherII);
        parser_md.l3_protocol = hdr.etherII.ether_type;
        transition parse_l3;
    }

    state parse_l3 {
        transition select(parser_md.l3_protocol) {
            ether_type_t.IPV4 : parse_ipv4;
            ether_type_t.IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        parser_md.l4_protocol = hdr.ipv4.protocol;

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
            /* 
             * Packets with other values of IHL are illegal and will be
             * dropped by the parser
             */
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ipv4_option_word[0]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        pkt.extract(hdr.ipv4_option_word[7]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        pkt.extract(hdr.ipv4_option_word[7]);
        pkt.extract(hdr.ipv4_option_word[8]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ipv4_option_word[0]);
        pkt.extract(hdr.ipv4_option_word[1]);
        pkt.extract(hdr.ipv4_option_word[2]);
        pkt.extract(hdr.ipv4_option_word[3]);
        pkt.extract(hdr.ipv4_option_word[4]);
        pkt.extract(hdr.ipv4_option_word[5]);
        pkt.extract(hdr.ipv4_option_word[6]);
        pkt.extract(hdr.ipv4_option_word[7]);
        pkt.extract(hdr.ipv4_option_word[8]);
        pkt.extract(hdr.ipv4_option_word[9]);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        parser_md.l4_lookup = pkt.lookahead<l4_lookup_t>();

        transition select(hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            ( 0, ip_proto_t.ICMP ) : parse_icmp;
            ( 0, ip_proto_t.IGMP ) : parse_igmp;
            ( 0, ip_proto_t.TCP ) : parse_tcp;
            ( 0, ip_proto_t.UDP ) : parse_udp;
            ( 0, _ ) : parse_first_fragment;
            default : accept;
        }
    }

    state parse_first_fragment {
        parser_md.first_frag = 1;
        transition accept;
    }
# 529 "../../p4c-3765/parde_no_varbit.p4"
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);

        transition select(hdr.ipv6.next_hdr) {







            ip_proto_t.IPV6_FRAGMENT : parse_ipv6_frag_ext;
            default: parse_ipv6_no_ext;
        }
    }

   state parse_ipv6_frag_ext {
        pkt.extract(hdr.ipv6_ext_hdr);



        parser_md.l4_protocol = hdr.ipv6_ext_hdr.next_hdr;

        transition select(
            hdr.ipv6_ext_hdr.ext_len, hdr.ipv6_ext_hdr.data[47:35]) {
            (0, 0) : parse_ipv6_after_ext;
            default: accept;
        }
    }
# 633 "../../p4c-3765/parde_no_varbit.p4"
    state parse_ipv6_no_ext {
        parser_md.l4_protocol = hdr.ipv6.next_hdr;
        transition parse_ipv6_after_ext;
    }

    state parse_ipv6_after_ext {
        parser_md.l4_lookup = pkt.lookahead<l4_lookup_t>();
        /* Note, we cannot get here if this is not a first fragment */
        transition select(parser_md.l4_protocol) {
            ip_proto_t.ICMP : parse_icmp;
            ip_proto_t.IGMP : parse_igmp;
            ip_proto_t.TCP : parse_tcp;
            ip_proto_t.UDP : parse_udp;
            default: parse_first_fragment;
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
}

    /*********************** D E P A R S E R  **************************/
control PacketDeparser(packet_out pkt,
                       in packet_headers_t hdr)
{
    apply {
        pkt.emit(hdr);
    }
}
# 189 "../../p4c-3765/simple_l3_acl.p4" 2


/*************************************************************************
 **************  I N G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

typedef packet_headers_t my_ingress_headers_t;

struct my_ingress_metadata_t {
    parser_metadata_t parser_md;
    /* Add more fields if necessary */
}

parser IngressParser(packet_in pkt,
    /* User */
    out my_ingress_headers_t hdr,
    out my_ingress_metadata_t meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t ig_intr_md)
{
    /* 
     * We instantiate the packet parser, since we might also need in Egress.
     * Otherwise we could have invoked it directly, i.e. PacketParser.apply()
     */
    PacketParser() packet_parser;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        /* Invoke Common Packet Parser */
        packet_parser.apply(pkt, hdr, meta.parser_md);

        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

/* Common drop algorithm for ingress and egress. */
action set_drop(inout bit<3> drop_ctl) {
    drop_ctl = drop_ctl | 1;
}

control Ingress(
    /* User */
    inout my_ingress_headers_t hdr,
    inout my_ingress_metadata_t meta,
    /* Intrinsic */
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action send(PortId_t port) {
            ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        set_drop(ig_dprsr_md.drop_ctl);
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
        key = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }

        default_action = send(64);
        size = 1024;
    }

    action do_acl(bool do_redirect, PortId_t port,
        bool do_dst_mac, mac_addr_t new_dst_mac,
        bool do_src_mac, mac_addr_t new_src_mac)
    {
        /* 
         * On Tofino, only a boolean action data parameter can be used
         * as a condition
         */
        if (do_redirect) {
            send(port);
        }

        /* Ternary operation is also supported with the same restriction */
        hdr.ethernet.dst_addr = (do_dst_mac)
                                    ? new_dst_mac
                                    : hdr.ethernet.dst_addr;

        hdr.ethernet.src_addr = (do_src_mac)
                                    ? new_src_mac
                                    : hdr.ethernet.src_addr;
    }

    action do_ipmc_ether() {
        hdr.ethernet.dst_addr[47:24] = 0x01_00_5E;
        hdr.ethernet.dst_addr[23:0] = hdr.ipv4.dst_addr[23:0] & ~24w0x80_00_00;
    }

    table ipv4_acl {
        key = {
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            meta.parser_md.l4_lookup.word_1 : ternary;
            meta.parser_md.l4_lookup.word_2 : ternary;
            meta.parser_md.first_frag : ternary;
            ig_intr_md.ingress_port : ternary;
            ig_tm_md.ucast_egress_port : ternary;
        }
        actions = { NoAction; drop; send; do_acl; do_ipmc_ether; }
        size = 1024;
    }

    /* The algorithm */
    apply {
        if (hdr.ipv4.isValid() && hdr.ipv4.ttl > 1) {
            if (!ipv4_host.apply().hit) {
                ipv4_lpm.apply();
            }
            ipv4_acl.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t hdr,
    in my_ingress_metadata_t meta,
    /* Intrinsic */
    in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    PacketDeparser() packet_deparser;

    apply {
        packet_deparser.apply(pkt, hdr);
    }
}

/*************************************************************************
 ****************  E G R E S S   P R O C E S S I N G   *******************
 *************************************************************************/

    /***********************  H E A D E R S  ************************/

typedef packet_headers_t my_egress_headers_t;

    /********  G L O B A L   E G R E S S   M E T A D A T A  *********/

struct my_egress_metadata_t {
    parser_metadata_t parser_md;
    /* Add more fields if necessary */
}

    /***********************  P A R S E R  **************************/

parser EgressParser(packet_in pkt,
    /* User */
    out my_egress_headers_t hdr,
    out my_egress_metadata_t meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t eg_intr_md)
{
    PacketParser() packet_parser;

    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);

        /* Use common packet parser */
        packet_parser.apply(pkt, hdr, meta.parser_md);
        transition accept;
    }
}

    /***************** M A T C H - A C T I O N  *********************/

control Egress(
    /* User */
    inout my_egress_headers_t hdr,
    inout my_egress_metadata_t meta,
    /* Intrinsic */
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md)
{






    action drop() {
        set_drop(eg_dprsr_md.drop_ctl);
    }

    table ipv4_acl {
        key = {







            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            meta.parser_md.l4_lookup.word_1 : ternary;
            meta.parser_md.l4_lookup.word_2 : ternary;

            meta.parser_md.first_frag : ternary;
            eg_intr_md.egress_port : ternary;
        }
        actions = { NoAction; drop; }
        size = 2048;
    }

    apply {
        if (hdr.ipv4.isValid()) {
# 435 "../../p4c-3765/simple_l3_acl.p4"
            ipv4_acl.apply();
        }
    }
}

    /*********************  D E P A R S E R  ************************/

control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t hdr,
    in my_egress_metadata_t meta,
    /* Intrinsic */
    in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{
    PacketDeparser() packet_deparser;

    apply {
        packet_deparser.apply(pkt, hdr);
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
