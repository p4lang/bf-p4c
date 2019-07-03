#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header vlan_tag_h {
    bit<3>    pcp;
    bit<1>    cfi;
    vlan_id_t vid;
    bit<16>   ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_len;
    bit<8>      next_hdr;
    bit<8>      hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4>  data_offset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> hdr_lenght;
    bit<16> checksum;
}

header icmp_h {
    bit<8>  type_;
    bit<8>  code;
    bit<16> hdr_checksum;
}

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8>  hw_addr_len;
    bit<8>  proto_addr_len;
    bit<16> opcode;
}

header ipv6_srh_h {
    bit<8>  next_hdr;
    bit<8>  hdr_ext_len;
    bit<8>  routing_type;
    bit<8>  seg_left;
    bit<8>  last_entry;
    bit<8>  flags;
    bit<16> tag;
}

header vxlan_h {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

header gre_h {
    bit<1>  C;
    bit<1>  R;
    bit<1>  K;
    bit<1>  S;
    bit<1>  s;
    bit<3>  recurse;
    bit<5>  flags;
    bit<3>  version;
    bit<16> proto;
}

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h     ipv4;
    ipv6_h     ipv6;
    tcp_h      tcp;
    udp_h      udp;
}

struct ingress_metadata_t {
}

struct egress_metadata_t {
}

parser SwitchIngressParser(packet_in pkt, out header_t hdr, out ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_intrinsic_metadata_t ig_intr_md_0;
    state start {
        ig_intr_md_0.setInvalid();
        transition TofinoIngressParser_start;
    }
    state TofinoIngressParser_start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md_0);
        transition select(ig_intr_md_0.resubmit_flag) {
            1w1: TofinoIngressParser_parse_resubmit;
            1w0: TofinoIngressParser_parse_port_metadata;
        }
    }
    state TofinoIngressParser_parse_resubmit {
        transition reject;
    }
    state TofinoIngressParser_parse_port_metadata {
        pkt.advance(32w64);
        transition start_0;
    }
    state start_0 {
        ig_intr_md = ig_intr_md_0;
        pkt.extract<ethernet_h>(hdr.ethernet);
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition accept;
    }
}

control SwitchIngress(inout header_t hdr, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    bit<32> npb_ing_flowtable_v4_flowtable_hash;
    bit<32> npb_ing_flowtable_v4_return_value;
    bit<32> npb_ing_flowtable_v4_tmp;
    bit<32> npb_ing_flowtable_v4_tmp_0;
    @name("SwitchIngress.npb_ing_flowtable_v4.test_reg") Register<bit<32>, bit<32>>(32w1024) npb_ing_flowtable_v4_test_reg;
    @name("SwitchIngress.npb_ing_flowtable_v4.test_reg_action") RegisterAction<bit<32>, bit<32>, bit<32>>(npb_ing_flowtable_v4_test_reg) npb_ing_flowtable_v4_test_reg_action = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            read_value = value;
            value = (bit<16>)ig_intr_md.ingress_port ++ npb_ing_flowtable_v4_flowtable_hash[31:16];
        }
    };
    @name("SwitchIngress.npb_ing_flowtable_v4.h") Hash<bit<32>>(HashAlgorithm_t.CRC32) npb_ing_flowtable_v4_h;
    apply {
        npb_ing_flowtable_v4_tmp = npb_ing_flowtable_v4_h.get<tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>>({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port });
        npb_ing_flowtable_v4_flowtable_hash = npb_ing_flowtable_v4_tmp;
        npb_ing_flowtable_v4_tmp_0 = npb_ing_flowtable_v4_test_reg_action.execute(npb_ing_flowtable_v4_flowtable_hash);
        npb_ing_flowtable_v4_return_value = npb_ing_flowtable_v4_tmp_0;
        if (npb_ing_flowtable_v4_return_value == (bit<16>)ig_intr_md.ingress_port ++ npb_ing_flowtable_v4_flowtable_hash[31:16]) 
            ig_intr_md_for_dprsr.drop_ctl = 3w0x1;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    bit<16> tmp_1;
    @name("SwitchIngressDeparser.ipv4_checksum") Checksum(HashAlgorithm_t.CRC16) ipv4_checksum_0;
    apply {
        tmp_1 = ipv4_checksum_0.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_1;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<vlan_tag_h>(hdr.vlan_tag);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
        pkt.emit<tcp_h>(hdr.tcp);
        pkt.emit<udp_h>(hdr.udp);
    }
}

parser SwitchEgressParser(packet_in pkt, out header_t hdr, out egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    egress_intrinsic_metadata_t eg_intr_md_0;
    state start {
        eg_intr_md_0.setInvalid();
        transition TofinoEgressParser_start;
    }
    state TofinoEgressParser_start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        transition start_1;
    }
    state start_1 {
        eg_intr_md = eg_intr_md_0;
        pkt.extract<ethernet_h>(hdr.ethernet);
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition accept;
    }
}

control SwitchEgress(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout header_t hdr, in egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    bit<16> tmp_2;
    @name("SwitchEgressDeparser.ipv4_checksum") Checksum(HashAlgorithm_t.CRC16) ipv4_checksum_1;
    apply {
        tmp_2 = ipv4_checksum_1.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_2;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<vlan_tag_h>(hdr.vlan_tag);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
        pkt.emit<tcp_h>(hdr.tcp);
        pkt.emit<udp_h>(hdr.udp);
    }
}

Pipeline<header_t, ingress_metadata_t, header_t, egress_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch<header_t, ingress_metadata_t, header_t, egress_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

