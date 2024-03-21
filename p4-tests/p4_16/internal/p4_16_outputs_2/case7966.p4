#include <tna.p4>

typedef bit<8> inthdr_type_t;
const inthdr_type_t INTHDR_TYPE_BRIDGE = 0xfc;
const inthdr_type_t INTHDR_TYPE_CLONE_INGRESS = 0xfd;
const inthdr_type_t INTHDR_TYPE_CLONE_EGRESS = 0xfe;
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

header bridged_meta_hdr_t {
    inthdr_type_t hdr_type;
    bit<3>        pad1;
    bit<1>        do_clone;
    bit<12>       pad0;
    bit<6>        pad2;
    MirrorId_t    mirror_id;
}

header mirror_meta_hdr_t {
    inthdr_type_t hdr_type;
    bit<16>       pad0;
}

struct headers_t {
    bridged_meta_hdr_t bridged_meta;
    ethernet_t         ethernet;
    ipv4_t             ipv4;
    vlan_tag_t         vlan;
}

struct local_metadata_t {
    bit<1>            unknown_pkt_err;
    bit<1>            do_clone;
    bit<6>            pad0;
    mirror_meta_hdr_t mirrored_meta;
}

@pa_container_size("egress" , "hdr.bridged_meta.mirror_id" , 16) control clone_e2e_control(inout headers_t hdr, in local_metadata_t md) {
    Mirror() mirror;
    apply {
        if (md.do_clone == 1) {
            mirror.emit(hdr.bridged_meta.mirror_id, { md.mirrored_meta.hdr_type, md.mirrored_meta.pad0 });
        }
    }
}

parser ingress_parser(packet_in packet, out headers_t hdr, out local_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        ig_md.unknown_pkt_err = 0;
        hdr.bridged_meta.hdr_type = INTHDR_TYPE_BRIDGE;
        hdr.bridged_meta.pad0 = 0x0;
        hdr.bridged_meta.setValid();
        packet.extract(ig_intr_md);
        packet.advance(64);
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x800: parse_ipv4;
            default: unknown_packet_err;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
    state unknown_packet_err {
        ig_md.unknown_pkt_err = 1;
        transition accept;
    }
}

control ingress_control(inout headers_t hdr, inout local_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    action do_nothing() {
    }
    apply {
        do_nothing();
    }
}

control ingress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        packet.emit(hdr);
    }
}

parser eg_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        eg_md.mirrored_meta.hdr_type = INTHDR_TYPE_CLONE_EGRESS;
        packet.extract(eg_intr_md);
        inthdr_type_t inthdr_type = packet.lookahead<inthdr_type_t>();
        transition select(inthdr_type) {
            INTHDR_TYPE_BRIDGE: parse_bridged_metadata;
            default: parse_mirrored_packet;
        }
    }
    state parse_mirrored_packet {
        packet.extract(eg_md.mirrored_meta);
        transition parse_bridged_metadata;
    }
    state parse_bridged_metadata {
        packet.extract(hdr.bridged_meta);
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}

parser egress_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    eg_parser() _eg_parser;
    state start {
        _eg_parser.apply(packet, hdr, eg_md, eg_intr_md);
        transition accept;
    }
}

control egress_control(inout headers_t hdr, inout local_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    action do_nothing() {
    }
    apply {
        do_nothing();
    }
}

control egress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    clone_e2e_control() clone_e2e;
    apply {
        packet.emit(hdr);
        clone_e2e.apply(hdr, eg_md);
    }
}

Pipeline(ingress_parser(), ingress_control(), ingress_deparser(), egress_parser(), egress_control(), egress_deparser()) pipeline;

Switch(pipeline) main;
