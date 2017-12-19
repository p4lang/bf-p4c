/*
Copyright (c) 2015-2017 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

// -----------------------------------------------------------------------------
// stratum.p4 describes the ground-zero architecture for all derived
// architectures (tofino.p4, jbay.p4 and psa.p4).
// -----------------------------------------------------------------------------

#ifndef STRATUM_P4_
#define STRATUM_P4_

#include "core.p4"

enum PacketPath_t {
    NORMAL,     /// Packet received by ingress that is none of the cases below.
    NORMAL_UNICAST,   /// Normal packet received by egress which is unicast
    NORMAL_MULTICAST, /// Normal packet received by egress which is multicast
    CLONE_I2E,  /// Packet created via a clone operation in ingress,
                /// destined for egress
    CLONE_E2E,  /// Packet created via a clone operation in egress,
                /// destined for egress
    RESUBMIT,   /// Packet arrival is the result of a resubmit operation
    RECIRCULATE /// Packet arrival is the result of a recirculate operation
}

enum MeterType_t {
    PACKETS,
    BYTES
}

/// Counter
enum CounterType_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

/// Selector mode
enum SelectorMode_t {
    FAIR,
    RESILIENT
}

enum HashAlgorithm_t {
    IDENTITY,
    RANDOM,
    CRC16,
    CRC32,
    CSUM16
}

match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
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

@__compiler_generated
struct compiler_generated_metadata_t {
    // This struct is intentionally left blank and to be filled by later passes.
}

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag;                // flag distinguising original packets
                                         // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version;               // packet version.

    bit<3> _pad2;

    bit<9> ingress_port;                 // ingress physical port id.
                                         // this field is passed to the deparser

    bit<48> ingress_mac_tstamp;          // ingress IEEE 1588 timestamp (in nsec)
                                         // taken at the ingress MAC.
}

/// Produced by Ingress Parser-Auxiliary
@__intrinsic_metadata
struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> ingress_global_tstamp;       // global timestamp (ns) taken upon
                                         // arrival at ingress.
    bit<32> ingress_global_ver;          // global version number taken upon
                                         // arrival at ingress.
    bit<16> ingress_parser_err;          // error flags indicating error(s)
                                         // encountered at ingress parser.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    // The ingress physical port id is passed to the TM directly from
    bit<9> ucast_egress_port;            // egress port for unicast packets. must
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

    bit<5> qid;                          // egress (logical) queue id into which
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

    bit<16>  mcast_grp_a;                // 1st multicast group (i.e., tree) id;
                                         // a tree can have two levels. must be
                                         // presented to TM for multicast.

    bit<16>  mcast_grp_b;                // 2nd multicast group (i.e., tree) id;
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

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_deparser_t {
    bit<3> learn_idx;
    bit<3> resubmit_idx;
    bit<3> mirror_idx;     // The user-selected mirror field list index.

    bit<8> mirror_source;  // Compiler-generated field containing metadata about
                           // the mirror field list.
                           // XXX(seth): We should eliminate this once we have a
                           // generic mechanism for introducing
                           // compiler-generated metadata in the midend; it's
                           // not really something that should be user-visible.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_mirror_buffer_t {
    bit<10> mirror_id;                   // ingress mirror id. must be presented
                                         // to mirror buffer for mirrored
                                         // packets.
}

// -----------------------------------------------------------------------------
// EGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header egress_intrinsic_metadata_t {
    bit<7> _pad0;

    bit<9> egress_port;                  // egress port id.
                                         // this field is passed to the deparser

    bit<5> _pad1;

    bit<19> enq_qdepth;                  // queue depth at the packet enqueue
                                         // time.

    bit<6> _pad2;

    bit<2> enq_congest_stat;             // queue congestion status at the packet
                                         // enqueue time.

    bit<32> enq_tstamp;                  // time snapshot taken when the packet
                                         // is enqueued (in nsec).

    bit<5> _pad3;

    bit<19> deq_qdepth;                  // queue depth at the packet dequeue
                                         // time.

    bit<6> _pad4;

    bit<2> deq_congest_stat;             // queue congestion status at the packet
                                         // dequeue time.

    bit<8> app_pool_congest_stat;        // dequeue-time application-pool
                                         // congestion status. 2bits per
                                         // pool.

    bit<32> deq_timedelta;               // time delta between the packet's
                                         // enqueue and dequeue time.

    bit<16> egress_rid;                  // L3 replication id for multicast
                                         // packets.

    bit<7> _pad5;

    bit<1> egress_rid_first;             // flag indicating the first replica for
                                         // the given multicast group.

    bit<3> _pad6;

    bit<5> egress_qid;                   // egress (physical) queue id via which
                                         // this packet was served.

    bit<5> _pad7;

    bit<3> egress_cos;                   // egress cos (eCoS) value.

    bit<7> _pad8;

    bit<1> deflection_flag;              // flag indicating whether a packet is
                                         // deflected due to deflect_on_drop.

    bit<16> pkt_length;                  // Packet length, in bytes
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_from_parser_t {
    bit<48> egress_global_tstamp;        // global time stamp (ns) taken at the
                                         // egress pipe.

    bit<32> egress_global_ver;           // global version number taken at the
                                         // egress pipe.

    bit<16> egress_parser_err;           // error flags indicating error(s)
                                         // encountered at egress
                                         // parser.

    bit<4> clone_digest_id;              // value indicating the digest ID,
                                         // based on the field list ID.

    bit<4> clone_src;                    // value indicating whether or not this
                                         // is a cloned packet, and if so, where
                                         // it came from.
                                         // (see #defines in glass's constants.p4)

    bit<8> coalesce_sample_count;        // if clone_src indicates this packet
                                         // is coalesced, the number of samples
                                         // taken from other packets
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> mirror_idx;

    bit<8> mirror_source;  // Compiler-generated field containing metadata about
                           // the mirror field list.
                           // XXX(seth): We should eliminate this once we have a
                           // generic mechanism for introducing
                           // compiler-generated metadata in the midend; it's
                           // not really something that should be user-visible.
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_mirror_buffer_t {
    bit<10> mirror_id;                   // egress mirror id. must be presented to
                                         // mirror buffer for mirrored packets.

    bit<1> coalesce_flush;               // flush the coalesced mirror buffer
    bit<7> coalesce_length;              // the number of bytes in the current
                                         // packet to collect in the mirror
                                         // buffer
}

@__intrinsic_metadata
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

    bit<3> drop_ctl;                     // disable packet replication:
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
header pktgen_generic_header_t {
    bit<3> _pad0;
    bit<3> app_id;
    bit<2> pipe_id;
    bit<8> key_msb;   // Only valid for recirc triggers.
    bit<16> batch_id; // Overloaded to port# or lsbs of key for port down and
                      // recirc triggers.
    bit<16> packet_id;
}

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
    checksum(HashAlgorithm_t algorithm);
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

// Parser value set
// The parser value set implements a run-time updatable values that is used to
// determine parser transition
extern value_set<D> {
    value_set(bit<8> size);
    bool is_member(in D data);
}

// Parser priority
// The ingress parser drops the packet based on priority if the input buffer is
// indicating congestion; egress parser does not perform any dropping.
extern priority {
    priority();
    void set(in bit<3> prio);
}

// -----------------------------------------------------------------------------
// HASH ENGINE
// -----------------------------------------------------------------------------
extern hash<D, T, M> {
    /// Constructor
    hash(HashAlgorithm_t algo);

    /// compute the hash for data
    ///  @base :
    ///  @max :
    T get_hash(in D data, @optional in T base, @optional in M max);
}

/// Random number generator
extern random<T> {
    random();
    T get(@optional in T mask);
}

/// idle timeout
extern idle_timeout {
    idle_timeout(bit<3> state_count, @optional bool two_way_notify /* = false */,
                 @optional bool per_flow_enable /* = false */);
}

/// Counter
extern Counter<W, S> {
    Counter(bit<32> n_counters, CounterType_t type);
    void count(in S index);
}

extern DirectCounter<W> {
    DirectCounter(CounterType_t type);
    void count();
}

/// Meter
extern Meter<S> {
    Meter(bit<32> n_meters, MeterType_t type);
    bit<8> execute(in S index, @optional in bit<2> color);
    //bit<8> execute(in S index);
}

/// direct meter is not translated.
extern DirectMeter {
    DirectMeter(MeterType_t type);
    bit<8> execute(@optional in bit<2> color);
    //bit<8> execute();
}

/// LPF
extern lpf<T> {
    lpf(@optional bit<32> instance_count);
    T execute(in T val, @optional in bit<32> index);
}

/// WRED
extern wred<T> {
    wred(T lower_bound, T upper_bound, @optional bit<32> instance_count);
    T execute(in T val, @optional in bit<32> index);
}

/// Register
extern register<T> {
    register(@optional bit<32> instance_count, @optional T initial_value);

    ///XXX(hanw): BRIG-212
    /// following two methods are not supported in brig backend
    /// they are present to help with the transition from v1model to tofino.p4
    /// after the transition, these two methods should be removed
    /// and the corresponding test cases should be marked as XFAILs.
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern register_params<T> {
    register_params();
    register_params(T value);
    register_params(T v1, T v2);
    register_params(T v1, T v2, T v3);
    register_params(T v1, T v2, T v3, T v4);
    T read(bit<2> index);
}

extern math_unit<T, U> {
    math_unit(bool invert, int<2> shift, int<6> scale, U data);
    T execute(in T x);
}

extern register_action<T, U> {
    register_action(register<T> reg, @optional math_unit<U, _> math,
                                     @optional register_params<U> params);
    abstract void apply(inout T value, @optional out U rv, @optional register_params<U> params);
    U execute(@optional in bit<32> index); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv);
        reg.write(index, value);
        return rv;
    } */
}

/// stateful alu defined but not yet supported, the one supported in backend is
/// the version after P14-to-16 translation.

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

extern action_selector {
    action_selector(HashAlgorithm_t algorithm, bit<32> size, bit<32> outputWidth);
}

extern selector_action {
    selector_action(action_selector sel);
    abstract void apply(inout bit<1> value, @optional out bit<1> rv);
    bit<1> execute(@optional in bit<32> index);
}

/// Action Selector
//extern action_selector<T> {
//    /// Optional annotations to help with compiler fitting
//    /// @max_num_groups, max number of groups in a selector table
//    /// @max_group_size, max number of entries in a group
//    action_selector(bit<32> size,
//                    @optional SelectorMode_t mode,
//                    @optional register<bit<1>> reg);
//    abstract T hash();
//}

extern action_profile {
    action_profile(bit<32> size);
}

/// need to remove truncate from tofino.p4
extern void truncate(in bit<32> length);

extern mirror_packet {
    /// Write @hdr into the ingress/egress mirror buffer.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(in T hdr);
}

extern resubmit_packet {
    /// Write @hdr into the resubmit header.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(@optional in T hdr);
}

extern learning_packet {
    /// Write @hdr into learning digest.
    void emit<T>(in T hdr);
}

parser IngressParser<H, M, CG>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md,
    out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux
    );

parser EgressParser<H, M, CG>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md,
    out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    /// following two arguments are bridged metadata
    inout ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux
    );

control Ingress<H, M, CG>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout CG aux
    );

control Egress<H, M, CG>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    // following two arguments are bridged metadata
    inout ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux
    );

control IngressDeparser<H, M, CG>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    mirror_packet mirror,
    resubmit_packet resubmit,
    learning_packet learning,
    inout CG aux
    );

control EgressDeparser<H, M, CG>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    mirror_packet mirror,
    inout CG aux
    );

package Switch<IH, IM, EH, EM, CG>(
    IngressParser<IH, IM, CG> ingress_parser,
    Ingress<IH, IM, CG> ingress,
    IngressDeparser<IH, IM, CG> ingress_deparser,
    EgressParser<EH, EM, CG> egress_parser,
    Egress<EH, EM, CG> egress,
    EgressDeparser<EH, EM, CG> egress_deparser);

#endif  /* STRATUM_P4_ */
