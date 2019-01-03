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

Register<bit<1>, bit<32>>(32w262144) bloom_filter_1;

Register<bit<1>, bit<32>>(32w262144) bloom_filter_2;

Register<bit<1>, bit<32>>(32w262144) bloom_filter_3;

struct tuple_0 {
    bit<8>  field;
    bit<32> field_0;
    bit<32> field_1;
    bit<16> field_2;
    bit<16> field_3;
}

control IngressP(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    bit<32> tmp;
    bit<1> tmp_0;
    bit<32> tmp_2;
    bit<1> tmp_3;
    bit<32> tmp_5;
    bit<1> tmp_6;
    @name(".NoAction") action NoAction_0() {
    }
    @name(".bloom_filter_alu_1") RegisterAction<bit<1>, bit<32>, bit<1>>(bloom_filter_1) bloom_filter_alu = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".bloom_filter_alu_2") RegisterAction<bit<1>, bit<32>, bit<1>>(bloom_filter_2) bloom_filter_alu_0 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name(".bloom_filter_alu_3") RegisterAction<bit<1>, bit<32>, bit<1>>(bloom_filter_3) bloom_filter_alu_4 = {
        void apply(inout bit<1> value, out bit<1> rv) {
            value = 1w1;
            rv = 1w0;
        }
    };
    @name("IngressP.hash_1") Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash_0;
    @name("IngressP.hash_2") Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash_4;
    @name("IngressP.hash_3") Hash<bit<32>>(HashAlgorithm_t.RANDOM) hash_5;
    @name(".check_bloom_filter_1") action check_bloom_filter_1() {
        tmp = hash_0.get<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 32w0, 32w262144);
        tmp_0 = bloom_filter_alu.execute(tmp);
        meta.md.bf_tmp = meta.md.bf_tmp | tmp_0;
    }
    @name(".check_bloom_filter_1") action check_bloom_filter_2() {
        tmp_2 = hash_4.get<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 32w0, 32w262144);
        tmp_3 = bloom_filter_alu_0.execute(tmp_2);
        meta.md.bf_tmp = meta.md.bf_tmp | tmp_3;
    }
    @name(".check_bloom_filter_1") action check_bloom_filter_3() {
        tmp_5 = hash_5.get<tuple_0>({ hdr.ipv4.proto, hdr.ipv4.sip, hdr.ipv4.dip, hdr.tcp.sPort, hdr.tcp.dPort }, 32w0, 32w262144);
        tmp_6 = bloom_filter_alu_4.execute(tmp_5);
        meta.md.bf_tmp = meta.md.bf_tmp | tmp_6;
    }
    @name(".bloom_filter_mark_sample") action bloom_filter_mark_sample() {
        ig_intr_tm_md.copy_to_cpu = true;
    }
    @name(".bloom_filter_1") table bloom_filter_1_1 {
        actions = {
            check_bloom_filter_1();
        }
        default_action = check_bloom_filter_1();
        size = 1;
    }
    @name(".bloom_filter_1") table bloom_filter_2_1 {
        actions = {
            check_bloom_filter_2();
        }
        default_action = check_bloom_filter_2();
        size = 1;
    }
    @name(".bloom_filter_1") table bloom_filter_3_1 {
        actions = {
            check_bloom_filter_3();
        }
        default_action = check_bloom_filter_3();
        size = 1;
    }
    @name(".bloom_filter_sample") table bloom_filter_sample_0 {
        actions = {
            bloom_filter_mark_sample();
            @defaultonly NoAction_0();
        }
        size = 1;
        default_action = NoAction_0();
    }
    apply {
        bloom_filter_1_1.apply();
        bloom_filter_2_1.apply();
        bloom_filter_3_1.apply();
        if (meta.md.bf_tmp != 1w0) 
            bloom_filter_sample_0.apply();
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

