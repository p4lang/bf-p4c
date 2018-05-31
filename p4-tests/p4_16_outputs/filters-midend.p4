#include <core.p4>
#include <tofino.p4>
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

struct switch_header_t {
    ethernet_h ethernet;
    ipv4_h     ipv4;
    ipv6_h     ipv6;
}

struct switch_metadata_t {
}

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out switch_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
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
    @hidden action act() {
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
    }
    @hidden table tbl_act {
        actions = {
            act();
        }
        const default_action = act();
    }
    apply {
        tbl_act.apply();
    }
}

control SwitchIngress(inout switch_header_t hdr, inout switch_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    @hidden action act_0() {
        ig_intr_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
    @hidden table tbl_act_0 {
        actions = {
            act_0();
        }
        const default_action = act_0();
    }
    apply {
        tbl_act_0.apply();
    }
}

control SwitchEgress(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    bool hasExited;
    bit<1> wred_flag;
    bit<19> avg_queue;
    bit<8> tmp_1;
    bit<19> tmp_2;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_4() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name("SwitchEgress.dummy_lpf") DirectLpf<bit<19>>() dummy_lpf;
    @name("SwitchEgress.direct_wred") DirectWred<bit<19>>(8w0, 8w1) direct_wred;
    @name("SwitchEgress.set_ipv4_ecn") action set_ipv4_ecn_0() {
        hdr.ipv4.diffserv[1:0] = 2w0b11;
    }
    @name("SwitchEgress.set_ipv6_ecn") action set_ipv6_ecn_0() {
        hdr.ipv6.traffic_class[1:0] = 2w0b11;
    }
    @name("SwitchEgress.ecn_marking") table ecn_marking {
        key = {
            hdr.ipv4.isValid()    : ternary @name("hdr.ipv4.$valid$") ;
            hdr.ipv4.diffserv     : ternary @name("hdr.ipv4.diffserv") ;
            hdr.ipv6.isValid()    : ternary @name("hdr.ipv6.$valid$") ;
            hdr.ipv6.traffic_class: ternary @name("hdr.ipv6.traffic_class") ;
        }
        actions = {
            NoAction_0();
            set_ipv4_ecn_0();
            set_ipv6_ecn_0();
        }
        size = 1024;
        default_action = NoAction_0();
    }
    @name("SwitchEgress.set_wred_flag") action set_wred_flag_0() {
        tmp_1 = direct_wred.execute(eg_intr_md.enq_qdepth);
        wred_flag = (bit<1>)tmp_1;
    }
    @name("SwitchEgress.wred") table wred {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
            eg_intr_md.egress_qid : exact @name("eg_intr_md.egress_qid") ;
        }
        actions = {
            NoAction_4();
            set_wred_flag_0();
        }
        const default_action = NoAction_4();
        size = 2048;
        filters = direct_wred;
    }
    @name("SwitchEgress.set_avg_queue") action set_avg_queue_0() {
        tmp_2 = dummy_lpf.execute(eg_intr_md.deq_qdepth);
        avg_queue = tmp_2;
    }
    @name("SwitchEgress.queue") table queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            set_avg_queue_0();
            @defaultonly NoAction_5();
        }
        filters = dummy_lpf;
        default_action = NoAction_5();
    }
    @hidden action act_1() {
        hasExited = false;
        wred_flag = 1w0;
        avg_queue = 19w0;
    }
    @hidden action act_2() {
        hasExited = true;
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    apply {
        tbl_act_1.apply();
        queue.apply();
        if (avg_queue == 19w0) 
            tbl_act_2.apply();
        if (!hasExited) {
            wred.apply();
            if (wred_flag == 1w1) 
                ecn_marking.apply();
        }
    }
}

parser TofinoIngressParser_0(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w1: parse_resubmit;
            1w0: parse_port_metadata;
            default: noMatch_0;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        transition accept;
    }
    state noMatch_0 {
        verify(false, error.NoMatch);
        transition reject;
    }
}

Pipeline<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(TofinoIngressParser_0(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

