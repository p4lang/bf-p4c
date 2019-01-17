#include <core.p4>
#include <tofino.p4>

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

typedef bit<16> bd_t;
typedef bit<16> vrf_t;
typedef bit<16> nexthop_t;
typedef bit<16> ifindex_t;
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

header pktgen_tail_t {
    bit<48> src_addr;
    bit<16> ether_type;
}

struct switch_header_t {
    pktgen_timer_header_t pktgen_timer;
    pktgen_tail_t         pktgen_tail;
    ethernet_h            ethernet;
    vlan_tag_h            vlan_tag;
    ipv4_h                ipv4;
    ipv6_h                ipv6;
    tcp_h                 tcp;
    udp_h                 udp;
}

struct metadata_t {
    bool      checksum_err;
    bd_t      bd;
    vrf_t     vrf;
    nexthop_t nexthop;
    ifindex_t ingress_ifindex;
    ifindex_t egress_ifindex;
    bit<32>   max_counter;
    bit<1>    pkt_counter;
    bit<8>    flow_index;
    bit<8>    max_index;
}

parser SwitchIngressParser(packet_in pkt, out switch_header_t hdr, out metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    ethernet_h ethernet_0;
    ethernet_h tmp;
    ingress_intrinsic_metadata_t ig_intr_md_0;
    pktgen_timer_header_t hdr_0_pktgen_timer;
    pktgen_tail_t hdr_0_pktgen_tail;
    ethernet_h hdr_0_ethernet;
    vlan_tag_h hdr_0_vlan_tag;
    ipv4_h hdr_0_ipv4;
    ipv6_h hdr_0_ipv6;
    tcp_h hdr_0_tcp;
    udp_h hdr_0_udp;
    bit<112> tmp_4;
    @name("SwitchIngressParser.simple_parser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CSUM16) simple_parser_ipv4_checksum;
    state start {
        ig_intr_md_0.setInvalid();
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md_0);
        transition select(ig_intr_md_0.resubmit_flag) {
            1w1: TofinoIngressParser_parse_resubmit;
            1w0: TofinoIngressParser_parse_port_metadata;
            default: noMatch;
        }
    }
    state TofinoIngressParser_parse_resubmit {
        transition reject;
    }
    state TofinoIngressParser_parse_port_metadata {
        pkt.advance(32w64);
        ig_intr_md = ig_intr_md_0;
        tmp_4 = pkt.lookahead<bit<112>>();
        tmp.setValid();
        tmp.dst_addr = tmp_4[111:64];
        tmp.src_addr = tmp_4[63:16];
        tmp.ether_type = tmp_4[15:0];
        ethernet_0 = tmp;
        transition select(ethernet_0.ether_type) {
            16w0x9001: parse_pktgen;
            default: parse_pkt;
        }
    }
    state parse_pkt {
        hdr_0_pktgen_timer = hdr.pktgen_timer;
        hdr_0_pktgen_tail = hdr.pktgen_tail;
        hdr_0_ethernet = hdr.ethernet;
        hdr_0_vlan_tag = hdr.vlan_tag;
        hdr_0_ipv4 = hdr.ipv4;
        hdr_0_ipv6 = hdr.ipv6;
        hdr_0_tcp = hdr.tcp;
        hdr_0_udp = hdr.udp;
        pkt.extract<ethernet_h>(hdr_0_ethernet);
        transition select(hdr_0_ethernet.ether_type) {
            16w0x800: SimplePacketParser_parse_ipv4;
            default: reject;
        }
    }
    state SimplePacketParser_parse_ipv4 {
        pkt.extract<ipv4_h>(hdr_0_ipv4);
        simple_parser_ipv4_checksum.add<ipv4_h>(hdr_0_ipv4);
        transition select(hdr_0_ipv4.protocol) {
            8w6: SimplePacketParser_parse_tcp;
            8w17: SimplePacketParser_parse_udp;
            default: parse_pkt_0;
        }
    }
    state SimplePacketParser_parse_udp {
        pkt.extract<udp_h>(hdr_0_udp);
        transition parse_pkt_0;
    }
    state SimplePacketParser_parse_tcp {
        pkt.extract<tcp_h>(hdr_0_tcp);
        transition parse_pkt_0;
    }
    state parse_pkt_0 {
        hdr.pktgen_timer = hdr_0_pktgen_timer;
        hdr.pktgen_tail = hdr_0_pktgen_tail;
        hdr.ethernet = hdr_0_ethernet;
        hdr.vlan_tag = hdr_0_vlan_tag;
        hdr.ipv4 = hdr_0_ipv4;
        hdr.ipv6 = hdr_0_ipv6;
        hdr.tcp = hdr_0_tcp;
        hdr.udp = hdr_0_udp;
        transition accept;
    }
    state parse_pktgen {
        pkt.extract<pktgen_timer_header_t>(hdr.pktgen_timer);
        pkt.extract<pktgen_tail_t>(hdr.pktgen_tail);
        transition accept;
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

struct tuple_1 {
    bit<4>  field_15;
    bit<4>  field_16;
    bit<8>  field_17;
    bit<16> field_18;
    bit<16> field_19;
    bit<3>  field_20;
    bit<13> field_21;
    bit<8>  field_22;
    bit<8>  field_23;
    bit<32> field_24;
    bit<32> field_25;
}

control SwitchIngressDeparser(packet_out pkt, inout switch_header_t hdr, in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    bit<16> tmp_0;
    @name("SwitchIngressDeparser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum_1;
    @hidden action act() {
        tmp_0 = ipv4_checksum_1.update<tuple_1>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_0;
        pkt.emit<pktgen_timer_header_t>(hdr.pktgen_timer);
        pkt.emit<pktgen_tail_t>(hdr.pktgen_tail);
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<udp_h>(hdr.udp);
        pkt.emit<tcp_h>(hdr.tcp);
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

parser SwitchEgressParser(packet_in pkt, out switch_header_t hdr, out metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    egress_intrinsic_metadata_t eg_intr_md_0;
    pktgen_timer_header_t hdr_1_pktgen_timer;
    pktgen_tail_t hdr_1_pktgen_tail;
    ethernet_h hdr_1_ethernet;
    vlan_tag_h hdr_1_vlan_tag;
    ipv4_h hdr_1_ipv4;
    ipv6_h hdr_1_ipv6;
    tcp_h hdr_1_tcp;
    udp_h hdr_1_udp;
    @name("SwitchEgressParser.simple_parser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CSUM16) simple_parser_ipv4_checksum_0;
    state start {
        eg_intr_md_0.setInvalid();
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        eg_intr_md = eg_intr_md_0;
        hdr_1_pktgen_timer = hdr.pktgen_timer;
        hdr_1_pktgen_tail = hdr.pktgen_tail;
        hdr_1_ethernet = hdr.ethernet;
        hdr_1_vlan_tag = hdr.vlan_tag;
        hdr_1_ipv4 = hdr.ipv4;
        hdr_1_ipv6 = hdr.ipv6;
        hdr_1_tcp = hdr.tcp;
        hdr_1_udp = hdr.udp;
        pkt.extract<ethernet_h>(hdr_1_ethernet);
        transition select(hdr_1_ethernet.ether_type) {
            16w0x800: SimplePacketParser_parse_ipv4_0;
            default: reject;
        }
    }
    state SimplePacketParser_parse_ipv4_0 {
        pkt.extract<ipv4_h>(hdr_1_ipv4);
        simple_parser_ipv4_checksum_0.add<ipv4_h>(hdr_1_ipv4);
        transition select(hdr_1_ipv4.protocol) {
            8w6: SimplePacketParser_parse_tcp_0;
            8w17: SimplePacketParser_parse_udp_0;
            default: start_2;
        }
    }
    state SimplePacketParser_parse_udp_0 {
        pkt.extract<udp_h>(hdr_1_udp);
        transition start_2;
    }
    state SimplePacketParser_parse_tcp_0 {
        pkt.extract<tcp_h>(hdr_1_tcp);
        transition start_2;
    }
    state start_2 {
        hdr.pktgen_timer = hdr_1_pktgen_timer;
        hdr.pktgen_tail = hdr_1_pktgen_tail;
        hdr.ethernet = hdr_1_ethernet;
        hdr.vlan_tag = hdr_1_vlan_tag;
        hdr.ipv4 = hdr_1_ipv4;
        hdr.ipv6 = hdr_1_ipv6;
        hdr.tcp = hdr_1_tcp;
        hdr.udp = hdr_1_udp;
        transition accept;
    }
}

control SwitchEgressDeparser(packet_out pkt, inout switch_header_t hdr, in metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    bit<16> tmp_1;
    @name("SwitchEgressDeparser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum_2;
    @hidden action act_0() {
        tmp_1 = ipv4_checksum_2.update<tuple_1>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_1;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<udp_h>(hdr.udp);
        pkt.emit<tcp_h>(hdr.tcp);
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

control SwitchIngress(inout switch_header_t hdr, inout metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("SwitchIngress.pkt_port_counter") Counter<bit<32>, PortId_t>(32w512, CounterType_t.PACKETS_AND_BYTES) pkt_port_counter_0;
    @name("SwitchIngress.set_mgid") action set_mgid(MulticastGroupId_t mgid) {
        ig_tm_md.mcast_grp_a = mgid;
        hdr.pktgen_tail.ether_type = 16w0x800;
    }
    @name("SwitchIngress.drop") action drop() {
        ig_dprsr_md.drop_ctl = 3w0x1;
    }
    @name("SwitchIngress.forward") table forward_0 {
        actions = {
            set_mgid();
            @defaultonly NoAction_0();
        }
        default_action = NoAction_0();
    }
    @hidden action act_1() {
        pkt_port_counter_0.count(ig_intr_md.ingress_port);
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_drop {
        actions = {
            drop();
        }
        const default_action = drop();
    }
    apply {
        if (hdr.pktgen_tail.isValid()) 
            forward_0.apply();
        else {
            tbl_act_1.apply();
            tbl_drop.apply();
        }
    }
}

control SwitchEgress(inout switch_header_t hdr, inout metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    bit<1> tmp_2;
    bit<8> tmp_3;
    @name(".NoAction") action NoAction_1() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name("SwitchEgress.port_pkts_reg") Register<bit<32>, bit<32>>(32w1024) port_pkts_reg_0;
    @name("SwitchEgress.port_pkts_alu") RegisterAction<bit<32>, bit<32>, bit<1>>(port_pkts_reg_0) port_pkts_alu_0 = {
        void apply(inout bit<32> value, out bit<1> read_value) {
            if (value < eg_md.max_counter) {
                value = value + 32w1;
                read_value = 1w0;
            }
            else {
                value = 32w0;
                read_value = 1w1;
            }
        }
    };
    @name("SwitchEgress.dip_choose_reg") Register<bit<8>, bit<32>>(32w1024) dip_choose_reg_0;
    @name("SwitchEgress.dip_choose_alu") RegisterAction<bit<8>, bit<32>, bit<8>>(dip_choose_reg_0) dip_choose_alu_0 = {
        void apply(inout bit<8> value, out bit<8> read_value) {
            if (eg_md.pkt_counter == 1w1) 
                if (value < eg_md.max_index) 
                    value = value + 8w1;
                else 
                    value = 8w0;
            read_value = value;
        }
    };
    @name("SwitchEgress.set_dip") action set_dip(ipv4_addr_t ip, mac_addr_t smac, mac_addr_t dmac) {
        hdr.ipv4.dst_addr = ip;
        hdr.ethernet.dst_addr = dmac;
        hdr.ethernet.src_addr = smac;
    }
    @name("SwitchEgress.flow_set") table flow_set_0 {
        key = {
            eg_md.flow_index: exact @name("eg_md.flow_index") ;
        }
        actions = {
            set_dip();
            @defaultonly NoAction_1();
        }
        size = 256;
        default_action = NoAction_1();
    }
    @name("SwitchEgress.max_read_run") action max_read_run(bit<32> max_counter, bit<8> max_index) {
        eg_md.max_counter = max_counter;
        eg_md.max_index = max_index;
    }
    @name("SwitchEgress.max_read") table max_read_0 {
        actions = {
            max_read_run();
            @defaultonly NoAction_5();
        }
        default_action = NoAction_5();
    }
    @name("SwitchEgress.pkt_counter_get_run") action pkt_counter_get_run() {
        tmp_2 = port_pkts_alu_0.execute((bit<32>)eg_intr_md.egress_port);
        eg_md.pkt_counter = tmp_2;
    }
    @name("SwitchEgress.pkt_counter_get") table pkt_counter_get_0 {
        actions = {
            pkt_counter_get_run();
        }
        default_action = pkt_counter_get_run();
    }
    @name("SwitchEgress.flow_counter_get_run") action flow_counter_get_run() {
        tmp_3 = dip_choose_alu_0.execute((bit<32>)eg_intr_md.egress_port);
        eg_md.flow_index = tmp_3;
    }
    @name("SwitchEgress.flow_counter_get") table flow_counter_get_0 {
        actions = {
            flow_counter_get_run();
        }
        default_action = flow_counter_get_run();
    }
    apply {
        max_read_0.apply();
        pkt_counter_get_0.apply();
        flow_counter_get_0.apply();
        flow_set_0.apply();
    }
}

Pipeline<switch_header_t, metadata_t, switch_header_t, metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch<switch_header_t, metadata_t, switch_header_t, metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

