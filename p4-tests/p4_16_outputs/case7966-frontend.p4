#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

typedef bit<8> inthdr_type_t;
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

parser ingress_parser(packet_in packet, out headers_t hdr, out local_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        ig_md.unknown_pkt_err = 1w0;
        hdr.bridged_meta.hdr_type = 8w0xfc;
        hdr.bridged_meta.pad0 = 12w0x0;
        hdr.bridged_meta.setValid();
        packet.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        packet.advance(32w64);
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
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
    @name("ingress_control.do_nothing") action do_nothing() {
    }
    apply {
        do_nothing();
    }
}

control ingress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        packet.emit<headers_t>(hdr);
    }
}

parser egress_parser(packet_in packet, out headers_t hdr, out local_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    headers_t hdr_0;
    local_metadata_t eg_md_0;
    egress_intrinsic_metadata_t eg_intr_md_0;
    inthdr_type_t _eg_parser_inthdr_type;
    bit<8> _eg_parser_tmp;
    state start {
        hdr_0.bridged_meta.setInvalid();
        hdr_0.ethernet.setInvalid();
        hdr_0.ipv4.setInvalid();
        hdr_0.vlan.setInvalid();
        eg_md_0.mirrored_meta.setInvalid();
        eg_intr_md_0.setInvalid();
        transition eg_parser_start;
    }
    state eg_parser_start {
        eg_md_0.mirrored_meta.hdr_type = 8w0xfe;
        packet.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        _eg_parser_tmp = packet.lookahead<inthdr_type_t>();
        _eg_parser_inthdr_type = _eg_parser_tmp;
        transition select(_eg_parser_inthdr_type) {
            8w0xfc: eg_parser_parse_bridged_metadata;
            default: eg_parser_parse_mirrored_packet;
        }
    }
    state eg_parser_parse_mirrored_packet {
        packet.extract<mirror_meta_hdr_t>(eg_md_0.mirrored_meta);
        transition eg_parser_parse_bridged_metadata;
    }
    state eg_parser_parse_bridged_metadata {
        packet.extract<bridged_meta_hdr_t>(hdr_0.bridged_meta);
        packet.extract<ethernet_t>(hdr_0.ethernet);
        transition select(hdr_0.ethernet.ether_type) {
            16w0x800: eg_parser_parse_ipv4;
            default: start_0;
        }
    }
    state eg_parser_parse_ipv4 {
        packet.extract<ipv4_t>(hdr_0.ipv4);
        transition start_0;
    }
    state start_0 {
        hdr = hdr_0;
        eg_md = eg_md_0;
        eg_intr_md = eg_intr_md_0;
        transition accept;
    }
}

control egress_control(inout headers_t hdr, inout local_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    @name("egress_control.do_nothing") action do_nothing_2() {
    }
    apply {
        do_nothing_2();
    }
}

control egress_deparser(packet_out packet, inout headers_t hdr, in local_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    @name("egress_deparser.clone_e2e.mirror") Mirror() clone_e2e_mirror;
    apply {
        packet.emit<headers_t>(hdr);
        @pa_container_size("egress" , "hdr.bridged_meta.mirror_id" , 16) {
            if (eg_md.do_clone == 1w1) 
                clone_e2e_mirror.emit<tuple<bit<8>, bit<16>>>(hdr.bridged_meta.mirror_id, { eg_md.mirrored_meta.hdr_type, eg_md.mirrored_meta.pad0 });
        }
    }
}

Pipeline<headers_t, local_metadata_t, headers_t, local_metadata_t>(ingress_parser(), ingress_control(), ingress_deparser(), egress_parser(), egress_control(), egress_deparser()) pipeline;

Switch<headers_t, local_metadata_t, headers_t, local_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipeline) main;

