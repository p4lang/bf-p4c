# 1 "npb/npb.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "npb/npb.p4"
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

// Custom profiles.




# 1 "/mnt/build/p4c/p4include/core.p4" 1
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

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */




/// Standard error codes.  New error codes can be declared by users.
error {
    NoError, /// No error.
    PacketTooShort, /// Not enough bits in packet for 'extract'.
    NoMatch, /// 'select' expression has no matches.
    StackOutOfBounds, /// Reference to invalid element of a header stack.
    HeaderTooShort, /// Extracting too many bits into a varbit field.
    ParserTimeout /// Parser execution time limit exceeded.
}

extern packet_in {
    /// Read a header from the packet into a fixed-sized header @hdr and advance the cursor.
    /// May trigger error PacketTooShort or StackOutOfBounds.
    /// @T must be a fixed-size header type
    void extract<T>(out T hdr);
    /// Read bits from the packet into a variable-sized header @variableSizeHeader
    /// and advance the cursor.
    /// @T must be a header containing exactly 1 varbit field.
    /// May trigger errors PacketTooShort, StackOutOfBounds, or HeaderTooShort.
    void extract<T>(out T variableSizeHeader,
                    in bit<32> variableFieldSizeInBits);
    /// Read bits from the packet without advancing the cursor.
    /// @returns: the bits read from the packet.
    /// T may be an arbitrary fixed-size type.
    T lookahead<T>();
    /// Advance the packet cursor by the specified number of bits.
    void advance(in bit<32> sizeInBits);
    /// @return packet length in bytes.  This method may be unavailable on
    /// some target architectures.
    bit<32> length();
}

extern packet_out {
    /// Write @hdr into the output packet, advancing cursor.
    /// @T can be a header type, a header stack, a header_union, or a struct
    /// containing fields with such types.
    void emit<T>(in T hdr);
}

// TODO: remove from this file, convert to built-in
/// Check a predicate @check in the parser; if the predicate is true do nothing,
/// otherwise set the parser error to @toSignal, and transition to the `reject` state.
extern void verify(in bool check, in error toSignal);

/// Built-in action that does nothing.
action NoAction() {}

/// Standard match kinds for table key fields.
/// Some architectures may not support all these match kinds.
/// Architectures can declare additional match kinds.
match_kind {
    /// Match bits exactly.
    exact,
    /// Ternary match, using a mask.
    ternary,
    /// Longest-prefix match.
    lpm
}
# 32 "npb/npb.p4" 2

# 1 "/mnt/build/p4c/p4include/t2na.p4" 1
/*
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */




# 1 "/mnt/build/p4c/p4include/core.p4" 1
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

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */
# 23 "/mnt/build/p4c/p4include/t2na.p4" 2
# 1 "/mnt/build/p4c/p4include/tofino2.p4" 1
/*
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
 *
 * All Rights Reserved.

 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.

 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 */




# 1 "/mnt/build/p4c/p4include/core.p4" 1
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

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */
# 23 "/mnt/build/p4c/p4include/tofino2.p4" 2

//XXX Open issues:
// Meter color
// Math unit
// Action selector
// Digest
// Coalesce mirroring

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9> PortId_t; // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t; // Multicast group id
typedef bit<7> QueueId_t; // Queue id
typedef bit<4> CloneId_t; // Clone id
typedef bit<8> MirrorId_t; // Mirror id
typedef bit<16> ReplicationId_t; // Replication id

typedef error ParserError_t;

const bit<32> PORT_METADATA_SIZE = 32w192;

/// Meter
enum MeterType_t { PACKETS, BYTES }

enum bit<8> MeterColor_t { GREEN = 8w0, YELLOW = 8w1, RED = 8w3 }

/// Counter
enum CounterType_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

/// Selector mode
enum SelectorMode_t { FAIR, RESILIENT }

enum HashAlgorithm_t {
    IDENTITY,
    RANDOM,
    CRC16,
    CRC32,
    CSUM16
}

match_kind {
    // exact,
    // ternary,
    // lpm,               // Longest-prefix match.
    range,
    selector, // Used for implementing dynamic action selection
    dleft_hash // Used for dleft dynamic caching
}

error {
    // NoError,           // No error.
    // NoMatch,           // 'select' expression has no matches.
    // PacketTooShort,    // Not enough bits in packet for 'extract'.
    // StackOutOfBounds,  // Reference to invalid element of a header stack.
    // HeaderTooShort,    // Extracting too many bits into a varbit field.
    // ParserTimeout      // Parser execution time limit exceeded.
    CounterRange, // Counter initialization error.
    Timeout,
    PhvOwner, // Invalid destination container.
    MultiWrite,
    IbufOverflow, // Input buffer overflow.
    IbufUnderflow // Inbut buffer underflow.
}

// -----------------------------------------------------------------------------
// INGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header ingress_intrinsic_metadata_t {
    bit<1> resubmit_flag; // Flag distinguising original packets
                                        // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version; // Read-only Packet version.

    bit<3> _pad2;

    PortId_t ingress_port; // Ingress physical port id.
                                        // this field is passed to the deparser

    bit<48> ingress_mac_tstamp; // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    PortId_t ucast_egress_port; // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bool bypass_egress; // Request flag for the warp mode
                                        // (egress bypass).

    bool deflect_on_drop; // Request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

    bit<3> ingress_cos; // Ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

    QueueId_t qid; // Egress (logical) queue id into which
                                        // this packet will be deposited.

    bit<3> icos_for_copy_to_cpu; // Ingress cos for the copy to CPU. must
                                        // be presented to TM if copy_to_cpu ==
                                        // 1.

    bool copy_to_cpu; // Request for copy to cpu.

    bit<2> packet_color; // Packet color (G,Y,R) that is
                                        // typically derived from meters and
                                        // used for color-based tail dropping.

    bool disable_ucast_cutthru; // Disable cut-through forwarding for
                                        // unicast.

    bool enable_mcast_cutthru; // Enable cut-through forwarding for
                                        // multicast.

    MulticastGroupId_t mcast_grp_a; // 1st multicast group (i.e., tree) id;
                                        // a tree can have two levels. must be
                                        // presented to TM for multicast.

    MulticastGroupId_t mcast_grp_b; // 2nd multicast group (i.e., tree) id;
                                        // a tree can have two levels.

    bit<13> level1_mcast_hash; // Source of entropy for multicast
                                        // replication-tree level1 (i.e., L3
                                        // replication). must be presented to TM
                                        // for L3 dynamic member selection
                                        // (e.g., ECMP) for multicast.

    bit<13> level2_mcast_hash; // Source of entropy for multicast
                                        // replication-tree level2 (i.e., L2
                                        // replication). must be presented to TM
                                        // for L2 dynamic member selection
                                        // (e.g., LAG) for nested multicast.

    bit<16> level1_exclusion_id; // Exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    bit<9> level2_exclusion_id; // Exclusion id for multicast
                                        // replication-tree level2. used for
                                        // pruning.

    ReplicationId_t rid; // L3 replication id for multicast.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp; // Global timestamp (ns) taken upon
                                        // arrival at ingress.

    bit<32> global_ver; // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err; // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_deparser_t {

    bit<3> drop_ctl; // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring
    bit<3> digest_type;

    bit<3> resubmit_type;

    bit<4> mirror_type; // The user-selected mirror field list
                                        // index.

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bool mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bool mirror_copy_to_cpu_ctrl; // Mirror enable copy-to-cpu if true.
    bool mirror_multicast_ctrl; // Mirror enable multicast if true.
    bit<9> mirror_egress_port; // Mirror packet egress port.
    bit<7> mirror_qid; // Mirror packet qid.
    bit<8> mirror_coalesce_length; // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    bit<32> adv_flow_ctl; // Advanced flow control for TM
    bit<14> mtu_trunc_len; // MTU for truncation check
    bit<1> mtu_trunc_err_f; // MTU truncation error flag

    bit<3> learn_sel; // Learn quantum table selector
    bool pktgen; // trigger packet generation
                                        // This is ONLY valid if resubmit_type
                                        // is not valid.
    bit<14> pktgen_address; // Packet generator buffer address.
    bit<10> pktgen_length; // Length of generated packet.

    // also need an extern for PacketGen
}
// -----------------------------------------------------------------------------
// GHOST INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata @__ghost_metadata
header ghost_intrinsic_metadata_t {
    bit<1> ping_pong; // ping-pong bit to control which version to update
    bit<18> qlength;
    bit<11> qid; // queue id for update
    bit<2> pipe_id;
}

// -----------------------------------------------------------------------------
// EGRESS INTRINSIC METADATA
// -----------------------------------------------------------------------------
@__intrinsic_metadata
header egress_intrinsic_metadata_t {
    bit<7> _pad0;

    bit<9> egress_port; // Egress port id.
                                        // this field is passed to the deparser

    bit<5> _pad1;

    bit<19> enq_qdepth; // Queue depth at the packet enqueue
                                        // time.

    bit<6> _pad2;

    bit<2> enq_congest_stat; // Queue congestion status at the packet
                                        // enqueue time.

    bit<32> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    bit<5> _pad3;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    bit<6> _pad4;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    bit<32> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    ReplicationId_t egress_rid; // L3 replication id for multicast
                                        // packets.

    bit<7> _pad5;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    bit<1> _pad6;

    QueueId_t egress_qid; // Egress (physical) queue id via which
                                        // this packet was served.

    bit<5> _pad7;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    bit<7> _pad8;

    bit<1> deflection_flag; // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length; // Packet length, in bytes

    bit<8> _pad9; // Pad to 4-byte alignment for egress
                                        // intrinsic metadata (HW constraint)
}


@__intrinsic_metadata
struct egress_intrinsic_metadata_from_parser_t {
    bit<48> global_tstamp; // Global timestamp (ns) taken upon
                                        // arrival at egress.

    bit<32> global_ver; // Global version number taken upon
                                        // arrival at ingress.

    bit<16> parser_err; // Error flags indicating error(s)
                                        // encountered at ingress parser.
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_deparser_t {
    bit<3> drop_ctl; // Disable packet replication:
                                        //    - bit 0 disables unicast,
                                        //      multicast, and resubmit
                                        //    - bit 1 disables copy-to-cpu
                                        //    - bit 2 disables mirroring

    bit<4> mirror_type;

    bit<1> coalesce_flush; // Flush the coalesced mirror buffer

    bit<7> coalesce_length; // The number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bool mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bool mirror_copy_to_cpu_ctrl; // Mirror enable copy-to-cpu if true.
    bool mirror_multicast_ctrl; // Mirror enable multicast if true.
    bit<9> mirror_egress_port; // Mirror packet egress port.
    bit<7> mirror_qid; // Mirror packet qid.
    bit<8> mirror_coalesce_length; // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    bit<32> adv_flow_ctl; // Advanced flow control for TM
    bit<14> mtu_trunc_len; // MTU for truncation check
    bit<1> mtu_trunc_err_f; // MTU truncation error flag
}

@__intrinsic_metadata
struct egress_intrinsic_metadata_for_output_port_t {
    bool capture_tstamp_on_tx; // Request for packet departure
                                        // timestamping at egress MAC for IEEE
                                        // 1588. consumed by h/w (egress MAC).

    bool update_delay_on_tx; // Request for PTP delay (elapsed time)
                                        // update at egress MAC for IEEE 1588
                                        // Transparent Clock. consumed by h/w
                                        // (egress MAC). when this is enabled,
                                        // the egress pipeline must prepend a
                                        // custom header composed of <ingress
                                        // tstamp (40), byte offset for the
                                        // elapsed time field (8), byte offset
                                        // for UDP checksum (8)> in front of the
                                        // Ethernet header.
    bool force_tx_error; // force a hardware transmission error
}

// -----------------------------------------------------------------------------
// PACKET GENERATION
// -----------------------------------------------------------------------------
// Packet generator supports up to 16 applications and a total of 16KB packet
// payload. Each application is associated with one of the four trigger types:
// - One-time timer
// - Periodic timer
// - Port down
// - Packet recirculation
// - MAU packet trigger
// For recirculated packets, the event fires when the first 32 bits of the
// recirculated packet matches the application match value and mask.
// A triggered event may generate programmable number of batches with
// programmable number of packets per batch.

header pktgen_timer_header_t {
    bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    bit<15> _pad2;
    bit<9> port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    bit<8> _pad2;
    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_deparser_header_t {
    bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    bit<8> _pad2;
    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_pfc_header_t {
    bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    bit<40> _pad2;
};

// -----------------------------------------------------------------------------
// TIME SYNCHRONIZATION
// -----------------------------------------------------------------------------

header ptp_metadata_t {
    bit<8> cf_byte_offset; // Byte offset at which the egress MAC
                                        // needs to re-insert
                                        // ptp_sync.correction field

    bit<8> udp_cksum_byte_offset; // Byte offset at which the egress MAC
                                        // needs to update the UDP checksum

    bit<48> updated_cf; // Updated correction field in ptp sync
                                        // message
}

// -----------------------------------------------------------------------------
// CHECKSUM
// -----------------------------------------------------------------------------
// Tofino checksum engine can verify the checksums for header-only checksums
// and calculate the residual (checksum minus the header field
// contribution) for checksums that include the payload.
// Checksum engine only supports 16-bit ones' complement checksums.

extern Checksum<W> {
    /// Constructor.
    /// @type_param W : Width of the calculated checksum. Only bit<16> is
    /// supported.
    /// @param algorithm : Only HashAlgorithm_t.CSUM16 is supported.
    Checksum(HashAlgorithm_t algorithm);

    /// Add data to checksum.
    /// @param data : List of fields to be added to checksum calculation. The
    /// data must be byte aligned.
    void add<T>(in T data);

    /// Subtract data from existing checksum.
    /// @param data : List of fields to be subtracted from the checksum. The
    /// data must be byte aligned.
    void subtract<T>(in T data);

    /// Verify whether the complemented sum is zero, i.e. the checksum is valid.
    /// @return : Boolean flag indicating wether the checksum is valid or not.
    bool verify();

    /// Get the calculated checksum value.
    /// @return : The calculated checksum value for added fields.
    W get();

    /// Calculate the checksum for a  given list of fields.
    /// @param data : List of fields contributing to the checksum value.
    W update<T>(in T data);
}

// ----------------------------------------------------------------------------
// PARSER COUNTER/PRIORITY
// ----------------------------------------------------------------------------
// Tofino parser counter can be used to extract header stacks or headers with
// variable length. Tofino has a single 8-bit signed counter that can be
// initialized with an immediate value or a header field.
extern ParserCounter<W> {
    // Constructor
    ParserCounter();

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

/// Random number generator.
extern Random<W> {
    /// Constructor
    Random();

    /// Return a random number with uniform distribution.
    /// @return : ranom number between 0 and 2**W - 1
    W get();
}

/// Idle timeout
extern IdleTimeout {
    IdleTimeout();
}


// -----------------------------------------------------------------------------
// EXTERN FUNCTIONS
// -----------------------------------------------------------------------------

extern T max<T>(in T t1, in T t2);

extern T min<T>(in T t1, in T t2);

extern void invalidate<T>(in T field);

/// Phase0
extern T port_metadata_unpack<T>(packet_in pkt);

/// Counter
extern Counter<W, I> {
    Counter(bit<32> size, CounterType_t type);
    void count(in I index);
}

/// DirectCounter
extern DirectCounter<W> {
    DirectCounter(CounterType_t type);
    void count();
}

/// Meter
extern Meter<I> {
    Meter(bit<32> size, MeterType_t type);
    Meter(bit<32> size, MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green);
    bit<8> execute(in I index, in MeterColor_t color);
    bit<8> execute(in I index);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type);
    DirectMeter(MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green);
    bit<8> execute(in MeterColor_t color);
    bit<8> execute();
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
extern Register<T, I> {
    /// Instantiate an array of <size> registers. The initial value is
    /// undefined.
    Register(bit<32> size);

    /// Initialize an array of <size> registers and set their value to
    /// initial_value.
    Register(bit<32> size, T initial_value);

    /// Return the value of register at specified index.
    T read(in I index);

    /// Write value to register at specified index.
    void write(in I index, in T value);
}

/// DirectRegister
extern DirectRegister<T> {
    /// Instantiate an array of direct registers. The initial value is
    /// undefined.
    DirectRegister();

    /// Initialize an array of direct registers and set their value to
    /// initial_value.
    DirectRegister(T initial_value);

    /// Return the value of the direct register.
    T read();

    /// Write value to a direct register.
    void write(in T value);
}

extern RegisterParam<T> {
    /// Construct a read-only run-time configurable parameter that can only be
    /// used by RegisterAction.
    /// @param initial_value : initial value of the parameter.
    RegisterParam(T initial_value);

    /// Return the value of the parameter.
    T read();
}

enum MathOp_t {
    MUL, // 2^scale * f(x)         --  false,  0
    SQR, // 2^scale * f(x^2)       --  false,  1
    SQRT, // 2^scale * f(sqrt(x))   --  false, -1
    DIV, // 2^scale * f(1/x)       --  true,   0
    RSQR, // 2^scale * f(1/x^2)     --  true,   1
    RSQRT // 2^scale * f(1/sqrt(x)) --  true,  -1
};

extern MathUnit<T> {
    /// Configure a math unit for use in a register action
    MathUnit(bool invert, int<2> shift, int<6> scale,
             tuple< bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8> > data);
    MathUnit(MathOp_t op, int<6> scale,
             tuple< bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8> > data);
    MathUnit(MathOp_t op, bit<64> factor); // configure as factor * op(x)
    T execute(in T x);
};

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);
    U execute(@optional out U rv2, @optional out U rv3, @optional out U rv4);
    @synchronous(execute)
    abstract void apply(inout T value, @optional out U rv, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern DirectRegisterAction2<T, U1, U2> {
    DirectRegisterAction2(DirectRegister<T> reg);
    U1 execute(out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern DirectRegisterAction3<T, U1, U2, U3> {
    DirectRegisterAction3(DirectRegister<T> reg);
    U1 execute(out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern DirectRegisterAction4<T, U1, U2, U3, U4> {
    DirectRegisterAction4(DirectRegister<T> reg);
    U1 execute(out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

extern RegisterAction<T, H, U> {
    RegisterAction(Register<T, H> reg);
    U execute(@optional in H index, @optional out U rv2,
              @optional out U rv3, @optional out U rv4);

    U execute_log(@optional out U rv2, @optional out U rv3, @optional out U rv4);
    U enqueue(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* fifo push */
    U dequeue(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* fifo pop */
    U push(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* stack push */
    U pop(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, @optional out U rv1, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value,
                                     @optional out U rv1, @optional out U rv2,
                                     @optional out U rv3, @optional out U rv4);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value,
                                      @optional out U rv1, @optional out U rv2,
                                      @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction2<T, H, U1, U2> {
    RegisterAction2(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2);

    U1 execute_log(out U2 rv2);
    U1 enqueue(out U2 rv2); /* fifo push */
    U1 dequeue(out U2 rv2); /* fifo pop */
    U1 push(out U2 rv2); /* stack push */
    U1 pop(out U2 rv2); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value, out U1 rv1, out U2 rv2);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value, out U1 rv1, out U2 rv);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction3<T, H, U1, U2, U3> {
    RegisterAction3(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3);

    U1 execute_log(out U2 rv2, out U3 rv3);
    U1 enqueue(out U2 rv2, out U3 rv3); /* fifo push */
    U1 dequeue(out U2 rv2, out U3 rv3); /* fifo pop */
    U1 push(out U2 rv2, out U3 rv3); /* stack push */
    U1 pop(out U2 rv2, out U3 rv3); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value, out U1 rv1, out U2 rv2, out U3 rv3);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction4<T, H, U1, U2, U3, U4> {
    RegisterAction4(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3, out U4 rv4);

    U1 execute_log(out U2 rv2, out U3 rv3, out U4 rv4);
    U1 enqueue(out U2 rv2, out U3 rv3, out U4 rv4); /* fifo push */
    U1 dequeue(out U2 rv2, out U3 rv3, out U4 rv4); /* fifo pop */
    U1 push(out U2 rv2, out U3 rv3, out U4 rv4); /* stack push */
    U1 pop(out U2 rv2, out U3 rv3, out U4 rv4); /* stack pop */
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop)
    abstract void apply(inout T value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    @synchronous(enqueue, push)
    @optional abstract void overflow(@optional inout T value,
                                     out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(dequeue, pop)
    @optional abstract void underflow(@optional inout T value,
                                      out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

extern LearnAction<T, H, D, U> {
    LearnAction(Register<T, H> reg);
    U execute(in H index, @optional out U rv2, @optional out U rv3, @optional out U rv4);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn,
                        @optional out U rv1, @optional out U rv2,
                        @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern LearnAction2<T, H, D, U1, U2> {
    LearnAction2(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern LearnAction3<T, H, D, U1, U2, U3> {
    LearnAction3(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn,
                        out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern LearnAction4<T, H, D, U1, U2, U3, U4> {
    LearnAction4(Register<T, H> reg);
    U1 execute(in H index, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout T value, in D digest, in bool learn,
                        out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply method to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

extern MinMaxAction<T, H, U> {
    MinMaxAction(Register<T, _> reg);
    U execute(@optional in H index, @optional out U rv2,
              @optional out U rv3, @optional out U rv4);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, @optional out U rv1, @optional out U rv2,
                                       @optional out U rv3, @optional out U rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address(@optional bit<1> subword); /* return the match address */
    U predicate(); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
}
extern MinMaxAction2<T, H, U1, U2> {
    MinMaxAction2(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
}
extern MinMaxAction3<T, H, U1, U2, U3> {
    MinMaxAction3(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
}
extern MinMaxAction4<T, H, U1, U2, U3, U4> {
    MinMaxAction4(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index);
}

extern ActionSelector {
    /// Construct an action selector of 'size' entries
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);

    /// Stateful action selector.
    ActionSelector(bit<32> size,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   Register<bit<1>, _> reg);
}

extern ActionProfile {
    /// Construct an action profile of 'size' entries.
    ActionProfile(bit<32> size);
}

extern Mirror {
    Mirror();

    void emit(in MirrorId_t session_id);

    /// Write @hdr into the ingress/egress mirror buffer.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in MirrorId_t session_id, in T hdr);
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

extern Digest<T> {
    /// define a digest stream to the control plane
    Digest();

    /// Emit data into the stream.  The p4 program can instantiate multiple
    /// Digest instances in the same deparser control block, and call the pack
    /// method once during a single execution of the control block
    void pack(in T data);
}

/// Tofino2 supports packet generation at the end of ingress pipeline. Packet
/// Generation can be triggered by MAU, some limited amount of metadata (128 bits)
/// can be prepended to the generated packet.
extern Pktgen {
    Pktgen();

    /// Define the prefix header for the generated packet.
    /// @param hdr : T can be a header type, a header stack, a header union,
    /// or a struct contains fields with such types.
    void emit<T>(in T hdr);
}
# 24 "/mnt/build/p4c/p4include/t2na.p4" 2

// The following declarations provide a template for the programmable blocks in
// JBay.

parser IngressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md);

parser EgressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md);

control IngressT<H, M>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional in ghost_intrinsic_metadata_t gh_intr_md);

control GhostT(in ghost_intrinsic_metadata_t gh_intr_md);

control EgressT<H, M>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);

control IngressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr);

control EgressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);

package Pipeline<IH, IM, EH, EM>(
    IngressParserT<IH, IM> ingress_parser,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParserT<EH, EM> egress_parser,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser,
    @optional GhostT ghost);

@pkginfo(arch="T2NA", version="0.5.0")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
# 34 "npb/npb.p4" 2




# 1 "npb/features.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/

// ***** ORIGINAL SWITCH DEFINES -- FOR REFERENCE  *****
// ***** (what barefoot initially had them set to) *****

/*
#define L4_PORT_LOU_ENABLE
// #define TCP_FLAGS_LOU_ENABLE
// #define BRIDGE_PORT_ENABLE
#define ERSPAN_ENABLE
// #define ERSPAN_TYPE2_ENABLE
#define IPV6_ENABLE
#define MIRROR_ENABLE
#define MIRROR_ACL_ENABLE
#define INGRESS_PORT_MIRROR_ENABLE
#define EGRESS_PORT_MIRROR_ENABLE
#define PTP_ENABLE
#define QOS_ENABLE
// #define QOS_ACL_ENABLE
#define INGRESS_POLICER_ENABLE
// #define STP_ENABLE
// #define MULTIPLE_STP
// #define WRED_ENABLE
#define COPP_ENABLE
#define MULTICAST_ENABLE
#define RACL_ENABLE
// #define PBR_ENABLE
#define STORM_CONTROL_ENABLE
// #define QINQ_ENABLE
#if __TARGET_TOFINO__ == 1
#define TUNNEL_ENABLE
// #define IPV6_TUNNEL_ENABLE
#define VXLAN_ENABLE
#endif
// #define MLAG_ENABLE
// #define MAC_PACKET_CLASSIFICATION
// #define PACKET_LENGTH_ADJUSTMENT
#define IPINIP
*/

// -----------------------------


// #define TCP_FLAGS_LOU_ENABLE
// #define BRIDGE_PORT_ENABLE

// #define ERSPAN_TYPE2_ENABLE






// #define QOS_ACL_ENABLE

// #define STP_ENABLE
// #define MULTIPLE_STP
// #define WRED_ENABLE



// #define PBR_ENABLE

// #define QINQ_ENABLE
//#if __TARGET_TOFINO__ == 1

// #define IPV6_TUNNEL_ENABLE
//#endif
// #define MLAG_ENABLE
// #define MAC_PACKET_CLASSIFICATION
// #define PACKET_LENGTH_ADJUSTMENT





// -----------------------------
// Extreme Networks Additions
// -----------------------------




//#define MPLS_ENABLE
//#define GTP_ENABLE

// define for selecting simple tables, rather than action_selectors/action_profiles tables



// per header stack counters for debug


// define so that you don't have to program up any tables to get a packet through (for debug only!)


// define for simultaneous switch and npb functionality (undefine for npb only)
# 39 "npb/npb.p4" 2
# 1 "npb/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header vlan_tag_h {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vid;
    bit<16> ether_type;
}

header mpls_h {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

// Router Alert IP option -- RFC 2113, RFC 2711
header router_alert_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header opaque_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}

header ipv6_h {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    ipv6_addr_t src_addr;
    ipv6_addr_t dst_addr;
}

header tcp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> seq_no;
    bit<32> ack_no;
    bit<4> data_offset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgent_ptr;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
}

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    // ...
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

// RDMA over Converged Ethernet (RoCEv2)
header rocev2_bth_h {
    bit<8> opcodee;
    bit<1> se;
    bit<1> migration_req;
    bit<2> pad_count;
    bit<4> transport_version;
    bit<16> partition_key;
    bit<1> f_res1;
    bit<1> b_res1;
    bit<6> reserved;
    bit<24> dst_qp;
    bit<1> ack_req;
    bit<7> reserved2;
    // ...
}

// Fiber Channel over Ethernet (FCoE)
header fcoe_fc_h {
    bit<4> version;
    bit<100> reserved;
    bit<8> sof; // Start of frame

    bit<8> r_ctl; // Routing control
    bit<24> d_id; // Destination identifier
    bit<8> cs_ctl; // Class specific control
    bit<24> s_id; // Source identifier
    bit<8> type;
    bit<24> f_ctl; // Frame control
    bit<8> seq_id;
    bit<8> df_ctl;
    bit<16> seq_cnt; // Sequence count
    bit<16> ox_id; // Originator exchange id
    bit<16> rx_id; // Responder exchange id
    // ...
    //XXX why parse all the fields if we only case about s_id and d_id;
}

// Segment Routing Extension (SRH) -- IETFv7
header ipv6_srh_h {
    bit<8> next_hdr;
    bit<8> hdr_ext_len;
    bit<8> routing_type;
    bit<8> seg_left;
    bit<8> last_entry;
    bit<8> flags;
    bit<16> tag;
}

// VXLAN -- RFC 7348
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Protocol Extension for VXLAN -- IETFv4
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

// Generic Routing Encapsulation (GRE) -- RFC 1701
header gre_h {
    bit<1> C;
    bit<1> R;
    bit<1> K;
    bit<1> S;
    bit<1> s;
    bit<3> recurse;
    bit<5> flags;
    bit<3> version;
    bit<16> proto;
}

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

// cmace - redefined ERSPAN in npb_headers.p4
//
//// ERSPAN Type II -- IETFv3
//header erspan_type2_h {
//    bit<4> version;
//    bit<12> vlan;
//    bit<6> cos_en_t;
//    bit<10> session_id;
//    bit<12> reserved;
//    bit<20> index;
//}
//
//// ERSPAN Type III -- IETFv3
//header erspan_type3_h {
//    bit<4> version;
//    bit<12> vlan;
//    bit<6> cos_bso_t;
//    bit<10> session_id;
//    bit<32> timestamp;
//    bit<16> sgt;    // Security group tag
//    bit<1>  p;
//    bit<5> ft;      // Frame type
//    bit<6> hw_id;
//    bit<1> d;       // Direction
//    bit<2> gra;     // Timestamp granularity
//    bit<1> o;       // Optional sub-header
//}
//
//// ERSPAN platform specific subheader -- IETFv3
//header erspan_platform_h {
//    bit<6> id;
//    bit<58> info;
//}

// Generic Network Virtualization Encapsulation (Geneve)
header geneve_h {
    bit<2> version;
    bit<6> opt_len;
    bit<1> oam;
    bit<1> critical;
    bit<6> reserved;
    bit<16> proto_type;
    bit<24> vni;
    bit<8> reserved2;
}

header geneve_option_h {
    bit<16> opt_class;
    bit<8> opt_type;
    bit<3> reserved;
    bit<5> opt_len;
}

// Bidirectional Forwarding Detection (BFD) -- RFC 5880
header bfd_h {
    bit<3> version;
    bit<5> diag;
    bit<8> flags;
    bit<8> detect_multi;
    bit<8> len;
    bit<32> my_discriminator;
    bit<32> your_discriminator;
    bit<32> desired_min_tx_interval;
    bit<32> req_min_rx_interval;
    bit<32> req_min_echo_rx_interval;
}

// BFN fabric header
header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
    bit<16> dst_port_or_group;
}

// BFN CPU header
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> ingress_ifindex;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

header timestamp_h {
    bit<48> timestamp;
}
# 40 "npb/npb.p4" 2
# 1 "npb/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/




// ----------------------------------------------------------------------------
// Extreme Added
// ----------------------------------------------------------------------------

// Tenant ID only needs to be 16 bits, but if I try to shrink it, I am getting
// a compiler error in 8.7: error: Ran out of constant output slots.


//#define TENANT_ID_WIDTH                                              16



# 1 "npb/npb_headers.p4" 1






//////////////////////////////////////////////////////////////
// Underlay Headers
//////////////////////////////////////////////////////////////

header ethernet_tagged_h { // for snooping
    mac_addr_t ether_dst_addr;
    mac_addr_t ether_src_addr;
    bit<16> ether_type;

    bit<3> tag_pcp;
    bit<1> tag_cfi;
    vlan_id_t tag_vid;
    bit<16> ether_type_tag;
}


//-----------------------------------------------------------
// ERSPAN
//-----------------------------------------------------------

// Barefoot ERSPAN Type2 header is missing the sequence
// number (which means it looks like ERSPAN Type1).
// Barefoot only uses this in the egress deparser.
// Let's redefine Type1 and Type2 here correctly and use
// these for parsing.

// ERSPAN Type1 -- IETFv3
header erspan_type1_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// ERSPAN Type2 -- IETFv3
header erspan_type2_h {
    bit<32> seq_num;
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// Barefoot ERSPAN Type3 header is incomplete. Let's
// redefine it here (and use this one instead).

// ERSPAN Type3 -- IETFv3
header erspan_type3_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_bso_t;
    bit<10> session_id;
    bit<32> timestamp;
    bit<16> sgt; // Security group tag
    bit<1> p;
    bit<5> ft; // Frame type
    bit<6> hw_id;
    bit<1> d; // Direction
    bit<2> gra; // Timestamp granularity
    bit<1> o; // Optional sub-header
}

// ERSPAN platform specific subheader -- IETFv3
header erspan_platform_h {
    bit<6> id;
    bit<58> info;
}


//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header
header nsh_base_h {
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;
}

// NSH Service Path Header
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}

// NSH MD Type1 (Fixed Length) Context Header
header nsh_md1_context_h {
    bit<128> md;
}

/*
// NSH MD Type2 (Variable Length) Context Header(s)
header nsh_md2_context_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
    varbit<1024> md; // (2^7)*8
}
*/

// fixed sized version of this is needed for lookahead
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}

// Single, Fixed Sized Extreme NSH Header
header nsh_extr_h {
 // base: word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;

 // base: word 1
    bit<24> spi;
    bit<8> si;

 // ext: type 2 - word 0
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved3;
    bit<7> md_len;

 // ext: type 2 - word 1+
 bit<8> extr_srvc_func_bitmask; //  1 byte
 bit<24> extr_tenant_id; //  3 bytes
 bit<8> extr_flow_type; //  1 byte?

//  bit<160> md_extr; // 20Byte fixed Extreme MD
//  bit<120> md_extr; // 20Byte fixed Extreme MD
}

// Single, Fixed Sized Extreme NSH Header
struct nsh_extr_internal_lkp_t {
 // metadata
    bit<1> valid; // set by sfc or incoming packet
    bit<1> end_of_chain; // set by sff

 // base: word 0

 // base: word 1
    bit<24> spi;
    bit<8> si;

 // ext: type 2 - word 0

 // ext: type 2 - word 1+
 bit<8> extr_srvc_func_bitmask_local; //  1 byte
 bit<8> extr_srvc_func_bitmask_remote; //  1 byte
 bit<24> extr_tenant_id; //  3 bytes
 bit<8> extr_flow_type; //  1 byte?
}



//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////

header e_tag_h {
    bit<3> pcp;
    bit<1> dei;
    bit<12> ingress_cid_base;
    bit<2> rsvd_0;
    bit<2> grp;
    bit<12> cid_base;
    bit<16> rsvd_1;
    bit<16> ether_type;
}

header vn_tag_h {
    bit<1> dir;
    bit<1> ptr;
    bit<14> dvif_id;
    bit<1> loop;
    bit<3> rsvd;
    bit<12> svif_id;
    bit<16> ether_type;
}
# 212 "npb/npb_headers.p4"
//////////////////////////////////////////////////////////////
// Layer3 Headers
//////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////
// Layer4 Headers
//////////////////////////////////////////////////////////////

header sctp_h {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
    bit<32> checksum;
}



//////////////////////////////////////////////////////////////
// LayerX Headers
//////////////////////////////////////////////////////////////

// (end of) MPLS pseudo wire control word (RFC 4448)
header mpls_pw_cw_h {
    bit<4> zeros;
    bit<12> rsvd;
    bit<16> seqNum;
}


//////////////////////////////////////////////////////////////
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// IPsec - ESP
//-----------------------------------------------------------

header esp_h {
    bit<32> spi;
    bit<32> seq_num;
}


//-----------------------------------------------------------
// GTP
//-----------------------------------------------------------

header gtp_v1_base_h {
    bit<3> version;
    bit<1> PT;
    bit<1> reserved;
    bit<1> E;
    bit<1> S;
    bit<1> PN;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> TEID;
}

header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8> n_pdu_num;
    bit<8> next_ext_hdr_type;
}

/*
header gtp_v1_extension_h {
    bit<8> ext_len;
    varbit<8192> contents;
    bit<8> next_ext_hdr;
}
*/
# 41 "npb/types.p4" 2

// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 54 "npb/types.p4"
//#define ETHERTYPE_QINQ 0x9100


// NPB Stuff

//#define ETHERTYPE_VN   0x892F
# 73 "npb/types.p4"
// NPB Stuff
# 83 "npb/types.p4"
// NPB Stuff
# 97 "npb/types.p4"
// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef QueueId_t switch_qid_t;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_ingress_cos_t;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 7;

typedef bit<16> switch_ifindex_t;
const switch_ifindex_t SWITCH_IFINDEX_FLOOD = 16w0xffff;

typedef bit<10> switch_port_lag_index_t;
typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

typedef bit<16> switch_vrf_t;
typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_port_lag_label_t;
typedef bit<16> switch_bd_label_t;
typedef bit<16> switch_if_label_t;

typedef bit<10> switch_rmac_group_t;
typedef bit<16> switch_smac_index_t;

typedef bit<16> switch_mtu_t;

typedef bit<12> switch_stats_index_t;

typedef bit<16> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;


typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITHC_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID = 25;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO = 26;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST = 27;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK = 28;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_MISS = 29;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID = 30;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_IP_INVALID_CHECKSUM = 31;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_VERSION_INVALID = 40;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_TTL_ZERO = 41;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_MULTICAST = 42;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_SRC_LOOPBACK = 43;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_IHL_INVALID = 44;
const switch_drop_reason_t SWITCH_DROP_REASON_IP_INVALID_CHECKSUM = 45;
const switch_drop_reason_t SWITCH_DROP_REASON_PORT_VLAN_MAPPING_MISS = 55;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_LEARNING = 56;
const switch_drop_reason_t SWITCH_DROP_REASON_STP_STATE_BLOCKING = 57;
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_MTU_CHECK_FAIL = 70;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_METER = 72;
const switch_drop_reason_t SWITCH_DROP_REASON_WRED = 73;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_RACL_DENY = 81;
const switch_drop_reason_t SWITCH_DROP_REASON_URPF_CHECK_FAIL = 82;
const switch_drop_reason_t SWITCH_DROP_REASON_IPSG_MISS = 83;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_YELLOW = 85;
const switch_drop_reason_t SWITCH_DROP_REASON_CPU_COLOR_RED = 86;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_YELLOW = 87;
const switch_drop_reason_t SWITCH_DROP_REASON_STORM_CONTROL_COLOR_RED = 88;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
const switch_drop_reason_t SWITCH_DROP_REASON_L3_IPV6_DISABLE = 100;

typedef bit<1> switch_port_type_t;
const switch_port_type_t SWITCH_PORT_TYPE_NORMAL = 0;
const switch_port_type_t SWITCH_PORT_TYPE_CPU = 1;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

// Bypass flags ---------------------------------------------------------------
typedef bit<16> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 16w0x0001;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L3 = 16w0x0002;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ACL = 16w0x0004;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SYSTEM_ACL = 16w0x0008;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_QOS = 16w0x0010;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_POLICER = 16w0x0020;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STORM_CONTROL = 16w0x0040;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_STP = 16w0x0080;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SMAC = 16w0x0100;

// Add more bypass flags here.

const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 16w0xffff;




// PKT ------------------------------------------------------------------------
typedef bit<16> switch_pkt_length_t;

//TODO(msharif) : try to reduce the bit width
typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGE = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_EGRESS = 2;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// LOU ------------------------------------------------------------------------

typedef bit<16> switch_l4_port_label_t;

// STP ------------------------------------------------------------------------
typedef bit<2> switch_stp_state_t;
const switch_stp_state_t SWITCH_STP_STATE_FORWARDING = 0;
const switch_stp_state_t SWITCH_STP_STATE_BLOCKING = 1;
const switch_stp_state_t SWITCH_STP_STATE_LEARNING = 2;

typedef bit<10> switch_stp_group_t;

struct switch_stp_metadata_t {
    switch_stp_group_t group;
    switch_stp_state_t state_;
}

// Metering -------------------------------------------------------------------

typedef bit<8> switch_copp_meter_id_t;


typedef bit<10> switch_policer_meter_index_t;


// QoS ------------------------------------------------------------------------
typedef bit<2> switch_qos_trust_mode_t;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_UNTRUSTED = 0;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_DSCP = 1;
const switch_qos_trust_mode_t SWITCH_QOS_TRUST_MODE_TRUST_PCP = 2;

typedef bit<5> switch_qos_group_t;


typedef bit<8> switch_tc_t;
typedef bit<3> switch_cos_t;

struct switch_qos_metadata_t {
    switch_qos_trust_mode_t trust_mode; // Ingress only.
    switch_qos_group_t group;
    switch_tc_t tc;
    switch_pkt_color_t color;
    switch_policer_meter_index_t meter_index; // Ingress only.
    switch_qid_t qid; // Egress only.
}

// Learning -------------------------------------------------------------------
typedef bit<1> switch_learning_mode_t;
const switch_learning_mode_t SWITCH_LEARNING_MODE_DISABLED = 0;
const switch_learning_mode_t SWITCH_LEARNING_MODE_LEARN = 1;

//@pa_alias("ingress", "ig_md.learning.digest.src_addr", "lkp_0.mac_src_addr")
//@pa_alias("ingress", "ig_md.learning.digest.ifindex", "ig_md.ifindex")
//@pa_alias("ingress", "ig_md.learning.digest.bd", "ig_md.bd")
struct switch_learning_digest_t {
    switch_bd_t bd;
    switch_ifindex_t ifindex;
    mac_addr_t src_addr;
}

struct switch_learning_metadata_t {
    switch_learning_mode_t bd_mode;
    switch_learning_mode_t port_mode;
    switch_learning_digest_t digest;
}

// Multicast ------------------------------------------------------------------
typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;
typedef bit<16> switch_multicast_rpf_group_t;
struct switch_multicast_metadata_t {
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// URPF -----------------------------------------------------------------------
typedef bit<2> switch_urpf_mode_t;
const switch_urpf_mode_t SWITCH_URPF_MODE_NONE = 0;
const switch_urpf_mode_t SWITCH_URPF_MODE_LOOSE = 1;
const switch_urpf_mode_t SWITCH_URPF_MODE_STRICT = 2;

// WRED/ECN -------------------------------------------------------------------

typedef bit<8> switch_wred_index_t;
typedef bit<12> switch_wred_stats_index_t;

typedef bit<2> switch_ecn_codepoint_t;
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_NON_ECT = 0b00; // Non ECN-capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT0 = 0b10; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_ECT1 = 0b01; // ECN capable transport
const switch_ecn_codepoint_t SWITCH_ECN_CODEPOINT_CE = 0b11; // Congestion encountered

// Mirroring ------------------------------------------------------------------
typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU = 250;


typedef bit<4> switch_mirror_type_t;







//XXX This is a temporary workaround to make sure mirror metadata do not share
// the PHV containers with any other fields or paddings -- P4C-1114




@pa_container_size("ingress", "hdr.mirror.port.session_id", 8)
@pa_container_size("egress", "hdr.mirror.port.session_id", 8)


// This is work around for P4C-723.
@pa_no_overlay("egress", "eg_md.mirror.src")
//@pa_no_overlay("egress", "eg_md.mirror.type")
@pa_no_overlay("egress", "eg_md.timestamp")
@pa_no_overlay("egress", "eg_md.mirror.session_id")

// Header formats for mirrored metadata fields.
header switch_port_mirror_metadata_h {
    switch_pkt_src_t src;
    bit<8> type;
    bit<48> timestamp;
    bit<16> session_id;
}

header switch_cpu_mirror_metadata_h {
    switch_pkt_src_t src;
    bit<8> type;
    bit<16> port;
    bit<16> bd;
    bit<16> ifindex;
    switch_cpu_reason_t reason_code;
}

// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    bit<8> type;
    switch_mirror_session_t session_id;
}

// Header format for mirrored metadata fields
struct switch_mirror_metadata_h {
    switch_port_mirror_metadata_h port;
    switch_cpu_mirror_metadata_h cpu;
}

// Tunneling ------------------------------------------------------------------
enum switch_tunnel_mode_t { PIPE, UNIFORM }
typedef bit<2> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;

const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MACINMAC_NSH = 3; // Derek Added!

//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTP_C = 2;
//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTP_U = 3;
//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 4;
//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 5;
//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_ESP = 6;

enum switch_tunnel_term_mode_t { P2P, P2MP };

typedef bit<16> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
    switch_ifindex_t ifindex;
    bit<16> hash;
    bool terminate;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
// Flags
struct switch_ingress_flags_t {
    bool ipv4_checksum_err;
    bool inner_ipv4_checksum_err;
    bool link_local;
    bool routed;
    bool acl_deny;
    bool racl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
    bool myip;
    bool glean;
    bool storm_control_drop;
    bool qos_policer_drop;
    bool flood_to_multicast_routers;
    bool peer_link;
    bool capture_ts;
    bool mac_pkt_class;

    // Add more flags here.
}

struct switch_egress_flags_t {
    bool routed;
    bool acl_deny;
    bool mlag_member;
    bool peer_link;
    bool capture_ts;
    bool wred_drop;

    // Add more flags here.
}


// Checks
struct switch_ingress_checks_t {
    switch_bd_t same_bd;
    switch_ifindex_t same_if;
    bool mrpf;
    bool urpf;
    // Add more checks here.
}

struct switch_egress_checks_t {
    switch_bd_t same_bd;
    switch_mtu_t mtu;
    bool stp;

    // Add more checks here.
}

// IP
struct switch_ip_metadata_t {
    bool unicast_enable;
    bool multicast_enable;
    bool multicast_snooping;
    // switch_urpf_mode_t urpf_mode;
}

@pa_atomic("ingress", "lkp_0.l4_src_port")
@pa_atomic("ingress", "lkp_0.l4_dst_port")
struct switch_lookup_fields_t {
    switch_pkt_type_t pkt_type;

    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
    bit<16> arp_opcode;

    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_tos;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;
    ipv6_addr_t ipv6_src_addr;
    ipv6_addr_t ipv6_dst_addr;

    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
}

//TODO(msharif): Remove the pragmas when serializable structs are supported by the compiler.
@pa_alias("ingress", "hdr.bridged_md.ingress_port", "ig_md.port")
@pa_alias("ingress", "hdr.bridged_md.ingress_ifindex", "ig_md.ifindex")
@pa_alias("ingress", "hdr.bridged_md.ingress_bd", "ig_md.bd")
//@pa_alias("ingress", "hdr.bridged_md.nexthop", "ig_md.nexthop")
@pa_alias("ingress", "hdr.bridged_md.routed", "ig_md.flags.routed")
@pa_alias("ingress", "hdr.bridged_md.peer_link", "ig_md.flags.peer_link")
@pa_alias("ingress", "hdr.bridged_md.tunnel_terminate", "ig_md.tunnel.terminate")
@pa_alias("ingress", "hdr.bridged_md.tc", "ig_md.qos.tc")
@pa_alias("ingress", "hdr.bridged_md.cpu_reason", "ig_md.cpu_reason")
@pa_alias("ingress", "hdr.bridged_md.timestamp", "ig_md.timestamp")
@pa_alias("ingress", "hdr.bridged_md.qid", "ig_intr_md_for_tm.qid")
//@pa_alias("ingress", "hdr.bridged_tunnel_md.outer_nexthop", "ig_md.outer_nexthop")
//@pa_alias("ingress", "hdr.bridged_tunnel_md.tunnel_index", "ig_md.tunnel.index")

// derek added (note: a few commented out becuase were causing phv to blow up.  ???)
/*
//@pa_alias("ingress", "hdr.bridged_md.nsh_extr_valid",                    "ig_md.nsh_extr.valid")
//@pa_alias("ingress", "hdr.bridged_md.nsh_extr_end_of_chain",             "ig_md.nsh_extr.end_of_chain")
@pa_alias("ingress", "hdr.bridged_md.nsh_extr_spi",                      "ig_md.nsh_extr.spi")
@pa_alias("ingress", "hdr.bridged_md.nsh_extr_si",                       "ig_md.nsh_extr.si")
@pa_alias("ingress", "hdr.bridged_md.nsh_extr_srvc_func_bitmask_local",  "ig_md.nsh_extr.extr_srvc_func_bitmask_local")
@pa_alias("ingress", "hdr.bridged_md.nsh_extr_srvc_func_bitmask_remote", "ig_md.nsh_extr.extr_srvc_func_bitmask_remote")
@pa_alias("ingress", "hdr.bridged_md.nsh_extr_tenant_id",                "ig_md.nsh_extr.extr_tenant_id")
@pa_alias("ingress", "hdr.bridged_md.nsh_extr_flow_type",                "ig_md.nsh_extr.extr_flow_type")
*/

// Header types used by ingress/egress deparsers.
header switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
// 1 byte
    switch_pkt_src_t src;
// 2 bytes
    bit<7> _pad0;
    switch_port_t ingress_port;
// 2 bytes
    switch_ifindex_t ingress_ifindex;
// 2 bytes
    switch_bd_t ingress_bd;
// 2 bytes
    switch_nexthop_t nexthop;
// 1 byte
    bit<6> _pad1;
    bit<1> routed;
    bit<1> tunnel_terminate;
// 1 byte
    bit<7> _pad2;
    bit<1> capture_ts;
// 1 byte
    bit<7> _pad3;
    bit<1> peer_link;
// 1 byte
    bit<6> _pad4;
    switch_pkt_type_t pkt_type;
// 1 bytes
    switch_tc_t tc;
// 2 bytes
    switch_cpu_reason_t cpu_reason;
// 6 bytes
    bit<48> timestamp;
// 1 byte

    bit<1> _pad5;



    switch_qid_t qid;

// 2 bytes
    switch_l4_port_label_t l4_port_label;

// 4 bytes
    bit<16> l4_src_port;
    bit<16> l4_dst_port;
    // Add more fields here.


// 29 bytes?

    // -----------------------------
    // ----- Extreme Networks -----
    // -----------------------------

// 11 bytes?

 // metadata
    bit<5> unused; // for byte-alignment
 bit<1> orig_pkt_had_nsh; // for egr parser
 bit<1> nsh_extr_valid; // set by sfc
 bit<1> nsh_extr_end_of_chain; // set by sff

    // base: word 0

    // base: word 1
    bit<24> nsh_extr_spi;
    bit<8> nsh_extr_si;

    // ext: type 2 - word 0

    // ext: type 2 - word 1+
    bit<8> nsh_extr_srvc_func_bitmask_local; //  1 byte
    bit<8> nsh_extr_srvc_func_bitmask_remote; //  1 byte
    bit<24> nsh_extr_tenant_id; //  3 bytes
    bit<8> nsh_extr_flow_type; //  1 byte?
}

header switch_bridged_metadata_tunnel_extension_t {
// 2 bytes
    switch_nexthop_t outer_nexthop;
// 2 bytes
    switch_tunnel_index_t index;
// 2 bytes
    bit<16> hash;

// 6 bytes
}

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
    switch_port_lag_label_t port_lag_label;
    switch_ifindex_t ifindex;
    // switch_if_label_t if_label;
}


// Ingress metadata
struct switch_ingress_metadata_t {

    switch_ifindex_t ifindex; /* ingress interface index */
    switch_port_t port; /* ingress port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_ifindex_t egress_ifindex; /* egress interface index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */
    switch_bd_t bd;
    switch_bd_t bd_nsh;
    switch_vrf_t vrf;
    switch_vrf_t vrf_nsh;
    switch_nexthop_t nexthop;
    switch_nexthop_t outer_nexthop;
    bit<48> timestamp;

    switch_ingress_flags_t flags;
    switch_ingress_checks_t checks;
    switch_ingress_bypass_t bypass;

    switch_ip_metadata_t ipv4_md; //XXX change the name
    switch_ip_metadata_t ipv4_md_nsh; //XXX change the name
    switch_ip_metadata_t ipv6_md; //XXX change the name
    switch_ip_metadata_t ipv6_md_nsh; //XXX change the name
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_bd_label_t bd_label_nsh;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_port_label;

    switch_drop_reason_t drop_reason;
    switch_cpu_reason_t cpu_reason;

    switch_rmac_group_t rmac_group;
    switch_rmac_group_t rmac_group_nsh;
    switch_multicast_metadata_t multicast;
    switch_multicast_metadata_t multicast_nsh;
    switch_stp_metadata_t stp;
    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_tunnel_metadata_t tunnel_nsh;
    switch_learning_metadata_t learning;
    switch_learning_metadata_t learning_nsh;
    switch_mirror_metadata_t mirror;

    // -----------------------------
    // ----- Extreme Networks -----
    // -----------------------------

 bit<1> orig_pkt_had_nsh; // for egr parser
 nsh_extr_internal_lkp_t nsh_extr;
}

// Egress metadata
struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
    switch_pkt_type_t pkt_type;

    switch_port_lag_index_t port_lag_index; /* egress port/lag index */
    switch_port_type_t port_type; /* egress port type */
    switch_port_t ingress_port; /* ingress port */
    switch_ifindex_t ingress_ifindex; /* ingress interface index */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_nexthop_t outer_nexthop;
    bit<48> timestamp;

    switch_egress_flags_t flags;
    switch_egress_checks_t checks;

    // for egress ACL
    switch_port_lag_label_t port_lag_label;
    switch_bd_label_t bd_label;
    switch_if_label_t if_label;
    switch_l4_port_label_t l4_port_label;

    switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel;
    switch_mirror_metadata_t mirror;

    switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason;

    // -----------------------------
    // ----- Extreme Networks -----
    // -----------------------------

 bit<1> orig_pkt_had_nsh; // for egr parser
 nsh_extr_internal_lkp_t nsh_extr;
}

struct switch_header_t {
    switch_bridged_metadata_t bridged_md;
    switch_bridged_metadata_tunnel_extension_t bridged_tunnel_md;

    // ===========================
    // misc
    // ===========================

 switch_mirror_metadata_h mirror;
    fabric_h fabric;
    cpu_h cpu;
    timestamp_h timestamp;

    // ===========================
    // outer
    // ===========================

    ethernet_h ethernet;
    e_tag_h e_tag;
    vn_tag_h vn_tag;
    vlan_tag_h[3] vlan_tag;
    //ether_type_h ether_type;
    ipv4_h ipv4;
    //opaque_option_h opaque_option;
    ipv6_h ipv6;
    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    //rocev2_bth_h rocev2_bth;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;





    erspan_type3_h erspan_type3;
    erspan_platform_h erspan_platform;


    // * NPB stuff start *

    nsh_extr_h nsh_extr_underlay;

    // underlay - for encap
    ethernet_h ethernet_underlay;
    vlan_tag_h vlan_tag_underlay;






    sctp_h sctp;
    esp_h esp;






    // * NPB stuff end *

    // ===========================
    // inner
    // ===========================

    ethernet_h inner_ethernet;
    ipv4_h inner_ipv4;
    ipv6_h inner_ipv6;
    udp_h inner_udp;
    tcp_h inner_tcp;
    icmp_h inner_icmp;

    // * NPB stuff start *
    vlan_tag_h inner_vlan_tag;
    arp_h inner_arp;
    sctp_h inner_sctp;
    gre_h inner_gre;
    esp_h inner_esp;
    igmp_h inner_igmp;
    // * NPB stuff end *
}
# 41 "npb/npb.p4" 2
# 1 "npb/table_sizes.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/




const bit<32> PORT_TABLE_SIZE = 288 * 2;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;
const bit<32> BD_FLOOD_TABLE_SIZE = VLAN_TABLE_SIZE * 4;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;
const bit<32> BD_STATS_TABLE_SIZE = BD_TABLE_SIZE * 3;
const bit<32> EGRESS_BD_MAPPING_TABLE_SIZE = BD_TABLE_SIZE * 3;
const bit<32> EGRESS_OUTER_BD_MAPPING_TABLE_SIZE = BD_TABLE_SIZE * 3;
const bit<32> EGRESS_BD_STATS_TABLE_SIZE = BD_TABLE_SIZE * 3;

// 16K MACs
const bit<32> MAC_TABLE_SIZE = 16384;

// IP Hosts/Routes
const bit<32> IPV4_LPM_TABLE_SIZE = 16384;
const bit<32> IPV6_LPM_TABLE_SIZE = 8192;
const bit<32> IPV4_HOST_TABLE_SIZE = 32768;
const bit<32> IPV6_HOST_TABLE_SIZE = 16384;

// Multicast
const bit<32> IPV4_MULTICAST_STAR_G_TABLE_SIZE = 2048;
const bit<32> IPV4_MULTICAST_S_G_TABLE_SIZE = 4096;
const bit<32> IPV6_MULTICAST_STAR_G_TABLE_SIZE = 512;
const bit<32> IPV6_MULTICAST_S_G_TABLE_SIZE = 512;
const bit<32> RID_TABLE_SIZE = 4096;

// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> DEST_TUNNEL_TABLE_SIZE = 512;
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 4096;
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 1024;
const bit<32> VNI_MAPPING_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 512;
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 4096;
const bit<32> TUNNEL_REWRITE_TABLE_SIZE = 512;

// ECMP/Nexthop
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024;
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096;
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384;
const bit<32> NEXTHOP_TABLE_SIZE = 32768;
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096;

// Ingress ACLs
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MIRROR_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_MAC_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_QOS_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_QOS_ACL_TABLE_SIZE = 512;

const bit<32> INGRESS_L4_PORT_LOU_TABLE_SIZE = 16 / 2;
const bit<32> ACL_STATS_TABLE_SIZE = 2048;

const bit<32> INGRESS_IPV4_RACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_RACL_TABLE_SIZE = 512;
const bit<32> RACL_STATS_TABLE_SIZE = 2048;

// Egress ACL
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;

// WRED
const bit<32> WRED_SIZE = 1 << 8;

// COPP
const bit<32> COPP_METER_SIZE = 1 << 8;
const bit<32> COPP_DROP_TABLE_SIZE = 1 << (8 + 1);

// QoS
const bit<32> DSCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> PCP_TO_TC_TABLE_SIZE = 1024;
const bit<32> QUEUE_TABLE_SIZE = 1024;
const bit<32> EGRESS_QOS_MAP_TABLE_SIZE = 1024;

// Policer
const bit<32> INGRESS_POLICER_TABLE_SIZE = 1 << 10;

// Storm Control
const bit<32> STORM_CONTROL_TABLE_SIZE = 512;

const bit<32> INGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_SYSTEM_ACL_TABLE_SIZE = 512;
const bit<32> DROP_STATS_TABLE_SIZE = 1 << 8;

const bit<32> MIRROR_SESSIONS_TABLE_SIZE = 1024;

const bit<32> L3_MTU_TABLE_SIZE = 1024;

// -----------------------------
// Extreme Networks Additions
// -----------------------------




// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_NSH_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART1_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SCHD_TABLE_PART2_DEPTH = 1024;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_TABLE_DEPTH = 1024;

// sf #1 -- basic / advanced
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V4_EXACT_MATCH_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V4_LPM_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V6_EXACT_MATCH_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_BAS_ADV_POLICY_V6_LPM_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART1_DEPTH = 1024;
const bit<32> NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART2_DEPTH = 1024;

// sf #2 -- replication

// sf #3 -- tool proxy
const bit<32> NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH = 1024;
# 42 "npb/npb.p4" 2

# 1 "npb/l3.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

# 1 "npb/acl.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/




//-----------------------------------------------------------------------------
// Common ACL actions.
//-----------------------------------------------------------------------------
action acl_deny(inout switch_ingress_metadata_t ig_md,
                inout switch_stats_index_t index,
                switch_stats_index_t stats_index,
                switch_cpu_reason_t reason_code) {
    index = stats_index;
    ig_md.flags.acl_deny = true;
    ig_md.cpu_reason = reason_code;
}

action acl_permit(inout switch_ingress_metadata_t ig_md,
                  inout switch_stats_index_t index,
                  switch_stats_index_t stats_index,
                  switch_cpu_reason_t reason_code) {
    index = stats_index;
    ig_md.flags.acl_deny = false;
    ig_md.cpu_reason = reason_code;
}

action acl_redirect(inout switch_ingress_metadata_t ig_md,
                    inout switch_stats_index_t index,
                    switch_nexthop_t nexthop,
                    switch_stats_index_t stats_index,
                    switch_cpu_reason_t reason_code) {






}
# 87 "npb/acl.p4"
//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------
control IngressIpv4Acl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ipv4_src_addr : ternary; lkp.ipv4_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_deny(ig_md, index);
            acl_permit(ig_md, index);
            acl_redirect(ig_md, index);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


control IngressIpv6Acl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {
//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------
    table acl {
        key = {
            lkp.ipv6_src_addr : ternary; lkp.ipv6_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_deny(ig_md, index);
            acl_permit(ig_md, index);
            acl_redirect(ig_md, index);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


control IngressMacAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
        }

        actions = {
            NoAction;
            acl_deny(ig_md, index);
            acl_permit(ig_md, index);
            acl_redirect(ig_md, index);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Comparison/Logical operation unit (LOU)
// LOU can perform logical operationis such AND and OR on tcp flags as well as comparison
// operations such as LT, GT, EQ, and NE for src/dst UDP/TCP ports.
//
// @param src_port : UDP/TCP source port.
// @param dst_port : UDP/TCP destination port.
// @param flags : TCP flags.
// @param port_label : A bit-map for L4 src/dst port ranges. Each bit is corresponding to a single
// range for src or dst port.
// @param table_size : Total number of supported ranges for src/dst ports.
// ----------------------------------------------------------------------------
control LOU(in bit<16> src_port,
            in bit<16> dst_port,
            inout bit<8> tcp_flags,
            out switch_l4_port_label_t port_label) {

    const switch_uint32_t table_size = 16 / 2;

    //TODO(msharif): Change this to bitwise OR so we can allocate bits to src/dst ports at runtime.
    action set_src_port_label(bit<8> label) {
        port_label[7:0] = label;
    }

    action set_dst_port_label(bit<8> label) {
        port_label[15:8] = label;
    }

    @entries_with_ranges(table_size)
    //TODO(msharif): Remove this when compiler checks table dependencies based on slices rather
    //than fields.
    @ignore_table_dependency("SwitchIngress.acl.lou.l4_src_port")
    table l4_dst_port {
        key = {
            dst_port : range;
        }

        actions = {
            NoAction;
            set_dst_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }


    @entries_with_ranges(table_size)
    table l4_src_port {
        key = {
            src_port : range;
        }

        actions = {
            NoAction;
            set_src_port_label;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action set_tcp_flags(bit<8> flags) {
        tcp_flags = flags;
    }

    table tcp {
        key = { tcp_flags : exact; }
        actions = {
            NoAction;
            set_tcp_flags;
        }

        size = 256;
    }

    apply {
# 268 "npb/acl.p4"
    }
}

// ----------------------------------------------------------------------------
// Ingress Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
//
// @flag MAC_PACKET_CLASSIFICATION : Controls whether MAC ACL applies to all
// traffic entering the interface, including IP traffic, or to non-IP traffic
// only.
// ----------------------------------------------------------------------------
control IngressAcl(
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        switch_uint32_t mac_table_size=512,
        bool mac_packet_class_enable=false) {

    IngressIpv4Acl(ipv4_table_size) ipv4_acl;
    IngressIpv6Acl(ipv6_table_size) ipv6_acl;
    IngressMacAcl(mac_table_size) mac_acl;
    LOU() lou;

    Counter<bit<16>, switch_stats_index_t>(
        ACL_STATS_TABLE_SIZE, CounterType_t.PACKETS_AND_BYTES) stats;

    switch_stats_index_t stats_index;

    apply {
        lou.apply(lkp.l4_src_port, lkp.l4_dst_port, lkp.tcp_flags, ig_md.l4_port_label);

        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_NONE || (mac_packet_class_enable && ig_md.flags.mac_pkt_class)) {

                mac_acl.apply(lkp, ig_md, stats_index);
            }
        }

        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_ACL != 0) && (!mac_packet_class_enable || !ig_md.flags.mac_pkt_class)) {
            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_acl.apply(lkp, ig_md, stats_index);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
                ipv6_acl.apply(lkp, ig_md, stats_index);
            }
        }

        stats.count(stats_index);
    }
}
//-----------------------------------------------------------------------------
// Common RACL actions.
//-----------------------------------------------------------------------------
action racl_deny(inout switch_ingress_metadata_t ig_md,
                 inout switch_stats_index_t index,
                 switch_stats_index_t stats_index) {
    index = stats_index;
    ig_md.flags.racl_deny = true;
}

action racl_permit(inout switch_ingress_metadata_t ig_md,
                   inout switch_stats_index_t index,
                   switch_stats_index_t stats_index,
                   switch_cpu_reason_t reason_code) {
    index = stats_index;
    ig_md.flags.racl_deny = false;
}

action racl_redirect(inout switch_stats_index_t index,
                     inout switch_nexthop_t nexthop,
                     switch_stats_index_t stats_index,
                     switch_nexthop_t nexthop_index) {
        index = stats_index;
        nexthop = nexthop_index;
}

//-----------------------------------------------------------------------------
// IPv4 RACL
//-----------------------------------------------------------------------------
control Ipv4Racl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ipv4_src_addr : ternary; lkp.ipv4_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            racl_deny(ig_md, index);
            racl_permit(ig_md, index);
            racl_redirect(index, nexthop);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


//-----------------------------------------------------------------------------
// IPv6 RACL
//-----------------------------------------------------------------------------
control Ipv6Racl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_stats_index_t index,
        out switch_nexthop_t nexthop)(
        switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ipv6_src_addr : ternary; lkp.ipv6_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            racl_deny(ig_md, index);
            racl_permit(ig_md, index);
            racl_redirect(index, nexthop);
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Router Access Control List (Router-ACL)
// @param lkp : Lookup fields used for ACL.
// @param ig_md : Ingress metadata fields.
//
// @flags PBR_ENABLE : Enable policy-based routing. PBR dictates a policy that
// determines where the packets are forwarded. Policies can be based IP address,
// port numbers and etc.
// ----------------------------------------------------------------------------
control RouterAcl(in switch_lookup_fields_t lkp,
                  inout switch_ingress_metadata_t ig_md)(
                  switch_uint32_t ipv4_table_size=512,
                  switch_uint32_t ipv6_table_size=512,
                  bool stats_enable=false,
                  switch_uint32_t stats_table_size=1024) {

    switch_stats_index_t stats_index;
    switch_nexthop_t nexthop;

    Counter<bit<16>, switch_stats_index_t>(stats_table_size, CounterType_t.PACKETS_AND_BYTES) stats;

    Ipv4Racl(ipv4_table_size) ipv4_racl;
    Ipv6Racl(ipv6_table_size) ipv6_racl;

    apply {
# 459 "npb/acl.p4"
    }
}

control Ipv4MirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        inout switch_mirror_type_t mirror_type,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    action acl_mirror(switch_mirror_session_t session_id) {
        mirror_type = 1;
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONE_INGRESS;
        ig_md.mirror.session_id = session_id;
    }

    table acl {
        key = {
            lkp.ipv4_src_addr : ternary; lkp.ipv4_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_mirror;
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv6MirrorAcl(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        inout switch_mirror_type_t mirror_type,
        out switch_stats_index_t index)(
        switch_uint32_t table_size=512) {

    action acl_mirror(switch_mirror_session_t session_id) {
        mirror_type = 1;
        ig_md.mirror.type = 1;
        ig_md.mirror.src = SWITCH_PKT_SRC_CLONE_INGRESS;
        ig_md.mirror.session_id = session_id;
    }

    table acl {
        key = {
            lkp.ipv6_src_addr : ternary; lkp.ipv6_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            acl_mirror;
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

// ----------------------------------------------------------------------------
// Mirror Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
//
// ----------------------------------------------------------------------------
control MirrorAcl(
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t ipv4_table_size=512,
        switch_uint32_t ipv6_table_size=512,
        bool stats_enable=false,
        switch_uint32_t stats_table_size=1024) {

    Ipv4MirrorAcl(ipv4_table_size) ipv4;
    Ipv6MirrorAcl(ipv6_table_size) ipv6;

    Counter<bit<16>, switch_stats_index_t>(stats_table_size, CounterType_t.PACKETS_AND_BYTES) stats;

    switch_stats_index_t stats_index;

    apply {
# 568 "npb/acl.p4"
    }
}


//-----------------------------------------------------------------------------
// System ACL
//
// @flag COPP_ENABLE
// @flag
//-----------------------------------------------------------------------------
control IngressSystemAcl(
        inout switch_ingress_metadata_t ig_md,
        in switch_lookup_fields_t lkp,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    Counter<bit<32>, switch_drop_reason_t>(
        1 << 8, CounterType_t.PACKETS) drop_stats;

    Meter<bit<8>>(1 << 8, MeterType_t.BYTES) copp_meter;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

    switch_copp_meter_id_t copp_meter_id;

    action drop(switch_drop_reason_t drop_reason) {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_md.drop_reason = drop_reason;
    }

    action copy_to_cpu(switch_cpu_reason_t reason_code,
                       switch_qid_t qid,
                       switch_copp_meter_id_t meter_id) {
        ig_intr_md_for_tm.qid = qid;
        // ig_intr_md_for_tm.ingress_cos = cos;
        ig_intr_md_for_tm.copy_to_cpu = true;




        ig_md.cpu_reason = reason_code;
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code,
                           switch_qid_t qid,
                           switch_copp_meter_id_t meter_id) {
        ig_intr_md_for_dprsr.drop_ctl = 0b1;
        copy_to_cpu(reason_code, qid, meter_id);
    }

    action mirror_on_drop(switch_drop_reason_t drop_reason) {
        drop(drop_reason);
        // TODO(msharif)
    }

    table system_acl {
        key = {
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.ifindex : ternary;

            // Lookup fields
            lkp.pkt_type : ternary;
            lkp.mac_type : ternary;
            lkp.mac_dst_addr : ternary;
            lkp.ip_ttl : ternary;
            lkp.ip_proto : ternary;
            lkp.ipv4_src_addr : ternary;
            // lkp.ipv6_src_addr : ternary;
            lkp.l4_src_port : ternary;
            lkp.l4_dst_port : ternary;
            lkp.arp_opcode : ternary;

            // Flags
            ig_md.flags.port_vlan_miss : ternary;
            ig_md.flags.acl_deny : ternary;
            ig_md.flags.racl_deny : ternary;
            ig_md.flags.rmac_hit : ternary;
            ig_md.flags.myip : ternary;
            ig_md.flags.glean : ternary;
            ig_md.flags.routed : ternary;
            ig_md.flags.storm_control_drop : ternary;
            ig_md.flags.qos_policer_drop : ternary;
            ig_md.flags.link_local : ternary;

            ig_md.checks.same_bd : ternary;
            ig_md.checks.same_if : ternary;
            ig_md.checks.mrpf : ternary;

            ig_md.stp.state_ : ternary;

            ig_md.ipv4_md.unicast_enable : ternary;
            ig_md.ipv4_md.multicast_enable : ternary;
            ig_md.ipv4_md.multicast_snooping : ternary;
            ig_md.ipv6_md.unicast_enable : ternary;
            ig_md.ipv6_md.multicast_enable : ternary;
            ig_md.ipv6_md.multicast_snooping : ternary;

            ig_md.cpu_reason : ternary;
            ig_md.drop_reason : ternary;
        }

        actions = {
            NoAction;
            drop;
            copy_to_cpu;
            redirect_to_cpu;
            mirror_on_drop;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action copp_drop() {
        ig_intr_md_for_tm.copy_to_cpu = false;
        copp_stats.count();
    }

    action copp_permit() {
        copp_stats.count();
    }

    table copp {
        key = {
            ig_intr_md_for_tm.packet_color : ternary;
            copp_meter_id : ternary;
        }

        actions = {
            copp_permit;
            copp_drop;
        }

        const default_action = copp_permit;
        size = (1 << 8 + 1);
        counters = copp_stats;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SYSTEM_ACL != 0)) {
            switch (system_acl.apply().action_run) {




                drop : { drop_stats.count(ig_md.drop_reason); }
            }
        }
    }
}

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------
control EgressMacAcl(in switch_header_t hdr,
                     inout switch_egress_metadata_t eg_md,
                     out switch_stats_index_t index)(
                     switch_uint32_t table_size=512) {
    action acl_deny(switch_stats_index_t stats_index, switch_cpu_reason_t reason_code) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
        eg_md.cpu_reason = reason_code;
    }

    action acl_permit(switch_stats_index_t stats_index, switch_cpu_reason_t reason_code) {
        index = stats_index;
        eg_md.cpu_reason = reason_code;
    }

    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.ethernet.ether_type : ternary;
        }

        actions = {
            NoAction;
            acl_deny;
            acl_permit;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------
control EgressIpv4Acl(in switch_header_t hdr,
                      in switch_lookup_fields_t lkp,
                      inout switch_egress_metadata_t eg_md,
                      out switch_stats_index_t index)(
                      switch_uint32_t table_size=512) {
    action acl_deny(switch_stats_index_t stats_index, switch_cpu_reason_t reason_code) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
        eg_md.cpu_reason = reason_code;
    }

    action acl_permit(switch_stats_index_t stats_index, switch_cpu_reason_t reason_code) {
        index = stats_index;
        eg_md.cpu_reason = reason_code;
    }

    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            eg_md.l4_port_label : ternary;
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.ipv4.protocol : ternary;
            hdr.ipv4.diffserv : ternary;
            lkp.l4_src_port : ternary;
            lkp.l4_dst_port : ternary;
        }

        actions = {
            NoAction;
            acl_deny;
            acl_permit;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------
control EgressIpv6Acl(in switch_header_t hdr,
                      in switch_lookup_fields_t lkp,
                      inout switch_egress_metadata_t eg_md,
                      out switch_stats_index_t index)(
                      switch_uint32_t table_size=512) {
    action acl_deny(switch_stats_index_t stats_index, switch_cpu_reason_t reason_code) {
        index = stats_index;
        eg_md.flags.acl_deny = true;
        eg_md.cpu_reason = reason_code;
    }

    action acl_permit(switch_stats_index_t stats_index, switch_cpu_reason_t reason_code) {
        index = stats_index;
        eg_md.cpu_reason = reason_code;
    }

    table acl {
        key = {
            eg_md.port_lag_label : ternary;
            eg_md.bd_label : ternary;
            eg_md.l4_port_label : ternary;
            hdr.ipv6.src_addr : ternary;
            hdr.ipv6.dst_addr : ternary;
            hdr.ipv6.next_hdr : ternary;
            hdr.ipv6.traffic_class : ternary;
            lkp.l4_src_port : ternary;
            lkp.l4_dst_port : ternary;
        }

        actions = {
            NoAction;
            acl_deny;
            acl_permit;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}


control EgressAcl(in switch_header_t hdr,
                  in switch_lookup_fields_t lkp,
                  inout switch_egress_metadata_t eg_md)(
                  switch_uint32_t mac_table_size=512,
                  switch_uint32_t ipv4_table_size=512,
                  switch_uint32_t ipv6_table_size=512,
                  bool stats_enable=false,
                  switch_uint32_t stats_table_size=2048) {
    EgressIpv4Acl(ipv4_table_size) ipv4_acl;
    EgressIpv6Acl(ipv6_table_size) ipv6_acl;
    EgressMacAcl(mac_table_size) mac_acl;

    Counter<bit<16>, switch_stats_index_t>(
        stats_table_size, CounterType_t.PACKETS_AND_BYTES) stats;

    switch_stats_index_t stats_index;

    apply {
# 887 "npb/acl.p4"
    }
}

control EgressSystemAcl(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)(
        switch_uint32_t table_size=512) {

    action drop(switch_drop_reason_t reason_code) {
        eg_md.drop_reason = reason_code;
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action copy_to_cpu(switch_cpu_reason_t reason_code) {
        eg_md.cpu_reason = reason_code;
        eg_intr_md_for_dprsr.mirror_type = 2;
        eg_md.mirror.type = 2;
        eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONE_EGRESS;
        hdr.mirror.cpu.port = (bit<16>)eg_intr_md.egress_port;
    }

    action redirect_to_cpu(switch_cpu_reason_t reason_code) {
        copy_to_cpu(reason_code);
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action insert_timestamp() {
        hdr.timestamp.setValid();
        hdr.timestamp.timestamp = eg_md.timestamp;
    }

    table system_acl {
        key = {
            eg_intr_md.egress_port : ternary;

            eg_md.flags.acl_deny : ternary;





            eg_md.checks.mtu : ternary;
            eg_md.checks.stp : ternary;




            //TODO add more
        }

        actions = {
            NoAction;
            drop;
            copy_to_cpu;
            redirect_to_cpu;
            insert_timestamp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        system_acl.apply();
    }
}
# 27 "npb/l3.p4" 2
# 1 "npb/l2.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/




//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param ig_md : Ingress metadata fields.
// @param stp_md : Spanning tree metadata.
// @param multiple_stp_enable : Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
// @param table_size : Size of the mstp table. Only used if multiple stp is enabled.
//
// @flag MULTIPLE_STP: Allows to map a group of VLAN’s into a single spanning
// tree instance, for which spanning tree is applied independently.
//-----------------------------------------------------------------------------
control IngressSTP(in switch_ingress_metadata_t ig_md,
                   inout switch_stp_metadata_t stp_md)(
                   bool multiple_stp_enable=false,
                   switch_uint32_t table_size=4096) {
    // This register is used to check the stp state of the ingress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the indes.
    const bit<32> stp_state_size = 1 << 19;
    Register<bit<1>, bit<32>>(stp_state_size, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    action set_stp_state(switch_stp_state_t stp_state) {
        stp_md.state_ = stp_state;
    }

    table mstp {
        key = {
            ig_md.port : exact;
            stp_md.group: exact;
        }

        actions = {
            NoAction;
            set_stp_state;
        }

        size = table_size;
        const default_action = NoAction;
    }

    apply {
# 89 "npb/l2.p4"
    }
}

//-----------------------------------------------------------------------------
// Spanning Tree Protocol
// @param port : Egress port.
// @param bd : Egress BD.
// @param stp_state : Spanning tree state.
//-----------------------------------------------------------------------------
control EgressSTP(in switch_port_t port, in switch_bd_t bd, inout bool stp_state) {
    // This register is used to check the stp state of the egress port.
    // (bd << 7 | port) is used as the index to read the stp state. To save
    // resources, only 7-bit local port id is used to construct the index.
    Register<bit<1>, bit<32>>(1 << 19, 0) stp;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;
    RegisterAction<bit<1>, bit<32>, bit<1>>(stp) stp_check = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
        }
    };

    apply {







    }
}


//-----------------------------------------------------------------------------
// Source MAC lookup
//
// @param src_addr : Source MAC address.
// @param ig_md : Ingress metadata
// @param table_size : Size of SMAC table.
//
// MAC learning
// - Trigger a new MAC learn if MAC address is unknown.
// - Trigger a new MAC learn if MAC address is known but attached to a different interface.
// - Trigger a new MAC learn if Spannig tree state is LEARNING (if enabled).
//-----------------------------------------------------------------------------
control SMAC(in mac_addr_t src_addr,
             inout switch_ingress_metadata_t ig_md,
             inout switch_digest_type_t digest_type)(
             switch_uint32_t table_size) {
    // local variables for MAC learning
    bool src_miss;
    switch_ifindex_t src_move;

    action smac_miss() {
        src_miss = true;
    }

    action smac_hit(switch_ifindex_t ifindex) {
        src_move = ig_md.ifindex ^ ifindex;
    }

    table smac {
        key = {
            ig_md.bd : exact;
            src_addr : exact;
        }

        actions = {
            @defaultonly smac_miss;
            smac_hit;
        }

        const default_action = smac_miss;
        size = table_size;
        idle_timeout = true;
    }

    action notify() {
        digest_type = SWITCH_DIGEST_TYPE_MAC_LEARNING;
        ig_md.learning.digest.bd = ig_md.bd;
        ig_md.learning.digest.src_addr = src_addr;
        ig_md.learning.digest.ifindex = ig_md.ifindex;
    }

    table learning {
        key = {
            src_miss : exact;
            src_move : ternary;
            ig_md.stp.state_ : ternary;
        }

        actions = {
            NoAction;
            notify;
        }

        const default_action = NoAction;
    }


    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SMAC != 0)) {
         smac.apply();
        }

        if (ig_md.learning.bd_mode == SWITCH_LEARNING_MODE_LEARN &&
                ig_md.learning.port_mode == SWITCH_LEARNING_MODE_LEARN) {
            learning.apply();
        }
    }
}

//-----------------------------------------------------------------------------
// Destination MAC lookup
//
// Performs a lookup on bd and destination MAC address.
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//
// @param dst_addr : destination MAC address.
// @param ig_md : Ingess metadata
// @param ig_intr_md_for_tm
// @param table_size : Size of the dmac table.
//-----------------------------------------------------------------------------
control DMAC_t(
        in mac_addr_t dst_addr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

control DMAC(
        in mac_addr_t dst_addr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size) {

    action dmac_miss() {
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
    }

    action dmac_hit(switch_ifindex_t ifindex,
                    switch_port_lag_index_t port_lag_index) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
    }

    action dmac_multicast(switch_mgid_t index) {
        ig_intr_md_for_tm.mcast_grp_b = index;
    }

    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
    }

    action dmac_drop() {
        //TODO(msharif): Drop the packet.
    }

    table dmac {
        key = {
            ig_md.bd : exact;
            dst_addr : exact;
        }

        actions = {
            dmac_miss;
            dmac_hit;
            dmac_multicast;
            dmac_redirect;
            dmac_drop;
        }

        const default_action = dmac_miss;
        size = table_size;
    }

    apply {
        if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
            dmac.apply();
        }
    }
}

control IngressBd(in switch_bd_t bd, in switch_pkt_type_t pkt_type)(switch_uint32_t table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() { stats.count(); }

    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        const default_action = NoAction;
        size = table_size;
        counters = stats;
    }

    apply {
        bd_stats.apply();
    }
}

control EgressBd(in switch_header_t hdr,
                 in switch_bd_t bd,
                 in switch_pkt_type_t pkt_type,
                 out switch_bd_label_t label,
                 out switch_smac_index_t smac_idx,
                 out switch_mtu_t mtu_idx)(
                 switch_uint32_t table_size,
                 switch_uint32_t stats_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() {
        stats.count();
    }

    table bd_stats {
        key = {
            bd : exact;
            pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = stats_table_size;
        counters = stats;
    }

    action set_bd_properties(switch_bd_label_t bd_label,
                             switch_smac_index_t smac_index,
                             switch_mtu_t mtu_index) {
        label = bd_label;
        smac_idx = smac_index;
        mtu_idx = mtu_index;
    }

    table bd_mapping {
        key = { bd : exact; }
        actions = {
            NoAction;
            set_bd_properties;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        bd_mapping.apply();
        bd_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanDecap(inout switch_header_t hdr, in switch_port_t port) {
    action remove_vlan_tag() {
        hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
        hdr.vlan_tag.pop_front(1);
    }

    table vlan_decap {
        key = {
            port : ternary;
            hdr.vlan_tag[0].isValid() : exact;
        }

        actions = {
            NoAction;
            remove_vlan_tag;
        }

        const default_action = NoAction;
    }

    apply {



        // Remove the vlan tag by default.
        if (hdr.vlan_tag[0].isValid()) {
            hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
            hdr.vlan_tag[0].setInvalid();
        }

    }
}

//-----------------------------------------------------------------------------
// Vlan translation
//
// @param hdr : Parsed headers.
// @param port_lag_index : Port/lag index.
// @param bd : Bridge domain
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanXlate(inout switch_header_t hdr,
                  in switch_port_lag_index_t port_lag_index,
                  in switch_bd_t bd)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
        //NoAction.
    }

    action set_vlan_tagged(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;

        // hdr.vlan_tag[0].pcp =  0;
        // hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }

    table port_bd_to_vlan_mapping {
        key = {
            port_lag_index : exact;
            bd : exact;
        }

        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
    }

    table bd_to_vlan_mapping {
        key = { bd : exact; }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = bd_table_size;
    }

    action set_type_vlan() {
         hdr.ethernet.ether_type = 0x8100;
     }

    action set_type_qinq() {
        hdr.ethernet.ether_type = 0x88a8;
    }

    action set_type_vlan_nsh() {
        hdr.ethernet_underlay.ether_type = 0x8100;
    }

    table set_ether_type {
        key = {
            hdr.vlan_tag[0].isValid() : exact;
            hdr.vlan_tag[1].isValid() : exact;

            hdr.vlan_tag_underlay.isValid() : exact;
        }

        actions = {
            NoAction;
            set_type_vlan;
            set_type_qinq;

            set_type_vlan_nsh;
        }

        const default_action = NoAction;
        const entries = {
//          (true, false) : set_type_vlan();
//          (true, true) : set_type_qinq();

            (true, false, false) : set_type_vlan();
            (true, true, false) : set_type_qinq();

            (_, _, true ) : set_type_vlan_nsh();
        }
    }

    apply {
        if (!port_bd_to_vlan_mapping.apply().hit) {
            bd_to_vlan_mapping.apply();
        }




    }
}
# 28 "npb/l3.p4" 2

//-----------------------------------------------------------------------------
// FIB lookup
//
// @param dst_addr : Destination IPv4 address.
// @param vrf
// @param flags
// @param nexthop : Nexthop index.
// @param host_table_size : Size of the host table.
// @param lpm_table_size : Size of the IPv4 route table.
//-----------------------------------------------------------------------------
control Fib<T>(in ipv4_addr_t dst_addr,
               in switch_vrf_t vrf,
               out switch_ingress_flags_t flags,
               out switch_nexthop_t nexthop)(
               switch_uint32_t host_table_size,
               switch_uint32_t lpm_table_size) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }

    action fib_miss() {
        flags.routed = false;
    }

    action fib_myip() {
        flags.myip = true;
    }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    @alpm(1)
    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)
    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}

control Fibv6<T>(in ipv6_addr_t dst_addr,
                 in switch_vrf_t vrf,
                 out switch_ingress_flags_t flags,
                 out switch_nexthop_t nexthop)(
                 switch_uint32_t host_table_size,
                 switch_uint32_t lpm_table_size) {
    action fib_hit(switch_nexthop_t nexthop_index) {
        nexthop = nexthop_index;
        flags.routed = true;
    }

    action fib_miss() {
        flags.routed = false;
    }

    action fib_myip() {
        flags.myip = true;
    }

    table fib {
        key = {
            vrf : exact;
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
            fib_myip;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    @alpm(1)
    @alpm_partitions(1024)
    @alpm_subtrees_per_partition(2)
    table fib_lpm {
        key = {
            vrf : exact;
            dst_addr : lpm;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = lpm_table_size;
    }

    apply {
        if (!fib.apply().hit) {
            fib_lpm.apply();
        }
    }
}

control MTU(in switch_header_t hdr, inout switch_mtu_t mtu_check)(switch_uint32_t table_size=1024) {

    action ipv4_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu - hdr.ipv4.total_len;
    }

    action ipv6_mtu_check(switch_mtu_t mtu) {
        mtu_check = mtu - hdr.ipv6.payload_len;
    }

    action mtu_miss() {
        mtu_check = 16w0xffff;
    }

    table mtu {
        key = {
            mtu_check : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            ipv4_mtu_check;
            ipv6_mtu_check;
            mtu_miss;
        }

        const default_action = mtu_miss;
        size = table_size;
    }

    apply {
        mtu.apply();
    }
}

//-----------------------------------------------------------------------------
// @param lkp : Lookup fields used to perform L2/L3 lookups.
// @param ig_md : Ingress metadata fields.
// @param ig_intr_md_for_tm : Intrinsic metadata fields consumed by traffic manager.
// @param dmac : DMAC instance (See l2.p4)
//-----------------------------------------------------------------------------
control IngressUnicast(in switch_lookup_fields_t lkp,
                       inout switch_ingress_metadata_t ig_md,
                       inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
                       DMAC_t dmac,
                       switch_uint32_t ipv4_host_table_size,
                       switch_uint32_t ipv4_route_table_size,
                       switch_uint32_t ipv6_host_table_size=1024,
                       switch_uint32_t ipv6_route_table_size=512) {

    Fib<ipv4_addr_t>(ipv4_host_table_size, ipv4_route_table_size) ipv4_fib;
    Fibv6<ipv6_addr_t>(ipv6_host_table_size, ipv6_route_table_size) ipv6_fib;

    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }

    action rmac_miss() {
        ig_md.flags.rmac_hit = false;
    }

//-----------------------------------------------------------------------------
// Router MAC lookup
// key: destination MAC address.
// - Route the packet if the destination MAC address is owned by the switch.
//-----------------------------------------------------------------------------
    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
        }

        actions = {
            rmac_hit;
            @defaultonly rmac_miss;
        }

        const default_action = rmac_miss;
        size = 1024;
    }

    apply {
        if (rmac.apply().hit) {
            //TODO(msharif) : SWI-821 Drop non-ip packets with router MAC.
            if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L3 != 0)) {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4_md.unicast_enable) {

                    ipv4_fib.apply(lkp.ipv4_dst_addr,
                                   ig_md.vrf,
                                   ig_md.flags,
                                   ig_md.nexthop);
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6_md.unicast_enable) {







                }
            }
        } else {
            dmac.apply(lkp.mac_dst_addr, ig_md, ig_intr_md_for_tm);
        }
    }
}
# 44 "npb/npb.p4" 2
# 1 "npb/nexthop.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

// ----------------------------------------------------------------------------
// Nexthop/ECMP resolution
//
// @param lkp : Lookup fields used for hash calculation.
// @param ig_md : Ingress metadata fields
// @param ig_intr_md_for_tm
// @param hash : Hash value used for ECMP selection.
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_lookup_fields_t lkp,
                inout switch_ingress_metadata_t ig_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
                in bit<16> hash)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_table_size,
                switch_uint32_t ecmp_selection_table_size) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(
        ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;

    action set_nexthop_properties(switch_ifindex_t ifindex,
                                  switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd) {
        ig_md.egress_ifindex = ifindex;
        ig_md.egress_port_lag_index = port_lag_index;
        ig_md.checks.same_if = ig_md.ifindex ^ ifindex;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }

    action set_nexthop_properties_post_routed_flood(switch_bd_t bd,
                                                    switch_mgid_t mgid) {
        ig_md.egress_ifindex = 0;
        ig_md.egress_port_lag_index = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
        ig_intr_md_for_tm.mcast_grp_b = mgid;
    }

    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
        ig_md.checks.same_bd = 0x3fff;
    }

    action set_nexthop_properties_drop() {
        ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }

    action set_ecmp_properties(switch_ifindex_t ifindex,
                               switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(ifindex, port_lag_index, bd);
    }

    action set_ecmp_properties_post_routed_flood(
            switch_bd_t bd,
            switch_mgid_t mgid,
            switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_post_routed_flood(bd, mgid);
    }

    action set_ecmp_properties_glean(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties_glean();
    }

    action set_tunnel_properties(switch_bd_t bd, switch_tunnel_index_t tunnel_index) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        ig_md.tunnel.index = tunnel_index;
        ig_md.egress_ifindex = 0;
        ig_md.checks.same_bd = ig_md.bd ^ bd;
    }

    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }

    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
            set_nexthop_properties_drop;
            set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = nexthop_table_size;
    }

    apply {
        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
        }
    }
}

control OuterNexthop(inout switch_ingress_metadata_t ig_md,
                     in bit<16> hash)(
                     switch_uint32_t nexthop_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;


    action set_nexthop_properties(
            switch_port_lag_index_t port_lag_index, switch_nexthop_t nexthop_index) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_ifindex = 0;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table ecmp {
        key = {
            ig_md.tunnel.index : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
        implementation = ecmp_selector;
        size = ecmp_table_size;
    }

    table nexthop {
        key = {
            ig_md.tunnel.index : exact;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        size = nexthop_table_size;
        const default_action = NoAction;
    }

    apply {

        switch(nexthop.apply().action_run) {
            NoAction : { ecmp.apply(); }
        }

    }
}
# 45 "npb/npb.p4" 2
# 1 "npb/parde.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2018 Barefoot Networks, Inc.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be coverep by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

# 1 "npb/headers.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 24 "npb/parde.p4" 2

# 1 "npb/types.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/
# 26 "npb/parde.p4" 2

# 1 "npb/npb_ing_parser.p4" 1



# 1 "npb/npb_sub_parsers.p4" 1



//-----------------------------------------------------------------------------
// Underlay - Layer 2
//-----------------------------------------------------------------------------

parser ParserUnderlayL2(
    packet_in pkt,
    inout switch_header_t hdr,
    out bit<16> ether_type) {

    state start {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_br;
            0x8926 : parse_vn;
            0x8100 : parse_vlan;
            0x88a8 : parse_vlan;
            default : accept;
        }
    }

    state parse_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_vlan;
            0x88a8 : parse_vlan;
            default : accept;
        }
    }

    state parse_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_vlan;
            0x88a8 : parse_vlan;
            default : accept;
        }
    }

    state parse_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_vlan;
            0x88a8 : parse_vlan;
            default : accept;
        }
    }
}


// //-----------------------------------------------------------------------------
// // Underlay - Network Service Headers (NSH)
// //-----------------------------------------------------------------------------
// // For now, we'll just assume a fixed 20Bytes of opaque Extreme metadata and
// // parse the whole thing as one big (fixed sized) header. We're also assuming
// // the next header will always be ethernet.
// 
// parser ParserUnderlayNsh(
//     packet_in pkt,
//     inout switch_header_t hdr) {
// 
//     state start {
// 	    pkt.extract(hdr.nsh_extr);
//         // verify base header md-type = 2
//         // verify base header length matches expected
//         // verify base header next_proto = ethernet
//         // verify md2 context header type = "extreme"
//         // verify md2 context header md_len matches expected
//         transition accept;
//     }
// }


// //-----------------------------------------------------------------------------
// // Layer3 - IPv4
// //-----------------------------------------------------------------------------
// 
// parser ParserIPv4(
//     packet_in pkt,
//     inout switch_ingress_metadata_t ig_md,
//     inout switch_header_t hdr) {
// 
//     Checksum<bit<16>>(HashAlgorithm_t.CRC16) ipv4_checksum;
// 
//     state start {
//         pkt.extract(hdr.ipv4);
//          // todo: Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum.add(hdr.ipv4);
//         transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
//             (5, 0, 0) : parse_ipv4_no_options_frags;
//             (5, 2, 0) : parse_ipv4_no_options_frags;
//             default : accept;
//         }
//     }
// 
//     state parse_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
//         // bit slicing like this not supported in v8.6.0
//         //ig_md.parser_scratch[15:8] = 0x4;
//         //ig_md.parser_scratch[7:0] = hdr.ipv4.protocol;
//         //ig_md.parser_scratch_b = 0x0004;
//         //ig_md.parser_scratch_proto = hdr.ipv4.protocol;
//         ig_md.parser_protocol = 0xFF;
//         transition accept;
//     }
// 
// 
// //     state start {
// //          // todo: Flag packet (to be sent to host) if it's a frag or has options.
// //         ig_md.parser_scratch = 0xFFFF; // can we flag it like this?
// //         //ig_md.parser_scratch = -1; // can we flag it like this?
// //         ipv4_h snoop = pkt.lookahead<ipv4_h>();
// //         transition select(snoop.ihl, snoop.flags, snoop.frag_offset) {
// //             (5, 0, 0) : parse_ipv4_no_options_frags;
// //             (5, 2, 0) : parse_ipv4_no_options_frags;
// //             default : accept;
// //         }
// //     }
// // 
// //     state parse_ipv4_no_options_frags {
// //         pkt.extract(hdr.ipv4);
// //         ipv4_checksum.add(hdr.ipv4);
// //         ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
// //         // bit slicing like this not supported in v8.6.0
// //         //ig_md.parser_scratch[15:8] = 0x4;
// //         //ig_md.parser_scratch[7:0] = hdr.ipv4.protocol;
// //         //ig_md.parser_scratch_b = 4;
// //         //ig_md.parser_scratch_b = hdr.ipv4.version;
// //         ig_md.parser_scratch = (bit<16>)hdr.ipv4.protocol;
// //         transition accept;
// //     }
// 
// 
// }
// 
// 
// 
// //-----------------------------------------------------------------------------
// // Layer3 - IPv6
// //-----------------------------------------------------------------------------
// 
// parser ParserIPv6(
//     packet_in pkt,
//     inout switch_ingress_metadata_t ig_md,
//     inout switch_header_t hdr) {
// 
//     state start {
//         pkt.extract(hdr.ipv6);
//         // bit slicing like this not supported in v8.6.0
//         //ig_md.parser_scratch[15:8] = 0x6;
//         //ig_md.parser_scratch[7:0] = hdr.ipv6.next_hdr;
//         //ig_md.parser_scratch_b = 0x0006;
//         //ig_md.parser_scratch = (bit<16>)hdr.ipv6.next_hdr;
//         transition accept;
//     }
// }




// //-------------------------------------------------------------------------
// // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
// //-------------------------------------------------------------------------
// // Based on pseudo code from Glenn (see email from 02/11/2019):
// // Does not support parsing GTP optional word
// // Does not support parsing (TLV) extension headers
// 
// parser ParserGtp(
//     packet_in pkt,
//     //inout switch_ingress_metadata_t ig_md,
//     inout bit<2> md_tunnel_type,
//     inout switch_header_t hdr) {
// 
//     state start {
// 
//         // todo: Flag frame (to be trapped) if version > 2
// #ifdef GTP_ENABLE
//         transition select(pkt.lookahead<bit<4>>()) { //version,PT
//             3: parse_gtp_u;
//             5: parse_gtp_c; // does PT matter w/ gtp-c?
//             //1,4: parse_gtp_prime;
//             default: accept;
//         }
// #else
//         transition reject;
// #endif  /* GTP_ENABLE */
//     }
// 
// #ifdef GTP_ENABLE
//     state parse_gtp_u {
//         pkt.extract(hdr.gtp_v1_base);
//     	transition select(
//             hdr.gtp_v1_base.E,
//             hdr.gtp_v1_base.S,
//             hdr.gtp_v1_base.PN) {
//             (0,0,0): parse_gtp_u_end;
//             default: accept;
//         }
//     }
// 
//     state parse_gtp_c {
//         pkt.extract(hdr.gtp_v1_base);
//         //ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_C;
//         md_tunnel_type = SWITCH_TUNNEL_TYPE_GTP_C;
//     	transition accept;
//     }
// 
//     state parse_gtp_u_end {
//         //ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GTP_U;
//         md_tunnel_type = SWITCH_TUNNEL_TYPE_GTP_U;
//     	transition accept;
//     }
// #endif  /* GTP_ENABLE */
// 
// }
# 5 "npb/npb_ing_parser.p4" 2

parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;

 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
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
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
        ig_md.port_lag_label = port_md.port_lag_label;
        ig_md.ifindex = port_md.ifindex;
        //transition parse_ethernet;
        transition snoop_underlay;
    }

    // todo: need to understand interaction w/ cpu better.
    // todo: can we assume no vlan-tags after cpu header?
    state parse_cpu {
        pkt.extract(hdr.fabric);
        pkt.extract(hdr.cpu);
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;
        transition select(hdr.cpu.ether_type) {
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            //ETHERTYPE_VLAN : parse_vlan;
            //ETHERTYPE_QINQ : parse_vlan;
            //ETHERTYPE_MPLS : parse_mpls;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2
    ///////////////////////////////////////////////////////////////////////////

    // Subparsers are broken in v8.7.0:
    // Any data set down in the subparser, except maybe header extractions,
    // will not be visible up here in the main parser.
    // 
    // // shared fanout/branch state to save tcam resource
    // state parse_ethernet {
    //     parser_underlay_l2_md_backup.apply(pkt, hdr, ig_md);
    //     transition select(ig_md.scratch_ether_type) {
    //         ETHERTYPE_NSH : parse_nsh_underlay;
    //         ETHERTYPE_ARP : parse_arp;
    //         ETHERTYPE_MPLS : parse_mpls;
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         ETHERTYPE_BFN : parse_cpu;
    //         default : accept;
    //     }
    // }

    // Snoop ahead here to determine type of underlay
    state snoop_underlay {
        ethernet_tagged_h snoop = pkt.lookahead<ethernet_tagged_h>();
        transition select(snoop.ether_type, snoop.ether_type_tag) {
            (0x894F, _): parse_underlay_nsh;
            (0x8100, 0x894F): parse_underlay_nsh_tagged;
            default: parse_underlay_l2_ethernet;
        }
    }

    state parse_underlay_nsh {
        // todo: is this enet used  - can we advance past it? not emit?
        // pkt.extract(hdr.ethernet_underlay);
        pkt.extract<ethernet_h>(_); // drop it
     pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }

    state parse_underlay_nsh_tagged {
        // todo: is this enet used  - can we advance past it? not emit?
        // pkt.extract(hdr.ethernet_underlay);
        // pkt.extract(hdr.vlan_tag_underlay);
        pkt.extract<ethernet_h>(_); // drop it
        pkt.extract<vlan_tag_h>(_); // drop it
     pkt.extract(hdr.nsh_extr_underlay);
        ig_md.orig_pkt_had_nsh = 1;
        transition parse_underlay_l2_ethernet;
    }


    ///////////////////////////////////////////////////////////////////////////
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_underlay_l2_br;
            0x8926 : parse_underlay_l2_vn;
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    // shared fanout/branch state to save tcam resource
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x0806 : parse_arp;
            0x86dd : parse_ipv6;
            0x9000 : parse_cpu;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5
    ///////////////////////////////////////////////////////////////////////////

    state parse_arp {
        pkt.extract(hdr.arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err = ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            0x01: parse_icmp;
            0x02: parse_igmp;
            default: parse_l3_protocol;
        }
    }

    state parse_ipv6 {
# 216 "npb/npb_ing_parser.p4"
        transition reject;

    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
           0x04: parse_ipinip;
           0x29: parse_ipv6inip;
           0x11: parse_udp;
           0x06: parse_tcp;
           0x84: parse_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_esp;
           0x2f: parse_gre;
           default : accept;
       }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_igmp {
        pkt.extract(hdr.igmp);
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789: parse_vxlan;
            2123: parse_gtp; // todo: src port too?
            2152: parse_gtp; // todo: src port too?
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X
    ///////////////////////////////////////////////////////////////////////////////

    state parse_mpls {
# 287 "npb/npb_ing_parser.p4"
        transition accept;

    }
# 300 "npb/npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels
    ///////////////////////////////////////////////////////////////////////////


    state parse_ipinip {

        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;



    }

    state parse_ipv6inip {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)

        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;



    }

    state parse_vxlan {

        pkt.extract(hdr.vxlan);
        ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel.id = hdr.vxlan.vni;
        transition parse_inner_ethernet;



    }

    state parse_gre {
     pkt.extract(hdr.gre);
        // todo: verify(hdr.gre.version == 0, error.GreVersionNotZero);
        // todo: ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {

            (0,0,1,0,0,0,0,0x6558): parse_nvgre;
            (0,0,0,0,0,0,0,0x8847): parse_mpls;
            (0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;
// #ifdef ERSPAN_UNDERLAY_ENABLE
//             (0,0,0,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1_underlay;
//             (0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2_underlay;
//             //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3_underlay;
// #endif /* ERSPAN_UNDERLAY_ENABLE */
            default: accept;
        }
    }

    state parse_nvgre {
     pkt.extract(hdr.nvgre);
        // todo: ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE;
     transition parse_inner_ethernet;
    }

    state parse_esp {
        pkt.extract(hdr.esp);
        // todo: ig_md.tunnel.type = SWITCH_TUNNEL_TYPE_ESP;
        transition accept;
    }



    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 02/11/2019):
    // Does not support parsing GTP optional word
    // Does not support parsing (TLV) extension headers

    // todo: create subparser for this
    // use metadata ing_tunnel_type to determine if we need to continue parsing
    // when I tried subparser, the compiler complained w/ the following:
    //   Unimplemented compiler support: Local metadata array hdr_2_vlan_tag not supported

    // state parse_gtp {
    //     //parser_gtp.apply(pkt, ig_md, hdr);
    //     parser_gtp.apply(pkt, ig_md.tunnel.type, hdr);
    // 	transition select(ig_md.tunnel.type, pkt.lookahead<bit<4>>()) {
    //         (SWITCH_TUNNEL_TYPE_GTP_U, 4): parse_inner_ipv4;
    //         (SWITCH_TUNNEL_TYPE_GTP_U, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_gtp {
        // todo: Flag frame (to be trapped) if version > 2
# 408 "npb/npb_ing_parser.p4"
        transition reject;

    }
# 464 "npb/npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 2 (ETH-T)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        inner_ether_type = hdr.inner_ethernet.ether_type;
        transition select(hdr.inner_ethernet.ether_type) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ether_type;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        inner_ether_type = hdr.inner_vlan_tag.ether_type;
        transition parse_inner_ether_type;
    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_ether_type {
        transition select(inner_ether_type) {
            0x0806 : parse_inner_arp;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner - Layer 2.5
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_arp {
        pkt.extract(hdr.inner_arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////
    // todo: When barefoot fixes case#8406, we should be able to use a common
    //       subparser for L3 parsing across both outer and inner. This will
    //       result in additional (tcam) resource savings. That being said,
    //       a subparser here can be a little tricky: We may need to use
    //       additional metadata or check valid bits to distinguish between
    //       v4 and v6 when exiting the subparser (into the famout branch).
    //       Also, would we need to indicate that we're finished parsing in
    //       the case of icmp/igmp (if these are done in the subparser(s)).

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        inner_ipv4_checksum.add(hdr.inner_ipv4);
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_ipv4_no_options_frags;
            //(5, 2, 0): parse_inner_ipv4_no_options_frags;
            (5, 3w2 &&& 3w5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
        transition select(hdr.inner_ipv4.protocol) {
            0x01: parse_inner_icmp;
            0x02: parse_inner_igmp;
            default: parse_inner_l3_protocol;
        }
    }

    state parse_inner_ipv6 {
# 550 "npb/npb_ing_parser.p4"
        transition reject;

    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           0x11: parse_inner_udp;
           0x06: parse_inner_tcp;
           0x84: parse_inner_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_inner_esp;
           0x2f: parse_inner_gre;
           default : accept;
       }
    }

    state parse_inner_icmp {
        pkt.extract(hdr.inner_icmp);
        transition accept;
    }

    state parse_inner_igmp {
        pkt.extract(hdr.inner_igmp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Tunnels
    ///////////////////////////////////////////////////////////////////////////

    // todo: do we need to parse this? extract?
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }

    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }



}
# 28 "npb/parde.p4" 2
# 1 "npb/npb_egr_parser.p4" 1





parser NpbEgressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    ParserUnderlayL2() parser_underlay_l2;

 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;


    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
# 31 "npb/npb_egr_parser.p4"
        transition parse_bridged_metadata;

    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGE;
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.ingress_ifindex = hdr.bridged_md.ingress_ifindex;
        eg_md.bd = hdr.bridged_md.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.nexthop;
        eg_md.qos.tc = hdr.bridged_md.tc;
        eg_md.cpu_reason = hdr.bridged_md.cpu_reason;
        eg_md.flags.routed = (bool) hdr.bridged_md.routed;
        eg_md.flags.peer_link = (bool) hdr.bridged_md.peer_link;
        eg_md.flags.capture_ts = (bool) hdr.bridged_md.capture_ts;
        eg_md.tunnel.terminate = (bool) hdr.bridged_md.tunnel_terminate;
        eg_md.pkt_type = hdr.bridged_md.pkt_type;
        eg_md.timestamp = hdr.bridged_md.timestamp;
        eg_md.qos.qid = hdr.bridged_md.qid;






        pkt.extract(hdr.bridged_tunnel_md);
        eg_md.outer_nexthop = hdr.bridged_tunnel_md.outer_nexthop;
        eg_md.tunnel.index = hdr.bridged_tunnel_md.index;
        eg_md.tunnel.hash = hdr.bridged_tunnel_md.hash;

        // Set bridged metadata here.

        // -----------------------------
        // ----- EXTREME NETWORKS -----
        // -----------------------------
        eg_md.orig_pkt_had_nsh = hdr.bridged_md.orig_pkt_had_nsh;

        eg_md.nsh_extr.valid = hdr.bridged_md.nsh_extr_valid;
        eg_md.nsh_extr.end_of_chain = hdr.bridged_md.nsh_extr_end_of_chain;

        // base: word 0

        // base: word 1
        eg_md.nsh_extr.spi = hdr.bridged_md.nsh_extr_spi;
        eg_md.nsh_extr.si = hdr.bridged_md.nsh_extr_si;

        // ext: type 2 - word 0

        // ext: type 2 - word 1+
        eg_md.nsh_extr.extr_srvc_func_bitmask_local = hdr.bridged_md.nsh_extr_srvc_func_bitmask_local; //  1 byte
        eg_md.nsh_extr.extr_srvc_func_bitmask_remote = hdr.bridged_md.nsh_extr_srvc_func_bitmask_remote; //  1 byte
        eg_md.nsh_extr.extr_tenant_id = hdr.bridged_md.nsh_extr_tenant_id; //  3 bytes
        eg_md.nsh_extr.extr_flow_type = hdr.bridged_md.nsh_extr_flow_type; //  1 byte?

        // -----------------------------

        //transition accept;
        //transition snoop_underlay;
        //transition select(eg_md.nsh_extr.valid) {
        transition select(eg_md.orig_pkt_had_nsh) {
            0: parse_underlay_l2_ethernet;
            1: parse_underlay_nsh;
        }
    }

/*
    state parse_mirrored_packet {
        pkt.extract(eg_md.mirror);
        eg_md.pkt_src = eg_md.mirror.src;
        pkt.extract(hdr.ethernet);
        transition accept;
    }
*/

    state parse_port_mirrored_metadata {
        switch_port_mirror_metadata_h md;
        pkt.extract(md);
        pkt.extract(hdr.ethernet);
        eg_md.pkt_src = md.src;



        eg_md.mirror.session_id = md.session_id[7:0];

        // eg_md.mirror.session_id = (switch_mirror_session_t) md.session_id;
        eg_md.timestamp = md.timestamp;
        transition accept;
    }

    state parse_cpu_mirrored_metadata {
        switch_cpu_mirror_metadata_h md;
        pkt.extract(md);
        eg_md.bd = (switch_bd_t) md.bd;
        // eg_md.ingress_port = (switch_port_t) md.port;
        // eg_md.ingress_ifindex = (switch_ifindex_t) md.ifindex;
        eg_md.cpu_reason = (switch_cpu_reason_t) md.reason_code;
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // L2 Underlay (L2-U)
    ///////////////////////////////////////////////////////////////////////////

    state parse_underlay_nsh {
        pkt.extract(hdr.nsh_extr_underlay);
        transition parse_underlay_l2_ethernet;
    }


    // Subparsers are broken in v8.7.0:
    // Any data set down in the subparser, except maybe header extractions,
    // will not be visible up here in the main parser.
    // 
    // // shared fanout/branch state to save tcam resource
    // state parse_underlay_l2 {
    //     parser_underlay_l2.apply(pkt, hdr, ether_type);
    //     transition select(ether_type) {
    //         ETHERTYPE_MPLS : parse_mpls;
    //         ETHERTYPE_IPV4 : parse_ipv4;
    //         ETHERTYPE_IPV6 : parse_ipv6;
    //         default : accept;
    //     }
    // }

    ///////////////////////////////////////////////////////////////////////////
    state parse_underlay_l2_ethernet {
        pkt.extract(hdr.ethernet);
        ether_type = hdr.ethernet.ether_type;
        transition select(hdr.ethernet.ether_type) {
            0x893F : parse_underlay_l2_br;
            0x8926 : parse_underlay_l2_vn;
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_br {
     pkt.extract(hdr.e_tag);
        ether_type = hdr.e_tag.ether_type;
        transition select(hdr.e_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vn {
     pkt.extract(hdr.vn_tag);
        ether_type = hdr.vn_tag.ether_type;
        transition select(hdr.vn_tag.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    state parse_underlay_l2_vlan {
     pkt.extract(hdr.vlan_tag.next);
        ether_type = hdr.vlan_tag.last.ether_type;
        transition select(hdr.vlan_tag.last.ether_type) {
            0x8100 : parse_underlay_l2_vlan;
            0x88a8 : parse_underlay_l2_vlan;
            default : parse_underlay_l2_ether_type;
        }
    }

    // shared fanout/branch state to save tcam resource
    state parse_underlay_l2_ether_type {
        transition select(ether_type) {
            0x8847 : parse_mpls;
            0x0800 : parse_ipv4;
            0x86dd : parse_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        protocol = hdr.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(hdr.ipv4.ihl, hdr.ipv4.flags, hdr.ipv4.frag_offset) {
            //(5, 0, 0) : parse_l3_protocol;
            //(5, 2, 0) : parse_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_l3_protocol;
            default : accept;
        }
    }

    state parse_ipv6 {





        transition reject;

    }

    // shared fanout/branch state to save tcam resource
    state parse_l3_protocol {
        transition select(protocol) {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)
           0x04: parse_inner_ipv4;
           0x29: parse_inner_ipv6;
//#endif
           0x11: parse_udp;
           0x06: parse_tcp;
           0x84: parse_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_esp;
           0x2f: parse_gre;
           default : accept;
       }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            4789: parse_vxlan;
            2123: parse_gtp; // todo: src port too?
            2152: parse_gtp; // todo: src port too?
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_sctp {
        pkt.extract(hdr.sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X
    ///////////////////////////////////////////////////////////////////////////////

    state parse_mpls {
# 295 "npb/npb_egr_parser.p4"
        transition accept;

    }
# 309 "npb/npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels
    ///////////////////////////////////////////////////////////////////////////

    state parse_vxlan {

        pkt.extract(hdr.vxlan);
        transition parse_inner_ethernet;



    }

    state parse_gre {
     pkt.extract(hdr.gre);
        //todo: verify(hdr.gre.version == 0, error.GreVersionNotZero);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_GRE;
        transition select(
            hdr.gre.C,
            hdr.gre.R,
            hdr.gre.K,
            hdr.gre.S,
            hdr.gre.s,
            hdr.gre.recurse,
            hdr.gre.version,
            hdr.gre.proto) {

            (0,0,1,0,0,0,0,0x6558): parse_nvgre;
            (0,0,0,0,0,0,0,0x8847): parse_mpls;
            (0,0,0,0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0,0,0,0x86dd): parse_inner_ipv6;
            //(0,0,0,0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1;
            //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2;
            //(0,0,0,1,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3;
            default: accept;
        }
    }

    state parse_nvgre {
     pkt.extract(hdr.nvgre);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_NVGRE;
     transition parse_inner_ethernet;
    }

    state parse_esp {
        pkt.extract(hdr.esp);
        // todo: eg_md.tunnel.type = SWITCH_TUNNEL_TYPE_ESP;
        transition accept;
    }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP)
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 02/11/2019):
    // Does not support parsing GTP optional word
    // Does not support parsing (TLV) extension headers

    // todo: create subparser for this
    // use metadata ing_tunnel_type to determine if we need to continue parsing
    // when I tried subparser, the compiler complained w/ the following:
    //   Unimplemented compiler support: Local metadata array hdr_2_vlan_tag not supported

    // state parse_gtp {
    //     //parser_gtp.apply(pkt, eg_md, hdr);
    //     parser_gtp.apply(pkt, eg_md.tunnel.type, hdr);
    // 	transition select(eg_md.tunnel.type, pkt.lookahead<bit<4>>()) {
    //         (SWITCH_TUNNEL_TYPE_GTP_U, 4): parse_inner_ipv4;
    //         (SWITCH_TUNNEL_TYPE_GTP_U, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_gtp {
        // todo: Flag frame (to be trapped) if version > 2
# 392 "npb/npb_egr_parser.p4"
        transition reject;

    }
# 449 "npb/npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 2 (ETH-T)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner_ethernet);
        inner_ether_type = hdr.inner_ethernet.ether_type;
        transition select(hdr.inner_ethernet.ether_type) {
            0x8100 : parse_inner_vlan;
            default : parse_inner_ether_type;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner_vlan_tag);
        inner_ether_type = hdr.inner_vlan_tag.ether_type;
        transition parse_inner_ether_type;
    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_ether_type {
        transition select(inner_ether_type) {
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 3 (Network)
    ///////////////////////////////////////////////////////////////////////////
    // todo: When barefoot fixes case#8406, we should be able to use a common
    //       subparser for L3 parsing across both outer and inner. This will
    //       result in additional (tcam) resource savings. That being said,
    //       a subparser here can be a little tricky: We may need to use
    //       additional metadata or check valid bits to distinguish between
    //       v4 and v6 when exiting the subparser (into the famout branch).
    //       Also, would we need to indicate that we're finished parsing in
    //       the case of icmp/igmp (if these are done in the subparser(s)).

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        inner_protocol = hdr.inner_ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_l3_protocol;
            //(5, 2, 0): parse_inner_l3_protocol;
            (5, 3w2 &&& 3w5, 0): parse_inner_l3_protocol;

            default: accept;
        }
    }

    state parse_inner_ipv6 {





        transition reject;

    }

    // shared fanout/branch state to save tcam resource
    state parse_inner_l3_protocol {
        transition select(inner_protocol) {
           0x11: parse_inner_udp;
           0x06: parse_inner_tcp;
           0x84: parse_inner_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_inner_esp;
           0x2f: parse_inner_gre;
           default : accept;
       }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 (Transport)
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        transition accept;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner_sctp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Tunnels
    ///////////////////////////////////////////////////////////////////////////

    // todo: do we need to parse this? extract?
    state parse_inner_esp {
        pkt.extract(hdr.inner_esp);
        transition accept;
    }

    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner_gre);
        transition accept;
    }



// 
// ///////////////////////////////////////////////////////////////////////////////
// // Underlay Encaps
// ///////////////////////////////////////////////////////////////////////////////
// 
// //-----------------------------------------------------------------------------
// // Encapsulated Remote Switch Port Analyzer (ERSPAN)
// //-----------------------------------------------------------------------------
// 
// state parse_erspan_t1 {
//     pkt.extract(hdr.erspan_type1);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T1
//     transition parse_inner_ethernet;
// }
// 
// state parse_erspan_t2 {
//     pkt.extract(hdr.erspan_type2);
//     //verify(hdr.erspan_typeII.version == 1, error.Erspan2VersionNotOne);
//     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T2
//     transition parse_inner_ethernet;
// }
// 
// // state parse_erspan_t3 {
// //     pkt.extract(hdr.erspan_type3);
// //     //verify(hdr.erspan_typeIII.version == 2, error.Erspan3VersionNotTwo);
// //     //metadata.ingress_tunnel_type, INGRESS_TUNNEL_TYPE_ERSPAN_T3
// //     transition select(hdr.erspan_type3.o) {
// //         1: parse_erspan_type3_platform;
// //         default: parse_inner_ethernet;
// //     }
// // }
// // 
// // state parse_erspan_type3_platform {
// //     pkt.extract(hdr.erspan_platform);
// //     transition parse_inner_ethernet;
// // }
// 
// 


}
# 29 "npb/parde.p4" 2

//-----------------------------------------------------------------------------
// Pktgen parser
//-----------------------------------------------------------------------------
parser PktgenParser<H>(packet_in pkt,
                       inout switch_header_t hdr,
                       inout H md) {
    state start {



        transition reject;

    }

    state parse_pktgen {
        transition reject;
    }
}

//-----------------------------------------------------------------------------
// MPLS parser
//-----------------------------------------------------------------------------
// parser MplsParser(packet_in pkt, inout switch_header_t hdr) {
//     state start {
// #ifdef MPLS_ENABLE
//         transition parse_mpls;
// #else
//         transition reject;
// #endif
//     }
// 
//     state parse_mpls {
//         pkt.extract(hdr.mpls.next);
//         transition select(hdr.mpls.last.bos) {
//             1 : accept;
//             0 : parse_mpls;
//         }
//     }
// }

//-----------------------------------------------------------------------------
// Inband network telemetry parser
//-----------------------------------------------------------------------------
parser DTelParser(packet_in pkt, inout switch_header_t hdr) {
    state start {
        transition reject;
    }
}

//-----------------------------------------------------------------------------
// Segment routing extension header parser
//-----------------------------------------------------------------------------
//parser SrhParser(packet_in pkt, inout switch_header_t hdr) {
//    state start {
//#ifdef SRV6_ENABLE
//        transition parse_srh;
//#else
//        transition reject;
//#endif
//    }
//
//    state parse_srh {
//        //TODO(msharif) : implement SRH parser.
//        transition reject;
//    }
//}


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend
// the prepend the mirror header.
    Mirror() mirror;

    apply {
# 119 "npb/parde.p4"
    }
}

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the
// mirror header.
    Mirror() mirror;

    apply {
# 150 "npb/parde.p4"
    }
}


//=============================================================================
// Ingress Deparser
//=============================================================================
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    IngressMirror() ingress_mirror;
    Digest<switch_learning_digest_t>() digest;

    apply {
        ingress_mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        if (ig_intr_md_for_dprsr.digest_type == SWITCH_DIGEST_TYPE_MAC_LEARNING)
        {
            digest.pack({ig_md.learning.digest.bd,
                         ig_md.learning.digest.ifindex,
                         ig_md.learning.digest.src_addr});
        }

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.
        pkt.emit(hdr.bridged_tunnel_md); // Ingress only.

        // ***** UNDERLAY *****
        pkt.emit(hdr.nsh_extr_underlay);
// #ifdef ERSPAN_UNDERLAY_ENABLE
//         pkt.emit(hdr.erspan_type1_underlay);
//         pkt.emit(hdr.erspan_type2_underlay);
// #endif /* ERSPAN_UNDERLAY_ENABLE */

        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.arp); // Ingress only.
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre);

        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp); // Ingress only.
        pkt.emit(hdr.icmp); // Ingress only.
        pkt.emit(hdr.igmp); // Ingress only.
        pkt.emit(hdr.vxlan);
# 215 "npb/parde.p4"
        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}

//=============================================================================
// Egress Deparser
//=============================================================================
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;

    apply {
        egress_mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);
        hdr.ipv4.hdr_checksum = ipv4_checksum.update({
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.total_len,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.frag_offset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.src_addr,
            hdr.ipv4.dst_addr});


        hdr.inner_ipv4.hdr_checksum = inner_ipv4_checksum.update({
            hdr.inner_ipv4.version,
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.diffserv,
            hdr.inner_ipv4.total_len,
            hdr.inner_ipv4.identification,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.frag_offset,
            hdr.inner_ipv4.ttl,
            hdr.inner_ipv4.protocol,
            hdr.inner_ipv4.src_addr,
            hdr.inner_ipv4.dst_addr});


/*
        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress Only.
        pkt.emit(hdr.cpu); // Egress Only.
        pkt.emit(hdr.timestamp); // Egress only.
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
        pkt.emit(hdr.gre); // Egress only.
        pkt.emit(hdr.erspan_type2); // Egress only.
        //pkt.emit(hdr.erspan_type3); // Egress only.
        //pkt.emit(hdr.erspan_platform); // Egress only.

        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
*/

        // ***** UNDERLAY *****
        pkt.emit(hdr.ethernet_underlay);
        pkt.emit(hdr.vlan_tag_underlay);
        pkt.emit(hdr.nsh_extr_underlay);

        // ***** OUTER *****
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric); // Egress Only.
        pkt.emit(hdr.cpu); // Egress Only.
        pkt.emit(hdr.timestamp); // Egress only.

        pkt.emit(hdr.e_tag);
        pkt.emit(hdr.vn_tag);
        pkt.emit(hdr.vlan_tag);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.gre); // Egress Only.




        pkt.emit(hdr.erspan_type3); // Egress Only.
        pkt.emit(hdr.erspan_platform); // Egress Only.


        pkt.emit(hdr.nvgre);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.sctp);
        pkt.emit(hdr.esp);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.vxlan);
# 339 "npb/parde.p4"
        // ***** INNER *****
        pkt.emit(hdr.inner_ethernet);
        pkt.emit(hdr.inner_vlan_tag);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_gre);
        pkt.emit(hdr.inner_sctp);
        pkt.emit(hdr.inner_esp);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_icmp);
        pkt.emit(hdr.inner_igmp);
    }
}
# 46 "npb/npb.p4" 2
# 1 "npb/port.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

# 1 "npb/rewrite.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/




# 1 "npb/l2.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/
# 28 "npb/rewrite.p4" 2

//-----------------------------------------------------------------------------
// @param hdr : Parsed headers. For mirrored packet only Ethernet header is parsed.
// @param eg_md : Egress metadata fields.
// @param table_size : Number of mirror sessions.
//
// @flags PACKET_LENGTH_ADJUSTMENT : For mirrored packet, the length of the mirrored
// metadata fields is also accounted in the packet length. This flags enables the
// calculation of the packet length excluding the mirrored metadata fields.
//-----------------------------------------------------------------------------
control MirrorRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md)(
                      switch_uint32_t table_size=1024) {
    bit<16> length;

    action add_ethernet_header(in mac_addr_t src_addr,
                               in mac_addr_t dst_addr,
                               in bit<16> ether_type) {
        hdr.ethernet.setValid();
        hdr.ethernet.ether_type = ether_type;
        hdr.ethernet.src_addr = src_addr;
        hdr.ethernet.dst_addr = dst_addr;
    }

    action add_ipv4_header(in bit<8> diffserv,
                           in bit<8> ttl,
                           in bit<8> protocol,
                           in ipv4_addr_t src_addr,
                           in ipv4_addr_t dst_addr) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        hdr.ipv4.diffserv = diffserv;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.ttl = ttl;
        hdr.ipv4.protocol = protocol;
        hdr.ipv4.src_addr = src_addr;
        hdr.ipv4.dst_addr = dst_addr;
    }

    action add_gre_header(in bit<16> proto) {
        hdr.gre.setValid();
        hdr.gre.C = 0;
        hdr.gre.K = 0;
        hdr.gre.S = 0;
        hdr.gre.s = 0;
        hdr.gre.recurse = 0;
        hdr.gre.flags = 0;
        hdr.gre.version = 0;
        hdr.gre.proto = proto;
    }

    action rewrite_(switch_qid_t qid) {
        eg_md.qos.qid = qid;
    }

    action rewrite_rspan(switch_qid_t qid, switch_bd_t bd) {
        eg_md.qos.qid = qid;
        eg_md.bd = bd;
    }

    action rewrite_erspan_type2(switch_qid_t qid,
                                mac_addr_t smac,
                                mac_addr_t dmac,
                                ipv4_addr_t sip,
                                ipv4_addr_t dip,
                                bit<8> tos,
                                bit<8> ttl) {
        //TODO(msharif): Support for GRE sequence number.
# 119 "npb/rewrite.p4"
    }

    action rewrite_erspan_type3(switch_qid_t qid,
                                mac_addr_t smac,
                                mac_addr_t dmac,
                                ipv4_addr_t sip,
                                ipv4_addr_t dip,
                                bit<8> tos,
                                bit<8> ttl) {
        eg_md.qos.qid = qid;
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.vlan = 0;
        hdr.erspan_type3.cos_bso_t = 0;
        hdr.erspan_type3.session_id = (bit<10>) eg_md.mirror.session_id;
        hdr.erspan_type3.timestamp = (bit<32>) eg_md.timestamp;
        hdr.erspan_type3.sgt = 0;
        //TODO(msharif): Set direction flag if EGRESS_PORT_MIRRORING is enabled.
        hdr.erspan_type3.p = 0;
        hdr.erspan_type3.ft = 0; // Ethernet frame
        hdr.erspan_type3.hw_id = 0;
        hdr.erspan_type3.d = 0;
        hdr.erspan_type3.gra = 0b10;
        hdr.erspan_type3.o = 0;

        add_gre_header(0x22EB);

        // Total length = packet length + 36
        //   IPv4 (20) + GRE (4) + Erspan (12)
        add_ipv4_header(
            tos, ttl, 0x2f, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w24; //16w36 - 16w12;

        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);
    }

    action rewrite_erspan_type3_platform_specific(
            switch_qid_t qid,
            mac_addr_t smac,
            mac_addr_t dmac,
            ipv4_addr_t sip,
            ipv4_addr_t dip,
            bit<8> tos,
            bit<8> ttl) {
        eg_md.qos.qid = qid;
        hdr.erspan_type3.setValid();
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.vlan = 0;
        hdr.erspan_type3.cos_bso_t = 0;
        hdr.erspan_type3.session_id = (bit<10>) eg_md.mirror.session_id;
        hdr.erspan_type3.timestamp = (bit<32>) eg_md.timestamp;
        hdr.erspan_type3.sgt = 0;
        hdr.erspan_type3.p = 0;
        hdr.erspan_type3.ft = 0; // Ethernet frame
        hdr.erspan_type3.hw_id = 0;
        hdr.erspan_type3.d = 0;
        hdr.erspan_type3.gra = 0b10;
        hdr.erspan_type3.o = 1;

        hdr.erspan_platform.setValid();
        hdr.erspan_platform.id = 0;
        hdr.erspan_platform.info = 0;

        add_gre_header(0x22EB);

        // Total length = packet length + 44
        //   IPv4 (20) + GRE (4) + Erspan (12) + Platform Specific (8)
        add_ipv4_header(
            tos, ttl, 0x2f, sip, dip);
        hdr.ipv4.total_len = eg_md.pkt_length + 16w32; // 16w44 - 16w12;

        hdr.inner_ethernet = hdr.ethernet;
        add_ethernet_header(smac, dmac, 0x0800);
    }

    table rewrite {
        key = { eg_md.mirror.session_id : exact; }
        actions = {
            NoAction;
            rewrite_;
            rewrite_rspan;
            rewrite_erspan_type2;
            rewrite_erspan_type3;
            rewrite_erspan_type3_platform_specific;
            //TODO : ethernet+vlan.
        }

        const default_action = NoAction;
        size = table_size;
    }


    action adjust_length(bit<16> length_offset) {
        eg_md.pkt_length = eg_md.pkt_length + length_offset;
    }

    table pkt_length {
        key = { eg_md.mirror.type : exact; }
        actions = { adjust_length; }
        const entries = {
            //This is mirror_metadata_t + 4 bytes of CRC
            1 : adjust_length(-12);
        }
    }


    apply {




        rewrite.apply();

    }
}

control Rewrite(inout switch_header_t hdr,
                inout switch_egress_metadata_t eg_md) {
    EgressBd(
        EGRESS_BD_MAPPING_TABLE_SIZE, EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
    switch_smac_index_t smac_index;

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {

        eg_md.flags.routed = false;
        eg_md.tunnel.type = type;

    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id) {

        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;

    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {

        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
        eg_md.tunnel.type = type;

    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {

        eg_md.flags.routed = true;
        hdr.ethernet.dst_addr = dmac;
        eg_md.tunnel.type = type;

    }

    // -------------------
    // Extreme Added
    // -------------------

    // For MAC-in-MAC, we want a hybrid of their above L2/L3 schemes.
    // In other words, we want to:
    //
    // - Retain the SA -- so clear the 'routed' flag (like l2).
    // - Change the DA                               (like l3).

    action rewrite_l2_l3_nsh(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.flags.routed = false;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
    }

    // -------------------

    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;

   rewrite_l2_l3_nsh;
        }

        const default_action = NoAction;
        size = NEXTHOP_TABLE_SIZE;
    }

    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
    }

    // RFC 1112
    action rewrite_ipv4_multicast() {
        //XXX might be possible on Tofino as dst_addr[23] is 0.
        //hdr.ethernet.dst_addr[22:0] = hdr.ipv4.dst_addr[22:0];
        //hdr.ethernet.dst_addr[47:24] = 0x01005E;
    }

    // RFC 2464
    action rewrite_ipv6_multicast() {
        //hdr.ethernet.dst_addr[31:0] = hdr.ipv6.dst_addr[31:0];
        //hdr.ethernet.dst_addr[47:32] = 16w0x3333;
    }

    table multicast_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv4.dst_addr[31:28] : ternary;
            //hdr.ipv6.isValid() : exact;
            //hdr.ipv6.dst_addr[127:96] : ternary;
        }

        actions = {
            NoAction;
            rewrite_ipv4_multicast;
            rewrite_ipv6_multicast;
        }

        const default_action = NoAction;
    }


    action rewrite_ipv4() {
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action rewrite_ipv6() {



    }

    table ip_rewrite {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;

   hdr.nsh_extr_underlay.isValid() : exact;
        }

        actions = {
            rewrite_ipv4;
            rewrite_ipv6;
        }

        const entries = {
//          (true, false) : rewrite_ipv4();
//          (false, true) : rewrite_ipv6();

            (true, false, false) : rewrite_ipv4();
            (false, true, false) : rewrite_ipv6();
        }
    }

    apply {
        // Should not rewrite packets redirected to CPU.
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            nexthop_rewrite.apply();
        }

        egress_bd.apply(hdr, eg_md.bd, eg_md.pkt_type, eg_md.bd_label,
            smac_index, eg_md.checks.mtu);

        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL && eg_md.flags.routed) {
            ip_rewrite.apply();
            smac_rewrite.apply();
        }
    }
}
# 27 "npb/port.p4" 2

//-----------------------------------------------------------------------------
// Ingress port mirroring
//-----------------------------------------------------------------------------
control PortMirror(
        in switch_port_t port,
        in bit<8> src,
        inout switch_mirror_metadata_t mirror_md,
        inout switch_mirror_type_t mirror_type)(
        switch_uint32_t table_size=288) {

    action set_mirror_id(switch_mirror_session_t session_id) {
        mirror_type = 1;
        mirror_md.type = 1;
        mirror_md.src = src;
        mirror_md.session_id = session_id;
    }

    table port_mirror {
        key = { port : exact; }
        actions = {
            NoAction;
            set_mirror_id;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        port_mirror.apply();
    }
}

control IngressPortMapping(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)(
        switch_uint32_t port_vlan_table_size,
        switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
        switch_uint32_t vlan_table_size=2048) {

    PortMirror(port_table_size) port_mirror;
    ActionProfile(bd_table_size) bd_action_profile;
    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) hash;

    // This register is used to check whether a port is a mermber of a vlan (bd)
    // or not. (port << 12 | vid) is used as the index to read the membership
    // status.To save resources, only 7-bit local port id is used to calculate
    // the indes.
    const bit<32> vlan_membership_size = 1 << 19;
    Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;
    RegisterAction<bit<1>, bit<32>, bit<1>>(vlan_membership) check_vlan_membership = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = ~val;
        }
    };

    action terminate_cpu_packet() {
        ig_md.bypass = hdr.cpu.reason_code;
        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        ig_intr_md_for_tm.ucast_egress_port =
            (switch_port_t) hdr.fabric.dst_port_or_group;
        //XXX(msharif) : Fix this for Tofino2
        // ig_intr_md_for_tm.qid = hdr.cpu.egress_queue;
        ig_intr_md_for_tm.bypass_egress = (bool) hdr.cpu.tx_bypass;
        hdr.ethernet.ether_type = hdr.cpu.ether_type;
    }

    action set_cpu_port_properties(
            switch_port_lag_index_t port_lag_index,
            switch_port_lag_label_t port_lag_label,
            switch_yid_t exclusion_id,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc) {
        ig_md.port_lag_index = port_lag_index;
        ig_md.port_lag_label = port_lag_label;
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

        terminate_cpu_packet();
    }

    action set_port_properties(
            switch_yid_t exclusion_id,
            switch_learning_mode_t learning_mode,
            switch_qos_trust_mode_t trust_mode,
            switch_qos_group_t qos_group,
            switch_pkt_color_t color,
            switch_tc_t tc,
            bool mac_pkt_class) {
        ig_md.qos.trust_mode = trust_mode;
        ig_md.qos.group = qos_group;
        ig_md.qos.color = color;
        ig_md.qos.tc = tc;
        ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
        ig_md.learning.port_mode = learning_mode;
        ig_md.checks.same_if = 0xffff;
        ig_md.flags.mac_pkt_class = mac_pkt_class;
    }

    table port_mapping {
        key = {
            ig_md.port : exact;
            hdr.cpu.isValid() : exact;
            hdr.cpu.ingress_port : exact;
        }

        actions = {
            set_port_properties;
            set_cpu_port_properties;
        }

        size = port_table_size * 2;
    }

    action port_vlan_miss() {
        //ig_md.flags.port_vlan_miss = true;
    }

    action set_bd_properties(switch_bd_t bd,
                             switch_vrf_t vrf,
                             switch_bd_label_t bd_label,
                             switch_rid_t rid,
                             switch_stp_group_t stp_group,
                             switch_learning_mode_t learning_mode,
                             bool ipv4_unicast_enable,
                             bool ipv4_multicast_enable,
                             bool igmp_snooping_enable,
                             bool ipv6_unicast_enable,
                             bool ipv6_multicast_enable,
                             bool mld_snooping_enable,
                             switch_multicast_rpf_group_t mrpf_group,
                             switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        ig_intr_md_for_tm.rid = rid;
        ig_md.rmac_group = rmac_group;
        ig_md.stp.group = stp_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4_md.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4_md.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4_md.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6_md.unicast_enable = ipv6_unicast_enable;
        ig_md.ipv6_md.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6_md.multicast_snooping = mld_snooping_enable;
    }

    // (port, vlan) --> bd mapping -- Following set of entres are needed:
    //   (port, 0, *)    L3 interface.
    //   (port, 1, vlan) L3 sub-interface.
    //   (port, 0, *)    Access port + untagged packet.
    //   (port, 1, vlan) Access port + packets tagged with access-vlan.
    //   (port, 1, 0)    Access port + .1p tagged packets.
    //   (port, 1, vlan) L2 sub-port.
    //   (port, 0, *)    Trunk port if native-vlan is not tagged.

    table port_vlan_to_bd_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = port_vlan_table_size;
    }

    // (*, vlan) --> bd mapping
    table vlan_to_bd_mapping {
        key = {
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = vlan_table_size;
    }

    table cpu_to_bd_mapping {
        key = { hdr.cpu.ingress_bd : exact; }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = bd_table_size;
    }

    action set_interface_properties(switch_ifindex_t ifindex, switch_if_label_t if_label) {
        ig_md.ifindex = ifindex;
        ig_md.checks.same_if = 0xffff;
        ig_md.if_label = if_label;
    }

    table port_vlan_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            NoAction;
            set_interface_properties;
        }

        const default_action = NoAction;
        size = port_vlan_table_size;
    }

    table port_to_ifindex_mapping {
        key = {
            ig_md.port_lag_index : exact;
        }

        actions = {
            NoAction;
            set_interface_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    action set_peer_link_properties() {
        ig_intr_md_for_tm.rid = SWITCH_RID_DEFAULT;
        ig_md.flags.peer_link = true;
    }

    table peer_link {
        key = { ig_md.port_lag_index : exact; }
        actions = {
            NoAction;
            set_peer_link_properties;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

    apply {
        switch (port_mapping.apply().action_run) {
            set_cpu_port_properties : {
                cpu_to_bd_mapping.apply();
            }

            set_port_properties : {
                if (!port_vlan_to_bd_mapping.apply().hit) {
                    if (hdr.vlan_tag[0].isValid())
                        vlan_to_bd_mapping.apply();
                }
            }
        }
# 318 "npb/port.p4"
        // Check vlan membership
        if (hdr.vlan_tag[0].isValid() && (bit<1>) ig_md.flags.port_vlan_miss == 0) {
            bit<32> pv_hash_ = hash.get({ig_md.port[6:0], hdr.vlan_tag[0].vid});
            ig_md.flags.port_vlan_miss =
                (bool)check_vlan_membership.execute(pv_hash_);
        }
# 335 "npb/port.p4"
    }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param lkp : Lookup fields used for hash calculation.
// @param port_lag_index : Port/Lag index.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
// @flag MLAG_ENABLE : Enable multi-chassis LAG.
// ----------------------------------------------------------------------------

control LAG(inout switch_ingress_metadata_t ig_md,
            in bit<16> hash,
            out switch_port_t egress_port) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(1024, selector_hash, SelectorMode_t.FAIR) lag_selector;

    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }

    action set_peer_link_port(switch_port_t port, switch_ifindex_t ifindex) {





    }

    action lag_miss() { }

    table lag {
        key = {



            ig_md.egress_port_lag_index : exact @name("port_lag_index");

            hash : selector;
        }

        actions = {
            lag_miss;
            set_lag_port;
            set_peer_link_port;
        }

        const default_action = lag_miss;
        size = 1024;
        implementation = lag_selector;
    }

    apply {
        lag.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress port lookup
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Egress port.
//
// @flag EGRESS_PORT_MIRROR_ENABLE: Enables egress port-base mirroring.
//-----------------------------------------------------------------------------
control EgressPortMapping(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port)(
        switch_uint32_t table_size=288) {
    PortMirror(table_size) port_mirror;

    action port_normal(switch_port_lag_index_t port_lag_index,
                       switch_port_lag_label_t port_lag_label,
                       switch_qos_group_t qos_group,
                       bool mlag_member) {
        eg_md.port_type = SWITCH_PORT_TYPE_NORMAL;
        eg_md.port_lag_index = port_lag_index;
        eg_md.port_lag_label = port_lag_label;
        eg_md.qos.group = qos_group;
        eg_md.flags.mlag_member = mlag_member;
    }

    action cpu_rewrite() {
        hdr.fabric.setValid();
        hdr.fabric.reserved = 0;
        hdr.fabric.color = 0;
        hdr.fabric.qos = 0;
        hdr.fabric.reserved2 = 0;
        hdr.fabric.dst_port_or_group = 0;

        hdr.cpu.setValid();
        hdr.cpu.egress_queue = 0;
        hdr.cpu.tx_bypass = 0;
        hdr.cpu.reserved = 0;
        hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;
        hdr.cpu.ingress_ifindex = eg_md.ingress_ifindex;
        hdr.cpu.ingress_bd = eg_md.bd;
        hdr.cpu.reason_code = eg_md.cpu_reason;
        hdr.cpu.ether_type = hdr.ethernet.ether_type;

        hdr.ethernet.ether_type = 0x9000;
    }

    action port_cpu() {
        eg_md.port_type = SWITCH_PORT_TYPE_CPU;
        cpu_rewrite();
    }

    table port_mapping {
        key = { port : exact; }

        actions = {
            port_normal;
            port_cpu;
        }

        size = table_size;
    }

    apply {
        port_mapping.apply();





    }
}
# 47 "npb/npb.p4" 2
# 1 "npb/validation.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

// ============================================================================
// Packet validaion
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
// ============================================================================
control PktValidation(
        in switch_header_t hdr,
        inout switch_ingress_flags_t flags,
        inout switch_lookup_fields_t lkp,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        out switch_drop_reason_t drop_reason) {
//-----------------------------------------------------------------------------
// Validate outer packet header
// - Drop the packet if src addr is zero or multicast or dst addr is zero.
//-----------------------------------------------------------------------------
    const switch_uint32_t table_size = 64;

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    action valid_unicast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_multicast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_broadcast_pkt_untagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.ethernet.ether_type;
    }

    action valid_unicast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    action valid_multicast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    action valid_broadcast_pkt_tagged() {
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
        lkp.mac_src_addr = hdr.ethernet.src_addr;
        lkp.mac_dst_addr = hdr.ethernet.dst_addr;
        lkp.mac_type = hdr.vlan_tag[0].ether_type;
        lkp.pcp = hdr.vlan_tag[0].pcp;
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.src_addr : ternary;
            hdr.ethernet.dst_addr : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
        }

        actions = {
            malformed_pkt;
            valid_unicast_pkt_untagged;
            valid_multicast_pkt_untagged;
            valid_broadcast_pkt_untagged;
            valid_unicast_pkt_tagged;
            valid_multicast_pkt_tagged;
            valid_broadcast_pkt_tagged;
        }

        size = table_size;
        /* XXX Driver does not support static entries for tables with match
        fields with more than 32 btis.
        const entries = {
            (_, _, _) : malformed_pkt(SWITCH_DROP_SRC_MAC_MULTICAST);
            (0, _, _) : malformed_pkt(SWITCH_DROP_SRC_MAC_ZERO);
            (_, 0, _) : malformed_pkt(SWITCH_DROP_DST_MAC_ZERO);
        }*/
    }

//-----------------------------------------------------------------------------
// Validate outer IPv4 header and set the lookup fields.
// - Drop the packet if ttl is zero, ihl is invalid, src addr is multicast, or
// - version is invalid.
//-----------------------------------------------------------------------------
    action valid_ipv4_pkt() {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ipv4_src_addr = hdr.ipv4.src_addr;
        lkp.ipv4_dst_addr = hdr.ipv4.dst_addr;
    }

    table validate_ipv4 {
        key = {
            flags.ipv4_checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            //TODO(msharif) This is the right place to set some flags to detect
            // IP fragmentation.
            // hdr.ipv4.flags : ternary;
            // hdr.ipv4.frag_offset : ternary;
            hdr.ipv4.ttl : ternary;
            hdr.ipv4.src_addr[31:24] : ternary; //TODO define the bit range.
        }

        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }

        size = table_size;
        /* XXX Driver does not support static entries for TCAM tables
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, _, _, 0x7f) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK);
            (_, _, _, _, 0xe0 &&& 0xf0) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, _, _, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (_, _, 0 &&& 0xc, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (_, _, 4 &&& 0xf, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (false, 4 &&& 0xf, _, _, _) : valid_ipv4_pkt();
            (true, 4 &&& 0xf, _, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        }
        */
    }


//-----------------------------------------------------------------------------
// Validate outer IPv6 header and set the lookup fields.
// - Drop the packet if hop_limit is zero, src addr is multicast or version is
// invalid.
//-----------------------------------------------------------------------------

    action valid_ipv6_pkt(bool is_link_local) {
        // Set common lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_tos = hdr.ipv6.traffic_class;
        lkp.ip_proto = hdr.ipv6.next_hdr;
        lkp.ip_ttl = hdr.ipv6.hop_limit;
        lkp.ipv6_src_addr = hdr.ipv6.src_addr;
        lkp.ipv6_dst_addr = hdr.ipv6.dst_addr;
        flags.link_local = is_link_local;
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hop_limit : ternary;
            hdr.ipv6.src_addr[127:96] : ternary; //TODO define the bit range.
        }

        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }

        size = table_size;
        /* XXX Driver does not support static entries for TCAM tables
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, 0xff) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (6, _, _) : valid_ipv6_pkt(false);
        }
        */
    }

//-----------------------------------------------------------------------------
// Set L4 and other lookup fields
//-----------------------------------------------------------------------------
    action set_tcp_ports() {
        lkp.l4_src_port = hdr.tcp.src_port;
        lkp.l4_dst_port = hdr.tcp.dst_port;
        lkp.tcp_flags = hdr.tcp.flags;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.udp.src_port;
        lkp.l4_dst_port = hdr.udp.dst_port;
        lkp.tcp_flags = 0;
    }

    action set_icmp_type() {
        lkp.l4_src_port[7:0] = hdr.icmp.type;
        lkp.l4_src_port[15:8] = hdr.icmp.code;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
    }

    action set_igmp_type() {






    }

    action set_arp_opcode() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
        lkp.arp_opcode = hdr.arp.opcode;
    }

    // Not much of a validation as it only sets the lookup fields.
    table validate_other {
        key = {
            hdr.tcp.isValid() : exact;
            hdr.udp.isValid() : exact;
            hdr.icmp.isValid() : exact;
            hdr.igmp.isValid() : exact;
            hdr.arp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
            set_icmp_type;
            set_igmp_type;
            set_arp_opcode;
        }

        const default_action = NoAction;
        const entries = {
            (true, false, false, false, false) : set_tcp_ports();
            (false, true, false, false, false) : set_udp_ports();
            (false, false, true, false, false) : set_icmp_type();
            (false, false, false, true, false) : set_igmp_type();
            (false, false, false, false, true) : set_arp_opcode();
        }
    }

    apply {
        switch(validate_ethernet.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.ipv4.isValid()) {
                    validate_ipv4.apply();
                } else if (hdr.ipv6.isValid()) {



                }

                validate_other.apply();
            }
        }
    }
}

// ============================================================================
// Inner packet validaion
// Validate ethernet, Ipv4 or Ipv6 common lookup fields.
// ============================================================================
control InnerPktValidation(
        in switch_header_t hdr,
        inout switch_lookup_fields_t lkp,
        inout switch_ingress_flags_t flags,
        inout switch_drop_reason_t drop_reason) {

    action valid_unicast_pkt() {
        // Set the common L2 lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_UNICAST;

    }

    action valid_multicast_pkt() {
        // Set the common L2 lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_MULTICAST;
    }

    action valid_broadcast_pkt() {
        // Set the common L2 lookup fields
        lkp.mac_src_addr = hdr.inner_ethernet.src_addr;
        lkp.mac_dst_addr = hdr.inner_ethernet.dst_addr;
        lkp.mac_type = hdr.inner_ethernet.ether_type;
        lkp.pkt_type = SWITCH_PKT_TYPE_BROADCAST;
    }

    action malformed_pkt(bit<8> reason) {
        drop_reason = reason;
    }

    table validate_ethernet {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ethernet.src_addr : ternary;
            hdr.inner_ethernet.dst_addr : ternary;
        }

        actions = {
            NoAction;
            valid_unicast_pkt;
            valid_multicast_pkt;
            valid_broadcast_pkt;
            malformed_pkt;
        }
    }

    action valid_ipv4_pkt() {
        // Set the common IP lookup fields
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_tos = hdr.inner_ipv4.diffserv;
        lkp.ip_ttl = hdr.inner_ipv4.ttl;
        lkp.ipv4_src_addr = hdr.inner_ipv4.src_addr;
        lkp.ipv4_dst_addr = hdr.inner_ipv4.dst_addr;
        // lkp.ipv6_src_addr = 0;
        // lkp.ipv6_dst_addr = 0;
    }

    table validate_ipv4 {
        key = {
            flags.inner_ipv4_checksum_err : ternary;
            hdr.inner_ipv4.version : ternary;
            hdr.inner_ipv4.ihl : ternary;
            hdr.inner_ipv4.ttl : ternary;
            hdr.inner_ipv4.src_addr[31:24] : ternary;
        }
        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }
        /*
        const default_action = malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        const entries = {
            (_, _, _, _, 0x7f) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_LOOPBACK);
            (_, _, _, _, 0xe0 &&& 0xf0) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_SRC_MULTICAST);
            (_, _, _, 0, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_TTL_ZERO);
            (_, _, 0 &&& 0xc, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (_, _, 4 &&& 0xf, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_IHL_INVALID);
            (false, 4 &&& 0xf, _, _, _) : valid_ipv4_pkt();
            (true, 4 &&& 0xf, _, _, _) : malformed_pkt(SWITCH_DROP_REASON_OUTER_IP_VERSION_INVALID);
        }
        */
    }

    action valid_ipv6_pkt(bool is_link_local) {
# 396 "npb/validation.p4"
    }

    table validate_ipv6 {
        key = {
            hdr.inner_ipv6.version : ternary;
            hdr.inner_ipv6.hop_limit : ternary;
            hdr.inner_ipv6.src_addr : ternary;
        }
        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }
    }

    action set_tcp_ports() {
        lkp.l4_src_port = hdr.inner_tcp.src_port;
        lkp.l4_dst_port = hdr.inner_tcp.dst_port;
    }

    action set_udp_ports() {
        lkp.l4_src_port = hdr.inner_udp.src_port;
        lkp.l4_dst_port = hdr.inner_udp.dst_port;
    }

    table validate_other {
        key = {
            hdr.inner_tcp.isValid() : exact;
            hdr.inner_udp.isValid() : exact;
        }

        actions = {
            NoAction;
            set_tcp_ports;
            set_udp_ports;
        }

        const default_action = NoAction;
        const entries = {
            (true, false) : set_tcp_ports();
            (false, true) : set_udp_ports();
        }
    }


    apply {
        switch(validate_ethernet.apply().action_run) {
            malformed_pkt : {}
            default : {
                if (hdr.inner_ipv4.isValid()) {
                    validate_ipv4.apply();
                } else if (hdr.inner_ipv6.isValid()) {



                }

                validate_other.apply();
            }
        }
    }
}
# 48 "npb/npb.p4" 2
# 1 "npb/rewrite.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/
# 49 "npb/npb.p4" 2
# 1 "npb/tunnel.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/





//-----------------------------------------------------------------------------
// Tunnel processing
// Outer router MAC
// IP source and destination VTEP
//-----------------------------------------------------------------------------
control IngressTunnel(in switch_header_t hdr,
                      inout switch_ingress_metadata_t ig_md,
                      inout switch_lookup_fields_t lkp,
                      inout switch_lookup_fields_t lkp_nsh)(
                      switch_uint32_t src_vtep_table_size) {

    InnerPktValidation() pkt_validation;
    InnerPktValidation() pkt_validation_nsh;

 // ---------------------------------
 // RMAC ----------------------------
 // ---------------------------------

    action rmac_hit() { }

    table rmac {
        key = {
            ig_md.rmac_group : exact;
            lkp.mac_dst_addr : exact;
        }

        actions = {
            NoAction;
            rmac_hit;
        }

        const default_action = NoAction;
        size = 1024;
    }

 // ---------------------------------
 // Src VTEP ------------------------
 // ---------------------------------

    action src_vtep_hit(switch_ifindex_t ifindex) {
        ig_md.tunnel.ifindex = ifindex;
    }

    action src_vtep_miss() {}

    table src_vtep {
        key = {
            lkp.ipv4_src_addr : exact @name("src_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = src_vtep_table_size;
    }

 // ---------------------------------
 // Src VTEP (NPB) ------------------
 // ---------------------------------

    action src_vtep_hit_nsh(switch_ifindex_t ifindex) {
        ig_md.tunnel_nsh.ifindex = ifindex;
    }

    action src_vtep_miss_nsh() {}

    table src_vtep_nsh {
        key = {
// Derek: Comment out these three lines...we only want to look for tunnel type!
//          lkp_nsh.ipv4_src_addr : exact @name("src_addr");
//          ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            src_vtep_miss_nsh;
            src_vtep_hit_nsh;
        }

        const default_action = src_vtep_miss_nsh;
        size = src_vtep_table_size;
    }

 // ---------------------------------
 // Dst VTEP ------------------------
 // ---------------------------------

    action dst_vtep_hit() {
    }

 // ---------------------------------

    //TODO(msharif): Add exclusion id.
    action set_vni_properties(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
        ig_md.bd = bd;
        ig_md.bd_label = bd_label;
        ig_md.vrf = vrf;
        // ig_intr_md_for_tm.rid = rid;
        ig_md.rmac_group = rmac_group;
        ig_md.multicast.rpf_group = mrpf_group;
        ig_md.learning.bd_mode = learning_mode;
        ig_md.ipv4_md.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4_md.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4_md.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6_md.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6_md.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6_md.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel.terminate = true;
    }

 // ---------------------------------

    table dst_vtep {
        key = {
            lkp.ipv4_src_addr : ternary @name("src_addr");
            lkp.ipv4_dst_addr : exact @name("dst_addr");
            ig_md.vrf : exact;
            ig_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            set_vni_properties;
        }

        const default_action = NoAction;
    }

 // ---------------------------------

    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
        key = { ig_md.tunnel.id : exact; }

        actions = {
            NoAction;
            set_vni_properties;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }

 // ---------------------------------
 // Dst VTEP (NPB) ------------------
 // ---------------------------------

    action dst_vtep_hit_nsh() {
    }

 // ---------------------------------

    //TODO(msharif): Add exclusion id.
    action set_vni_properties_nsh(
            switch_bd_t bd,
            switch_vrf_t vrf,
            switch_bd_label_t bd_label,
            switch_rid_t rid,
            switch_learning_mode_t learning_mode,
            bool ipv4_unicast_enable,
            bool ipv4_multicast_enable,
            bool igmp_snooping_enable,
            bool ipv6_unicast_enable,
            bool ipv6_multicast_enable,
            bool mld_snooping_enable,
            switch_multicast_rpf_group_t mrpf_group,
            switch_rmac_group_t rmac_group) {
        ig_md.bd_nsh = bd;
        ig_md.bd_label_nsh = bd_label;
        ig_md.vrf_nsh = vrf;
        // ig_intr_md_for_tm.rid = rid;
        ig_md.rmac_group_nsh = rmac_group;
        ig_md.multicast_nsh.rpf_group = mrpf_group;
        ig_md.learning_nsh.bd_mode = learning_mode;
        ig_md.ipv4_md_nsh.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv4_md_nsh.multicast_enable = ipv4_multicast_enable;
        ig_md.ipv4_md_nsh.multicast_snooping = igmp_snooping_enable;
        ig_md.ipv6_md_nsh.unicast_enable = ipv4_unicast_enable;
        ig_md.ipv6_md_nsh.multicast_enable = ipv6_multicast_enable;
        ig_md.ipv6_md_nsh.multicast_snooping = mld_snooping_enable;
        ig_md.tunnel_nsh.terminate = true;
    }

 // ---------------------------------

    table dst_vtep_nsh {
        key = {
// Derek: Comment out these three lines...we only want to look for tunnel type!
//          lkp_nsh.ipv4_src_addr : ternary @name("src_addr");
//          lkp_nsh.ipv4_dst_addr : exact @name("dst_addr");
//          ig_md.vrf : exact;
            ig_md.tunnel_nsh.type : exact;
        }

        actions = {
            NoAction;
            dst_vtep_hit_nsh;
            set_vni_properties_nsh;
        }

        const default_action = NoAction;
    }

 // ---------------------------------

    // Tunnel id -> BD Translation
    table vni_to_bd_mapping_nsh {
        key = { ig_md.tunnel_nsh.id : exact; }

        actions = {
            NoAction;
            set_vni_properties_nsh;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }

 // ---------------------------------
 // ---------------------------------
 // ---------------------------------

    apply {

        // outer RMAC lookup for tunnel termination.
        switch(rmac.apply().action_run) {
            rmac_hit : {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                    src_vtep.apply();
                    switch(dst_vtep.apply().action_run) {
                        dst_vtep_hit : {
                            // Vxlan
                            vni_to_bd_mapping.apply();
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties : {
                            // IPinIP
                            pkt_validation.apply(hdr, lkp, ig_md.flags, ig_md.drop_reason);
                        }
                    }
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {



                }

    // ---------------------------------
    // Extreme Added
    // ---------------------------------

                if (lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV4) {
                    src_vtep_nsh.apply();
                    switch(dst_vtep_nsh.apply().action_run) {
                        dst_vtep_hit_nsh : {
                            // Vxlan
                            vni_to_bd_mapping_nsh.apply();
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }

                        set_vni_properties_nsh : {
                            // IPinIP
                            pkt_validation_nsh.apply(hdr, lkp_nsh, ig_md.flags, ig_md.drop_reason);
                        }
                    }
                } else if (lkp_nsh.ip_type == SWITCH_IP_TYPE_IPV6) {



                }
            }
        }


    }
}

//-----------------------------------------------------------------------------
// Tunnel decapsulation
//
// @param hdr : Parsed headers.
// @param mode :  Specify the model for tunnel decapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying from the outer header on decapsulation. In the PIPE mode, ttl,
// and dscp fields of the inner header are independent of that in the outer header and remain the
// same on decapsulation.
//
//-----------------------------------------------------------------------------
control TunnelDecap(inout switch_header_t hdr)(switch_tunnel_mode_t mode) {
    action decap_inner_udp() {
        hdr.udp = hdr.inner_udp;
        hdr.inner_udp.setInvalid();
    }

    action decap_inner_tcp() {
        hdr.tcp = hdr.inner_tcp;
        hdr.inner_tcp.setInvalid();
        hdr.udp.setInvalid();
    }

    action decap_inner_unknown() {
        hdr.udp.setInvalid();
    }

    //TODO(msharif) : Inner tcp is only parsed if egress ACL is enabled.
    table decap_inner_l4 {
        key = {
            hdr.inner_udp.isValid() : exact;
            hdr.inner_tcp.isValid() : exact;
        }

        actions = {
            decap_inner_udp;
            // decap_inner_tcp;
            decap_inner_unknown;
        }

        const default_action = decap_inner_unknown;
        const entries = {
            (true, false) : decap_inner_udp();
            // (false, true) : decap_inner_tcp();
        }
    }

    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr.ipv4.setValid();
        hdr.ipv4.version = hdr.inner_ipv4.version;
        hdr.ipv4.ihl = hdr.inner_ipv4.ihl;
        hdr.ipv4.total_len = hdr.inner_ipv4.total_len;
        hdr.ipv4.identification = hdr.inner_ipv4.identification;
        hdr.ipv4.flags = hdr.inner_ipv4.flags;
        hdr.ipv4.frag_offset = hdr.inner_ipv4.frag_offset;
        hdr.ipv4.protocol = hdr.inner_ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.inner_ipv4.hdr_checksum;
        hdr.ipv4.src_addr = hdr.inner_ipv4.src_addr;
        hdr.ipv4.dst_addr = hdr.inner_ipv4.dst_addr;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = hdr.inner_ipv4.ttl;
            hdr.ipv4.diffserv = hdr.inner_ipv4.diffserv;
        }

        hdr.inner_ipv4.setInvalid();
    }

    action invalidate_tunneling_headers() {
        // Removing tunneling headers by default.
        hdr.vxlan.setInvalid();
    }

    action decap_inner_ethernet_ipv4() {
        hdr.ethernet = hdr.inner_ethernet;
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ethernet_ipv6() {
# 418 "npb/tunnel.p4"
    }

    action decap_inner_ethernet_non_ip() {
        hdr.ethernet = hdr.inner_ethernet;
        hdr.ipv4.setInvalid();
        hdr.ipv6.setInvalid();
        hdr.inner_ethernet.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv4() {
        copy_ipv4_header();
        hdr.ipv6.setInvalid();
        invalidate_tunneling_headers();
    }

    action decap_inner_ipv6() {






    }

    table decap_inner_ip {
        key = {
            hdr.inner_ethernet.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }

        actions = {
            decap_inner_ethernet_ipv4;
            decap_inner_ethernet_ipv6;
            decap_inner_ethernet_non_ip;
            decap_inner_ipv4;
            decap_inner_ipv6;
        }

        const entries = {
            (true, true, false) : decap_inner_ethernet_ipv4();
            (true, false, true) : decap_inner_ethernet_ipv6();
            (true, false, false) : decap_inner_ethernet_non_ip();
            (false, true, false) : decap_inner_ipv4();
            (false, false, true) : decap_inner_ipv6();
        }
    }

    apply {

        // Copy L4 headers into inner headers.
        decap_inner_l4.apply();
        // Copy L3 headers into inner headers.
        decap_inner_ip.apply();

    }
}

control TunnelRewrite(inout switch_header_t hdr,
                      inout switch_egress_metadata_t eg_md) {

    EgressBd(EGRESS_OUTER_BD_MAPPING_TABLE_SIZE,
             EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
    switch_bd_label_t bd_label;
    switch_smac_index_t smac_index;

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet.dst_addr = dmac;
    }

    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop : exact;
        }

        actions = {
            rewrite_tunnel;
        }
    }

    // Tunnel source IP rewrite
    action rewrite_ipv4_src(ipv4_addr_t src_addr) {
        hdr.ipv4.src_addr = src_addr;
    }

    action rewrite_ipv6_src(ipv6_addr_t src_addr) {



    }

    table src_addr_rewrite {
        key = { eg_md.bd : exact; }
        actions = {
            rewrite_ipv4_src;
            rewrite_ipv6_src;
        }

        // size = TUNNEL_SRC_REWRITE_TABLE_SIZE;
    }

    // Tunnel destination IP rewrite
    action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
        hdr.ipv4.dst_addr = dst_addr;
    }

    action rewrite_ipv6_dst(ipv6_addr_t dst_addr) {



    }

    table dst_addr_rewrite {
        key = { eg_md.tunnel.index : exact; }
        actions = {
            NoAction;
            rewrite_ipv4_dst;
            rewrite_ipv6_dst;
        }

        // size = TUNNEL_DST_REWRITE_TABLE_SIZE;
    }

    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet.src_addr = smac;
    }

    // --------------------- 
    // Extreme Added
    // ---------------------

    action rewrite_smac_nsh(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }

    table smac_rewrite {
//      key = { smac_index : exact; }
        key = {
   smac_index : exact;
   hdr.nsh_extr_underlay.isValid() : exact;
  }
        actions = {
            NoAction;
            rewrite_smac;

   rewrite_smac_nsh;
        }

        // size = TUNNEL_SMAC_REWRITE_TABLE_SIZE;
    }

    apply {

        nexthop_rewrite.apply();
        egress_bd.apply(
            hdr, eg_md.bd, eg_md.pkt_type, bd_label, smac_index, eg_md.checks.mtu);
        src_addr_rewrite.apply();
        dst_addr_rewrite.apply();
        smac_rewrite.apply();

    }
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
//
control TunnelEncap(inout switch_header_t hdr,
                    inout switch_egress_metadata_t eg_md)(
                    switch_tunnel_mode_t mode) {
    TunnelRewrite() rewrite;
    bit<16> payload_len;

    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        // size = VNI_MAPPING_TABLE_SIZE;
    }

    action copy_ipv4_header() {
        // Copy all of the IPv4 header fields.
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4.version = hdr.ipv4.version;
        hdr.inner_ipv4.ihl = hdr.ipv4.ihl;
        hdr.inner_ipv4.diffserv = hdr.ipv4.diffserv;
        hdr.inner_ipv4.total_len = hdr.ipv4.total_len;
        hdr.inner_ipv4.identification = hdr.ipv4.identification;
        hdr.inner_ipv4.flags = hdr.ipv4.flags;
        hdr.inner_ipv4.frag_offset = hdr.ipv4.frag_offset;
        hdr.inner_ipv4.ttl = hdr.ipv4.ttl;
        hdr.inner_ipv4.protocol = hdr.ipv4.protocol;
        // hdr.inner_ipv4.hdr_checksum = hdr.ipv4.hdr_checksum;
        hdr.inner_ipv4.src_addr = hdr.ipv4.src_addr;
        hdr.inner_ipv4.dst_addr = hdr.ipv4.dst_addr;
        hdr.ipv4.setInvalid();
    }

    action rewrite_inner_ipv4_udp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_udp = hdr.udp;
        hdr.udp.setInvalid();
    }

    action rewrite_inner_ipv4_tcp() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
        hdr.inner_tcp = hdr.tcp;
        hdr.tcp.setInvalid();
    }

    action rewrite_inner_ipv4_unknown() {
        payload_len = hdr.ipv4.total_len;
        copy_ipv4_header();
    }

    action rewrite_inner_ipv6_udp() {







    }

    action rewrite_inner_ipv6_tcp() {







    }

    action rewrite_inner_ipv6_unknown() {





    }


    //TODO(msharif): We only need to parse TCP if egress ACL is enabled.
    table encap_outer {
        key = {
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
            hdr.udp.isValid() : exact;
            // hdr.tcp.isValid() : exact;

   hdr.nsh_extr_underlay.isValid() : exact;
        }

        actions = {
            rewrite_inner_ipv4_udp;
            // rewrite_inner_ipv4_tcp;
            rewrite_inner_ipv4_unknown;
            rewrite_inner_ipv6_udp;
            // rewrite_inner_ipv6_tcp;
            rewrite_inner_ipv6_unknown;
        }

        const entries = {
//          (true, false, false) : rewrite_inner_ipv4_unknown();
//          (false, true, false) : rewrite_inner_ipv6_unknown();
//          (true, false, true) : rewrite_inner_ipv4_udp();
//          (false, true, true) : rewrite_inner_ipv6_udp();

            (true, false, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false, false) : rewrite_inner_ipv6_unknown();
            (true, false, true, false) : rewrite_inner_ipv4_udp();
            (false, true, true, false) : rewrite_inner_ipv6_udp();
        }
    }

//-----------------------------------------------------------------------------
// Helper actions to add various headers.
//-----------------------------------------------------------------------------
    action add_udp_header(bit<16> src_port, bit<16> dst_port) {
        hdr.udp.setValid();
        hdr.udp.src_port = src_port;
        hdr.udp.dst_port = dst_port;
        hdr.udp.checksum = 0;
        // hdr.udp.length = 0;
    }

    action add_vxlan_header(bit<24> vni) {

        hdr.vxlan.setValid();
        hdr.vxlan.flags = 8w0x08;
        hdr.vxlan.reserved = 0;
        hdr.vxlan.vni = vni;
        hdr.vxlan.reserved2 = 0;

    }

    action add_gre_header(bit<16> proto) {
# 749 "npb/tunnel.p4"
    }

    action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {

        hdr.erspan_type3.setValid();
        hdr.erspan_type3.timestamp = timestamp;
        hdr.erspan_type3.session_id = (bit<10>) session_id;
        hdr.erspan_type3.version = 4w0x2;
        hdr.erspan_type3.sgt = 0;
        hdr.erspan_type3.vlan = 0;

    }

    action add_ipv4_header(bit<8> proto) {
        hdr.ipv4.setValid();
        hdr.ipv4.version = 4w4;
        hdr.ipv4.ihl = 4w5;
        // hdr.ipv4.total_len = 0;
        hdr.ipv4.identification = 0;
        hdr.ipv4.flags = 0;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.protocol = proto;
        // hdr.ipv4.src_addr = 0;
        // hdr.ipv4.dst_addr = 0;

        if (mode == switch_tunnel_mode_t.UNIFORM) {
            // NoAction.
        } else if (mode == switch_tunnel_mode_t.PIPE) {
            hdr.ipv4.ttl = 8w64;
            hdr.ipv4.diffserv = 0;
        }
    }

    action add_ipv6_header(bit<8> proto) {
# 794 "npb/tunnel.p4"
    }

    action rewrite_ipv4_vxlan() {
        hdr.inner_ethernet = hdr.ethernet;
        add_ipv4_header(0x11);
        // Total length = packet length + 50
        //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.ipv4.total_len = payload_len + 16w50;

        add_udp_header(eg_md.tunnel.hash, 4789);
        // UDP length = packet length + 30
        //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
        hdr.udp.length = payload_len + 16w30;

        add_vxlan_header(eg_md.tunnel.id);
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_ipv4_ip() {
        add_ipv4_header(0x04);
        // Total length = packet length + 20
        //   IPv4 (20)
        hdr.ipv4.total_len = payload_len + 16w20;
        hdr.ethernet.ether_type = 0x0800;
    }

    action rewrite_ipv6_vxlan() {
# 836 "npb/tunnel.p4"
    }

    action rewrite_ipv6_ip() {






    }

    // --------------------- 
    // Extreme Added
    // ---------------------

    action rewrite_mac_in_mac_nsh() {
        hdr.ethernet_underlay.setValid();

        hdr.ethernet_underlay.ether_type = 0x894F;
    }

    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            rewrite_ipv4_vxlan;
            rewrite_ipv6_vxlan;
            rewrite_ipv4_ip;
            rewrite_ipv6_ip;

   rewrite_mac_in_mac_nsh;
        }

        const default_action = NoAction;
        const entries = {
            SWITCH_TUNNEL_TYPE_VXLAN : rewrite_ipv4_vxlan();
            SWITCH_TUNNEL_TYPE_IPINIP : rewrite_ipv4_ip();

   SWITCH_TUNNEL_TYPE_MACINMAC_NSH : rewrite_mac_in_mac_nsh();
        }
    }

    apply {

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0)
            bd_to_vni_mapping.apply();

        if (eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
            // Copy L3/L4 header into inner headers.
            encap_outer.apply();

            // Add outer L3/L4/Tunnel headers.
            tunnel.apply();

            rewrite.apply(hdr, eg_md);
        }

    }
}
# 50 "npb/npb.p4" 2
# 1 "npb/multicast.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/




//-----------------------------------------------------------------------------
// IP Multicast
// @param src_addr : IP source address.
// @param grp_addr : IP group address.
// @param bd : Bridge domain.
// @param group_id : Multicast group id.
// @param s_g_table_size : (s, g) table size.
// @param star_g_table_size : (*, g) table size.
//-----------------------------------------------------------------------------
control MulticastBridge<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {

        switch(s_g.apply().action_run) {
            NoAction : { star_g.apply(); }
        }

    }
}

control MulticastBridgev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_bd_t bd,
        out switch_mgid_t group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {
    action s_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_hit(switch_mgid_t mgid) {
        group_id = mgid;
        multicast_hit = 1;
    }

    action star_g_miss() {
        multicast_hit = 0;
    }

    table s_g {
        key = {
            bd : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
    }

    table star_g {
        key = {
            bd : exact;
            grp_addr : exact;
        }

        actions = {
            star_g_miss;
            star_g_hit;
        }

        const default_action = star_g_miss;
        size = star_g_table_size;
    }

    apply {

        switch(s_g.apply().action_run) {
            NoAction : { star_g.apply(); }
        }

    }
}

control MulticastRoute<T>(
        in ipv4_addr_t src_addr,
        in ipv4_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;

    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        s_g_stats.count();
    }

    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check != 0
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }

    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }

    apply {

        if (!s_g.apply().hit) {
            star_g.apply();
        }

    }
}


control MulticastRoutev6<T>(
        in ipv6_addr_t src_addr,
        in ipv6_addr_t grp_addr,
        in switch_vrf_t vrf,
        inout switch_multicast_metadata_t multicast_md,
        out switch_multicast_rpf_group_t rpf_check,
        out switch_mgid_t multicast_group_id,
        out bit<1> multicast_hit)(
        switch_uint32_t s_g_table_size,
        switch_uint32_t star_g_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) s_g_stats;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) star_g_stats;

    action s_g_hit(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        s_g_stats.count();
    }

    action star_g_hit_bidir(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check != 0
        rpf_check = rpf_group & multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_BIDIR;
        star_g_stats.count();
    }

    action star_g_hit_sm(
            switch_mgid_t mgid, switch_multicast_rpf_group_t rpf_group) {
        multicast_group_id = mgid;
        multicast_hit = 1;
        // rpf check passes if rpf_check == 0
        rpf_check = rpf_group ^ multicast_md.rpf_group;
        multicast_md.mode = SWITCH_MULTICAST_MODE_PIM_SM;
        star_g_stats.count();
    }

    // Source and Group address pair (S, G) lookup
    table s_g {
        key = {
            vrf : exact;
            src_addr : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            s_g_hit;
        }

        const default_action = NoAction;
        size = s_g_table_size;
        counters = s_g_stats;
    }

    // Group address (*, G) lookup
    table star_g {
        key = {
            vrf : exact;
            grp_addr : exact;
        }

        actions = {
            @defaultonly NoAction;
            star_g_hit_sm;
            star_g_hit_bidir;
        }

        const default_action = NoAction;
        size = star_g_table_size;
        counters = star_g_stats;
    }

    apply {

        if (!s_g.apply().hit) {
            star_g.apply();
        }

    }
}

control IngressMulticast(
        in switch_lookup_fields_t lkp,
        inout switch_ingress_metadata_t ig_md,
        out switch_mgid_t group_id)(
        switch_uint32_t ipv4_s_g_table_size,
        switch_uint32_t ipv4_star_g_table_size,
        switch_uint32_t ipv6_s_g_table_size,
        switch_uint32_t ipv6_star_g_table_size) {

    // For each rendezvous point (RP), there is a list of interfaces for which
    // the switch is the designated forwarder (DF).

    MulticastBridge<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_bridge;
    MulticastRoute<ipv4_addr_t>(ipv4_s_g_table_size, ipv4_star_g_table_size) ipv4_multicast_route;
    MulticastBridgev6<ipv6_addr_t>(
        ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_bridge;
    MulticastRoutev6<ipv6_addr_t>(ipv6_s_g_table_size, ipv6_star_g_table_size) ipv6_multicast_route;

    switch_multicast_rpf_group_t rpf_check;
    bit<1> multicast_hit;

    action set_multicast_route() {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
        ig_md.flags.flood_to_multicast_routers = false;
        ig_md.checks.same_bd = 0x3fff;
    }

    action set_multicast_bridge(bool mrpf) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = false;
    }

    action set_multicast_flood(bool mrpf, bool flood) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;
    }

    table fwd_result {
        key = {
            multicast_hit : ternary;
            lkp.ip_type : ternary;
            ig_md.ipv4_md.multicast_snooping : ternary;
            ig_md.ipv6_md.multicast_snooping : ternary;
            ig_md.multicast.mode : ternary;
            rpf_check : ternary;
        }

        actions = {
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
        }
    }

    apply {

        if (lkp.ip_type == SWITCH_IP_TYPE_IPV4 && ig_md.ipv4_md.multicast_enable) {
            ipv4_multicast_route.apply(lkp.ipv4_src_addr,
                                       lkp.ipv4_dst_addr,
                                       ig_md.vrf,
                                       ig_md.multicast,
                                       rpf_check,
                                       group_id,
                                       multicast_hit);
        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6 && ig_md.ipv6_md.multicast_enable) {
# 420 "npb/multicast.p4"
        }

        if (multicast_hit == 0 ||
            (ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_SM && rpf_check != 0) ||
            (ig_md.multicast.mode == SWITCH_MULTICAST_MODE_PIM_BIDIR && rpf_check == 0)) {

            if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
                ipv4_multicast_bridge.apply(lkp.ipv4_src_addr,
                                            lkp.ipv4_dst_addr,
                                            ig_md.bd,
                                            group_id,
                                            multicast_hit);
            } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {







            }
        }

        fwd_result.apply();

    }
}


//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
control MulticastFlooding(
        in switch_pkt_type_t pkt_type,
        in switch_bd_t bd,
        in bool flood_to_multicast_routers,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size) {
    action flood(switch_mgid_t mgid) {
        ig_intr_md_for_tm.mcast_grp_b = mgid;
    }

    table bd_flood {
        key = {
            bd : exact;
            pkt_type : exact;
            flood_to_multicast_routers : exact;
        }

        actions = { flood; }
        size = table_size;
    }

    apply {
        bd_flood.apply();
    }
}

control MulticastReplication(in switch_rid_t replication_id,
                             in switch_port_t port,
                             inout switch_egress_metadata_t eg_md)(
                             switch_uint32_t table_size=4096) {
    action rid_hit(switch_bd_t bd) {
        eg_md.checks.same_bd = bd ^ eg_md.bd;
        eg_md.bd = bd;
    }

    action rid_miss() {
        eg_md.flags.routed = false;
    }

    table rid {
        key = { replication_id : exact; }
        actions = {
            rid_miss;
            rid_hit;
        }

        size = table_size;
        const default_action = rid_miss;
    }

    apply {

        if (replication_id != 0)
            rid.apply();

        if (eg_md.checks.same_bd == 0)
            eg_md.flags.routed = false;

    }
}
# 51 "npb/npb.p4" 2
# 1 "npb/qos.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 *
 ******************************************************************************/




# 1 "npb/acl.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/
# 28 "npb/qos.p4" 2
# 1 "npb/meter.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/




//-------------------------------------------------------------------------------------------------
// Ingress Policer
//
// Monitors the data rate for a particular class of service and drops the traffic
// when the rate exceeds a user-defined thresholds.
//
// @param ig_md : Ingress metadata fields.
// @param qos_md : QoS related metadata fields.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the ingress policer table.
//-------------------------------------------------------------------------------------------------
control IngressPolicer(in switch_ingress_metadata_t ig_md,
                       inout switch_qos_metadata_t qos_md,
                       out bool flag)(
                       switch_uint32_t table_size=1024) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) stats;
    DirectMeter(MeterType_t.BYTES) meter;

    // Requires 3 entries per meter index for unicast/broadcast/multicast packets.
    //XXX compiler fails with error : Cannot evaluate initializer to a compiler-time constant.
    // const switch_uint32_t meter_action_table_size = 3 * table_size;

    action meter_deny() {
        stats.count();
        flag = true;
    }

    action meter_permit() {
        stats.count();
        flag = false;
    }

    table meter_action {
        key = {
            qos_md.color : exact;
            qos_md.meter_index : exact;
        }

        actions = {
            meter_permit;
            meter_deny;
        }

        const default_action = meter_permit;
        // size = meter_action_table_size;
        counters = stats;
    }

    action set_color() {
        qos_md.color = (bit<2>) meter.execute();
    }

    table meter_index {
        key = {
            qos_md.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            set_color;
        }

        const default_action = NoAction;
        size = table_size;
        meters = meter;
    }

    apply {







    }
}

//-------------------------------------------------------------------------------------------------
// Storm Control
//
// Monitors incoming traffic and prevents the excessive traffic on a particular interface by
// dropping the traffic. Each port has a single storm control levels for all types of traffic
// (broadcast, multicast, and unicast).
//
// @param ig_md : Ingress metadata fields
// @param pkt_type : One of Unicast, Multicast, or Broadcast packet types.
// @param flag : Indicating whether the packet should get dropped or not.
// @param table_size : Size of the storm control table.
//-------------------------------------------------------------------------------------------------
control StormControl(in switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=512) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(table_size, MeterType_t.BYTES) meter;
    switch_pkt_color_t color;

    action count() {
        storm_control_stats.count();
        flag = false;
    }

    action drop_and_count() {
        storm_control_stats.count();
        flag = true;
    }

    table stats {
        key = {
            color: exact;
            pkt_type : ternary;
            ig_md.port: exact;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        color = (bit<2>) meter.execute(index);
    }

    //TODO(msharif) : Only apply this for unknown unicast packets (SWI-1610)
    @name(".storm_control")
    table storm_control {
        key = {
            ig_md.port : exact;
            pkt_type : ternary;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {







    }
}
# 29 "npb/qos.p4" 2

//-----------------------------------------------------------------------------
// Common QoS related actions used by QoS ACL slices or QoS dscp/pcp mappings.
//-----------------------------------------------------------------------------
action set_ingress_tc(inout switch_qos_metadata_t qos_md, switch_tc_t tc) {
    qos_md.tc = tc;
}

action set_ingress_color(inout switch_qos_metadata_t qos_md, switch_pkt_color_t color) {
    qos_md.color = color;
}

action set_ingress_tc_and_color(
        inout switch_qos_metadata_t qos_md, switch_tc_t tc, switch_pkt_color_t color) {
    set_ingress_tc(qos_md, tc);
    set_ingress_color(qos_md, color);
}

action set_ingress_tc_color_and_meter(
        inout switch_qos_metadata_t qos_md,
        switch_tc_t tc,
        switch_pkt_color_t color,
        switch_policer_meter_index_t index) {




}

control MacQosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary;
            ig_md.port_lag_label : ternary;
            lkp.pcp : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv4QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ipv4_src_addr : ternary; lkp.ipv4_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control Ipv6QosAcl(
    in switch_lookup_fields_t lkp,
    inout switch_qos_metadata_t qos_md,
    inout switch_ingress_metadata_t ig_md)(
    switch_uint32_t table_size=512) {

    table acl {
        key = {
            lkp.ipv6_src_addr : ternary; lkp.ipv6_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.ip_ttl : ternary; lkp.tcp_flags : ternary;
            ig_md.port_lag_label : ternary;
            ig_md.bd_label : ternary;
            ig_md.l4_port_label : ternary;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = table_size;
    }

    apply {
        acl.apply();
    }
}

control IngressQos(
        in switch_header_t hdr,
        in switch_lookup_fields_t lkp,
        inout switch_qos_metadata_t qos_md,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t dscp_map_size=1024,
        switch_uint32_t pcp_map_size=1024) {

    const bit<32> ppg_table_size = 1024;
    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ppg_stats;
    IngressPolicer(1 << 10) policer;
    MacQosAcl() mac_acl;
    Ipv4QosAcl() ipv4_acl;
    Ipv6QosAcl() ipv6_acl;

    table dscp_tc_map {
        key = {
            qos_md.group : exact;
            lkp.ip_tos : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = dscp_map_size;
    }

    table pcp_tc_map {
        key = {
            qos_md.group : exact;
            lkp.pcp : exact;
        }

        actions = {
            NoAction;
            set_ingress_tc(qos_md);
            set_ingress_color(qos_md);
            set_ingress_tc_and_color(qos_md);
            set_ingress_tc_color_and_meter(qos_md);
        }

        size = pcp_map_size;
    }


    action set_icos(switch_cos_t icos) {
        ig_intr_md_for_tm.ingress_cos = icos;
    }

    action set_queue(switch_qid_t qid) {
        ig_intr_md_for_tm.qid = qid;
    }

    action set_icos_and_queue(switch_cos_t icos, switch_qid_t qid) {
        set_icos(icos);
        set_queue(qid);
    }

    table traffic_class {
        key = {
            ig_md.port : ternary;
            qos_md.color : ternary;
            qos_md.tc : exact;
        }

        actions = {
            set_icos;
            set_queue;
            set_icos_and_queue;
        }

        size = queue_table_size;
    }

    action count() {
        ppg_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and cos pair.
    table ppg {
        key = {
            ig_md.port : exact @name("port");
            ig_intr_md_for_tm.ingress_cos : exact @name("icos");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        const default_action = NoAction;
        size = ppg_table_size;
        counters = ppg_stats;
    }

    apply {
# 280 "npb/qos.p4"
    }
}


control EgressQos(inout switch_header_t hdr,
                  in switch_port_t port,
                  in switch_qos_metadata_t qos_md)(
                  switch_uint32_t table_size=1024) {

    const bit<32> queue_table_size = 1024;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) queue_stats;

    // Overwrites 6-bit dscp only.
    action set_ipv4_dscp(bit<6> dscp) {
        hdr.ipv4.diffserv[7:2] = dscp;
    }

    action set_ipv4_tos(switch_uint8_t tos) {
        hdr.ipv4.diffserv = tos;
    }

    // Overwrites 6-bit dscp only.
    action set_ipv6_dscp(bit<6> dscp) {



    }

    action set_ipv6_tos(switch_uint8_t tos) {



    }

    action set_vlan_pcp(bit<3> pcp) {
        hdr.vlan_tag[0].pcp = pcp;
    }

    table qos_map {
        key = {
            qos_md.group : exact;
            qos_md.tc : exact;
            qos_md.color : exact;
            hdr.ipv4.isValid() : exact;
            hdr.ipv6.isValid() : exact;
        }

        actions = {
            NoAction;
            set_ipv4_dscp;
            set_ipv4_tos;
            set_ipv6_dscp;
            set_ipv6_tos;
            set_vlan_pcp;
        }

        const default_action = NoAction;
        size = table_size;
    }

    action count() {
        queue_stats.count();
    }

    // Asymmetric table to maintain statistics per local port and queue pair. This table does NOT
    // take care of packets that get dropped or sent to cpu by system acl.
    table queue {
        key = {
            port : exact;
            qos_md.qid : exact @name("qid");
        }

        actions = {
            @defaultonly NoAction;
            count;
        }

        size = queue_table_size;
        const default_action = NoAction;
        counters = queue_stats;
    }

    apply {




    }
}
# 52 "npb/npb.p4" 2
# 1 "npb/meter.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/
# 53 "npb/npb.p4" 2
# 1 "npb/wred.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * Milad Sharif (msharif@barefootnetworks.com)
 *
 ******************************************************************************/

//-------------------------------------------------------------------------------------------------
// ECN Access control list
//
// @param ig_md : Ingress metadata fields.
// @param lkp : Lookup fields.
// @param qos_md : QoS metadata fields.
// @param table_size : Size of the ACL table.
//-------------------------------------------------------------------------------------------------
control EcnAcl(in switch_ingress_metadata_t ig_md,
               in switch_lookup_fields_t lkp,
               inout switch_qos_metadata_t qos_md)(
               switch_uint32_t table_size=512) {
    action set_ingress_color(switch_pkt_color_t color) {
        qos_md.color = color;
    }

    table acl {
        key = {
            ig_md.port_lag_label : ternary;
            lkp.ip_tos : ternary;
            lkp.tcp_flags : ternary;
        }

        actions = {
            NoAction;
            set_ingress_color;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        acl.apply();
    }
}

//-------------------------------------------------------------------------------------------------
// Weighted Random Early Dropping (WRED)
//
// @param hdr : Parse headers. Only ipv4.diffserv or ipv6.traffic_class are modified.
// @param eg_md : Egress metadata fields.
// @param qos_md
// @param eg_intr_md
// @param wred_sie : Number of WRED profiles.
//-------------------------------------------------------------------------------------------------
control WRED(inout switch_header_t hdr,
             in switch_qos_metadata_t qos_md,
             in egress_intrinsic_metadata_t eg_intr_md,
             out bool flag) {

    switch_wred_index_t index;
    switch_wred_stats_index_t stats_index;
    bit<1> drop_flag;
    const switch_uint32_t wred_size = 1 << 8;
    // Per color/qid/port counter.
    const switch_uint32_t wred_index_table_size = 8192;

    Counter<bit<32>, switch_wred_stats_index_t>(
        wred_index_table_size, CounterType_t.PACKETS_AND_BYTES) wred_stats;

    Wred<bit<19>, switch_wred_index_t>(wred_size, 1 /* drop value*/, 0 /* no drop value */) wred;

    action set_ipv4_ecn() {
        hdr.ipv4.diffserv[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_stats.count(stats_index);
    }

    action set_ipv6_ecn() {
        hdr.ipv6.traffic_class[1:0] = SWITCH_ECN_CODEPOINT_CE;
        wred_stats.count(stats_index);
    }

    action drop() {
        flag = true;
    }

    // Packets from flows that are not ECN capable will continue to be dropped by RED (as was the
    // case before ECN) -- RFC2884
    table wred_action {
        key = {
            index : exact;
            hdr.ipv4.isValid() : ternary;
            hdr.ipv4.diffserv : ternary;
            hdr.ipv6.isValid() : ternary;
            hdr.ipv6.traffic_class : ternary;
        }

        actions = {
            NoAction;
            drop;
            set_ipv4_ecn;
            set_ipv6_ecn;
        }

        // Requires 4 entries per WRED profile to drop or mark IPv4/v6 packets.
        size = 4 * wred_size;
    }

    action set_wred_index(switch_wred_index_t wred_index,
                          switch_wred_stats_index_t wred_stats_index) {
        index = wred_index;
        stats_index = wred_stats_index;
        drop_flag = (bit<1>) wred.execute(eg_intr_md.enq_qdepth, wred_index);
    }

    table wred_index {
        key = {
           eg_intr_md.egress_port : exact;
           qos_md.qid : exact;
           qos_md.color : exact;
        }

        actions = {
            NoAction;
            set_wred_index;
        }

        const default_action = NoAction;
        size = wred_index_table_size;
    }

    apply {






    }
}
# 54 "npb/npb.p4" 2

// -----------------------------
// ----- EXTREME NETWORKS -----
// -----------------------------

# 1 "npb/npb_ing_sfc_top.p4" 1

control npb_ing_sfc_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in switch_lookup_fields_t lkp
) {

 bit<8> service_func_chain_;

 // =========================================================================
 // Table #1:
 //
 // Type: Normal
 // 
 // Function: tenantId and protocol --> flowType
 // =========================================================================

 action table_1_hit (
  bit<8> flow_type
 ) {
  // ext type 1 - word 0
  ig_md.nsh_extr.extr_flow_type = flow_type;
 }

 // ---------------------------------

 table table_1 {
  key = {
   // l3
   lkp.ip_type : exact;
   lkp.ip_proto : exact;

   ig_md.nsh_extr.extr_tenant_id : exact;
  }

  actions = {
   NoAction;
   table_1_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_FLOW_TYPE_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #2:
 //
 // Type: Normal
 // 
 // Function: tenantId and flowType --> sfc and nsh header
 // =========================================================================

 action table_2_hit (
  bit<8> nsh_sph_si,

  bit<8> srvc_func_bitmask_local,
  bit<8> srvc_func_bitmask_remote,

  bit<8> service_func_chain
 ) {
  // base - word 0

  // base - word 1
  ig_md.nsh_extr.si = nsh_sph_si;

  // ext type 1 - word 0
  ig_md.nsh_extr.extr_srvc_func_bitmask_local = srvc_func_bitmask_local;
  ig_md.nsh_extr.extr_srvc_func_bitmask_remote = srvc_func_bitmask_remote;
//		ig_md.nsh_extr.extr_tenant_id                = ig_md.tunnel.id;
  ig_md.nsh_extr.extr_tenant_id = (bit<24>)ig_md.bd;

  // change metadata
  service_func_chain_ = service_func_chain;
 }

 // ---------------------------------

 table table_2 {
  key = {
   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;
  }

  actions = {
   NoAction;
   table_2_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_NSH_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #3:
 //
 // Type: Action Selector
 // 
 // Function: tenantId, flowType, and sfc --> nsh header
 // =========================================================================
# 115 "npb/npb_ing_sfc_top.p4"
 // ---------------------------------

 action table_3_hit (
  bit<24> nsh_sph_spi
 ) {
  ig_md.nsh_extr.valid = 1;

  // base - word 1
  ig_md.nsh_extr.spi = nsh_sph_spi;
 }

 // ---------------------------------

 table table_3 {
  key = {
   service_func_chain_ : exact;




   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;

  }

  actions = {
   NoAction;
   table_3_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFC_SCHD_TABLE_PART1_DEPTH;




 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  if(hdr.nsh_extr_underlay.isValid()) {

   // ***** Packet has an NSH header on it *****

   ig_md.nsh_extr.valid = 1;

   // base: word 0

   // base: word 1
   ig_md.nsh_extr.spi = hdr.nsh_extr_underlay.spi;
   ig_md.nsh_extr.si = hdr.nsh_extr_underlay.si;

   // ext: type 2 - word 0

   // ext: type 2 - word 1+
   ig_md.nsh_extr.extr_srvc_func_bitmask_local = hdr.nsh_extr_underlay.extr_srvc_func_bitmask; //  1 byte
   ig_md.nsh_extr.extr_tenant_id = hdr.nsh_extr_underlay.extr_tenant_id; //  3 bytes
   ig_md.nsh_extr.extr_flow_type = hdr.nsh_extr_underlay.extr_flow_type; //  1 byte?

  } else {

   // ***** Packet does NOT have an NSH header on it *****

   if(table_1.apply().hit) {

    if(table_2.apply().hit) {

     table_3.apply();
    }

   }

  }

 }

}
# 60 "npb/npb.p4" 2
# 1 "npb/npb_ing_sff_top.p4" 1
# 1 "npb/npb_ing_sf_npb_basic_adv_top.p4" 1
# 1 "npb/npb_ing_sf_npb_basic_adv_dedup.p4" 1
/* -*- P4_16 -*- */




// *****************************************************************************
// Example register code, taken from "P4 Language Cheat Sheet"
// *****************************************************************************

struct pair_t {
 bit<16> hash;
 bit<16> data;
};

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
 in switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 bit<32> flowtable_hash;
 bit<16> flowtable_hash_hi;
 bit<16> flowtable_hash_lo;

 // =========================================================================
 // The Register Array
 // =========================================================================

 Register<pair_t, bit<32>>(32w1024) test_reg; // syntax seems to be <data type, index type>

 RegisterAction<pair_t, bit<32>, bit<8>>(test_reg) test_reg_action = { // syntax seems to be <data type, index type, return type>
  void apply(
   inout pair_t reg_value, // register entry
   out bit<8> return_value // return value
  ) {
   // check entry
   if((reg_value.hash == flowtable_hash[31:16]) && (reg_value.data != (bit<16>)ig_intr_md.ingress_port)) {
    return_value = 1; // drop packet
   } else {
    return_value = 0; // pass packet
   }

/*
			return_value = (bit<8>)((bit<1>)((bit<16>)flowtable_hash[31:16]   - reg_value.hash == 0) &
			                        (bit<1>)((bit<16>)ig_intr_md.ingress_port - reg_value.data != 0));
*/

   // update entry
   reg_value.hash = (bit<16>)(flowtable_hash[31:16]);
   reg_value.data = (bit<16>)(ig_intr_md.ingress_port);
  }
 };

 // =========================================================================
 // The Hash Function
 // =========================================================================

 Hash<bit<32>>(HashAlgorithm_t.CRC32) h;

 // =========================================================================
 // The Apply Block
 // =========================================================================

 apply {

  bit<8> return_value;

  // ***** hash the key *****
  flowtable_hash = h.get({hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol, hdr.tcp.src_port, hdr.tcp.dst_port});

  flowtable_hash_hi = flowtable_hash[31:16];
  flowtable_hash_lo = flowtable_hash[15: 0];

  // ***** use hashed key to index register *****
  return_value = test_reg_action.execute((bit<32>)flowtable_hash_lo);

  // ***** drop packet? *****
  if(return_value != 0) {
   ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
  }

 }

}
# 2 "npb/npb_ing_sf_npb_basic_adv_top.p4" 2

control npb_ing_sf_npb_basic_adv_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in switch_lookup_fields_t lkp
) {

 bit<8> flow_type_new;

 bit<8> nsh_sph_si_new;

 bit<8> nsh_srvc_func_bitmask_local_new;
 bit<8> nsh_srvc_func_bitmask_remote_new;

 bit<8> service_func_chain_;

 bit<1> action_bitmask_;

 // =========================================================================
 // Table #1:
 //
 // Type: Normal
 // 
 // Function: tenantId and 5-tuple --> flowType and sfc
 // =========================================================================

 action table_1_hit (
  bit<8> flow_type,

  bit<8> nsh_sph_si,

  bit<8> srvc_func_bitmask_local,
  bit<8> srvc_func_bitmask_remote,

  bit<8> service_func_chain,

  bit<1> action_bitmask,
  bit<3> discard
 ) {
  // change nsh

  // change metadata
  flow_type_new = flow_type;

  // base - word 1
  nsh_sph_si_new = nsh_sph_si;

  // ext type 1 - word 0
  nsh_srvc_func_bitmask_local_new = srvc_func_bitmask_local;
  nsh_srvc_func_bitmask_remote_new = srvc_func_bitmask_remote;

  // change metadata
  service_func_chain_ = service_func_chain;

  action_bitmask_ = action_bitmask;
  ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet
 }

 // ---------------------------------
 // v4 exact
 // ---------------------------------

 table table_1_v4_exact {
  key = {
   // l3
            lkp.ip_type : exact;
   lkp.ip_proto : exact;
   lkp.ipv4_src_addr : exact;
   lkp.ipv4_dst_addr : exact;

   // l4
   lkp.l4_src_port : exact;
   lkp.l4_dst_port : exact;

   ig_md.nsh_extr.extr_tenant_id : exact;
  }

  actions = {
   NoAction;
   table_1_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_BAS_ADV_POLICY_V4_EXACT_MATCH_TABLE_DEPTH;
 }

 // ---------------------------------
 // v4 lpm
 // ---------------------------------

 table table_1_v4_lpm {
  key = {
   // l3
            lkp.ip_type : exact;
   lkp.ip_proto : exact;
   lkp.ipv4_src_addr : exact;
   lkp.ipv4_dst_addr : exact;

   // l4
   lkp.l4_src_port : exact;
   lkp.l4_dst_port : exact;

   ig_md.nsh_extr.extr_tenant_id : exact;
  }

  actions = {
   NoAction;
   table_1_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SF_BAS_ADV_POLICY_V4_LPM_TABLE_DEPTH;
 }


 // ---------------------------------
 // v6 exact
 // ---------------------------------
# 152 "npb/npb_ing_sf_npb_basic_adv_top.p4"
 // ---------------------------------
 // v6 lpm
 // ---------------------------------
# 182 "npb/npb_ing_sf_npb_basic_adv_top.p4"
 // =========================================================================
 // Table #3:
 //
 // Type: Action Selector
 // 
 // Function: tenantId, flowType, and sfc --> nsh header
 // =========================================================================
# 199 "npb/npb_ing_sf_npb_basic_adv_top.p4"
 // ---------------------------------

 action table_3_hit (
  bit<24> nsh_sph_path_identifier
 ) {
  // change nsh

  // change metadata
  ig_md.nsh_extr.extr_flow_type = flow_type_new;

  // base - word 1
  ig_md.nsh_extr.spi = nsh_sph_path_identifier;
  ig_md.nsh_extr.si = nsh_sph_si_new;

  // ext type 1 - word 0
  ig_md.nsh_extr.extr_srvc_func_bitmask_local = nsh_srvc_func_bitmask_local_new;
  ig_md.nsh_extr.extr_srvc_func_bitmask_remote = nsh_srvc_func_bitmask_remote_new;
 }

 // ---------------------------------

 action table_3_miss (
 ) {
  // TODO: what should be do on a miss????
 }

 // ---------------------------------

 table table_3 {
  key = {
   service_func_chain_ : exact;




   ig_md.nsh_extr.extr_tenant_id : exact;
   ig_md.nsh_extr.extr_flow_type : exact;

  }

  actions = {
   NoAction;
   table_3_hit;
   table_3_miss;
  }

  const default_action = table_3_miss;
  size = NPB_ING_SF_BAS_ADV_SCHD_TABLE_PART1_DEPTH;




 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  ig_md.nsh_extr.si = ig_md.nsh_extr.si - 1; // decrement sp_index

  // -------------------------------------
  // Action Lookup
  // -------------------------------------

  if(lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   if (!table_1_v4_exact.apply().hit) {
    table_1_v4_lpm.apply();
   }






  }

  // -------------------------------------
  // Action(s)
  // -------------------------------------

  if(action_bitmask_[0:0] == 1) {

   // -------------------------------------
   // Action #0
   // -------------------------------------

/*
			npb_ing_sf_npb_basic_adv_dedup.apply (
				hdr,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
*/
  }

  table_3.apply();

 }

}
# 2 "npb/npb_ing_sff_top.p4" 2
//#include "npb_ing_sf_repli_top.p4"

control npb_ing_sff_top (
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in switch_lookup_fields_t lkp
) {

 // Derek TODO:
 //
 // What should be the default action on a miss -- the l2 miss action, or the
 // l3 miss action?  It seems like anything that got here would have been
 // addressed to us, so I'm thinking the l3 miss action....

 // =========================================================================
 // Table  - EXACT MATCH
 //   - Key    = SPI, SI, ?
 //   - Result = service_func_bitmask
 // =========================================================================

 // =====================================
 // L2 Actions
 // =====================================

 action dmac_miss(
 ) {
  ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;

  ig_md.nsh_extr.end_of_chain = 1;
 }

 // =====================================

 action dmac_hit(
  switch_ifindex_t ifindex,
  switch_port_lag_index_t port_lag_index,

  bit<1> end_of_chain
 ) {
  ig_md.egress_ifindex = ifindex;
  ig_md.egress_port_lag_index = port_lag_index;
  ig_md.checks.same_if = ig_md.ifindex ^ ifindex;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action dmac_multicast(
  switch_mgid_t index,

  bit<1> end_of_chain
 ) {
  ig_intr_md_for_tm.mcast_grp_b = index;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action dmac_redirect(
  switch_nexthop_t nexthop_index,

  bit<1> end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action dmac_drop(
  bit<1> end_of_chain
 ) {
  //TODO(msharif): Drop the packet.

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================
 // L3 Unicast Actions
 // =====================================

 action fib_hit(
  switch_nexthop_t nexthop_index,

  bit<1> end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;
  ig_md.flags.routed = true;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================

 action fib_miss(
 ) {
  ig_md.flags.routed = false;

  ig_md.nsh_extr.end_of_chain = 1;
 }

 // =====================================

 action fib_myip(
  bit<1> end_of_chain
 ) {
  ig_md.flags.myip = true;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
 }

 // =====================================
 // L3 Multicast Actions
 // =====================================

    action set_multicast_route(
  switch_multicast_mode_t mode,
  switch_mgid_t index,
  bit<1> end_of_chain
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
        ig_md.flags.flood_to_multicast_routers = false;
        ig_md.checks.same_bd = 0x3fff;

  ig_md.multicast.mode = mode;
  ig_intr_md_for_tm.mcast_grp_b = index;
  ig_md.nsh_extr.end_of_chain = end_of_chain;
    }

 // =====================================

    action set_multicast_bridge(
  bool mrpf,

  switch_mgid_t index,
  bit<1> end_of_chain
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = false;

  ig_intr_md_for_tm.mcast_grp_b = index;
  ig_md.nsh_extr.end_of_chain = end_of_chain;
    }

 // =====================================

    action set_multicast_flood(
  bool mrpf,
  bool flood,

  bit<1> end_of_chain
 ) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;

  ig_md.nsh_extr.end_of_chain = end_of_chain;
    }

 // =====================================
 // Table
 // =====================================

 table table_1 {
  key = {
   ig_md.nsh_extr.spi : exact;
   ig_md.nsh_extr.si : exact;
  }

  actions = {
   // l2 actions
   dmac_miss;
   dmac_hit;
   dmac_multicast;
   dmac_redirect;
   dmac_drop;

   // l3 unicast actions
   fib_miss;
   fib_hit;
   fib_myip;

   // l3 multicast actions
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
  }

//		const default_action = dmac_miss;
  const default_action = fib_miss;
  size = NPB_ING_SFF_TABLE_DEPTH;
 }

 // =========================================================================
 // Table  - EXACT MATCH
 // 
 // TTL Decrement
 // =========================================================================

/*
    action new_ttl(bit<6> ttl) {
        ig_md.nsh_extr.ttl = ttl;
    }

    action discard() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
    }

    table dec_ttl {
        key = { ig_md.nsh_extr.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0  : new_ttl(63);
            1  : discard();
            2  : new_ttl(1);
            3  : new_ttl(2);
            4  : new_ttl(3);
            5  : new_ttl(4);
            6  : new_ttl(5);
            7  : new_ttl(6);
            8  : new_ttl(7);
            9  : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }
*/

 // =========================================================================
 // Apply
 // =========================================================================

 // Need to do two table lookups here?
 //
 // 1: service func lookup to get sf bitmask.
 // 2: forwarding lookup, after any sf's have reclassified the packet.

 apply {

  if(ig_md.nsh_extr.valid == 1) {

   // -------------------------------------
   // Decrement and Check TTL
   // -------------------------------------

   // Note: according to RFC: "each SFF MUST decrement the TTL value
   // "prior to the NSH forwarding lookup".

//        	dec_ttl.apply();

/*
			// -------------------------------------
			// Forwarding Lookup
			// -------------------------------------

			// table here:

			table_1.apply();
*/

   // -------------------------------------
   // SF(s)
   // -------------------------------------

   if(ig_md.nsh_extr.extr_srvc_func_bitmask_local[0:0] == 1) {

    // -------------------------------------
    // SF #0
    // -------------------------------------

    npb_ing_sf_npb_basic_adv_top.apply (
     hdr,
     ig_md,
     ig_intr_md,
     ig_intr_md_from_prsr,
     ig_intr_md_for_dprsr,
     ig_intr_md_for_tm,

     lkp
    );

    // check sp index
    if(ig_md.nsh_extr.si == 0) {
     ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
    }
   }

   // -------------------------------------
   // Forwarding Lookup
   // -------------------------------------

   // table here:

   table_1.apply();

  }

 }

}
# 61 "npb/npb.p4" 2

# 1 "npb/npb_egr_sff_top.p4" 1
# 1 "npb/npb_egr_sf_proxy_top.p4" 1
# 1 "npb/npb_egr_sf_proxy_act_sel.p4" 1

control npb_egr_sf_proxy_act_sel (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,

 out bit<4> action_bitmask_,
 out bit<10> meter_id_,
 out bit<8> meter_overhead_
) {

 // =========================================================================
 // Table
 //
 // Function: spi and si --> actions
 // =========================================================================

 action hit(
  bit<4> action_bitmask,
  bit<10> meter_id,
  bit<8> meter_overhead,
  bit<3> discard
 ) {
  action_bitmask_ = action_bitmask;

  meter_id_ = meter_id;
  meter_overhead_ = meter_overhead;

  eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet

 }

 // =====================================

 action miss(
 ) {
  action_bitmask_ = 0;
 }

 // =====================================

 table myTable {
  key = {
   hdr.nsh_extr_underlay.spi : exact;
   hdr.nsh_extr_underlay.si : exact;
  }

  actions = {
   hit;
   miss;
  }

  const default_action = miss;
  size = NPB_EGR_SF_EGRESS_SFP_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // table needed: key {spi, si}

  myTable.apply();

 }

}
# 2 "npb/npb_egr_sf_proxy_top.p4" 2
//#include "npb_egr_sf_proxy_hdr_strip.p4"
//#include "npb_egr_sf_proxy_hdr_edit.p4"
//#include "npb_egr_sf_proxy_truncate.p4"
# 1 "npb/npb_egr_sf_proxy_meter.p4" 1

control npb_egr_sf_proxy_meter (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,

 in bit<10> meter_id,
 in bit<8> meter_overhead
) {

 bit<8> temp;

 // -----------------------------------------------------------------

 DirectMeter(MeterType_t.BYTES) direct_meter;

 action set_color_direct() {
  // Execute the Direct meter and write the color to the ipv4 header diffserv field
//		hdr.ipv4.diffserv = direct_meter.execute();
  temp = direct_meter.execute();
 }

 table direct_meter_color {
  key = {
//			hdr.ethernet.src_addr : exact;
   meter_id : exact;
  }

  actions = {
   set_color_direct;
  }
  meters = direct_meter;
  size = 1024;
 }

 // -----------------------------------------------------------------

 apply {

  // logic here

  direct_meter_color.apply();

  if(temp == 0) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }

 }

}
# 6 "npb/npb_egr_sf_proxy_top.p4" 2

control npb_egr_sf_proxy_top (

 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 bit<4> action_bitmask;
 bit<10> meter_id;
 bit<8> meter_overhead;

 apply {

  hdr.nsh_extr_underlay.setInvalid(); // proxy removes the nsh

  // ----------------------------------
  // Action Lookup
  // ----------------------------------

  npb_egr_sf_proxy_act_sel.apply (
   hdr,
   eg_md,
   eg_intr_md,
   eg_intr_md_from_prsr,
   eg_intr_md_for_dprsr,
   eg_intr_md_for_oport,

   action_bitmask,
   meter_id,
   meter_overhead
  );

  // ----------------------------------
  // Actions(s)
  // ----------------------------------

/*
		if(action_bitmask[0:0] == 1) {
			npb_egr_sf_proxy_hdr_strip.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[1:1] == 1) {
			npb_egr_sf_proxy_hdr_edit.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}

		if(action_bitmask[2:2] == 1) {
			npb_egr_sf_proxy_truncate.apply (
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			);
		}
*/

  if(action_bitmask[3:3] == 1) {
   npb_egr_sf_proxy_meter.apply (
    hdr,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport,

    meter_id,
    meter_overhead
   );
  }

    }

}
# 2 "npb/npb_egr_sff_top.p4" 2

control npb_egr_sff_top (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Table
 // =========================================================================

    action new_ttl(bit<6> ttl) {
        hdr.nsh_extr_underlay.ttl = ttl;
    }

    action discard() {
        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table dec_ttl {
        key = { hdr.nsh_extr_underlay.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0 : new_ttl(63);
            1 : discard();
            2 : new_ttl(1);
            3 : new_ttl(2);
            4 : new_ttl(3);
            5 : new_ttl(4);
            6 : new_ttl(5);
            7 : new_ttl(6);
            8 : new_ttl(7);
            9 : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // -----------------------------------------------------------------------------
  // Get the nsh header squared away
  // -----------------------------------------------------------------------------

  // **** Write common fields that come across in the metadata to the nsh header ****

  // Note: do this here and not in the first state of the parser, because they will
  // get overwritten in the parser if the packet already has an nsh header on it.

        // base: word 0
  // (nothing to do)

        // base: word 1
        hdr.nsh_extr_underlay.spi = eg_md.nsh_extr.spi;
        hdr.nsh_extr_underlay.si = eg_md.nsh_extr.si;

        // ext: type 2 - word 0
  // (nothing to do)

        // ext: type 2 - word 1+
        hdr.nsh_extr_underlay.extr_srvc_func_bitmask = eg_md.nsh_extr.extr_srvc_func_bitmask_remote; //  1 byte
        hdr.nsh_extr_underlay.extr_tenant_id = eg_md.nsh_extr.extr_tenant_id; //  3 bytes
        hdr.nsh_extr_underlay.extr_flow_type = eg_md.nsh_extr.extr_flow_type; //  1 byte?

  // ----------------------------------------

  if(hdr.nsh_extr_underlay.isValid()) {
   // ----------------------------------------
   // Packet already has an NSH header on it
   // ----------------------------------------

   dec_ttl.apply();

  } else {
   // ----------------------------------------
   // Packet needs an NSH header put on it
   // ----------------------------------------

   if(eg_md.nsh_extr.valid == 1) {
     hdr.nsh_extr_underlay.setValid();
   }

   // base: word 0
   hdr.nsh_extr_underlay.version = 0x0;
   hdr.nsh_extr_underlay.o = 0x0;
   hdr.nsh_extr_underlay.reserved = 0x0;
   hdr.nsh_extr_underlay.ttl = 0x0;
   hdr.nsh_extr_underlay.len = 0x8; // in 4-byte words
   hdr.nsh_extr_underlay.reserved2 = 0x0;
   hdr.nsh_extr_underlay.md_type = 0x2;
   hdr.nsh_extr_underlay.next_proto = 0x3;

   // base: word 1
   // (nothing to do -- these fields get set in the parser from the bridged metadata)

   // ext: type 2 - word 0
   hdr.nsh_extr_underlay.md_class = 0x0;
   hdr.nsh_extr_underlay.type = 0x0;
   hdr.nsh_extr_underlay.reserved3 = 0x0;
   hdr.nsh_extr_underlay.md_len = 0x14;

   // ext: type 2 - word 1+
   // (nothing to do -- these fields get set in the parser from the bridged metadata)

  }

  // ----------------------------

  // Regardless if the packet already had an nsh header on it or we added one,
  // invalidate it if we're at the end of the chain....
  if(eg_md.nsh_extr.end_of_chain == 1) {
   hdr.nsh_extr_underlay.setInvalid();
  }

  // -----------------------------------------------------------------------------
  // Do some work
  // -----------------------------------------------------------------------------

  if(eg_md.nsh_extr.valid == 1) {

   // -------------------------------------
   // SF(s)
   // -------------------------------------

   if(eg_md.nsh_extr.extr_srvc_func_bitmask_local[2:2] == 1) {

    // -------------------------------------
    // SF #0
    // -------------------------------------

    npb_egr_sf_proxy_top.apply (
     hdr,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

    // DON"T NEED TO DO THIS.  THE PROXY DELETES THE NSH HEADER SO THERES NO POINT IN CHECKING.
    // check sp index
//				if(eg_md.nsh_extr_underlay.si == 0) {
//					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//				}

   }

  }

 }

}
# 63 "npb/npb.p4" 2
# 1 "npb/npb_egr_sff_tunnel.p4" 1

// =============================================================================
// =============================================================================
// Taken from l2.p4 ============================================================
// =============================================================================
// =============================================================================

control npb_egr_sff_vlan_decap(inout switch_header_t hdr, in switch_port_t port) {

 // ----------------------------------------

 action remove_vlan_tag() {
  hdr.ethernet_underlay.ether_type = hdr.vlan_tag_underlay.ether_type;
//		hdr.vlan_tag_underlay.pop_front(1);
 }

 table vlan_decap {
  key = {
   port : ternary;
   hdr.vlan_tag_underlay.isValid() : exact;
  }

  actions = {
   NoAction;
   remove_vlan_tag;
  }

  const default_action = NoAction;
 }

 // ----------------------------------------

 apply {



  // Remove the vlan tag by default.
  if (hdr.vlan_tag_underlay.isValid()) {
   hdr.ethernet_underlay.ether_type = hdr.vlan_tag_underlay.ether_type;
   hdr.vlan_tag_underlay.setInvalid();
  }

 }
}

// =============================================================================
// =============================================================================
// Taken from tunnel.p4 ========================================================
// =============================================================================
// =============================================================================

control npb_egr_sff_tunnel_decap (
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // ----------------------------------------

 action invalidate_tunneling_headers() {
  // Removing tunneling headers by default.
 }

 // ----------------------------------------

 action decap_inner_ethernet_non_ip() {
  hdr.ethernet_underlay.setInvalid();
  invalidate_tunneling_headers();
 }

 table decap_inner_ip {
  key = {
   hdr.ethernet_underlay.isValid() : exact;
  }

  actions = {
   decap_inner_ethernet_non_ip;
  }

  const entries = {
   (true) : decap_inner_ethernet_non_ip();
  }
 }

 // ----------------------------------------

 apply {
  // Copy L3 headers into outer headers.
  decap_inner_ip.apply();
 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_rewrite (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

    EgressBd(
        EGRESS_BD_MAPPING_TABLE_SIZE, EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
    switch_smac_index_t smac_index;

	// =========================================================================
	// Table
	// =========================================================================

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = false;
        eg_md.tunnel.type = type;
#endif
    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        eg_md.tunnel.type = type;
        eg_md.tunnel.id = id;
#endif
    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.bd = bd;
        eg_md.tunnel.type = type;
#endif
    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {
#ifdef TUNNEL_ENABLE
//      eg_md.flags.routed = true;
        hdr.ethernet_underlay.dst_addr = dmac;
        eg_md.tunnel.type = type;
#endif
    }

    table nexthop_rewrite {
        key = { eg_md.nexthop : exact; }
        actions = {
            NoAction;
            rewrite_l2_with_tunnel;
            rewrite_l3;
            rewrite_l3_with_tunnel;
            rewrite_l3_with_tunnel_bd;
            rewrite_l3_with_tunnel_id;
        }

        const default_action = NoAction;
        size = NEXTHOP_TABLE_SIZE;
    }

	// =========================================================================
	// Table
	// =========================================================================

    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

        // Should not rewrite packets redirected to CPU.
        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL) {
            nexthop_rewrite.apply();
        }

        egress_bd.apply(
			hdr,             // in
			eg_md.bd,        // in
			eg_md.pkt_type,  // in
			eg_md.bd_label,  // out
            smac_index,      // out
			eg_md.checks.mtu // out
		);

        if (eg_md.port_type == SWITCH_PORT_TYPE_NORMAL && eg_md.flags.routed) {
            smac_rewrite.apply();
        }

	}

}
*/

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_tunnel_rewrite (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	EgressBd(EGRESS_OUTER_BD_MAPPING_TABLE_SIZE,
	         EGRESS_BD_STATS_TABLE_SIZE) egress_bd;
	switch_bd_label_t bd_label;
	switch_smac_index_t smac_index;

	// =========================================================================
	// Table - DA & BD
	// =========================================================================

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr.ethernet_underlay.dst_addr = dmac;
    }

    table nexthop_rewrite {
        key = {
            eg_md.nexthop : exact;
        }

        actions = {
            rewrite_tunnel;
        }
    }

	// =========================================================================
	// Table, SA
	// =========================================================================

    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr.ethernet_underlay.src_addr = smac;
    }
    
    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        size = TUNNEL_SMAC_REWRITE_TABLE_SIZE;
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		nexthop_rewrite.apply(); // sets l2 da, eg_md.bd

		egress_bd.apply(
			hdr,             // in
			eg_md.bd,        // in
			eg_md.pkt_type,  // in
			bd_label,        // out --> currently unused!?!?
			smac_index,      // out
			eg_md.checks.mtu // out
		);

		smac_rewrite.apply(); // sets l2 sa

	}

}
*/

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

/*
control npb_egr_sff_tunnel_encap (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Table - Set VNI
	// =========================================================================

    action set_vni(switch_tunnel_id_t id) {
        eg_md.tunnel.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = VNI_MAPPING_TABLE_SIZE;
    }

	// =========================================================================
	// Table - Tunnel Type
	// =========================================================================

	action rewrite_eth_nsh() {

			hdr.ethernet_underlay.setValid();
			hdr.vlan_tag_underlay.setValid();

			hdr.ethernet_underlay.ether_type = ETHERTYPE_NSH;
	}

	// -----------------------------------------------

    table tunnel {
        key = {
            eg_md.tunnel.type : exact;
        }

        actions = {
            NoAction;
            rewrite_eth_nsh;
        }

        const default_action = NoAction;
        const entries = {
            SWITCH_TUNNEL_TYPE_MACINMAC_NSH : rewrite_eth_nsh();
        }
    }

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE && eg_md.tunnel.id == 0) {
			bd_to_vni_mapping.apply();
		}

		if(eg_md.tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {

			// Add outer Tunnel headers.
			tunnel.apply();

			npb_egr_sff_tunnel_rewrite.apply(
				hdr,
				eg_md,
				eg_intr_md,
				eg_intr_md_from_prsr,
				eg_intr_md_for_dprsr,
				eg_intr_md_for_oport
			); 

		}

	}

}
*/
# 64 "npb/npb.p4" 2





// ----------------------------------------------------------------------------

control SwitchIngress(
        inout switch_header_t hdr,
        inout switch_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {


    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE) ingress_port_mapping;
    PktValidation() pkt_validation;
    IngressSTP() stp;
    SMAC(MAC_TABLE_SIZE) smac;
    DMAC(MAC_TABLE_SIZE) dmac;
    IngressTunnel(IPV4_SRC_TUNNEL_TABLE_SIZE) tunnel;
    IngressBd(BD_STATS_TABLE_SIZE) bd_stats;
    IngressMulticast(IPV4_MULTICAST_S_G_TABLE_SIZE,
                     IPV4_MULTICAST_STAR_G_TABLE_SIZE,
                     IPV6_MULTICAST_S_G_TABLE_SIZE,
                     IPV6_MULTICAST_STAR_G_TABLE_SIZE) multicast;
    IngressUnicast(dmac,
                   IPV4_HOST_TABLE_SIZE,
                   IPV4_LPM_TABLE_SIZE,
                   IPV6_HOST_TABLE_SIZE,
                   IPV6_LPM_TABLE_SIZE) unicast;
    IngressAcl() acl;
    MirrorAcl() mirror_acl;
    RouterAcl(
        INGRESS_IPV4_RACL_TABLE_SIZE, INGRESS_IPV6_RACL_TABLE_SIZE, true, RACL_STATS_TABLE_SIZE) racl;

    IngressQos() qos;
    StormControl(STORM_CONTROL_TABLE_SIZE) storm_control;
    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterNexthop(
        OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) outer_nexthop;
    LAG() lag;
    MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;
    IngressSystemAcl() system_acl;


 // ----------------------------------------------------------------------------

    //TODO(msharif) : Use different algorithms for upper and lower 16 bits.
    Hash<bit<32>>(HashAlgorithm_t.CRC32) flow_hash;
    Hash<bit<32>>(HashAlgorithm_t.CRC32) flow_hash2;

    switch_lookup_fields_t lkp;
    switch_lookup_fields_t lkp_nsh;

 // ----------------------------------------------------------------------------

    //XXX Tofino can generate 4 bytes of hash per logical table, we need to make sure PHV
    // container(s) allocated for hash is less than 32 bits. P4C-669.
    @pa_container_size("ingress", "hash_1", 16)
    bit<32> hash;

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = SWITCH_PKT_SRC_BRIDGE;
        // hdr.bridged_md.ingress_port = ig_md.port;
        // hdr.bridged_md.ingress_ifindex = ig_md.ifindex;
        // hdr.bridged_md.ingress_bd = ig_md.bd;
        hdr.bridged_md.nexthop = ig_md.nexthop;
        // hdr.bridged_md.routed = (bit<1>) ig_md.flags.routed;
        // hdr.bridged_md.peer_link = (bit<1>) ig_md.flags.peer_link;
        // hdr.bridged_md.capture_ts = (bit<1>) ig_md.flags.capture_ts;
        // hdr.bridged_md.tunnel_terminate = (bit<1>) ig_md.tunnel.terminate;
        // hdr.bridged_md.tc = ig_md.qos.tc;
        // hdr.bridged_md.cpu_reason = ig_md.cpu_reason;
        // hdr.bridged_md.timestamp = ig_md.timestamp;
        // hdr.bridged_md.qid = ig_intr_md_for_tm.qid;
# 149 "npb/npb.p4"
        hdr.bridged_tunnel_md.setValid();
        hdr.bridged_tunnel_md.index = ig_md.tunnel.index;
        hdr.bridged_tunnel_md.outer_nexthop = ig_md.outer_nexthop;
        hdr.bridged_tunnel_md.hash = hash[15:0];


        //TODO(msharif) : Move this to deparser.
        hdr.mirror.port.session_id = (bit<16>) ig_md.mirror.session_id;

        // -----------------------------
        // ----- Extreme Networks -----
        // -----------------------------

  // metadata
        hdr.bridged_md.orig_pkt_had_nsh = ig_md.orig_pkt_had_nsh;

        hdr.bridged_md.nsh_extr_valid = ig_md.nsh_extr.valid;
        hdr.bridged_md.nsh_extr_end_of_chain = ig_md.nsh_extr.end_of_chain;

        // base: word 0

        // base: word 1
        hdr.bridged_md.nsh_extr_spi = ig_md.nsh_extr.spi;
        hdr.bridged_md.nsh_extr_si = ig_md.nsh_extr.si;

        // ext: type 2 - word 0

        // ext: type 2 - word 1+
        hdr.bridged_md.nsh_extr_srvc_func_bitmask_local = ig_md.nsh_extr.extr_srvc_func_bitmask_local; //  1 byte
        hdr.bridged_md.nsh_extr_srvc_func_bitmask_remote = ig_md.nsh_extr.extr_srvc_func_bitmask_remote; //  1 byte
        hdr.bridged_md.nsh_extr_tenant_id = ig_md.nsh_extr.extr_tenant_id; //  3 bytes
        hdr.bridged_md.nsh_extr_flow_type = ig_md.nsh_extr.extr_flow_type; //  1 byte?
    }

 // ----------------------------------------------------------------------------

    action compute_ip_hash() {
        hash = flow_hash.get({lkp.ipv4_src_addr,
                              lkp.ipv4_dst_addr,
                              lkp.ipv6_src_addr,
                              lkp.ipv6_dst_addr,
                              lkp.ip_proto,
                              lkp.l4_dst_port,
                              lkp.l4_src_port});
    }

 // ----------------------------------------------------------------------------

    action compute_non_ip_hash() {
        hash = flow_hash2.get({lkp.mac_type, lkp.mac_src_addr, lkp.mac_dst_addr});
    }

 // ----------------------------------------------------------------------------

    apply {

        // -----------------------------------------------------
        // derek: just set the tx-port to the rx-port, for debug!
        // -----------------------------------------------------


        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;


        // -----------------------------------------------------
        // cmace: header stack id experiment
        // -----------------------------------------------------





        // -----------------------------------------------------



        pkt_validation.apply(
            hdr, ig_md.flags, lkp, ig_intr_md_for_tm, ig_md.drop_reason);
  lkp_nsh = lkp; // Derek added
        ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);
//      stp.apply(ig_md, ig_md.stp);

        tunnel.apply(hdr, ig_md, lkp, lkp_nsh);
//      smac.apply(lkp.mac_src_addr, ig_md, ig_intr_md_for_dprsr.digest_type);
//      bd_stats.apply(ig_md.bd, lkp.pkt_type);
//      acl.apply(lkp, ig_md);
//      mirror_acl.apply(lkp, ig_md, ig_intr_md_for_dprsr);

        // =====================================
  // Paths Fork
        // =====================================

        // =====================================
  // Path A: NSH Processing
        // =====================================

        // -------------------------------------
        // SFC
        // -------------------------------------

        npb_ing_sfc_top.apply (
            hdr,
            ig_md,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm,

            lkp_nsh
        );

        // -------------------------------------
        // SFF and SF(s)
        // -------------------------------------

        npb_ing_sff_top.apply (
            hdr,
            ig_md,
            ig_intr_md,
            ig_intr_from_prsr,
            ig_intr_md_for_dprsr,
            ig_intr_md_for_tm,

            lkp_nsh
        );

        // =====================================
  // Path B: Switch Processing
        // =====================================
# 295 "npb/npb.p4"
        // =====================================
  // Paths Join
        // =====================================

  // Give higher priority to nsh forwarding than switch forwarding....







  // nsh tunnel settings become switch tunnel settings (see tunnel.p4)....

  ig_md.tunnel.ifindex = ig_md.tunnel_nsh.ifindex;

        ig_md.bd = ig_md.bd_nsh;
        ig_md.bd_label = ig_md.bd_label_nsh;
        ig_md.vrf = ig_md.vrf_nsh;
        // ig_intr_md_for_tm.rid         = ig_intr_md_for_tm.rid;
        ig_md.rmac_group = ig_md.rmac_group_nsh;
        ig_md.multicast.rpf_group = ig_md.multicast_nsh.rpf_group;
        ig_md.learning.bd_mode = ig_md.learning_nsh.bd_mode;
        ig_md.ipv4_md.unicast_enable = ig_md.ipv4_md_nsh.unicast_enable;
        ig_md.ipv4_md.multicast_enable = ig_md.ipv4_md_nsh.multicast_enable;
        ig_md.ipv4_md.multicast_snooping = ig_md.ipv4_md_nsh.multicast_snooping;
        ig_md.ipv6_md.unicast_enable = ig_md.ipv6_md_nsh.unicast_enable;
        ig_md.ipv6_md.multicast_enable = ig_md.ipv6_md_nsh.multicast_enable;
        ig_md.ipv6_md.multicast_snooping = ig_md.ipv6_md_nsh.multicast_snooping;
  ig_md.tunnel.terminate = ig_md.tunnel_nsh.terminate;







//      racl.apply(lkp, ig_md);

        if (lkp.ip_type == SWITCH_IP_TYPE_NONE) {
            compute_non_ip_hash();
        } else {
            compute_ip_hash();
        }

        nexthop.apply(lkp, ig_md, ig_intr_md_for_tm, hash[15:0]);
//      qos.apply(hdr, lkp, ig_md.qos, ig_md, ig_intr_md_for_tm);
//      storm_control.apply(ig_md, lkp.pkt_type, ig_md.flags.storm_control_drop);
        outer_nexthop.apply(ig_md, hash[31:16]);

        if (ig_md.egress_ifindex == SWITCH_IFINDEX_FLOOD) {
//          flood.apply(
//              lkp.pkt_type, ig_md.bd, ig_md.flags.flood_to_multicast_routers, ig_intr_md_for_tm);
        } else {
//          lag.apply(ig_md, hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
        }

//      system_acl.apply(
//          ig_md, lkp, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        if (!ig_intr_md_for_tm.bypass_egress) {
            add_bridged_md();
        }


        // Set PRE hash values
//XXX Compiler doesn't like this copy!!!!
//        ig_intr_md_for_tm.level1_mcast_hash = hash[12:0];
//        ig_intr_md_for_tm.level2_mcast_hash = hash[28:16];
# 373 "npb/npb.p4"
    }
}

// ----------------------------------------------------------------------------

control SwitchEgress(
        inout switch_header_t hdr,
        inout switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
# 406 "npb/npb.p4"
    switch_lookup_fields_t lkp;

 // ----------------------------------------------------------------------------

    apply {
# 527 "npb/npb.p4"
    }
}

// ----------------------------------------------------------------------------

Pipeline(
        //SwitchIngressParser(),
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        //SwitchEgressParser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
