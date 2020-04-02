# 1 "npb.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "npb.p4"
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
 ******************************************************************************/

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
# 24 "npb.p4" 2



# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tna.p4" 1
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


# 1 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tofino1arch.p4" 1
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
# 23 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tofino1arch.p4" 2
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
    MathUnit(MathOp_t op, int factor); // configure as factor * op(x)
    MathUnit(MathOp_t op, int A, int B); // configure as (A/B) * op(x)
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
# 24 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tofino1arch.p4" 2

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
# 21 "/home/zma/HEAD/bf-p4c-compilers/build/p4c/p4include/tna.p4" 2
# 28 "npb.p4" 2


# 1 "features.p4" 1
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
 ******************************************************************************/

// List of all supported #define directives.

// ==========================================================
// ==========================================================
// ==========================================================
// Tofino 1
// ==========================================================
// ==========================================================
// ==========================================================






// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE
# 50 "features.p4"
// define to stub out the vast majority of the ingress MAU - for debug

// define to stub out the vast majority of the egress MAU - for debug


// define for selecting whether opaque stack sizes get passes across as md or hdrs.
// only one of the following can be defined at a time!


//#define  OPAQUE_SIZE_AS_MD
//#undef   OPAQUE_SIZE_AS_HDR

// defines for various egress parser experiments - only define one!
# 71 "features.p4"
// define for selecting simple tables, rather than action_selectors/action_profiles tables.


// define for action selector, undef for action_profile -- only used if _SIMPLE is undefined.


// define for simultaneous switch and npb functionality (undefine for npb only)
# 92 "features.p4"
// define to include per header-stack counters (for debug - currently used by parser tests)


// define to enable user-defined fields (this feature needs work - placeholder for now)


// define to enable the handling of parser errors in MAU
// (currently, only udf-releated partial header errors are supported)
// (currently, all parser errors get dropped in the parser due to p4c limitation (case #9472)) 


// define to include the parse_cpu state in the ingress parser.
// when enabled in certain configurations, we exceed tofino's 12 (mau) stages.


// define to enable parser/deparser support for inner ARP, ICMP, IGMP, GRE, ESP headers.
// these headers are not currently used in MAU, so removing them (undef) may result in PHV savings.
// not sure if some will evenutally be needed for L7 UDF stuff - hence the define...
# 31 "npb.p4" 2
# 1 "types.p4" 1
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
 ******************************************************************************/




// ----------------------------------------------------------------------------
// Common protocols/types
//-----------------------------------------------------------------------------
# 44 "types.p4"
//#define ETHERTYPE_VN   0x892F
# 75 "types.p4"
//#define MPLS_DEPTH 3


// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------
typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;

typedef PortId_t switch_port_t;
const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;

typedef ReplicationId_t switch_rid_t;
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<3> switch_digest_type_t;
const switch_digest_type_t SWITCH_DIGEST_TYPE_INVALID = 0;
const switch_digest_type_t SWITCH_DIGEST_TYPE_MAC_LEARNING = 1;

typedef bit<16> switch_ifindex_t;
typedef bit<10> switch_port_lag_index_t;
const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<16> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf




typedef bit<16> switch_nexthop_t;
typedef bit<16> switch_outer_nexthop_t;

typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_smac_index_t;

typedef bit<12> switch_stats_index_t;


typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
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
const switch_drop_reason_t SWITCH_DROP_REASON_SAME_IFINDEX = 58;
const switch_drop_reason_t SWITCH_DROP_REASON_MULTICAST_SNOOPING_ENABLED = 59;
const switch_drop_reason_t SWITCH_DROP_REASON_TRAFFIC_MANAGER = 71;
const switch_drop_reason_t SWITCH_DROP_REASON_ACL_DENY = 80;
const switch_drop_reason_t SWITCH_DROP_REASON_IFINDEX = 84;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_UNICAST = 89;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_MULTICAST = 90;
const switch_drop_reason_t SWITCH_DROP_REASON_L2_MISS_BROADCAST = 91;
const switch_drop_reason_t SWITCH_DROP_REASON_EGRESS_ACL_DENY = 92;
const switch_drop_reason_t SWITCH_DROP_REASON_NEXTHOP = 93;
const switch_drop_reason_t SWITCH_DROP_REASON_MLAG_MEMBER = 95;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_VERSION_INVALID = 110;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_OAM = 111;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_TTL_ZERO = 112;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_LEN_INVALID = 113;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MDTYPE_INVALID = 114;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_NEXT_PROTO_INVALID = 115;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_SI_ZERO = 116;
const switch_drop_reason_t SWITCH_DROP_REASON_TRANSPORT_NSH_MD_LEN_INVALID = 117;
const switch_drop_reason_t SWITCH_DROP_REASON_SFC_TABLE_MISS = 118;

typedef bit<2> switch_ip_type_t;
const switch_ip_type_t SWITCH_IP_TYPE_NONE = 0;
const switch_ip_type_t SWITCH_IP_TYPE_IPV4 = 1;
const switch_ip_type_t SWITCH_IP_TYPE_IPV6 = 2;

typedef bit<2> switch_ip_frag_t;
const switch_ip_frag_t SWITCH_IP_FRAG_NON_FRAG = 0b00; // Not fragmented.
const switch_ip_frag_t SWITCH_IP_FRAG_HEAD = 0b10; // First fragment of the fragmented packets.
const switch_ip_frag_t SWITCH_IP_FRAG_NON_HEAD = 0b11; // Fragment with non-zero offset.

// PKT ------------------------------------------------------------------------

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// When using varbit opqaque header on egress, we needed to pass the actual length across.
// varbit is broken, so now we can simply pass a (shorter) stack identifier across.
//typedef bit<10> switch_stack_length_t;
typedef bit<5> switch_stack_length_t;

// outer stacks
const switch_stack_length_t STACK_IPV4 = 1; // (20)*8;     // 20B (160b)
const switch_stack_length_t STACK_IPV4_GRE = 2; // (20+4)*8;   // 24B (192b)
const switch_stack_length_t STACK_IPV4_NVGRE = 3; // (20+4+4)*8; // 28B (224b)
const switch_stack_length_t STACK_IPV4_UDP_VXLAN = 4; // (20+8+8)*8; // 36B (288b)
const switch_stack_length_t STACK_IPV4_UDP_GTPU = 5; // (20+8+8)*8; // 36B (288b)

const switch_stack_length_t STACK_IPV6 = 6; // (40)*8;     // 40B (320b)
const switch_stack_length_t STACK_IPV6_GRE = 7; // (40+4)*8;   // 44B (352b)
const switch_stack_length_t STACK_IPV6_NVGRE = 8; // (40+4+4)*8; // 48B (384b)
const switch_stack_length_t STACK_IPV6_UDP_VXLAN = 9; // (40+8+8)*8; // 56B (448b)
const switch_stack_length_t STACK_IPV6_UDP_GTPU = 10; // (40+8+8)*8; // 56B (448b)

// inner stacks
const switch_stack_length_t STACK_ENET_IPV4_GRE = 11; // (14+20+4)*8;     // 38B (304b)
const switch_stack_length_t STACK_ENET_VLAN_IPV4_GRE = 12; // (14+4+20+4)*8;   // 42B (336b)
const switch_stack_length_t STACK_ENET_IPV4_UDP_GTPU = 13; // (14+20+8+8)*8;   // 50B (400b)
const switch_stack_length_t STACK_ENET_VLAN_IPV4_UDP_GTPU = 14; // (14+4+20+8+8)*8; // 54B (432b)

const switch_stack_length_t STACK_ENET_IPV6_GRE = 15; // (14+40+4)*8;     // 58B (464b)
const switch_stack_length_t STACK_ENET_VLAN_IPV6_GRE = 16; // (14+4+40+4)*8;   // 62B (496b)
const switch_stack_length_t STACK_ENET_IPV6_UDP_GTPU = 17; // (14+40+8+8)*8;   // 70B (560b)
const switch_stack_length_t STACK_ENET_VLAN_IPV6_UDP_GTPU = 18; // (14+4+40+8+8)*8; // 74B (592b)


// Multicast ------------------------------------------------------------------

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
    switch_multicast_rpf_group_t rpf_group;
}

// Tunneling ------------------------------------------------------------------

enum switch_tunnel_mode_t { PIPE, UNIFORM }

typedef bit<4> switch_tunnel_type_t;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NONE = 0;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VXLAN = 1;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_IPINIP = 2;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NSH = 3;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_NVGRE = 4;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPC = 5;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GTPU = 6;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_ERSPAN = 7;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GRE = 8;
//const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VLAN = 9;




typedef bit<16> switch_tunnel_index_t;
typedef bit<24> switch_tunnel_id_t;

struct switch_tunnel_metadata_t {
    switch_tunnel_type_t type;
    switch_tunnel_index_t index;
    switch_tunnel_id_t id;
 bit<8> flow_id;
    switch_ifindex_t ifindex;
    bit<16> hash;
    bool terminate;
}

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------
# 280 "types.p4"
// Single, Fixed Sized Extreme NSH Header (internal)
struct nsh_type1_internal_lkp_t {
 // ANY NSH METADATA THAT IS COLLECTED ABOUT THE PACKET GOES HERE.

    bool hdr_is_new; // ingress / egress
    bit<3> sf_bitmask; // ingress / egress

    bool sfc_is_new; // ingress only
    bit<8> sfc; // ingress only
    bit<8> flow_class; // ingress only
 bool l2_fwd_en; // ingress only

 bit<16> dsap; // egress only
 bool strip_e_tag; // egress only
 bool strip_vn_tag; // egress only
 bool strip_vlan_tag; // egress only
 bool truncate; // egress only
 bit<14> truncate_len; // egress only
 bit<4> tunnel_outer_type; // egress only
 bit<4> tunnel_inner_type; // egress only
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.


// Flags
//XXX Force the fields that are XORd to NOT share containers.
struct switch_ingress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
    bool acl_deny;
    bool port_vlan_miss;
    bool rmac_hit;
 bool dmac_miss;
    bool glean;
    // Add more flags here.
}

struct switch_egress_flags_t {
    bool ipv4_checksum_err_0;
    bool ipv4_checksum_err_1;
    bool ipv4_checksum_err_2;
    bool acl_deny;
    bool rmac_hit;
    // Add more flags here.
}

// Checks
struct switch_ingress_checks_t {
    // Add more checks here.
}

struct switch_egress_checks_t {
    // Add more checks here.
}

@flexible
struct switch_lookup_fields_t {
 // l2
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
//  bit<16>           arp_opcode;

 // l3
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<6> ip_dscp;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
 bit<16> ip_len;

 // l4
    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

 // tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_id_t tunnel_id;

 // l7




    switch_drop_reason_t drop_reason;
}

#if 0
@flexible
struct switch_lookup_fields_egress_t {
 // l2
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
//  bit<16>           arp_opcode;

 // l3
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<6> ip_dscp;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
 bit<16> ip_len;

 // l4
    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

 // tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_id_t tunnel_id;

    switch_drop_reason_t drop_reason;
}
#endif


@flexible
struct switch_lookup_fields_bridged_t {
 // l2
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;

    // 1 for ARP request, 2 for ARP reply.
//  bit<16>           arp_opcode;

 // l3
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<6> ip_dscp;
    //bit<128>          ip_src_addr;
    //bit<128>          ip_dst_addr;
 bit<16> ip_len;

 // l4
    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

 // tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_id_t tunnel_id;

    switch_drop_reason_t drop_reason;
}





// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;
    switch_port_lag_index_t ingress_port_lag_index;
    switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
//  bit<48> timestamp;
 bool rmac_hit;

    // Add more fields here.







    // ---------------
    // nsh meta data
    // ---------------
    bool nsh_type1_hdr_is_new; // set by sfc

    bit<3> nsh_type1_sf_bitmask; //  1 byte

    // ---------------
    // dedup stuff
    // ---------------





}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_index_t index;
    switch_outer_nexthop_t outer_nexthop;
    bit<16> hash;

//  bool terminate;
    bool terminate_0;
    bool terminate_1;
    bool terminate_2;
 bool nsh_terminate;
}

typedef bit<8> switch_bridge_type_t;

// ----------------------------------------

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;

    switch_lookup_fields_bridged_t lkp;





    switch_bridged_metadata_tunnel_extension_t tunnel;

}

// --------------------------------------------------------------------------------
// Ingress port metadata
// --------------------------------------------------------------------------------

struct switch_port_metadata_t {
    switch_port_lag_index_t port_lag_index;
//  switch_ifindex_t ifindex;
}

// --------------------------------------------------------------------------------
// Ingress metadata
// --------------------------------------------------------------------------------

@pa_container_size("ingress", "ig_md.lkp.l4_src_port", 8)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")
@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress port/lag index */ /* derek: passed to egress */
    switch_bd_t bd;
    switch_nexthop_t nexthop; /* derek: egress table pointer #1 */
    switch_outer_nexthop_t outer_nexthop; /* derek: egress table pointer #2 */
//  switch_nexthop_t acl_nexthop;
//  bool acl_redirect;

    bit<48> timestamp;
    bit<32> hash;
    bit<32> hash_nsh;

    switch_ingress_flags_t flags;
//  switch_ingress_checks_t checks;

    switch_drop_reason_t drop_reason_general;
    switch_drop_reason_t drop_reason_0;
    switch_drop_reason_t drop_reason_1;
    switch_drop_reason_t drop_reason_2;

    switch_lookup_fields_t lkp;
    switch_multicast_metadata_t multicast;
    switch_tunnel_metadata_t tunnel_0; /* derek: egress table pointer #3 (tunnel_0.index) */
    switch_tunnel_metadata_t tunnel_1;
    switch_tunnel_metadata_t tunnel_2;
 bool nsh_terminate;




    nsh_type1_internal_lkp_t nsh_type1;







}

// --------------------------------------------------------------------------------
// Egress metadata
// --------------------------------------------------------------------------------

struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
    switch_pkt_length_t pkt_length;
//  switch_kt_type_t pkt_type;

    switch_port_lag_index_t port_lag_index; /* egress port/lag index */
    switch_port_t port; /* Mutable copy of egress port */
    switch_port_t ingress_port; /* ingress port */
    switch_ifindex_t ingress_ifindex; /* ingress interface index */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_outer_nexthop_t outer_nexthop;

//  bit<32> timestamp;
//  bit<48> ingress_timestamp;

    switch_egress_flags_t flags;
//  switch_egress_checks_t checks;

    switch_lookup_fields_t lkp;
    switch_tunnel_metadata_t tunnel_0;
    switch_tunnel_metadata_t tunnel_1;
    switch_tunnel_metadata_t tunnel_2;
 bool nsh_terminate;

    switch_drop_reason_t drop_reason_general;
    switch_drop_reason_t drop_reason_0;
    switch_drop_reason_t drop_reason_1;
    switch_drop_reason_t drop_reason_2;

    nsh_type1_internal_lkp_t nsh_type1;

    bit<6> action_bitmask;
//  bit<NPB_EGR_SF_EGRESS_SFP_ACT_SEL_TABLE_DEPTH_POW2> action_3_meter_id;
    bit<10> action_3_meter_id;
    bit<8> action_3_meter_overhead;
}
# 32 "npb.p4" 2
# 1 "headers.p4" 1
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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------





///////////////////////////////////////////////////////////////////////////
// Layer 2 Headers
///////////////////////////////////////////////////////////////////////////

@pa_container_size("ingress", "hdr.transport.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.transport.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.outer.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.outer.ethernet.$valid", 16)
@pa_container_size("ingress", "hdr.inner.ethernet.src_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.dst_addr", 16, 32)
@pa_container_size("ingress", "hdr.inner.ethernet.$valid", 16)
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

header mpls_h { // LayerX
    bit<20> label;
    bit<3> exp;
    bit<1> bos;
    bit<8> ttl;
}

// (end of) MPLS pseudo wire control word (RFC 4448)
header mpls_pw_cw_h {
    bit<4> zeros;
    bit<12> rsvd;
    bit<16> seqNum;
}

//////////////////////////////////////////////////////////////
// Layer 3 Headers
//////////////////////////////////////////////////////////////

// Address Resolution Protocol -- RFC 6747
header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
    // ...
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<6> diffserv;
    bit<2> ecn;
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

header ipv4_option_h {
    bit<8> type;
    bit<8> length;
    bit<16> value;
}


  header ipv6_h {
      bit<4> version;
      bit<6> diffserv;
      bit<2> ecn;
      bit<20> flow_label;
      bit<16> payload_len;
      bit<8> next_hdr;
      bit<8> hop_limit;
      ipv6_addr_t src_addr;
      ipv6_addr_t dst_addr;
  }



//////////////////////////////////////////////////////////////
// Layer 4 Headers
//////////////////////////////////////////////////////////////

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

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> length;
    bit<16> checksum;
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

header sctp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<32> verifTag;
    bit<32> checksum;
}


//////////////////////////////////////////////////////////////
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// VXLAN -- RFC 7348
//-----------------------------------------------------------
header vxlan_h {
    bit<8> flags;
    bit<24> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

//-----------------------------------------------------------
// Generic Protocol Extension for VXLAN -- IETFv4
//-----------------------------------------------------------
header vxlan_gpe_h {
    bit<8> flags;
    bit<16> reserved;
    bit<24> vni;
    bit<8> reserved2;
}

//-----------------------------------------------------------
// Generic Routing Encapsulation (GRE) -- RFC 1701
//-----------------------------------------------------------
header gre_h {
    bit<1> C;
    bit<1> R; // deprecated in RFC 2784
    bit<1> K; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> S; // deprecated in RFC 2784, brought back in RFC 2890
    bit<1> s; // deprecated in RFC 2784
    bit<3> recurse; // deprecated in RFC 2784
    bit<5> flags; // deprecated in RFC 2784
    bit<3> version;
    bit<16> proto;
}

header gre_extension_sequence_h {
    bit<32> seq_num;
}

//-----------------------------------------------------------
// Network Virtualisation using GRE (NVGRE) -- RFC 7637
//-----------------------------------------------------------
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}

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
//  bit<32> TEID;
}

header gtp_v2_base_h {
    bit<3> version;
    bit<1> P;
    bit<1> T;
    bit<3> reserved;
    bit<8> msg_type;
    bit<16> msg_len;
}

header gtp_v1_v2_teid_h {
    bit<32> teid;
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


//////////////////////////////////////////////////////////////
// Transport Headers
//////////////////////////////////////////////////////////////
# 334 "headers.p4"
//-----------------------------------------------------------
// NSH
//-----------------------------------------------------------

// NSH Base Header (word 0, base word 0)
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

// NSH Service Path Header (word 1, base word 1)
header nsh_svc_path_h {
    bit<24> spi;
    bit<8> si;
}

// NSH MD Type1 (Fixed Length) Context Header (word 2, ext type 1 words 0-3)
header nsh_md1_context_h {
    bit<128> md;
}

// fixed sized version of this is needed for lookahead (word 2, ext type 2 word 0)
header nsh_md2_context_fixed_h {
    bit<16> md_class;
    bit<8> type;
    bit<1> reserved;
    bit<7> len;
}

// Single, Fixed Sized Extreme NSH Header (external)
header nsh_type1_h {
    // word 0: base word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words
    bit<4> reserved2;
    bit<4> md_type;
    bit<8> next_proto;

 // --------------------

    // word 1: base word 1
    bit<24> spi;
    bit<8> si;

 // --------------------

    // word 2: ext type 1 word 0-3
 bit<8> ver; // word 0
 bit<8> scope; // word 0
//	bit<6>                          reserved3; // word 0
 bit<16> sap; // word 0

 bit<16> vpn; // word 1
 bit<16> sfc_data; // word 1

 bit<32> reserved4; // word 2

 bit<32> timestamp; // word 3
}


//////////////////////////////////////////////////////////////
// Layer7 Headers (aka UDF)
//////////////////////////////////////////////////////////////

header udf_h {
    bit<88> opaque;
}



//////////////////////////////////////////////////////////////
// Opaque Headers
//////////////////////////////////////////////////////////////


  header opaque_length_h {
      //bit<16> len;
      switch_stack_length_t len;
      //bit<6> pad;
      bit<11> pad;
  }





  header opaque_32B_h {
      bit<256> data;
  }
  header opaque_16B_h {
      bit<128> data;
  }
  header opaque_8B_h {
      bit<64> data;
  }
  header opaque_4B_h {
      bit<32> data;
  }
  header opaque_2B_h {
      bit<16> data;
  }
# 505 "headers.p4"
// --------------------------------------------------------------------------
// --------------------------------------------------------------------------
// Header Structures
// --------------------------------------------------------------------------
// --------------------------------------------------------------------------

struct switch_header_transport_t {
    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;
    nsh_type1_h nsh_type1;
# 524 "headers.p4"
}

// -----------------------------------------------------------------------------

struct switch_header_outer_t {

    ethernet_h ethernet;
    e_tag_h e_tag;
    vn_tag_h vn_tag;
    vlan_tag_h[2] vlan_tag;

    opaque_length_h opaque_length; // emit only




    ipv4_h ipv4;

    ipv6_h ipv6;

    arp_h arp;
    udp_h udp;
    icmp_h icmp;
    igmp_h igmp;
    tcp_h tcp;
    vxlan_h vxlan;
    gre_h gre;
    nvgre_h nvgre;





    sctp_h sctp;
    esp_h esp;


    gtp_v1_base_h gtp_v1_base;
    gtp_v2_base_h gtp_v2_base;
    gtp_v1_v2_teid_h gtp_v1_v2_teid;
    gtp_v1_optional_h gtp_v1_optional;


}

struct switch_header_outer_egress_t {
    ethernet_h ethernet;
    e_tag_h e_tag;
    vn_tag_h vn_tag;
    vlan_tag_h[2] vlan_tag;

    opaque_length_h opaque_length; // do not deparse





    opaque_32B_h opaque_32B_0;
    opaque_16B_h opaque_16B_0;
    opaque_8B_h opaque_8B_0;
    opaque_4B_h opaque_4B_0;
# 600 "headers.p4"
}


// -----------------------------------------------------------------------------

struct switch_header_inner_t {


    opaque_length_h opaque_length; // emit only

    ethernet_h ethernet;
    ipv4_h ipv4;

    ipv6_h ipv6;

    udp_h udp;
    tcp_h tcp;




    vlan_tag_h[1] vlan_tag;
    sctp_h sctp;


    gre_h gre;
# 637 "headers.p4"
}

struct switch_header_inner_egress_t {

    opaque_length_h opaque_length; // do not deparse




    opaque_32B_h opaque_32B_0;
    opaque_16B_h opaque_16B_0;
    opaque_8B_h opaque_8B_0;
    opaque_8B_h opaque_8B_1;
    opaque_4B_h opaque_4B_0;
    opaque_4B_h opaque_4B_1;
    opaque_2B_h opaque_2B_0;
# 667 "headers.p4"
}



// -----------------------------------------------------------------------------

struct switch_header_t {

    // ===========================
    // misc 
    // ===========================

    switch_bridged_metadata_h bridged_md;

    // ===========================
    // transport
    // ===========================

 switch_header_transport_t transport;

    // ===========================
    // outer
    // ===========================

 switch_header_outer_t outer;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_t inner;

    // ===========================
    // layer7
    // ===========================

    udf_h l7_udf;
}


struct switch_header_egress_t {

    // ===========================
    // misc 
    // ===========================

    switch_bridged_metadata_h bridged_md;

    // ===========================
    // transport
    // ===========================

 switch_header_transport_t transport;

    // ===========================
    // outer
    // ===========================

 switch_header_outer_egress_t outer;

    // ===========================
    // inner
    // ===========================

    switch_header_inner_egress_t inner;
}
# 33 "npb.p4" 2
# 1 "table_sizes.p4" 1
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
 ******************************************************************************/




// --------------------------------------------




// --------------------------------------------

const bit<32> PORT_TABLE_SIZE = 256;

// 4K L2 vlans
const bit<32> VLAN_TABLE_SIZE = 4096;

// 1K (port, vlan) <--> BD
const bit<32> PORT_VLAN_TABLE_SIZE = 1024;

// 5K BDs
const bit<32> BD_TABLE_SIZE = 5120;

// IP Hosts/Routes
const bit<32> RMAC_TABLE_SIZE = 64;

// 16K MACs



const bit<32> MAC_TABLE_SIZE = 1024;


// Tunnels - 4K IPv4 + 1K IPv6
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 64; // ingress
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 256; // ingress
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE = 64; // ingress
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 256; // ingress

const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512; // egress
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 1024; // egress
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 32; // egress
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 256; // egress

// ECMP/Nexthop



const bit<32> NEXTHOP_TABLE_SIZE = 1024;

const bit<32> ECMP_GROUP_TABLE_SIZE = 1024; // derek: unused; removed this table
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; removed this table

// ECMP/Nexthop
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096; // aka NUM_TUNNELS
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096; // derek: unused in switch.p4
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; changed table type to normal table

// Lag
const bit<32> LAG_GROUP_TABLE_SIZE = 1024;
const bit<32> LAG_SELECT_TABLE_SIZE = 256;

// Ingress ACLs






const bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 512;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE = 512;


// Egress ACL





const bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512;


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Extreme Networks - Added
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------



// ----------------
// *** tofino 1 ***
// ----------------

// net intf

// sfc -- classifies non-nsh packets
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 512;
const bit<32> NPB_ING_SFC_NET_SAP_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH = 1024; // derek, what size to make this?

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_LEN_RNG_TABLE_DEPTH = 512;

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_FLW_CLS_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SFF_SCHD_TABLE_PART1_DEPTH = 512; // action selector group
const bit<32> NPB_ING_SFF_SCHD_TABLE_PART2_DEPTH = 1024; // action selector select
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 1024;

// sf #1 -- replication
const bit<32> NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE = 1024;

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH = 1024;

const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_LEN_RNG_TABLE_DEPTH = 1024;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH = 512; // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH = 512; // unused in latest spec
# 34 "npb.p4" 2
# 1 "stack_sizes.p4" 1

# 1 "types.p4" 1
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
 ******************************************************************************/
# 3 "stack_sizes.p4" 2

// Stack length tables - For determining the size of various opaque stacks

// -----------------------------------------------------------------------------
// Outer Stack (1) - Does not include layer2 

control OpaqueStackLength_1(

    inout switch_header_outer_t hdr // src & dst





) {

    action set_length_to_zero() {

        hdr.opaque_length.setValid();
        hdr.opaque_length.len = 0;




    }

    //action set_length(bit<10> x) {
    action set_length(bit<5> x) {

        hdr.opaque_length.setValid();
        hdr.opaque_length.len = x;




    }

    table table_stack_length {

        key = {
            hdr.ipv4.isValid() : ternary;

            hdr.ipv6.isValid() : ternary;

            hdr.gre.isValid() : ternary;
            hdr.nvgre.isValid() : ternary;
            hdr.udp.isValid() : ternary;
            hdr.vxlan.isValid() : ternary;
            hdr.gtp_v1_base.isValid() : ternary;
        }

        actions = {
            //NoAction;
            set_length_to_zero;
            set_length;
        }

        size = 8;
        const default_action = set_length_to_zero;
        const entries = {


            (true, _, _, true, _, _, _):
            set_length(STACK_IPV4_NVGRE);
            (true, _, true, false, _, _, _):
            set_length(STACK_IPV4_GRE);
            (true, _, _, _, _, true, _):
            set_length(STACK_IPV4_UDP_VXLAN);
            (true, _, _, _, _, _, true):
            set_length(STACK_IPV4_UDP_GTPU);
            (true, _, _, _, _, _, _):
            set_length(STACK_IPV4);

            (_, true, _, true, _, _, _):
            set_length(STACK_IPV6_NVGRE);
            (_, true, true, false, _, _, _):
            set_length(STACK_IPV6_GRE);
            (_, true, _, _, _, true, _):
            set_length(STACK_IPV6_UDP_VXLAN);
            (_, true, _, _, _, _, true):
            set_length(STACK_IPV6_UDP_GTPU);
            (_, true, _, _, _, _, _):
            set_length(STACK_IPV6);
# 99 "stack_sizes.p4"
        }
    }

    // -----------------------------
 // Apply
    // -----------------------------

    apply {
        table_stack_length.apply();
    }
}


// -----------------------------------------------------------------------------
// Inner Stack (2)

control OpaqueStackLength_2(

    inout switch_header_inner_t hdr // src & dst





) {

    bool gtp_dummy_placeholder = false;


    action set_length_to_zero() {

        hdr.opaque_length.setValid();
        hdr.opaque_length.len = 0;




    }

    //action set_length(bit<10> x) {
    action set_length(bit<5> x) {

        hdr.opaque_length.setValid();
        hdr.opaque_length.len = x;




    }

    table table_stack_length {

        key = {
            hdr.ethernet.isValid() : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.ipv4.isValid() : ternary;

            hdr.ipv6.isValid() : ternary;

            hdr.gre.isValid() : ternary;
            hdr.udp.isValid() : ternary;
            //hdr.gtp_v1_base.isValid() : ternary;
            gtp_dummy_placeholder : ternary;
        }

        actions = {
            //NoAction;
            set_length_to_zero;
            set_length;
        }

        size = 16;
        const default_action = set_length_to_zero;
        const entries = {


            (true, false, true, _, true, _, _):
            set_length(STACK_ENET_IPV4_GRE);
            (true, true, true, _, true, _, _):
            set_length(STACK_ENET_VLAN_IPV4_GRE);
            (false, false, true, _, true, _, _):
            set_length(STACK_IPV4_GRE);

            // (true, false, true, _, _, _, true):
            // set_length(STACK_ENET_IPV4_UDP_GTPU);
            // (true, true, true, _, _, _, true):
            // set_length(STACK_ENET_VLAN_IPV4_UDP_GTPU);
            // (false, false, true, _, _, _, true):
            // set_length(STACK_IPV4_UDP_GTPU);

            (true, false, _, true, true, _, _):
            set_length(STACK_ENET_IPV6_GRE);
            (true, true, _, true, true, _, _):
            set_length(STACK_ENET_VLAN_IPV6_GRE);
            (false, false, _, true, true, _, _):
            set_length(STACK_IPV6_GRE);

            // (true, false, _, true, _, _, true):
            // set_length(STACK_ENET_IPV6_UDP_GTPU);
            // (true, true, _, true, _, _, true):
            // set_length(STACK_ENET_VLAN_IPV6_UDP_GTPU);
            // (false, false, _, true, _, _, true):
            // set_length(STACK_IPV6_UDP_GTPU);    
# 218 "stack_sizes.p4"
        }
    }

    // -----------------------------
 // Apply
    // -----------------------------

    apply {
        table_stack_length.apply();
    }
}


/*
    ENET,        // 14B
    VLAN,        // 4B
    ETAG,        // 8B
    VNTAG,       // 6B
    IPV4,        // 20B
    IPV6         // 40B
    UDP,         // 8B
    TCP,         // 20B
    SCTP         // 12B
    NSH,         // 24B
    GRE,         // 4B
    GRE SEQ EXT, // 4B
    NVGRE EXT,   // 4B
    ERSPAN_1,    // 8B
    ERSPAN_2,    // 12B
    VXLAN        // 8B
    ESP          // 8B
    GTP          // 8B
    UDF          // 11B
*/
# 35 "npb.p4" 2

# 1 "util.p4" 1
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
 ******************************************************************************/

# 1 "types.p4" 1
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
 ******************************************************************************/
# 24 "util.p4" 2

// -----------------------------------------------------------------------------

// Flow hash calculation.
Hash<bit<32>>(HashAlgorithm_t.CRC32) ip_hash;

action compute_ip_hash(
    in switch_lookup_fields_t lkp,
    out bit<32> hash
) {
    hash = ip_hash.get({
        lkp.ip_src_addr,
        lkp.ip_dst_addr,
        lkp.ip_proto,
        lkp.l4_dst_port,
        lkp.l4_src_port
    });
}

Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;

action compute_non_ip_hash(
    in switch_lookup_fields_t lkp,
    out bit<32> hash
) {
    hash = non_ip_hash.get({
        lkp.mac_type,
        lkp.mac_src_addr,
        lkp.mac_dst_addr
    });
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
action add_bridged_md(
    inout switch_bridged_metadata_h bridged_md,
    in switch_ingress_metadata_t ig_md
) {
    bridged_md.setValid();
    bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
    bridged_md.base = {
        ig_md.port,
        ig_md.port_lag_index,
        ig_md.bd,
        ig_md.nexthop,
//      ig_md.lkp.pkt_type,
//      ig_md.timestamp,
        ig_md.flags.rmac_hit,

        ig_md.nsh_type1.hdr_is_new,
        ig_md.nsh_type1.sf_bitmask //  1 byte
    };


    bridged_md.tunnel = {
        ig_md.tunnel_0.index,
        ig_md.outer_nexthop,
        ig_md.hash[15:0],

        ig_md.tunnel_0.terminate,
        ig_md.tunnel_1.terminate,
        ig_md.tunnel_2.terminate,
  ig_md.nsh_terminate
    };


    //bridged_md.lkp = ig_md.lkp;
    bridged_md.lkp.mac_src_addr = ig_md.lkp.mac_src_addr;
    bridged_md.lkp.mac_dst_addr = ig_md.lkp.mac_dst_addr;
    bridged_md.lkp.mac_type = ig_md.lkp.mac_type ;
    bridged_md.lkp.pcp = ig_md.lkp.pcp ;
    bridged_md.lkp.ip_type = ig_md.lkp.ip_type ;
    bridged_md.lkp.ip_proto = ig_md.lkp.ip_proto ;
    bridged_md.lkp.ip_dscp = ig_md.lkp.ip_dscp ;




    bridged_md.lkp.ip_len = ig_md.lkp.ip_len ;
    bridged_md.lkp.tcp_flags = ig_md.lkp.tcp_flags ;
    bridged_md.lkp.l4_src_port = ig_md.lkp.l4_src_port ;
    bridged_md.lkp.l4_dst_port = ig_md.lkp.l4_dst_port ;
    bridged_md.lkp.tunnel_type = ig_md.lkp.tunnel_type ;
    bridged_md.lkp.tunnel_id = ig_md.lkp.tunnel_id ;
    bridged_md.lkp.drop_reason = ig_md.lkp.drop_reason ;
}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
    in switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
    // Set PRE hash values
//  ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
    ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
    ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;
}
# 37 "npb.p4" 2
# 1 "l3.p4" 1
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
 ******************************************************************************/

# 1 "acl.p4" 1
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
 ******************************************************************************/




# 1 "scoper.p4" 1
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
 ******************************************************************************/




// ============================================================================
// This module correctly populates the lookup structure from a header stack.
//
// Note: Since not all header stacks have all of the header types, some headers
// have separate valids on them to handle this.  Feel free to add more of these
// separate valid signals as needed.
// ============================================================================

control Scoper(
  in ethernet_h l2,
  in vlan_tag_h l2_tag0,
  in bool l2_tag1_isValid,
  in vlan_tag_h l2_tag1,

  in ipv4_h l3_ipv4,

  in bool l3_ipv6_isValid,
  in ipv6_h l3_ipv6,

  in bool l4_tcp_isValid,
  in tcp_h l4_tcp,
  in udp_h l4_udp,
  in sctp_h l4_sctp,

  in switch_tunnel_type_t tunnel_type, // only send in actual tunnels here -- do not send in vlan tunnels (use vlan input instead)
  in switch_tunnel_id_t tunnel_id, // only send in actual tunnels here -- do not send in vlan tunnels (use vlan input instead)

  in switch_drop_reason_t drop_reason,

        inout switch_lookup_fields_t lkp
) {

    // -----------------------------
 // L2
    // -----------------------------

    action scope_l2_none() {
        lkp.mac_src_addr = 0;
        lkp.mac_dst_addr = 0;
        lkp.mac_type = 0;
        lkp.pcp = 0;
 }

    action scope_l2() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type = l2.ether_type;
    }

    action scope_l2_1tag() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type = l2.ether_type;
        lkp.mac_type = l2_tag0.ether_type;
        lkp.pcp = l2_tag0.pcp;
    }

    action scope_l2_2tags() {
        lkp.mac_src_addr = l2.src_addr;
        lkp.mac_dst_addr = l2.dst_addr;
        lkp.mac_type = l2.ether_type;
        lkp.mac_type = l2_tag0.ether_type;
        lkp.pcp = l2_tag0.pcp;
    }

    table scope_l2_ {
        key = {
   l2.isValid(): exact;
            l2_tag0.isValid(): exact;
            l2_tag1_isValid: exact;
        }
        actions = {
            scope_l2_none;
            scope_l2;
            scope_l2_1tag;
            scope_l2_2tags;
        }
        const entries = {
            (false, false, false): scope_l2_none();
            (true, false, false): scope_l2();
            (true, true, false): scope_l2_1tag();
            (true, true, true ): scope_l2_2tags();
        }

 }

    // -----------------------------
 // L3
    // -----------------------------

    action scope_l3_none() {
        lkp.ip_type = 0;
        lkp.ip_dscp = 0;
        lkp.ip_proto = 0;
        lkp.ip_src_addr = 0;
        lkp.ip_dst_addr = 0;
        lkp.ip_len = 0; // extreme added
 }

    action scope_l3_v4() {
        lkp.ip_type = SWITCH_IP_TYPE_IPV4;
        lkp.ip_dscp = l3_ipv4.diffserv;
        lkp.ip_proto = l3_ipv4.protocol;
        lkp.ip_src_addr = (bit<128>) l3_ipv4.src_addr;
        lkp.ip_dst_addr = (bit<128>) l3_ipv4.dst_addr;
        lkp.ip_len = l3_ipv4.total_len;
    }


    action scope_l3_v6() {
        lkp.ip_type = SWITCH_IP_TYPE_IPV6;
        lkp.ip_dscp = l3_ipv6.diffserv;
        lkp.ip_proto = l3_ipv6.next_hdr;
        lkp.ip_src_addr = l3_ipv6.src_addr;
        lkp.ip_dst_addr = l3_ipv6.dst_addr;
        lkp.ip_len = l3_ipv6.payload_len;
    }


    table scope_l3_ {
        key = {
            l3_ipv4.isValid(): exact;

            l3_ipv6_isValid: exact;

        }
        actions = {
            scope_l3_none;
            scope_l3_v4;

            scope_l3_v6;

        }
        const entries = {

   (false, false): scope_l3_none();
            (true, false): scope_l3_v4();
            (false, true ): scope_l3_v6();




        }

 }

    // -----------------------------
 // L4
    // -----------------------------

    action scope_l4_none() {
        lkp.l4_src_port = 0;
        lkp.l4_dst_port = 0;
        lkp.tcp_flags = 0;
 }

    action scope_l4_tcp() {
        lkp.l4_src_port = l4_tcp.src_port;
        lkp.l4_dst_port = l4_tcp.dst_port;
        lkp.tcp_flags = l4_tcp.flags;
    }

    action scope_l4_udp() {
        lkp.l4_src_port = l4_udp.src_port;
        lkp.l4_dst_port = l4_udp.dst_port;
        lkp.tcp_flags = 0;
    }

    action scope_l4_sctp() {
        lkp.l4_src_port = l4_sctp.src_port;
        lkp.l4_dst_port = l4_sctp.dst_port;
        lkp.tcp_flags = 0;
    }

    table scope_l4_ {
        key = {
            l4_tcp_isValid: exact;
            l4_udp.isValid(): exact;
            l4_sctp.isValid(): exact;
        }
        actions = {
            scope_l4_tcp;
            scope_l4_udp;
            scope_l4_sctp;
   scope_l4_none;
        }
        const entries = {
            (false, false, false): scope_l4_none();
            (true, false, false): scope_l4_tcp();
            (false, true, false): scope_l4_udp();
            (false, false, true ): scope_l4_sctp();
        }

 }

    // -----------------------------
 // TUNNEL
    // -----------------------------

    action scope_tunnel_none() {
        lkp.tunnel_type = 0;
        lkp.tunnel_id = 0;
 }
/*
    action scope_tunnel_vlan() {
		lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VLAN;
		lkp.tunnel_id   = (switch_tunnel_id_t)l2_tag0.vid;
    }
*/
    action scope_tunnel_vni() {
  lkp.tunnel_type = tunnel_type;
  lkp.tunnel_id = tunnel_id;
    }

    table scope_tunnel_ {
        key = {
            tunnel_type: exact;
/*
            tunnel_type: ternary;
            l2_tag0.isValid(): exact;
            l2_tag0.vid: ternary;
*/
        }
        actions = {
            scope_tunnel_vni;
//          scope_tunnel_vlan;
            scope_tunnel_none;
        }
        const entries = {
/*
			// highest -> lowest priority in tcam
            (0, true,  0): scope_tunnel_none(); // tag has priority only
            (0, true,  _): scope_tunnel_vlan(); // tag has priority and vlan
            (_, true,  _): scope_tunnel_vni();
            (_, false, _): scope_tunnel_vni();
            (0, false, _): scope_tunnel_none();
*/
            (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
        }
        const default_action = scope_tunnel_vni;

 }

    // -----------------------------
 // Apply
    // -----------------------------

 apply {
  scope_l2_.apply();
  scope_l3_.apply();
  scope_l4_.apply();
  scope_tunnel_.apply();

  lkp.drop_reason = drop_reason;
 }

}

// ============================================================================

control Scoper_l7(
    in udf_h hdr_l7_udf,
    inout switch_lookup_fields_t lkp
) {
    // -----------------------------

    action set_udf() {



    }

    action clear_udf() {



    }

    table validate_udf {
        key = {
            hdr_l7_udf.isValid() : exact;
        }

        actions = {
            NoAction;
            set_udf;
            clear_udf;
        }

        const default_action = NoAction;
        const entries = {
            (true) : set_udf();
            (false) : clear_udf();
        }
    }

    // -----------------------------

    apply {



    }

}
# 27 "acl.p4" 2

//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 60 "acl.p4"
;
# 106 "acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 170 "acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 355 "acl.p4"
// ---------------------------------

/*
action redirect_decap (
    bit<FLOW_CLASS_WIDTH>           flow_class
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

    terminate = true;
    scope     = true;

	stats.count();                                                            }
}
*/

// ---------------------------------

/*
action redirect_sfc_and_decap (
    bit<FLOW_CLASS_WIDTH>           flow_class,
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc,
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

    ig_md.nsh_type1.sfc_is_new             = 1;
    ig_md.nsh_type1.sfc                    = sfc;

	terminate = true;
    scope     = true;

	stats.count();                                                            }
}

// ---------------------------------

action redirect_decap_and_trunc (
    bit<FLOW_CLASS_WIDTH>           flow_class,
    bit<14>                         truncate_len
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

	terminate = true;
    scope     = true;

#if __TARGET_TOFINO__ == 2
    ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;
#endif

	stats.count();                                                            }
}

// ---------------------------------

action redirect_sfc_and_decap_and_trunc (
    bit<FLOW_CLASS_WIDTH>           flow_class,
    bit<SRVC_FUNC_CHAIN_WIDTH>      sfc,
    bit<14>                         truncate_len
) {
    ig_md.flags.acl_deny = false;

    // ----- extreme -----

    ig_md.nsh_type1.flow_class                 = flow_class;

    ig_md.nsh_type1.sfc_is_new             = 1;
    ig_md.nsh_type1.sfc                    = sfc;

    terminate = true;
    scope     = true;

#if __TARGET_TOFINO__ == 2
    ig_intr_md_for_dprsr.mtu_trunc_len = truncate_len;
#endif

	stats.count();                                                            }
}
*/

//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 503 "acl.p4"
// ============================================================================
// ============================================================================
// Ingress ACL ================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
    in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool scope_,
 inout bool hit,
 in bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { ig_md.flags.acl_deny = true; stats.count(); } action permit( ) { ig_md.flags.acl_deny = false; stats.count(); } action drop ( switch_drop_reason_t drop_reason ) { ig_md.flags.acl_deny = true; ig_intr_md_for_dprsr.drop_ctl = 0x1; ig_md.drop_reason_general = drop_reason; stats.count(); } action redirect ( bit<8> flow_class, bool terminate, bool scope ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); }
    action redirect_sfc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }



    action redirect_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); } action redirect_sfc_and_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }


    table acl {
        key = {
           

            // extreme added



            hdr.nsh_type1.sap : ternary @name("sap");
            ig_md.nsh_type1.flow_class : ternary;
//          length_bitmask                       : ternary;
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

   // extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control IngressIpAcl(
    in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool scope_,
 inout bool hit,
 in bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { ig_md.flags.acl_deny = true; stats.count(); } action permit( ) { ig_md.flags.acl_deny = false; stats.count(); } action drop ( switch_drop_reason_t drop_reason ) { ig_md.flags.acl_deny = true; ig_intr_md_for_dprsr.drop_ctl = 0x1; ig_md.drop_reason_general = drop_reason; stats.count(); } action redirect ( bit<8> flow_class, bool terminate, bool scope ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); }
    action redirect_sfc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }



    action redirect_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); } action redirect_sfc_and_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }


    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_dscp : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

            // extreme added



            hdr.nsh_type1.sap : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
            length_bitmask : ternary;
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

   // extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}

//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control IngressIpv4Acl(
    in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool scope_,
 inout bool hit,
 in bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { ig_md.flags.acl_deny = true; stats.count(); } action permit( ) { ig_md.flags.acl_deny = false; stats.count(); } action drop ( switch_drop_reason_t drop_reason ) { ig_md.flags.acl_deny = true; ig_intr_md_for_dprsr.drop_ctl = 0x1; ig_md.drop_reason_general = drop_reason; stats.count(); } action redirect ( bit<8> flow_class, bool terminate, bool scope ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); }
    action redirect_sfc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }



    action redirect_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); } action redirect_sfc_and_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }


    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_dscp : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



            hdr.nsh_type1.sap : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
            length_bitmask : ternary;
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

   // extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }
        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------



control IngressIpv6Acl(
    in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool scope_,
 inout bool hit,
 in bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { ig_md.flags.acl_deny = true; stats.count(); } action permit( ) { ig_md.flags.acl_deny = false; stats.count(); } action drop ( switch_drop_reason_t drop_reason ) { ig_md.flags.acl_deny = true; ig_intr_md_for_dprsr.drop_ctl = 0x1; ig_md.drop_reason_general = drop_reason; stats.count(); } action redirect ( bit<8> flow_class, bool terminate, bool scope ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); }
    action redirect_sfc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }



    action redirect_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); } action redirect_sfc_and_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }


    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_dscp : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

            // extreme added



            hdr.nsh_type1.sap : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
            length_bitmask : ternary;
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

   // extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}



//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control IngressMacAcl(
    in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout switch_nexthop_t nexthop,

    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool scope_,
 inout bool hit,
 in bit<16> int_control_flags
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { ig_md.flags.acl_deny = true; stats.count(); } action permit( ) { ig_md.flags.acl_deny = false; stats.count(); } action drop ( switch_drop_reason_t drop_reason ) { ig_md.flags.acl_deny = true; ig_intr_md_for_dprsr.drop_ctl = 0x1; ig_md.drop_reason_general = drop_reason; stats.count(); } action redirect ( bit<8> flow_class, bool terminate, bool scope ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); }
    action redirect_sfc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }



    action redirect_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; stats.count(); } action redirect_sfc_and_trunc ( bit<8> flow_class, bool terminate, bool scope, bit<8> sfc, bit<14> truncate_len ) { ig_md.flags.acl_deny = false; ig_md.nsh_type1.flow_class = flow_class; terminate_ = terminate; scope_ = scope; ig_md.nsh_type1.sfc_is_new = true; ig_md.nsh_type1.sfc = sfc; stats.count(); }


    table acl {
        key = {
            lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

            // extreme added



            hdr.nsh_type1.sap : ternary @name("sap");
//          hdr.nsh_type1.flow_class           : ternary @name("flow_class");
//          length_bitmask                     : ternary;
        }

        actions = {
            NoAction_;
//          deny();
            permit();
//          redirect();

   // extreme added
            drop();
            redirect();
            redirect_sfc();
            redirect_trunc();
            redirect_sfc_and_trunc();
//          redirect_decap();
//          redirect_sfc_and_decap();
//          redirect_decap_and_trunc();
//          redirect_sfc_and_decap_and_trunc();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}

// ----------------------------------------------------------------------------
// Ingress Access Control List (ACL)
//
// @param lkp : Lookup fields used for lookups.
// @param ig_md : Ingress metadata.
// @param mac_acl_enable : Add a ACL slice for L2 traffic. If mac_acl_enable is false, IPv4 ACL is
// applied to IPv4 and non-IP traffic.
// @param mac_packet_class_enable : Controls whether MAC ACL applies to all traffic entering the
// interface, including IP traffic, or to non-IP traffic only.
// ----------------------------------------------------------------------------

control IngressAcl(
    inout switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> length_bitmask,
    inout switch_header_transport_t hdr_0,
    inout switch_header_inner_t hdr_2,
 in bit<16> int_ctrl_flags
) (



    switch_uint32_t ipv4_table_size=512,
    switch_uint32_t ipv6_table_size=512,

    switch_uint32_t mac_table_size=512,
    switch_uint32_t l7_table_size=512
) {

 // ---------------------------------------------------




    IngressIpv4Acl(ipv4_table_size) ipv4_acl;
    IngressIpv6Acl(ipv6_table_size) ipv6_acl;

    IngressMacAcl(mac_table_size) mac_acl;




    switch_nexthop_t nexthop;
 bool terminate;
    bool scope;
 bool hit;

    // -------------------------------------
    // Table: Scope Increment
    // -------------------------------------
/*
    action new_scope(bit<8> scope_new) {
        hdr_0.nsh_type1.scope = scope_new;
    }

    table scope_inc {
        key = {
            hdr_0.nsh_type1.scope : exact;
        }
        actions = {
            new_scope;
        }
        const entries = {
            0  : new_scope(1);
            1  : new_scope(2);
            2  : new_scope(3);
        }
    }
*/
 // ---------------------------------------------------

    apply {
        ig_md.flags.acl_deny = false;
        nexthop = 0;
        terminate = false;
        scope = false;
  hit = false;

  // ----- l7 -----




  // ----- l3/4 -----
  if(hit == false) {





         if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

             ipv6_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);

         } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
             ipv4_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
         }

  }

  // ----- l2 -----
  if(hit == false) {
         mac_acl.apply(lkp, hdr_0, ig_md, ig_intr_md_for_dprsr, nexthop, length_bitmask, terminate, scope, hit, int_ctrl_flags);
  }

  // --------------

  // note: terminate + !scope is an illegal condition
  if(terminate == true) {
      ig_md.tunnel_1.terminate = true;
   if(hdr_0.nsh_type1.scope == 1) {
       ig_md.tunnel_2.terminate = true;
   }
  }

  if(scope == true) {
      vlan_tag_h vlan_tag_dummy;

   if(hdr_0.nsh_type1.scope == 0) {
          Scoper.apply(
              hdr_2.ethernet,
              hdr_2.vlan_tag[0],
              false, // inner only has 1 vlan...set the valid false
              hdr_2.vlan_tag[0], // inner only has 1 vlan...send in anything that will compile
//		            vlan_tag_dummy,    // inner only has 1 vlan...send in anything that will compile
              hdr_2.ipv4,

              hdr_2.ipv6.isValid(),
              hdr_2.ipv6,

              hdr_2.tcp.isValid(),
              hdr_2.tcp,
              hdr_2.udp,
              hdr_2.sctp,
              ig_md.tunnel_2.type,
              ig_md.tunnel_2.id,
     ig_md.drop_reason_2,

              ig_md.lkp
          );
   }

   hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//			scope_inc.apply();
  }
    }
}

// ============================================================================
// ============================================================================
// Egress ACL =================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control EgressMacAcl(
    in switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool hit
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { eg_md.flags.acl_deny = true; stats.count(); } action permit( ) { eg_md.flags.acl_deny = false; stats.count(); } action drop( ) { eg_md.flags.acl_deny = true; eg_intr_md_for_dprsr.drop_ctl = 0x1; stats.count(); } action redirect( bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bool truncate, bit<14> truncate_len ) { eg_md.flags.acl_deny = false; terminate_ = terminate; eg_md.nsh_type1.strip_e_tag = strip_tag_e; eg_md.nsh_type1.strip_vn_tag = strip_tag_vn; eg_md.nsh_type1.strip_vlan_tag = strip_tag_vlan; eg_md.nsh_type1.truncate = truncate; eg_md.nsh_type1.truncate_len = truncate_len; stats.count(); }

    table acl {
        key = {
//          hdr.ethernet.src_addr : ternary;
//          hdr.ethernet.dst_addr : ternary;
//          hdr.ethernet.ether_type : ternary;




   // extreme added
   eg_md.nsh_type1.dsap : ternary @name("dsap");
//			length_bitmask          : ternary;


   eg_md.nsh_type1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.nsh_type1.tunnel_inner_type : ternary @name("tunnel_inner_type");

        }

        actions = {
            NoAction_;
//          deny();
            permit();

            drop();
            redirect();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}

//-----------------------------------------------------------------------------
// IP ACL
//-----------------------------------------------------------------------------

control EgressIpAcl(
    in switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool hit
)(
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { eg_md.flags.acl_deny = true; stats.count(); } action permit( ) { eg_md.flags.acl_deny = false; stats.count(); } action drop( ) { eg_md.flags.acl_deny = true; eg_intr_md_for_dprsr.drop_ctl = 0x1; stats.count(); } action redirect( bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bool truncate, bit<14> truncate_len ) { eg_md.flags.acl_deny = false; terminate_ = terminate; eg_md.nsh_type1.strip_e_tag = strip_tag_e; eg_md.nsh_type1.strip_vn_tag = strip_tag_vn; eg_md.nsh_type1.strip_vlan_tag = strip_tag_vlan; eg_md.nsh_type1.truncate = truncate; eg_md.nsh_type1.truncate_len = truncate_len; stats.count(); }

    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_dscp : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added
   eg_md.nsh_type1.dsap : ternary @name("dsap");
   length_bitmask : ternary;


   eg_md.nsh_type1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.nsh_type1.tunnel_inner_type : ternary @name("tunnel_inner_type");

        }

        actions = {
            NoAction_;
//          deny();
            permit();

            drop();
            redirect();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}
//-----------------------------------------------------------------------------
// IPv4 ACL
//-----------------------------------------------------------------------------

control EgressIpv4Acl(
    in switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool hit
) (
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { eg_md.flags.acl_deny = true; stats.count(); } action permit( ) { eg_md.flags.acl_deny = false; stats.count(); } action drop( ) { eg_md.flags.acl_deny = true; eg_intr_md_for_dprsr.drop_ctl = 0x1; stats.count(); } action redirect( bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bool truncate, bit<14> truncate_len ) { eg_md.flags.acl_deny = false; terminate_ = terminate; eg_md.nsh_type1.strip_e_tag = strip_tag_e; eg_md.nsh_type1.strip_vn_tag = strip_tag_vn; eg_md.nsh_type1.strip_vlan_tag = strip_tag_vlan; eg_md.nsh_type1.truncate = truncate; eg_md.nsh_type1.truncate_len = truncate_len; stats.count(); }

    table acl {
        key = {
            lkp.ip_src_addr[31:0] : ternary; lkp.ip_dst_addr[31:0] : ternary; lkp.ip_proto : ternary; lkp.ip_dscp : ternary; lkp.tcp_flags : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;
//          hdr.ethernet.ether_type : ternary;

   // extreme added
   eg_md.nsh_type1.dsap : ternary @name("dsap");
   length_bitmask : ternary;


   eg_md.nsh_type1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.nsh_type1.tunnel_inner_type : ternary @name("tunnel_inner_type");

        }

        actions = {
            NoAction_;
//          deny();
            permit();
            drop();
            redirect();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}

//-----------------------------------------------------------------------------
// IPv6 ACL
//-----------------------------------------------------------------------------



control EgressIpv6Acl(
    in switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in bit<16> length_bitmask,
 inout bool terminate_,
 inout bool hit
)(
    switch_uint32_t table_size=512
) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action NoAction_() { stats.count(); } action deny( ) { eg_md.flags.acl_deny = true; stats.count(); } action permit( ) { eg_md.flags.acl_deny = false; stats.count(); } action drop( ) { eg_md.flags.acl_deny = true; eg_intr_md_for_dprsr.drop_ctl = 0x1; stats.count(); } action redirect( bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bool truncate, bit<14> truncate_len ) { eg_md.flags.acl_deny = false; terminate_ = terminate; eg_md.nsh_type1.strip_e_tag = strip_tag_e; eg_md.nsh_type1.strip_vn_tag = strip_tag_vn; eg_md.nsh_type1.strip_vlan_tag = strip_tag_vlan; eg_md.nsh_type1.truncate = truncate; eg_md.nsh_type1.truncate_len = truncate_len; stats.count(); }

    table acl {
        key = {
            lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_dscp : ternary; lkp.tcp_flags : ternary; lkp.l4_src_port : ternary; lkp.l4_dst_port : ternary; lkp.tunnel_type : ternary; lkp.drop_reason : ternary;

   // extreme added
   eg_md.nsh_type1.dsap : ternary @name("dsap");
   length_bitmask : ternary;


   eg_md.nsh_type1.tunnel_outer_type : ternary @name("tunnel_outer_type");
   eg_md.nsh_type1.tunnel_inner_type : ternary @name("tunnel_inner_type");

        }

        actions = {
            NoAction_;
//          deny();
            permit();

            drop();
            redirect();
        }

        const default_action = NoAction_;
  counters = stats;
        size = table_size;
    }

    apply {
        if(acl.apply().hit) {
   hit = true;
  }
    }
}



//-----------------------------------------------------------------------------

control EgressAcl(
    in switch_lookup_fields_t lkp,
    inout switch_egress_metadata_t eg_md,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in bit<16> length_bitmask,
    inout switch_header_transport_t hdr_0
) (



    switch_uint32_t ipv4_table_size=512,
    switch_uint32_t ipv6_table_size=512,

    switch_uint32_t mac_table_size=512
) {

 // ---------------------------------------------------




    EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;
    EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;





 bool terminate;
 bool hit;

 // ---------------------------------------------------

    apply {
        eg_md.flags.acl_deny = false;
        terminate = false;
  hit = false;

  // ----- l3/4 -----





        if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

            egress_ipv6_acl.apply(lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask, terminate, hit);

        } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
            egress_ipv4_acl.apply(lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask, terminate, hit);
        }


  // ----- l2 -----
  if(hit == false) {



  }

  // --------------

  // note: terminate + !scope is an illegal condition
  if(terminate == true) {
      eg_md.tunnel_1.terminate = true;
   if(hdr_0.nsh_type1.scope == 1) {
       eg_md.tunnel_2.terminate = true;
   }
  }

  // note: don't need to adjust scope here, as nobody else looks at the data after this.
    }
}
# 24 "l3.p4" 2
# 1 "l2.p4" 1
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
 ******************************************************************************/




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
control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
    in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {

    action dmac_miss() {
        ig_md.egress_port_lag_index = SWITCH_FLOOD;
        ig_md.flags.dmac_miss = true;
    }

    action dmac_hit(switch_port_lag_index_t port_lag_index) {
        ig_md.egress_port_lag_index = port_lag_index;

    }

    action dmac_multicast(switch_mgid_t index) {
        ig_md.multicast.id = index;
    }

    action dmac_redirect(switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
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
        }

        const default_action = dmac_miss;
        size = table_size;
    }

    apply {
        ig_md.flags.dmac_miss = false;

        dmac.apply();
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

        // 3 entries per bridge domain for unicast/broadcast/multicast packets.
        size = 3 * table_size;
        counters = stats;
    }

    apply {
        bd_stats.apply();
    }
}

control EgressBd(in switch_header_transport_t hdr,
                 in switch_bd_t bd,

                 in switch_pkt_src_t pkt_src,

                 out switch_smac_index_t smac_idx
)(
                 switch_uint32_t table_size) {
/*
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

    action count() {
        stats.count();
    }

    table bd_stats {
        key = {
            bd : exact;
//          pkt_type : exact;
        }

        actions = {
            count;
            @defaultonly NoAction;
        }

        size = 3 * table_size;
        counters = stats;
    }
*/
    action set_bd_properties(
  switch_smac_index_t smac_index
    ) {

        smac_idx = smac_index;

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
//      if (pkt_src == SWITCH_PKT_SRC_BRIDGED)
//          bd_stats.apply();
    }
}

//-----------------------------------------------------------------------------
// VLAN tag decapsulation
// Removes the vlan tag by default or selectively based on the ingress port if QINQ_ENABLE flag
// is defined.
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param port : Ingress port.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanDecap(inout switch_header_transport_t hdr, in switch_egress_metadata_t eg_md) {

    // ---------------------
    // Apply
    // ---------------------

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
// @param eg_md : Egress metadata fields.
// @flag QINQ_ENABLE
//-----------------------------------------------------------------------------
control VlanXlate(inout switch_header_transport_t hdr,
                  in switch_egress_metadata_t eg_md)(
                  switch_uint32_t bd_table_size,
                  switch_uint32_t port_bd_table_size) {
    action set_vlan_untagged() {
        //NoAction.
    }
# 226 "l2.p4"
    action set_vlan_tagged(vlan_id_t vid) {



        hdr.vlan_tag[0].setValid();
        hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
//      hdr.vlan_tag[0].pcp = eg_md.lkp.pcp;
        hdr.vlan_tag[0].cfi = 0;
        hdr.vlan_tag[0].vid = vid;
        hdr.ethernet.ether_type = 0x8100;
    }

    table port_bd_to_vlan_mapping {
        key = {
            eg_md.port_lag_index : exact @name("port_lag_index");
            eg_md.bd : exact @name("bd");
        }

        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = port_bd_table_size;
        //TODO : fix table size once scale requirements for double tag is known
    }

    table bd_to_vlan_mapping {
        key = { eg_md.bd : exact @name("bd"); }
        actions = {
            set_vlan_untagged;
            set_vlan_tagged;
        }

        const default_action = set_vlan_untagged;
        size = bd_table_size;
    }
# 293 "l2.p4"
    apply {

            if (!port_bd_to_vlan_mapping.apply().hit) {
                bd_to_vlan_mapping.apply();
            }
        }




}

//-----------------------------------------------------------------------------
// NSH Fixer
//
// After the packet has been reframed, and new vlan tags have been inserted /
// removed, fix up the type fields if the packet is going out with an nsh.
//-----------------------------------------------------------------------------

control NSHTypeFixer(
 inout switch_header_transport_t hdr
) (
) {

    // ---------------------
    // Table: Look at what header(s) come *before* the nsh header....
    // ---------------------

 action set_type_0tag() {
  hdr.ethernet.ether_type = 0x894F;
 }

 action set_type_1tag() {
  hdr.vlan_tag[0].ether_type = 0x894F;
 }

    table set_ether_type {
        key = {
   hdr.nsh_type1.isValid() : exact;

            hdr.vlan_tag[0].isValid() : exact;
        }

        actions = {
            NoAction;
            set_type_0tag;
            set_type_1tag;
        }

        const default_action = NoAction;
        const entries = {
            (true, false) : set_type_0tag();
            (true, true ) : set_type_1tag();
        }
    }

    // ---------------------
    // Table: Look at what header comes *after* the nsh header....
    // ---------------------

// commenting out to help with fitting, hardcoding instead....
/*
	action set_type_eth() {
		hdr.nsh_type1.next_proto    = 0x3; // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.
	}

    // nsh followed by ipv4 not supported
	// action set_type_v4() {
	// 	hdr.nsh_type1.next_proto    = 0x1; // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.
	// }

    table set_nsh_type {
        key = {
			hdr.nsh_type1.isValid()    : exact; // don't need this, as it doesn't matter if it's valid or not....
            //hdr.ipv4.isValid()        : exact;  // nsh followed by ipv4 not supported
        }

        actions = {
            NoAction;
            set_type_eth;
            //set_type_v4;
        }

        const default_action = NoAction;
        const entries = {
            (true) : set_type_eth();
            //(false) : set_type_eth();
            //(true ) : set_type_v4();
        }
    }
*/

    // ---------------------
    // Apply
    // ---------------------

    apply {
  set_ether_type.apply();

// commenting out to help with fitting, hardcoding instead....
//		set_nsh_type.apply();
  hdr.nsh_type1.next_proto = 0x3; // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.
 }

}
# 25 "l3.p4" 2

control IngressUnicast(
 in switch_header_transport_t hdr,
    inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t rmac_table_size = 1024
) {

    //-----------------------------------------------------------------------------
    // Router MAC lookup
    // key: destination MAC address.
    // - Route the packet if the destination MAC address is owned by the switch.
    //-----------------------------------------------------------------------------
/*
    action rmac_hit() {
        ig_md.flags.rmac_hit = true;
    }

    action rmac_miss() {
        ig_md.flags.rmac_hit = false;
    }

    table rmac {
        key = {
            hdr.ethernet.dst_addr : exact;
        }

        actions = {
            rmac_hit;
            @defaultonly rmac_miss;
        }

        const default_action = rmac_miss;
        size = rmac_table_size;
    }
*/
 //-----------------------------------------------------------------------------
 // Apply
 //-----------------------------------------------------------------------------

    apply {
//		rmac.apply();
    }
}
# 38 "npb.p4" 2
# 1 "nexthop.p4" 1
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
 ******************************************************************************/

// ----------------------------------------------------------------------------
// Nexthop/ECMP resolution
//
// @param lkp : Lookup fields used for hash calculation.
// @param ig_md : Ingress metadata fields
// @param hash : Hash value used for ECMP selection.
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_lookup_fields_t lkp,
                inout switch_ingress_metadata_t ig_md,
                in bit<16> hash)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_table_size,
                switch_uint32_t ecmp_selection_table_size) {
/*
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(
        ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;
*/
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd) {
        ig_md.egress_port_lag_index = port_lag_index;

    }

    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid) {
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }

    action set_nexthop_properties_glean() {
        ig_md.flags.glean = true;
    }

    action set_nexthop_properties_drop() {
        ig_md.drop_reason_general = SWITCH_DROP_REASON_NEXTHOP;
    }

    action set_ecmp_properties(switch_port_lag_index_t port_lag_index,
                               switch_bd_t bd,
                               switch_nexthop_t nexthop_index) {
        ig_md.nexthop = nexthop_index;
        set_nexthop_properties(port_lag_index, bd);
    }

    action set_ecmp_properties_drop() {
        set_nexthop_properties_drop();
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
        ig_md.tunnel_0.index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
    }
/*
    table ecmp {
        key = {
            ig_md.nexthop : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_ecmp_properties;
            set_ecmp_properties_drop;
            set_ecmp_properties_glean;
            set_ecmp_properties_post_routed_flood;
            set_tunnel_properties;
        }

        const default_action = NoAction;
        size = ecmp_table_size;
        implementation = ecmp_selector;
    }
*/




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
//          NoAction : { ecmp.apply(); }
            default : {}
        }



    }
}

// ----------------------------------------------------------------------------
// OuterFib (aka Outer Nexthop)
// ----------------------------------------------------------------------------

control OuterFib(inout switch_ingress_metadata_t ig_md,
                     in bit<16> hash)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {
//  Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
//  ActionSelector(ecmp_selection_table_size, selector_hash, SelectorMode_t.FAIR) ecmp_selector;

    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_outer_nexthop_t nexthop_index) {
        ig_md.outer_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table fib {
        key = {
            ig_md.tunnel_0.index : exact;
            hash : selector;
        }

        actions = {
            NoAction;
            set_nexthop_properties;
        }

        const default_action = NoAction;
//      implementation = ecmp_selector;
        size = fib_table_size;
    }

    apply {

        fib.apply();

    }
}
# 39 "npb.p4" 2

# 1 "npb_ing_parser.p4" 1



parser NpbIngressParser(
        packet_in pkt,
        out switch_header_t hdr,
        out switch_ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;
    //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) inner_ipv4_checksum;
    //Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) ipv4_checksum;
    //Checksum<bit<16>>(ChecksumAlgorithm_t.CSUM16) inner_ipv4_checksum;
    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    value_set<bit<16>>(1) udp_port_vxlan;

 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;
        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp;
        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }
        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
        // Parse port metadata produced by ibuf
        switch_port_metadata_t port_md = port_metadata_unpack<switch_port_metadata_t>(pkt);
        ig_md.port_lag_index = port_md.port_lag_index;
//      ig_md.ifindex = port_md.ifindex;
        //transition parse_ethernet;
        transition snoop_head;
    }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Tofino1: NSH support only (no ERSPAN or GRE)
    // Tofino2: NSH, ERSPAN, GRE support


// #if __TARGET_TOFINO__ == 1
// 
//     ///////////////////////////////////////////////////////////////////////////
//     // Tofino1
//     ///////////////////////////////////////////////////////////////////////////
// 
//     // Snoop ahead here to try and determine if there's a transport present
//     state snoop_head {
//         // Pre-setting to snoop header is broken - see BF-case 9245
//         //ethernet_tagged_h snoop = pkt.lookahead<ethernet_tagged_h>();
//         //transition select(snoop.ether_type, snoop.ether_type_tag) {
//         transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<144>>()[15:0]) {
//             (ETHERTYPE_NSH, _): parse_transport_nsh;
//             (ETHERTYPE_VLAN, ETHERTYPE_NSH): parse_transport_nsh_tagged;
//             default: parse_outer_ethernet;
//         }
//     }
// 
//     //-------------------------------------------------------------------------
//     // NSH - Transport
//     //-------------------------------------------------------------------------
// 
//     state parse_transport_nsh {
//         pkt.extract(hdr.transport.ethernet);
// 	    pkt.extract(hdr.transport.nsh_type1);
//         ig_md.tunnel_0.type = SWITCH_TUNNEL_TYPE_NSH;
//         transition parse_outer_ethernet;
//     }
// 
//     state parse_transport_nsh_tagged {
//         pkt.extract(hdr.transport.ethernet);
//         pkt.extract(hdr.transport.vlan_tag.next);
// 	    pkt.extract(hdr.transport.nsh_type1);
//         ig_md.tunnel_0.type = SWITCH_TUNNEL_TYPE_NSH;
//         transition parse_outer_ethernet;
//     }
// 
// #else /* __TARGET_TOFINO__ == 1 */


    // Snoop ahead here to try and determine if there's a transport present
    state snoop_head {
        // transition select(
        //             pkt.lookahead<bit<112>>()[15:0],   // pkt.lookahead<head_snoop_h>().enet_ether_type;
        //             pkt.lookahead<bit<144>>()[15:0],   // pkt.lookahead<head_snoop_h>().vlan_ether_type;
        //             pkt.lookahead<bit<224>>()[7:0]) {  // pkt.lookahead<head_snoop_h>().ipv4_protocol;
        // 
        //     (ETHERTYPE_NSH , _            , _): parse_transport_nsh;
        //     (ETHERTYPE_VLAN, ETHERTYPE_NSH, _): parse_transport_nsh_tagged;
        //     default: parse_outer_ethernet;
        // }

        // tofino1 snoop
        transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<144>>()[15:0]) {
            (0x894F, _): parse_transport_nsh;
            (0x8100, 0x894F): parse_transport_nsh_tagged;
            default: parse_outer_ethernet;
        }
    }

    //-------------------------------------------------------------------------
    // NSH - Transport
    //-------------------------------------------------------------------------

    state parse_transport_nsh {
        pkt.extract(hdr.transport.ethernet);
     pkt.extract(hdr.transport.nsh_type1);
        ig_md.tunnel_0.type = SWITCH_TUNNEL_TYPE_NSH;
        transition parse_outer_ethernet;
    }

    state parse_transport_nsh_tagged {
        pkt.extract(hdr.transport.ethernet);
        pkt.extract(hdr.transport.vlan_tag.next);
     pkt.extract(hdr.transport.nsh_type1);
        ig_md.tunnel_0.type = SWITCH_TUNNEL_TYPE_NSH;
        transition parse_outer_ethernet;
    }

// #endif /* __TARGET_TOFINO__ == 1 */



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    // Barefoot compiler doesn't allow us to set the same variable (or header)
    // more than once in Tofino1. Doing so causes a wire-OR instead of
    // clear-on-write. Because of this limitation, we're unable to use a
    // fanout/branch state at layer2.

    // We can still employ a fanout/branch state for e-tags and vn-tags, since
    // the two headers are mutually exclusive.

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);
        transition select(hdr.outer.ethernet.ether_type) {
            0x893F : parse_outer_br;
            0x8926 : parse_outer_vn;
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }

    state parse_outer_br {
     pkt.extract(hdr.outer.e_tag);
        ether_type = hdr.outer.e_tag.ether_type;
        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;
            default : branch_outer_ether_type;
        }
    }

    state parse_outer_vn {
     pkt.extract(hdr.outer.vn_tag);
        ether_type = hdr.outer.vn_tag.ether_type;
        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;
            default : branch_outer_ether_type;
        }
    }

    state parse_outer_vlan {
     pkt.extract(hdr.outer.vlan_tag.next);
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_ether_type {
        transition select(ether_type) {



            0x0800 : parse_outer_ipv4;
            0x0806 : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_arp {
        pkt.extract(hdr.outer.arp);
        transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);
        protocol = hdr.outer.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        ipv4_checksum.add(hdr.outer.ipv4);
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.flags, hdr.outer.ipv4.frag_offset) {
            (5, 3w2 &&& 3w5, 0): parse_outer_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_outer_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum.verify();
        transition select(hdr.outer.ipv4.protocol) {
            1: parse_outer_icmp;
            2: parse_outer_igmp;
            default: branch_outer_l3_protocol;
        }
    }

    state parse_outer_ipv6 {

        pkt.extract(hdr.outer.ipv6);
        protocol = hdr.outer.ipv6.next_hdr;
        transition select(hdr.outer.ipv6.next_hdr) {
            58: parse_outer_icmp;
            default: branch_outer_l3_protocol;
        }



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol {
        transition select(protocol) {
           4: parse_outer_ipinip;
           41: parse_outer_ipv6inip;
           17: parse_outer_udp;
           6: parse_outer_tcp;
           0x84: parse_outer_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.
           0x32: parse_outer_esp;
           47: parse_outer_gre;
           default : accept;
       }
    }

    state parse_outer_icmp {
        pkt.extract(hdr.outer.icmp);
        transition accept;
    }

    state parse_outer_igmp {
        pkt.extract(hdr.outer.igmp);
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp {
        pkt.extract(hdr.outer.udp);
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {
            (_, 4789): parse_outer_vxlan;

            (_, 2123): parse_outer_gtp_c;
            (2123, _): parse_outer_gtp_c;
            (_, 2152): parse_outer_gtp_u;
            (2152, _): parse_outer_gtp_u;

            default : parse_layer7_udf;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp {
        pkt.extract(hdr.outer.tcp);
        transition parse_layer7_udf;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp {
        pkt.extract(hdr.outer.sctp);
        transition parse_layer7_udf;
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
# 371 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan {

        pkt.extract(hdr.outer.vxlan);
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.tunnel_1.id = hdr.outer.vxlan.vni;
        transition parse_inner_ethernet;



    }


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip {

        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv4;



    }

    state parse_outer_ipv6inip {
//#if defined(IPINIP) && defined(IPV6_TUNNEL_ENABLE)

        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_IPINIP;
        transition parse_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    // todo: validation - make sure R, s, recurse and flags are zero.
    //       see rfc 2784, and 2890
    state parse_outer_gre {
     pkt.extract(hdr.outer.gre);
//      ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GRE;
        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.version,
            hdr.outer.gre.proto) {

            (0,1,0,0,0x6558): parse_outer_nvgre;



            (0,0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0,0x86dd): parse_inner_ipv6;
// #ifdef ERSPAN_TRANSPORT_ENABLE
//             (0,0,0,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t1_transport;
//             (0,0,1,0,GRE_PROTOCOLS_ERSPAN_TYPE_2): parse_erspan_t2_transport;
//             //(0,0,1,0,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_erspan_t3_transport;
// #endif /* ERSPAN_TRANSPORT_ENABLE */
            default: accept;
        }
    }

    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
     pkt.extract(hdr.outer.nvgre);
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_NVGRE;
  ig_md.tunnel_1.id = hdr.outer.nvgre.vsid;
     transition parse_inner_ethernet;
    }

    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_esp {
        pkt.extract(hdr.outer.esp);
        transition accept;
    }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------

    // state parse_outer_gtp_c {
    //     pkt.extract(hdr.outer.gtp_v2_base);
    //     transition select(hdr.outer.gtp_v2_base.version, hdr.outer.gtp_v2_base.T) {
    //         (2, 1): parse_outer_gtp_c_tied;
    //         default: accept;
    //     }
    // }
    // 
    // state parse_outer_gtp_c_teid {
    //     pkt.extract(hdr.outer.teid);
    // 	transition accept;
    // }

    state parse_outer_gtp_c {
        gtp_v2_base_h snoop_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        transition select(snoop_gtp_v2_base.version, snoop_gtp_v2_base.T) {
            (2, 1): extract_outer_gtp_c;
            default: accept;
        }
    }

    state extract_outer_gtp_c {
        pkt.extract(hdr.outer.gtp_v2_base);
        pkt.extract(hdr.outer.gtp_v1_v2_teid);
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GTPC; // extreme added
//      ig_md.tunnel_1.id = hdr.outer.gtp_v1_v2_teid.teid; // extreme added
     transition accept;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Does not support parsing GTP v1 optional word
    // Does not support parsing (TLV) extension headers

    // state parse_outer_gtp_u {
    //     pkt.extract(hdr.outer.gtp_v1_base);
    //     transition select(
    //         hdr.outer.gtp_v1_base.version,
    //         hdr.outer.gtp_v1_base.PT,
    //         hdr.outer.gtp_v1_base.E,
    //         hdr.outer.gtp_v1_base.S,
    //         hdr.outer.gtp_v1_base.PN
    //         pkt.lookahead<bit<4>>()) {
    // 
    //         (1, 1, 0, 0, 0, 4): parse_inner_ipv4;
    //         (1, 1, 0, 0, 0, 6): parse_inner_ipv6;
    //         default: accept;
    //     }
    // }

    state parse_outer_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): extract_outer_gtp_u;
            default: accept;
        }
    }

    state extract_outer_gtp_u {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_v2_teid);
        ig_md.tunnel_1.type = SWITCH_TUNNEL_TYPE_GTPU; // extreme added
//      ig_md.tunnel_1.id = hdr.outer.gtp_v1_v2_teid.teid; // extreme added
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }




    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer 2 (ETH-T) - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_ethernet {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {



            0x8100 : parse_inner_vlan;
            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {



            0x0800 : parse_inner_ipv4;
            0x86dd : parse_inner_ipv6;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 2.5 - Inner
    ///////////////////////////////////////////////////////////////////////////
# 604 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
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
        pkt.extract(hdr.inner.ipv4);
        inner_protocol = hdr.inner.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        inner_ipv4_checksum.add(hdr.inner.ipv4);
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.flags,
            hdr.inner.ipv4.frag_offset) {
            //(5, 0, 0): parse_inner_ipv4_no_options_frags;
            //(5, 2, 0): parse_inner_ipv4_no_options_frags;
            (5, 3w2 &&& 3w5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        ig_md.flags.ipv4_checksum_err_2 = inner_ipv4_checksum.verify();
        transition select(hdr.inner.ipv4.protocol) {




            default: branch_inner_l3_protocol;
        }
    }

    state parse_inner_ipv6 {

        pkt.extract(hdr.inner.ipv6);
        inner_protocol = hdr.inner.ipv6.next_hdr;
        transition select(hdr.inner.ipv6.next_hdr) {



            default: branch_inner_l3_protocol;
        }



    }

    // shared fanout/branch state to save tcam resource
    state branch_inner_l3_protocol {
        transition select(inner_protocol) {
           17: parse_inner_udp;
           6: parse_inner_tcp;
           0x84: parse_inner_sctp;
           // todo: encap doc shows no v6 branch for esp.
           // if true, we need to move this up into v4 state.




           47: parse_inner_gre;

           default : accept;
       }
    }
# 689 "npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_udp {
        pkt.extract(hdr.inner.udp);
        transition parse_layer7_udf;
    }

    state parse_inner_tcp {
        pkt.extract(hdr.inner.tcp);
        transition parse_layer7_udf;
    }

    state parse_inner_sctp {
        pkt.extract(hdr.inner.sctp);
        transition parse_layer7_udf;
    }


    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////
# 722 "npb_ing_parser.p4"
    // todo: do we need to parse this? extract?
    state parse_inner_gre {
        pkt.extract(hdr.inner.gre);
        ig_md.tunnel_2.type = SWITCH_TUNNEL_TYPE_GRE;
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 7 - UDF
    ///////////////////////////////////////////////////////////////////////////

    state parse_layer7_udf {




        transition accept;
    }

}
# 41 "npb.p4" 2
# 1 "npb_ing_deparser.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
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
 ******************************************************************************/

# 1 "headers.p4" 1
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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "npb_ing_deparser.p4" 2
# 1 "types.p4" 1
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
 ******************************************************************************/
# 23 "npb_ing_deparser.p4" 2

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------
control SwitchIngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** TRANSPORT *****
        pkt.emit(hdr.transport.ethernet);
        pkt.emit(hdr.transport.vlan_tag);
        pkt.emit(hdr.transport.nsh_type1);
# 52 "npb_ing_deparser.p4"
        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);
        pkt.emit(hdr.outer.e_tag);
        pkt.emit(hdr.outer.vn_tag);
        pkt.emit(hdr.outer.vlan_tag);
        pkt.emit(hdr.outer.arp); // Ingress only.
        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.nvgre);
        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.sctp);
        pkt.emit(hdr.outer.esp);
        pkt.emit(hdr.outer.tcp); // Ingress only.
        pkt.emit(hdr.outer.icmp); // Ingress only.
        pkt.emit(hdr.outer.igmp); // Ingress only.
        pkt.emit(hdr.outer.vxlan);

        pkt.emit(hdr.outer.gtp_v1_base);
        pkt.emit(hdr.outer.gtp_v2_base);
        pkt.emit(hdr.outer.gtp_v1_v2_teid);
        pkt.emit(hdr.outer.gtp_v1_optional);







        // ***** INNER *****
        pkt.emit(hdr.inner.ethernet);
        pkt.emit(hdr.inner.vlan_tag);
        pkt.emit(hdr.inner.ipv4);

        pkt.emit(hdr.inner.ipv6);

        pkt.emit(hdr.inner.udp);
        pkt.emit(hdr.inner.tcp);
        pkt.emit(hdr.inner.sctp);


        pkt.emit(hdr.inner.gre);
# 108 "npb_ing_deparser.p4"
    }
}
# 42 "npb.p4" 2






# 1 "npb_egr_parser_B.p4" 1



parser NpbEgressParser(
        packet_in pkt,
        out switch_header_egress_t hdr,
        out switch_egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

 bit<16> ether_type;
 bit<16> inner_ether_type;
 bit<8> protocol;
 bit<8> inner_protocol;






    value_set<bit<16>>(1) udp_port_vxlan;

    state start {
        pkt.extract(eg_intr_md);
        eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.port = eg_intr_md.egress_port;







        transition parse_bridged_pkt;

    }

    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;
        eg_md.port_lag_index = hdr.bridged_md.base.ingress_port_lag_index;
        eg_md.bd = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type = hdr.bridged_md.base.pkt_type;
//      eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
        eg_md.flags.rmac_hit = hdr.bridged_md.base.rmac_hit;
# 55 "npb_egr_parser_B.p4"
        eg_md.outer_nexthop = hdr.bridged_md.tunnel.outer_nexthop;
        eg_md.tunnel_0.index = hdr.bridged_md.tunnel.index;
        eg_md.tunnel_0.hash = hdr.bridged_md.tunnel.hash;

        eg_md.tunnel_0.terminate = hdr.bridged_md.tunnel.terminate_0;
        eg_md.tunnel_1.terminate = hdr.bridged_md.tunnel.terminate_1;
        eg_md.tunnel_2.terminate = hdr.bridged_md.tunnel.terminate_2;
  eg_md.nsh_terminate = hdr.bridged_md.tunnel.nsh_terminate;


  // ---------------
  // nsh meta data
  // ---------------
        eg_md.nsh_type1.hdr_is_new = hdr.bridged_md.base.nsh_type1_hdr_is_new;

        eg_md.nsh_type1.sf_bitmask = hdr.bridged_md.base.nsh_type1_sf_bitmask; //  1 byte

  // ---------------
  // dedup stuff
  // ---------------





        // scoped lookup structure
        //eg_md.lkp = hdr.bridged_md.lkp;
        eg_md.lkp.mac_src_addr = hdr.bridged_md.lkp.mac_src_addr;
        eg_md.lkp.mac_dst_addr = hdr.bridged_md.lkp.mac_dst_addr;
        eg_md.lkp.mac_type = hdr.bridged_md.lkp.mac_type ;
        eg_md.lkp.pcp = hdr.bridged_md.lkp.pcp ;
        eg_md.lkp.ip_type = hdr.bridged_md.lkp.ip_type ;
        eg_md.lkp.ip_proto = hdr.bridged_md.lkp.ip_proto ;
        eg_md.lkp.ip_dscp = hdr.bridged_md.lkp.ip_dscp ;




        eg_md.lkp.ip_len = hdr.bridged_md.lkp.ip_len ;
        eg_md.lkp.tcp_flags = hdr.bridged_md.lkp.tcp_flags ;
        eg_md.lkp.l4_src_port = hdr.bridged_md.lkp.l4_src_port ;
        eg_md.lkp.l4_dst_port = hdr.bridged_md.lkp.l4_dst_port ;
        eg_md.lkp.tunnel_type = hdr.bridged_md.lkp.tunnel_type ;
        eg_md.lkp.tunnel_id = hdr.bridged_md.lkp.tunnel_id ;
        eg_md.lkp.drop_reason = hdr.bridged_md.lkp.drop_reason ;

        // -----------------------------

        transition snoop_head;
        // transition select(eg_md.orig_pkt_had_nsh) {
        //     0: parse_outer_ethernet;
        //     1: parse_transport_ethernet;
        // }
    }


    // Snoop ahead here to try and determine if there's a transport present
    state snoop_head {
        transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<144>>()[15:0]) {
            (0x894F, _): parse_transport_ethernet;
            (0x8100, 0x894F): parse_transport_ethernet;
            default: parse_outer_ethernet;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Transport Layer 2 (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // NSH
    ///////////////////////////////////////////////////////////////////////////

    state parse_transport_ethernet {
        pkt.extract(hdr.transport.ethernet);
        transition select(hdr.transport.ethernet.ether_type) {
            0x8100: parse_transport_vlan;
            default: parse_transport_nsh;
        }
    }

    state parse_transport_vlan {
        pkt.extract(hdr.transport.vlan_tag[0]);
        transition parse_transport_nsh;
    }

    state parse_transport_nsh {
     pkt.extract(hdr.transport.nsh_type1);
        transition parse_outer_ethernet;
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);
        transition select(hdr.outer.ethernet.ether_type) {
            0x893F: parse_outer_br;
            0x8926: parse_outer_vn;
            0x8100: parse_outer_vlan;
            0x88A8: parse_outer_vlan;
            default: parse_outer_opaque_fanout;
        }
    }

    state parse_outer_br {
     pkt.extract(hdr.outer.e_tag);
        ether_type = hdr.outer.e_tag.ether_type;
        transition select(hdr.outer.e_tag.ether_type) {
            0x8100: parse_outer_vlan;
            0x88A8: parse_outer_vlan;
            default: parse_outer_opaque_fanout;
        }
    }

    state parse_outer_vn {
     pkt.extract(hdr.outer.vn_tag);
        ether_type = hdr.outer.vn_tag.ether_type;
        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100: parse_outer_vlan;
            0x88A8: parse_outer_vlan;
            default: parse_outer_opaque_fanout;
        }
    }

    state parse_outer_vlan {
     pkt.extract(hdr.outer.vlan_tag.next);
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            0x8100: parse_outer_vlan;
            0x88A8: parse_outer_vlan;
            default: parse_outer_opaque_fanout;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Outer, Opaque Stack
    ///////////////////////////////////////////////////////////////////////////

    state parse_outer_opaque_fanout {

     pkt.extract(hdr.outer.opaque_length);
        transition select(hdr.outer.opaque_length.len) {





            // STACK_IPV4:           parse_outer_opaque20;
            // STACK_IPV4_GRE:       parse_outer_opaque24;
            // STACK_IPV4_NVGRE:     parse_outer_opaque28;
            // STACK_IPV4_UDP_VXLAN: parse_outer_opaque36;
            // STACK_IPV4_UDP_GTPU:  parse_outer_opaque36;
            // STACK_IPV6:           parse_outer_opaque40;
            // STACK_IPV6_GRE:       parse_outer_opaque44;
            // STACK_IPV6_NVGRE:     parse_outer_opaque48;
            // STACK_IPV6_UDP_VXLAN: parse_outer_opaque56;
            // STACK_IPV6_UDP_GTPU:  parse_outer_opaque56;

            STACK_IPV4: parse_outer_opaque16;
            STACK_IPV4_GRE: parse_outer_opaque16;
            STACK_IPV4_NVGRE: parse_outer_opaque16;

            STACK_IPV4_UDP_VXLAN: parse_outer_opaque32;
            STACK_IPV4_UDP_GTPU: parse_outer_opaque32;
            STACK_IPV6: parse_outer_opaque32;
            STACK_IPV6_GRE: parse_outer_opaque32;
            STACK_IPV6_NVGRE: parse_outer_opaque32;
            STACK_IPV6_UDP_VXLAN: parse_outer_opaque32;
            STACK_IPV6_UDP_GTPU: parse_outer_opaque32;
            default: accept;
        }
    }


    state parse_outer_opaque32 {
     pkt.extract(hdr.outer.opaque_32B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.outer.opaque_length.len) {




            STACK_IPV4_UDP_VXLAN: parse_outer_opaque4;
            STACK_IPV4_UDP_GTPU: parse_outer_opaque4;
            STACK_IPV6: parse_outer_opaque8;
            STACK_IPV6_GRE: parse_outer_opaque8;
            STACK_IPV6_NVGRE: parse_outer_opaque16;
            STACK_IPV6_UDP_VXLAN: parse_outer_opaque16;
            STACK_IPV6_UDP_GTPU: parse_outer_opaque16;
            default: parse_inner_opaque_fanout;
        }
    }

    state parse_outer_opaque16 {
     pkt.extract(hdr.outer.opaque_16B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.outer.opaque_length.len) {




            STACK_IPV4: parse_outer_opaque4;
            STACK_IPV4_GRE: parse_outer_opaque8;
            STACK_IPV4_NVGRE: parse_outer_opaque8;

            STACK_IPV6_NVGRE: parse_inner_opaque_fanout;
            STACK_IPV6_UDP_VXLAN: parse_outer_opaque8;
            STACK_IPV6_UDP_GTPU: parse_outer_opaque8;
            default: parse_inner_opaque_fanout;
        }
    }


    state parse_outer_opaque8 {
     pkt.extract(hdr.outer.opaque_8B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.outer.opaque_length.len) {




            STACK_IPV4_GRE: parse_inner_opaque_fanout;
            STACK_IPV4_NVGRE: parse_outer_opaque4;

            STACK_IPV6: parse_inner_opaque_fanout;
            STACK_IPV6_GRE: parse_outer_opaque4;
            STACK_IPV6_UDP_VXLAN: parse_inner_opaque_fanout;
            STACK_IPV6_UDP_GTPU: parse_inner_opaque_fanout;
            default: parse_inner_opaque_fanout;
        }
    }


    state parse_outer_opaque4 {
     pkt.extract(hdr.outer.opaque_4B_0);
        transition parse_inner_opaque_fanout;
    }




    ///////////////////////////////////////////////////////////////////////////
    // Inner, Opaque Stack
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_opaque_fanout {

     pkt.extract(hdr.inner.opaque_length);
        transition select(hdr.inner.opaque_length.len) {





            // STACK_ENET_IPV4_GRE:           parse_inner_opaque38;
            // STACK_ENET_VLAN_IPV4_GRE:      parse_inner_opaque42;
            // STACK_ENET_IPV4_UDP_GTPU:      parse_inner_opaque50;
            // STACK_ENET_VLAN_IPV4_UDP_GTPU: parse_inner_opaque54;
            // STACK_ENET_IPV6_GRE:           parse_inner_opaque58;
            // STACK_ENET_VLAN_IPV6_GRE:      parse_inner_opaque62;
            // STACK_ENET_IPV6_UDP_GTPU:      parse_inner_opaque70;
            // STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque74;

            STACK_ENET_IPV4_GRE: parse_inner_opaque32;
            STACK_ENET_VLAN_IPV4_GRE: parse_inner_opaque32;
            STACK_ENET_IPV4_UDP_GTPU: parse_inner_opaque32;
            STACK_ENET_VLAN_IPV4_UDP_GTPU: parse_inner_opaque32;
            STACK_ENET_IPV6_GRE: parse_inner_opaque32;
            STACK_ENET_VLAN_IPV6_GRE: parse_inner_opaque32;
            STACK_ENET_IPV6_UDP_GTPU: parse_inner_opaque32;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque32;
            default: accept;
         }
    }



    state parse_inner_opaque32 {
     pkt.extract(hdr.inner.opaque_32B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_IPV4_GRE: parse_inner_opaque4_0;
            STACK_ENET_VLAN_IPV4_GRE: parse_inner_opaque8_0;
            STACK_ENET_IPV4_UDP_GTPU: parse_inner_opaque16;
            STACK_ENET_VLAN_IPV4_UDP_GTPU: parse_inner_opaque16;
            STACK_ENET_IPV6_GRE: parse_inner_opaque16;
            STACK_ENET_VLAN_IPV6_GRE: parse_inner_opaque16;
            STACK_ENET_IPV6_UDP_GTPU: parse_inner_opaque16;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque16;
            default: accept;
         }
    }


    state parse_inner_opaque16 {
     pkt.extract(hdr.inner.opaque_16B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_IPV4_UDP_GTPU: parse_inner_opaque2;
            STACK_ENET_VLAN_IPV4_UDP_GTPU: parse_inner_opaque4_0;
            STACK_ENET_IPV6_GRE: parse_inner_opaque8_0;
            STACK_ENET_VLAN_IPV6_GRE: parse_inner_opaque8_0;
            STACK_ENET_IPV6_UDP_GTPU: parse_inner_opaque8_0;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque8_0;
            default: accept;
         }
    }


    state parse_inner_opaque8_0 {
     pkt.extract(hdr.inner.opaque_8B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_VLAN_IPV4_GRE: parse_inner_opaque2;
            STACK_ENET_IPV6_GRE: parse_inner_opaque2;
            STACK_ENET_VLAN_IPV6_GRE: parse_inner_opaque4_0;
            STACK_ENET_IPV6_UDP_GTPU: parse_inner_opaque4_0;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque4_0;
         }
    }


    state parse_inner_opaque4_0 {
     pkt.extract(hdr.inner.opaque_4B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_IPV4_GRE: parse_inner_opaque2;
            STACK_ENET_VLAN_IPV4_UDP_GTPU: parse_inner_opaque2;
            STACK_ENET_VLAN_IPV6_GRE: parse_inner_opaque2;
            STACK_ENET_IPV6_UDP_GTPU: parse_inner_opaque2;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque2;
         }
    }


    state parse_inner_opaque2 {
     pkt.extract(hdr.inner.opaque_2B_0);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_IPV4_UDP_GTPU: accept;
            STACK_ENET_VLAN_IPV4_GRE: accept;
            STACK_ENET_IPV6_GRE: accept;
            STACK_ENET_IPV4_GRE: accept;
            STACK_ENET_VLAN_IPV4_UDP_GTPU: accept;
            STACK_ENET_VLAN_IPV6_GRE: accept;
            STACK_ENET_IPV6_UDP_GTPU: parse_inner_opaque8_1;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque8_1;
         }
    }


    state parse_inner_opaque8_1 {
     pkt.extract(hdr.inner.opaque_8B_1);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_IPV6_UDP_GTPU: accept;
            STACK_ENET_VLAN_IPV6_UDP_GTPU: parse_inner_opaque4_1;
         }
    }

    state parse_inner_opaque4_1 {
     pkt.extract(hdr.inner.opaque_4B_1);

        // This will likely require (tofino2 only) scratch registers

        transition select(hdr.inner.opaque_length.len) {




            STACK_ENET_VLAN_IPV6_UDP_GTPU: accept;
         }
    }




    // state parse_inner_opaque38 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_4B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque42 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_8B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque50 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_16B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque54 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_16B_0);
 //     pkt.extract(hdr.inner.opaque_4B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque58 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_16B_0);
 //     pkt.extract(hdr.inner.opaque_8B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque62 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_16B_0);
 //     pkt.extract(hdr.inner.opaque_8B_0);
 //     pkt.extract(hdr.inner.opaque_4B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque70 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_16B_0);
 //     pkt.extract(hdr.inner.opaque_8B_0);
 //     pkt.extract(hdr.inner.opaque_4B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
 //     pkt.extract(hdr.inner.opaque_8B_1);
    //     transition accept;
    // }
    // 
    // state parse_inner_opaque74 {
 //     pkt.extract(hdr.inner.opaque_32B_0);
 //     pkt.extract(hdr.inner.opaque_16B_0);
 //     pkt.extract(hdr.inner.opaque_8B_0);
 //     pkt.extract(hdr.inner.opaque_4B_0);
 //     pkt.extract(hdr.inner.opaque_2B_0);
 //     pkt.extract(hdr.inner.opaque_8B_1);
 //     pkt.extract(hdr.inner.opaque_4B_1);
    //     transition accept;
    // }



// ///////////////////////////////////////////////////////////////////////////////
// // Transport Encaps
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

}
# 49 "npb.p4" 2






# 1 "npb_egr_deparser.p4" 1
/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.
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
 ******************************************************************************/

# 1 "headers.p4" 1
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
 ******************************************************************************/

//-----------------------------------------------------------------------------
// Protocol Header Definitions
//-----------------------------------------------------------------------------
# 22 "npb_egr_deparser.p4" 2
# 1 "types.p4" 1
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
 ******************************************************************************/
# 23 "npb_egr_deparser.p4" 2

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out pkt,
        inout switch_header_egress_t hdr,
        in switch_egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Checksum() ipv4_checksum;
    Checksum() inner_ipv4_checksum;

    apply {
# 56 "npb_egr_deparser.p4"
// #ifdef TUNNEL_ENABLE
//         hdr.outer.ipv4.hdr_checksum = inner_ipv4_checksum.update({
//             hdr.outer.ipv4.version,
//             hdr.outer.ipv4.ihl,
//             hdr.outer.ipv4.diffserv,
//             hdr.outer.ipv4.ecn,
//             hdr.outer.ipv4.total_len,
//             hdr.outer.ipv4.identification,
//             hdr.outer.ipv4.flags,
//             hdr.outer.ipv4.frag_offset,
//             hdr.outer.ipv4.ttl,
//             hdr.outer.ipv4.protocol,
//             hdr.outer.ipv4.src_addr,
//             hdr.outer.ipv4.dst_addr});
// #endif


        // ***** TRANSPORT *****
        pkt.emit(hdr.transport.ethernet);
        pkt.emit(hdr.transport.vlan_tag);
        pkt.emit(hdr.transport.nsh_type1);
# 88 "npb_egr_deparser.p4"
        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);
        pkt.emit(hdr.outer.e_tag);
        pkt.emit(hdr.outer.vn_tag);
        pkt.emit(hdr.outer.vlan_tag);
        pkt.emit(hdr.outer.opaque_32B_0);
        pkt.emit(hdr.outer.opaque_16B_0);
        pkt.emit(hdr.outer.opaque_8B_0);
        pkt.emit(hdr.outer.opaque_4B_0);

        // ***** INNER *****
        pkt.emit(hdr.inner.opaque_32B_0);
        pkt.emit(hdr.inner.opaque_16B_0);
        pkt.emit(hdr.inner.opaque_8B_0);
        pkt.emit(hdr.inner.opaque_8B_1);
        pkt.emit(hdr.inner.opaque_4B_0);
        pkt.emit(hdr.inner.opaque_4B_1);
        pkt.emit(hdr.inner.opaque_2B_0);
# 130 "npb_egr_deparser.p4"
    }
}
# 56 "npb.p4" 2

# 1 "port.p4" 1
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
 ******************************************************************************/

# 1 "rewrite.p4" 1

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
 ******************************************************************************/




# 1 "l2.p4" 1
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
 ******************************************************************************/
# 28 "rewrite.p4" 2

control Rewrite(inout switch_header_transport_t hdr,
                inout switch_egress_metadata_t eg_md,
    inout switch_tunnel_metadata_t tunnel
)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t bd_table_size) {

//  EgressBd(bd_table_size) egress_bd;
    switch_smac_index_t smac_index;

 // ---------------------------------------------
 // Table: Nexthop Rewrite
 // ---------------------------------------------

    action rewrite_l2_with_tunnel(switch_tunnel_type_t type) {


        tunnel.type = type;

    }

    action rewrite_l3(switch_bd_t bd, mac_addr_t dmac) {

        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
    }

    action rewrite_l3_with_tunnel_id(
            mac_addr_t dmac, switch_tunnel_type_t type, switch_tunnel_id_t id, bit<8> flow_id) {

        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = SWITCH_BD_DEFAULT_VRF;
        tunnel.type = type;
        tunnel.id = id;
  tunnel.flow_id = flow_id;

    }

    action rewrite_l3_with_tunnel_bd(mac_addr_t dmac, switch_tunnel_type_t type, switch_bd_t bd) {


        hdr.ethernet.dst_addr = dmac;
        eg_md.bd = bd;
        tunnel.type = type;

    }

    action rewrite_l3_with_tunnel(mac_addr_t dmac, switch_tunnel_type_t type) {


        hdr.ethernet.dst_addr = dmac;
        tunnel.type = type;
//      eg_md.bd = (switch_bd_t) eg_md.vrf;

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
        size = nexthop_table_size;
    }

 // ---------------------------------------------
 // Table: SMAC Rewrite
 // ---------------------------------------------
/*
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
*/
 // ---------------------------------------------
 // Apply
 // ---------------------------------------------

    apply {
        smac_index = 0;

        nexthop_rewrite.apply();

//      egress_bd.apply(hdr, eg_md.bd,                          eg_md.pkt_src,
//          smac_index);

//      smac_rewrite.apply();
    }
}
# 24 "port.p4" 2

//-----------------------------------------------------------------------------
// Ingress Port Mapping
//-----------------------------------------------------------------------------

control IngressPortMapping(
        inout switch_header_transport_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) (
        switch_uint32_t port_vlan_table_size,
  switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
  switch_uint32_t vlan_table_size=4096
) {
    ActionProfile(bd_table_size) bd_action_profile;

 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 action set_port_properties_with_nsh(
  switch_yid_t exclusion_id,

  bool l2_fwd_en,
  bit<3> sf_bitmask
 ) {
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

  ig_md.nsh_type1.l2_fwd_en = l2_fwd_en; //  1 bit
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits
 }

 action set_port_properties_without_nsh(
  switch_yid_t exclusion_id,

  bit<16> sap,
  bit<16> vpn,
  bit<24> spi,
  bit<8> si,
  bool l2_fwd_en,
  bit<3> sf_bitmask
 ) {
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

    hdr.nsh_type1.sap = sap; // 16 bits
    hdr.nsh_type1.vpn = vpn; // 16 bits
    hdr.nsh_type1.spi = spi; // 24 bits
    hdr.nsh_type1.si = si; //  8 bits
  ig_md.nsh_type1.l2_fwd_en = l2_fwd_en; //  1 bit
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits
 }

 table port_mapping {
  key = {
   ig_md.port : exact;
   hdr.nsh_type1.isValid() : exact;
  }

  actions = {
   set_port_properties_with_nsh;
   set_port_properties_without_nsh;
  }

  size = port_table_size * 2;
 }

 // ----------------------------------------------
 // Table: BD Mapping
 // ----------------------------------------------

    action port_vlan_miss() {
        //ig_md.flags.port_vlan_miss = true;
    }

    action set_bd_properties(
  switch_bd_t bd
    ) {
        ig_md.bd = bd;
 }

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

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

    apply {
/*
        switch (port_mapping.apply().action_run) {
            set_port_properties : {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
			}
        }
*/
        if(port_mapping.apply().hit) {
    if (!port_vlan_to_bd_mapping.apply().hit) {
     if (hdr.vlan_tag[0].isValid()) {
      vlan_to_bd_mapping.apply();
     }
    }
  }
    }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
// ----------------------------------------------------------------------------

control LAG(
    inout switch_ingress_metadata_t ig_md,
    in bit<16> hash,
    out switch_port_t egress_port
) (
 switch_uint32_t table_size_lag_group = LAG_GROUP_TABLE_SIZE,
 switch_uint32_t table_size_lag_selector = LAG_SELECT_TABLE_SIZE
) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(table_size_lag_selector, selector_hash, SelectorMode_t.FAIR) lag_selector;

 // ----------------------------------------------
 // Table: LAG
 // ----------------------------------------------

    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }
# 203 "port.p4"
    action lag_miss() { egress_port = 0; }

    table lag {
        key = {



            ig_md.egress_port_lag_index : exact @name("port_lag_index");

            hash : selector;
        }

        actions = {
            lag_miss;
            set_lag_port;

        }

        const default_action = lag_miss;
        size = table_size_lag_group;
        implementation = lag_selector;
    }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

    apply {
        lag.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress Port Mapping
//-----------------------------------------------------------------------------

control EgressPortMapping(
        inout switch_header_transport_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port
) (
        switch_uint32_t table_size=288
) {

 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

    action port_normal(
  switch_port_lag_index_t port_lag_index
    ) {
        eg_md.port_lag_index = port_lag_index;
    }

    table port_mapping {
        key = {
   port : exact;
  }

        actions = {
            port_normal;
        }

        size = table_size;
    }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

    apply {
        port_mapping.apply();
    }
}
# 58 "npb.p4" 2





# 1 "rewrite.p4" 1

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
 ******************************************************************************/
# 64 "npb.p4" 2
# 1 "tunnel.p4" 1
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
 ******************************************************************************/




# 1 "scoper.p4" 1
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
 ******************************************************************************/
# 27 "tunnel.p4" 2

//#if defined(IPV6_TUNNEL_ENABLE) && !defined(IPV6_ENABLE)
//#error "IPv6 tunneling cannot be enabled without enabling IPv6"
//#endif

//-----------------------------------------------------------------------------
// Ingress Tunnel RMAC: Transport
//-----------------------------------------------------------------------------

control IngressTunnelRMAC(
    inout switch_header_transport_t hdr_0,
    inout switch_ingress_metadata_t ig_md
) (
 switch_uint32_t table_size = 128
) {

    // -------------------------------------
    // Table: RMAC
    // -------------------------------------
# 74 "tunnel.p4"
    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {







        ig_md.flags.rmac_hit = true;

 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Transport (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnel(
    inout switch_ingress_metadata_t ig_md,
    inout bool ig_md_flags_ipv4_checksum_err,
    inout switch_lookup_fields_t lkp,
    inout switch_tunnel_metadata_t tunnel_0,
    inout switch_header_transport_t hdr_0,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
) (
 switch_uint32_t ipv4_src_vtep_table_size=1024,
    switch_uint32_t ipv6_src_vtep_table_size=1024,
    switch_uint32_t ipv4_dst_vtep_table_size=1024,
    switch_uint32_t ipv6_dst_vtep_table_size=1024
) {

    // -------------------------------------
    // Table: IPv4/v6 Src VTEP
    // -------------------------------------

    // Derek note: These tables are unused in latest switch.p4 code from barefoot

 action src_vtep_hit(
  switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<16> vpn,
  bit<3> sf_bitmask
 ) {
  ig_md.port_lag_index = port_lag_index;
  hdr_0.nsh_type1.sap = sap; // 16 bits
  hdr_0.nsh_type1.vpn = vpn; // 16 bits
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits
 }

 action src_vtep_miss(
 ) {
 }

    // -------------------------------------

    table src_vtep {
        key = {



            tunnel_0.type : exact @name("tunnel_type");
        }

        actions = {
            src_vtep_miss;
            src_vtep_hit;
        }

        const default_action = src_vtep_miss;
        size = ipv4_src_vtep_table_size;
    }

    // -------------------------------------
# 171 "tunnel.p4"
    // -------------------------------------
    // Table: IPv4/v6 Dst VTEP
    // -------------------------------------

 action dst_vtep_hit(
//		switch_bd_t bd,

  bit<3> drop


  ,
  switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<16> vpn,
  bit<3> sf_bitmask

 ) {
//		ig_md.bd = bd;

  ig_intr_md_for_dprsr.drop_ctl = drop;


  ig_md.port_lag_index = port_lag_index;
  hdr_0.nsh_type1.sap = sap; // 16 bits
  hdr_0.nsh_type1.vpn = vpn; // 16 bits
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits

 }

    // -------------------------------------

    table dst_vtep {
        key = {






            tunnel_0.type : exact @name("tunnel_type");
        }

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        const default_action = NoAction;
        size = ipv4_dst_vtep_table_size;
    }

    // -------------------------------------
# 246 "tunnel.p4"
    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {

        // outer RMAC lookup for tunnel termination.
//      switch(rmac.apply().action_run) {
//          rmac_hit : {
                if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {

                    src_vtep.apply();

                    switch(dst_vtep.apply().action_run) {
                        dst_vtep_hit : {
                        }
                    }
                } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {
# 273 "tunnel.p4"
    }
//          }
//      }

    }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Outer (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelOuterInner(
    inout switch_ingress_metadata_t ig_md,
    inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_t tunnel_2
) (
    switch_uint32_t dst_vtep_exm_table_size=32w1024,
    switch_uint32_t dst_vtep_tcam_table_size=32w1024
) {

    // -------------------------------------
    // Table: Dst VTEP
    // -------------------------------------

 bool terminate_ = false;
 bool scope_ = false;

    action dst_vtep_hit(
  bit<16> sap,
        bit<16> vpn,
  bit<3> sf_bitmask
    ) {
  hdr_0.nsh_type1.sap = sap;
        hdr_0.nsh_type1.vpn = vpn;
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits
    }

    action dst_vtep_hit_scope(
  bit<16> sap,
        bit<16> vpn,
  bit<3> sf_bitmask
    ) {
  hdr_0.nsh_type1.sap = sap;
        hdr_0.nsh_type1.vpn = vpn;
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits

  scope_ = true;
    }

    action dst_vtep_hit_term(
  bit<16> sap,
        bit<16> vpn,
  bit<3> sf_bitmask
    ) {
  hdr_0.nsh_type1.sap = sap;
        hdr_0.nsh_type1.vpn = vpn;
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits

  terminate_ = true;
    }

    action dst_vtep_hit_scope_and_term(
  bit<16> sap,
        bit<16> vpn,
  bit<3> sf_bitmask
    ) {
  hdr_0.nsh_type1.sap = sap;
        hdr_0.nsh_type1.vpn = vpn;
  ig_md.nsh_type1.sf_bitmask = sf_bitmask; //  8 bits

  scope_ = true;
  terminate_ = true;
    }

    // -------------------------------------

    table dst_vtep_exm {
        key = {
            hdr_0.nsh_type1.sap : exact @name("sap");
            lkp.tunnel_type : exact @name("tunnel_type");
            lkp.tunnel_id : exact @name("tynnel_id");
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            dst_vtep_hit_scope;
            dst_vtep_hit_term;
            dst_vtep_hit_scope_and_term;
        }

        const default_action = NoAction;
        size = dst_vtep_exm_table_size;
    }

    // -------------------------------------

    table dst_vtep_tcam {
        key = {
            hdr_0.nsh_type1.sap : ternary @name("sap");
            lkp.tunnel_type : ternary @name("tunnel_type");
            lkp.tunnel_id : ternary @name("tynnel_id");
        }

        actions = {
            NoAction;
            dst_vtep_hit;
            dst_vtep_hit_scope;
            dst_vtep_hit_term;
            dst_vtep_hit_scope_and_term;
        }

        const default_action = NoAction;
        size = dst_vtep_tcam_table_size;
    }

    // -------------------------------------
    // Table: Scope Increment
    // -------------------------------------

    action new_scope(bit<8> scope_new) {
        hdr_0.nsh_type1.scope = scope_new;
    }
/*
    table scope_inc {
        key = {
			hdr_0.nsh_type1.scope : exact;
		}
        actions = {
			new_scope;
		}
        const entries = {
            0  : new_scope(1);
            1  : new_scope(2);
            2  : new_scope(3);
		}
	}
*/
    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {

  if(!dst_vtep_exm.apply().hit) {
   dst_vtep_tcam.apply();
  }

  if(terminate_ == true) {
            ig_md.tunnel_1.terminate = true;
            if(hdr_0.nsh_type1.scope == 1) {
                ig_md.tunnel_2.terminate = true;
   }
  }

  if(scope_ == true) {
   vlan_tag_h vlan_tag_dummy;

            if(hdr_0.nsh_type1.scope == 0) {
                Scoper.apply(
                    hdr_2.ethernet,
                    hdr_2.vlan_tag[0],
                    false, // inner only has 1 vlan...set the valid false
                    hdr_2.vlan_tag[0], // inner only has 1 vlan...send in anything that will compile
//                  vlan_tag_dummy,    // inner only has 1 vlan...send in anything that will compile
                    hdr_2.ipv4,

                    hdr_2.ipv6.isValid(),
                    hdr_2.ipv6,

                    hdr_2.tcp.isValid(),
                    hdr_2.tcp,
                    hdr_2.udp,
                    hdr_2.sctp,
                    tunnel_2.type,
                    tunnel_2.id,
                    ig_md.drop_reason_2,

                    ig_md.lkp
                );
            }

   hdr_0.nsh_type1.scope = hdr_0.nsh_type1.scope + 1;
//			scope_inc.apply();
  }
 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Transport
//-----------------------------------------------------------------------------

// looks like this control block is doing nothing if ERSPAN ripped out

control TunnelDecapTransportIngress(
    inout switch_header_transport_t hdr_0,



    in switch_ingress_metadata_t eg_md,

    in switch_tunnel_metadata_t tunnel
) (
    switch_tunnel_mode_t mode
) {

// There is no UDP support in transport
//     // -------------------------------------
//     // Decap L4
//     // -------------------------------------
// 
// 	action decap_l4() {
// 		hdr_0.udp.setInvalid();
// //		hdr_0.tcp.setInvalid();
// 	}

    // -------------------------------------
    // Decap L3
    // -------------------------------------

 // helper functions
# 516 "tunnel.p4"
    // -------------------------------------
    // Decap L2
    // -------------------------------------


 action decap_l2() {
//      hdr_0.ethernet.setInvalid();
//      hdr_0.vlan_tag[0].setInvalid();
//      hdr_0.nsh_type1.setInvalid();
 }

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {

  // ----- l2 -----
        if(tunnel.terminate) {
   decap_l2();
  }
# 545 "tunnel.p4"
        // No L4 support in transport
  // // ----- l4 -----
        // if(tunnel.terminate) {
  // 	decap_l4();
  // }

    }

}

//-----------------------------------------------------------------------------

control TunnelDecapTransportEgress(
    inout switch_header_transport_t hdr_0,
    in switch_egress_metadata_t eg_md,
    in switch_tunnel_metadata_t tunnel,
    in bool nsh_terminate
) (
    switch_tunnel_mode_t mode
) {
    // -------------------------------------
    // Decap L2
    // -------------------------------------

 action decap_l2() {
        hdr_0.ethernet.setInvalid();
        hdr_0.vlan_tag[0].setInvalid();
 }

 action decap_l2_nsh() {
        hdr_0.nsh_type1.setInvalid();
 }

    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {
  if(tunnel.terminate) { // always true
   decap_l2();
  }

  if(nsh_terminate) { // maybe true
   decap_l2_nsh();
  }
 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
 in bool terminate_a,
 in bool terminate_b,
 inout switch_header_transport_t hdr_0
) {

    action new_scope(bit<8> scope_new) {
        hdr_0.nsh_type1.scope = scope_new;
    }

    table scope_dec {
  key = {
   terminate_a : exact;
   terminate_b : exact;
   hdr_0.nsh_type1.scope : exact;
  }
  actions = {
   new_scope;
  }
  const entries = {
/*
			0 : new_scope(0); // this is an error condition (underflow)!
			1 : new_scope(0);
			2 : new_scope(1);
			3 : new_scope(2);
*/
   // no decrement
   (false, false, 0) : new_scope(0);
   (false, false, 1) : new_scope(1);
   (false, false, 2) : new_scope(2);
   (false, false, 3) : new_scope(3);
   // decrement one
   (false, true, 0) : new_scope(0); // this is an error condition (underflow)!
   (false, true, 1) : new_scope(0);
   (false, true, 2) : new_scope(1);
   (false, true, 3) : new_scope(2);
   // decrement one
   (true, false, 0) : new_scope(0); // this is an error condition (underflow)!
   (true, false, 1) : new_scope(0);
   (true, false, 2) : new_scope(1);
   (true, false, 3) : new_scope(2);
   // decrement two
   (true, true, 0) : new_scope(0); // this is an error condition (underflow)!
   (true, true, 1) : new_scope(0); // this is an error condition (underflow)!
   (true, true, 2) : new_scope(0);
   (true, true, 3) : new_scope(1);
  }
 }

 // -------------------------

 apply {
  scope_dec.apply();
 }
}



//-----------------------------------------------------------------------------
// Tunnel Decap Outer
//-----------------------------------------------------------------------------

control TunnelDecapOuter(
    inout switch_header_transport_t hdr_0,
    inout switch_header_outer_egress_t hdr_1,
    in switch_egress_metadata_t eg_md,
    in switch_tunnel_metadata_t tunnel
) (
    switch_tunnel_mode_t mode
) {
    // -------------------------------------
 // Decap L2
    // -------------------------------------

 action decap_l2() {
        hdr_1.ethernet.setInvalid();
  hdr_1.e_tag.setInvalid();
  hdr_1.vn_tag.setInvalid();
        hdr_1.vlan_tag[0].setInvalid(); // extreme added
        hdr_1.vlan_tag[1].setInvalid(); // extreme added
 }

    // -------------------------------------
 // Apply
    // -------------------------------------

    apply {
        if(tunnel.terminate) {
            decap_l2();



   hdr_1.opaque_32B_0.setInvalid();
   hdr_1.opaque_16B_0.setInvalid();
   hdr_1.opaque_8B_0.setInvalid();
   hdr_1.opaque_4B_0.setInvalid();
# 706 "tunnel.p4"
  }
    }
}


//-----------------------------------------------------------------------------
// Tunnel Decap Inner
//-----------------------------------------------------------------------------

control TunnelDecapInner(
    inout switch_header_transport_t hdr_0,
    inout switch_header_inner_egress_t hdr_2,
    in switch_egress_metadata_t eg_md,
    in switch_tunnel_metadata_t tunnel
) (
    switch_tunnel_mode_t mode
) {
    // -------------------------------------
    // Apply
    // -------------------------------------

    apply {
        if(tunnel.terminate) {



   hdr_2.opaque_32B_0.setInvalid();
   hdr_2.opaque_16B_0.setInvalid();
   hdr_2.opaque_8B_0.setInvalid();
   hdr_2.opaque_8B_1.setInvalid();
   hdr_2.opaque_4B_0.setInvalid();
   hdr_2.opaque_4B_1.setInvalid();
   hdr_2.opaque_2B_0.setInvalid();
# 754 "tunnel.p4"
  }
  }
}


//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------

control TunnelRewrite(
    inout switch_header_transport_t hdr_0,
    inout switch_egress_metadata_t eg_md,
    in switch_tunnel_metadata_t tunnel
) (
    switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,
    switch_uint32_t nexthop_rewrite_table_size=512,
    switch_uint32_t src_addr_rewrite_table_size=1024,
    switch_uint32_t smac_rewrite_table_size=1024
) {

    EgressBd(BD_TABLE_SIZE) egress_bd;
    switch_smac_index_t smac_index;

    // -------------------------------------
 // Table: Nexthop Rewrite (DMAC & BD)
    // -------------------------------------

    // Outer nexthop rewrite
    action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
        eg_md.bd = bd;
        hdr_0.ethernet.dst_addr = dmac;
    }

    table nexthop_rewrite {
        key = {
            eg_md.outer_nexthop : exact;
        }

        actions = {
            NoAction;
            rewrite_tunnel;
        }

        const default_action = NoAction;
        size = nexthop_rewrite_table_size;
    }

    // -------------------------------------
 // Table: SIP Rewrite
    // -------------------------------------
# 837 "tunnel.p4"
    // -------------------------------------
 // Table: SMAC Rewrite
    // -------------------------------------

    // Tunnel source MAC rewrite
    action rewrite_smac(mac_addr_t smac) {
        hdr_0.ethernet.src_addr = smac;
    }

    table smac_rewrite {
        key = { smac_index : exact; }
        actions = {
            NoAction;
            rewrite_smac;
        }

        const default_action = NoAction;
        size = smac_rewrite_table_size;
    }

    // -------------------------------------
 // Apply
    // -------------------------------------

    apply {

        if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            nexthop_rewrite.apply();

        if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE)
            egress_bd.apply(hdr_0, eg_md.bd, eg_md.pkt_src,
                smac_index);
# 880 "tunnel.p4"
        smac_rewrite.apply();

    }
}

//-----------------------------------------------------------------------------
// Tunnel encapsulation
//
// @param hdr : Parsed headers.
// @param eg_md : Egress metadata fields.
// @param mode :  Specify the model for tunnel encapsulation. In the UNIFORM model, ttl and dscp
// fields are preserved by copying into the outer header on encapsulation. This results in 'normal'
// behaviour for ECN field (See RFC 6040 secion 4.1). In the PIPE model, outer header ttl and dscp
// fields are independent of that in the inner header and are set to user-defined values on
// encapsulation.
// @param vni_mapping_table_size : Number of VNIs.
//
//-----------------------------------------------------------------------------

control TunnelEncap(
    inout switch_header_transport_t hdr_0,
    inout switch_header_outer_egress_t hdr_1,
    inout switch_egress_metadata_t eg_md,
    inout switch_tunnel_metadata_t tunnel_
) (
    switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
    switch_uint32_t vni_mapping_table_size=1024
) {

    bit<16> payload_len;
    bit<8> ip_proto;

    // -------------------------------------

    action set_vni(switch_tunnel_id_t id) {
        tunnel_.id = id;
    }

    table bd_to_vni_mapping {
        key = { eg_md.bd : exact; }

        actions = {
            NoAction;
            set_vni;
        }

        size = vni_mapping_table_size;
    }

 //=============================================================================
 // Copy L3/4 Outer -> Inner
 //=============================================================================
# 941 "tunnel.p4"
    action rewrite_inner_ipv4_udp() {
        //payload_len = hdr_1.ipv4.total_len;




        ip_proto = 4;
    }

    action rewrite_inner_ipv4_unknown() {
        //payload_len = hdr_1.ipv4.total_len;



        ip_proto = 4;
    }


    action rewrite_inner_ipv6_udp() {
        //payload_len = hdr_1.ipv6.payload_len + 16w40;
        ip_proto = 41;
    }

    action rewrite_inner_ipv6_unknown() {
        //payload_len = hdr_1.ipv6.payload_len + 16w40;
        ip_proto = 41;
    }


    table encap_outer {
        key = {
/*
            hdr_1.ipv4.isValid() : exact;
#ifdef IPV6_ENABLE
            hdr_1.ipv6.isValid() : exact;
#endif  // IPV6_ENABLE
            hdr_1.udp.isValid() : exact;
*/
            // hdr_1.tcp.isValid() : exact;

// Derek: This is a hack to get chuck something that compiles.
   hdr_1.ethernet.isValid() : exact;

   hdr_1.e_tag.isValid() : exact;

   hdr_1.vn_tag.isValid() : exact;
        }

        actions = {
            rewrite_inner_ipv4_udp;
            rewrite_inner_ipv4_unknown;

            rewrite_inner_ipv6_udp;
            rewrite_inner_ipv6_unknown;

        }

        const entries = {

            (true, false, false) : rewrite_inner_ipv4_unknown();
            (false, true, false) : rewrite_inner_ipv6_unknown();
            (true, false, true) : rewrite_inner_ipv4_udp();
            (false, true, true) : rewrite_inner_ipv6_udp();





        }
    }

 //=============================================================================
 // Copy L2 Outer -> Inner
    // Writes Tunnel header, rewrites some of Outer
 //=============================================================================

    //-----------------------------------------------------------------------------
    // Helper actions to add various headers.
    //-----------------------------------------------------------------------------

    // there is no UDP supported inthe transport
    // action add_udp_header(bit<16> src_port, bit<16> dst_port) {
    //     hdr_0.udp.setValid();
    //     hdr_0.udp.src_port = src_port;
    //     hdr_0.udp.dst_port = dst_port;
    //     hdr_0.udp.checksum = 0;
    //     // hdr_0.udp.length = 0;
    // }

    // -------------------------------------
    // Extreme Networks - Modified
    // -------------------------------------
# 1062 "tunnel.p4"
 action add_l2_header() {
        hdr_0.ethernet.setValid();
 }

    // -------------------------------------
# 1089 "tunnel.p4"
    // -------------------------------------
# 1113 "tunnel.p4"
    //-----------------------------------------------------------------------------
    // Actual actions.
    //-----------------------------------------------------------------------------

    // =====================================
    // ----- Rewrite, IPv4 Stuff -----
    // =====================================

 action rewrite_ipv4_erspan() {
# 1138 "tunnel.p4"
 }

    // =====================================
    // ----- Rewrite, IPv6 Stuff -----
    // =====================================

    // -------------------------------------
    // Extreme Networks - Added
    // -------------------------------------

    action rewrite_mac_in_mac() {
  add_l2_header();
        hdr_0.ethernet.ether_type = 0x894F;
    }

    // -------------------------------------

    table tunnel {
        key = {
            tunnel_.type : exact;
        }

        actions = {
            NoAction;

            rewrite_mac_in_mac; // extreme added
            rewrite_ipv4_erspan; // extreme added
        }

        const default_action = NoAction;

     // ---------------------------------
     // Extreme Networks - Added
     // ---------------------------------
  /*
		// Note that this table should just be programmed with the
		// following constants, but the language doesn't seem to allow it....
		const entries = {
			(SWITCH_TUNNEL_TYPE_NSH)      = rewrite_mac_in_mac();  // extreme added
			(SWITCH_TUNNEL_TYPE_GRE)      = rewrite_ipv4_gre();    // extreme added
			(SWITCH_TUNNEL_TYPE_ERSPAN)   = rewrite_ipv4_erspan(); // extreme added
		}
		*/
     // ---------------------------------
    }

 //=============================================================================
 // Apply
 //=============================================================================

    apply {

        if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE && tunnel_.id == 0)
            bd_to_vni_mapping.apply();

        if (tunnel_.type != SWITCH_TUNNEL_TYPE_NONE) {
            // Copy L3/L4 header into inner headers.
            encap_outer.apply();

            // Add outer L3/L4/Tunnel headers.
            tunnel.apply();
        }

    }
}
# 65 "npb.p4" 2

# 1 "npb_ing_top.p4" 1
# 1 "npb_ing_sfc_top.p4" 1
# 1 "tunnel.p4" 1
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
 ******************************************************************************/
# 2 "npb_ing_sfc_top.p4" 2





control npb_ing_sfc_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
 inout udf_h hdr_l7_udf,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_tunnel_metadata_t tunnel_1,
 inout switch_tunnel_metadata_t tunnel_2
) {
# 33 "npb_ing_sfc_top.p4"
 IngressTunnelOuterInner(NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;

 Scoper() scoper0;
 Scoper() scoper1;
 Scoper() scoper2;





 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy

 // =========================================================================
 // W/O NSH... Table #0: FlowType Classifier / SFC Classifier
 // =========================================================================
# 94 "npb_ing_sfc_top.p4"
 // =========================================================================
 // W/  NSH... Table #0:
 // =========================================================================

 action ing_sfc_sf_sel_hit(
  bit<3> sf_bitmask

 ) {
  // ----- change nsh -----

  // change metadata

  // base - word 0

  // base - word 1

  // ext type 1 - word 0-3

  // change metadata

  ig_md.nsh_type1.sf_bitmask = sf_bitmask;

 }

 // ---------------------------------

 action ing_sfc_sf_sel_miss(
 ) {
  ig_md.nsh_type1.sf_bitmask = 0;
 }

 // ---------------------------------

 table ing_sfc_sf_sel {
  key = {
   hdr_0.nsh_type1.spi : exact @name("spi");
   hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
   ing_sfc_sf_sel_hit;
   ing_sfc_sf_sel_miss;
  }

  const default_action = ing_sfc_sf_sel_miss;
  size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {






  // -----------------------------------------------------------------
  // Set Initial Scope (L7)
  // -----------------------------------------------------------------

        // populate l7_udf in lkp struct for the following cases:
        //   scope==inner
        //   scope==outer and no inner stack present
        // todo: do we need to qualify this w/ hdr_l7_udf.isValid()? (the thinking is it will just work w/o doing so)







  // ---------------------------------------------------------------------
  // Classify
  // ---------------------------------------------------------------------

  if(hdr_0.nsh_type1.isValid()) {

   // -----------------------------------------------------------------
   // Packet already has  a NSH header on it (is already classified) --> just copy it to internal NSH structure
   // -----------------------------------------------------------------

   // metadata
   ig_md.nsh_type1.hdr_is_new = false;
   ig_md.nsh_type1.sfc_is_new = false;

   // -----------------------------------------------------------------
   // Set Initial Scope
   // -----------------------------------------------------------------

   vlan_tag_h vlan_tag_dummy;

   if(hdr_0.nsh_type1.scope == 0) {
    scoper0.apply(
     hdr_1.ethernet,
     hdr_1.vlan_tag[0],
     hdr_1.vlan_tag[1].isValid(),
     hdr_1.vlan_tag[1],
     hdr_1.ipv4,

     hdr_1.ipv6.isValid(),
     hdr_1.ipv6,

     hdr_1.tcp.isValid(),
     hdr_1.tcp,
     hdr_1.udp,
     hdr_1.sctp,
     tunnel_1.type,
     tunnel_1.id,
     ig_md.drop_reason_1,

     ig_md.lkp
    );
   } else {
    scoper1.apply(
     hdr_2.ethernet,
     hdr_2.vlan_tag[0],
     false, // inner only has 1 vlan...set the valid false
     hdr_2.vlan_tag[0], // inner only has 1 vlan...send in anything that will compile
//					vlan_tag_dummy,    // inner only has 1 vlan...send in anything that will compile
     hdr_2.ipv4,

     hdr_2.ipv6.isValid(),
     hdr_2.ipv6,

     hdr_2.tcp.isValid(),
     hdr_2.tcp,
     hdr_2.udp,
     hdr_2.sctp,
     tunnel_2.type,
     tunnel_2.id,
     ig_md.drop_reason_2,

     ig_md.lkp
    );
   }

   // -----------------------------------------------------------------

   ing_sfc_sf_sel.apply();

  } else {

   // -----------------------------------------------------------------
   // Packet doesn't have a NSH header on it (needs classification) --> try to classify / populate internal NSH structure
   // -----------------------------------------------------------------

   // metadata
   ig_md.nsh_type1.hdr_is_new = true; // * see design note below
   ig_md.nsh_type1.sfc_is_new = false; // * see design note below

   // header
   hdr_0.nsh_type1.setValid();

   // base: word 0
   // (nothing to do)

   // base: word 1
//			hdr_0.nsh_type1.spi                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.si                           = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE

   // ext: type 1 - word 1-3
   hdr_0.nsh_type1.scope = 0;
//			hdr_0.nsh_type1.sap                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE
//			hdr_0.nsh_type1.vpn                          = 0; // DO NOT CLEAR -- DEFAULT VALUE COMES FROM PORT TABLE



   hdr_0.nsh_type1.timestamp = 0; // FOR SIMS


   // * design note: we have to ensure that all sfc tables have hits, otherwise
   // we can end up with a partially classified packet -- which would be bad.
   // one "cheap" (resource-wise) way of doing this is to initially set all
   // the control signals valid, and then have any table that misses clear them....

   // -----------------------------------------------------------------
   // Set Initial Scope
   // -----------------------------------------------------------------

   scoper2.apply(
    hdr_1.ethernet,
    hdr_1.vlan_tag[0],
    hdr_1.vlan_tag[1].isValid(),
    hdr_1.vlan_tag[1],
    hdr_1.ipv4,

    hdr_1.ipv6.isValid(),
    hdr_1.ipv6,

    hdr_1.tcp.isValid(),
    hdr_1.tcp,
    hdr_1.udp,
    hdr_1.sctp,
    tunnel_1.type,
    tunnel_1.id,
    ig_md.drop_reason_1,

    ig_md.lkp
   );

   // -----------------------------------------------------------------

   if(hdr_0.ethernet.isValid()) {
    // ---------------------------
    // ----- normally tapped -----
    // ---------------------------







   } else {
    // ----------------------------
    // ----- optically tapped -----
    // ----------------------------

    // -----------------------
    // Tunnel - Outer
    // -----------------------

    // if hit, validates and copies ***inner*** to lkp struct.



   }

   // -----------------------
   // Tunnel - Inner
   // -----------------------

   // if hit, validates and copies ***inner*** to lkp struct.
   tunnel_inner.apply(ig_md, ig_md.lkp, hdr_0, hdr_2, tunnel_2);

   // -----------------------
   // Finishing Touches
   // -----------------------

   // add a dummy ethernet header -- only need to set the etype (not the da/sa)....
   hdr_0.ethernet.setValid();
   hdr_0.ethernet.ether_type = 0x894F;
  }

  // always terminate transport headers
  tunnel_0.terminate = true;

 }
}
# 2 "npb_ing_top.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_top.p4" 1
//#include "npb_ing_sf_npb_basic_adv_acl.p4"
//#include "npb_ing_sf_npb_basic_adv_dedup.p4"

control npb_ing_sf_npb_basic_adv_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_inner_t hdr_2,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 IngressAcl(
  INGRESS_IPV4_ACL_TABLE_SIZE,


        INGRESS_IPV6_ACL_TABLE_SIZE,

        INGRESS_MAC_ACL_TABLE_SIZE,
        INGRESS_L7_ACL_TABLE_SIZE
 ) acl;

 // temporary internal variables
 bit<2> action_bitmask_internal;
 bit<16> int_ctrl_flags_internal;

    // =========================================================================
    // Notes
    // =========================================================================

    // Note: egress action_bitmask defined as follows....
    //
    //   [0:0] act #1: policy
    //   [1:1] act #2: unused (was dedup)

    // =========================================================================
    // Table #1: Action Select
    // =========================================================================

    action ing_sf_action_sel_hit(
        bit<2> action_bitmask,
  bit<16> int_ctrl_flags
//      bit<3>  discard
    ) {
        action_bitmask_internal = action_bitmask;
  int_ctrl_flags_internal = int_ctrl_flags;

//      ig_intr_md_for_dprsr.drop_ctl = discard; // drop packet
    }

    // =====================================

    action ing_sf_action_sel_miss(
    ) {
        action_bitmask_internal = 0;
  int_ctrl_flags_internal = 0;
    }

    // =====================================

    table ing_sf_action_sel {
        key = {
            hdr_0.nsh_type1.spi : exact @name("spi");
            hdr_0.nsh_type1.si : exact @name("si");
        }

        actions = {
            ing_sf_action_sel_hit;
            ing_sf_action_sel_miss;
        }

        const default_action = ing_sf_action_sel_miss;
        size = NPB_ING_SF_0_BAS_ADV_ACT_SEL_TABLE_DEPTH;
    }

    // =========================================================================
    // Table #2: IP Length Range
    // =========================================================================

 bit<16> length_bitmask_internal = 0;
# 114 "npb_ing_sf_npb_basic_adv_top.p4"
    // =========================================================================
    // Apply
    // =========================================================================

 apply {
  if(ig_md.nsh_type1.sf_bitmask[0:0] == 1) {

   // =====================================
   // Action Lookup
   // =====================================

   ing_sf_action_sel.apply();

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is becuase of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index




   // =====================================
   // Action(s)
   // =====================================

   if(action_bitmask_internal[0:0] == 1) {

    // -------------------------------------
    // Action #0 - Policy
    // -------------------------------------





    acl.apply(ig_md.lkp, ig_md, ig_intr_md_for_dprsr, length_bitmask_internal, hdr_0, hdr_2, int_ctrl_flags_internal);

   }

   if(action_bitmask_internal[1:1] == 1) {

    // -------------------------------------
    // Action #1 - Deduplication
    // -------------------------------------
/*
#ifdef SF_0_DEDUP_ENABLE
				npb_ing_sf_npb_basic_adv_dedup.apply (
					hdr_0,
					ig_md,
					ig_intr_md,
					ig_intr_md_from_prsr,
					ig_intr_md_for_dprsr,
					ig_intr_md_for_tm
				);
#endif
*/
   }

  }

 }
}
# 3 "npb_ing_top.p4" 2
# 1 "npb_egr_sf_multicast_top.p4" 1



control npb_ing_sf_multicast_top_part1 (
    inout switch_header_transport_t hdr_0,
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
    switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_ACT_SEL_TABLE_DEPTH
) {

    // temporary internal variables
    bit<1> action_bitmask_internal;

    // =========================================================================
    // Notes
    // =========================================================================

    // Note: egress action_bitmask defined as follows....
    //
    //   [0:0] act #1: multicast

    // =========================================================================
    // Table #1: Action Select
    // =========================================================================

    action ing_sf_action_sel_hit(
        bit<1> action_bitmask,
  switch_mgid_t mgid
    ) {
        action_bitmask_internal = action_bitmask;

  ig_md.multicast.id = mgid;

        ig_md.egress_port_lag_index = 0;
    }

    // =====================================

    action ing_sf_action_sel_miss(
    ) {
        action_bitmask_internal = 0;
    }

    // =====================================

    table ing_sf_action_sel {
        key = {
            hdr_0.nsh_type1.spi : exact @name("spi");
            hdr_0.nsh_type1.si : exact @name("si");
        }

        actions = {
            ing_sf_action_sel_hit;
            ing_sf_action_sel_miss;
        }

        size = table_size;
        const default_action = ing_sf_action_sel_miss;
    }

    // =========================================================================
    // Apply
    // =========================================================================

    apply {

        if(ig_md.nsh_type1.sf_bitmask[1:1] == 1) {

            // =====================================
            // Action Lookup
            // =====================================

            ing_sf_action_sel.apply();

            // =====================================
            // Decrement SI
            // =====================================

   // Moved to egress

            // =====================================
            // Action(s)
            // =====================================

            if(action_bitmask_internal[0:0] == 1) {

    // There used to be a table here that took sfc and gave mgid.  It has been removed in the latest iteration.

   }

  }

 }
}

// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sf_multicast_top_part2 (
 inout switch_header_transport_t hdr_0,
    in switch_rid_t replication_id,
    in switch_port_t port,
    inout switch_egress_metadata_t eg_md
) (
    switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1: 
 // =========================================================================


    action rid_hit(
        switch_bd_t bd,

        bit<24> spi,
        bit<8> si,
        bit<3> sf_bitmask
    ) {
        eg_md.bd = bd;

        hdr_0.nsh_type1.spi = spi;
        hdr_0.nsh_type1.si = si;
        eg_md.nsh_type1.sf_bitmask = sf_bitmask;
    }

    action rid_miss() {
    }

    table rid {
        key = {
   replication_id : exact;
  }
        actions = {
            rid_miss;
            rid_hit;
        }

        size = table_size;
        const default_action = rid_miss;
    }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  if(eg_md.nsh_type1.sf_bitmask[1:1] == 1) {

            // =====================================
            // Action Lookup
            // =====================================

            // =====================================
            // Decrement SI
            // =====================================

            // Derek: We have moved this here, rather than at the end of the sf,
            // in violation of RFC8300.  This is becuase of an issue were a sf
            // can reclassify the packet with a new si, which would then get immediately
            // decremented.  This means firmware would have to add 1 to the si value
            // the really wanted.  So move it here so that is gets decremented after
            // the lookup that uses it, but before any actions have run....

            // NOTE: THIS IS DONE IN EGRESS INSTEAD OF INGRESS, BECAUSE WE DON"T FIT OTHERWISE!


            hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index



            // =====================================
            // Action(s)
            // =====================================


   if(replication_id != 0) {
    rid.apply();
   }

  }
 }
}
# 4 "npb_ing_top.p4" 2
# 1 "npb_ing_sff_top.p4" 1
# 1 "npb_ing_sff_flow_schd.p4" 1

control npb_ing_sff_flow_schd (
 inout switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in bit<16> hash
) {

 bit<8> flow_class_internal;

 // =========================================================================
 // Notes
 // =========================================================================

 // =========================================================================
 // Table #1:
 // =========================================================================

 action ing_flow_class_hit (
  bit<8> flow_class
 ) {
  // ----- change nsh -----

  // change metadata
  flow_class_internal = flow_class;
 }

 // ---------------------------------

 table ing_flow_class {
  key = {
   hdr.nsh_type1.vpn : ternary @name("vpn");
   ig_md.lkp.mac_type : ternary @name("mac_type");
   ig_md.lkp.ip_proto : ternary @name("ip_proto");
   ig_md.lkp.l4_src_port : ternary @name("l4_src_port");
   ig_md.lkp.l4_dst_port : ternary @name("l4_dst_port");
  }

  actions = {
   NoAction;
   ing_flow_class_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFF_FLW_CLS_TABLE_DEPTH;
 }

 // =========================================================================
 // Hash:
 // =========================================================================

 // =========================================================================
 // Table #2: Action Selector
 // =========================================================================



 // Use just a plain old table...
# 103 "npb_ing_sff_flow_schd.p4"
 // ---------------------------------

 action ing_schd_hit (
  bit<24> spi,
  bit<8> si,

  bit<3> sf_bitmask
 ) {
  // ----- change nsh -----

  // change metadata

  // base - word 0

  // base - word 1
  hdr.nsh_type1.spi = spi;
  hdr.nsh_type1.si = si;

  // ext type 1 - word 0
  ig_md.nsh_type1.sf_bitmask = sf_bitmask;

  // change metadata
 }

 // ---------------------------------

 table ing_schd {
  key = {
   ig_md.nsh_type1.sfc : exact @name("sfc");





  }

  actions = {
   NoAction;
   ing_schd_hit;
  }

  const default_action = NoAction;
  size = NPB_ING_SFF_SCHD_TABLE_PART1_DEPTH;



 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  if(ig_md.nsh_type1.sfc_is_new == true) {
   ing_flow_class.apply();
   ing_schd.apply();
  }
 }

}
# 2 "npb_ing_sff_top.p4" 2

control npb_ing_sff_top (
 inout switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in bit<16> hash
) {

 bit<8> hdr_nsh_type1_si_predec; // local copy used for pre-decrementing prior to forwarding lookup.

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy

 // =========================================================================
 // Table #1: ARP
 // =========================================================================

 action drop_pkt (
 ) {
  ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
 }

 // =====================================

 action unicast(
  switch_nexthop_t nexthop_index,

  bool end_of_chain
 ) {
  ig_md.nexthop = nexthop_index;

  ig_md.nsh_terminate = end_of_chain;
 }

 // =====================================

 action multicast(
  switch_mgid_t mgid,

  bool end_of_chain
 ) {
        ig_md.multicast.id = mgid;

  ig_md.nsh_terminate = end_of_chain;
 }

 // =====================================
 // Table
 // =====================================

 table ing_sff_fib {
  key = {
   hdr.nsh_type1.spi : exact @name("spi");
//			hdr.nsh_type1.si        : exact @name("si");
   hdr_nsh_type1_si_predec : exact @name("si");
  }

  actions = {
   drop_pkt;
   multicast;
   unicast;
  }

  // Derek: drop packet on miss...
  //
  // RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
  // do not correspond to a valid next hop in a valid SFP, that packet MUST
  // be dropped by the SFF.

  const default_action = drop_pkt;
  size = NPB_ING_SFF_ARP_TABLE_DEPTH;
 }

 // =========================================================================
 // Table - SI  Decrement
 // =========================================================================

 // this table just does a 'pop count' on the bitmask....

 bit<2> nsh_si_dec_amount;

 action new_si(bit<2> dec) {
//		ig_md.nsh_type1.si = ig_md.nsh_type1.si |-| (bit<8>)dec; // saturating subtract
  nsh_si_dec_amount = dec;
 }

 // NOTE: SINCE THE FIRST SF HAS ALREADY RUN, WE ONLY NEED TO ACCOUNT FOR
 // THE REMAINING SFs...

/*
	// this is code we'd like to use, but it doesn't work! -- barefoot bug?
    table ing_sff_dec_si {
        key = { ig_md.nsh_type1.sf_bitmask[2:1] : exact; }
        actions = { new_si; }
        const entries = {
            0  : new_si(0); // 0 bits set
            1  : new_si(1); // 1 bits set
            2  : new_si(1); // 1 bits set
            3  : new_si(2); // 2 bits set
        }
    }
*/

    table ing_sff_dec_si {
        key = { ig_md.nsh_type1.sf_bitmask[2:0] : exact; }
        actions = { new_si; }
        const entries = {
            0 : new_si(0); // 0 bits set
            1 : new_si(0); // 1 bits set -- but don't count bit 0
            2 : new_si(1); // 1 bits set
            3 : new_si(1); // 2 bits set -- but don't count bit 0
            4 : new_si(1); // 1 bits set
            5 : new_si(1); // 2 bits set -- but don't count bit 0
            6 : new_si(2); // 2 bits set
            7 : new_si(2); // 3 bits set -- but don't count bit 0
        }
  const default_action = new_si(0);
    }

 // =========================================================================
 // Apply
 // =========================================================================

 // Need to do one table lookups here:
 //
 // 1: forwarding lookup, after any sf's have reclassified the packet.

 apply {
  ig_md.flags.dmac_miss = false;

  // +---------------+---------------+-----------------------------+
  // | hdr nsh valid | our nsh valid | signals / actions           |
  // +---------------+---------------+-----------------------------+
  // | n/a           | FALSE         | --> (classification failed) |
  // | FALSE         | TRUE          | --> we  classified          |
  // | TRUE          | TRUE          | --> was classified          |
  // +---------------+---------------+-----------------------------+

//		if(ig_md.nsh_type1.valid == 1) {
  if(1 == 1) {

   // Note: All of this code has to come after, serially, the first service function.
   // This is because the first service function can reclassify / change just about
   // anything with regard to the packet and it's service path.

   // -------------------------------------
   // Perform Flow Scheduling
   // -------------------------------------

// TODO: Modify these functions to include flowclass and vpn....
/*
			if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
				compute_non_ip_hash(ig_md.lkp, ig_md.hash);
			else
				compute_ip_hash(ig_md.lkp, ig_md.hash);
*/

   // -----------------

   npb_ing_sff_flow_schd.apply(
    hdr,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm,

    ig_md.hash[15:0]
   );

   // -------------------------------------
   // Pre-Decrement SI
   // -------------------------------------

   // Here we decrement the SI for all SF's we are going to do in the
   // chip.  We have to do all the decrements prior to the forwarding
   // lookup.  However, each SF still needs to do it's own decrement so
   // the the next SF gets the correct value.  Thus we don't want to
   // save this value permanently....

   ing_sff_dec_si.apply(); // do a pop-count on the bitmask

   hdr_nsh_type1_si_predec = hdr.nsh_type1.si |-| (bit<8>)nsh_si_dec_amount; // saturating subtract

   // -------------------------------------
   // Perform Forwarding Lookup
   // -------------------------------------

   ing_sff_fib.apply();

   // -------------------------------------
   // Check SI
   // -------------------------------------

   // RFC 8300: "an SFF that is not the terminal SFF for an SFP will
   // discard any NSH packet with an SI of 0, as there will be no valid
   // next SF information."

//			if((ig_md_nsh_type1_si == 0) && (ig_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtract)
//				ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//			}

   // NOTE: MOVED TO EGRESS

  }

 }

}
# 5 "npb_ing_top.p4" 2

control npb_ing_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
 inout udf_h hdr_l7_udf,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_tunnel_metadata_t tunnel_1,
 inout switch_tunnel_metadata_t tunnel_2,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

                // -------------------------------------
                // SFC
                // -------------------------------------

                npb_ing_sfc_top.apply (
                    hdr_0,
                    hdr_1,
                    hdr_2,
                    hdr_l7_udf,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm,

                    tunnel_0,
                    tunnel_1,
                    tunnel_2
                );

                // -------------------------------------
                // SF(s)
                // -------------------------------------

                npb_ing_sf_npb_basic_adv_top.apply (
                    hdr_0,
                    hdr_2,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm
                );

                // -------------------------------------

                npb_ing_sf_multicast_top_part1.apply (
                    hdr_0,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm
                );

                // -------------------------------------
                // Perform hash for SFF
                // -------------------------------------

                // extreme: this mirrors the hash the switch.p4 does

                // note: TODO - modify these hash functions to include flowclass and vpn (although I
                // question if this is really necessary, since these values are derived from the packet anyway(?) --
                // if not, then we could simply move switch.p4's hash up above from its current location down
                // below and use it's results instead of having to use our own separate hash function).

                if (ig_md.lkp.ip_type == SWITCH_IP_TYPE_NONE)
                    compute_non_ip_hash(ig_md.lkp, ig_md.hash_nsh);
                else
                    compute_ip_hash(ig_md.lkp, ig_md.hash_nsh);

                // -------------------------------------
                // SFF
                // -------------------------------------

                npb_ing_sff_top.apply (
                    hdr_0,
                    ig_md,
                    ig_intr_md,
                    ig_intr_md_from_prsr,
                    ig_intr_md_for_dprsr,
                    ig_intr_md_for_tm,

                    ig_md.hash_nsh[15:0]
                );

 }
}
# 67 "npb.p4" 2
# 1 "npb_egr_top.p4" 1




# 1 "npb_egr_sff_top.p4" 1
control npb_egr_sff_top_part1 (
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Tables
 // =========================================================================

    action new_ttl(bit<6> ttl) {
        hdr.nsh_type1.ttl = ttl;
    }

    action discard() {
//        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { hdr.nsh_type1.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0 : new_ttl(63);
//          1  : discard();
            1 : new_ttl(0);
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

  // =====================================
  // SFF
  // =====================================

  // -------------------------------------
  // Reframer
  // -------------------------------------

  // Three mutually-exclusive reframing scenarios are supported:
  //
  // 1: First  in chain --> encap
  // 2: Middle in chain --> rewrite
  // 3: Last   in chain --> decap
  //
  // Note that the example in the RFC shows either a first/middle or last -- but not
  // combinations of these.  Howver, conceivabably I suppose you could have a last
  // (i.e. decap) followed by a first (i.e. encap).  Regardless, the RFC example
  // doesn't show this, and so we don't support it (currently anyway).
  //
  // To support these three reframing scenarios, I look at three signals:
  //
  // +---------------+---------------+--------------+-------------------------------------+
  // | hdr nsh valid | our nsh valid | terminate    | signals / actions                   |
  // +---------------+---------------+--------------+-------------------------------------+
  // | n/a           | FALSE         | n/a          | --> (classification failed)         |
  // | FALSE         | TRUE          | FALSE        | --> first  / encap                  |
  // | FALSE         | TRUE          | TRUE         | --> first  / encap   & last / decap |
  // | TRUE          | TRUE          | FALSE        | --> middle / rewrite                |
  // | TRUE          | TRUE          | TRUE         | --> last   / decap                  |
  // +---------------+---------------+--------------+-------------------------------------+
  //
  // Note: The above truth table just shows how my logic handles the three scenarios,
  // although you could devise other ways to look at these signals and still get the
  // same results.

  // ----------------------------------------
  // Move NSH Metadata to NSH Header
  // ----------------------------------------

//		if((eg_md.nsh_type1.valid == 1) && (hdr.nsh_type1.isValid())) {
//		if(hdr.nsh_type1.isValid()) {
  if(eg_md.nsh_type1.hdr_is_new == false) {

   // ---------------
   // need to do a rewrite...
   // ---------------

   npb_egr_sff_dec_ttl.apply();

  } else {

   // ---------------
   // need to do a encap...
   // ---------------

//			hdr.nsh_type1.setValid();

   // base: word 0
   hdr.nsh_type1.version = 0x0;
   hdr.nsh_type1.o = 0x0;
   hdr.nsh_type1.reserved = 0x0;
   hdr.nsh_type1.ttl = 0x3f; // 63 is the rfc's recommended default value.
   hdr.nsh_type1.len = 0x6; // in 4-byte words (1 + 1 + 4).
   hdr.nsh_type1.reserved2 = 0x0;
   hdr.nsh_type1.md_type = 0x1; // 0 = reserved, 1 = fixed len, 2 = variable len.
   hdr.nsh_type1.next_proto = 0x3; // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

   // base: word 1
   // (nothing to do)

   // ext: type 1 - word 0-3
   hdr.nsh_type1.ver = 0x2; // word 0
//			hdr.nsh_type1.reserved3                = 0x0;  // word 0

   hdr.nsh_type1.reserved4 = 0x0; // word 2

  }

 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_egr_sff_top_part2 (
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: bitmask defined as follows....
 //
 //   [0:0] sf  #1: ingress basic/advanced
 //   [1:1] sf  #2: unused (was multicast)
 //   [2:2] sf  #3: egress proxy 

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =============================
  // SFF (continued)
  // =============================

//		if(eg_md.nsh_type1.valid == 1) {
  if(1 == 1) {

   // -------------------------------------
   // Check TTL & SI
   // -------------------------------------

   // RFC 8300: "an SFF that is not the terminal SFF for an SFP will
   // discard any NSH packet with an SI of 0, as there will be no valid
   // next SF information."

//			if((hdr.nsh_type1.si == 0) && (eg_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtracts)
//				eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//			}

   if(eg_md.tunnel_0.terminate == false) { // check for si of 0 (or underflow, since we used a saturating subtracts)
    if((hdr.nsh_type1.ttl == 0) || (hdr.nsh_type1.si == 0)) {
     eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
    }
   }

   // -------------------------------------
   // Fowrarding Lookup
   // -------------------------------------

   // Derek: I guess the forwarding lookup would normally
   // be done here.  However, since Tofino requires the outport
   // to set in ingress, it has to be done there instead....

  }

 }

}
# 6 "npb_egr_top.p4" 2

# 1 "npb_egr_sf_proxy_top.p4" 1
# 1 "npb_egr_sf_proxy_hdr_strip.p4" 1

control npb_egr_sf_proxy_hdr_strip (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_egress_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
     if(eg_md.nsh_type1.strip_e_tag) {
         hdr_1.e_tag.setInvalid();
     }

     if(eg_md.nsh_type1.strip_vn_tag) {
         hdr_1.vn_tag.setInvalid();
     }

     if(eg_md.nsh_type1.strip_vlan_tag) {
         hdr_1.vlan_tag[0].setInvalid();
         hdr_1.vlan_tag[1].setInvalid();
     }

 }

}
# 2 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_hdr_edit.p4" 1

control npb_egr_sf_proxy_hdr_edit (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_egress_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
 }

}
# 3 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_truncate.p4" 1

control npb_egr_sf_proxy_truncate (
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
    if(eg_md.nsh_type1.truncate) {



        }

 }

}
# 4 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_egr_sf_proxy_meter.p4" 1

control npb_egr_sf_proxy_meter (
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
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
   eg_md.action_3_meter_id : exact;
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
# 5 "npb_egr_sf_proxy_top.p4" 2
# 1 "npb_ing_sf_npb_basic_adv_dedup.p4" 1
/* -*- P4_16 -*- */

//#define DEPTH      32w65536
//#define DEPTH_POW2 16




//#define DEPTH      32w262144
//#define DEPTH_POW2 18



// =============================================================================
// =============================================================================
// Example register code, taken from "P4 Language Cheat Sheet"
// =============================================================================
// =============================================================================

struct pair_t {
 bit<16> hash;
 bit<16> data;
};

// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup_reg (
 in switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,

 in bit<17> flowtable_hash_lo,
 in bit<16> flowtable_hash_hi // always 16 bits
) {

 // =========================================================================
 // The Register Array
 // =========================================================================

 Register <pair_t, bit<17>>(32w131072) test_reg; // syntax seems to be <data type, index type>

 // =========================================================================

 RegisterAction<pair_t, bit<17>, bit<8>>(test_reg) register_array = { // syntax seems to be <data type, index type, return type>
  void apply(
   inout pair_t reg_value, // register entry
   out bit<8> return_value // return value
  ) {
   if(reg_value.hash == flowtable_hash_hi) {
    // existing flow
    // --------
    if(reg_value.data == (bit<16>)(eg_md.ingress_port)) {
     // same port
     // --------
     return_value = 0; // pass packet
    } else {
     // different port
     // --------
     return_value = 1; // drop packet
    }
   } else {
    // new flow (entry collision, overwrite old flow)
    // --------
    // update entry
    reg_value.hash = flowtable_hash_hi;
    reg_value.data = (bit<16>)(eg_md.ingress_port);

    return_value = 0; // pass packet
   }
  }
 };

 // =========================================================================
 // The Apply Block
 // =========================================================================

 apply {

  bit<8> return_value;

  // ***** hash the key *****
//		flowtable_hash_lo = flowtable_hash[15: 0];
//		flowtable_hash_hi = flowtable_hash[31:16];

  // ***** use hashed key to index register *****
  return_value = register_array.execute(flowtable_hash_lo);

  // ***** drop packet? *****
  if(return_value != 0) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
  }

 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================

control npb_ing_sf_npb_basic_adv_dedup (
 in switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 npb_ing_sf_npb_basic_adv_dedup_reg() npb_ing_sf_npb_basic_adv_dedup_reg_0;

 bit<32> flowtable_hash;

 bit<17> flowtable_hash_lo;
 bit<16> flowtable_hash_hi; // always 16 bits

 // =========================================================================
 // The Hash Function
 // =========================================================================




 Hash<bit<17>>(HashAlgorithm_t.CRC32) h_lo;
 Hash<bit<16 >>(HashAlgorithm_t.CRC16) h_hi; // always 16 bits


 // =========================================================================
 // The Apply Block
 // =========================================================================

 apply {
  // ***** hash the key *****





  flowtable_hash_lo = h_lo.get({eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port});
  flowtable_hash_hi = h_hi.get({eg_md.lkp.ip_src_addr, eg_md.lkp.ip_dst_addr, eg_md.lkp.ip_proto, eg_md.lkp.l4_src_port, eg_md.lkp.l4_dst_port});


  // note: the register code has been structured such that multiple
  // registers can be laid down, perhaps using the upper bits of the hash
  // to select between them....

  // ***** call dedup function *****
  npb_ing_sf_npb_basic_adv_dedup_reg_0.apply (
   hdr,
   eg_md,
   eg_intr_md,
   eg_intr_md_from_prsr,
   eg_intr_md_for_dprsr,
   eg_intr_md_for_oport,

   flowtable_hash_lo,
   flowtable_hash_hi
  );

 }
}
# 6 "npb_egr_sf_proxy_top.p4" 2

# 1 "acl.p4" 1
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
 ******************************************************************************/
# 8 "npb_egr_sf_proxy_top.p4" 2

control npb_egr_sf_proxy_top (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_egress_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 EgressAcl(
  EGRESS_IPV4_ACL_TABLE_SIZE,


  EGRESS_IPV6_ACL_TABLE_SIZE,

  EGRESS_MAC_ACL_TABLE_SIZE
 ) acl;

 // =========================================================================
 // Notes
 // =========================================================================

 // Note: egress action_bitmask defined as follows....
 //
 //   [0:0] act #1: policy
 //   [1:1] act #2: header strip
 //   [2:2] act #3: header edit
 //   [3:3] act #4: truncate
 //   [4:4] act #5: meter
 //   [5:5] act #6: dedup

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 action egr_sf_action_sel_hit(
  bit<16> dsap,
  bit<6> action_bitmask,
  bit<10> action_3_meter_id,
  bit<8> action_3_meter_overhead
//		bit<3>                                                discard
 ) {
  eg_md.nsh_type1.dsap = dsap;

  eg_md.action_bitmask = action_bitmask;

  eg_md.action_3_meter_id = action_3_meter_id;
  eg_md.action_3_meter_overhead = action_3_meter_overhead;

//		eg_intr_md_for_dprsr.drop_ctl = discard; // drop packet
 }

 // =====================================

 action egr_sf_action_sel_miss(
 ) {
  eg_md.action_bitmask = 0;
 }

 // =====================================

 table egr_sf_action_sel {
  key = {
      hdr_0.nsh_type1.spi : exact @name("spi");
      hdr_0.nsh_type1.si : exact @name("si");
  }

  actions = {
      egr_sf_action_sel_hit;
      egr_sf_action_sel_miss;
  }

  const default_action = egr_sf_action_sel_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_ACT_SEL_TABLE_DEPTH;
 }

 // =========================================================================
 // Table #x: Ip Length Range
 // =========================================================================

    bit<16> length_bitmask_internal = 0;
# 123 "npb_egr_sf_proxy_top.p4"
 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  if(eg_md.nsh_type1.sf_bitmask[2:2] == 1) {

   // ==================================
   // Action Lookup
   // ==================================

   egr_sf_action_sel.apply();

   // ==================================
   // Decrement SI
   // ==================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is becuase of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   hdr_0.nsh_type1.si = hdr_0.nsh_type1.si - 1; // decrement sp_index




   // ==================================
   // Actions(s)
   // ==================================

   if(eg_md.action_bitmask[0:0] == 1) {

    // ----------------------------------
    // Action #0 - Policy
    // ----------------------------------





    // multiple small policy tables....
    acl.apply(eg_md.lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask_internal, hdr_0);

   }

   if(eg_md.action_bitmask[1:1] == 1) {

    // ----------------------------------
    // Action #1 - Hdr Strip
    // ----------------------------------
    npb_egr_sf_proxy_hdr_strip.apply (
     hdr_0,
     hdr_1,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

   }

   if(eg_md.action_bitmask[2:2] == 1) {

    // ----------------------------------
    // Action #2 - Hdr Edit
    // ----------------------------------
    npb_egr_sf_proxy_hdr_edit.apply (
     hdr_0,
     hdr_1,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

   }

   if(eg_md.action_bitmask[3:3] == 1) {

    // ----------------------------------
    // Action #3 - Truncate
    // ----------------------------------
    npb_egr_sf_proxy_truncate.apply (
     hdr_0,
     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

   }

   if(eg_md.action_bitmask[4:4] == 1) {

    // ----------------------------------
    // Action #4 - Meter
    // ----------------------------------
# 238 "npb_egr_sf_proxy_top.p4"
   }

   if(eg_md.action_bitmask[5:5] == 1) {

    // ----------------------------------
    // Action #5 - Deduplication
    // ----------------------------------
# 255 "npb_egr_sf_proxy_top.p4"
   }

  }
 }
}

// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
// =============================================================================
/*
control npb_egr_sf_proxy_top_part2 (
	inout switch_header_transport_t                   hdr_0,
	inout switch_header_outer_t                       hdr_1,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: egress action_bitmask defined as follows....
	//
	//   [0:0] act #1: unused (was header strip)
	//   [1:1] act #2: unused (was header edit)
	//   [2:2] act #3: unused (reserved for truncate)
	//   [3:3] act #4: meter
	//   [4:4] act #5: dedup

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		if(eg_md.nsh_type1.sf_bitmask[2:2] == 1) {

			// ==================================
			// Actions(s)
			// ==================================

			if(eg_md.action_bitmask[0:0] == 1) {

				// ----------------------------------
				// Action #0 - Policy
				// ----------------------------------

#ifdef SF_2_LEN_RNG_TABLE_ENABLE
				egr_sf_ip_len_rng.apply();
#endif

				// multiple small policy tables....
				acl.apply(eg_md.lkp, eg_md, eg_intr_md_for_dprsr, length_bitmask_internal);

			}

			if(eg_md.action_bitmask[1:1] == 1) {

				// ----------------------------------
				// Action #1 - Hdr Strip
				// ----------------------------------
				npb_egr_sf_proxy_hdr_strip.apply (
					hdr_0,
					hdr_1,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

			}

			if(eg_md.action_bitmask[2:2] == 1) {

				// ----------------------------------
				// Action #2 - Hdr Edit
				// ----------------------------------
				npb_egr_sf_proxy_hdr_edit.apply (
					hdr_0,
					hdr_1,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

			}

			if(eg_md.action_bitmask[3:3] == 1) {

				// ----------------------------------
				// Action #3 - Truncate
				// ----------------------------------
				npb_egr_sf_proxy_truncate.apply (
					hdr_0,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

			}

			if(eg_md.action_bitmask[4:4] == 1) {

				// ----------------------------------
				// Action #4 - Meter
				// ----------------------------------
#ifdef SF_2_METER_ENABLE
				npb_egr_sf_proxy_meter.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}

			if(eg_md.action_bitmask[5:5] == 1) {

				// ----------------------------------
				// Action #5 - Deduplication
				// ----------------------------------
#ifdef SF_2_DEDUP_ENABLE
				npb_ing_sf_npb_basic_adv_dedup.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);
#endif
			}
		}
	}
}
*/
# 8 "npb_egr_top.p4" 2

# 1 "scoper.p4" 1
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
 ******************************************************************************/
# 10 "npb_egr_top.p4" 2

control npb_egr_top (
    inout switch_header_transport_t hdr_0,
    inout switch_header_outer_egress_t hdr_1,
    inout switch_header_inner_egress_t hdr_2,
    inout switch_tunnel_metadata_t tunnel_1,
    inout switch_tunnel_metadata_t tunnel_2,
    inout switch_egress_metadata_t eg_md,

    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {
 Scoper() scoper0;
 Scoper() scoper1;






    TunnelDecapOuter(switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
    TunnelDecapInner(switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

        // -------------------------------------
        // SFF Part 1 --> *** before reframing ***
        // -------------------------------------

        npb_egr_sff_top_part1.apply (
            hdr_0,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------
        // Scoper
        // -------------------------------------

  vlan_tag_h vlan_tag_dummy;

// 		if(hdr_0.nsh_type1.scope == 0) {
// 			scoper0.apply(
// 				hdr_1.ethernet,
// 				hdr_1.vlan_tag[0],
// 				hdr_1.vlan_tag[1].isValid(),
// 				hdr_1.vlan_tag[1],
// 				hdr_1.ipv4,
// #ifdef IPV6_ENABLE
// 				hdr_1.ipv6.isValid(),
// 				hdr_1.ipv6,
// #endif  /* IPV6_ENABLE */
// 				hdr_1.tcp.isValid(),
// 				hdr_1.tcp,
// 				hdr_1.udp,
// 				hdr_1.sctp,
// 				tunnel_1.type,
// 				tunnel_1.id,
// 				eg_md.drop_reason_1,
// 
// 				eg_md.lkp
// 			);
// 
// #ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
// 			eg_md.nsh_type1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE;
// 			eg_md.nsh_type1.tunnel_inner_type = eg_md.tunnel_2.type;
// #endif
// 		} else {
// 			scoper1.apply(
// 				hdr_2.ethernet,
// 				hdr_2.vlan_tag[0],
// 				false,             // inner only has 1 vlan...set the valid false
//  				hdr_2.vlan_tag[0], // inner only has 1 vlan...send in anything that will compile
// //				vlan_tag_dummy,    // inner only has 1 vlan...send in anything that will compile
// 				hdr_2.ipv4,
// #ifdef IPV6_ENABLE
// 				hdr_2.ipv6.isValid(),
// 				hdr_2.ipv6,
// #endif  /* IPV6_ENABLE */
// 				hdr_2.tcp.isValid(),
// 				hdr_2.tcp,
// 				hdr_2.udp,
// 				hdr_2.sctp,
// 				tunnel_2.type,
// 				tunnel_2.id,
// 				eg_md.drop_reason_2,
// 
// 				eg_md.lkp
// 			);
// 
// #ifdef SF_2_ACL_INNER_OUTER_TUNNEL_KEY_ENABLE
// 			eg_md.nsh_type1.tunnel_outer_type = eg_md.tunnel_1.type;
// 			eg_md.nsh_type1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE;
// #endif
// 		}

        // -------------------------------------
        // Scoper
        // -------------------------------------

  // This code is an experment to mux the signals before the scoper code.  It blows out of phv in spectacular fashion....
/*
		ethernet_h ethernet;
		vlan_tag_h[2] vlan_tag;
		ipv4_h ipv4;
		ipv6_h ipv6;
		tcp_h tcp;
		udp_h udp;
		sctp_h sctp;
		switch_tunnel_type_t tunnel_type;
        switch_tunnel_id_t tunnel_id;

		if(eg_md.nsh_type1.scope == 0) {
			ethernet    = hdr_1.ethernet;
			vlan_tag[0] = hdr_1.vlan_tag[0];
			vlan_tag[1] = hdr_1.vlan_tag[1];
			ipv4        = hdr_1.ipv4;
			ipv6        = hdr_1.ipv6;
			tcp         = hdr_1.tcp;
			udp         = hdr_1.udp;
			sctp        = hdr_1.sctp;
			tunnel_type = tunnel_1.type;
			tunnel_id   = tunnel_1.id;
		} else {
			ethernet    = hdr_2.ethernet;
			vlan_tag[0] = hdr_2.vlan_tag[0];
//			vlan_tag[1] = hdr_2.vlan_tag[1];
			vlan_tag[1].setInvalid(); // inner only has 1 vlan
			ipv4        = hdr_2.ipv4;
			ipv6        = hdr_2.ipv6;
			tcp         = hdr_2.tcp;
			udp         = hdr_2.udp;
			sctp        = hdr_2.sctp;
			tunnel_type = tunnel_2.type;
			tunnel_id   = tunnel_2.id;
		}

        // -------------------------------------

		scoper.apply(
			ethernet,
			vlan_tag[0],
			vlan_tag[1].isValid(),
			vlan_tag[1],
			ipv4,
#ifdef IPV6_ENABLE
			ipv6.isValid(),
			ipv6,
#endif
			tcp.isValid(),
			tcp,
			udp,
			sctp,
			tunnel_type,
			tunnel_id,

			eg_md.lkp
		);
*/
        // -------------------------------------
        // Scoper
        // -------------------------------------
/*
#ifdef VALIDATION_ENABLE
        // set scope
        if(eg_md.nsh_type1.scope == 0) {
            // validates and copies ***outer*** to lkp struct.
            pkt_validation_outer.apply(hdr_1, eg_md.flags.ipv4_checksum_err_1, tunnel_1, eg_md.lkp, eg_md.drop_reason_1);
        } else {
            // validates and copies ***inner*** to lkp struct.
            pkt_validation_inner.apply(hdr_2, eg_md.flags.ipv4_checksum_err_2, tunnel_2, eg_md.lkp, eg_md.drop_reason_2);
        }
#endif

*/
        // -------------------------------------
        // SF(s): Part 1 --> *** before reframing ***
        // -------------------------------------

        npb_egr_sf_multicast_top_part2.apply (
   hdr_0,
   eg_intr_md.egress_rid,
   eg_intr_md.egress_port,
   eg_md
        );

        // -------------------------------------

        npb_egr_sf_proxy_top.apply (
            hdr_0,
            hdr_1,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

        // -------------------------------------
  // Reframing
        // -------------------------------------

        tunnel_decap_outer.apply(hdr_0, hdr_1, eg_md, tunnel_1);
        tunnel_decap_inner.apply(hdr_0, hdr_2, eg_md, tunnel_2);
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0);

        // -------------------------------------
        // SF(s): Part 2 --> *** after reframing ***
        // -------------------------------------
/*
        npb_egr_sf_proxy_top_part2.apply (
            hdr_0,
            hdr_1,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );
*/
        // -------------------------------------
        // SFF: Part 2 --> *** after reframing ***
        // -------------------------------------

        npb_egr_sff_top_part2.apply (
            hdr_0,
            eg_md,
            eg_intr_md,
            eg_intr_md_from_prsr,
            eg_intr_md_for_dprsr,
            eg_intr_md_for_oport
        );

 }
}
# 68 "npb.p4" 2


# 1 "npb_ing_hdr_stack_counters.p4" 1


control IngressHdrStackCounters(
    in switch_header_t hdr
) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;

    // ------------------------------------------------------------
    // transport stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_transport_stack_hdr_cntr() {
        transport_stack_hdr_cntrs.count();
    }

    table transport_stack_hdr_cntr_tbl {
        key = {
            hdr.transport.ethernet.isValid(): exact;
            hdr.transport.vlan_tag[0].isValid(): exact;
            hdr.transport.nsh_type1.isValid(): exact;






        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }

        size = 3;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_transport_stack_hdr_cntr;
        // const default_action = bump_transport_stack_unexpected_hdr_cntr;
        counters = transport_stack_hdr_cntrs;

        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
// #ifndef ERSPAN_ENABLE
//             //enet   vlan0  nsh
// 
//             // None
//             ( false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // NSH
//             ( true,  false, true ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true ): bump_transport_stack_hdr_cntr;
// #else
//             //enet  vlan0   nsh    ipv4   gre    greSeq erspan 
// 
//             // None
//             ( false, false, false, false, false, false, false ): bump_transport_stack_hdr_cntr;
// 
//             // NSH
//             ( true,  false, true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  true,  false, false, false, false ): bump_transport_stack_hdr_cntr; 
// 
//             // ERSPAN-TYPE1
//             ( true,  false, false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  false, true  ): bump_transport_stack_hdr_cntr;
// 
//             // ERSPAN-TYPE2
//             ( true,  false, false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
//             ( true,  true,  false, true,  true,  true,  true  ): bump_transport_stack_hdr_cntr; 
// 
// 
// #endif // ERSPAN_ENABLE
//         }
    }


    // ------------------------------------------------------------
    // outer stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_outer_stack_hdr_cntr() {
        outer_stack_hdr_cntrs.count();
    }

    table outer_stack_hdr_cntr_tbl {
        key = {
            hdr.outer.ethernet.isValid(): exact;
            hdr.outer.e_tag.isValid(): exact;
            hdr.outer.vn_tag.isValid(): exact;
            hdr.outer.vlan_tag[0].isValid(): exact;
            hdr.outer.vlan_tag[1].isValid(): exact;

            hdr.outer.arp.isValid(): exact;
            hdr.outer.ipv4.isValid(): exact;
            hdr.outer.ipv6.isValid(): exact;

            hdr.outer.icmp.isValid(): exact;
            hdr.outer.igmp.isValid(): exact;
            hdr.outer.udp.isValid(): exact;
            hdr.outer.tcp.isValid(): exact;
            hdr.outer.sctp.isValid(): exact;

            hdr.outer.gre.isValid(): exact;
            hdr.outer.esp.isValid(): exact;

            hdr.outer.vxlan.isValid(): exact;
            hdr.outer.nvgre.isValid(): exact;
            hdr.outer.gtp_v1_base.isValid(): exact;
            hdr.outer.gtp_v2_base.isValid(): exact;
            hdr.outer.gtp_v1_v2_teid.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        size = 217;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_outer_stack_hdr_cntr;
        counters = outer_stack_hdr_cntrs;
        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2 gtp_teid
// 
//             // None (invalid)
//             ( false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2
//             ( true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / ARP
//             ( true,  false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV4
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV6
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2 gtp_teid
// 
//             // L2 / L3 / ICMP
//             ( true,  false, false, false, false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//                      
//             ( true,  false, false, false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  true,  false, false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV4 / IGMP
//             ( true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//                      
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2 gtp_teid
// 
//             // L2 / L3 / UDP
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / TCP
//             ( true,  false, false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / SCTP
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//                      
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, true,  false, false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2 gtp_teid
// 
//             // L2 / L3 / GRE
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / IPV4 / ESP
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, false, true,  false, false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
// 
//             //enet   etag   vntag  vlan0  vlan1  arp    ipv4   ipv6   icmp   igmp   udp    tcp    sctp   gre    esp    vxlan  nvgre  gtp_v1 gtp_v2 gtp_teid
// 
//             // L2 / L3 / L4 / VXLAN
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, true,  false, false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / L4 / NVGRE
//             ( true,  false, false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, false, false, false, true,  false, false, true,  false, false, false ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / L4 / GTP-U
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, true,  false, true  ): bump_outer_stack_hdr_cntr;
// 
//             // L2 / L3 / L4 / GTP-C
//             ( true,  false, false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, true,  false, false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
// 
//             ( true,  false, false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  false, false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  false, false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//             ( true,  false, true,  true,  true,  false, false, true,  false, false, true,  false, false, false, false, false, false, false, true,  true  ): bump_outer_stack_hdr_cntr;
//         }
    }



    // ------------------------------------------------------------
    // inner stack --------------------------------------------
    // ------------------------------------------------------------

    action bump_inner_stack_hdr_cntr() {
        inner_stack_hdr_cntrs.count();
    }

    table inner_stack_hdr_cntr_tbl {
        key = {
            hdr.inner.ethernet.isValid(): exact;
            hdr.inner.vlan_tag[0].isValid(): exact;

            //hdr.inner.arp.isValid(): exact;
            hdr.inner.ipv4.isValid(): exact;
            hdr.inner.ipv6.isValid(): exact;

            //hdr.inner.icmp.isValid(): exact;
            //hdr.inner.igmp.isValid(): exact;
            hdr.inner.udp.isValid(): exact;
            hdr.inner.tcp.isValid(): exact;
            hdr.inner.sctp.isValid(): exact;

            //hdr.inner.gre.isValid(): exact;        
            //hdr.inner.esp.isValid(): exact;

            //hdr.inner.gtp_v1_base.isValid(): exact;
            //hdr.inner.gtp_v2_base.isValid(): exact;
            //hdr.inner.gtp_v1_v2_teid.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        size = 27;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_inner_stack_hdr_cntr;
        counters = inner_stack_hdr_cntrs;
        // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
// 
// //#ifdef IPV6_ENABLE
// 
//             //enet   vlan0  ipv4   ipv6   udp    tcp    sctp   gre    esp
// 
//             // None (invalid)
//             ( false, false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2                                             
//             ( true,  false, false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, false, false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3                                        
//             ( true,  false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3 / UDP                                  
//             ( true,  false, true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3 / TCP                                  
//             ( true,  false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L2 / L3 / SCTP                                 
//             ( true,  false, true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  false, false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( true,  true,  false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
//
//             // L3                                        
//             ( false, false, true,  false, false, false, false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L3 / UDP                                  
//             ( false, false, true,  false, true,  false, false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  true,  false, false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L3 / TCP                                  
//             ( false, false, true,  false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, true,  false ): bump_inner_stack_hdr_cntr;
//                                                               
//             // L3 / SCTP                                 
//             ( false, false, true,  false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             ( false, false, false, true,  false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // // L2 / L3 / GRE
//             // ( true,  false, true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  true,  false, false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  false, false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  false, true,  false, false, false, true,  false ): bump_inner_stack_hdr_cntr;
// 
//             // // L2 / IPV4 / ESP
//             // ( true,  false, true,  false, false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
//             // ( true,  true,  true,  false, false, false, false, false, true  ): bump_inner_stack_hdr_cntr;
// 
//             // // L3 / GRE
//             // // L3 / ESP
//         }
    }



    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();
    }

}
# 71 "npb.p4" 2


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchIngress(
    inout switch_header_t hdr,
    inout switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

    // ---------------------------------------------------------------------

    IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE, PORT_TABLE_SIZE, VLAN_TABLE_SIZE) ingress_port_mapping;







    DMAC(MAC_TABLE_SIZE) dmac;
//  IngressBd(BD_TABLE_SIZE) bd_stats;
//  IngressUnicast(RMAC_TABLE_SIZE) unicast;
 IngressTunnelRMAC(RMAC_TABLE_SIZE) rmac;

    Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;
    OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;
    LAG() lag;
    TunnelDecapTransportIngress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;

    OpaqueStackLength_1() opaque_stack_length_1;
    OpaqueStackLength_2() opaque_stack_length_2;

    // ---------------------------------------------------------------------

    apply {

        // -----------------------------------------------------
        // Extreme Networks - Added
        // -----------------------------------------------------


        IngressHdrStackCounters.apply(hdr);


        // -----------------------------------------------------

        ig_intr_md_for_dprsr.drop_ctl = 0;
        ig_md.multicast.id = 0;
# 216 "npb.p4"
        add_bridged_md(hdr.bridged_md, ig_md);

        set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);


  tunnel_decap_transport_ingress.apply(hdr.transport, ig_md, ig_md.tunnel_0);



    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control SwitchEgress(
    inout switch_header_egress_t hdr,
    inout switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

    // -------------------------------------------------------------------------

    EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;



    TunnelDecapTransportEgress(switch_tunnel_mode_t.PIPE) tunnel_decap_transport_egress;
//  VlanDecap() vlan_decap;
    Rewrite(NEXTHOP_TABLE_SIZE, BD_TABLE_SIZE) rewrite;
    TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
    TunnelRewrite() tunnel_rewrite;
    VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
//	NSHTypeFixer() nsh_type_fixer;

    // -------------------------------------------------------------------------

    apply {


        hdr.outer.opaque_length.setInvalid(); // could do this in parser
        hdr.inner.opaque_length.setInvalid(); // could do this in parser


        eg_intr_md_for_dprsr.drop_ctl = 0;
//      eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];
        egress_port_mapping.apply(hdr.transport, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);



  if((hdr.transport.nsh_type1.isValid() == true)) {

         npb_egr_top.apply (
             hdr.transport,
             hdr.outer,
             hdr.inner,
                eg_md.tunnel_1,
                eg_md.tunnel_2,

             eg_md,
             eg_intr_md,
             eg_intr_md_from_prsr,
             eg_intr_md_for_dprsr,
             eg_intr_md_for_oport
         );

  }

//      vlan_decap.apply(hdr.transport, eg_md);



        tunnel_decap_transport_egress.apply(hdr.transport, eg_md, eg_md.tunnel_0, eg_md.nsh_terminate);
        rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
        tunnel_encap.apply(hdr.transport, hdr.outer, eg_md, eg_md.tunnel_0);
        tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);

        vlan_xlate.apply(hdr.transport, eg_md);
//		nsh_type_fixer.apply(hdr.transport);


    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
        NpbIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        NpbEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
