// This test is meant to exercise the attached_output.cpp for allocating
// action data bus for meter outputs. It varies the phv container size for 
// each meter output (8, 16, 32).
#include <core.p4>
#include <tna.p4>
#include "util.h"

#define ETHERTYPE_IPV4 0x0800
#define ETHERTYPE_IPV6 0x86dd
#define IP_PROTOCOLS_TCP 6
#define IP_PROTOCOLS_UDP 17


struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    ipv6_h ipv6;
}

struct switch_metadata_t {
    bit<32> qdepth_32;
    bit<7> qdepth_7;
    bit<19> qdepth_19;

    @pa_container_size("egress", "avg_queue328", 8)
    bit<32> avg_queue328;
    @pa_container_size("egress", "avg_queue3216", 16)
    bit<32> avg_queue3216;
    @pa_container_size("egress", "avg_queue3232", 32)
    bit<32> avg_queue3232;
    @pa_container_size("egress", "avg_queue198", 8)
    bit<19> avg_queue198;
    @pa_container_size("egress", "avg_queue1916", 16)
    bit<19> avg_queue1916;
    @pa_container_size("egress", "avg_queue1932", 32)
    bit<19> avg_queue1932;
    // no constraint
    bit<19> avg_queue;
    @pa_container_size("egress", "avg_queue78", 8)
    bit<7> avg_queue78;
    @pa_container_size("egress", "avg_queue716", 16)
    bit<7> avg_queue716;
    @pa_container_size("egress", "avg_queue732", 32)
    bit<7> avg_queue732;
}

parser SwitchEgressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_IPV6 : parse_ipv6;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply { }
}


control SwitchEgressDeparser(packet_out pkt,
                              inout switch_header_t hdr,
                              in switch_metadata_t eg_md,
                              in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    apply {
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
    }
}

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

control LpfRun<T>(in egress_intrinsic_metadata_t eg_intr_md, in T deq_qdepth, inout T avg_queue)() {
    DirectLpf<T>() dummy_lpf;
    action set_avg_queue() {
	avg_queue = dummy_lpf.execute(deq_qdepth);
    }
    table queue { 
	key = { 
	    eg_intr_md.egress_port : exact; 
	}
        actions = {
            set_avg_queue;
        }
        filters = dummy_lpf;
    }
    apply { queue.apply(); }
}

control SwitchEgress(
    inout switch_header_t hdr,
    inout switch_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    LpfRun<bit<32>>() lpf_32_8;
    LpfRun<bit<32>>() lpf_32_16;
    LpfRun<bit<32>>() lpf_32_32;
    LpfRun<bit<19>>() lpf_19_8;
    LpfRun<bit<19>>() lpf_19_16;
    LpfRun<bit<19>>() lpf_19_32;
    LpfRun<bit<19>>() lpf;
    LpfRun<bit<7>>() lpf_7_8;
    LpfRun<bit<7>>() lpf_7_16;
    LpfRun<bit<7>>() lpf_7_32;

    table t0 {
	key = {
	    eg_md.avg_queue328 : exact;
	    eg_md.avg_queue3216 : exact;
	    eg_md.avg_queue3232 : exact;
	    eg_md.avg_queue198 : exact;
	    eg_md.avg_queue1916 : exact;
	    eg_md.avg_queue1932 : exact;
	    eg_md.avg_queue78 : exact;
	    eg_md.avg_queue716 : exact;
	    eg_md.avg_queue732 : exact;
	    eg_md.avg_queue : exact;
	}
	actions = { NoAction; }
    }

    apply {
	lpf_32_8.apply(eg_intr_md, eg_md.qdepth_32, eg_md.avg_queue328);
	lpf_32_16.apply(eg_intr_md, eg_md.qdepth_32, eg_md.avg_queue3216);
	lpf_32_32.apply(eg_intr_md, eg_md.qdepth_32, eg_md.avg_queue3232);
	lpf_19_8.apply(eg_intr_md, eg_md.qdepth_19, eg_md.avg_queue198);
	lpf_19_16.apply(eg_intr_md, eg_md.qdepth_19, eg_md.avg_queue1916);
	lpf_19_32.apply(eg_intr_md, eg_md.qdepth_19, eg_md.avg_queue1932);
	lpf_7_8.apply(eg_intr_md, eg_md.qdepth_7, eg_md.avg_queue78);
	lpf_7_16.apply(eg_intr_md, eg_md.qdepth_7, eg_md.avg_queue716);
	lpf_7_32.apply(eg_intr_md, eg_md.qdepth_7, eg_md.avg_queue732);
	lpf.apply(eg_intr_md, eg_md.qdepth_19, eg_md.avg_queue);
	t0.apply();
    }
}

Pipeline(EmptyIngressParser<switch_header_t, switch_metadata_t>(),
       SwitchIngress(),
       SwitchIngressDeparser(),
       SwitchEgressParser(),
       SwitchEgress(),
       SwitchEgressDeparser()) pipe0;
Switch(pipe0) main;
