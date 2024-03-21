error {
    NoError,
    PacketTooShort,
    NoMatch,
    StackOutOfBounds,
    HeaderTooShort,
    ParserTimeout,
    CounterRange,
    Timeout,
    PhvOwner,
    MultiWrite,
    IbufOverflow,
    IbufUnderflow
}

extern packet_in {
    void extract<T>(out T hdr);
    void extract<T>(out T variableSizeHeader, in bit<32> variableFieldSizeInBits);
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

typedef bit<9> PortId_t;
typedef bit<16> MulticastGroupId_t;
typedef bit<5> QueueId_t;
typedef bit<10> MirrorId_t;
typedef bit<16> ReplicationId_t;
typedef error ParserError_t;
enum MeterType_t {
    PACKETS,
    BYTES
}

enum MeterColor_t {
    GREEN,
    YELLOW,
    RED
}

enum CounterType_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

enum SelectorMode_t {
    FAIR,
    RESILIENT
}

enum HashAlgorithm_t {
    IDENTITY,
    RANDOM,
    CRC8,
    CRC16,
    CRC32,
    CRC64,
    CSUM16
}

match_kind {
    range,
    selector
}

@__intrinsic_metadata header ingress_intrinsic_metadata_t {
    bit<1>   resubmit_flag;
    bit<1>   _pad1;
    bit<2>   packet_version;
    bit<3>   _pad2;
    PortId_t ingress_port;
    bit<48>  ingress_mac_tstamp;
}

@__intrinsic_metadata struct ingress_intrinsic_metadata_for_tm_t {
    PortId_t           ucast_egress_port;
    bool               bypass_egress;
    bool               deflect_on_drop;
    bit<3>             ingress_cos;
    QueueId_t          qid;
    bit<3>             icos_for_copy_to_cpu;
    bool               copy_to_cpu;
    bit<2>             packet_color;
    bool               disable_ucast_cutthru;
    bool               enable_mcast_cutthru;
    MulticastGroupId_t mcast_grp_a;
    MulticastGroupId_t mcast_grp_b;
    bit<13>            level1_mcast_hash;
    bit<13>            level2_mcast_hash;
    bit<16>            level1_exclusion_id;
    bit<9>             level2_exclusion_id;
    ReplicationId_t    rid;
}

@__intrinsic_metadata struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp;
    bit<32> global_ver;
    bit<16> parser_err;
}

@__intrinsic_metadata struct ingress_intrinsic_metadata_for_deparser_t {
    bit<3> drop_ctl;
    bit<3> digest_type;
    bit<3> resubmit_type;
    bit<3> mirror_type;
}

@__intrinsic_metadata header egress_intrinsic_metadata_t {
    bit<7>          _pad0;
    bit<9>          egress_port;
    bit<5>          _pad1;
    bit<19>         enq_qdepth;
    bit<6>          _pad2;
    bit<2>          enq_congest_stat;
    bit<14>         _pad3;
    bit<18>         enq_tstamp;
    bit<5>          _pad4;
    bit<19>         deq_qdepth;
    bit<6>          _pad5;
    bit<2>          deq_congest_stat;
    bit<8>          app_pool_congest_stat;
    bit<14>         _pad6;
    bit<18>         deq_timedelta;
    ReplicationId_t egress_rid;
    bit<7>          _pad7;
    bit<1>          egress_rid_first;
    bit<3>          _pad8;
    QueueId_t       egress_qid;
    bit<5>          _pad9;
    bit<3>          egress_cos;
    bit<7>          _pad10;
    bit<1>          deflection_flag;
    bit<16>         pkt_length;
}

@__intrinsic_metadata struct egress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp;
    bit<32> global_ver;
    bit<16> parser_err;
}

@__intrinsic_metadata struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> drop_ctl;
    bit<3> mirror_type;
    bit<1> coalesce_flush;
    bit<7> coalesce_length;
}

@__intrinsic_metadata struct egress_intrinsic_metadata_for_output_port_t {
    bool capture_tstamp_on_tx;
    bool update_delay_on_tx;
    bool force_tx_error;
}

header pktgen_timer_header_t {
    bit<3>  _pad1;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<8>  _pad2;
    bit<16> batch_id;
    bit<16> packet_id;
}

header pktgen_port_down_header_t {
    bit<3>  _pad1;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<15> _pad2;
    bit<9>  port_num;
    bit<16> packet_id;
}

header pktgen_recirc_header_t {
    bit<3>  _pad1;
    bit<2>  pipe_id;
    bit<3>  app_id;
    bit<24> key;
    bit<16> packet_id;
}

header ptp_metadata_t {
    bit<8>  cf_byte_offset;
    bit<8>  udp_cksum_byte_offset;
    bit<48> updated_cf;
}

extern Checksum<W> {
    Checksum(HashAlgorithm_t algorithm);
    void add<T>(in T data);
    void subtract<T>(in T data);
    bool verify();
    W get();
    W update<T>(in T data);
}

extern ParserCounter<W> {
    ParserCounter();
    void set(in W value);
    void set(in W value, in W max, in W rotate, in W mask, in W add);
    W get();
    void increment(in W value);
    void decrement(in W value);
}

extern ParserPriority {
    ParserPriority();
    void set(in bit<3> prio);
}

extern Hash<W> {
    Hash(HashAlgorithm_t algo);
    W get<D>(in D data);
    W get<D>(in D data, in W base, in W max);
}

extern Random<W> {
    Random();
    W get();
}

extern T max<T>(T t1, T t2);
extern T min<T>(T t1, T t2);
extern void invalidate<T>(in T field);
extern Counter<W, I> {
    Counter(bit<32> size, CounterType_t type);
    void count(in I index);
}

extern DirectCounter<W> {
    DirectCounter(CounterType_t type);
    void count();
}

extern Meter<I> {
    Meter(bit<32> size, MeterType_t type);
    bit<8> execute(in I index, in MeterColor_t color);
    bit<8> execute(in I index);
}

extern DirectMeter {
    DirectMeter(MeterType_t type);
    bit<8> execute(in MeterColor_t color);
    bit<8> execute();
}

extern Lpf<T, I> {
    Lpf(bit<32> size);
    T execute(in T val, in I index);
}

extern DirectLpf<T> {
    DirectLpf();
    T execute(in T val);
}

extern Wred<T, I> {
    Wred(bit<32> size, bit<8> drop_value, bit<8> no_drop_value);
    bit<8> execute(in T val, in I index);
}

extern DirectWred<T> {
    DirectWred(bit<8> drop_value, bit<8> no_drop_value);
    bit<8> execute(in T val);
}

extern Register<T, I> {
    Register(bit<32> size);
    Register(bit<32> size, T initial_value);
    T read(in I index);
    void write(in I index, in T value);
}

extern DirectRegister<T> {
    DirectRegister();
    DirectRegister(T initial_value);
    T read();
    void write(in T value);
}

extern RegisterParam<T> {
    RegisterParam(T initial_value);
    T read();
}

extern RegisterAction<T, I, U> {
    RegisterAction(Register<_, _> reg);
    abstract void apply(inout T value, @optional out U rv);
    U execute(in I index);
    U execute_log();
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);
    abstract void apply(inout T value, @optional out U rv);
    U execute();
}

extern ActionSelector {
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode, Register<bit<1>, _> reg);
}

extern ActionProfile {
    ActionProfile(bit<32> size);
}

extern Mirror {
    Mirror();
    void emit(in MirrorId_t session_id);
    void emit<T>(in MirrorId_t session_id, in T hdr);
}

extern Resubmit {
    Resubmit();
    void emit();
    void emit<T>(in T hdr);
}

extern Digest<T> {
    Digest();
    void pack(in T data);
}

parser IngressParser<H, M>(packet_in pkt, out H hdr, out M ig_md, out ingress_intrinsic_metadata_t ig_intr_md);
parser EgressParser<H, M>(packet_in pkt, out H hdr, out M eg_md, out egress_intrinsic_metadata_t eg_intr_md);
control Ingress<H, M>(inout H hdr, inout M ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);
control Egress<H, M>(inout H hdr, inout M eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);
control IngressDeparser<H, M>(packet_out pkt, inout H hdr, in M metadata, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr);
control EgressDeparser<H, M>(packet_out pkt, inout H hdr, in M metadata, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);
package Pipeline<IH, IM, EH, EM>(IngressParser<IH, IM> ingress_parser, Ingress<IH, IM> ingress, IngressDeparser<IH, IM> ingress_deparser, EgressParser<EH, EM> egress_parser, Egress<EH, EM> egress, EgressDeparser<EH, EM> egress_deparser);
@pkginfo(arch="TNA", version="1.0.0") package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1, IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(Pipeline<IH0, IM0, EH0, EM0> pipe0, @optional Pipeline<IH1, IM1, EH1, EM1> pipe1, @optional Pipeline<IH2, IM2, EH2, EM2> pipe2, @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header vlan_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vlanId;
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

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seq;
    bit<32> ack;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<32> checksum;
}

header gtp_u_t {
    bit<3>  version;
    bit<1>  pt;
    bit<1>  spare;
    bit<1>  extFlag;
    bit<1>  seqFlag;
    bit<1>  pn;
    bit<8>  msgType;
    bit<16> totalLen;
    bit<32> teid;
}

header gtp_u_extended_t {
    bit<16> seqNumb;
    bit<8>  npdu;
    bit<8>  neh;
}

header dp_ctrl_header_t {
    bit<5>   _pad0;
    bit<3>   ring_id;
    bit<79>  _pad1;
    PortId_t port;
    bit<16>  etherType;
}

header upf_bridged_metadata_t {
    bit<11> _pad0;
    bit<9>  ingress_port;
    bit<12> vlanId;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8>  protocol;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<32> teid;
}

struct headers {
    upf_bridged_metadata_t bridged_md;
    dp_ctrl_header_t       dp_ctrl;
    ethernet_t             ethernet;
    vlan_t                 vlan;
    ipv4_t                 outer_ipv4;
    udp_t                  outer_udp;
    tcp_t                  outer_tcp;
    gtp_u_t                gtp_u;
    ipv4_t                 inner_ipv4;
    udp_t                  inner_udp;
    tcp_t                  inner_tcp;
}

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x800;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff;
typedef bit<16> size_t;
const size_t ETH_MIN_SIZE = 16w0xe;
const size_t IPV4_MIN_SIZE = 16w0x14;
const size_t UDP_SIZE = 16w0x8;
const size_t GTP_MIN_SIZE = 16w0x8;
const size_t VLAN_SIZE = 16w0x4;
typedef bit<16> port_t;
const port_t PORT_GTP_U = 16w2152;
typedef bit<8> ip_protocol_t;
const ip_protocol_t PROTO_UDP = 8w17;
const ip_protocol_t PROTO_TCP = 8w6;
struct upf_egress_metadata_t {
    bit<16> pkt_length;
    bit<9>  ingress_port;
    bit<12> vlanId;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8>  protocol;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<32> teid;
}

header upf_port_metatdata_t {
    bit<7>  _pad;
    bit<9>  port_lag_index;
    bit<16> port_lag_label;
    bit<1>  port_type;
    bit<31> _pad1;
}

struct upf_ingress_metadata_t {
    bit<1>  resubmit_flag;
    bit<1>  _pad1;
    bit<2>  packet_version;
    bit<3>  _pad2;
    bit<9>  cpu_port;
    bit<48> ingress_mac_tstamp;
    bit<16> dlSrcPort;
    bit<16> dlDstPort;
}

parser UPFIngressParser(packet_in pkt, out headers hdr, out upf_ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        ig_md.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp;
        transition select(ig_intr_md.resubmit_flag) {
            1w1: parse_resubmit;
            1w0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        upf_port_metatdata_t port_md;
        pkt.extract<upf_port_metatdata_t>(port_md);
        transition parse_packet;
    }
    state parse_packet {
        dp_ctrl_header_t ether = pkt.lookahead<dp_ctrl_header_t>();
        transition select(ether.etherType) {
            16w0x99ff: parse_dp_ctrl;
            default: parse_ethernet;
        }
    }
    state parse_dp_ctrl {
        pkt.extract<dp_ctrl_header_t>(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            16w0x99ff: parse_ethernet;
            default: accept;
        }
    }
    state parse_ethernet {
        pkt.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan;
            16w0x800: parse_outer_ipv4;
            default: accept;
        }
    }
    state parse_vlan {
        pkt.extract<vlan_t>(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            16w0x800: parse_outer_ipv4;
            default: accept;
        }
    }
    state parse_outer_ipv4 {
        pkt.extract<ipv4_t>(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            8w17: parse_outer_udp;
            8w6: parse_outer_tcp;
            default: accept;
        }
    }
    state parse_outer_tcp {
        pkt.extract<tcp_t>(hdr.outer_tcp);
        ig_md.dlSrcPort = hdr.outer_tcp.srcPort;
        ig_md.dlDstPort = hdr.outer_tcp.dstPort;
        transition accept;
    }
    state parse_outer_udp {
        pkt.extract<udp_t>(hdr.outer_udp);
        ig_md.dlSrcPort = hdr.outer_udp.srcPort;
        ig_md.dlDstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            16w2152: parse_gtp_u;
            default: accept;
        }
    }
    state parse_gtp_u {
        pkt.extract<gtp_u_t>(hdr.gtp_u);
        transition accept;
    }
}

control UPFIngressDeparser(packet_out pkt, inout headers hdr, in upf_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit<upf_bridged_metadata_t>(hdr.bridged_md);
        pkt.emit<dp_ctrl_header_t>(hdr.dp_ctrl);
        pkt.emit<ethernet_t>(hdr.ethernet);
        pkt.emit<vlan_t>(hdr.vlan);
        pkt.emit<ipv4_t>(hdr.outer_ipv4);
        pkt.emit<udp_t>(hdr.outer_udp);
        pkt.emit<tcp_t>(hdr.outer_tcp);
        pkt.emit<gtp_u_t>(hdr.gtp_u);
        pkt.emit<ipv4_t>(hdr.inner_ipv4);
        pkt.emit<udp_t>(hdr.inner_udp);
    }
}

parser UPFEgressParser(packet_in pkt, out headers hdr, out upf_egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md);
        transition parse_bridged_metadata;
    }
    state parse_bridged_metadata {
        pkt.extract<upf_bridged_metadata_t>(hdr.bridged_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.vlanId = hdr.bridged_md.vlanId;
        eg_md.srcPort = hdr.bridged_md.srcPort;
        eg_md.dstPort = hdr.bridged_md.dstPort;
        eg_md.protocol = hdr.bridged_md.protocol;
        eg_md.srcAddr = hdr.bridged_md.srcAddr;
        eg_md.dstAddr = hdr.bridged_md.dstAddr;
        eg_md.teid = hdr.bridged_md.teid;
        transition parse_packet;
    }
    state parse_packet {
        pkt.extract<dp_ctrl_header_t>(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            16w0x99ff: parse_ethernet;
            16w0x8100: parse_vlan;
            16w0x800: parse_outer_ipv4;
            default: accept;
        }
    }
    state parse_ethernet {
        pkt.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan;
            16w0x800: parse_outer_ipv4;
            default: accept;
        }
    }
    state parse_vlan {
        pkt.extract<vlan_t>(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            16w0x800: parse_outer_ipv4;
            default: accept;
        }
    }
    state parse_outer_ipv4 {
        pkt.extract<ipv4_t>(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            8w17: parse_outer_udp;
            8w6: parse_outer_tcp;
            default: accept;
        }
    }
    state parse_outer_tcp {
        pkt.extract<tcp_t>(hdr.outer_tcp);
        transition accept;
    }
    state parse_outer_udp {
        pkt.extract<udp_t>(hdr.outer_udp);
        transition select(hdr.outer_udp.dstPort) {
            16w2152: parse_gtp_u;
            default: accept;
        }
    }
    state parse_gtp_u {
        pkt.extract<gtp_u_t>(hdr.gtp_u);
        transition accept;
    }
}

control UPFEgressDeparser(packet_out pkt, inout headers hdr, in upf_egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    Checksum(HashAlgorithm_t.CRC16) outer_ipv4_checksum;
    Checksum(HashAlgorithm_t.CRC16) inner_ipv4_checksum;
    apply {
        hdr.outer_ipv4.hdrChecksum = outer_ipv4_checksum.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.outer_ipv4.version, hdr.outer_ipv4.ihl, hdr.outer_ipv4.diffserv, hdr.outer_ipv4.totalLen, hdr.outer_ipv4.identification, hdr.outer_ipv4.flags, hdr.outer_ipv4.fragOffset, hdr.outer_ipv4.ttl, hdr.outer_ipv4.protocol, hdr.outer_ipv4.srcAddr, hdr.outer_ipv4.dstAddr });
        hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.inner_ipv4.version, hdr.inner_ipv4.ihl, hdr.inner_ipv4.diffserv, hdr.inner_ipv4.totalLen, hdr.inner_ipv4.identification, hdr.inner_ipv4.flags, hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ttl, hdr.inner_ipv4.protocol, hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr });
        pkt.emit<dp_ctrl_header_t>(hdr.dp_ctrl);
        pkt.emit<ethernet_t>(hdr.ethernet);
        pkt.emit<vlan_t>(hdr.vlan);
        pkt.emit<ipv4_t>(hdr.outer_ipv4);
        pkt.emit<udp_t>(hdr.outer_udp);
        pkt.emit<tcp_t>(hdr.outer_tcp);
        pkt.emit<gtp_u_t>(hdr.gtp_u);
        pkt.emit<ipv4_t>(hdr.inner_ipv4);
        pkt.emit<tcp_t>(hdr.inner_tcp);
        pkt.emit<udp_t>(hdr.inner_udp);
    }
}

control Uplink(inout headers hdr, inout upf_egress_metadata_t eg_md) {
    action decap_gtp() {
        hdr.outer_ipv4.setInvalid();
        hdr.outer_udp.setInvalid();
        hdr.gtp_u.setInvalid();
    }
    apply {
        decap_gtp();
    }
}

control Downlink(inout headers hdr, inout upf_egress_metadata_t eg_md) {
    action sub_fcs_tofino() {
        eg_md.pkt_length = eg_md.pkt_length + 16w0xfffc;
    }
    action payload_vlan_len() {
        eg_md.pkt_length = eg_md.pkt_length + 16w0xfffc;
    }
    action payload_len() {
        eg_md.pkt_length = eg_md.pkt_length + 16w0xfff2;
    }
    action compute_len() {
        hdr.outer_ipv4.totalLen = 16w0x24 + eg_md.pkt_length;
        hdr.outer_udp.hdrLen = 16w0x10 + eg_md.pkt_length;
        hdr.gtp_u.totalLen = eg_md.pkt_length;
    }
    action copy_outer_ip_to_inner_ip() {
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4 = hdr.outer_ipv4;
        hdr.outer_ipv4.protocol = 8w17;
    }
    action add_gtp() {
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 3w1;
        hdr.gtp_u.pt = 1w1;
        hdr.gtp_u.msgType = 8w255;
        hdr.gtp_u.teid = 32w0;
    }
    action copy_outer_tcp_to_inner_tcp() {
        hdr.inner_tcp.setValid();
        hdr.inner_tcp = hdr.outer_tcp;
        hdr.outer_tcp.setInvalid();
    }
    action copy_outer_udp_to_inner_udp() {
        hdr.inner_udp.setValid();
        hdr.inner_udp = hdr.outer_udp;
        hdr.inner_udp.checksum = hdr.outer_udp.checksum;
    }
    action add_outer_udp() {
        hdr.outer_udp.setValid();
        hdr.outer_udp.checksum = 16w0;
        hdr.outer_udp.dstPort = 16w2152;
        hdr.outer_udp.srcPort = 16w2152;
    }
    apply {
        copy_outer_ip_to_inner_ip();
        add_gtp();
        if (hdr.outer_tcp.isValid()) 
            copy_outer_tcp_to_inner_tcp();
        else 
            if (hdr.outer_udp.isValid()) 
                copy_outer_udp_to_inner_udp();
        add_outer_udp();
        if (hdr.vlan.isValid()) 
            payload_vlan_len();
        sub_fcs_tofino();
        payload_len();
        compute_len();
    }
}

control UPFIngress(inout headers hdr, inout upf_ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ig_drp_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) send_cpu_cntr;
    action set_cpu_port(PortId_t cpu_port) {
        ig_md.cpu_port = cpu_port;
    }
    table read_cpu_port_table {
        key = {
            ig_md.cpu_port: ternary @name("ig_md.cpu_port") ;
        }
        actions = {
            set_cpu_port();
        }
        default_action = set_cpu_port(9w1);
        size = 1;
    }
    action add_dp_header() {
        hdr.dp_ctrl.setValid();
        hdr.dp_ctrl.port = ig_intr_md.ingress_port;
        hdr.dp_ctrl.etherType = 16w0x99ff;
    }
    action send_to_cpu() {
        add_dp_header();
        ig_intr_md_for_tm.ucast_egress_port = ig_md.cpu_port;
        send_cpu_cntr.count();
        exit;
    }
    action send_from_cpu() {
        ig_intr_md_for_tm.ucast_egress_port = hdr.dp_ctrl.port;
        exit;
    }
    action drop_pkt_ingress() {
        ig_intr_md_for_dprsr.drop_ctl = 3w0x1;
        ig_drp_cntr.count();
        exit;
    }
    action forward(PortId_t eg_port) {
        ig_intr_md_for_tm.ucast_egress_port = eg_port;
    }
    table ul_dl_session_table {
        key = {
            ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
            hdr.vlan.vlanId        : exact @name("hdr.vlan.vlanId") ;
            hdr.outer_ipv4.dstAddr : exact @name("hdr.outer_ipv4.dstAddr") ;
            hdr.gtp_u.teid         : exact @name("hdr.gtp_u.teid") ;
        }
        actions = {
            forward();
            NoAction();
        }
        size = 100;
        default_action = NoAction();
    }
    table flow_table {
        key = {
            ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
            hdr.vlan.vlanId        : exact @name("hdr.vlan.vlanId") ;
            hdr.outer_ipv4.srcAddr : exact @name("hdr.outer_ipv4.srcAddr") ;
            hdr.outer_ipv4.dstAddr : exact @name("hdr.outer_ipv4.dstAddr") ;
            ig_md.dlSrcPort        : exact @name("ig_md.dlSrcPort") ;
            ig_md.dlDstPort        : exact @name("ig_md.dlDstPort") ;
            hdr.outer_ipv4.protocol: exact @name("hdr.outer_ipv4.protocol") ;
        }
        actions = {
            NoAction();
        }
        size = 100;
        default_action = NoAction();
    }
    table policy_table {
        key = {
            ig_intr_md.ingress_port: exact @name("ig_intr_md.ingress_port") ;
            hdr.vlan.vlanId        : exact @name("hdr.vlan.vlanId") ;
            hdr.outer_ipv4.srcAddr : ternary @name("hdr.outer_ipv4.srcAddr") ;
            hdr.outer_ipv4.protocol: ternary @name("hdr.outer_ipv4.protocol") ;
            ig_md.dlSrcPort        : ternary @name("ig_md.dlSrcPort") ;
            ig_md.dlDstPort        : ternary @name("ig_md.dlDstPort") ;
        }
        actions = {
            forward();
            NoAction();
        }
        size = 100;
        default_action = NoAction();
    }
    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
        hdr.bridged_md.vlanId = hdr.vlan.vlanId;
        hdr.bridged_md.srcPort = ig_md.dlSrcPort;
        hdr.bridged_md.dstPort = ig_md.dlDstPort;
        hdr.bridged_md.protocol = hdr.outer_ipv4.protocol;
        hdr.bridged_md.srcAddr = hdr.outer_ipv4.srcAddr;
        hdr.bridged_md.dstAddr = hdr.outer_ipv4.dstAddr;
        hdr.bridged_md.teid = hdr.gtp_u.teid;
    }
    apply {
        switch (ul_dl_session_table.apply().action_run) {
            NoAction: {
                read_cpu_port_table.apply();
                if (ig_intr_md.ingress_port == ig_md.cpu_port) 
                    send_from_cpu();
                else 
                    send_to_cpu();
            }
        }

        add_bridged_md();
    }
}

control UPFEgress(inout headers hdr, inout upf_egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    Uplink() uplink;
    Downlink() downlink;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) eg_drp_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) dl_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ul_cntr;
    action drop_pkt_egress() {
        eg_intr_md_for_dprsr.drop_ctl = 3w0x1;
        eg_drp_cntr.count();
        exit;
    }
    apply {
        if (hdr.dp_ctrl.isValid() && hdr.ethernet.isValid()) 
            hdr.dp_ctrl.setInvalid();
        else 
            if (hdr.gtp_u.isValid()) {
                ul_cntr.count();
                uplink.apply(hdr, eg_md);
            }
            else {
                dl_cntr.count();
                downlink.apply(hdr, eg_md);
            }
    }
}

Pipeline<headers, upf_ingress_metadata_t, headers, upf_egress_metadata_t>(UPFIngressParser(), UPFIngress(), UPFIngressDeparser(), UPFEgressParser(), UPFEgress(), UPFEgressDeparser()) pipe;

Switch<headers, upf_ingress_metadata_t, headers, upf_egress_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

