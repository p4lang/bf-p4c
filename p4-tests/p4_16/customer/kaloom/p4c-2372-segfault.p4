# 1 "tna_32q_multiprogram_a.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "tna_32q_multiprogram_a.p4"
/*******************************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 11 "tna_32q_multiprogram_a.p4" 2
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tna.p4" 1
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




# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 23 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tna.p4" 2
# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tofino.p4" 1
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




# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/core.p4" 1
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
# 23 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tofino.p4" 2

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
# 24 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tna.p4" 2

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
# 12 "tna_32q_multiprogram_a.p4" 2

# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




/*
 * Default constants and table sizes
 */
const PortId_t DEFAULT_CPU_PORT = 320;
const bit<8> DEFAULT_PUNT_TYPE = 0;

typedef bit<3> ring_id_t;
const ring_id_t KC_RINGID = 0x7;
const ring_id_t POLICY_RINGID = 0x6;
const ring_id_t GTP_RINGID = 0x5;
const ring_id_t DEFAULT_RINGID_SPAN = 0x4;

typedef bit<32> table_size_t;

const table_size_t FLOW_TABLE_UL = 100000;
const table_size_t SESSION_TABLE_UL_1 = 150000;
const table_size_t SESSION_TABLE_UL_2 = 170000;
const table_size_t SESSION_TABLE_UL_3 = 50000;
const table_size_t POLICY_TABLE_UL = 5000;
const table_size_t ACTIONID_TABLE_UL = 200000;

const table_size_t FLOW_TABLE_DL = 40000;
const table_size_t SESSION_TABLE_DL_1 = 10000;
const table_size_t SESSION_TABLE_DL_2 = 175000;
const table_size_t SESSION_TABLE_DL_3 = 30000;
const table_size_t ASSOCIATIVE_TABLE_DL_1 = 1024;
const table_size_t ACTIONID_TABLE_DL = 220000;
const table_size_t POLICY_TABLE_DL = 4000;






/*
 *  Ether types
 */
typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_IPV6 = 16w0x86dd;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_DP_CTRL = 16w0x99ff; // Used for to/from CPU packets for now

/*
 *  Header minimum size
 */
typedef bit<16> size_t;
const size_t ETH_MIN_SIZE = 0x0E;
const size_t IPV4_MIN_SIZE = 0x14;
const size_t IPV6_MIN_SIZE = 0x28;
const size_t UDP_SIZE = 0x08;
const size_t GTP_MIN_SIZE = 0x08;
const size_t VLAN_SIZE = 0x04;

/*
 *  Port number definitions
 */
typedef bit<16> port_t;
const port_t PORT_GTP_U = 2152;

/*
 *  IP Protocol definitions
 */
typedef bit<8> ip_protocol_t;
const ip_protocol_t PROTO_ICMP = 1;
const ip_protocol_t PROTO_UDP = 17;
const ip_protocol_t PROTO_TCP = 6;
const ip_protocol_t PROTO_IPV6 = 41;
const ip_protocol_t PROTO_ICMPV6 = 58;

/*
 *  Type definitions
 */
typedef bit<16> knid_t;
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;
typedef bit<8> protocol_t;

/*
 * Single index indirect counters
 */
typedef bit<1> single_indirect_counter_t;
const single_indirect_counter_t SINGLE_INDIRECT_COUNTER = 1;

/*
 * Action index indirect counters
 */
typedef bit<16> dl_flow_id_indirect_counter_t;
const dl_flow_id_indirect_counter_t DL_FLOW_ID_INDIRECT_COUNTER = 16;
typedef bit<16> ul_flow_id_indirect_counter_t;
const ul_flow_id_indirect_counter_t UL_FLOW_ID_INDIRECT_COUNTER = 16;
typedef bit<16> port_stats_indirect_counter_t;
const ul_flow_id_indirect_counter_t UL_PORT_STATS_INDIRECT_COUNTER = 16;

/*
 *  Padding for extended IPV4
 */
typedef bit<32> padding_32b_t;
const padding_32b_t ZEROS_PADDING_4B = 32w0x00000000;
const padding_32b_t ONES_PADDING_4B = 32w0xFFFFFFFF;
const padding_32b_t MIXED_PADDING_4B = 32w0x0000FFFF;

/*
* Padding for IPV6
*/
typedef bit<64> padding_64b_t;
const padding_64b_t ZEROS_PADDING_8B = 64w0x0000000000000000;
const padding_64b_t ONES_PADDING_8B = 64w0xFFFFFFFFFFFFFFFF;
const padding_64b_t MIXED_PADDING_8B = 64w0x00000000FFFFFFFF;
const padding_64b_t MIXED_SINGLE_FFFF_PADDING_8B = 64w0x000000000000FFFF;

typedef bit<96> padding_96b_t;
const padding_96b_t MIXED_PADDING_12B = 96w0x00000000000000000000FFFF;


/*
 *  Mirroring
 */
typedef MirrorId_t mirror_id_t; // Defined in tna.p4
typedef bit<3> mirror_type_t;

/*
 *  Source of the packet received
 */
typedef bit<3> pkt_src_t;
const pkt_src_t PKT_SRC_BRIDGE = 0;
const pkt_src_t PKT_SRC_CLONE_INGRESS = 1;
const pkt_src_t PKT_SRC_CLONE_EGRESS = 2;

typedef bit<9> port_comp_t;
const port_comp_t PORT_BIT_OR = 0x80;
# 14 "core/headers/headers.p4" 2

/*************************************************************************
********************************** L2  ***********************************
*************************************************************************/

header ethernet_t {
    mac_addr_t dstAddr;
    mac_addr_t srcAddr;
    bit<16> etherType;
}

header vlan_t {
    bit<3> pcp;
    bit<1> cfi;
    vlan_id_t vlanId;
    bit<16> etherType;
}

// Address Resolution Protocol
header arp_t {
    bit<16> hwType;
    bit<16> protoType;
    bit<8> hwAddrLen;
    bit<8> protoAddrLen;
    bit<16> opcode;
}

/*************************************************************************
********************************** L3  ***********************************
*************************************************************************/

header ipv4_t { //Enhanced IP
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    protocol_t protocol;
    bit<16> hdrChecksum;
    ipv4_addr_t srcAddr;
    ipv4_addr_t dstAddr;
}

header ipv6_t {
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payloadLen;
    protocol_t nextHdr;
    bit<8> hopLimit;
    ipv6_addr_t srcAddr;
    ipv6_addr_t dstAddr;
}

header icmp_t {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
    //bit<32>    restOfHeader;
}


/*************************************************************************
********************************** L4  ***********************************
*************************************************************************/
@pa_no_overlay("egress", "hdr.outer_udp.checksum")
@pa_no_overlay("ingress", "hdr.outer_udp.checksum")
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
    bit<3> res;
    bit<9> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
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

header gtp_u_options_t {
    bit<16> seqNumb;
    bit<8> npdu;
    bit<8> neh;
}

/*
 * PDU session container (GTP header extension). More details in 3GPP 
 * spec. 38415 and 29281.
 * Type 0 for downlink (8 bytes)
 * Type 1 for uplink (4 bytes)
 * neh value: 0x85
 * Length of this header should be 4n, thus the padding.
 */
header gtp_u_pdu_sess_cont_0_t {
    bit<8> len;

    bit<4> type;
    bit<4> spare0;
    bit<1> ppp;
    bit<1> rqi;
    bit<6> qfi;
    bit<3> ppi;
    bit<5> spare1;
    bit<24> pad0;

    bit<8> neh;
}

header gtp_u_pdu_sess_cont_1_t {
    bit<8> len;

    bit<4> type;
    bit<6> spare0;
    bit<6> qfi;

    bit<8> neh;
}

/*************************************************************************
*************************  DP Control Header  ****************************
*************************************************************************/

/* Metadata for packets that are forwarded to/from CPU */
/*
 * TODO: Decide what metadata should be fowarded. Padding added for this purpose.
 *       Implement ring id number (should be in a Round Robin fashion for the pal)
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
// user-defined metadata carried over from ingress to egress. 120 bits.
    bit<2> _pad0;
    /* Punt type:
        00: other (0x0)
        01: kc_punt (0x01)
        10: policy_punt (0x2)
        11: gtp_punt (0x3)
    */
    bit<2> punt_type;
    bit<1> n9;
    bit<1> mirrored;
    bit<1> protoEncap;
    bit<1> priority;
    bit<8> session_miss;
    knid_t ingress_knid;
    knid_t knid;
    bit<8> type;
    bit<20> policyId;
    PortId_t ucast_egress_port;
    bit<1> punt;
    bit<1> drop;
    bit<1> flow_table;
    bit<1> policy_lkp_fwd;
    bit<1> bypass_egress;
    PortId_t ingress_port;
    bit<1> policy_hit;
    bit<20> flowId;
// add more fields here.
}
/* For dependency that rely on this size, in bytes and hexadecimal */


/*************************************************************************
************************* Headers declaration ****************************
*************************************************************************/

struct headers {
    upf_bridged_metadata_t bridged_md;
    dp_ctrl_header_t dp_ctrl;
    ethernet_t ethernet;
    vlan_t vlan;
    arp_t arp;
    ipv4_t outer_ipv4;
    ipv6_t outer_ipv6;
    icmp_t icmp;
    udp_t outer_udp;
    tcp_t outer_tcp;
    gtp_u_t gtp_u;
    gtp_u_options_t gtp_u_options;
    ipv4_t inner_ipv4;
    ipv6_t inner_ipv6;
    udp_t inner_udp;
    tcp_t inner_tcp;
}
# 14 "tna_32q_multiprogram_a.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "tna_32q_multiprogram_a.p4" 2

# 1 "UPFIngress1_0.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2019
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "UPFIngress1_0.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "UPFIngress1_0.p4" 2

# 1 "ingress_port_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "ingress_port_table.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "ingress_port_table.p4" 2

# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "metadata.p4" 2

header upf_port_metatdata_t {
    bit<7> _pad ;
    bit<9> port_lag_index;
    bit<16> port_lag_label;
    bit<1> port_type;
    bit<31> _pad1;
}

/*

struct upf_ingress_metadata_t {
    bit<1>       resubmit_flag;
    bit<1>       drop;
    bit<2>       packet_version;
    bit<1>       punt;
    bit<1>       kc_punt;
    bit<7>       priority;
    bit<9>       cpu_port;
    port_t       srcPort;          
    port_t       dstPort;         
    bit<64>      srcAddr64;
    bit<64>      dstAddr64;
    protocol_t   protocol;
    knid_t       knid;
    bit<32>      srvcId;
    bit<8>       type;
    ring_id_t    ring_span;
    ring_id_t    kc_ring_id;
    ring_id_t    policy_ring_id;
    ring_id_t    gtp_ring_id;
    bit<1>       policy_punt;
    bit<1>       policy_lkp_fwd;
    bit<1>       gtp_punt;
}
*/

struct local_metadata_t {
    bit<1> policy_hit;
    bit<64> dstPrefix;
}

//=============================================================================
// Egress metadata
//=============================================================================

struct upf_egress_metadata_t {
    bit<16> pkt_length;
    bit<32> srcAddrv4;
    bit<128> srcAddrv6;
    bit<128> dstAddrv6;
    protocol_t nextHdrv6;
    knid_t knid;
    ipv6_addr_t dstAddr;
    bit<32> teid;
    bit<1> protoEncap;
    bit<1> protocol;
    bit<20> flowId;
    bit<16> flen;
    bit<16> portStatsId;
}


//=============================================================================
// Ingres metadata
//=============================================================================
struct upf_ingress_metadata_t {
    bit<1> drop;
    bit<1> punt;
    bit<7> priority;
    bit<9> cpu_port;
    ring_id_t ring_span;
    ring_id_t kc_ring_id;
    ring_id_t policy_ring_id;
    ring_id_t gtp_ring_id;
    bit<1> policy_lkp_fwd;
    bit<2> color;
    bit<1> activate_meters;
    bit<1> gtp_echo;
    bit<1> protocol;
    mac_addr_t srcMac;
    mac_addr_t dstMac;
    ipv6_addr_t srcAddrv6;
    ipv6_addr_t dstAddrv6;
    protocol_t nextHdrv6;
    ipv6_addr_t dstAddrv6Masked;
    bit<32> srcAddr;
    bit<32> dstAddr;
    bit<16> portStatsId;
}
# 17 "ingress_port_table.p4" 2
//=============================================================================
// Ingress port table
//=============================================================================

control IngressPortTable(inout headers hdr,
        in ingress_intrinsic_metadata_t ig_intr_md) {

    action store_ingress_port(){
        hdr.bridged_md.ingress_port = ig_intr_md.ingress_port;
    }

    action punt() {
        hdr.bridged_md.punt = 0x1;
    }

    action get_knid(knid_t knid) {
        hdr.bridged_md.ingress_knid = knid;
    }

    table port_table {
        key = {
            ig_intr_md.ingress_port : exact;
            hdr.vlan.vlanId : exact;
        }
        actions = {
            get_knid;
            @defaultonly punt;
        }
        size = 512;
        default_action = punt;
    }

    apply {
        port_table.apply();
        store_ingress_port();
    }
}
# 17 "UPFIngress1_0.p4" 2
# 1 "session_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/





# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "session_table.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "session_table.p4" 2

# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 18 "session_table.p4" 2
//=============================================================================
// Session port table
//=============================================================================
control SessionTableDownlink(inout headers hdr, in bit<128> dstAddrv6)(table_size_t table_size) {

    /* Tables counters */
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) session_cntr;

    action punt() {
        hdr.bridged_md.session_miss = hdr.bridged_md.session_miss + 2;
    }

    action session_fwd_encap(knid_t knid, bit<20> flowId) {
        session_cntr.count();
        hdr.bridged_md.knid = knid;
        hdr.bridged_md.flowId = flowId;
    }

    action policy_lkp_or_fwd(bit<20> policyId, knid_t knid, bit<20> flowId) {
        session_cntr.count();
        hdr.bridged_md.policyId = policyId;
        hdr.bridged_md.knid = knid;
        hdr.bridged_md.flowId = flowId;
        hdr.bridged_md.policy_lkp_fwd = 0x1;
    }

    table session_table {
        key = {
            hdr.bridged_md.ingress_knid : exact;
            dstAddrv6 : exact;
            /* Keep teid for downlink in the case of N9/N9 fowarding */
            hdr.gtp_u.teid : exact;
        }
        actions = {
            policy_lkp_or_fwd;
            session_fwd_encap;
            @defaultonly punt;
        }
        size = table_size;
        default_action = punt;
        counters = session_cntr;
    }

    apply {
        session_table.apply();
    }
}

control SessionTableUplink(inout headers hdr)(table_size_t table_size) {

    /* Tables counters */
    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) session_cntr;

    action punt() {
        hdr.bridged_md.session_miss = hdr.bridged_md.session_miss + 2;
    }

    action fwd_decap(knid_t knid, bit<20> flowId ) {
        session_cntr.count();
        hdr.bridged_md.knid = knid;
        hdr.bridged_md.flowId = flowId;
    }

    action session_fwd_N9(knid_t knid, bit<20> flowId) {
        session_cntr.count();
        hdr.bridged_md.knid = knid;
        hdr.bridged_md.flowId = flowId;
        hdr.bridged_md.n9 = 0x1;
    }

    table session_table {
        key = {
            hdr.bridged_md.ingress_knid : exact;
            hdr.outer_ipv6.dstAddr : exact;
            /* Keep teid for downlink in the case of N9/N9 fowarding */
            hdr.gtp_u.teid : exact;
        }
        actions = {
            fwd_decap;
            session_fwd_N9;
            @defaultonly punt;
        }
        size = table_size;
        default_action = punt;
        counters = session_cntr;
    }

    apply {
        session_table.apply();
    }
}
# 18 "UPFIngress1_0.p4" 2
# 1 "flow_table.p4" 1
/*******************************************************************************
 * Copyright (c) Kaloom Inc., 2019
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/

# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "flow_table.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "flow_table.p4" 2

# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "flow_table.p4" 2
//=============================================================================
// Flow table control
//=============================================================================

control FlowTableDownlink(inout headers hdr, in bit<128> dstAddrv6, in bit<128> srcAddrv6, in protocol_t nextHdrv6)(table_size_t table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) flow_cntr;

    action flow_fwd_encap(knid_t knid, bit<20> flowId) {
        flow_cntr.count();
        hdr.bridged_md.knid = knid;
        hdr.bridged_md.flowId = flowId;

        //If flow table is hit, ig_md.flow_table = 1
        hdr.bridged_md.flow_table = 1;
    }

    table flow_table {
        key = {
            hdr.bridged_md.ingress_knid : exact;
            srcAddrv6 : exact;
            dstAddrv6 : exact;
            hdr.outer_tcp.srcPort : exact;
            hdr.outer_tcp.dstPort : exact;
            nextHdrv6 : exact;
        }
        actions = {
            flow_fwd_encap;
        }
        size = table_size;
        counters = flow_cntr;
    }

    apply {
        flow_table.apply();
    }

}

control FlowTableUplink(inout headers hdr)(table_size_t table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) flow_cntr;

    action flow_fwd_encap(knid_t knid, bit<20> flowId) {
        flow_cntr.count();
        hdr.bridged_md.knid = knid;
        hdr.bridged_md.flowId = flowId;

        //If flow table is hit, ig_md.flow_table = 1
        hdr.bridged_md.flow_table = 1;
    }

    table flow_table {
        key = {
            hdr.bridged_md.ingress_knid : exact;
            hdr.inner_ipv6.srcAddr : exact;
            hdr.inner_ipv6.dstAddr : exact;
            hdr.inner_tcp.srcPort : exact;
            hdr.inner_tcp.dstPort : exact;
            hdr.inner_ipv6.nextHdr : exact;
        }
        actions = {
            flow_fwd_encap;
        }
        size = table_size;
        counters = flow_cntr;
    }

    apply {
        flow_table.apply();
    }
}
# 19 "UPFIngress1_0.p4" 2

//=============================================================================
// Parser 1_0 (uplink)
//=============================================================================

parser UPFIngress1_0Parser(
            packet_in pkt,
            out headers hdr,
            out upf_ingress_metadata_t ig_md,
            out ingress_intrinsic_metadata_t ig_intr_md) {

    /*
     *  Packet entry point.
     */
    @pa_container_size("ingress", "ig_intr_md.ingress_port", 16)
    state start {
        pkt.extract(ig_intr_md);
        transition parse_port_metadata;
     }

    state parse_port_metadata {
        //Parse port metadata appended by tofino
        //FIXME: If not needed, we can advance in order to release space for PHV
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
    }

    /*
     *  Dp-ctrl parsing.
     */
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
        ig_md.srcMac = hdr.ethernet.srcAddr;
        ig_md.dstMac = hdr.ethernet.dstAddr;
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  ARP parsing.
     */
    state parse_arp {
        pkt.extract(hdr.arp);
        hdr.bridged_md.punt = 0x1;
        transition accept;
    }


    /*
     *  VLAN parsing.
     */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
            default : accept;
        }
    }

    /*
     *  IPv4 parsing.
     */
    state parse_outer_ipv4 {
        pkt.extract(hdr.outer_ipv4);
        ig_md.srcAddr = hdr.outer_ipv4.srcAddr;
        ig_md.dstAddr = hdr.outer_ipv4.dstAddr;
        transition select(hdr.outer_ipv4.protocol) {
            PROTO_ICMP : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     *  IPv6 parsing.
     */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        ig_md.srcAddrv6 = hdr.outer_ipv6.srcAddr;
        ig_md.dstAddrv6 = hdr.outer_ipv6.dstAddr;
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_ICMPV6 : parse_icmp;
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            default : accept;
        }
    }

    /*
     * Parse outer TCP (downlink).
     * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort 
     */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition accept;
    }

    /*
     *  Outer UDP parsing.
     */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        hdr.outer_tcp.srcPort = hdr.outer_udp.srcPort;
        hdr.outer_tcp.dstPort = hdr.outer_udp.dstPort;
        transition select(hdr.outer_udp.dstPort) {
            PORT_GTP_U : parse_gtp_u;
            default : accept;
        }
    }

    /*
     * Parse ICMP
     */
    state parse_icmp {
        pkt.extract(hdr.icmp);
        //hdr.bridged_md.punt = 0x1;
        transition accept;
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u {
        pkt.extract(hdr.gtp_u);
        transition select(hdr.gtp_u.extFlag, hdr.gtp_u.seqFlag, hdr.gtp_u.pn, hdr.gtp_u.msgType) {
            (1,_,_,_) : parse_gtp_u_options;
            (_,1,_,_) : parse_gtp_u_options;
            (_,_,1,_) : parse_gtp_u_options;
            (_,_,_,0xFF) : parse_inner_ip;
            default : gtp_punt;
        }
    }

    /*
     *  GTP_U parsing.
     */
    state parse_gtp_u_options {
        pkt.extract(hdr.gtp_u_options);
        transition select(hdr.gtp_u.msgType) {
            0x01 : gtp_echo;
            0xFF : parse_inner_ip;
            default : gtp_punt;
        }
    }

    state parse_inner_ip {
        bit<4> version = pkt.lookahead<bit<4>>();
        transition select(version){
            0x4 : parse_inner_ipv4;
            0x6 : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
         transition select(hdr.inner_ipv4.protocol) {
            PROTO_UDP : parse_inner_udp;
            PROTO_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
         transition select(hdr.inner_ipv6.nextHdr) {
            PROTO_UDP : parse_inner_udp;
            PROTO_TCP : parse_inner_tcp;
            default : accept;
        }
    }

    /*
    * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort 
    */
    state parse_inner_tcp {
        pkt.extract(hdr.inner_tcp);
        transition accept;
    }

    state parse_inner_udp {
        pkt.extract(hdr.inner_udp);
        hdr.inner_tcp.srcPort = hdr.inner_udp.srcPort;
        hdr.inner_tcp.dstPort = hdr.inner_udp.dstPort;
        transition accept;
    }

    /*
     * Packet will be drop/punt, but we need to pass it to ingress control block for counter
     * purposes.
     */
     state drop {
        ig_md.drop = 0x1;
        transition accept;
    }

    /*
    * First gress parser has to punt if it is GTP option.
    */
    state gtp_punt {
        hdr.bridged_md.punt_type = 0x3;
        transition accept;
    }

    state gtp_echo {
        ig_md.gtp_echo = 0x1;
        transition accept;
    }
}

//=============================================================================
// Ingress 1_0 control (uplink)
//=============================================================================

control UPFIngress1_0(
        inout headers hdr,
        inout upf_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {

    Counter<bit<64>,single_indirect_counter_t>(64, CounterType_t.PACKETS_AND_BYTES) send_from_cpu_cntr;

    @pragma idletime_precision 1
    @pragma proxy_hash_width 52
    FlowTableUplink(FLOW_TABLE_UL) flow_table;

    @pragma idletime_precision 1
    @pragma proxy_hash_width 52
    IngressPortTable() ingress_port_table;

    action set_ip_lkpv4() {
        ig_md.srcAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.srcAddrv6[95:64] = hdr.outer_ipv4.srcAddr;
        ig_md.srcAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;

        ig_md.dstAddrv6[127:96] = ZEROS_PADDING_4B;
        ig_md.dstAddrv6[95:64] = hdr.outer_ipv4.dstAddr;
        ig_md.dstAddrv6[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        ig_md.nextHdrv6 = hdr.outer_ipv4.protocol;
    }


    action set_ip_lkpv6() {
    }

    action set_inner_ip_lkpv6() {
    }

    action set_inner_ip_lkpv4() {
        hdr.inner_ipv6.srcAddr[127:96] = ZEROS_PADDING_4B;
        hdr.inner_ipv6.srcAddr[95:64] = hdr.inner_ipv4.srcAddr;
        hdr.inner_ipv6.srcAddr[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;;

        hdr.inner_ipv6.dstAddr[127:96] = ZEROS_PADDING_4B;
        hdr.inner_ipv6.dstAddr[95:64] = hdr.inner_ipv4.dstAddr;
        hdr.inner_ipv6.dstAddr[63:0] = MIXED_SINGLE_FFFF_PADDING_8B;
        hdr.inner_ipv6.nextHdr = hdr.inner_ipv4.protocol;
    }

    action set_v4v4(){
        set_ip_lkpv4();
        set_inner_ip_lkpv4();
    }

    action set_v4v6(){
        set_ip_lkpv4();
        set_inner_ip_lkpv6();
    }

    action set_v6v4(){
        set_ip_lkpv6();
        set_inner_ip_lkpv4();
    }

    action set_v6v6(){
        set_ip_lkpv6();
        set_inner_ip_lkpv6();
    }

    table extract_info_table{
        key = {
            hdr.outer_ipv4.isValid() : exact;
            hdr.outer_ipv6.isValid() : exact;
            hdr.inner_ipv4.isValid() : exact;
            hdr.inner_ipv6.isValid() : exact;
        }
        actions = {
            set_ip_lkpv4;
            set_ip_lkpv6;
            set_v4v4;
            set_v4v6;
            set_v6v4;
            set_v6v6;
        }
        const entries = {
            (true, false, false, false): set_ip_lkpv4();
            (false, true, false, false): set_ip_lkpv6();
            (true, false, true, false): set_v4v4();
            (true, false, false, true): set_v4v6();
            (false, true, true, false): set_v6v4();
            (false, true, false, true): set_v6v6();
        }
    }

    // If sending from CPU, do not go through the folded pipeline
    action send_from_cpu() {
        ig_intr_md_for_tm.ucast_egress_port = hdr.dp_ctrl.port;
        hdr.dp_ctrl.setInvalid();
        send_from_cpu_cntr.count(SINGLE_INDIRECT_COUNTER);
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    action gtp_echo_response() {
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.gtp_u.teid = 0x0;
        hdr.gtp_u.msgType = 0x2;
        hdr.gtp_u_options.seqNumb = 0x0000;
        hdr.ethernet.srcAddr = ig_md.dstMac;
        hdr.ethernet.dstAddr = ig_md.srcMac;
        ig_intr_md_for_tm.bypass_egress = 1;
        exit;
    }

    action mark_to_punt_kc() {
        hdr.bridged_md.punt = 0x1;
        hdr.bridged_md.punt_type = 0x1;
    }

    action drop_pkt_ingress() {
        ig_intr_md_for_dprsr.drop_ctl = 0x1;
        exit;
    }

    //If Kubernetes Vlan hit, punt to cpu with dedicated ring ID.
    table kc_table{
        key = {
            hdr.vlan.vlanId : exact;
        }
        actions = {
            mark_to_punt_kc;
        }
        size = 1;
    }

    /* 
    * int_load_balancing_reg register
    * Load balancing on internal ports, round robin mode 
    */
    Register<bit<16>, bit<1>> (0x1) int_load_balancing_reg;
    RegisterAction< bit<16>, bit<1>, bit<16>>(int_load_balancing_reg) int_load_balancing_reg_action = {
        void apply(inout bit<16> value, out bit<16> read_value){
            if (value > 0xbe || value < 0x80){ // 0xbe=190 0x80=128
                value = 0x80;
            } else {
                value = value + 1;
            }
            read_value = value;
        }
    };

    action send_on_folded(){
        ig_intr_md_for_tm.ucast_egress_port = (bit<9>) int_load_balancing_reg_action.execute(0);
        hdr.bridged_md.setValid();
    }

    table parser_marked_table{
        key = {
            ig_md.drop : exact;
            hdr.dp_ctrl.isValid() : exact;
        }
        actions = {
            drop_pkt_ingress;
            send_from_cpu;
            NoAction;
        }
        const entries = {
            (0x1, false) : drop_pkt_ingress();
            (0x0, true) : send_from_cpu();
            (0x0, false) : NoAction();
            (0x1, true) : NoAction();
        }
    }

    action swap_v4(){
        hdr.outer_ipv4.srcAddr = ig_md.dstAddr;
        hdr.outer_ipv4.dstAddr = ig_md.srcAddr;
    }

    action swap_v6() {
        hdr.outer_ipv6.srcAddr = ig_md.dstAddrv6;
        hdr.outer_ipv6.dstAddr = ig_md.srcAddrv6;
    }

    apply {
        parser_marked_table.apply();
        if (ig_md.gtp_echo == 1) {
            if(hdr.inner_ipv6.isValid()){
                swap_v6();
            }
            else {
                swap_v4();
            }
            gtp_echo_response();
        }
        //else if (hdr.bridged_md.punt == 0x1) {
        //    send_on_folded();
        //}
        else {

            extract_info_table.apply();

            kc_table.apply();
            ingress_port_table.apply(hdr, ig_intr_md);

            // Do not activate flow_table for now, as it does nothing
            //flow_table.apply(hdr);

            //if (hdr.bridged_md.flow_table == 0x0) {
                //session_table.apply(hdr);
                //}
            send_on_folded();
        }
    }
}

//=============================================================================
// Deparser 1_0
//=============================================================================

control UPFIngress1_0Deparser(
            packet_out pkt,
            inout headers hdr,
            in upf_ingress_metadata_t ig_md,
            in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply{
        pkt.emit(hdr.bridged_md);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.icmp);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.gtp_u_options);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}
# 17 "tna_32q_multiprogram_a.p4" 2
# 1 "UPFEgress8_0.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2019
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "UPFEgress8_0.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "UPFEgress8_0.p4" 2

# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "UPFEgress8_0.p4" 2
# 1 "encap_gtp.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/




# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "encap_gtp.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "encap_gtp.p4" 2

# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 17 "encap_gtp.p4" 2

control Encap(inout headers hdr,
            inout upf_egress_metadata_t eg_md) {

    action payload_vlan_len() {
        eg_md.pkt_length = eg_md.pkt_length - VLAN_SIZE;
    }

    /* 
    * Subtract 4 from the packet length to account for the 4 bytes of Ethernet
    * FCS that is included in Tofino's packet length metadata.
    * - ETH_MIN_SIZE (0xE)
    * - SIZE OF BRIDGES METADATA (0xF)
    * = 0x21
    */
    action payload_fcs_bridged_len(){
        eg_md.pkt_length = eg_md.pkt_length - 0x21;
    }

    action compute_len_v4() {
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
    }

    action compute_len_v6() {
        hdr.outer_ipv6.payloadLen = UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;

    }

    action compute_len_gtp_udp() {
        hdr.outer_udp.hdrLen = UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.gtp_u.totalLen = eg_md.pkt_length;
    }

    action copy_outer_ip_to_inner_ipv4() {
        // Copy outer IP to inner IP
        hdr.inner_ipv4.setValid();
        hdr.inner_ipv4 = hdr.outer_ipv4;
    }

    action copy_outer_ip_to_inner_ipv6() {
        // Copy outer IP to inner IP
        hdr.inner_ipv6.setValid();
        hdr.inner_ipv6 = hdr.outer_ipv6;
    }

    action add_gtp() {
        // Add GTP
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 1;
        hdr.gtp_u.pt = 1;
        hdr.gtp_u.msgType = 255;

        hdr.gtp_u.teid = eg_md.teid;
    }

    action add_gtpv4() {
        // Add GTP
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 1;
        hdr.gtp_u.pt = 1;
        hdr.gtp_u.msgType = 255;
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + UDP_SIZE + GTP_MIN_SIZE + eg_md.pkt_length;
        hdr.gtp_u.teid = eg_md.teid;
    }

    action add_gtpv6() {
        // Add GTP
        hdr.gtp_u.setValid();
        hdr.gtp_u.version = 1;
        hdr.gtp_u.pt = 1;
        hdr.gtp_u.msgType = 255;

        hdr.gtp_u.teid = eg_md.teid;
    }

    action copy_outer_tcp_to_inner_tcp() {
        hdr.inner_tcp.setValid();
        hdr.inner_tcp = hdr.outer_tcp;
        hdr.outer_tcp.setInvalid();
    }

    action copy_outer_udp_to_inner_udp() {
        hdr.inner_udp.setValid();
        hdr.inner_udp = hdr.outer_udp;
    }

    action add_outer_udp() {
        // ADD outer UDP
        hdr.outer_udp.setValid();
        // Tofino does not support UDP checksum       
        hdr.outer_udp.checksum = 0;
        hdr.outer_udp.dstPort = PORT_GTP_U;
        hdr.outer_udp.srcPort = PORT_GTP_U;
    }

    action modify_outer_ipv4() {
        hdr.outer_ipv4.version = 0x4;
        hdr.outer_ipv4.ihl = 0x5;
        hdr.outer_ipv4.diffserv = 0x0;
        hdr.outer_ipv4.identification = 0x1;
        hdr.outer_ipv4.ttl = 0x40;
        hdr.outer_ipv4.flags = 0x0;
        hdr.outer_ipv4.fragOffset = 0x0;
        hdr.vlan.etherType = ETHERTYPE_IPV4;
        hdr.outer_ipv4.dstAddr = eg_md.dstAddr[95:64];
        hdr.outer_ipv4.srcAddr = eg_md.srcAddrv4;

        hdr.outer_ipv4.protocol = PROTO_UDP;
    }

    action modify_outer_ipv6() {
        hdr.vlan.etherType = ETHERTYPE_IPV6;
        hdr.outer_ipv6.version = 0x6;
        hdr.outer_ipv6.trafficClass = 0x00;
        hdr.outer_ipv6.flowLabel = 0x00000;
        hdr.outer_ipv6.hopLimit = 0x40;
        hdr.outer_ipv6.dstAddr = eg_md.dstAddr;
        hdr.outer_ipv6.srcAddr = eg_md.srcAddrv6;

        hdr.outer_ipv6.nextHdr = PROTO_UDP;
    }


    action v4_to_v4(){
        copy_outer_ip_to_inner_ipv4();
        modify_outer_ipv4();
    }
    action v4_to_v6(){
        copy_outer_ip_to_inner_ipv4();
        hdr.outer_ipv4.setInvalid();
        hdr.outer_ipv6.setValid();
        modify_outer_ipv6();
    }
    action v6_to_v4(){
        copy_outer_ip_to_inner_ipv6();
        hdr.outer_ipv6.setInvalid();
        hdr.outer_ipv4.setValid();
        modify_outer_ipv4();
    }
    action v6_to_v6(){
        copy_outer_ip_to_inner_ipv6();
        modify_outer_ipv6();
    }

    table select_encap {
        key = {
            eg_md.protoEncap: exact;
            hdr.outer_ipv4.isValid(): exact;
            hdr.outer_ipv6.isValid(): exact;
        }
        actions = {
            v4_to_v4;
            v4_to_v6;
            v6_to_v4;
            v6_to_v6;
        }
        const entries = {
            (0, true, false): v4_to_v4();
            (1, true, false): v4_to_v6();
            (0, false, true): v6_to_v4();
            (1, false, true): v6_to_v6();
        }
    }

    table copy_inner_tcp_or_udp {
        key = {
            hdr.outer_tcp.isValid(): exact;
            hdr.outer_udp.isValid(): exact;
        }
        actions = {
            copy_outer_tcp_to_inner_tcp;
            copy_outer_udp_to_inner_udp;
        }
        const entries = {
            (true, false): copy_outer_tcp_to_inner_tcp();
            (false, true): copy_outer_udp_to_inner_udp();
        }
    }

    apply {
        select_encap.apply();
        add_gtp();

        /*
        * If we parsed a outer tcp we need to copy it to inner tcp
        * and delete it. 
        */
        copy_inner_tcp_or_udp.apply();

        add_outer_udp();
        if (hdr.vlan.isValid()) {
            payload_vlan_len();
        }

        /*
         * Lengths computation.
        */

        payload_fcs_bridged_len();

        if (eg_md.protoEncap == 0) {
            compute_len_v4();
        } else {
            compute_len_v6();
        }
        compute_len_gtp_udp();
    }
}
# 18 "UPFEgress8_0.p4" 2
# 1 "N9.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/





# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 15 "N9.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 16 "N9.p4" 2

# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 18 "N9.p4" 2
//=============================================================================
// N9 interface
//=============================================================================
control N9Rewrite(inout headers hdr,
                inout upf_egress_metadata_t eg_md) {

    action rewrite_v4() {
        hdr.outer_ipv4.dstAddr = eg_md.dstAddr[95:64];
        hdr.outer_ipv4.srcAddr = eg_md.srcAddrv4;
    }

    action rewrite_v6() {
        hdr.outer_ipv6.dstAddr = eg_md.dstAddr;
        hdr.outer_ipv6.srcAddr = eg_md.srcAddrv6;
    }

    action modify_outer_ipv4() {
        hdr.outer_ipv4.version = 0x4;
        hdr.outer_ipv4.ihl = 0x5;
        hdr.outer_ipv4.diffserv = 0x0;
        hdr.outer_ipv4.identification = 0x1;
        hdr.outer_ipv4.ttl = 0x40;
        hdr.outer_ipv4.flags = 0x0;
        hdr.outer_ipv4.fragOffset = 0x0;
        hdr.vlan.etherType = ETHERTYPE_IPV4;
        hdr.outer_ipv4.dstAddr = eg_md.dstAddr[95:64];
        hdr.outer_ipv4.srcAddr = eg_md.srcAddrv4;

        hdr.outer_ipv4.protocol = PROTO_UDP;
    }

    action modify_outer_ipv6() {
        hdr.vlan.etherType = ETHERTYPE_IPV6;
        hdr.outer_ipv6.version = 0x6;
        hdr.outer_ipv6.trafficClass = 0x00;
        hdr.outer_ipv6.flowLabel = 0x00000;
        hdr.outer_ipv6.hopLimit = 0x40;
        hdr.outer_ipv6.dstAddr = eg_md.dstAddr;
        hdr.outer_ipv6.srcAddr = eg_md.srcAddrv6;

        hdr.outer_ipv6.nextHdr = PROTO_UDP;
    }

    action rewrite_gtp(){
        hdr.gtp_u.teid = eg_md.teid;
    }

    action set_checksum_udp(){
        hdr.outer_udp.checksum = 0;
    }

    action compute_len_v4() {
        hdr.outer_ipv4.totalLen = IPV4_MIN_SIZE + hdr.outer_udp.hdrLen;
    }

    action compute_len_v6() {
        hdr.outer_ipv6.payloadLen = hdr.outer_udp.hdrLen;
    }


    action v4_to_v6(){
        hdr.outer_ipv4.setInvalid();
        hdr.outer_ipv6.setValid();
        modify_outer_ipv6();
    }
    action v6_to_v4(){
        hdr.outer_ipv6.setInvalid();
        hdr.outer_ipv4.setValid();
        modify_outer_ipv4();
    }

    table select_encap {
        key = {
            eg_md.protoEncap: exact;
            hdr.outer_ipv4.isValid(): exact;
            hdr.outer_ipv6.isValid(): exact;
        }
        actions = {
            rewrite_v4;
            v4_to_v6;
            v6_to_v4;
            rewrite_v6;
        }
        const entries = {
            (0, true, false): rewrite_v4();
            (1, true, false): v4_to_v6();
            (0, false, true): v6_to_v4();
            (1, false, true): rewrite_v6();
        }
    }

    apply {
        select_encap.apply();
        rewrite_gtp();
        set_checksum_udp();

        /*
         * Lengths computation.
         */
        if (eg_md.protoEncap == 0) {
            compute_len_v4();
        } else {
            compute_len_v6();
        }
    }
}
# 19 "UPFEgress8_0.p4" 2
# 1 "egress_port_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/




# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 14 "egress_port_table.p4" 2

//=============================================================================
// Egress port table
//=============================================================================

control EgressPortTable(inout headers hdr,
                        in egress_intrinsic_metadata_t eg_intr_md,
                        inout upf_egress_metadata_t eg_md) {

    action get_knid_info(mac_addr_t dstMac, mac_addr_t srcMac, bit<32> srcIpv4, bit<128> srcIpv6, bit<12> vlanId) {
        hdr.ethernet.dstAddr = dstMac;
        hdr.ethernet.srcAddr = srcMac;
        eg_md.srcAddrv4 = srcIpv4;
        eg_md.srcAddrv6 = srcIpv6;
        hdr.vlan.vlanId = vlanId;
    }


    table port_table {
        key = {
            eg_intr_md.egress_port : exact;
            hdr.bridged_md.knid : exact;
        }
        actions = {
            get_knid_info;
        }
        size = 512;
    }

    apply {
        port_table.apply();
    }
}
# 20 "UPFEgress8_0.p4" 2
# 1 "action_id_table.p4" 1
/*******************************************************************************
* Copyright (c) Kaloom Inc., 2018
*
* This unpublished material is property of Kaloom Inc.
* All rights reserved.
* Reproduction or distribution, in whole or in part, is
* forbidden except by express written permission of Kaloom Inc.
****************************************************************/

# 1 "core/headers/headers.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 11 "action_id_table.p4" 2
# 1 "core/headers/types.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 12 "action_id_table.p4" 2
# 1 "metadata.p4" 1
/****************************************************************
 * Copyright (c) Kaloom Inc., 2018
 *
 * This unpublished material is property of Kaloom Inc.
 * All rights reserved.
 * Reproduction or distribution, in whole or in part, is
 * forbidden except by express written permission of Kaloom Inc.
 ****************************************************************/
# 13 "action_id_table.p4" 2

//=============================================================================
// Action ID table control
//=============================================================================

control ActionIdTableDownlink(inout headers hdr, inout upf_egress_metadata_t eg_md)(table_size_t table_size) {

    action flow_fwd_encap(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
    }

    action session_fwd_encap(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
    }

    action assos_fwd_encap(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
    }

    action default_fwd_encap(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
    }

    action punt(){}

    table actionId_table {
        key = {
            hdr.bridged_md.flowId : exact;
        }
        actions = {
            flow_fwd_encap;
            session_fwd_encap;
            assos_fwd_encap;
            default_fwd_encap;
           @defaultonly punt;
        }
        size = table_size;
        default_action = punt;
    }

    apply {
        actionId_table.apply();
    }

}

control ActionIdTableUplink(inout headers hdr, inout upf_egress_metadata_t eg_md)(table_size_t table_size) {


    action punt(){}

    action fwd_decap() {
    }

    action flow_fwd_encap(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
 }

    action session_fwd_encap(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
    }

    action session_fwd_N9(bit<128> dstAddr, bit<32> teid, bit<1> protocol) {
        eg_md.teid = teid;
        eg_md.protoEncap = protocol;
        eg_md.dstAddr = dstAddr;
    }

    table actionId_table {
        key = {
            hdr.bridged_md.flowId : exact;
        }
        actions = {
            fwd_decap;
            flow_fwd_encap;
            session_fwd_N9;
            session_fwd_encap;
            @defaultonly punt;
        }
        size = table_size;
        default_action = punt ;
    }

    apply {
        actionId_table.apply();
    }

}
# 21 "UPFEgress8_0.p4" 2

//=============================================================================
// Egress 8_0 Parser (Downlink)
//=============================================================================
parser UPFEgress8_0Parser(
            packet_in pkt,
            out headers hdr,
            out upf_egress_metadata_t eg_md,
            out egress_intrinsic_metadata_t eg_intr_md) {

    /*
     *  Packet entry point.
     */
    state start {
        /* Initialize metadata for no warnings */
        eg_md.pkt_length = 0;
        eg_md.dstAddr = 0;
        eg_md.srcAddrv4 = 0;
        eg_md.srcAddrv6 = 0;

        pkt.extract(eg_intr_md);
        transition parse_bridged_metadata;
     }

    state parse_bridged_metadata {
        pkt.extract(hdr.bridged_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        transition parse_ethernet;
    }

    /*
    *  Ethernet parsing.
    */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_outer_ipv4;
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
            ETHERTYPE_IPV4 : parse_outer_ipv4;
            ETHERTYPE_IPV6 : parse_outer_ipv6;
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
            8w0x00 &&& 8w0x00 : accept;
            /* Never taken */
            8w0xFF &&& 8w0xFF : parse_outer_ipv6;
        }
    }

    /*
    *  IPv6 parsing.
    */
    state parse_outer_ipv6 {
        pkt.extract(hdr.outer_ipv6);
        transition select(hdr.outer_ipv6.nextHdr) {
            PROTO_UDP : parse_outer_udp;
            PROTO_TCP : parse_outer_tcp;
            8w0x00 &&& 8w0x00 : accept;
            /* Never taken */
            8w0xFF &&& 8w0xFF : parse_outer_ipv4;
        }
    }

    /*
    * Parse outer TCP (downlink).
    * Instead of saving srcPort and dstPort in a metadata, just use tcp.srcPort / tcp.dstPort 
    */
    state parse_outer_tcp {
        pkt.extract(hdr.outer_tcp);
        transition select(hdr.outer_tcp.urgentPtr) {
            16w0x0000 &&& 16w0x0000 : accept;
            /* Never taken */
            16w0xFFFF &&& 16w0xFFFF : parse_gtp_u;
        }
    }

    /*
    *  Outer UDP parsing.
    */
    state parse_outer_udp {
        pkt.extract(hdr.outer_udp);
        hdr.outer_tcp.srcPort = hdr.outer_udp.srcPort;
        hdr.outer_tcp.dstPort = hdr.outer_udp.dstPort;
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
        transition select(hdr.gtp_u.extFlag, hdr.gtp_u.seqFlag, hdr.gtp_u.pn, hdr.gtp_u.msgType) {
            (1,_,_,_) : parse_gtp_u_options;
            (_,1,_,_) : parse_gtp_u_options;
            (_,_,1,_) : parse_gtp_u_options;
            (_,_,_,_) : accept;
            /* Never taken */
            (1,1,1,0xFF) : parse_inner_ipv4;
            (1,1,1,0xFF) : parse_inner_ipv6;
        }
    }

    /*
    *  GTP_U parsing.
    */
    state parse_gtp_u_options {
        pkt.extract(hdr.gtp_u_options);
        transition select(hdr.gtp_u.msgType) {
            0xFF : accept;
            /* Never taken */
            0x1 &&& 0x1 : parse_inner_ipv4;
            0x1 &&& 0x1 : parse_inner_ipv6;
        }
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.protocol) {
            8w0x00 &&& 8w0x00 : accept;
            /* Never taken */
            8w0xFF &&& 8w0xFF : parse_inner_ipv6;
        }
    }

    state parse_inner_ipv6 {
        pkt.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w0x00 &&& 8w0x00 : accept;
            /* Never taken */
            8w0xFF &&& 8w0xFF : parse_inner_ipv4;
        }
    }

}
//=============================================================================
// Egress 8_0 control (dowlink)
//=============================================================================

control UPFEgress8_0(
        inout headers hdr,
        inout upf_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    EgressPortTable() port_table;
    ActionIdTableDownlink(ACTIONID_TABLE_DL) actionId_table;
    Encap() encap;
    N9Rewrite() N9;

    /* Downlink flowId counters */
    Counter<bit<64>, dl_flow_id_indirect_counter_t>(1024, CounterType_t.PACKETS_AND_BYTES) dl_encap_cntr0;
    Counter<bit<64>, dl_flow_id_indirect_counter_t>(1024, CounterType_t.PACKETS_AND_BYTES) dl_encap_cntr1;
    Counter<bit<64>, dl_flow_id_indirect_counter_t>(1024, CounterType_t.PACKETS_AND_BYTES) dl_encap_cntr2;
    Counter<bit<64>, dl_flow_id_indirect_counter_t>(1024, CounterType_t.PACKETS_AND_BYTES) dl_encap_cntr3;

    Counter<bit<64>, port_stats_indirect_counter_t>(1024, CounterType_t.PACKETS_AND_BYTES) eg_dl_knid;
    Counter<bit<64>, bit<9>>(512, CounterType_t.PACKETS_AND_BYTES) eg_dl_port;

    action del_bridged_md() {
        hdr.bridged_md.setInvalid();
    }

    action transfer_flowid(){
        eg_md.flowId = hdr.bridged_md.flowId;
    }

    apply {
//// prev 0 NOK
//        transfer_flowid(); 
//        actionId_table.apply(hdr, eg_md);
//// prev 3 NOK
//        if (eg_md.flowId[17:16] == 0) {
//            dl_encap_cntr0.count(eg_md.flowId[15:0]);
//        } else if (eg_md.flowId[17:16] == 1) {
//            dl_encap_cntr1.count(eg_md.flowId[15:0]);
//        } else if (eg_md.flowId[17:16] == 2) {
//            dl_encap_cntr2.count(eg_md.flowId[15:0]);
//        } else {
//            dl_encap_cntr3.count(eg_md.flowId[15:0]);
//        }
//// prev 4 NOK
//        port_table.apply(hdr, eg_intr_md, eg_md);
//// prev 1 OK
//        eg_dl_knid.count(hdr.bridged_md.knid);
//        eg_dl_port.count(eg_intr_md.egress_port);
//// prev 2 OK
//        if (!hdr.gtp_u.isValid()) {
//            encap.apply(hdr, eg_md);
//        } else {
//            N9.apply(hdr, eg_md);
//        }
//        del_bridged_md();
    }
}

//=============================================================================
// Egress  8_0 Deparser
//=============================================================================
control UPFEgress8_0Deparser(
            packet_out pkt,
            inout headers hdr,
            in upf_egress_metadata_t eg_md,
            in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() outer_ipv4_checksum;
    Checksum() inner_ipv4_checksum;

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

        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.vlan);
        pkt.emit(hdr.outer_ipv4);
        pkt.emit(hdr.outer_ipv6);
        pkt.emit(hdr.outer_udp);
        pkt.emit(hdr.outer_tcp);
        pkt.emit(hdr.gtp_u);
        pkt.emit(hdr.gtp_u_options);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ipv6);
        pkt.emit(hdr.inner_udp);
        pkt.emit(hdr.inner_tcp);
    }
}
# 18 "tna_32q_multiprogram_a.p4" 2

Pipeline(UPFIngress1_0Parser(),
  UPFIngress1_0(),
  UPFIngress1_0Deparser(),
  UPFEgress8_0Parser(),
  UPFEgress8_0(),
  UPFEgress8_0Deparser()) profile_a;

Switch(profile_a) main;
