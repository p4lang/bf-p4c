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

extern CRCPolynomial<T> {
    CRCPolynomial(T coeff, bool reversed, bool msb, bool extended, T init, T xor);
}

extern Hash<W> {
    Hash(HashAlgorithm_t algo);
    Hash(HashAlgorithm_t algo, CRCPolynomial<_> poly);
    W get<D>(in D data);
    W get<D>(in D data, in W base, in W max);
}

extern Random<W> {
    Random();
    W get();
}

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

enum MathOp_t {
    MUL,
    SQR,
    SQRT,
    DIV,
    RSQR,
    RSQRT
}

extern MathUnit<T> {
    MathUnit(bool invert, int<2> shift, int<6> scale, tuple<bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>> data);
    MathUnit(MathOp_t op, int<6> scale, tuple<bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>, bit<8>> data);
    MathUnit(MathOp_t op, bit<64> factor);
    T execute(in T x);
}

extern RegisterAction<T, I, U> {
    RegisterAction(Register<T, I> reg);
    U execute(in I index);
    U execute_log();
    @synchronous(execute, execute_log) abstract void apply(inout T value, @optional out U rv);
    U predicate();
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);
    U execute();
    @synchronous(execute) abstract void apply(inout T value, @optional out U rv);
    U predicate();
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

parser IngressParserT<H, M>(packet_in pkt, out H hdr, out M ig_md, out ingress_intrinsic_metadata_t ig_intr_md);
parser EgressParserT<H, M>(packet_in pkt, out H hdr, out M eg_md, out egress_intrinsic_metadata_t eg_intr_md);
control IngressT<H, M>(inout H hdr, inout M ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);
control EgressT<H, M>(inout H hdr, inout M eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);
control IngressDeparserT<H, M>(packet_out pkt, inout H hdr, in M metadata, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr);
control EgressDeparserT<H, M>(packet_out pkt, inout H hdr, in M metadata, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);
package Pipeline<IH, IM, EH, EM>(IngressParserT<IH, IM> ingress_parser, IngressT<IH, IM> ingress, IngressDeparserT<IH, IM> ingress_deparser, EgressParserT<EH, EM> egress_parser, EgressT<EH, EM> egress, EgressDeparserT<EH, EM> egress_deparser);
@pkginfo(arch="TNA", version="1.0.0") package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1, IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(Pipeline<IH0, IM0, EH0, EM0> pipe0, @optional Pipeline<IH1, IM1, EH1, EM1> pipe1, @optional Pipeline<IH2, IM2, EH2, EM2> pipe2, @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

header vlan_tag_h {
    bit<3>    pcp;
    bit<1>    cfi;
    vlan_id_t vid;
    bit<16>   ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3>  exp;
    bit<1>  bos;
    bit<8>  ttl;
}

header ipv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     total_len;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv6_h {
    bit<4>      version;
    bit<8>      traffic_class;
    bit<20>     flow_label;
    bit<16>     payload_len;
    bit<8>      next_hdr;
    bit<8>      hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
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

header icmp_h {
    bit<8>  type_;
    bit<8>  code;
    bit<16> hdr_checksum;
}

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8>  hw_addr_len;
    bit<8>  proto_addr_len;
    bit<16> opcode;
}

header ipv6_srh_h {
    bit<8>  next_hdr;
    bit<8>  hdr_ext_len;
    bit<8>  routing_type;
    bit<8>  seg_left;
    bit<8>  last_entry;
    bit<8>  flags;
    bit<16> tag;
}

header vxlan_h {
    bit<8>  flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8>  reserved2;
}

header gre_h {
    bit<1>  C;
    bit<1>  R;
    bit<1>  K;
    bit<1>  S;
    bit<1>  s;
    bit<3>  recurse;
    bit<5>  flags;
    bit<3>  version;
    bit<16> proto;
}

struct header_t {
    ethernet_h ethernet;
    vlan_tag_h vlan_tag;
    ipv4_h     ipv4;
    ipv6_h     ipv6;
    tcp_h      tcp;
    udp_h      udp;
}

struct ingress_metadata_t {
}

struct egress_metadata_t {
}

parser SwitchIngressParser(packet_in pkt, out header_t hdr, out ingress_metadata_t ig_md, out ingress_intrinsic_metadata_t ig_intr_md) {
    ingress_intrinsic_metadata_t ig_intr_md_0;
    state start {
        ig_intr_md_0.setInvalid();
        transition TofinoIngressParser_start;
    }
    state TofinoIngressParser_start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md_0);
        transition select(ig_intr_md_0.resubmit_flag) {
            1w1: TofinoIngressParser_parse_resubmit;
            1w0: TofinoIngressParser_parse_port_metadata;
        }
    }
    state TofinoIngressParser_parse_resubmit {
        transition reject;
    }
    state TofinoIngressParser_parse_port_metadata {
        pkt.advance(32w64);
        transition start_0;
    }
    state start_0 {
        ig_intr_md = ig_intr_md_0;
        pkt.extract<ethernet_h>(hdr.ethernet);
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition accept;
    }
}

control SwitchIngress(inout header_t hdr, inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    bit<32> npb_ing_flowtable_v4_flowtable_hash;
    bit<32> npb_ing_flowtable_v4_return_value;
    bit<32> npb_ing_flowtable_v4_tmp;
    bit<32> npb_ing_flowtable_v4_tmp_0;
    @name("SwitchIngress.npb_ing_flowtable_v4.test_reg") Register<bit<32>, bit<32>>(32w1024) npb_ing_flowtable_v4_test_reg;
    @name("SwitchIngress.npb_ing_flowtable_v4.test_reg_action") RegisterAction<bit<32>, bit<32>, bit<32>>(npb_ing_flowtable_v4_test_reg) npb_ing_flowtable_v4_test_reg_action = {
        void apply(inout bit<32> value, out bit<32> read_value) {
            read_value = value;
            value = (bit<16>)ig_intr_md.ingress_port ++ npb_ing_flowtable_v4_flowtable_hash[31:16];
        }
    };
    @name("SwitchIngress.npb_ing_flowtable_v4.h") Hash<bit<32>>(HashAlgorithm_t.CRC32) npb_ing_flowtable_v4_h;
    apply {
        npb_ing_flowtable_v4_tmp = npb_ing_flowtable_v4_h.get<tuple<bit<32>, bit<32>, bit<8>, bit<16>, bit<16>>>({ hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port });
        npb_ing_flowtable_v4_flowtable_hash = npb_ing_flowtable_v4_tmp;
        npb_ing_flowtable_v4_tmp_0 = npb_ing_flowtable_v4_test_reg_action.execute(npb_ing_flowtable_v4_flowtable_hash);
        npb_ing_flowtable_v4_return_value = npb_ing_flowtable_v4_tmp_0;
        if ((PortId_t)npb_ing_flowtable_v4_return_value[31:16] == ig_intr_md.ingress_port) 
            if (npb_ing_flowtable_v4_return_value[15:0] == npb_ing_flowtable_v4_flowtable_hash[31:16]) 
                ig_intr_md_for_dprsr.drop_ctl = 3w0x1;
    }
}

control SwitchIngressDeparser(packet_out pkt, inout header_t hdr, in ingress_metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    bit<16> tmp_1;
    @name("SwitchIngressDeparser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum_0;
    apply {
        tmp_1 = ipv4_checksum_0.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_1;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<vlan_tag_h>(hdr.vlan_tag);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
        pkt.emit<tcp_h>(hdr.tcp);
        pkt.emit<udp_h>(hdr.udp);
    }
}

parser SwitchEgressParser(packet_in pkt, out header_t hdr, out egress_metadata_t eg_md, out egress_intrinsic_metadata_t eg_intr_md) {
    egress_intrinsic_metadata_t eg_intr_md_0;
    state start {
        eg_intr_md_0.setInvalid();
        transition TofinoEgressParser_start;
    }
    state TofinoEgressParser_start {
        pkt.extract<egress_intrinsic_metadata_t>(eg_intr_md_0);
        transition start_1;
    }
    state start_1 {
        eg_intr_md = eg_intr_md_0;
        pkt.extract<ethernet_h>(hdr.ethernet);
        pkt.extract<ipv4_h>(hdr.ipv4);
        transition accept;
    }
}

control SwitchEgress(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control SwitchEgressDeparser(packet_out pkt, inout header_t hdr, in egress_metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    bit<16> tmp_2;
    @name("SwitchEgressDeparser.ipv4_checksum") Checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum_1;
    apply {
        tmp_2 = ipv4_checksum_1.update<tuple<bit<4>, bit<4>, bit<8>, bit<16>, bit<16>, bit<3>, bit<13>, bit<8>, bit<8>, bit<32>, bit<32>>>({ hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.total_len, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.frag_offset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.src_addr, hdr.ipv4.dst_addr });
        hdr.ipv4.hdr_checksum = tmp_2;
        pkt.emit<ethernet_h>(hdr.ethernet);
        pkt.emit<vlan_tag_h>(hdr.vlan_tag);
        pkt.emit<ipv4_h>(hdr.ipv4);
        pkt.emit<ipv6_h>(hdr.ipv6);
        pkt.emit<tcp_h>(hdr.tcp);
        pkt.emit<udp_h>(hdr.udp);
    }
}

Pipeline<header_t, ingress_metadata_t, header_t, egress_metadata_t>(SwitchIngressParser(), SwitchIngress(), SwitchIngressDeparser(), SwitchEgressParser(), SwitchEgress(), SwitchEgressDeparser()) pipe;

Switch<header_t, ingress_metadata_t, header_t, egress_metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe) main;

