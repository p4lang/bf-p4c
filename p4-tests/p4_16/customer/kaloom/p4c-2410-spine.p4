# 1 "spine.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "spine.p4"
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/core.p4" 1
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
    ParserTimeout, /// Parser execution time limit exceeded.
    ParserInvalidArgument /// Parser operation was called with a value
                           /// not supported by the implementation.
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
# 11 "spine.p4" 2
# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tna.p4" 1
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




# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tna.p4" 2
# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tofino.p4" 2

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------
typedef bit<9> PortId_t; // Port id -- ingress or egress port
typedef bit<16> MulticastGroupId_t; // Multicast group id
typedef bit<5> QueueId_t; // Queue id
typedef bit<10> MirrorId_t; // Mirror id
typedef bit<16> ReplicationId_t; // Replication id

typedef error ParserError_t;

const bit<32> PORT_METADATA_SIZE = 32w64;

const bit<16> PARSER_ERROR_OK = 16w0x0000;
const bit<16> PARSER_ERROR_NO_TCAM = 16w0x0001;
const bit<16> PARSER_ERROR_PARTIAL_HDR = 16w0x0002;
const bit<16> PARSER_ERROR_CTR_RANGE = 16w0x0004;
const bit<16> PARSER_ERROR_TIMEOUT_USER = 16w0x0008;
const bit<16> PARSER_ERROR_TIMEOUT_HW = 16w0x0010;
const bit<16> PARSER_ERROR_SRC_EXT = 16w0x0020;
const bit<16> PARSER_ERROR_DST_CONT = 16w0x0040;
const bit<16> PARSER_ERROR_PHV_OWNER = 16w0x0080;
const bit<16> PARSER_ERROR_MULTIWRITE = 16w0x0100;
const bit<16> PARSER_ERROR_ARAM_MBE = 16w0x0400;
const bit<16> PARSER_ERROR_FCS = 16w0x0800;

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
    CRC8,
    CRC16,
    CRC32,
    CRC64,
    CUSTOM
}

match_kind {
    // exact,
    // ternary,
    // lpm,               // Longest-prefix match.
    range,
    selector, // Used for implementing dynamic action selection
    atcam_partition_index // Used for implementing algorithmic tcam
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
    @padding bit<1> _pad1;

    bit<2> packet_version; // Read-only Packet version.

    @padding bit<3> _pad2;

    bit<9> ingress_port; // Ingress physical port id.

    bit<48> ingress_mac_tstamp; // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    bit<9> ucast_egress_port; // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bit<1> bypass_egress; // Request flag for the warp mode
                                        // (egress bypass).

    bit<1> deflect_on_drop; // Request for deflect on drop. must be
                                        // presented to TM to enable deflection
                                        // upon drop.

    bit<3> ingress_cos; // Ingress cos (iCoS) for PG mapping,
                                        // ingress admission control, PFC,
                                        // etc.

    bit<5> qid; // Egress (logical) queue id into which
                                        // this packet will be deposited.

    bit<3> icos_for_copy_to_cpu; // Ingress cos for the copy to CPU. must
                                        // be presented to TM if copy_to_cpu ==
                                        // 1.

    bit<1> copy_to_cpu; // Request for copy to cpu.

    bit<2> packet_color; // Packet color (G,Y,R) that is
                                        // typically derived from meters and
                                        // used for color-based tail dropping.

    bit<1> disable_ucast_cutthru; // Disable cut-through forwarding for
                                        // unicast.

    bit<1> enable_mcast_cutthru; // Enable cut-through forwarding for
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

    bit<16> rid; // L3 replication id for multicast.
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
    @padding bit<7> _pad0;

    bit<9> egress_port; // Egress port id.
                                        // this field is passed to the deparser

    @padding bit<5> _pad1;

    bit<19> enq_qdepth; // Queue depth at the packet enqueue
                                        // time.

    @padding bit<6> _pad2;

    bit<2> enq_congest_stat; // Queue congestion status at the packet
                                        // enqueue time.

    @padding bit<14> _pad3;
    bit<18> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    @padding bit<5> _pad4;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    @padding bit<6> _pad5;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    @padding bit<14> _pad6;
    bit<18> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    bit<16> egress_rid; // L3 replication id for multicast
                                        // packets.

    @padding bit<7> _pad7;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    @padding bit<3> _pad8;

    bit<5> egress_qid; // Egress (physical) queue id via which
                                        // this packet was served.

    @padding bit<5> _pad9;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    @padding bit<7> _pad10;

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
    bit<1> capture_tstamp_on_tx; // Request for packet departure
                                        // timestamping at egress MAC for IEEE
                                        // 1588. consumed by h/w (egress MAC).

    bit<1> update_delay_on_tx; // Request for PTP delay (elapsed time)
                                        // update at egress MAC for IEEE 1588
                                        // Transparent Clock. consumed by h/w
                                        // (egress MAC). when this is enabled,
                                        // the egress pipeline must prepend a
                                        // custom header composed of <ingress
                                        // tstamp (40), byte offset for the
                                        // elapsed time field (8), byte offset
                                        // for UDP checksum (8)> in front of the
                                        // Ethernet header.
    bit<1> force_tx_error; // force a hardware transmission error
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
    @padding bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @padding bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    @padding bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @padding bit<15> _pad2;
    bit<9> port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    @padding bit<3> _pad1;
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
    bit<8> udp_cksum_byte_offset; // Byte offset at which the egress MAC
                                        // needs to update the UDP checksum


    bit<8> cf_byte_offset; // Byte offset at which the egress MAC
                                        // needs to re-insert
                                        // ptp_sync.correction field

    bit<48> updated_cf; // Updated correction field in ptp sync
                                        // message
}

// -----------------------------------------------------------------------------
// CHECKSUM
// -----------------------------------------------------------------------------
// Tofino checksum engine can verify the checksums for header-only checksums
// and calculate the residual (checksum minus the header field
// contribution) for checksums that include the payload.
// Checksum engine only supports 16-bit ones' complement checksums, also known
// as csum16 or internet checksum.

extern Checksum {
    /// Constructor.
    Checksum();

    /// Add data to checksum.
    /// @param data : List of fields to be added to checksum calculation. The
    /// data must be byte aligned.
    void add<T>(in T data);

    /// Subtract data from existing checksum.
    /// @param data : List of fields to be subtracted from the checksum. The
    /// data must be byte aligned.
    void subtract<T>(in T data);

    /// Verify whether the complemented sum is zero, i.e. the checksum is valid.
    /// @return : Boolean flag indicating whether the checksum is valid or not.
    bool verify();

    /// Get the calculated checksum value.
    /// @return : The calculated checksum value for added fields.
    bit<16> get();

    /// Subtract all header fields after the current state and
    /// return the calculated checksum value.
    /// Marks the end position for residual checksum header.
    /// All header fields extracted after will be automatically subtracted.
    /// @param residual : The calculated checksum value for added fields.
    void subtract_all_and_deposit<T>(out T residual);
 
    /// Calculate the checksum for a  given list of fields.
    /// @param data : List of fields contributing to the checksum value.
    /// @param zeros_as_ones : encode all-zeros value as all-ones.
    bit<16> update<T>(in T data, @optional in bool zeros_as_ones);
}

// ----------------------------------------------------------------------------
// PARSER COUNTER
// ----------------------------------------------------------------------------
// Tofino parser counter can be used to extract header stacks or headers with
// variable length. Tofino has a single 8-bit signed counter that can be
// initialized with an immediate value or a header field.

extern ParserCounter {
    /// Constructor
    ParserCounter();

    /// Load the counter with an immediate value or a header field.
    void set<T>(in T value);

    /// Load the counter with a header field.
    /// @param max : Maximum permitted value for counter (pre rotate/mask/add).
    /// @param rotate : Right rotate (circular) the source field by this number of bits.
    /// @param mask : Mask the rotated source field by 2 ^ (mask + 1) - 1.
    /// @param add : Constant to add to the rotated and masked lookup field.
    void set<T>(in T field,
                in bit<8> max,
                in bit<8> rotate,
                in bit<3> mask,
                in bit<8> add);

    /// @return true if counter value is zero.
    bool is_zero();

    /// @return true if counter value is negative.
    bool is_negative();

    /// Add an immediate value to the parser counter.
    /// @param value : Constant to add to the counter.
    void increment(in bit<8> value);

    /// Subtract an immediate value from the parser counter.
    /// @param value : Constant to subtract from the counter.
    void decrement(in bit<8> value);
}

// ----------------------------------------------------------------------------
// PARSER PRIORITY
// ----------------------------------------------------------------------------
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
extern CRCPolynomial<T> {
    CRCPolynomial(T coeff, bool reversed, bool msb, bool extended, T init, T xor);
}

extern Hash<W> {
    /// Constructor
    /// @type_param W : width of the calculated hash.
    /// @param algo : The default algorithm used for hash calculation.
    Hash(HashAlgorithm_t algo);

    /// Constructor
    /// @param poly : The default coefficient used for hash algorithm.
    Hash(HashAlgorithm_t algo, CRCPolynomial<_> poly);

    /// Compute the hash for the given data.
    /// @param data : The list of fields contributing to the hash.
    /// @return The hash value.
    W get<D>(in D data);
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

extern T max<T>(in T t1, in T t2);

extern T min<T>(in T t1, in T t2);

extern void invalidate<T>(in T field);

/// Phase0
extern T port_metadata_unpack<T>(packet_in pkt);

extern bit<32> sizeInBits<H>(in H h);

extern bit<32> sizeInBytes<H>(in H h);

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

// This is implemented using an experimental feature in p4c and subject to
// change. See https://github.com/p4lang/p4-spec/issues/561
extern RegisterAction<T, I, U> {
    RegisterAction(Register<T, I> reg);

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

    // Abstract method that needs to be implemented when RegisterAction is
    // instantiated.
    // @param value : register value.
    // @param rv : return value.
    @synchronous(execute, execute_log)
    abstract void apply(inout T value, @optional out U rv);

    U predicate(@optional in bool cmplo,
                @optional in bool cmphi); /* return the 4-bit predicate value */
}

extern DirectRegisterAction<T, U> {
    DirectRegisterAction(DirectRegister<T> reg);

    U execute(); /* {
        U rv;
        T value = reg.read();
        apply(value, rv);
        reg.write(value);
        return rv;
    } */

    // Abstract method that needs to be implemented when RegisterAction is
    // instantiated.
    // @param value : register value.
    // @param rv : return value.
    @synchronous(execute)
    abstract void apply(inout T value, @optional out U rv);

    U predicate(@optional in bool cmplo,
                @optional in bool cmphi); /* return the 4-bit predicate value */
}

extern ActionProfile {
    /// Construct an action profile of 'size' entries.
    ActionProfile(bit<32> size);
}

extern ActionSelector {
    /// Construct a selection table for a given ActionProfile.
    ActionSelector(ActionProfile action_profile,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   bit<32> max_group_size,
                   bit<32> num_groups);

    /// Stateful action selector.
    ActionSelector(ActionProfile action_profile,
                   Hash<_> hash,
                   SelectorMode_t mode,
                   Register<bit<1>, _> reg,
                   bit<32> max_group_size,
                   bit<32> num_groups);

    /// Construct a selection table for action profile of 'size' entries.
    @deprecated("ActionSelector must be specified with an associated ActionProfile")
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode);

    @deprecated("ActionSelector must be specified with an associated ActionProfile")
    ActionSelector(bit<32> size, Hash<_> hash, SelectorMode_t mode, Register<bit<1>, _> reg);
}

extern SelectorAction {
    SelectorAction(ActionSelector sel);
    bit<1> execute(@optional in bit<32> index);
    @synchronous(execute)
    abstract void apply(inout bit<1> value, @optional out bit<1> rv);
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

// Tofino supports packet resubmission at the end of ingress pipeline. When
// a packet is resubmitted, the original packet reference and some limited
// amount of metadata (64 bits) are passed back to the packet’s original
// ingress buffer, where the packet is enqueued again.
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

// Algorithmic TCAM.
// Specify the implementation of a table to be algorithmic TCAM by providing an
// instance of the extern to the 'implementation' attribute of the table.  User
// must also specify one of the table keys with 'atcam_partition_index'
// match_kind.
extern Atcam {
    /// define the parameters for ATCAM table.
    Atcam(@optional bit<32> number_partitions);
}

// Algorithmic LPM.
// Specify the implementation of a table to be algorithmic LPM by providing an
// instance of the extern to the 'implementation' attribute of the table.
extern Alpm {
    /// define the parameters for ALPM table.
    Alpm(@optional bit<32> number_partitions, @optional bit<32> subtrees_per_partition);
}
# 24 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tna.p4" 2

// The following declarations provide a template for the programmable blocks in
// Tofino.

parser IngressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    @optional out ingress_intrinsic_metadata_t ig_intr_md,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr);

parser EgressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    @optional out egress_intrinsic_metadata_t eg_intr_md,
    @optional out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

control IngressT<H, M>(
    inout H hdr,
    inout M ig_md,
    @optional in ingress_intrinsic_metadata_t ig_intr_md,
    @optional in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    @optional inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

control EgressT<H, M>(
    inout H hdr,
    inout M eg_md,
    @optional in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    @optional inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);

control IngressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    @optional in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional in ingress_intrinsic_metadata_t ig_intr_md);

control EgressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    @optional in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

package Pipeline<IH, IM, EH, EM>(
    IngressParserT<IH, IM> ingress_parser,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParserT<EH, EM> egress_parser,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser);

@pkginfo(arch="TNA", version="1.0.1")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);

package IngressParsers<H, M>(
    IngressParserT<H, M> prsr0,
    @optional IngressParserT<H, M> prsr1,
    @optional IngressParserT<H, M> prsr2,
    @optional IngressParserT<H, M> prsr3,
    @optional IngressParserT<H, M> prsr4,
    @optional IngressParserT<H, M> prsr5,
    @optional IngressParserT<H, M> prsr6,
    @optional IngressParserT<H, M> prsr7,
    @optional IngressParserT<H, M> prsr8,
    @optional IngressParserT<H, M> prsr9,
    @optional IngressParserT<H, M> prsr10,
    @optional IngressParserT<H, M> prsr11,
    @optional IngressParserT<H, M> prsr12,
    @optional IngressParserT<H, M> prsr13,
    @optional IngressParserT<H, M> prsr14,
    @optional IngressParserT<H, M> prsr15,
    @optional IngressParserT<H, M> prsr16,
    @optional IngressParserT<H, M> prsr17);

package EgressParsers<H, M>(
    EgressParserT<H, M> prsr0,
    @optional EgressParserT<H, M> prsr1,
    @optional EgressParserT<H, M> prsr2,
    @optional EgressParserT<H, M> prsr3,
    @optional EgressParserT<H, M> prsr4,
    @optional EgressParserT<H, M> prsr5,
    @optional EgressParserT<H, M> prsr6,
    @optional EgressParserT<H, M> prsr7,
    @optional EgressParserT<H, M> prsr8,
    @optional EgressParserT<H, M> prsr9,
    @optional EgressParserT<H, M> prsr10,
    @optional EgressParserT<H, M> prsr11,
    @optional EgressParserT<H, M> prsr12,
    @optional EgressParserT<H, M> prsr13,
    @optional EgressParserT<H, M> prsr14,
    @optional EgressParserT<H, M> prsr15,
    @optional EgressParserT<H, M> prsr16,
    @optional EgressParserT<H, M> prsr17);

package MultiParserPipeline<IH, IM, EH, EM>(
    IngressParsers<IH, IM> ig_prsr,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParsers<EH, EM> eg_prsr,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser);

package MultiParserSwitch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
                          IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    MultiParserPipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional MultiParserPipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional MultiParserPipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional MultiParserPipeline<IH3, IM3, EH3, EM3> pipe3);
# 12 "spine.p4" 2

# 1 "table_profile.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "hw_defs.h" 1
/****************************************************************
 * Copyright (c) Kaloom, 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/






/* KTEP_HW_L2_TABLE_SIZE is the size of vnet_dmac table */



/* TODO: merge vnet_smac tables into one big table */



/* 128 kvteps x 128 remote_vteps */
# 33 "hw_defs.h"
/* ID of the destination IP address of HOSTDEV */






/* Max LAG group size */
# 14 "table_profile.p4" 2


const bit<32> L2_INGRESS_TABLE_SIZE = 1024;
const bit<32> ROUTING_IPV6_TABLE_SIZE = 10000;

/* Number of ECMP groups (ECMP_GROUP_TABLE_SIZE) must be < (ECMP_SELECT_TABLE_SIZE
 * divided by MEMBER_NUM_PER_ENTRY).
 */
const bit<32> ECMP_GROUPS_TABLE_SIZE = 1024;
/* ECMP_SELECTION_TABLE_SIZE indicates the total number of members (for all groups)
 * in the action profile.
 */
const bit<32> ECMP_SELECTION_TABLE_SIZE = 16384;
const bit<32> ECMP_SELECTION_MAX_GROUP_SIZE = 128;
/* PORT_FAILOVER_TABLE_SIZE should be calculated based on ECMP action profile
 * size x potential entry repetition (2 in our case).
 */
const bit<32> PORT_FAILOVER_TABLE_SIZE = 32768;
const bit<32> L2_EGRESS_TABLE_SIZE = 512;

/* Port failover */
const bit<32> port_failover_register_instance_count = 131072;
# 14 "spine.p4" 2
# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tna.p4" 1
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
# 14 "./core/types.p4" 2




typedef bit<48> mac_addr_t;
typedef bit<8> mac_addr_id_t;
typedef bit<16> ethertype_t;
typedef bit<12> vlan_id_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<56> knid_t;
typedef bit<32> port_failover_reg_index_t;
typedef bit<32> ecmp_group_id_t; /* TODO: use 16 bits when compiler is fixed. */

typedef PortId_t port_id_t;
typedef MirrorId_t mirror_id_t;
typedef QueueId_t queue_id_t;

const port_id_t RECIRC_PORT_PIPE_0 = 68;

const bit<8> POSTCARD_VERSION = 0x1;

/* Drop control codes */
const bit<3> DROP_CTL_UNICAST_MULTICAST_RESUBMIT = 0x1;
const bit<3> DROP_CTL_COPY_TO_CPU = 0x2;
const bit<3> DROP_CTL_MIRRORING = 0x4;
const bit<3> DROP_CTL_ALL = DROP_CTL_UNICAST_MULTICAST_RESUBMIT
                            | DROP_CTL_COPY_TO_CPU
                            | DROP_CTL_MIRRORING;

/* Field in bridged metadata or mirror metadata that identifies if the
 * packet is a mirror.
 */
typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGE = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONE_EGRESS = 3;
const switch_pkt_src_t SWITCH_PKT_SRC_COALESCED = 5;

/* Different types of packet mirroring.
 * In ingress, set ig_intr_md_for_dprsr.mirror_type and in egress,
 * set eg_intr_md_for_dprsr.mirror_type. Since there are two metadata fields,
 * it acceptable to use overlapping IDs for ingress and egress.
 */
const bit<3> MIRROR_TYPE_NONE = 0;
const bit<3> MIRROR_TYPE_I2I = 1;
const bit<3> MIRROR_TYPE_I2E = 2;
const bit<3> MIRROR_TYPE_E2E = 1;
const bit<3> MIRROR_TYPE_E2I = 2;

/* Fabric metadata */
struct ig_fabric_metadata_t {
    ipv6_addr_t lkp_ipv6_addr; /* Carries key for the lookup in routing_ipv6 and neighbor tables */
    port_id_t cpu_port; /* CPU port ID */
    bit<1> routing_lkp_flag; /* Indicates if routing table lookup should be performed */
    bit<1> l2_ingress_lkp_flag; /* Indicates if l2 ingress table lookup should be performed */
    bit<1> l2_egress_lkp_flag; /* Indicates if l2 egress table lookup should be performed */
    ecmp_group_id_t ecmp_grp_id; /* A key used to lookup in ECMP_groups table */
    mac_addr_id_t neigh_mac; /* Carries mac ID of neighbor MAC address */
    bit<16> flow_hash; /* Hash value of the overlay flow */
}

struct eg_fabric_metadata_t {
    bit<1> l2_egress_lkp_flag; /* Indicates if l2 egress table lookup should be performed */
    mac_addr_id_t neigh_mac; /* Carries mac ID of neighbor MAC address */
    port_id_t cpu_port; /* Recalculated in egress, does not need to be bridged. */
    bit<16> flow_hash;
}

struct bridged_fabric_metadata_t {
    @flexible mac_addr_id_t neigh_mac;
    @flexible bit<1> l2_egress_lkp_flag;
    @flexible bit<16> flow_hash;
}

/* Metadata header used in mirror packets. This does not necessarily match
 * the header definition below because the compiler can add padding.
 */
const bit<16> MIRROR_SIZE = 24;

header eg_mirror_metadata_t {
    switch_pkt_src_t src;
    @flexible mirror_id_t session_id;
    @flexible port_id_t ingress_port;
    @flexible port_id_t egress_port;
    @flexible queue_id_t queue_id;
    @flexible bit<19> queue_depth;
    @flexible bit<48> ingress_tstamp;
    @flexible bit<48> egress_tstamp;
    @flexible bit<8> sequence_num;
}

/* Telemetry metadata */
struct eg_tel_metadata_t {
    bit<1> generate_postcard; /* Set to generate a postcard */
    bit<1> watchlist_hit; /* Set when a packet matches a watchlist rule */
}

struct eg_parser_metadata_t {
    bit<8> clone_src;
}
# 14 "core/headers/headers.p4" 2

const ethertype_t ETHERTYPE_IPV6 = 0x86dd;
const ethertype_t ETHERTYPE_IPV4 = 0x0800;
const ethertype_t ETHERTYPE_DP_CTRL = 0x99ff;
const ethertype_t ETHERTYPE_VLAN = 0x8100;
const ethertype_t ETHERTYPE_BF_PKTGEN = 0x9001;

const bit<4> IPV6_VERSION = 0x6;
const bit<4> IPV4_VERSION = 0x4;

const bit<8> UDP_PROTO = 0x11;
const bit<8> TCP_PROTO = 0x6;
const bit<8> HOP_LIMIT = 64;

const bit<16> KNF_UDP_DST_PORT = 0x38C7;
const bit<16> KNF_UDP_SRC_PORT = 0;
const bit<16> UDP_PORT_VXLAN = 4789;
const bit<16> UDP_PORT_TEL_REPORT = 0x7FFF;

const bit<16> ETH_SIZE = 14;
const bit<16> IPV4_SIZE = 20;
const bit<16> IPV6_SIZE = 40;
const bit<16> UDP_SIZE = 8;
const bit<16> KNF_SIZE = 12;
const bit<16> VXLAN_SIZE = 8;
const bit<16> POSTCARD_SIZE = 36;

const bit<3> PKTGEN_APP_PORT_FAILOVER = 0x2;

header pktgen_ext_header_t {
    bit<48> pad;
    ethertype_t etherType;
}

/* Header definition used for lookahead of ethertype */
header check_ethertype_t {
    bit<96> _pad;
    ethertype_t etherType;
}

/* Header definition used for lookahead of pktgen packets */
header check_pktgen_t {
    bit<3> _pad0;
    bit<2> pipe_id;
    bit<3> app_id;
}

header ethernet_t {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    ethertype_t etherType;
}

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    ipv6_addr_t srcAddr;
    ipv6_addr_t dstAddr;
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
    ipv4_addr_t srcAddr;
    ipv4_addr_t dstAddr;
}

/* Carries metadata for packets that are forwarded to/from CPU */
header dp_ctrl_header_t {
    bit<5> _pad0; /* This padding is needed because the ring identifier corresponds
                    * to the 3 lower bits in the first byte of the packet
                    */
    bit<3> ring_id; /* Ring Identifier */
    bit<72> _pad1; /* 9 Bytes of padding needed to match a regular Ethernet Header size */
    bit<16> port; /* input/output port */
    bit<16> etherType; /* Ethertype of ETHERTYPE_DP_CTRL */
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vlanID;
    ethertype_t etherType;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> hdrLen;
    bit<16> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNum;
    bit<32> ackNum;
    bit<4> dataOffset;
    bit<4> reserved;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header vxlan_t {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

header knf_t {
    bit<4> version;
    bit<4> pType;
    knid_t knid; /* OEType : 8; IDID : 16; VNI : 32; */
    /* bit<16> hdrMap; */
    bit<16> remoteLagID; /* TODO: this field used to be hdrMap. We need to put 
                          * it back when KNF header extensions are supported.
                          */
    bit<1> hdrElided;
    bit<1> doNotLearn;
    bit<6> reserved;
    bit<8> telSequenceNum;
}

header postcard_header_t {
    bit<8> version;
    bit<16> reserved;
    bit<8> sequence_num;
    bit<64> switch_id;
    bit<16> ingress_port;
    bit<16> egress_port;
    bit<8> queue_id;
    bit<24> queue_depth;
    bit<64> ingress_tstamp;
    bit<64> egress_tstamp;
}
# 15 "spine.p4" 2
# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "spine.p4" 2
# 1 "parde.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "parde.p4" 2
# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "parde.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "/home/parallels/bf-sde-9.1.0.19-pr/install/share/p4c/p4include/tofino.p4" 1
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
# 14 "types.p4" 2

# 1 "core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "types.p4" 2
# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "types.p4" 2

/* Port Metadata. Must be 64 bits. This is currently a 64-bit pad as there is no
 * port metadata in the spine. It is done like this so that the tofino parser
 * can be used by both applications.
 */
header port_metadata_t {
    bit<64> pad0;
}

/* User-defined metadata carried over from ingress to egress */
header bridged_metadata_t {
    switch_pkt_src_t src;
    @flexible port_id_t ingress_port;
    @flexible bit<48> ingress_tstamp;
    bridged_fabric_metadata_t fabric_meta;
}

/* Ingress Metadata */
struct ingress_metadata_t {
    port_metadata_t port_md;
    ig_fabric_metadata_t fabric_meta;
}
@pa_alias("ingress", "hdr.bridged_md.fabric_meta_neigh_mac", "ig_md.fabric_meta.neigh_mac")

/* Egress Metadata */
@pa_no_overlay("egress", "eg_md.mirror.src")
@pa_no_overlay("egress", "eg_md.mirror.session_id")
@pa_no_overlay("egress", "eg_md.mirror.ingress_port")
@pa_no_overlay("egress", "eg_md.mirror.egress_port")
@pa_no_overlay("egress", "eg_md.mirror.queue_id")
@pa_no_overlay("egress", "eg_md.mirror.queue_depth")
@pa_no_overlay("egress", "eg_md.mirror.ingress_tstamp")
@pa_no_overlay("egress", "eg_md.mirror.egress_tstamp")
@pa_no_overlay("egress", "eg_md.mirror.sequence_num")
struct egress_metadata_t {
    port_id_t ingress_port;
    eg_parser_metadata_t parser_metadata;
    eg_mirror_metadata_t mirror;
    eg_tel_metadata_t tel_metadata;
    eg_fabric_metadata_t fabric_meta;
}

/* Header structure */
@pa_no_overlay("ingress", "hdr.dp_ctrl_hdr.ring_id")
struct header_t {
    bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl_hdr;
    pktgen_port_down_header_t pktgen_port_down;
    pktgen_ext_header_t pktgen_ext_header;
    ethernet_t ethernet;
    ipv6_t ipv6;
    udp_t udp;
    knf_t knf;
    postcard_header_t postcard_header;
    ethernet_t inner_ethernet;
}
# 16 "parde.p4" 2
# 1 "core/parsers/tofino_parser.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




parser TofinoIngressParser(
        packet_in pkt,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        /* Parse resubmitted packet here */
        transition reject;
    }

    state parse_port_metadata {
        pkt.extract(ig_md.port_md);
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
# 17 "parde.p4" 2
# 1 "core/deparsers/egress_mirror.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/* Egress to Egress Mirroring */
control EgressMirror(
    in egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Mirror() mirror;

    apply {
        if (eg_intr_md_for_dprsr.mirror_type == MIRROR_TYPE_E2E) {
            mirror.emit<eg_mirror_metadata_t>(eg_md.mirror.session_id,
                    eg_md.mirror);
        }
    }
}
# 18 "parde.p4" 2

/* Ingress Parser */
parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_md, ig_intr_md);

        /* Initialize Metadata to Zero */
        ig_md.fabric_meta.routing_lkp_flag = 0;
        ig_md.fabric_meta.l2_egress_lkp_flag = 0;

        /* To differentiate between ethernet packets, dp_ctrl packets and
         * pktgen packets we need to lookahead at the ethertype field which
         * starts from bit 96 (2 x 48 bits) and is encoded in 16 bits.
         */
        check_ethertype_t tmp = pkt.lookahead<check_ethertype_t>();
        transition select(tmp.etherType) {
            ETHERTYPE_BF_PKTGEN : parse_pktgen_header;
            ETHERTYPE_DP_CTRL : parse_dp_ctrl;
            default : parse_ethernet;
        }
    }

    /* The first 48 bits in pktgen packet contain application-specific fields
     * where 3 bits starting from the 5th bit encode the application identifier.
     * In the following parser state we need to lookahead at app_id field.
     * If its value equals 0x2 then we know it's a port down pktgen packet.
     */
    state parse_pktgen_header {
        check_pktgen_t tmp = pkt.lookahead<check_pktgen_t>();
        transition select(tmp.app_id) {
            PKTGEN_APP_PORT_FAILOVER : parse_pktgen_port_down;
            default : accept;
        }
    }

    /* Pktgen port down packet uses the first 48 bits from the beginning of the
     * packet (which is the position of destination MAC address) to populate
     * the following fields :
     *       _pad0     :  3;
     *       pipe_id   :  2;
     *       app_id    :  3;
     *       _pad1     : 15;
     *       port_num  :  9;
     *       packet_id : 16;
     */
    state parse_pktgen_port_down {
        pkt.extract(hdr.pktgen_port_down);
        transition parse_pktgen_ext_header;
    }

    /* Pktgen extension header is used to fill the bits of the equivalent of
     * source MAC address with '0' so that the etherType is placed in the same
     * position as a regular ethernet packet.
     * Pktgen extension header fields are the following :
     *       pad : 48;
     *       etherType : 16;
     */
    state parse_pktgen_ext_header {
        pkt.extract(hdr.pktgen_ext_header);
        transition accept;
    }

    state parse_dp_ctrl {
        pkt.extract(hdr.dp_ctrl_hdr);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        ig_md.fabric_meta.routing_lkp_flag = 1;
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            KNF_UDP_DST_PORT : parse_knf;
            default : accept;
        }
    }

    state parse_knf {
        pkt.extract(hdr.knf);
        transition accept;
    }
}

/* Ingress Deparser */
control SwitchIngressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.dp_ctrl_hdr);
        pkt.emit(hdr.pktgen_port_down);
        pkt.emit(hdr.pktgen_ext_header);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.knf);
    }
}

/* Egress Parser */
parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        switch_pkt_src_t src = pkt.lookahead<switch_pkt_src_t>();
        transition select(src) {
            SWITCH_PKT_SRC_BRIDGE : parse_bridged_metadata;
            SWITCH_PKT_SRC_CLONE_EGRESS : parse_mirrored_packet;
            default : reject;
        }
    }

    state parse_mirrored_packet {
     pkt.extract(eg_md.mirror);
        eg_md.parser_metadata.clone_src = eg_md.mirror.src;
        transition accept;
    }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);

        /* Copy all bridged metadata fields to eg_md fields */
        eg_md.ingress_port = hdr.bridged_md.ingress_port;
        eg_md.parser_metadata.clone_src = hdr.bridged_md.src;

        /* Fabric Metadata */
        eg_md.fabric_meta.l2_egress_lkp_flag = hdr.bridged_md.fabric_meta.l2_egress_lkp_flag;
        eg_md.fabric_meta.neigh_mac = hdr.bridged_md.fabric_meta.neigh_mac;

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV6 : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            UDP_PROTO : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            KNF_UDP_DST_PORT : parse_knf;
            default : accept;
        }
    }

    state parse_knf {
        pkt.extract(hdr.knf);
        transition accept;
    }
}

/* Egress Deparser */
control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    EgressMirror() egress_mirror;

    apply {
        egress_mirror.apply(eg_md, eg_intr_md_for_dprsr);
        pkt.emit(hdr.dp_ctrl_hdr);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv6);
        pkt.emit(hdr.udp);
        pkt.emit(hdr.knf);
        pkt.emit(hdr.postcard_header);
        pkt.emit(hdr.inner_ethernet);
    }
}
# 17 "spine.p4" 2
# 1 "types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 18 "spine.p4" 2
# 1 "core/modules/common.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/* Action used to bypass the egress pipeline and directly forward the packet
 * to output. It is used when there is no more processing required like
 * when control packets are coming from CPU.
 */
control BypassAndExit(out ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action bypass_and_exit() {
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    apply {
        bypass_and_exit();
    }
}
# 19 "spine.p4" 2
# 1 "core/modules/cpu.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/cpu.p4" 2

/* Get the CPU port value set by the control plane and Set the Ring ID metadata */
control CPUPort(out port_id_t cpu_port_id, out bit<3> ring_id) {
    /* The register ring_id_counter and the associated RegisterAction are used
     * to loop around the 8 lanes of pcie in a round-robin fashion.
     */
    const bit<32> ring_id_counter_instance_count = 1;
    Register<bit<8>, bit<1>>(ring_id_counter_instance_count, 0) ring_id_counter;
    RegisterAction<bit<8>, bit<1>, bit<3>>(ring_id_counter) generate_ring_id = {
        void apply(inout bit<8> val, out bit<3> rv) {
            if (val < 7) {
                val = val + 1;
            } else {
                val = 0;
            }
            rv = (bit<3>)val;
        }
    };

    // TODO: Is the index argument necessary? Can it be hard-coded?
    action get_cpu_port_(port_id_t port_id, bit<1> index) {
        cpu_port_id = port_id;
        ring_id = generate_ring_id.execute(index);
    }

    table cpu_port {
        key = {}
        actions = {
            get_cpu_port_;
        }

        /* Setting default action suppresses uninitialized parameter warnings.
         * The default action must be modified by the controller with the correct
         * CPU port ID.
         */
        default_action = get_cpu_port_(0, 0);
        size = 1;
    }

    apply {
        cpu_port.apply();
    }
}

/* Resetting cpu_port in egress pipeline as action data by the host reduces its 
 * life range in ingress pipeline and lowers the size of bridged metadata.
 */
control EgressCPUPort(inout egress_metadata_t eg_md) {

    action get_cpu_port_hit(port_id_t cpu_port) {
        eg_md.fabric_meta.cpu_port = cpu_port;
    }

    table get_cpu_port {
        key = {}
        actions = {
            get_cpu_port_hit;
        }
        default_action = get_cpu_port_hit(0);
        size = 1;
    }

    apply {
        get_cpu_port.apply();
    }
}
# 20 "spine.p4" 2
# 1 "core/modules/fabric.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "./core/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "core/modules/fabric.p4" 2
# 1 "./core/modules/port_failover.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/





control PortFailover(
        inout header_t hdr,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> port_failover_table_size,
        Register<bit<1>, port_failover_reg_index_t> port_failover_reg,
        RegisterAction<bit<1>, port_failover_reg_index_t, bit<1>> port_failover_register_action) {

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    /* Deactivate entry by clearing its bound register in the register array. */
    action port_failover_deactivate_entry(port_failover_reg_index_t index) {
        /* deactivate ecmp member by calling execute_stateful_alu to clear the
         * register.
         */
        port_failover_register_action.execute(index);
    }

    /* Deactivate entry by clearing its bound register in the register array.
     * This action is the last port-to-index pain, recirculate portdown packet to
     * next pipe.
     */
    action port_failover_deactivate_entry_last_member(port_failover_reg_index_t index) {
        /* deactivate ecmp member by calling execute_stateful_alu to clear the
         * register.
         */
        port_failover_register_action.execute(index);
    }

    action port_failover_miss() {
        drop_packet();
    }

    /* Workaround for Barefoot Case #9630 */




    /* Since the port_failover table accesses the register array named
     * "port_failover_reg" that is bound to the ecmp_groups table, both tables must
     * be in the same stage.
     */

    @stage(5)


    /* port_failover is used to translate port number into a register index that is
     * bound to the ECMP defined by this port number.
     * This table is updated by a callback after each ECMP member addition.
     * "packet_id" is used to disable multiple registers within the same pipe.
     */
    table port_failover {
        key = {
            hdr.pktgen_port_down.port_num : exact;
            hdr.pktgen_port_down.packet_id : exact;
        }
        actions = {
            port_failover_deactivate_entry;
            port_failover_deactivate_entry_last_member;
            port_failover_miss;
        }
        default_action = port_failover_miss();
        size = port_failover_table_size;
    }

    action recirc_failover_pkt(port_id_t recirc_port) {
        /* Set packet_id to 0 to start deactivating entry from the beginning. */
        hdr.pktgen_port_down.packet_id = 0;
        ig_tm_md.ucast_egress_port = recirc_port;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action port_failover_recirc_miss() {
        drop_packet();
    }

    /* Recirculate the port down packet to be processed by the other pipes.
     * The last pipe must drop the port down packet.
     */
    table port_failover_recirc {
        key = {
            hdr.pktgen_port_down.pipe_id : exact;
        }
        actions = {
            recirc_failover_pkt;
            port_failover_recirc_miss;
        }
        size = 2;
    }

    /* If one port is shared by multiple ECMP entries, we need to recirculate the
     * portdown packet to the same port after incrementing the instance_id/packet_id
     * to deactivate all entries that has this port as their destination.
     * Thus, this action sets the recirculation port number of the same pipe.
     */
    action recirc_to_same_pipe() {
        /* Add 1 to packet_id to fetch the next entry in failover table. */
        hdr.pktgen_port_down.packet_id = hdr.pktgen_port_down.packet_id + 1;
        ig_tm_md.ucast_egress_port[8:7] = (bit<2>)(ig_intr_md.ingress_port >> 7);
        ig_tm_md.ucast_egress_port[6:0] = (bit<7>)RECIRC_PORT_PIPE_0;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    apply {
        if (hdr.pktgen_port_down.isValid() && hdr.pktgen_ext_header.isValid()) {
            /* The valid condition wasn't enough for capturing only pktgen packets.
             * lldp packets were matching also this condition.
             * therefore, an extra condition was added to check pktgen ethertype
             * and block lldp packets from matching port failover table.
             * TODO: remove ethertype condition and re-test with lldp packets
             */
            if (hdr.pktgen_ext_header.etherType == ETHERTYPE_BF_PKTGEN) {
                switch(port_failover.apply().action_run) {
                    port_failover_deactivate_entry_last_member : {
                        port_failover_recirc.apply();
                    }
                    /* Using if condition to apply recirc_to_same_pipe did not work.
                     * So it was replaced by this code to apply recirc_to_same_pipe
                     * if the action is not of type
                     * "port_failover_deactivate_entry_last_member". This replaces
                     * the use of isLastMember parameter from the table, but it
                     * requires removing the entry and adding it with new action
                     * type in order to update it.
                     */
                    port_failover_deactivate_entry : {
                        recirc_to_same_pipe();
                    }
                }
            }
        }
    }
}
# 15 "core/modules/fabric.p4" 2

control L2Ingress(
        inout header_t hdr,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> l2_ingress_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) l2_ingress_cntr;

    action l2_ingress_miss() {
        l2_ingress_cntr.count();
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action l2_ingress_send_to_cpu_hit() {
        l2_ingress_cntr.count();
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = fabric_meta.cpu_port;
        /* TODO: The p4-14 code does not bypass_egress - workaround for BF 8844 */
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    /* Receive from the CPU */
    action l2_ingress_process_cpu_packet() {
        l2_ingress_cntr.count();
        /* Set egress port */
        ig_tm_md.ucast_egress_port = (port_id_t)hdr.dp_ctrl_hdr.port;
        /* Pop dp_ctrl_header */
        hdr.dp_ctrl_hdr.setInvalid();
        fabric_meta.routing_lkp_flag = 0;
    }

    /* If a packet hits this action then it will be forwarded to the routing
     * block
     */
    action l2_ingress_router_iface_hit() {
        l2_ingress_cntr.count();
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    /* l2_ingress table classifies incoming packets and forward to the
     * corresponding block. Ternary match is needed so that we can mask the
     * port id for an lldp packet arriving at any port also ternary is needed
     * if we want to mask dest_mac for multicast cases.
     */
    table l2_ingress {
        key = {
            ig_intr_md.ingress_port : ternary;
            hdr.ethernet.dstAddr : ternary;
        }
        actions = {
            l2_ingress_router_iface_hit;
            l2_ingress_send_to_cpu_hit;
            l2_ingress_process_cpu_packet;
            l2_ingress_miss;
        }

        const default_action = l2_ingress_miss();
        size = l2_ingress_table_size;
        counters = l2_ingress_cntr;
    }

    apply {
        l2_ingress.apply();
    }
}

control FabricRouting(
        inout header_t hdr,
        inout ig_fabric_metadata_t fabric_meta,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
        bit<32> routing_ipv6_table_size,
        bit<32> neighbor_table_size,
        bit<32> ecmp_groups_table_size,
        bit<32> ecmp_selection_table_size,
        bit<32> ecmp_selection_max_group_size,
        Register<bit<1>, port_failover_reg_index_t> port_failover_reg) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) routing_ipv6_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) neighbor_cntr;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) ecmp_groups_cntr;

    action drop_packet() {
        ig_dprsr_md.drop_ctl = DROP_CTL_ALL;
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    /* The packet can be sent directly to the destination device and does not need
     * to be sent via another router.
     */
    action routing_dcn_hit() {
        routing_ipv6_cntr.count();
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    /* The host is accessible via another router */
    action routing_nh_hit(ipv6_addr_t nexthop_ipv6) {
        routing_ipv6_cntr.count();
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = nexthop_ipv6;
    }

    action routing_to_host() {
        routing_ipv6_cntr.count();
        hdr.dp_ctrl_hdr.setValid();
        hdr.dp_ctrl_hdr.etherType = ETHERTYPE_DP_CTRL;
        hdr.dp_ctrl_hdr.port = (bit<16>)ig_intr_md.ingress_port;
        ig_tm_md.ucast_egress_port = fabric_meta.cpu_port;
        /* TODO: The p4-14 code does not bypass_egress - workaround for BF 8844 */
        ig_tm_md.bypass_egress = 1;
        exit;
    }

    action routing_ecmp(ecmp_group_id_t ecmp_grp_id) {
        routing_ipv6_cntr.count();
        fabric_meta.ecmp_grp_id = ecmp_grp_id;
    }

    action routing_miss() {
        routing_ipv6_cntr.count();
        drop_packet();
    }

    /* Routing_ipv6 table performs a lookup on the packet ipv6 destination
     * address. This table allows to differentiate between DCN and NH routes.
     * In case it's a DCN route then it sets fabric_meta.lkp_ipv6_addr to the
     * destination IP in the packet.
     * If it's a NH route then it sets fabric_meta.lkp_ipv6_addr to the IP of
     * the NH.
     * If it's a local IP the packet is sent to Host CPU.
     * If it's an ECMP action, set a flag to resolve nexthop IP using
     * ecmp_groups table
     * In case of a table miss the packet is dropped.
     */
    table routing_ipv6 {
        key = {
            fabric_meta.lkp_ipv6_addr : lpm;
        }
        actions = {
            routing_to_host;
            routing_dcn_hit;
            routing_nh_hit;
            routing_ecmp;
            routing_miss;
        }
        const default_action = routing_miss();
        size = routing_ipv6_table_size;
        counters = routing_ipv6_cntr;
    }

    /* Sets the destination MAC and the egress port */
    action neighbor_hit(mac_addr_id_t neigh_mac, port_id_t egress_port) {
        neighbor_cntr.count();
        fabric_meta.neigh_mac = neigh_mac;
        ig_tm_md.ucast_egress_port = egress_port;
    }

    action neighbor_miss() {
        neighbor_cntr.count();
        drop_packet();
    }

    /* Neighbor table sets the destination mac and the egress port after
     * performing an exact match (/128) on the IPv6 address resolved in the
     * previous lookup from the routing_ipv6 table.
     */
    table neighbor {
        key = {
            fabric_meta.lkp_ipv6_addr : exact;
        }
        actions = {
            neighbor_hit;
            neighbor_miss;
        }
        const default_action = neighbor_miss();
        size = neighbor_table_size;
        counters = neighbor_cntr;
    }

    Hash<bit<16>>(HashAlgorithm_t.CRC16) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_selector;
    ActionSelector(ecmp_selector, selector_hash, SelectorMode_t.FAIR,
            port_failover_reg, ecmp_selection_max_group_size,
            ecmp_groups_table_size) ecmp_selector_sel;


    /* The host is accessible via another router */
    action ecmp_routing_nh_hit(ipv6_addr_t nexthop_ipv6) {
        ecmp_groups_cntr.count();
        fabric_meta.l2_egress_lkp_flag = 1;
        fabric_meta.lkp_ipv6_addr = nexthop_ipv6;
    }

    /* Workaround for Barefoot Case #9630 */



    /* Since the port_failover table accesses the register array named
     * "port_failover_reg" that is bound to the ecmp_groups table, both tables must
     * be in the same stage.
     */

    @stage(5)


    /* ecmp_groups table is used to select one nexthop entry from an ECMP group
     * that is defined for each destination IP.
     * Destimation IP is mapped into an ecmp_group_id using routing_ipv6 table,
     * then this table select one entry from the selected group based on a hashing
     * algorithm defined by a hash calculation algorithm (namely ecmp_hash).
     */
    table ecmp_groups {
        key = {
            fabric_meta.ecmp_grp_id : exact;
            hdr.ipv6.srcAddr : selector;
            hdr.ipv6.dstAddr : selector;
            hdr.ipv6.nextHdr : selector;
            hdr.udp.srcPort : selector;
            hdr.udp.dstPort : selector;
        }
        actions = {
            ecmp_routing_nh_hit;
        }
        size = ecmp_groups_table_size;
        implementation = ecmp_selector_sel;
        counters = ecmp_groups_cntr;
    }

    apply {
        if (fabric_meta.routing_lkp_flag == 1) {
            switch(routing_ipv6.apply().action_run) {
                routing_ecmp : {
                    switch(ecmp_groups.apply().action_run) {
                        ecmp_routing_nh_hit : {
                            neighbor.apply();
                        }
                    }
                }
                routing_dcn_hit :
                routing_nh_hit : {
                    neighbor.apply();
                }
            }
        }
    }
}

/* l2_egress table maps the output port to its MAC address.
 * The source mac of outgoing packets is updated with the resulting MAC addr.
 */
control L2Egress(
        inout header_t hdr,
        in egress_intrinsic_metadata_t eg_intr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)(
        bit<32> l2_egress_table_size) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) l2_egress_cntr;

    action l2_egress_hit(mac_addr_t iface_mac) {
        l2_egress_cntr.count();
        hdr.ipv6.hopLimit = hdr.ipv6.hopLimit - 1;
        hdr.ethernet.srcAddr = iface_mac;
    }

    action l2_egress_miss() {
        l2_egress_cntr.count();
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    @ternary(1)
    table l2_egress {
        key = {
            eg_intr_md.egress_port : exact;
        }
        actions = {
            l2_egress_hit;
            l2_egress_miss;
        }
        const default_action = l2_egress_miss();
        size = l2_egress_table_size;
        counters = l2_egress_cntr;
    }

    apply {
        l2_egress.apply();
    }
}

control CopyNexthopMAC(
        inout header_t hdr,
        in eg_fabric_metadata_t fabric_meta) (
        bit<32> neighbor_table_size) {

    action set_neigh_mac_hit(mac_addr_t mac_addr) {
        hdr.ethernet.dstAddr = mac_addr;
    }

    action set_neigh_mac_miss() {}

    /* Set_neigh_mac table is used for mapping the Neighbor MAC ID address to its 
     * MAC address in the underlay.
     * Today, with the current assumptions like fabric topology and the current hardware 
     * and number of ports and links between spines and leaf switches, a MAC neighbors 
     * table of 256 entries and a MAC ID of 8 bits is enough. 
     * However, if the current assumptions change then we will be able to scale by 
     * incresing the MAC ID size and set_neigh_mac table size.
     * Set_neigh_mac table is placed in stage 10, which is almost fully used because 
     * of the port_failover and lag_failover tables being also placed in stage 10. 
     * Therefore, we are placing the key in the TCAM via the @ternary annotation for 
     * most of the tables in stage 10 to leave more SRAM blocks available for scaling.
     */
    @ternary(1)
    table set_neigh_mac {
        key = {
            fabric_meta.neigh_mac : exact;
        }
        actions = {
            set_neigh_mac_hit;
            set_neigh_mac_miss;
        }
        default_action = set_neigh_mac_miss();
        size = neighbor_table_size;
    }

    apply {
        set_neigh_mac.apply();
    }
}

control EgressDrop(
        in header_t hdr,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    action drop_packet() {
        eg_dprsr_md.drop_ctl = DROP_CTL_ALL;
        exit;
    }

    apply {
        if (hdr.ipv6.hopLimit == 0) {
            drop_packet();
        }
    }
}
# 21 "spine.p4" 2
# 1 "core/modules/port_failover.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 22 "spine.p4" 2
# 1 "core/modules/tel_postcard.p4" 1
/****************************************************************
 * Copyright (c) Kaloom, 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




const mirror_id_t INT_MIRROR_SESSION_ID = 0x1;

/* Perform packet mirroring to be used as postcard report */
control TelE2EMirror(
        inout header_t hdr,
        inout eg_tel_metadata_t tel_metadata,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    action mirror_packet() {
        eg_md.mirror = {
            SWITCH_PKT_SRC_CLONE_EGRESS,
            INT_MIRROR_SESSION_ID,
            eg_md.ingress_port,
            eg_intr_md.egress_port,
            eg_intr_md.egress_qid,
            eg_intr_md.deq_qdepth,
            hdr.bridged_md.ingress_tstamp,
            eg_prsr_md.global_tstamp,
            hdr.knf.telSequenceNum
        };
    }

    /* TODO: @ignore_table_dependency("tel_postcard_insert") */
    action tel_postcard_e2e() {
        eg_dprsr_md.mirror_type = MIRROR_TYPE_E2E;
        mirror_packet();
    }

    apply {
        if (tel_metadata.generate_postcard == 1) {
            tel_postcard_e2e();
        }
    }
}

/* Add telemetry data to the mirrored packet (report) */
control TelGeneratePostcard(
        inout header_t hdr,
        inout eg_tel_metadata_t tel_metadata,
        in eg_mirror_metadata_t mirror,
        in eg_parser_metadata_t eg_intr_md_from_parser_aux, /* Using this name to match P4-14 code */
        in egress_intrinsic_metadata_t eg_intr_md) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) tel_postcard_insert_cntr;

    action tel_mirror_encap(ipv6_addr_t srcip, ipv6_addr_t dstip) {
        hdr.ethernet.setValid();
        hdr.udp.setValid();

        hdr.udp.srcPort = 0;
        hdr.udp.dstPort = UDP_PORT_TEL_REPORT;
        hdr.udp.checksum = 0;
        /* Calculate pkt len = recirculated pkt len + 28B for postcard header */
        const bit<16> pkt_len_adjust = POSTCARD_SIZE + UDP_SIZE - MIRROR_SIZE - 4;
        hdr.udp.hdrLen = eg_intr_md.pkt_length + pkt_len_adjust;
        /* TODO: Verify if we need to add the extra 8 byte of udp length */

        hdr.ipv6.setValid();
        hdr.ipv6.payloadLen = eg_intr_md.pkt_length + pkt_len_adjust;
        hdr.ipv6.version = 0x6;
        hdr.ipv6.nextHdr = UDP_PROTO;
        hdr.ipv6.hopLimit = 64;
        hdr.ipv6.trafficClass = 0;
        hdr.ipv6.flowLabel = 0;

        hdr.ethernet.etherType = ETHERTYPE_IPV6;
        hdr.ipv6.srcAddr = srcip;
        hdr.ipv6.dstAddr = dstip;
        /* smac and dmac must be set after the recirculation. */
    }

    action postcard_insert_common(bit<64> switch_id) {
        hdr.postcard_header.setValid();
        hdr.postcard_header.version = POSTCARD_VERSION;
        hdr.postcard_header.sequence_num = mirror.sequence_num;
        hdr.postcard_header.switch_id = switch_id;
        hdr.postcard_header.ingress_port = (bit<16>)mirror.ingress_port;
        hdr.postcard_header.egress_port = (bit<16>)mirror.egress_port;
        hdr.postcard_header.queue_id = (bit<8>)mirror.queue_id;
        hdr.postcard_header.queue_depth = (bit<24>)mirror.queue_depth;
        hdr.postcard_header.ingress_tstamp = (bit<64>)mirror.ingress_tstamp;
        hdr.postcard_header.egress_tstamp = (bit<64>)mirror.egress_tstamp;
    }

    action postcard_insert(ipv6_addr_t srcip, ipv6_addr_t dstip,
            bit<64> switch_id) {
        tel_postcard_insert_cntr.count();
        tel_mirror_encap(srcip, dstip);
        postcard_insert_common(switch_id);
    }

    action tel_postcard_insert_miss() {
        tel_postcard_insert_cntr.count();
    }

    /* tel_postcard_insert runs on mirrored packets, tel_postcard_e2e runs on 
     * original ones.
     */
    /* TODO: @ignore_table_dependency("tel_postcard_e2e") */
    table tel_postcard_insert {
        key = {
            eg_intr_md_from_parser_aux.clone_src : exact;
        }
        actions = {
            postcard_insert;
            tel_postcard_insert_miss;
        }
        const default_action = tel_postcard_insert_miss();
        size = 3;
        counters = tel_postcard_insert_cntr;
    }

    apply {
        tel_postcard_insert.apply();
    }
}
# 23 "spine.p4" 2

control SwitchIngress(
        inout header_t hdr,
        inout ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    /* This register array is bound to ECMP entries, which means that for every ECMP
     * entry there is one bit that associated with it. If this bit is 1, which means
     * that this entry is active and ECMP selector considers this entry as a valid
     * nexthop. Otherwise, ECMP selector considers it as invalid entry and avoids it.
     * TODO: Put register instance count to a smaller value once Barefoot case
     * #8948 gets resolved.
     */
    Register<bit<1>, port_failover_reg_index_t>(port_failover_register_instance_count) port_failover_reg;

    /* Clears the bit of the register that is bound to ECMP entry.
     * Mapping port_num into a register index is kept in port_failover table.
     * Port_failover table is populated using a callback function that notifies
     * the control plane each time a new entry is added/deleted into
     * ecmp_groups table and the register index bound to it.
     */
    RegisterAction<bit<1>, port_failover_reg_index_t, bit<1>>(port_failover_reg) port_failover_register_action = {
        void apply(inout bit<1> val) {
            val = 0;
        }
    };

    CPUPort() cpu_port;
    L2Ingress(L2_INGRESS_TABLE_SIZE) l2_ingress;
    FabricRouting(ROUTING_IPV6_TABLE_SIZE, 256,
            ECMP_GROUPS_TABLE_SIZE, ECMP_SELECTION_TABLE_SIZE,
            ECMP_SELECTION_MAX_GROUP_SIZE, port_failover_reg) fabric_routing;
    BypassAndExit() bypass_and_exit;
    PortFailover(PORT_FAILOVER_TABLE_SIZE, port_failover_reg,
            port_failover_register_action) port_failover;

    /* Action used to set lkp_ipv6_addr for recirculated packets and continue
     * normal packet processing.
     */
    action process_recirculated_packet() {
        ig_md.fabric_meta.lkp_ipv6_addr = hdr.ipv6.dstAddr;
    }

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.src = SWITCH_PKT_SRC_BRIDGE;
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
        hdr.bridged_md.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;

        /* Fabric Metadata */
        hdr.bridged_md.fabric_meta.l2_egress_lkp_flag = ig_md.fabric_meta.l2_egress_lkp_flag;
    }

    apply {
        cpu_port.apply(ig_md.fabric_meta.cpu_port, hdr.dp_ctrl_hdr.ring_id);

        if (!hdr.pktgen_ext_header.isValid()) {
            if ((ig_intr_md.ingress_port & 0x7f) != RECIRC_PORT_PIPE_0) {
                l2_ingress.apply(hdr, ig_md.fabric_meta, ig_intr_md, ig_tm_md,
                        ig_dprsr_md);
            } else {
                process_recirculated_packet();
            }

            if (ig_intr_md.ingress_port == ig_md.fabric_meta.cpu_port) {
                bypass_and_exit.apply(ig_tm_md);
            }

            fabric_routing.apply(hdr, ig_md.fabric_meta, ig_intr_md, ig_tm_md,
                    ig_dprsr_md);
        } else {
            port_failover.apply(hdr, ig_intr_md, ig_tm_md, ig_dprsr_md);
        }

        /* Only add bridged metadata if we are NOT bypassing egress pipeline. */
        if (ig_tm_md.bypass_egress == 0) {
            add_bridged_md();
        }
    }
}

control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    L2Egress(L2_EGRESS_TABLE_SIZE) l2_egress;
    CopyNexthopMAC(256) copy_nh_mac;
    EgressDrop() egress_drop;
    TelE2EMirror() tel_e2e_mirror;
    TelGeneratePostcard() tel_generate_postcard;

    /* Hardware Config. */
    EgressCPUPort() egress_cpu_port;

    apply {
        if (eg_md.parser_metadata.clone_src == SWITCH_PKT_SRC_BRIDGE) {
            egress_cpu_port.apply(eg_md);

            if (eg_md.fabric_meta.l2_egress_lkp_flag == 1) {
                l2_egress.apply(hdr, eg_intr_md, eg_dprsr_md);
                copy_nh_mac.apply(hdr, eg_md.fabric_meta);
                egress_drop.apply(hdr, eg_dprsr_md);
                if (hdr.knf.isValid() && hdr.knf.telSequenceNum != 0) {
                    /* If knf header is valid and knf.telSequenceNum is set,
                     * then use that as the postcard sequence num.
                     */
                    eg_md.tel_metadata.generate_postcard = 1;
                } else {
                    eg_md.tel_metadata.generate_postcard = 0;
                }
                tel_e2e_mirror.apply(hdr, eg_md.tel_metadata, eg_md,
                        eg_intr_md, eg_prsr_md, eg_dprsr_md);
            }
        } else {
            /* For mirrored packet, generate the postcard report. */
            tel_generate_postcard.apply(hdr, eg_md.tel_metadata, eg_md.mirror,
                    eg_md.parser_metadata, eg_intr_md);
        }
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipe;

Switch(pipe) main;
