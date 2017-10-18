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

#ifndef _V1MODEL_P4_
#define _V1MODEL_P4_

#include "core.p4"

// -----------------------------------------------------------------------------
// COMMON TYPES
// -----------------------------------------------------------------------------
typedef bit<9>  PortId_t;     // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t;   // Multicast group id
typedef bit<5>  QueueId_t;    // Queue id
typedef bit<4>  CloneId_t;    // Clone id
typedef bit<10> MirrorId_t;   // Mirror id

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

enum HashAlgorithm_t {
    IDENTITY,
    RANDOM,
    CRC16,
    CRC32,
    CSUM16
}

// p4_14_prim.p4 forward declared this enum.
enum CloneType {
    I2E,
    E2E
}

match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
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

    PortId_t ingress_port;               // ingress physical port id.
                                         // this field is passed to the deparser

    bit<48> ingress_mac_tstamp;          // ingress IEEE 1588 timestamp (in nsec)
                                         // taken at the ingress MAC.

    bit<32> instance_type;               // FIXME: tofino does not have this metadata
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
    bit<1> resubmit_flag;                // flag distinguising original packets
                                         // from resubmitted packets.
                                         // XXX(hanw) add_parde_metadata requires this.
    PortId_t ingress_port;               // ingress physical port id.
                                         // this field is passed to the deparser

    PortId_t ucast_egress_port;          // egress port for unicast packets. must
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

    QueueId_t qid;                           // egress (logical) queue id into which
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

    MulticastGroupId_t  mcast_grp_a;                 // 1st multicast group (i.e., tree) id;
                                         // a tree can have two levels. must be
                                         // presented to TM for multicast.

    MulticastGroupId_t  mcast_grp_b;                 // 2nd multicast group (i.e., tree) id;
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

struct ingress_intrinsic_metadata_for_deparser_t {
    bit<3> learn_idx;
    bit<3> resubmit_idx;
    bit<3> mirror_idx;
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
    bit<32> instance_type;               // TODO: tofino does not have this field
    PortId_t ingress_port;               // TODO(hanw): hack until ingress_port is part
                                         // of bridged metadata.

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

    bit<16> egress_parser_err;           // error flags indicating error(s)
                                         // encountered at egress
                                         // parser.
    bit<8> clone_src;                    // TODO: tofino does not have this field
}

struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> mirror_idx;
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

    bit<3> drop_ctl;                     // disable packet replication:
                                         //    - bit 0 disables unicast,
                                         //      multicast, and resubmit
                                         //    - bit 1 disables copy-to-cpu
                                         //    - bit 2 disables mirroring
                                         // TODO: which of these actually apply
                                         //       for egress?
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
extern counter<I> {
    counter(CounterType_t type, I instance_count);
    void count(in I index);
}

extern direct_counter {
    direct_counter(CounterType_t type);
    void count();
}

/// Meter
extern meter<I> {
    meter(MeterType_t type, @optional I instance_count);
    bit<8> execute(@optional in I index, @optional in bit<2> color);
}

extern direct_meter {
    direct_meter(MeterType_t type);
    void execute(in bit<2> color);
}

/// LPF

/// WRED

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

/// XXX(hanw): convert
extern action_selector {
    action_selector(HashAlgorithm_t algorithm, bit<32> size, bit<32> outputWidth);
}

extern action_profile {
    action_profile(bit<32> size);
}

/// XXX(hanw): avoid using 'emit' as method name to avoid issue in gen_deparser.cpp
/// as 'emit' is treated as packet_out.emit(), and it does not handle empty parameter.
extern mirror_packet {
    /// Write @hdr into the ingress/egress mirror buffer.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void add_metadata<T>(in T hdr);
}

extern resubmit_packet {
    /// Write @hdr into the in.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void add_metadata<T>(@optional in T hdr);
}

extern learn_filter_packet {
    ///
    void add_metadata<T>(in T hdr);
}

extern void mark_to_drop();
extern void recirculate<T>(in T data);
extern void truncate(in bit<32> length);

parser IngressParser<H, M>(
    packet_in pkt,
    out H hdr,
    inout M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
    );

parser EgressParser<H, M>(
    packet_in pkt,
    out H hdr,
    inout M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md);

control Ingress<H, M>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    @optional in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional out ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb,
    @optional out ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr);

control Egress<H, M>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    @optional out egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb,
    @optional out egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,
    @optional out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);

control IngressDeparser<H, M>(
    packet_out pkt,
    inout H hdr,
    @optional in M metadata,
    @optional in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional mirror_packet mirror,
    @optional resubmit_packet resubmit);

control EgressDeparser<H, M>(
    packet_out pkt,
    inout H hdr,
    @optional in M metadata,
    @optional in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional mirror_packet mirror);

package Switch<IH, IM, EH, EM>(
    IngressParser<IH, IM> ingress_parser,
    Ingress<IH, IM> ingress,
    IngressDeparser<IH, IM> ingress_deparser,
    EgressParser<EH, EM> egress_parser,
    Egress<EH, EM> egress,
    EgressDeparser<EH, EM> egress_deparser);

#endif  /* _V1MODEL_P4_ */
