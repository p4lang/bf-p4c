# 1 "case9745.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "case9745.p4"
/* npb_switch.p4
 *
 * Supports only bridging for passive Network Packet Broker (NPB) operations.
 *
 * Copyright 2019 MNK Consulting, LLC.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * MNK Consulting, LLC. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to MNK Consulting, LLC.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law. Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from MNK Consulting, LLC.
* No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with MNK Consulting, LLC.
 *
*/
# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/core.p4" 1
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
# 21 "case9745.p4" 2



# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/tna.p4" 1
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




# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/tna.p4" 2
# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/tofino.p4" 2

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
# 24 "/home/vgurevich/bf-sde-9.0.0/install/share/p4c/p4include/tna.p4" 2

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
# 25 "case9745.p4" 2



struct empty_header_t {}

struct empty_metadata_t {}


// Make sure, with new SDE, change strings below.
# 1 "common/util.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2019-present Barefoot Networks, Inc.
 *
 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks, Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.  Dissemination of
 * this information or reproduction of this material is strictly forbidden unless
 * prior written permission is obtained from Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a written
 * agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/




parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
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
        pkt.advance(PORT_METADATA_SIZE);
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

// Skip egress
control BypassEgress(inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action set_bypass_egress() {
        ig_tm_md.bypass_egress = 1w1;
    }

    table bypass_egress {
        actions = {
            set_bypass_egress();
        }
        const default_action = set_bypass_egress;
    }

    apply {
        bypass_egress.apply();
    }
}

// Empty egress parser/control blocks
parser EmptyEgressParser(
        packet_in pkt,
        out empty_header_t hdr,
        out empty_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser(
        packet_out pkt,
        inout empty_header_t hdr,
        in empty_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress(
        inout empty_header_t hdr,
        inout empty_metadata_t eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 35 "case9745.p4" 2

//#include <util.p4>

/*
 * ingress parser/mau/deparser and have egress parser/mau/deparser all empty - did not
 *  work. Ran into hash not fitting in ingress - this is the error.
 * In file: /media/ramdisk/submodules/bf-p4c-compilers/p4c/extensions/bf-p4c/mau/action_format.cpp:388
 * Compiler Bug: Hash distribution splitting too complicated
*/



enum bit<8> tunnelTypes {
    NO_TUN = 8w0,
    IPVX_IN_IP = 8w1,
    GTP = 8w2,
    EOMPLS = 8w3,
    MPLS_VX = 8w4
}

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;

typedef bit<16> bd_t;
typedef bit<16> ifindex_t;
typedef bit<16> nexthop_t;
typedef bit<16> vrf_t;

struct npb_metadata_t {
    ifindex_t eg_id;
    bit<20> lb_hash;
}

struct egress_metadata_t {
    npb_metadata_t npb;
}

header bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    bit<4> type;
    ifindex_t eg_id;
    bit<20> lb_hash;
}

struct ingress_metadata_t {
    bd_t bd;
    nexthop_t nexthop;
    ifindex_t ifindex;
    ifindex_t egress_ifindex;
}

struct tunnel_metadata_t {
    bit<8> ingress_tunnel_type;
    bit<24> tunnel_vni;
    bit<1> mpls_enabled;
    bit<20> mpls_label;
    bit<3> mpls_exp;
    bit<8> mpls_ttl;
    bit<8> egress_tunnel_type;
    bit<14> tunnel_index;
    bit<9> tunnel_src_index;
    bit<9> tunnel_smac_index;
    bit<14> tunnel_dst_index;
    bit<14> tunnel_dmac_index;
    bit<24> vnid;
    bit<1> tunnel_terminate;
    bit<1> tunnel_if_check;
    bit<4> egress_header_count;
    bit<8> inner_ip_proto;
}

// PW control word
header eompls_t {
    bit<4> zero;
    bit<12> reserved;
    bit<16> seqNo;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
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
    bit<32> srcAddr;
    bit<32> dstAddr;
}

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

header sctp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> verifTag;
    bit<32> checksum;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4> dataOffset;
    bit<4> res;
    bit<8> flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header mpls_t {
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

header vlan_tag_t {
    bit<3> pcp;
    bit<1> cfi;
    bit<12> vid;
    bit<16> etherType;
}

// GTP message format
header gtpv01_t {
    bit<3> ver;
    bit<1> pt; // Protocol type
    bit<1> reserved;
    bit<1> e; // Extension header flag
    bit<1> s; // Sequence number flag
    bit<1> pn; // N-PDU number flag
    bit<8> mesgType;
    bit<16> mesgLen;
    bit<32> teid; // Tunnel endpoint id
}

header gtpv01_opt_fields_t {
    bit<16> seqnum;
    bit<8> npdu;
    bit<8> next_hdr;
    bit<8> extLen;
    bit<16> contents;
    bit<8> nextExtHdr;
}
header pppoe_payload_t {
    bit<4> ver;
    bit<4> type;
    bit<8> code;
    bit<16> session_id;
    bit<16> len;
    bit<16> ppp_prot_id;
    // TODO: IPv6 compression protcol id
}

header ppp_t {
    bit<48> x;
}

struct metadata_t {
    bit<8> lb_type;
    bit<20> lb_hash;
    bit<8> espec;
    bit<8> inner_tunnel_type;
    bit<1> pw_ctrl_word_present;
    bit<1> ppoe_type;
}

struct metadata {
    ingress_metadata_t ingress_metadata;
    ingress_intrinsic_metadata_t intrinsic_metadata;
    tunnel_metadata_t tunnel_metadata;
    metadata_t meta;
}

struct headers {
    bridged_metadata_t bridged_md;
    ethernet_t ethernet;
    vlan_tag_t[6] vlan_tag;
    mpls_t[6] mpls;
    eompls_t eompls;
    pppoe_payload_t pppoe;
    ppp_t ppp;
    ipv4_t ipv4;
    ipv6_t ipv6;
    udp_t udp;
    tcp_t tcp;
    sctp_t sctp;
    gtpv01_t gtpv01_hdr;
    gtpv01_opt_fields_t gtpv01_opts;
    ethernet_t inner_ethernet;
    ipv4_t inner_ipv4;
    ipv6_t inner_ipv6;
    udp_t inner_udp;
    tcp_t inner_tcp;
    sctp_t inner_sctp;
}

struct lookup_fields_t {
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;

    bit<4> ip_version;
    bit<8> ip_proto;
    bit<8> ip_ttl;
    bit<8> ip_dscp;

    bit<20> ipv6_flow_label;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;
    ipv6_addr_t ipv6_src_addr;
    ipv6_addr_t ipv6_dst_addr;
}

// Copied from BF p4-16 simple_switch.p4
//-----------------------------------------------------------------------------
// Packet validaion
// Validate ethernet, Ipv4 or Ipv6 headers and set the common lookup fields.
//-----------------------------------------------------------------------------
control PktValidation(
        in headers hdr, out lookup_fields_t lkp) {

    const bit<32> table_size = 512;

    action malformed_pkt() {
        // drop.
    }

    action valid_pkt_untagged() {
        lkp.mac_src_addr = hdr.ethernet.srcAddr;
        lkp.mac_dst_addr = hdr.ethernet.dstAddr;
        lkp.mac_type = hdr.ethernet.etherType;
    }

    action valid_pkt_tagged() {
        lkp.mac_src_addr = hdr.ethernet.srcAddr;
        lkp.mac_dst_addr = hdr.ethernet.dstAddr;
        lkp.mac_type = hdr.vlan_tag[0].etherType; // TODO: we have 6 VLANs, what do we do?
    }

    table validate_ethernet {
        key = {
            hdr.ethernet.srcAddr : ternary;
            hdr.ethernet.dstAddr : ternary;
            hdr.vlan_tag[0].isValid() : ternary; // TODO: we have 6 VLANs, what do we do?
        }

        actions = {
            malformed_pkt;
            valid_pkt_untagged;
            valid_pkt_tagged;
        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Validate outer IPv4 header and set the lookup fields.
// - Drop the packet if ttl is zero, ihl is invalid, or version is invalid.
//-----------------------------------------------------------------------------
    action valid_ipv4_pkt() {
        // Set common lookup fields
        lkp.ip_version = 4w4;
        lkp.ip_dscp = hdr.ipv4.diffserv;
        lkp.ip_proto = hdr.ipv4.protocol;
        lkp.ip_ttl = hdr.ipv4.ttl;
        lkp.ipv4_src_addr = hdr.ipv4.srcAddr;
        lkp.ipv4_dst_addr = hdr.ipv4.dstAddr;
    }

    table validate_ipv4 {
        key = {
            //ig_md.checksum_err : ternary;
            hdr.ipv4.version : ternary;
            hdr.ipv4.ihl : ternary;
            hdr.ipv4.ttl : ternary;
        }

        actions = {
            valid_ipv4_pkt;
            malformed_pkt;
        }

        size = table_size;
    }

//-----------------------------------------------------------------------------
// Validate outer IPv6 header and set the lookup fields.
// - Drop the packet if hop_limit is zero or version is invalid.
//-----------------------------------------------------------------------------
    action valid_ipv6_pkt() {
        // Set common lookup fields
        lkp.ip_version = 4w6;
        lkp.ip_dscp = hdr.ipv6.trafficClass;
        lkp.ip_proto = hdr.ipv6.nextHdr;
        lkp.ip_ttl = hdr.ipv6.hopLimit;
        lkp.ipv6_src_addr = hdr.ipv6.srcAddr;
        lkp.ipv6_dst_addr = hdr.ipv6.dstAddr;
    }

    table validate_ipv6 {
        key = {
            hdr.ipv6.version : ternary;
            hdr.ipv6.hopLimit : ternary;
        }

        actions = {
            valid_ipv6_pkt;
            malformed_pkt;
        }

        size = table_size;
    }

    apply {
        validate_ethernet.apply();
        if (hdr.ipv4.isValid()) {
            validate_ipv4.apply();
        } else if (hdr.ipv6.isValid()) {
            validate_ipv6.apply();
        }
    }
}

control PortMapping(
        in PortId_t port,
        in vlan_tag_t vlan_tag,
        in headers hdr,
        inout metadata meta)(
        bit<32> port_vlan_table_size,
        bit<32> bd_table_size) {

    ActionProfile(bd_table_size) bd_action_profile;

    action set_port_attributes(ifindex_t ifindex) {
        meta.ingress_metadata.ifindex = ifindex;
        // Add more port attributes here.
    }

    table port_mapping {
        key = { port : exact; }
        actions = { set_port_attributes; }
    }

    action set_bd_attributes(bd_t bd, vrf_t vrf) {
        meta.ingress_metadata.bd = bd;
    }

    table port_vlan_to_bd_mapping {
        key = {
            meta.ingress_metadata.ifindex : exact;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary; // TODO: we have 6 VLANs, what do we do?
        }

        actions = {
            NoAction;
            set_bd_attributes;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = port_vlan_table_size;
    }

    apply {
        port_mapping.apply();
        port_vlan_to_bd_mapping.apply();
    }
}

//-----------------------------------------------------------------------------
// Destination MAC lookup
// - Bridge out the packet of the interface in the MAC entry.
// - Flood the packet out of all ports within the ingress BD.
//-----------------------------------------------------------------------------
control MAC(
    in mac_addr_t dst_addr,
    in bd_t bd,
    inout ifindex_t egress_ifindex)(
    bit<32> mac_table_size) {

    action dmac_miss() {
        egress_ifindex = 16w0xffff;
    }

    action dmac_hit(ifindex_t ifindex) {
        egress_ifindex = ifindex;
    }

    table dmac {
        key = {
            bd : exact;
            dst_addr : exact;
        }

        actions = {
            dmac_miss;
            dmac_hit;
        }

        const default_action = dmac_miss;
        size = mac_table_size;
    }

    apply {
        dmac.apply();
    }
}

control FIB(in mac_addr_t dst_addr,
            out nexthop_t nexthop)(
            bit<32> host_table_size) {

    action fib_hit(nexthop_t nexthop_index) {
        nexthop = nexthop_index;
    }

    action fib_miss() { }

    table fib {
        key = {
            dst_addr : exact;
        }

        actions = {
            fib_miss;
            fib_hit;
        }

        const default_action = fib_miss;
        size = host_table_size;
    }

    apply {
        fib.apply();
    }
}

// ----------------------------------------------------------------------------
// Nexthop
// ----------------------------------------------------------------------------
control Nexthop(inout headers hdr,
                inout metadata meta,
                inout mac_addr_t mac)(
                bit<32> table_size) {

    action set_nexthop_attributes(bd_t bd, mac_addr_t dmac) {
        meta.ingress_metadata.bd = bd;
        mac = dmac;
    }

    table nexthop {
        key = {
            meta.ingress_metadata.nexthop : exact;
        }

        actions = {
            NoAction;
            set_nexthop_attributes;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
        nexthop.apply();
    }
}

// Copied from BF p4-16 simple_switch.p4
// ----------------------------------------------------------------------------
// Link Aggregation
// ----------------------------------------------------------------------------
control LAG(in lookup_fields_t lkp,
            in ifindex_t ifindex,
            out PortId_t egress_port) {
    Hash<bit<32>>(HashAlgorithm_t.CRC32) sel_hash;
    ActionSelector(1024, sel_hash, SelectorMode_t.FAIR) lag_selector;

    action set_port(PortId_t port) {
        egress_port = port;
    }

    action lag_miss() { }

    table lag {
        key = {
            ifindex : exact;
            lkp.ipv6_src_addr : selector;
            lkp.ipv6_dst_addr : selector;
            lkp.ipv6_flow_label : selector;
            lkp.ipv4_src_addr : selector;
            lkp.ipv4_dst_addr : selector;
        }

        actions = {
            lag_miss;
            set_port;
        }

        const default_action = lag_miss;
        size = 1024;
        implementation = lag_selector;
    }

    apply {
        lag.apply();
    }
}

parser SwitchIngressParser(packet_in packet, out headers hdr,
                           out metadata meta,
                           out ingress_intrinsic_metadata_t ig_intr_md) {
    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(packet, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.NO_TUN;
        transition select(hdr.ethernet.etherType) {
            16w0x8100: parse_vlan;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            16w0x88a8: parse_qinq;
            16w0x8847: parse_mpls;
     16w0x8863: parse_pppoe;
     16w0x8864: parse_pppoe;
            default: accept;
        }
    }

    state parse_gtpv01_hdr {
        packet.extract(hdr.gtpv01_hdr);
        transition select(hdr.gtpv01_hdr.e) {
            1w0: parse_gtp_payload;
            default: parse_gtpv01_opts;
        }
    }

    state parse_gtpv01_opts {
        packet.extract(hdr.gtpv01_opts);
        transition parse_gtp_payload;
    }

    state parse_gtp_payload {
        bit<4> version = packet.lookahead<bit<4>>();
        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.GTP;
        transition select(version) {
            4w4: parse_inner_ipv4;
            4w6: parse_inner_ipv6;
            default: reject;
        }
    }

    state parse_inner_ethernet {
        packet.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_inner_ipv4;
            16w0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }
    state parse_inner_eompls {
        packet.extract(hdr.inner_ethernet);
        transition select(hdr.inner_ethernet.etherType) {
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ihl, hdr.inner_ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x6): parse_inner_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_inner_udp;
            (13w0x0, 4w0x5, 8w0x84): parse_inner_sctp;
            (13w0x0, 4w0x5, 8w0x4): parse_ipv4_in_ip;
            (13w0x0, 4w0x5, 8w0x29): parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_inner_ipv6 {
        packet.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w17: parse_inner_udp;
            8w6: parse_inner_tcp;
            8w132: parse_inner_sctp;
            8w4: parse_ipv4_in_ip;
            8w41: parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x6): parse_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_udp;
            (13w0x0, 4w0x5, 8w0x84): parse_sctp;
            (13w0x0, 4w0x5, 8w0x4): parse_ipv4_in_ip;
            (13w0x0, 4w0x5, 8w0x29): parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_ipv4_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.IPVX_IN_IP;
        transition parse_inner_ipv4;
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w6: parse_tcp;
            8w132: parse_sctp;
            8w4: parse_ipv4_in_ip;
            8w17: parse_udp;
            8w41: parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_ipv6_in_ip {
        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.IPVX_IN_IP;
        transition parse_inner_ipv6;
    }
    state parse_mpls {
        packet.extract(hdr.mpls.next);
        transition select(hdr.mpls.last.bos) {
            1w1: parse_mpls_bos;
            default: parse_mpls;
        }
    }
    state parse_mpls_bos {
        transition select((packet.lookahead<bit<4>>())) {
            4w0x0: parse_mpls_pw_ctrl;
            4w0x4: parse_ipv4;
            4w0x6: parse_ipv6;
            default: parse_eompls;
        }
    }
    state parse_eompls {
        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.EOMPLS;
        transition parse_inner_eompls;
    }
    state parse_mpls_pw_ctrl {
 packet.extract(hdr.eompls);
        meta.meta.pw_ctrl_word_present = 1w1;
        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.EOMPLS;
        transition parse_inner_eompls;
    }
    state parse_qinq {
        packet.extract(hdr.vlan_tag[0]);
        transition select(hdr.vlan_tag[0].etherType) {
            16w0x8100: parse_qinq_vlan;
            default: accept;
        }
    }
    state parse_qinq_vlan {
        packet.extract(hdr.vlan_tag[1]);
        transition select(hdr.vlan_tag[1].etherType) {
            16w0x8847: parse_mpls;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
            default: accept;
        }
    }
    state parse_sctp {
        packet.extract(hdr.sctp);
        transition accept;
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        transition select(hdr.udp.dstPort) {
            16w2152: parse_gtpv01_hdr;
            default: accept;
        }
    }
    state parse_inner_sctp {
        packet.extract(hdr.inner_sctp);
        transition accept;
    }
    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        transition accept;
    }
    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        transition accept;
    }
    state parse_vlan {
        packet.extract(hdr.vlan_tag.next);
        transition select(hdr.vlan_tag.last.etherType) {
            16w0x8100: parse_vlan;
            16w0x800: parse_ipv4;
            16w0x86dd: parse_ipv6;
     16w0x8847: parse_mpls;
            default: accept;
        }
    }
    state parse_pppoe {
        meta.meta.ppoe_type = 1w1;
        packet.extract(hdr.pppoe);
        transition select(hdr.pppoe.ppp_prot_id) {
            16w0x0021: parse_ipv4;
            16w0x0057: parse_ipv6;
     default: accept;
        }
    }
}

control SwitchIngress(inout headers hdr,
                      inout metadata meta,
                      in ingress_intrinsic_metadata_t ig_intr_md,
                      in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
                      inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                      inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    PortMapping(1024, 1024) port_mapping;
    PktValidation() pkt_validation;
    Nexthop(1024) nexthop;
    FIB(1024) fib;
    MAC(1024) mac;
    LAG() lag;
    mac_addr_t dmac = 48w0;
    lookup_fields_t lkp;


    // Define which input field pairs for the hash should be made symmetric.
    // Multiple pairs can be defined using multiple pragma calls.
    @symmetric("hdr.inner_ipv4.srcAddr", "hdr.inner_ipv4.dstAddr")
    Hash<bit<20>>(HashAlgorithm_t.CRC32) hash_1;
    @symmetric("hdr.inner_ipv6.srcAddr", "hdr.inner_ipv6.dstAddr")
    Hash<bit<20>>(HashAlgorithm_t.CRC32) hash_2;
    @symmetric("hdr.ipv4.srcAddr", "hdr.ipv4.dstAddr")
    Hash<bit<20>>(HashAlgorithm_t.CRC32) hash_3;
    @symmetric("hdr.ipv6.srcAddr", "hdr.ipv6.dstAddr")
    Hash<bit<20>>(HashAlgorithm_t.CRC32) hash_4;
# 827 "case9745.p4"
    action set_lb_hashed_index_ipv4() {
        hdr.bridged_md.lb_hash = hash_1.get({hdr.inner_ipv4.srcAddr, hdr.inner_ipv4.dstAddr});
        meta.meta.espec = hdr.bridged_md.lb_hash[19:12];
    }
    action set_lb_hashed_index_ipv6() {
        hdr.bridged_md.lb_hash = hash_2.get({hdr.inner_ipv6.srcAddr, hdr.inner_ipv6.dstAddr});
        meta.meta.espec = hdr.bridged_md.lb_hash[19:12];
    }

    action set_lb_hashed_index_outer_ipv4() {
        hdr.bridged_md.lb_hash = hash_3.get({hdr.ipv4.srcAddr, hdr.ipv4.dstAddr});
        meta.meta.espec = hdr.bridged_md.lb_hash[19:12];
    }
    action set_lb_hashed_index_outer_ipv6() {
        hdr.bridged_md.lb_hash = hash_4.get({hdr.ipv6.srcAddr, hdr.ipv6.dstAddr});
        meta.meta.espec = hdr.bridged_md.lb_hash[19:12];
    }

    action outer_ipv4_strip() {
        hdr.ipv4.setInvalid();
    }
    action outer_ipv6_strip() {
        hdr.ipv6.setInvalid();
    }
    action eompls_strip() { // or pseudowire
        hdr.eompls.setInvalid();
    }
    action pppoe_strip() {
        hdr.pppoe.setInvalid();
    }
    action ppp_strip() {
        hdr.ppp.setInvalid();
    }
    // If MAX_VLAN changes definition, this action changes to add/remove
    // setInvalid statements.
    action vlan_strip() {
        hdr.vlan_tag[0].setInvalid();
        hdr.vlan_tag[1].setInvalid();
        hdr.vlan_tag[2].setInvalid();
        hdr.vlan_tag[3].setInvalid();
        hdr.vlan_tag[4].setInvalid();
        hdr.vlan_tag[5].setInvalid();
    }
    // If MAX_MPLS changes definition, this action changes to add/remove
    // setInvalid statements.
    action mpls_strip() {
        hdr.mpls[0].setInvalid();
        hdr.mpls[1].setInvalid();
        hdr.mpls[2].setInvalid();
        hdr.mpls[3].setInvalid();
        hdr.mpls[4].setInvalid();
        hdr.mpls[5].setInvalid();
    }
    // If MAX_MPLS changes definition, this action changes to add/remove
    // setInvalid statements.
    // EoMPLS = Eth|MPLS|tnnlEth|IPx
/*    action l2tunnel_strip() {
        hdr.ethernet.setInvalid();
        hdr.inner_ethernet.setInvalid();
    }
*/
    action gtp_strip() {
        hdr.gtpv01_hdr.setInvalid();
        hdr.gtpv01_opts.setInvalid();
    }

    action add_bridged_md() {
        hdr.bridged_md.setValid();
        hdr.bridged_md.type = 4w0;
    }

    action set_egress_spec(bit<8> spec) {
 meta.ingress_metadata.egress_ifindex[15:8] = spec; // TODO: use this setting once symmtric hash is supported with p4-16 from BF.  Right now mac.apply() is used.
    }
    table lb_tbl {
        key = {
            meta.meta.espec : exact;
        }
        actions = {
            set_egress_spec;
        }
 size = 256;
    }

    apply {
        meta.ingress_metadata.nexthop = 16w0;
        mpls_strip();
 if (meta.meta.pw_ctrl_word_present == 1w1) {
     eompls_strip();
 }
        pppoe_strip();
        ppp_strip();
        add_bridged_md();
        if ((meta.tunnel_metadata.ingress_tunnel_type >=
     (bit<8>)tunnelTypes.IPVX_IN_IP) &&
     (meta.tunnel_metadata.ingress_tunnel_type <
     (bit<8>)tunnelTypes.EOMPLS)) { // IP tunnel
     outer_ipv4_strip();
     outer_ipv6_strip();
            hdr.udp.setInvalid();
            hdr.tcp.setInvalid();
            hdr.sctp.setInvalid();
     gtp_strip();
     if (hdr.inner_ipv4.version == 4) {
  set_lb_hashed_index_ipv4();
  hdr.bridged_md.type = 4w1;
            } else if (hdr.inner_ipv6.version == 6) {
                set_lb_hashed_index_ipv6();
  hdr.bridged_md.type = 4w2;
            }
 } else {
            if (hdr.ipv4.version == 4) {
  set_lb_hashed_index_outer_ipv4();
  hdr.bridged_md.type = 4w3;
     } else if (hdr.ipv4.version == 6) {
  set_lb_hashed_index_outer_ipv6();
  hdr.bridged_md.type = 4w4;
     }
 }
 lb_tbl.apply();
 // TODO: what happens to vlan_tag below if ingressed pkt has 6 VLANs?
        port_mapping.apply(ig_intr_md.ingress_port, hdr.vlan_tag[0], hdr, meta); // TODO: we have 6 VLANs, what do we do?
 pkt_validation.apply(hdr, lkp);
 if (hdr.inner_ethernet.isValid()) {
     dmac = hdr.inner_ethernet.dstAddr;
 } else {
            dmac = hdr.ethernet.dstAddr;
        }
        fib.apply(dmac, meta.ingress_metadata.nexthop);
        nexthop.apply(hdr, meta, dmac);
        mac.apply(dmac, meta.ingress_metadata.bd, meta.ingress_metadata.egress_ifindex);
        lag.apply(lkp, meta.ingress_metadata.egress_ifindex, ig_tm_md.ucast_egress_port);
        hdr.bridged_md.eg_id = meta.ingress_metadata.egress_ifindex;
 vlan_strip();
    }

}

/* Deparser control cannot apply a table */
control SwitchIngressDeparser(packet_out packet,
                              inout headers hdr,
                              in metadata meta,
                              in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    apply {
        packet.emit(hdr.bridged_md);
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
        packet.emit(hdr.sctp);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_ipv6);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_sctp);
    }
}

parser SwitchEgressParser(
        packet_in packet,
        out headers hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    TofinoEgressParser() tofino_parser;

    state start {
        tofino_parser.apply(packet, eg_intr_md);
        transition parse_bridged_metadata;
    }
    state parse_bridged_metadata {
        packet.extract(hdr.bridged_md);
        eg_md.npb.eg_id = hdr.bridged_md.eg_id;
        eg_md.npb.lb_hash = hdr.bridged_md.lb_hash;
        transition parse_ethernet;
    }
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.bridged_md.type) {
            4w1 : parse_inner_ipv4;
            4w2 : parse_inner_ipv6;
            4w3 : parse_ipv4;
            4w4 : parse_ipv6;
     default: accept;
        }
    }
    state parse_inner_ipv4 {
        packet.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.fragOffset, hdr.inner_ipv4.ihl, hdr.inner_ipv4.protocol) {
            (13w0x0, 4w0x5, 8w0x6): parse_inner_tcp;
            (13w0x0, 4w0x5, 8w0x11): parse_inner_udp;
            (13w0x0, 4w0x5, 8w0x84): parse_inner_sctp;
            (13w0x0, 4w0x5, 8w0x4): parse_ipv4_in_ip;
            (13w0x0, 4w0x5, 8w0x29): parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_inner_ipv6 {
        packet.extract(hdr.inner_ipv6);
        transition select(hdr.inner_ipv6.nextHdr) {
            8w17: parse_inner_udp;
            8w6: parse_inner_tcp;
            8w132: parse_inner_sctp;
            8w4: parse_ipv4_in_ip;
            8w41: parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_inner_sctp {
        packet.extract(hdr.inner_sctp);
        transition accept;
    }
    state parse_inner_tcp {
        packet.extract(hdr.inner_tcp);
        transition accept;
    }
    state parse_inner_udp {
        packet.extract(hdr.inner_udp);
        transition accept;
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w0x6: parse_tcp;
            8w0x11: parse_udp;
            8w0x84: parse_sctp;
            8w0x4: parse_ipv4_in_ip;
            8w0x29: parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_ipv4_in_ip {
    // TODO: Do we support ipv4 in ip tunnel?  Sewar hasn't asked for it.
//        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.IPVX_IN_IP;
        transition parse_inner_ipv4;
    }
    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            8w6: parse_tcp;
            8w132: parse_sctp;
            8w4: parse_ipv4_in_ip;
            8w17: parse_udp;
            8w41: parse_ipv6_in_ip;
            default: accept;
        }
    }
    state parse_ipv6_in_ip {
    // TODO: Do we support ipv6 in ip tunnel?  Sewar hasn't asked for it.
//        meta.tunnel_metadata.ingress_tunnel_type = (bit<8>)tunnelTypes.IPVX_IN_IP;
        transition parse_inner_ipv6;
    }
    state parse_sctp {
        packet.extract(hdr.sctp);
        transition accept;
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }
    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
}

control SwitchEgress(inout headers hdr,
                     inout egress_metadata_t eg_md,
                     in egress_intrinsic_metadata_t eg_intr_md,
                     in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
                     inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                     inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    action nop() { }
    action rewrite_vlan0_eth(bit<48> srcAddr,
                             bit<48> dstAddr) {
        hdr.ethernet.setValid();
 hdr.ethernet.srcAddr = srcAddr;
 hdr.ethernet.dstAddr = dstAddr;
 hdr.ethernet.etherType = 16w0x8100;
        hdr.vlan_tag[0].setValid();
 // TODO: When symmetric hash is supported for p4-16 by BF.
        hdr.vlan_tag[0].vid = 7; // eg_md.npb.lb_hash[11:0];

    }
    table rewrite_tbl {
 key = {
            eg_md.npb.eg_id : exact;
 }
 actions = {
     rewrite_vlan0_eth;
     nop;
 }
    }

    apply {
        hdr.ethernet.setInvalid();
        hdr.inner_ethernet.setInvalid();
 if (hdr.ipv6.isValid() || hdr.inner_ipv6.isValid()) {
     hdr.vlan_tag[0].etherType = 16w0x86dd;
 } else {
     hdr.vlan_tag[0].etherType = 16w0x800;
 }
 rewrite_tbl.apply();
    }
}

control SwitchEgressDeparser(packet_out packet, inout headers hdr,
                             in egress_metadata_t eg_md,
                             in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag[0]);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
        packet.emit(hdr.sctp);
        packet.emit(hdr.inner_ipv4);
        packet.emit(hdr.inner_ipv6);
        packet.emit(hdr.inner_udp);
        packet.emit(hdr.inner_tcp);
        packet.emit(hdr.inner_sctp);
    }
}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         SwitchEgressParser(),
  SwitchEgress(),
  SwitchEgressDeparser()) pipe;

Switch(pipe) main;
