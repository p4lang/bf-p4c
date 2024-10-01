#include <tna.p4>

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
parser PacketParser(packet_in pkt, inout headers_t hdr, inout user_metadata_t md) {
    bit<8> tmp;
    state start {
        tmp = pkt.lookahead<bit<8>>();
        transition select(tmp) {
            8w0x1 &&& 8w0xe7: parse_pktgen_port_down;
            8w0x2 &&& 8w0xe7: parse_pktgen_recirc;
            8w0x3 &&& 8w0xe7: parse_pktgen_hw_clr;
            8w0xf0 &&& 8w0xf0: parse_recirc_pkt;
            default: parse_ethernet;
        }
    }
    state parse_recirc_pkt {
        pkt.extract<recirc_h>(hdr.recirc_hdr);
        md.recirc_pkt = true;
        transition select(hdr.recirc_hdr.rtype) {
            4w1: parse_pktgen_port_down;
            default: accept;
        }
    }
    state parse_pktgen_recirc {
        pkt.extract<pktgen_recirc_header_t>(hdr.pktgen_recirc);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_pktgen_port_down {
        pkt.extract<pktgen_port_down_header_t>(hdr.pktgen_port_down);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_pktgen_hw_clr {
        pkt.extract<pktgen_generic_h>(hdr.pktgen_generic);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_ethernet {
        pkt.extract<ethernet_h>(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            16w0x800: parse_ipv4;
        }
    }
    state parse_ipv4 {
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition select(hdr.ipv4.proto) {
            8w6: parse_tcp;
            8w17: parse_udp;
        }
    }
    state parse_tcp {
        pkt.extract<tcp_h>(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        pkt.extract<udp_h>(hdr.udp);
        transition accept;
    }
}

parser SwitchIngressParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    bit<16> tmp_0;
    @name("packet_parser") PacketParser() packet_parser_0;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select((bool)ig_intr_md.resubmit_flag) {
            true: reject;
            false: parse_per_port_metadata;
        }
    }
    state parse_per_port_metadata {
        tmp_0 = pkt.lookahead<ifindex_t>();
        md.ifindex = tmp_0;
        pkt.advance(32w64);
        packet_parser_0.apply(pkt, hdr, md);
        transition accept;
    }
}

parser SwitchEgressParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t eg_intr_md) {
    @name("packet_parser") PacketParser() packet_parser_1;
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        packet_parser_1.apply(pkt, hdr, md);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, in headers_t hdr, in user_metadata_t md) {
    apply {
        pkt.emit<headers_t>(hdr);
    }
}

control SwitchEgressDeparser(packet_out pkt, in headers_t hdr, in user_metadata_t md) {
    apply {
        pkt.emit<headers_t>(hdr);
    }
}

control OneBitRead(inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    bit<1> tmp_1;
    bit<1> tmp_2;
    @name("ob1") register<bit<1>, bit<16>>(16w1000) ob1_0;
    @name("ob2") register<bit<1>, bit<16>>(16w1000) ob2_0;
    @name("one_bit_alu_1") stateful_alu<bit<1>, bit<16>, bit<1>, _>(ob1_0) one_bit_alu = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            rv = v;
        }
    };
    @name("one_bit_alu_2") stateful_alu<bit<1>, bit<16>, bit<1>, _>(ob2_0) one_bit_alu_0 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            rv = v;
        }
    };
    @name("do_undrop") action do_undrop_0() {
        ig_intr_md_for_tm.drop_ctl = 3w0;
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
    }
    apply {
        tmp_1 = one_bit_alu.execute(16w1);
        md.one_bit_val_1 = tmp_1;
        tmp_2 = one_bit_alu_0.execute(16w2);
        md.one_bit_val_2 = tmp_2;
        if (md.one_bit_val_1 == 1w1 && md.one_bit_val_2 == 1w1)
            do_undrop_0();
    }
}

control BloomFilter(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    bit<18> index_0;
    bit<18> index_4;
    bit<18> index_5;
    bit<18> tmp_3;
    bit<18> tmp_4;
    bit<18> tmp_5;
    bit<1> tmp_6;
    bit<1> tmp_7;
    bit<1> tmp_8;
    bit<1> tmp_9;
    bit<1> tmp_10;
    @name("bf_hash_1") hash<bit<18>>(hash_algorithm_t.RANDOM) bf_hash_0;
    @name("bf_hash_2") hash<bit<18>>(hash_algorithm_t.RANDOM) bf_hash_4;
    @name("bf_hash_3") hash<bit<18>>(hash_algorithm_t.RANDOM) bf_hash_5;
    @name("bloom_filter_1") register<bit<1>, bit<18>>(18w262143) bloom_filter_0;
    @name("bloom_filter_2") register<bit<1>, bit<18>>(18w262143) bloom_filter_4;
    @name("bloom_filter_3") register<bit<1>, bit<18>>(18w262143) bloom_filter_5;
    @name("bloom_fiter_alu_1") stateful_alu<bit<1>, bit<18>, bit<1>, _>(bloom_filter_0) bloom_fiter_alu = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = 1w1;
            rv = (bit<1>)!(bool)v;
        }
    };
    @name("bloom_filter_alu_2") stateful_alu<bit<1>, bit<18>, bit<1>, _>(bloom_filter_4) bloom_filter_alu = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = 1w1;
            rv = (bit<1>)!(bool)v;
        }
    };
    @name("bloom_filter_alu_3") stateful_alu<bit<1>, bit<18>, bit<1>, _>(bloom_filter_5) bloom_filter_alu_0 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = 1w1;
            rv = (bit<1>)!(bool)v;
        }
    };
    @name("bloom_filter_mark_sample") action bloom_filter_mark_sample_0() {
        ig_intr_md_for_tm.copy_to_cpu = 1w1;
    }
    apply {
        tmp_3 = bf_hash_0.get_hash<tuple<bit<8>, bit<30>, bit<30>, bit<16>, bit<16>>>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        index_0 = tmp_3;
        tmp_4 = bf_hash_4.get_hash<tuple<bit<8>, bit<30>, bit<30>, bit<16>, bit<16>>>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        index_4 = tmp_4;
        tmp_5 = bf_hash_5.get_hash<tuple<bit<8>, bit<30>, bit<30>, bit<16>, bit<16>>>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        index_5 = tmp_5;
        tmp_6 = bloom_fiter_alu.execute(index_0);
        tmp_7 = bloom_filter_alu.execute(index_4);
        tmp_8 = tmp_6 | tmp_7;
        tmp_9 = bloom_filter_alu_0.execute(index_5);
        tmp_10 = tmp_8 | tmp_9;
        md.bf_temp = (bool)tmp_10;
        if (md.bf_temp == true)
            bloom_filter_mark_sample_0();
    }
}

control ClearBloomFilter(inout headers_t hdr, inout user_metadata_t md) {
    bit<18> index_6;
    bit<18> tmp_11;
    @name("bf_hash") hash<bit<18>>(hash_algorithm_t.IDENTITY) bf_hash_6;
    @name("bloom_filter_1") register<bit<1>, bit<18>>(18w262143) bloom_filter_6;
    @name("bloom_filter_2") register<bit<1>, bit<18>>(18w262143) bloom_filter_7;
    @name("bloom_filter_3") register<bit<1>, bit<18>>(18w262143) bloom_filter_8;
    @name("clr_bloom_filter_alu_1") stateful_alu<bit<1>, bit<18>, _, _>(bloom_filter_6) clr_bloom_filter_alu = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("clr_bloom_filter_alu_2") stateful_alu<bit<1>, bit<18>, _, _>(bloom_filter_7) clr_bloom_filter_alu_0 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("clr_bloom_filter_alu_3") stateful_alu<bit<1>, bit<18>, _, _>(bloom_filter_8) clr_bloom_filter_alu_4 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    apply {
        tmp_11 = bf_hash_6.get_hash<tuple<bit<16>, bit<16>>>({ hdr.pktgen_generic.batch_id, hdr.pktgen_generic.packet_id });
        index_6 = tmp_11;
        clr_bloom_filter_alu.execute(index_6);
        clr_bloom_filter_alu_0.execute(index_6);
        clr_bloom_filter_alu_4.execute(index_6);
    }
}

control SipSampler(in headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("sampling_cntr") register<bit<32>, bit<18>>(18w143360, 32w1) sampling_cntr_0;
    @name("sampling_alu") stateful_alu<bit<32>, bit<18>, bit<1>, _>(sampling_cntr_0) sampling_alu_0 = {
        void instruction(inout bit<32> v, out bit<1> rv) {
            if (v >= 32w10)
                v = 32w1;
            else
                v = v + 32w1;
            if (ig_intr_md_for_tm.copy_to_cpu == 1w1)
                rv = 1w0;
        }
    };
    @name("no_sample") action no_sample_0() {
    }
    @name("sample") action sample_0() {
        sampling_alu_0.execute();
    }
    @name("sip_sampler") table sip_sampler_0 {
        key = {
            hdr.ipv4.src_addr: exact @name("hdr.ipv4.src_addr") ;
        }
        actions = {
            sample_0();
            no_sample_0();
            @defaultonly NoAction();
        }
        size = 85000;
        default_action = NoAction();
    }
    apply {
        sip_sampler_0.apply();
    }
}

struct flowlet_state_t {
    bit<16> id;
    bit<48> ts;
}

control Flowlet(inout headers_t hdr, inout user_metadata_t md) {
    bit<15> index_7;
    bit<15> tmp_12;
    bit<16> tmp_13;
    @name("flowlet_inactive_timeout") stateful_param<bit<32>>(32w5000) flowlet_inactive_timeout_0;
    @name("flowlet_alu") stateful_alu<flowlet_state_t, bit<15>, bit<16>, bit<48>>() flowlet_alu_0 = {
        void instruction(inout flowlet_state_t v, out bit<16> rv, in bit<48> p) {
            if (md.timestamp - v.ts > p && v.id != 16w65535)
                v.id = md.nhop_id;
            v.ts = md.timestamp;
            rv = v.id;
        }
    };
    @name("flowlet_hash") hash<bit<15>>(hash_algorithm_t.CRC16) flowlet_hash_0;
    apply {
        tmp_12 = flowlet_hash_0.get_hash<tuple<bit<8>, bit<30>, bit<30>, bit<16>, bit<16>>>({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        index_7 = tmp_12;
        tmp_13 = flowlet_alu_0.execute(index_7);
        md.nhop_id = tmp_13;
    }
}

control EcmpFailover(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("next_hop_ecmp_alu") stateful_alu<bit<1>, bit<17>, _, _>() next_hop_ecmp_alu_0 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("set_ecmp_fast_update_key") action set_ecmp_fast_update_key_0(bit<17> key) {
        md.ecmp_tbl_bit_index = key;
    }
    @name("drop_ecmp_update_pkt") action drop_ecmp_update_pkt_0() {
    }
    @name("set_mbr_down") action set_mbr_down_0() {
        next_hop_ecmp_alu_0.execute(md.ecmp_tbl_bit_index);
        ig_intr_md_for_tm.drop_ctl = 3w0x7;
    }
    @name("make_key_ecmp_fast_update") table make_key_ecmp_fast_update_0 {
        key = {
            hdr.pktgen_recirc.key      : exact @name("hdr.pktgen_recirc.key") ;
            hdr.pktgen_recirc.packet_id: exact @name("hdr.pktgen_recirc.packet_id") ;
        }
        actions = {
            set_ecmp_fast_update_key_0();
            drop_ecmp_update_pkt_0();
            @defaultonly NoAction();
        }
        size = 16384;
        default_action = NoAction();
    }
    apply {
        make_key_ecmp_fast_update_0.apply();
        set_mbr_down_0();
    }
}

control LagFailover(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("lag_alu") stateful_alu<bit<1>, bit<17>, _, _>() lag_alu_0 = {
        void instruction(inout bit<1> v) {
            v = 1w0;
        }
    };
    @name("drop_ifindex_update_pkt") action drop_ifindex_update_pkt_0() {
    }
    @name("set_lag_fast_update_key") action set_lag_fast_update_key_0(bit<17> key) {
        md.lag_tbl_bit_index = key;
    }
    @name("set_lag_mbr_down") action set_lag_mbr_down_0() {
        lag_alu_0.execute(md.lag_tbl_bit_index);
        ig_intr_md_for_tm.drop_ctl = 3w0x7;
    }
    @name("eg_ifindex_fast_update_make_key") table eg_ifindex_fast_update_make_key_0 {
        key = {
            hdr.pktgen_port_down.port_num : exact @name("hdr.pktgen_port_down.port_num") ;
            hdr.pktgen_port_down.packet_id: exact @name("hdr.pktgen_port_down.packet_id") ;
        }
        actions = {
            set_lag_fast_update_key_0();
            drop_ifindex_update_pkt_0();
        }
        const default_action = drop_ifindex_update_pkt_0();
        size = 16384;
    }
    apply {
        eg_ifindex_fast_update_make_key_0.apply();
        set_lag_mbr_down_0();
    }
}

control IfindexCounter(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("one_bit_read") OneBitRead() one_bit_read_0;
    @name("sip_sampler") SipSampler() sip_sampler_1;
    @name("bloom_filter") BloomFilter() bloom_filter_9;
    @name("flowlet") Flowlet() flowlet_0;
    @name("ifindex_ctr") register<bit<16>, _>() ifindex_ctr_0;
    @name("ifindex_cntr_alu") stateful_alu<bit<16>, _, _, _>() ifindex_cntr_alu_0 = {
        void instruction(inout bit<16> ctr) {
            ctr = ctr + (bit<16>)hdr.ipv4.ttl;
        }
    };
    @name("run_ifid_cntr") action run_ifid_cntr_0() {
        ifindex_cntr_alu_0.execute();
    }
    @name("set_ifindex_based_params") action set_ifindex_based_params_0(bit<48> ts, bit<32> offset) {
        run_ifid_cntr_0();
    }
    @name("drop_it") action drop_it_0() {
        run_ifid_cntr_0();
    }
    @name("ifindex") table ifindex_0 {
        key = {
            md.ifindex: exact @name("md.ifindex") ;
        }
        actions = {
            set_ifindex_based_params_0();
            drop_it_0();
            @defaultonly NoAction();
        }
        size = 25000;
        implementation = ifindex_ctr_0;
        default_action = NoAction();
    }
    apply {
        switch (ifindex_0.apply().action_run) {
            drop_it_0: {
                one_bit_read_0.apply(md, ig_intr_md, ig_intr_md_for_tm);
            }
            default: {
                bloom_filter_9.apply(hdr, md, ig_intr_md_for_tm);
                sip_sampler_1.apply(hdr, md, ig_intr_md_for_tm);
                flowlet_0.apply(hdr, md);
            }
        }

    }
}

control PgenPass1(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("clear_bloom_filter") ClearBloomFilter() clear_bloom_filter_0;
    @name("ecmp_failover") EcmpFailover() ecmp_failover_0;
    @name("prepare") action prepare_0(bit<4> rtype, bit<16> mgid) {
        hdr.recirc_hdr.tag = 4w0xf;
        hdr.recirc_hdr.rtype = rtype;
        ig_intr_md_for_tm.mcast_grp_b = mgid;
    }
    @name("prepare_for_recirc") table prepare_for_recirc_0 {
        key = {
            hdr.pktgen_port_down.app_id: exact @name("hdr.pktgen_port_down.app_id") ;
        }
        actions = {
            prepare_0();
            @defaultonly NoAction();
        }
        size = 7;
        default_action = NoAction();
    }
    apply {
        if (hdr.pktgen_generic.isValid())
            clear_bloom_filter_0.apply(hdr, md);
        else
            if (hdr.pktgen_recirc.isValid())
                ecmp_failover_0.apply(hdr, md, ig_intr_md_for_tm);
            else
                prepare_for_recirc_0.apply();
    }
}

control PgenPass2(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("lag_failover") LagFailover() lag_failover_0;
    apply {
        if (hdr.recirc_hdr.rtype == 4w2)
            ;
        else
            if (hdr.recirc_hdr.rtype == 4w1)
                lag_failover_0.apply(hdr, md, ig_intr_md_for_tm);
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name("ifindex_counter") IfindexCounter() ifindex_counter_0;
    @name("pgen_pass_1") PgenPass1() pgen_pass;
    @name("pgen_pass_2") PgenPass2() pgen_pass_0;
    apply {
        if (md.recirc_pkt == false && md.pkt_gen_pkt == false)
            ifindex_counter_0.apply(hdr, md, ig_intr_md, ig_intr_md_for_tm);
        else
            if (md.recirc_pkt == false && md.pkt_gen_pkt == true)
                pgen_pass.apply(hdr, md, ig_intr_md_for_tm);
            else
                if (md.recirc_pkt == true && md.pkt_gen_pkt == false)
                    ;
                else
                    pgen_pass_0.apply(hdr, md, ig_intr_md_for_tm);
    }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t md_from_prsr) {
    apply {
    }
}

Switch<headers_t, user_metadata_t, headers_t, user_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) main;
