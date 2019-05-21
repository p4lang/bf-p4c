# 1 "intSw.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "intSw.p4"
/****************************************************************

 * Copyright (c) Kaloom Inc., 2018

 *

 * This unpublished material is property of Kaloom Inc.

 * All rights reserved.

 * Reproduction or distribution, in whole or in part, is

 * forbidden except by express written permission of Kaloom Inc.

 ****************************************************************/
# 10 "intSw.p4"
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
# 11 "intSw.p4" 2
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
/// Indexed counter with `size? independent counter values.
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
/// amount of metadata (64 bits) are passed back to the packet?s original
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
# 12 "intSw.p4" 2
// #include <psa.p4>


# 1 "headers.p4" 1
/****************************************************************

 * Copyright (c) Kaloom Inc., 2018

 *

 * This unpublished material is property of Kaloom Inc.

 * All rights reserved.

 * Reproduction or distribution, in whole or in part, is

 * forbidden except by express written permission of Kaloom Inc.

 ****************************************************************/
# 13 "headers.p4"
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
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now
//#define ETHERTYPE_ARP  0x0806

/*
 *  Port Definitions
 */


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
//#define IP_PROTOCOLS_ICMP   1
//#define IP_PROTOCOLS_IPV4   4
//#define IP_PROTOCOLS_TCP    6
//#define IP_PROTOCOLS_IPV6   41
//#define IP_PROTOCOLS_ICMPV6 58

// FIXME: temporary, until we introduce lookups
# 68 "types.p4"
typedef bit<8> switch_pkt_src_t;
typedef MirrorId_t switch_mirror_id_t;
const bit<32> INT_SESSION_NUM = 15;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGE = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_EGRESS = 2;
# 14 "headers.p4" 2

/*************************************************************************

********************************** L2  ***********************************

*************************************************************************/
# 19 "headers.p4"
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
# 36 "headers.p4"
// header ipv4_t {
//     bit<4>      version;
//     bit<4>      ihl;
//     bit<8>      diffserv;
//     bit<16>     totalLen;
//     bit<16>     identification;
//     bit<3>      flags;
//     bit<13>     fragOffset;
//     bit<8>      ttl;
//     bit<8>      protocol;
//     bit<16>     hdrChecksum;
//     bit<32>     srcAddr;
//     bit<32>     dstAddr;
// }

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

/* TODO :  Add IPV6 headers*/

/*************************************************************************

********************************** L4  ***********************************

*************************************************************************/
# 68 "headers.p4"
header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header vxlan_t {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

/* Metadata for packets that are forwarded to/from CPU */
/*

 *TODO : Decide what metadata should be fowarded. Padding added for this purpose.

 */
# 86 "headers.p4"
header dp_ctrl_header_t {
    bit<5> _pad0;
    bit<3> ring_id;
    bit<72> _pad1;
    bit<9> port;
    bit<7> _pad3;
    bit<16> etherType;
}

header inter_pipes_header_t {
    bit<9> ingress_port;
    bit<1> postcard_en;
    bit<6> pad0;
    bit<32> ingress_tstamp; // TODO: to become 48 bit
    bit<8> int_session_id; // INT config session id
    bit<7> pad1;
    bit<9> egress_port;
    bit<32> flow_hash;
    bit<32> reg_value;
}

@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.int_session_id", 8)
@pa_container_size("egress", "eg_md.mirror.ingress_port_id", 8)
@pa_container_size("egress", "eg_md.mirror.egress_port_id", 8)
header switch_mirror_metadata_t {
    switch_pkt_src_t src; // bit<8>
    bit<32> hop_latency;
    bit<32> ingress_tstamp;
    bit<32> egress_tstamp;
    bit<32> q_congestion;
    bit<32> egress_port_tx_utilization;
    bit<24> q_occupancy0;
    bit<8> int_session_id;
    // INT data
    bit<8> ingress_port_id;
    bit<8> egress_port_id;
    bit<8> qid;
    // bit<1>              pad_1;
    // bit<6>              _pad;
    // switch_mirror_id_t  session_id;
    // bit<8>              _pad2;
}

// phase0 header that is added by the ingress parser
header phase_0_metatdata_t {
    bit<7> _pad;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

/*************************************************************************

************************* Headers declaration ****************************

*************************************************************************/
# 142 "headers.p4"
/** INTSW meta-value headers - different header for each value type ****/
// INT headers
// header int_header_t {
//     bit<4>      ver;
//     bit<2>      rep; // Replication requested (e.g. replicat INT information for all possible passes, ECMP for example)
//     bit<1>      c; // Copy (e.g. broadcast or multicast)
//     bit<1>      e; // Max Hop Count exceeded
//     bit<1>      d;
//     bit<2>      rsvd1;
//     bit<5>      ins_cnt;
//     bit<8>      max_hop_cnt;
//     bit<8>      total_hop_cnt;
//     bit<4>      instruction_bitmap_0003;  // split the bits for lookup
//     bit<4>      instruction_bitmap_0407;
//     bit<4>      instruction_bitmap_0811;
//     bit<4>      instruction_bitmap_1215;
//     bit<16>     rsvd2_digest;
// }
// INT meta-value headers - different header for each value type
header int_switch_id_header_t {
    bit<32> switch_id;
}
header int_port_ids_header_t {
    bit<8> pad_1;
    bit<8> ingress_port_id;
    bit<8> egress_port_id;
    bit<8> pad_2;
}
// header int_ingress_port_id_header_t {
//     bit<16>    ingress_port_id_1;
//     bit<16>    ingress_port_id_0;
// }
header int_hop_latency_header_t {
    bit<32> hop_latency;
}
header int_q_occupancy_header_t {
    // bit<3>      rsvd;
    bit<8> qid;
    bit<24> q_occupancy0;
}
header int_ingress_tstamp_header_t {
    bit<32> ingress_tstamp;
}
header int_egress_tstamp_header_t {
    bit<32> egress_tstamp;
}
header int_q_congestion_header_t {
    bit<32> q_congestion;
}
header int_egress_port_tx_utilization_header_t {
    bit<32> egress_port_tx_utilization;
}

/***************** INT report ********************/
header dtel_report_header_t {
        bit<8> ver_Len;
        /*

        bit<3>   next_proto; // 0: Ethernet, 1: IPv4, 2: IPv6

        bit<1>   d; // dropped

        bit<1>   q; // congested_queue

        bit<1>   f; // path_tracking_flow

        bit<6>   reserved;

        bit<6>  reserved2;

        bit<6>   hw_id;

        */
# 207 "headers.p4"
        bit<24> merged_fields;
        bit<32> sequence_number;
        // timestamp;
}

/**************************** INTSW meta-value headers *******************************/

// FIXME: Does this belong here?
struct intSw_headers_t {
    ethernet_t encap_ethernet;
    ipv6_t encap_ipv6;
    udp_t encap_udp;

    dtel_report_header_t dtel_report_header;
    int_switch_id_header_t int_switch_id_header;
    int_port_ids_header_t int_port_ids_header;
    int_hop_latency_header_t int_hop_latency_header;
    int_q_occupancy_header_t int_q_occupancy_header;
    int_ingress_tstamp_header_t int_ingress_tstamp_header;
    int_egress_tstamp_header_t int_egress_tstamp_header;
    int_q_congestion_header_t int_q_congestion_header;
    int_egress_port_tx_utilization_header_t int_egress_port_tx_utilization_header;

    ethernet_t ethernet;
    vlan_t vlan;
    ipv6_t outer_ipv6;
    ipv6_t inner_ipv6;
    udp_t outer_udp;
    udp_t inner_udp;
    dp_ctrl_header_t dp_ctrl; // To/from CPU
    inter_pipes_header_t inter_pipes_hdr;
    // int_header_t                            int_header;
}
# 16 "intSw.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "intSw.p4" 2


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
# 13 "metadata.p4"
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
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "metadata.p4" 2

@pa_container_size("egress", "eg_md.egress_port", 16)
// @pa_container_size("egress", "intSw_egress_metadata_t.egress_port", 16)
struct intSw_egress_metadata_t {
    // bit<16>     pkt_length;
    switch_mirror_metadata_t mirror;
    PortId_t egress_port; // bit<9>
    switch_mirror_id_t session_id; // bit<10>
    bit<5> pad;
    bit<4> instruction_bitmap_0003; // split the bits for lookup
    bit<4> instruction_bitmap_0407;
    bit<4> instruction_bitmap_0811;
    bit<4> instruction_bitmap_1215;
    bit<16> int_len;
}


struct intSw_ingress_metadata_t {
    bit<1> resubmit_flag;
    bit<2> packet_version;
    bit<5> _pad1;
    bit<16> nexthop_id;
    bit<32> flow_hash;
}
# 15 "parde.p4" 2


//----------------------------------------------------------------------------
// Mirror packet deparser
//-----------------------------------------------------------------------------
//XXX This is a temporary workaround to make sure mirror metadata do not share
// the PHV containers with any other fields or paddings.
// @pa_container_size("ingress", "ig_md.mirror.session_id", 16)
control EgressMirror(
    in intSw_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Ingress deparser create a copy of the original ingress packet and prepend
// the prepend the mirror header.
    Mirror() mirror; // BAHNASY: I imagine this creates the mirror clone of the original packet.

    apply {
        if (eg_intr_md_for_dprsr.mirror_type == 0x4) {
            mirror.emit<switch_mirror_metadata_t>(eg_md.session_id, {
                         eg_md.mirror.src,
                         eg_md.mirror.hop_latency,
                         eg_md.mirror.ingress_tstamp,
                         eg_md.mirror.egress_tstamp,
                         eg_md.mirror.q_congestion,
                         eg_md.mirror.egress_port_tx_utilization,
                         eg_md.mirror.q_occupancy0,
                         eg_md.mirror.int_session_id,
                         eg_md.mirror.ingress_port_id,
                         eg_md.mirror.egress_port_id,
                         eg_md.mirror.qid
                         });
        }
    }
}

parser INTSWCommonParser(
            packet_in pkt,
            out intSw_headers_t hdr) {
    state start {
        transition parse_ethernet;
    }
    /*
     *  Ethernet parsing.
     */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  IPv6 parsing.
     */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_UDP : parse_outer_udp;
            default : accept;
        }
    }

    /*
     *  UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        transition accept;
        // transition select(hdr.outer_udp.dstPort) {
        //     PORT_GTP_U      : parse_gtp_u;
        //     default         : accept;
        // }
    }

    /********* Parse VXLAN *********
    parser parse_vxlan {
        pkt.extract(hdr.vxlan);
        transition parse_vxlan_inner_ethernet;
    }

    parser parse_vxlan_inner_ethernet {
        extract(vxlan_inner_ethernet);
        transition select(latest.etherType) {
            //ETHERTYPE_IPV6    : parse_vxlan_inner_ipv6;
            ETHERTYPE_IPV6    : parse_inner_ipv6;
            default           : accept;
        }
    }
    ******************/
}
//=============================================================================
// Ingress Parser
//=============================================================================
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_port", 16)
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_tstamp", 16)
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_port")
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_tstamp")
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_tstamp", 32)
parser INTSWIngressParser(
            packet_in pkt,
            out intSw_headers_t hdr,
            out intSw_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {

    INTSWCommonParser() prsr;
    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(ig_intr_md);
        // hdr.inter_pipes_hdr.ingress_port = ig_intr_md.ingress_port;
        // hdr.inter_pipes_hdr.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit; // Need criteria for resubmitting
            0 : parse_phase_0_metadata; // default
        }
    }

    state parse_resubmit {
        // Parse resubmit packet mirrored or notice
        //TODO : add necessary actions in resubmit case
        transition reject;
    }

    state parse_phase_0_metadata {
        //Parse port metadata appended by tofino
        phase_0_metatdata_t phase_0_md;
        pkt.extract(phase_0_md);
        transition parse_packet;
    }

    state parse_packet {
            prsr.apply(pkt, hdr);
            transition accept;
        }
}

//=============================================================================
// Ingress Deparser
//=============================================================================
control INTSWIngressDeparser(
            packet_out pkt,
            inout intSw_headers_t hdr,
            in intSw_ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply{
        pkt.emit(hdr.inter_pipes_hdr);
        // pkt.emit(hdr.dp_ctrl);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.outer_udp);
        // pkt.emit(hdr.gtp_u);
        // pkt.emit(hdr.inner_ipv6);
        // pkt.emit(hdr.inner_udp);
    }
}

//=============================================================================
// Egress Parser
//=============================================================================
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_port", 16)
// @pa_container_size("ingress", "hdr.inter_pipes_hdr.ingress_tstamp", 16)
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_port")
// @pa_no_overlay("ingress", "hdr.inter_pipes_hdr.ingress_tstamp")

// @pa_container_size("egress", "hdr.int_ingress_tstamp_header.ingress_tstamp", 32)
parser INTSWEgressParser(
            packet_in pkt,
            out intSw_headers_t hdr,
            out intSw_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    INTSWCommonParser() prsr;
    /*
     *  Packet entry point.
     */
    state start {
        pkt.extract(eg_intr_md);
        switch_pkt_src_t src = pkt.lookahead<switch_pkt_src_t>();
        transition select(src) {
            SWITCH_PKT_SRC_BRIDGE : parse_metadata;
            default : parse_mirrored_packet;
        }
    }

    state parse_mirrored_packet {
        pkt.extract(eg_md.mirror);
        // eg_md.pkt_src = eg_md.mirror.src;
        transition parse_packet;
    }
    /*
     *  Parse metadata. FIXME: Is this right ?
     */
    state parse_metadata {
        // eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.mirror.src = SWITCH_PKT_SRC_BRIDGE; // Added to force normal packet processing at the egress pipe
        transition parse_inter_pipes_hdr;
    }

    state parse_inter_pipes_hdr {
        pkt.extract(hdr.inter_pipes_hdr);
        eg_md.egress_port = hdr.inter_pipes_hdr.egress_port;
        transition parse_packet;
    }

    state parse_packet {
            prsr.apply(pkt, hdr);
            transition accept;
        }
}

//=============================================================================
// Egress Deparser
//=============================================================================
control INTSWEgressDeparser(
            packet_out pkt,
            inout intSw_headers_t hdr,
            in intSw_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;

    Checksum<bit<16>>(HashAlgorithm_t.CSUM16) encap_udp_checksum;
    // Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;

    apply {
        hdr.encap_udp.checksum = encap_udp_checksum.update({
        //         hdr.encap_ipv6.version,
        //         hdr.encap_ipv6.ihl,
        //         hdr.encap_ipv6.diffserv,
        //         hdr.encap_ipv6.totalLen,
        //         hdr.encap_ipv6.identification,
        //         hdr.encap_ipv6.flags,
        //         hdr.encap_ipv6.fragOffset,
        //         hdr.encap_ipv6.ttl,
                hdr.encap_ipv6.nextHdr,
                hdr.encap_ipv6.srcAddr,
                hdr.encap_ipv6.dstAddr,
                hdr.encap_udp.hdrLen
                // FIXME: to add the payload.
        });
        pkt.emit(hdr.encap_ethernet);
        pkt.emit(hdr.encap_ipv6);
        pkt.emit(hdr.encap_udp);

        pkt.emit(hdr.dtel_report_header);
        pkt.emit(hdr.int_switch_id_header);
        pkt.emit(hdr.int_port_ids_header);
        pkt.emit(hdr.int_hop_latency_header);
        pkt.emit(hdr.int_q_occupancy_header);
        pkt.emit(hdr.int_ingress_tstamp_header);
        pkt.emit(hdr.int_egress_tstamp_header);
        pkt.emit(hdr.int_q_congestion_header);
        pkt.emit(hdr.int_egress_port_tx_utilization_header);

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.outer_udp);
       // pkt.emit(hdr.gtp_u);
        // pkt.emit(hdr.inner_ipv6);
        // pkt.emit(hdr.inner_udp);
        egress_mirror.apply(eg_md, eg_intr_md_for_dprsr);
    }
}

//=============================================================================
// Ingress control
//=============================================================================
control INTSWIngress(
        inout intSw_headers_t hdr,
        inout intSw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    apply {}
}
//=============================================================================
// Egress control
//=============================================================================
control INTSWEgress(
        inout intSw_headers_t hdr,
        inout intSw_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {}
}

Pipeline(INTSWIngressParser(),
        INTSWIngress(),
        INTSWIngressDeparser(),
        INTSWEgressParser(),
        INTSWEgress(),
        INTSWEgressDeparser()) pipe;

Switch(pipe) main;
