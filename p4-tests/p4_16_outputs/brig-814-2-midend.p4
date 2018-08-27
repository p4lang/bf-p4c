#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

struct user_metadata_t {
    bit<1> bf_tmp;
}

header ethernet_t {
    bit<48> dmac;
    bit<48> smac;
    bit<16> ethertype;
}

header ipv4_t {
    bit<4>  ver;
    bit<4>  len;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> id;
    bit<3>  flags;
    bit<13> offset;
    bit<8>  ttl;
    bit<8>  proto;
    bit<16> csum;
    bit<32> sip;
    bit<32> dip;
}

header tcp_t {
    bit<16> sPort;
    bit<16> dPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    tcp_t      tcp;
}

struct metadata {
    user_metadata_t md;
}

parser ParserI(packet_in packet, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x800: parse_ipv4;
            default: noMatch;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.proto) {
            8w6: parse_tcp;
            default: noMatch;
        }
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract<tcp_t>(hdr.tcp);
        transition accept;
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

Register<bit<1>>(32w262144) bloom_filter_1;

Register<bit<1>>(32w262144) bloom_filter_2;

Register<bit<1>>(32w262144) bloom_filter_3;

struct tuple_0 {
    bit<8>  field;
    bit<32> field_0;
    bit<32> field_1;
    bit<16> field_2;
    bit<16> field_3;
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    bit<32> tmp_8;
    bit<1> tmp_9;
    bit<32> tmp_11;
    bit<1> tmp_12;
    bit<32> tmp_14;
    bit<1> tmp_15;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".NoAction") action NoAction_5() {
    }
    @name(".NoAction") action NoAction_6() {
    }
    @name(".NoAction") action NoAction_7() {
    }
    @name(".bloom_filter_alu_1") RegisterAction<bit<1>, bit<1>>(bloom_filter_1) bloom_filter_alu_1 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".bloom_filter_alu_2") RegisterAction<bit<1>, bit<1>>(bloom_filter_2) bloom_filter_alu_2 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".bloom_filter_alu_3") RegisterAction<bit<1>, bit<1>>(bloom_filter_3) bloom_filter_alu_3 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name("IngressP.hash_1") Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash_1;
    @name("IngressP.hash_2") Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash_2;
    @name("IngressP.hash_3") Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash_3;
    @name(".check_bloom_filter_1") action check_bloom_filter() {
        tmp_8 = hash_1.get<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 32w0, 32w262144);
        tmp_9 = bloom_filter_alu_1.execute(tmp_8);
        meta.md.bf_tmp = meta.md.bf_tmp | tmp_9;
    }
    @name(".check_bloom_filter_1") action check_bloom_filter_0() {
        tmp_11 = hash_2.get<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 32w0, 32w262144);
        tmp_12 = bloom_filter_alu_2.execute(tmp_11);
        meta.md.bf_tmp = meta.md.bf_tmp | tmp_12;
    }
    @name(".check_bloom_filter_1") action check_bloom_filter_4() {
        tmp_14 = hash_3.get<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 32w0, 32w262144);
        tmp_15 = bloom_filter_alu_3.execute(tmp_14);
        meta.md.bf_tmp = meta.md.bf_tmp | tmp_15;
    }
    @name(".bloom_filter_mark_sample") action bloom_filter_mark_sample_0() {
        ig_intr_tm_md.copy_to_cpu = true;
    }
    @name(".bloom_filter_1") table bloom_filter_1_0 {
        actions = {
            check_bloom_filter();
            @defaultonly NoAction_0();
        }
        size = 1;
        default_action = NoAction_0();
    }
    @name(".bloom_filter_1") table bloom_filter_2_0 {
        actions = {
            check_bloom_filter_0();
            @defaultonly NoAction_5();
        }
        size = 1;
        default_action = NoAction_5();
    }
    @name(".bloom_filter_1") table bloom_filter_3_0 {
        actions = {
            check_bloom_filter_4();
            @defaultonly NoAction_6();
        }
        size = 1;
        default_action = NoAction_6();
    }
    @name(".bloom_filter_sample") table bloom_filter_sample {
        actions = {
            bloom_filter_mark_sample_0();
            @defaultonly NoAction_7();
        }
        size = 1;
        default_action = NoAction_7();
    }
    apply {
        bloom_filter_1_0.apply();
        bloom_filter_2_0.apply();
        bloom_filter_3_0.apply();
        if (meta.md.bf_tmp != 1w0) 
            bloom_filter_sample.apply();
    }
}

control DeparserI(packet_out b, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    @hidden action act() {
        b.emit<ethernet_t>(hdr.ethernet);
        b.emit<ipv4_t>(hdr.ipv4);
        b.emit<tcp_t>(hdr.tcp);
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

parser ParserE(packet_in b, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        b.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

control EgressP(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_prsr_md, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control DeparserE(packet_out b, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    @hidden action act_0() {
        b.emit<ethernet_t>(hdr.ethernet);
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

Pipeline<headers, metadata, headers, metadata>(ParserI(), IngressP(), DeparserI(), ParserE(), EgressP(), DeparserE()) pipe0;

Switch<headers, metadata, headers, metadata, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

