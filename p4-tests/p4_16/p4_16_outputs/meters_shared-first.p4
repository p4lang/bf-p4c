#include <tna.p4>

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
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

parser TofinoIngressParser(packet_in pkt, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w1: parse_resubmit;
            1w0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        transition accept;
    }
}

parser TofinoEgressParser(packet_in pkt, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition accept;
    }
}

parser EmptyIngressParser<H, M>(packet_in pkt, out H hdr, out M ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;
    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition accept;
    }
}

parser EmptyEgressParser<H, M>(packet_in pkt, out H hdr, out M eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    TofinoEgressParser() tofino_parser;
    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(packet_out pkt, inout H hdr, in M eg_md, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {
    }
}

control EmptyEgress<H, M>(inout H hdr, inout M eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h     ipv4;
    ipv6_h     ipv6;
}

struct switch_metadata_t {
    bit<19> qdepth_19;
    @pa_container_size("egress" , "avg_queue198" , 8)
    bit<19> avg_queue198;
    @pa_container_size("egress" , "avg_queue1916" , 16)
    bit<19> avg_queue1916;
}

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition parse_ethernet;
    }
    state parse_ethernet {
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: reject;
        }
    }
    state parse_ipv4 {
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition accept;
    }
    state parse_ipv6 {
        pkt.extract<ipv6_h>(hdr.ipv6);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout switch_header_t hdr, in switch_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    apply {
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control LpfRun<T, I>(in egress_intrinsic_metadata_t eg_intr_md, in T deq_qdepth, inout T avg_queue)(Lpf<T, I> dummy_lpf) {
    action set_avg_queue(I idx) {
        avg_queue = dummy_lpf.execute(deq_qdepth, idx);
    }
    table queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            set_avg_queue();
            @defaultonly NoAction();
        }
        filters = dummy_lpf;
        default_action = NoAction();
    }
    apply {
        queue.apply();
    }
}

control SwitchEgress(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    Lpf<bit<19>, bit<1>>(32w2) dummy_lpf;
    LpfRun<bit<19>, bit<1>>(dummy_lpf) lpf_19_8;
    LpfRun<bit<19>, bit<1>>(dummy_lpf) lpf_19_16;
    table t0 {
        key = {
            eg_md.avg_queue198 : exact @name("eg_md.avg_queue198") ;
            eg_md.avg_queue1916: exact @name("eg_md.avg_queue1916") ;
        }
        actions = {
            NoAction();
        }
        default_action = NoAction();
    }
    apply {
        if (eg_intr_md.egress_port == 9w0)
            lpf_19_8.apply(eg_intr_md, eg_md.qdepth_19, eg_md.avg_queue198);
        else
            lpf_19_16.apply(eg_intr_md, eg_md.qdepth_19, eg_md.avg_queue1916);
        t0.apply();
    }
}

Pipeline<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(EmptyIngressParser<switch_header_t, switch_metadata_t>(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
