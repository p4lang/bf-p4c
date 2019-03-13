#include <core.p4>
#include <tofino.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<6>  dscp;
    bit<2>  ecn;
    bit<16> len;
    bit<16> identification;
    bit<3>  flags;
    bit<13> frag_offset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ether_type;
}

header metadata_hdr_t {
    bit<20> pad0;
    bit<12> vid;
}

struct headers_t {
    metadata_hdr_t bridged_meta;
    ethernet_t     ethernet;
    ipv4_t         ipv4;
    vlan_tag_t     vlan;
}

header mirror_metadata_t {
    MirrorId_t id;
    bit<22>    pad0;
}

struct local_metadata_t {
    bit<1>            unknown_pkt_err;
    bit<31>           pad0;
    mirror_metadata_t mirr_md;
}

parser ingress_parser(packet_in packet, out headers_t hdr, out local_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        ig_md.unknown_pkt_err = 1w0;
        hdr.bridged_meta.pad0 = 20w0x12345;
        hdr.bridged_meta.setValid();
        packet.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        packet.advance(32w64);
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x800: parse_ipv4;
            16w0x8100: parse_vlan;
            default: unknown_packet_err;
        }
    }
    state parse_vlan {
        packet.extract<vlan_tag_t>(hdr.vlan);
        transition select(hdr.vlan.ether_type) {
            16w0x800: parse_ipv4;
            default: unknown_packet_err;
        }
    }
    state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition accept;
    }
    state unknown_packet_err {
        ig_md.unknown_pkt_err = 1w1;
        transition accept;
    }
}

control ingress_control(inout headers_t hdr, inout local_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    @name("ingress_control.set_egress_port") action set_egress_port(PortId_t port, bit<12> vid) {
        ig_tm_md.ucast_egress_port = port;
        hdr.bridged_meta.vid = vid;
    }
    @name("ingress_control.set_egress_port") action set_egress_port_2() {
        ig_tm_md.ucast_egress_port = 9w64;
        hdr.bridged_meta.vid = 12w0;
    }
    @name("ingress_control.drop") action drop() {
        ig_dprsr_md.drop_ctl = 3w0x1;
    }
    @name("ingress_control.set_output") table set_output_0 {
        key = {
            ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
        }
        actions = {
            set_egress_port();
            drop();
        }
        const default_action = drop();
    }
    @hidden table tbl_set_egress_port {
        actions = {
            set_egress_port_2();
        }
        const default_action = set_egress_port_2();
    }
    apply {
        if (ig_md.unknown_pkt_err != 1w0) 
            tbl_set_egress_port.apply();
        else 
            set_output_0.apply();
    }
}

control ingress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    @hidden action act() {
        packet.emit<metadata_hdr_t>(hdr.bridged_meta);
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<ipv4_t>(hdr.ipv4);
        packet.emit<vlan_tag_t>(hdr.vlan);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

parser egress_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    metadata_hdr_t hdr_0_bridged_meta;
    ethernet_t hdr_0_ethernet;
    ipv4_t hdr_0_ipv4;
    vlan_tag_t hdr_0_vlan;
    bit<1> eg_md_0_unknown_pkt_err;
    bit<31> eg_md_0_pad0;
    mirror_metadata_t eg_md_0_mirr_md;
    egress_intrinsic_metadata_t eg_intr_md_0;
    state start {
        hdr_0_bridged_meta.setInvalid();
        hdr_0_ethernet.setInvalid();
        hdr_0_ipv4.setInvalid();
        hdr_0_vlan.setInvalid();
        eg_md_0_mirr_md.setInvalid();
        eg_intr_md_0.setInvalid();
        packet.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        packet.extract<metadata_hdr_t>(hdr_0_bridged_meta);
        packet.extract<ethernet_t>(hdr_0_ethernet);
        transition select(hdr_0_ethernet.ether_type) {
            16w0x800: eg_parser_parse_ipv4;
            16w0x8100: eg_parser_parse_vlan;
            default: start_0;
        }
    }
    state eg_parser_parse_vlan {
        packet.extract<vlan_tag_t>(hdr_0_vlan);
        transition select(hdr_0_vlan.ether_type) {
            16w0x800: eg_parser_parse_ipv4;
            default: start_0;
        }
    }
    state eg_parser_parse_ipv4 {
        packet.extract<ipv4_t>(hdr_0_ipv4);
        transition start_0;
    }
    state start_0 {
        hdr.bridged_meta = hdr_0_bridged_meta;
        hdr.ethernet = hdr_0_ethernet;
        hdr.ipv4 = hdr_0_ipv4;
        hdr.vlan = hdr_0_vlan;
        eg_md.unknown_pkt_err = eg_md_0_unknown_pkt_err;
        eg_md.pad0 = eg_md_0_pad0;
        eg_md.mirr_md = eg_md_0_mirr_md;
        eg_intr_md = eg_intr_md_0;
        transition accept;
    }
}

control egress_control(inout headers_t hdr, inout local_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    @name("egress_control.push_vlan_hdr") action push_vlan_hdr() {
        hdr.vlan.setValid();
        hdr.ethernet.ether_type = 16w0x8100;
        hdr.vlan.vid = hdr.bridged_meta.vid;
        hdr.vlan.ether_type = 16w0x800;
    }
    @name("egress_control.push_vlan") table push_vlan_0 {
        actions = {
            push_vlan_hdr();
        }
        const default_action = push_vlan_hdr();
    }
    apply {
        if (hdr.bridged_meta.vid != 12w0) 
            push_vlan_0.apply();
    }
}

control egress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    @name("egress_deparser._clone_e2e.mirror") Mirror() _clone_e2e_mirror;
    @name("egress_deparser._clone_e2e.clone") action _clone_e2e_clone_0(bit<48> dst_addr, MirrorId_t mirr_id) {
        _clone_e2e_mirror.emit(mirr_id);
    }
    @name("egress_deparser._clone_e2e.do_not_clone") action _clone_e2e_do_not_clone_0() {
    }
    @name("egress_deparser._clone_e2e.clone_e2e") table _clone_e2e_clone_e2e {
        key = {
            hdr.ethernet.dst_addr: exact @name("hdr.ethernet.dst_addr") ;
        }
        actions = {
            _clone_e2e_clone_0();
            _clone_e2e_do_not_clone_0();
        }
        default_action = _clone_e2e_do_not_clone_0();
    }
    @hidden action act_0() {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t>(hdr.vlan);
        packet.emit<ipv4_t>(hdr.ipv4);
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
        @pa_container_size("egress" , "mirr_id" , 16) {
            _clone_e2e_clone_e2e.apply();
        }
    }
}

Pipeline<headers_t, local_metadata_t, headers_t, local_metadata_t>(ingress_parser(), ingress_control(), ingress_deparser(), egress_parser(), egress_control(), egress_deparser()) pipeline;

Switch<headers_t, local_metadata_t, headers_t, local_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipeline) main;

