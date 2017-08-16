#ifndef _TOFINO_P4_
#define _TOFINO_P4_

#include "core.p4"

// -----------------------------------------------------------------------------
// COMMON TYPES
// -----------------------------------------------------------------------------
typedef bit<9> portid_t;     // Port ID -- ingress or egress port
typedef bit<16> mgid_t;      // Multicast group id
typedef bit<5> qid_t;        // Queue id
typedef bit<4> cloneid_t;    // Clone id
typedef bit<10> mirrorid_t;  // Mirror id

/// Meter types
enum meter_type_t {
    PACKETS,
    BYTES
}

/// Meter colors
enum meter_color_t {
    RED,
    GREEN,
    YELLOW
};

/// Counter
enum counter_type_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

/// Selector mode
enum selector_mode_t {
    FAIR,
    RESILIENT
}

enum hash_algorithm_t {
    IDENTITY,
    RANDOM,
    CRC16,
    CRC32
}

match_kind {
    // exact
    // ternary
    // lpm
    range
}

error {
    // NoError,           // No error.
    // PacketTooShort,    // Not enough bits in packet for 'extract'.
    // NoMatch,           // 'select' expression has no matches.
    // StackOutOfBounds,  // Reference to invalid element of a header stack.
    // HeaderTooShort,    // Extracting too many bits into a varbit field.
    // ParserTimeout      // Parser execution time limit exceeded.
    CounterRange,
    PhvOwner,
    MultiWrite
    // Add more errors here.
}

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag;                // flag distinguising original packets
                                         // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version;               // packet version.

    bit<3> _pad2;

    portid_t ingress_port;               // ingress physical port id.
                                         // this field is passed to the deparser

    bit<48> ingress_mac_tstamp;          // ingress IEEE 1588 timestamp (in nsec)
                                         // taken at the ingress MAC.
}

/// Produced by Ingress Parser-Auxiliary
struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> ingress_global_tstamp;       // global timestamp (ns) taken upon
                                         // arrival at ingress.
    bit<32> ingress_global_ver;          // global version number taken upon
                                         // arrival at ingress.
    bit<16> ingress_parser_err;          // error flags indicating error(s)
                                         // encountered at ingress parser.
}

struct ingress_intrinsic_metadata_for_tm_t {
    // The ingress physical port id is passed to the TM directly from
    // ig_intr_md.ingress_port

    portid_t ucast_egress_port;          // egress port for unicast packets. must
                                         // be presented to TM for unicast.

    bit<3> drop_ctl;                     // disable packet replication:
                                         //    - bit 0 disables unicast,
                                         //      multicast, and resubmit
                                         //    - bit 1 disables copy-to-cpu
                                         //    - bit 2 disables mirroring
    bit<1> bypass_egress;                // request flag for the warp mode
                                         // (egress bypass).
    bit<1> deflect_on_drop;              // request for deflect on drop. must be
                                         // presented to TM to enable deflection
                                         // upon drop.

    bit<3> ingress_cos;                  // ingress cos (iCoS) for PG mapping,
                                         // ingress admission control, PFC,
                                         // etc.

    qid_t qid;                           // egress (logical) queue id into which
                                         // this packet will be deposited.
    bit<3> icos_for_copy_to_cpu;         // ingress cos for the copy to CPU. must
                                         // be presented to TM if copy_to_cpu ==
                                         // 1.

    bit<1> copy_to_cpu;                  // request for copy to cpu.

    bit<2> packet_color;                 // packet color (G,Y,R) that is
                                         // typically derived from meters and
                                         // used for color-based tail dropping.

    bit<1> disable_ucast_cutthru;        // disable cut-through forwarding for
                                         // unicast.
    bit<1> enable_mcast_cutthru;         // enable cut-through forwarding for
                                         // multicast.

    mgid_t  mcast_grp_a;                 // 1st multicast group (i.e., tree) id;
                                         // a tree can have two levels. must be
                                         // presented to TM for multicast.

    mgid_t  mcast_grp_b;                 // 2nd multicast group (i.e., tree) id;
                                         // a tree can have two levels.

    bit<13> level1_mcast_hash;           // source of entropy for multicast
                                         // replication-tree level1 (i.e., L3
                                         // replication). must be presented to TM
                                         // for L3 dynamic member selection
                                         // (e.g., ECMP) for multicast.

    bit<13> level2_mcast_hash;           // source of entropy for multicast
                                         // replication-tree level2 (i.e., L2
                                         // replication). must be presented to TM
                                         // for L2 dynamic member selection
                                         // (e.g., LAG) for nested multicast.

    bit<16> level1_exclusion_id;         // exclusion id for multicast
                                         // replication-tree level1. used for
                                         // pruning.

    bit<9> level2_exclusion_id;          // exclusion id for multicast
                                         // replication-tree level2. used for
                                         // pruning.

    bit<16> rid;                         // L3 replication id for multicast.
}

struct ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<10> mirror_id;                   // ingress mirror id. must be presented
                                         // to mirror buffer for mirrored
                                         // packets.
}

// -----------------------------------------------------------------------------
// EGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
header egress_intrinsic_metadata_t {
    bit<9> egress_port;                  // egress port id.
                                         // this field is passed to the deparser

    bit<19> enq_qdepth;                  // queue depth at the packet enqueue
                                         // time.

    bit<2> enq_congest_stat;             // queue congestion status at the packet
                                         // enqueue time.

    bit<32> enq_tstamp;                  // time snapshot taken when the packet
                                         // is enqueued (in nsec).

    bit<19> deq_qdepth;                  // queue depth at the packet dequeue
                                         // time.

    bit<2> deq_congest_stat;             // queue congestion status at the packet
                                         // dequeue time.

    bit<8> app_pool_congest_stat;        // dequeue-time application-pool
                                         // congestion status. 2bits per
                                         // pool.

    bit<32> deq_timedelta;               // time delta between the packet's
                                         // enqueue and dequeue time.

    bit<16> egress_rid;                  // L3 replication id for multicast
                                         // packets.

    bit<1> egress_rid_first;             // flag indicating the first replica for
                                         // the given multicast group.

    bit<5> egress_qid;                   // egress (physical) queue id via which
                                         // this packet was served.

    bit<3> egress_cos;                   // egress cos (eCoS) value.

    bit<1> deflection_flag;              // flag indicating whether a packet is
                                         // deflected due to deflect_on_drop.

    bit<16> pkt_length;                  // Packet length, in bytes
}

struct egress_intrinsic_metadata_from_parser_t {
    bit<48> egress_global_tstamp;        // global time stamp (ns) taken at the
                                         // egress pipe.

    bit<32> egress_global_ver;           // global version number taken at the
                                         // egress pipe.

  bit<16> egress_parser_err;             // error flags indicating error(s)
                                         // encountered at egress
                                         // parser.
}

struct egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<10> mirror_id;                   // egress mirror id. must be presented to
                                         // mirror buffer for mirrored packets.

    bit<1> coalesce_flush;               // flush the coalesced mirror buffer
    bit<7> coalesce_length;              // the number of bytes in the current
                                         // packet to collect in the mirror
                                         // buffer
}

struct egress_intrinsic_metadata_for_output_port_t {
    bit<1> capture_tstamp_on_tx;         // request for packet departure
                                         // timestamping at egress MAC for IEEE
                                         // 1588. consumed by h/w (egress MAC).
    bit<1> update_delay_on_tx;           // request for PTP delay (elapsed time)
                                         // update at egress MAC for IEEE 1588
                                         // Transparent Clock. consumed by h/w
                                         // (egress MAC). when this is enabled,
                                         // the egress pipeline must prepend a
                                         // custom header composed of <ingress
                                         // tstamp (40), byte offset for the
                                         // elapsed time field (8), byte offset
                                         // for UDP checksum (8)> in front of the
                                         // Ethernet header.
    bit<1> force_tx_error;               // force a hardware transmission error

    bit<1> drop_ctl;                     // disable packet replication:
                                         //    - bit 0 disables unicast,
                                         //      multicast, and resubmit
                                         //    - bit 1 disables copy-to-cpu
                                         //    - bit 2 disables mirroring
                                         // TODO: which of these actually apply
                                         //       for egress?
}


// -----------------------------------------------------------------------------
// PACKET GENERATION
// -----------------------------------------------------------------------------
// Packet generator supports up to 8 applications and a total of 16KB packet 
// payload. Each application is associated with one of the four trigger types:
// - One-time timer
// - Periodic timer
// - Port down
// - Packet recirculation
// For recirculated packets, the event fires when the first 32 bits of the
// recirculated packet matches the application match value and mask.
// A triggered event may generate programmable number of batches with
// programmable packets per batch.

header pktgen_timer_header_t {
    bit<3> _pad1;
    bit<2> pipe_id;     // Pipe id
    bit<3> app_id;      // Application id 
    bit<8> _pad2;
    bit<16> batch_id;   // Start at 0 and increment to a programmed number
    bit<16> packet_id;  // Start at 0 and increment to a programmed number
}

header pktgen_port_down_header_t {
    bit<3> _pad1;
    bit<2> pipe_id;     // Pipe id
    bit<3> app_id;      // Application id
    bit<15> _pad2;
    bit<9> port_num;    // Port number
    bit<16> packet_id;  // Start at 0 and increment to a programmed number
}

header pktgen_recirc_header_t {
    bit<3> _pad1;
    bit<2> pipe_id;     // Pipe id
    bit<3> app_id;      // Application id
    bit<24> key;        // key from the recirculated packet 
    bit<16> packet_id;  // Start at 0 and increment to a programmed number
}

// -----------------------------------------------------------------------------
// CHECKSUM
// -----------------------------------------------------------------------------
// Tofino checksum engine can verify the checksums for header-only checksums
// and calculate the residual (checksum minus the header field
// contribution) for checksums that include the payload.
// Checksum engine only supports 16-bit ones' complement checksums.
extern checksum<W> {
    checksum(hash_algorithm_t algorithm);
    void add<T>(in T data);
    bool verify();
    void update<T>(in T data, out W csum, @optional in W residul_csum);
    W residual_checksum<T>(in T data);
}

// -----------------------------------------------------------------------------
// PARSER COUNTER/PRIORITY/VALUE SET
// -----------------------------------------------------------------------------
extern parser_counter {
    parser_counter();
    /// Load the counter with an immediate value or a header field.
    ///   @max : Maximum permitted value for counter (pre rotate/mask/add).
    ///   @rotate : Rotate the source field right by this number of bits.
    ///   @mask : Mask the rotated source field by 2**(MASK+1) - 1.
    ///   @add : Constant to add to the rotated and masked lookup field.
    void set(in int<8> value,
            @optional in int<8> max,
            @optional in bit<3> rotate,
            @optional in bit<3> mask,
            @optional in int<8> add);

    /// Add an immediate value to the parser counter.
    void increment(in int<8> value);
    bool is_zero();
    bool is_neg();
}

// Parser priority
// The ingress parser drops the packet based on priority if the input buffer is
// indicating congestion; egress parser does not perform any dropping.
extern priority {
    priority();
    void set(in bit<3> prio);
}

// Parser value set
// The parser value set implements a run-time updatable values that is used to
// determine parser transition
extern value_set<D> {
    value_set(bit<8> size);
    bool is_member(in D data);
}

// -----------------------------------------------------------------------------
// HASH ENGINE
// -----------------------------------------------------------------------------
extern hash<T> {
    /// Constructor
    hash(hash_algorithm_t algo);

    /// compute the hash for data
    ///  @base :
    ///  @max :
    T get_hash<D>(in D data, @optional in T base, @optional in T max);
}

/// Random number generator
extern random<T> {
    random();
    T get(@optional in T mask);
}

/// idle timeout
extern idle_timeout<N, T> {
    idle_timeout(N state_count, T idle_interval);
}

/// Counter
extern counter<I> {
    counter(counter_type_t type, @optional I instance_count);
    void count(@optional in I index);
}

/// Meter
extern meter<I> {
    meter(meter_type_t type, @optional I instance_count);
    meter_color_t execute(@optional in I index,
                          @optional in meter_color_t color);
}

/// Low pass filter (LPF)
extern lpf<T, I> {
    lpf(@optional I instance_count);
    T execute(in T data, @optional in I index);
}

/// Random early drop (RED)
extern wred<T, I> {
    wred(@optional I instance_count);
    T execute(in T data, @optional in I index);
}

/// Register
extern register<T> {
    register(@optional bit<32> instance_count, @optional T initial_value);
}

extern stateful_param<T> {
    stateful_param(T initial_value);
    T read();
}

/// StatefulALU
extern stateful_alu<T, O, P> {
    stateful_alu(@optional register<T> reg, @optional stateful_param<P> param);
    abstract void instruction(inout T value, @optional out O rv, @optional in P p);
    O execute<I>(@optional in I index);
}

/// Action Selector
extern action_selector<T> {
    /// Optional annotations to help with compiler fitting
    /// @max_num_groups, max number of groups in a selector table
    /// @max_group_size, max number of entries in a group
    action_selector(bit<32> size,
                    @optional selector_mode_t mode,
                    @optional register<bit<1>> reg);
    abstract T hash();
}

extern action_profile {
    action_profile(bit<32> size);
}

extern mirror_packet {
    /// Write @hdr into the ingress/egress mirror buffer.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(in T hdr);
}

extern resubmit_packet {
    /// Write @hdr into the in.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(in T hdr);
}

extern learn_filter_packet {
    ///
    void emit<T>(in T hdr);
}

parser IngressParser<H, M>(
  packet_in pkt,
  out H hdr,
  out M ig_md,
  out ingress_intrinsic_metadata_t ig_intr_md,
  @optional in bit<48> global_tstamp,
  @optional in bit<32> global_version);

parser EgressParser<H, M>(
  packet_in pkt,
  out H hdr,
  out M eg_md,
  out egress_intrinsic_metadata_t eg_intr_md,
  @optional in bit<48> global_tstamp,
  @optional in bit<32> global_version);

control Ingress<H, M>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    @optional in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional out ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb);

control Egress<H, M>(
  inout H hdr,
  inout M eg_md,
  in egress_intrinsic_metadata_t eg_intr_md,
  @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
  @optional out egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb,
  @optional out egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);


control IngressDeparser<H, M>(
    packet_out pkt,
    in H hdr,
    @optional in M metadata,
    @optional mirror_packet mirror,
    @optional resubmit_packet resubmit,
    @optional learn_filter_packet lf);

control EgressDeparser<H, M>(
    packet_out pkt,
    in H hdr,
    @optional in M metadata,
    @optional mirror_packet mirror);

package Switch<IH, IM, EH, EM>(
    IngressParser<IH, IM> ingress_parser,
    Ingress<IH, IM> ingress,
    IngressDeparser<IH, IM> ingress_deparser,
    EgressParser<EH, EM> egress_parser,
    Egress<EH, EM> egress,
    EgressDeparser<EH, EM> egress_deparser);

#endif  /* _TOFINO_P4_ */
