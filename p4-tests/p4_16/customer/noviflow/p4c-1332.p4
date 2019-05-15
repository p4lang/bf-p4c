
#include <core.p4>
#include <tna.p4>


action nop() {}


header mirror_meta_hdr_t{
    bit<8> type;
    @flexible bit<17> mirrorfield1;
    @flexible bit<16> mirrorfield2;
    @flexible bit<4> mirrorfield3;
    @flexible bit<1> someflag5;
}

header bridged_meta_hdr_t{
    @flexible bit<1> someflag5;
    @flexible bit<1> someflag6;
    @flexible bit<1> someflag7;
    @flexible bit<1> someflag8;
    @flexible bit<1> someflag9;
    @flexible bit<4> somefield1;
    @flexible bit<16> egress_port;
    @flexible bit<16> ingress_phy_port;
    @flexible bit<32> meta;
    @flexible bit<16> ingress_port;
    @flexible bit<16> etherType;
    @flexible bit<3> somefield;
}

struct ingress_metadata_t {
    bit<1> someflag1;
    bit<1> someflag2;
    bit<1> someflag3;
    bit<16> somefield4;
}


header packet_out_t {
        bit<8> output_local;
        bit<8> do_recirculate;
        bit<16> egress_port;
        bit<16> ingress_port;
        bit<8> do_output;
        bit<8> someflag3;
        bit<16> somefield4;
        bit<8> do_output_lag;
        bit<8> do_pkt_in;
        bit<16> etherType;
}

struct egress_metadata_t
{
    bit<1> unknown_pkt_err;

    bit<1> do_clone;
    bit<10> mirror_id;
}



header recirc_header_t {

    bit<32> meta;
    bit<16> egress_port;
    bit<16> ingress_port;
    bit<32> some_padding;
    bit<16> etherType;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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




struct packet_headers_t {
    recirc_header_t recirc;
    packet_out_t packet_out;

    ethernet_t ethernet;
    vlan_tag_t[3] vlan;
    mpls_t[3] mpls;
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
            default: parse_ethernet;
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
            default: accept;
        }
    }
}






parser egress_parser( packet_in packet,
                        out headers_t hdr,
                        out egress_metadata_t eg_md,
                        out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {


        packet.extract(eg_intr_md);
        packet.extract(hdr.internal);
        transition accept;
    }
}



control ingress_control( inout headers_t hdr,
                            inout ingress_metadata_t ig_md,
                            in ingress_intrinsic_metadata_t ig_intr_md,
                            in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)
{
    action preparse_recirculate() {
        hdr.bridged_meta.ingress_port = hdr.pkt.recirc.ingress_port;

    }

    action preparse_packet_out() {
         ig_md.someflag2 = 1;
         hdr.bridged_meta.someflag5 = (bit<1>) hdr.pkt.packet_out.do_output;
         hdr.bridged_meta.someflag9 = (bit<1>) hdr.pkt.packet_out.output_local;
         hdr.bridged_meta.egress_port = hdr.pkt.packet_out.egress_port ;
         ig_md.someflag1 = (bit<1>) hdr.pkt.packet_out.do_recirculate;
         hdr.bridged_meta.ingress_port = hdr.pkt.packet_out.ingress_port;
         hdr.bridged_meta.ingress_phy_port = hdr.pkt.packet_out.ingress_port;
         hdr.bridged_meta.somefield = 3;

         ig_md.someflag3 = (bit<1>) hdr.pkt.packet_out.someflag3;
         ig_md.somefield4 = hdr.pkt.packet_out.somefield4;
         hdr.bridged_meta.someflag8 = (bit<1>) hdr.pkt.packet_out.do_output_lag;



     }

    action preparse_dataplane_packet() {
        hdr.bridged_meta.ingress_port = (bit<16>)ig_intr_md.ingress_port;



        hdr.bridged_meta.ingress_phy_port = (bit<16>)ig_intr_md.ingress_port;
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

            nop;
        }
        const default_action = nop;
        size = 262;
    }

    action set_innermost_ethertype_vlan2() {
        hdr.bridged_meta.etherType = hdr.pkt.vlan[2].etherType;
    }

    action set_innermost_ethertype_vlan1() {
        hdr.bridged_meta.etherType = hdr.pkt.vlan[1].etherType;
    }

    action set_innermost_ethertype_vlan0() {
        hdr.bridged_meta.etherType = hdr.pkt.vlan[0].etherType;
    }

    action set_innermost_ethertype_ethernet() {
        hdr.bridged_meta.etherType = hdr.pkt.ethernet.etherType;
    }


    table table_set_innermost_ethertype {
        key = {
            hdr.pkt.ethernet.isValid() : ternary;
            hdr.pkt.vlan[0].isValid() : ternary;
            hdr.pkt.vlan[1].isValid() : ternary;
            hdr.pkt.vlan[2].isValid() : ternary;
        }
        actions = {
            set_innermost_ethertype_vlan2;
            set_innermost_ethertype_vlan1;
            set_innermost_ethertype_vlan0;
            set_innermost_ethertype_ethernet;
            nop;
        }
        const default_action = nop;
        size = 6;
    }
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
            hdr.bridged_meta.someflag5: exact;
            hdr.bridged_meta.someflag7: exact;
        }

        actions = {
            set_egress_port;
            set_egress_inport;
            set_egress_invalidate;
        }

        const default_action = set_egress_invalidate;
    }

    apply{

        table_set_innermost_ethertype.apply();
        table_preparse.apply();

        set_output.apply();
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



control egress_control( inout headers_t hdr,
                        inout egress_metadata_t eg_md,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
   apply {
    nop();
   }
}


control egress_deparser( packet_out packet,
                            inout headers_t hdr,
                            in egress_metadata_t eg_md,
                            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
    Mirror() mirror;

    apply {
        packet.emit(hdr.pkt);
        if (eg_md.do_clone == 1)
        {
            mirror.emit<mirror_meta_hdr_t>(eg_md.mirror_id, { hdr.internal.type,

                                            hdr.mirror.mirrorfield1,
                                            hdr.mirror.mirrorfield2,
                                            hdr.mirror.mirrorfield3,
                                            hdr.mirror.someflag5

                                            });


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
