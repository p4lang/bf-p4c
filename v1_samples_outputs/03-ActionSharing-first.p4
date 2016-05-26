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
    packets,
    bytes,
    packets_and_bytes
}

extern counter {
    counter(bit<32> size, CounterType type);
    void count(in bit<32> index);
}

extern direct_counter {
    direct_counter(CounterType type);
}

extern meter {
    meter(bit<32> size, CounterType type);
    void execute_meter<T>(in bit<32> index, out T result);
}

extern direct_meter<T> {
    direct_meter(CounterType type);
    void read(out T result);
}

extern register<T> {
    register(bit<32> size);
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern action_profile {
    action_profile(bit<32> size);
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
extern action_selector {
    action_selector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
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
struct metadata_t {
    bit<1>  field1_1;
    bit<1>  field1_2;
    bit<1>  field1_3;
    bit<1>  field1_4;
    bit<1>  field1_5;
    bit<1>  field1_6;
    bit<1>  field1_7;
    bit<1>  field1_8;
    bit<8>  field8_1;
    bit<8>  field8_2;
    bit<8>  field8_3;
    bit<8>  field8_4;
    bit<8>  field8_5;
    bit<8>  field8_6;
    bit<8>  field8_7;
    bit<8>  field8_8;
    bit<64> field16_1;
    bit<64> field16_2;
    bit<64> field16_3;
    bit<64> field16_4;
    bit<64> field16_5;
    bit<64> field16_6;
    bit<64> field16_7;
    bit<64> field16_8;
    bit<32> field32_1;
    bit<32> field32_2;
    bit<32> field32_3;
    bit<32> field32_4;
    bit<32> field32_5;
    bit<32> field32_6;
    bit<32> field32_7;
    bit<32> field32_8;
}

header egress_intrinsic_metadata_t {
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

header egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> egress_mirror_id;
    bit<1>  coalesce_flush;
    bit<7>  coalesce_length;
}

header egress_intrinsic_metadata_for_output_port_t {
    bit<2> _pad1;
    bit<1> capture_tstamp_on_tx;
    bit<1> update_delay_on_tx;
    bit<1> force_tx_error;
    bit<3> drop_ctl;
}

header egress_intrinsic_metadata_from_parser_aux_t {
    bit<48> egress_global_tstamp;
    bit<32> egress_global_ver;
    bit<16> egress_parser_err;
    bit<8>  clone_src;
    bit<8>  coalesce_sample_count;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> ethertype;
}

header ingress_intrinsic_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  _pad2;
    bit<3>  _pad3;
    bit<9>  ingress_port;
    bit<48> ingress_mac_tstamp;
}

header ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<6>  _pad1;
    bit<10> ingress_mirror_id;
}

header ingress_intrinsic_metadata_for_tm_t {
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

header ingress_intrinsic_metadata_from_parser_aux_t {
    bit<48> ingress_global_tstamp;
    bit<32> ingress_global_ver;
    bit<16> ingress_parser_err;
}

header generator_metadata_t {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header ingress_parser_control_signals {
    bit<3> priority;
}

struct metadata {
    @name("md") 
    metadata_t md;
}

struct headers {
    @name("eg_intr_md") 
    egress_intrinsic_metadata_t                    eg_intr_md;
    @name("eg_intr_md_for_mb") 
    egress_intrinsic_metadata_for_mirror_buffer_t  eg_intr_md_for_mb;
    @name("eg_intr_md_for_oport") 
    egress_intrinsic_metadata_for_output_port_t    eg_intr_md_for_oport;
    @name("eg_intr_md_from_parser_aux") 
    egress_intrinsic_metadata_from_parser_aux_t    eg_intr_md_from_parser_aux;
    @name("ethernet") 
    ethernet_t                                     ethernet;
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
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("start") state start {
        packet.extract(hdr.ethernet);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("set_field1_1") action set_field1_1(bit<1> value) {
        meta.md.field1_1 = value;
    }
    @name("set_field1_2") action set_field1_2(bit<1> value) {
        meta.md.field1_2 = value;
    }
    @name("set_field1_3") action set_field1_3(bit<1> value) {
        meta.md.field1_3 = value;
    }
    @name("set_field1_4") action set_field1_4(bit<1> value) {
        meta.md.field1_4 = value;
    }
    @name("set_field1_5") action set_field1_5(bit<1> value) {
        meta.md.field1_5 = value;
    }
    @name("set_field1_6") action set_field1_6(bit<1> value) {
        meta.md.field1_6 = value;
    }
    @name("set_field1_7") action set_field1_7(bit<1> value) {
        meta.md.field1_7 = value;
    }
    @name("set_field1_8") action set_field1_8(bit<1> value) {
        meta.md.field1_8 = value;
    }
    @name("set_field8_1") action set_field8_1(bit<8> value) {
        meta.md.field8_1 = value;
    }
    @name("set_field8_2") action set_field8_2(bit<8> value) {
        meta.md.field8_2 = value;
    }
    @name("set_field8_3") action set_field8_3(bit<8> value) {
        meta.md.field8_3 = value;
    }
    @name("set_field8_4") action set_field8_4(bit<8> value) {
        meta.md.field8_4 = value;
    }
    @name("set_field8_5") action set_field8_5(bit<8> value) {
        meta.md.field8_5 = value;
    }
    @name("set_field8_6") action set_field8_6(bit<8> value) {
        meta.md.field8_6 = value;
    }
    @name("set_field8_7") action set_field8_7(bit<8> value) {
        meta.md.field8_7 = value;
    }
    @name("set_field8_8") action set_field8_8(bit<8> value) {
        meta.md.field8_8 = value;
    }
    @name("set_field16_1") action set_field16_1(bit<64> value) {
        meta.md.field16_1 = value;
    }
    @name("set_field16_2") action set_field16_2(bit<64> value) {
        meta.md.field16_2 = value;
    }
    @name("set_field16_3") action set_field16_3(bit<64> value) {
        meta.md.field16_3 = value;
    }
    @name("set_field16_4") action set_field16_4(bit<64> value) {
        meta.md.field16_4 = value;
    }
    @name("set_field16_5") action set_field16_5(bit<64> value) {
        meta.md.field16_5 = value;
    }
    @name("set_field16_6") action set_field16_6(bit<64> value) {
        meta.md.field16_6 = value;
    }
    @name("set_field16_7") action set_field16_7(bit<64> value) {
        meta.md.field16_7 = value;
    }
    @name("set_field16_8") action set_field16_8(bit<64> value) {
        meta.md.field16_8 = value;
    }
    @name("set_field32_1") action set_field32_1(bit<32> value) {
        meta.md.field32_1 = value;
    }
    @name("set_field32_2") action set_field32_2(bit<32> value) {
        meta.md.field32_2 = value;
    }
    @name("set_field32_3") action set_field32_3(bit<32> value) {
        meta.md.field32_3 = value;
    }
    @name("set_field32_4") action set_field32_4(bit<32> value) {
        meta.md.field32_4 = value;
    }
    @name("set_field32_5") action set_field32_5(bit<32> value) {
        meta.md.field32_5 = value;
    }
    @name("set_field32_6") action set_field32_6(bit<32> value) {
        meta.md.field32_6 = value;
    }
    @name("set_field32_7") action set_field32_7(bit<32> value) {
        meta.md.field32_7 = value;
    }
    @name("dmac1") table dmac1() {
        actions = {
            set_field1_1();
            set_field1_2();
            set_field1_3();
            set_field1_4();
            set_field1_5();
            set_field1_6();
            set_field1_7();
            set_field1_8();
            set_field8_1();
            set_field8_2();
            set_field8_3();
            set_field8_4();
            set_field8_5();
            set_field8_6();
            set_field8_7();
            set_field8_8();
            set_field16_1();
            set_field16_2();
            set_field16_3();
            set_field16_4();
            set_field16_5();
            set_field16_6();
            set_field16_7();
            set_field16_8();
            set_field32_1();
            set_field32_2();
            set_field32_3();
            set_field32_4();
            set_field32_5();
            set_field32_6();
            set_field32_7();
            NoAction();
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 32768;
        default_action = NoAction();
    }
    @name("dmac2") table dmac2() {
        actions = {
            set_field1_1();
            set_field1_2();
            set_field1_3();
            set_field1_4();
            set_field1_5();
            set_field1_6();
            set_field1_7();
            set_field1_8();
            set_field8_1();
            set_field8_2();
            set_field8_3();
            set_field8_4();
            set_field8_5();
            set_field8_6();
            set_field8_7();
            set_field8_8();
            set_field16_1();
            set_field16_2();
            set_field16_3();
            set_field16_4();
            set_field16_5();
            set_field16_6();
            set_field16_7();
            set_field16_8();
            set_field32_1();
            set_field32_2();
            set_field32_3();
            set_field32_4();
            set_field32_5();
            set_field32_6();
            set_field32_7();
            NoAction();
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 32768;
        default_action = NoAction();
    }
    apply {
        if ((hdr.ig_intr_md.ingress_port & 9w0x1) == 9w0x1) 
            dmac1.apply();
        else 
            dmac2.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
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
