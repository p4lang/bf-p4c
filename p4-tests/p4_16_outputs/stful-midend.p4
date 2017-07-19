#include <core.p4>
#include <tofino.p4>

typedef bit<16> ifindex_t;
typedef bit<16> nexthop_t;
typedef bit<48> mac_addr_t;
typedef bit<30> ip_addr_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header ipv4_h {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   tota_lLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   frag_offset;
    bit<8>    ttl;
    bit<8>    proto;
    bit<16>   hdr_checksum;
    ip_addr_t src_addr;
    ip_addr_t dst_addr;
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

header pktgen_generic_h {
    bit<3>  _pad0;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  key_msb;
    bit<16> batch_id;
    bit<16> packet_id;
}

header recirc_h {
    bit<4>  tag;
    bit<4>  rtype;
    bit<8>  pad;
    bit<16> key;
}

struct user_metadata_t {
    ifindex_t ifindex;
    ifindex_t eg_ifindex;
    bit<48>   timestamp;
    bit<32>   offset;
    bool      bf_temp;
    bit<8>    flowlet_hash_input;
    nexthop_t nhop_id;
    bit<17>   lag_tbl_bit_index;
    bit<17>   ecmp_tbl_bit_index;
    bool      pkt_gen_pkt;
    bool      recirc_pkt;
    bit<1>    one_bit_val_1;
    bit<1>    one_bit_val_2;
}

struct headers_t {
    recirc_h                  recirc_hdr;
    pktgen_generic_h          pktgen_generic;
    pktgen_recirc_header_t    pktgen_recirc;
    pktgen_port_down_header_t pktgen_port_down;
    pktgen_timer_header_t     pktgen_timer;
    ethernet_h                ethernet;
    ipv4_h                    ipv4;
    tcp_h                     tcp;
    udp_h                     udp;
}

register<bit<1>, bit<18>>(18w262143) bloom_filter_1;
register<bit<1>, bit<18>>(18w262143) bloom_filter_2;
register<bit<1>, bit<18>>(18w262143) bloom_filter_3;
register<bit<1>, bit<17>>(17w131071) lag_reg;
register<bit<1>, bit<29>>(29w131072) next_hop_ecmp_reg;
parser SwitchIngressParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    bit<16> tmp;
    recirc_h hdr_2_recirc_hdr;
    pktgen_generic_h hdr_2_pktgen_generic;
    pktgen_recirc_header_t hdr_2_pktgen_recirc;
    pktgen_port_down_header_t hdr_2_pktgen_port_down;
    pktgen_timer_header_t hdr_2_pktgen_timer;
    ethernet_h hdr_2_ethernet;
    ipv4_h hdr_2_ipv4;
    tcp_h hdr_2_tcp;
    udp_h hdr_2_udp;
    user_metadata_t md_2;
    bit<8> packet_parser_tmp_1;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select((bit<1>)(bool)ig_intr_md.resubmit_flag) {
            1w1: reject;
            1w0: parse_per_port_metadata;
            default: noMatch;
        }
    }
    state parse_per_port_metadata {
        tmp = pkt.lookahead<ifindex_t>();
        md.ifindex = tmp;
        pkt.advance(32w64);
        hdr_2_recirc_hdr = hdr.recirc_hdr;
        hdr_2_pktgen_generic = hdr.pktgen_generic;
        hdr_2_pktgen_recirc = hdr.pktgen_recirc;
        hdr_2_pktgen_port_down = hdr.pktgen_port_down;
        hdr_2_pktgen_timer = hdr.pktgen_timer;
        hdr_2_ethernet = hdr.ethernet;
        hdr_2_ipv4 = hdr.ipv4;
        hdr_2_tcp = hdr.tcp;
        hdr_2_udp = hdr.udp;
        md_2.ifindex = md.ifindex;
        md_2.eg_ifindex = md.eg_ifindex;
        md_2.timestamp = md.timestamp;
        md_2.offset = md.offset;
        md_2.bf_temp = md.bf_temp;
        md_2.flowlet_hash_input = md.flowlet_hash_input;
        md_2.nhop_id = md.nhop_id;
        md_2.lag_tbl_bit_index = md.lag_tbl_bit_index;
        md_2.ecmp_tbl_bit_index = md.ecmp_tbl_bit_index;
        md_2.pkt_gen_pkt = md.pkt_gen_pkt;
        md_2.recirc_pkt = md.recirc_pkt;
        md_2.one_bit_val_1 = md.one_bit_val_1;
        md_2.one_bit_val_2 = md.one_bit_val_2;
        packet_parser_tmp_1 = pkt.lookahead<bit<8>>();
        transition select(packet_parser_tmp_1) {
            8w0x1 &&& 8w0xe7: PacketParser_parse_pktgen_port_down;
            8w0x2 &&& 8w0xe7: PacketParser_parse_pktgen_recirc;
            8w0x3 &&& 8w0xe7: PacketParser_parse_pktgen_hw_clr;
            8w0xf0 &&& 8w0xf0: PacketParser_parse_recirc_pkt;
            default: PacketParser_parse_ethernet;
        }
    }
    state PacketParser_parse_recirc_pkt {
        pkt.extract<recirc_h>(hdr_2_recirc_hdr);
        md_2.recirc_pkt = true;
        transition select(hdr_2_recirc_hdr.rtype) {
            4w1: PacketParser_parse_pktgen_port_down;
            default: parse_per_port_metadata_0;
        }
    }
    state PacketParser_parse_pktgen_recirc {
        pkt.extract<pktgen_recirc_header_t>(hdr_2_pktgen_recirc);
        md_2.pkt_gen_pkt = true;
        transition parse_per_port_metadata_0;
    }
    state PacketParser_parse_pktgen_port_down {
        pkt.extract<pktgen_port_down_header_t>(hdr_2_pktgen_port_down);
        md_2.pkt_gen_pkt = true;
        transition parse_per_port_metadata_0;
    }
    state PacketParser_parse_pktgen_hw_clr {
        pkt.extract<pktgen_generic_h>(hdr_2_pktgen_generic);
        md_2.pkt_gen_pkt = true;
        transition parse_per_port_metadata_0;
    }
    state PacketParser_parse_ethernet {
        pkt.extract<ethernet_h>(hdr_2_ethernet);
        transition select(hdr_2_ethernet.ether_type) {
            16w0x800: PacketParser_parse_ipv4;
            default: noMatch;
        }
    }
    state PacketParser_parse_ipv4 {
        pkt.extract<ipv4_h>(hdr_2_ipv4);
        transition select(hdr_2_ipv4.proto) {
            8w6: PacketParser_parse_tcp;
            8w17: PacketParser_parse_udp;
            default: noMatch;
        }
    }
    state PacketParser_parse_tcp {
        pkt.extract<tcp_h>(hdr_2_tcp);
        transition parse_per_port_metadata_0;
    }
    state PacketParser_parse_udp {
        pkt.extract<udp_h>(hdr_2_udp);
        transition parse_per_port_metadata_0;
    }
    state parse_per_port_metadata_0 {
        hdr.recirc_hdr = hdr_2_recirc_hdr;
        hdr.pktgen_generic = hdr_2_pktgen_generic;
        hdr.pktgen_recirc = hdr_2_pktgen_recirc;
        hdr.pktgen_port_down = hdr_2_pktgen_port_down;
        hdr.pktgen_timer = hdr_2_pktgen_timer;
        hdr.ethernet = hdr_2_ethernet;
        hdr.ipv4 = hdr_2_ipv4;
        hdr.tcp = hdr_2_tcp;
        hdr.udp = hdr_2_udp;
        md.ifindex = md_2.ifindex;
        md.eg_ifindex = md_2.eg_ifindex;
        md.timestamp = md_2.timestamp;
        md.offset = md_2.offset;
        md.bf_temp = md_2.bf_temp;
        md.flowlet_hash_input = md_2.flowlet_hash_input;
        md.nhop_id = md_2.nhop_id;
        md.lag_tbl_bit_index = md_2.lag_tbl_bit_index;
        md.ecmp_tbl_bit_index = md_2.ecmp_tbl_bit_index;
        md.pkt_gen_pkt = md_2.pkt_gen_pkt;
        md.recirc_pkt = md_2.recirc_pkt;
        md.one_bit_val_1 = md_2.one_bit_val_1;
        md.one_bit_val_2 = md_2.one_bit_val_2;
        transition accept;
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

parser SwitchEgressParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t eg_intr_md) {
    recirc_h hdr_3_recirc_hdr;
    pktgen_generic_h hdr_3_pktgen_generic;
    pktgen_recirc_header_t hdr_3_pktgen_recirc;
    pktgen_port_down_header_t hdr_3_pktgen_port_down;
    pktgen_timer_header_t hdr_3_pktgen_timer;
    ethernet_h hdr_3_ethernet;
    ipv4_h hdr_3_ipv4;
    tcp_h hdr_3_tcp;
    udp_h hdr_3_udp;
    user_metadata_t md_3;
    bit<8> packet_parser_tmp_2;
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        hdr_3_recirc_hdr = hdr.recirc_hdr;
        hdr_3_pktgen_generic = hdr.pktgen_generic;
        hdr_3_pktgen_recirc = hdr.pktgen_recirc;
        hdr_3_pktgen_port_down = hdr.pktgen_port_down;
        hdr_3_pktgen_timer = hdr.pktgen_timer;
        hdr_3_ethernet = hdr.ethernet;
        hdr_3_ipv4 = hdr.ipv4;
        hdr_3_tcp = hdr.tcp;
        hdr_3_udp = hdr.udp;
        md_3.ifindex = md.ifindex;
        md_3.eg_ifindex = md.eg_ifindex;
        md_3.timestamp = md.timestamp;
        md_3.offset = md.offset;
        md_3.bf_temp = md.bf_temp;
        md_3.flowlet_hash_input = md.flowlet_hash_input;
        md_3.nhop_id = md.nhop_id;
        md_3.lag_tbl_bit_index = md.lag_tbl_bit_index;
        md_3.ecmp_tbl_bit_index = md.ecmp_tbl_bit_index;
        md_3.pkt_gen_pkt = md.pkt_gen_pkt;
        md_3.recirc_pkt = md.recirc_pkt;
        md_3.one_bit_val_1 = md.one_bit_val_1;
        md_3.one_bit_val_2 = md.one_bit_val_2;
        packet_parser_tmp_2 = pkt.lookahead<bit<8>>();
        transition select(packet_parser_tmp_2) {
            8w0x1 &&& 8w0xe7: PacketParser_parse_pktgen_port_down_0;
            8w0x2 &&& 8w0xe7: PacketParser_parse_pktgen_recirc_0;
            8w0x3 &&& 8w0xe7: PacketParser_parse_pktgen_hw_clr_0;
            8w0xf0 &&& 8w0xf0: PacketParser_parse_recirc_pkt_0;
            default: PacketParser_parse_ethernet_0;
        }
    }
    state PacketParser_parse_recirc_pkt_0 {
        pkt.extract<recirc_h>(hdr_3_recirc_hdr);
        md_3.recirc_pkt = true;
        transition select(hdr_3_recirc_hdr.rtype) {
            4w1: PacketParser_parse_pktgen_port_down_0;
            default: start_0;
        }
    }
    state PacketParser_parse_pktgen_recirc_0 {
        pkt.extract<pktgen_recirc_header_t>(hdr_3_pktgen_recirc);
        md_3.pkt_gen_pkt = true;
        transition start_0;
    }
    state PacketParser_parse_pktgen_port_down_0 {
        pkt.extract<pktgen_port_down_header_t>(hdr_3_pktgen_port_down);
        md_3.pkt_gen_pkt = true;
        transition start_0;
    }
    state PacketParser_parse_pktgen_hw_clr_0 {
        pkt.extract<pktgen_generic_h>(hdr_3_pktgen_generic);
        md_3.pkt_gen_pkt = true;
        transition start_0;
    }
    state PacketParser_parse_ethernet_0 {
        pkt.extract<ethernet_h>(hdr_3_ethernet);
        transition select(hdr_3_ethernet.ether_type) {
            16w0x800: PacketParser_parse_ipv4_0;
            default: noMatch_0;
        }
    }
    state PacketParser_parse_ipv4_0 {
        pkt.extract<ipv4_h>(hdr_3_ipv4);
        transition select(hdr_3_ipv4.proto) {
            8w6: PacketParser_parse_tcp_0;
            8w17: PacketParser_parse_udp_0;
            default: noMatch_0;
        }
    }
    state PacketParser_parse_tcp_0 {
        pkt.extract<tcp_h>(hdr_3_tcp);
        transition start_0;
    }
    state PacketParser_parse_udp_0 {
        pkt.extract<udp_h>(hdr_3_udp);
        transition start_0;
    }
    state start_0 {
        hdr.recirc_hdr = hdr_3_recirc_hdr;
        hdr.pktgen_generic = hdr_3_pktgen_generic;
        hdr.pktgen_recirc = hdr_3_pktgen_recirc;
        hdr.pktgen_port_down = hdr_3_pktgen_port_down;
        hdr.pktgen_timer = hdr_3_pktgen_timer;
        hdr.ethernet = hdr_3_ethernet;
        hdr.ipv4 = hdr_3_ipv4;
        hdr.tcp = hdr_3_tcp;
        hdr.udp = hdr_3_udp;
        md.ifindex = md_3.ifindex;
        md.eg_ifindex = md_3.eg_ifindex;
        md.timestamp = md_3.timestamp;
        md.offset = md_3.offset;
        md.bf_temp = md_3.bf_temp;
        md.flowlet_hash_input = md_3.flowlet_hash_input;
        md.nhop_id = md_3.nhop_id;
        md.lag_tbl_bit_index = md_3.lag_tbl_bit_index;
        md.ecmp_tbl_bit_index = md_3.ecmp_tbl_bit_index;
        md.pkt_gen_pkt = md_3.pkt_gen_pkt;
        md.recirc_pkt = md_3.recirc_pkt;
        md.one_bit_val_1 = md_3.one_bit_val_1;
        md.one_bit_val_2 = md_3.one_bit_val_2;
        transition accept;
    }
    state noMatch_0 {
        verify(false, error.NoMatch);
        transition reject;
    }
}

control SwitchIngressDeparser(packet_out pkt, in headers_t hdr, in user_metadata_t md) {
    @hidden action act() {
        pkt.emit<recirc_h>(hdr.recirc_hdr);
        pkt.emit<pktgen_generic_h>(hdr.pktgen_generic);
        pkt.emit<pktgen_recirc_header_t>(hdr.pktgen_recirc);
        pkt.emit<pktgen_port_down_header_t>(hdr.pktgen_port_down);
        pkt.emit<pktgen_timer_header_t>(hdr.pktgen_timer);
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<tcp_h>(hdr.tcp);
        pkt.emit<udp_h>(hdr.udp);
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

control SwitchEgressDeparser(packet_out pkt, in headers_t hdr, in user_metadata_t md) {
    @hidden action act_0() {
        pkt.emit<recirc_h>(hdr.recirc_hdr);
        pkt.emit<pktgen_generic_h>(hdr.pktgen_generic);
        pkt.emit<pktgen_recirc_header_t>(hdr.pktgen_recirc);
        pkt.emit<pktgen_port_down_header_t>(hdr.pktgen_port_down);
        pkt.emit<pktgen_timer_header_t>(hdr.pktgen_timer);
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<tcp_h>(hdr.tcp);
        pkt.emit<udp_h>(hdr.udp);
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

struct flowlet_state_t {
    bit<16> id;
    bit<48> ts;
}

struct tuple_0 {
    bit<8>  field;
    bit<30> field_0;
    bit<30> field_1;
    bit<16> field_2;
    bit<16> field_3;
}

struct tuple_1 {
    bit<16> field_4;
    bit<16> field_5;
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    bit<1> ifindex_counter_one_bit_read_tmp_1;
    bit<1> ifindex_counter_one_bit_read_tmp_2;
    bit<18> ifindex_counter_bloom_filter_tmp_7;
    bit<18> ifindex_counter_bloom_filter_tmp_8;
    bit<18> ifindex_counter_bloom_filter_tmp_9;
    bit<1> ifindex_counter_bloom_filter_tmp_10;
    bit<1> ifindex_counter_bloom_filter_tmp_11;
    bit<1> ifindex_counter_bloom_filter_tmp_13;
    bit<15> ifindex_counter_flowlet_tmp_1;
    bit<16> ifindex_counter_flowlet_tmp_2;
    bit<18> pgen_pass_1_clear_bloom_filter_tmp_0;
    @name("NoAction") action NoAction_0() {
    }
    @name("NoAction") action NoAction_5() {
    }
    @name("NoAction") action NoAction_6() {
    }
    @name("NoAction") action NoAction_7() {
    }
    @name("ifindex_counter.one_bit_read.ob1") register<bit<1>, bit<16>>(16w1000) ifindex_counter_one_bit_read_ob1_0;
    @name("ifindex_counter.one_bit_read.ob2") register<bit<1>, bit<16>>(16w1000) ifindex_counter_one_bit_read_ob2_0;
    @name("ifindex_counter.one_bit_read.one_bit_alu_1") stateful_alu<bit<1>, bit<16>, bit<1>, _>(ifindex_counter_one_bit_read_ob1_0) ifindex_counter_one_bit_read_one_bit_alu_1 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            rv = v;
        }
    };
    @name("ifindex_counter.one_bit_read.one_bit_alu_2") stateful_alu<bit<1>, bit<16>, bit<1>, _>(ifindex_counter_one_bit_read_ob2_0) ifindex_counter_one_bit_read_one_bit_alu_2 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            rv = v;
        }
    };
    @name("ifindex_counter.one_bit_read.do_undrop") action ifindex_counter_one_bit_read_do_undrop() {
        ig_intr_md_for_tm.drop_ctl = 3w0;
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
    }
    @name("ifindex_counter.sip_sampler.sampling_cntr") register<bit<32>, bit<18>>(18w143360, 32w1) ifindex_counter_sip_sampler_sampling_cntr_0;
    @name("ifindex_counter.sip_sampler.sampling_alu") stateful_alu<bit<32>, bit<18>, bit<1>, _>(ifindex_counter_sip_sampler_sampling_cntr_0) ifindex_counter_sip_sampler_sampling_alu_0 = {
        void instruction(inout bit<32> v, out bit<1> rv) {
            if (v >= 32w10) 
                v = 32w1;
            else 
                v = v + 32w1;
            if (ig_intr_md_for_tm.copy_to_cpu == 1w1) 
                rv = 1w0;
        }
    };
    @name("ifindex_counter.sip_sampler.no_sample") action ifindex_counter_sip_sampler_no_sample() {
    }
    @name("ifindex_counter.sip_sampler.sample") action ifindex_counter_sip_sampler_sample() {
        ifindex_counter_sip_sampler_sampling_alu_0.execute();
    }
    @name("ifindex_counter.sip_sampler.sip_sampler") table ifindex_counter_sip_sampler_sip_sampler_0 {
        key = {
            hdr.ipv4.src_addr: exact @name("hdr.ipv4.src_addr") ;
        }
        actions = {
            ifindex_counter_sip_sampler_sample();
            ifindex_counter_sip_sampler_no_sample();
            @defaultonly NoAction_0();
        }
        size = 85000;
        default_action = NoAction_0();
    }
    @name("ifindex_counter.bloom_filter.bf_hash_1") hash<bit<18>>(hash_algorithm_t.RANDOM) ifindex_counter_bloom_filter_bf_hash_2;
    @name("ifindex_counter.bloom_filter.bf_hash_2") hash<bit<18>>(hash_algorithm_t.RANDOM) ifindex_counter_bloom_filter_bf_hash_3;
    @name("ifindex_counter.bloom_filter.bf_hash_3") hash<bit<18>>(hash_algorithm_t.RANDOM) ifindex_counter_bloom_filter_bf_hash_4;
    @name("ifindex_counter.bloom_filter.bloom_filter_1") register<bit<1>, bit<18>>(18w262143) ifindex_counter_bloom_filter_bloom_filter_2;
    @name("ifindex_counter.bloom_filter.bloom_filter_2") register<bit<1>, bit<18>>(18w262143) ifindex_counter_bloom_filter_bloom_filter_3;
    @name("ifindex_counter.bloom_filter.bloom_filter_3") register<bit<1>, bit<18>>(18w262143) ifindex_counter_bloom_filter_bloom_filter_4;
    @name("ifindex_counter.bloom_filter.bloom_fiter_alu_1") stateful_alu<bit<1>, bit<18>, bit<1>, _>(ifindex_counter_bloom_filter_bloom_filter_2) ifindex_counter_bloom_filter_bloom_fiter_alu_0 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = 1w1;
            rv = 1w0;
        }
    };
    @name("ifindex_counter.bloom_filter.bloom_filter_alu_2") stateful_alu<bit<1>, bit<18>, bit<1>, _>(ifindex_counter_bloom_filter_bloom_filter_3) ifindex_counter_bloom_filter_bloom_filter_alu_1 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = 1w1;
            rv = 1w0;
        }
    };
    @name("ifindex_counter.bloom_filter.bloom_filter_alu_3") stateful_alu<bit<1>, bit<18>, bit<1>, _>(ifindex_counter_bloom_filter_bloom_filter_4) ifindex_counter_bloom_filter_bloom_filter_alu_2 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = 1w1;
            rv = 1w0;
        }
    };
    @name("ifindex_counter.bloom_filter.bloom_filter_mark_sample") action ifindex_counter_bloom_filter_bloom_filter_mark_sample() {
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    @name("ifindex_counter.flowlet.flowlet_inactive_timeout") stateful_param<bit<32>>(32w5000) ifindex_counter_flowlet_flowlet_inactive_timeout_0;
    @name("ifindex_counter.flowlet.flowlet_alu") stateful_alu<flowlet_state_t, bit<15>, bit<16>, bit<48>>() ifindex_counter_flowlet_flowlet_alu_0 = {
        void instruction(inout flowlet_state_t v, out bit<16> rv, in bit<48> p) {
            if (md.timestamp - v.ts > p && v.id != 16w65535) 
                v.id = md.nhop_id;
            v.ts = md.timestamp;
            rv = v.id;
        }
    };
    @name("ifindex_counter.flowlet.flowlet_hash") hash<bit<15>>(hash_algorithm_t.CRC16) ifindex_counter_flowlet_flowlet_hash_0;
    @name("ifindex_counter.ifindex_ctr") register<bit<16>, _>() ifindex_counter_ifindex_ctr_0;
    @name("ifindex_counter.ifindex_cntr_alu") stateful_alu<bit<16>, _, _, _>() ifindex_counter_ifindex_cntr_alu_0 = {
        void instruction(inout bit<16> ctr) {
            ctr = ctr + (bit<16>)hdr.ipv4.ttl;
        }
    };
    @name("ifindex_counter.set_ifindex_based_params") action ifindex_counter_set_ifindex_based_params(bit<48> ts, bit<32> offset) {
        ifindex_counter_ifindex_cntr_alu_0.execute();
    }
    @name("ifindex_counter.drop_it") action ifindex_counter_drop_it() {
        ifindex_counter_ifindex_cntr_alu_0.execute();
    }
    @name("ifindex_counter.ifindex") table ifindex_counter_ifindex_0 {
        key = {
            md.ifindex: exact @name("md.ifindex") ;
        }
        actions = {
            ifindex_counter_set_ifindex_based_params();
            ifindex_counter_drop_it();
            @defaultonly NoAction_5();
        }
        size = 25000;
        implementation = ifindex_counter_ifindex_ctr_0;
        default_action = NoAction_5();
    }
    @name("pgen_pass_1.clear_bloom_filter.bf_hash") hash<bit<18>>(hash_algorithm_t.IDENTITY) pgen_pass_1_clear_bloom_filter_bf_hash_0;
    @name("pgen_pass_1.clear_bloom_filter.bloom_filter_1") register<bit<1>, bit<18>>(18w262143) pgen_pass_1_clear_bloom_filter_bloom_filter_2;
    @name("pgen_pass_1.clear_bloom_filter.bloom_filter_2") register<bit<1>, bit<18>>(18w262143) pgen_pass_1_clear_bloom_filter_bloom_filter_3;
    @name("pgen_pass_1.clear_bloom_filter.bloom_filter_3") register<bit<1>, bit<18>>(18w262143) pgen_pass_1_clear_bloom_filter_bloom_filter_4;
    @name("pgen_pass_1.clear_bloom_filter.clr_bloom_filter_alu_1") stateful_alu<bit<1>, bit<18>, _, _>(pgen_pass_1_clear_bloom_filter_bloom_filter_2) pgen_pass_1_clear_bloom_filter_clr_bloom_filter_alu_2 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("pgen_pass_1.clear_bloom_filter.clr_bloom_filter_alu_2") stateful_alu<bit<1>, bit<18>, _, _>(pgen_pass_1_clear_bloom_filter_bloom_filter_3) pgen_pass_1_clear_bloom_filter_clr_bloom_filter_alu_3 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("pgen_pass_1.clear_bloom_filter.clr_bloom_filter_alu_3") stateful_alu<bit<1>, bit<18>, _, _>(pgen_pass_1_clear_bloom_filter_bloom_filter_4) pgen_pass_1_clear_bloom_filter_clr_bloom_filter_alu_4 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("pgen_pass_1.ecmp_failover.next_hop_ecmp_alu") stateful_alu<bit<1>, bit<17>, _, _>() pgen_pass_1_ecmp_failover_next_hop_ecmp_alu_0 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("pgen_pass_1.ecmp_failover.set_ecmp_fast_update_key") action pgen_pass_1_ecmp_failover_set_ecmp_fast_update_key(bit<17> key) {
        md.ecmp_tbl_bit_index = key;
    }
    @name("pgen_pass_1.ecmp_failover.drop_ecmp_update_pkt") action pgen_pass_1_ecmp_failover_drop_ecmp_update_pkt() {
    }
    @name("pgen_pass_1.ecmp_failover.set_mbr_down") action pgen_pass_1_ecmp_failover_set_mbr_down() {
        pgen_pass_1_ecmp_failover_next_hop_ecmp_alu_0.execute(md.ecmp_tbl_bit_index);
        ig_intr_md_for_tm.drop_ctl = 3w0x7;
    }
    @name("pgen_pass_1.ecmp_failover.make_key_ecmp_fast_update") table pgen_pass_1_ecmp_failover_make_key_ecmp_fast_update_0 {
        key = {
            hdr.pktgen_recirc.key      : exact @name("hdr.pktgen_recirc.key") ;
            hdr.pktgen_recirc.packet_id: exact @name("hdr.pktgen_recirc.packet_id") ;
        }
        actions = {
            pgen_pass_1_ecmp_failover_set_ecmp_fast_update_key();
            pgen_pass_1_ecmp_failover_drop_ecmp_update_pkt();
            @defaultonly NoAction_6();
        }
        size = 16384;
        default_action = NoAction_6();
    }
    @name("pgen_pass_1.prepare") action pgen_pass_1_prepare(bit<4> rtype, bit<16> mgid) {
        hdr.recirc_hdr.tag = 4w0xf;
        hdr.recirc_hdr.rtype = rtype;
        ig_intr_md_for_tm.mcast_grp_b = mgid;
    }
    @name("pgen_pass_1.prepare_for_recirc") table pgen_pass_1_prepare_for_recirc_0 {
        key = {
            hdr.pktgen_port_down.app_id: exact @name("hdr.pktgen_port_down.app_id") ;
        }
        actions = {
            pgen_pass_1_prepare();
            @defaultonly NoAction_7();
        }
        size = 7;
        default_action = NoAction_7();
    }
    @name("pgen_pass_2.lag_failover.lag_alu") stateful_alu<bit<1>, bit<17>, _, _>() pgen_pass_2_lag_failover_lag_alu_0 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("pgen_pass_2.lag_failover.drop_ifindex_update_pkt") action pgen_pass_2_lag_failover_drop_ifindex_update_pkt() {
    }
    @name("pgen_pass_2.lag_failover.set_lag_fast_update_key") action pgen_pass_2_lag_failover_set_lag_fast_update_key(bit<17> key) {
        md.lag_tbl_bit_index = key;
    }
    @name("pgen_pass_2.lag_failover.set_lag_mbr_down") action pgen_pass_2_lag_failover_set_lag_mbr_down() {
        pgen_pass_2_lag_failover_lag_alu_0.execute(md.lag_tbl_bit_index);
        ig_intr_md_for_tm.drop_ctl = 3w0x7;
    }
    @name("pgen_pass_2.lag_failover.eg_ifindex_fast_update_make_key") table pgen_pass_2_lag_failover_eg_ifindex_fast_update_make_key_0 {
        key = {
            hdr.pktgen_port_down.port_num : exact @name("hdr.pktgen_port_down.port_num") ;
            hdr.pktgen_port_down.packet_id: exact @name("hdr.pktgen_port_down.packet_id") ;
        }
        actions = {
            pgen_pass_2_lag_failover_set_lag_fast_update_key();
            pgen_pass_2_lag_failover_drop_ifindex_update_pkt();
        }
        const default_action = pgen_pass_2_lag_failover_drop_ifindex_update_pkt();
        size = 16384;
    }
    @hidden action act_1() {
        ifindex_counter_one_bit_read_tmp_1 = ifindex_counter_one_bit_read_one_bit_alu_1.execute(16w1);
        md.one_bit_val_1 = ifindex_counter_one_bit_read_tmp_1;
        ifindex_counter_one_bit_read_tmp_2 = ifindex_counter_one_bit_read_one_bit_alu_2.execute(16w2);
        md.one_bit_val_2 = ifindex_counter_one_bit_read_tmp_2;
    }
    @hidden action act_2() {
        ifindex_counter_bloom_filter_tmp_7 = ifindex_counter_bloom_filter_bf_hash_2.get_hash<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        ifindex_counter_bloom_filter_tmp_8 = ifindex_counter_bloom_filter_bf_hash_3.get_hash<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        ifindex_counter_bloom_filter_tmp_9 = ifindex_counter_bloom_filter_bf_hash_4.get_hash<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        ifindex_counter_bloom_filter_tmp_10 = ifindex_counter_bloom_filter_bloom_fiter_alu_0.execute(ifindex_counter_bloom_filter_tmp_7);
        ifindex_counter_bloom_filter_tmp_11 = ifindex_counter_bloom_filter_bloom_filter_alu_1.execute(ifindex_counter_bloom_filter_tmp_8);
        ifindex_counter_bloom_filter_tmp_13 = ifindex_counter_bloom_filter_bloom_filter_alu_2.execute(ifindex_counter_bloom_filter_tmp_9);
        md.bf_temp = (bool)(ifindex_counter_bloom_filter_tmp_10 | ifindex_counter_bloom_filter_tmp_11 | ifindex_counter_bloom_filter_tmp_13);
    }
    @hidden action act_3() {
        ifindex_counter_flowlet_tmp_1 = ifindex_counter_flowlet_flowlet_hash_0.get_hash<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        ifindex_counter_flowlet_tmp_2 = ifindex_counter_flowlet_flowlet_alu_0.execute(ifindex_counter_flowlet_tmp_1);
        md.nhop_id = ifindex_counter_flowlet_tmp_2;
    }
    @hidden action act_4() {
        pgen_pass_1_clear_bloom_filter_tmp_0 = pgen_pass_1_clear_bloom_filter_bf_hash_0.get_hash<tuple_1>({ hdr.pktgen_generic.batch_id, hdr.pktgen_generic.packet_id });
        pgen_pass_1_clear_bloom_filter_clr_bloom_filter_alu_2.execute(pgen_pass_1_clear_bloom_filter_tmp_0);
        pgen_pass_1_clear_bloom_filter_clr_bloom_filter_alu_3.execute(pgen_pass_1_clear_bloom_filter_tmp_0);
        pgen_pass_1_clear_bloom_filter_clr_bloom_filter_alu_4.execute(pgen_pass_1_clear_bloom_filter_tmp_0);
    }
    @hidden table tbl_act_1 {
        actions = {
            act_1();
        }
        const default_action = act_1();
    }
    @hidden table tbl_ifindex_counter_one_bit_read_do_undrop {
        actions = {
            ifindex_counter_one_bit_read_do_undrop();
        }
        const default_action = ifindex_counter_one_bit_read_do_undrop();
    }
    @hidden table tbl_act_2 {
        actions = {
            act_2();
        }
        const default_action = act_2();
    }
    @hidden table tbl_ifindex_counter_bloom_filter_bloom_filter_mark_sample {
        actions = {
            ifindex_counter_bloom_filter_bloom_filter_mark_sample();
        }
        const default_action = ifindex_counter_bloom_filter_bloom_filter_mark_sample();
    }
    @hidden table tbl_act_3 {
        actions = {
            act_3();
        }
        const default_action = act_3();
    }
    @hidden table tbl_act_4 {
        actions = {
            act_4();
        }
        const default_action = act_4();
    }
    @hidden table tbl_pgen_pass_1_ecmp_failover_set_mbr_down {
        actions = {
            pgen_pass_1_ecmp_failover_set_mbr_down();
        }
        const default_action = pgen_pass_1_ecmp_failover_set_mbr_down();
    }
    @hidden table tbl_pgen_pass_2_lag_failover_set_lag_mbr_down {
        actions = {
            pgen_pass_2_lag_failover_set_lag_mbr_down();
        }
        const default_action = pgen_pass_2_lag_failover_set_lag_mbr_down();
    }
    apply {
        if (md.recirc_pkt == false && md.pkt_gen_pkt == false) 
            switch (ifindex_counter_ifindex_0.apply().action_run) {
                ifindex_counter_drop_it: {
                    tbl_act_1.apply();
                    if (md.one_bit_val_1 == 1w1 && md.one_bit_val_2 == 1w1) 
                        tbl_ifindex_counter_one_bit_read_do_undrop.apply();
                }
                default: {
                    tbl_act_2.apply();
                    if (md.bf_temp == true) 
                        tbl_ifindex_counter_bloom_filter_bloom_filter_mark_sample.apply();
                    ifindex_counter_sip_sampler_sip_sampler_0.apply();
                    tbl_act_3.apply();
                }
            }

        else 
            if (md.recirc_pkt == false && md.pkt_gen_pkt == true) 
                if (hdr.pktgen_generic.isValid()) {
                    tbl_act_4.apply();
                }
                else 
                    if (hdr.pktgen_recirc.isValid()) {
                        pgen_pass_1_ecmp_failover_make_key_ecmp_fast_update_0.apply();
                        tbl_pgen_pass_1_ecmp_failover_set_mbr_down.apply();
                    }
                    else 
                        pgen_pass_1_prepare_for_recirc_0.apply();
            else 
                if (md.recirc_pkt == true && md.pkt_gen_pkt == false) 
                    ;
                else 
                    if (hdr.recirc_hdr.rtype == 4w2) 
                        ;
                    else 
                        if (hdr.recirc_hdr.rtype == 4w1) {
                            pgen_pass_2_lag_failover_eg_ifindex_fast_update_make_key_0.apply();
                            tbl_pgen_pass_2_lag_failover_set_lag_mbr_down.apply();
                        }
    }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t md_from_prsr) {
    apply {
    }
}

Switch<headers_t, user_metadata_t, headers_t, user_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) main;
