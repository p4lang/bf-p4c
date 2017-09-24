/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/// XXX(hanw): This is a temporary architecture file to assist the
/// v1model to tofino translation, it will be removed once the
/// translation to tofino native architeture is complete.

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

match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
}

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
struct ingress_intrinsic_metadata_t {
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
    // ig_intr_md.ingress_port

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
struct egress_intrinsic_metadata_t {
    bit<32> instance_type;               // TODO: tofino does not have this field
    bit<8> clone_src;                    // TODO: tofino does not have this field

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

    bit<1> drop_ctl;                     // disable packet replication:
                                         //    - bit 0 disables unicast,
                                         //      multicast, and resubmit
                                         //    - bit 1 disables copy-to-cpu
                                         //    - bit 2 disables mirroring
                                         // TODO: which of these actually apply
                                         //       for egress?
}

extern Checksum16 {
    Checksum16();
    bit<16> get<D>(in D data);
}

/// Counter
enum counter_type_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

enum meter_type_t {
    PACKETS,
    BYTES
}

/// Counter
extern counter<I> {
    counter(counter_type_t type, @optional I instance_count);
    void count(@optional in I index);
}

/// Meter
extern meter<I> {
    meter(meter_type_t type, @optional I instance_count);
    bit<8> execute(@optional in I index, @optional in bit<8> color);
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

// used as table implementation attribute
extern action_profile {
    action_profile(bit<32> size);
}

/// Random number generator
extern random<T> {
    random();
    T get(@optional in T mask);
}

// If the type T is a named struct, the name is used
// to generate the control-plane API.
extern void digest<T>(in bit<32> receiver, in T data);

extern void mark_to_drop();

enum hash_algorithm_t {
    IDENTITY,
    RANDOM,
    CRC16,
    CRC32
}
extern hash<D, T, M> {
    /// Constructor
    hash(hash_algorithm_t algo);

    /// compute the hash for data
    ///  @base :
    ///  @max :
    T get_hash(in D data, @optional in T base, @optional in M max);
}

extern action_selector {
    action_selector(hash_algorithm_t algorithm, bit<32> size, bit<32> outputWidth);
}

enum CloneType {
    I2E,
    E2E
}

extern void resubmit<T>(in T data);
extern void recirculate<T>(in T data);
extern void clone(in CloneType type, in bit<32> session);
extern void clone3<T>(in CloneType type, in bit<32> session, in T data);

extern void truncate(in bit<32> length);

parser IngressParser<H, M>(
    packet_in pkt,
    out H hdr,
    inout M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md);

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
    @optional out ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb);

control Egress<H, M>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    @optional out egress_intrinsic_metadata_for_mirror_buffer_t eg_intr_md_for_mb,
    @optional out egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,
    /// XXX(hanw): temporary solution for bridge metadata until we can use defuse
    /// in midend to create bridge metadata.
    @optional in ingress_intrinsic_metadata_t ig_intr_md,
    @optional in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    @optional in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional in ingress_intrinsic_metadata_for_mirror_buffer_t ig_intr_md_for_mb);

control IngressDeparser<H, M>(
    packet_out pkt,
    in H hdr,
    @optional in M metadata);

control EgressDeparser<H, M>(
    packet_out pkt,
    in H hdr,
    @optional in M metadata);

package Switch<IH, IM, EH, EM>(
    IngressParser<IH, IM> ingress_parser,
    Ingress<IH, IM> ingress,
    IngressDeparser<IH, IM> ingress_deparser,
    EgressParser<EH, EM> egress_parser,
    Egress<EH, EM> egress,
    EgressDeparser<EH, EM> egress_deparser);

#endif  /* _V1MODEL_P4_ */
