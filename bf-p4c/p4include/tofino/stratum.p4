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
// Barefoot architectures.
// -----------------------------------------------------------------------------

#ifndef _STRATUM_P4_
#define _STRATUM_P4_

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

/// A hack to support v1model to tofino translation, the enum is required
/// as long as we still support v1model.p4
enum CloneType {
    I2E,
    E2E
}

enum MeterType_t {
    PACKETS,
    BYTES
}

enum MeterColor_t { RED, GREEN, YELLOW };

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

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag;               // Flag distinguising original packets
                                        // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version;              // Read-only Packet version.

    bit<3> _pad2;

    bit<9> ingress_port;              // Ingress physical port id.
                                        // this field is passed to the deparser

    bit<48> ingress_mac_tstamp;         // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    bit<9> ucast_egress_port;           // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bit<1> bypass_egress;               // Request flag for the warp mode
                                        // (egress bypass).

    bit<1> deflect_on_drop;             // Request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

    bit<3> ingress_cos;                 // Ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

    bit<5> qid;                         // Egress (logical) queue id into which
                                        // this packet will be deposited.

    bit<3> icos_for_copy_to_cpu;        // Ingress cos for the copy to CPU. must
                                        // be presented to TM if copy_to_cpu ==
                                        // 1.

    bit<1> copy_to_cpu;                 // Request for copy to cpu.

    bit<2> packet_color;                // Packet color (G,Y,R) that is
                                        // typically derived from meters and
                                        // used for color-based tail dropping.

    bit<1> disable_ucast_cutthru;       // Disable cut-through forwarding for
                                        // unicast.

    bit<1> enable_mcast_cutthru;        // Enable cut-through forwarding for
                                        // multicast.

    bit<16>  mcast_grp_a;    // 1st multicast group (i.e., tree) id;
                                        // a tree can have two levels. must be
                                        // presented to TM for multicast.

    bit<16>  mcast_grp_b;    // 2nd multicast group (i.e., tree) id;
                                        // a tree can have two levels.

    bit<13> level1_mcast_hash;          // Source of entropy for multicast
                                        // replication-tree level1 (i.e., L3
                                        // replication). must be presented to TM
                                        // for L3 dynamic member selection
                                        // (e.g., ECMP) for multicast.

    bit<13> level2_mcast_hash;          // Source of entropy for multicast
                                        // replication-tree level2 (i.e., L2
                                        // replication). must be presented to TM
                                        // for L2 dynamic member selection
                                        // (e.g., LAG) for nested multicast.

    bit<16> level1_exclusion_id;        // Exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    bit<9> level2_exclusion_id;         // Exclusion id for multicast
                                        // replication-tree level2. used for
                                        // pruning.

    bit<16> rid;                // L3 replication id for multicast.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp;              // Global timestamp (ns) taken upon
                                        // arrival at ingress.

    bit<32> global_ver;                 // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err;                 // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_deparser_t {

    bit<3> drop_ctl;                    // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring
    bit<3> digest_type;

    bit<3> resubmit_type;

    bit<3> mirror_type;                 // The user-selected mirror field list
                                        // index.
}

// -----------------------------------------------------------------------------
// EGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header egress_intrinsic_metadata_t {
    bit<7> _pad0;

    bit<9> egress_port;                 // Egress port id.
                                        // this field is passed to the deparser

    bit<5> _pad1;

    bit<19> enq_qdepth;                 // Queue depth at the packet enqueue
                                        // time.

    bit<6> _pad2;

    bit<2> enq_congest_stat;            // Queue congestion status at the packet
                                        // enqueue time.

    bit<32> enq_tstamp;                 // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    bit<5> _pad3;

    bit<19> deq_qdepth;                 // Queue depth at the packet dequeue
                                        // time.

    bit<6> _pad4;

    bit<2> deq_congest_stat;            // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat;       // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    bit<32> deq_timedelta;              // Time delta between the packet's
                                        // enqueue and dequeue time.

    bit<16> egress_rid;         // L3 replication id for multicast
                                        // packets.

    bit<7> _pad5;

    bit<1> egress_rid_first;            // Flag indicating the first replica for
                                        // the given multicast group.

    bit<3> _pad6;

    bit<5> egress_qid;               // Egress (physical) queue id via which
                                        // this packet was served.

    bit<5> _pad7;

    bit<3> egress_cos;                  // Egress cos (eCoS) value.

    bit<7> _pad8;

    bit<1> deflection_flag;             // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length;                 // Packet length, in bytes
}


@__intrinsic_metadata
struct egress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp;              // Global timestamp (ns) taken upon
                                        // arrival at ingress.

    bit<32> global_ver;                 // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err;                 // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> drop_ctl;                    // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring

    bit<3> mirror_type;

    bit<1> coalesce_flush;              // Flush the coalesced mirror buffer

    bit<7> coalesce_length;             // The number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_output_port_t {
    bit<1> capture_tstamp_on_tx;        // Request for packet departure
                                        // timestamping at egress MAC for IEEE
                                        // 1588. consumed by h/w (egress MAC).

    bit<1> update_delay_on_tx;          // Request for PTP delay (elapsed time)
                                        // update at egress MAC for IEEE 1588
                                        // Transparent Clock. consumed by h/w
                                        // (egress MAC). when this is enabled,
                                        // the egress pipeline must prepend a
                                        // custom header composed of <ingress
                                        // tstamp (40), byte offset for the
                                        // elapsed time field (8), byte offset
                                        // for UDP checksum (8)> in front of the
                                        // Ethernet header.
    bit<1> force_tx_error;              // force a hardware transmission error
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
extern Checksum<W> {
    Checksum(HashAlgorithm_t algorithm);
    void add<T>(in T data);
    void subtract<T>(in T data);
    bool verify();
    W get();
    W update<T>(in T data);
    W update<T>(in T data, in W residul_csum);
}

// -----------------------------------------------------------------------------
// PARSER COUNTER/PRIORITY/VALUE SET
// -----------------------------------------------------------------------------
extern ParserCounter<W> {
    // Constructor
    ParserCounter();

    /// Load the counter with an immediate value or a header field.
    void set(in W value);

    /// Load the counter with an immediate value or a header field.
    /// @param max : Maximum permitted value for counter (pre rotate/mask/add).
    /// @param rotate : Rotate the source field right by this number of bits.
    /// @param mask : Mask the rotated source field by 2**(MASK+1) - 1.
    /// @param add : Constant to add to the rotated and masked lookup field.
    void set(in W value,
             in W max,
             in W rotate,
             in W mask,
             in W add);

    /// Get the parser counter value. Can only be used in the select expression
    /// in a parser state and can only checks if the counter is zero or
    /// negative.
    /// @return : restricted parser counter value.
    W get();

    /// Add an immediate value to the parser counter.
    /// @param value : Constant to add to the counter.
    void increment(in W value);

    /// Subtract an immediate value from the parser counter.
    /// @param value : Constant to subtract from the counter.
    void decrement(in W value);
}

// Tofino ingress parser compare the priority with a configurable!!! threshold
// to determine to whether drop the packet if the input buffer is congested.
// Egress parser does not perform any dropping.
extern ParserPriority {
    /// Constructor
    ParserPriority();

    /// Set a new priority for the packet.
    void set(in bit<3> prio);
}

// ----------------------------------------------------------------------------
// HASH ENGINE
// ----------------------------------------------------------------------------
extern Hash<W> {
    /// Constructor
    Hash(HashAlgorithm_t algo);

    /// Compute the hash for data.
    /// @param data : The data over which to calculate the hash.
    /// @return The hash value.
    W get<D>(in D data);

    /// Compute the hash for data.
    /// @param data : The data over which to calculate the hash.
    /// @param base : Minimum return value.
    /// @param max : The value use in modulo operation.
    /// @return (base + (h % max)) where h is the hash value.
    W get<D>(in D data, in W base, in W max);
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
extern Lpf<T, I> {
    Lpf(bit<32> size);
    T execute(in T val, in I index);
}

/// Direct LPF
extern DirectLpf<T> {
    DirectLpf();
    T execute(in T val);
}

/// WRED
extern Wred<T, I> {
    Wred(bit<32> size, bit<8> drop_value, bit<8> no_drop_value);
    bit<8> execute(in T val, in I index);
}

/// Direct WRED
extern DirectWred<T> {
    DirectWred(bit<8> drop_value, bit<8> no_drop_value);
    bit<8> execute(in T val);
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
    U execute_log(); /* execute at an index that increments each time */
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

/// Register
extern Register<T> {
    /// Instantiate an array of <size> registers. The initial value is
    /// undefined.
    Register(bit<32> size);

    /// Initialize an array of <size> registers and set their value to
    /// initial_value.
    Register(bit<32> size, T initial_value);
}

extern ActionSelector {
    /// Construct an action selector of 'size' entries
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);

    /// Stateful action selector.
    ActionSelector(bit<32> size,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   Register<bit<1>> reg);
}

extern selector_action {
    selector_action(ActionSelector sel);
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


extern ActionProfile {
    /// Construct an action profile of 'size' entries.
    ActionProfile(bit<32> size);
}

/// need to remove truncate from tofino.p4
extern void truncate(in bit<32> length);

extern Mirror {
    Mirror();

    void emit(in bit<10> session_id);

    /// Write @hdr into the ingress/egress mirror buffer.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in bit<10> session_id, in T hdr);
}


/// Tofino supports packet resubmission at the end of ingress pipeline. When
/// a packet is resubmitted, the original packet reference and some limited
/// amount of metadata (64 bits) are passed back to the packet’s original
/// ingress buffer, where the packet is enqueued again.
extern Resubmit {
    /// Constructor
    Resubmit();

    /// Resubmit the packet.
    void emit();

    /// Resubmit the packet and prepend it with @hdr.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in T hdr);
}

extern Digest {
    /// define a digest stream to the control plane
    Digest();

    /// Emit data into the stream.  The p4 program can instantiate multiple
    /// Digest instances in the same deparser control block, and call the pack
    /// method once during a single execution of the control block
    void pack<T>(in T data);
}

parser IngressParser<H, M, CG>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md,
    out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

parser EgressParser<H, M, CG>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md,
    out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    /// following two arguments are bridged metadata
    inout ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

control Ingress<H, M, CG>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

control Egress<H, M, CG>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,
    // following two arguments are bridged metadata
    inout ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout CG aux);

control IngressDeparser<H, M, CG>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout CG aux);

control EgressDeparser<H, M, CG>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    in egress_intrinsic_metadata_t eg_intr_md,
    in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

package Switch<IH, IM, EH, EM, CG>(
    IngressParser<IH, IM, CG> ingress_parser,
    Ingress<IH, IM, CG> ingress,
    IngressDeparser<IH, IM, CG> ingress_deparser,
    EgressParser<EH, EM, CG> egress_parser,
    Egress<EH, EM, CG> egress,
    EgressDeparser<EH, EM, CG> egress_deparser);

#endif  /* _STRATUM_P4_ */
