#include <core.p4>
#include <tna.p4>       /* TOFINO1_ONLY */

header Internal_h {
  bit<8> layer2Skip;

  @padding bit<5> pad1;
  bit<1> finalOutput;
  bit<1> maybeIPv6;
  bit<1> haveUBus;

  @padding bit<4> pad2;
  bit<4> outputGroup;

  @padding bit<5> pad3;
  bit<3> priority;
}

struct metadata {}

struct headers { Internal_h internal; }

parser ParserI(packet_in pkt,
               out headers hdr,
               out metadata meta,
               out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        pkt.extract(hdr.internal);
        transition accept;
    }
}

control IngressP(
        inout headers hdr,
        inout metadata meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    action OutputPort(bit<9> port) { ig_intr_tm_md.ucast_egress_port = port; }

    table OutputMapper {
        actions = { OutputPort; }
        key = {
            hdr.internal.outputGroup : exact;
        }
        size = 16;
    }

    apply {
        OutputMapper.apply();
    }

}

control DeparserI(
        packet_out pkt,
        inout headers hdr,
        in metadata meta,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { pkt.emit(hdr); }
}

control Deconfliction(in bit<3> priority0, in bit<4> group0, in bit<3> priority1, in bit<4> group1,
                    in bit<3> priority2, in bit<4> group2, in bit<3> priority3, in bit<4> group3,
                    in bit<3> priority4, in bit<4> group4, in bit<3> priority5, in bit<4> group5,
                    in bit<4> group6, in bit<4> group7, out bit<3> priority, out bit<4> group)
{
  action Deconflict0(bit<3> pri) { priority = pri; group = group0; }
  action Deconflict1(bit<3> pri) { priority = pri; group = group1; }
  action Deconflict2(bit<3> pri) { priority = pri; group = group2; }
  action Deconflict3(bit<3> pri) { priority = pri; group = group3; }
  action Deconflict4(bit<3> pri) { priority = pri; group = group4; }
  action Deconflict5(bit<3> pri) { priority = pri; group = group5; }
  action Deconflict6(bit<3> pri) { priority = pri; group = group6; }
  action Deconflict7(bit<3> pri) { priority = pri; group = group7; }

  @hidden table deconflict {
    actions = { Deconflict0; Deconflict1; Deconflict2; Deconflict3; 
            Deconflict4; Deconflict5; Deconflict6; Deconflict7; }
    key = {
      priority0 : ternary;
      priority1 : ternary;
      priority2 : ternary;
      priority3 : ternary;
      priority4 : ternary;
      priority5 : ternary;
    }
  }

  apply {
    deconflict.apply();
  }
}

control GenericFilter(in bit<32> ip4src, in bit<32> ip4dst, in bit<128> ip6src, in bit<128> ip6dst,
                in bool transport, in bool ip4, in bool notIp, in bool fragmented,
                inout bit<3> priority, inout bit<4> group)
{
    Deconfliction() deconflict;

    bit<3> priority1 = 0; bit<4> group1 = 0; action Output1 (bit<4> gr, bit<3> pri) { group1 = gr; priority1 = pri; } 
    bit<3> priority2 = 0; bit<4> group2 = 0; action Output2 (bit<4> gr, bit<3> pri) { group2 = gr; priority2 = pri; } 
    bit<3> priority3 = 0; bit<4> group3 = 0; action Output3 (bit<4> gr, bit<3> pri) { group3 = gr; priority3 = pri; }
    bit<3> priority4 = 0; bit<4> group4 = 0; action Output4 (bit<4> gr, bit<3> pri) { group4 = gr; priority4 = pri; }
    bit<3> priority5 = 0; bit<4> group5 = 0; action Output5 (bit<4> gr, bit<3> pri) { group5 = gr; priority5 = pri; }
    bit<3> priority6 = 0; bit<4> group6 = 0; action Output6 (bit<4> gr, bit<3> pri) { group6 = gr; priority6 = pri; }
    bit<3> priority7 = 0; bit<4> group7 = 0; action Output7 (bit<4> gr, bit<3> pri) { group7 = gr; priority7 = pri; }

    table IPNextProtocol {
        actions = { Output1; }
        size = 256;
    }
    table TransportLayer {
        actions = { Output2; }
        size = 1024;
    }
    table IPFragmentation {
        actions = { Output2; }
    }
    table Source_v4 {
        actions = { Output4; }
        key = {
        ip4src : exact @name("src_addr");
        }
        size = 1024000;
    }
    table Dest_v4 {
        actions = { Output5; }
        key = {
        ip4dst : exact @name("dst_addr");
        }
        size = 1024000;
    }
    table SourceCidr_v4 {
        actions = { Output6; }
        key = {
        ip4src : lpm @name("src_addr");
        }
        size = 6144;
    }
    table DestCidr_v4 {
        actions = { Output7; }
        key = {
        ip4dst : lpm @name("dst_addr");
        }
        size = 6144;
    }
    table FiveTuple_v6 {
        actions = { Output3; }
        key = {
        ip6src : exact @name("src_addr");
        }
        size = 10240;
    }
    table Source_v6 {
        actions = { Output4; }
        key = {
        ip6src : exact @name("src_addr");
        }
        size = 32768;
    }
    table Dest_v6 {
        actions = { Output5; }
        key = {
        ip6dst : exact @name("dst_addr");
        }
        size = 32768;
    }
    table SourceCidr_v6 {
        actions = { Output6; }
        key = {
        ip6src : lpm @name("src_addr");
        }
        size = 2048;
    }
    table DestCidr_v6 {
        actions = { Output7; }
        key = {
        ip6dst : lpm @name("dst_addr");
        }
        size = 2048;
    }
    table Unknown {
        actions = { Output7; }
    }

    apply {
        FiveTuple_v6.apply();

        if(notIp)
            Output4(0,7);
        else if (ip4)
            Source_v4.apply();
        else
            Source_v6.apply();

        if(notIp)
            Output5(0,7);
        else if (ip4)
            Dest_v4.apply();
        else
            Dest_v6.apply();

        if(notIp)
            Output1(0, 7);
        else
            IPNextProtocol.apply();

        if (transport)
            TransportLayer.apply();
        else if (fragmented)
            IPFragmentation.apply();
        else
            Output2(0,7);

        if(notIp)
            Output6(0,7);
        else if (ip4)
            SourceCidr_v4.apply();
        else
            SourceCidr_v6.apply();

        if (notIp)
            Unknown.apply();
        else if (ip4)
            DestCidr_v4.apply();
        else
            DestCidr_v6.apply();

        deconflict.apply(priority, group,
            priority1, group1,
            priority2, group2,
            priority3, group3,
            priority4, group4,
            priority5, group5,
            group6, group7,
            priority, group
        );
    }
}

@flexible struct decision_meta_t {
    bool found_ipv4;
    bool not_ip;
    bool fragmented;
}

header IPv4_h {
    bit<4> version;
    bit<4> header_len;
    bit<8> tos;
    bit<16> total_len;
    bit<16> ipid;
    bit<1> reserved;
    bit<1> dontFragment;
    bit<1> moreFrags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> nextProto;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header IPv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> total_len;
    bit<8> nextProto;
    bit<8> ttl;
    bit<128> src_addr;
    bit<128> dst_addr;
}

header IpExtensionBytes_s {
    bit<160> B20;
    bit<64> B8a;
    bit<64> B8b;
    bit<32> B4;
}

header Transport_h {
  bit<16> src_port;
  bit<16> dst_port;
}

struct decision_headers_t
{
  Internal_h internal;
  IPv4_h ipv4;
  IPv6_h ipv6;
  IpExtensionBytes_s opt1;
  Transport_h transport;
}

parser ParserE(packet_in pkt,
            out decision_headers_t hdr,
            out decision_meta_t meta,
            out egress_intrinsic_metadata_t eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        pkt.extract(hdr.internal);

        transition accept;
    }
}

control CommonFilterWrapper(inout decision_headers_t hdr, in decision_meta_t meta,
                        inout bit<3> priority, inout bit<4> group)
{
  GenericFilter() filter;
  apply {
    filter.apply(hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv6.src_addr, hdr.ipv6.dst_addr,
            hdr.transport.isValid(), hdr.ipv4.isValid(), meta.not_ip, meta.fragmented, 
            priority, group
    );
  }
}

control EgressP(inout decision_headers_t hdr,
                 inout decision_meta_t meta,
                 in egress_intrinsic_metadata_t eg_intr_md,
                 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
  CommonFilterWrapper() filter;

  apply {
    filter.apply(hdr, meta, hdr.internal.priority, hdr.internal.outputGroup);
   }
}

control DeparserE(packet_out pkt,
                  inout decision_headers_t hdr,
                  in decision_meta_t meta,
                  in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply { pkt.emit(hdr); }
}

Pipeline(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;
Switch(pipe0) main;
