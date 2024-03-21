#include <core.p4>
#include <tna.p4>

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(64);
        transition accept;
    }
}
parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}
control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}
control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}
header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}
header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
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
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}
header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
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
header icmp_h {
    bit<8> type_;
    bit<8> code;
    bit<16> hdr_checksum;
}
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}
struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h ipv4;
    ipv6_h ipv6;
    tcp_h tcp;
    udp_h udp;
}
parser SimplePacketParser(packet_in pkt, inout header_t hdr) {
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.next_hdr) {
            IP_PROTOCOLS_TCP : parse_tcp;
            IP_PROTOCOLS_UDP : parse_udp;
            default : accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
}
struct ingress_metadata_t {
};
struct egress_metadata_t {
}
struct pair {
 bit<32> first;
 bit<32> second;
};
control npb_ing_flowtable_v4 (
 in header_t hdr,
 in ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr
) {
 bit<32> flowtable_hash;
 Register<pair, bit<32>>(32w1024) test_reg;
 RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_action = {
  void apply(
   inout pair value,
   out bit<32> read_value
  ){
   read_value = value.second;
   value.first = (bit<32>)flowtable_hash[31:16];
   value.second = value.first + 100;
  }
 };
 Hash<bit<32>>(HashAlgorithm_t.CRC32) h;
 apply {
  flowtable_hash = h.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port});
  test_reg_action.execute((bit<32>)flowtable_hash[15:0]);
 }
}
parser SwitchIngressParser(
 packet_in pkt,
 out header_t hdr,
 out ingress_metadata_t ig_md,
 out ingress_intrinsic_metadata_t ig_intr_md
) {
 TofinoIngressParser() tofino_parser;
 state start {
  tofino_parser.apply(pkt, ig_intr_md);
  transition parse_ethernet;
 }
 state parse_ethernet {
  pkt.extract(hdr.ethernet);
  transition parse_ipv4;
 }
 state parse_ipv4 {
  pkt.extract(hdr.ipv4);
  transition accept;
 }
}
control SwitchIngress(
 inout header_t hdr,
 inout ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
 apply {
  npb_ing_flowtable_v4.apply(
   hdr,
   ig_md,
   ig_intr_md,
   ig_intr_md_from_prsr
  );
 }
}
control SwitchIngressDeparser(
 packet_out pkt,
 inout header_t hdr,
 in ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md
) {
 Checksum() ipv4_checksum;
 apply {
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
   hdr.ipv4.dst_addr});
   pkt.emit(hdr.ethernet);
   pkt.emit(hdr.vlan_tag);
   pkt.emit(hdr.ipv4);
   pkt.emit(hdr.ipv6);
   pkt.emit(hdr.tcp);
   pkt.emit(hdr.udp);
 }
}
parser SwitchEgressParser(
 packet_in pkt,
 out header_t hdr,
 out egress_metadata_t eg_md,
 out egress_intrinsic_metadata_t eg_intr_md
) {
 TofinoEgressParser() tofino_parser;
 state start {
  tofino_parser.apply(pkt, eg_intr_md);
  transition parse_ethernet;
 }
 state parse_ethernet {
  pkt.extract(hdr.ethernet);
  transition parse_ipv4;
 }
 state parse_ipv4 {
  pkt.extract(hdr.ipv4);
  transition accept;
 }
}
control SwitchEgress(
 inout header_t hdr,
 inout egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 apply {
 }
}
control SwitchEgressDeparser(
 packet_out pkt,
 inout header_t hdr,
 in egress_metadata_t eg_md,
 in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md
) {
 Checksum() ipv4_checksum;
 apply {
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
   hdr.ipv4.dst_addr});
   pkt.emit(hdr.ethernet);
   pkt.emit(hdr.vlan_tag);
   pkt.emit(hdr.ipv4);
   pkt.emit(hdr.ipv6);
   pkt.emit(hdr.tcp);
   pkt.emit(hdr.udp);
 }
}
Pipeline(
 SwitchIngressParser (),
 SwitchIngress (),
 SwitchIngressDeparser(),
 SwitchEgressParser (),
 SwitchEgress (),
 SwitchEgressDeparser ()
) pipe;
Switch(pipe) main;
