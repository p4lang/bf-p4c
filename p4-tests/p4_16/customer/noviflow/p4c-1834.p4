#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

action nop() {}

@pa_atomic("egress", "hdr.mirror.entry_id")
@pa_atomic("ingress", "hdr.mirror.entry_id")
header mirror_meta_hdr_t{
    bit<8> type;
    bit<15> pad0;
    bit<17> entry_id;
    bit<16> step_id;
    bit<4> pad1;
    bit<4> chain_id;
    bit<8> do_ACTION_SET_OUTPUT_PORT;
}

header bridged_meta_hdr_t{
    @flexible bit<8> do_ACTION_SET_OUTPUT_PORT;
    @flexible bit<8> do_ACTION_SET_OUTPUT_INPORT;
    @flexible bit<8> do_ACTION_SET_OUTPUT_LAG;
    @flexible bit<8> do_ACTION_SET_OUTPUT_LOCAL;
    @flexible bit<8> next_table_id;
    @flexible bit<16> egress_port;
    @flexible bit<16> ingress_phy_port;
    @flexible bit<32> ingress_timestamp;
    @flexible bit<8> original_ttl;
    @flexible bit<16> ingress_port;
    @flexible bit<16> etherType;
    @flexible bit<8> pkt_in_reason;

    @flexible bit<16> meter_id;
    @flexible bit<8> meter_color;

    @flexible bit<32> meta;
    @flexible bit<8> pad;
    @flexible bit<16> l4_checksum;
}

struct ingress_metadata_t {
    bit<1> do_ACTION_RECIRCULATE;
    bit<8> ip_protocol ;
    bit<1> is_packet_out;
    bit<1> do_mcast_group;
    bit<1> do_apply_actions;
    bit<16> mcast_group;
    bit<4> hash_profile_id;
    bit<16> hash_instr_result_1;
    bit<16> hash_instr_result_2;
    bit<16> hash_instr_result_3;
    bit<16> hash_instr_result_4;
    bit<16> hash_instr_result;
    bit<16> l4_dstport;
    bit<16> l4_srcport;


    bit<16> meter_byte_id;
    bit<16> meter_pkt_id;


}

struct egress_metadata_t
{
    bit<7> pad0;
    bit<17> entry_id;

    bit<1> unknown_pkt_err;

    bit<8> do_ACTION_SET_OUTPUT_CONTROLLER;
    bit<1> do_ACTION_SET_OUTPUT_GROUP;
    bit<1> do_clone;
    bit<3> clone_dst;
    bit<8> group_type;
    MirrorId_t mirror_id;

    bit<1> tunnel_drop;

    bit<4> chain_id;

    bit<16> step_id;

    bit<16> packet_len;
    bit<16> packet_len_subtract;


    bit<1> do_set_l4_dstport;
    bit<16> l4_dstport;


    bit<1> do_set_l4_srcport;
    bit<16> l4_srcport;


    bit<1> do_ACTION_SET_NW_TTL;
    bit<8> nw_ttl ;


    bit<1> do_ACTION_DEC_MPLS_TTL;





    bit<1> do_ACTION_DEC_NW_TTL;
    bit<1> do_ACTION_SET_VLAN_VID;
    bit<12> vlan_vid;


    bit<1> do_ACTION_SET_ETH_SRC;
    bit<48> eth_src;


    bit<1> do_ACTION_SET_ETH_DST;
    bit<48> eth_dst;






    bit<1> do_ACTION_SET_IPV4_SRC;
    bit<32> ipv4_src;


    bit<1> do_ACTION_SET_IPV4_DST;
    bit<32> ipv4_dst;


    bit<1> do_ACTION_SET_IPV6_SRC;
    bit<128> ipv6_src;


    bit<1> do_ACTION_SET_IPV6_DST;
    bit<128> ipv6_dst;

    bit<1> do_ACTION_SET_MPLS_LABEL;
    bit<20> mpls_label;


    bit<1> do_ACTION_SET_MPLS_TTL;
    bit<8> mpls_ttl;
    bit<1> do_pop_vlan;


    bit<1> do_push_vlan_8100;
    bit<1> do_push_vlan_88a8;


    bit<1> do_push_mpls_8847;
    bit<1> do_push_mpls_8848;
    bit<8> mpls_ttl_0 ;
    bit<1> mpls_bos_0 ;


    bit<3> do_pop_mpls_type;
    bit<8> meter_dscp_type;
}



header egress_control_t {
    bit<96> __padding;
    bit<16> etherType;
}
header egress_control_id_t {
    bit<17> entry_id;
    bit<14> __padding;
    bit<1> bos;
}

header recirc_header_t {


    bit<32> meta;
    bit<16> egress_port;
    bit<16> ingress_phy_port;
    bit<16> ingress_port;
    bit<8> bridged_metadata_pkt_in_reason;
    bit<8> table_id;
    bit<16> etherType;
    bit<8> egress_metadata_group_type;
    bit<8> egress_metadata_do_ACTION_SET_OUTPUT_CONTROLLER;
    bit<8> bridged_metadata_do_ACTION_SET_OUTPUT_LOCAL;
    bit<8> bridged_metadata_do_ACTION_SET_OUTPUT_INPORT;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header pbb_t {
        bit<4> i_pcp_dei;
        bit<1> i_uca;
        bit<3> i_res;
        bit<24> i_sid;
}

header vlan_tag_t {
        bit<3> pcp;
        bit<1> cfi;
        bit<12> vid;
        bit<16> etherType;
}

header mpls_t {
        bit<20> label;
        bit<3> exp;
        bit<1> bos;
        bit<8> ttl;
}

header l2gre_t {
        bit<16> flagsAndVersion;
        bit<16> protoType;
        bit<32> key;
}


header arp_rarp_t {
        bit<16> hwType;
        bit<16> protoType;
        bit<8> hwAddrLen;
        bit<8> protoAddrLen;
        bit<16> opcode;
}

header arp_rarp_ipv4_t {
        bit<48> srcHwAddr;
        bit<32> srcProtoAddr;
        bit<48> dstHwAddr;
        bit<32> dstProtoAddr;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> len;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header ipv6_t {
    bit<4> version;
    bit<6> dscp;
    bit<2> ecn;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<3> res;
    bit<3> ecn;
    bit<6> ctrl;
    bit<16> window;
}

header tcp_cksum_t {
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdr_length;
}

header udp_cksum_t {
    bit<16> checksum;
}


header sctp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
}

header sctp_cksum_t {
    bit<32> checksum;
}

header icmpv4_t {
    bit<8> _type ;
    bit<8> code ;
}

header icmpv4_cksum_t {
    bit<16> checksum ;
}

header icmpv6_t {
    bit<8> _type ;
    bit<8> code ;
    bit<16> hdrChecksum ;
}



header icmpv6_nd_na_ns_t {
    bit<32> reserved ;
    bit<128> target_addr ;
}


header icmpv6_nd_option_t {
    bit<8> _type ;
    bit<8> _length ;
}






header icmpv6_nd_option_ll_address_t {
    bit<48> ll_address ;
}

header vxlan_t {
    bit<32> flags;
    bit<24> vni;
    bit<8> rsvd;
}

header l2mpls_t {
    bit<24> label_exp_bos;
    bit<8> ttl;
}

header control_word_t {
    bit<32> zero;
}

header packet_in_t {
        bit<8> reason;
        bit<8> pktin_type;
        bit<15> _pad_entry_id;
        bit<17> entry_id;
        bit<16> ingress_port;
        bit<16> hw_ingress_port;
        bit<32> meta;
}

header packet_out_t {
        bit<8> output_local;
        bit<8> do_recirculate;
        bit<16> egress_port;
        bit<16> ingress_port;
        bit<8> do_output;
        bit<8> do_mcast_group;
        bit<16> mcast_group;
        bit<8> do_output_lag;
        bit<8> do_pkt_in;
        bit<16> etherType;




}

struct packet_headers_t {
    egress_control_t eg_control;
    egress_control_id_t[8] eg_control_id;
    recirc_header_t recirc;
    packet_out_t packet_out;
    packet_in_t packet_in_header;


    ethernet_t tunnel_ethernet_push;
    ipv4_t tunnel_ipv4_push;
    pbb_t pbb_push;
    l2gre_t l2gre_gre_push;
    udp_t vxlan_udp_push;
    udp_cksum_t vxlan_udp_cksum_push;
    vxlan_t vxlan_push;
    l2mpls_t l2mpls_mpls_push;
    l2mpls_t l2mpls_mpls2_push;
    control_word_t l2mpls_control_word_push;

    ethernet_t ethernet;
    vlan_tag_t[3] vlan;
    arp_rarp_t arp_rarp;
    arp_rarp_ipv4_t arp_rarp_ipv4;
    mpls_t[3] mpls;
    pbb_t pbb_parsed;
    control_word_t l2mpls_control_word;
    ipv4_t ipv4;
    ipv6_t ipv6;
    l2gre_t l2gre_gre_pop;
    ethernet_t inner_ethernet;
    tcp_t tcp;
    tcp_cksum_t tcpv4_cksum;
    tcp_cksum_t tcpv6_cksum;
    udp_t udp;
    udp_cksum_t udpv4_cksum;
    udp_cksum_t udpv6_cksum;
    sctp_t sctp;
    sctp_cksum_t sctp_cksum;
    vxlan_t vxlan;
    icmpv4_t icmpv4;
    icmpv4_cksum_t icmpv4_cksum;
    icmpv6_t icmpv6;
    icmpv6_nd_na_ns_t icmpv6_nd_na_ns;
    icmpv6_nd_option_t icmpv6_nd_option;
    icmpv6_nd_option_ll_address_t icmpv6_nd_option_sll_address;
    icmpv6_nd_option_ll_address_t icmpv6_nd_option_tll_address;
};

typedef bit<8> inthdr_type_t;
const inthdr_type_t INTHDR_TYPE_BRIDGE = 0xfc;
const inthdr_type_t INTHDR_TYPE_CLONE_INGRESS = 0xfd;
const inthdr_type_t INTHDR_TYPE_CLONE_EGRESS = 0xfe;

header internal_t
{
    inthdr_type_t type;
}
struct headers_t {
    internal_t internal;
    mirror_meta_hdr_t mirror;
    bridged_meta_hdr_t bridged_meta;
    packet_headers_t pkt;
};





parser ingress_parser( packet_in packet,
                        out headers_t hdr,
                        out ingress_metadata_t ig_md,
                        out ingress_intrinsic_metadata_t ig_intr_md)
{



    Checksum() tcpv4_checksum;
    Checksum() tcpv6_checksum;
    Checksum() udpv4_checksum;
    Checksum() udpv6_checksum;

    state start {

        hdr.internal.setValid();
        hdr.bridged_meta.setValid();

        hdr.internal.type = INTHDR_TYPE_BRIDGE;


        packet.extract(ig_intr_md);


        packet.advance(64);
        transition parse_packet;
    }
    state parse_packet {
        ethernet_t eth = packet.lookahead<ethernet_t>();
        transition select (eth.etherType) {
            0x0102: parse_recirculate;
            0x0104: parse_egress_control;
            0x0103: parse_packet_out;
            default: parse_ethernet;
        }
    }


    state parse_recirculate {
        packet.extract(hdr.pkt.recirc);

        hdr.bridged_meta.ingress_port = hdr.pkt.recirc.ingress_port;
        transition parse_after_recirculate;
    }
    state parse_after_recirculate {
        ethernet_t eth = packet.lookahead<ethernet_t>();
        transition select (eth.etherType) {
            0x0104: parse_egress_control;
            default: parse_ethernet;
        }
    }


    state parse_egress_control {
        packet.extract(hdr.pkt.eg_control);
        transition parse_egress_control_id;
    }
    state parse_egress_control_id {
        packet.extract(hdr.pkt.eg_control_id.next);
        transition select(hdr.pkt.eg_control_id.last.bos) {
            1: parse_ethernet;
            default: parse_egress_control_id;
        }
    }


    state parse_packet_out {
        packet.extract (hdr.pkt.packet_out);
        transition parse_ethernet;
    }


    state parse_ethernet {






        packet.extract (hdr.pkt.ethernet);

        transition parse_ethernet_next;
    }
    state parse_ethernet_next {





        transition select (hdr.pkt.ethernet.etherType) {
            0x8100 : parse_vlan;
            0x88A8 : parse_vlan;






            0x8847 : parse_mpls;
            0x8848 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86DD : parse_ipv6;
            default: accept;
        }
    }

    state parse_vlan {
        packet.extract(hdr.pkt.vlan.next);
        transition select (hdr.pkt.vlan.last.etherType) {
            0x8100 : parse_vlan;
            0x88A8 : parse_vlan;






            0x8847 : parse_mpls;
            0x8848 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86DD : parse_ipv6;
            default: accept;
        }
    }
    state parse_mpls {
        packet.extract(hdr.pkt.mpls.next);
        transition select (hdr.pkt.mpls.last.bos) {
            0 : parse_mpls;
            1 : parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {





        transition select(packet.lookahead<bit<4>>()) {



            0x4 : parse_ipv4;
            0x6 : parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract (hdr.pkt.ipv4);

        ig_md.ip_protocol = hdr.pkt.ipv4.protocol;

        hdr.bridged_meta.original_ttl = hdr.pkt.ipv4.ttl;

        tcpv4_checksum.subtract({hdr.pkt.ipv4.srcAddr, hdr.pkt.ipv4.dstAddr, hdr.pkt.ipv4.protocol, hdr.pkt.ipv4.len});
        udpv4_checksum.subtract({hdr.pkt.ipv4.srcAddr, hdr.pkt.ipv4.dstAddr, hdr.pkt.ipv4.protocol, hdr.pkt.ipv4.len});







        transition parse_ipv4_next;
    }
    state parse_ipv4_next {





        transition select(hdr.pkt.ipv4.protocol) {



            0x6 : parse_tcp_v4;
            0x11 : parse_udp_v4;
            0x84 : parse_sctp;



            default: accept;
        }
    }
    state parse_udp_v4 {
        packet.extract (hdr.pkt.udp);
        packet.extract (hdr.pkt.udpv4_cksum);

        udpv4_checksum.subtract({
            hdr.pkt.udp.srcPort,
            hdr.pkt.udp.dstPort,
            hdr.pkt.udp.hdr_length});
        udpv4_checksum.subtract_all_and_deposit(hdr.bridged_meta.l4_checksum);

        ig_md.l4_srcport = hdr.pkt.udp.srcPort;
        ig_md.l4_dstport = hdr.pkt.udp.dstPort;






        transition select (hdr.pkt.udp.dstPort) {



            default: accept;
        }
    }
    state parse_tcp_v4 {
        packet.extract (hdr.pkt.tcp);
        packet.extract (hdr.pkt.tcpv4_cksum);

        tcpv4_checksum.subtract({
                hdr.pkt.tcp.srcPort,
                hdr.pkt.tcp.dstPort,
                hdr.pkt.tcp.seqNo,
                hdr.pkt.tcp.ackNo,
                hdr.pkt.tcp.dataOffset,
                hdr.pkt.tcp.res,
                hdr.pkt.tcp.ecn,
                hdr.pkt.tcp.ctrl,
                hdr.pkt.tcp.window,
                hdr.pkt.tcpv4_cksum.urgentPtr});
        tcpv4_checksum.subtract_all_and_deposit(hdr.bridged_meta.l4_checksum);

        ig_md.l4_srcport = hdr.pkt.tcp.srcPort;
        ig_md.l4_dstport = hdr.pkt.tcp.dstPort;

        transition accept;
    }
    state parse_sctp {
        packet.extract (hdr.pkt.sctp);
        packet.extract (hdr.pkt.sctp_cksum);
        transition accept;
    }


    state parse_ipv6 {
        packet.extract (hdr.pkt.ipv6);

        ig_md.ip_protocol = hdr.pkt.ipv6.nextHdr;

        hdr.bridged_meta.original_ttl = hdr.pkt.ipv6.hopLimit;

        tcpv6_checksum.subtract({
            hdr.pkt.ipv6.srcAddr,
            hdr.pkt.ipv6.dstAddr,
            hdr.pkt.ipv6.payloadLen,
            hdr.pkt.ipv6.nextHdr});

        udpv6_checksum.subtract({
            hdr.pkt.ipv6.srcAddr,
            hdr.pkt.ipv6.dstAddr,
            hdr.pkt.ipv6.payloadLen,
            hdr.pkt.ipv6.nextHdr});

        transition parse_ipv6_next;
    }
    state parse_ipv6_next {





        transition select(hdr.pkt.ipv6.nextHdr) {



            0x6 : parse_tcp_v6;
            0x11 : parse_udp_v6;
            0x84 : parse_sctp;
            default : accept;
        }
    }

    state parse_tcp_v6 {
        packet.extract (hdr.pkt.tcp);
        packet.extract (hdr.pkt.tcpv6_cksum);

        tcpv6_checksum.subtract({
                hdr.pkt.tcp.srcPort,
                hdr.pkt.tcp.dstPort,
                hdr.pkt.tcp.seqNo,
                hdr.pkt.tcp.ackNo,
                hdr.pkt.tcp.dataOffset,
                hdr.pkt.tcp.res,
                hdr.pkt.tcp.ecn,
                hdr.pkt.tcp.ctrl,
                hdr.pkt.tcp.window,
                hdr.pkt.tcpv6_cksum.urgentPtr});
        tcpv6_checksum.subtract_all_and_deposit(hdr.bridged_meta.l4_checksum);

        ig_md.l4_srcport = hdr.pkt.tcp.srcPort;
        ig_md.l4_dstport = hdr.pkt.tcp.dstPort;

        transition accept;
    }

    state parse_udp_v6 {
        packet.extract (hdr.pkt.udp);
        packet.extract (hdr.pkt.udpv6_cksum);

        udpv6_checksum.subtract({
                hdr.pkt.udp.srcPort,
                hdr.pkt.udp.dstPort,
                hdr.pkt.udp.hdr_length});
        udpv6_checksum.subtract_all_and_deposit(hdr.bridged_meta.l4_checksum);

        ig_md.l4_srcport = hdr.pkt.udp.srcPort;
        ig_md.l4_dstport = hdr.pkt.udp.dstPort;
        transition accept;
    }
}





parser egress_parser( packet_in packet,
                        out headers_t hdr,
                        out egress_metadata_t eg_md,
                        out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {


        packet.extract(eg_intr_md);
        internal_t internal = packet.lookahead<internal_t>();
        transition select (internal.type) {
            INTHDR_TYPE_BRIDGE: parse_bridged_metadata;
            INTHDR_TYPE_CLONE_EGRESS: parse_mirror;
            default: unknown_packet_err;
        }
    }

    state unknown_packet_err{
        eg_md.unknown_pkt_err = 1;
        transition accept;
    }

    state parse_bridged_metadata{
        packet.extract(hdr.internal);
        packet.extract(hdr.bridged_meta);
        transition parse_packet;
    }
    state parse_mirror {
        packet.extract(hdr.mirror);
        transition parse_packet;
    }
    state parse_packet {
        ethernet_t eth = packet.lookahead<ethernet_t>();
        transition select (eth.etherType) {
            0x0102: parse_recirculate;
            0x0104: parse_egress_control;
            0x0103: parse_packet_out;
            default: parse_ethernet;
        }
    }


    state parse_recirculate {
        packet.extract(hdr.pkt.recirc);

        hdr.bridged_meta.ingress_port = hdr.pkt.recirc.ingress_port;
        transition parse_after_recirculate;
    }
    state parse_after_recirculate {
        ethernet_t eth = packet.lookahead<ethernet_t>();
        transition select (eth.etherType) {
            0x0104: parse_egress_control;
            default: parse_ethernet;
        }
    }


    state parse_egress_control {
        packet.extract(hdr.pkt.eg_control);
        transition parse_egress_control_id;
    }
    state parse_egress_control_id {
        packet.extract(hdr.pkt.eg_control_id.next);
        transition select(hdr.pkt.eg_control_id.last.bos) {
            1: dataplane_packet;
            default: parse_egress_control_id;
        }
    }

    state dataplane_packet {
        transition select(packet.lookahead<bit<1>>()) {
        0 &&& 0 : parse_ethernet;
        default: ghost_header;
        }

    }

    state ghost_header {

        transition parse_ethernet;
    }


    state parse_packet_out {
        packet.extract (hdr.pkt.packet_out);
        transition parse_ethernet;
    }



    state parse_ethernet {
        packet.extract (hdr.pkt.ethernet);






        transition parse_ethernet_next;
    }
    state parse_ethernet_next {
        transition select (hdr.pkt.ethernet.etherType) {
            0x8100 : parse_vlan;
            0x88A8 : parse_vlan;






            0x8847 : parse_mpls;
            0x8848 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86DD : parse_ipv6;
            default: accept;
        }
    }

    state parse_vlan {
        packet.extract(hdr.pkt.vlan.next);
        transition select (hdr.pkt.vlan.last.etherType) {
            0x8100 : parse_vlan;
            0x88A8 : parse_vlan;






            0x8847 : parse_mpls;
            0x8848 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86DD : parse_ipv6;
            default: accept;
        }
    }
    state parse_mpls {
        packet.extract(hdr.pkt.mpls.next);
        transition select (hdr.pkt.mpls.last.bos) {
            0 : parse_mpls;
            1 : parse_mpls_bos;
            default: accept;
        }
    }
    state parse_mpls_bos {
        transition select(packet.lookahead<bit<4>>()) {



            0x4 : parse_ipv4;
            0x6 : parse_ipv6;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract (hdr.pkt.ipv4);
        hdr.bridged_meta.original_ttl = hdr.pkt.ipv4.ttl;






        transition parse_ipv4_next;
    }

    state parse_ipv4_next {
        transition select(hdr.pkt.ipv4.protocol) {



            0x6 : parse_tcp_v4;
            0x11 : parse_udp_v4;
            0x84 : parse_sctp;



            default: accept;
        }
    }
    state parse_udp_v4 {
        packet.extract (hdr.pkt.udp);
        packet.extract (hdr.pkt.udpv4_cksum);
        transition select (hdr.pkt.udp.dstPort) {



            default: accept;
        }
    }
    state parse_tcp_v4 {
        packet.extract (hdr.pkt.tcp);
        packet.extract (hdr.pkt.tcpv4_cksum);
        transition accept;
    }
    state parse_sctp {
        packet.extract (hdr.pkt.sctp);
        packet.extract (hdr.pkt.sctp_cksum);
        transition accept;
    }
    state parse_ipv6 {
        packet.extract (hdr.pkt.ipv6);
        hdr.bridged_meta.original_ttl = hdr.pkt.ipv6.hopLimit;
        transition parse_ipv6_next;
    }
    state parse_ipv6_next {
        transition select(hdr.pkt.ipv6.nextHdr) {



            0x6 : parse_tcp_v6;
            0x11 : parse_udp_v6;
            0x84 : parse_sctp;
            default : accept;
        }
    }

    state parse_tcp_v6 {
        packet.extract (hdr.pkt.tcp);
        packet.extract (hdr.pkt.tcpv6_cksum);
        transition accept;
    }

    state parse_udp_v6 {
        packet.extract (hdr.pkt.udp);
        packet.extract (hdr.pkt.udpv6_cksum);
        transition accept;
    }
}






control control_set_innermost_ethertype(inout headers_t hdr,
                                        inout ingress_metadata_t ig_md,
                                        in ingress_intrinsic_metadata_t ig_intr_md,
                                        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                                        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
     action set_innermost_ethertype_vlan2() {
        hdr.bridged_meta.etherType = hdr.pkt.vlan[2].etherType;
     }

     action set_innermost_ethertype_vlan1() {
        hdr.bridged_meta.etherType = hdr.pkt.vlan[1].etherType;
     }

    action set_innermost_ethertype_vlan0() {
        hdr.bridged_meta.etherType = hdr.pkt.vlan[0].etherType;
    }

    action set_innermost_ethertype_packet_out() {
        hdr.bridged_meta.etherType = hdr.pkt.packet_out.etherType;
    }

    action set_innermost_ethertype_ethernet() {
        hdr.bridged_meta.etherType = hdr.pkt.ethernet.etherType;
    }


    table table_set_innermost_ethertype {
        key = {
            hdr.pkt.ethernet.isValid() : ternary;
            hdr.pkt.packet_out.isValid() : ternary;
            hdr.pkt.vlan[0].isValid() : ternary;
            hdr.pkt.vlan[1].isValid() : ternary;
            hdr.pkt.vlan[2].isValid() : ternary;
        }
        actions = {
            set_innermost_ethertype_vlan2;
            set_innermost_ethertype_vlan1;
            set_innermost_ethertype_vlan0;
            set_innermost_ethertype_packet_out;
            set_innermost_ethertype_ethernet;
            nop;
        }
        const default_action = nop;
        size = 6;
    }
    apply {
        table_set_innermost_ethertype.apply();
    }
}

control control_preparse( inout headers_t hdr,
                            inout ingress_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action preparse_recirculate() {
        hdr.bridged_meta.ingress_port = hdr.pkt.recirc.ingress_port;
        hdr.bridged_meta.ingress_phy_port = hdr.pkt.recirc.ingress_phy_port;
        hdr.bridged_meta.next_table_id = hdr.pkt.recirc.table_id;



        hdr.pkt.recirc.setInvalid();
    }

    action preparse_packet_out() {
         ig_md.is_packet_out = 1;
         hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT = hdr.pkt.packet_out.do_output;
         hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL = hdr.pkt.packet_out.output_local;
         hdr.bridged_meta.egress_port = hdr.pkt.packet_out.egress_port ;
         ig_md.do_ACTION_RECIRCULATE = (bit<1>) hdr.pkt.packet_out.do_recirculate[0:0];
         hdr.bridged_meta.ingress_port = hdr.pkt.packet_out.ingress_port;
         hdr.bridged_meta.ingress_phy_port = hdr.pkt.packet_out.ingress_port;
         hdr.bridged_meta.pkt_in_reason = 3;

         ig_md.do_mcast_group = (bit<1>) hdr.pkt.packet_out.do_mcast_group[0:0];
         ig_md.mcast_group = hdr.pkt.packet_out.mcast_group;
         hdr.bridged_meta.do_ACTION_SET_OUTPUT_LAG = hdr.bridged_meta.do_ACTION_SET_OUTPUT_LAG | hdr.pkt.packet_out.do_output_lag;



     }

    action preparse_dataplane_packet() {
        hdr.bridged_meta.ingress_port = (bit<16>)ig_intr_md.ingress_port;



        hdr.bridged_meta.ingress_phy_port = (bit<16>)ig_intr_md.ingress_port;
    }

    action preparse_dataplane_packet_lport_match( bit<16> logical_port ){
        hdr.bridged_meta.ingress_port = logical_port;



        hdr.bridged_meta.ingress_phy_port = (bit<16>) ig_intr_md.ingress_port;
    }

    table table_preparse {
        key = {
            hdr.pkt.ethernet.isValid() : ternary;
            hdr.pkt.packet_out.isValid() : ternary;
            hdr.pkt.recirc.isValid() : ternary;
            ig_intr_md.ingress_port : ternary;
        }
        actions = {
            preparse_packet_out;
            preparse_recirculate;
            preparse_dataplane_packet;
            preparse_dataplane_packet_lport_match;
            nop;
        }
        const default_action = nop;
        size = 262;
    }

    control_set_innermost_ethertype() ct_set_innermost_ethertype;
    apply {
        ct_set_innermost_ethertype.apply(hdr,ig_md,ig_intr_md,ig_prsr_md,ig_tm_md);
        table_preparse.apply();
        hdr.bridged_meta.pad = 0;
    }

}
control control_dataplane_packet( inout headers_t hdr,
                                    inout ingress_metadata_t ig_md,
                                    in ingress_intrinsic_metadata_t ig_intr_md,
                                    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                                    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action flowentry_common(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta)
    {
        ig_md.do_ACTION_RECIRCULATE = do_ACTION_RECIRCULATE | ig_md.do_ACTION_RECIRCULATE;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT = do_ACTION_SET_OUTPUT_PORT | hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT;
        hdr.bridged_meta.egress_port = egress_port;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT = do_ACTION_SET_OUTPUT_INPORT | hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_LAG = do_ACTION_SET_OUTPUT_LAG | hdr.bridged_meta.do_ACTION_SET_OUTPUT_LAG;
        ig_md.do_mcast_group = ig_md.do_mcast_group | (bit<1>)do_mcast_group;
        ig_md.mcast_group = do_mcast_group ? mcast_group : ig_md.mcast_group;

        ig_md.do_apply_actions = do_apply_actions;
        hdr.bridged_meta.next_table_id = next_table_id;
        ig_tm_md.qid = queue_id;

        hdr.bridged_meta.meter_id = meter_id;



    }





    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) table0_stats;
    Register<bit<32>, bit<1>>(2, 0) table0_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table0_hit_miss) table0_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr0(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[0].setValid();
        hdr.pkt.eg_control_id[0].entry_id = entry_id;
        table0_stats.count();
    }
    action flowentry_simple0(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table0_stats.count();
    }
    table table0{
        key = {




hdr.pkt.ethernet.dstAddr:ternary;
hdr.pkt.ethernet.srcAddr:ternary;
hdr.bridged_meta.etherType:ternary;
hdr.pkt.vlan[0].isValid():ternary;
hdr.pkt.vlan[0].vid:ternary;
hdr.pkt.vlan[0].pcp:ternary;
ig_md.ip_protocol:ternary;
hdr.pkt.ipv4.srcAddr:ternary;
hdr.pkt.ipv4.dstAddr:ternary;


hdr.pkt.tcp.srcPort:ternary;
hdr.pkt.tcp.dstPort:ternary;
hdr.pkt.udp.srcPort:ternary;
hdr.pkt.udp.dstPort:ternary;
hdr.pkt.sctp.srcPort:ternary;
hdr.pkt.sctp.dstPort:ternary;

hdr.bridged_meta.ingress_port:ternary;



































        }

        actions = {
            flowentry_instr0;
            flowentry_simple0;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 1024;
        counters = table0_stats;
    }

    action action_table0_hit()
    {
        table0_hit_miss_action.execute(0);
    }
    table table0_hit {
        actions = {
            action_table0_hit;
        }
        const default_action = action_table0_hit;
        size = 1;
    }

    action action_table0_miss()
    {
        table0_hit_miss_action.execute(1);
    }
    table table0_miss {
        actions = {
            action_table0_miss;
        }
        const default_action = action_table0_miss;
        size = 1;
    }





    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table1_stats;
    Register<bit<32>, bit<1>>(2, 0) table1_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table1_hit_miss) table1_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr1(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[1].setValid();
        hdr.pkt.eg_control_id[1].entry_id = entry_id;
        table1_stats.count();
    }
    action flowentry_simple1(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table1_stats.count();
    }
    table table1{
        key = {
hdr.pkt.ethernet.dstAddr:ternary;
hdr.pkt.ipv6.srcAddr:ternary;
hdr.pkt.ipv6.dstAddr:ternary;
hdr.bridged_meta.ingress_port:ternary;
hdr.bridged_meta.ingress_phy_port:ternary;

        }

        actions = {
            flowentry_instr1;
            flowentry_simple1;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 1024;
        counters = table1_stats;
    }

    action action_table1_hit()
    {
        table1_hit_miss_action.execute(0);
    }
    table table1_hit {
        actions = {
            action_table1_hit;
        }
        const default_action = action_table1_hit;
        size = 1;
    }

    action action_table1_miss()
    {
        table1_hit_miss_action.execute(1);
    }
    table table1_miss {
        actions = {
            action_table1_miss;
        }
        const default_action = action_table1_miss;
        size = 1;
    }






    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table2_stats;
    Register<bit<32>, bit<1>>(2, 0) table2_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table2_hit_miss) table2_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr2(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[2].setValid();
        hdr.pkt.eg_control_id[2].entry_id = entry_id;
        table2_stats.count();
    }
    action flowentry_simple2(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table2_stats.count();
    }
    table table2{
        key = {



hdr.pkt.ethernet.dstAddr:ternary;
hdr.pkt.ethernet.srcAddr:ternary;
hdr.bridged_meta.etherType:ternary;
hdr.pkt.vlan[0].isValid():ternary;
hdr.pkt.vlan[0].vid:ternary;

ig_md.ip_protocol:ternary;
hdr.pkt.ipv4.srcAddr:ternary;
hdr.pkt.ipv4.dstAddr:ternary;


hdr.pkt.tcp.srcPort:ternary;
hdr.pkt.tcp.dstPort:ternary;
hdr.pkt.sctp.srcPort:ternary;
hdr.pkt.sctp.dstPort:ternary;
hdr.bridged_meta.ingress_port:ternary;
        }

        actions = {
            flowentry_instr2;
            flowentry_simple2;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 1024;
        counters = table2_stats;
    }

    action action_table2_hit()
    {
        table2_hit_miss_action.execute(0);
    }
    table table2_hit {
        actions = {
            action_table2_hit;
        }
        const default_action = action_table2_hit;
        size = 1;
    }

    action action_table2_miss()
    {
        table2_hit_miss_action.execute(1);
    }
    table table2_miss {
        actions = {
            action_table2_miss;
        }
        const default_action = action_table2_miss;
        size = 1;
    }






    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table3_stats;
    Register<bit<32>, bit<1>>(2, 0) table3_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table3_hit_miss) table3_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr3(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[3].setValid();
        hdr.pkt.eg_control_id[3].entry_id = entry_id;
        table3_stats.count();
    }
    action flowentry_simple3(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table3_stats.count();
    }
    table table3{
        key = {



hdr.pkt.ethernet.dstAddr:ternary;
hdr.pkt.ethernet.srcAddr:ternary;
hdr.bridged_meta.etherType:ternary;
hdr.pkt.vlan[0].isValid():ternary;
hdr.pkt.vlan[0].vid:ternary;

ig_md.ip_protocol:ternary;
hdr.pkt.ipv4.srcAddr:ternary;
hdr.pkt.ipv4.dstAddr:ternary;




hdr.pkt.udp.srcPort:ternary;
hdr.pkt.udp.dstPort:ternary;



hdr.bridged_meta.ingress_port:ternary;



































        }

        actions = {
            flowentry_instr3;
            flowentry_simple3;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 1024;
        counters = table3_stats;
    }

    action action_table3_hit()
    {
        table3_hit_miss_action.execute(0);
    }
    table table3_hit {
        actions = {
            action_table3_hit;
        }
        const default_action = action_table3_hit;
        size = 1;
    }

    action action_table3_miss()
    {
        table3_hit_miss_action.execute(1);
    }
    table table3_miss {
        actions = {
            action_table3_miss;
        }
        const default_action = action_table3_miss;
        size = 1;
    }






    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table4_stats;
    Register<bit<32>, bit<1>>(2, 0) table4_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table4_hit_miss) table4_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr4(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[4].setValid();
        hdr.pkt.eg_control_id[4].entry_id = entry_id;
        table4_stats.count();
    }
    action flowentry_simple4(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table4_stats.count();
    }
    table table4{
        key = {





















hdr.bridged_meta.ingress_port:exact;



































        }

        actions = {
            flowentry_instr4;
            flowentry_simple4;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 512;
        counters = table4_stats;
    }

    action action_table4_hit()
    {
        table4_hit_miss_action.execute(0);
    }
    table table4_hit {
        actions = {
            action_table4_hit;
        }
        const default_action = action_table4_hit;
        size = 1;
    }

    action action_table4_miss()
    {
        table4_hit_miss_action.execute(1);
    }
    table table4_miss {
        actions = {
            action_table4_miss;
        }
        const default_action = action_table4_miss;
        size = 1;
    }






    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table5_stats;
    Register<bit<32>, bit<1>>(2, 0) table5_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table5_hit_miss) table5_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr5(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[5].setValid();
        hdr.pkt.eg_control_id[5].entry_id = entry_id;
        table5_stats.count();
    }
    action flowentry_simple5(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table5_stats.count();
    }
    table table5{
        key = {



hdr.pkt.ethernet.dstAddr:exact;





















































        }

        actions = {
            flowentry_instr5;
            flowentry_simple5;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 4000;
        counters = table5_stats;
    }

    action action_table5_hit()
    {
        table5_hit_miss_action.execute(0);
    }
    table table5_hit {
        actions = {
            action_table5_hit;
        }
        const default_action = action_table5_hit;
        size = 1;
    }

    action action_table5_miss()
    {
        table5_hit_miss_action.execute(1);
    }
    table table5_miss {
        actions = {
            action_table5_miss;
        }
        const default_action = action_table5_miss;
        size = 1;
    }






    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table6_stats;
    Register<bit<32>, bit<1>>(2, 0) table6_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table6_hit_miss) table6_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr6(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[6].setValid();
        hdr.pkt.eg_control_id[6].entry_id = entry_id;
        table6_stats.count();
    }
    action flowentry_simple6(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table6_stats.count();
    }
    table table6{
        key = {




hdr.pkt.ethernet.srcAddr:exact;




















































        }

        actions = {
            flowentry_instr6;
            flowentry_simple6;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 4000;
        counters = table6_stats;
    }

    action action_table6_hit()
    {
        table6_hit_miss_action.execute(0);
    }
    table table6_hit {
        actions = {
            action_table6_hit;
        }
        const default_action = action_table6_hit;
        size = 1;
    }

    action action_table6_miss()
    {
        table6_hit_miss_action.execute(1);
    }
    table table6_miss {
        actions = {
            action_table6_miss;
        }
        const default_action = action_table6_miss;
        size = 1;
    }







    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) table7_stats;
    Register<bit<32>, bit<1>>(2, 0) table7_hit_miss;
    RegisterAction<bit<32>, bit<1>, bit<1>>(table7_hit_miss) table7_hit_miss_action = {
        void apply(inout bit<32> value) {
            value = value + 1;
        }
    };
    action flowentry_instr7(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> entry_id) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        hdr.pkt.eg_control_id[7].setValid();
        hdr.pkt.eg_control_id[7].entry_id = entry_id;
        table7_stats.count();
    }
    action flowentry_simple7(bit<1> do_apply_actions, bit<1> do_ACTION_RECIRCULATE, bit<8> do_ACTION_SET_OUTPUT_PORT, bit<8> do_ACTION_SET_OUTPUT_INPORT, bit<8> do_ACTION_SET_OUTPUT_LAG, bit<16> egress_port, bool do_mcast_group, bit<16> mcast_group, QueueId_t queue_id, bit<16> meter_id, bit<8> next_table_id, bool do_write_metadata, bit<32> meta, bit<17> index) {
        flowentry_common(do_apply_actions, do_ACTION_RECIRCULATE, do_ACTION_SET_OUTPUT_PORT, do_ACTION_SET_OUTPUT_INPORT, do_ACTION_SET_OUTPUT_LAG, egress_port, do_mcast_group, mcast_group, queue_id, meter_id, next_table_id, do_write_metadata, meta);
        table7_stats.count();
    }
    table table7{
        key = {





hdr.bridged_meta.etherType:exact;



















































        }

        actions = {
            flowentry_instr7;
            flowentry_simple7;
            @defaultonly nop;
        }

        const default_action = nop;
        size = 4000;
        counters = table7_stats;
    }

    action action_table7_hit()
    {
        table7_hit_miss_action.execute(0);
    }
    table table7_hit {
        actions = {
            action_table7_hit;
        }
        const default_action = action_table7_hit;
        size = 1;
    }

    action action_table7_miss()
    {
        table7_hit_miss_action.execute(1);
    }
    table table7_miss {
        actions = {
            action_table7_miss;
        }
        const default_action = action_table7_miss;
        size = 1;
    }
    apply {

        if (hdr.bridged_meta.next_table_id == 0){
            if(table0.apply().hit) {
                table0_hit.apply();
            }
            else {
                table0_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 1 &&
            ig_md.do_apply_actions == 0){
            if(table1.apply().hit) {
                table1_hit.apply();
            }
            else {
                table1_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 2 &&
            ig_md.do_apply_actions == 0){
            if(table2.apply().hit) {
                table2_hit.apply();
            }
            else {
                table2_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 3 &&
            ig_md.do_apply_actions == 0){
            if(table3.apply().hit) {
                table3_hit.apply();
            }
            else {
                table3_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 4 &&
            ig_md.do_apply_actions == 0){
            if(table4.apply().hit) {
                table4_hit.apply();
            }
            else {
                table4_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 5 &&
            ig_md.do_apply_actions == 0){
            if(table5.apply().hit) {
                table5_hit.apply();
            }
            else {
                table5_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 6 &&
            ig_md.do_apply_actions == 0){
            if(table6.apply().hit) {
                table6_hit.apply();
            }
            else {
                table6_miss.apply();
            }
        }


        if (hdr.bridged_meta.next_table_id == 7 &&
            ig_md.do_apply_actions == 0){
            if(table7.apply().hit) {
                table7_hit.apply();
            }
            else {
                table7_miss.apply();
            }
        }
    }
}


control control_set_egress_port(inout headers_t hdr,
                                inout ingress_metadata_t ig_md,
                                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_egress_port( ){
        ig_tm_md.ucast_egress_port = (bit<9>)hdr.bridged_meta.egress_port;
    }
    action set_egress_inport( ){
        ig_tm_md.ucast_egress_port = (bit<9>)hdr.bridged_meta.ingress_phy_port;
    }
    action set_egress_invalidate( ){
        invalidate( ig_tm_md.ucast_egress_port );
    }

    table set_output{

        key = {
            hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT: exact;
            hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT: exact;
        }

        actions = {
            set_egress_port;
            set_egress_inport;
            set_egress_invalidate;
        }

        const default_action = set_egress_invalidate;
    }

    apply{
        set_output.apply();
    }
}





control control_set_egress_recirc( inout headers_t hdr,
                                    inout ingress_metadata_t ig_md,
                                    in ingress_intrinsic_metadata_t ig_intr_md,
                                    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) lag_hash;

    action set_egress_recirc()
    {
        ig_tm_md.mcast_grp_b = 2;
    }

    action set_recirculate_hash()
    {
        ig_tm_md.level2_mcast_hash = (bit<13>)hash.get({ig_intr_md.ingress_mac_tstamp,
                                                        ig_intr_md.ingress_port});
    }
    action set_lag_hash()
    {

        ig_tm_md.level2_mcast_hash = (bit<13>)lag_hash.get({



hdr.pkt.ethernet.dstAddr,
hdr.pkt.ethernet.srcAddr,
hdr.bridged_meta.etherType,












































            hdr.bridged_meta.pad
        });
    }



    table tb_set_egress_recirc {
        key = {
            ig_md.do_ACTION_RECIRCULATE: exact;
        }
        actions = {
            set_egress_recirc;
        }
        size = 2;
    }

    table tb_set_lag_hash{
        key = {
            ig_md.do_ACTION_RECIRCULATE: exact;
            hdr.bridged_meta.do_ACTION_SET_OUTPUT_LAG: exact;
        }
        actions = {
            set_recirculate_hash;
            set_lag_hash;
        }
        size = 4;
    }

    apply {
        tb_set_egress_recirc.apply();
        tb_set_lag_hash.apply();
    }
}





control control_mcast_group(inout headers_t hdr, inout ingress_metadata_t ig_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action a_set_mcast_group()
    {
        ig_tm_md.mcast_grp_a = ig_md.mcast_group;
    }

    table t_set_mcast_group {
        actions = {
            a_set_mcast_group;
        }
        const default_action = a_set_mcast_group;
        size = 1;
    }
    apply {
        if (ig_md.do_mcast_group == 1) {
            t_set_mcast_group.apply();
        }
    }
}


control control_set_eg_control(inout headers_t hdr)
{




    action set_egress_control_id_0() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[0].bos = 1;
    }

    action set_egress_control_id_1() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[1].bos = 1;
    }


    action set_egress_control_id_2() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[2].bos = 1;
    }


    action set_egress_control_id_3() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[3].bos = 1;
    }


    action set_egress_control_id_4() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[4].bos = 1;
    }


    action set_egress_control_id_5() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[5].bos = 1;
    }


    action set_egress_control_id_6() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[6].bos = 1;
    }


    action set_egress_control_id_7() {
        hdr.pkt.eg_control.setValid();
        hdr.pkt.eg_control.etherType = 0x0104;
        hdr.pkt.eg_control_id[7].bos = 1;
    }
    table tb_set_egress_control {
        key = {
            hdr.pkt.eg_control_id[0].isValid() : ternary;

            hdr.pkt.eg_control_id[1].isValid() : ternary;


            hdr.pkt.eg_control_id[2].isValid() : ternary;


            hdr.pkt.eg_control_id[3].isValid() : ternary;


            hdr.pkt.eg_control_id[4].isValid() : ternary;


            hdr.pkt.eg_control_id[5].isValid() : ternary;


            hdr.pkt.eg_control_id[6].isValid() : ternary;


            hdr.pkt.eg_control_id[7].isValid() : ternary;




        }
        actions = {
            set_egress_control_id_0;

            set_egress_control_id_1;


            set_egress_control_id_2;


            set_egress_control_id_3;


            set_egress_control_id_4;


            set_egress_control_id_5;


            set_egress_control_id_6;


            set_egress_control_id_7;




            nop;
        }
        const default_action = nop;
        size = 10;
    }
    apply {
        tb_set_egress_control.apply();
    }
}
control control_meter_pkt_apply(inout headers_t hdr, inout ingress_metadata_t ig_md)
{

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) meter_pkt_apply_counter;
    Meter<bit<24>>(5000, MeterType_t.PACKETS) pkt_meter;

    action meter_pkt_apply(bit<24> idx)
    {
        meter_pkt_apply_counter.count();
        hdr.bridged_meta.meter_color = pkt_meter.execute(idx);
    }

    table tb_meter_pkt_apply
    {
        key = {
            hdr.bridged_meta.meter_id: exact;
        }
        actions = {
            meter_pkt_apply;
        }
        size = 5000;
        counters = meter_pkt_apply_counter;
    }

    apply {
        tb_meter_pkt_apply.apply();
    }
}




control ingress_control( inout headers_t hdr,
                            inout ingress_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    control_preparse() ct_preparse;
    control_dataplane_packet() ct_dataplane_packet;
    control_set_egress_port() ct_set_egress_port;
    control_mcast_group() ct_mcast_group;
    control_set_egress_recirc() ct_set_egress_recirc;
    control_set_eg_control() ct_set_eg_control;




    control_meter_pkt_apply() ct_meter_pkt_apply;


    apply{

        ct_preparse.apply(hdr, ig_md, ig_intr_md, ig_prsr_md, ig_tm_md);

        ct_dataplane_packet.apply(hdr, ig_md, ig_intr_md, ig_prsr_md, ig_tm_md);





        ct_set_egress_port.apply(hdr, ig_md, ig_tm_md);

        ct_mcast_group.apply(hdr, ig_md, ig_tm_md);

        ct_set_egress_recirc.apply(hdr, ig_md, ig_intr_md, ig_tm_md);

        ct_set_eg_control.apply(hdr);


        ct_meter_pkt_apply.apply(hdr, ig_md);

    }
}




control ingress_deparser( packet_out packet,
                            inout headers_t hdr,
                            in ingress_metadata_t ig_md,
                            in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{

    apply {

        packet.emit(hdr);
    }
}



control control_remove_internal_headers(inout headers_t hdr,
                                        inout egress_metadata_t eg_md,
                                        in egress_intrinsic_metadata_t eg_intr_md,
                                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    action remove_recirculate_e2e() {



        hdr.bridged_meta.ingress_port = hdr.pkt.recirc.ingress_port;
        hdr.bridged_meta.ingress_phy_port = hdr.pkt.recirc.ingress_phy_port;
        hdr.bridged_meta.egress_port = hdr.pkt.recirc.egress_port;
        eg_md.group_type = hdr.pkt.recirc.egress_metadata_group_type;
        eg_md.do_ACTION_SET_OUTPUT_CONTROLLER = hdr.pkt.recirc.egress_metadata_do_ACTION_SET_OUTPUT_CONTROLLER;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT = hdr.pkt.recirc.bridged_metadata_do_ACTION_SET_OUTPUT_INPORT;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL = hdr.pkt.recirc.bridged_metadata_do_ACTION_SET_OUTPUT_LOCAL;
        hdr.bridged_meta.pkt_in_reason = hdr.pkt.recirc.bridged_metadata_pkt_in_reason;
        hdr.bridged_meta.next_table_id = hdr.pkt.recirc.table_id;
        hdr.pkt.recirc.setInvalid();
    }
    action remove_recirculate_ingress() {


    }

    action remove_packet_out(){
        eg_md.do_ACTION_SET_OUTPUT_CONTROLLER = hdr.pkt.packet_out.do_pkt_in;
        hdr.pkt.packet_out.setInvalid();
    }

    action remove_mirror(){
        eg_md.entry_id = hdr.mirror.entry_id;
        eg_md.step_id = hdr.mirror.step_id;
        eg_md.chain_id = hdr.mirror.chain_id;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT = hdr.mirror.do_ACTION_SET_OUTPUT_PORT;
        hdr.mirror.setInvalid();
    }


    table tb_remove_mirror{
        key = {
            hdr.mirror.isValid(): exact;
        }
        actions = {
            remove_mirror;
            nop;
        }
        const default_action = nop;
        size = 1;
    }


    table remove_internal_headers {
        key = {
            hdr.pkt.recirc.isValid(): exact;
            hdr.pkt.packet_out.isValid(): exact;
            hdr.internal.type: exact;
        }
        actions = {
            remove_recirculate_e2e;
            remove_recirculate_ingress;
            remove_packet_out;
            nop;
        }
        const default_action = nop;
        size = 4;
    }
    apply {
        remove_internal_headers.apply();
        tb_remove_mirror.apply();
    }
}

control control_rid_control(inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    action rid_control_do_group(){
        eg_md.step_id = (bit<16>)eg_intr_md.egress_port;
        eg_md.do_ACTION_SET_OUTPUT_GROUP = 1;
    }
    action rid_control_force_output(){
        eg_md.step_id = (bit<16>)0x1FF;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT = 1;
    }
    action rid_control_step_id(){
        eg_md.step_id = (bit<16>)eg_intr_md.egress_port;
    }
    action rid_control_step_wildcard(){
        eg_md.step_id = (bit<16>)0x1FF;
    }


    table rid_control{
        key = {
            eg_intr_md.egress_rid: exact;
            hdr.internal.type: ternary;
        }
        actions = {
            rid_control_step_id;
            rid_control_do_group;
            rid_control_force_output;
            rid_control_step_wildcard;
            nop;
        }
        const default_action = nop;
        size = 6;
    }
    apply {
        rid_control.apply();
    }
}

control control_pop_egress_control( inout headers_t hdr,
                                    inout egress_metadata_t eg_md,
                                    in egress_intrinsic_metadata_t eg_intr_md,
                                    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                                    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                                    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    action pop_egress_control_id() {
        eg_md.entry_id = hdr.pkt.eg_control_id[0].entry_id;
        hdr.pkt.eg_control_id[0].setInvalid();
    }

    action pop_egress_control() {
        eg_md.entry_id = hdr.pkt.eg_control_id[0].entry_id;
        hdr.pkt.eg_control_id[0].setInvalid();
        hdr.pkt.eg_control.setInvalid();
    }

    table tb_pop_egress_control {
     key = {

      hdr.pkt.eg_control_id[1].isValid(): exact;

      hdr.pkt.eg_control_id[0].isValid(): exact;
            eg_md.chain_id: exact;
     }
     actions = {
      pop_egress_control;

      pop_egress_control_id;

      nop;
     }
        const default_action = nop;
     size = 3;
    }
    apply {
     tb_pop_egress_control.apply();
    }
}

control control_group_buckets_counters( inout headers_t hdr,
                                            inout egress_metadata_t eg_md,
                                            in egress_intrinsic_metadata_t eg_intr_md,
                                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) direct_counter;
    @ignore_table_dependency("egress_control.ct_pop_egress_control.tb_pop_egress_control")
    action inc_counter() {
        direct_counter.count();
    }
    table egress_indirect_counters{
        key = {
            eg_md.entry_id: exact;
            eg_intr_md.egress_port: exact;
            eg_md.chain_id: exact;
        }
        actions = {
            inc_counter;
        }
        size = 15000;
        counters = direct_counter;
    }
    apply {
        egress_indirect_counters.apply();
    }
}


control control_prepare_packet_update( inout headers_t hdr,
                                         inout egress_metadata_t eg_md,
                                         in egress_intrinsic_metadata_t eg_intr_md,
                                         in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                                         inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                                         inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
     action subtract_recirc(bit<16> len) {
         eg_md.packet_len_subtract = len;
     }
     action subtract_recirc_fcs() {
         eg_md.packet_len_subtract = 18 +4;
     }
     action subtract_fcs() {
         eg_md.packet_len_subtract = 4;
     }

     table tb_prepare_packet_update {
         key = {
             hdr.internal.type: exact;
             hdr.pkt.recirc.isValid(): exact;
             hdr.pkt.eg_control_id[0].isValid(): ternary;

             hdr.pkt.eg_control_id[1].isValid() : ternary;


             hdr.pkt.eg_control_id[2].isValid() : ternary;


             hdr.pkt.eg_control_id[3].isValid() : ternary;


             hdr.pkt.eg_control_id[4].isValid() : ternary;


             hdr.pkt.eg_control_id[5].isValid() : ternary;


             hdr.pkt.eg_control_id[6].isValid() : ternary;


             hdr.pkt.eg_control_id[7].isValid() : ternary;




         }
         actions = {
             subtract_recirc;
             subtract_recirc_fcs;
             subtract_fcs;
         }
         size = 15;
     }
     apply {
         tb_prepare_packet_update.apply();
     }
 }


control control_packet_len_update(inout headers_t hdr,
                                inout egress_metadata_t eg_md,
                                in egress_intrinsic_metadata_t eg_intr_md,
                                in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                                inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                                inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)

{
    action packet_len_update() {



    }

    table tb_packet_len_update {
        actions = {
           packet_len_update;
      }
        const default_action = packet_len_update;
        size = 1;
    }
    apply {
        tb_packet_len_update.apply();
    }
}


control control_instructions( inout headers_t hdr,
                                inout egress_metadata_t eg_md,
                                in egress_intrinsic_metadata_t eg_intr_md,
                                in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                                inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                                inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{

    action instructions(






bit<1> do_ACTION_SET_MPLS_LABEL,bit<20> mpls_label,
bit<1> do_ACTION_SET_VLAN_VID,bit<12> vlan_vid,
bit<1> do_ACTION_SET_ETH_SRC,bit<48> eth_src,
bit<1> do_ACTION_SET_ETH_DST,bit<48> eth_dst,

bit<1> do_ACTION_SET_IPV4_SRC,bit<32> ipv4_src,
bit<1> do_ACTION_SET_IPV4_DST,bit<32> ipv4_dst,
bit<1> do_ACTION_SET_IPV6_SRC,bit<128> ipv6_src,
bit<1> do_ACTION_SET_IPV6_DST,bit<128> ipv6_dst,










bit<1> do_ACTION_SET_MPLS_TTL,bit<8> mpls_ttl,


bit<1> do_ACTION_DEC_MPLS_TTL,
bit<1> do_ACTION_DEC_NW_TTL,









                    bit<1> do_group,
                    bit<8> do_output,
                    bit<8> do_inport,
                    bit<4> next_chain_id,
                    bit<8> do_pkt_in,
                    bit<8> do_pkt_local,
                    bit<3> clone_dst,

                    bit<17> entry_id,

                    bit<1> do_push_vlan_8100, bit<1> do_push_vlan_88a8,
                    bit<1> do_pop_vlan,
                    bool do_push_l2gre,
                    bit<1> do_push_l2gre_default,
                    bit<1> do_pop_l2gre,
                    bit<1> do_push_mpls_8847, bit<1> do_push_mpls_8848,
                    bit<3> do_pop_mpls_type,
                    bit<1> do_set_nw_ttl, bit<8> nw_ttl,
                    bit<1> do_copy_field, bit<4> copy_field_profile_id,
                    bit<1> do_swap_field, bit<4> swap_field_profile_id,
        bit<1> do_hash_fields, bit<2> hash_field_profile_id,
                    bit<1> do_push_l2mpls, bool do_push_tunnel_with_flag, bit<24> l2mpls_tunnel_label, bit<24> l2mpls_vc_label,
                    bit<48> tunnel_eth_src, bit<48> tunnel_eth_dst, bit<32> tunnel_ipv4_src, bit<32> tunnel_ipv4_dst,
                    bit<32>l2gre_gre_key,
                    bit<1> do_pop_l2mpls,
                    bit<1> do_push_pbb,
                    bit<1> do_pop_pbb,
                    bit<1> do_push_vxlan, bit<16> vxlan_udp_src, bit<24> vxlan_vni,
                    bit<1> do_pop_vxlan,

                    bit<1> do_l4_srcport, bit<16> l4_srcport,
                    bit<1> do_l4_dstport, bit<16> l4_dstport,

                    bit<1> do_set_ip_ecn, bit<2> ip_ecn,
                    bit<1> do_set_ip_dscp, bit<6> ip_dscp,
                    bit<1> do_set_ip_proto, bit<8> ip_proto
                    )
    {






eg_md.do_ACTION_SET_MPLS_LABEL = do_ACTION_SET_MPLS_LABEL ;
eg_md.do_ACTION_SET_VLAN_VID = do_ACTION_SET_VLAN_VID ;
eg_md.do_ACTION_SET_ETH_SRC = do_ACTION_SET_ETH_SRC ;
eg_md.do_ACTION_SET_ETH_DST = do_ACTION_SET_ETH_DST ;

eg_md.do_ACTION_SET_IPV4_SRC = do_ACTION_SET_IPV4_SRC ;
eg_md.do_ACTION_SET_IPV4_DST = do_ACTION_SET_IPV4_DST ;
eg_md.do_ACTION_SET_IPV6_SRC = do_ACTION_SET_IPV6_SRC ;
eg_md.do_ACTION_SET_IPV6_DST = do_ACTION_SET_IPV6_DST ;










eg_md.do_ACTION_SET_MPLS_TTL = do_ACTION_SET_MPLS_TTL ;














eg_md.mpls_label = mpls_label ;
eg_md.vlan_vid = vlan_vid ;
eg_md.eth_src = eth_src ;
eg_md.eth_dst = eth_dst ;

eg_md.ipv4_src = ipv4_src ;
eg_md.ipv4_dst = ipv4_dst ;
eg_md.ipv6_src = ipv6_src ;
eg_md.ipv6_dst = ipv6_dst ;










eg_md.mpls_ttl = mpls_ttl ;













        eg_md.chain_id = next_chain_id;

        eg_md.clone_dst = clone_dst;

        hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT = do_output | hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT = do_inport | hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT;

        hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL = do_pkt_local;
        eg_md.do_ACTION_SET_OUTPUT_CONTROLLER = do_pkt_in;
        hdr.bridged_meta.pkt_in_reason = 1;

        eg_md.do_ACTION_SET_OUTPUT_GROUP = do_group;
        eg_md.entry_id = entry_id;


        eg_md.do_set_l4_srcport = do_l4_srcport;
        eg_md.l4_srcport = l4_srcport;


        eg_md.do_set_l4_dstport = do_l4_dstport;
        eg_md.l4_dstport = l4_dstport;



        eg_md.do_push_vlan_8100 = do_push_vlan_8100;
        eg_md.do_push_vlan_88a8 = do_push_vlan_88a8;


        eg_md.do_pop_vlan = do_pop_vlan;


        eg_md.do_push_mpls_8847 = do_push_mpls_8847;
        eg_md.do_push_mpls_8848 = do_push_mpls_8848;


        eg_md.do_pop_mpls_type = do_pop_mpls_type;


        eg_md.do_ACTION_SET_NW_TTL = do_set_nw_ttl;
        eg_md.nw_ttl = nw_ttl;


        eg_md.do_ACTION_DEC_MPLS_TTL = do_ACTION_DEC_MPLS_TTL;


        eg_md.do_ACTION_DEC_NW_TTL = do_ACTION_DEC_NW_TTL;
    }


    table tb_instructions {
        key = {
            eg_md.step_id: exact;
            eg_md.chain_id: exact;
            eg_md.entry_id: exact;
        }

        actions = {
            instructions;
            nop;
        }

        const default_action = nop;
        size = 30000;
    }
    apply {
        tb_instructions.apply();
    }
}





control control_tunnel_exec(inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{

    action copy_ethernet_header() {
        hdr.pkt.ethernet.dstAddr = hdr.pkt.inner_ethernet.dstAddr;
        hdr.pkt.ethernet.srcAddr = hdr.pkt.inner_ethernet.srcAddr;
        hdr.pkt.ethernet.etherType = hdr.pkt.inner_ethernet.etherType;
    }







    action vlan_push_vlan_8100() {
        hdr.pkt.vlan.push_front(1);
        hdr.pkt.vlan[0].pcp = 0;
        hdr.pkt.vlan[0].cfi = 0;
        hdr.pkt.vlan[0].vid = 0;
        hdr.pkt.vlan[0].etherType = hdr.pkt.ethernet.etherType;
        hdr.pkt.ethernet.etherType = 0x8100;
    }
    action vlan_push_vlan_88a8() {
        hdr.pkt.vlan.push_front(1);
        hdr.pkt.vlan[0].pcp = 0;
        hdr.pkt.vlan[0].cfi = 0;
        hdr.pkt.vlan[0].vid = 0;
        hdr.pkt.vlan[0].etherType = hdr.pkt.ethernet.etherType;
        hdr.pkt.ethernet.etherType = 0x88A8;
    }




    action vlan_pop_vlan() {
        hdr.pkt.vlan[0].setInvalid();
        hdr.pkt.ethernet.etherType = hdr.pkt.vlan[0].etherType;
    }
    action mpls_push_eth(bit<16> eth_type) {
        hdr.pkt.mpls.push_front(1);
        hdr.pkt.mpls[0].label = 0;
        hdr.pkt.mpls[0].bos = eg_md.mpls_bos_0;
        hdr.pkt.mpls[0].ttl = eg_md.mpls_ttl_0;
        hdr.pkt.mpls[0].exp = 0;
        hdr.pkt.ethernet.etherType = eth_type;
    }

    action mpls_push_vlan0(bit<16>eth_type) {
        hdr.pkt.mpls.push_front(1);
        hdr.pkt.mpls[0].label = 0;
        hdr.pkt.mpls[0].bos = eg_md.mpls_bos_0;
        hdr.pkt.mpls[0].ttl = eg_md.mpls_ttl_0;
        hdr.pkt.mpls[0].exp = 0;
        hdr.pkt.vlan[0].etherType = eth_type;
    }

    action mpls_push_vlan1(bit<16>eth_type) {
        hdr.pkt.mpls.push_front(1);
        hdr.pkt.mpls[0].label = 0;
        hdr.pkt.mpls[0].bos = eg_md.mpls_bos_0;
        hdr.pkt.mpls[0].ttl = eg_md.mpls_ttl_0;
        hdr.pkt.mpls[0].exp = 0;
        hdr.pkt.vlan[1].etherType = eth_type;
    }

    action mpls_push_vlan2(bit<16>eth_type) {
        hdr.pkt.mpls.push_front(1);
        hdr.pkt.mpls[0].label = 0;
        hdr.pkt.mpls[0].bos = eg_md.mpls_bos_0;
        hdr.pkt.mpls[0].ttl = eg_md.mpls_ttl_0;
        hdr.pkt.mpls[0].exp = 0;
        hdr.pkt.vlan[2].etherType = eth_type;
    }



    action mpls_pop_eth(bit<16>eth_type) {
        hdr.pkt.mpls[0].setInvalid();
        hdr.pkt.ethernet.etherType = eth_type;
    }

    action mpls_pop_vlan0(bit<16>eth_type) {
        hdr.pkt.mpls[0].setInvalid();
        hdr.pkt.vlan[0].etherType = eth_type;
    }

    action mpls_pop_vlan1(bit<16>eth_type) {
        hdr.pkt.mpls[0].setInvalid();
        hdr.pkt.vlan[1].etherType = eth_type;
    }
    action mpls_pop_vlan2(bit<16>eth_type) {
        hdr.pkt.mpls[0].setInvalid();
        hdr.pkt.vlan[2].etherType = eth_type;
    }

    action tunnel_drop()
    {
        eg_md.tunnel_drop = 1;
    }

    table tb_tunnel_exec{
        key = {


            eg_md.do_push_vlan_8100: ternary;
            eg_md.do_push_vlan_88a8: ternary;


            eg_md.do_pop_vlan: ternary;


            eg_md.do_push_mpls_8847: ternary;
            eg_md.do_push_mpls_8848: ternary;


            eg_md.do_pop_mpls_type: ternary;
            hdr.pkt.ethernet.isValid(): ternary;
            hdr.pkt.vlan[0].isValid(): ternary;
            hdr.pkt.vlan[1].isValid(): ternary;
            hdr.pkt.vlan[2].isValid(): ternary;
            hdr.pkt.mpls[0].isValid(): ternary;
            hdr.pkt.mpls[1].isValid(): ternary;
            hdr.pkt.mpls[2].isValid(): ternary;






            hdr.pkt.ipv4.isValid() : ternary;
            hdr.pkt.ipv6.isValid() : ternary;
            hdr.pkt.udp.isValid() : ternary;
            hdr.pkt.udpv4_cksum.isValid() : ternary;



            hdr.pkt.udpv6_cksum.isValid() : ternary;
        }
        actions = {


            vlan_push_vlan_8100;
            vlan_push_vlan_88a8;


            vlan_pop_vlan;


            mpls_push_eth;
            mpls_push_vlan0;
            mpls_push_vlan1;
            mpls_push_vlan2;


            mpls_pop_eth;
            mpls_pop_vlan0;
            mpls_pop_vlan1;
            mpls_pop_vlan2;
            tunnel_drop;

            nop;
        }
        const default_action = nop;
        size = 120;

    }

    apply {
        tb_tunnel_exec.apply();
    }
}
control control_action_set_fields( inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    action set_tcp_dst() {

            hdr.pkt.tcp.dstPort = eg_md.l4_dstport;

    }
    action set_tcp_src() {

            hdr.pkt.tcp.srcPort = eg_md.l4_srcport;

    }
    action set_tcp_dst_src() {

            hdr.pkt.tcp.dstPort = eg_md.l4_dstport;


            hdr.pkt.tcp.srcPort = eg_md.l4_srcport;

    }
    action set_udp_dst() {

            hdr.pkt.udp.dstPort = eg_md.l4_dstport;

    }
    action set_udp_src() {

            hdr.pkt.udp.srcPort = eg_md.l4_srcport;

    }
    action set_udp_dst_src() {

            hdr.pkt.udp.dstPort = eg_md.l4_dstport;


            hdr.pkt.udp.srcPort = eg_md.l4_srcport;

    }


    table tb_layer4_fields {
        key = {

                eg_md.do_set_l4_dstport: exact;


                eg_md.do_set_l4_srcport: exact;



                hdr.pkt.tcp.isValid(): exact;



                hdr.pkt.udp.isValid(): exact;
        }
        actions = {
            set_tcp_dst;
            set_tcp_src;
            set_tcp_dst_src;

            set_udp_dst;
            set_udp_src;
            set_udp_dst_src;

            nop;
        }
        const default_action = nop;
        size = 19;
    }





    action set_mpls_label() {

            hdr.pkt.mpls[0].label = eg_md.mpls_label;

    }




    action set_ipv4_src() {

            hdr.pkt.ipv4.srcAddr = eg_md.ipv4_src;

    }
    action set_ipv4_dst() {

            hdr.pkt.ipv4.dstAddr = eg_md.ipv4_dst;

    }
    action set_ipv4_src_dst() {

            hdr.pkt.ipv4.dstAddr = eg_md.ipv4_dst;


            hdr.pkt.ipv4.srcAddr = eg_md.ipv4_src;

    }




    action set_ipv6_src() {

            hdr.pkt.ipv6.srcAddr = eg_md.ipv6_src;

    }
    action set_ipv6_dst() {

            hdr.pkt.ipv6.dstAddr = eg_md.ipv6_dst;

    }
    action set_ipv6_src_dst() {

            hdr.pkt.ipv6.dstAddr = eg_md.ipv6_dst;


            hdr.pkt.ipv6.srcAddr = eg_md.ipv6_src;

    }

    action set_ipv6_src_flabel() {

            hdr.pkt.ipv6.srcAddr = eg_md.ipv6_src;




    }
    action set_ipv6_dst_flabel() {

            hdr.pkt.ipv6.dstAddr = eg_md.ipv6_dst;




    }
    action set_ipv6_src_dst_flabel() {

            hdr.pkt.ipv6.dstAddr = eg_md.ipv6_dst;


            hdr.pkt.ipv6.srcAddr = eg_md.ipv6_src;

    }



    table tb_layer3_fields_part1 {
        key = {

                eg_md.do_ACTION_SET_IPV4_SRC: exact;


                eg_md.do_ACTION_SET_IPV4_DST: exact;



                eg_md.do_ACTION_SET_IPV6_SRC: exact;


                eg_md.do_ACTION_SET_IPV6_DST: exact;
                eg_md.do_ACTION_SET_MPLS_LABEL: exact;

        }
        actions = {
            set_mpls_label;

            set_ipv4_src;
            set_ipv4_dst;
            set_ipv4_src_dst;

            set_ipv6_src;
            set_ipv6_dst;
            set_ipv6_src_dst;

            nop;
        }
        const default_action = nop;
        size = 21;
    }


    action set_vlan_vid() {

        hdr.pkt.vlan[0].vid = eg_md.vlan_vid;

    }

    table tb_vlan_fields {
        key = {

            eg_md.do_ACTION_SET_VLAN_VID: exact;




        }
        actions = {
            set_vlan_vid;
            nop;
        }
        const default_action = nop;
        size = 3;
    }



    action set_eth_dst() {

            hdr.pkt.ethernet.dstAddr = eg_md.eth_dst;

    }
    action set_eth_src() {

            hdr.pkt.ethernet.srcAddr = eg_md.eth_src;

    }
    action set_eth_type() {



    }
    action set_eth_dst_src() {

            hdr.pkt.ethernet.dstAddr = eg_md.eth_dst;


            hdr.pkt.ethernet.srcAddr = eg_md.eth_src;

    }
    action set_eth_dst_type() {

            hdr.pkt.ethernet.dstAddr = eg_md.eth_dst;




    }
    action set_eth_src_type() {

            hdr.pkt.ethernet.srcAddr = eg_md.eth_src;




    }
    action set_eth_dst_src_type() {

            hdr.pkt.ethernet.dstAddr = eg_md.eth_dst;


            hdr.pkt.ethernet.srcAddr = eg_md.eth_src;




    }

    table tb_layer2_fields {
        key = {

                eg_md.do_ACTION_SET_ETH_SRC: exact;


                eg_md.do_ACTION_SET_ETH_DST: exact;




        }
        actions = {
            set_eth_dst;
            set_eth_src;
            set_eth_type;
            set_eth_dst_src;
            set_eth_dst_type;
            set_eth_src_type;
            set_eth_dst_src_type;
            nop;
        }
        const default_action = nop;
        size = 8;
    }


    action set_pbb_uca() {




    }
    action set_pbb_isid() {




    }
    apply {

        tb_layer2_fields.apply();


        tb_layer3_fields_part1.apply();





        tb_layer4_fields.apply();


        tb_vlan_fields.apply();




    }
}



control control_nw_mpls_ttl( inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{

    action ACTION_DEC_MPLS_TTL() {

        hdr.pkt.mpls[0].ttl = hdr.pkt.mpls[0].ttl - 1;

    }
    action ACTION_DEC_NW_TTL_IPV4() {

        hdr.pkt.ipv4.ttl = hdr.pkt.ipv4.ttl - 1;

    }
    action ACTION_DEC_NW_TTL_IPV6() {

        hdr.pkt.ipv6.hopLimit = hdr.pkt.ipv6.hopLimit - 1;

    }
    action ACTION_SET_NW_TTL_IPV4() {

        hdr.pkt.ipv4.ttl = eg_md.nw_ttl;

    }
    action ACTION_SET_NW_TTL_IPV6() {

        hdr.pkt.ipv6.hopLimit = eg_md.nw_ttl;

    }

    action ACTION_SET_MPLS_TTL() {

        hdr.pkt.mpls[0].ttl = eg_md.mpls_ttl;

    }
    action ACTION_INVALID_TTL()
    {

        hdr.bridged_meta.pkt_in_reason = 2;
        hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT = 0;
        eg_md.clone_dst = 2;
        eg_md.do_ACTION_SET_OUTPUT_CONTROLLER = 1;
    }

    table tb_nw_mpls_ttl {
        key = {

                eg_md.do_ACTION_DEC_NW_TTL: ternary;


                eg_md.do_ACTION_DEC_MPLS_TTL: ternary;


                eg_md.do_ACTION_SET_MPLS_TTL: ternary;


                eg_md.do_ACTION_SET_NW_TTL: ternary;


            hdr.pkt.mpls[0].isValid() : ternary;
            hdr.pkt.mpls[0].ttl : ternary;

            hdr.pkt.ipv4.isValid() : ternary;
            hdr.pkt.ipv6.isValid() : ternary;
            hdr.pkt.ipv4.ttl : ternary;
            hdr.pkt.ipv6.hopLimit : ternary;
        }
        actions = {
            ACTION_DEC_MPLS_TTL;
            ACTION_DEC_NW_TTL_IPV4;
            ACTION_DEC_NW_TTL_IPV6;

            ACTION_SET_NW_TTL_IPV4;
            ACTION_SET_NW_TTL_IPV6;
            ACTION_SET_MPLS_TTL;

            ACTION_INVALID_TTL;
            nop;
        }
        const default_action = nop;
        size = 10;
    }
    apply {
        tb_nw_mpls_ttl.apply();
    }
}
control control_action_set( inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{

        control_nw_mpls_ttl() ct_nw_mpls_ttl;


    control_tunnel_exec() ct_tunnel_exec;
        control_action_set_fields() ct_action_set_fields;


    apply {

            ct_nw_mpls_ttl.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);


            ct_tunnel_exec.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
            ct_action_set_fields.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

    }
}




control control_group( inout headers_t hdr,
                        inout egress_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
    ActionSelector(1000, sel_hash, SelectorMode_t.FAIR) action_selector;

    action group( MirrorId_t clone_id, bit<9> port, bit<8> group_type, bit<17> bucket_instr_id )
    {
        hdr.internal.type = 0xfe;
        hdr.mirror.do_ACTION_SET_OUTPUT_PORT = 0;
        hdr.mirror.entry_id = bucket_instr_id;
        eg_md.group_type = group_type;
        hdr.mirror.step_id = (bit<16>)port;
        hdr.mirror.chain_id = eg_md.chain_id;
        eg_md.do_clone = 1;
        eg_md.mirror_id = clone_id;
    }

    table tb_group {
        key = {
            eg_md.entry_id: exact;
        }

        actions = {
            group;
        }

        size = 1000;
    }

    @ignore_table_dependency("egress_control.ct_group.tb_group")
    table tb_group_select {
        key = {
            eg_md.entry_id: exact;



hdr.pkt.ethernet.dstAddr : selector;
hdr.pkt.ethernet.srcAddr : selector;
hdr.bridged_meta.etherType : selector;












































        }
        actions = {
            group;
        }
        implementation = action_selector;
        size = 1000;
    }

    apply {
        tb_group.apply();
        tb_group_select.apply();
    }
}





control control_mpls_push_prepare( inout headers_t hdr,
                        inout egress_metadata_t eg_md)
{




    action mpls_push_prep_mpls(){
        eg_md.mpls_bos_0 = 0;
        eg_md.mpls_ttl_0 = hdr.pkt.mpls[0].ttl;
    }




    action mpls_push_prep_ip(){
        eg_md.mpls_bos_0 = 1;
        eg_md.mpls_ttl_0 = hdr.bridged_meta.original_ttl;
    }




    action mpls_push_prep_nottl(){
        eg_md.mpls_bos_0 = 1;
        eg_md.mpls_ttl_0 = 255;
    }






    table tb_mpls_push_prep {
        key = {
            hdr.pkt.mpls[0].isValid(): ternary;
            hdr.pkt.ipv4.isValid(): ternary;
            hdr.pkt.ipv6.isValid(): ternary;
        }
        actions = {
            mpls_push_prep_mpls;
            mpls_push_prep_ip;



            mpls_push_prep_nottl;
        }
        const default_action = mpls_push_prep_nottl;
        size = 4;
    }

    apply {

            tb_mpls_push_prep.apply();

    }
}




control control_meter_exec( inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                            inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) meter_color_counter;

    action meter_policy_drop()
    {
        meter_color_counter.count();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;

        exit;
    }

    action meter_policy_dscpremark (bit<8> type_dscp) {
        meter_color_counter.count();
        eg_md.meter_dscp_type = type_dscp;
    }

    action meter_policy_dscp_ipv4_set(bit<6> add_val)
    {

    }

    action meter_policy_dscp_ipv6_set(bit<6> add_val)
    {

    }


    table meter_policy_for_dscp {
     key = {
      eg_md.meter_dscp_type: exact;
      hdr.pkt.ipv4.dscp: ternary;
      hdr.pkt.ipv6.dscp: ternary;
      hdr.bridged_meta.etherType : exact;
     }
     actions = {
      meter_policy_dscp_ipv4_set;
      meter_policy_dscp_ipv6_set;
            nop;
     }
        const default_action = nop;
     size = 9;
    }



    table meter_policy{
        key = {
            hdr.bridged_meta.meter_id : exact;
            hdr.bridged_meta.meter_color: exact;
        }
        actions = {
            meter_policy_drop;
            meter_policy_dscpremark;
            @defaultonly nop;
        }
        const default_action = nop;
        size = 10001;
        counters = meter_color_counter;
    }


    apply {

            if (hdr.bridged_meta.meter_id != 0) {
                meter_policy.apply();
                meter_policy_for_dscp.apply();
            }

    }
}




control control_push_recirculate( inout headers_t hdr,
                                    inout egress_metadata_t eg_md,
                                    in egress_intrinsic_metadata_t eg_intr_md)
{
    action push_recirculate() {


        hdr.pkt.recirc.etherType = 0x0102;

        hdr.pkt.recirc.ingress_port = hdr.bridged_meta.ingress_port;
        hdr.pkt.recirc.table_id = hdr.bridged_meta.next_table_id;



        hdr.pkt.recirc.meta = 0;

        hdr.pkt.recirc.egress_metadata_group_type = eg_md.group_type;
        hdr.pkt.recirc.egress_metadata_do_ACTION_SET_OUTPUT_CONTROLLER = eg_md.do_ACTION_SET_OUTPUT_CONTROLLER;
        hdr.pkt.recirc.bridged_metadata_do_ACTION_SET_OUTPUT_INPORT = hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT;
        hdr.pkt.recirc.bridged_metadata_do_ACTION_SET_OUTPUT_LOCAL = hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL;
        hdr.pkt.recirc.bridged_metadata_pkt_in_reason = hdr.bridged_meta.pkt_in_reason;
        hdr.pkt.recirc.egress_port = (bit<16>) eg_intr_md.egress_port;
        hdr.pkt.recirc.setValid();
    }

    table tb_push_recirculate{
        key = {
            eg_intr_md.egress_port: ternary;
            eg_md.clone_dst: ternary;
            hdr.pkt.eg_control.isValid(): ternary;
            eg_md.do_ACTION_SET_OUTPUT_GROUP: ternary;
        }
        actions = {
            push_recirculate;
        }
        size = 19;
    }
    apply {
        tb_push_recirculate.apply();
    }
}


control control_if_do_clone_e2e(inout headers_t hdr,
                                inout egress_metadata_t eg_md,
                                in egress_intrinsic_metadata_t eg_intr_md)
{
    action do_clone_e2e_same_port(MirrorId_t mirr_session){
        hdr.mirror.do_ACTION_SET_OUTPUT_PORT = 1;
        hdr.mirror.step_id = eg_md.step_id;
        hdr.mirror.chain_id = eg_md.chain_id;
        hdr.mirror.entry_id = eg_md.entry_id;
        eg_md.mirror_id = mirr_session;
        eg_md.do_clone = 1;
        hdr.mirror.type = 0xfe;
    }
    action do_clone_e2e_inport(MirrorId_t mirr_session){
        hdr.mirror.do_ACTION_SET_OUTPUT_PORT = 1;




        hdr.mirror.step_id = 0x1FD;
        hdr.mirror.chain_id = eg_md.chain_id;
        hdr.mirror.entry_id = eg_md.entry_id;
        eg_md.mirror_id = mirr_session;
        eg_md.do_clone = 1;
        hdr.mirror.type = 0xfe;
    }
    action do_clone_e2e_cpu(MirrorId_t cpu_mirror_session){
        hdr.mirror.do_ACTION_SET_OUTPUT_PORT = 1;
        hdr.mirror.step_id = 0x1FE;
        hdr.mirror.chain_id = eg_md.chain_id;
        hdr.mirror.entry_id = eg_md.entry_id;
        eg_md.mirror_id = cpu_mirror_session;
        eg_md.do_clone = 1;
        hdr.mirror.type = 0xfe;
    }
    action do_clone_e2e_broadcast(MirrorId_t broadcast_session){
        hdr.mirror.do_ACTION_SET_OUTPUT_PORT = 1;
        hdr.mirror.step_id = 0x1FE;
        hdr.mirror.chain_id = eg_md.chain_id;
        hdr.mirror.entry_id = eg_md.entry_id;
        eg_md.mirror_id = broadcast_session;
        eg_md.do_clone = 1;
        hdr.mirror.type = 0xfe;
    }


    table tb_do_clone_e2e {
        key = {
            eg_md.clone_dst: exact;
            hdr.pkt.eg_control.isValid(): ternary;

            hdr.bridged_meta.ingress_phy_port: ternary;
            eg_intr_md.egress_port: ternary;
        }
        actions = {
            do_clone_e2e_same_port;
            do_clone_e2e_inport;
            do_clone_e2e_cpu;
            do_clone_e2e_broadcast;
            nop;
        }
        const default_action = nop;
        size = 800;
    }
    apply {
        tb_do_clone_e2e.apply();
    }
}

control control_egress_drop(inout headers_t hdr,
                            inout egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_t eg_intr_md,
                            inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    action egress_drop(){
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }
    action egress_drop_exit(){
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
        exit;
    }

    table tb_egress_drop{
        key = {



            hdr.bridged_meta.ingress_port: ternary;
            eg_intr_md.egress_port: ternary;
            hdr.bridged_meta.do_ACTION_SET_OUTPUT_INPORT: ternary;
            eg_md.group_type: ternary;


            hdr.bridged_meta.do_ACTION_SET_OUTPUT_PORT: ternary;




            eg_md.do_ACTION_SET_VLAN_VID: ternary;




            hdr.pkt.vlan[0].isValid(): ternary;


            eg_md.do_ACTION_SET_MPLS_LABEL: ternary;


            eg_md.do_ACTION_SET_MPLS_TTL: ternary;





            eg_md.do_ACTION_DEC_MPLS_TTL: ternary;


            eg_md.do_ACTION_DEC_NW_TTL: ternary;
            hdr.pkt.ipv4.isValid() : ternary;
            hdr.pkt.ipv6.isValid() : ternary;


            hdr.pkt.mpls[0].isValid(): ternary;



            eg_md.do_ACTION_SET_OUTPUT_GROUP: ternary;




            eg_md.clone_dst: ternary;


            hdr.pkt.eg_control.isValid(): ternary;


            eg_md.chain_id: ternary;




            eg_md.tunnel_drop: ternary;
        }
        actions = {
            egress_drop;
            egress_drop_exit;
            nop;
        }
        const default_action = nop;
        size = 300;
    }
    apply {
        tb_egress_drop.apply();
    }
}




control control_packet_to_cpu( inout headers_t hdr,
                                inout egress_metadata_t eg_md,
                                in egress_intrinsic_metadata_t eg_intr_md)
{
    action a_packet_in() {
        hdr.pkt.packet_in_header.setValid();
        hdr.pkt.packet_in_header.reason = hdr.bridged_meta.pkt_in_reason;
        hdr.pkt.packet_in_header.pktin_type = 0;
        hdr.pkt.packet_in_header.ingress_port = hdr.bridged_meta.ingress_port;
        hdr.pkt.packet_in_header.hw_ingress_port = hdr.bridged_meta.ingress_port;
        hdr.pkt.packet_in_header.entry_id = eg_md.entry_id;
        hdr.pkt.packet_in_header.meta = hdr.bridged_meta.meta;


    }

    action packet_local() {
        hdr.pkt.packet_in_header.setValid();
        hdr.pkt.packet_in_header.reason = 0;
        hdr.pkt.packet_in_header.pktin_type = 1;
        hdr.pkt.packet_in_header.ingress_port = hdr.bridged_meta.ingress_port;
        hdr.pkt.packet_in_header.hw_ingress_port = hdr.bridged_meta.ingress_port;


        hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL = 0;
    }

    action packet_bfd() {
        hdr.pkt.packet_in_header.setValid();
        hdr.pkt.packet_in_header.reason = 0;
        hdr.pkt.packet_in_header.pktin_type = 2;
        hdr.pkt.packet_in_header.ingress_port = hdr.bridged_meta.ingress_port;
        hdr.pkt.packet_in_header.hw_ingress_port = hdr.bridged_meta.ingress_port;


        hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL = 0;
    }


    table tb_packet_to_cpu {
        key = {
            hdr.pkt.udp.isValid() : ternary;
            hdr.pkt.udp.dstPort : ternary;
            eg_intr_md.egress_port: exact;
            hdr.bridged_meta.do_ACTION_SET_OUTPUT_LOCAL: exact;
            eg_md.do_ACTION_SET_OUTPUT_CONTROLLER : exact;

        }
        actions = {
            a_packet_in;
            packet_bfd;
            packet_local;
            nop;
        }
        const default_action = nop;
        size = 4;
    }
    apply {
        tb_packet_to_cpu.apply();
    }
}

control egress_control( inout headers_t hdr,
                        inout egress_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
    control_remove_internal_headers() ct_remove_internal_headers;
    control_rid_control() ct_rid_control;
    control_mpls_push_prepare() ct_mpls_push_prepare;
    control_pop_egress_control() ct_pop_egress_control;
    control_prepare_packet_update() ct_prepare_packet_update;
    control_packet_len_update() ct_packet_len_update;
    control_group_buckets_counters() ct_group_buckets_counters;

    control_instructions() ct_instructions;
    control_action_set() ct_action_set;
    control_group() ct_group;
    control_meter_exec() ct_meter_exec;

    control_if_do_clone_e2e() ct_if_do_clone_e2e;
    control_egress_drop() ct_egress_drop;
    control_packet_to_cpu() ct_packet_to_cpu;
    control_push_recirculate() ct_push_recirculate;

    apply {
        ct_remove_internal_headers.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        ct_rid_control.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        ct_mpls_push_prepare.apply (hdr, eg_md);
        ct_pop_egress_control.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        ct_group_buckets_counters.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        ct_prepare_packet_update.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        ct_packet_len_update.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

        ct_instructions.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

        ct_action_set.apply (hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

        if ( eg_md.do_ACTION_SET_OUTPUT_GROUP == 1 ){




            ct_group.apply(hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
        }
        ct_meter_exec.apply(hdr, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

        ct_egress_drop.apply (hdr, eg_md, eg_intr_md, eg_intr_md_for_dprsr);
        ct_push_recirculate.apply (hdr, eg_md, eg_intr_md);
        ct_if_do_clone_e2e.apply (hdr, eg_md, eg_intr_md);
        ct_packet_to_cpu.apply (hdr, eg_md, eg_intr_md);
    }
}


control egress_deparser( packet_out packet,
                            inout headers_t hdr,
                            in egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    Mirror() mirror;

    Checksum() ipv4_checksum;



    Checksum() tcpv4_checksum;
    Checksum() tcpv6_checksum;
    Checksum() udpv4_checksum;
    Checksum() udpv6_checksum;

    apply {
        hdr.pkt.tunnel_ipv4_push.hdr_checksum = ipv4_checksum.update({
            hdr.pkt.tunnel_ipv4_push.version,
            hdr.pkt.tunnel_ipv4_push.ihl,
            hdr.pkt.tunnel_ipv4_push.dscp,
            hdr.pkt.tunnel_ipv4_push.ecn,
            hdr.pkt.tunnel_ipv4_push.len,
            hdr.pkt.tunnel_ipv4_push.identification,
            hdr.pkt.tunnel_ipv4_push.flags,
            hdr.pkt.tunnel_ipv4_push.fragOffset,
            hdr.pkt.tunnel_ipv4_push.ttl,
            hdr.pkt.tunnel_ipv4_push.protocol,
            hdr.pkt.tunnel_ipv4_push.srcAddr,
            hdr.pkt.tunnel_ipv4_push.dstAddr});

        hdr.pkt.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.pkt.ipv4.version,
            hdr.pkt.ipv4.ihl,
            hdr.pkt.ipv4.dscp,
            hdr.pkt.ipv4.ecn,
            hdr.pkt.ipv4.len,
            hdr.pkt.ipv4.identification,
            hdr.pkt.ipv4.flags,
            hdr.pkt.ipv4.fragOffset,
            hdr.pkt.ipv4.ttl,
            hdr.pkt.ipv4.protocol,
            hdr.pkt.ipv4.srcAddr,
            hdr.pkt.ipv4.dstAddr});
        hdr.pkt.tcpv4_cksum.checksum = tcpv4_checksum.update({
            hdr.pkt.ipv4.srcAddr,
            hdr.pkt.ipv4.dstAddr,
            8w0,
            hdr.pkt.ipv4.protocol,
            hdr.pkt.ipv4.len,
            hdr.pkt.tcp.srcPort,
            hdr.pkt.tcp.dstPort,
            hdr.pkt.tcp.seqNo,
            hdr.pkt.tcp.ackNo,
            hdr.pkt.tcp.dataOffset,
            hdr.pkt.tcp.res,
            hdr.pkt.tcp.ecn,
            hdr.pkt.tcp.ctrl,
            hdr.pkt.tcp.window,
            hdr.pkt.tcpv4_cksum.urgentPtr,
            hdr.bridged_meta.l4_checksum});
        hdr.pkt.tcpv6_cksum.checksum = tcpv6_checksum.update({
            hdr.pkt.ipv6.srcAddr,
            hdr.pkt.ipv6.dstAddr,
            16w0,
            hdr.pkt.ipv6.payloadLen,
            24w0,
            hdr.pkt.ipv6.nextHdr,
            hdr.pkt.tcp.srcPort,
            hdr.pkt.tcp.dstPort,
            hdr.pkt.tcp.seqNo,
            hdr.pkt.tcp.ackNo,
            hdr.pkt.tcp.dataOffset,
            hdr.pkt.tcp.res,
            hdr.pkt.tcp.ecn,
            hdr.pkt.tcp.ctrl,
            hdr.pkt.tcp.window,
            hdr.pkt.tcpv6_cksum.urgentPtr,
            hdr.bridged_meta.l4_checksum});

        hdr.pkt.udpv4_cksum.checksum = udpv4_checksum.update({
            hdr.pkt.ipv4.srcAddr,
            hdr.pkt.ipv4.dstAddr,
            8w0,
            hdr.pkt.ipv4.protocol,
            hdr.pkt.ipv4.len,
            hdr.pkt.udp.srcPort,
            hdr.pkt.udp.dstPort,
            hdr.pkt.udp.hdr_length,
            hdr.bridged_meta.l4_checksum});

        hdr.pkt.udpv6_cksum.checksum = udpv6_checksum.update({
            hdr.pkt.ipv6.srcAddr,
            hdr.pkt.ipv6.dstAddr,
            16w0,
            hdr.pkt.ipv6.payloadLen,
            24w0,
            hdr.pkt.ipv6.nextHdr,
            hdr.pkt.udp.srcPort,
            hdr.pkt.udp.dstPort,
            hdr.pkt.udp.hdr_length,
            hdr.bridged_meta.l4_checksum});

        packet.emit(hdr.pkt);
        if (eg_md.do_clone == 1)
        {
            mirror.emit(eg_md.mirror_id, hdr.mirror);
        }
    }
}




Pipeline(ingress_parser(),
         ingress_control(),
         ingress_deparser(),
         egress_parser(),
         egress_control(),
         egress_deparser()) pipeline;

Switch(pipeline) main;
