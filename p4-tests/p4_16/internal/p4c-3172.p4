// bf-p4c --std=p4-16 --target=tofino2 --arch=t2na p4c-3172.p4

#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_MPLS = 16w0x8847;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    ether_type_t ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> qos;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<2> ecn;
    bit<6> dscp;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

struct headers {
    ethernet_h ethernet;
    vlan_tag_h vlan;
    mpls_h[4] mpls;
    ipv4_h ipv4;
}

#define COUNTER_WIDTH 32
#define INDEX_WIDTH 6

struct metadata {
    bit<INDEX_WIDTH> index1;
    bit<INDEX_WIDTH> index2;
    bit<INDEX_WIDTH> index3;
    bit<INDEX_WIDTH> index4;
    bit<INDEX_WIDTH> index5;
}

parser ingressParser(packet_in pkt, out headers hdr, out metadata meta,
                     out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        meta.index1 = 0;
        meta.index2 = 0;
        meta.index3 = 0;
        meta.index4 = 0;
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_MPLS : parse_mpls;
            ETHERTYPE_IPV4 : parse_ipv4;
        }
    }
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_MPLS : parse_mpls;
            ETHERTYPE_IPV4 : parse_ipv4;
        }
    }
    state parse_mpls {
        pkt.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos, pkt.lookahead<bit<4>>()) {
            (0, _)  : parse_mpls;
            (1, 4)  : parse_ipv4;
            default : reject;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action actionKeyNoParam() {
        meta.index1 = (bit<INDEX_WIDTH>)hdr.vlan.pcp + meta.index1;
    }
    table tableKeyNoParam {
        key = { hdr.vlan.pcp : exact; }
        actions = { actionKeyNoParam; }
    }

    action actionNoKeyDefaultActionNoParam() {
        meta.index2 = (bit<INDEX_WIDTH>)hdr.vlan.pcp + meta.index2;
    }
    table tableNoKeyDefaultActionNoParam {
        actions = { actionNoKeyDefaultActionNoParam; }
        default_action = actionNoKeyDefaultActionNoParam;
    }

    action actionNoParamSub() {
        meta.index3 = (bit<INDEX_WIDTH>)hdr.vlan.pcp - meta.index3;
    }
    action actionNoParamAddSat() {
        //meta.index3 = (bit<INDEX_WIDTH>)hdr.vlan.pcp |+| meta.index3;
    }
    action actionNoParamSubSat() {
        meta.index3 = (bit<INDEX_WIDTH>)hdr.vlan.pcp |-| meta.index3;
    }
    table tableKeyNoParamBinary {
        key = { hdr.vlan.pcp : exact; }
        actions = {
            actionNoParamSub;
            actionNoParamAddSat;
            actionNoParamSubSat;
        }
    }

    action actionNoParamAddCommutative() {
        meta.index4 = meta.index4 + (bit<INDEX_WIDTH>)hdr.vlan.pcp;
    }
    action actionNoParamAddSatCommutative() {
        //meta.index4 = meta.index4 |+| (bit<INDEX_WIDTH>)hdr.vlan.pcp;
    }
    table tableKeyNoParamBinaryCommutative {
        key = { hdr.vlan.pcp : exact; }
        actions = {
            actionNoParamAddCommutative;
            actionNoParamAddSatCommutative;
        }
    }

    action metaIndexAction() {
    }
    table metaIndexTable {
        key = {
            meta.index1 : exact;
            meta.index2 : exact;
            meta.index3 : exact;
            meta.index4 : exact;
            meta.index5 : exact;
        }
        actions = { metaIndexAction; }
    }

    apply {
        meta.index5 = (bit<INDEX_WIDTH>)hdr.vlan.pcp + meta.index5;
        if (hdr.vlan.isValid()) {
            tableKeyNoParam.apply();
            tableNoKeyDefaultActionNoParam.apply();
            tableKeyNoParamBinary.apply();
            tableKeyNoParamBinaryCommutative.apply();
            metaIndexTable.apply();
        }
    }
}

control ingressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                        in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs) {
    apply {
    }
}

parser egressParser(packet_in packet, out headers hdr, out metadata meta,
                    out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        packet.extract(eg_intr_md);
        transition accept;
    }
}


control egress(inout headers hdr, inout metadata meta,
               in egress_intrinsic_metadata_t eg_intr_md,
               in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
               inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
               inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control egressDeparser(packet_out packet, inout headers hdr, in metadata meta,
                       in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs) {
    apply {
    }
}

Pipeline(ingressParser(), ingress(), ingressDeparser(), egressParser(), egress(), egressDeparser()) pipe;

Switch(pipe) main;
