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
    bit<19> qdepth_19;
    @pa_container_size("egress" , "avg_queue198" , 8) 
    bit<19> avg_queue198;
    @pa_container_size("egress" , "avg_queue1916" , 16) 
    bit<19> avg_queue1916;
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

control SwitchEgress(inout switch_header_t hdr, inout switch_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_4() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name("SwitchEgress.dummy_lpf") Lpf<bit<19>, bit<1>>(32w2) dummy_lpf_0;
    bit<19> lpf_19_8_tmp;
    @name("SwitchEgress.lpf_19_8.set_avg_queue") action lpf_19_8_set_avg_queue_0(bit<1> idx) {
        lpf_19_8_tmp = dummy_lpf_0.execute(eg_md.qdepth_19, idx);
        eg_md.avg_queue198 = lpf_19_8_tmp;
    }
    @name("SwitchEgress.lpf_19_8.queue") table lpf_19_8_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_19_8_set_avg_queue_0();
            @defaultonly NoAction_0();
        }
        filters = dummy_lpf_0;
        default_action = NoAction_0();
    }
    bit<19> lpf_19_16_tmp;
    @name("SwitchEgress.lpf_19_16.set_avg_queue") action lpf_19_16_set_avg_queue_0(bit<1> idx) {
        lpf_19_16_tmp = dummy_lpf_0.execute(eg_md.qdepth_19, idx);
        eg_md.avg_queue1916 = lpf_19_16_tmp;
    }
    @name("SwitchEgress.lpf_19_16.queue") table lpf_19_16_queue {
        key = {
            eg_intr_md.egress_port: exact @name("eg_intr_md.egress_port") ;
        }
        actions = {
            lpf_19_16_set_avg_queue_0();
            @defaultonly NoAction_4();
        }
        filters = dummy_lpf_0;
        default_action = NoAction_4();
    }
    @name("SwitchEgress.t0") table t0_0 {
        key = {
            eg_md.avg_queue198 : exact @name("eg_md.avg_queue198") ;
            eg_md.avg_queue1916: exact @name("eg_md.avg_queue1916") ;
        }
        actions = {
            NoAction_5();
        }
        default_action = NoAction_5();
    }
    apply {
        if (eg_intr_md.egress_port == 9w0) 
            lpf_19_8_queue.apply();
        else 
            lpf_19_16_queue.apply();
        t0_0.apply();
    }
}

parser EmptyIngressParser_0(packet_in pkt, out switch_header_t hdr, out switch_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
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
        transition start_0;
    }
    state start_0 {
        ig_intr_md = ig_intr_md_0;
        transition accept;
    }
}

Pipeline<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t>(EmptyIngressParser_0(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe0;

Switch<switch_header_t, switch_metadata_t, switch_header_t, switch_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

