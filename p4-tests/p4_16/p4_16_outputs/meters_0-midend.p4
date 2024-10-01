#include <tna.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
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
    bit<32> qdepth_32;
    bit<7>  qdepth_7;
    bit<19> qdepth_19;
    @pa_container_size("egress" , "avg_queue328" , 8)
    bit<32> avg_queue328;
    @pa_container_size("egress" , "avg_queue3216" , 16)
    bit<32> avg_queue3216;
    @pa_container_size("egress" , "avg_queue3232" , 32)
    bit<32> avg_queue3232;
    @pa_container_size("egress" , "avg_queue198" , 8)
    bit<19> avg_queue198;
    @pa_container_size("egress" , "avg_queue1916" , 16)
    bit<19> avg_queue1916;
    @pa_container_size("egress" , "avg_queue1932" , 32)
    bit<19> avg_queue1932;
    bit<19> avg_queue;
    @pa_container_size("egress" , "avg_queue78" , 8)
    bit<7>  avg_queue78;
    @pa_container_size("egress" , "avg_queue716" , 16)
    bit<7>  avg_queue716;
    @pa_container_size("egress" , "avg_queue732" , 32)
    bit<7>  avg_queue732;
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
    bit<32> lpf_32_8_tmp;
    bit<32> lpf_32_16_tmp;
    bit<32> lpf_32_32_tmp;
    bit<19> lpf_19_8_tmp;
    bit<19> lpf_19_16_tmp;
    bit<19> lpf_19_32_tmp;
    bit<19> lpf_tmp;
    bit<7> lpf_7_8_tmp;
    bit<7> lpf_7_16_tmp;
    bit<7> lpf_7_32_tmp;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_12() {
    }
    @name(".NoAction") action NoAction_13() {
    }
    @name(".NoAction") action NoAction_14() {
    }
    @name(".NoAction") action NoAction_15() {
    }
    @name(".NoAction") action NoAction_16() {
    }
    @name(".NoAction") action NoAction_17() {
    }
    @name(".NoAction") action NoAction_18() {
    }
    @name(".NoAction") action NoAction_19() {
    }
    @name(".NoAction") action NoAction_20() {
    }
    @name(".NoAction") action NoAction_21() {
    }
    @name("SwitchEgress.lpf_32_8.dummy_lpf") DirectLpf<bit<32>>() lpf_32_8_dummy_lpf;
    @name("SwitchEgress.lpf_32_8.set_avg_queue") action lpf_32_8_set_avg_queue_0() {
        lpf_32_8_tmp = lpf_32_8_dummy_lpf.execute(eg_md.qdepth_32);
        eg_md.avg_queue328 = lpf_32_8_tmp;
    }
    @name("SwitchEgress.lpf_32_8.queue") table lpf_32_8_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_32_8_set_avg_queue_0();
            @defaultonly NoAction_0();
        }
        filters = lpf_32_8_dummy_lpf;
        default_action = NoAction_0();
    }
    @name("SwitchEgress.lpf_32_16.dummy_lpf") DirectLpf<bit<32>>() lpf_32_16_dummy_lpf;
    @name("SwitchEgress.lpf_32_16.set_avg_queue") action lpf_32_16_set_avg_queue_0() {
        lpf_32_16_tmp = lpf_32_16_dummy_lpf.execute(eg_md.qdepth_32);
        eg_md.avg_queue3216 = lpf_32_16_tmp;
    }
    @name("SwitchEgress.lpf_32_16.queue") table lpf_32_16_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_32_16_set_avg_queue_0();
            @defaultonly NoAction_12();
        }
        filters = lpf_32_16_dummy_lpf;
        default_action = NoAction_12();
    }
    @name("SwitchEgress.lpf_32_32.dummy_lpf") DirectLpf<bit<32>>() lpf_32_32_dummy_lpf;
    @name("SwitchEgress.lpf_32_32.set_avg_queue") action lpf_32_32_set_avg_queue_0() {
        lpf_32_32_tmp = lpf_32_32_dummy_lpf.execute(eg_md.qdepth_32);
        eg_md.avg_queue3232 = lpf_32_32_tmp;
    }
    @name("SwitchEgress.lpf_32_32.queue") table lpf_32_32_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_32_32_set_avg_queue_0();
            @defaultonly NoAction_13();
        }
        filters = lpf_32_32_dummy_lpf;
        default_action = NoAction_13();
    }
    @name("SwitchEgress.lpf_19_8.dummy_lpf") DirectLpf<bit<19>>() lpf_19_8_dummy_lpf;
    @name("SwitchEgress.lpf_19_8.set_avg_queue") action lpf_19_8_set_avg_queue_0() {
        lpf_19_8_tmp = lpf_19_8_dummy_lpf.execute(eg_md.qdepth_19);
        eg_md.avg_queue198 = lpf_19_8_tmp;
    }
    @name("SwitchEgress.lpf_19_8.queue") table lpf_19_8_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_19_8_set_avg_queue_0();
            @defaultonly NoAction_14();
        }
        filters = lpf_19_8_dummy_lpf;
        default_action = NoAction_14();
    }
    @name("SwitchEgress.lpf_19_16.dummy_lpf") DirectLpf<bit<19>>() lpf_19_16_dummy_lpf;
    @name("SwitchEgress.lpf_19_16.set_avg_queue") action lpf_19_16_set_avg_queue_0() {
        lpf_19_16_tmp = lpf_19_16_dummy_lpf.execute(eg_md.qdepth_19);
        eg_md.avg_queue1916 = lpf_19_16_tmp;
    }
    @name("SwitchEgress.lpf_19_16.queue") table lpf_19_16_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_19_16_set_avg_queue_0();
            @defaultonly NoAction_15();
        }
        filters = lpf_19_16_dummy_lpf;
        default_action = NoAction_15();
    }
    @name("SwitchEgress.lpf_19_32.dummy_lpf") DirectLpf<bit<19>>() lpf_19_32_dummy_lpf;
    @name("SwitchEgress.lpf_19_32.set_avg_queue") action lpf_19_32_set_avg_queue_0() {
        lpf_19_32_tmp = lpf_19_32_dummy_lpf.execute(eg_md.qdepth_19);
        eg_md.avg_queue1932 = lpf_19_32_tmp;
    }
    @name("SwitchEgress.lpf_19_32.queue") table lpf_19_32_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_19_32_set_avg_queue_0();
            @defaultonly NoAction_16();
        }
        filters = lpf_19_32_dummy_lpf;
        default_action = NoAction_16();
    }
    @name("SwitchEgress.lpf.dummy_lpf") DirectLpf<bit<19>>() lpf_dummy_lpf;
    @name("SwitchEgress.lpf.set_avg_queue") action lpf_set_avg_queue_0() {
        lpf_tmp = lpf_dummy_lpf.execute(eg_md.qdepth_19);
        eg_md.avg_queue = lpf_tmp;
    }
    @name("SwitchEgress.lpf.queue") table lpf_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_set_avg_queue_0();
            @defaultonly NoAction_17();
        }
        filters = lpf_dummy_lpf;
        default_action = NoAction_17();
    }
    @name("SwitchEgress.lpf_7_8.dummy_lpf") DirectLpf<bit<7>>() lpf_7_8_dummy_lpf;
    @name("SwitchEgress.lpf_7_8.set_avg_queue") action lpf_7_8_set_avg_queue_0() {
        lpf_7_8_tmp = lpf_7_8_dummy_lpf.execute(eg_md.qdepth_7);
        eg_md.avg_queue78 = lpf_7_8_tmp;
    }
    @name("SwitchEgress.lpf_7_8.queue") table lpf_7_8_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_7_8_set_avg_queue_0();
            @defaultonly NoAction_18();
        }
        filters = lpf_7_8_dummy_lpf;
        default_action = NoAction_18();
    }
    @name("SwitchEgress.lpf_7_16.dummy_lpf") DirectLpf<bit<7>>() lpf_7_16_dummy_lpf;
    @name("SwitchEgress.lpf_7_16.set_avg_queue") action lpf_7_16_set_avg_queue_0() {
        lpf_7_16_tmp = lpf_7_16_dummy_lpf.execute(eg_md.qdepth_7);
        eg_md.avg_queue716 = lpf_7_16_tmp;
    }
    @name("SwitchEgress.lpf_7_16.queue") table lpf_7_16_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_7_16_set_avg_queue_0();
            @defaultonly NoAction_19();
        }
        filters = lpf_7_16_dummy_lpf;
        default_action = NoAction_19();
    }
    @name("SwitchEgress.lpf_7_32.dummy_lpf") DirectLpf<bit<7>>() lpf_7_32_dummy_lpf;
    @name("SwitchEgress.lpf_7_32.set_avg_queue") action lpf_7_32_set_avg_queue_0() {
        lpf_7_32_tmp = lpf_7_32_dummy_lpf.execute(eg_md.qdepth_7);
        eg_md.avg_queue732 = lpf_7_32_tmp;
    }
    @name("SwitchEgress.lpf_7_32.queue") table lpf_7_32_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_7_32_set_avg_queue_0();
            @defaultonly NoAction_20();
        }
        filters = lpf_7_32_dummy_lpf;
        default_action = NoAction_20();
    }
    @name("SwitchEgress.t0") table t0_0 {
        key = {
            eg_md.avg_queue328 : exact @name("eg_md.avg_queue328") ;
            eg_md.avg_queue3216: exact @name("eg_md.avg_queue3216") ;
            eg_md.avg_queue3232: exact @name("eg_md.avg_queue3232") ;
            eg_md.avg_queue198 : exact @name("eg_md.avg_queue198") ;
            eg_md.avg_queue1916: exact @name("eg_md.avg_queue1916") ;
            eg_md.avg_queue1932: exact @name("eg_md.avg_queue1932") ;
            eg_md.avg_queue78  : exact @name("eg_md.avg_queue78") ;
            eg_md.avg_queue716 : exact @name("eg_md.avg_queue716") ;
            eg_md.avg_queue732 : exact @name("eg_md.avg_queue732") ;
            eg_md.avg_queue    : exact @name("eg_md.avg_queue") ;
        }
        actions = {
            NoAction_21();
        }
        default_action = NoAction_21();
    }
    apply {
        lpf_32_8_queue.apply();
        lpf_32_16_queue.apply();
        lpf_32_32_queue.apply();
        lpf_19_8_queue.apply();
        lpf_19_16_queue.apply();
        lpf_19_32_queue.apply();
        lpf_7_8_queue.apply();
        lpf_7_16_queue.apply();
        lpf_7_32_queue.apply();
        lpf_queue.apply();
        t0_0.apply();
    }
}

parser EmptyIngressParser_0(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_intrinsic_metadata_t ig_intr_md_0;
    state start {
        ig_intr_md_0.setInvalid();
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md_0);
        transition select(ig_intr_md_0.resubmit_flag) {
            1w1: TofinoIngressParser_parse_resubmit;
            1w0: TofinoIngressParser_parse_port_metadata;
            default: noMatch_0;
        }
    }
    state TofinoIngressParser_parse_resubmit {
        transition reject;
    }
    state TofinoIngressParser_parse_port_metadata {
        ig_intr_md = ig_intr_md_0;
        transition accept;
    }
    state noMatch_0 {
        verify(false, error.NoMatch);
        transition reject;
    }
}

Pipeline<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(EmptyIngressParser_0(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;
