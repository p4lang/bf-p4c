# 1 "upf.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "upf.p4"
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "/home/vgurevich/bf-sde-8.5.0/install/share/p4c/p4include/core.p4" 1
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
# 11 "upf.p4" 2
# 1 "/home/vgurevich/bf-sde-8.5.0/install/share/p4c/p4include/tna.p4" 1
/*
 * Copyright (c) 2015-2017 Barefoot Networks, Inc.
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




# 1 "/home/vgurevich/bf-sde-8.5.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-8.5.0/install/share/p4c/p4include/tna.p4" 2
# 1 "/home/vgurevich/bf-sde-8.5.0/install/share/p4c/p4include/tofino.p4" 1
/*
 * Copyright (c) 2015-2017 Barefoot Networks, Inc.
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




// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9> PortId_t; // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t; // Multicast group id
typedef bit<5> QueueId_t; // Queue id
typedef bit<10> MirrorId_t; // Mirror id
typedef bit<16> ReplicationId_t; // Replication id

typedef error ParserError_t;

/// Meter
enum MeterType_t { PACKETS, BYTES }

enum MeterColor_t { GREEN, YELLOW, RED }

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
    CRC8,
    CRC16,
    CRC32,
    CRC64,
    CSUM16
}

match_kind {
    // exact,
    // ternary,
    // lpm,               // Longest-prefix match.
    range,
    selector // Used for implementing dynamic action selection
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
    bit<1> resubmit_flag; // Flag distinguishing original packets
                                        // from resubmitted packets.
    bit<1> _pad1;

    bit<2> packet_version; // Read-only Packet version.

    bit<3> _pad2;

    PortId_t ingress_port; // Ingress physical port id.

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

    bit<3> mirror_type; // The user-selected mirror field list
                                        // index.
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

    bit<14> _pad3;
    bit<18> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    bit<5> _pad4;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    bit<6> _pad5;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    bit<14> _pad6;
    bit<18> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    ReplicationId_t egress_rid; // L3 replication id for multicast
                                        // packets.

    bit<7> _pad7;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    bit<3> _pad8;

    QueueId_t egress_qid; // Egress (physical) queue id via which
                                        // this packet was served.

    bit<5> _pad9;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    bit<7> _pad10;

    bit<1> deflection_flag; // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length; // Packet length, in bytes
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

    bit<3> mirror_type;

    bit<1> coalesce_flush; // Flush the coalesced mirror buffer

    bit<7> coalesce_length; // The number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer
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
// Packet generator supports up to 8 applications and a total of 16KB packet
// payload. Each application is associated with one of the four trigger types:
// - One-time timer
// - Periodic timer
// - Port down
// - Packet recirculation
// For recirculated packets, the event fires when the first 32 bits of the
// recirculated packet matches the application match value and mask.
// A triggered event may generate programmable number of batches with
// programmable number of packets per batch.
header pktgen_timer_header_t {
    bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    bit<15> _pad2;
    bit<9> port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    bit<24> key; // Key from the recirculated packet

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

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
    /// Constructor
    /// @type_param W : Width of counter. Only 8-bit counter is supported.
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
    /// @return : parser counter value.
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
    /// param prio : parser priority for the parsed packet.
    void set(in bit<3> prio);
}

// ----------------------------------------------------------------------------
// HASH ENGINE
// ----------------------------------------------------------------------------
extern Hash<W> {
    /// Constructor
    /// @type_param W : width of the calculated hash.
    /// @param algo : The default algorithm used for hash calculation.
    Hash(HashAlgorithm_t algo);

    /// Compute the hash for the given data.
    /// @param data : The list of fields contributing to the hash.
    /// @return The hash value.
    W get<D>(in D data);

    /// Compute the hash for data.
    /// @param data : The list of fields contributing to the hash.
    /// @param base : Minimum return value.
    /// @param max : The value use in modulo operation.
    /// @return (base + (h % max)) where h is the hash value.
    W get<D>(in D data, in W base, in W max);
}

/// Random number generator.
extern Random<W> {
    /// Constructor
    /// @type_param W : width of the calculated hash.
    Random();

    /// Return a random number with uniform distribution.
    /// @return : random number between 0 and 2**W - 1
    W get();
}

// -----------------------------------------------------------------------------
// EXTERN FUNCTIONS
// -----------------------------------------------------------------------------

extern T max<T>(T t1, T t2);

extern T min<T>(T t1, T t2);

extern void invalidate<T>(in T field);

/// Counter
/// Indexed counter with `size’ independent counter values.
extern Counter<W, I> {
    /// Constructor
    /// @type_param W : width of the counter value.
    /// @type_param I : width of the counter index.
    /// @param type : counter type. Packet an byte counters are supported.
    Counter(bit<32> size, CounterType_t type);

    /// Increment the counter value.
    /// @param index : index of the counter to be incremented.
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
    bit<8> execute(in I index, in MeterColor_t color);
    bit<8> execute(in I index);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type);
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

// This is implemented using an experimental feature in p4c and subject to
// change. See https://github.com/p4lang/p4-spec/issues/561
extern RegisterAction<T, I, U> {
    RegisterAction(Register<T, I> reg);

    // Abstract method that needs to be implemented when RegisterAction is
    // instantiated.
    // @param value : register value.
    // @param rv : return value.
    abstract void apply(inout T value, @optional out U rv);

    U execute(in I index); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv);
        reg.write(index, value);
        return rv;
    } */

    // Apply the implemented abstract method using an index that increments each
    // time. This method is useful for stateful logging.
    U execute_log();
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);

    // Abstract method that needs to be implemented when RegisterAction is
    // instantiated.
    // @param value : register value.
    // @param rv : return value.
    abstract void apply(inout T value, @optional out U rv);

    U execute(); /* {
        U rv;
        T value = reg.read();
        apply(value, rv);
        reg.write(value);
        return rv;
    } */
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

// Tofino supports mirroring both at the ingress and egress. Ingress deparser
// creates a copy of the original ingress packet and prepends the mirror header.
// Egress deparser first constructs the output packet and then prepends the
// mirror header.
extern Mirror {
    /// Constructor
    Mirror();

    /// Mirror the packet.
    void emit(in MirrorId_t session_id);

    /// Write @hdr into the ingress/egress mirror buffer.
    /// @param hdr : T can be a header type.
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
    /// @param hdr : T can be a header type.
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
# 24 "/home/vgurevich/bf-sde-8.5.0/install/share/p4c/p4include/tna.p4" 2

// The following declarations provide a template for the programmable blocks in
// Tofino.

parser IngressParser<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md);

parser EgressParser<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md);

control Ingress<H, M>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

control Egress<H, M>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);

control IngressDeparser<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr);

control EgressDeparser<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);

package Pipeline<IH, IM, EH, EM>(
    IngressParser<IH, IM> ingress_parser,
    Ingress<IH, IM> ingress,
    IngressDeparser<IH, IM> ingress_deparser,
    EgressParser<EH, EM> egress_parser,
    Egress<EH, EM> egress,
    EgressDeparser<EH, EM> egress_deparser);

@pkginfo(arch="TNA", version="1.0.0")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
# 12 "upf.p4" 2

# 1 "headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/*************************************************************************
********************************** L2  ***********************************
*************************************************************************/

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vlanId;
    bit<16> etherType;
}

/*************************************************************************
********************************** L3  ***********************************
*************************************************************************/

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
    bit<32> srcAddr;
    bit<32> dstAddr;
}

/* TODO:  Add IPV6 headers*/

/*************************************************************************
********************************** L4  ***********************************
*************************************************************************/

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
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<32> checksum;
    // FIXME: We merged checksum and urgentPtr since we don't use the later, to 
    // allow us to copy the checksum. It is clearly a bug.
    //bit<16>     urgentPtr;
}

/*************************************************************************
******************************* Tunneling  *******************************
*************************************************************************/

header gtp_u_t {
    bit<3> version;
    bit<1> pt;
    bit<1> spare;
    bit<1> extFlag;
    bit<1> seqFlag;
    bit<1> pn;
    bit<8> msgType;
    bit<16> totalLen;
    bit<32> teid;
}

/*
 * TODO: Extended header GTP_U, take it into account
 */
header gtp_u_extended_t {
    bit<16> seqNumb;
    bit<8> npdu;
    bit<8> neh;
}

/*************************************************************************
*************************  DP Control Header  ****************************
*************************************************************************/

/* Metadata for packets that are forwarded to/from CPU */
/*
 * TODO: Decide what metadata should be fowarded. Padding added for this purpose.
 */
header dp_ctrl_header_t {
    bit<5> _pad0;
    bit<3> ring_id;
    bit<79> _pad1;
    PortId_t port;
    bit<16> etherType;
}

/*************************************************************************
******************** Ingress/Egress bridge Header  ***********************
*************************************************************************/
header upf_bridged_metadata_t {
// user-defined metadata carried over from ingress to egress. 168 bits.
    bit<11> _pad0;
    bit<9> ingress_port;
    bit<12> vlanId;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8> protocol;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<32> teid;
// add more fields here.
}

/*************************************************************************
************************* Headers declaration ****************************
*************************************************************************/

// FIXME: Does this belong here?
struct headers {
    upf_bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl;
    ethernet_t ethernet;
    vlan_t vlan;
    ipv4_t outer_ipv4;
    udp_t outer_udp;
    tcp_t outer_tcp;
    gtp_u_t gtp_u;
    ipv4_t inner_ipv4;
    udp_t inner_udp;
    tcp_t inner_tcp;
}
# 14 "upf.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/*
 * Ether types
 */
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now

/*
 * Header minimum size
 */
typedef bit<16> size_t;
const size_t ETH_MIN_SIZE = 0x0E;
const size_t IPV4_MIN_SIZE = 0x14;
const size_t UDP_SIZE = 0x08;
const size_t GTP_MIN_SIZE = 0x08;
const size_t VLAN_SIZE = 0x04;

/*
 *  Port number definition
 */
typedef bit<16> port_t;
const port_t PORT_GTP_U = 2152;

/*
 *  IP Protocol definition
 */
typedef bit<8> ip_protocol_t;
const ip_protocol_t PROTO_UDP = 17;
const ip_protocol_t PROTO_TCP = 6;
# 15 "upf.p4" 2


# 1 "parde.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "parde.p4" 2
# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "metadata.p4" 2
# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "metadata.p4" 2

// TODO: explaining each metadata (like BF)

struct upf_egress_metadata_t {
    bit<16> pkt_length;
    bit<9> ingress_port;
    bit<12> vlanId;
    bit<16> srcPort;
    bit<16> dstPort;
    bit<8> protocol;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<32> teid;
}

header upf_port_metatdata_t {
    bit<7> _pad ;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

struct upf_ingress_metadata_t {
    bit<1> resubmit_flag;
    bit<1> _pad1;
    bit<2> packet_version;
    bit<3> _pad2;
    bit<9> cpu_port;
    bit<48> ingress_mac_tstamp;
    bit<16> dlSrcPort; // To abstract TCP/UDP src port 
    bit<16> dlDstPort; // To abstract TCP/UDP dst port 
}
# 15 "parde.p4" 2

//=============================================================================
// Ingress Parser
//=============================================================================
parser UPFIngressParser(
            packet_in pkt,
            out headers hdr,
            out upf_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {

    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(ig_intr_md);
        ig_md.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp;
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit; // Need criteria for resubmitting
            0 : parse_port_metadata; // default
        }
    }

    state parse_resubmit {
        // Parse resubmit packet mirrored or notice
        // TODO: add necessary actions in resubmit case
        transition reject;
    }

    state parse_port_metadata {
        //Parse port metadata appended by tofino
        upf_port_metatdata_t port_md;
        pkt.extract(port_md);
        transition parse_packet;
    }

    state parse_packet {
        dp_ctrl_header_t ether = pkt.lookahead<dp_ctrl_header_t>();
        transition select(ether.etherType) {
            ETHERTYPE_DP_CTRL : parse_dp_ctrl;
            default : parse_ethernet;
        }
/*         dp_ctrl_header_t dp_ctrl_hdr;
        transition parse_ethernet; */
    }

    state parse_dp_ctrl {
        pkt.extract(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            ETHERTYPE_DP_CTRL : parse_ethernet;
            default : accept;
        }
    }


    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        ig_md.dlSrcPort = hdr.outer_tcp.srcPort;
        ig_md.dlDstPort = hdr.outer_tcp.dstPort;
        transition accept;
    }

    /*
     *  Outer UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        ig_md.dlSrcPort = hdr.outer_udp.srcPort;
        ig_md.dlDstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition accept;
    }
}

//=============================================================================
// Ingress Deparser
//=============================================================================
control UPFIngressDeparser(
            packet_out pkt,
            inout headers hdr,
            in upf_ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply{

        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_udp);
    }
}

//=============================================================================
// Egress Parser
//=============================================================================
parser UPFEgressParser(
            packet_in pkt,
            out headers hdr,
            out upf_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(eg_intr_md);
        transition parse_bridged_metadata;
    }

    /*
     *  Parse metadata. FIXME: Is this right ?
     */
    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.ingress_port = hdr.bridged_md.ingress_port ;
        eg_md.vlanId = hdr.bridged_md.vlanId ;
        eg_md.srcPort = hdr.bridged_md.srcPort ;
        eg_md.dstPort = hdr.bridged_md.dstPort ;
        eg_md.protocol = hdr.bridged_md.protocol;
        eg_md.srcAddr = hdr.bridged_md.srcAddr ;
        eg_md.dstAddr = hdr.bridged_md.dstAddr;
        eg_md.teid = hdr.bridged_md.teid;
        transition parse_packet;
    }

    state parse_packet {
        pkt.extract(hdr.dp_ctrl);
        transition select(hdr.dp_ctrl.etherType) {
            ETHERTYPE_DP_CTRL : parse_ethernet;
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            default : accept;
        }
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition accept;
    }

    /*
     *  UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition accept;
    }
}

//=============================================================================
// Egress Deparser
//=============================================================================
control UPFEgressDeparser(
            packet_out pkt,
            inout headers hdr,
            in upf_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) outer_ipv4_checksum;
    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;

    apply {
        hdr.outer_ipv4.hdrChecksum = outer_ipv4_checksum.update({
                hdr.outer_ipv4.version,
                hdr.outer_ipv4.ihl,
                hdr.outer_ipv4.diffserv,
                hdr.outer_ipv4.totalLen,
                hdr.outer_ipv4.identification,
                hdr.outer_ipv4.flags,
                hdr.outer_ipv4.fragOffset,
                hdr.outer_ipv4.ttl,
                hdr.outer_ipv4.protocol,
                hdr.outer_ipv4.srcAddr,
                hdr.outer_ipv4.dstAddr
        });

        hdr.inner_ipv4.hdrChecksum = inner_ipv4_checksum.update({
                hdr.inner_ipv4.version,
                hdr.inner_ipv4.ihl,
                hdr.inner_ipv4.diffserv,
                hdr.inner_ipv4.totalLen,
                hdr.inner_ipv4.identification,
                hdr.inner_ipv4.flags,
                hdr.inner_ipv4.fragOffset,
                hdr.inner_ipv4.ttl,
                hdr.inner_ipv4.protocol,
                hdr.inner_ipv4.srcAddr,
                hdr.inner_ipv4.dstAddr
        });

        pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_tcp);
        pkt.emit(hdr.inner_udp);
    }
}
# 18 "upf.p4" 2
# 1 "uplink.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control Uplink(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    action decap_gtp() {
        // If we need to decap VLAN, should be here
        hdr.outer_ipv4.setInvalid();
        hdr.outer_udp.setInvalid();
        hdr.gtp_u.setInvalid();
    }

    apply {
        decap_gtp();
    }
}
# 19 "upf.p4" 2
# 1 "downlink.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




control Downlink(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    action sub_fcs_tofino() {
        /* Subtract 4 from the packet length to account for the 4 bytes of Ethernet
         * FCS that is included in Tofino's packet length metadata.
         */
        eg_md.pkt_length = eg_md.pkt_length - 0x4;
    }

    action payload_vlan_len() {
        eg_md.pkt_length = eg_md.pkt_length - VLAN_SIZE;
    }

    action payload_len() {
        eg_md.pkt_length = eg_md.pkt_length - ETH_MIN_SIZE;
    }

    action compute_len() {
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.outer_udp.hdrLen = UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.gtp_u.totalLen = eg_md.pkt_length;
    }

    action copy_outer_ip_to_inner_ip() {
        // Copy outer IP to inner IP
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4 = hdr.outer_ipv4;
        hdr.outer_ipv4.protocol = PROTO_UDP;
    }

    action add_gtp() {
        // Add GTP
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 1;
        hdr.gtp_u.pt = 1;
        hdr.gtp_u.msgType = 255;
        // TODO: To be changed when the tables will be done
        hdr.gtp_u.teid = 0;
    }

    action copy_outer_tcp_to_inner_tcp() {
        /*
         * If we parsed a outer tcp we need to copy it to inner tcp
         * and delet it. 
         */
        hdr.inner_tcp.setValid();
        hdr.inner_tcp = hdr.outer_tcp;
        //hdr.inner_tcp.checksum = hdr.outer_tcp.checksum;
        hdr.outer_tcp.setInvalid();
    }

    action copy_outer_udp_to_inner_udp() {
        hdr.inner_udp.setValid();
        hdr.inner_udp = hdr.outer_udp;
        hdr.inner_udp.checksum = hdr.outer_udp.checksum;
    }

    action add_outer_udp() {
        // ADD outer UDP
        hdr.outer_udp.setValid();
        // Tofino does not support UDP checksum       
        hdr.outer_udp.checksum = 0;
        hdr.outer_udp.dstPort = PORT_GTP_U;
        hdr.outer_udp.srcPort = PORT_GTP_U;
    }

    apply {
        copy_outer_ip_to_inner_ip();
        add_gtp();
        if (hdr.outer_tcp.isValid()){
            copy_outer_tcp_to_inner_tcp();
        } else if (hdr.outer_udp.isValid()){
            copy_outer_udp_to_inner_udp();
        }
        add_outer_udp();
        if (hdr.vlan.isValid()) {
            payload_vlan_len();
        }
        sub_fcs_tofino();
        payload_len();
        compute_len();
    }
}
# 20 "upf.p4" 2
# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 21 "upf.p4" 2

// FIXME: temporary, until we introduce lookups


//=============================================================================
// Ingress control
//=============================================================================
control UPFIngress(
        inout headers hdr,
        inout upf_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    // Stateful objects
    // If need to use for p4 conditions use Registers instead of counters
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ig_drp_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) send_cpu_cntr;

    /*
     * Control header and actions for send_to_cpu and drop.
     * (FIXME: need a file commun.p4?)
     */

    action set_cpu_port(PortId_t cpu_port) {
        ig_md.cpu_port = cpu_port;
    }

    table read_cpu_port_table {
        key = {
            ig_md.cpu_port : ternary;
        }
        actions = {
            set_cpu_port;
        }

        default_action = set_cpu_port(1);



        size = 1;
    }

    action add_dp_header() {
        hdr.dp_ctrl.setValid();
        hdr.dp_ctrl.port = ig_intr_md.ingress_port;
        hdr.dp_ctrl.etherType = ETHERTYPE_DP_CTRL;
    }

    action send_to_cpu(){
        /*
         * TODO: Configure metadata when sending packets to CPU
         */
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
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        ig_drp_cntr.count();
          exit;
    }

    //-----------------------------------------------------------------------------------------------------
    //               GTP Tables
    //-----------------------------------------------------------------------------------------------------

    action forward(PortId_t eg_port) {
        /*
         * TODO: should we set vlan ID for egress packet? If so it should be set
         * in egress.
         */
         ig_intr_md_for_tm.ucast_egress_port = eg_port;
    }

    table ul_dl_session_table {
        key = {
            // TODO: adapt to IPv6
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
            hdr.outer_ipv4.dstAddr : exact;
            hdr.gtp_u.teid : exact;
        }
        actions = {
            // policy_lookup;
            forward;
            NoAction;
        }
        size = 100;
        default_action = NoAction;
    }

    table flow_table {
        key = {
            // TODO: adapt to IPv6
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
            hdr.outer_ipv4.srcAddr : exact;
            hdr.outer_ipv4.dstAddr : exact;
            ig_md.dlSrcPort : exact;
            ig_md.dlDstPort : exact;
            hdr.outer_ipv4.protocol : exact;
        }
        actions = {
            NoAction;
        }
        size = 100;
        default_action = NoAction;
    }

    table policy_table {
        key = {
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
            hdr.outer_ipv4.srcAddr : ternary;
            hdr.outer_ipv4.protocol : ternary;
            ig_md.dlSrcPort : ternary;
            ig_md.dlDstPort : ternary;
        }
        actions = {
            // ul_drop;
            // ul_fwd;
            // dl_policy;
            forward;
            NoAction;
        }
        size = 100;
        default_action = NoAction;
    }

    //-----------------------------------------------------------------------------------------------------
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
        switch(ul_dl_session_table.apply().action_run){
            NoAction: {
                read_cpu_port_table.apply();
                if (ig_intr_md.ingress_port == ig_md.cpu_port) {
                    send_from_cpu();
                } else {
                    send_to_cpu();
                }
            }
        }
        // Only add bridged metadata if we are NOT bypassing egress pipeline.
        add_bridged_md();
    }
}

//=============================================================================
// Egress control
//=============================================================================
control UPFEgress(
        inout headers hdr,
        inout upf_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    Uplink() uplink;
    Downlink() downlink;

    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) eg_drp_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) dl_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) ul_cntr;

    // Should be in commun.p4 ?
    action drop_pkt_egress() {
        eg_intr_md_for_dprsr.drop_ctl = 0x1; // Drop packet.
        eg_drp_cntr.count();
        exit;
    }

    apply {
        if (hdr.dp_ctrl.isValid() && hdr.ethernet.isValid()) {
            hdr.dp_ctrl.setInvalid();
        } else if (hdr.gtp_u.isValid()) {
            ul_cntr.count();
            uplink.apply(hdr, eg_md);
        }
        else {
            dl_cntr.count();
            downlink.apply(hdr, eg_md);
        }
    }
}

Pipeline(UPFIngressParser(),
        UPFIngress(),
        UPFIngressDeparser(),
        UPFEgressParser(),
        UPFEgress(),
        UPFEgressDeparser()) pipe;

Switch(pipe) main;
