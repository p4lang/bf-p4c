#include <tna.p4>
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;

enum bit<16> ether_type_t {
    TPID = 0x8100,
    IPV4 = 0x0800,
    IPV6 = 0x86DD
}

enum bit<8> ip_proto_t {
    ICMP = 1,
    IGMP = 2,
    TCP = 6,
    UDP = 17
}

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    ether_type_t ether_type;
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
struct metadata {
  PortId_t port;
}
struct headers {
    ethernet_h ethernet;
    ipv4_h ipv4;
}

parser iPrsr(packet_in pkt, out headers hdr, out metadata md,
             out ingress_intrinsic_metadata_t ig_intr_md) {
  state start {
    pkt.extract(hdr.ethernet);
    pkt.extract(hdr.ipv4);
    transition accept;
  }
}

control c1(
    in headers hdr,
    in metadata meta,
    out bit<32> f1)
{

    action a1() {
        f1 = hdr.ipv4.src_addr;
    }
    // expect error@NO SOURCE: "Name 'pipe.abc' is used for multiple table objects in the P4Info message"
    // expect error@NO SOURCE: "Found 1 duplicate name\(s\) in the P4Info"
    @name(".abc")
    table t1 {
        actions = { a1 ; }
        default_action = a1();
    }

    apply {
        t1.apply();
    }
}

control ig(inout headers hdr, inout metadata md,
           in ingress_intrinsic_metadata_t ig_intr_md,
           in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
           inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
           inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
  c1() c2;
  c1() c3;
  bit<32> field1;

  apply {
    c2.apply(hdr, md, field1);
    c3.apply(hdr, md, field1);
  }
}


control iDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
  apply {
    pkt.emit(hdr);
  }
}

parser ePrsr(packet_in pkt, out headers hdr, out metadata md,
             out egress_intrinsic_metadata_t eg_intr_md) {
  state start { transition reject; }
}

control eg(inout headers hdr, inout metadata md, in egress_intrinsic_metadata_t eg_intr_md,
           in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md,
           inout egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md,
           inout egress_intrinsic_metadata_for_output_port_t eg_intr_eport_md) {
  apply {}
}

control eDprsr(packet_out pkt, inout headers hdr, in metadata md,
               in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
  apply {}
}

Pipeline(iPrsr(), ig(), iDprsr(), ePrsr(), eg(), eDprsr()) pipe;
Switch(pipe) main;
