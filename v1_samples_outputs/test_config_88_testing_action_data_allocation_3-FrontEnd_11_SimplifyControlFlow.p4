struct Version {
    bit<8> major;
    bit<8> minor;
}

const Version P4_VERSION = { 8w1, 8w2 };
error {
    NoError,
    PacketTooShort,
    NoMatch,
    EmptyStack,
    FullStack,
    OverwritingHeader
}

extern packet_in {
    void extract<T>(out T hdr);
    void extract<T>(out T variableSizeHeader, in bit<32> sizeInBits);
    T lookahead<T>();
    void advance(in bit<32> sizeInBits);
    bit<32> length();
}

extern packet_out {
    void emit<T>(in T hdr);
}

extern void verify(in bool check, in error toSignal);
action NoAction() {
}
match_kind {
    exact,
    ternary,
    lpm
}

const Version v1modelVersion = { 8w0, 8w1 };
match_kind {
    range,
    selector
}

struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    bit<1>  drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
}

extern Checksum16 {
    bit<16> get<D>(in D data);
}

enum CounterType {
    Packets,
    Bytes,
    Both
}

extern Counter {
    Counter(bit<32> size, CounterType type);
    void increment(in bit<32> index);
}

extern DirectCounter {
    DirectCounter(CounterType type);
}

extern Meter {
    Meter(bit<32> size, CounterType type);
    void meter<T>(in bit<32> index, out T result);
}

extern DirectMeter<T> {
    DirectMeter(CounterType type);
    void read(out T result);
}

extern Register<T> {
    Register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern ActionProfile {
    ActionProfile(bit<32> size);
}

extern bit<32> random(in bit<5> logRange);
extern void digest<T>(in bit<32> receiver, in T data);
enum HashAlgorithm {
    crc32,
    crc16,
    random,
    identity
}

extern void mark_to_drop();
extern void hash<O, T, D, M>(out O result, in HashAlgorithm algo, in T base, in D data, in M max);
extern ActionSelector {
    ActionSelector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

enum CloneType {
    I2E,
    E2E
}

extern void resubmit<T>(in T data);
extern void recirculate<T>(in T data);
extern void clone(in CloneType type, in bit<32> session);
extern void clone3<T>(in CloneType type, in bit<32> session, in T data);
parser Parser<H, M>(packet_in b, out H parsedHdr, inout M meta, inout standard_metadata_t standard_metadata);
control VerifyChecksum<H, M>(in H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Ingress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Egress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control ComputeCkecksum<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Deparser<H>(packet_out b, in H hdr);
package V1Switch<H, M>(Parser<H, M> p, VerifyChecksum<H, M> vr, Ingress<H, M> ig, Egress<H, M> eg, ComputeCkecksum<H, M> ck, Deparser<H> dep);
struct egress_intrinsic_metadata_t {
    bit<16> egress_port;
    bit<5>  _pad1;
    bit<19> enq_qdepth;
    bit<6>  _pad2;
    bit<2>  enq_congest_stat;
    bit<32> enq_tstamp;
    bit<5>  _pad3;
    bit<19> deq_qdepth;
    bit<6>  _pad4;
    bit<2>  deq_congest_stat;
    bit<8>  app_pool_congest_stat;
    bit<32> deq_timedelta;
    bit<16> egress_rid;
    bit<7>  _pad5;
    bit<1>  egress_rid_first;
    bit<3>  _pad6;
    bit<5>  egress_qid;
    bit<5>  _pad7;
    bit<3>  egress_cos;
    bit<7>  _pad8;
    bit<1>  deflection_flag;
    bit<16> pkt_length;
}

struct egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

struct egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

struct egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<8>  clone_src;
    bit<8>  coalesce_sample_count;
}

struct ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

struct ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

struct ingress_intrinsic_metadata_for_tm_t {
    bit<7>  _pad1;
    bit<9>  ucast_egress_port;
    bit<3>  drop_ctl;
    bit<1>  bypass_egress;
    bit<1>  deflect_on_drop;
    bit<3>  ingress_cos;
    bit<5>  qid;
    bit<3>  icos_for_copy_to_cpu;
    bit<3>  _pad2;
    bit<1>  copy_to_cpu;
    bit<2>  packet_color;
    bit<1>  disable_ucast_cutthru;
    bit<1>  enable_mcast_cutthru;
    bit<16> mcast_grp_a;
    bit<16> mcast_grp_b;
    bit<3>  _pad3;
    bit<13> level1_mcast_hash;
    bit<3>  _pad4;
    bit<13> level2_mcast_hash;
    bit<16> level1_exclusion_id;
    bit<7>  _pad5;
    bit<9>  level2_exclusion_id;
    bit<16> rid;
}

struct ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

struct generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

struct ingress_parser_control_signals {
    bit<3> priority;
}

struct meta_t {
    bit<32> meta_a_32;
    bit<32> meta_b_32;
    bit<32> meta_c_32;
    bit<32> meta_d_32;
}

header pkt_t {
    bit<32> field_a_32;
    bit<32> field_b_32;
    bit<32> field_c_32;
    bit<32> field_d_32;
    bit<16> field_e_16;
    bit<16> field_f_16;
    bit<16> field_g_16;
    bit<16> field_h_16;
    bit<8>  field_i_8;
    bit<8>  field_j_8;
    bit<8>  field_k_8;
    bit<8>  field_l_8;
}

struct metadata {
    @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name("ig_intr_md") 
    ingress_intrinsic_metadata_t                   ig_intr_md;
    @name("ig_intr_md_for_mb") 
    ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb;
    @name("ig_intr_md_for_tm") 
    ingress_intrinsic_metadata_for_tm_t            ig_intr_md_for_tm;
    @name("ig_intr_md_from_parser_aux") 
    ingress_intrinsic_metadata_from_parser_aux_t   ig_intr_md_from_parser_aux;
    @name("ig_pg_md") 
    generator_metadata_t                           ig_pg_md;
    @name("ig_prsr_ctrl") 
    ingress_parser_control_signals                 ig_prsr_ctrl;
    @name("meta") 
    meta_t                                         meta;
}

struct headers {
    @name("pkt") 
    pkt_t pkt;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_test") state parse_test {
        packet.extract(hdr.pkt);
        transition accept;
    }
    @name("start") state start {
        transition parse_test;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("action_0") action action_0(bit<32> param_a_32) {
        hdr.pkt.field_a_32 = param_a_32;
    }
    @name("action_1") action action_1(bit<16> param_e_16) {
        hdr.pkt.field_e_16 = param_e_16;
    }
    @name("action_2") action action_2(bit<8> param_i_8) {
        hdr.pkt.field_i_8 = param_i_8;
    }
    @name("action_3") action action_3(bit<32> param_b_32) {
        hdr.pkt.field_b_32 = hdr.pkt.field_b_32 & 32w0x5000 | param_b_32 & 32w0xffffafff;
    }
    @name("action_4") action action_4(bit<16> param_f_16) {
        hdr.pkt.field_f_16 = hdr.pkt.field_f_16 & 16w0x500 | param_f_16 & 16w0xfaff;
    }
    @name("action_5") action action_5(bit<8> param_j_8) {
        hdr.pkt.field_j_8 = hdr.pkt.field_j_8 & 8w0x55 | param_j_8 & 8w0xaa;
    }
    @name("action_6") action action_6(bit<32> param_c_32, bit<16> param_g_16, bit<8> param_k_8) {
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_g_16 = param_g_16;
        hdr.pkt.field_k_8 = param_k_8;
    }
    @name("action_7") action action_7(bit<32> param_c_32, bit<32> param_d_32, bit<16> param_h_16, bit<8> param_l_8, bit<32> param_a_32, bit<16> param_e_16) {
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_d_32 = param_d_32;
        hdr.pkt.field_h_16 = param_h_16;
        hdr.pkt.field_l_8 = param_l_8;
        hdr.pkt.field_a_32 = hdr.pkt.field_a_32 & 32w0xffff0030 | param_a_32 & 32w0xffcf;
        hdr.pkt.field_e_16 = hdr.pkt.field_e_16 & 16w0x300 | param_e_16 & 16w0xfcff;
    }
    @name("action_8") action action_8(bit<8> param_i_8, bit<8> param_j_8, bit<8> param_k_8) {
        hdr.pkt.field_i_8 = param_i_8;
        hdr.pkt.field_j_8 = param_j_8;
        hdr.pkt.field_k_8 = param_k_8;
    }
    @name("action_9") action action_9(bit<16> param_e_16, bit<16> param_f_16, bit<16> param_g_16) {
        hdr.pkt.field_e_16 = param_e_16;
        hdr.pkt.field_f_16 = param_f_16;
        hdr.pkt.field_g_16 = param_g_16;
    }
    @name("action_10") action action_10(bit<32> param_a_32, bit<32> param_b_32, bit<32> param_c_32, bit<32> param_d_32) {
        hdr.pkt.field_a_32 = param_a_32;
        hdr.pkt.field_b_32 = param_b_32;
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_d_32 = param_d_32;
    }
    @name("action_11") action action_11(bit<32> param_a_32, bit<32> param_b_32, bit<32> param_c_32, bit<16> param_e_16, bit<16> param_f_16, bit<16> param_g_16, bit<8> param_i_8, bit<8> param_j_8, bit<8> param_k_8, bit<8> param_l_8) {
        hdr.pkt.field_a_32 = param_a_32;
        hdr.pkt.field_b_32 = param_b_32;
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_e_16 = param_e_16;
        hdr.pkt.field_f_16 = param_f_16;
        hdr.pkt.field_g_16 = param_g_16;
        hdr.pkt.field_i_8 = param_i_8;
        hdr.pkt.field_j_8 = param_j_8;
        hdr.pkt.field_k_8 = param_k_8;
        hdr.pkt.field_l_8 = param_l_8;
    }
    @name("action_12") action action_12(bit<32> param_a_32, bit<32> param_b_32, bit<32> param_c_32, bit<8> param_i_8, bit<8> param_j_8, bit<8> param_k_8, bit<8> param_l_8) {
        hdr.pkt.field_a_32 = hdr.pkt.field_a_32 & 32w0xffff0030 | param_a_32 & 32w0xffcf;
        hdr.pkt.field_b_32 = hdr.pkt.field_b_32 & 32w0xffff0300 | param_b_32 & 32w0xfcff;
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_i_8 = param_i_8;
        hdr.pkt.field_j_8 = param_j_8;
        hdr.pkt.field_k_8 = param_k_8;
        hdr.pkt.field_l_8 = param_l_8;
    }
    @name("action_13") action action_13(bit<32> param_a_32, bit<32> param_b_32, bit<32> param_c_32, bit<16> param_e_16, bit<16> param_f_16, bit<16> param_g_16, bit<16> param_h_16) {
        hdr.pkt.field_a_32 = hdr.pkt.field_a_32 & 32w0xffff0030 | param_a_32 & 32w0xffcf;
        hdr.pkt.field_b_32 = hdr.pkt.field_b_32 & 32w0xffff0300 | param_b_32 & 32w0xfcff;
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_e_16 = param_e_16;
        hdr.pkt.field_f_16 = param_f_16;
        hdr.pkt.field_g_16 = param_g_16;
        hdr.pkt.field_h_16 = param_h_16;
    }
    @name("action_14") action action_14(bit<32> param_a_32, bit<32> param_b_32, bit<32> param_c_32, bit<32> param_d_32, bit<32> param_meta_a_32) {
        hdr.pkt.field_a_32 = hdr.pkt.field_a_32 & 32w0xffff0030 | param_a_32 & 32w0xffcf;
        hdr.pkt.field_b_32 = hdr.pkt.field_b_32 & 32w0xffff0300 | param_b_32 & 32w0xfcff;
        hdr.pkt.field_c_32 = param_c_32;
        hdr.pkt.field_d_32 = param_d_32;
        meta.meta.meta_a_32 = param_meta_a_32;
    }
    @name("action_15") action action_15() {
    }
    @name("table_0") table table_0() {
        actions = {
            action_0;
            action_1;
            action_2;
            action_3;
            action_4;
            action_5;
            action_6;
            action_7;
            action_8;
            action_9;
            action_10;
            action_11;
            action_12;
            action_13;
            action_14;
            action_15;
            NoAction;
        }
        key = {
            hdr.pkt.field_b_32: exact;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        table_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.pkt);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
