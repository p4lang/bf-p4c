#include <core.p4>
#include <tna.p4>

// Macros to generate P4info annotations; use these instead of literal annos in code to aloow for globally changing format etc.




//====================== BUILD PROFILES ===========================
// Different build options







    //
    // Maximize PGIDs (32K) but sacrifice dual stats banks. Static SMAC, SIP.
    //
    //#define USE_DUAL_STATS_BANKS 1

    //#define USE_SUBSTREAMS 1





    //#define USE_EGRESS_STREAM_METERS 1
    //#define USE_EGRESS_PORT_METERS


    //#define USE_VAL_LIST 1

    //#define USE_8x1_TCAM_COUNTER_PARAMS_TBL 1
    //#define USE_DYNAMIC_SRC_ADDR 1
    // #define USE_PKT_ID_GLOBAL_REG_INDEX  // assumes unbroken sequence of packets
# 92 "profiles.p4"
//===================== DETAILED BUILD OPTIONS =====================
// ==>>> Options below are all commented out
// ==>>> Use the "profiles" above to selectively enable them

// Define to enable dual-banks stats controlled by mode reg bit
//#define USE_DUAL_STATS_BANKS 1

// Define to support multiple streams, else just one
//#define USE_STREAM_IDS 1

// Define to use 5-but stream + 5-bit substream, otherwise only 5-bit stream (pipeapp)
//#define USE_SUBSTREAMS 1

// Define to use ternary port-matching for eg metering, eg hdr pop, udf and pgid index assignments
// Otherwise use exact-match
// #define USE_TERNARY_PORT_MATCHING

// #define USE_64K_PGIDS 1
// #define USE_32K_PGIDS 1
// #define USE_16K_PGIDS 1
// #define USE_8K_PGIDS 1
// #define USE_4K_PGIDS 1
# 135 "profiles.p4"
// #define USE_EG_PKT_AND_BYTE_CNTRS 1
// #define USE_IG_PKT_AND_BYTE_CNTRS 1
# 176 "profiles.p4"
// Must use supported register sizes for p4c compiler
// p4c-tofino would round up silently
// TODO - test for PGID_WIDTH and round up to next valid size etc.



// Define to perform stream metering in ingress,  using stream number only
// leave commented to perform stream metering in egress using stream and port keys
// #define USE_INGRESS_STREAM_METERS 1

// Define to perform stream metering in egress using stream and port keys
//#define USE_EGRESS_STREAM_METERS 1
# 196 "profiles.p4"
// Define to use per-egress port meters
//#define USE_EGRESS_PORT_METERS

// Define to treat MAC, IP addresses as octets
// #define USE_IPV4_INDIV_OCTETS 1 // used inside stdhdrs.p4
// #define USE_MAC_INDIV_OCTETS 1  // used inside stdhdrs.p4

//#define USE_VAL_LIST 1
# 217 "profiles.p4"
// Define to use 8x1 tcam counter approach
// #define USE_8x1_TCAM_CNTRS
// Define to use a counter max val, else use load decision entries
//#define USE_8x1_TCAM_COUNTER_PARAMS_TBL 1





// Define to populate smac and sip with udf or vlist values, otherwise use static values from eg_prepopulate_ether_ip_tbl
//#define USE_DYNAMIC_SRC_ADDR 1

//================================================================
//========== MODE REG ==============





//========== TOFINO PARAMETERS ==============
# 248 "profiles.p4"
//========== OUR DESIGN CONSTANTS ==============
# 270 "profiles.p4"
// Roll-up the attributes into a combined ppackage-level list to be included in main()'s' @pkginfo
# 16 "pktgen11.p4" 2

typedef bit<8> Gpkt_cntr_t;
typedef bit<15> Pgid_t; // Port Group ID
typedef bit<16> Pgid_reg_t; // PGID_WIDTH rounded up to next standard Tofino register width
typedef bit<8> Pgid_reg_index_t;


typedef bit<8> Udf_counter_t;
typedef bit<8> Udf_index_t;

typedef bit<5> Stream_t; // Stream index
typedef bit<8> Mode_t; // Global mode

# 1 "std_hdrs.p4" 1



//=====================
//      DEFINES
//=====================

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;

typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 1;
const ip_protocol_t IP_PROTOCOLS_IPV4 = 4;
const ip_protocol_t IP_PROTOCOLS_TCP = 6;
const ip_protocol_t IP_PROTOCOLS_UDP = 17;
const ip_protocol_t IP_PROTOCOLS_IPV6 = 41;
const ip_protocol_t IP_PROTOCOLS_SRV6 = 43;
const ip_protocol_t IP_PROTOCOLS_NONXT = 59;

typedef bit<16> udp_port_t;
const udp_port_t UDP_PORT_GTPC = 2123;
const udp_port_t UDP_PORT_GTPU = 2152;
const udp_port_t UDP_PORT_VXLAN = 4789;

// === Standard Headers ===
# 125 "std_hdrs.p4"
header ethernet_t {

    bit<8> dstAddr0;
    bit<8> dstAddr1;
    bit<8> dstAddr2;
    bit<8> dstAddr3;
    bit<8> dstAddr4;
    bit<8> dstAddr5;
    bit<8> srcAddr0;
    bit<8> srcAddr1;
    bit<8> srcAddr2;
    bit<8> srcAddr3;
    bit<8> srcAddr4;
    bit<8> srcAddr5;




    ether_type_t etherType;
}

header pktgen_ethernet_t {
    bit<3> _pad0;
    bit<2> pipe_id;
    bit<3> app_id;
    bit<8> _pad1;
    bit<16> batch_id;
    bit<16> packet_id;

    bit<8> srcAddr0;
    bit<8> srcAddr1;
    bit<8> srcAddr2;
    bit<8> srcAddr3;
    bit<8> srcAddr4;
    bit<8> srcAddr5;



    ether_type_t etherType;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;

    bit<8> srcAddr0;
    bit<8> srcAddr1;
    bit<8> srcAddr2;
    bit<8> srcAddr3;
    bit<8> dstAddr0;
    bit<8> dstAddr1;
    bit<8> dstAddr2;
    bit<8> dstAddr3;




}

header udp_t {
    udp_port_t srcPort;
    udp_port_t dstPort;
    bit<16> length_;
    bit<16> checksum;
}
# 30 "pktgen11.p4" 2
# 1 "ixia_hdrs.p4" 1




// TODO - use parser-value sets to make these dynamic






typedef bit<32> Ixia_seqnum_t;
typedef bit<32> Ixia_tstamp_t;
typedef bit<32> Ixia_sig_chunk_t;
# 113 "ixia_hdrs.p4"
header ixia_signature_t {
    bit<32> sig1;
    bit<32> sig2;
    bit<32> sig3;
}

header ixia_extended_instrum_t {
    bit<3> tstamp_hires;
    bit<14> pgpad;
    Pgid_t pgid;
    Ixia_seqnum_t seqnum;
    Ixia_tstamp_t tstamp;
}
# 31 "pktgen11.p4" 2

struct ingress_metadata_t {
    Mode_t modes;
    Stream_t stream;
    Pgid_t rxpgid;
    Gpkt_cntr_t g_pkt_cntr_max;
    Udf_counter_t g_udf_bank_index;
    Ixia_tstamp_t seq_delta;
    Ixia_tstamp_t latency;
    Ixia_tstamp_t lat_to_mem;
    Ixia_tstamp_t dv_signed;
    Ixia_tstamp_t dv_abs;
    bit<2> eg_port_color;
    bit<2> eg_stream_color;
    bit<1> divide_drop;
    bit<1> has_instrum;
    bit<1> known_flow;
    bit<1> seq_incr;
    bit<1> seq_big;
    bit<1> seq_dup;
    bit<1> seq_rvs;
    bool checksum_err;
}

struct pgid_16x2_t {
    Pgid_t cntrA;
    Pgid_t cntrA_data_offset;
    Pgid_t cntrA_mod;
    Pgid_t cntrA_increment;
    Pgid_t cntrA_data;
    Pgid_t cntrB;
    Pgid_t cntrB_data_offset;
    Pgid_t cntrB_mod;
    Pgid_t cntrB_increment;
    Pgid_t cntrB_data;
    Pgid_reg_index_t reg_index;
}

struct udf_8x1_tcam_t {
    Udf_counter_t next_val;
    bit<1> do_load;
}

struct egress_metadata_t {
    Pgid_t txpgid;
    bit<2> eg_port_color;
    bit<2> eg_stream_color;
    bit<1> has_instrum;
    Udf_index_t g_udf_bank_index;
    pgid_16x2_t pgid_16x2;

    udf_8x1_tcam_t udf_8x1_tcam_ipv4_dip;
    udf_8x1_tcam_t udf_8x1_tcam_dmac;

}

header bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    Mode_t modes;
    bit<8> g_pkt_cntr;
    bit<5> stream;
    bit<1> is_pktgen;
    // Ensure byte-alignment
    bit<2> pad;
}

struct header_t {
    bridged_metadata_t bridged_md;
    ethernet_t eth;
    pktgen_ethernet_t pktgen_eth;
    ipv4_t outer_ipv4;
    udp_t outer_udp;
    ixia_signature_t sig;
    ixia_extended_instrum_t instrum;
}

// Conditionally include files. Set attribute macros to empty placeholders, may get overridden by included files
// Need some value to avoid unexpected IDENTIFIER preprocessor errors when referenced as annotations for main() below.
# 1 "parde.p4" 1

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {



        pkt.advance(64);

        transition accept;
    }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum() ipv4_checksum;
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition select(ig_intr_md.ingress_port) {
            68 &&& 9w0x7f: parse_pktgen_eth;
            default: parse_eth;
        }
    }
    state parse_eth {
        hdr.bridged_md.is_pktgen = 1w0;
        pkt.extract(hdr.eth);
        transition select(hdr.eth.etherType) {
            ETHERTYPE_IPV4: parse_outer_ipv4;
            default: scan_instrum_sig;
        }
    }
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            IP_PROTOCOLS_UDP: parse_outer_udp;
            default: scan_instrum_sig;
        }
    }
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition scan_instrum_sig;
    }
    state parse_pktgen_eth {
        hdr.bridged_md.is_pktgen = 1w1;
        pkt.extract(hdr.pktgen_eth);
        transition select(hdr.pktgen_eth.etherType) {
            ETHERTYPE_IPV4: parse_outer_ipv4;
            default: scan_instrum_sig;
        }
    }
    state scan_instrum_sig {
        transition select((pkt.lookahead<bit<32>>())[31:0]) {
            0x87736749: scan_instrum_sig_2;
            default: accept;
        }
    }
    state scan_instrum_sig_2 {
        transition select((pkt.lookahead<bit<64>>())[31:0]) {
            0x42871180: scan_instrum_sig_3;
            default: accept;
        }
    }
    state scan_instrum_sig_3 {
        transition select((pkt.lookahead<bit<96>>())[31:0]) {
            0x08711805: parse_instrumentation;
            default: accept;
        }
    }
    state parse_instrumentation {
        ig_md.has_instrum = 1w1;
        pkt.extract(hdr.sig);
        pkt.extract(hdr.instrum);
        ig_md.rxpgid = hdr.instrum.pgid;
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.eth);
        pkt.emit(hdr.pktgen_eth);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.sig);
        pkt.emit(hdr.instrum);
    }
}

// ---------------------------------------------------------------------------
// Egress parser
// ---------------------------------------------------------------------------
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition parse_bridged_metadata;
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        // transition parse_pktgen_eth;
        // ingress parser sets bridged_md.is_pktgen if came from pkgen internal port
        transition select(hdr.bridged_md.is_pktgen) {
            1w1: parse_pktgen_eth;
            default: parse_eth;
        }
    }
    state parse_eth {
        pkt.extract(hdr.eth);
        transition select(hdr.eth.etherType) {
            ETHERTYPE_IPV4: parse_outer_ipv4;
            default: scan_instrum_sig;
        }
    }
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            IP_PROTOCOLS_UDP: parse_outer_udp;
            default: scan_instrum_sig;
        }
    }
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition scan_instrum_sig;
    }
    state parse_pktgen_eth {
        pkt.extract(hdr.pktgen_eth);
        transition select(hdr.pktgen_eth.etherType) {
            ETHERTYPE_IPV4: parse_outer_ipv4;
            default: scan_instrum_sig;
        }
    }
    state scan_instrum_sig {
        transition select((pkt.lookahead<bit<32>>())[31:0]) {
            0x87736749: scan_instrum_sig_2;
            default: accept;
        }
    }
    state scan_instrum_sig_2 {
        transition select((pkt.lookahead<bit<64>>())[31:0]) {
            0x42871180: scan_instrum_sig_3;
            default: accept;
        }
    }
    state scan_instrum_sig_3 {
        transition select((pkt.lookahead<bit<96>>())[31:0]) {
            0x08711805: parse_instrumentation;
            default: accept;
        }
    }
    state parse_instrumentation {
        eg_md.has_instrum = 1w1;
        pkt.extract(hdr.sig);
        pkt.extract(hdr.instrum);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    Checksum() ipv4_checksum;

    apply {
        hdr.outer_ipv4.hdrChecksum = ipv4_checksum.update(
                {hdr.outer_ipv4.version,
                 hdr.outer_ipv4.ihl,
                 hdr.outer_ipv4.diffserv,
                 hdr.outer_ipv4.totalLen,
                 hdr.outer_ipv4.identification,
                 hdr.outer_ipv4.flags,
                 hdr.outer_ipv4.fragOffset,
                 hdr.outer_ipv4.ttl,
                 hdr.outer_ipv4.protocol,

                 hdr.outer_ipv4.srcAddr0,
                 hdr.outer_ipv4.srcAddr1,
                 hdr.outer_ipv4.srcAddr2,
                 hdr.outer_ipv4.srcAddr3,
                 hdr.outer_ipv4.dstAddr0,
                 hdr.outer_ipv4.dstAddr1,
                 hdr.outer_ipv4.dstAddr2,
                 hdr.outer_ipv4.dstAddr3




                });

        pkt.emit(hdr.eth);
        pkt.emit(hdr.pktgen_eth);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.sig);
        pkt.emit(hdr.instrum);

    }
}
# 110 "pktgen11.p4" 2
# 1 "mode_reg.p4" 1
# 20 "mode_reg.p4"
control process_mode_reg(inout ingress_metadata_t ig_md) {
    @name(".do_set_mode") action do_set_mode(
        Mode_t mode) {
        ig_md.modes = mode;
    }
    @name(".mode_tbl")
    table mode_tbl {
        actions = {
            do_set_mode;
        }
        size = 1;
        default_action = do_set_mode(mode = 0);
    }
    apply {
        mode_tbl.apply();
    }
}
# 111 "pktgen11.p4" 2
# 1 "ig_stats.p4" 1
# 141 "ig_stats.p4"
//================================ P4-16 code ===========================================//
control process_ig_port_stats(inout ingress_metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md) {
    @name(".ig_port_stats_cntrA")
    @block(name=ig_port_stats)
    @feature(name="RxPortStatsA", block=eg_port_stats, service=Stats, service_id=RxPortStatsA, index=port,
            instance=0, display_name="Rx Port Stats A", display_cols="Port|RxBytesA|RxPacketsA",col_units="|bytes|packets")
    Counter<bit<32>, PortId_t>(
        32w512, CounterType_t.PACKETS_AND_BYTES) ig_port_stats_cntrA;

    @name(".do_ig_port_statsA")
    action do_ig_port_statsA() {
        ig_port_stats_cntrA.count(ig_intr_md.ingress_port);
    }

    @name(".ig_port_statsA_tbl")
    table ig_port_statsA_tbl {
        actions = {
            do_ig_port_statsA;
        }
        size = 1;
        default_action = do_ig_port_statsA();
    }
# 187 "ig_stats.p4"
    apply {







        ig_port_statsA_tbl.apply();

    }
}

control process_ig_pgid_stats(inout ingress_metadata_t ig_md) {
    @name(".ig_pgid_stats_cntrA")
    @block(name=ig_pgid_stats)
    @feature(name="RxPgidStatsA", block=eg_pgid_stats, service=Stats, service_id=RxPgidStatsA, index=pgid,
            instance=0, display_name="Rx PGID Stats A", display_cols="Port|RxBytesA|RxPacketsA",col_units="|bytes|packets")
    Counter<bit<32>, Pgid_t>(32768, CounterType_t.PACKETS_AND_BYTES) ig_pgid_stats_cntrA;

    @name(".do_ig_pgid_statsA")
    action do_ig_pgid_statsA() {
        ig_pgid_stats_cntrA.count(ig_md.rxpgid);
    }

    @name(".ig_pgid_statsA_tbl")
    table ig_pgid_statsA_tbl {
        actions = {
            do_ig_pgid_statsA;
        }
        size = 1;
        default_action = do_ig_pgid_statsA();
    }
# 243 "ig_stats.p4"
    apply {







        ig_pgid_statsA_tbl.apply();

    }
}
# 112 "pktgen11.p4" 2
# 1 "ig_port_fwd.p4" 1
# 62 "ig_port_fwd.p4"
control process_port_forwarding(inout ingress_metadata_t ig_md,
                                in ingress_intrinsic_metadata_t ig_intr_md,
                                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md
                                ) {
    @name(".do_drop")
    @Api(label="Drop Packet")
    action do_drop() {
        ig_intr_dprsr_md.drop_ctl = 0x1; // Drop packet.
    }
    @name("._set_eg_port")
    action _set_eg_port(
      @brief(Egress Port)
      @description ("Egress port specification")
      @Api(label=Port,type=uint32,format=dec)
      bit<9> eg_port
    ) {
        ig_tm_md.ucast_egress_port = eg_port;
    }
    @name(".do_set_unicast")
    @brief("Set packet unicast egress dataplane port number")
    @feature(name="unicast_action", service_id="unicast_action", display_name="Unicast to Port")
    action do_set_unicast(
        @Api(name=txPort, label="Tx Port",display_fmt="fp_ports",wr_xform="fromFpPorts", rd_xform="toFpPorts") bit<9> eg_port)

    {
        _set_eg_port(eg_port);
    }

    @name("._set_general_md")
    @brief("Wrapper to set ig_tm_md metadata plus set port to DROP value to inhibit unicast)")
    action _set_general_md(
      bit<16> rid, bit<16> xid, bit<9> yid, bit<13> h1, bit<13> h2) {
        ig_tm_md.rid = rid;
        ig_tm_md.level1_exclusion_id = xid;
        ig_tm_md.level2_exclusion_id = yid;
        ig_tm_md.level1_mcast_hash = h1;
        ig_tm_md.level2_mcast_hash = h2;
        _set_eg_port(9w511);
    }

    @name(".do_set_mcast1_md")
    @brief("Set packet multicast group id (MGID) and replication id (RID)")
    @feature(name="multicast_action", service_id="multicast_action", display_name="Multicast to ports")
    @description("Mulicast group must be configured in the PRE; RID can be used to perform egress processing")
    // ORIG - pktgen9    action do_set_mcast1_md(bit<16> mgid, bit<16> rid, bit<16> xid, bit<9> yid, bit<13> h1, bit<13> h2) {
    action do_set_mcast1_md(
      @Api(label="MGID", type=uint32, format="dec") bit<16> mgid,
      @Api(label="RID", type=uint32, format="dec") bit<16> rid)
    {
        ig_tm_md.mcast_grp_a = mgid;
        // ORIG: _set_general_md(rid, (bit<16>)xid, (bit<9>)yid, (bit<13>)h1, (bit<13>)h2);
        _set_general_md(rid, (bit<16>)0, (bit<9>)0, (bit<13>)0, (bit<13>)0);
    }

    @name(".ig_port_tbl")
    @brief("Simple Layer-1 forwarding table; input ports mapped to one or multiple output ports.")
    @feature(name="L1Fwding", block=ig_port_fwd, service=Fwding, service_id=PortStreamFwding,
        display_name="Port/Stream Forwarding Table")
    table ig_port_tbl {
        actions = {
            do_drop;
            do_set_unicast;
            do_set_mcast1_md;
        }
        key = {
            ig_md.stream : ternary @Api(name=streamNumber, label="Stream number",display_fmt="dec");
            ig_intr_md.ingress_port : ternary @Api(name=rxPort, label="Rx Port",display_fmt="fp_ports",wr_xform="fromFpPorts",rd_xform="toFpPorts");
        }
        size = 288;
        default_action = do_drop();
    }
    apply {
        ig_port_tbl.apply();
    }
}
# 113 "pktgen11.p4" 2
# 1 "rx_pgid.p4" 1
//=============== PGID Rx flow tracking =================
# 39 "rx_pgid.p4"
// One-bit wide reg for each PGID, init value = 0
@name(".rx_pgid_flow_state_reg")
Register<bit<1>, bit<32>>(32768, 0) rx_pgid_flow_state_reg;
//       width   index       num entries   init

control process_rx_pgid_flow_tracking(inout ingress_metadata_t ig_md) {
    @name(".rx_pgid_known_flow_tracker_salu")
    RegisterAction<bit<1>, bit<32>, bit<1>>(rx_pgid_flow_state_reg) rx_pgid_known_flow_tracker_salu = {
        void apply(inout bit<1> value, out bit<1> rv) {
            rv = 1w0;
            bit<1> in_value;
            in_value = value;
            value = 1w1;
            rv = value;
        }
    };
    @name(".do_rx_pgid_track_flows")
    action do_rx_pgid_track_flows() {
        ig_md.known_flow = rx_pgid_known_flow_tracker_salu.execute((bit<32>)ig_md.rxpgid);
    }
    @name(".rx_pgid_flow_tbl")
    table rx_pgid_flow_tbl {
        actions = {
            do_rx_pgid_track_flows;
        }
        size = 1;
        default_action = do_rx_pgid_track_flows();
    }
    apply {
        rx_pgid_flow_tbl.apply();
    }
}
# 114 "pktgen11.p4" 2
# 1 "rx_seqnum.p4" 1
# 514 "rx_seqnum.p4"
//==================== P4-16 code ===========================//


@name(".rx_seq_big_threshold_reg")
Register<bit<32>,bit<32>>(32w1, 0) rx_seq_big_threshold_reg;

@name(".rx_seq_delta_reg")
Register<bit<32>,bit<32>>(32768, 0) rx_seq_delta_reg;

@name(".rx_seq_dup_reg")
Register<bit<32>,bit<32>>(32w1, 0) rx_seq_dup_reg;

@name(".rx_seq_incr_reg")
Register<bit<32>,bit<32>>(32w1, 0) rx_seq_incr_reg;

@name(".rx_seq_max_reg")
@feature(name="RxPgidMaxSeqNum", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidMaxSeqNum, index=pgid,
        display_name="Rx Max Sequence Number", display_cols="PGID|MaxSeqNum",col_units="|packets")
Register<bit<32>,bit<32>>(32768, 0) rx_seq_max_reg;

// pseudo-feature to declare a regex and label for multiple stats
@feature(name="SequenceStats", block=ig_pgid_seq_stats, service=Stats, service_id=".*Seq.*|.*BigErr.*|.*SmErr.*|.*Rvs.*|.*Dup.*",
  index=pgid, display_name="All Sequence Stats")
@brief("Fake entity - not instantatiated, do not attempt to access")
@description("Fake entity to receive annotation for service_id regex")
Register<bit<32>,bit<32>>(32768, 0) rx_fake_sequence_reg;

@name(".rx_seq_rvs_reg")
Register<bit<32>,bit<32>>(32w1, 0) rx_seq_rvs_reg;

control process_ig_seq_stats(inout header_t hdr, inout ingress_metadata_t ig_md) {

    //================================
    // Detect/store max seq number
    //================================

    // Detect Seq Max SALU & action
    @name(".store_prev_seq_max")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_max_reg) store_prev_seq_max_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = hdr.instrum.seqnum;
        }
    };

    @name(".store_prev_seq_max")
    action store_prev_seq_max() {
        store_prev_seq_max_salu.execute((bit<32>)ig_md.rxpgid);
    }

    @name(".seq_max_detector")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_max_reg) seq_max_detector_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (hdr.instrum.seqnum > in_value)
                value = hdr.instrum.seqnum;
            else
                value = in_value;
        }
    };
    @name(".rx_detect_seq_max")
    action rx_detect_seq_max() {
        seq_max_detector_salu.execute((bit<32>)ig_md.rxpgid);
    }

    // Detect Seq Max wrapper table
    @name(".rx_seq_max_detect_tbl")
    table rx_seq_max_detect_tbl {
        actions = {
            rx_detect_seq_max;
            store_prev_seq_max;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): store_prev_seq_max();
            (1): rx_detect_seq_max();
        }
    }

    //================================
    // Calculate sequence delta
    //================================

    // Seq Delta SALU & action
    @name(".seq_delta_calc")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_delta_reg) seq_delta_calc_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi;
            bit<32> in_value;
            in_value = value;
            alu_hi = hdr.instrum.seqnum - in_value;
            value = hdr.instrum.seqnum;
            rv = alu_hi;
        }
    };
    @name(".rx_calc_seq_delta")
    action rx_calc_seq_delta() {
        ig_md.seq_delta = seq_delta_calc_salu.execute((bit<32>)ig_md.rxpgid);
    }

    // Seq Delta "store prev" i.e. record first value SALU & action
    @name(".store_prev_seq_delta")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_delta_reg) store_prev_seq_delta_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = hdr.instrum.seqnum;
        }
    };
    @name(".store_prev_seq_delta")
    action store_prev_seq_delta() {
        store_prev_seq_delta_salu.execute((bit<32>)ig_md.rxpgid);
    }

    // Seq Delta Wrapper table
    @name(".rx_seq_delta_calc_tbl")
    table rx_seq_delta_calc_tbl {
        actions = {
            store_prev_seq_delta;
            rx_calc_seq_delta;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): store_prev_seq_delta();
            (1): rx_calc_seq_delta();
        }
    }

    //================================
    // Sequence Increment Detection (i.e. no error)
    //================================

    // Sequence Increment Detect SALU & action
    @name(".seq_incr_detector")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_incr_reg) seq_incr_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi;
            bit<32> in_value;
            in_value = value;
            if (ig_md.seq_delta == 1)
                alu_hi = (bit<32>)1;
            else
                alu_hi = (bit<32>)0;
            rv = alu_hi;
        }
    };
    @name(".rx_detect_seq_incr")
    action rx_detect_seq_incr() {
        ig_md.seq_incr = (bit<1>)seq_incr_detector_salu.execute(32w0);
    }

    // Sequence Increment Detect Wrapper table
    @name(".rx_seq_incr_detect_tbl")
    table rx_seq_incr_detect_tbl {
        actions = {
            rx_detect_seq_incr;
        }
        size = 1;
        default_action = rx_detect_seq_incr();
    }

    //================================
    // Sequence Duplicate Errors
    //================================

    // Detect Sequence Duplicate Errors SALU & Action
    @name(".seq_dup_detector")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_dup_reg) seq_dup_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi;
            bit<32> in_value;
            in_value = value;
            if (ig_md.seq_delta == 0)
                alu_hi = (bit<32>)1;
            else
                alu_hi = (bit<32>)0;
            rv = alu_hi;
        }
    };

    @name(".rx_detect_seq_dup")
    action rx_detect_seq_dup() {
        ig_md.seq_dup = (bit<1>)seq_dup_detector_salu.execute(32w0);
    }

    // Detect Sequence Duplicate Errors wrapper table
    @name(".rx_seq_dup_detect_tbl")
    table rx_seq_dup_detect_tbl {
        actions = {
            rx_detect_seq_dup;
        }
        size = 1;
        default_action = rx_detect_seq_dup();
    }

    // Count Seq Dup Errors

    @name(".rx_seq_dup_cntrA")
    @feature(name="RxPgidDupCntrA", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidDupCntrA, index=pgid,
        display_name="Rx Duplicate Sequence Numbers Bank A", display_cols="PGID|DupSeqA",col_units="|packets")
    Counter<bit<32>, Pgid_t>(32768, CounterType_t.PACKETS) rx_seq_dup_cntrA;

    @name(".count_seq_dupA")
    action count_seq_dupA() {
        rx_seq_dup_cntrA.count(ig_md.rxpgid);
    }
    @name(".rx_seq_dup_count_tblA")
    table rx_seq_dup_count_tblA {
        actions = {
            count_seq_dupA;
        }
        size = 1;
        default_action = count_seq_dupA();
    }
# 761 "rx_seqnum.p4"
    //================================
    // Count Sequence Small errors
    //================================

    // Note: no explicit "small sequence error" detector is needed
    // It is the default condition when the sequence is none of:
    // normal (incr), duplicate, reeverse or big error and this is
    // determined in the main control logic block

    // Sequence Small errors Cuunter, action, wrapper table
    @name(".rx_seq_sm_cntrA")
    @feature(name="RxPgidSmErrCntrA", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidSmErrCntrA, index=pgid,
        display_name="Rx Small Sequence Errors", display_cols="PGID|SmSeqErrA",col_units="|packets")
    Counter<bit<32>, Pgid_t>(32768, CounterType_t.PACKETS) rx_seq_sm_cntrA;

    @name(".count_seq_smA") action count_seq_smA() {
        rx_seq_sm_cntrA.count(ig_md.rxpgid);
    }
    @name(".rx_seq_sm_count_tblA")
    table rx_seq_sm_count_tblA {
        actions = {
            count_seq_smA;
        }
        size = 1;
        default_action = count_seq_smA();
    }
# 806 "rx_seqnum.p4"
    //================================
    // Sequence Big Errors
    //================================

    // Detect Sequence Big Errors SALU & action
    @name(".seq_big_detector")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_big_threshold_reg) seq_big_detector_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi;
            bit<32> in_value;
            in_value = value;
            if ((bit<32>)ig_md.seq_delta >= in_value)
                alu_hi = (bit<32>)1;
            else
                alu_hi = (bit<32>)0;
            rv = alu_hi;
        }
    };
    @name(".rx_detect_seq_big")
    action rx_detect_seq_big() {
        ig_md.seq_big = (bit<1>)seq_big_detector_salu.execute(32w0);
    }

    // Detect Sequence Big Errors wrapper table
    @name(".rx_seq_big_detect_tbl")
    table rx_seq_big_detect_tbl {
        actions = {
            rx_detect_seq_big;
        }
        size = 1;
        default_action = rx_detect_seq_big();
    }

     // Count Sequence Big Errors action & wrapper table
    @name(".rx_seq_big_cntrA")
    @feature(name="RxPgidBigErrCntrA", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidBigErrCntrA, index=pgid,
        display_name="Rx Big Sequence Errors", display_cols="PGID|BigSeqErrA",col_units="|packets")
    Counter<bit<32>, Pgid_t>(32768, CounterType_t.PACKETS) rx_seq_big_cntrA;

    @name(".count_seq_bigA")
    action count_seq_bigA() {
        rx_seq_big_cntrA.count(ig_md.rxpgid);
    }
    @name(".rx_seq_big_count_tblA")
    table rx_seq_big_count_tblA {
        actions = {
            count_seq_bigA;
        }
        size = 1;
        default_action = count_seq_bigA();
    }
# 878 "rx_seqnum.p4"
    //================================
    // Sequence Reverse Errors
    //================================

    // Detect Sequence Reverse Errors SALU & action
    @name(".seq_rvs_detector")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_seq_rvs_reg) seq_rvs_detector = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi;
            bit<32> in_value;
            in_value = value;
            if (ig_md.seq_delta < 0)
                alu_hi = (bit<32>)1;
            else
                alu_hi = (bit<32>)0;
            rv = alu_hi;
        }
    };
    @name(".rx_detect_seq_rvs")
    action rx_detect_seq_rvs() {
        ig_md.seq_rvs = (bit<1>)seq_rvs_detector.execute(32w0);
    }

    // Detect Seq Reverse Errors wrapper table
    @name(".rx_seq_rvs_detect_tbl")
    table rx_seq_rvs_detect_tbl {
        actions = {
            rx_detect_seq_rvs;
        }
        size = 1;
        default_action = rx_detect_seq_rvs();
    }

    // Count Sequence Reverse Errors counter, action and wrapper table

    @name(".rx_seq_rvs_cntrA")
    @feature(name="RxPgidRvErrCntrA", block=ig_pgid_seq_stats, service=Stats, service_id=RxPgidRvsErrCntrA, index=pgid,
        display_name="Rx Reverse Sequence Errors", display_cols="PGID|RvsSeqErrA",col_units="|packets")
    Counter<bit<32>, Pgid_t>(32768, CounterType_t.PACKETS) rx_seq_rvs_cntrA;

    @name(".count_seq_rvsA")
    action count_seq_rvsA() {
        rx_seq_rvs_cntrA.count(ig_md.rxpgid);
    }

    @name(".rx_seq_rvs_count_tblA")
    table rx_seq_rvs_count_tblA {
        actions = {
            count_seq_rvsA;
        }
        size = 1;
        default_action = count_seq_rvsA();
    }
# 953 "rx_seqnum.p4"
    //================================
    // Main Control Logic
    //================================
    apply {
        rx_seq_max_detect_tbl.apply();
        rx_seq_delta_calc_tbl.apply();
        if (ig_md.known_flow == 1w1) {
            rx_seq_incr_detect_tbl.apply();
            rx_seq_dup_detect_tbl.apply();
            rx_seq_rvs_detect_tbl.apply();
            rx_seq_big_detect_tbl.apply();



            if (ig_md.seq_dup == 1w1) {
                rx_seq_dup_count_tblA.apply();
            } else if (ig_md.seq_rvs == 1w1) {
                rx_seq_rvs_count_tblA.apply();
            } else if (ig_md.seq_big == 1w1) {
                rx_seq_big_count_tblA.apply();
            } else if (ig_md.seq_incr == 0) {
                rx_seq_sm_count_tblA.apply();
            }
# 990 "rx_seqnum.p4"
        }
    }
}
# 115 "pktgen11.p4" 2
# 1 "rx_latency.p4" 1
# 532 "rx_latency.p4"
//=========================== P4-16 Code =================================//

@name(".rx_latency_reg")
Register<bit<32>,bit<32>>(32768, 0) rx_latency_reg;

@name(".rx_first_stamp_reg")
@feature(name="RxPgidFirstTstamp", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidFirstTstamp, index=pgid,
  display_name="Rx First Timestamp", display_cols="PGID|FirstTstamp",col_units="|nsec")
Register<bit<32>,bit<32>>(32768, 0) rx_first_stamp_reg;

// pseudo-feature to declare a regex and label for multiple stats
@feature(name="LatencyStats", block=ig_pgid_lat_stats, service=Stats, service_id=".*Lat.*|.*Tstamp.*",
  index=pgid, display_name="All Latency Stats")
@brief("Fake entity - not instantatiated, do not attempt to access")
@description("Fake entity to receive annotation for service_id regex")
Register<bit<32>,bit<32>>(32768, 0) rx_fake_latency_reg;

@name(".rx_last_stamp_reg")
@feature(name="RxPgidLastTstamp", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidLastTstamp, index=pgid,
        display_name="Rx Last Timestamp", display_cols="PGID|LastTstamp",col_units="|nsec")
Register<bit<32>,bit<32>>(32768, 0) rx_last_stamp_reg;

@name(".rx_lat_maxA_reg")
@feature(name="RxPgidMaxLatA", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidMaxLatA, index=pgid,
        display_name="Rx Max Latency Bank A", display_cols="PGID|MaxLatA",col_units="|nsec")
Register<bit<32>,bit<32>>(32768, 0) rx_lat_maxA_reg;

@name(".rx_lat_minA_reg")
@feature(name="RxPgidMinLatA", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidMinLatA, index=pgid,
        display_name="Rx Min Latency Bank A", display_cols="PGID|MinLatA",col_units="|nsec")
Register<bit<32>,bit<32>>(32768, 0) rx_lat_minA_reg;

@name(".rx_lat_totA_reg")
@feature(name="RxPgidTotLatA", block=ig_pgid_lat_stats, service=Stats, service_id=RxPgidTotLatA, index=pgid,
        display_name="Rx Total Latency Bank A", display_cols="PGID|TotLatA",col_units="|nsec")
Register<bit<32>,bit<32>>(32768, 0) rx_lat_totA_reg;
# 587 "rx_latency.p4"
control process_ig_lat_stats(inout header_t hdr, in ingress_intrinsic_metadata_from_parser_t ig_prsr_md, inout ingress_metadata_t ig_md) {

     //================================
    // Calc latency = diff btwn curr TS & Rx pkt's TS
    //================================
    @name(".rx_latency_calc")
    action rx_latency_calc() {
        ig_md.latency = (bit<32>)ig_prsr_md.global_tstamp - hdr.instrum.tstamp;
    }
    @name(".rx_latency_calc_tbl") table rx_latency_calc_tbl {
        actions = {
            rx_latency_calc;
        }
        size = 1;
        default_action = rx_latency_calc();
    }

    //================================
    // Calc latency delta
    //================================

    // First pkt in flow: just store cur lat
    @name(".store_prev_latency_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_latency_reg) store_prev_latency_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = ig_md.latency;
        }
    };
    @name(".do_store_prev_latency")
    action do_store_prev_latency() {
        store_prev_latency_salu.execute((bit<32>)ig_md.rxpgid);
    }

    // Calc delta btwn cur lat and prev; store cur lat
    @name(".lat_delta_calc_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_latency_reg) lat_delta_calc_salu = {
        void apply(inout bit<32> value, out bit<32> rv) {
            rv = 32w0;
            bit<32> alu_hi;
            bit<32> in_value;
            in_value = value;
            alu_hi = ig_md.latency - in_value;
            value = ig_md.latency;
            rv = alu_hi;
        }
    };
    @name(".do_rx_calc_lat_delta")
    action do_rx_calc_lat_delta() {
        ig_md.dv_signed = lat_delta_calc_salu.execute((bit<32>)ig_md.rxpgid);
    }
    @name(".rx_lat_delta_calc_tbl") table rx_lat_delta_calc_tbl {
        actions = {
            do_store_prev_latency;
            do_rx_calc_lat_delta;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): do_store_prev_latency();
            (1): do_rx_calc_lat_delta();
        }
    }

    //================================
    // Calc min latency
    //================================

    @name(".lat_min_detectorA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_minA_reg) lat_min_detectorA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (ig_md.lat_to_mem < in_value)
                value = ig_md.lat_to_mem;
            if (!(ig_md.lat_to_mem < in_value))
                value = in_value;
        }
    };
    @name(".do_rx_detect_lat_minA")
    action do_rx_detect_lat_minA() {
        lat_min_detectorA_salu.execute((bit<32>)ig_md.rxpgid);
    }

    @name(".store_prev_lat_minA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_minA_reg) store_prev_lat_minA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = ig_md.lat_to_mem;
        }
    };
    @name(".do_store_prev_lat_minA")
    action do_store_prev_lat_minA() {
        store_prev_lat_minA_salu.execute((bit<32>)ig_md.rxpgid);
    }
    @name(".rx_lat_min_detectA_tbl")
    table rx_lat_min_detectA_tbl {
        actions = {
            do_store_prev_lat_minA;
            do_rx_detect_lat_minA;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): do_store_prev_lat_minA();
            (1): do_rx_detect_lat_minA();
        }
    }
# 748 "rx_latency.p4"
    //================================
    // Calc max latency
    //================================

    // Just store first lat in a flow
    @name(".store_prev_lat_maxA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_maxA_reg) store_prev_lat_maxA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = ig_md.lat_to_mem;
        }
    };

    @name(".do_store_prev_lat_maxA")
    action do_store_prev_lat_maxA() {
        store_prev_lat_maxA_salu.execute((bit<32>)ig_md.rxpgid);
    }
    // Store greater of curr lat or prev one
    @name(".lat_max_detectorA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_maxA_reg) lat_max_detectorA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            if (ig_md.lat_to_mem > in_value)
                value = ig_md.lat_to_mem;
            if (!(ig_md.lat_to_mem > in_value))
                value = in_value;
        }
    };

    @name(".do_rx_detect_lat_maxA")
    action do_rx_detect_lat_maxA() {
        lat_max_detectorA_salu.execute((bit<32>)ig_md.rxpgid);
    }


    @name(".rx_lat_max_detectA_tbl")
    table rx_lat_max_detectA_tbl {
        actions = {
            do_store_prev_lat_maxA;
            do_rx_detect_lat_maxA;
        }
        key = {
            ig_md.known_flow: exact;
        }
        size = 2;
        const entries = {
            (0): do_store_prev_lat_maxA();
            (1): do_rx_detect_lat_maxA();
        }
    }
# 853 "rx_latency.p4"
    //================================
    // Calc Total latency
    //================================

    @name(".lat_tot_detectorA_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_lat_totA_reg) lat_tot_detectorA_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = ig_md.lat_to_mem + in_value;
        }
    };
    @name(".do_rx_calc_lat_totA")
    action do_rx_calc_lat_totA() {
        lat_tot_detectorA_salu.execute((bit<32>)ig_md.rxpgid);
    }
    @name(".rx_lat_tot_detectA_tbl") table rx_lat_tot_detectA_tbl {
        actions = {
            do_rx_calc_lat_totA;
        }
        size = 1;
        default_action = do_rx_calc_lat_totA();
    }
# 899 "rx_latency.p4"
    //================================
    // Store first timestamp
    //================================

    @name(".store_first_tstamp_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_first_stamp_reg) store_first_tstamp_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = hdr.instrum.tstamp;
        }
    };

    @name(".do_store_first_stamp") action do_store_first_stamp() {
        store_first_tstamp_salu.execute((bit<32>)ig_md.rxpgid);
    }

    @name(".rx_store_first_tstamp_tbl")
    table rx_store_first_tstamp_tbl {
        actions = {
            do_store_first_stamp;
        }
        size = 1;
        default_action = do_store_first_stamp();
    }

    //================================
    // Store last timestamp
    //================================
    @name(".store_last_tstamp_salu")
    RegisterAction<bit<32>, bit<32>, bit<32>>(rx_last_stamp_reg) store_last_tstamp_salu = {
        void apply(inout bit<32> value) {
            bit<32> in_value;
            in_value = value;
            value = hdr.instrum.tstamp;
        }
    };
    @name(".do_store_last_stamp") action do_store_last_stamp() {
        store_last_tstamp_salu.execute((bit<32>)ig_md.rxpgid);
    }
    @name(".rx_store_last_tstamp_tbl")
    table rx_store_last_tstamp_tbl {
        actions = {
            do_store_last_stamp;
        }
        size = 1;
        default_action = do_store_last_stamp();
    }

    //================================
    // Compute abs val of dly var
    //================================
    // negate a negative value to obtain abs
    @name(".do_negate_dv")
    action do_negate_dv() {
        ig_md.dv_abs = 32w0 - ig_md.dv_signed;
    }
    @name(".rx_dv_abs_negate_tbl")
    table rx_dv_abs_negate_tbl {
        actions = {
            do_negate_dv;
        }
        size = 1;
        default_action = do_negate_dv();
    }

    // copy  positive value to obtain abs
    @name(".do_no_negate_dv")
    action do_no_negate_dv() {
        ig_md.dv_abs = ig_md.dv_signed;
    }
    @name(".rx_dv_abs_no_negate_tbl")
    table rx_dv_abs_no_negate_tbl {
        actions = {
            do_no_negate_dv;
        }
        size = 1;
        default_action = do_no_negate_dv();
    }

    //================================
    // Copy selected stat, either abs(DV) or lat), to "shared" lat memory
    //================================
    @name(".do_rx_copy_dv_to_lat_mem")
    action do_rx_copy_dv_to_lat_mem() {
        ig_md.lat_to_mem = ig_md.dv_abs;
    }
    @name(".rx_copy_dv_to_lat_mem_tbl")
    table rx_copy_dv_to_lat_mem_tbl {
        actions = {
            do_rx_copy_dv_to_lat_mem;
        }
        size = 1;
        default_action = do_rx_copy_dv_to_lat_mem();
    }

    @name(".do_rx_copy_latency_to_lat_mem")
    action do_rx_copy_latency_to_lat_mem() {
        ig_md.lat_to_mem = ig_md.latency;
    }
    @name(".rx_copy_latency_to_lat_mem_tbl")
    table rx_copy_latency_to_lat_mem_tbl {
        actions = {
            do_rx_copy_latency_to_lat_mem;
        }
        size = 1;
        default_action = do_rx_copy_latency_to_lat_mem();
    }

    apply {
        rx_store_last_tstamp_tbl.apply();
        if (ig_md.known_flow == 1w0) {
            rx_store_first_tstamp_tbl.apply();
        }
        rx_latency_calc_tbl.apply();
        rx_lat_delta_calc_tbl.apply();
        if (ig_md.modes & 0x02 == 0x02) {
            // if (ig_md.dv_signed & 32w0x80000000 == 32w0) { // if sign bit == 0
            if (ig_md.dv_signed >= 0) { // if sign bit == 0
                rx_dv_abs_no_negate_tbl.apply();
            }
            else {
                rx_dv_abs_negate_tbl.apply();
            }
            rx_copy_dv_to_lat_mem_tbl.apply();
        }
        else {
            rx_copy_latency_to_lat_mem_tbl.apply();
        }
        if (ig_md.known_flow == 1w1 || ig_md.modes & 0x02 == 8w0) {



                rx_lat_max_detectA_tbl.apply(); // assumes max initialized to 0
                rx_lat_min_detectA_tbl.apply(); // assumes min initialized to MAX_INT_32
                rx_lat_tot_detectA_tbl.apply();







        }
    }
}
# 116 "pktgen11.p4" 2


# 1 "substreams.p4" 1
// ----------- Extract and bit-pack the pktgen pipenum & appID into a primary flow number ------------------
# 143 "substreams.p4"
control process_stream_ids(inout header_t hdr, inout ingress_metadata_t ig_md) {
    Hash<bit<5>>(HashAlgorithm_t.IDENTITY) pipeapp_pack_hash;

    @name(".do_pack_pipeapp")
    action do_pack_pipeapp() {
        ig_md.stream = pipeapp_pack_hash.get({ hdr.pktgen_eth.pipe_id, hdr.pktgen_eth.app_id });
    }
    @name(".pack_pipeapp_tbl")
    table pack_pipeapp_tbl {
        actions = {
            do_pack_pipeapp;
        }
        size = 1;
        default_action = do_pack_pipeapp();
    }
    apply {
        pack_pipeapp_tbl.apply();
    }
}
# 119 "pktgen11.p4" 2



# 1 "stream_meters.p4" 1
// -----------  stream metering and optional stats counters----------
# 93 "stream_meters.p4"
//========================= p4-16 code ============================================

control process_stream_metering(inout ingress_metadata_t ig_md) {
    @name(".stream_meter")
    @feature(name="stream_meter", service="Stream", service_id="stream_meter", block="stream_metering")
    DirectMeter(MeterType_t.BYTES) stream_meter;

    @name(".do_stream_meter")
    action do_stream_meter() {
        ig_md.eg_stream_color = (bit<2>)stream_meter.execute();
    }
    @name(".stream_meter_tbl")
    @feature(name="stream_meter_tbl", service="Stream", service_id="stream_meter_tbl", block="stream_metering")
    table stream_meter_tbl {
        actions = {
            do_stream_meter;
        }
        key = {
            ig_md.stream: exact;
        }
        size = 32;
        default_action = do_stream_meter;
        meters = stream_meter;
    }
    apply {
        stream_meter_tbl.apply();
    }
}

control process_stream_meter_drops(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    @name(".do_stream_meter_drop")
    action do_stream_meter_drop() {
        ig_tm_md.ucast_egress_port = 9w511;
    }
    @name(".stream_meter_drop_tbl")
    table stream_meter_drop_tbl {
        actions = {
            do_stream_meter_drop;
        }
        size = 1;
        default_action = do_stream_meter_drop();
    }
    apply {
        stream_meter_drop_tbl.apply();
    }
}
# 123 "pktgen11.p4" 2




# 1 "g_pkt_cntr.p4" 1
// ======================================================
// g_pkt_cntr.p4
// Count global packets after stream metering, into PRE
// ======================================================
# 74 "g_pkt_cntr.p4"
//========================= p4-16 code ============================================





// single "global" counter register, PKT_CNTR_WIDTH bits wide
@name(".g_pkt_cntr_reg")
@brief("Global Packet Counter register")
@description("This counter count from 0 to max value as programmed into load_g_pkt_cntr_params_tbl.                It controls the sequencing of UDF generators")

@feature(name="g_pkt_cntr_val", service="Stream", service_id="g_pkt_cntr_val", block="g_pkt_cntr", label="Global Packet Counter", service_descrip="Global Packet Counter register; this counter counts from 0 to max value as programmed into load_g_pkt_cntr_params_tbl.                It controls the sequencing of UDF generators")

Register<Gpkt_cntr_t,bit<8>>(32w1, 0) g_pkt_cntr_reg;

control process_g_pkt_cntr(inout header_t hdr, inout ingress_metadata_t ig_md) {

    @name(".g_pkt_cntr_salu")
    @brief("Stateful ALU implements  global packet counter")
    RegisterAction<bit<8>, bit<32>, bit<8>>(g_pkt_cntr_reg) g_pkt_cntr_salu = {
        void apply(inout bit<8> value, out bit<8> rv) {
            rv = (Gpkt_cntr_t)0;
            Gpkt_cntr_t in_value;
            in_value = value;
            if (in_value < ig_md.g_pkt_cntr_max)
                value = 1 + in_value;
            else
                value = (Gpkt_cntr_t)0;
            rv = value;
        }
    };

    @name(".do_g_pkt_cntr")
    @brief("Action to run stateful ALU program")
    action do_g_pkt_cntr() {
        hdr.bridged_md.g_pkt_cntr = g_pkt_cntr_salu.execute(32w0);
    }
    @name(".g_pkt_cntr_tbl")
    @brief("Global Packet Counter execute table - invokes action run stateful ALU program")
    table g_pkt_cntr_tbl {
        actions = {
            do_g_pkt_cntr;
        }
        size = 1;
        default_action = do_g_pkt_cntr();
    }

    @name(".do_load_g_pkt_cntr_counter_params")
    action do_load_g_pkt_cntr_counter_params(bit<8> max_count) {
        ig_md.g_pkt_cntr_max = max_count;
    }
    @name(".load_g_pkt_cntr_params_tbl")
    @brief("Global Packet Counter parameter table - determines counter max value")
    @feature(name="g_pkt_cntr_max", service="Stream", service_id="g_pkt_cntr_max", block="g_pkt_cntr")
    table load_g_pkt_cntr_params_tbl {
        actions = {
            do_load_g_pkt_cntr_counter_params;
        }
        size = 1;
        default_action = do_load_g_pkt_cntr_counter_params(max_count = 0);
    }
    apply {
        load_g_pkt_cntr_params_tbl.apply();
        g_pkt_cntr_tbl.apply();
    }
}
# 128 "pktgen11.p4" 2



# 1 "prepop_hdrs.p4" 1
// --- populate hdr fields with looked-up values ---
# 90 "prepop_hdrs.p4"
//========================= p4-16 code ============================================

// #define EG_POPULATE_FEATURE_PKGINFO @feature("name='eg.populate.ether',outer_eth.dmac-octets","block=eg_hdr_pop") //                                     @feature("name='eg.populate.outer_ipv4',outer_ipv4.dip-octets","block=eg_hdr_pop")







control process_prepopulate_hdr_g_reg(inout header_t hdr, inout egress_metadata_t eg_md,
                    in egress_intrinsic_metadata_t eg_intr_md) {
    @name(".do_prepopulate_ether_ip")
    @block(name="eg_hdr_pop")
    action do_prepopulate_ether_ip(bit<8> g_udf_bank_index,
                bit<8> dmac0, bit<8> dmac1, bit<8> dmac2, bit<8> dmac3, bit<8> dmac4, bit<8> dmac5,
                bit<8> smac0, bit<8> smac1, bit<8> smac2, bit<8> smac3, bit<8> smac4, bit<8> smac5,
                bit<8> sip0, bit<8> sip1, bit<8> sip2, bit<8> sip3,
                bit<8> dip0, bit<8> dip1, bit<8> dip2, bit<8> dip3) {
        hdr.eth.setValid();
        hdr.eth.dstAddr0 = dmac0;
        hdr.eth.dstAddr1 = dmac1;
        hdr.eth.dstAddr2 = dmac2;
        hdr.eth.dstAddr3 = dmac3;
        hdr.eth.dstAddr4 = dmac4;
        hdr.eth.dstAddr5 = dmac5;
        hdr.eth.srcAddr0 = smac0;
        hdr.eth.srcAddr1 = smac1;
        hdr.eth.srcAddr2 = smac2;
        hdr.eth.srcAddr3 = smac3;
        hdr.eth.srcAddr4 = smac4;
        hdr.eth.srcAddr5 = smac5;
        hdr.eth.etherType = hdr.pktgen_eth.etherType;
        hdr.pktgen_eth.setInvalid();
        hdr.outer_ipv4.dstAddr0 = dip0;
        hdr.outer_ipv4.dstAddr1 = dip1;
        hdr.outer_ipv4.dstAddr2 = dip2;
        hdr.outer_ipv4.dstAddr3 = dip3;
        hdr.outer_ipv4.srcAddr0 = sip0;
        hdr.outer_ipv4.srcAddr1 = sip1;
        hdr.outer_ipv4.srcAddr2 = sip2;
        hdr.outer_ipv4.srcAddr3 = sip3;
        eg_md.g_udf_bank_index = g_udf_bank_index;
    }
    @name(".eg_prepop_hdr_and_g_reg_tbl")
    @block(name="eg_hdr_pop")
    @feature(name="eg_prepop_hdr_and_g_reg_tbl", service="Stream", service_id="eg_prepop_hdr", block="eg_hdr_pop")
    table eg_prepop_hdr_and_g_reg_tbl {
        actions = {
            do_prepopulate_ether_ip;
        }
        key = {
            hdr.bridged_md.stream: ternary;
            eg_intr_md.egress_port: ternary;
        }
        size = 32;
        default_action = do_prepopulate_ether_ip(g_udf_bank_index = 0,
                         dmac0 = 0, dmac1 = 0, dmac2 = 0, dmac3 = 0, dmac4 = 0, dmac5 = 0,
                         smac0 = 0, smac1 = 0, smac2 = 0, smac3 = 0, smac4 = 0, smac5 = 0,
                         sip0 = 0, sip1 = 0, sip2 = 0, sip3 = 0, dip0 = 0,
                         dip1 = 0, dip2 = 0, dip3 = 0);
    }
    apply {
        eg_prepop_hdr_and_g_reg_tbl.apply();
    }
}
# 132 "pktgen11.p4" 2
# 1 "pgid_16x2.p4" 1
// 2 16-bit PGID counters
# 258 "pgid_16x2.p4"
//============================== P4-16 Code ==================================================
# 267 "pgid_16x2.p4"
control process_pgid_16x2_load_params(inout header_t hdr, inout egress_metadata_t eg_md,
                                         in egress_intrinsic_metadata_t eg_intr_md) {

    @name(".do_load_pgid_counter_params")
    action do_load_pgid_counter_params(Pgid_t cntrA_data_offset, Pgid_t cntrA_mod, Pgid_t cntrA_incr,
                    Pgid_t cntrB_data_offset, Pgid_t cntrB_mod, Pgid_t cntrB_incr, Pgid_reg_index_t pgid_index) {
        eg_md.pgid_16x2.cntrA_data_offset = cntrA_data_offset;
        eg_md.pgid_16x2.cntrA_mod = cntrA_mod;
        eg_md.pgid_16x2.cntrA_increment = cntrA_incr;
        eg_md.pgid_16x2.cntrB_data_offset = cntrB_data_offset;
        eg_md.pgid_16x2.cntrB_mod = cntrB_mod;
        eg_md.pgid_16x2.cntrB_increment = cntrB_incr;
        eg_md.pgid_16x2.reg_index = pgid_index;
    }
    @name(".pgid_16x2_load_params_tbl")
    table pgid_16x2_load_params_tbl {
        actions = {
            do_load_pgid_counter_params;
        }
        key = {
            hdr.bridged_md.stream : ternary;
            eg_intr_md.egress_port: ternary;
        }
        size = 256;
        default_action = do_load_pgid_counter_params(cntrA_data_offset = 0, cntrA_mod = 0, cntrA_incr = 0,
                               cntrB_data_offset = 0, cntrB_mod = 0, cntrB_incr = 0, pgid_index = 0);
    }
    apply {
        pgid_16x2_load_params_tbl.apply();
    }
}

//Bank of low-order pgid-counters, one per global counter index
@name(".pgid_16x2_cntrA_reg")
@brief("Bank of low-order pgid-counters, one per global counter index")
Register<Pgid_reg_t,Pgid_reg_index_t>(256, 0) pgid_16x2_cntrA_reg;

//Bank of high-order pgid-counters, one per global counter index, cascaded from counter A's
@name(".pgid_16x2_cntrB_reg")
@brief("Bank of high-order pgid-counters, one per global counter index, cascaded from counter A")
Register<Pgid_reg_t,Pgid_reg_index_t>(256, 0) pgid_16x2_cntrB_reg;

control process_pgid_16x2_process_pgids(inout egress_metadata_t eg_md) {
    @name(".pgid_16x2_cntrA") RegisterAction<Pgid_reg_t, Pgid_reg_index_t, Pgid_reg_t>(pgid_16x2_cntrA_reg) pgid_16x2_cntrA = {
        void apply(inout Pgid_reg_t value, out Pgid_reg_t rv) {
            rv = (Pgid_reg_t)0;
            Pgid_reg_t in_value;
            in_value = value;
            if (in_value < (Pgid_reg_t)eg_md.pgid_16x2.cntrA_mod)
                value = (Pgid_reg_t)eg_md.pgid_16x2.cntrA_increment + in_value;
            else
                value = (Pgid_reg_t)0;
            rv = value;
        }
    };
    @name(".pgid_16x2_cntrB")
    RegisterAction<Pgid_reg_t, Pgid_reg_index_t, Pgid_reg_t>(pgid_16x2_cntrB_reg) pgid_16x2_cntrB = {
        void apply(inout Pgid_reg_t value, out Pgid_reg_t rv) {
            rv = (Pgid_reg_t)0;
            Pgid_reg_t in_value;
            in_value = value;
            if (in_value < (Pgid_reg_t)eg_md.pgid_16x2.cntrB_mod)
                value = (Pgid_reg_t)eg_md.pgid_16x2.cntrB_increment + in_value;
            else
                value = (Pgid_reg_t)0;
            rv = value;
        }
    };
    @name(".pgid_16x2_cntrB_read")
    RegisterAction<Pgid_reg_t,Pgid_reg_index_t, Pgid_reg_t>(pgid_16x2_cntrB_reg) pgid_16x2_cntrB_read = {
        void apply(inout Pgid_reg_t value, out Pgid_reg_t rv) {
            rv = (Pgid_reg_t)0;
            Pgid_reg_t in_value;
            in_value = value;
            rv = in_value;
        }
    };
    @name(".do_pgid_16x2_cntrA_data_offset")
    action do_pgid_16x2_cntrA_data_offset() {
        eg_md.pgid_16x2.cntrA_data = eg_md.pgid_16x2.cntrA + eg_md.pgid_16x2.cntrA_data_offset;
    }
    @name(".do_merge_pgid_16x2_cntrA")
    action do_merge_pgid_16x2_cntrA() {
        eg_md.txpgid = eg_md.txpgid | eg_md.pgid_16x2.cntrA_data;
    }
    @name(".do_pgid_16x2_cntrA")
    action do_pgid_16x2_cntrA() {
        eg_md.pgid_16x2.cntrA = (Pgid_t)pgid_16x2_cntrA.execute(eg_md.pgid_16x2.reg_index);
    }
    @name(".do_pgid_16x2_cntrB_data_offset")
    action do_pgid_16x2_cntrB_data_offset() {
        eg_md.pgid_16x2.cntrB_data = eg_md.pgid_16x2.cntrB + eg_md.pgid_16x2.cntrB_data_offset;
    }
    @name(".do_merge_pgid_16x2_cntrB")
    action do_merge_pgid_16x2_cntrB() {
        eg_md.txpgid = eg_md.txpgid | eg_md.pgid_16x2.cntrB_data;
    }
    @name(".do_pgid_16x2_cntrB_read")
    action do_pgid_16x2_cntrB_read() {
        eg_md.pgid_16x2.cntrB = (Pgid_t)pgid_16x2_cntrB_read.execute(eg_md.pgid_16x2.reg_index);
    }
    @name(".do_pgid_16x2_cntrB")
    action do_pgid_16x2_cntrB() {
        eg_md.pgid_16x2.cntrB = (Pgid_t)pgid_16x2_cntrB.execute(eg_md.pgid_16x2.reg_index);
    }
    @name(".pgid_16x2_cntrA_data_offset_tbl")
    table pgid_16x2_cntrA_data_offset_tbl {
        actions = {
            do_pgid_16x2_cntrA_data_offset;
        }
        size = 1;
        default_action = do_pgid_16x2_cntrA_data_offset();
    }
    @name(".pgid_16x2_cntrA_merge_tbl")
    table pgid_16x2_cntrA_merge_tbl {
        actions = {
            do_merge_pgid_16x2_cntrA;
        }
        size = 1;
        default_action = do_merge_pgid_16x2_cntrA();
    }
    @name(".pgid_16x2_cntrA_tbl")
    table pgid_16x2_cntrA_tbl {
        actions = {
            do_pgid_16x2_cntrA;
        }
        size = 1;
        default_action = do_pgid_16x2_cntrA();
    }
    @name(".pgid_16x2_cntrB_data_offset_tbl")
    table pgid_16x2_cntrB_data_offset_tbl {
        actions = {
            do_pgid_16x2_cntrB_data_offset;
        }
        size = 1;
        default_action = do_pgid_16x2_cntrB_data_offset();
    }
    @name(".pgid_16x2_cntrB_merge_tbl")
    table pgid_16x2_cntrB_merge_tbl {
        actions = {
            do_merge_pgid_16x2_cntrB;
        }
        size = 1;
        default_action = do_merge_pgid_16x2_cntrB();
    }
    @name(".pgid_16x2_cntrB_read_tbl")
    table pgid_16x2_cntrB_read_tbl {
        actions = {
            do_pgid_16x2_cntrB_read;
        }
        size = 1;
        default_action = do_pgid_16x2_cntrB_read();
    }
    @name(".pgid_16x2_cntrB_tbl")
    table pgid_16x2_cntrB_tbl {
        actions = {
            do_pgid_16x2_cntrB;
        }
        size = 1;
        default_action = do_pgid_16x2_cntrB();
    }
    apply {
        pgid_16x2_cntrA_tbl.apply();
        if (eg_md.pgid_16x2.cntrA == (Pgid_t)0) {
            pgid_16x2_cntrB_tbl.apply(); // B-counter rollover
        }
        else {
            pgid_16x2_cntrB_read_tbl.apply(); // B counter unchanged
        }
        pgid_16x2_cntrA_data_offset_tbl.apply();
        pgid_16x2_cntrA_merge_tbl.apply();
        pgid_16x2_cntrB_data_offset_tbl.apply();
        pgid_16x2_cntrB_merge_tbl.apply();
    }
}
# 133 "pktgen11.p4" 2

// NOTE - not translated into p4-16 yet:
# 147 "pktgen11.p4"
# 1 "udf_8x1_tcam_ipv4_dip.p4" 1
# 139 "udf_8x1_tcam_ipv4_dip.p4"
//========================= p4-16 code ============================================





@name(".udf_8x1_tcam_ipv4_dip_cntr_reg")
@brief("Bank of UDF_CNTR_TBL_SZ counters, each one maintains incrementing count sequence for one udf index")
@description("The counters can execute one of two actions: increment, or reload a new value                controlled by udf_8x1_tcam_ipv4_dip_cntr_decision_tbl. This register should be cleared

                before starting a new sequence.")
@block(name="udf.outer_ipv4.dip")
@feature(name="udf_8x1_tcam_ipv4_dip_cntr_reg", service="Stream", service_id="udf_8x1_tcam_ipv4_dip_cntr_reg", block="udf.outer_ipv4.dip")
Register<Udf_counter_t, Udf_index_t>(256, 0) udf_8x1_tcam_ipv4_dip_cntr_reg;

@block(name="udf.outer_ipv4.dip")
control process_udf_8x1_tcam_ipv4_dip(inout header_t hdr, inout egress_metadata_t eg_md) {
    @name("._nop")
    action _nop() {
    }

    @name(".salu_udf_8x1_tcam_ipv4_dip_cntr_incr")
    @block(name="udf.outer_ipv4.dip")
    RegisterAction<Udf_counter_t, Udf_index_t, Udf_counter_t>
                    (udf_8x1_tcam_ipv4_dip_cntr_reg) salu_udf_8x1_tcam_ipv4_dip_cntr_incr = {
        void apply(inout Udf_counter_t value, out Udf_counter_t rv) {
            rv = (Udf_counter_t)0;
            Udf_counter_t in_value;
            in_value = value;
            value = 1 + in_value;
            rv = value;
        }
    };
    @name(".salu_udf_8x1_tcam_ipv4_dip_next_val")
    @block(name="udf.outer_ipv4.dip")
    RegisterAction<Udf_counter_t, Udf_index_t, Udf_counter_t>(udf_8x1_tcam_ipv4_dip_cntr_reg) salu_udf_8x1_tcam_ipv4_dip_next_val = {
        void apply(inout Udf_counter_t value) {
            Udf_counter_t in_value;
            in_value = value;
            value = eg_md.udf_8x1_tcam_ipv4_dip.next_val;
        }
    };

    // set a flag (or not) to tell the next stage to load a new counter value, else increment by default 
    @name(".do_udf_8x1_tcam_ipv4_dip_prepare_load")
    action do_udf_8x1_tcam_ipv4_dip_prepare_load(Udf_counter_t next_val) {
        eg_md.udf_8x1_tcam_ipv4_dip.next_val = next_val;
        eg_md.udf_8x1_tcam_ipv4_dip.do_load = 1w1;
    }
    @name(".udf_8x1_tcam_ipv4_dip_cntr_decision_tbl")
    @brief("This table programs counting load/increment sequence for each of N UDFs assigned to IPv4 DIP sequencing.")
    @description("For action 'do_udf_8x1_tcam_ipv4_dip_prepare_load', when the counter for UDF 'g_udf_bank_index'                 reaches value 'g_pkt_cntr', the next value of the counter shall  be 'next_val'. If the action is '_nop'                then by default the counter shall increment on the  next packet.                The table keys allow each UDF bank to form a counting sequence based on the global pacaket counter.                The table size allows each UDF to have two actions programmed. Typically, each port would receive                a stream controlled by one UDF and the counting sequences for each port would cycle through 'dstAddr'                values associated with all  other ports. This requires programming an initial load value when g_pkt_cntr==0                to start the sequence, and another 'load' value to skip past 'this' port in the sequence.")







    @block(name="udf.outer_ipv4.dip")
    @feature(name="udf_8x1_tcam_ipv4_dip_cntr_decision_tbl", service="Stream", service_id="udf_8x1_tcam_ipv4_dip_cntr_decision_tbl", block="udf.outer_ipv4.dip")
    table udf_8x1_tcam_ipv4_dip_cntr_decision_tbl {
        actions = {
            do_udf_8x1_tcam_ipv4_dip_prepare_load;
            _nop;
        }
        key = {
            eg_md.g_udf_bank_index: exact;
            hdr.bridged_md.g_pkt_cntr: exact;
        }
        size = (256*2);
        default_action = _nop();
    }

    // increment or load a new counter value      
    @name(".do_udf_8x1_tcam_ipv4_dip_cntr_incr")
    action do_udf_8x1_tcam_ipv4_dip_cntr_incr() {
        eg_md.udf_8x1_tcam_ipv4_dip.next_val = salu_udf_8x1_tcam_ipv4_dip_cntr_incr.execute(eg_md.g_udf_bank_index);
    }
    @name(".do_udf_8x1_tcam_ipv4_dip_next_val")
    action do_udf_8x1_tcam_ipv4_dip_next_val() {
        salu_udf_8x1_tcam_ipv4_dip_next_val.execute(eg_md.g_udf_bank_index);
    }
    @name(".udf_8x1_tcam_ipv4_dip_cntr_defer_cmd_tbl")
    @brief("Static table used to either increment or load a new counter value.")
    @description("Static table used to either increment or load a new counter value.")
    @block(name="udf.outer_ipv4.dip")
    table udf_8x1_tcam_ipv4_dip_cntr_defer_cmd_tbl {
        actions = {
            do_udf_8x1_tcam_ipv4_dip_cntr_incr;
            do_udf_8x1_tcam_ipv4_dip_next_val;
        }
        key = {
            eg_md.udf_8x1_tcam_ipv4_dip.do_load: exact;
        }
        size = 2;
        const entries = {
            (0): do_udf_8x1_tcam_ipv4_dip_cntr_incr();
            (1): do_udf_8x1_tcam_ipv4_dip_next_val();
        }
    }

    // Populate the selected IPv4 DIP octet
    @name(".do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip0")
    action do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip0() {
        hdr.outer_ipv4.dstAddr0 = eg_md.udf_8x1_tcam_ipv4_dip.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip1")
    action do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip1() {
        hdr.outer_ipv4.dstAddr1 = eg_md.udf_8x1_tcam_ipv4_dip.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip2")
    action do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip2() {
        hdr.outer_ipv4.dstAddr2 = eg_md.udf_8x1_tcam_ipv4_dip.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip3")
    action do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip3() {
        hdr.outer_ipv4.dstAddr3 = eg_md.udf_8x1_tcam_ipv4_dip.next_val;
    }

    @name(".udf_8x1_tcam_ipv4_dip_populate_tbl")
    @brief("Select which outer IPv4 DIP octet (or none) will be populated; globally applies to all UDFs")
    @description("If none is selected the value will remain unchanged (as set by the prepopulate block)")
    @block(name="udf.outer_ipv4.dip")
    @attribute("global")
    @feature(name="udf_8x1_tcam_ipv4_dip_populate_tbl", service="Stream", service_id="udf_8x1_tcam_ipv4_dip_populate_tbl", block="udf.outer_ipv4.dip")
    table udf_8x1_tcam_ipv4_dip_populate_tbl {
        actions = {
            @Api(layer="udf.outer_ipv4.dip,[0:7]") do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip0;
            @Api(layer="udf.outer_ipv4.dip,[8:15]") do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip1;
            @Api(layer="udf.outer_ipv4.dip,[16:23]") do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip2;
            @Api(layer="udf.outer_ipv4.dip,[24:31]") do_populate_udf_8x1_tcam_ipv4_dip_outer_ipv4_dip3;
            @Api(layer="none") _nop;
        }
        size = 1;
        default_action = _nop();
    }
    apply {
        udf_8x1_tcam_ipv4_dip_cntr_decision_tbl.apply();
        udf_8x1_tcam_ipv4_dip_cntr_defer_cmd_tbl.apply();
        udf_8x1_tcam_ipv4_dip_populate_tbl.apply();
    }
}
# 148 "pktgen11.p4" 2
# 1 "udf_8x1_tcam_dmac.p4" 1
// ======================================================
// udf_8x1_tcam_mac_x.
// ======================================================
# 153 "udf_8x1_tcam_dmac.p4"
//========================= p4-16 code ============================================





@name(".udf_8x1_tcam_dmac_cntr_reg")
@block(name="udf.outer_eth.dmac")
@feature(name="udf_8x1_tcam_dmac_cntr_reg", service="Stream", service_id="udf_8x1_tcam_dmac_cntr_reg", block="udf.outer_eth.dmac")
Register<Udf_counter_t, Udf_index_t>(256, 0) udf_8x1_tcam_dmac_cntr_reg;

control process_udf_8x1_tcam_dmac(inout header_t hdr, inout egress_metadata_t eg_md) {

    @name(".salu_udf_8x1_tcam_dmac_cntr_incr")
    RegisterAction<Udf_counter_t, Udf_index_t, Udf_counter_t>
                    (udf_8x1_tcam_dmac_cntr_reg) salu_udf_8x1_tcam_dmac_cntr_incr = {
        void apply(inout Udf_counter_t value, out Udf_counter_t rv) {
            rv = (Udf_counter_t)0;
            Udf_counter_t in_value;
            in_value = value;
            value = 1 + in_value;
            rv = value;
        }
    };
    @name(".salu_udf_8x1_tcam_dmac_next_val")
    RegisterAction<Udf_counter_t, Udf_index_t, Udf_counter_t>(udf_8x1_tcam_dmac_cntr_reg) salu_udf_8x1_tcam_dmac_next_val = {
        void apply(inout Udf_counter_t value) {
            Udf_counter_t in_value;
            in_value = value;
            value = eg_md.udf_8x1_tcam_dmac.next_val;
        }
    };
    @name(".do_udf_8x1_tcam_dmac_prepare_load")
    action do_udf_8x1_tcam_dmac_prepare_load(Udf_counter_t next_val) {
        eg_md.udf_8x1_tcam_dmac.next_val = next_val;
        eg_md.udf_8x1_tcam_dmac.do_load = 1w1;
    }
    @name("._nop") action _nop() {
    }

    @name(".udf_8x1_tcam_dmac_cntr_decision_tbl")
    @feature(name="udf_8x1_tcam_dmac_cntr_decision_tbl", service="Stream", service_id="udf_8x1_tcam_dmac_cntr_decision_tbl", block="udf.outer_eth.dmac")
    table udf_8x1_tcam_dmac_cntr_decision_tbl {
        actions = {
            do_udf_8x1_tcam_dmac_prepare_load;
            _nop;
        }
        key = {
            eg_md.g_udf_bank_index: exact;
            hdr.bridged_md.g_pkt_cntr: exact;
        }
        size = (256*2);
        default_action = _nop();
    }

    // based on lookup using g_pkt_cntr, either increment a UDF cntr
    // or load a new value to change the sequence
    @name(".do_udf_8x1_tcam_dmac_cntr_incr")
    action do_udf_8x1_tcam_dmac_cntr_incr() {
        eg_md.udf_8x1_tcam_dmac.next_val = salu_udf_8x1_tcam_dmac_cntr_incr.execute(eg_md.g_udf_bank_index);
    }
    @name(".do_udf_8x1_tcam_dmac_next_val")
    action do_udf_8x1_tcam_dmac_next_val() {
        salu_udf_8x1_tcam_dmac_next_val.execute(eg_md.g_udf_bank_index);
    }
        @name(".udf_8x1_tcam_dmac_cntr_defer_cmd_tbl")
    table udf_8x1_tcam_dmac_cntr_defer_cmd_tbl {
        actions = {
            do_udf_8x1_tcam_dmac_cntr_incr;
            do_udf_8x1_tcam_dmac_next_val;
        }
        key = {
            eg_md.udf_8x1_tcam_dmac.do_load: exact;
        }
        size = 2;
        const entries = {
            (0): do_udf_8x1_tcam_dmac_cntr_incr();
            (1): do_udf_8x1_tcam_dmac_next_val();
        }
    }

    // Populate one octet in the DMAC with processed UDF counter output
    @name(".do_populate_udf_8x1_tcam_dmac_dmac0")
    action do_populate_udf_8x1_tcam_dmac_dmac0() {
        hdr.eth.dstAddr0 = eg_md.udf_8x1_tcam_dmac.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_dmac_dmac1")
    action do_populate_udf_8x1_tcam_dmac_dmac1() {
        hdr.eth.dstAddr1 = eg_md.udf_8x1_tcam_dmac.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_dmac_dmac2")
    action do_populate_udf_8x1_tcam_dmac_dmac2() {
        hdr.eth.dstAddr2 = eg_md.udf_8x1_tcam_dmac.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_dmac_dmac3")
    action do_populate_udf_8x1_tcam_dmac_dmac3() {
        hdr.eth.dstAddr3 = eg_md.udf_8x1_tcam_dmac.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_dmac_dmac4")
    action do_populate_udf_8x1_tcam_dmac_dmac4() {
        hdr.eth.dstAddr4 = eg_md.udf_8x1_tcam_dmac.next_val;
    }
    @name(".do_populate_udf_8x1_tcam_dmac_dmac5")
    action do_populate_udf_8x1_tcam_dmac_dmac5() {
        hdr.eth.dstAddr5 = eg_md.udf_8x1_tcam_dmac.next_val;
    }
    @name(".udf_8x1_tcam_dmac_populate_tbl")
    @brief("Select which outer DMAC octet (or none) will be populated; globally applies to all UDFs")
    @description("If none is selected the value will remain unchanged (as set by the prepopulate block)")
    @block(name="udf.outer_eth.dmac")
    @attribute("global")
    @feature(name="udf_8x1_tcam_dmac_populate_tbl", service="Stream", service_id="udf_8x1_tcam_dmac_populate_tbl", block="udf.outer_eth.dmac")
    table udf_8x1_tcam_dmac_populate_tbl {
        actions = {
            @Api(layer="udf.outer_eth.dmac,0:7]") do_populate_udf_8x1_tcam_dmac_dmac0;
            @Api(layer="udf.outer_eth.dmac,8:15]") do_populate_udf_8x1_tcam_dmac_dmac1;
            @Api(layer="udf.outer_eth.dmac,16:23]") do_populate_udf_8x1_tcam_dmac_dmac2;
            @Api(layer="udf.outer_eth.dmac,24:31]") do_populate_udf_8x1_tcam_dmac_dmac3;
            @Api(layer="udf.outer_eth.dmac,32:39]") do_populate_udf_8x1_tcam_dmac_dmac4;
            @Api(layer="udf.outer_eth.dmac,40:47]") do_populate_udf_8x1_tcam_dmac_dmac5;
            @Api(layer="none") _nop;
        }
        size = 1;
        default_action = _nop();
    }
    apply {
        udf_8x1_tcam_dmac_cntr_decision_tbl.apply();
        udf_8x1_tcam_dmac_cntr_defer_cmd_tbl.apply();
        udf_8x1_tcam_dmac_populate_tbl.apply();
    }
}
# 149 "pktgen11.p4" 2







# 1 "tx_instrum.p4" 1
// ----------- Generate incrementing seqnums per pgid ------------------
/*
 * For seq_incr processing:
 * Just count up
 */
# 60 "tx_instrum.p4"
@name(".tx_seq_incr_reg")
Register<Ixia_seqnum_t, Pgid_t>(32768, 0) tx_seq_incr_reg;

control process_tx_instrum(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md,
                        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr) {
    @name(".seq_incr_gen")
    RegisterAction<Ixia_seqnum_t, Pgid_t, Ixia_seqnum_t>(tx_seq_incr_reg) seq_incr_gen = {
        void apply(inout Ixia_seqnum_t value, out Ixia_seqnum_t rv) {
            rv = (Ixia_seqnum_t)0;
            Ixia_seqnum_t in_value;
            in_value = value;
            value = in_value + 1;
            rv = value;
        }
    };
    @name(".do_populate_instrum")
    action do_populate_instrum() {
        hdr.instrum.tstamp = (Ixia_tstamp_t)eg_intr_from_prsr.global_tstamp;
        hdr.instrum.pgid = eg_md.txpgid;
    }
    @name(".do_incr_seqnum") action do_incr_seqnum() {
        hdr.instrum.seqnum = seq_incr_gen.execute(eg_md.txpgid);
    }
    @name(".eg_populate_instrum_tbl")
    table eg_populate_instrum_tbl {
        actions = {
            do_populate_instrum;
        }
        size = 1;
        default_action = do_populate_instrum();
    }
    @name(".incr_seqnum_tbl")
    table incr_seqnum_tbl {
        actions = {
            do_incr_seqnum;
        }
        size = 1;
        default_action = do_incr_seqnum();
    }
    apply {
        eg_populate_instrum_tbl.apply();
        incr_seqnum_tbl.apply();
    }
}
# 157 "pktgen11.p4" 2
# 1 "eg_stats.p4" 1
# 126 "eg_stats.p4"
//===============================  P4-16 code ==================================

control process_eg_port_stats(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
  @name(".eg_port_stats_cntrA")
  @block(name=eg_port_stats)
  @Feature(name="TxPortStatsA", block=eg_port_stats, service=Stats, service_id=TxPortStatsA, index=port,
    display_name="Tx Port Stats A", display_cols="Port|TxBytesA|TxPacketsA",col_units="|bytes|packets")
  @brief("Egress port stats counter bank A")
  @description("Egress port stats counter bank A, increments when MODE REG bank = 0")
 Counter<bit<32>, PortId_t>(32w512, CounterType_t.PACKETS_AND_BYTES) eg_port_stats_cntrA;

  // pseudo-feature to declare a regex and label for multiple stats
  @Feature(name="PortStats", block=eg_port_stats, service=Stats, service_id=".*PortStats.*",
    index=port, display_name="All Port Stats")
  @brief("Fake entity - not instantatiated, do not attempt to access")
  @description("Fake entity to receive annotation for service_id regex")
  Counter<bit<32>, PortId_t>(32w512, CounterType_t.PACKETS_AND_BYTES) eg_port_stats_cntr_fake_all_port_stats;

  @name(".do_eg_port_statsA")
  @block(name=eg_port_stats)
 action do_eg_port_statsA() {
        eg_port_stats_cntrA.count(eg_intr_md.egress_port);
    }

  @name(".eg_port_statsA_tbl")
  @block(name=eg_port_stats)
 table eg_port_statsA_tbl {
        actions = {
            do_eg_port_statsA;
        }
        size = 1;
        default_action = do_eg_port_statsA();
    }
# 184 "eg_stats.p4"
    apply {
# 193 "eg_stats.p4"
  eg_port_statsA_tbl.apply();

    }
}

control process_eg_pgid_stats(inout header_t hdr, inout egress_metadata_t eg_md, in egress_intrinsic_metadata_t eg_intr_md) {
  @name(".eg_pgid_stats_cntrA")
  @block(name=eg_pgid_stats)
  @Feature(name="TxPgidStatsA", block=eg_pgid_stats, service=Stats, service_id=TxPgidStatsA, index=pgid,
      display_name="Tx PGID Stats A", display_cols="Port|TxBytesA|TxPacketsA",col_units="|bytes|packets")
 Counter<bit<32>, Pgid_t>(32768, CounterType_t.PACKETS_AND_BYTES) eg_pgid_stats_cntrA;

  // pseudo-feature to declare a regex and label for multiple stats
  @Feature(name="PgidStats", block=eg_port_stats, service=Stats, service_id=".*PgidStats.*",
    index=pgid, display_name="All PGID Traffic Stats")
  @brief("Fake entity - not instantatiated, do not attempt to access")
  @description("Fake entity to receive annotation for service_id regex")
  Counter<bit<32>, PortId_t>(32w512, CounterType_t.PACKETS_AND_BYTES) eg_pgid_stats_cntr_fake_all_rx_port_stats;

  @name(".do_eg_pgid_statsA")
  @block(name=eg_pgid_stats)
 action do_eg_pgid_statsA() {
        eg_pgid_stats_cntrA.count(eg_md.txpgid);
    }

  @block(name=eg_pgid_stats)
  @name(".eg_pgid_statsA_tbl")
 table eg_pgid_statsA_tbl {
        actions = {
            do_eg_pgid_statsA;
        }
        size = 1;
        default_action = do_eg_pgid_statsA();
    }
# 252 "eg_stats.p4"
    apply {
# 261 "eg_stats.p4"
  eg_pgid_statsA_tbl.apply();

    }
}
# 158 "pktgen11.p4" 2

//=============================
//    TOP-LEVEL CONTROLS
//=============================
control process_validate_bridged_md(inout header_t hdr) {
    apply {
        hdr.bridged_md.setValid();
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    process_mode_reg() mode_reg;
    process_ig_port_stats() ig_port_stats;
    process_ig_pgid_stats() ig_pgid_stats;
    process_port_forwarding() port_forwarding;
    process_rx_pgid_flow_tracking() rx_pgid_flow_tracking;
    process_ig_seq_stats() ig_seq_stats;
    process_ig_lat_stats() ig_lat_stats;
    process_stream_ids() stream_ids;
    process_stream_metering() stream_metering;
    process_stream_meter_drops() stream_meter_drops;
    process_g_pkt_cntr() g_pkt_cntr;
    process_validate_bridged_md() validate_bridged_md;

    apply {
        validate_bridged_md.apply(hdr);
        mode_reg.apply(ig_md);
        ig_port_stats.apply(ig_md, ig_intr_md);

    // TODO - test for instrum, in case we generate non-instrum pkts?
        if (hdr.bridged_md.is_pktgen == 1 && ig_md.has_instrum == 1) {
            // packets from internal pktgen

            stream_ids.apply(hdr, ig_md);


            stream_metering.apply(ig_md);
            if ((ig_md.eg_stream_color != 0) &&
                ((ig_md.modes & 0x08) == 0x08) )
            {
                stream_meter_drops.apply(ig_tm_md);
            } else {


                g_pkt_cntr.apply(hdr, ig_md);



            }


        } else if (ig_md.has_instrum == 1) {
            // packets from external ports & contain instrumentation
            rx_pgid_flow_tracking.apply(ig_md);
            ig_pgid_stats.apply(ig_md);
            ig_lat_stats.apply(hdr, ig_prsr_md, ig_md);
            ig_seq_stats.apply(hdr, ig_md);
        }
        // fwd pktgen pkts; drop (usually) front-panel Rx packets, we just analyze them
        port_forwarding.apply(ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    // Instantiate controls
    process_prepopulate_hdr_g_reg() prepopulate_hdr_g_reg;
    process_pgid_16x2_load_params() pgid_16x2_load_params;
    process_pgid_16x2_process_pgids() pgid_16x2_process_pgids;
    process_udf_8x1_tcam_ipv4_dip() udf_8x1_tcam_ipv4_dip;
    process_udf_8x1_tcam_dmac() udf_8x1_tcam_dmac;
    process_tx_instrum() tx_instrum;
    process_eg_port_stats() eg_port_stats;
    process_eg_pgid_stats() eg_pgid_stats;

    // Invoke the controls
    apply {
        // Populate/modify the tx packet if it's from packet generator
        if (hdr.bridged_md.is_pktgen == 1w1) {

//#define BUG8382 1

            prepopulate_hdr_g_reg.apply(hdr, eg_md, eg_intr_md);
            pgid_16x2_load_params.apply(hdr, eg_md, eg_intr_md);
            pgid_16x2_process_pgids.apply(eg_md);

            udf_8x1_tcam_ipv4_dip.apply(hdr, eg_md);

            udf_8x1_tcam_dmac.apply(hdr, eg_md);
            tx_instrum.apply(hdr, eg_md, eg_intr_md, eg_intr_from_prsr);
            // TODO - should we process eg_pgid stats if instrumented packet, whether or not from pktgen?
            // Implies we might forward an  instrumented packet from a front panel port
            eg_pgid_stats.apply(hdr, eg_md, eg_intr_md);


        }
        eg_port_stats.apply(hdr, eg_md, eg_intr_md);
    }
}


//=============================
//    TOP-LEVEL PACKAGE
//=============================

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

/**
 * Below code appends global annotations to pkginfo by annotating "main()"
 */
// define Tofino internal packet generator annotations






// P4 "Standard" pkginfo annnotations to main()
@pkginfo(name="pktgen11.p4",version="1")
@brief("Tofino Packet Blaster")
@description("Tofino Packet Blaster.Performs RFC2889 port-mesh. Hackathon love-child.")

@pkginfo(organization="KeySight ISG NTS/Labs co-production")
@pkginfo(contact="chris.sommers@keysight.com")
@pkginfo(url="www.keysight.com")

// User-definned pkginfo annotations to main() 
// merge package-level attributes, conditionally set and/or #included



@attr(target_type=TOFINO1,access=ro,descrip="Target device type") @attr(pktgen_apps_per_pipe=8,access=ro,descrip="Number of packet-generator apps per pipe")
@attr(profile=1,access=ro,descrip="Build profile for this program") @attr(num_pgids=32768,access=ro,descrip="Number of PGID flows/stats supported by this program/profile") @attr(num_stats_banks=1,access=ro,descrip="Number of statistics banks supported by this program/profile")
@feature(name="gpkt_counter_x8",block="ig.pktgen",description="Global 8-bit counter used to synchronize UDF counters") @attr(global_pkt_cntr_width=8,access=ro,descrip="Width of global packet counter in bits")
@feature(name="pgid_16x2",block="eg.pgid",description="Chained 16-bit PGID counters") @attr(num_pgid_counters=256,access=ro,descrip="Size of PGID counter bank")@attr(pgid_cntr_width=16,access=ro,descrip="Width of pgid counters") @attr(pgid_cntr_stages=2,access=ro,descrip="Number of pgid counters in the chain")
@feature(name="udf.outer_ipv4.dip-octets",block="udf.outer_ipv4.dip",description="8-bit UDF generator to populate one selected octet in outer ipv4 dip")
@feature(name="udf.outer_eth.dmac-octets",block="udf.outer_eth.dmac",description="8-bit UDF generator to populate one selected octet in outer eth dmac")
@feature(name="eg.populate.outer_eth.dmac",block=eg_hdr_pop,description="configure static values for outer eth dmac octets") @feature(name="eg.populate.outer_eth.smac",block=eg_hdr_pop,description="configure static values for outer eth smac octets") @feature(name="eg.populate.outer_ipv4.dip",block=eg_hdr_pop,description="configure static values for outer ipv4 dip octets") @feature(name="eg.populate.outer_ipv4.sip",block=eg_hdr_pop,description="configure static values for outer ipv4 sip octets")
@feature(name="egress_port_stats",block="eg_port_stats",description="per-egress port byte and packet counters") @feature(name="egress_pgid_stats",block="eg_pgid_stats",description="per-egress PGID byte and packet counters")
@feature(name="ingress_port_stats",block="ig_port_stats",description="per-ingress port byte and packet counters") @feature(name="ingress_pgid_stats",block="ig_pgid_stats",description="per-ingress PGID byte and packet counters")
@feature(name="PktGen", block=pktgen, service=PktGen, service_id=pktgen, index="pipe|app", display_name="Tofino Packet Generator", display_cols="Pipe #|App #'|# Trigger Events|# Batches Sent|# Packets Sent", col_units="pipe|app|triggers|batches|packets")
Switch(pipe) main;
