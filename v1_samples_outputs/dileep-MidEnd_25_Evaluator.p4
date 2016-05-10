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
control ComputeCkecksum<H, M>(inout H hdr, inout M meta);
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

struct routing_metadata_t {
    bit<1> drop;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
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

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdr_length;
    bit<16> checksum;
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
    @name("routing_metadata") 
    routing_metadata_t                             routing_metadata;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("ipv4") 
    ipv4_t     ipv4;
    @name("tcp") 
    tcp_t      tcp;
    @name("udp") 
    udp_t      udp;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name("parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.protocol) {
            (13w0, 8w6): parse_tcp;
            (13w0, 8w17): parse_udp;
            default: accept;
        }
    }
    @name("parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    @name("parse_udp") state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action NoAction_0() {
    }
    action NoAction_1() {
    }
    action NoAction_2() {
    }
    action NoAction_3() {
    }
    action NoAction_4() {
    }
    action NoAction_5() {
    }
    action NoAction_6() {
    }
    @name("nop") action nop_0() {
    }
    @name("nop") action nop() {
    }
    @name("nop") action nop_1() {
    }
    @name("nop") action nop_2() {
    }
    @name("nop") action nop_3() {
    }
    @name("nop") action nop_4() {
    }
    @name("nop") action nop_5() {
    }
    @name("hop_ipv4") action hop_ipv4_0(bit<9> egress_port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name("hop_ipv4") action hop_ipv4(bit<9> egress_port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name("next_hop_ipv4") action next_hop_ipv4_0(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("next_hop_ipv4") action next_hop_ipv4(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("mod_mac_adr") action mod_mac_adr_0(bit<9> egress_port, bit<48> srcmac, bit<48> dstmac) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.ethernet.srcAddr = srcmac;
        hdr.ethernet.dstAddr = dstmac;
    }
    @name("tcp_hdr_rm") action tcp_hdr_rm_0(bit<9> egress_port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.tcp.setInvalid();
        hdr.ipv4.protocol = 8w0;
    }
    @name("udp_hdr_add") action udp_hdr_add_0(bit<9> egress_port) {
        meta.ig_intr_md_for_tm.ucast_egress_port = egress_port;
        hdr.udp.setValid();
        hdr.ipv4.protocol = 8w17;
        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 16w8;
    }
    @name("ipv4_routing") table ipv4_routing_0() {
        actions = {
            nop_0;
            hop_ipv4_0;
            NoAction_0;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        default_action = NoAction_0();
    }
    @name("ipv4_routing_exm_stage_5") table ipv4_routing_exm_stage() {
        actions = {
            nop;
            next_hop_ipv4_0;
            NoAction_1;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
            hdr.ipv4.srcAddr: exact;
        }
        size = 28672;
        default_action = NoAction_0();
    }
    @name("ipv4_routing_exm_stage_6") table ipv4_routing_exm_stage_0() {
        actions = {
            nop_1;
            next_hop_ipv4;
            NoAction_2;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        size = 8192;
        default_action = NoAction_0();
    }
    @name("ipv4_routing_stage_1") table ipv4_routing_stage() {
        actions = {
            nop_2;
            hop_ipv4;
            NoAction_3;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
            hdr.ipv4.srcAddr: exact;
        }
        size = 1024;
        default_action = NoAction_0();
    }
    @name("tcam_tbl_stage_2") table tcam_tbl_stage() {
        actions = {
            nop_3;
            mod_mac_adr_0;
            NoAction_4;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        default_action = NoAction_0();
    }
    @name("tcp_rm_tbl_stage_4") table tcp_rm_tbl_stage() {
        actions = {
            nop_4;
            tcp_hdr_rm_0;
            NoAction_5;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
        }
        default_action = NoAction_0();
    }
    @name("udp_add_tbl_stage_3") table udp_add_tbl_stage() {
        actions = {
            nop_5;
            udp_hdr_add_0;
            NoAction_6;
        }
        key = {
            hdr.ethernet.srcAddr: ternary;
        }
        default_action = NoAction_0();
    }
    apply {
        ipv4_routing_0.apply();
        ipv4_routing_stage.apply();
        tcam_tbl_stage.apply();
        udp_add_tbl_stage.apply();
        tcp_rm_tbl_stage.apply();
        ipv4_routing_exm_stage.apply();
        ipv4_routing_exm_stage_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
