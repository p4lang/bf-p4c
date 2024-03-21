# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4"
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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

@command_line("--disable-parse-max-depth-limit")
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
# 2 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 1
/*
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
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


# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 1
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




# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino.p4" 1
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




# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 23 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino.p4" 2

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

extern bool is_validated<T>(in T field);

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
    MathUnit(MathOp_t op, int factor); // configure as factor * op(x)
    MathUnit(MathOp_t op, int A, int B); // configure as (A/B) * op(x)
    T execute(in T x);
};

// This is implemented using an experimental feature in p4c and subject to
// change. See https://github.com/p4lang/p4-spec/issues/561
extern RegisterAction<T, I, U> {
    RegisterAction(Register<_, _> reg);

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
# 24 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino_fixed.p4" 1
/*
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
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

// Fixed function blocks in Tofino are configured by bf_runtime through a
// table-based API. Each table requires a unique name that is not used by the
// user-defined table in P4 program. These fixed function blocks are
// instantiated as a top level extern instances. Their names are reserved at
// top level and used by bf_runtime.
//
// These extern constructs are NOT to be used in any P4 programs.

extern PacketReplicationEngine {
    PacketReplicationEngine();
}

PacketReplicationEngine() pre;

extern MirrorEngine {
    MirrorEngine();
}

MirrorEngine() mirror;

extern PortConfigrationEngine {
    PortConfigrationEngine();
}

PortConfigrationEngine() port;

extern TrafficManager {
    TrafficManager();
}

TrafficManager() tm;

extern PacketGenerationEngine {
    PacketGenerationEngine();
}

PacketGenerationEngine() pktgen;
# 25 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 2

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
# 21 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 2
# 3 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4" 2

# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 1
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/headers.p4" 1



typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<16> ether_type_t;
const ether_type_t ETHERTYPE_IPV4 = 16w0x0800;
const ether_type_t ETHERTYPE_ARP = 16w0x0806;
const ether_type_t ETHERTYPE_VLAN = 16w0x8100;
const ether_type_t ETHERTYPE_BF_FABRIC = 16w0x9000;


typedef bit<8> ip_protocol_t;
const ip_protocol_t IP_PROTOCOLS_ICMP = 8w1;
const ip_protocol_t IP_PROTOCOLS_TCP = 8w6;
const ip_protocol_t IP_PROTOCOLS_UDP = 8w17;
const ip_protocol_t IP_PROTOCOLS_GRE = 8w47;
const ip_protocol_t IP_PROTOCOLS_IPIP = 8w4;

/* definition headers length */
const bit<16> IP_LEN = 16w20;
const bit<16> GRE_LEN = 16w4;
const bit<16> GRE_KEY_OPT_KEN = 16w4;
const bit<16> GRE_CSUM_OPT_LEN = 16w4;

/* outter ip + gre + gre_key */
const bit<16> IP_GRE_OPT_KEY_LEN = 16w28;

/* outter ip + gre + gre_key + gre_csum */
const bit<16> IP_GRE_OPT_KEY_CSUM_LEN = 16w32;

/* outter ip + gre + gre_key + gre_csum + gre_seq */
const bit<16> IP_GRE_OPT_KEY_CSUM_SEQ_LEN = 16w36;

/* Ingress mirroring information */





//#define ETH1_CPU_PORT 66
//#define ETH2_CPU_PORT 67



//#define PCIE_CPU_PORT 192
# 61 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/headers.p4"
/* IP MTU. */


/*
* 1500 - 36(gre:4 + opt_ket:4 + opt_csum:4 + opt_seq:4 + out_ip:20) = 1464
*/



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

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<1> flag_rs;
    bit<1> flag_df;
    bit<1> flag_mf;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header option_word_h {
    bit<32> data;
}

header tcp_h {
    //bit<16> src_port;
    //bit<16> dst_port;
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
    //bit<16> src_port;
    //bit<16> dst_port;
    bit<16> hdr_length;
    bit<16> checksum;
}

header l4_port_h {
    bit<16> src_port;
    bit<16> dst_port;
}

header tcp_option_1_h {
     bit<8> data;
}

header tcp_option_2_h {
    bit<16> data;
}

header tcp_option_4_h {
    bit<32> value;
}

header tcp_option_mss_h {
    bit<8> kind;
    bit<8> length;
    bit<16> mss;
}

header icmp_h {
    bit<8> msg_type;
    bit<8> msg_code;
    bit<16> checksum;
}

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header arp_ipv4_h {
    mac_addr_t src_hw_addr;
    ipv4_addr_t src_proto_addr;
    mac_addr_t dst_hw_addr;
    ipv4_addr_t dst_proto_addr;
}

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

header gre_opt_key_h {
    bit<32> key;
}

header gre_opt_csum_h {
    bit<32> csum;
}

header gre_opt_seq_h {
    bit<32> seq;
}

header fabric_header_h {
    bit<3> packetType;
    bit<2> headerVersion;
    bit<2> packetVersion;
    bit<1> pad1;

    bit<3> fabricColor;
    bit<5> fabricQos;

    bit<8> dstDevice;
    bit<16> dstPortOrGroup;
}

header fabric_header_cpu_h {
    bit<5> egressQueue;
    bit<1> txBypass;
    bit<2> reserved;

    bit<16> ingressPort;
    bit<16> ingressIfindex;
    bit<16> ingressBd;

    bit<16> reasonCode;
}

header fabric_payload_header_h {
    bit<16> etherType;
}






header inthdr_h {
    bit<8> header_type;
}

/*
 *Bridged metadata: 28 byte free, after that minimum packet size will be impacted.
*/
header to_vnet_bridge_a_meta_h {
    bit<8> header_type;
//    bit<7>      pad0; PortId_t  ingress_port;
    bit<32> local_bip;

    bit<16> iph_id;
    bit<16> vport;

    /* in nsec */
    bit<16> ingress_mac_tstamp;
}

// 31byte totally
header recirculate_header_h {
    bit<8> header_type;
//    bit<7>      pad0; PortId_t    ingress_port;
    bit<32> local_bip;

    bit<16> iph_id;

    bit<32> ct_snatip;
    bit<32> ct_rsip;
    bit<16> ct_rsport;
    bit<32> ct_vpcid;
    bit<32> ct_remote_ip;
    bit<32> ct_gw_ip;

    bit<16> ingress_mac_tstamp;
}

typedef recirculate_header_h to_vnet_bridge_b_meta_h;

typedef inthdr_h ing_port_mirror_h;

header to_rnet_bridge_meta_h {
    bit<8> header_type;
    bit<16> ingress_mac_tstamp;
    bit<16> iph_id;
}

header to_rnet_bridge_rsinfo_h {
    bit<32> ct_snatip;
    bit<32> ct_rsip;
    bit<16> ct_rsport;
}

/*
* no use in stage and will be storaged in TPHV.
* used to prevent compile optimization only.
*/
header payload_frag_h {
    bit<16> data;
}
# 2 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/dump_header.p4" 1
# 22 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/dump_header.p4"
header dump_h {

    bit<32> magic;
/*
    bit<1> ingress;
    bit<1> egress;
    bit<1> from_cpu;
    bit<1> to_cpu;
    bit<1> arp_handler;
    bit<1> icmp_handler;
    bit<1> drop_by_rule;
    bit<1> check_error;
    bit<1> decap_error;
    bit<1> ingress_ip_rnet;
    bit<1> ingress_ip_vpc;
    bit<1> route_not_find;
    bit<19> reserved;
*/
    bit<32> flags;
}

header dump_bridge_meta_h {
    bit<8> header_type;
    bit<32> dump_flag;
}

typedef dump_bridge_meta_h dump_mirror_h;
# 3 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/drop_info_header.p4" 1
# 17 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/drop_info_header.p4"
header drop_info_h {
    bit<32> magic;
    bit<32> flags;
}

header drop_info_bridge_meta_h {
    bit<8> header_type;
    bit<32> flags;
}

typedef drop_info_bridge_meta_h drop_mirror_h;
# 4 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/types.p4" 1



/* vpcid of physical network (-1) */
# 19 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/types.p4"
typedef bit<64> switch_uint64_t;
typedef bit<48> switch_uint48_t;
typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef int<32> switch_int32_t;

typedef bit<8> header_type_t;
typedef bit<8> header_info_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

/*****************sys info*************************/

struct local_jnsgw_info_t {
    switch_uint32_t vip;
    switch_uint32_t agent_vip;
}

struct physical_port_t {
    switch_port_t port_id;
    ipv4_addr_t ip;
    ipv4_addr_t gw_ip;
    mac_addr_t mac;
    mac_addr_t gw_mac;
}

/*****************vpc info**************************/
struct underlay_flow_entry_t {
    switch_uint32_t snatip;
    switch_uint32_t rsip;
    switch_uint16_t rsport;
    switch_uint32_t vpcid;
    switch_uint32_t remote_ip;
    switch_uint32_t gwip;
}

struct overlay_flow_entry_t {
    switch_uint32_t vip;
    switch_uint32_t cip;
    switch_uint16_t vport;
}

struct jnsgw_header_t {
    to_vnet_bridge_a_meta_h to_vnet_bridge_a;
    to_vnet_bridge_b_meta_h to_vnet_bridge_b;
    to_rnet_bridge_meta_h to_rnet_bridge;
    to_rnet_bridge_rsinfo_h to_rnet_bridge_rsinfo;


    recirculate_header_h recir_header;

    ethernet_h ethernet;
    fabric_header_h fabric_header;
    fabric_header_cpu_h fabric_header_cpu;
    fabric_payload_header_h fabric_payload_header;

    udp_h udp;
    tcp_h tcp;
    l4_port_h l4_port;

    tcp_option_4_h[10] tcp_options_4_before;
    tcp_option_2_h tcp_options_2_before;
    tcp_option_1_h tcp_options_1_before;
    tcp_option_mss_h tcp_options_mss;

    option_word_h inner_ip_opt_word_1;
    option_word_h inner_ip_opt_word_2;
    option_word_h inner_ip_opt_word_3;
    option_word_h inner_ip_opt_word_4;
    option_word_h inner_ip_opt_word_5;
    option_word_h inner_ip_opt_word_6;
    option_word_h inner_ip_opt_word_7;
    option_word_h inner_ip_opt_word_8;
    option_word_h inner_ip_opt_word_9;
    option_word_h inner_ip_opt_word_10;
    ipv4_h inner_ipv4;

    gre_h gre;
    gre_opt_key_h gre_opt_key;
    gre_opt_csum_h gre_opt_csum;
    gre_opt_seq_h gre_opt_seq;

    option_word_h ip_opt_word_1;
    option_word_h ip_opt_word_2;
    option_word_h ip_opt_word_3;
    option_word_h ip_opt_word_4;
    option_word_h ip_opt_word_5;
    option_word_h ip_opt_word_6;
    option_word_h ip_opt_word_7;
    option_word_h ip_opt_word_8;
    option_word_h ip_opt_word_9;
    option_word_h ip_opt_word_10;
    ipv4_h ipv4;

    icmp_h icmp;
    arp_h arp;
    arp_ipv4_h arp_ipv4;

    ipv4_h new_out_ipv4;
    gre_h new_gre;
    gre_opt_key_h new_gre_opt_key;
    gre_opt_csum_h new_gre_opt_csum;
    gre_opt_seq_h new_gre_opt_seq;

    dump_h dump;

    payload_frag_h payload_frag;
}

struct jnsgw_ingress_metadata_t {
    recirculate_header_h recir_header;

    bit<8> multi_or_broad_flag;
    bit<1> ipv4_checksum_err;

    switch_uint8_t ipv4_ttl;

    switch_uint32_t vpcid;
    ipv4_addr_t local_bip;

    local_jnsgw_info_t local_jnsgw_info;
    physical_port_t tx_phy_port;
    switch_uint16_t iph_id;

    header_type_t mirror_header_type;
    switch_uint16_t mirror_session_id;
    switch_uint32_t dump_flag;
    bool dump_count_check;
    switch_uint8_t dip_type;
    PortId_t tem_portid;
    switch_uint16_t tcp_checksum;
    bool tcp_checksum_odd;
}

struct jnsgw_egress_metadata_t {

    /* get from ingress  */
    ing_port_mirror_h ing_port_mirror;
    to_vnet_bridge_a_meta_h to_vnet_bridge_a;
    to_vnet_bridge_b_meta_h to_vnet_bridge_b;
    to_rnet_bridge_meta_h to_rnet_bridge;

    dump_bridge_meta_h dump_bridge;

    local_jnsgw_info_t local_jnsgw_info;
    ipv4_addr_t local_bip;
    switch_uint16_t iph_id;
    physical_port_t tx_phy_port;

    /* get from egress parser or egress */
    underlay_flow_entry_t underlay_flow_entry;
    overlay_flow_entry_t overlay_flow_entry;

    header_type_t mirror_header_type;
    switch_uint16_t mirror_session_id;
    switch_uint32_t dump_flag;
    bool dump_count_check;

    switch_uint16_t ingress_mac_tstamp;
    switch_uint16_t tcp_udp_checksum;
    switch_uint32_t pseudo_ipv4_src_addr;
    switch_uint32_t pseudo_ipv4_dst_addr;
}
# 5 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/const.p4" 1



/* table size definition  */
const switch_uint32_t VPC_TABLE_SIZE = 10240;


const switch_uint32_t UNDERLAY_FLOWS_PRE0_TABLE_SIZE = 500000;//136000;
const switch_uint32_t UNDERLAY_FLOWS_PRE_TABLE_SIZE = 20000;
const switch_uint32_t UNDERLAY_FLOWS_TABLE_SIZE = 98304;

const switch_uint32_t OVERLAY_FLOWS_PRE0_TABLE_SIZE = 125000;
const switch_uint32_t OVERLAY_FLOWS_PRE_TABLE_SIZE = 520000;
const switch_uint32_t OVERLAY_FLOWS_TABLE_SIZE = 100000;

const switch_uint32_t PHY_PORT_TABLE_SIZE = 32;
const switch_uint8_t PHY_PORT_MAX = 32;

const switch_uint32_t ARP_REPLY_ROUTE_TABLE_SIZE = 1024;
const switch_uint32_t ICMP_REPLY_ROUTE_TABLE_SIZE = 1024;

const switch_uint32_t BIP_MAX_PER_jnsgw = 1024;

const switch_uint32_t DROP_IP_RULES_TABLE_SIZE = 1024;

const switch_uint32_t DELAY_STATS_TABLE_SIZE = 32;

const switch_uint32_t DIP_TYPE_TABLE_SIZE = 1024;
/* header type */


/* ingress_a to egress_a to rnet  */
const header_type_t HEADER_TYPE_TO_RNET_BRIDGE = 0x1;
/* ingress_a to egress_b to vent not do fragment. */
const header_type_t HEADER_TYPE_TO_VNET_BRIDGE1 = 0x2;
/* ingress_a to egress_b to vnet do fragment for second pkt */
const header_type_t HEADER_TYPE_TO_VNET_BRIDGE2 = 0x3;
/* ingress_a to egress_b to vnwt do fragment for first pkt  */
const header_type_t HEADER_TYPE_MIRROR_INGRESS = 0x4;
/* egress mirror to ingress */
const header_type_t HEADER_TYPE_MIRROR_EGRESS = 0x5;
const header_type_t HEADER_TYPE_RESUBMIT = 0x6;
/* egress_b to ingress_b */
const header_type_t HEADER_TYPE_RECIRCULATE = 0x7;
/* dump */
const header_type_t HEADER_TYPE_DUMP = 0x8;
/* drop info */
const header_type_t HEADER_TYPE_DROP_INFO = 0x9;

const MirrorId_t MIRROR_DUMP_ID1 = 1000;
const MirrorId_t MIRROR_DUMP_ID2 = 1001;


/* DIP_TYPE  */
const switch_uint8_t PAL_DIP_TYPE_UNDEFINED = 0;
const switch_uint8_t PAL_DIP_TYPE_TUNNEL = 1;
const switch_uint8_t PAL_DIP_TYPE_MAX = 2;
# 6 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/util.p4" 1



parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md,
        out jnsgw_ingress_metadata_t ig_md) {
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
        ig_md.tx_phy_port.ip = pkt.lookahead<bit<32>>();
        pkt.advance(32);




        pkt.advance(32);

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

// Empty egress parser/control blocks
parser EmptyEgressParser<H, M>(
        packet_in pkt,
        out H hdr,
        out M eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        transition accept;
    }
}

control EmptyEgressDeparser<H, M>(
        packet_out pkt,
        inout H hdr,
        in M eg_md,
        in egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md) {
    apply {}
}

control EmptyEgress<H, M>(
        inout H hdr,
        inout M eg_md,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {}
}
# 7 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_a.p4" 2

parser IngressParser_a(packet_in pkt,
    out jnsgw_header_t hdr,
    out jnsgw_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md){
    TofinoIngressParser() tofino_parser;
    Checksum() ipv4_checksum;

    state start {
        tofino_parser.apply(pkt, ig_intr_md, ig_md);
        transition meta_init;
    }

    state meta_init {
        ig_md.multi_or_broad_flag = 0;
        ig_md.ipv4_checksum_err = 0;

        ig_md.vpcid = 0;
        ig_md.local_jnsgw_info = {0,0};
        ig_md.iph_id = 0;
        ig_md.mirror_header_type = 0;
        ig_md.dip_type = 0;

        transition parse_ethernet;
    }

    state parse_ethernet {
        ig_md.multi_or_broad_flag = pkt.lookahead<bit<8>>();
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            ETHERTYPE_BF_FABRIC : parse_fabric_header;
            default : accept;
        }
    }

    state parse_fabric_header {
        pkt.extract(hdr.fabric_header);
        transition parse_fabric_header_cpu;
    }

    state parse_fabric_header_cpu {
        pkt.extract(hdr.fabric_header_cpu);
        transition parse_fabric_payload_header;
    }

    state parse_fabric_payload_header {
        pkt.extract(hdr.fabric_payload_header);
        hdr.ethernet.ether_type = hdr.fabric_payload_header.etherType;
        transition select(hdr.fabric_payload_header.etherType) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            default : accept;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition select(hdr.arp.hw_type, hdr.arp.proto_type) {
            (0x0001, ETHERTYPE_IPV4) : parse_arp_ipv4;
            default: reject;
        }
    }

    state parse_arp_ipv4 {
        pkt.extract(hdr.arp_ipv4);
        transition accept;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        ipv4_checksum.add(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        ipv4_checksum.add(hdr.ip_opt_word_1);
        ipv4_checksum.add(hdr.ip_opt_word_2);
        ipv4_checksum.add(hdr.ip_opt_word_3);
        ipv4_checksum.add(hdr.ip_opt_word_4);
        ipv4_checksum.add(hdr.ip_opt_word_5);
        ipv4_checksum.add(hdr.ip_opt_word_6);
        ipv4_checksum.add(hdr.ip_opt_word_7);
        ipv4_checksum.add(hdr.ip_opt_word_8);
        ipv4_checksum.add(hdr.ip_opt_word_9);
        ipv4_checksum.add(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        ig_md.ipv4_checksum_err = (bit<1>)ipv4_checksum.verify();
        transition select(hdr.ipv4.protocol) {
            (IP_PROTOCOLS_ICMP ) : parse_icmp;
            (IP_PROTOCOLS_GRE ) : parse_gre;
            (IP_PROTOCOLS_TCP ) : parse_tcp;
            (IP_PROTOCOLS_UDP ) : parse_udp;
            default : accept;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept;
    }

    state parse_gre {
        pkt.extract(hdr.gre);
        transition select(hdr.gre.C, hdr.gre.K, hdr.gre.S, hdr.gre.proto) {
            (1, _, _, ETHERTYPE_IPV4) : parse_gre_opt_c;
            (0, 1, _, ETHERTYPE_IPV4) : parse_gre_opt_k;
            (0, 0, 1, ETHERTYPE_IPV4) : parse_gre_opt_s;
            (0, 0, 0, ETHERTYPE_IPV4) : parse_inner_ipv4;
            default: reject;
        }
    }

    state parse_gre_opt_c {
        pkt.extract(hdr.gre_opt_csum);
        transition select(hdr.gre.K, hdr.gre.S) {
            (1, _) : parse_gre_opt_k;
            (0, 1) : parse_gre_opt_s;
            default: parse_inner_ipv4;
        }
    }

    state parse_gre_opt_k {
        pkt.extract(hdr.gre_opt_key);
        transition select(hdr.gre.S) {
            1 : parse_gre_opt_s;
            default: parse_inner_ipv4;
        }
    }

    state parse_gre_opt_s {
        pkt.extract(hdr.gre_opt_seq);
        transition parse_inner_ipv4;
    }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner_ipv4);
        transition select(hdr.inner_ipv4.ihl) {
             5 : parse_inner_ipv4_no_options;
             6 : parse_inner_ipv4_options_1;
             7 : parse_inner_ipv4_options_2;
             8 : parse_inner_ipv4_options_3;
             9 : parse_inner_ipv4_options_4;
            10 : parse_inner_ipv4_options_5;
            11 : parse_inner_ipv4_options_6;
            12 : parse_inner_ipv4_options_7;
            13 : parse_inner_ipv4_options_8;
            14 : parse_inner_ipv4_options_9;
            15 : parse_inner_ipv4_options_10;
            default: reject;
        }
    }

    state parse_inner_ipv4_options_1 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_2 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_3 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_4 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_5 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_6 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_7 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_8 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_9 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        pkt.extract(hdr.inner_ip_opt_word_9);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_options_10 {
        pkt.extract(hdr.inner_ip_opt_word_1);
        pkt.extract(hdr.inner_ip_opt_word_2);
        pkt.extract(hdr.inner_ip_opt_word_3);
        pkt.extract(hdr.inner_ip_opt_word_4);
        pkt.extract(hdr.inner_ip_opt_word_5);
        pkt.extract(hdr.inner_ip_opt_word_6);
        pkt.extract(hdr.inner_ip_opt_word_7);
        pkt.extract(hdr.inner_ip_opt_word_8);
        pkt.extract(hdr.inner_ip_opt_word_9);
        pkt.extract(hdr.inner_ip_opt_word_10);
        transition parse_inner_ipv4_no_options;
    }

    state parse_inner_ipv4_no_options {
        transition select(hdr.inner_ipv4.frag_offset, hdr.inner_ipv4.protocol) {
            (0, IP_PROTOCOLS_TCP ) : parse_tcp;
            (0, IP_PROTOCOLS_UDP ) : parse_udp;
            default : accept;
        }
    }

    state parse_tcp {
        //ig_md.l4_port = pkt.lookahead<l4_port_h>();
        pkt.extract(hdr.l4_port);
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        //ig_md.l4_port = pkt.lookahead<l4_port_h>();
        pkt.extract(hdr.l4_port);
        pkt.extract(hdr.udp);
        transition accept;
    }
}

control IngressDeparser_a(
        packet_out pkt,
        inout jnsgw_header_t hdr,
        in jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    Mirror() ing_port_mirror;

    apply {

        if (ig_dprsr_md.mirror_type == 2) {
            ing_port_mirror.emit<dump_mirror_h>(
                (MirrorId_t)ig_md.mirror_session_id,
                {ig_md.mirror_header_type,
                ig_md.dump_flag
                });
        }

        pkt.emit(hdr.to_vnet_bridge_a);
        pkt.emit(hdr.to_rnet_bridge);
        pkt.emit(hdr.to_rnet_bridge_rsinfo);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.fabric_header);
        pkt.emit(hdr.fabric_header_cpu);
        pkt.emit(hdr.fabric_payload_header);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);
        pkt.emit(hdr.gre);
        pkt.emit(hdr.gre_opt_csum);
        pkt.emit(hdr.gre_opt_key);
        pkt.emit(hdr.gre_opt_seq);
        pkt.emit(hdr.inner_ipv4);
        pkt.emit(hdr.inner_ip_opt_word_1);
        pkt.emit(hdr.inner_ip_opt_word_2);
        pkt.emit(hdr.inner_ip_opt_word_3);
        pkt.emit(hdr.inner_ip_opt_word_4);
        pkt.emit(hdr.inner_ip_opt_word_5);
        pkt.emit(hdr.inner_ip_opt_word_6);
        pkt.emit(hdr.inner_ip_opt_word_7);
        pkt.emit(hdr.inner_ip_opt_word_8);
        pkt.emit(hdr.inner_ip_opt_word_9);
        pkt.emit(hdr.inner_ip_opt_word_10);

        pkt.emit(hdr.l4_port);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);

        pkt.emit(hdr.icmp);
        pkt.emit(hdr.arp);
        pkt.emit(hdr.arp_ipv4);
    }
}

parser EgressParser_a(packet_in pkt,
    out jnsgw_header_t hdr,
    out jnsgw_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md){

    TofinoEgressParser() tofino_parser;
    inthdr_h inthdr;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition meta_init;
    }

    state meta_init {
        eg_md.local_jnsgw_info = {0,0};

        eg_md.local_bip = 0;
        eg_md.iph_id = 0;
        eg_md.tx_phy_port = {0,0,0,0,0};
        eg_md.mirror_header_type = 0;
        eg_md.ing_port_mirror.header_type = 0;
        eg_md.ingress_mac_tstamp = 0;
        eg_md.tcp_udp_checksum = 0;
        eg_md.pseudo_ipv4_src_addr = 0;
        eg_md.pseudo_ipv4_dst_addr = 0;

        transition parse_pre;
    }

    state parse_pre {
        inthdr = pkt.lookahead<inthdr_h>();
        transition select(inthdr.header_type) {
            ( HEADER_TYPE_TO_RNET_BRIDGE ) : parse_to_rnet_bridge;
            ( HEADER_TYPE_TO_VNET_BRIDGE2 ) : parse_to_vnet_bridge;
            ( HEADER_TYPE_TO_VNET_BRIDGE1 ) : parse_to_vnet_bridge;
            ( HEADER_TYPE_MIRROR_INGRESS ) : parse_to_mirror_bridge;
            default : reject;
        }
    }

    state parse_to_mirror_bridge {
        pkt.extract(eg_md.ing_port_mirror);
        transition parse_to_vnet_bridge;
    }

    state parse_to_rnet_bridge {
        pkt.extract(eg_md.to_rnet_bridge);
        eg_md.to_vnet_bridge_b.ct_snatip = pkt.lookahead<bit<32>>();
        pkt.advance(32);
        eg_md.to_vnet_bridge_b.ct_rsip = pkt.lookahead<bit<32>>();
        pkt.advance(32);
        eg_md.to_vnet_bridge_b.ct_rsport = pkt.lookahead<bit<16>>();
        pkt.advance(16);

        eg_md.ingress_mac_tstamp = eg_md.to_rnet_bridge.ingress_mac_tstamp;
        transition parse_ethernet;
    }

    state parse_to_vnet_bridge {
        pkt.extract(eg_md.to_vnet_bridge_b);
        eg_md.ingress_mac_tstamp = eg_md.to_vnet_bridge_b.ingress_mac_tstamp;
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        tcp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        udp_checksum.subtract({hdr.ipv4.src_addr,hdr.ipv4.dst_addr});
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        /* shrinking the live range of select fields, the size of match key register is 32bit only. */
        transition select(inthdr.header_type) {
            (HEADER_TYPE_TO_RNET_BRIDGE ) : parse_l4_header;
            (HEADER_TYPE_TO_VNET_BRIDGE1 ) : parse_l4_header;
            (HEADER_TYPE_MIRROR_INGRESS ) : parse_l4_header;
            (HEADER_TYPE_TO_VNET_BRIDGE2 ) : parse_do_fragment;
            default : reject;
        }

    }

    state parse_l4_header {
        pkt.extract(hdr.l4_port);
        tcp_checksum.subtract({hdr.l4_port.src_port, hdr.l4_port.dst_port});
        udp_checksum.subtract({hdr.l4_port.src_port, hdr.l4_port.dst_port});
        transition select(hdr.ipv4.protocol) {
            (IP_PROTOCOLS_TCP ) : parse_tcp;
            (IP_PROTOCOLS_UDP ) : parse_udp;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        tcp_checksum.subtract({hdr.tcp.checksum});
        eg_md.tcp_udp_checksum = tcp_checksum.get();

        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        udp_checksum.subtract({hdr.udp.checksum});
        eg_md.tcp_udp_checksum = udp_checksum.get();

        transition accept;
    }

    state parse_do_fragment {
        hdr.l4_port = pkt.lookahead<l4_port_h>();
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);//320byte
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(256);
        pkt.advance(192);//440byte

        pkt.extract(hdr.payload_frag);
        transition accept;
    }

}

control EgressDeparser_a(
        packet_out pkt,
        inout jnsgw_header_t hdr,
        in jnsgw_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    Checksum() new_out_ipv4_checksum;
    Checksum() ipv4_checksum;
    Checksum() tcp_checksum;
    Checksum() udp_checksum;
    Mirror() egr_port_mirror;

    apply {

        if(hdr.new_out_ipv4.isValid()){
            hdr.new_out_ipv4.hdr_checksum = new_out_ipv4_checksum.update({
                hdr.new_out_ipv4.version,
                hdr.new_out_ipv4.ihl,
                hdr.new_out_ipv4.diffserv,
                hdr.new_out_ipv4.total_len,
                hdr.new_out_ipv4.identification,
                hdr.new_out_ipv4.flag_rs,
                hdr.new_out_ipv4.flag_df,
                hdr.new_out_ipv4.flag_mf,
                hdr.new_out_ipv4.frag_offset,
                hdr.new_out_ipv4.ttl,
                hdr.new_out_ipv4.protocol,
                hdr.new_out_ipv4.src_addr,
                hdr.new_out_ipv4.dst_addr
                });
        }

        if(hdr.ipv4.isValid()){
            hdr.ipv4.hdr_checksum = ipv4_checksum.update({
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flag_rs,
                hdr.ipv4.flag_df,
                hdr.ipv4.flag_mf,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr,
                hdr.ip_opt_word_1,
                hdr.ip_opt_word_2,
                hdr.ip_opt_word_3,
                hdr.ip_opt_word_4,
                hdr.ip_opt_word_5,
                hdr.ip_opt_word_6,
                hdr.ip_opt_word_7,
                hdr.ip_opt_word_8,
                hdr.ip_opt_word_9,
                hdr.ip_opt_word_10
                });
        }

        if (hdr.tcp.isValid()) {
            hdr.tcp.checksum = tcp_checksum.update({
                eg_md.pseudo_ipv4_src_addr,
                eg_md.pseudo_ipv4_dst_addr,
                hdr.l4_port.src_port,
                hdr.l4_port.dst_port,
                eg_md.tcp_udp_checksum
            });
        }

        if (hdr.udp.isValid()) {
            hdr.udp.checksum = udp_checksum.update({
                eg_md.pseudo_ipv4_src_addr,
                eg_md.pseudo_ipv4_dst_addr,
                hdr.l4_port.src_port,
                hdr.l4_port.dst_port,
                eg_md.tcp_udp_checksum
            });
        }

        if (eg_dprsr_md.mirror_type == 3) {
            /* mirror for egress dump */
            egr_port_mirror.emit<dump_mirror_h>(
                (MirrorId_t)eg_md.mirror_session_id,
                {eg_md.mirror_header_type,
                 eg_md.dump_flag
                });
        }

        pkt.emit(hdr.ethernet);

        pkt.emit(hdr.new_out_ipv4);
        pkt.emit(hdr.new_gre);
        pkt.emit(hdr.new_gre_opt_csum);
        pkt.emit(hdr.new_gre_opt_key);
        pkt.emit(hdr.new_gre_opt_seq);

        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);
        pkt.emit(hdr.payload_frag);

        pkt.emit(hdr.l4_port);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.udp);

    }
}
# 5 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/parde_b.p4" 1







parser IngressParser_b(packet_in pkt,
    out jnsgw_header_t hdr,
    out jnsgw_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md){
    TofinoIngressParser() tofino_parser;
    inthdr_h inthdr;
    Checksum() tcp_checksum;
    ParserCounter() pctr;

    state start {
        tofino_parser.apply(pkt, ig_intr_md, ig_md);
        transition meta_init;
    }

    state meta_init {
        transition parse_pre;
    }

    state parse_pre {
        inthdr = pkt.lookahead<inthdr_h>();
        transition select(ig_intr_md.ingress_port, inthdr.header_type) {
            (258, _) : parse_ethernet;
            (257, _) : parse_ethernet;
            (_, HEADER_TYPE_RECIRCULATE) : parse_recir;
            default : reject;
        }
    }

    state parse_recir {
        pkt.extract(ig_md.recir_header);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl) {
             5 : parse_ipv4_no_options;
             6 : parse_ipv4_options_1;
             7 : parse_ipv4_options_2;
             8 : parse_ipv4_options_3;
             9 : parse_ipv4_options_4;
            10 : parse_ipv4_options_5;
            11 : parse_ipv4_options_6;
            12 : parse_ipv4_options_7;
            13 : parse_ipv4_options_8;
            14 : parse_ipv4_options_9;
            15 : parse_ipv4_options_10;
            default: reject;
        }
    }

    state parse_ipv4_options_1 {
        pkt.extract(hdr.ip_opt_word_1);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_2 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_3 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_4 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_5 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_6 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_7 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_8 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_9 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_options_10 {
        pkt.extract(hdr.ip_opt_word_1);
        pkt.extract(hdr.ip_opt_word_2);
        pkt.extract(hdr.ip_opt_word_3);
        pkt.extract(hdr.ip_opt_word_4);
        pkt.extract(hdr.ip_opt_word_5);
        pkt.extract(hdr.ip_opt_word_6);
        pkt.extract(hdr.ip_opt_word_7);
        pkt.extract(hdr.ip_opt_word_8);
        pkt.extract(hdr.ip_opt_word_9);
        pkt.extract(hdr.ip_opt_word_10);
        transition parse_ipv4_no_options;
    }

    state parse_ipv4_no_options {
        transition select(hdr.ipv4.protocol) {
            (IP_PROTOCOLS_TCP ) : parse_tcp;
            default : accept;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.l4_port);
        pkt.extract(hdr.tcp);

        tcp_checksum.subtract({hdr.tcp.checksum});
        ig_md.tcp_checksum = tcp_checksum.get();

        transition select(hdr.tcp.data_offset) {
            5 : accept;
            default : parse_tcp_option;
        }
    }

    state parse_tcp_option {
        transition select(hdr.tcp.flags[1:1]) {
            1 : parse_tcp_syn_option; // syn
            default : accept;
        }
    }

    state parse_tcp_syn_option {
        pctr.set(hdr.tcp.data_offset, 15 << 2, 2, 0x7, -20); // (max, rot, mask, add)
        transition next_option_0b_align;
    }

    // Processing for data starting at byte 0 in 32b word
    @dont_unroll
    state next_option_0b_align {
        transition select(pctr.is_zero()) {
            true : accept; // no TCP Option bytes left
            default : next_option_0b_align_part2;
        }
    }

    @dont_unroll
    state next_option_0b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 4
        transition select(pkt.lookahead<bit<32>>()) {
            0x02000000 &&& 0xff000000 : parse_tcp_option_mss;
            0x00000000 &&& 0xfefefefe : parse_tcp_option_4b_before;
            0x00000000 &&& 0xfefefe00 : next_option_3b_align;
            0x00000000 &&& 0xfefe0000 : next_option_2b_align;
            0x00000000 &&& 0xfe000000 : next_option_1b_align;
            0x00020000 &&& 0x00ff0000 : next_option_2b_align;
            0x00030000 &&& 0x00ff0000 : next_option_3b_align;
            0x00040000 &&& 0x00ff0000 : parse_tcp_option_4b_before;
            0x00060000 &&& 0x00ff0000 : parse_tcp_option_4b_before_2b;
            0x00080000 &&& 0x00ff0000 : parse_tcp_option_8b_before;
            0x000a0000 &&& 0x00ff0000 : parse_tcp_option_8b_before_2b;
            default : accept;
        }
    }

    // Processing for data starting at byte 1 in 32b word
    @dont_unroll
    state next_option_1b_align {
        transition select(pctr.is_zero()) {
            true : accept; // no TCP Option bytes left
            default : next_option_1b_align_part2;
        }
    }

    @dont_unroll
    state next_option_1b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 3
        transition select(pkt.lookahead<bit<32>>()[23:0]) {
            0x020000 &&& 0xff0000 : parse_tcp_option_1b_before_mss;
            0x000000 &&& 0xfefefe : parse_tcp_option_4b_before;
            0x000000 &&& 0xfefe00 : next_option_3b_align;
            0x000000 &&& 0xfe0000 : next_option_2b_align;
            0x000200 &&& 0x00ff00 : next_option_3b_align;
            0x000300 &&& 0x00ff00 : parse_tcp_option_4b_before;
            0x000400 &&& 0x00ff00 : parse_tcp_option_4b_before_1b;
            0x000600 &&& 0x00ff00 : parse_tcp_option_4b_before_3b;
            0x000800 &&& 0x00ff00 : parse_tcp_option_8b_before_1b;
            0x000a00 &&& 0x00ff00 : parse_tcp_option_8b_before_3b;
        }
    }

    // Processing for data starting at byte 2 in 32b word
    @dont_unroll
    state next_option_2b_align {
        transition select(pctr.is_zero()) {
            true : accept; // no TCP Option bytes left
            default : next_option_2b_align_part2;
        }
    }

    state next_option_2b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 2
        transition select(pkt.lookahead<bit<32>>()[15:0]) {
            0x0200 &&& 0xff00 : parse_tcp_option_2b_before_mss;
            0x0000 &&& 0xfefe : parse_tcp_option_4b_before;
            0x0000 &&& 0xfe00 : next_option_3b_align;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_2b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before;
        }
    }

    // Processing for data starting at byte 3 in 32b word
    @dont_unroll
    state next_option_3b_align {
        transition select(pctr.is_zero()) {
            true : accept; // no TCP Option bytes left
            default : next_option_3b_align_part2;
        }
    }

    @dont_unroll
    state next_option_3b_align_part2 {
        // precondition: tcp_hdr_bytes_left >= 2
        transition select(pkt.lookahead<bit<40>>()[15:0]) {
            0x0200 &&& 0xff00 : parse_tcp_option_3b_before_mss;
            0x0000 &&& 0xfe00 : parse_tcp_option_4b_before;
            0x0002 &&& 0x00ff : parse_tcp_option_4b_before_1b;
            0x0003 &&& 0x00ff : parse_tcp_option_4b_before_2b;
            0x0004 &&& 0x00ff : parse_tcp_option_4b_before_3b;
            0x0006 &&& 0x00ff : parse_tcp_option_8b_before_1b;
            0x0008 &&& 0x00ff : parse_tcp_option_8b_before_3b;
            0x000a &&& 0x00ff : parse_tcp_option_12b_before_1b;
            default : parse_tcp_option_3b_before_mss;
        }
    }

    @dont_unroll
    state parse_tcp_option_mss {
        pkt.extract(hdr.tcp_options_mss);
        transition accept;
    }

    @dont_unroll
    state parse_tcp_option_1b_before_mss {
        pkt.extract(hdr.tcp_options_1_before);
        pctr.decrement(1);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_2b_before_mss {
        pkt.extract(hdr.tcp_options_2_before);
        pctr.decrement(2);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_3b_before_mss {
        pkt.extract(hdr.tcp_options_2_before);
        pkt.extract(hdr.tcp_options_1_before);
        pctr.decrement(3);
        transition parse_tcp_option_mss;
    }

    @dont_unroll
    state parse_tcp_option_4b_before {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_1b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_2b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_4b_before_3b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(4);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_1b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_1b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_2b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_2b_align;
    }

    @dont_unroll
    state parse_tcp_option_8b_before_3b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(8);
        transition next_option_3b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(12);
        transition next_option_0b_align;
    }

    @dont_unroll
    state parse_tcp_option_12b_before_1b {
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pkt.extract(hdr.tcp_options_4_before.next);
        pctr.decrement(12);
        transition next_option_1b_align;
    }
}


control IngressDeparser_b(
        packet_out pkt,
        inout jnsgw_header_t hdr,
        in jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    Mirror() ing_port_mirror;
    Checksum() tcp_checksum;

    apply {

        if (ig_dprsr_md.mirror_type == 1) {
            /* mirror to egress for 1th fragment */
            ing_port_mirror.emit<ing_port_mirror_h>(
                (MirrorId_t)ig_md.mirror_session_id,
                {ig_md.mirror_header_type});
        }

        if (ig_md.tcp_checksum_odd) {
            hdr.tcp.checksum = tcp_checksum.update({
                hdr.tcp_options_4_before[0],
                hdr.tcp_options_4_before[1],
                hdr.tcp_options_4_before[2],
                hdr.tcp_options_4_before[3],
                hdr.tcp_options_4_before[4],
                hdr.tcp_options_4_before[5],
                hdr.tcp_options_4_before[6],
                hdr.tcp_options_4_before[7],
                hdr.tcp_options_4_before[8],
                hdr.tcp_options_4_before[9],
                hdr.tcp_options_2_before,
                hdr.tcp_options_1_before,
                hdr.tcp_options_mss,
                8w0,
                ig_md.tcp_checksum
            });
        } else {
            hdr.tcp.checksum = tcp_checksum.update({
                hdr.tcp_options_4_before[0],
                hdr.tcp_options_4_before[1],
                hdr.tcp_options_4_before[2],
                hdr.tcp_options_4_before[3],
                hdr.tcp_options_4_before[4],
                hdr.tcp_options_4_before[5],
                hdr.tcp_options_4_before[6],
                hdr.tcp_options_4_before[7],
                hdr.tcp_options_4_before[8],
                hdr.tcp_options_4_before[9],
                hdr.tcp_options_2_before,
                //hdr.tcp_options_1_before,
                hdr.tcp_options_mss,
                ig_md.tcp_checksum
            });
        }

        pkt.emit(hdr.to_vnet_bridge_b);
        pkt.emit(hdr.ethernet);
        pkt.emit(hdr.ipv4);
        pkt.emit(hdr.ip_opt_word_1);
        pkt.emit(hdr.ip_opt_word_2);
        pkt.emit(hdr.ip_opt_word_3);
        pkt.emit(hdr.ip_opt_word_4);
        pkt.emit(hdr.ip_opt_word_5);
        pkt.emit(hdr.ip_opt_word_6);
        pkt.emit(hdr.ip_opt_word_7);
        pkt.emit(hdr.ip_opt_word_8);
        pkt.emit(hdr.ip_opt_word_9);
        pkt.emit(hdr.ip_opt_word_10);

        pkt.emit(hdr.l4_port);
        pkt.emit(hdr.tcp);
        pkt.emit(hdr.tcp_options_4_before);
        pkt.emit(hdr.tcp_options_2_before);
        pkt.emit(hdr.tcp_options_1_before);
        pkt.emit(hdr.tcp_options_mss);

    }
}

parser EgressParser_b(packet_in pkt,
    out jnsgw_header_t hdr,
    out jnsgw_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md){
    TofinoEgressParser() tofino_parser;
    inthdr_h inthdr;

    state start {
        tofino_parser.apply(pkt, eg_intr_md);
        transition meta_init;
    }

    state meta_init {
        eg_md.local_jnsgw_info = {0,0};

        eg_md.local_bip = 0;
        eg_md.iph_id = 0;
        eg_md.underlay_flow_entry = {0,0,0,0,0,0};
        eg_md.tx_phy_port = {0,0,0,0,0};

        transition parse_pre;
    }

    state parse_pre {
        inthdr = pkt.lookahead<inthdr_h>();
        transition select(inthdr.header_type) {
            ( HEADER_TYPE_TO_VNET_BRIDGE1 ) : parse_bridge;
            ( HEADER_TYPE_DUMP ) : parse_dump_bridge;
            default : reject;
        }
    }

    state parse_bridge {
        pkt.extract(eg_md.to_vnet_bridge_a);
        transition parse_ethernet;
    }

    state parse_dump_bridge {
        pkt.extract(eg_md.dump_bridge);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

control EgressDeparser_b(
        packet_out pkt,
        inout jnsgw_header_t hdr,
        in jnsgw_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {

    apply {

        pkt.emit(hdr.recir_header);

        pkt.emit(hdr.ethernet);
        /* add dump flags after ether header. */
        pkt.emit(hdr.dump);
        pkt.emit(hdr.ipv4);
    }
}
# 6 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4" 2

# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 1
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 2 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 1
/*
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
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


# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 1
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
# 21 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 2
# 3 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2




# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/sys_config.p4" 1



# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/dump.p4" 1



control DumpHandler(in jnsgw_header_t hdr,
  inout jnsgw_ingress_metadata_t ig_md,
  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)
{
    Register<switch_int32_t, bit<32>>(1) count_reg;
    RegisterAction<switch_int32_t, bit<32>, bit<3>>(count_reg) count_reg_action = {
        void apply(inout switch_int32_t value, out bit<3> mirror_type){
            if (value > 0){
                mirror_type = 2;
                value = value - 1;
            } else {
                mirror_type = 0;
            }

        }
    };

    action hit() {
        ig_md.dump_flag = (32w0x80000000);
        ig_md.mirror_header_type = HEADER_TYPE_DUMP;
        ig_md.mirror_session_id = (switch_uint16_t)MIRROR_DUMP_ID1;
        ig_dprsr_md.mirror_type = count_reg_action.execute(0);
    }

    table dump_to_cpu {
        key = {
            hdr.gre_opt_key.isValid() : ternary;
            hdr.gre_opt_key.key : ternary;
            hdr.ipv4.isValid(): ternary;
            hdr.ipv4.src_addr : ternary;
            hdr.ipv4.dst_addr : ternary;
            hdr.inner_ipv4.isValid() : ternary;
            hdr.inner_ipv4.src_addr : ternary;
            hdr.inner_ipv4.dst_addr : ternary;
            hdr.ethernet.ether_type : ternary;
        }

        actions = {
            hit;
            @defaultonly NoAction;
        }

        const default_action = NoAction();
        size = 10;
    }

    apply {

        dump_to_cpu.apply();
    }
}

control DumpEgressHandler(in jnsgw_header_t hdr,
  inout jnsgw_egress_metadata_t eg_md,
  inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)
{

    Register<switch_int32_t, bit<32>>(1) count_reg;
    RegisterAction<switch_int32_t, bit<32>, bit<3>>(count_reg) count_reg_action = {
        void apply(inout switch_int32_t value, out bit<3> mirror_type){
            if (value > 0){
                mirror_type = 3;
                value = value - 1;
            } else {
                mirror_type = 0;
            }
        }
    };


 action hit() {
  eg_md.dump_flag = eg_md.dump_flag | (32w0x80000000);
  eg_md.mirror_header_type = HEADER_TYPE_DUMP;
  eg_md.mirror_session_id = (switch_uint16_t)MIRROR_DUMP_ID2;
  eg_dprsr_md.mirror_type = count_reg_action.execute(0);
 }

 table dump_to_cpu {
  key = {
            hdr.new_gre_opt_key.isValid() : ternary;
   hdr.new_gre_opt_key.key : ternary;
            hdr.new_out_ipv4.isValid() : ternary;
   hdr.new_out_ipv4.src_addr : ternary;
   hdr.new_out_ipv4.dst_addr : ternary;
            hdr.ipv4.isValid() : ternary;
   hdr.ipv4.src_addr : ternary;
   hdr.ipv4.dst_addr : ternary;
  }

  actions = {
   hit;
   @defaultonly NoAction;
  }

  const default_action = NoAction();
  size = 10;
 }

 apply {
  dump_to_cpu.apply();
 }
}
# 5 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/sys_config.p4" 2
control GetLocaljnsgwInfo(inout jnsgw_header_t hdr,
                inout jnsgw_ingress_metadata_t ig_md,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS) local_jnsgw_info_indr_ct;

    action miss() {
        //ig_dprsr_md.drop_ctl = 1;
        local_jnsgw_info_indr_ct.count(0);
        //exit;
    }

    action hit(ipv4_addr_t vip, ipv4_addr_t agent_vip) {
        ig_md.local_jnsgw_info.vip = vip;
        ig_md.local_jnsgw_info.agent_vip = agent_vip;
    }

    table local_jnsgw_info {
        actions = {
            hit;
            miss;
        }

        default_action = miss;
    }

    apply {
     /* get local jnsgw info */
        local_jnsgw_info.apply();
    }
}

control GetGlobalIPId(inout jnsgw_header_t hdr,
                inout jnsgw_ingress_metadata_t ig_md){

    Register<switch_uint16_t, bit<32>>(1) global_iph_id_reg;
    RegisterAction<switch_uint16_t, bit<32>, switch_uint16_t>(global_iph_id_reg) global_iph_id_reg_action = {
        void apply(inout switch_uint16_t value, out switch_uint16_t read_value){
            read_value = value;
            value = value + 1;
        }
    };

    apply {
     /* get global iph id */
     ig_md.iph_id = global_iph_id_reg_action.execute(0);
    }

}

control SelectMultiBip(inout jnsgw_header_t hdr,
            inout jnsgw_ingress_metadata_t ig_md,
            in ipv4_addr_t src_addr,
            in ipv4_addr_t dst_addr,
            in switch_uint8_t protocol)(
            switch_uint32_t bip_max_per_jnsgw){

    switch_uint8_t id = 1;
    Hash<bit<16>>(HashAlgorithm_t.CRC16) sel_hash;
    ActionProfile(bip_max_per_jnsgw) action_selector_ap;
    ActionSelector(action_selector_ap,
                 sel_hash,
                 SelectorMode_t.FAIR,
                 bip_max_per_jnsgw,// max group size
                 1 // max number of groups
                 ) action_selector;

    action miss() {
        ig_md.local_bip = ig_md.local_jnsgw_info.vip;
    }

    action hit(ipv4_addr_t bip) {
        ig_md.local_bip = bip;
    }

    table select_bip {
        key = {
            id : exact;
            src_addr : selector;
            dst_addr : selector;
            protocol : selector;
        }

        actions = {
            hit;
            miss;
        }

        default_action = miss;
        size = 1;
        implementation = action_selector;
    }

    apply {
        select_bip.apply();
    }

}

control GetDipType(inout jnsgw_header_t hdr,
            inout jnsgw_ingress_metadata_t ig_md,
            in ipv4_addr_t dst_addr)(
            switch_uint32_t DIP_TYPE_TABLE_SIZE){

    action miss() {
    }

    action hit(switch_uint8_t dip_type) {
        ig_md.dip_type = dip_type;
    }

    table dip_type{
        key = {
            dst_addr : ternary;
        }

        actions = {
            hit;
            miss;
        }

        default_action = miss;
        size = DIP_TYPE_TABLE_SIZE;
    }

    apply {
        dip_type.apply();
    }
}

control DoDelayStats(
    inout jnsgw_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md)(
    switch_uint32_t DELAY_STATS_TABLE_SIZE) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS) delay_stats_dr_ct;
    switch_uint16_t time_diff = 0;

    action hit() {
        delay_stats_dr_ct.count();
    }

    action miss() {
        delay_stats_dr_ct.count();
    }

    table delay_stats {
        key = {
            time_diff : range;
        }

        actions = {
            hit;
            miss;
        }

        counters = delay_stats_dr_ct;
        const default_action = miss;
        size = DELAY_STATS_TABLE_SIZE;
    }

    apply {
        time_diff = eg_prsr_md.global_tstamp[23:8] - eg_md.ingress_mac_tstamp;
        delay_stats.apply();
    }

}
# 8 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/port.p4" 1



control IngressFindPhysicalPort(inout jnsgw_header_t hdr,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
            inout ingress_intrinsic_metadata_for_tm_t ig_tm_md,
            inout physical_port_t phy_port_info,
            in switch_port_t port_id)(
            switch_uint32_t phy_port_table_size) {

    /* phy port tx stats */
 DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) physical_port_dr_ct;
 action hit(ipv4_addr_t ip, mac_addr_t mac, ipv4_addr_t gw_ip, mac_addr_t gw_mac){
  phy_port_info.ip = ip;
  phy_port_info.gw_ip = gw_ip;
  phy_port_info.mac = mac;
  phy_port_info.gw_mac = gw_mac;
  physical_port_dr_ct.count();
 }

    action miss() {
        ig_dprsr_md.drop_ctl = 1;
        physical_port_dr_ct.count();
  exit;
    }

 table physical_port {
  key = {
   port_id : exact;
  }

  actions = {
   hit;
   miss;
  }

  counters = physical_port_dr_ct;
  const default_action = miss;
  size = phy_port_table_size;
 }

 apply {
  physical_port.apply();
 }
}
# 9 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/cpu.p4" 1



control FromPcieCpuPort(
  inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md){

 Counter<bit<64>, switch_uint8_t>(2, CounterType_t.PACKETS_AND_BYTES) from_pcie_port_indr_ct;

    action set_egress_port() {
        ig_tm_md.ucast_egress_port = (bit<9>)hdr.fabric_header.dstPortOrGroup;
        hdr.ethernet.ether_type = hdr.fabric_payload_header.etherType;
        hdr.fabric_header.setInvalid();
        hdr.fabric_header_cpu.setInvalid();
        hdr.fabric_payload_header.setInvalid();
    }

    apply {
     if(hdr.fabric_header.isValid()) {
      set_egress_port();
            /* pkts from pcie stats */
            from_pcie_port_indr_ct.count(0);
     }else {
            /* pkts err from pcie cpu port */
      ig_dprsr_md.drop_ctl = 1;
      from_pcie_port_indr_ct.count(1);
            exit;
     }

    }
}

control ToPcieCpuPort(
  inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md){


    action add_cpu_header(
        bit<16> reason_code) {

        hdr.fabric_header.setValid();
        hdr.fabric_header.packetType = 5;
        hdr.fabric_header.headerVersion = 0;
        hdr.fabric_header.packetVersion = 0;
        hdr.fabric_header.pad1 = 0;
        hdr.fabric_header.fabricColor = 0;
        hdr.fabric_header.fabricQos = 0;
        hdr.fabric_header.dstDevice = 0;
        hdr.fabric_header.dstPortOrGroup = 0;

        hdr.fabric_header_cpu.setValid();
        hdr.fabric_header_cpu.reserved = 0;
        hdr.fabric_header_cpu.ingressIfindex = 0;
        hdr.fabric_header_cpu.ingressBd = 1;
        hdr.fabric_header_cpu.reasonCode = reason_code;
        hdr.fabric_header_cpu.ingressPort = (switch_uint16_t)ig_intr_md.ingress_port;

        hdr.fabric_payload_header.setValid();
        hdr.fabric_payload_header.etherType = hdr.ethernet.ether_type;
        hdr.ethernet.ether_type = ETHERTYPE_BF_FABRIC;
        ig_tm_md.ucast_egress_port = 134;

    }

    apply {
  add_cpu_header(0);
    }
}
# 10 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/vpc.p4" 1



control DoVpcTrafficStats1(inout jnsgw_header_t hdr,
            inout jnsgw_ingress_metadata_t ig_md,
            inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(
            switch_uint32_t vpc_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vpc_dr_ct;
    action hit(){
        vpc_dr_ct.count();
    }

 action miss() {
        vpc_dr_ct.count();
    }

    table vpc_stats {
        key = {
            ig_md.vpcid : ternary;
        }

        actions = {
            hit;
            miss;
        }

        counters = vpc_dr_ct;
        const default_action = miss;
        size = vpc_table_size;
    }

    apply {
        vpc_stats.apply();
    }
}

control DoVpcTrafficStats2(inout jnsgw_header_t hdr,
            inout jnsgw_egress_metadata_t eg_md,
            inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md)(
            switch_uint32_t vpc_table_size) {

    DirectCounter<bit<64>>(CounterType_t.PACKETS_AND_BYTES) vpc_dr_ct;
    action hit(){
        vpc_dr_ct.count();
    }

 action miss() {
        vpc_dr_ct.count();
    }

    table vpc_stats {
        key = {
            eg_md.to_vnet_bridge_b.ct_vpcid : ternary;
        }

        actions = {
            hit;
            miss;
        }

        counters = vpc_dr_ct;
        const default_action = miss;
        size = vpc_table_size;
    }

    apply {
        vpc_stats.apply();
    }
}

control FindUnderlayFlowEntry(inout jnsgw_header_t hdr,
            inout jnsgw_egress_metadata_t eg_md,
            inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
            in ipv4_addr_t cip,
            in ipv4_addr_t vip,
            in switch_uint16_t vport,
            in switch_uint8_t proto)(
            switch_uint32_t underlay_flows_pre0_table_size,
            switch_uint32_t underlay_flows_pre_table_size,
            switch_uint32_t underlay_flows_table_size) {

    //Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS) underlay_flows_indr_ct;
    bit<24> index;

    action hit(ipv4_addr_t snatip, switch_uint32_t remote_ip, switch_uint32_t gwip, bit<24> _index){
        hdr.recir_header.ct_snatip = snatip;
        hdr.recir_header.ct_remote_ip = remote_ip;
        hdr.recir_header.ct_gw_ip = gwip;
        index = _index;
        hdr.recir_header.setValid();
        hdr.recir_header.header_type = HEADER_TYPE_RECIRCULATE;
        hdr.recir_header.local_bip = eg_md.to_vnet_bridge_a.local_bip;
        hdr.recir_header.ingress_mac_tstamp = eg_md.to_vnet_bridge_a.ingress_mac_tstamp;
    }

    action miss() {
        hdr.recir_header.ct_remote_ip = 0;
        //underlay_flows_indr_ct.count(0);
    }

    @placement_priority(-10)
    table underlay_flows_pre0 {
        key = {
            cip : exact;
            vip : exact;
            vport : exact;
            proto : exact;
        }

        actions = {
            hit;
        }

        const default_action = hit(0,0,0,0);
        size = underlay_flows_pre0_table_size;
    }

    @placement_priority(-10)
    table underlay_flows_pre {
        key = {
            cip : exact;
            vip : exact;
            vport : exact;
            proto : exact;
        }

        actions = {
            hit;
        }

        proxy_hash = Hash<bit<32>>(HashAlgorithm_t.CRC32);

        const default_action = hit(0,0,0,0);
        size = underlay_flows_pre_table_size;
    }

    action hit2(switch_uint16_t rsport, switch_uint32_t rsip, switch_uint32_t vpcid){
        hdr.recir_header.ct_rsport = rsport;
        hdr.recir_header.ct_rsip = rsip;
        hdr.recir_header.ct_vpcid = vpcid;
    }

    @placement_priority(-10)
    table underlay_flows {
        key = {
            index : exact;
        }

        actions = {
            hit2;
            miss;
        }

        const default_action = miss;

        size = underlay_flows_table_size;
    }

    apply {

        if (!underlay_flows_pre0.apply().hit) {
            underlay_flows_pre.apply();
        }
        underlay_flows.apply();
    }
}

control FindOverlayFlowEntry(inout jnsgw_header_t hdr,
            inout jnsgw_egress_metadata_t eg_md,
            inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
            in ipv4_addr_t rsip,
            in switch_uint16_t rsport,
            in ipv4_addr_t snatip)(
            switch_uint32_t overlay_flows_pre0_table_size,
            switch_uint32_t overlay_flows_pre_table_size,
            switch_uint32_t overlay_flows_table_size) {

    //Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS) overlay_flows_indr_ct;
    bit<24> index;

    action hit(switch_uint32_t cip, bit<24> _index){
        eg_md.overlay_flow_entry.cip = cip;
        index = _index;
    }

    action miss() {
        eg_dprsr_md.drop_ctl = 1;
        eg_md.dump_flag = (32w0x0400);
        //overlay_flows_indr_ct.count(0);
        //exit;
    }

    table overlay_flows_pre0 {
        key = {
            rsip : exact;
            rsport : exact;
            snatip : exact;
        }

        actions = {
            hit;
        }

        const default_action = hit(0,0);
        size = overlay_flows_pre0_table_size;
    }

    table overlay_flows_pre {
        key = {
            rsip : exact;
            rsport : exact;
            snatip : exact;
        }

        actions = {
            hit;
        }

        proxy_hash = Hash<bit<32>>(HashAlgorithm_t.CRC32);

        const default_action = hit(0,0);
        size = overlay_flows_pre_table_size;
    }

    action hit2(ipv4_addr_t vip, switch_uint16_t vport){
        eg_md.overlay_flow_entry.vip = vip;
        eg_md.overlay_flow_entry.vport = vport;
    }

    table overlay_flows {
        key = {
            index : exact;
        }

        actions = {
            hit2;
            miss;
        }

        const default_action = miss;
        size = overlay_flows_table_size;
    }


    apply {
        if (! overlay_flows_pre0.apply().hit) {
            overlay_flows_pre.apply();
        }
        overlay_flows.apply();
    }
}
# 11 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2

# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/l2.p4" 1



control L2Handler(inout jnsgw_header_t hdr,
                inout jnsgw_ingress_metadata_t ig_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    apply{
        ig_md.vpcid = (32w0xffffffff);
        //ig_tm_md.ucast_egress_port = ig_md.ingress_port;
    }
}
# 13 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/l3.p4" 1



control IpHandler(inout jnsgw_header_t hdr,
                inout jnsgw_ingress_metadata_t ig_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
                  inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    Counter<bit<64>, switch_uint8_t>(6, CounterType_t.PACKETS_AND_BYTES) ip_handler_indr_ct;

    /*
    *Should save stats ALU resources as much as possible, each MAU supports 4 only.
    *index:[0-255] ip protocol stats.
    *index:[256] ttl err stats.
    *index:[257] ip_proto err stats.
    */
    Counter<bit<64>, switch_uint16_t>(512, CounterType_t.PACKETS_AND_BYTES) ip_handler2_indr_ct;

    switch_uint8_t ip_protocol;

 apply {
  if(hdr.ipv4.isValid()) {
            if(ig_md.ipv4_checksum_err == 0) {

                if(ig_md.dip_type == PAL_DIP_TYPE_TUNNEL){

                    if (hdr.gre.isValid()
                        && hdr.gre_opt_key.isValid()
                        && hdr.inner_ipv4.isValid()) {

                        ig_md.dump_flag = ig_md.dump_flag | (32w0x0200);
                        ig_md.vpcid = hdr.gre_opt_key.key;
                        ig_md.ipv4_ttl = hdr.inner_ipv4.ttl;

                        ip_protocol = hdr.inner_ipv4.protocol;

                        /* from vnet stats */
                        ip_handler_indr_ct.count(3);
                    } else {
                        /* tunnel packet decap error  */
                        ig_md.dump_flag = ig_md.dump_flag | (32w0x0080);

                        ig_dprsr_md.drop_ctl = 1;
                        ip_handler_indr_ct.count(2);
                        exit;
                    }

                } else {
                    ig_md.dump_flag = ig_md.dump_flag | (32w0x0100);
                    ig_md.ipv4_ttl = hdr.ipv4.ttl;

                    ip_protocol = hdr.ipv4.protocol;

                    /* from rnet stats */
                    ip_handler_indr_ct.count(4);
                }

            } else {

                ig_md.dump_flag = ig_md.dump_flag | (32w0x0040);
                /* ip header csum check error  */
                ig_dprsr_md.drop_ctl = 1;
                ip_handler_indr_ct.count(1);
                exit;
            }

        }else {
            /* unknow proto pkts */
            ig_dprsr_md.drop_ctl = 1;
            ip_handler_indr_ct.count(0);
            exit;
        }

        /* TTL check */
        if(ig_md.ipv4_ttl < 2) {

            /* ip header ttl error  */
            ig_dprsr_md.drop_ctl = 1;
            ip_handler2_indr_ct.count(256);
            exit;

        } else if (ip_protocol != IP_PROTOCOLS_TCP && ip_protocol != IP_PROTOCOLS_UDP) {
            /* ip_proto error  */
            ig_dprsr_md.drop_ctl = 1;
            ip_handler2_indr_ct.count(257);
            exit;

        } else {

            /* tcp/udp rx pkt stats */
            ip_handler2_indr_ct.count((switch_uint16_t)ip_protocol);
        }
    }
}


control IpOutputVnetEgress(inout jnsgw_header_t hdr,
                  inout jnsgw_ingress_metadata_t ig_md,
                  in ingress_intrinsic_metadata_t ig_intr_md,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md){
    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS_AND_BYTES) to_vnet_egress_indr_ct;

    apply {
        hdr.to_vnet_bridge_a.setValid();

        hdr.to_vnet_bridge_a.header_type = HEADER_TYPE_TO_VNET_BRIDGE1;
        hdr.to_vnet_bridge_a.iph_id = ig_md.iph_id;

        hdr.to_vnet_bridge_a.local_bip = ig_md.local_bip;
        hdr.to_vnet_bridge_a.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp[23:8];
        hdr.to_vnet_bridge_a.vport = hdr.l4_port.dst_port;

        /* set ethernet */
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
        hdr.ethernet.src_addr = ig_md.tx_phy_port.mac;
        hdr.ethernet.dst_addr = ig_md.tx_phy_port.gw_mac;
        hdr.ethernet.setValid();

        to_vnet_egress_indr_ct.count(0);
    }

}

control IpOutputRnetEgress(inout jnsgw_header_t hdr,
                  inout jnsgw_ingress_metadata_t ig_md,
                  in ingress_intrinsic_metadata_t ig_intr_md,
                  inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md){

    Counter<bit<64>, switch_uint8_t>(1, CounterType_t.PACKETS_AND_BYTES) to_rnet_egress_indr_ct;

    apply {

        hdr.ipv4.setInvalid();
        hdr.inner_ipv4.ttl = hdr.inner_ipv4.ttl - 1;

        /* set ethernet */
        hdr.ethernet.ether_type = ETHERTYPE_IPV4;
        hdr.ethernet.src_addr = ig_md.tx_phy_port.mac;
        hdr.ethernet.dst_addr = ig_md.tx_phy_port.gw_mac;
        hdr.ethernet.setValid();

        hdr.to_rnet_bridge.header_type = HEADER_TYPE_TO_RNET_BRIDGE;
        hdr.to_rnet_bridge.ingress_mac_tstamp = ig_intr_md.ingress_mac_tstamp[23:8];

        hdr.to_rnet_bridge.iph_id = ig_md.iph_id;
        hdr.to_rnet_bridge.setValid();

        hdr.to_rnet_bridge_rsinfo.ct_snatip = hdr.inner_ipv4.dst_addr;
        hdr.to_rnet_bridge_rsinfo.ct_rsip = hdr.inner_ipv4.src_addr;
        hdr.to_rnet_bridge_rsinfo.ct_rsport = hdr.l4_port.src_port;
        hdr.to_rnet_bridge_rsinfo.setValid();

        hdr.gre.setInvalid();
        hdr.gre_opt_key.setInvalid();
        hdr.gre_opt_csum.setInvalid();
        hdr.gre_opt_seq.setInvalid();

        to_rnet_egress_indr_ct.count(0);
    }
}


control IpOutputVnet(inout jnsgw_header_t hdr,
                  inout jnsgw_egress_metadata_t eg_md,
                  inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md){

    apply {

        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        /* do nat */
        hdr.ipv4.src_addr = eg_md.to_vnet_bridge_b.ct_snatip;
        hdr.ipv4.dst_addr = eg_md.to_vnet_bridge_b.ct_rsip;
        eg_md.pseudo_ipv4_src_addr = eg_md.to_vnet_bridge_b.ct_snatip;
        eg_md.pseudo_ipv4_dst_addr = eg_md.to_vnet_bridge_b.ct_rsip;

        hdr.l4_port.dst_port = eg_md.to_vnet_bridge_b.ct_rsport;

        hdr.new_out_ipv4 = {0,0,0,0,0,0,0,0,0,0,0,0,0,0};
        /* pack gre tunnel*/
        hdr.new_gre.K = 1;
        hdr.new_gre.version = (3w1);
        hdr.new_gre.proto = ETHERTYPE_IPV4;
        hdr.new_gre.R = 0;
        hdr.new_gre.S = 0;
        hdr.new_gre.s = 0;
        hdr.new_gre.recurse = 0;
        hdr.new_gre.flags = 0;

        if (eg_md.to_vnet_bridge_b.ct_gw_ip != 0) {
            hdr.new_gre.C = 1;
            hdr.new_gre_opt_csum.csum = eg_md.to_vnet_bridge_b.ct_gw_ip;
            hdr.new_gre_opt_csum.setValid();

            hdr.new_out_ipv4.total_len = hdr.ipv4.total_len + IP_GRE_OPT_KEY_CSUM_LEN;
        } else {
            hdr.new_gre.C = 0;
            hdr.new_out_ipv4.total_len = hdr.ipv4.total_len + IP_GRE_OPT_KEY_LEN;
        }

        hdr.new_gre.setValid();
        hdr.new_gre_opt_key.key = eg_md.to_vnet_bridge_b.ct_vpcid;
        hdr.new_gre_opt_key.setValid();

        hdr.new_out_ipv4.src_addr = eg_md.local_bip;
        hdr.new_out_ipv4.dst_addr = eg_md.to_vnet_bridge_b.ct_remote_ip;

        hdr.new_out_ipv4.ttl = 64;
        hdr.new_out_ipv4.ihl = (bit<4>)(IP_LEN >> 2);
        hdr.new_out_ipv4.identification = eg_md.iph_id;
        hdr.new_out_ipv4.frag_offset = 0;
        hdr.new_out_ipv4.protocol = IP_PROTOCOLS_GRE;
        hdr.new_out_ipv4.version = 4;
        hdr.new_out_ipv4.setValid();

    }

}
# 14 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/arp.p4" 1




control ArpHandler(inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    Counter<bit<64>, switch_uint8_t>(2, CounterType_t.PACKETS_AND_BYTES) arp_reply_indr_ct;

    ToPcieCpuPort() toPcieCpuPort;


    apply {

        if(hdr.arp.isValid() && hdr.arp_ipv4.isValid()) {
            /*send to hostif*/
            toPcieCpuPort.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);

            /* arp pkts stats */
            arp_reply_indr_ct.count(1);

        }else {
            /* arp error pkts */
            ig_dprsr_md.drop_ctl = 1;
            arp_reply_indr_ct.count(0);
            exit;
        }

    }
}
# 15 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/icmp.p4" 1



control IcmpHandler(
  inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md)(
        switch_uint32_t icmp_reply_route_table_size) {

    Counter<bit<64>, switch_uint8_t>(3, CounterType_t.PACKETS_AND_BYTES) icmp_reply_indr_ct;
    ToPcieCpuPort() toPcieCpuPort;


    action hit() {
    }

    action miss() {
    }

    table icmp_reply {
        key = {
            hdr.ipv4.dst_addr : ternary;
        }

        actions = {
            hit;
            miss;
        }

        const default_action = miss;
        size = icmp_reply_route_table_size;
    }

    apply {

        if(hdr.ipv4.isValid() && hdr.icmp.isValid()){

            if (icmp_reply.apply().hit) {
                /*send to hostif*/
                toPcieCpuPort.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);

                /* icmp rx pkts stats */
                icmp_reply_indr_ct.count(0);

            } else {
                /* unknown icmp pkts */
                ig_dprsr_md.drop_ctl = 1;
                icmp_reply_indr_ct.count(2);
                exit;
            }

        } else {
            /* icmp error pkts */
            ig_dprsr_md.drop_ctl = 1;
            icmp_reply_indr_ct.count(1);
            exit;
        }
    }
}
# 16 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_a.p4" 2



control IngressIP(
        inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    DoVpcTrafficStats1(VPC_TABLE_SIZE) doVpcTrafficStats1;
    SelectMultiBip(BIP_MAX_PER_jnsgw) selectMultiBip;
    IngressFindPhysicalPort(PHY_PORT_TABLE_SIZE) findPhysicalPort;

    IpOutputVnetEgress() ipOutputVnetEgress;
    IpOutputRnetEgress() ipOutputRnetEgress;

    apply{

        findPhysicalPort.apply(hdr, ig_dprsr_md, ig_tm_md, ig_md.tx_phy_port, ig_tm_md.ucast_egress_port);

        if(ig_md.vpcid == (32w0xffffffff)) {
            /* Traffic type one:  from rnet to vnet. */

            /* select multi bip */
            selectMultiBip.apply(hdr, ig_md, hdr.ipv4.src_addr, hdr.ipv4.dst_addr, hdr.ipv4.protocol);

            /* send to folded pipeline */
            ig_tm_md.ucast_egress_port = ig_tm_md.ucast_egress_port & 127;

            ig_tm_md.bypass_egress = 0;
            ipOutputVnetEgress.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md);

        } else {
            /* Traffic type two:  from vnet to rnet.  */

            /* vpc traffic statistic */
            doVpcTrafficStats1.apply(hdr, ig_md, ig_dprsr_md);

            ig_tm_md.bypass_egress = 0;
            ipOutputRnetEgress.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md);
        }
    }
}

control Ingress_a(
        inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
    /* control */
    GetLocaljnsgwInfo() getLocaljnsgwInfo;
    GetGlobalIPId() getGlobalIPId;

    L2Handler() l2Handler;
    ArpHandler() arpHandler;
    IcmpHandler(ICMP_REPLY_ROUTE_TABLE_SIZE) icmpHandler;
    IngressIP() ingressIP;

    FromPcieCpuPort() fromPcieCpuPort;

    ToPcieCpuPort() toPcieCpuPort;
    DumpHandler() dumpHandler;

    GetDipType(DIP_TYPE_TABLE_SIZE) getDipType;
    IpHandler() ipHandler;
    Counter<bit<64>, switch_uint8_t>(3, CounterType_t.PACKETS_AND_BYTES) ingress_indr_ct;

    Random<bit<5>>() random;

    apply {

        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;

        ig_md.tem_portid[1:0] = 0;
        ig_md.tem_portid[6:2] = random.get();
        ig_md.tem_portid[8:7] = 1;

        l2Handler.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
        getGlobalIPId.apply(hdr, ig_md);
        getLocaljnsgwInfo.apply(hdr, ig_md, ig_dprsr_md);

        ig_tm_md.bypass_egress = 1;

        dumpHandler.apply(hdr, ig_md, ig_dprsr_md);
        ig_md.dump_flag = ig_md.dump_flag | (32w0x0001);

        if(ig_intr_md.ingress_port == 134){
            /* packet from cpu port */
            fromPcieCpuPort.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
            ig_md.dump_flag = ig_md.dump_flag | (32w0x0004);

        } else {

            if(hdr.arp.isValid()) {
                /* arp */
                arpHandler.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
                ig_md.dump_flag = ig_md.dump_flag | (32w0x0010);

            } else if(hdr.icmp.isValid()) {
                /* icmp */
                icmpHandler.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
                ig_md.dump_flag = ig_md.dump_flag | (32w0x0020);

            } else if (ig_md.multi_or_broad_flag[0:0] == 1
                    || hdr.ipv4.dst_addr == ig_md.tx_phy_port.ip
                    || hdr.ipv4.dst_addr == ig_md.local_jnsgw_info.agent_vip) {
                /* send broadcast/muticast/management traffic to cpu hostif */
                toPcieCpuPort.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
                ingress_indr_ct.count(0);
                ig_md.dump_flag = ig_md.dump_flag | (32w0x0008);

            }else{
                /* get dip type */
                getDipType.apply(hdr, ig_md, hdr.ipv4.dst_addr);

                ipHandler.apply(hdr, ig_md, ig_dprsr_md, ig_tm_md);
                if (hdr.ipv4.isValid() && (hdr.ipv4.flag_mf != 0 || hdr.ipv4.frag_offset != 0)) {
                    // recvive ip frag pkts
                    ig_tm_md.ucast_egress_port = 258;
                    ingress_indr_ct.count(1);
                    return;

                }else if (hdr.inner_ipv4.isValid() && (hdr.inner_ipv4.flag_mf != 0 || hdr.inner_ipv4.frag_offset != 0)) {
                    // receive inner ip frag pkts
                    ig_tm_md.ucast_egress_port = 258;
                    ingress_indr_ct.count(2);
                    return;

                } else if (ig_intr_md.ingress_port == 385) {
                    // from CPU ETH
                    ig_tm_md.ucast_egress_port = ig_md.tem_portid;
                }

                /* ip handle */
                ingressIP.apply(hdr, ig_md, ig_intr_md, ig_dprsr_md, ig_tm_md);
            }

        }
    }
}

//@ignore_table_dependency("Egress_a.doDelayStats.delay_stats")
control Egress_a(
    /* User */
    inout jnsgw_header_t hdr,
    inout jnsgw_egress_metadata_t eg_md,
    /* Intrinsic */
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    FindOverlayFlowEntry(OVERLAY_FLOWS_PRE0_TABLE_SIZE, OVERLAY_FLOWS_PRE_TABLE_SIZE, OVERLAY_FLOWS_TABLE_SIZE) findOverlayFlowEntry;

    IpOutputVnet() ipOutputVnet;
    DoVpcTrafficStats2(VPC_TABLE_SIZE) doVpcTrafficStats2;
    DumpEgressHandler() dumpHandler1;
    DumpEgressHandler() dumpHandler2;

    Counter<bit<64>, switch_uint8_t>(6, CounterType_t.PACKETS_AND_BYTES) egress_output_indr_ct;
    Counter<bit<64>, switch_uint8_t>(256, CounterType_t.PACKETS_AND_BYTES) ip_proto_tx_stats_indr_ct;

    DoDelayStats(DELAY_STATS_TABLE_SIZE) doDelayStats;
    bit<13> tem_offset;

    action set_ip_offset(){
         hdr.ipv4.frag_offset = tem_offset;
    }

    apply {

        /* lookup overlay_flow_tb  */
        findOverlayFlowEntry.apply(hdr, eg_md, eg_dprsr_md, eg_md.to_vnet_bridge_b.ct_rsip,
                                   eg_md.to_vnet_bridge_b.ct_rsport,
                                   eg_md.to_vnet_bridge_b.ct_snatip);

        if (eg_md.to_vnet_bridge_b.isValid()) {

            /* init eg_md */
            eg_md.dump_flag = (32w0x2000);
            eg_md.local_bip = eg_md.to_vnet_bridge_b.local_bip;
            eg_md.iph_id = eg_md.to_vnet_bridge_b.iph_id;

            tem_offset = (hdr.ipv4.frag_offset + 13w55);

            if(eg_md.to_vnet_bridge_b.ct_remote_ip == 0){

                eg_dprsr_md.drop_ctl = 1;
                eg_md.dump_flag = eg_md.dump_flag | (32w0x0400);

                /* underlay flow miss stats */
                egress_output_indr_ct.count(2);

            } else if (eg_dprsr_md.drop_ctl == 1) {
                /* reverse lookup overlay_flow_tb miss stats */
                egress_output_indr_ct.count(5);

            } else if (eg_md.overlay_flow_entry.cip != hdr.ipv4.src_addr ) {
                /* underlay flow hash conflict error stats */
                eg_dprsr_md.drop_ctl = 1;
                egress_output_indr_ct.count(4);

            } else if (eg_md.overlay_flow_entry.vip != hdr.ipv4.dst_addr) {
                /* underlay flow hash conflict error stats */
                eg_dprsr_md.drop_ctl = 1;
                egress_output_indr_ct.count(4);

            } else if (eg_md.overlay_flow_entry.vport != hdr.l4_port.dst_port) {
                /* underlay flow hash conflict error stats */
                eg_dprsr_md.drop_ctl = 1;
                egress_output_indr_ct.count(4);

            } else {
                /* egress output vnet stats */
                egress_output_indr_ct.count(0);
            }

            if (eg_md.ing_port_mirror.header_type == HEADER_TYPE_MIRROR_INGRESS) {
                hdr.ipv4.flag_mf = 0x1;
                hdr.ipv4.flag_df = 0;
                hdr.ipv4.total_len = 16w460;
            } else if (eg_md.to_vnet_bridge_b.header_type == HEADER_TYPE_TO_VNET_BRIDGE2) {
                set_ip_offset();
                hdr.ipv4.flag_df = 0;
                hdr.ipv4.total_len = hdr.ipv4.total_len - 16w440;
                hdr.l4_port.setInvalid();
            }

            doVpcTrafficStats2.apply(hdr, eg_md, eg_dprsr_md);
            ipOutputVnet.apply(hdr, eg_md, eg_dprsr_md);

            dumpHandler1.apply(hdr, eg_md, eg_dprsr_md);

            /* tcp/udp tx pkt stats */
            ip_proto_tx_stats_indr_ct.count(hdr.ipv4.protocol);

        } else if (eg_md.to_rnet_bridge.isValid()) {

            /* do nat */
            hdr.new_out_ipv4 = hdr.ipv4;
            hdr.new_out_ipv4.src_addr = eg_md.overlay_flow_entry.vip;
            hdr.new_out_ipv4.dst_addr = eg_md.overlay_flow_entry.cip;
            eg_md.pseudo_ipv4_src_addr = eg_md.overlay_flow_entry.vip;
            eg_md.pseudo_ipv4_dst_addr = eg_md.overlay_flow_entry.cip;

            hdr.new_out_ipv4.setValid();
            hdr.ipv4.setInvalid();

            hdr.l4_port.src_port = eg_md.overlay_flow_entry.vport;

            /* egress output rnet stats */
            if (eg_dprsr_md.drop_ctl == 1) {
                /* overlay_flow_tb miss */
                egress_output_indr_ct.count(3);

            } else {
                egress_output_indr_ct.count(1);
                eg_md.dump_flag = (32w0x1000);
            }

            /* tcp/udp tx pkt stats */
            ip_proto_tx_stats_indr_ct.count(hdr.new_out_ipv4.protocol);

            dumpHandler2.apply(hdr, eg_md, eg_dprsr_md);
        }

        doDelayStats.apply(eg_md, eg_prsr_md);
    }
}
# 8 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_b.p4" 1
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/core.p4" 1
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
# 2 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_b.p4" 2
# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 1
/*
 * Copyright (c) 2015-2020 Barefoot Networks, Inc.
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


# 1 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tofino1arch.p4" 1
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
# 21 "/data/yinchaoyang/p4/bf-sde-9.1.0/install/share/p4c/p4include/tna.p4" 2
# 3 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_b.p4" 2
# 18 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/pipeline_profile_b.p4"
control Ingress_b(
        inout jnsgw_header_t hdr,
        inout jnsgw_ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    /* control */
    Counter<bit<64>, switch_uint8_t>(4, CounterType_t.PACKETS_AND_BYTES) ingress_b_indr_ct;

    bit<16> mss_check = 0;

    action do_mss_check(bit<16> mss, bit<16> expect) {
        mss_check = mss - expect; //  saturated subtract
    }

    apply {

        if (ig_intr_md.ingress_port == 257) {
            /* recv from cpu eth1 */
            ingress_b_indr_ct.count(2);
            ig_dprsr_md.drop_ctl = 1;
            exit;

        } else if (ig_intr_md.ingress_port == 258) {
            /* recv from cpu eth2 */
            ingress_b_indr_ct.count(3);
            ig_tm_md.bypass_egress = 1;
            ig_tm_md.ucast_egress_port = 385;

        } else {

            hdr.to_vnet_bridge_b.setValid();

            hdr.to_vnet_bridge_b.local_bip = ig_md.recir_header.local_bip;
            hdr.to_vnet_bridge_b.iph_id = ig_md.recir_header.iph_id;
            hdr.to_vnet_bridge_b.ingress_mac_tstamp = ig_md.recir_header.ingress_mac_tstamp;

            hdr.to_vnet_bridge_b.ct_snatip = ig_md.recir_header.ct_snatip;
            hdr.to_vnet_bridge_b.ct_rsip = ig_md.recir_header.ct_rsip;
            hdr.to_vnet_bridge_b.ct_rsport = ig_md.recir_header.ct_rsport;
            hdr.to_vnet_bridge_b.ct_vpcid = ig_md.recir_header.ct_vpcid;
            hdr.to_vnet_bridge_b.ct_remote_ip = ig_md.recir_header.ct_remote_ip;
            hdr.to_vnet_bridge_b.ct_gw_ip = ig_md.recir_header.ct_gw_ip;

            bit<11> tem = (bit<11>)1464;
            bit<5> high_value = (bit<5>)(hdr.ipv4.total_len >> 11);
            bit<11> low_value = (bit<11>)(hdr.ipv4.total_len);

            if(high_value > 0 || low_value > tem) {
                /* notify egress parser to do fragment. */
                hdr.to_vnet_bridge_b.header_type = HEADER_TYPE_TO_VNET_BRIDGE2;

                ig_dprsr_md.mirror_type = 1;
                ig_md.mirror_session_id = (switch_uint16_t)ig_intr_md.ingress_port + 129;

                ig_md.mirror_header_type = HEADER_TYPE_MIRROR_INGRESS;

                /* stats pkt need to do fragment */
                ingress_b_indr_ct.count(0);
            } else {
                /* not do fragment */
                hdr.to_vnet_bridge_b.header_type = HEADER_TYPE_TO_VNET_BRIDGE1;
                ingress_b_indr_ct.count(1);
            }

            if (hdr.tcp_options_mss.isValid()) {
                do_mss_check(hdr.tcp_options_mss.mss, 1406);
                if (mss_check > 0) {
                    hdr.tcp_options_mss.mss = 1406;
                }
            }

            if (hdr.tcp_options_1_before.isValid()) {
                ig_md.tcp_checksum_odd = true;
            }

            /* send back to original pipe */
            ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port | 128;

        }
    }
}


control Egress_b(
    /* User */
    inout jnsgw_header_t hdr,
    inout jnsgw_egress_metadata_t eg_md,
    /* Intrinsic */
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t eg_oport_md) {

    Counter<bit<64>, switch_uint8_t>(8, CounterType_t.PACKETS_AND_BYTES) egress_b_indr_ct;

    FindUnderlayFlowEntry(UNDERLAY_FLOWS_PRE0_TABLE_SIZE, UNDERLAY_FLOWS_PRE_TABLE_SIZE, UNDERLAY_FLOWS_TABLE_SIZE) findUnderlayFlowEntry;


    apply {

        if (eg_md.to_vnet_bridge_a.isValid()) {
            /* stats recv pkts */
            egress_b_indr_ct.count(0);

            findUnderlayFlowEntry.apply(hdr, eg_md, eg_dprsr_md, hdr.ipv4.src_addr, hdr.ipv4.dst_addr,
                eg_md.to_vnet_bridge_a.vport, hdr.ipv4.protocol);

        } else if (eg_md.dump_bridge.isValid()) {

            if (hdr.ipv4.src_addr == 0) {
                /* ugly code: change ipv4.src_addr to phv */
                hdr.ipv4.src_addr = 1;
                hdr.ipv4.dst_addr = 1;
            }

            /* stats dump pkts */
            egress_b_indr_ct.count(1);

            hdr.dump.setValid();
            hdr.dump.flags = eg_md.dump_bridge.dump_flag;
            hdr.dump.magic = 32w0xffffffff;
        } else {
            /* egress unknow pkts */
            eg_dprsr_md.drop_ctl = 1;
            egress_b_indr_ct.count(2);
            exit;
        }
    }
}
# 9 "/data/yinchaoyang/p4/bf-sde-9.1.0/pkgsrc/p4-jnsgw-folded/jnsgw_main.p4" 2





@pa_no_overlay("ingress", "hdr.fabric_header.packetType")
@pa_no_overlay("ingress", "hdr.fabric_header.headerVersion")
@pa_no_overlay("ingress", "hdr.fabric_header.packetVersion")
@pa_no_overlay("ingress", "hdr.fabric_header.pad1")
@pa_no_overlay("ingress", "hdr.fabric_header.fabricColor")
@pa_no_overlay("ingress", "hdr.fabric_header.fabricQos")
@pa_no_overlay("ingress", "hdr.fabric_header.dstDevice")
@pa_no_overlay("ingress", "hdr.fabric_header.dstPortOrGroup")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.ingressBd")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.reasonCode")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.egressQueue")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.txBypass")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.reserved")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.ingressPort")
@pa_no_overlay("ingress", "hdr.fabric_header_cpu.ingressIfindex")
@pa_no_overlay("ingress", "hdr.fabric_payload_header.etherType")

@pa_no_overlay("ingress", "hdr.inner_ipv4.protocol")
@pa_no_overlay("ingress", "hdr.icmp.checksum")


@pa_container_size("ingress", "hdr.arp.$valid", 8)
@pa_container_size("ingress", "hdr.arp_ipv4.$valid", 8)
@pa_container_size("ingress", "hdr.ethernet.$valid", 8)
@pa_container_size("ingress", "hdr.fabric_header.$valid", 8)
@pa_container_size("ingress", "hdr.fabric_header_cpu.$valid", 8)
@pa_container_size("ingress", "hdr.fabric_payload_header.$valid", 8)
@pa_container_size("ingress", "hdr.gre.$valid", 8)
@pa_container_size("ingress", "hdr.gre_opt_csum.$valid", 8)
@pa_container_size("ingress", "hdr.gre_opt_key.$valid", 8)
@pa_container_size("ingress", "hdr.gre_opt_seq.$valid", 8)
@pa_container_size("ingress", "hdr.icmp.$valid", 8)
@pa_container_size("ingress", "hdr.inner_ipv4.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_1.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_2.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_3.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_4.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_5.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_6.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_7.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_8.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_9.$valid", 8)
@pa_container_size("ingress", "hdr.ip_opt_word_10.$valid", 8)
@pa_container_size("ingress", "hdr.ipv4.$valid", 8)
@pa_container_size("ingress", "hdr.to_rnet_or_tgw_bridge.$valid", 8)
@pa_container_size("ingress", "hdr.to_vnet_bridge_a.$valid", 8)

@pa_container_size("egress", "eg_md.to_rnet_or_tgw_bridge.$valid", 8)
@pa_container_size("egress", "eg_md.to_vnet_bridge_b.$valid", 8)
@pa_container_size("egress", "hdr.ethernet.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_1.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_2.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_3.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_4.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_5.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_6.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_7.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_8.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_9.$valid", 8)
@pa_container_size("egress", "hdr.ip_opt_word_10.$valid", 8)
@pa_container_size("egress", "hdr.ipv4.$valid", 8)
@pa_container_size("egress", "hdr.new_gre.$valid", 8)
@pa_container_size("egress", "hdr.new_gre_opt_csum.$valid", 8)
@pa_container_size("egress", "hdr.new_gre_opt_key.$valid", 8)
@pa_container_size("egress", "hdr.new_gre_opt_seq.$valid", 8)
@pa_container_size("egress", "hdr.new_out_ipv4.$valid", 8)
@pa_container_size("egress", "hdr.payload_frag.$valid", 8)

/* pipe 0 */
@pa_container_size("ingress", "hdr.to_vnet_bridge_b.$valid", 8)
@pa_container_size("egress", "eg_md.dump_bridge.$valid", 8)
@pa_container_size("egress", "hdr.dump.$valid", 8)
@pa_container_size("egress", "hdr.recir_header.$valid", 8)

/*
* arp/icmp/ctrl flow: ingress_a (ing_mirror for dump) <--> cpu_pcie
* v2r flow: ingress_a (ing_mirror for input dump) --> egress_a (eg_mirror for output dump)
* r2v flow: ingress_a (ing_mirror to egress_a for input dump) --> egress_b
*           egress_b(lookup underlay_flow_tb) --> ingress_b
*           ingress_b(ing_mirror to egress_a for fragment) --> egress_a(eg_mirror to egress_a for output dump)
* frag pkts or flow_tb not found: ingress_a --> egress_b(CPU ETH2)
* dump pkts:ingress_a/egress_a --> egress_b(CPU_ETH1)
*/

Pipeline(IngressParser_a(),
         Ingress_a(),
         IngressDeparser_a(),
         EgressParser_a(),
         Egress_a(),
         EgressDeparser_a()) pipeline_profile_a;

Pipeline(IngressParser_b(),
         Ingress_b(),
         IngressDeparser_b(),
         EgressParser_b(),
         Egress_b(),
         EgressDeparser_b()) pipeline_profile_b;

Switch(pipeline_profile_b, pipeline_profile_a) main;
