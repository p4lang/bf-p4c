# 1 "int_demo.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "int_demo.p4"
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Code taken from:
 * https://github.com/p4lang/p4-applications/blob/master/telemetry/specs/INT.mdk
 */

# 1 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/core.p4" 1
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
# 23 "int_demo.p4" 2
# 1 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/tna.p4" 1
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




# 1 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/tna.p4" 2
# 1 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/tofino.p4" 2

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
    @hidden bit<1> _pad1;

    bit<2> packet_version; // Read-only Packet version.

    @hidden bit<3> _pad2;

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
    @hidden bit<7> _pad0;

    bit<9> egress_port; // Egress port id.
                                        // this field is passed to the deparser

    @hidden bit<5> _pad1;

    bit<19> enq_qdepth; // Queue depth at the packet enqueue
                                        // time.

    @hidden bit<6> _pad2;

    bit<2> enq_congest_stat; // Queue congestion status at the packet
                                        // enqueue time.

    @hidden bit<14> _pad3;
    bit<18> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    @hidden bit<5> _pad4;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    @hidden bit<6> _pad5;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    @hidden bit<14> _pad6;
    bit<18> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    ReplicationId_t egress_rid; // L3 replication id for multicast
                                        // packets.

    @hidden bit<7> _pad7;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    @hidden bit<3> _pad8;

    QueueId_t egress_qid; // Egress (physical) queue id via which
                                        // this packet was served.

    @hidden bit<5> _pad9;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    @hidden bit<7> _pad10;

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
    @hidden bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @hidden bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    @hidden bit<3> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<3> app_id; // Application id
    @hidden bit<15> _pad2;
    bit<9> port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    @hidden bit<3> _pad1;
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
    bit<16> get();

    /// Subtract all header fields after the current state and
    /// return the calculated checksum value.
    /// Marks the end position for residual checksum header.
    /// All header fields extracted after will be automatically subtracted.
    /// @param residual : The calculated checksum value for added fields.
    void subtract_all_and_deposit<T>(out T residual);

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

extern T max<T>(in T t1, in T t2);

extern T min<T>(in T t1, in T t2);

extern void invalidate<T>(in T field);

/// Phase0
extern T port_metadata_unpack<T>(packet_in pkt);

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

    U predicate(); /* return the 4-bit predicate value */
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

    U predicate(); /* return the 4-bit predicate value */
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
# 24 "/home/rvdp/src/bf-sde-8.9.1/install/share/p4c/p4include/tna.p4" 2

// The following declarations provide a template for the programmable blocks in
// Tofino.

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
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

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
# 24 "int_demo.p4" 2

# 1 "types.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




typedef PortId_t port_t;

enum bit<2> int_role_t {
    SOURCE = 0,
    TRANSIT = 1,
    SINK = 2
}
# 26 "int_demo.p4" 2
# 1 "constants.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




/* indicate INT by UDP/TCP destination port */
const bit<32> INT_PROBE_MARKER_1 = 0xFF00FF00;
const bit<32> INT_PROBE_MARKER_2 = 0xFF00FF00;

const bit<32> IPv4_ACL_TABLE_SIZE = 1024;
const bit<32> IPv6_ACL_TABLE_SIZE = 1024;
const bit<32> FORWARD_TABLE_SIZE = 1024;
# 27 "int_demo.p4" 2

# 1 "metadata.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * Code taken from:
 * https://github.com/p4lang/p4-applications/blob/master/telemetry/specs/INT.mdk
 */




struct ingress_metadata_t {
}

header bridged_metadata_h {
    bit<5> padding;
    int_role_t int_role;
    port_t ingress_port;
    bit<48> ingress_timestamp;
}

/* switch internal variables for INT logic implementation */
struct int_metadata_t {
    bit<32> switch_id;
    bit<16> length;
    bit<16> insert_word_cnt;
    bit<16> insert_double_word_cnt;
    bit<16> insert_byte_cnt;
    bit<8> int_hdr_word_len;
}

struct probe_marker_t {
    bit<32> marker_1;
    bit<32> marker_2;
}

struct egress_metadata_t {
    port_t ingress_port;
    bit<48> ingress_timestamp; // arrival at ingress MAC
    bit<48> egress_timestamp; // arrival at egress
    bit<16> l3_mtu;
    int_metadata_t int_metadata;
}
# 29 "int_demo.p4" 2

# 1 "ingress_parser.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ethernet.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




/*
 * IEEE Std 802.1Q-2018, section 9.6
 */

typedef bit<48> ether_addr_t;
typedef bit<16> ethertype_t;

# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ethertypes.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




/*
 * https://www.iana.org/assignments/ieee-802-numbers/ *                ieee-802-numbers.xhtml#ieee-802-numbers-1
1
 */
# 28 "/home/rvdp/github.com/rvdpdotorg/P4include/ethernet.p4" 2

header ethernet_h {
    ether_addr_t daddr;
    ether_addr_t saddr;
    ethertype_t type;
}

header vlan_h {
    bit<3> pcp; // Priority Code Point (section 6.9.3)
    bit<1> dei; // Drop Eligible Indicator (section 6.9.3)
    bit<12> vid;
    ethertype_t type;
}
# 21 "ingress_parser.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv6.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/protocols.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * https://www.iana.org/assignments/protocol-numbers/ *                      protocol-numbers.xhtml
l
 */
# 21 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv6.p4" 2

/*
 * RFC 8200: Internet Protocol, Version 6 (IPv6) Specification, July 2017
 */

typedef bit<128> ipv6_addr_t;

header ipv6_h {
    bit<4> version;
    bit<6> dscp;
    bit<2> ecn;
    bit<20> flowlabel;
    bit<16> payload_len;
    bit<8> nexthdr;
    bit<8> hoplimit;
    ipv6_addr_t saddr;
    ipv6_addr_t daddr;
}

// RFC 8200, section 4, IPv6 Extension Headers
header ipv6_ext_hdr_h {
    bit<8> nexthdr;
    bit<8> length;
}

// RFC 8200, section 4.2, Options
header ipv6_options_h {
    bit<8> type;
    bit<8> length;
}

// RFC 8200, section 4.4, Routing Header
header ipv6_routing_hdr_h {
    bit<8> type;
    bit<8> segments_left;
}

// RFC 8200, section 4.5, Fragment Header
header ipv6_fragment_hdr_h {
    bit<13> fragment_offset;
    bit<2> reserved;
    bit<1> more_fragments;
    bit<32> id;
}
# 22 "ingress_parser.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/int.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




/*
 * https://github.com/p4lang/p4-applications/blob/master/docs/INT.pdf
 */

/* INT probe marker for TCP/UDP */
header int_probe_marker_1_h {
    bit<32> value;
}

header int_probe_marker_2_h {
    bit<32> value;
}

/* INT shim header for TCP/UDP */
header intl4_shim_h {
    bit<8> int_type; /* INT header type */
    bit<8> rsvd1; /* Reserved */
    bit<8> len; /* Total length of INT Metadata, INT Stack */
                            /* and Shim Header in 4-byte words */
    bit<6> dscp; /* Original IP DSCP value (optional) */
    bit<2> rsvd2; /* Reserved */
}

/* INT header */
/* 16 instruction bits are defined in four 4b fields to allow concurrent */
/* lookups of the bits without listing 2^16 combinations */
header int_header_h {
    bit<4> ver; /* Version (1 for this version) */
    bit<2> rep; /* Replication requested */
    bit<1> c; /* Copy */
    bit<1> e; /* Max Hop Count exceeded */
    bit<1> m; /* MTU exceeded */
    bit<7> rsvd1; /* Reserved */
    // @padding
    bit<3> rsvd2; /* Reserved */
    bit<5> hop_metadata_len; /* Per-hop Metadata Length */
                                        /* in 4-byte words */
    bit<8> remaining_hop_cnt; /* Remaining Hop Count */
    bit<4> instruction_mask_0003; /* Instruction bitmap bits 0-3 */
    bit<4> instruction_mask_0407; /* Instruction bitmap bits 4-7 */
    bit<4> instruction_mask_0811; /* Instruction bitmap bits 8-11 */
    bit<4> instruction_mask_1215; /* Instruction bitmap bits 12-15 */
    bit<16> rsvd3; /* Reserved */
}

/* INT meta-value headers - different header for each value type */
header int_switch_id_h {
    bit<32> switch_id;
}

header int_level1_port_ids_h {
    bit<16> ingress_port_id;
    bit<16> egress_port_id;
}

header int_hop_latency_h {
    bit<32> hop_latency;
}

header int_q_occupancy_h {
    bit<8> q_id;
    bit<24> q_occupancy;
}

header int_ingress_tstamp_h {
    bit<32> ingress_tstamp;
}

header int_egress_tstamp_h {
    bit<32> egress_tstamp;
}

header int_level2_port_ids_h {
    bit<32> ingress_port_id;
    bit<32> egress_port_id;
}

header int_egress_port_tx_util_h {
    bit<32> egress_port_tx_util;
}

header int_b_occupancy_h {
    bit<8> b_id;
    bit<24> b_occupancy;
}
# 23 "ingress_parser.p4" 2

struct ingress_headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
    ipv6_h ipv6;
    int_probe_marker_1_h int_probe_marker_1;
    int_probe_marker_2_h int_probe_marker_2;
    intl4_shim_h intl4_shim;
    int_header_h int_header;
}

parser ingress_parser(
        packet_in pkt,
        out ingress_headers_t hdr,
        out ingress_metadata_t ingress_metadata,
        out ingress_intrinsic_metadata_t
            ingress_intrinsic_metadata)
{
    state start {
        pkt.extract(ingress_intrinsic_metadata);
        pkt.advance(PORT_METADATA_SIZE);
        hdr.bridged_metadata.setValid();
        hdr.bridged_metadata.ingress_port =
            ingress_intrinsic_metadata.ingress_port;
        hdr.bridged_metadata.ingress_timestamp =
            ingress_intrinsic_metadata.ingress_mac_tstamp;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86DD: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition accept;
    }
}
# 31 "int_demo.p4" 2
# 1 "ingress_mau.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




control ingress_mau(
        inout ingress_headers_t hdr,
        inout ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_t ingress_intrinsic_metadata,
        in ingress_intrinsic_metadata_from_parser_t
            ingress_intrinsic_metadata_from_parser,
        inout ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser,
        inout ingress_intrinsic_metadata_for_tm_t
            ingress_intrinsic_metadata_for_tm)
{
    action set_int_role(int_role_t role) {
        hdr.bridged_metadata.int_role = role;
    }

    table int_role {
        actions = {
            set_int_role;
        }
        size = 1;
    }

    action add_int_headers(
            bit<4> instruction_mask_0003,
            bit<4> instruction_mask_0407,
            bit<4> instruction_mask_0811,
            bit<4> instruction_mask_1215
    ) {
        hdr.int_probe_marker_1.setValid();
        hdr.int_probe_marker_1.value = INT_PROBE_MARKER_1;

        hdr.int_probe_marker_2.setValid();
        hdr.int_probe_marker_2.value = INT_PROBE_MARKER_2;

        hdr.intl4_shim.setValid();
        hdr.intl4_shim.int_type = 1;
        hdr.intl4_shim.rsvd1 = 0;
        hdr.intl4_shim.len = 8;
        hdr.intl4_shim.dscp = 0;
        hdr.intl4_shim.rsvd2 = 0;

        hdr.int_header.setValid();
        hdr.int_header.ver = 1;
        hdr.int_header.rep = 0;
        hdr.int_header.c = 0;
        hdr.int_header.e = 0;
        hdr.int_header.m = 0;
        hdr.int_header.rsvd1 = 0;
        hdr.int_header.rsvd2 = 0;
        hdr.int_header.hop_metadata_len = 0;
        hdr.int_header.remaining_hop_cnt = 255;
        hdr.int_header.instruction_mask_0003 = instruction_mask_0003;
        hdr.int_header.instruction_mask_0407 = instruction_mask_0407;
        hdr.int_header.instruction_mask_0811 = instruction_mask_0811;
        hdr.int_header.instruction_mask_1215 = instruction_mask_1215;
        hdr.int_header.rsvd3 = 0;
    }

    table int_ipv6_acl {
        key = {
            hdr.ethernet.saddr: ternary;
            hdr.ethernet.daddr: ternary;
            hdr.ipv6.saddr: ternary;
            hdr.ipv6.daddr: ternary;
            hdr.ipv6.nexthdr: exact;
        }
        actions = {
            add_int_headers;
        }
        size = IPv6_ACL_TABLE_SIZE;
    }

    action send_to(port_t port) {
        ingress_intrinsic_metadata_for_tm.ucast_egress_port = port;
    }

    action drop() {
        ingress_intrinsic_metadata_for_deparser.drop_ctl = 1;
    }

 table forward {
        key = {
            hdr.ethernet.daddr: exact;
        }
        actions = {
            send_to;
            drop;
        }
        const default_action = drop();
        size = FORWARD_TABLE_SIZE;
    }

    apply {
        int_role.apply();
        if (hdr.bridged_metadata.int_role == int_role_t.SOURCE) {
            if (hdr.ipv6.isValid()) {
                int_ipv6_acl.apply();
            }
        }
        forward.apply();
    }
}
# 32 "int_demo.p4" 2
# 1 "ingress_deparser.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




control ingress_deparser(
        packet_out pkt,
        inout ingress_headers_t hdr,
        in ingress_metadata_t ingress_metadata,
        in ingress_intrinsic_metadata_for_deparser_t
            ingress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}
# 33 "int_demo.p4" 2

# 1 "egress_parser.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ethernet.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 21 "egress_parser.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/ipv6.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 22 "egress_parser.p4" 2
# 1 "/home/rvdp/github.com/rvdpdotorg/P4include/int.p4" 1
/*
 * Copyright [2018-present] Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
# 23 "egress_parser.p4" 2

struct egress_headers_t {
    bridged_metadata_h bridged_metadata;
    ethernet_h ethernet;
    ipv6_h ipv6;
    ipv6_ext_hdr_h ipv6_ext_hdr;
    int_header_h int_header;
    int_switch_id_h int_switch_id;
    int_level1_port_ids_h int_level1_port_ids;
    int_hop_latency_h int_hop_latency;
    int_q_occupancy_h int_q_occupancy;
    int_ingress_tstamp_h int_ingress_tstamp;
    int_egress_tstamp_h int_egress_tstamp;
    int_level2_port_ids_h int_level2_port_ids;
    int_egress_port_tx_util_h int_egress_port_tx_util;
    int_b_occupancy_h int_b_occupancy;
}

parser egress_parser (
        packet_in pkt,
        out egress_headers_t hdr,
        out egress_metadata_t egress_metadata,
        out egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    state start {
        pkt.extract(egress_intrinsic_metadata);
        pkt.extract(hdr.bridged_metadata);
        egress_metadata.ingress_port = hdr.bridged_metadata.ingress_port;
        egress_metadata.ingress_timestamp =
            hdr.bridged_metadata.ingress_timestamp;
        egress_metadata.egress_timestamp = 0;
        egress_metadata.l3_mtu = 0;
        egress_metadata.int_metadata = {0, 0, 0, 0, 0, 0};
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
            0x86DD: parse_ipv6;
            default: accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nexthdr) {
            0: parse_hop_by_hop_options;
            default: accept;
        }
    }

    state parse_hop_by_hop_options {
        pkt.extract(hdr.ipv6_ext_hdr);
        pkt.extract(hdr.int_header);
        transition accept;
    }
}
# 35 "int_demo.p4" 2
# 1 "egress_mau.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




# 1 "outer_encap.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




control outer_encap_control(
        inout egress_headers_t hdr,
        in int_metadata_t int_metadata)
{
    apply {
        if (hdr.ipv6.isValid()) {
            hdr.ipv6.payload_len =
                hdr.ipv6.payload_len + int_metadata.insert_byte_cnt;
        }

        if (hdr.ipv6_ext_hdr.isValid()) {
            hdr.ipv6_ext_hdr.length =
                hdr.ipv6_ext_hdr.length + int_metadata.insert_double_word_cnt[7:0];
        }
    }
}
# 21 "egress_mau.p4" 2
# 1 "metadata_insert.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




control metadata_insert_control(
        inout egress_headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in int_metadata_t int_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata)
{
    action int_set_header_0() {
        hdr.int_switch_id.setValid();
        hdr.int_switch_id.switch_id = int_metadata.switch_id;
    }
    action int_set_header_1() {
        hdr.int_level1_port_ids.setValid();
        hdr.int_level1_port_ids.ingress_port_id =
            (bit<16>) egress_metadata.ingress_port;
        hdr.int_level1_port_ids.egress_port_id =
            (bit<16>) egress_intrinsic_metadata.egress_port;
    }
    action int_set_header_2() {
        hdr.int_hop_latency.setValid();
        hdr.int_hop_latency.hop_latency =
            (bit<32>) egress_metadata.egress_timestamp -
            (bit<32>) egress_metadata.ingress_timestamp;
    }
    action int_set_header_3() {
        hdr.int_q_occupancy.setValid();
        hdr.int_q_occupancy.q_id =
            (bit<8>) egress_intrinsic_metadata.egress_qid;
        hdr.int_q_occupancy.q_occupancy =
            (bit<24>) egress_intrinsic_metadata.enq_qdepth;
    }

    action int_set_header_4() {
        hdr.int_ingress_tstamp.setValid();
        hdr.int_ingress_tstamp.ingress_tstamp =
            (bit<32>) egress_metadata.ingress_timestamp;
    }

    action int_set_header_5() {
        hdr.int_egress_tstamp.setValid();
        hdr.int_egress_tstamp.egress_tstamp =
            (bit<32>) egress_metadata.egress_timestamp;
    }

    action int_set_header_6() {
        hdr.int_level2_port_ids.setValid();
        hdr.int_level2_port_ids.ingress_port_id = 0; // TBD
        hdr.int_level2_port_ids.egress_port_id = 0; // TBD
    }

    action int_set_header_7() {
        hdr.int_egress_port_tx_util.setValid();
        hdr.int_egress_port_tx_util.egress_port_tx_util = 0; // TBD
    }

    /*
     * Action functions for bits 0-3 combinations, 0 is msb, 3 is lsb.
     * Each bit set indicates that corresponding INT header should be added.
     */
    action int_set_header_0003_i0() {
    }
    action int_set_header_0003_i1() {
        int_set_header_3();
    }
    action int_set_header_0003_i2() {
        int_set_header_2();
    }
    action int_set_header_0003_i3() {
        int_set_header_3();
        int_set_header_2();
    }
    action int_set_header_0003_i4() {
        int_set_header_1();
    }
    action int_set_header_0003_i5() {
        int_set_header_3();
        int_set_header_1();
    }
    action int_set_header_0003_i6() {
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i7() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
    }
    action int_set_header_0003_i8() {
        int_set_header_0();
    }
    action int_set_header_0003_i9() {
        int_set_header_3();
        int_set_header_0();
    }
    action int_set_header_0003_i10() {
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i11() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_0();
    }
    action int_set_header_0003_i12() {
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i13() {
        int_set_header_3();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i14() {
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }
    action int_set_header_0003_i15() {
        int_set_header_3();
        int_set_header_2();
        int_set_header_1();
        int_set_header_0();
    }

    /* Table to process instruction bits 0-3 */
    table int_inst_0003 {
        key = {
            hdr.int_header.instruction_mask_0003: exact;
        }
        actions = {
            int_set_header_0003_i0;
            int_set_header_0003_i1;
            int_set_header_0003_i2;
            int_set_header_0003_i3;
            int_set_header_0003_i4;
            int_set_header_0003_i5;
            int_set_header_0003_i6;
            int_set_header_0003_i7;
            int_set_header_0003_i8;
            int_set_header_0003_i9;
            int_set_header_0003_i10;
            int_set_header_0003_i11;
            int_set_header_0003_i12;
            int_set_header_0003_i13;
            int_set_header_0003_i14;
            int_set_header_0003_i15;
            NoAction;
        }
        default_action = NoAction();
        size = 16;
        const entries = {
            0: int_set_header_0003_i0();
            1: int_set_header_0003_i1();
            2: int_set_header_0003_i2();
            3: int_set_header_0003_i3();
            4: int_set_header_0003_i4();
            5: int_set_header_0003_i5();
            6: int_set_header_0003_i6();
            7: int_set_header_0003_i7();
            8: int_set_header_0003_i8();
            9: int_set_header_0003_i9();
            10: int_set_header_0003_i10();
            11: int_set_header_0003_i11();
            12: int_set_header_0003_i12();
            13: int_set_header_0003_i13();
            14: int_set_header_0003_i14();
            15: int_set_header_0003_i15();
        }
    }

    /*
     * Action functions for bits 4-7 combinations, 4 is msb, 7 is lsb.
     * Each bit set indicates that corresponding INT header should be added.
     */
    action int_set_header_0407_i0() {
    }
    action int_set_header_0407_i1() {
        int_set_header_7();
    }
    action int_set_header_0407_i2() {
        int_set_header_6();
    }
    action int_set_header_0407_i3() {
        int_set_header_7();
        int_set_header_6();
    }
    action int_set_header_0407_i4() {
        int_set_header_5();
    }
    action int_set_header_0407_i5() {
        int_set_header_7();
        int_set_header_4();
    }
    action int_set_header_0407_i6() {
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i7() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
    }
    action int_set_header_0407_i8() {
        int_set_header_4();
    }
    action int_set_header_0407_i9() {
        int_set_header_7();
        int_set_header_4();
    }
    action int_set_header_0407_i10() {
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i11() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_4();
    }
    action int_set_header_0407_i12() {
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i13() {
        int_set_header_7();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i14() {
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }
    action int_set_header_0407_i15() {
        int_set_header_7();
        int_set_header_6();
        int_set_header_5();
        int_set_header_4();
    }

    /* Table to process instruction bits 4-7 */
    table int_inst_0407 {
        key = {
            hdr.int_header.instruction_mask_0407: exact;
        }
        actions = {
            int_set_header_0407_i0;
            int_set_header_0407_i1;
            int_set_header_0407_i2;
            int_set_header_0407_i3;
            int_set_header_0407_i4;
            int_set_header_0407_i5;
            int_set_header_0407_i6;
            int_set_header_0407_i7;
            int_set_header_0407_i8;
            int_set_header_0407_i9;
            int_set_header_0407_i10;
            int_set_header_0407_i11;
            int_set_header_0407_i12;
            int_set_header_0407_i13;
            int_set_header_0407_i14;
            int_set_header_0407_i15;
            NoAction;
        }
        default_action = NoAction();
        size = 16;
        const entries = {
            0: int_set_header_0407_i0();
            1: int_set_header_0407_i1();
            2: int_set_header_0407_i2();
            3: int_set_header_0407_i3();
            4: int_set_header_0407_i4();
            5: int_set_header_0407_i5();
            6: int_set_header_0407_i6();
            7: int_set_header_0407_i7();
            8: int_set_header_0407_i8();
            9: int_set_header_0407_i9();
            10: int_set_header_0407_i10();
            11: int_set_header_0407_i11();
            12: int_set_header_0407_i12();
            13: int_set_header_0407_i13();
            14: int_set_header_0407_i14();
            15: int_set_header_0407_i15();
        }
    }

    apply {
        int_inst_0003.apply();
        int_inst_0407.apply();
        // int_inst_0811.apply();
    }
}
# 22 "egress_mau.p4" 2

control egress_mau (
        inout egress_headers_t hdr,
        inout egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_t egress_intrinsic_metadata,
        in egress_intrinsic_metadata_from_parser_t
            egress_intrinsic_metadata_from_parser,
        inout egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser,
        inout egress_intrinsic_metadata_for_output_port_t
            egress_intrinsic_metadata_for_output_port)
{
    metadata_insert_control() metadata_insert;
    outer_encap_control() outer_encap;

    action int_save_int_header_data() {
        egress_metadata.int_metadata.insert_word_cnt =
            (bit<16>) hdr.int_header.hop_metadata_len;
        egress_metadata.int_metadata.insert_double_word_cnt =
            (bit<16>) (hdr.int_header.hop_metadata_len >> 1);
        egress_metadata.int_metadata.length =
            egress_metadata.l3_mtu - hdr.ipv6.payload_len;
    }

    table int_save_int_header_data_table {
        actions = {
            int_save_int_header_data;
        }
        default_action = int_save_int_header_data;
        size = 1;
    }

    action int_hop_cnt_exceeded() {
        hdr.int_header.e = 1;
    }

    action int_mtu_limit_hit() {
        hdr.int_header.m = 1;
    }

    action int_hop_cnt_decrement() {
        hdr.int_header.remaining_hop_cnt =
            hdr.int_header.remaining_hop_cnt - 1;
    }

    action int_transit(bit<32> switch_id, bit<16> l3_mtu) {
        egress_metadata.int_metadata.switch_id = switch_id;
        egress_metadata.int_metadata.insert_byte_cnt =
            egress_metadata.int_metadata.insert_word_cnt << 2;
        egress_metadata.int_metadata.int_hdr_word_len =
            (bit<8>) hdr.int_header.hop_metadata_len;
        egress_metadata.l3_mtu = l3_mtu;
    }

    table int_prep {
        key = {}
        actions = {
            int_transit;
        }
        default_action = int_transit(0x42434445, 1500);
        size = 1;
    }

    apply {
        egress_metadata.egress_timestamp =
            egress_intrinsic_metadata_from_parser.global_tstamp;
        if (hdr.int_header.isValid()) {
            if (hdr.int_header.remaining_hop_cnt == 0
                    || (hdr.int_header.e == 1)) {
                int_hop_cnt_exceeded();
            } else if ((hdr.int_header.instruction_mask_0811 == 0) &&
                        (hdr.int_header.instruction_mask_1215[3:3] == 0)) {
                /* v1.0 spec allows two options for handling unsupported
                 * INT instructions. This example code skips the entire
                 * hop if any unsupported bit (bit 8 to 14 in v1.0 spec)
                 * is set.
                 */
                int_prep.apply();
                int_save_int_header_data_table.apply();
                // check MTU limit
                egress_metadata.int_metadata.length =
                    egress_metadata.int_metadata.length -
                    egress_metadata.int_metadata.insert_byte_cnt;
                if (egress_metadata.int_metadata.length <= 0) {
                    int_mtu_limit_hit();
                } else {
                    int_hop_cnt_decrement();
                    metadata_insert.apply(hdr, egress_metadata,
                        egress_metadata.int_metadata,
                        egress_intrinsic_metadata);
                    outer_encap.apply(hdr, egress_metadata.int_metadata);
                }
            }
        }
        hdr.bridged_metadata.setInvalid();
    }
}
# 36 "int_demo.p4" 2
# 1 "egress_deparser.p4" 1
/*
 * Copyright 2019-present Ronald van der Pol <Ronald.vanderPol@rvdp.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




control egress_deparser (
        packet_out pkt,
        inout egress_headers_t hdr,
        in egress_metadata_t egress_metadata,
        in egress_intrinsic_metadata_for_deparser_t
            egress_intrinsic_metadata_for_deparser)
{
    apply {
        pkt.emit(hdr);
    }
}
# 37 "int_demo.p4" 2

Pipeline(
    ingress_parser(),
    ingress_mau(),
    ingress_deparser(),
    egress_parser(),
    egress_mau(),
    egress_deparser()
) pipe;

Switch(pipe) main;
