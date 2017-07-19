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

register<bit<1>, bit<18>>(262143) bloom_filter_1;
register<bit<1>, bit<18>>(262143) bloom_filter_2;
register<bit<1>, bit<18>>(262143) bloom_filter_3;
register<bit<1>, bit<17>>(131071) lag_reg;
register<bit<1>, bit<29>>(131072) next_hop_ecmp_reg;
parser PacketParser(packet_in pkt, inout headers_t hdr, inout user_metadata_t md) {
    state start {
        transition select(pkt.lookahead<bit<8>>()) {
            0x1 &&& 0xe7: parse_pktgen_port_down;
            0x2 &&& 0xe7: parse_pktgen_recirc;
            0x3 &&& 0xe7: parse_pktgen_hw_clr;
            0xf0 &&& 0xf0: parse_recirc_pkt;
            default: parse_ethernet;
        }
    }
    state parse_recirc_pkt {
        pkt.extract(hdr.recirc_hdr);
        md.recirc_pkt = true;
        transition select(hdr.recirc_hdr.rtype) {
            1: parse_pktgen_port_down;
            default: accept;
        }
    }
    state parse_pktgen_recirc {
        pkt.extract(hdr.pktgen_recirc);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_pktgen_port_down {
        pkt.extract(hdr.pktgen_port_down);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_recirc_trigger_pkt {
        pkt.extract(hdr.pktgen_generic);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_pktgen_hw_clr {
        pkt.extract(hdr.pktgen_generic);
        md.pkt_gen_pkt = true;
        transition accept;
    }
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            0x800: parse_ipv4;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.proto) {
            6: parse_tcp;
            17: parse_udp;
        }
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
}

parser SwitchIngressParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out ingress_intrinsic_metadata_t ig_intr_md) {
    PacketParser() packet_parser;
    state start {
        pkt.extract(ig_intr_md);
        transition select((bool)ig_intr_md.resubmit_flag) {
            true: reject;
            false: parse_per_port_metadata;
        }
    }
    state parse_per_port_metadata {
        md.ifindex = pkt.lookahead<ifindex_t>();
        pkt.advance(64);
        transition parse_packet;
    }
    state parse_packet {
        packet_parser.apply(pkt, hdr, md);
        transition accept;
    }
}

parser SwitchEgressParser(packet_in pkt, out headers_t hdr, out user_metadata_t md, out egress_intrinsic_metadata_t eg_intr_md) {
    PacketParser() packet_parser;
    state start {
        pkt.extract(eg_intr_md);
        transition parse_packet;
    }
    state parse_packet {
        packet_parser.apply(pkt, hdr, md);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt, in headers_t hdr, in user_metadata_t md) {
    apply {
        pkt.emit(hdr);
    }
}

control SwitchEgressDeparser(packet_out pkt, in headers_t hdr, in user_metadata_t md) {
    apply {
        pkt.emit(hdr);
    }
}

control OneBitRead(inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    register<bit<1>, bit<16>>(1000) ob1;
    register<bit<1>, bit<16>>(1000) ob2;
    stateful_alu<bit<1>, bit<16>, bit<1>, _>(ob1) one_bit_alu_1 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            rv = v;
        }
    };
    stateful_alu<bit<1>, bit<16>, bit<1>, _>(ob2) one_bit_alu_2 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            rv = v;
        }
    };
    action do_undrop() {
        ig_intr_md_for_tm.drop_ctl = 0;
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
    }
    apply {
        md.one_bit_val_1 = one_bit_alu_1.execute(1);
        md.one_bit_val_2 = one_bit_alu_2.execute(2);
        if (md.one_bit_val_1 == 1 && md.one_bit_val_2 == 1) {
            do_undrop();
        }
    }
}

control BloomFilter(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    hash<bit<18>>(hash_algorithm_t.RANDOM) bf_hash_1;
    hash<bit<18>>(hash_algorithm_t.RANDOM) bf_hash_2;
    hash<bit<18>>(hash_algorithm_t.RANDOM) bf_hash_3;
    register<bit<1>, bit<18>>(262143) bloom_filter_1;
    register<bit<1>, bit<18>>(262143) bloom_filter_2;
    register<bit<1>, bit<18>>(262143) bloom_filter_3;
    stateful_alu<bit<1>, bit<18>, bit<1>, _>(bloom_filter_1) bloom_fiter_alu_1 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = (bit<1>)true;
            rv = (bit<1>)!(bool)v;
        }
    };
    stateful_alu<bit<1>, bit<18>, bit<1>, _>(bloom_filter_2) bloom_filter_alu_2 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = (bit<1>)true;
            rv = (bit<1>)!(bool)v;
        }
    };
    stateful_alu<bit<1>, bit<18>, bit<1>, _>(bloom_filter_3) bloom_filter_alu_3 = {
        void instruction(inout bit<1> v, out bit<1> rv) {
            v = (bit<1>)true;
            rv = (bit<1>)!(bool)v;
        }
    };
    action drop_clearing_packet() {
        ig_intr_md_for_tm.drop_ctl = 0x7;
    }
    action bloom_filter_mark_sample() {
        ig_intr_md_for_tm.copy_to_cpu = 1;
    }
    apply {
        bit<18> index_1 = bf_hash_1.get_hash({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        bit<18> index_2 = bf_hash_2.get_hash({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        bit<18> index_3 = bf_hash_3.get_hash({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
        md.bf_temp = (bool)(bloom_fiter_alu_1.execute(index_1) | bloom_filter_alu_2.execute(index_2) | bloom_filter_alu_3.execute(index_3));
        if (md.bf_temp == true) {
            bloom_filter_mark_sample();
        }
    }
}

control ClearBloomFilter(inout headers_t hdr, inout user_metadata_t md) {
    hash<bit<18>>(hash_algorithm_t.IDENTITY) bf_hash;
    bit<18> index = bf_hash.get_hash({ hdr.pktgen_generic.batch_id, hdr.pktgen_generic.packet_id });
    register<bit<1>, bit<18>>(262143) bloom_filter_1;
    register<bit<1>, bit<18>>(262143) bloom_filter_2;
    register<bit<1>, bit<18>>(262143) bloom_filter_3;
    stateful_alu<bit<1>, bit<18>, _, _>(bloom_filter_1) clr_bloom_filter_alu_1 = {
        void instruction(inout bit<1> v) {
            v = (bit<1>)false;
        }
    };
    stateful_alu<bit<1>, bit<18>, _, _>(bloom_filter_2) clr_bloom_filter_alu_2 = {
        void instruction(inout bit<1> v) {
            v = (bit<1>)false;
        }
    };
    stateful_alu<bit<1>, bit<18>, _, _>(bloom_filter_3) clr_bloom_filter_alu_3 = {
        void instruction(inout bit<1> v) {
            v = (bit<1>)false;
        }
    };
    apply {
        clr_bloom_filter_alu_1.execute(index);
        clr_bloom_filter_alu_2.execute(index);
        clr_bloom_filter_alu_3.execute(index);
    }
}

control SipSampler(in headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    register<bit<32>, bit<18>>(143360, 1) sampling_cntr;
    stateful_alu<bit<32>, bit<18>, bit<1>, _>(sampling_cntr) sampling_alu = {
        void instruction(inout bit<32> v, out bit<1> rv) {
            if (v >= 10) {
                v = 1;
            }
            else {
                v = v + 1;
            }
            if (ig_intr_md_for_tm.copy_to_cpu == 1) {
                rv = 0;
            }
        }
    };
    action no_sample() {
    }
    action sample() {
        sampling_alu.execute();
    }
    table sip_sampler {
        key = {
            hdr.ipv4.src_addr: exact;
        }
        actions = {
            sample;
            no_sample;
        }
        size = 85000;
    }
    apply {
        sip_sampler.apply();
    }
}

struct flowlet_state_t {
    bit<16> id;
    bit<48> ts;
}

control Flowlet(inout headers_t hdr, inout user_metadata_t md) {
    stateful_param<bit<32>>(5000) flowlet_inactive_timeout;
    stateful_alu<flowlet_state_t, bit<15>, bit<16>, bit<48>>() flowlet_alu = {
        void instruction(inout flowlet_state_t v, out bit<16> rv, in bit<48> p) {
            if (md.timestamp - v.ts > p && v.id != 65535) {
                v.id = md.nhop_id;
            }
            v.ts = md.timestamp;
            rv = v.id;
        }
    };
    hash<bit<15>>(hash_algorithm_t.CRC16) flowlet_hash;
    bit<15> index = flowlet_hash.get_hash({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.src_port, hdr.tcp.dst_port });
    apply {
        md.nhop_id = flowlet_alu.execute(index);
    }
}

control IpRoute(in headers_t hdr, inout user_metadata_t md) {
    action set_nexthop(nexthop_t nhop_id) {
        md.nhop_id = nhop_id;
    }
    action set_ecmp(bit<16> ecmp_id) {
        md.nhop_id = ecmp_id;
    }
    table ipv4_router {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            set_nexthop;
            set_ecmp;
        }
        size = 512;
    }
    action_selector<bit<29>>(4096, selector_mode_t.FAIR, 0, 0, next_hop_ecmp_reg) next_hop_ecmp_selector = {
        bit<29> hash() {
            hash<bit<29>>(hash_algorithm_t.CRC16) nexthop_ecmp_hash;
            return nexthop_ecmp_hash.get_hash({ hdr.ipv4.proto, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.tcp.dst_port, hdr.tcp.src_port });
        }
    };
    table nexthop_ecmp {
        key = {
            md.nhop_id: exact;
        }
        actions = {
            set_nexthop;
        }
        size = 4096;
        implementation = next_hop_ecmp_selector;
    }
    apply {
        switch (ipv4_router.apply().action_run) {
            set_ecmp: {
                nexthop_ecmp.apply();
            }
        }

    }
}

control EcmpFailover(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    stateful_alu<bit<1>, bit<17>, _, _>() next_hop_ecmp_alu = {
        void instruction(inout bit<1> v) {
            v = (bit<1>)false;
        }
    };
    action set_ecmp_fast_update_key(bit<17> key) {
        md.ecmp_tbl_bit_index = key;
    }
    action drop_ecmp_update_pkt() {
        ig_intr_md_for_tm.drop_ctl = 0x7;
    }
    action set_mbr_down() {
        next_hop_ecmp_alu.execute(md.ecmp_tbl_bit_index);
        ig_intr_md_for_tm.drop_ctl = 0x7;
    }
    table make_key_ecmp_fast_update {
        key = {
            hdr.pktgen_recirc.key      : exact;
            hdr.pktgen_recirc.packet_id: exact;
        }
        actions = {
            set_ecmp_fast_update_key;
            drop_ecmp_update_pkt;
        }
        size = 16384;
    }
    apply {
        make_key_ecmp_fast_update.apply();
        set_mbr_down();
    }
}

control Nexthop(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    register<bit<16>, bit<12>>(4095) scratch;
    stateful_alu<bit<16>, bit<12>, _, _>(scratch) scratch_alu_add = {
        void instruction(inout bit<16> v) {
            v = v + md.nhop_id;
        }
    };
    stateful_alu<bit<16>, bit<12>, _, _>(scratch) scratch_alu_sub = {
        void instruction(inout bit<16> value) {
            value = md.nhop_id - value;
        }
    };
    stateful_alu<bit<16>, bit<12>, _, _>(scratch) scratch_alu_zero = {
        void instruction(inout bit<16> value) {
            value = 0;
        }
    };
    stateful_alu<bit<16>, bit<12>, _, _>(scratch) scratch_alu_invert = {
        void instruction(inout bit<16> value) {
            value = ~value;
        }
    };
    action set_eg_ifindex(ifindex_t ifindex) {
        md.eg_ifindex = ifindex;
    }
    action scratch_add(bit<12> index, ifindex_t ifindex) {
        set_eg_ifindex(ifindex);
        scratch_alu_add.execute(index);
    }
    action scratch_sub(bit<12> index, ifindex_t ifindex) {
        set_eg_ifindex(ifindex);
        scratch_alu_sub.execute(index);
    }
    action scratch_zero(bit<12> index, ifindex_t ifindex) {
        set_eg_ifindex(ifindex);
        scratch_alu_zero.execute(index);
    }
    action scratch_invert(bit<12> index, ifindex_t ifindex) {
        set_eg_ifindex(ifindex);
        scratch_alu_invert.execute(index);
    }
    action next_hop_down(bit<16> mgid) {
        hdr.recirc_hdr.tag = 0xf;
        hdr.recirc_hdr.rtype = 2;
        hdr.recirc_hdr.pad = 0;
        hdr.recirc_hdr.key = md.nhop_id;
        ig_intr_md_for_tm.mcast_grp_b = mgid;
    }
    table next_hop {
        key = {
            md.nhop_id: ternary;
        }
        actions = {
            set_eg_ifindex;
            scratch_add;
            scratch_sub;
            scratch_zero;
            scratch_invert;
            next_hop_down;
        }
        size = 4096;
    }
    apply {
        next_hop.apply();
    }
}

control EgressIfindex(inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    action_selector<bit<66>>(4096, selector_mode_t.FAIR, 128, 1200, lag_reg) lag_as = {
        bit<66> hash() {
        }
    };
    action set_eg_port(bit<9> port) {
        ig_intr_md_for_tm.ucast_egress_port = port;
    }
    table eg_ifindex {
        key = {
            md.eg_ifindex: exact;
        }
        actions = {
            set_eg_port;
        }
        size = 16384;
        implementation = lag_as;
    }
    apply {
        eg_ifindex.apply();
    }
}

control LagFailover(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    stateful_alu<bit<1>, bit<17>, _, _>() lag_alu = {
        void instruction(inout bit<1> v) {
            v = (bit<1>)false;
        }
    };
    action drop_ifindex_update_pkt() {
        ig_intr_md_for_tm.drop_ctl = 0x7;
    }
    action set_lag_fast_update_key(bit<17> key) {
        md.lag_tbl_bit_index = key;
    }
    action set_lag_mbr_down() {
        lag_alu.execute(md.lag_tbl_bit_index);
        ig_intr_md_for_tm.drop_ctl = 0x7;
    }
    table eg_ifindex_fast_update_make_key {
        key = {
            hdr.pktgen_port_down.port_num : exact;
            hdr.pktgen_port_down.packet_id: exact;
        }
        actions = {
            set_lag_fast_update_key;
            drop_ifindex_update_pkt;
        }
        const default_action = drop_ifindex_update_pkt;
        size = 16384;
    }
    apply {
        eg_ifindex_fast_update_make_key.apply();
        set_lag_mbr_down();
    }
}

control IfindexCounter(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    OneBitRead() one_bit_read;
    SipSampler() sip_sampler;
    BloomFilter() bloom_filter;
    Flowlet() flowlet;
    register<bit<16>, _>() ifindex_ctr;
    stateful_alu<bit<16>, _, _, _>() ifindex_cntr_alu = {
        void instruction(inout bit<16> ctr) {
            ctr = ctr + (bit<16>)hdr.ipv4.ttl;
        }
    };
    action run_ifid_cntr() {
        ifindex_cntr_alu.execute();
    }
    action set_ifindex_based_params(bit<48> ts, bit<32> offset) {
        run_ifid_cntr();
        md.timestamp = ts;
        md.offset = offset;
    }
    action drop_it() {
        run_ifid_cntr();
        ig_intr_md_for_tm.drop_ctl = 0x7;
    }
    table ifindex {
        key = {
            md.ifindex: exact;
        }
        actions = {
            set_ifindex_based_params;
            drop_it;
        }
        size = 25000;
        implementation = ifindex_ctr;
    }
    apply {
        switch (ifindex.apply().action_run) {
            drop_it: {
                one_bit_read.apply(md, ig_intr_md, ig_intr_md_for_tm);
            }
            default: {
                bloom_filter.apply(hdr, md, ig_intr_md_for_tm);
                sip_sampler.apply(hdr, md, ig_intr_md_for_tm);
                flowlet.apply(hdr, md);
            }
        }

    }
}

control PgenPass1(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    ClearBloomFilter() clear_bloom_filter;
    EcmpFailover() ecmp_failover;
    action prepare(bit<4> rtype, bit<16> mgid) {
        hdr.recirc_hdr.tag = 0xf;
        hdr.recirc_hdr.rtype = rtype;
        ig_intr_md_for_tm.mcast_grp_b = mgid;
    }
    table prepare_for_recirc {
        key = {
            hdr.pktgen_port_down.app_id: exact;
        }
        actions = {
            prepare;
        }
        size = 7;
    }
    apply {
        if (hdr.pktgen_generic.isValid()) {
            clear_bloom_filter.apply(hdr, md);
        }
        else 
            if (hdr.pktgen_recirc.isValid()) {
                ecmp_failover.apply(hdr, md, ig_intr_md_for_tm);
            }
            else {
                prepare_for_recirc.apply();
            }
    }
}

control PgenPass2(inout headers_t hdr, inout user_metadata_t md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    LagFailover() lag_failover;
    apply {
        if (hdr.recirc_hdr.rtype == 2) {
        }
        else 
            if (hdr.recirc_hdr.rtype == (bit<4>)1) {
                lag_failover.apply(hdr, md, ig_intr_md_for_tm);
            }
    }
}

control SwitchIngress(inout headers_t hdr, inout user_metadata_t md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    IfindexCounter() ifindex_counter;
    OneBitRead() one_bit_read;
    SipSampler() sip_sampler;
    BloomFilter() bloom_filter;
    Flowlet() flowlet;
    PgenPass1() pgen_pass_1;
    PgenPass2() pgen_pass_2;
    apply {
        if (md.recirc_pkt == false && md.pkt_gen_pkt == false) {
            ifindex_counter.apply(hdr, md, ig_intr_md, ig_intr_md_for_tm);
        }
        else 
            if (md.recirc_pkt == false && md.pkt_gen_pkt == true) {
                pgen_pass_1.apply(hdr, md, ig_intr_md_for_tm);
            }
            else 
                if (md.recirc_pkt == true && md.pkt_gen_pkt == false) {
                }
                else {
                    pgen_pass_2.apply(hdr, md, ig_intr_md_for_tm);
                }
    }
}

control SwitchEgress(inout headers_t hdr, inout user_metadata_t md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t md_from_prsr) {
    apply {
    }
}

Switch<headers_t, user_metadata_t, headers_t, user_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) main;
