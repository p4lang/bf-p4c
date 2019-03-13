#include <tna.p4>

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header jeju_t {
    bit<32> da;
    bit<32> db;
}

struct headers_t {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    jeju_t     jeju;
}

struct user_metadata_t {
}

struct pvs_data {
    bit<16> f16;
}

parser IgCPUParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
	    16w5 : parse_jeju;
	}
    }

    state parse_jeju {
	pkt.extract(hdr.jeju);
	transition accept;
    }
}

parser IgNetworkParser(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w4 : parse_ipv4;
	}
    }

    state parse_ipv4 {
	pkt.extract(hdr.ipv4);
	transition accept;
    }
}

parser IgCPUParser2(
    packet_in pkt,
    out headers_t hdr,
    out user_metadata_t md,
    out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
	    16w5 : parse_jeju;
	}
    }

    state parse_jeju {
	pkt.extract(hdr.jeju);
	transition accept;
    }
}

parser EgCPUParser(
    packet_in pkt, 
    out headers_t hdr,
    out user_metadata_t md,
    out egress_intrinsic_metadata_t ig_intr_md) {
  value_set<pvs_data>(4) vs;
  state start {
    pkt.extract(hdr.ethernet);
    transition select(hdr.ethernet.etherType) {
        16w4 : reject;
        vs   : accept;
    // transition accept;
    }
  }
}

control SwitchIngress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    action m_action() {
    }

    action nop() {
    }
    table t {
        actions = { nop; m_action; }
        key = { hdr.ethernet.etherType: exact; }
    }
    apply {
        t.apply();
    }
}

control SwitchIngressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in user_metadata_t meta,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

control SwitchEgress(
    inout headers_t hdr,
    inout user_metadata_t md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

control SwitchEgressDeparser(
    packet_out pkt,
    inout headers_t hdr,
    in user_metadata_t md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr);
    }
}

@default_portmap(17, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16})
IngressParsers(IgCPUParser(), IgNetworkParser()) ig_pipe0;

@default_portmap({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17})
EgressParsers(EgCPUParser()) eg_pipe0;

@default_portmap({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17})
IngressParsers(IgCPUParser2()) ig_pipe1;

@default_portmap({0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17})
EgressParsers(EgCPUParser()) eg_pipe1;

MultiParserPipeline(ig_pipe0, SwitchIngress(), SwitchIngressDeparser(),
         	    eg_pipe0, SwitchEgress(), SwitchEgressDeparser()) pipe0;

MultiParserPipeline(ig_pipe1, SwitchIngress(), SwitchIngressDeparser(),
         	    eg_pipe1, SwitchEgress(), SwitchEgressDeparser()) pipe1;

MultiParserSwitch(pipe0, pipe1) main;
