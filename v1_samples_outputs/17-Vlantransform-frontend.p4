struct Version {
    bit<8> major;
    bit<8> minor;
}

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

action NoAction() {
}
match_kind {
    exact,
    ternary,
    lpm
}

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

enum HashAlgorithm {
    crc32,
    crc16,
    random,
    identity
}

extern ActionSelector {
    ActionSelector(HashAlgorithm algorithm, bit<32> size, bit<32> outputWidth);
}

parser Parser<H, M>(packet_in b, out H parsedHdr, inout M meta, inout standard_metadata_t standard_metadata);
control VerifyChecksum<H, M>(in H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Ingress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Egress<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control ComputeCkecksum<H, M>(inout H hdr, inout M meta, inout standard_metadata_t standard_metadata);
control Deparser<H>(packet_out b, in H hdr);
package V1Switch<H, M>(Parser<H, M> p, VerifyChecksum<H, M> vr, Ingress<H, M> ig, Egress<H, M> eg, ComputeCkecksum<H, M> ck, Deparser<H> dep);
struct metadata_t {
    bit<16> new_outer_tpid;
    bit<3>  new_outer_pri;
    bit<1>  new_outer_cfi;
    bit<12> new_outer_vid;
    bit<16> new_inner_tpid;
    bit<3>  new_inner_pri;
    bit<1>  new_inner_cfi;
    bit<12> new_inner_vid;
    bit<1>  new_outer_tpid_en;
    bit<1>  new_outer_pri_en;
    bit<1>  new_outer_cfi_en;
    bit<1>  new_outer_vid_en;
    bit<1>  new_inner_tpid_en;
    bit<1>  new_inner_pri_en;
    bit<1>  new_inner_cfi_en;
    bit<1>  new_inner_vid_en;
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

header vlan_tag_t {
    bit<3>  pri;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> ethertype;
}

struct metadata {
    @name("meta") 
    metadata_t meta;
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
    @name("vlan_tag") 
    vlan_tag_t[2]                                  vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_vlan_tag") state parse_vlan_tag {
        packet.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.ethertype) {
            16w0x8100: parse_vlan_tag;
            default: accept;
        }
    }
    @name("start") state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x8100: parse_vlan_tag;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("do_new_inner_cfi") action do_new_inner_cfi() {
        hdr.vlan_tag[1].cfi = meta.meta.new_inner_cfi;
    }
    @name("do_new_inner_pri") action do_new_inner_pri() {
        hdr.vlan_tag[1].pri = meta.meta.new_inner_pri;
    }
    @name("do_new_inner_tpid") action do_new_inner_tpid() {
        hdr.vlan_tag[0].ethertype = meta.meta.new_inner_tpid;
    }
    @name("do_new_inner_vid") action do_new_inner_vid() {
        hdr.vlan_tag[1].vid = meta.meta.new_inner_vid;
    }
    @name("do_new_outer_cfi") action do_new_outer_cfi() {
        hdr.vlan_tag[0].cfi = meta.meta.new_outer_cfi;
    }
    @name("do_new_outer_pri") action do_new_outer_pri() {
        hdr.vlan_tag[0].pri = meta.meta.new_outer_pri;
    }
    @name("do_new_outer_tpid") action do_new_outer_tpid() {
        hdr.ethernet.ethertype = meta.meta.new_outer_tpid;
    }
    @name("do_new_outer_vid") action do_new_outer_vid() {
        hdr.vlan_tag[0].vid = meta.meta.new_outer_vid;
    }
    @name("nop") action nop() {
    }
    @name("rewrite_tags") action rewrite_tags(bit<16> new_outer_tpid, bit<1> new_outer_tpid_en, bit<3> new_outer_pri, bit<1> new_outer_pri_en, bit<1> new_outer_cfi, bit<1> new_outer_cfi_en, bit<12> new_outer_vid, bit<1> new_outer_vid_en, bit<16> new_inner_tpid, bit<1> new_inner_tpid_en, bit<3> new_inner_pri, bit<1> new_inner_pri_en, bit<1> new_inner_cfi, bit<1> new_inner_cfi_en, bit<12> new_inner_vid, bit<1> new_inner_vid_en) {
        meta.meta.new_outer_tpid = new_outer_tpid;
        meta.meta.new_outer_tpid_en = new_outer_tpid_en;
        meta.meta.new_outer_pri = new_outer_pri;
        meta.meta.new_outer_pri_en = new_outer_pri_en;
        meta.meta.new_outer_cfi = new_outer_cfi;
        meta.meta.new_outer_cfi_en = new_outer_cfi_en;
        meta.meta.new_outer_vid = new_outer_vid;
        meta.meta.new_outer_vid_en = new_outer_vid_en;
        meta.meta.new_inner_tpid = new_inner_tpid;
        meta.meta.new_inner_tpid_en = new_inner_tpid_en;
        meta.meta.new_inner_pri = new_inner_pri;
        meta.meta.new_inner_pri_en = new_inner_pri_en;
        meta.meta.new_inner_cfi = new_inner_cfi;
        meta.meta.new_inner_cfi_en = new_inner_cfi_en;
        meta.meta.new_inner_vid = new_inner_vid;
        meta.meta.new_inner_vid_en = new_inner_vid_en;
    }
    @name("new_inner_cfi") table new_inner_cfi() {
        actions = {
            do_new_inner_cfi();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_inner_pri") table new_inner_pri() {
        actions = {
            do_new_inner_pri();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_inner_tpid") table new_inner_tpid() {
        actions = {
            do_new_inner_tpid();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_inner_vid") table new_inner_vid() {
        actions = {
            do_new_inner_vid();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_outer_cfi") table new_outer_cfi() {
        actions = {
            do_new_outer_cfi();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_outer_pri") table new_outer_pri() {
        actions = {
            do_new_outer_pri();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_outer_tpid") table new_outer_tpid() {
        actions = {
            do_new_outer_tpid();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("new_outer_vid") table new_outer_vid() {
        actions = {
            do_new_outer_vid();
            NoAction();
        }
        default_action = NoAction();
    }
    @name("vlan_xlate") table vlan_xlate() {
        actions = {
            nop();
            rewrite_tags();
            NoAction();
        }
        key = {
            hdr.vlan_tag[0].isValid(): exact;
            hdr.vlan_tag[0].vid      : exact;
            hdr.vlan_tag[1].isValid(): exact;
            hdr.vlan_tag[1].vid      : exact;
        }
        default_action = NoAction();
    }
    apply {
        vlan_xlate.apply();
        if (meta.meta.new_outer_tpid_en == 1w1) 
            new_outer_tpid.apply();
        if (meta.meta.new_outer_pri_en == 1w1) 
            new_outer_pri.apply();
        if (meta.meta.new_outer_cfi_en == 1w1) 
            new_outer_cfi.apply();
        if (meta.meta.new_outer_vid_en == 1w1) 
            new_outer_vid.apply();
        if (meta.meta.new_inner_tpid_en == 1w1) 
            new_inner_tpid.apply();
        if (meta.meta.new_inner_pri_en == 1w1) 
            new_inner_pri.apply();
        if (meta.meta.new_inner_cfi_en == 1w1) 
            new_inner_cfi.apply();
        if (meta.meta.new_inner_vid_en == 1w1) 
            new_inner_vid.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
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
