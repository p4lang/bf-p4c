# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/pgm_sp_npb_vcpFw_top.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/pgm_sp_npb_vcpFw_top.p4"




# 1 "/mnt/build/p4c/p4include/t2na.p4" 1




# 1 "/mnt/build/p4c/p4include/tofino2_specs.p4" 1



/**
 Version Notes:

 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

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
@noWarn("unused")
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
# 17 "/mnt/build/p4c/p4include/tofino2_specs.p4" 2

// ----------------------------------------------------------------------------
// COMMON TYPES
// ----------------------------------------------------------------------------

typedef bit<9> PortId_t; // Port id -- ingress or egress port

typedef bit<16> MulticastGroupId_t; // Multicast group id

typedef bit<7> QueueId_t; // Queue id

typedef bit<4> MirrorType_t; // Mirror type

typedef bit<8> MirrorId_t; // Mirror id

typedef bit<3> ResubmitType_t; // Resubmit type

typedef bit<3> DigestType_t; // Digest type

typedef bit<16> ReplicationId_t; // Replication id

typedef bit<16> L1ExclusionId_t; // L1 Exclusion id

typedef bit<9> L2ExclusionId_t; // L2 Exclusion id

// CloneId_t will be deprecated in 9.4. Adding a typedef for any old references.
typedef MirrorType_t CloneId_t;

typedef error ParserError_t;


const bit<32> PORT_METADATA_SIZE = 32w192;
# 6 "/mnt/build/p4c/p4include/t2na.p4" 2






# 1 "/mnt/build/p4c/p4include/tofino2_arch.p4" 1



/**
 Version Notes:

 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

*/

# 1 "/mnt/build/p4c/p4include/tofino2_base.p4" 1



/**
 Version Notes:

 0.6.0:
 - Initial release
 0.6.1:
 - Rename PARSER_ERROR_NO_TCAM to PARSER_ERROR_NO_MATCH
 0.6.2:
 - Add portable macros and types
 1.0.1:
 - Restructuralize P4 header files (t2na.p4 -> tofino2_specs.p4 + tofino2_base.p4 + tofino2_arch.p4)
   - t2na.p4               : Top-level header file to be included by P4 programs, includes the below
     -> tofino2_specs.p4   : Target-device-specific types, constants and macros
     -> tofino2_arch.p4    : Portable parsers, controls and packages (originally tofino2arch.p4)
        -> tofino2_base.p4 : Portable constants, headers, externs etc. (originally tofino2.p4)

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
# 26 "/mnt/build/p4c/p4include/tofino2_base.p4" 2

//XXX Open issues:
// Meter color
// Math unit
// Action selector
// Digest
// Coalesce mirroring

const bit<16> PARSER_ERROR_OK = 16w0x0000;
const bit<16> PARSER_ERROR_NO_MATCH = 16w0x0001;
const bit<16> PARSER_ERROR_PARTIAL_HDR = 16w0x0002;
const bit<16> PARSER_ERROR_CTR_RANGE = 16w0x0004;
const bit<16> PARSER_ERROR_TIMEOUT_USER = 16w0x0008;
const bit<16> PARSER_ERROR_TIMEOUT_HW = 16w0x0010;
const bit<16> PARSER_ERROR_SRC_EXT = 16w0x0020;
const bit<16> PARSER_ERROR_PHV_OWNER = 16w0x0080;
const bit<16> PARSER_ERROR_MULTIWRITE = 16w0x0100;
const bit<16> PARSER_ERROR_ARAM_MBE = 16w0x0400;
const bit<16> PARSER_ERROR_FCS = 16w0x0800;
const bit<16> PARSER_ERROR_CSUM_MBE = 16w0x1000;

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
    dleft_hash, // Used for dleft dynamic caching
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

    @padding bit<(4 - 9 % 8)> _pad2;

    PortId_t ingress_port; // Ingress physical port id.
                                        // this field is passed to the deparser

    bit<48> ingress_mac_tstamp; // Ingress IEEE 1588 timestamp (in nsec)
                                        // taken at the ingress MAC.
}

@__intrinsic_metadata
struct ingress_intrinsic_metadata_for_tm_t {
    PortId_t ucast_egress_port; // Egress port for unicast packets. must
                                        // be presented to TM for unicast.

    bit<1> bypass_egress; // Request flag for the warp mode
                                        // (egress bypass).

    bit<1> deflect_on_drop; // Request for deflect on drop. must be
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

    L1ExclusionId_t level1_exclusion_id; // Exclusion id for multicast
                                        // replication-tree level1. used for
                                        // pruning.

    L2ExclusionId_t level2_exclusion_id; // Exclusion id for multicast
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
    DigestType_t digest_type;

    ResubmitType_t resubmit_type;

    MirrorType_t mirror_type; // The user-selected mirror field list
                                        // index.

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bit<1> mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bit<1> mirror_multicast_ctrl; // Mirror enable multicast if true.
    PortId_t mirror_egress_port; // Mirror packet egress port.
    QueueId_t mirror_qid; // Mirror packet qid.
    bit<8> mirror_coalesce_length; // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    bit<32> adv_flow_ctl; // Advanced flow control for TM
    bit<14> mtu_trunc_len; // MTU for truncation check
    bit<1> mtu_trunc_err_f; // MTU truncation error flag

    bit<3> learn_sel; // Learn quantum table selector
    bit<1> pktgen; // trigger packet generation
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
    @padding bit<(8 - 9 % 8)> _pad0;

    PortId_t egress_port; // Egress port id.
                                        // this field is passed to the deparser

    @padding bit<5> _pad1;

    bit<19> enq_qdepth; // Queue depth at the packet enqueue
                                        // time.

    @padding bit<6> _pad2;

    bit<2> enq_congest_stat; // Queue congestion status at the packet
                                        // enqueue time.

    bit<32> enq_tstamp; // Time snapshot taken when the packet
                                        // is enqueued (in nsec).

    @padding bit<5> _pad3;

    bit<19> deq_qdepth; // Queue depth at the packet dequeue
                                        // time.

    @padding bit<6> _pad4;

    bit<2> deq_congest_stat; // Queue congestion status at the packet
                                        // dequeue time.

    bit<8> app_pool_congest_stat; // Dequeue-time application-pool
                                        // congestion status. 2bits per
                                        // pool.

    bit<32> deq_timedelta; // Time delta between the packet's
                                        // enqueue and dequeue time.

    bit<16> egress_rid; // L3 replication id for multicast
                                        // packets.

    @padding bit<7> _pad5;

    bit<1> egress_rid_first; // Flag indicating the first replica for
                                        // the given multicast group.

    @padding bit<(8 - 7 % 8)> _pad6;

    QueueId_t egress_qid; // Egress (physical) queue id within a MAC via which
                                        // this packet was served.

    @padding bit<5> _pad7;

    bit<3> egress_cos; // Egress cos (eCoS) value.

    @padding bit<7> _pad8;

    bit<1> deflection_flag; // Flag indicating whether a packet is
                                        // deflected due to deflect_on_drop.

    bit<16> pkt_length; // Packet length, in bytes

    @padding bit<8> _pad9; // Pad to 4-byte alignment for egress
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

    MirrorType_t mirror_type;

    bit<1> coalesce_flush; // Flush the coalesced mirror buffer

    bit<7> coalesce_length; // The number of bytes in the current
                                        // packet to collect in the mirror
                                        // buffer

    bit<1> mirror_io_select; // Mirror incoming or outgoing packet

    // Setting the following metadata will override the value in mirror table
    bit<13> mirror_hash; // Mirror hash field.
    bit<3> mirror_ingress_cos; // Mirror ingress cos for PG mapping.
    bit<1> mirror_deflect_on_drop; // Mirror enable deflection on drop if true.
    bit<1> mirror_multicast_ctrl; // Mirror enable multicast if true.
    PortId_t mirror_egress_port; // Mirror packet egress port.
    QueueId_t mirror_qid; // Mirror packet qid.
    bit<8> mirror_coalesce_length; // Mirror coalesced packet max sample
                                        // length. Unit is quad bytes.
    bit<32> adv_flow_ctl; // Advanced flow control for TM
    bit<14> mtu_trunc_len; // MTU for truncation check
    bit<1> mtu_trunc_err_f; // MTU truncation error flag
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
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<8> _pad2;

    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_port_down_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<(16 - 9 % 8)> _pad2;
    PortId_t port_num; // Port number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_recirc_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<8> _pad2;
    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_deparser_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<8> _pad2;
    bit<16> batch_id; // Start at 0 and increment to a
                                        // programmed number

    bit<16> packet_id; // Start at 0 and increment to a
                                        // programmed number
}

header pktgen_pfc_header_t {
    @padding bit<2> _pad1;
    bit<2> pipe_id; // Pipe id
    bit<4> app_id; // Application id
    @padding bit<40> _pad2;
};

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
// Tofino2 parser counter can be used to extract header stacks or headers with
// variable length. Tofino2 has a single 8-bit signed counter that can be
// initialized with an immediate value or a header field.
//
// On Tofino2, the parser counter also comes with a shallow stack (with depth of 4).
// The counter stack is useful when parsing nested TLV headers (e.g. GENEVE-like options
// where the total option length is variable and each individual option length is
// also variable).

extern ParserCounter {
    /// Constructor
    ParserCounter();

    /// Load the counter with an immediate value or a header field.
    void set<T>(in T value);

    /// Load the counter with a header field.
    /// @param max : Maximum permitted value for counter (pre rotate/mask/add).
    /// @param rotate : Right rotate (circular) the source field by this number of bits.
    /// @param mask : Mask the rotated source field.
    /// @param add : Constant to add to the rotated and masked lookup field.
    void set<T>(in T field,
                in bit<8> max,
                in bit<8> rotate,
                in bit<8> mask,
                in bit<8> add);

    /// Push the immediate value or a header field onto the stack.
    /// @param update_with_top : update the pushed value when the top-of-stack value is updated.
    void push<T>(in T value, @optional bool update_with_top);

    /// Push the header field onto the stack.
    /// @param update_with_top : update the pushed value when the top-of-stack value is updated.
    void push<T>(in T field,
                 in bit<8> max,
                 in bit<8> rotate,
                 in bit<8> mask,
                 in bit<8> add,
                 @optional bool update_with_top);

    /// Pop the top-of-stack value from the stack.
    void pop();

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

extern void funnel_shift_right<T>(out T dst, in T src1, in T src2, int shift_amount);

extern void invalidate<T>(in T field);

/// Phase0
extern T port_metadata_unpack<T>(packet_in pkt);

extern bit<32> sizeInBits<H>(in H h);

extern bit<32> sizeInBytes<H>(in H h);

/// Counter
/// Indexed counter with `size’ independent counter values.
@noWarn("unused")
extern Counter<W, I> {
    /// Constructor
    /// @type_param W : width of the counter value.
    /// @type_param I : width of the counter index.
    /// @param type : counter type. Packet an byte counters are supported.
    /// @param true_egress_accounting : Use the final byte count from egress deparser after the final
    ///                                 output packet has been re-assembled (available in egress only).
    Counter(bit<32> size, CounterType_t type, @optional bool true_egress_accounting);

    /// Increment the counter value.
    /// @param index : index of the counter to be incremented.
    void count(in I index, @optional in bit<32> adjust_byte_count);
}

/// DirectCounter
@noWarn("unused")
extern DirectCounter<W> {
    DirectCounter(CounterType_t type, @optional bool true_egress_accounting);
    void count(@optional in bit<32> adjust_byte_count);
}

/// Meter
extern Meter<I> {
    Meter(bit<32> size, MeterType_t type, @optional bool true_egress_accounting);
    Meter(bit<32> size, MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green, @optional bool true_egress_accounting);
    bit<8> execute(in I index, in MeterColor_t color, @optional in bit<32> adjust_byte_count);
    bit<8> execute(in I index, @optional in bit<32> adjust_byte_count);
}

/// Direct meter.
extern DirectMeter {
    DirectMeter(MeterType_t type, @optional bool true_egress_accounting);
    DirectMeter(MeterType_t type, bit<8> red, bit<8> yellow, bit<8> green, @optional bool true_egress_accounting);
    bit<8> execute(in MeterColor_t color, @optional in bit<32> adjust_byte_count);
    bit<8> execute(@optional in bit<32> adjust_byte_count);
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

    /// Write a value to every index in the register
    void clear(in T value, @optional in T busy);
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

    /// Write a value to every element of the register
    void clear(in T value, @optional in T busy);
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
             // Note: data tuple contains values in order from 15..0 (reversed)
             tuple< bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8>,
                    bit<8>, bit<8>, bit<8>, bit<8> > data);
    MathUnit(MathOp_t op, int factor); // configure as factor * op(x)
    MathUnit(MathOp_t op, int A, int B); // configure as (A/B) * op(x)
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
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the 16-bit predicate value */
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}

@noWarn("unused")
extern RegisterAction<T, H, U> {
    RegisterAction(Register<_, _> reg);
    U execute(@optional in H index, @optional out U rv2,
              @optional out U rv3, @optional out U rv4);

    U execute_log(@optional out U rv2, @optional out U rv3, @optional out U rv4);
    U enqueue(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* fifo push */
    U dequeue(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* fifo pop */
    U push(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* stack push */
    U pop(@optional out U rv2, @optional out U rv3, @optional out U rv4); /* stack pop */
    /// execute the action on every entry in the register
    void sweep(@optional in U busy);
    @synchronous(execute, execute_log, enqueue, dequeue, push, pop, sweep)
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
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction2<T, H, U1, U2> {
    RegisterAction2(Register<_, _> reg);
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction3<T, H, U1, U2, U3> {
    RegisterAction3(Register<_, _> reg);
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
    bit<8> min8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<8> max8<I>(in I val, in bit<16> mask, @optional out bit<4> index);
    bit<16> min16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
    bit<16> max16<I>(in I val, in bit<8> mask, @optional out bit<3> index);
}
extern RegisterAction4<T, H, U1, U2, U3, U4> {
    RegisterAction4(Register<_, _> reg);
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the 16-bit predicate value */
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
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the predicate value */
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
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
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
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
    U predicate(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<8> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<8> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<8> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<8> postmod);
}
extern MinMaxAction2<T, H, U1, U2> {
    MinMaxAction2(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
}
extern MinMaxAction3<T, H, U1, U2, U3> {
    MinMaxAction3(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2, out U3 rv3);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2, out U3 rv3);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
}
extern MinMaxAction4<T, H, U1, U2, U3, U4> {
    MinMaxAction4(Register<T, _> reg);
    U1 execute(@optional in H index, out U2 rv2, out U3 rv3, out U4 rv4);
    @synchronous(execute)
    abstract void apply(inout bit<128> value, out U1 rv1, out U2 rv2, out U3 rv3, out U4 rv4);

    /* These routines can be called in apply/overflow/underflow methods to get these values
     * to assign to a return value, but generally no operations can be applied */
    U address<U>(@optional bit<1> subword); /* return the match address */
    U predicate<U>(@optional in bool cmp0, @optional in bool cmp1, @optional in bool cmp2,
                   @optional in bool cmp3); /* return the predicate value */
    bit<8> min8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<8> max8(in bit<128> val, in bit<16> mask, @optional out bit<4> index,
                @optional in int<9> postmod);
    bit<16> min16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
    bit<16> max16(in bit<128> val, in bit<8> mask, @optional out bit<3> index,
                  @optional in int<9> postmod);
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

extern Mirror {
    /// Constructor
    @deprecated("Mirror must be specified with the value of the mirror_type instrinsic metadata")
    Mirror();

    /// Constructor
    Mirror(MirrorType_t mirror_type);

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
    @deprecated("Resubmit must be specified with the value of the resubmit_type instrinsic metadata")
    Resubmit();

    /// Constructor
    Resubmit(ResubmitType_t resubmit_type);

    /// Resubmit the packet.
    void emit();

    /// Resubmit the packet and prepend it with @hdr.
    /// @param hdr : T can be a header type, a header stack, a header_union,
    /// or a struct containing fields with such types.
    void emit<T>(in T hdr);
}

extern Digest<T> {
    /// define a digest stream to the control plane
    @deprecated("Digest must be specified with the value of the digest_type instrinsic metadata")
    Digest();

    /// constructor.
    Digest(DigestType_t digest_type);

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
    Alpm(@optional bit<32> number_partitions, @optional bit<32> subtrees_per_partition,
         @optional bit<32> atcam_subset_width, @optional bit<32> shift_granularity);
}
# 17 "/mnt/build/p4c/p4include/tofino2_arch.p4" 2

// The following declarations provide a template for the programmable blocks in
// Tofino2.

parser IngressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md,
    @optional out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    @optional out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr);

parser EgressParserT<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md,
    @optional out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    @optional out egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr);

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
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    @optional in ingress_intrinsic_metadata_t ig_intr_md);

control EgressDeparserT<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    @optional in egress_intrinsic_metadata_t eg_intr_md,
    @optional in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr);

package Pipeline<IH, IM, EH, EM>(
    IngressParserT<IH, IM> ingress_parser,
    IngressT<IH, IM> ingress,
    IngressDeparserT<IH, IM> ingress_deparser,
    EgressParserT<EH, EM> egress_parser,
    EgressT<EH, EM> egress,
    EgressDeparserT<EH, EM> egress_deparser,
    @optional GhostT ghost);

@pkginfo(arch="T2NA", version="1.0.1")
package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1,
               IH2, IM2, EH2, EM2, IH3, IM3, EH3, EM3>(
    Pipeline<IH0, IM0, EH0, EM0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3> pipe3);
# 13 "/mnt/build/p4c/p4include/t2na.p4" 2
# 6 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/pgm_sp_npb_vcpFw_top.p4" 2




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/deployment_params.p4" 1
// This file is auto-generated via /npb-dp/p4_pipelines/cls/pipeline.py



// Use this #define within your modules to declare
// the list of deployment parameters being passed in
// from above.
# 40 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/deployment_params.p4"
// Use this #define within your modules to declare
// the list of deployment parameters being passed down
// to sub-module instances.
# 75 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/deployment_params.p4"
// Deployment Profile: vcpFw
// --------------------------------------------------

const bool TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW = true;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 2048;
const bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW = false;
const bool FOLDED_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool UDF_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool EGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = false;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW = true;
const bool TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW = 2048;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1024;
const bool TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW = true;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 6144;
const bool TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW = true;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 512;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW = 1536;

// Use this #define to pass the list of deployment
// parameters into your top-level module instantiations.
# 143 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/deployment_params.p4"
// Deployment Profile: chtr
// --------------------------------------------------

const bool TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_V6_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_CHTR = false;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 2048;
const bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_CHTR = false;
const bool FOLDED_ENABLE_PIPELINE_NPB_CHTR = false;
const bool UDF_ENABLE_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool EGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_CHTR = false;
const bool TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_V4_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_CHTR = true;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_CHTR = true;
const bool TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_CHTR = 2048;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1024;
const bool TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_CHTR = true;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 6144;
const bool TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_CHTR = true;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 512;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_CHTR = 1536;

// Use this #define to pass the list of deployment
// parameters into your top-level module instantiations.
# 211 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/deployment_params.p4"
// Deployment Profile: igOnly
// --------------------------------------------------

const bool TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool INGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool TRANSPORT_V6_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_IGONLY = true;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 2048;
const bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_IGONLY = false;
const bool FOLDED_ENABLE_PIPELINE_NPB_IGONLY = false;
const bool UDF_ENABLE_PIPELINE_NPB_IGONLY = false;
const bool TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_IGONLY = false;
const bool EGRESS_ENABLE_PIPELINE_NPB_IGONLY = false;
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 1024;
const bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_IGONLY = true;
const bool TRANSPORT_V4_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_IGONLY = false;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_IGONLY = true;
const bool TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_IGONLY = 2048;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 512;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 1024;
const bool TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_IGONLY = true;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 6144;
const bool TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_IGONLY = true;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 512;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_IGONLY = 1536;

// Use this #define to pass the list of deployment
// parameters into your top-level module instantiations.
# 279 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/deployment_params.p4"
// Deployment Profile: egOnly
// --------------------------------------------------

const bool TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool INGRESS_ENABLE_PIPELINE_NPB_EGONLY = false;
const bool TRANSPORT_V6_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool OUTER_VXLAN_ENABLE_PIPELINE_NPB_EGONLY = true;
const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 512;
const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 2048;
const bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_EGONLY = false;
const bool FOLDED_ENABLE_PIPELINE_NPB_EGONLY = false;
const bool UDF_ENABLE_PIPELINE_NPB_EGONLY = false;
const bool TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool OUTER_ETAG_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool OUTER_GENEVE_ENABLE_PIPELINE_NPB_EGONLY = false;
const bool EGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 1024;
const bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_EGONLY = true;
const bool TRANSPORT_V4_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_EGONLY = false;
const bool OUTER_NVGRE_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool OUTER_VNTAG_ENABLE_PIPELINE_NPB_EGONLY = true;
const bool TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_EGONLY = 2048;
const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 512;
const bit<32> INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 1024;
const bool TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_EGONLY = true;
const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 6144;
const bool TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_EGONLY = true;
const bit<32> EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 512;
const bit<32> INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_EGONLY = 1536;

// Use this #define to pass the list of deployment
// parameters into your top-level module instantiations.
# 11 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/pgm_sp_npb_vcpFw_top.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 1
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

// **********************************************************************************
// ****  COPY ALL THIS (INCLUDING INCLUDE GUARDS) WHEN CONVERTING LATEST MASTER *****
// will also need to go and add contructor params to all the top-level pipeline
// pieces (parsers, mau, deparsers).




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
# 32 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2







# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/features.p4" 1
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





// ===== pkt header defines =================================

// ----- applies to: transport -----

// original names
# 50 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/features.p4"
// ----- applies to: outer -----
//#define ETAG_ENABLE   //moved to param OUTER_ETAG_ENABLE
//#define VNTAG_ENABLE  //moved to param OUTER_VNTAG_ENABLE

//#undef  GENEVE_ENABLE //moved to param OUTER_GENEVE_ENABLE
//#define VXLAN_ENABLE  //moved to param OUTER_VXLAN_ENABLE
//#define NVGRE_ENABLE  //moved to param OUTER_NVGRE_ENABLE







// ----- applies to: inner -----



// ----- applies to: outer and inner -----

//#undef  UDF_ENABLE // moved to param UDF_ENABLE
                     // if SF_0_ONE_POLICY_TABLE is defined, you may need to shrink the UDF width to fit
// ===== feature defines ====================================

// ----- parser -----
# 86 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/features.p4"
// ----- switch: general -----



// ----- switch: mirroring -----





// ----- switch: cpu -----
# 105 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/features.p4"
// ----- switch: dtel -----







// ----- switch: other -----

// #define QINQ_ENABLE
// #define QINQ_RIF_ENABLE




// ----- npb: sfc -----






// ----- npb: sff -----




// ----- npb: sf #0 -----
# 148 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/features.p4"
// ----- npb: sf #2  -----
# 164 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/features.p4"
// ----- tofino 1 fitting -----





// ----- debug and miscellaneous -----




// ----- bug fixes -----




// ----- other wanted / needed features that don't fit -----
# 40 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/field_widths.p4" 1





    // -------------------------------------
    // Switch Widths
    // -------------------------------------
# 28 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/field_widths.p4"
    // -------------------------------------
    // NPB Widths
    // -------------------------------------
# 41 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/table_sizes.p4" 1
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




// -----------------------------------------------------------------------------
// Switch
// -----------------------------------------------------------------------------

const bit<32> PORT_TABLE_SIZE = 288;

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
//const bit<32> IPV4_DST_TUNNEL_TABLE_SIZE                           = 1024; // ingress --> SEE YAML FILE
const bit<32> IPV4_SRC_TUNNEL_TABLE_SIZE = 256; // ingress
const bit<32> IPV6_DST_TUNNEL_TABLE_SIZE = 1024; // ingress
const bit<32> IPV6_SRC_TUNNEL_TABLE_SIZE = 256; // ingress

const bit<32> TUNNEL_SRC_REWRITE_TABLE_SIZE = 512; // egress
const bit<32> TUNNEL_DST_REWRITE_TABLE_SIZE = 1024; // egress
const bit<32> TUNNEL_SMAC_REWRITE_TABLE_SIZE = 32; // egress
const bit<32> TUNNEL_DMAC_REWRITE_TABLE_SIZE = 256; // egress

// ECMP/Nexthop
const bit<32> NEXTHOP_TABLE_SIZE = 8192;
const bit<32> ECMP_GROUP_TABLE_SIZE = 1024; // derek: unused; removed this table
const bit<32> ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; removed this table

// ECMP/Nexthop
const bit<32> OUTER_NEXTHOP_TABLE_SIZE = 4096; // aka NUM_TUNNELS
const bit<32> OUTER_ECMP_GROUP_TABLE_SIZE = 4096; // derek: unused in switch.p4
const bit<32> OUTER_ECMP_SELECT_TABLE_SIZE = 16384; // derek: unused; changed table type to normal table

// Lag
const bit<32> LAG_TABLE_SIZE = 1024; // switch.p4 was 1024
const bit<32> LAG_GROUP_TABLE_SIZE = 32; // switch.p4 was 256
const bit<32> LAG_MAX_MEMBERS_PER_GROUP = 64; // switch.p4 was 64
const bit<32> LAG_SELECTOR_TABLE_SIZE = 2048; // 256 * 64 // switch.p4 was 16384

// Ingress ACLs
//const bit<32> INGRESS_MAC_ACL_TABLE_SIZE                           = 1536; --> SEE YAML FILE
//const bit<32> INGRESS_IPV4_ACL_TABLE_SIZE                          = 6144; --> SEE YAML FILE
//const bit<32> INGRESS_IPV6_ACL_TABLE_SIZE                          = 2048; --> SEE YAML FILE
//const bit<32> INGRESS_L7_ACL_TABLE_SIZE                            = 1024; --> SEE YAML FILE

// Egress ACL
//const bit<32> EGRESS_MAC_ACL_TABLE_SIZE                            = 512; --> SEE YAML FILE
//const bit<32> EGRESS_IPV4_ACL_TABLE_SIZE                           = 512; --> SEE YAML FILE
//const bit<32> EGRESS_IPV6_ACL_TABLE_SIZE                           = 512; --> SEE YAML FILE

// DTEL
const bit<32> INGRESS_IP_DTEL_ACL_TABLE_SIZE = 512;
const bit<32> DTEL_GROUP_TABLE_SIZE = 4;
const bit<32> DTEL_MAX_MEMBERS_PER_GROUP = 64;
const bit<32> DTEL_SELECTOR_TABLE_SIZE = 256;





// -----------------------------------------------------------------------------
// NPB
// -----------------------------------------------------------------------------

// net intf

// sfc -- classifies non-nsh packets
//const bit<32> NPB_ING_SFC_TUNNEL_NETWORK_SAP_TABLE_DEPTH           = 8192;
//const bit<32> NPB_ING_SFC_TUNNEL_OUTER_EXM_TABLE_DEPTH             = 8192; // unused now
//const bit<32> NPB_ING_SFC_TUNNEL_OUTER_TCAM_TABLE_DEPTH            = 1024; // was 256;
const bit<32> NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH = 8192;
//const bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH            = 2048; --> SEE YAML FILE

const bit<32> NPB_ING_SFC_SF_SEL_TABLE_DEPTH = 8192; // derek, what size to make this?
const bit<32> NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH = 8192; // derek, what size to make this?

// sf #0 -- basic / advanced
const bit<32> NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH = 128;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH = 256;
const bit<32> NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH = 256;

// sf #0 - sfp select
const bit<32> NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH = 128;
//const bit<32> NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE                     = 128;
const bit<32> NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE = 8192;
const bit<32> NPB_ING_SF_0_SFP_SCHD_GROUP_TABLE_SIZE = 128;
const bit<32> NPB_ING_SF_0_SFP_SCHD_MAX_MEMBERS_PER_GROUP = 128;
const bit<32> NPB_ING_SF_0_SFP_SCHD_SELECTOR_TABLE_SIZE = 16384; // 128 * 128

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_ING_SFF_ARP_TABLE_DEPTH = 8192;

// sf #1 -- replication
const bit<32> NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH = 1024;
const bit<32> NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE = 2096;

// sf #2 -- tool proxy
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH = 8192;

const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH= 128;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH= 256;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH= 256;
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_HDR_STRIP_TABLE_DEPTH = 8; // unused in latest spec
const bit<32> NPB_EGR_SF_2_EGRESS_SFP_TRUNC_TABLE_DEPTH = 8; // unused in latest spec

// sff -- forwards the packets to the sf's, then forwards to the packet along the chain.
const bit<32> NPB_EGR_SFF_ARP_TABLE_DEPTH = 8192;

const bit<32> dedup_num_blocks = 16;
const bit<32> dedup_addr_width_ = 16; // 64k deep
# 42 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2

# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/headers.p4" 1
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




typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

//////////////////////////////////////////////////////////////
// Layer2 Headers
//////////////////////////////////////////////////////////////
/*
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

header vlan_tag_grouped_h {
    bit<16> pcp_cfi_vid;
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


//////////////////////////////////////////////////////////////
// Layer3 Headers
//////////////////////////////////////////////////////////////

// Address Resolution Protocol -- RFC 6747

header arp_h {
    bit<16> hw_type;
    bit<16> proto_type;
    bit<8> hw_addr_len;
    bit<8> proto_addr_len;
    bit<16> opcode;
}

header ipv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> tos;
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

//#ifdef IPV6_ENABLE
  header ipv6_h {
      bit<4> version;
      bit<8> tos;
      bit<20> flow_label;
      bit<16> payload_len;
      bit<8> next_hdr;
      bit<8> hop_limit;
      ipv6_addr_t src_addr;
      ipv6_addr_t dst_addr;
  }

  header ipv6_truncated_h {
      bit<4> version;
      bit<8> tos;
      bit<20> flow_label;
      bit<16> payload_len;
  }
//#endif  /* IPV6_ENABLE */

header dummy_ethernet_h {
      bit<8> unused;
}

header dummy_ipv4_h {
    bit<16> total_len;
}

header dummy_ipv6_h {
      bit<16> payload_len;
}


//////////////////////////////////////////////////////////////
// Layer4 Headers
//////////////////////////////////////////////////////////////

header icmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header igmp_h {
    bit<8> type;
    bit<8> code;
    bit<16> checksum;
}

header udp_h {
    bit<16> src_port;
    bit<16> dst_port;
    bit<16> len;
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
// Transport Headers
//////////////////////////////////////////////////////////////

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

    // word 1: base word 1
    bit<24> spi;
    bit<8> si;

    // word 2: ext type 1 word 0
 bit<8> ver;
//	bit<8>  scope;
 bit<8> reserved3;
//	bit<16> reserved3;
 bit<16> lag_hash;

    // word 2: ext type 1 word 1
 bit<16> vpn;
 bit<16> sfc_data; // unused

    // word 2: ext type 1 word 2
 bit<8> reserved4;
 bit<8> scope;
 bit<16> sap;

    // word 2: ext type 1 word 3
 bit<32> timestamp;
}

header nsh_type1_internal_h { // 11 bytes
    // word 0: base word 0
    bit<2> version;
    bit<1> o;
    bit<1> reserved;
    bit<6> ttl;
    bit<6> len; // in 4-byte words

    // word 0: base word 1
    bit<24> spi;
    bit<8> si;

    // word 2: ext type 1 word 0-3
 bit<16> vpn;
 bit<8> scope;
 bit<16> sap;
}

//-----------------------------------------------------------
// ERSPAN
//-----------------------------------------------------------

// ERSPAN Type II -- IETFv3
header erspan_type2_h {
    bit<4> version;
    bit<12> vlan;
    bit<6> cos_en_t;
    bit<10> session_id;
    bit<12> reserved;
    bit<20> index;
}

// ERSPAN Type III -- IETFv3
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



//////////////////////////////////////////////////////////////
// LayerX Headers
//////////////////////////////////////////////////////////////

header mpls_h {
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
// Tunnel Headers
//////////////////////////////////////////////////////////////

//-----------------------------------------------------------
// Geneve
//-----------------------------------------------------------

header geneve_h {
    bit<2> ver;
    bit<6> opt_len;
    bit<1> O;
    bit<1> C;
    bit<6> rsvd1;
    bit<16> proto_type;
    bit<24> vni;
    bit<8> rsvd2;
}


//-----------------------------------------------------------
// VXLAN
//-----------------------------------------------------------

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


//-----------------------------------------------------------
// GRE
//-----------------------------------------------------------

// Generic Routing Encapsulation (GRE) -- RFC 1701
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

header gre_optional_h {
    bit<32> data;
}

header gre_extension_sequence_h {
    bit<32> seq_num;
}


//-----------------------------------------------------------
// NVGRE
//-----------------------------------------------------------

// Network Virtualisation using GRE (NVGRE) -- RFC 7637
header nvgre_h {
    bit<24> vsid;
    bit<8> flow_id;
}


//-----------------------------------------------------------
// ESP - IPsec
//-----------------------------------------------------------

header esp_h {
    //bit<32> spi;
    bit<16> spi_hi;
    bit<16> spi_lo;
    bit<32> seq_num;
}


//-----------------------------------------------------------
// GTP
//-----------------------------------------------------------
// GTP-U: v1
// GTP-C: v2

header gtp_v1_base_h {
    bit<3> version;
    bit<1> PT;
    bit<1> reserved;
    bit<1> E;
    bit<1> S;
    bit<1> PN;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> teid;
}

header gtp_v1_optional_h {
    bit<16> seq_num;
    bit<8> n_pdu_num;
    bit<8> next_ext_hdr_type;
}

// header gtp_v1_extension_h {
//     bit<8>       ext_len;
//     varbit<8192> contents;
//     bit<8>       next_ext_hdr;
// }

header gtp_v2_base_h {
    bit<3> version;
    bit<1> P;
    bit<1> T;
    bit<3> reserved;
    bit<8> msg_type;
    bit<16> msg_len;
    bit<32> teid;
    //bit<24> seq_num;
    //bit<8>  spare;
}



//////////////////////////////////////////////////////////////
// Layer7 Headers (aka UDF)
//////////////////////////////////////////////////////////////

header udf_h {
    bit<128> opaque;
}



// min ip-length in order to accomodate full UDF extraction
# 508 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/headers.p4"
//////////////////////////////////////////////////////////////
// DTel
//////////////////////////////////////////////////////////////

// Telemetry report header -- version 0.5
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v0_5.pdf
header dtel_report_v05_h {
    bit<4> version;
    bit<4> next_proto;
    bit<3> d_q_f;
    bit<15> reserved;
    bit<6> hw_id;
    bit<32> seq_number;
    bit<32> timestamp;
    bit<32> switch_id;
}

// DTel report base header
header dtel_report_base_h {



    bit<7> pad0;

    PortId_t ingress_port;



    bit<7> pad1;

    PortId_t egress_port;




    bit<1> pad2;
    bit<7> queue_id;

}

// DTel drop report header
header dtel_drop_report_h {
    bit<8> drop_reason;
    bit<16> reserved;
}

// DTel switch local report header
header dtel_switch_local_report_h {
    bit<5> pad3;
    bit<19> queue_occupancy;
    bit<32> timestamp;
}

// Telemetry report header -- version 1.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v1_0.pdf
header dtel_report_v10_h {
    bit<4> version;
    bit<4> length;
    bit<3> next_proto;
    bit<6> metadata_bits;
    bit<6> reserved;
    bit<3> d_q_f;
    bit<6> hw_id;
    bit<32> switch_id;
    bit<32> seq_number;
    bit<32> timestamp;
}

// Telemetry report header -- version 2.0
// See https://github.com/p4lang/p4-applications/blob/master/docs/telemetry_report_v2_0.pdf
header dtel_report_v20_h {
    bit<4> version;
    // Telemetry Report v2.0 hw_id is 6 bits, however due to p4 constraints,
    // shrinking it to 4 bits
    bit<4> hw_id;
    // Telemetry Report v2.0 seq_number is 22 bits, however due to p4
    // constraints, expanding it to 24 bits, always leaving the top 2 bits as 0
    bit<24> seq_number;
    bit<32> switch_id;
    // Due to p4 constraints, need to treat the following as one field:
    // bit<4> rep_type;
    // bit<4> in_type;
    // bit<16> report_length;
    bit<16> report_length;
    bit<8> md_length;
    bit<3> d_q_f;
    bit<5> reserved;
    bit<16> rep_md_bits;
    bit<16> domain_specific_id;
    bit<16> ds_md_bits;
    bit<16> ds_md_status;
}

// Optional metadata present in the telemetry report.
header dtel_metadata_1_h {



    bit<7> pad0;

    PortId_t ingress_port;



    bit<7> pad1;

    PortId_t egress_port;
}

header dtel_metadata_2_h {
    bit<32> hop_latency;
}

header dtel_metadata_3_h {




    bit<1> pad2;
    bit<7> queue_id;

    bit<5> pad3;
    bit<19> queue_occupancy;
}

header dtel_metadata_4_h {
    bit<16> pad;
    bit<48> ingress_timestamp;
}

header dtel_metadata_5_h {
    bit<16> pad;
    bit<48> egress_timestamp;
}

header dtel_report_metadata_15_h {




    bit<1> pad;
    bit<7> queue_id;

    bit<8> drop_reason;
    bit<16> reserved;
}

//////////////////////////////////////////////////////////////
// Barefoot Specific Headers
//////////////////////////////////////////////////////////////

header fabric_h {
    bit<8> reserved;
    bit<3> color;
    bit<5> qos;
    bit<8> reserved2;
}

// CPU header
header cpu_h {
    bit<5> egress_queue;
    bit<1> tx_bypass;
    bit<1> capture_ts;
    bit<1> reserved;
    bit<16> ingress_port;
    bit<16> port_lag_index;
    bit<16> ingress_bd;
    bit<16> reason_code; // Also used as a 16-bit bypass flag.
    bit<16> ether_type;
}

// CPU header
//TODO(msharif): Update format of the CPU header.
// header cpu_h {
//    bit<8> flags; /*
//        bit<1> tx_bypass;
//        bit<1> capture_ts;
//        bit<1> multicast;
//        bit<5> reserved;
//    */
//    bit<8> qid;
//    bit<16> reserved;
//    bit<16> port_or_group;
//    bit<16> port;
//    bit<16> port_lag_index;
//    bit<16> bd;
//    bit<16> reason_code; // Also used as a 16-bit bypass flag.
//    bit<16> ether_type;
//}

// header timestamp_h {
//     bit<48> timestamp;
// }



//////////////////////////////////////////////////////////////
// Lookahead/Snoop Headers
//////////////////////////////////////////////////////////////

header snoop_enet_my_mac_h {
    bit<16> dst_addr_hi;
    bit<32> dst_addr_lo;
    mac_addr_t src_addr;
    bit<16> ether_type;
}

header snoop_enet_cpu_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]
# 727 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/headers.p4"
    bit<5> cpu_egress_queue;
    bit<1> cpu_tx_bypass;
    bit<1> cpu_capture_ts;
 bit<1> reserved;
    bit<16> cpu_ingress_port;
    bit<16> cpu_port_lag_index;
    bit<16> cpu_ingress_bd;
    bit<16> cpu_reason_code;
    bit<16> cpu_ether_type;
}

header snoop_head_enet_vlan_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]
} // 14B + 4B = 18B

header snoop_head_enet_ipv4_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 10B = 24B

header snoop_head_enet_vlan_ipv4_h {
    mac_addr_t enet_dst_addr;
    mac_addr_t enet_src_addr;
    bit<16> enet_ether_type; // lookahead<bit<112>>()[15:0]

    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type; // lookahead<bit<144>>()[15:0]

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol; // lookahead<bit<224>>()[7:0]
} // 14B + 4B + 10B = 28B



header snoop_ipv4_udp_h {
    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol;
    bit<16> ipv4_hdr_checksum;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;

    bit<16> udp_src_port;
    bit<16> udp_dst_port;
    //bit<16> udp_len;
    //bit<16> udp_checksum;

} // 20B + 4B = 24B


header snoop_ipv4_udp_geneve_h {
    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol;
    bit<16> ipv4_hdr_checksum;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;

    bit<16> udp_src_port;
    bit<16> udp_dst_port;
    bit<16> udp_len;
    bit<16> udp_checksum;

    bit<2> geneve_ver;
    bit<6> geneve_opt_len;
    bit<1> geneve_O;
    bit<1> geneve_C;
    bit<6> geneve_rsvd1;
    bit<16> geneve_proto_type;
} // 20B + 8B + 4B = 32B



header snoop_vlan_ipv4_udp_h {
    bit<3> vlan_pcp;
    bit<1> vlan_cfi;
    vlan_id_t vlan_vid;
    bit<16> vlan_ether_type;

    bit<4> ipv4_version;
    bit<4> ipv4_ihl;
    bit<8> ipv4_diffserv;
    bit<16> ipv4_total_len;
    bit<16> ipv4_identification;
    bit<3> ipv4_flags;
    bit<13> ipv4_frag_offset;
    bit<8> ipv4_ttl;
    bit<8> ipv4_protocol;
    bit<16> ipv4_hdr_checksum;
    ipv4_addr_t ipv4_src_addr;
    ipv4_addr_t ipv4_dst_addr;

    bit<16> udp_src_port;
    bit<16> udp_dst_port;
    //bit<16> udp_len;
    //bit<16> udp_checksum;

} // 4B + 20B + 4B = 28B
# 44 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4" 1
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
# 47 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
//#define ETHERTYPE_VN   0x892F
# 88 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
//#define MPLS_DEPTH 3


// ----------------------------------------------------------------------------
// Common types
//-----------------------------------------------------------------------------

typedef bit<32> switch_uint32_t;
typedef bit<16> switch_uint16_t;
typedef bit<8> switch_uint8_t;





typedef PortId_t switch_port_t; // defined in tna




const switch_port_t SWITCH_PORT_INVALID = 9w0x1ff;
typedef bit<7> switch_port_padding_t;


typedef QueueId_t switch_qid_t; // defined in tna (t2 = 7 bits)

typedef ReplicationId_t switch_rid_t; // defined in tna
const switch_rid_t SWITCH_RID_DEFAULT = 0xffff;

typedef bit<10> switch_port_lag_index_t;
//const switch_port_lag_index_t SWITCH_FLOOD = 0x3ff;

typedef bit<8> switch_bd_t;
const switch_bd_t SWITCH_BD_DEFAULT_VRF = 4097; // bd allocated for default vrf

//#ifndef switch_nexthop_width
//#define switch_nexthop_width 16
//#endif
typedef bit<12> switch_nexthop_t;






typedef bit<32> switch_hash_t;
# 147 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
typedef bit<16> switch_xid_t;
typedef bit<9> switch_yid_t;

typedef bit<16> switch_smac_index_t;

typedef bit<8> switch_cpu_reason_t;
const switch_cpu_reason_t SWITCH_CPU_REASON_PTP = 8;
// -------------------------------------
// Extreme Networks - Added
// -------------------------------------
const switch_cpu_reason_t SWITCH_CPU_REASON_IG_PORT_MIRROR = 254;
const switch_cpu_reason_t SWITCH_CPU_REASON_EG_PORT_MIRROR = 255;

struct switch_cpu_port_value_set_t {
    bit<16> ether_type;
    switch_port_t port;
}

//#define switch_drop_reason_width 8
typedef bit<8> switch_drop_reason_t;
const switch_drop_reason_t SWITCH_DROP_REASON_UNKNOWN = 0;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_ZERO = 10;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SRC_MAC_MULTICAST = 11;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_DST_MAC_ZERO = 12;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_ETHERNET_MISS = 13;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_ZERO = 14;
const switch_drop_reason_t SWITCH_DROP_REASON_SRC_MAC_MULTICAST = 15;
const switch_drop_reason_t SWITCH_DROP_REASON_DST_MAC_ZERO = 16;
const switch_drop_reason_t SWITCH_DROP_REASON_OUTER_SAME_MAC_CHECK = 17;
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

// To determine these values, run the test "test_mau_1hop_s_e_sf0_l2_acl_sf2_l2_acl" and subtract the count values.
const int EGRESS_ACL_ADJUST_NORMAL = -32; // DO NOT DELETE -- FIRMWARE CONSUMES THIS
//const int EGRESS_ACL_ADJUST_DROP   =   4; // DO NOT DELETE -- FIRMWARE CONSUMES THIS
const int EGRESS_ACL_ADJUST_DROP = -32; // DO NOT DELETE -- FIRMWARE CONSUMES THIS

// Bypass flags ---------------------------------------------------------------

typedef bit<8> switch_ingress_bypass_t;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_L2 = 8w0x01;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SFC = 8w0x02;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_ACL = 8w0x04;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SF_MCAST = 8w0x08;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_SFF = 8w0x10;
//const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_REWRITE       = 8w0x20;
const switch_ingress_bypass_t SWITCH_INGRESS_BYPASS_ALL = 8w0xff;


//#define INGRESS_BYPASS(t) (false)

// PKT ------------------------------------------------------------------------

typedef bit<16> switch_pkt_length_t;

typedef bit<8> switch_pkt_src_t;
const switch_pkt_src_t SWITCH_PKT_SRC_BRIDGED = 0;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_INGRESS = 1;
const switch_pkt_src_t SWITCH_PKT_SRC_CLONED_EGRESS = 2;
const switch_pkt_src_t SWITCH_PKT_SRC_DEFLECTED = 3;

typedef bit<2> switch_pkt_color_t;
const switch_pkt_color_t SWITCH_METER_COLOR_GREEN = 0;
const switch_pkt_color_t SWITCH_METER_COLOR_YELLOW = 1;
const switch_pkt_color_t SWITCH_METER_COLOR_RED = 3;

typedef bit<2> switch_pkt_type_t;
const switch_pkt_type_t SWITCH_PKT_TYPE_UNICAST = 0;
const switch_pkt_type_t SWITCH_PKT_TYPE_MULTICAST = 1;
const switch_pkt_type_t SWITCH_PKT_TYPE_BROADCAST = 2;

// Metering -------------------------------------------------------------------

//#define switch_copp_meter_id_width 8
typedef bit<8> switch_copp_meter_id_t;

//#define switch_meter_index_width 10
typedef bit<10> switch_meter_index_t;

//#define switch_mirror_meter_id_width 8
typedef bit<8> switch_mirror_meter_id_t;

// QoS ------------------------------------------------------------------------

struct switch_qos_metadata_t {
//	switch_tc_t tc;
//	switch_pkt_color_t color;
 switch_qid_t qid;
 bit<19> qdepth; // Egress only.
}

// Multicast ------------------------------------------------------------------

typedef bit<2> switch_multicast_mode_t;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_NONE = 0;
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_SM = 1; // Sparse mode
const switch_multicast_mode_t SWITCH_MULTICAST_MODE_PIM_BIDIR = 2; // Bidirectional

typedef MulticastGroupId_t switch_mgid_t;

//typedef bit<16> switch_multicast_rpf_group_t;

struct switch_multicast_metadata_t {
    switch_mgid_t id;
    bit<2> mode;
//  switch_multicast_rpf_group_t rpf_group;
}

// Mirroring ------------------------------------------------------------------

typedef MirrorId_t switch_mirror_session_t; // Defined in tna.p4
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU_INGRESS = 251;
const switch_mirror_session_t SWITCH_MIRROR_SESSION_CPU_EGRESS = 250;

// Using same mirror type for both Ingress/Egress to simplify the parser.
typedef bit<8> switch_mirror_type_t;






/* Although strictly speaking deflected packets are not mirrored packets,
 * need a mirror_type codepoint for packet length adjustment.
 * Pick a large value since this is not used by mirror logic.
 */


// Common metadata used for mirroring.
struct switch_mirror_metadata_t {
    switch_pkt_src_t src;
    switch_mirror_type_t type;
    switch_mirror_session_t session_id;
    switch_mirror_meter_id_t meter_index;
}
/*
header switch_port_mirror_ingress_metadata_h { // this is a header!
    switch_pkt_src_t src;                   // 8
    switch_mirror_type_t type;              // 8
    switch_port_padding_t _pad1;            // 7  \ 16 total
    switch_port_t port;                     // 9  /
    switch_bd_t bd;                         // 16
#ifdef CPU_HDR_CONTAINS_EG_PORT
    bit<7> _pad2;                           // 7  \ 16 total
    switch_port_t eg_port;                  // 9  /
#else
    bit<6> _pad2;                           // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
#endif
//#if defined(PTP_ENABLE) || defined(INT_V2)
//    bit<48> timestamp;
//#else
//    bit<32> timestamp;                      // 32
//#endif
//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code;        // 16
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
}
*/
/*
header switch_port_mirror_egress_metadata_h { // this is a header!
    switch_pkt_src_t src;                   // 8
    switch_mirror_type_t type;              // 8
    switch_port_padding_t _pad1;            // 7  \ 16 total
    switch_port_t port;                     // 9  /
    switch_bd_t bd;                         // 16
#ifdef CPU_HDR_CONTAINS_EG_PORT
    bit<7> _pad2;                           // 7  \ 16 total
    switch_port_t eg_port;                  // 9  /
#else
    bit<6> _pad2;                           // 6  \ 16 total
    switch_port_lag_index_t port_lag_index; // 10 /
#endif
//#if defined(PTP_ENABLE) || defined(INT_V2)
//    bit<48> timestamp;
//#else
//    bit<32> timestamp;                      // 32
//#endif
//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code;        // 16
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
}
*/
header switch_cpu_mirror_ingress_metadata_h { // this is a header!
    switch_pkt_src_t src; // 8
    switch_mirror_type_t type; // 8
    switch_port_padding_t _pad1; // 7  \ 16 total
    switch_port_t port; // 9  /
    switch_bd_t bd; // 16

    bit<7> _pad2; // 7  \ 16 total
    switch_port_t eg_port; // 9  /







    bit<32> timestamp; // 32

//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code; // 16
/*
#if __TARGET_TOFINO__ == 1
    bit<3> _pad4;
#else
    bit<1> _pad4;
#endif
    switch_qid_t qos_qid;                   // 7
	bit< 5> _pad5;                          // 5  \ 24 total
	bit<19> qos_qdepth;                     // 19 /
*/
}

header switch_cpu_mirror_egress_metadata_h { // this is a header!
    switch_pkt_src_t src; // 8
    switch_mirror_type_t type; // 8
    switch_port_padding_t _pad1; // 7  \ 16 total
    switch_port_t port; // 9  /
    switch_bd_t bd; // 16

    bit<7> _pad2; // 7  \ 16 total
    switch_port_t eg_port; // 9  /







    bit<32> timestamp; // 32

//#if __TARGET_TOFINO__ == 1
//    bit<6> _pad;
//#endif
//    switch_mirror_session_t session_id;     // 8
    switch_cpu_reason_t reason_code; // 16



    bit<1> _pad4;

    switch_qid_t qos_qid; // 7
 bit< 5> _pad5; // 5  \ 24 total
 bit<19> qos_qdepth; // 19 /
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
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_VLAN = 9;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_MPLS = 10;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_UNSUPPORTED = 11;
const switch_tunnel_type_t SWITCH_TUNNEL_TYPE_GENEVE = 12;

//#ifndef switch_tunnel_index_width
//#define switch_tunnel_index_width 16
//#endif
typedef bit<8> switch_tunnel_index_t;
//#ifndef switch_tunnel_ip_index_width
//#define switch_tunnel_ip_index_width 16
//#endif
typedef bit<16> switch_tunnel_ip_index_t;



typedef bit<12> switch_tunnel_nexthop_t;
typedef bit<32> switch_tunnel_vni_t;

struct switch_tunnel_metadata_t { // for transport
 // note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
 // --------------------------------
    switch_tunnel_type_t type; // only used by egress encap code (parser does not set)
 switch_tunnel_index_t index;
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_vni_t vni;
//  switch_ifindex_t ifindex;
//  bit<16> hash;
 bool terminate;
 bit<8> nvgre_flow_id;

 bool unsupported_tunnel;
}

struct switch_tunnel_metadata_reduced_t { // for outer and inner
 // note: in addition to tunnel stuff, this structure serves as a catch-all for all non-scoped signals (tunnel related or not)
 // --------------------------------
//	switch_tunnel_type_t type; // not used (parser does not set)
//	switch_tunnel_index_t index;
//  switch_tunnel_ip_index_t dip_index;
//  switch_tunnel_vni_t vni;
//  switch_ifindex_t ifindex;
//  bit<16> hash;
 bool terminate;
 bit<8> nvgre_flow_id;

 bool unsupported_tunnel;
}

// Data-plane telemetry (DTel) ------------------------------------------------
/* report_type bits for drop and flow reflect dtel_acl results,
 * i.e. whether drop reports and flow reports may be triggered by this packet.
 * report_type bit for queue is not used by bridged / deflected packets,
 * reflects whether queue report is triggered by this packet in cloned packets.
 */
typedef bit<8> switch_dtel_report_type_t;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_NONE = 0b000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_FLOW = 0b001;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_QUEUE = 0b010;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_DROP = 0b100;

const switch_dtel_report_type_t SWITCH_DTEL_SUPPRESS_REPORT = 0b1000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_IFA_CLONE = 0b10000;
const switch_dtel_report_type_t SWITCH_DTEL_IFA_EDGE = 0b100000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE = 0b1000000;
const switch_dtel_report_type_t SWITCH_DTEL_REPORT_TYPE_ETRAP_HIT = 0b10000000;

typedef bit<8> switch_ifa_sample_id_t;






typedef bit<6> switch_dtel_hw_id_t;

// Outer header sizes for DTEL Reports
/* Up to the beginning of the DTEL Report v0.5 header
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 4 (CRC) = 46 bytes */
const bit<16> DTEL_REPORT_V0_5_OUTER_HEADERS_LENGTH = 46;
/* Outer headers + part of DTEL Report v2 length not included in report_length
 * 14 (Eth) + 20 (IPv4) + 8 (UDP) + 12 (DTEL) + 4 (CRC) = 58 bytes */
const bit<16> DTEL_REPORT_V2_OUTER_HEADERS_LENGTH = 58;

struct switch_dtel_metadata_t {
    switch_dtel_report_type_t report_type;
    bit<1> ifa_gen_clone; // Ingress only, indicates desire to clone this packet
    bit<1> ifa_cloned; // Egress only, indicates this is an ifa cloned packet
    bit<32> latency; // Egress only.
    switch_mirror_session_t session_id;
    switch_mirror_session_t clone_session_id; // Used for IFA interop
    bit<32> hash;
    bit<2> drop_report_flag; // Egress only.
    bit<2> flow_report_flag; // Egress only.
    bit<1> queue_report_flag; // Egress only.
}

header switch_dtel_switch_local_mirror_metadata_h { // 28 bytes?
    switch_pkt_src_t src; // 1
    switch_mirror_type_t type; // 1



    bit<32> timestamp;




    switch_mirror_session_t session_id; // 1
    bit<32> hash; // 4
    switch_dtel_report_type_t report_type; // 1
    switch_port_padding_t _pad2; // \ 2
    switch_port_t ingress_port; // /
    switch_port_padding_t _pad3; // \ 2
    switch_port_t egress_port; // /



    bit<1> _pad4;

    switch_qid_t qid; // 1
    bit<5> _pad5; // \ 3
    bit<19> qdepth; // /



    bit<32> egress_timestamp;

}

header switch_dtel_drop_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    bit<32> timestamp;




    switch_mirror_session_t session_id;
    bit<32> hash;
    switch_dtel_report_type_t report_type;
    switch_port_padding_t _pad2;
    switch_port_t ingress_port;
    switch_port_padding_t _pad3;
    switch_port_t egress_port;



    bit<1> _pad4;

    switch_qid_t qid;
    switch_drop_reason_t drop_reason;
}

// Used for dtel truncate_only and ifa_clone mirror sessions
header switch_simple_mirror_metadata_h {
    switch_pkt_src_t src;
    switch_mirror_type_t type;



    switch_mirror_session_t session_id;
}

@flexible
struct switch_bridged_metadata_dtel_extension_t {
//  switch_dtel_report_type_t report_type;
//  switch_mirror_session_t session_id;
//  bit<32> hash;
//  switch_port_t egress_port;
}

//-----------------------------------------------------------------------------
// NSH Metadata
//-----------------------------------------------------------------------------

struct nsh_metadata_t {
 bit<2> pad;
 bit<6> ttl; // ingress / egress hdr
 bit<24> spi; // ingress / egress hdr
 bit<8> si; // ingress / egress hdr
 bit<8> ver; // ingress          hdr
 bit<16> vpn; // ingress / egress hdr
 bit<8> scope; // ingress / egress hdr
 bit<16> sap; // ingress / egress hdr

//  bool                            start_of_path;          // ingress / egress
    bool end_of_path; // ingress / egress
    bool truncate_enable; // ingress / egress
    bit<14> truncate_len; // ingress / egress
//	bool                            sf1_active;             // ingress / egress

    bit<8> si_predec; // ingress only
    bool sfc_enable; // ingress only (for sfp sel)
    bit<12> sfc; // ingress only (for sfp sel)
 bit<16> hash_1; // ingress only (for sfp sel)
    bool l2_fwd_en; // ingress only
 bit<32> hash_2; // ingress only (for dedup)
 bit<6> lag_hash_mask_en; // ingress only

    bit<16> dsap; // egress only (for egress sf)
    bool strip_tag_e; // egress only
    bool strip_tag_vn; // egress only
    bool strip_tag_vlan; // egress only
    bit<8> add_tag_vlan_bd; // egress only
    bool terminate_outer; // egress only
    bool terminate_inner; // egress only
    bool dedup_en; // egress only
}

// ** Note: tenant id definition, from draft-wang-sfc-nsh-ns-allocation-00:
//
// Tenant ID: The tenant identifier is used to represent the tenant or security
// policy domain that the Service Function Chain is being applied to. The Tenant
// ID is a unique value assigned by a control plane. The distribution of Tenant
// ID's is outside the scope of this document. As an example application of
// this field, the first node on the Service Function Chain may insert a VRF
// number, VLAN number, VXLAN VNI or a policy domain ID.

//-----------------------------------------------------------------------------
// Other Metadata Definitions
//-----------------------------------------------------------------------------

// Flags
//XXX Force the fields that are XORd to NOT share containers.
struct switch_ingress_flags_t {
//  bool ipv4_checksum_err_0;
//  bool ipv4_checksum_err_1;
//  bool ipv4_checksum_err_2;
//  bool acl_deny;
//  bool port_vlan_miss;
//  bool rmac_hit;
//	bool dmac_miss;
//  bool glean;
 bool bypass_egress;
    // Add more flags here.
    bool transport_valid;
 bool outer_enet_in_transport;
}

struct switch_egress_flags_t {
 bool routed;
 bool bypass_egress;
//  bool acl_deny;
//  bool rmac_hit;
    // Add more flags here.
    bool transport_valid;
}

// Checks
struct switch_ingress_checks_t {
    // Add more checks here.
}

struct switch_egress_checks_t {
    // Add more checks here.
}

struct switch_lookup_fields_t {
 // l2
 bool l2_valid;
    mac_addr_t mac_src_addr;
    mac_addr_t mac_dst_addr;
    bit<16> mac_type;
    bit<3> pcp;
 bit<1> pad; // to keep everything byte-aligned, so that the parser can extract to this struct.
 vlan_id_t vid;

 // l3
    switch_ip_type_t ip_type;
    bit<8> ip_proto;
    bit<8> ip_tos;
 bit<3> ip_flags;
    bit<128> ip_src_addr;
    bit<128> ip_dst_addr;
 bit<32> ip_src_addr_v4;
 bit<32> ip_dst_addr_v4;
    @pa_alias("ingress" , "ig_md.lkp_0.ip_src_addr[31:0]", "ig_md.lkp_0.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_0.ip_dst_addr[31:0]", "ig_md.lkp_0.ip_dst_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_1.ip_dst_addr[31:0]", "ig_md.lkp_1.ip_dst_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_src_addr[31:0]", "ig_md.lkp_2.ip_src_addr_v4" )
    @pa_alias("ingress" , "ig_md.lkp_2.ip_dst_addr[31:0]", "ig_md.lkp_2.ip_dst_addr_v4" )
    @pa_alias("egress" , "eg_md.lkp_1.ip_src_addr[31:0]", "eg_md.lkp_1.ip_src_addr_v4" )
    @pa_alias("egress" , "eg_md.lkp_1.ip_dst_addr[31:0]", "eg_md.lkp_1.ip_dst_addr_v4" )
    bit<16> ip_len;

 // l4
    bit<8> tcp_flags;
    bit<16> l4_src_port;
    bit<16> l4_dst_port;

 // tunnel
    switch_tunnel_type_t tunnel_type;
    switch_tunnel_vni_t tunnel_id;

    switch_tunnel_type_t tunnel_outer_type; // egress only
    switch_tunnel_type_t tunnel_inner_type; // egress only

 // misc
 bool next_lyr_valid;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

// Header types used by ingress/egress deparsers.
@flexible
struct switch_bridged_metadata_t {
    // user-defined metadata carried over from ingress to egress.
    switch_port_t ingress_port;

//  switch_port_t egress_port; // derek added



//  switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
 bool bypass_egress;
 switch_cpu_reason_t cpu_reason;



    bit<32> timestamp;

 switch_qid_t qid;

    // Add more fields here.

    switch_hash_t hash;
 bool transport_valid;
    bool nsh_md_end_of_path;
    bool nsh_md_l2_fwd_en;
 bool nsh_md_dedup_en;
}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_acl_extension_t {
# 832 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
    bit<8> tcp_flags;

}

// ----------------------------------------

@flexible
struct switch_bridged_metadata_tunnel_extension_t {
    switch_tunnel_ip_index_t dip_index;
    switch_tunnel_nexthop_t tunnel_nexthop;



//  bool terminate;
}

// ----------------------------------------
/*
@flexible
struct switch_bridged_metadata_nsh_extension_t {
    // ---------------
    // nsh meta data
    // ---------------
    bool                            nsh_md_end_of_path;
    bool                            nsh_md_l2_fwd_en;

	bool                            nsh_md_dedup_en;
}
*/
// ----------------------------------------
# 895 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
// ----------------------------------------

typedef bit<8> switch_bridge_type_t;

header switch_bridged_metadata_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_t base;
//	switch_bridged_metadata_nsh_extension_t nsh;





    switch_bridged_metadata_tunnel_extension_t tunnel;

    switch_bridged_metadata_dtel_extension_t dtel;
}

// --------------------------------------------------------------------------------
// Bridged Metadata
// --------------------------------------------------------------------------------

@flexible
struct switch_bridged_metadata_folded_t {
 // user-defined metadata carried over from egress to ingress.
    switch_port_t ingress_port;
//  switch_bd_t ingress_bd;
    switch_nexthop_t nexthop;
//  switch_pkt_type_t pkt_type;
    bool bypass_egress;
    switch_cpu_reason_t cpu_reason;



    bit<32> timestamp;

    switch_qid_t qid;

 // Add more fields here.

    switch_hash_t hash;
 bool transport_valid;
    bool nsh_md_end_of_path;
    bool nsh_md_l2_fwd_en;
 bool nsh_md_dedup_en;
}

// ----------------------------------------

header switch_bridged_metadata_folded_h {
    switch_pkt_src_t src;
    switch_bridge_type_t type;
    switch_bridged_metadata_folded_t base;
//	switch_bridged_metadata_nsh_extension_t nsh;





    switch_bridged_metadata_tunnel_extension_t tunnel;

    switch_bridged_metadata_dtel_extension_t dtel;
}

// --------------------------------------------------------------------------------
// Ingress Port Metadata
// --------------------------------------------------------------------------------

struct switch_port_metadata_t {
# 973 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
/*
    switch_yid_t exclusion_id;

	// for packets w/o nsh header:
    bit<SSAP_ID_WIDTH>              sap;
    bit<VPN_ID_WIDTH>               vpn;
    bit<SPI_WIDTH>                  spi;
    bit<8>                          si;
    bit<8>                          si_predec;
*/

}

@pa_auto_init_metadata

// --------------------------------------------------------------------------------
// Ingress Metadata
// --------------------------------------------------------------------------------

@pa_container_size("ingress", "ig_md.mirror.src", 8)
@pa_container_size("ingress", "ig_md.mirror.type", 8)
//@pa_container_size("ingress", "smac_src_move", 16)
@pa_alias("ingress", "ig_md.egress_port", "ig_intr_md_for_tm.ucast_egress_port")

@pa_alias("ingress", "ig_md.multicast.id", "ig_intr_md_for_tm.mcast_grp_b")

@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
//@pa_alias("ingress", "ig_md.qos.icos", "ig_intr_md_for_tm.ingress_cos")

@pa_alias("ingress", "ig_intr_md_for_dprsr.mirror_type", "ig_md.mirror.type")


struct switch_ingress_metadata_t {
    switch_port_t port; /* ingress port */
    switch_port_t egress_port; /* egress  port */
    switch_port_lag_index_t port_lag_index; /* ingress port/lag index */
    switch_port_lag_index_t egress_port_lag_index; /* egress  port/lag index */ /* derek: passed to egress */
    switch_bd_t bd;
    switch_nexthop_t nexthop; /* derek: egress table pointer #1 */
    switch_tunnel_nexthop_t tunnel_nexthop; /* derek: egress table pointer #2 */
//  switch_nexthop_t acl_nexthop;
//  bool acl_redirect;
 switch_nexthop_t unused_nexthop;




    bit<32> timestamp;

    switch_hash_t hash;

    switch_ingress_flags_t flags;
//  switch_ingress_checks_t checks;
 switch_ingress_bypass_t bypass;

 switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason; // used by dtel code

//#ifdef INGRESS_PARSER_POPULATES_LKP_0
    switch_lookup_fields_t lkp_0;
//#endif
    switch_lookup_fields_t lkp_1; // initially non-scoped, later scoped, version of fields
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
    switch_lookup_fields_t lkp_2; // non-scoped version of fields
//#endif
    switch_multicast_metadata_t multicast;
 switch_qos_metadata_t qos;
 switch_mirror_metadata_t mirror;

    switch_tunnel_metadata_t tunnel_0; // non-scoped version of fields /* derek: egress table pointer #3 (tunnel_0.dip_index) */
    switch_tunnel_metadata_reduced_t tunnel_1; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3; // non-scoped version of fields

 switch_dtel_metadata_t dtel;

    nsh_metadata_t nsh_md;

//	bool copp_enable;
//	switch_copp_meter_id_t copp_meter_id;

//	switch_header_inner_inner_t inner_inner;
}

// --------------------------------------------------------------------------------
// Egress Metadata
// --------------------------------------------------------------------------------

@pa_container_size("egress", "eg_md.mirror.src", 8)
@pa_container_size("egress", "eg_md.mirror.type", 8)





struct switch_egress_metadata_t {
    switch_pkt_src_t pkt_src;
//  switch_pkt_type_t pkt_type;
//  switch_pkt_length_t pkt_length;
    switch_pkt_length_t payload_len;

    switch_port_lag_index_t port_lag_index; /* egress port/lag index */
    switch_port_t port; /* Mutable copy of egress port */

//  switch_port_t port_orig;                    /* Mutable copy of egress port */

    switch_port_t ingress_port; /* ingress port */
    switch_bd_t bd;
    switch_nexthop_t nexthop;
    switch_tunnel_nexthop_t tunnel_nexthop;





    bit<32> timestamp;
    bit<32> ingress_timestamp;

    switch_hash_t hash;

    switch_egress_flags_t flags;
//  switch_egress_checks_t checks;

 switch_cpu_reason_t cpu_reason;
    switch_drop_reason_t drop_reason; // used by dtel code

    switch_lookup_fields_t lkp_1; //     scoped version of fields
//  switch_tunnel_type_t   lkp_1_tunnel_outer_type;
//  switch_tunnel_type_t   lkp_1_tunnel_inner_type;
 switch_qos_metadata_t qos;
    switch_tunnel_metadata_t tunnel_0; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_1; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_2; // non-scoped version of fields
    switch_tunnel_metadata_reduced_t tunnel_3; // non-scoped version of fields
 switch_mirror_metadata_t mirror;
 switch_dtel_metadata_t dtel;

    nsh_metadata_t nsh_md;

//	bool copp_enable;
//	switch_copp_meter_id_t copp_meter_id;

//  bit<6>                                          action_bitmask;
//  bit<NPB_EGR_SF_EGRESS_SFP_SFF_TABLE_DEPTH_POW2> action_3_meter_id;
//  bit<10>                                         action_3_meter_id;
//  bit<8>                                          action_3_meter_overhead;

//	switch_header_inner_inner_t inner_inner;
}

// --------------------------------------------------------------------------
// Headers
// --------------------------------------------------------------------------

struct switch_mirror_metadata_h {
/*
    switch_port_mirror_ingress_metadata_h port_ingress;
    switch_port_mirror_egress_metadata_h port_egress;
*/
    switch_cpu_mirror_ingress_metadata_h cpu_ingress;
    switch_cpu_mirror_egress_metadata_h cpu_egress;
    switch_dtel_drop_mirror_metadata_h dtel_drop;
    switch_dtel_switch_local_mirror_metadata_h dtel_switch_local;
    switch_simple_mirror_metadata_h simple_mirror;
}

// -----------------------------------------------------------------------------

struct switch_header_transport_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;
    nsh_type1_h nsh_type1;
    nsh_type1_internal_h nsh_type1_internal;
    mpls_h[4] mpls;
    ipv4_h ipv4;
    ipv6_h ipv6;
    gre_h gre;
 gre_extension_sequence_h gre_sequence;
    erspan_type2_h erspan_type2;
    //erspan_type3_h erspan_type3;
    udp_h udp;
    geneve_h geneve;
    vxlan_h vxlan;
# 1166 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4"
    dtel_report_v05_h dtel;
    dtel_report_base_h dtel_report;
    dtel_switch_local_report_h dtel_switch_local_report;
    dtel_drop_report_h dtel_drop_report;

}

// -----------------------------------------------------------------------------

struct switch_header_outer_t {

    ethernet_h ethernet;

    e_tag_h e_tag;
    vn_tag_h vn_tag;
    vlan_tag_h[2] vlan_tag;






    ipv4_h ipv4;

    ipv6_h ipv6;

    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;
    geneve_h geneve;
    vxlan_h vxlan;
    gre_h gre;
    gre_optional_h gre_optional;
    nvgre_h nvgre;

    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;
 gtp_v2_base_h gtp_v2_base;

}

// -----------------------------------------------------------------------------

struct switch_header_inner_t {

    ethernet_h ethernet;
    vlan_tag_h[1] vlan_tag;

    ipv4_h ipv4;

    ipv6_h ipv6;


    udp_h udp;
    tcp_h tcp;
    sctp_h sctp;


    gre_h gre;
    gre_optional_h gre_optional;



    gtp_v1_base_h gtp_v1_base;
    gtp_v1_optional_h gtp_v1_optional;
 gtp_v2_base_h gtp_v2_base;


}

// -----------------------------------------------------------------------------

struct switch_header_inner_inner_t {
 dummy_ethernet_h ethernet;
 dummy_ipv4_h ipv4;
 dummy_ipv6_h ipv6;
}

// -----------------------------------------------------------------------------

struct switch_header_t {

    // ===========================
    // misc
    // ===========================

    switch_bridged_metadata_h bridged_md;
 // switch_mirror_metadata_h mirror;
 switch_bridged_metadata_folded_h bridged_md_folded;
    fabric_h fabric;
    cpu_h cpu;

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
    // inner
    // ===========================

    switch_header_inner_inner_t inner_inner;

    // ===========================
    // layer7
    // ===========================

    udf_h udf;

}
# 45 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/util.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4" 1
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
# 27 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/util.p4" 2

// -----------------------------------------------------------------------------

// Bridged metadata fields for Egress pipeline.
control add_bridged_md(
 inout switch_bridged_metadata_h bridged_md,
 in switch_ingress_metadata_t ig_md
) {
 apply {
  bridged_md.setValid();
  bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
  bridged_md.base = {
   ig_md.port,

//			ig_md.egress_port, // derek added



//			ig_md.bd,
   ig_md.nexthop,
//			ig_md.lkp.pkt_type,
   ig_md.flags.bypass_egress,
   ig_md.cpu_reason,
   ig_md.timestamp,
   ig_md.qos.qid,

   // Add more fields here.
   ig_md.hash,
   ig_md.flags.transport_valid,
   ig_md.nsh_md.end_of_path,
   ig_md.nsh_md.l2_fwd_en,
   ig_md.nsh_md.dedup_en
  };
/*
		bridged_md.nsh = {
			ig_md.nsh_md.end_of_path,
			ig_md.nsh_md.l2_fwd_en,
			ig_md.nsh_md.dedup_en
		};
*/

  bridged_md.tunnel = {
   ig_md.tunnel_0.dip_index,
   ig_md.tunnel_nexthop
//			ig_md.hash[15:0],

//			ig_md.tunnel_0.terminate // unused, but removing causes a compiler error
//			ig_md.tunnel_1.terminate,
//			ig_md.tunnel_2.terminate
  };


  bridged_md.dtel = {
//			ig_md.dtel.report_type,
//			ig_md.dtel.session_id,
//			ig_md.hash,
//			ig_md.egress_port
  };
 }
}

// -----------------------------------------------------------------------------

// Bridged metadata fields for Ingress pipeline.
control add_bridged_md_folded(
 inout switch_bridged_metadata_folded_h bridged_md,
 in switch_egress_metadata_t eg_md
) {
 apply {
  bridged_md.setValid();
  bridged_md.src = SWITCH_PKT_SRC_BRIDGED;
  bridged_md.base = {
   eg_md.ingress_port,
//			eg_md.bd,
   eg_md.nexthop,
//			eg_md.lkp.pkt_type,
   false,
   0,
   eg_md.ingress_timestamp,
   eg_md.qos.qid,

   // Add more fields here.
   eg_md.hash,
   eg_md.flags.transport_valid,
   eg_md.nsh_md.end_of_path,
   eg_md.nsh_md.l2_fwd_en,
   eg_md.nsh_md.dedup_en
  };
/*
		bridged_md.nsh = {
			eg_md.nsh_md.end_of_path,
			eg_md.nsh_md.l2_fwd_en,
			eg_md.nsh_md.dedup_en
		};
*/

  bridged_md.tunnel = {
   eg_md.tunnel_0.dip_index,
   eg_md.tunnel_nexthop
//			eg_md.hash[15:0],

//			eg_md.tunnel_0.terminate // unused, but removing causes a compiler error
//			eg_md.tunnel_1.terminate,
//			eg_md.tunnel_2.terminate
  };


  bridged_md.dtel = {
//			eg_md.dtel.report_type,
//			eg_md.dtel.session_id,
//			eg_md.hash,
//			eg_md.egress_port
  };
 }
}

// -----------------------------------------------------------------------------

action set_ig_intr_md(
 in switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {
 ig_intr_md_for_tm.mcast_grp_b = ig_md.multicast.id;

 // Set PRE hash values
 bit<13> hash;



 hash = ig_md.hash[32/2+12:32/2]; // cap  at 13 bits


//	ig_intr_md_for_tm.level1_mcast_hash = ig_md.hash[12:0];
//	ig_intr_md_for_tm.level2_mcast_hash = ig_md.hash[28:16];
 ig_intr_md_for_tm.level2_mcast_hash = hash;

//	ig_intr_md_for_dprsr.mirror_type = (bit<4>) ig_md.mirror.type;



}

// -----------------------------------------------------------------------------

action set_eg_intr_md(
 in switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {




 eg_intr_md_for_dprsr.mirror_type = (bit<4>) eg_md.mirror.type;
 eg_intr_md_for_dprsr.mirror_io_select = 1;


}
# 46 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/hash.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4" 1
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
# 27 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/hash.p4" 2

// Flow hash calculation.

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Hash Mask -------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control HashMask(
 inout switch_lookup_fields_t lkp,
 inout bit<6> lkp_hash_mask_en
) {

 // -----------------------------------------

 apply {

//		if(lkp_hash_mask_en[0:0] == 1) { lkp.mac_type     = 0; }
//		if(lkp_hash_mask_en[1:1] == 1) { lkp.mac_src_addr = 0; }
//		if(lkp_hash_mask_en[1:1] == 1) { lkp.mac_dst_addr = 0; }
  if(lkp_hash_mask_en[2:2] == 1) { lkp.ip_src_addr = 0; }
  if(lkp_hash_mask_en[2:2] == 1) { lkp.ip_dst_addr = 0; }
  if(lkp_hash_mask_en[3:3] == 1) { lkp.ip_proto = 0; }
  if(lkp_hash_mask_en[4:4] == 1) { lkp.l4_src_port = 0; }
  if(lkp_hash_mask_en[4:4] == 1) { lkp.l4_dst_port = 0; }
  if(lkp_hash_mask_en[5:5] == 1) { lkp.tunnel_id = 0; }

 }
}

// -----------------------------------------------------------------------------

// If fragments, then reset hash l4 port values to zero
// For non fragments, hash l4 ports will be init to l4 port values
control EnableFragHash(
 inout switch_lookup_fields_t lkp
) {
 apply {
//		if (lkp.ip_frag != SWITCH_IP_FRAG_NON_FRAG) {
//			lkp.hash_l4_dst_port = 0;
//			lkp.hash_l4_src_port = 0;
//		}
 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// Hash ------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
# 382 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/hash.p4"
// -----------------------------------------------------------------------------
// Normal Hashes ---------------------------------------------------------------
// -----------------------------------------------------------------------------

control Ipv4Hash(
 in switch_lookup_fields_t lkp,
 out switch_hash_t hash
) (
 switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

 apply {
  hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
   lkp.ip_src_addr_v4,
//			lkp.ip_dst_addr[31:0],
   lkp.ip_dst_addr_v4,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id // extreme added
  });
 }
}

control Ipv6Hash(
 in switch_lookup_fields_t lkp,
 out switch_hash_t hash
) (
 switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

 apply {
  hash[31:0] = ipv6_hash.get({
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id // extreme added
  });
 }
}

control NonIpHash(
 in switch_lookup_fields_t lkp,
 out switch_hash_t hash
) (
 switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

 Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) non_ip_hash;

 apply {
  hash [31:0] = non_ip_hash.get({
   lkp.mac_type,
   lkp.mac_src_addr,
   lkp.mac_dst_addr
  });
 }
}
# 477 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/hash.p4"
// -----------------------------------------------------------------------------
// Symmetric Hashes ------------------------------------------------------------
// -----------------------------------------------------------------------------

control Ipv4HashSymmetric(
 in switch_lookup_fields_t lkp,
 out switch_hash_t hash
) (
 switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
//	@symmetric("ig_md.lkp_1.ip_src_addr[31:0]", "ig_md.lkp_1.ip_dst_addr[31:0]")
 @symmetric("ig_md.lkp_1.ip_src_addr_v4", "ig_md.lkp_1.ip_dst_addr_v4")
 @symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv4_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv4_hash;

 apply {
  hash [31:0] = ipv4_hash.get({
//			lkp.ip_src_addr[31:0],
   lkp.ip_src_addr_v4,
//			lkp.ip_dst_addr[31:0],
   lkp.ip_dst_addr_v4,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id // extreme added
  });
 }
}

control Ipv6HashSymmetric(
 in switch_lookup_fields_t lkp,
 out switch_hash_t hash
) (
 switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
 @symmetric("ig_md.lkp_1.ip_src_addr", "ig_md.lkp_1.ip_dst_addr")
 @symmetric("ig_md.lkp_1.l4_src_port", "ig_md.lkp_1.l4_dst_port")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

 Hash<bit<32>>(HashAlgorithm_t.CRC32) ipv6_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) ipv6_hash;

 apply {
  hash[31:0] = ipv6_hash.get({
   lkp.ip_src_addr,
   lkp.ip_dst_addr,
   lkp.ip_proto,
   lkp.l4_dst_port,
   lkp.l4_src_port,
   lkp.tunnel_id // extreme added
  });
 }
}

control NonIpHashSymmetric(
 in switch_lookup_fields_t lkp,
 out switch_hash_t hash
) (
 switch_uint32_t coeff = 0x04c11db7 // crc32 -- for making wider hashes, we can pass in other polynoials (see training docs for more info)
) {
 @symmetric("ig_md.lkp_1.mac_src_addr", "ig_md.lkp_1.mac_dst_addr")

//	CRCPolynomial<bit<32>>(coeff = coeff, reversed = true, msb = false, extended = false, init = 0xffffffff, xor = 0xffffffff) poly; // crc32

 Hash<bit<32>>(HashAlgorithm_t.CRC32) non_ip_hash;
//	Hash<bit<32>>(HashAlgorithm_t.CUSTOM, poly) non_ip_hash;

 apply {
  hash [31:0] = non_ip_hash.get({
   lkp.mac_type,
   lkp.mac_src_addr,
   lkp.mac_dst_addr
  });
 }
}
# 47 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2

# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l3.p4" 1
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

// DEREK: NOT USING THIS TABLE ANYMORE -- USING THE TABLE IN TUNNEL.P4 INSTEAD.




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_lkp_to_lkp.p4" 1
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
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_Lkp_To_Lkp(
 in switch_lookup_fields_t lkp_curr,

 inout switch_lookup_fields_t lkp
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

//	action scoper() {
 apply {




  // l2
  if(lkp_curr.l2_valid != false) {
   // only update if next layer has l2
   lkp.mac_src_addr = lkp_curr.mac_src_addr;
   lkp.mac_dst_addr = lkp_curr.mac_dst_addr;
//			lkp.mac_type            = lkp_curr.mac_type;
   lkp.pcp = lkp_curr.pcp;
   lkp.pad = lkp_curr.pad;
   lkp.vid = lkp_curr.vid;
  }
  lkp.mac_type = lkp_curr.mac_type;

  // l3
  lkp.ip_type = lkp_curr.ip_type;
  lkp.ip_proto = lkp_curr.ip_proto;
  lkp.ip_tos = lkp_curr.ip_tos;
  lkp.ip_flags = lkp_curr.ip_flags;
  lkp.ip_src_addr = lkp_curr.ip_src_addr;
  lkp.ip_dst_addr = lkp_curr.ip_dst_addr;
  // Comment the two below as they are alias fields and do not need to be written again.
  //lkp.ip_src_addr_v4    = lkp_curr.ip_src_addr_v4;
  //lkp.ip_dst_addr_v4    = lkp_curr.ip_dst_addr_v4;
  lkp.ip_len = lkp_curr.ip_len;

  // l4
  lkp.tcp_flags = lkp_curr.tcp_flags;
  lkp.l4_src_port = lkp_curr.l4_src_port;
  lkp.l4_dst_port = lkp_curr.l4_dst_port;

  // tunnel

  if(lkp_curr.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) {
   // only update if next layer has tunnel
   lkp.tunnel_type = lkp_curr.tunnel_type;
   lkp.tunnel_id = lkp_curr.tunnel_id;
  }






  // outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
  lkp.tunnel_outer_type = lkp_curr.tunnel_outer_type; // egress only
  lkp.tunnel_inner_type = lkp_curr.tunnel_inner_type; // egress only


  // misc
  lkp.next_lyr_valid = lkp_curr.next_lyr_valid;

 }
/*
	apply {
		scoper();
	}
*/
}
# 27 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr0_to_lkp.p4" 1
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
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_Hdr0_To_Lkp(
 in switch_header_transport_t hdr_curr,
 in switch_header_outer_t hdr_next,
 in switch_lookup_fields_t lkp_curr,
 in bool flags_unsupported_tunnel,

 inout switch_lookup_fields_t lkp
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // -----------------------------
 // L2
 // -----------------------------
/*
	action scope_l2_none() {
		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
	}
*/
 action scope_l2_0tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.ethernet.ether_type;
  lkp.pcp = 0;
  lkp.pad = 0;
  lkp.vid = 0;
 }

 action scope_l2_1tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.vlan_tag[0].ether_type;
  lkp.pcp = hdr_curr.vlan_tag[0].pcp;
  lkp.pad = 0;
  lkp.vid = hdr_curr.vlan_tag[0].vid;
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = SWITCH_IP_TYPE_NONE;
  lkp.ip_proto = 0;
  lkp.ip_tos = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_proto = hdr_curr.ipv4.protocol;
  lkp.ip_tos = hdr_curr.ipv4.tos;
  lkp.ip_flags = hdr_curr.ipv4.flags;
  lkp.ip_src_addr_v4= hdr_curr.ipv4.src_addr;
  lkp.ip_dst_addr_v4= hdr_curr.ipv4.dst_addr;
  lkp.ip_len = hdr_curr.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_proto = hdr_curr.ipv6.next_hdr;
  lkp.ip_tos = hdr_curr.ipv6.tos;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_curr.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_curr.ipv6.dst_addr;
  lkp.ip_len = hdr_curr.ipv6.payload_len;

 }

 // -----------------------------
 // L4
 // -----------------------------

 action scope_l4_none() {
  lkp.l4_src_port = 0;
  lkp.l4_dst_port = 0;
  lkp.tcp_flags = 0;
 }


 action scope_l4_udp() {
  lkp.l4_src_port = hdr_curr.udp.src_port;
  lkp.l4_dst_port = hdr_curr.udp.dst_port;
  lkp.tcp_flags = 0;
 }


 // -----------------------------
 // TUNNEL
 // -----------------------------

 action scope_tunnel_none() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = false;
 }

 action scope_tunnel_ipinip() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = true;
 }

 action scope_tunnel_gre() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = true;
 }

 action scope_tunnel_erspan() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;



  lkp.tunnel_id = 0;

  lkp.next_lyr_valid = true;
 }

 action scope_tunnel_vxlan() {

  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
  lkp.tunnel_id = (bit<32>)hdr_curr.vxlan.vni;
  lkp.next_lyr_valid = true;

 }

 action scope_tunnel_mpls0() {

  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
  lkp.tunnel_id = hdr_curr.mpls[0].label ++ hdr_curr.mpls[0].exp ++ hdr_curr.mpls[0].bos ++ hdr_curr.mpls[0].ttl;
  lkp.next_lyr_valid = true;

 }

 action scope_tunnel_mpls1() {


  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
  lkp.tunnel_id = hdr_curr.mpls[1].label ++ hdr_curr.mpls[1].exp ++ hdr_curr.mpls[1].bos ++ hdr_curr.mpls[1].ttl;
  lkp.next_lyr_valid = true;


 }

 action scope_tunnel_mpls2() {


  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
  lkp.tunnel_id = hdr_curr.mpls[2].label ++ hdr_curr.mpls[2].exp ++ hdr_curr.mpls[2].bos ++ hdr_curr.mpls[2].ttl;
  lkp.next_lyr_valid = true;


 }

 action scope_tunnel_mpls3() {


  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
  lkp.tunnel_id = hdr_curr.mpls[3].label ++ hdr_curr.mpls[3].exp ++ hdr_curr.mpls[3].bos ++ hdr_curr.mpls[3].ttl;
  lkp.next_lyr_valid = true;


 }

 action scope_tunnel_unsupported() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = false; // unsupported has no next layer
 }

 action scope_tunnel_use_parser_values(bool lkp_curr_next_lyr_valid) {
  lkp.tunnel_type = lkp_curr.tunnel_type;
  lkp.tunnel_id = lkp_curr.tunnel_id;
  lkp.next_lyr_valid = lkp_curr_next_lyr_valid;
 }

 // -----------------------------
/*
	table scope_tunnel_ {
		key = {
			flags_unsupported_tunnel: exact;

			hdr_curr.gre.isValid(): exact;
			hdr.curr.erspan_type2.isValid(): exact;
#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
			hdr_curr.vxlan.isValid(): exact;
#endif // VXLAN_TRANSPORT_INGRESS_ENABLE_V4
#ifdef MPLS_SR_TRANSPORT_INGRESS_ENABLE
			hdr_curr.mpls[0].isValid(): exact;
			hdr_curr.mpls[1].isValid(): exact;
			hdr_curr.mpls[2].isValid(): exact;
			hdr_curr.mpls[3].isValid(): exact;
#endif // MPLS_SR_TRANSPORT_INGRESS_ENABLE

			hdr_next.ipv4.isValid(): exact;
			hdr_next.ipv6.isValid(): exact;
		}
		actions = {
			scope_tunnel_gre;
			scope_tunnel_erspan;
			scope_tunnel_vxlan;
			scope_tunnel_mpls0;
			scope_tunnel_mpls1;
			scope_tunnel_mpls2;
			scope_tunnel_mpls3;
			scope_tunnel_ipinip;
			scope_tunnel_none;
			scope_tunnel_unsupported;
		}
		const entries = {
#if !defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) && !defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE)
		const entries = {
			//      hdr0                                             hdr1
			// ---- ------------------------------------------------ ------------
			(true,  true,  false,                                    false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  false,                                    false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false,                                    true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false,                                    false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(true,  true,  true,                                     false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  true,                                     false, false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,                                     true,  false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,                                     false, true ): scope_tunnel_erspan(); // hdr1 is a don't care

			{true,  false, false,                                    false, false}: scope_tunnel_unsupported(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false,                                    true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false,                                    false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif // !VXLAN_TRANSPORT_INGRESS_ENABLE_V4 && !MPLS_SR_TRANSPORT_INGRESS_ENABLE
#if  defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) && !defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE)
			//      hdr0                                             hdr1
			// ---- ------------------------------------------------ ------------
			(true,  true,  false, false,                             false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  false, false,                             false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false, false,                             true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false, false,                             false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(true,  true,  true,  false,                             false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  true,  false,                             false, false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,  false,                             true,  false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,  false,                             false, true ): scope_tunnel_erspan(); // hdr1 is a don't care

			(true,  false, false, true,                              false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false, true,                              false, false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, false, false, true,                              true,  false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, false, false, true,                              false, true ): scope_tunnel_vxlan(); // hdr1 is a don't care

			{true,  false, false, false,                             false, false}: scope_tunnel_unsupported(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false, false,                             true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false, false,                             false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif //  VXLAN_TRANSPORT_INGRESS_ENABLE_V4 && !MPLS_SR_TRANSPORT_INGRESS_ENABLE
#if !defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) &&  defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE)
			//      hdr0                                             hdr1
			// ---- ------------------------------------------------ ------------
			(true,  true,  false,        false, false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  false,        false, false, false, false, false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false,        false, false, false, false, true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false,        false, false, false, false, false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(true,  true,  true,         false, false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  true,         false, false, false, false, false, false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,         false, false, false, false, true,  false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,         false, false, false, false, false, true ): scope_tunnel_erspan(); // hdr1 is a don't care

			(true,  false, false,        true,  false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false,        true,  false, false, false, false, false): scope_tunnel_mpls0(); // hdr1 is a don't care
			(false, false, false,        true,  false, false, false, true,  false): scope_tunnel_mpls0(); // hdr1 is a don't care
			(false, false, false,        true,  false, false, false, false, true ): scope_tunnel_mpls0(); // hdr1 is a don't care
			(true,  false, false,        true,  true,  false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false,        true,  true,  false, false, false, false): scope_tunnel_mpls1(); // hdr1 is a don't care
			(false, false, false,        true,  true,  false, false, true,  false): scope_tunnel_mpls1(); // hdr1 is a don't care
			(false, false, false,        true,  true,  false, false, false, true ): scope_tunnel_mpls1(); // hdr1 is a don't care
			(true,  false, false,        true,  true,  true,  false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false,        true,  true,  true,  false, false, false): scope_tunnel_mpls2(); // hdr1 is a don't care
			(false, false, false,        true,  true,  true,  false, true,  false): scope_tunnel_mpls2(); // hdr1 is a don't care
			(false, false, false,        true,  true,  true,  false, false, true ): scope_tunnel_mpls2(); // hdr1 is a don't care
			(true,  false, false,        true,  true,  true,  true,  false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false,        true,  true,  true,  true,  false, false): scope_tunnel_mpls3(); // hdr1 is a don't care
			(false, false, false,        true,  true,  true,  true,  true,  false): scope_tunnel_mpls3(); // hdr1 is a don't care
			(false, false, false,        true,  true,  true,  true,  false, true ): scope_tunnel_mpls3(); // hdr1 is a don't care

			{true,  false, false,        false, false, false, false, false, false}: scope_tunnel_unsupported(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false,        false, false, false, false, true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false,        false, false, false, false, false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif // !VXLAN_TRANSPORT_INGRESS_ENABLE_V4 &&  MPLS_SR_TRANSPORT_INGRESS_ENABLE
#if  defined(VXLAN_TRANSPORT_INGRESS_ENABLE_V4) &&  defined(MPLS_SR_TRANSPORT_INGRESS_ENABLE)
			//      hdr0                                             hdr1
			// ---- ------------------------------------------------ ------------
			(true,  true,  false, false, false, false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  false, false, false, false, false, false, false, false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false, false, false, false, false, false, true,  false): scope_tunnel_gre(); // hdr1 is a don't care
			(false, true,  false, false, false, false, false, false, false, true ): scope_tunnel_gre(); // hdr1 is a don't care

			(true,  true,  true,  false, false, false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, true,  true,  false, false, false, false, false, false, false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,  false, false, false, false, false, true,  false): scope_tunnel_erspan(); // hdr1 is a don't care
			(false, true,  true,  false, false, false, false, false, false, true ): scope_tunnel_erspan(); // hdr1 is a don't care

			(true,  false, false, true,  false, false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false, true,  false, false, false, false, false, false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, false, false, true,  false, false, false, false, true,  false): scope_tunnel_vxlan(); // hdr1 is a don't care
			(false, false, false, true,  false, false, false, false, false, true ): scope_tunnel_vxlan(); // hdr1 is a don't care

			(true,  false, false, false, true,  false, false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false, false, true,  false, false, false, false, false): scope_tunnel_mpls0(); // hdr1 is a don't care
			(false, false, false, false, true,  false, false, false, true,  false): scope_tunnel_mpls0(); // hdr1 is a don't care
			(false, false, false, false, true,  false, false, false, false, true ): scope_tunnel_mpls0(); // hdr1 is a don't care
			(true,  false, false, false, true,  true,  false, false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  false, false, false, false): scope_tunnel_mpls1(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  false, false, true,  false): scope_tunnel_mpls1(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  false, false, false, true ): scope_tunnel_mpls1(); // hdr1 is a don't care
			(true,  false, false, false, true,  true,  true,  false, false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  true,  false, false, false): scope_tunnel_mpls2(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  true,  false, true,  false): scope_tunnel_mpls2(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  true,  false, false, true ): scope_tunnel_mpls2(); // hdr1 is a don't care
			(true,  false, false, false, true,  true,  true,  true,  false, false): scope_tunnel_unsupported(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  true,  true,  false, false): scope_tunnel_mpls3(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  true,  true,  true,  false): scope_tunnel_mpls3(); // hdr1 is a don't care
			(false, false, false, false, true,  true,  true,  true,  false, true ): scope_tunnel_mpls3(); // hdr1 is a don't care

			{true,  false, false, false, false, false, false, false, false, false}: scope_tunnel_unsupported(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false, false, false, false, false, false, true,  false}: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			{false, false, false, false, false, false, false, false, false, true }: scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
#endif //  VXLAN_TRANSPORT_INGRESS_ENABLE_V4 &&  MPLS_SR_TRANSPORT_INGRESS_ENABLE
		const default_action = scope_tunnel_none;
	}
*/
 table scope_tunnel_ {
  key = {
   lkp_curr.tunnel_type: exact;
  }
  actions = {
   scope_tunnel_none;
   scope_tunnel_use_parser_values;
  }
  const entries = {
   (SWITCH_TUNNEL_TYPE_GTPC): scope_tunnel_use_parser_values(false);
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
   (SWITCH_TUNNEL_TYPE_VXLAN): scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP): scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
  }
  const default_action = scope_tunnel_use_parser_values(true);
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------

//	action scope_l2_none_l3_none_l4_none() { scope_l2_none(); scope_l3_none(); scope_l4_none(); }

 action scope_l2_0tag_l3_none_l4_none() { scope_l2_0tag(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }

 action scope_l2_0tag_l3_v4_l4_none() { scope_l2_0tag(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_1tag_l3_v4_l4_none() { scope_l2_1tag(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_0tag_l3_v4_l4_udp() { scope_l2_0tag(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v4_l4_udp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_udp(); }

 action scope_l2_0tag_l3_v6_l4_none() { scope_l2_0tag(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_1tag_l3_v6_l4_none() { scope_l2_1tag(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_0tag_l3_v6_l4_udp() { scope_l2_0tag(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v6_l4_udp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_udp(); }

 // -----------------------------

 table scope_l234_ {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;
   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;


   hdr_curr.udp.isValid(): exact;

  }
  actions = {
//			scope_l2_none_l3_none_l4_none;

   scope_l2_0tag_l3_none_l4_none;
   scope_l2_1tag_l3_none_l4_none;

   scope_l2_0tag_l3_v4_l4_none;
   scope_l2_1tag_l3_v4_l4_none;

   scope_l2_0tag_l3_v4_l4_udp;
   scope_l2_1tag_l3_v4_l4_udp;


   scope_l2_0tag_l3_v6_l4_none;
   scope_l2_1tag_l3_v6_l4_none;

   scope_l2_0tag_l3_v6_l4_udp;
   scope_l2_1tag_l3_v6_l4_udp;

  }
  const entries = {


   // l2             l3                l4
   // ----------     -------------     ------
   (true, false, false, false, false): scope_l2_0tag_l3_none_l4_none;
   (true, true, false, false, false): scope_l2_1tag_l3_none_l4_none;

   (true, false, true, false, false): scope_l2_0tag_l3_v4_l4_none;
   (true, true, true, false, false): scope_l2_1tag_l3_v4_l4_none;
   (true, false, true, false, true ): scope_l2_0tag_l3_v4_l4_udp;
   (true, true, true, false, true ): scope_l2_1tag_l3_v4_l4_udp;

   (true, false, false, true, false): scope_l2_0tag_l3_v6_l4_none;
   (true, true, false, true, false): scope_l2_1tag_l3_v6_l4_none;
   (true, false, false, true, true ): scope_l2_0tag_l3_v6_l4_udp;
   (true, true, false, true, true ): scope_l2_1tag_l3_v6_l4_udp;
# 488 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr0_to_lkp.p4"
  }
//		const default_action = scope_l2_none_l3_none_l4_none;
 }

 apply {
  scope_l234_.apply();
  // Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_curr.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_curr.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_curr.next_lyr_valid);
		}
*/
  scope_tunnel_.apply();
 }
}
# 28 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr1_to_lkp.p4" 1
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
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_Hdr1_To_Lkp(
 in switch_header_outer_t hdr_curr,
 in switch_header_inner_t hdr_next,
 in switch_lookup_fields_t lkp_curr,
 in bool flags_unsupported_tunnel,

 inout switch_lookup_fields_t lkp
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // -----------------------------
 // L2
 // -----------------------------
/*
	action scope_l2_none() {
#ifdef INGRESS_MAU_NO_LKP_1
		// do nothing...keep previous layer's values
#else
//		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
//		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
		lkp.l2_valid     = false;
		lkp.mac_type     = 0;
	}
*/
 action scope_l2_none_v4() {

  // do nothing...keep previous layer's values
# 73 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr1_to_lkp.p4"
  lkp.l2_valid = false;
  lkp.mac_type = 0x0800;
 }

 action scope_l2_none_v6() {

  // do nothing...keep previous layer's values
# 89 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr1_to_lkp.p4"
  lkp.l2_valid = false;
  lkp.mac_type = 0x86dd;
 }

 action scope_l2_0tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.ethernet.ether_type;
  lkp.pcp = 0;
  lkp.pad = 0;
  lkp.vid = 0;
 }

 action scope_l2_e_tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.e_tag.ether_type;
  //lkp.pcp          = hdr_curr.e_tag.pcp;
  lkp.pcp = 0; // do not populate w/ e-tag
  lkp.pad = 0;
  lkp.vid = 0;
 }

 action scope_l2_vn_tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.vn_tag.ether_type;
  lkp.pcp = 0;
  lkp.pad = 0;
  lkp.vid = 0;
 }

 action scope_l2_1tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.vlan_tag[0].ether_type;
  lkp.pcp = hdr_curr.vlan_tag[0].pcp;
  lkp.pad = 0;
  lkp.vid = hdr_curr.vlan_tag[0].vid;
 }

 action scope_l2_2tags() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.vlan_tag[1].ether_type;
  lkp.pcp = hdr_curr.vlan_tag[1].pcp;
  lkp.pad = 0;
  lkp.vid = hdr_curr.vlan_tag[1].vid;
 }

 // -----------------------------

 @name("scope_l2_")
 table scope_l2_ {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;
   hdr_curr.vlan_tag[1].isValid(): exact;

   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

  }
  actions = {
//			scope_l2_none;
   scope_l2_none_v4;
   scope_l2_none_v6;
   scope_l2_0tag;
//			scope_l2_e_tag;
//			scope_l2_vn_tag;
   scope_l2_1tag;
   scope_l2_2tags;
  }
  const entries = {
   // l2                 l3
   // ------------------ ------------
//			(false, false, false, false, false): scope_l2_none();
   (false, false, false, true, false): scope_l2_none_v4();
   (false, false, false, false, true ): scope_l2_none_v6();

   (true, false, false, false, false): scope_l2_0tag();
   (true, false, false, true, false): scope_l2_0tag();
   (true, false, false, false, true ): scope_l2_0tag();

   (true, true, false, false, false): scope_l2_1tag();
   (true, true, false, true, false): scope_l2_1tag();
   (true, true, false, false, true ): scope_l2_1tag();

   (true, true, true, false, false): scope_l2_2tags();
   (true, true, true, true, false): scope_l2_2tags();
   (true, true, true, false, true ): scope_l2_2tags();
  }
 }

 // -----------------------------

 @name("scope_l2_")
 table scope_l2_etag {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.e_tag.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;
   hdr_curr.vlan_tag[1].isValid(): exact;

   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

  }
  actions = {
//			scope_l2_none;
   scope_l2_none_v4;
   scope_l2_none_v6;
   scope_l2_0tag;
   scope_l2_e_tag;
//			scope_l2_vn_tag;
   scope_l2_1tag;
   scope_l2_2tags;
  }
  const entries = {
   // l2                        l3
   // ------------------------- ------------
//			(false, false, false, false, false, false): scope_l2_none();
   (false, false, false, false, true, false): scope_l2_none_v4();
   (false, false, false, false, false, true ): scope_l2_none_v6();

   (true, false, false, false, false, false): scope_l2_0tag();
   (true, false, false, false, true, false): scope_l2_0tag();
   (true, false, false, false, false, true ): scope_l2_0tag();

   (true, true, false, false, false, false): scope_l2_e_tag();
   (true, true, false, false, true, false): scope_l2_e_tag();
   (true, true, false, false, false, true ): scope_l2_e_tag();

   (true, false, true, false, false, false): scope_l2_1tag();
   (true, false, true, false, true, false): scope_l2_1tag();
   (true, false, true, false, false, true ): scope_l2_1tag();
   (true, true, true, false, false, false): scope_l2_1tag();
   (true, true, true, false, true, false): scope_l2_1tag();
   (true, true, true, false, false, true ): scope_l2_1tag();

   (true, false, true, true, false, false): scope_l2_2tags();
   (true, false, true, true, true, false): scope_l2_2tags();
   (true, false, true, true, false, true ): scope_l2_2tags();
   (true, true, true, true, false, false): scope_l2_2tags();
   (true, true, true, true, true, false): scope_l2_2tags();
   (true, true, true, true, false, true ): scope_l2_2tags();
  }
 }

 // -----------------------------

 @name("scope_l2_")
 table scope_l2_vntag {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.vn_tag.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;
   hdr_curr.vlan_tag[1].isValid(): exact;

   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

  }
  actions = {
//			scope_l2_none;
   scope_l2_none_v4;
   scope_l2_none_v6;
   scope_l2_0tag;
//			scope_l2_e_tag;
   scope_l2_vn_tag;
   scope_l2_1tag;
   scope_l2_2tags;
  }
  const entries = {
   // l2                        l3
   // ------------------------- ------------
//			(false, false, false, false, false, false): scope_l2_none();
   (false, false, false, false, true, false): scope_l2_none_v4();
   (false, false, false, false, false, true ): scope_l2_none_v6();

   (true, false, false, false, false, false): scope_l2_0tag();
   (true, false, false, false, true, false): scope_l2_0tag();
   (true, false, false, false, false, true ): scope_l2_0tag();

   (true, true, false, false, false, false): scope_l2_vn_tag();
   (true, true, false, false, true, false): scope_l2_vn_tag();
   (true, true, false, false, false, true ): scope_l2_vn_tag();

   (true, false, true, false, false, false): scope_l2_1tag();
   (true, false, true, false, true, false): scope_l2_1tag();
   (true, false, true, false, false, true ): scope_l2_1tag();
   (true, true, true, false, false, false): scope_l2_1tag();
   (true, true, true, false, true, false): scope_l2_1tag();
   (true, true, true, false, false, true ): scope_l2_1tag();

   (true, false, true, true, false, false): scope_l2_2tags();
   (true, false, true, true, true, false): scope_l2_2tags();
   (true, false, true, true, false, true ): scope_l2_2tags();
   (true, true, true, true, false, false): scope_l2_2tags();
   (true, true, true, true, true, false): scope_l2_2tags();
   (true, true, true, true, false, true ): scope_l2_2tags();
  }
 }

 // -----------------------------

 @name("scope_l2_")
 table scope_l2_etag_vntag {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.e_tag.isValid(): exact;
   hdr_curr.vn_tag.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;
   hdr_curr.vlan_tag[1].isValid(): exact;

   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

  }
  actions = {
//			scope_l2_none;
   scope_l2_none_v4;
   scope_l2_none_v6;
   scope_l2_0tag;
   scope_l2_e_tag;
   scope_l2_vn_tag;
   scope_l2_1tag;
   scope_l2_2tags;
  }
  const entries = {
   // l2                               l3
   // -------------------------------- ------------
//			(false, false, false, false, false, false, false): scope_l2_none();
   (false, false, false, false, false, true, false): scope_l2_none_v4();
   (false, false, false, false, false, false, true ): scope_l2_none_v6();

   (true, false, false, false, false, false, false): scope_l2_0tag();
   (true, false, false, false, false, true, false): scope_l2_0tag();
   (true, false, false, false, false, false, true ): scope_l2_0tag();

   (true, true, false, false, false, false, false): scope_l2_e_tag();
   (true, true, false, false, false, true, false): scope_l2_e_tag();
   (true, true, false, false, false, false, true ): scope_l2_e_tag();
   (true, false, true, false, false, false, false): scope_l2_vn_tag();
   (true, false, true, false, false, true, false): scope_l2_vn_tag();
   (true, false, true, false, false, false, true ): scope_l2_vn_tag();

   (true, false, false, true, false, false, false): scope_l2_1tag();
   (true, false, false, true, false, true, false): scope_l2_1tag();
   (true, false, false, true, false, false, true ): scope_l2_1tag();
   (true, true, false, true, false, false, false): scope_l2_1tag();
   (true, true, false, true, false, true, false): scope_l2_1tag();
   (true, true, false, true, false, false, true ): scope_l2_1tag();
   (true, false, true, true, false, false, false): scope_l2_1tag();
   (true, false, true, true, false, true, false): scope_l2_1tag();
   (true, false, true, true, false, false, true ): scope_l2_1tag();

   (true, false, false, true, true, false, false): scope_l2_2tags();
   (true, false, false, true, true, true, false): scope_l2_2tags();
   (true, false, false, true, true, false, true ): scope_l2_2tags();
   (true, true, false, true, true, false, false): scope_l2_2tags();
   (true, true, false, true, true, true, false): scope_l2_2tags();
   (true, true, false, true, true, false, true ): scope_l2_2tags();
   (true, false, true, true, true, false, false): scope_l2_2tags();
   (true, false, true, true, true, true, false): scope_l2_2tags();
   (true, false, true, true, true, false, true ): scope_l2_2tags();
  }
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = SWITCH_IP_TYPE_NONE;
  lkp.ip_tos = 0;
  lkp.ip_proto = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_tos = hdr_curr.ipv4.tos;
  lkp.ip_proto = hdr_curr.ipv4.protocol;
  lkp.ip_flags = hdr_curr.ipv4.flags;
  lkp.ip_src_addr_v4= hdr_curr.ipv4.src_addr;
  lkp.ip_dst_addr_v4= hdr_curr.ipv4.dst_addr;
  lkp.ip_len = hdr_curr.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_tos = hdr_curr.ipv6.tos;
  lkp.ip_proto = hdr_curr.ipv6.next_hdr;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_curr.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_curr.ipv6.dst_addr;
  lkp.ip_len = hdr_curr.ipv6.payload_len;

 }

 // -----------------------------

 table scope_l3_ {
  key = {
   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

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
  lkp.l4_src_port = hdr_curr.tcp.src_port;
  lkp.l4_dst_port = hdr_curr.tcp.dst_port;
  lkp.tcp_flags = hdr_curr.tcp.flags;
 }

 action scope_l4_udp() {
  lkp.l4_src_port = hdr_curr.udp.src_port;
  lkp.l4_dst_port = hdr_curr.udp.dst_port;
  lkp.tcp_flags = 0;
 }

 action scope_l4_sctp() {
  lkp.l4_src_port = hdr_curr.sctp.src_port;
  lkp.l4_dst_port = hdr_curr.sctp.dst_port;
  lkp.tcp_flags = 0;
 }

 // -----------------------------

 table scope_l4_ {
  key = {
   hdr_curr.tcp.isValid(): exact;
   hdr_curr.udp.isValid(): exact;
   hdr_curr.sctp.isValid(): exact;
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
 // L3 / L4
 // -----------------------------

 action scope_l3_none_l4_none() { scope_l3_none(); scope_l4_none(); }
 action scope_l3_v4_l4_none() { scope_l3_v4(); scope_l4_none(); }
 action scope_l3_v6_l4_none() { scope_l3_v6(); scope_l4_none(); }
 action scope_l3_v4_l4_tcp() { scope_l3_v4(); scope_l4_tcp(); }
 action scope_l3_v6_l4_tcp() { scope_l3_v6(); scope_l4_tcp(); }
 action scope_l3_v4_l4_udp() { scope_l3_v4(); scope_l4_udp(); }
 action scope_l3_v6_l4_udp() { scope_l3_v6(); scope_l4_udp(); }
 action scope_l3_v4_l4_sctp() { scope_l3_v4(); scope_l4_sctp(); }
 action scope_l3_v6_l4_sctp() { scope_l3_v6(); scope_l4_sctp(); }

 // -----------------------------

 table scope_l34_ {
  key = {
   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;


   hdr_curr.tcp.isValid(): exact;
   hdr_curr.udp.isValid(): exact;
   hdr_curr.sctp.isValid(): exact;
  }
  actions = {
   scope_l3_v4_l4_tcp;
   scope_l3_v6_l4_tcp;
   scope_l3_v4_l4_udp;
   scope_l3_v6_l4_udp;
   scope_l3_v4_l4_sctp;
   scope_l3_v6_l4_sctp;
   scope_l3_v4_l4_none;
   scope_l3_v6_l4_none;
   scope_l3_none_l4_none;
  }
  const entries = {

   (false, false, false, false, false): scope_l3_none_l4_none();

   (true, false, false, false, false): scope_l3_v4_l4_none();
   (false, true, false, false, false): scope_l3_v6_l4_none();
   (true, false, true, false, false): scope_l3_v4_l4_tcp();
   (false, true, true, false, false): scope_l3_v6_l4_tcp();
   (true, false, false, true, false): scope_l3_v4_l4_udp();
   (false, true, false, true, false): scope_l3_v6_l4_udp();
   (true, false, false, false, true ): scope_l3_v4_l4_sctp();
   (false, true, false, false, true ): scope_l3_v6_l4_sctp();
# 537 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr1_to_lkp.p4"
  }
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------
// Derek: Not using this, because it chews up too much vliw resources in tofino....
/*
	action scope_l2_none_l3_none_l4_none()  { scope_l2_none();   scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_none_l4_none()  { scope_l2_0tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_etag_l3_none_l4_none()  { scope_l2_e_tag();  scope_l3_none(); scope_l4_none(); }
	action scope_l2_vntag_l3_none_l4_none() { scope_l2_vn_tag(); scope_l3_none(); scope_l4_none(); }
	action scope_l2_1tag_l3_none_l4_none()  { scope_l2_1tag();   scope_l3_none(); scope_l4_none(); }
	action scope_l2_2tag_l3_none_l4_none()  { scope_l2_2tags();  scope_l3_none(); scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_none()    { scope_l2_0tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_etag_l3_v4_l4_none()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_none(); }
	action scope_l2_vntag_l3_v4_l4_none()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_none(); }
	action scope_l2_1tag_l3_v4_l4_none()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_none(); }
	action scope_l2_2tag_l3_v4_l4_none()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_none(); }

	action scope_l2_0tag_l3_v6_l4_none()    { scope_l2_0tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_etag_l3_v6_l4_none()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_none(); }
	action scope_l2_vntag_l3_v6_l4_none()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_none(); }
	action scope_l2_1tag_l3_v6_l4_none()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_none(); }
	action scope_l2_2tag_l3_v6_l4_none()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_none(); }

	action scope_l2_0tag_l3_v4_l4_tcp()     { scope_l2_0tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v4_l4_tcp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v4_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v4_l4_tcp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v4_l4_tcp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v6_l4_tcp()     { scope_l2_0tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_etag_l3_v6_l4_tcp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_vntag_l3_v6_l4_tcp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_1tag_l3_v6_l4_tcp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_tcp();  }
	action scope_l2_2tag_l3_v6_l4_tcp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_tcp();  }

	action scope_l2_0tag_l3_v4_l4_udp()     { scope_l2_0tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_etag_l3_v4_l4_udp()     { scope_l2_e_tag();  scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v4_l4_udp()    { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v4_l4_udp()     { scope_l2_1tag();   scope_l3_v4();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v4_l4_udp()     { scope_l2_2tags();  scope_l3_v4();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v6_l4_udp()     { scope_l2_0tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_etag_l3_v6_l4_udp()     { scope_l2_e_tag();  scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_vntag_l3_v6_l4_udp()    { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_1tag_l3_v6_l4_udp()     { scope_l2_1tag();   scope_l3_v6();   scope_l4_udp();  }
	action scope_l2_2tag_l3_v6_l4_udp()     { scope_l2_2tags();  scope_l3_v6();   scope_l4_udp();  }

	action scope_l2_0tag_l3_v4_l4_sctp()    { scope_l2_0tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v4_l4_sctp()    { scope_l2_e_tag();  scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v4_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v4_l4_sctp()    { scope_l2_1tag();   scope_l3_v4();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v4_l4_sctp()    { scope_l2_2tags();  scope_l3_v4();   scope_l4_sctp(); }

	action scope_l2_0tag_l3_v6_l4_sctp()    { scope_l2_0tag();   scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_etag_l3_v6_l4_sctp()    { scope_l2_e_tag();  scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_vntag_l3_v6_l4_sctp()   { scope_l2_vn_tag(); scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_1tag_l3_v6_l4_sctp()    { scope_l2_1tag();   scope_l3_v6();   scope_l4_sctp(); }
	action scope_l2_2tag_l3_v6_l4_sctp()    { scope_l2_2tags();  scope_l3_v6();   scope_l4_sctp(); }

	// -----------------------------

	table scope_l234_ {
		key = {
			hdr_curr.ethernet.isValid(): exact;
			hdr_curr.e_tag.isValid(): exact;
			hdr_curr.vn_tag.isValid(): exact;
			hdr_curr.vlan_tag[0].isValid(): exact;
			hdr_curr.vlan_tag[1].isValid(): exact;

			hdr_curr.ipv4.isValid(): exact;
#ifdef IPV6_ENABLE
			hdr_curr.ipv6.isValid(): exact;
#endif // IPV6_ENABLE

			hdr_curr.tcp.isValid():  exact;
			hdr_curr.udp.isValid():  exact;
			hdr_curr.sctp.isValid(): exact;
		}
		actions = {
			scope_l2_0tag_l3_v4_l4_tcp;
			scope_l2_etag_l3_v4_l4_tcp;
			scope_l2_vntag_l3_v4_l4_tcp;
			scope_l2_1tag_l3_v4_l4_tcp;
			scope_l2_2tag_l3_v4_l4_tcp;

			scope_l2_0tag_l3_v6_l4_tcp;
			scope_l2_etag_l3_v6_l4_tcp;
			scope_l2_vntag_l3_v6_l4_tcp;
			scope_l2_1tag_l3_v6_l4_tcp;
			scope_l2_2tag_l3_v6_l4_tcp;

			scope_l2_0tag_l3_v4_l4_udp;
			scope_l2_etag_l3_v4_l4_udp;
			scope_l2_vntag_l3_v4_l4_udp;
			scope_l2_1tag_l3_v4_l4_udp;
			scope_l2_2tag_l3_v4_l4_udp;

			scope_l2_0tag_l3_v6_l4_udp;
			scope_l2_etag_l3_v6_l4_udp;
			scope_l2_vntag_l3_v6_l4_udp;
			scope_l2_1tag_l3_v6_l4_udp;
			scope_l2_2tag_l3_v6_l4_udp;

			scope_l2_0tag_l3_v4_l4_sctp;
			scope_l2_etag_l3_v4_l4_sctp;
			scope_l2_vntag_l3_v4_l4_sctp;
			scope_l2_1tag_l3_v4_l4_sctp;
			scope_l2_2tag_l3_v4_l4_sctp;

			scope_l2_0tag_l3_v6_l4_sctp;
			scope_l2_etag_l3_v6_l4_sctp;
			scope_l2_vntag_l3_v6_l4_sctp;
			scope_l2_1tag_l3_v6_l4_sctp;
			scope_l2_2tag_l3_v6_l4_sctp;

			scope_l2_0tag_l3_v4_l4_none;
			scope_l2_etag_l3_v4_l4_none;
			scope_l2_vntag_l3_v4_l4_none;
			scope_l2_1tag_l3_v4_l4_none;
			scope_l2_2tag_l3_v4_l4_none;

			scope_l2_0tag_l3_v6_l4_none;
			scope_l2_etag_l3_v6_l4_none;
			scope_l2_vntag_l3_v6_l4_none;
			scope_l2_1tag_l3_v6_l4_none;
			scope_l2_2tag_l3_v6_l4_none;

			scope_l2_0tag_l3_none_l4_none;
			scope_l2_etag_l3_none_l4_none;
			scope_l2_vntag_l3_none_l4_none;
			scope_l2_1tag_l3_none_l4_none;
			scope_l2_2tag_l3_none_l4_none;

			scope_l2_none_l3_none_l4_none;
		}
		const entries = {
			(false, false, false, false, false,     false, false,     false, false, false): scope_l2_none_l3_none_l4_none();

			(true,  false, false, false, false,     false, false,     false, false, false): scope_l2_0tag_l3_none_l4_none();
			(true,  true,  false, false, false,     false, false,     false, false, false): scope_l2_etag_l3_none_l4_none();
			(true,  false, true,  false, false,     false, false,     false, false, false): scope_l2_vntag_l3_none_l4_none();
			(true,  false, false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  true,  false, true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, true,  true,  false,     false, false,     false, false, false): scope_l2_1tag_l3_none_l4_none();
			(true,  false, false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  true,  false, true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();
			(true,  false, true,  true,  true,      false, false,     false, false, false): scope_l2_2tag_l3_none_l4_none();

			(true,  false, false, false, false,     true,  false,     false, false, false): scope_l2_0tag_l3_v4_l4_none();
			(true,  true,  false, false, false,     true,  false,     false, false, false): scope_l2_etag_l3_v4_l4_none();
			(true,  false, true,  false, false,     true,  false,     false, false, false): scope_l2_vntag_l3_v4_l4_none();
			(true,  false, false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  true,  false, true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, true,  true,  false,     true,  false,     false, false, false): scope_l2_1tag_l3_v4_l4_none();
			(true,  false, false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  true,  false, true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();
			(true,  false, true,  true,  true,      true,  false,     false, false, false): scope_l2_2tag_l3_v4_l4_none();

			(true,  false, false, false, false,     false, true,      false, false, false): scope_l2_0tag_l3_v6_l4_none();
			(true,  true,  false, false, false,     false, true,      false, false, false): scope_l2_etag_l3_v6_l4_none();
			(true,  false, true,  false, false,     false, true,      false, false, false): scope_l2_vntag_l3_v6_l4_none();
			(true,  false, false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  true,  false, true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, true,  true,  false,     false, true,      false, false, false): scope_l2_1tag_l3_v6_l4_none();
			(true,  false, false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  true,  false, true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();
			(true,  false, true,  true,  true,      false, true,      false, false, false): scope_l2_2tag_l3_v6_l4_none();

			(true,  false, false, false, false,     true,  false,     true,  false, false): scope_l2_0tag_l3_v4_l4_tcp();
			(true,  true,  false, false, false,     true,  false,     true,  false, false): scope_l2_etag_l3_v4_l4_tcp();
			(true,  false, true,  false, false,     true,  false,     true,  false, false): scope_l2_vntag_l3_v4_l4_tcp();
			(true,  false, false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  false,     true,  false,     true,  false, false): scope_l2_1tag_l3_v4_l4_tcp();
			(true,  false, false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  true,  false, true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();
			(true,  false, true,  true,  true,      true,  false,     true,  false, false): scope_l2_2tag_l3_v4_l4_tcp();

			(true,  false, false, false, false,     false, true,      true,  false, false): scope_l2_0tag_l3_v6_l4_tcp();
			(true,  true,  false, false, false,     false, true,      true,  false, false): scope_l2_etag_l3_v6_l4_tcp();
			(true,  false, true,  false, false,     false, true,      true,  false, false): scope_l2_vntag_l3_v6_l4_tcp();
			(true,  false, false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  false,     false, true,      true,  false, false): scope_l2_1tag_l3_v6_l4_tcp();
			(true,  false, false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  true,  false, true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();
			(true,  false, true,  true,  true,      false, true,      true,  false, false): scope_l2_2tag_l3_v6_l4_tcp();

			(true,  false, false, false, false,     true,  false,     false, true,  false): scope_l2_0tag_l3_v4_l4_udp();
			(true,  true,  false, false, false,     true,  false,     false, true,  false): scope_l2_etag_l3_v4_l4_udp();
			(true,  false, true,  false, false,     true,  false,     false, true,  false): scope_l2_vntag_l3_v4_l4_udp();
			(true,  false, false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  true,  false, true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, true,  true,  false,     true,  false,     false, true,  false): scope_l2_1tag_l3_v4_l4_udp();
			(true,  false, false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  true,  false, true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();
			(true,  false, true,  true,  true,      true,  false,     false, true,  false): scope_l2_2tag_l3_v4_l4_udp();

			(true,  false, false, false, false,     false, true,      false, true,  false): scope_l2_0tag_l3_v6_l4_udp();
			(true,  true,  false, false, false,     false, true,      false, true,  false): scope_l2_etag_l3_v6_l4_udp();
			(true,  false, true,  false, false,     false, true,      false, true,  false): scope_l2_vntag_l3_v6_l4_udp();
			(true,  false, false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  true,  false, true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, true,  true,  false,     false, true,      false, true,  false): scope_l2_1tag_l3_v6_l4_udp();
			(true,  false, false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  true,  false, true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();
			(true,  false, true,  true,  true,      false, true,      false, true,  false): scope_l2_2tag_l3_v6_l4_udp();

			(true,  false, false, false, false,     true,  false,     false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
			(true,  true,  false, false, false,     true,  false,     false, false, true ): scope_l2_etag_l3_v4_l4_sctp();
			(true,  false, true,  false, false,     true,  false,     false, false, true ): scope_l2_vntag_l3_v4_l4_sctp();
			(true,  false, false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  false,     true,  false,     false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();
			(true,  false, false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  true,  false, true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();
			(true,  false, true,  true,  true,      true,  false,     false, false, true ): scope_l2_2tag_l3_v4_l4_sctp();

			(true,  false, false, false, false,     false, true,      false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
			(true,  true,  false, false, false,     false, true,      false, false, true ): scope_l2_etag_l3_v6_l4_sctp();
			(true,  false, true,  false, false,     false, true,      false, false, true ): scope_l2_vntag_l3_v6_l4_sctp();
			(true,  false, false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  false,     false, true,      false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();
			(true,  false, false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  true,  false, true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
			(true,  false, true,  true,  true,      false, true,      false, false, true ): scope_l2_2tag_l3_v6_l4_sctp();
		}
	}
*/
 // -----------------------------
 // TUNNEL
 // -----------------------------

 action scope_tunnel_none() {
/*
		lkp.tunnel_type    = SWITCH_TUNNEL_TYPE_NONE;
		lkp.tunnel_id      = 0;
		lkp.next_lyr_valid = false;
*/


  // do nothing...keep previous layer's values
  lkp.next_lyr_valid = false;
# 796 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr1_to_lkp.p4"
 }

 action scope_tunnel_gre() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = true;
 }
# 828 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr1_to_lkp.p4"
 action scope_tunnel_unsupported() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = false; // unsupported has no next layer
 }

 action scope_tunnel_use_parser_values(bool lkp_curr_next_lyr_valid) {
  lkp.tunnel_type = lkp_curr.tunnel_type;
  lkp.tunnel_id = lkp_curr.tunnel_id;
  lkp.next_lyr_valid = lkp_curr_next_lyr_valid;
 }

 // -----------------------------
/*
	table scope_tunnel_ {
		key = {
			hdr_curr.gre.isValid():  exact;
		}
		actions = {
			scope_tunnel_gre;
			scope_tunnel_none;
			scope_tunnel_unsupported;
		}
		const entries = {
			(true ): scope_tunnel_gre();
			(false): scope_tunnel_none();
		}
		const default_action = scope_tunnel_none;
	}
*/
 table scope_tunnel_ {
  key = {
   lkp_curr.tunnel_type: exact;
  }
  actions = {
   scope_tunnel_none;
   scope_tunnel_use_parser_values;
  }
  const entries = {
   (SWITCH_TUNNEL_TYPE_GTPC): scope_tunnel_use_parser_values(false);
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
   (SWITCH_TUNNEL_TYPE_VXLAN): scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP): scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
  }
  const default_action = scope_tunnel_use_parser_values(true);
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
  if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
   scope_l2_etag_vntag.apply();
  } else if(OUTER_ETAG_ENABLE) {
   scope_l2_etag.apply();
  } else if(OUTER_VNTAG_ENABLE) {
   scope_l2_vntag.apply();
  } else {
   scope_l2_.apply();
  }
//		scope_l3_.apply();
//		scope_l4_.apply();
  scope_l34_.apply();
//		scope_l234_.apply();
  // Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_curr.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_curr.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_curr.next_lyr_valid);
		}
*/
  scope_tunnel_.apply();
 }
}
# 29 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr2_to_lkp.p4" 1
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
// Low Level Routines (meant to only be used by functions within this file)
// ============================================================================

control Scoper_Hdr2_To_Lkp(
 in switch_header_inner_t hdr_curr,
 in switch_header_inner_inner_t hdr_next,
 in switch_lookup_fields_t lkp_curr,
 in bool flags_unsupported_tunnel,

 inout switch_lookup_fields_t lkp
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // -----------------------------
 // L2
 // -----------------------------
/*
	action scope_l2_none() {
#ifdef INGRESS_MAU_NO_LKP_2
		// do nothing...keep previous layer's values
#else
//		lkp.l2_valid     = false;
		lkp.mac_src_addr = 0;
		lkp.mac_dst_addr = 0;
//		lkp.mac_type     = 0;
		lkp.pcp          = 0;
		lkp.pad          = 0;
		lkp.vid          = 0;
#endif
		lkp.l2_valid     = false;
		lkp.mac_type     = 0;
	}
*/
 action scope_l2_none_v4() {

  // do nothing...keep previous layer's values
# 73 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr2_to_lkp.p4"
  lkp.l2_valid = false;
  lkp.mac_type = 0x0800;
 }

 action scope_l2_none_v6() {

  // do nothing...keep previous layer's values
# 89 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr2_to_lkp.p4"
  lkp.l2_valid = false;
  lkp.mac_type = 0x86dd;
 }

 action scope_l2_0tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.ethernet.ether_type;
  lkp.pcp = 0;
  lkp.pad = 0;
  lkp.vid = 0;
 }

 action scope_l2_1tag() {
  lkp.l2_valid = true;
  lkp.mac_src_addr = hdr_curr.ethernet.src_addr;
  lkp.mac_dst_addr = hdr_curr.ethernet.dst_addr;
  lkp.mac_type = hdr_curr.vlan_tag[0].ether_type;
  lkp.pcp = hdr_curr.vlan_tag[0].pcp;
  lkp.pad = 0;
  lkp.vid = hdr_curr.vlan_tag[0].vid;
 }

 // -----------------------------

 table scope_l2_ {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;

   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

  }
  actions = {
//			scope_l2_none;
   scope_l2_none_v4;
   scope_l2_none_v6;
   scope_l2_0tag;
   scope_l2_1tag;
  }
  const entries = {
   // l2          l3
   // ----------- ------------
//			(false, false, false, false): scope_l2_none();
   (false, false, true, false): scope_l2_none_v4();
   (false, false, false, true ): scope_l2_none_v6();

   (true, false, false, false): scope_l2_0tag();
   (true, false, true, false): scope_l2_0tag();
   (true, false, false, true ): scope_l2_0tag();

   (true, true, false, false): scope_l2_1tag();
   (true, true, true, false): scope_l2_1tag();
   (true, true, false, true ): scope_l2_1tag();
  }
 }

 // -----------------------------
 // L3
 // -----------------------------

 action scope_l3_none() {
  lkp.ip_type = SWITCH_IP_TYPE_NONE;
  lkp.ip_proto = 0;
  lkp.ip_tos = 0;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = 0;
  lkp.ip_dst_addr = 0;
  lkp.ip_len = 0; // extreme added
 }

 action scope_l3_v4() {
  lkp.ip_type = SWITCH_IP_TYPE_IPV4;
  lkp.ip_proto = hdr_curr.ipv4.protocol;
  lkp.ip_tos = hdr_curr.ipv4.tos;
  lkp.ip_flags = hdr_curr.ipv4.flags;
  lkp.ip_src_addr_v4= hdr_curr.ipv4.src_addr;
  lkp.ip_dst_addr_v4= hdr_curr.ipv4.dst_addr;
  lkp.ip_len = hdr_curr.ipv4.total_len;
 }

 action scope_l3_v6() {

  lkp.ip_type = SWITCH_IP_TYPE_IPV6;
  lkp.ip_proto = hdr_curr.ipv6.next_hdr;
  lkp.ip_tos = hdr_curr.ipv6.tos;
  lkp.ip_flags = 0;
  lkp.ip_src_addr = hdr_curr.ipv6.src_addr;
  lkp.ip_dst_addr = hdr_curr.ipv6.dst_addr;
  lkp.ip_len = hdr_curr.ipv6.payload_len;

 }

 // -----------------------------

 table scope_l3_ {
  key = {
   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;

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
  lkp.l4_src_port = hdr_curr.tcp.src_port;
  lkp.l4_dst_port = hdr_curr.tcp.dst_port;
  lkp.tcp_flags = hdr_curr.tcp.flags;
 }

 action scope_l4_udp() {
  lkp.l4_src_port = hdr_curr.udp.src_port;
  lkp.l4_dst_port = hdr_curr.udp.dst_port;
  lkp.tcp_flags = 0;
 }

 action scope_l4_sctp() {
  lkp.l4_src_port = hdr_curr.sctp.src_port;
  lkp.l4_dst_port = hdr_curr.sctp.dst_port;
  lkp.tcp_flags = 0;
 }

 // -----------------------------

 table scope_l4_ {
  key = {
   hdr_curr.tcp.isValid(): exact;
   hdr_curr.udp.isValid(): exact;
   hdr_curr.sctp.isValid(): exact;
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

 // scenario 1: we're the only  step (no_lkp2     defined)
 //  - overload     defined: keep (do nothing)
 //  - overload not defined: replace
 // secnario 2: we're the first step (no_lkp2 not defined)
 //  - overload     defined: replace (scoper handles)
 //  - overload not defined: replace (scoper handles)



  // do nothing...keep previous layer's values
  lkp.next_lyr_valid = false;
# 288 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr2_to_lkp.p4"
 }

 action scope_tunnel_ipinip() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = true;
 }

 action scope_tunnel_gre() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = true;
 }

 action scope_tunnel_gtpu() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
  lkp.tunnel_id = hdr_curr.gtp_v1_base.teid;
  lkp.next_lyr_valid = true;
 }

 action scope_tunnel_gtpc() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
  lkp.tunnel_id = hdr_curr.gtp_v2_base.teid;
  lkp.next_lyr_valid = false; // gtp-c has no next layer
 }

 action scope_tunnel_unsupported() {
  lkp.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  lkp.tunnel_id = 0;
  lkp.next_lyr_valid = false; // unsupported has no next layer
 }

 action scope_tunnel_use_parser_values(bool lkp_curr_next_lyr_valid) {
  lkp.tunnel_type = lkp_curr.tunnel_type;
  lkp.tunnel_id = lkp_curr.tunnel_id;
  lkp.next_lyr_valid = lkp_curr_next_lyr_valid;
 }

 // -----------------------------
/*
	table scope_tunnel_ {
		key = {
			flags_unsupported_tunnel: exact;
			
			hdr_curr.gre.isValid():  exact;
			hdr_curr.gtp_v1_base.isValid():  exact;
			hdr_curr.gtp_v2_base.isValid():  exact;

			hdr_next.ipv4.isValid(): exact;
			hdr_next.ipv6.isValid(): exact;
		}
		actions = {
			scope_tunnel_ipinip;
			scope_tunnel_gre;
			scope_tunnel_gtpu;
			scope_tunnel_gtpc;
			scope_tunnel_none;
			scope_tunnel_unsupported;
		}
		const entries = {
			//      hdr2                 hdr3
			// ---- -------------------- ------------
			(true,  true,  false, false, false, false): scope_tunnel_unsupported(); // hdr3 is a don't care
			(false, true,  false, false, false, false): scope_tunnel_gre(); // hdr3 is a don't care
			(false, true,  false, false, true,  false): scope_tunnel_gre(); // hdr3 is a don't care
			(false, true,  false, false, false, true ): scope_tunnel_gre(); // hdr3 is a don't care

			(true,  false, true,  false, false, false): scope_tunnel_unsupported(); // hdr3 is a don't care
			(false, false, true,  false, false, false): scope_tunnel_gtpu(); // hdr3 is a don't care
			(false, false, true,  false, true,  false): scope_tunnel_gtpu(); // hdr3 is a don't care
			(false, false, true,  false, false, true ): scope_tunnel_gtpu(); // hdr3 is a don't care

			(true,  false, false, true,  false, false): scope_tunnel_unsupported(); // hdr3 is a don't care
			(false, false, false, true,  false, false): scope_tunnel_gtpc(); // hdr3 is a don't care
			(false, false, false, true,  true,  false): scope_tunnel_gtpc(); // hdr3 is a don't care
			(false, false, false, true,  false, true ): scope_tunnel_gtpc(); // hdr3 is a don't care

			(true,  false, false, false, false, false): scope_tunnel_unsupported(); // no tunnels valid, but next layer is...so must be ip-in-ip
			(false, false, false, false, true,  false): scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
			(false, false, false, false, false, true ): scope_tunnel_ipinip(); // no tunnels valid, but next layer is...so must be ip-in-ip
		}
		const default_action = scope_tunnel_none;
	}
*/
 table scope_tunnel_ {
  key = {
   lkp_curr.tunnel_type: exact;
  }
  actions = {
   scope_tunnel_none;
   scope_tunnel_use_parser_values;
  }
  const entries = {
   (SWITCH_TUNNEL_TYPE_GTPC): scope_tunnel_use_parser_values(false);
   (SWITCH_TUNNEL_TYPE_NONE): scope_tunnel_none();
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED): scope_tunnel_use_parser_values(false);
   (SWITCH_TUNNEL_TYPE_VXLAN): scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP): scope_tunnel_use_parser_values(true); // filler entries to get rid of compiler bug when less than 4 constant entries
  }
  const default_action = scope_tunnel_use_parser_values(true);
 }

 // -----------------------------
 // L2 / L3 / L4
 // -----------------------------

//	action scope_l2_none_l3_none_l4_none() { scope_l2_none();    scope_l3_none(); scope_l4_none(); }
 // l2 only
 action scope_l2_0tag_l3_none_l4_none() { scope_l2_0tag(); scope_l3_none(); scope_l4_none(); }
 action scope_l2_1tag_l3_none_l4_none() { scope_l2_1tag(); scope_l3_none(); scope_l4_none(); }
 // l2, l3, l4
 action scope_l2_0tag_l3_v4_l4_none() { scope_l2_0tag(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_1tag_l3_v4_l4_none() { scope_l2_1tag(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_0tag_l3_v6_l4_none() { scope_l2_0tag(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_1tag_l3_v6_l4_none() { scope_l2_1tag(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_0tag_l3_v4_l4_tcp() { scope_l2_0tag(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_1tag_l3_v4_l4_tcp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_0tag_l3_v6_l4_tcp() { scope_l2_0tag(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_1tag_l3_v6_l4_tcp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_0tag_l3_v4_l4_udp() { scope_l2_0tag(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v4_l4_udp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_0tag_l3_v6_l4_udp() { scope_l2_0tag(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_1tag_l3_v6_l4_udp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_0tag_l3_v4_l4_sctp() { scope_l2_0tag(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_1tag_l3_v4_l4_sctp() { scope_l2_1tag(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_0tag_l3_v6_l4_sctp() { scope_l2_0tag(); scope_l3_v6(); scope_l4_sctp(); }
 action scope_l2_1tag_l3_v6_l4_sctp() { scope_l2_1tag(); scope_l3_v6(); scope_l4_sctp(); }
 // l3, l4 only (no l2)
 action scope_l2_none_l3_v4_l4_none() { scope_l2_none_v4(); scope_l3_v4(); scope_l4_none(); }
 action scope_l2_none_l3_v6_l4_none() { scope_l2_none_v6(); scope_l3_v6(); scope_l4_none(); }
 action scope_l2_none_l3_v4_l4_tcp() { scope_l2_none_v4(); scope_l3_v4(); scope_l4_tcp(); }
 action scope_l2_none_l3_v6_l4_tcp() { scope_l2_none_v6(); scope_l3_v6(); scope_l4_tcp(); }
 action scope_l2_none_l3_v4_l4_udp() { scope_l2_none_v4(); scope_l3_v4(); scope_l4_udp(); }
 action scope_l2_none_l3_v6_l4_udp() { scope_l2_none_v6(); scope_l3_v6(); scope_l4_udp(); }
 action scope_l2_none_l3_v4_l4_sctp() { scope_l2_none_v4(); scope_l3_v4(); scope_l4_sctp(); }
 action scope_l2_none_l3_v6_l4_sctp() { scope_l2_none_v6(); scope_l3_v6(); scope_l4_sctp(); }

 table scope_l234_ {
  key = {
   hdr_curr.ethernet.isValid(): exact;
   hdr_curr.vlan_tag[0].isValid(): exact;

   hdr_curr.ipv4.isValid(): exact;

   hdr_curr.ipv6.isValid(): exact;


   hdr_curr.tcp.isValid(): exact;
   hdr_curr.udp.isValid(): exact;
   hdr_curr.sctp.isValid(): exact;
  }
  actions = {
//			scope_l2_none_l3_none_l4_none;
   // l2 only
   scope_l2_0tag_l3_none_l4_none;
   scope_l2_1tag_l3_none_l4_none;
   // l2, l3, l4
   scope_l2_0tag_l3_v4_l4_tcp;
   scope_l2_1tag_l3_v4_l4_tcp;
   scope_l2_0tag_l3_v6_l4_tcp;
   scope_l2_1tag_l3_v6_l4_tcp;
   scope_l2_0tag_l3_v4_l4_udp;
   scope_l2_1tag_l3_v4_l4_udp;
   scope_l2_0tag_l3_v6_l4_udp;
   scope_l2_1tag_l3_v6_l4_udp;
   scope_l2_0tag_l3_v4_l4_sctp;
   scope_l2_1tag_l3_v4_l4_sctp;
   scope_l2_0tag_l3_v6_l4_sctp;
   scope_l2_1tag_l3_v6_l4_sctp;
   scope_l2_0tag_l3_v4_l4_none;
   scope_l2_1tag_l3_v4_l4_none;
   scope_l2_0tag_l3_v6_l4_none;
   scope_l2_1tag_l3_v6_l4_none;
   // l3, l4 only (no l2)
   scope_l2_none_l3_v4_l4_tcp;
   scope_l2_none_l3_v6_l4_tcp;
   scope_l2_none_l3_v4_l4_udp;
   scope_l2_none_l3_v6_l4_udp;
   scope_l2_none_l3_v4_l4_sctp;
   scope_l2_none_l3_v6_l4_sctp;
   scope_l2_none_l3_v4_l4_none;
   scope_l2_none_l3_v6_l4_none;
  }
  const entries = {

   // l2              l3                l4
   // -----------     -------------     -------------------
   // v4
   (true, false, false, false, false, false, false): scope_l2_0tag_l3_none_l4_none();
   (true, true, false, false, false, false, false): scope_l2_1tag_l3_none_l4_none();

   (true, false, true, false, false, false, false): scope_l2_0tag_l3_v4_l4_none();
   (true, true, true, false, false, false, false): scope_l2_1tag_l3_v4_l4_none();

   (true, false, true, false, true, false, false): scope_l2_0tag_l3_v4_l4_tcp();
   (true, true, true, false, true, false, false): scope_l2_1tag_l3_v4_l4_tcp();

   (true, false, true, false, false, true, false): scope_l2_0tag_l3_v4_l4_udp();
   (true, true, true, false, false, true, false): scope_l2_1tag_l3_v4_l4_udp();

   (true, false, true, false, false, false, true ): scope_l2_0tag_l3_v4_l4_sctp();
   (true, true, true, false, false, false, true ): scope_l2_1tag_l3_v4_l4_sctp();

   // v4, l3 tunnel cases (no l2)
   (false, false, true, false, false, false, false): scope_l2_none_l3_v4_l4_none();

   (false, false, true, false, true, false, false): scope_l2_none_l3_v4_l4_tcp();

   (false, false, true, false, false, true, false): scope_l2_none_l3_v4_l4_udp();

   (false, false, true, false, false, false, true ): scope_l2_none_l3_v4_l4_sctp();

   // v6
   (true, false, false, true, false, false, false): scope_l2_0tag_l3_v6_l4_none();
   (true, true, false, true, false, false, false): scope_l2_1tag_l3_v6_l4_none();

   (true, false, false, true, true, false, false): scope_l2_0tag_l3_v6_l4_tcp();
   (true, true, false, true, true, false, false): scope_l2_1tag_l3_v6_l4_tcp();

   (true, false, false, true, false, true, false): scope_l2_0tag_l3_v6_l4_udp();
   (true, true, false, true, false, true, false): scope_l2_1tag_l3_v6_l4_udp();

   (true, false, false, true, false, false, true ): scope_l2_0tag_l3_v6_l4_sctp();
   (true, true, false, true, false, false, true ): scope_l2_1tag_l3_v6_l4_sctp();

   // v6, l3 tunnel cases (no l2)
   (false, false, false, true, false, false, false): scope_l2_none_l3_v6_l4_none();

   (false, false, false, true, true, false, false): scope_l2_none_l3_v6_l4_tcp();

   (false, false, false, true, false, true, false): scope_l2_none_l3_v6_l4_udp();

   (false, false, false, true, false, false, true ): scope_l2_none_l3_v6_l4_sctp();
# 547 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper_hdr2_to_lkp.p4"
  }
//		const default_action = scope_l2_none_l3_none_l4_none;
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
//		scope_l2_.apply();
//		scope_l3_.apply();
//		scope_l4_.apply();
  scope_l234_.apply();
  // Note: we can't use our tunnel table, because we don't know about the parser's unsupported tunnel type
/*
		lkp.tunnel_type    = lkp_curr.tunnel_type;
		scope_tunnel_.apply();
*/
/*
		if(lkp_curr.tunnel_type == SWITCH_TUNNEL_TYPE_NONE) {
			// for handling overload case
			scope_tunnel_none();
		} else {
			scope_tunnel_use_parser_values(lkp_curr.next_lyr_valid);
		}
*/
  scope_tunnel_.apply();
 }
}
# 30 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 2

// ============================================================================
// High Level Routines (meant to only be used by functions outside this file)
// ============================================================================

// NO  Set Terminates / Scope
// YES Set Lkp Data

control Scoper_Data_Only(
 in bool flags_unsupported_tunnel_0_in,
 in bool flags_unsupported_tunnel_1_in,
 in bool flags_unsupported_tunnel_2_in,

 in switch_lookup_fields_t lkp0_in,
//	in    switch_lookup_fields_t lkp1_in,
 in switch_lookup_fields_t lkp2_in,

 in switch_header_outer_t hdr_1,
 in switch_header_inner_t hdr_2,
 in switch_header_inner_inner_t hdr_3,

 in bit<8> scope,
 inout switch_lookup_fields_t lkp
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 Scoper_Lkp_To_Lkp (TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_lkp_to_lkp;
 Scoper_Hdr0_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr0_to_lkp;
 Scoper_Hdr1_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr1_to_lkp;
 Scoper_Hdr2_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr2_to_lkp;

 apply {
  if(scope == 0) {



//			scoper_lkp_to_lkp.apply(lkp0_in, lkp);

  } else if(scope == 1) {

//			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, lkp1_in, flags_unsupported_tunnel_1_in, lkp);



  } else {

   scoper_hdr2_to_lkp.apply(hdr_2, hdr_3, lkp2_in, flags_unsupported_tunnel_2_in, lkp);



  }
 }
}

// ============================================================================

// YES Set Terminates / Scope
// NO  Set Lkp Data

control Scoper_Scope_And_Term_Only(
 inout switch_lookup_fields_t lkp,

 in bool terminate_flag,
 in bool scope_flag,
 inout bit<8> scope,
 inout bool terminate_0,
 inout bool terminate_1,
 inout bool terminate_2
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 action scope_0() {
//		scoper();
  scope = 1;
 }

 action scope_1() {
//		scoper();
  scope = 2;
 }

 action scope_2() {
  // we can't scope any deeper here
  scope = 3;
 }

 action term_0() {
//		terminate_0           = true;
//		scoper();
  scope = 1;
 }

 action term_1() {
  terminate_1 = true;
//		scoper();
  scope = 2;
 }

 action term_2() {
  terminate_1 = true;
  terminate_2 = true;
  // we can't scope any deeper here
  scope = 3;
 }

 table scope_inc {
  key = {
   lkp.next_lyr_valid : exact;
   terminate_flag : exact;
   scope_flag : exact;
   scope : exact;
  }
  actions = {
   NoAction;
   scope_0;
   scope_1;
   scope_2;
   term_0;
   term_1;
   term_2;
  }
  const entries = {
   (true, false, true, 0) : scope_0();
   (true, false, true, 1) : scope_1();
   (true, false, true, 2) : scope_2();

   (true, true, true, 0) : term_0(); // scope_flag is a don't care when terminating
   (true, true, false, 0) : term_0(); // scope_flag is a don't care when terminating
   (true, true, true, 1) : term_1(); // scope_flag is a don't care when terminating
   (true, true, false, 1) : term_1(); // scope_flag is a don't care when terminating
   (true, true, true, 2) : term_2(); // scope_flag is a don't care when terminating
   (true, true, false, 2) : term_2(); // scope_flag is a don't care when terminating
  }
  const default_action = NoAction;
 }

 apply {
  scope_inc.apply();
 }
}

// ============================================================================

// YES Set Terminates / Scope
// NO  Set Lkp Data

// Note: Exact same code as "Scoper_Scope_And_Term_Only" (above), only without the "scope_flag" input signal.

control Scoper_Scope_And_Term_Only_no_scope_flag(
 inout switch_lookup_fields_t lkp,

 in bool terminate_flag,
 in bool terminate_prev_flag,
 inout bit<8> scope,
 inout bool terminate_0,
 inout bool terminate_1,
 inout bool terminate_2
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 action scope_0() {
//		scoper();
  scope = 1;
 }

 action scope_1() {
//		scoper();
  scope = 2;
 }

 action scope_2() {
  // we can't scope any deeper here
  scope = 3;
 }

 action term_0() {
//		terminate_0           = true;
//		scoper();
  scope = 1;
 }

 action term_1() {
  terminate_1 = true;
//		scoper();
  scope = 2;
 }

 action term_2() {
  terminate_1 = true;
  terminate_2 = true;
  // we can't scope any deeper here
  scope = 3;
 }

 table scope_inc {
  key = {
   lkp.next_lyr_valid : exact;
   terminate_flag : exact;
   terminate_prev_flag : exact;
   scope : exact;
  }
  actions = {
   NoAction;
   scope_0;
   scope_1;
   scope_2;
   term_0;
   term_1;
   term_2;
  }
  const entries = {
   // terminate previous only
   (true, false, true, 1) : term_0();
   (true, false, true, 2) : term_1();

   // terminate current and previous
   (true, true, true, 0) : term_0(); // scope_flag is a don't care when terminating
   (true, true, false, 0) : term_0(); // scope_flag is a don't care when terminating
   (true, true, true, 1) : term_1(); // scope_flag is a don't care when terminating
   (true, true, false, 1) : term_1(); // scope_flag is a don't care when terminating
   (true, true, true, 2) : term_2(); // scope_flag is a don't care when terminating
   (true, true, false, 2) : term_2(); // scope_flag is a don't care when terminating
  }
  const default_action = NoAction;
 }

 apply {
  scope_inc.apply();
 }
}

// ============================================================================

// YES Set Terminates / Scope
// YES Set Lkp Data

control Scoper_Scope_And_Term_And_Data(
 in bool flags_unsupported_tunnel_0_in,
 in bool flags_unsupported_tunnel_1_in,
 in bool flags_unsupported_tunnel_2_in,

 inout switch_lookup_fields_t lkp0_in,
//	inout switch_lookup_fields_t lkp1_in,
 inout switch_lookup_fields_t lkp2_in,

 in switch_header_outer_t hdr_1,
 in switch_header_inner_t hdr_2,
 in switch_header_inner_inner_t hdr_3,

 inout switch_lookup_fields_t lkp,

 in bool terminate_flag,
 in bool scope_flag,
 inout bit<8> scope,
 inout bool terminate_0,
 inout bool terminate_1,
 inout bool terminate_2
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 Scoper_Lkp_To_Lkp (TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_lkp_to_lkp;
 Scoper_Hdr0_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr0_to_lkp;
 Scoper_Hdr1_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr1_to_lkp;
 Scoper_Hdr2_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr2_to_lkp;

 action scope_0() {
//		scoper();
  scope = 1;
 }

 action scope_1() {
//		scoper();
  scope = 2;
 }

 action scope_2() {
  // we can't scope any deeper here
  scope = 3;
 }

 action term_0() {
//		terminate_0           = true;
//		scoper();
  scope = 1;
 }

 action term_1() {
  terminate_1 = true;
//		scoper();
  scope = 2;
 }

 action term_2() {
  terminate_1 = true;
  terminate_2 = true;
  // we can't scope any deeper here
  scope = 3;
 }

 table scope_inc {
  key = {
   lkp.next_lyr_valid : exact;
   terminate_flag : exact;
   scope_flag : exact;
   scope : exact;
  }
  actions = {
   NoAction;
   scope_0;
   scope_1;
   scope_2;
   term_0;
   term_1;
   term_2;
  }
  const entries = {
   (true, false, true, 0) : scope_0();
   (true, false, true, 1) : scope_1();
   (true, false, true, 2) : scope_2();

   (true, true, true, 0) : term_0(); // scope_flag is a don't care when terminating
   (true, true, false, 0) : term_0(); // scope_flag is a don't care when terminating
   (true, true, true, 1) : term_1(); // scope_flag is a don't care when terminating
   (true, true, false, 1) : term_1(); // scope_flag is a don't care when terminating
   (true, true, true, 2) : term_2(); // scope_flag is a don't care when terminating
   (true, true, false, 2) : term_2(); // scope_flag is a don't care when terminating
  }
  const default_action = NoAction;
 }

 apply {
/*
		scope_inc.apply();
		if(scope == 0) {
			scoper_lkp_to_lkp.apply(lkp0_in, lkp);
		} else if(scope == 1) {
//			scoper_lkp_to_lkp.apply(lkp1_in, lkp);
		} else {
			scoper_lkp_to_lkp.apply(lkp2_in, lkp);
		}
*/
  if(scope_inc.apply().hit) {

   scoper_hdr2_to_lkp.apply(hdr_2, hdr_3, lkp2_in, flags_unsupported_tunnel_2_in, lkp);



  }
 }

}
# 27 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/copp.p4" 1



// -----------------------------------------------------------------------------
// Ingress COPP
// -----------------------------------------------------------------------------

control IngressCopp (
 in switch_copp_meter_id_t copp_meter_id,

 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
) {
# 56 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/copp.p4"
 //-------------------------------------------------------------

 apply {







 }

}

// -----------------------------------------------------------------------------
// Egress COPP
// -----------------------------------------------------------------------------

control EgressCopp (
 in switch_copp_meter_id_t copp_meter_id,

 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) (
) {
# 124 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/copp.p4"
 //-------------------------------------------------------------

 apply {







 }
}
# 28 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4" 2

//-----------------------------------------------------------------------------
// Common Ingress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 106 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL match keys and Actions
//-----------------------------------------------------------------------------
# 178 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
//-----------------------------------------------------------------------------
// Common Ingress ACL actions.
//-----------------------------------------------------------------------------
# 238 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
//-----------------------------------------------------------------------------
// Common Egress ACL actions.
//-----------------------------------------------------------------------------
# 294 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
// ============================================================================
// ============================================================================
// Ingress ACL ================================================================
// ============================================================================
// ============================================================================

//-----------------------------------------------------------------------------
// MAC ACL
//-----------------------------------------------------------------------------

control IngressMacAcl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<8> flow_class_,
 inout switch_qid_t qid_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, switch_qid_t qid, bool dtel_report_type_enable, switch_dtel_report_type_t dtel_report_type, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; qid_ = qid; dtel_report_type_enable_ = dtel_report_type_enable; dtel_report_type_ = dtel_report_type; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   prev_table_hit_ : ternary; lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



   // -------------------------------------------
   ig_md.nsh_md.sap : ternary @name("sap");
   ig_md.nsh_md.vpn : ternary @name("vpn");
   // -------------------------------------------

   lkp.vid : ternary;

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<8> flow_class_,
 inout switch_qid_t qid_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, switch_qid_t qid, bool dtel_report_type_enable, switch_dtel_report_type_t dtel_report_type, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; qid_ = qid; dtel_report_type_enable_ = dtel_report_type_enable; dtel_report_type_ = dtel_report_type; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;
   lkp.mac_type : ternary;

   // extreme added



   // -------------------------------------------
   ig_md.nsh_md.sap : ternary @name("sap");
   ig_md.nsh_md.vpn : ternary @name("vpn");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
   ip_len : ternary @name("lkp.ip_len");

   ip_len_rng : ternary @name("lkp.ip_len_rng");





   // -------------------------------------------
   l4_src_port : ternary @name("lkp.l4_src_port");

   l4_src_port_rng : ternary @name("lkp.l4_src_port_rng");





   // -------------------------------------------
   l4_dst_port : ternary @name("lkp.l4_dst_port");

   l4_dst_port_rng : ternary @name("lkp.l4_dst_port_rng");





  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<8> flow_class_,
 inout switch_qid_t qid_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, switch_qid_t qid, bool dtel_report_type_enable, switch_dtel_report_type_t dtel_report_type, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; qid_ = qid; dtel_report_type_enable_ = dtel_report_type_enable; dtel_report_type_ = dtel_report_type; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr_v4 : ternary @name("lkp.ip_src_addr[31:0]"); lkp.ip_dst_addr_v4 : ternary @name("lkp.ip_dst_addr[31:0]"); lkp.ip_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;




   // extreme added



   // -------------------------------------------
   ig_md.nsh_md.sap : ternary @name("sap");
   ig_md.nsh_md.vpn : ternary @name("vpn");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
   ip_len : ternary @name("lkp.ip_len");

   ip_len_rng : ternary @name("lkp.ip_len_rng");





   // -------------------------------------------
   l4_src_port : ternary @name("lkp.l4_src_port");

   l4_src_port_rng : ternary @name("lkp.l4_src_port_rng");





   // -------------------------------------------
   l4_dst_port : ternary @name("lkp.l4_dst_port");

   l4_dst_port_rng : ternary @name("lkp.l4_dst_port_rng");





  }

  actions = {
   no_action;
   hit();
  }
  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<8> flow_class_,
 inout switch_qid_t qid_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, switch_qid_t qid, bool dtel_report_type_enable, switch_dtel_report_type_t dtel_report_type, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; qid_ = qid; dtel_report_type_enable_ = dtel_report_type_enable; dtel_report_type_ = dtel_report_type; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary;




   // extreme added



   // -------------------------------------------
   ig_md.nsh_md.sap : ternary @name("sap");
   ig_md.nsh_md.vpn : ternary @name("vpn");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
   ip_len : ternary @name("lkp.ip_len");

   ip_len_rng : ternary @name("lkp.ip_len_rng");





   // -------------------------------------------
   l4_src_port : ternary @name("lkp.l4_src_port");

   l4_src_port_rng : ternary @name("lkp.l4_src_port_rng");





   // -------------------------------------------
   l4_dst_port : ternary @name("lkp.l4_dst_port");

   l4_dst_port_rng : ternary @name("lkp.l4_dst_port_rng");





  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
  }
 }
}



//-----------------------------------------------------------------------------
// L7 ACL
//-----------------------------------------------------------------------------

control IngressL7Acl(
 in switch_lookup_fields_t lkp,
 in switch_header_transport_t hdr,
 in udf_h hdr_udf,
 inout switch_ingress_metadata_t ig_md,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool scope_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<8> flow_class_,
 inout switch_qid_t qid_,
 inout bool dtel_report_type_enable_,
 inout switch_dtel_report_type_t dtel_report_type_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action no_action() { stats.count(); } action hit ( bool drop, bool terminate, bool scope, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool sfc_enable, bit<12> sfc, bit<8> flow_class, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, switch_qid_t qid, bool dtel_report_type_enable, switch_dtel_report_type_t dtel_report_type, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; scope_ = scope; ig_md.nsh_md.truncate_enable= truncate_enable; ig_md.nsh_md.truncate_len = truncate_len; ig_md.nsh_md.dedup_en = dedup_en; ig_md.nsh_md.sfc_enable = sfc_enable; ig_md.nsh_md.sfc = sfc; flow_class_ = flow_class; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; qid_ = qid; dtel_report_type_enable_ = dtel_report_type_enable; dtel_report_type_ = dtel_report_type; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   hdr_udf.opaque : ternary;

   // extreme added



   // -------------------------------------------
   ig_md.nsh_md.sap : ternary @name("sap");
   ig_md.nsh_md.vpn : ternary @name("vpn");
   // -------------------------------------------
   flow_class_ : ternary @name("flow_class");
  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 inout switch_header_transport_t hdr_0,
 in udf_h hdr_udf,
 in bit<8> int_ctrl_flags
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536,



 switch_uint32_t ipv4_table_size=512,
 switch_uint32_t ipv6_table_size=512,

 switch_uint32_t mac_table_size=512,
 switch_uint32_t l7_table_size=512
) {

 // ---------------------------------------------------




 IngressIpv4Acl(ipv4_table_size) ipv4_acl;

 IngressIpv6Acl(ipv6_table_size) ipv6_acl;


 IngressMacAcl(mac_table_size) mac_acl;
 IngressL7Acl(l7_table_size) l7_acl;

 Scoper_Scope_And_Term_Only(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_scope_and_term_only;


//	Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
 Counter<bit<32>, bit<15>>(32768, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<16>>(65536, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<17>>(131072, CounterType_t.PACKETS_AND_BYTES) indirect_counter;


 bool prev_table_hit = false;
 bool drop = false;
 bool terminate = false;
 bool scope = false;
 switch_cpu_reason_t cpu_reason = 0;
 bool mirror_enable = false;
 switch_mirror_session_t mirror_session_id = 0;
 bool dtel_report_type_enable = false;
 switch_mirror_meter_id_t mirror_meter_id = 0;
 bit<8> flow_class = 0;
 switch_qid_t qid = 0;
 switch_dtel_report_type_t dtel_report_type;
 bit<6> indirect_counter_index = 0;

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		ig_md.nsh_md.scope = scope_new;
	}

	table scope_inc {
		key = {
			ig_md.nsh_md.scope : exact;
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
 // Table: COPP
 // -------------------------------------

 action copy_to_cpu_process_results(in switch_mirror_session_t mirror_session_id_, in switch_cpu_reason_t cpu_reason_) {
/*
		ig_intr_md_for_tm.copy_to_cpu = 1w1;
		ig_md.cpu_reason = cpu_reason_;
*/
  ig_md.cpu_reason = cpu_reason_;
//		ig_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_CPU; // don't need, there is an alias on ingress for this.
  ig_md.mirror.type = 2;
  ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
//		ig_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU_INGRESS;
  ig_md.mirror.session_id = mirror_session_id_;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
/*
		drop                         = false;
		terminate                    = false;
		scope                        = false;
		mirror_enable                = false;
		mirror_session_id            = 0;
		dtel_report_type_enable      = false;
		cpu_reason                   = 0;
//		mirror_meter_id              = 0; // TODO: this may be data and therefore not need to be initialized
		flow_class                   = 0;
		indirect_counter_index       = 0;
*/
  ig_md.nsh_md.truncate_enable = false;
  ig_md.nsh_md.dedup_en = false;
  ig_md.nsh_md.sfc_enable = false;





  // --------------
  // tables
  // --------------

  // Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
  // end up with partial results from one table and partial results from another in the final result.  So it is very import
  // that all "hit" actions write ALL of the outputs.

  // ----- l2 -----
  mac_acl.apply(
   lkp,
   hdr_0,
   ig_md,
   ig_intr_md_for_dprsr,
   ip_len, ip_len_rng,
   l4_src_port, l4_src_port_rng,
   l4_dst_port, l4_dst_port_rng,
   int_ctrl_flags,
   // ----- results -----
   prev_table_hit,
   drop,
   terminate,
   scope,
   mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
   dtel_report_type_enable, dtel_report_type,
   indirect_counter_index
  );

  // ----- l3/4 -----
# 934 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
  if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

   ipv6_acl.apply(
    lkp,
    hdr_0,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_rng,
    l4_src_port, l4_src_port_rng,
    l4_dst_port, l4_dst_port_rng,
    int_ctrl_flags,
    // ----- results -----
    prev_table_hit,
    drop,
    terminate,
    scope,
    mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
    dtel_report_type_enable, dtel_report_type,
    indirect_counter_index
   );

  } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   ipv4_acl.apply(
    lkp,
    hdr_0,
    ig_md,
    ig_intr_md_for_dprsr,
    ip_len, ip_len_rng,
    l4_src_port, l4_src_port_rng,
    l4_dst_port, l4_dst_port_rng,
    int_ctrl_flags,
    // ----- results -----
    prev_table_hit,
    drop,
    terminate,
    scope,
    mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
    dtel_report_type_enable, dtel_report_type,
    indirect_counter_index
   );
  }


  // ----- l7 -----
  if(UDF_ENABLE) {
   if (hdr_udf.isValid()) {
    l7_acl.apply(
     lkp,
     hdr_0,
     hdr_udf,
     ig_md,
     ig_intr_md_for_dprsr,
     ip_len, ip_len_rng,
     l4_src_port, l4_src_port_rng,
     l4_dst_port, l4_dst_port_rng,
     int_ctrl_flags,
     // ----- results -----
     prev_table_hit,
     drop,
     terminate,
     scope,
     mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
     dtel_report_type_enable, dtel_report_type,
     indirect_counter_index
    );
   }
  }
/*
		// ----- l2 -----
		mac_acl.apply(
			lkp,
			hdr_0,
			ig_md,
			ig_intr_md_for_dprsr,
			ip_len, ip_len_rng,
			l4_src_port, l4_src_port_rng,
			l4_dst_port, l4_dst_port_rng,
			int_ctrl_flags,
			// ----- results -----
			prev_table_hit,
			drop,
			terminate,
			scope,
			mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id, flow_class, qid,
			dtel_report_type_enable, dtel_report_type,
			indirect_counter_index
		);
*/
  // --------------
  // results
  // --------------

  // ----- drop -----

  if(drop == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  // note: terminate + !scope is an illegal condition
/*
		if(lkp.next_lyr_valid == true) {

			// ----- terminate -----

			if(terminate == true) {
				ig_md.tunnel_1.terminate           = true;
				if(ig_md.nsh_md.scope == 2) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			// ----- scope -----

#ifdef SF_0_ALLOW_SCOPE_CHANGES
			if(scope == true) {
				if(ig_md.nsh_md.scope == 1) {

					// note: need to change scope here so that the lag
					// hash gets the new values....

  #ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						ig_md.lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
  #else
					ScoperInner.apply(
						hdr_2,

						lkp
					);
  #endif

//					ig_md.nsh_md.hash_1 = ig_md.nsh_md.hash_2;
				}

				ig_md.nsh_md.scope = ig_md.nsh_md.scope + 1;
//				scope_inc.apply();
			}
#endif
		}
*/

/*
		Scoper_ScopeAndTermAndData.apply(
			ig_md.lkp_0,
//			ig_md.lkp_1,
			ig_md.lkp_2,

			lkp,

			terminate,
			scope,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
*/
  scoper_scope_and_term_only.apply(
   lkp,

   terminate,
   scope,
   ig_md.nsh_md.scope,
   ig_md.tunnel_0.terminate,
   ig_md.tunnel_1.terminate,
   ig_md.tunnel_2.terminate
  );


  // ----- truncate -----

  if(ig_md.nsh_md.truncate_enable) {

   ig_intr_md_for_dprsr.mtu_trunc_len = ig_md.nsh_md.truncate_len + 36;





  }

  // ----- qid -----

  ig_intr_md_for_tm.qid = (switch_qid_t) qid;


  // ----- copy to cpu -----

/*
		if(copy_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason);
		} else if(redirect_to_cpu == true) {
			ig_intr_md_for_dprsr.drop_ctl = 0b1;
			copy_to_cpu_process_results(cpu_reason);
		}

		if((copy_to_cpu == true) || (redirect_to_cpu == true)) {
			IngressCopp.apply(copp_meter_id, ig_intr_md_for_tm);
		}
*/
  if(mirror_enable == true) {
   copy_to_cpu_process_results(mirror_session_id, cpu_reason);

//			IngressCopp.apply(copp_meter_id, ig_intr_md_for_tm);
   ig_md.mirror.meter_index = mirror_meter_id; // derek added
  }
# 1154 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
  indirect_counter.count(ig_md.port ++ indirect_counter_index);

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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   prev_table_hit_ : ternary; lkp.mac_src_addr : ternary; lkp.mac_dst_addr : ternary; lkp.mac_type : ternary; lkp.pcp : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;

   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------

   lkp.tunnel_outer_type : ternary @name("tunnel_outer_type");
   lkp.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = hit(false, false, false, false, false, 0, false, 0, false, false, false, false, 0, 0, 0, 0);
  //const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<6> indirect_counter_index_
)(
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.ip_flags : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;
   lkp.mac_type : ternary;

   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
   ip_len : ternary @name("lkp.ip_len");

   ip_len_rng : ternary @name("lkp.ip_len_rng");





   // -------------------------------------------
   l4_src_port : ternary @name("lkp.l4_src_port");

   l4_src_port_rng : ternary @name("lkp.l4_src_port_rng");





   // -------------------------------------------
   l4_dst_port : ternary @name("lkp.l4_dst_port");

   l4_dst_port_rng : ternary @name("lkp.l4_dst_port_rng");





   // -------------------------------------------

   lkp.tunnel_outer_type : ternary @name("tunnel_outer_type");
   lkp.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<6> indirect_counter_index_
) (
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr_v4 : ternary @name("lkp.ip_src_addr[31:0]"); lkp.ip_dst_addr_v4 : ternary @name("lkp.ip_dst_addr[31:0]"); lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.ip_flags : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;




   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
   ip_len : ternary @name("lkp.ip_len");

   ip_len_rng : ternary @name("lkp.ip_len_rng");





   // -------------------------------------------
   l4_src_port : ternary @name("lkp.l4_src_port");

   l4_src_port_rng : ternary @name("lkp.l4_src_port_rng");





   // -------------------------------------------
   l4_dst_port : ternary @name("lkp.l4_dst_port");

   l4_dst_port_rng : ternary @name("lkp.l4_dst_port_rng");





   // -------------------------------------------

   lkp.tunnel_outer_type : ternary @name("tunnel_outer_type");
   lkp.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_2.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
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
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 in bit<8> int_control_flags,
 // ----- results -----
 inout bool prev_table_hit_,
 inout bool drop_,
 inout bool terminate_,
 inout bool mirror_enable_,
 inout switch_mirror_session_t mirror_session_id_,
 inout switch_cpu_reason_t cpu_reason_,
 inout switch_mirror_meter_id_t mirror_meter_id_,
 inout bit<6> indirect_counter_index_
)(
 switch_uint32_t table_size=512
) {
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES,true_egress_accounting=false) stats;

 action no_action() { stats.count(); } action hit( bool drop, bool terminate, bool strip_tag_e, bool strip_tag_vn, bool strip_tag_vlan, bit<8> add_tag_vlan_bd, bool truncate_enable, bit<14> truncate_len, bool dedup_en, bool terminate_outer, bool terminate_inner, bool mirror_enable, switch_mirror_session_t mirror_session_id, switch_cpu_reason_t cpu_reason_code, switch_mirror_meter_id_t mirror_meter_id, bit<6> indirect_counter_index ) { drop_ = drop; terminate_ = terminate; eg_md.nsh_md.strip_tag_e = strip_tag_e; eg_md.nsh_md.strip_tag_vn = strip_tag_vn; eg_md.nsh_md.strip_tag_vlan = strip_tag_vlan; eg_md.nsh_md.add_tag_vlan_bd= add_tag_vlan_bd; eg_md.nsh_md.truncate_enable= truncate_enable; eg_md.nsh_md.truncate_len = truncate_len; eg_md.nsh_md.dedup_en = dedup_en; eg_md.nsh_md.terminate_outer= terminate_outer; eg_md.nsh_md.terminate_inner= terminate_inner; mirror_enable_ = mirror_enable; mirror_session_id_ = mirror_session_id; cpu_reason_ = cpu_reason_code; mirror_meter_id_ = mirror_meter_id; stats.count(); indirect_counter_index_ = indirect_counter_index; }

 table acl {
  key = {
   lkp.ip_src_addr : ternary; lkp.ip_dst_addr : ternary; lkp.ip_proto : ternary; lkp.ip_tos : ternary; lkp.tcp_flags : ternary; lkp.tunnel_type : ternary; lkp.tunnel_id : ternary;




   // extreme added



   // -------------------------------------------
   eg_md.nsh_md.dsap : ternary @name("dsap");
   // -------------------------------------------

   lkp.vid : ternary;

   // -------------------------------------------
   ip_len : ternary @name("lkp.ip_len");

   ip_len_rng : ternary @name("lkp.ip_len_rng");





   // -------------------------------------------
   l4_src_port : ternary @name("lkp.l4_src_port");

   l4_src_port_rng : ternary @name("lkp.l4_src_port_rng");





   // -------------------------------------------
   l4_dst_port : ternary @name("lkp.l4_dst_port");

   l4_dst_port_rng : ternary @name("lkp.l4_dst_port_rng");





   // -------------------------------------------

   lkp.tunnel_outer_type : ternary @name("tunnel_outer_type");
   lkp.tunnel_inner_type : ternary @name("tunnel_inner_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_outer_type");
//			eg_md.tunnel_1.type                    : ternary @name("tunnel_inner_type");

  }

  actions = {
   no_action;
   hit();
  }

  const default_action = no_action;
  counters = stats;
  size = table_size;
 }

 apply {
  if(acl.apply().hit) {
   prev_table_hit_ = true;
  }
 }
}



//-----------------------------------------------------------------------------

control EgressAcl(
 inout switch_lookup_fields_t lkp,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in bit<16> ip_len,
 in bit<8> ip_len_rng,
 in bit<16> l4_src_port,
 in bit<8> l4_src_port_rng,
 in bit<16> l4_dst_port,
 in bit<8> l4_dst_port_rng,
 inout switch_header_transport_t hdr_0,
 in bit<8> int_ctrl_flags
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536,



 switch_uint32_t ipv4_table_size=512,
 switch_uint32_t ipv6_table_size=512,

 switch_uint32_t mac_table_size=512
) {

 // ---------------------------------------------------




 EgressIpv4Acl(ipv4_table_size) egress_ipv4_acl;

 EgressIpv6Acl(ipv6_table_size) egress_ipv6_acl;


 EgressMacAcl(mac_table_size) egress_mac_acl;

 Scoper_Scope_And_Term_Only_no_scope_flag(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_scope_and_term_only;


//	Counter<bit<32>, PortId_t>(512, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
 Counter<bit<32>, bit<15>>(32768, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<16>>(65536, CounterType_t.PACKETS_AND_BYTES) indirect_counter;
//	Counter<bit<32>, bit<17>>(131072, CounterType_t.PACKETS_AND_BYTES) indirect_counter;


 bool prev_table_hit = false;
 bool drop = false;
 bool terminate = false;
 bool mirror_enable = false;
 switch_mirror_session_t mirror_session_id = 0;
 switch_cpu_reason_t cpu_reason = 0;
 switch_mirror_meter_id_t mirror_meter_id = 0;
 bit<6> indirect_counter_index = 0;

 // -------------------------------------
 // Table: Terminate
 // -------------------------------------

/*
	action terminate_table_none() {
//		eg_md.nsh_md.terminate_popcount = 0;
	}

	action terminate_table_outer() {
		eg_md.tunnel_1.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
	}

//	action terminate_table_inner() {
//		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 1;
//	}

	action terminate_table_both() {
		eg_md.tunnel_1.terminate = true;
		eg_md.tunnel_2.terminate = true;
//		eg_md.nsh_md.terminate_popcount = 2;
	}

	table terminate_table {
		key = {
			eg_md.nsh_md.scope           : exact;

			eg_md.nsh_md.terminate_outer : exact; // prev
			terminate                    : exact; // curr
			eg_md.nsh_md.terminate_inner : exact; // next
		}
		actions = {
			terminate_table_none;
			terminate_table_outer;
//			terminate_table_inner;
			terminate_table_both;
		}
		const entries = {
			//  prev,  curr,  next
			// --------------------
			// scope is "outer" -- ignore terminate prev bit (there is nothing before present scope)
			(0, false, false, false) : terminate_table_none();
			(0, true,  false, false) : terminate_table_none();
			(0, false, true,  false) : terminate_table_outer();
			(0, true,  true,  false) : terminate_table_outer();
			(0, false, false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, true,  false, true ) : terminate_table_both();  // can't term just inner, must term both outer and inner
			(0, false, true,  true ) : terminate_table_both();
			(0, true,  true,  true ) : terminate_table_both();

			// scope is "inner" -- ignore terminate next bit (there is nothing after present scope)
			(1, false, false, false) : terminate_table_none();
			(1, true,  false, false) : terminate_table_outer();
			(1, false, true,  false) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  false) : terminate_table_both();
			(1, false, false, true ) : terminate_table_none();
			(1, true,  false, true ) : terminate_table_outer();
			(1, false, true,  true ) : terminate_table_both();   // can't term just inner, must term both outer and inner
			(1, true,  true,  true ) : terminate_table_both();
		}
	}
*/

 // -------------------------------------
 // Table: COPP
 // -------------------------------------

 action copy_to_cpu_process_results(in switch_mirror_session_t mirror_session_id_, in switch_cpu_reason_t cpu_reason_) {
  eg_md.cpu_reason = cpu_reason_;
  eg_intr_md_for_dprsr.mirror_type = 2;
  eg_md.mirror.type = 2;
  eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
//		eg_md.mirror.session_id = SWITCH_MIRROR_SESSION_CPU_EGRESS;
  eg_md.mirror.session_id = mirror_session_id_;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
/*
		drop                         = false;
		terminate                    = false;
		mirror_enable                = false;
		mirror_session_id            = 0;
		cpu_reason                   = 0;
//		mirror_meter_id              = 0; // TODO: this may be data and therefore not need to be initialized
		indirect_counter_index       = 0;
*/
  eg_md.nsh_md.strip_tag_e = false;
  eg_md.nsh_md.strip_tag_vn = false;
  eg_md.nsh_md.strip_tag_vlan = false;
  eg_md.nsh_md.add_tag_vlan_bd = 0;
  eg_md.nsh_md.truncate_enable = false;
  eg_md.nsh_md.dedup_en = false;
  eg_md.nsh_md.terminate_outer = false;
  eg_md.nsh_md.terminate_inner = false;

  // --------------
  // tables
  // --------------

  // Derek: The way this works is that the "hit" action of each table MUST write ALL of the outputs.  This is so that we don't
  // end up with partial results from one table and partial results from another in the final result.  So it is very import
  // that all "hit" actions write ALL of the outputs.

  // ----- l2 -----
  egress_mac_acl.apply(
   lkp,
   eg_md,
   eg_intr_md_for_dprsr,
   ip_len, ip_len_rng,
   l4_src_port, l4_src_port_rng,
   l4_dst_port, l4_dst_port_rng,
   int_ctrl_flags,
   // ----- results -----
   prev_table_hit,
   drop,
   terminate,
   mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
   indirect_counter_index
  );

  // ----- l3/4 -----
# 1743 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
  if (lkp.ip_type == SWITCH_IP_TYPE_IPV6) {

   egress_ipv6_acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    ip_len, ip_len_rng,
    l4_src_port, l4_src_port_rng,
    l4_dst_port, l4_dst_port_rng,
    int_ctrl_flags,
    // ----- results -----
    prev_table_hit,
    drop,
    terminate,
    mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
    indirect_counter_index
   );

  } else if (lkp.ip_type == SWITCH_IP_TYPE_IPV4) {
   egress_ipv4_acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    ip_len, ip_len_rng,
    l4_src_port, l4_src_port_rng,
    l4_dst_port, l4_dst_port_rng,
    int_ctrl_flags,
    // ----- results -----
    prev_table_hit,
    drop,
    terminate,
    mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
    indirect_counter_index
   );
  }

/*
		// ----- l2 -----
		egress_mac_acl.apply(
			lkp,
			eg_md,
			eg_intr_md_for_dprsr,
			ip_len, ip_len_rng,
			l4_src_port, l4_src_port_rng,
			l4_dst_port, l4_dst_port_rng,
			int_ctrl_flags,
			// ----- results -----
			prev_table_hit,
			drop,
			terminate,
			mirror_enable, mirror_session_id, cpu_reason, mirror_meter_id,
			indirect_counter_index
		);
*/
  // --------------
  // results
  // --------------

  // ----- drop -----

  if(drop == true) {
   eg_intr_md_for_dprsr.drop_ctl = 0x1;
  }

  // note: terminate + !scope is an illegal condition

  // ----- terminate -----
/*
		if(terminate || eg_md.nsh_md.terminate_inner) {
			eg_md.tunnel_1.terminate           = true;
			if(eg_md.nsh_md.scope == 2) {
				eg_md.tunnel_2.terminate           = true;
			}
		}
*/
# 1851 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4"
/*
		if((eg_md.nsh_md.terminate_inner == true)) {
			// outer means two back from current scope (scope-2), inner means one back from current scope (scope-1)
			if(eg_md.nsh_md.scope == 2) {
				eg_md.tunnel_1.terminate           = true;
			}
		}
*/
/*
		if(lkp.next_lyr_valid == true) {

			// ----- terminate -----

			if(terminate == true) { 
				eg_md.tunnel_1.terminate           = true;
				if(eg_md.nsh_md.scope == 2) {
					eg_md.tunnel_2.terminate           = true;
				}

			}

			// ----- scope -----

			// since we don't have an explicit 'scope' signal in egress acl, use 'terminate':
			if(terminate == true) { 

				// note: don't need to advance the data here, as nobody else looks at it after this.

				eg_md.nsh_md.scope = eg_md.nsh_md.scope + 1;
//				scope_inc.apply();
			}
		}
*/
  scoper_scope_and_term_only.apply(
   lkp,

   terminate, // curr and prev
   eg_md.nsh_md.terminate_inner, // prev only
   eg_md.nsh_md.scope,
   eg_md.tunnel_0.terminate,
   eg_md.tunnel_1.terminate,
   eg_md.tunnel_2.terminate
  );


  // ----- truncate -----

  if(eg_md.nsh_md.truncate_enable) {

   eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;





  }

  // ----- copy to cpu -----

/*
		if(copy_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason);
		} else if(redirect_to_cpu == true) {
			copy_to_cpu_process_results(cpu_reason);
			eg_intr_md_for_dprsr.drop_ctl = 0x1;
		}

		if((copy_to_cpu == true) || (redirect_to_cpu == true)) {
			EgressCopp.apply(copp_meter_id, eg_intr_md_for_dprsr);
		}
*/
  if(mirror_enable == true) {
   copy_to_cpu_process_results(mirror_session_id, cpu_reason);

//			EgressCopp.apply(copp_meter_id, eg_intr_md_for_dprsr);
   eg_md.mirror.meter_index = mirror_meter_id; // derek added
  }




  indirect_counter.count(eg_md.port ++ indirect_counter_index);

 }
}
# 29 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l3.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l2.p4" 1
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
//control DMAC_t(in mac_addr_t dst_addr, inout switch_ingress_metadata_t ig_md);

control DMAC(
 in mac_addr_t dst_addr,
 in switch_lookup_fields_t lkp,
 inout switch_ingress_metadata_t ig_md,
 inout switch_header_t hdr
) (
 switch_uint32_t table_size
) {

//	bool copp_enable_;
//	switch_copp_meter_id_t copp_meter_id_;

 //-------------------------------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 // sets: port_lag_index
 action dmac_miss(//bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  stats.count();

//		ig_md.egress_port_lag_index = SWITCH_FLOOD;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;

  ig_md.nsh_md.l2_fwd_en = true;
 }

 // sets: port_lag_index
 action dmac_hit(switch_port_lag_index_t port_lag_index //, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  stats.count();

  ig_md.egress_port_lag_index = port_lag_index;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;

  ig_md.nsh_md.l2_fwd_en = true;
 }

 // sets: mgid
 action dmac_multicast(switch_mgid_t index //, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  stats.count();

  ig_md.multicast.id = index;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;

  ig_md.nsh_md.l2_fwd_en = true;
 }

 // sets: nexthop
 action dmac_redirect(switch_nexthop_t nexthop_index //, bool copp_enable, switch_copp_meter_id_t copp_meter_id
 ) {
  stats.count();

  ig_md.nexthop = nexthop_index;

//		copp_enable_ = copp_enable;
//		copp_meter_id_ = copp_meter_id;

  ig_md.nsh_md.l2_fwd_en = true;
 }

 action dmac_npb(
 ) {
  stats.count();

  ig_md.nsh_md.l2_fwd_en = false;
 }

 table dmac {
  key = {
//			ig_md.bd : exact;
//			dst_addr : exact;

   lkp.mac_dst_addr : ternary @name("mac_dst_addr");
   lkp.vid : ternary @name("vid");
   lkp.mac_type : ternary @name("mac_type");
   ig_md.port_lag_index : ternary @name("port_lag_index");
  }

  actions = {
   dmac_miss;
   dmac_hit;
   dmac_multicast;
   dmac_redirect;

   dmac_npb;
  }

//		const default_action = dmac_miss(false, 0);
//		const default_action = dmac_miss;
  const default_action = dmac_npb;
  size = table_size;
  counters = stats;
 }

 //-------------------------------------------------------------

 apply {
  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_L2 != 0)) {
   dmac.apply();
  }


//		ig_md.copp_enable = copp_enable_;
//      ig_md.copp_meter_id = copp_meter_id_;

 }
}

//-----------------------------------------------------------------------------
// Ingress BD (VLAN, RIF) Stats
//
//-----------------------------------------------------------------------------

control IngressBd(
 in switch_bd_t bd,
 in switch_pkt_type_t pkt_type
) (
 switch_uint32_t table_size
) {

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

//-----------------------------------------------------------------------------
// Egress BD Stats
//      -- Outer BD for encap cases
//
//-----------------------------------------------------------------------------

control EgressBDStats(
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md
) (
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action count() {
  stats.count();
 }

 table bd_stats {
  key = {
   eg_md.bd : exact;
//			eg_md.pkt_type : exact;
  }

  actions = {
   count;
   @defaultonly NoAction;
  }

  size = 3 * BD_TABLE_SIZE;
  counters = stats;
 }

 apply {
  if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {
   bd_stats.apply();
  }
 }
}

//-----------------------------------------------------------------------------
// Egress BD Properties
//      -- Outer BD for encap cases
//
//-----------------------------------------------------------------------------

control EgressBD(
 inout switch_header_transport_t hdr,
 inout switch_egress_metadata_t eg_md,
 out switch_smac_index_t smac_idx
) (
 switch_uint32_t table_size
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 action set_bd_properties(
  switch_smac_index_t smac_index
 ) {
  stats.count();

  smac_idx = smac_index;
 }

 action no_action() {
  stats.count();
 }

 table bd_mapping {
  key = { eg_md.bd : exact @name("bd"); }
  actions = {
   no_action;
   set_bd_properties;
  }

  const default_action = no_action;
  size = table_size;
  counters = stats;
 }

 apply {
  smac_idx = 0; // extreme added

//		if (!eg_md.flags.bypass_egress && eg_md.flags.routed) {
   bd_mapping.apply();
//		}
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

control VlanDecap(
 inout switch_header_transport_t hdr,
 in switch_egress_metadata_t eg_md
) {

 // ---------------------
 // Apply
 // ---------------------

 apply {
  if (!eg_md.flags.bypass_egress) {
   // Remove the vlan tag by default.
   if (hdr.vlan_tag[0].isValid()) {
    hdr.ethernet.ether_type = hdr.vlan_tag[0].ether_type;
    hdr.vlan_tag[0].setInvalid();
   }
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

control VlanXlate(
 inout switch_header_transport_t hdr,
 in switch_egress_metadata_t eg_md
) (
 switch_uint32_t bd_table_size,
 switch_uint32_t port_bd_table_size
) {

 action set_vlan_untagged() {
  //NoAction.
 }
# 351 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l2.p4"
 action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {



  hdr.vlan_tag[0].setValid();
  hdr.vlan_tag[0].ether_type = hdr.ethernet.ether_type;
  hdr.vlan_tag[0].pcp = pcp; // derek: added this here...barefoot set it in qos.p4, which we don't have.
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
# 418 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l2.p4"
 apply {
  if (!eg_md.flags.bypass_egress) {
   if (!port_bd_to_vlan_mapping.apply().hit) {
    bd_to_vlan_mapping.apply();
   }
  }



 }
}
# 30 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l3.p4" 2

//-----------------------------------------------------------------------------
// Router MAC lookup
// key: destination MAC address.
// - Route the packet if the destination MAC address is owned by the switch.
//-----------------------------------------------------------------------------
# 62 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/l3.p4"
//-----------------------------------------------------------------------------
// @param lkp : Lookup fields used to perform L2/L3 lookups.
// @param ig_md : Ingress metadata fields.
// @param dmac : DMAC instance (See l2.p4)
//-----------------------------------------------------------------------------
control IngressUnicast(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md
) (
) {

//  RMAC

 //-----------------------------------------------------------------------------
 // Apply
 //-----------------------------------------------------------------------------

    apply {
//      if (rmac.apply().hit) {
//      } else {
//      }
    }
}
# 49 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/nexthop.p4" 1
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
// @param ig_md : Ingress metadata fields
// @param nexthop_table_size : Number of nexthops.
// @param ecmp_group_table_size : Number of ECMP groups.
// @param ecmp_selction_table_size : Maximum number of ECMP members.
//
// ----------------------------------------------------------------------------
control Nexthop(inout switch_ingress_metadata_t ig_md)(
                switch_uint32_t nexthop_table_size,
                switch_uint32_t ecmp_group_table_size,
                switch_uint32_t ecmp_selection_table_size) {
/*
    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
#ifdef RESILIENT_ECMP_HASH_ENABLE
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.RESILIENT,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#else
    ActionSelector(ecmp_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   ECMP_MAX_MEMBERS_PER_GROUP,
                   ecmp_group_table_size) ecmp_selector;
#endif
*/
    DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action() {
        stats.count();

    }

    // IP Nexthop
    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_bd_t bd
    ) {
        stats.count();
        ig_md.egress_port_lag_index = port_lag_index;
    }

    // Post Route Flood
    action set_nexthop_properties_post_routed_flood(switch_bd_t bd, switch_mgid_t mgid) {
        stats.count();
        ig_md.egress_port_lag_index = 0;
        ig_md.multicast.id = mgid;
    }
/*
    // Glean
    action set_nexthop_properties_glean() {
        stats.count();
        ig_md.flags.glean = true;
    }
*/
    // Drop
    action set_nexthop_properties_drop(
    ) {
        stats.count();
//      ig_md.drop_reason = SWITCH_DROP_REASON_NEXTHOP;
    }



    // Tunnel Encap
    action set_nexthop_properties_tunnel(
        switch_bd_t bd,
        switch_tunnel_ip_index_t tunnel_index
    ) {
        // TODO(msharif) : Disable cut-through for non-ip packets.
        stats.count();
        ig_md.tunnel_0.dip_index = tunnel_index;
        ig_md.egress_port_lag_index = 0;
  ig_md.tunnel_nexthop = ig_md.nexthop; // derek: added 6-28-21 to match latest switch.p4 code.
    }
# 128 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/nexthop.p4"
    table nexthop {
        key = {
            ig_md.nexthop : exact;
        }

        actions = {
            no_action;
            set_nexthop_properties;
            set_nexthop_properties_drop;
//          set_nexthop_properties_glean;
            set_nexthop_properties_post_routed_flood;

            set_nexthop_properties_tunnel;

        }

        const default_action = no_action;
        size = nexthop_table_size;
        counters = stats;
    }

    apply {
        switch(nexthop.apply().action_run) {
            default : {}
        }
    }
}


//--------------------------------------------------------------------------
// Route lookup and ECMP resolution for Tunnel Destination IP
//-------------------------------------------------------------------------
control OuterFib(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t fib_table_size,
                     switch_uint32_t ecmp_table_size,
                     switch_uint32_t ecmp_selection_table_size) {

//  Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
//  ActionProfile(ecmp_selection_table_size) ecmp_action_profile;
//  ActionSelector(ecmp_action_profile,
//                 selector_hash,
//                 SelectorMode_t.FAIR,
//                 ECMP_MAX_MEMBERS_PER_GROUP,
//                 ecmp_group_table_size) ecmp_selector;

    DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action no_action(
    ) {
        stats.count();
    }

    action set_nexthop_properties(switch_port_lag_index_t port_lag_index,
                                  switch_tunnel_nexthop_t nexthop_index
    ) {
        stats.count();
        ig_md.tunnel_nexthop = nexthop_index;
        ig_md.egress_port_lag_index = port_lag_index;
    }

    table fib {
        key = {
            ig_md.tunnel_0.dip_index : exact @name("ig_md.tunnel_0.index");
//          ig_md.hash[31:16] : selector;
        }

        actions = {
            no_action;
            set_nexthop_properties;
        }

        const default_action = no_action;
//      implementation = ecmp_selector;
        size = fib_table_size;
        counters = stats;
    }

    apply {
        fib.apply();
    }
}
# 50 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/port.p4" 1
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
// Ingress/Egress Port Mirroring
//-----------------------------------------------------------------------------

control PortMirror(
  in switch_port_t port,
  in switch_pkt_src_t src,
  inout switch_mirror_metadata_t mirror_md, // derek added
  in switch_cpu_reason_t cpu_reason_in, // derek added
  inout switch_cpu_reason_t cpu_reason // derek added
) (
  switch_uint32_t table_size=288
) {

 action set_mirror_id(
  switch_mirror_session_t session_id,
  switch_mirror_meter_id_t meter_index // derek added
 ) {
  mirror_md.type = 2;
  mirror_md.src = src;
  mirror_md.session_id = session_id;



  cpu_reason = cpu_reason_in; // derek added
 }

 table port_mirror {
  key = {
   port : exact;
  }
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

//-----------------------------------------------------------------------------
// Ingress Port Mapping
//-----------------------------------------------------------------------------

control IngressPortMapping(
  inout switch_header_t hdr,
  inout switch_ingress_metadata_t ig_md,
  inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
  inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) (
  switch_uint32_t port_vlan_table_size,
  switch_uint32_t bd_table_size,
  switch_uint32_t port_table_size=288,
  switch_uint32_t vlan_table_size=4096
) {

 PortMirror(port_table_size) port_mirror;

//	ActionProfile(bd_table_size) bd_action_profile;

 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 // Helper action:

 action terminate_cpu_packet() {
  // ig_md.bypass = (bit<8>) hdr.cpu.reason_code;                                 // Done in parser
//		ig_md.port = (switch_port_t) hdr.cpu.ingress_port;                              // Done in parser
//		ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index; // Done in parser
  ig_intr_md_for_tm.ucast_egress_port = (bit<9>) hdr.cpu.port_lag_index; // Not done in parser, since ig_intr_md_for_tm doesn't exist there.
  ig_intr_md_for_tm.qid = (switch_qid_t) hdr.cpu.egress_queue; // Not done in parser, since ig_intr_md_for_tm doesn't exist there.

//		ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;                           // Done in parser
//		DEREK: This next line should be deleted, but doing so causes us not to fit!?!?  ¯\_('')_/¯




//		hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;                             // Wants to be done in parser (see bf-case 10933)
 }

 // --------------------------

 action set_cpu_port_properties(
  switch_port_lag_index_t port_lag_index,
//		switch_port_lag_label_t port_lag_label,
  switch_yid_t exclusion_id
//		switch_qos_trust_mode_t trust_mode,
//		switch_qos_group_t qos_group,
//		switch_pkt_color_t color,
//		switch_tc_t tc
//		bool l2_fwd_en
 ) {

  stats.count();

  ig_md.port_lag_index = port_lag_index;
//		ig_md.port_lag_label = port_lag_label;
//		ig_md.qos.trust_mode = trust_mode;
//		ig_md.qos.group = qos_group;
//		ig_md.qos.color = color;
//		ig_md.qos.tc = tc;
  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;
//		ig_md.nsh_md.l2_fwd_en = l2_fwd_en;

  terminate_cpu_packet();

 }

 // --------------------------

 action set_port_properties(
  // note: for regular ports, port_lag_index and l2_fwd_en come from the port_metadata table.
  switch_yid_t exclusion_id

  ,
  switch_port_lag_index_t port_lag_index
//		bool l2_fwd_en


 ) {
  stats.count();

  ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

  ig_md.port_lag_index = port_lag_index;
//		ig_md.nsh_md.l2_fwd_en = l2_fwd_en;





 }

 // --------------------------

 table port_mapping {
  key = {
   ig_md.port : exact;

   hdr.cpu.isValid() : exact;
//			hdr.cpu.ingress_port : exact; // DEREK: IS THIS NEEDED / WHAT IS IT FOR?

  }

  actions = {
   set_port_properties;
   set_cpu_port_properties;
  }


  size = port_table_size * 2;



  default_action = set_port_properties(0, 0);
  counters = stats;
 }

 // ----------------------------------------------
 // Table: BD Mapping
 // ----------------------------------------------
/*
	action port_vlan_miss() {
		//ig_md.flags.port_vlan_miss = true;
	}

	action set_bd_properties(
		switch_bd_t bd ,
		switch_rid_t rid
	) {
		ig_md.bd = bd;
#ifdef MULTICAST_INGRESS_RID_ENABLE
		ig_intr_md_for_tm.rid = rid;
#endif
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
//			hdr.transport.vlan_tag[0].isValid() : ternary;
//			hdr.transport.vlan_tag[0].vid : ternary;
			hdr.outer.vlan_tag[0].isValid() : ternary;
			hdr.outer.vlan_tag[0].vid : ternary;
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
//			hdr.transport.vlan_tag[0].vid : exact;
			hdr.outer.vlan_tag[0].vid : exact;
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
		key = { ig_md.bd : exact; }

		actions = {
			NoAction;
			port_vlan_miss;
			set_bd_properties;
		}

		const default_action = port_vlan_miss;
		implementation = bd_action_profile;
		size = bd_table_size;
	}
*/
 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
/*
		switch (port_mapping.apply().action_run) {
#ifdef CPU_BD_MAP_ENABLE
			set_cpu_port_properties : {
				cpu_to_bd_mapping.apply();
			}
#endif

			set_port_properties : {



					if (!port_vlan_to_bd_mapping.apply().hit) {
						if (hdr.transport.vlan_tag[0].isValid())
							vlan_to_bd_mapping.apply();
					}



			}
		}
*/
  if(port_mapping.apply().hit) {
/*
			if(hdr.cpu.isValid()) {
#ifdef CPU_BD_MAP_ENABLE
				cpu_to_bd_mapping.apply();
#endif
			} else {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.transport.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
			}
*/
  }


  port_mirror.apply(ig_md.port, SWITCH_PKT_SRC_CLONED_INGRESS, ig_md.mirror, SWITCH_CPU_REASON_IG_PORT_MIRROR, ig_md.cpu_reason);

 }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
//
//
// ----------------------------------------------------------------------------

control LAG(
 in switch_lookup_fields_t lkp,
 inout switch_ingress_metadata_t ig_md,
 in switch_hash_t hash,
 out switch_port_t egress_port
) {


 Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;



 ActionProfile(LAG_SELECTOR_TABLE_SIZE) lag_action_profile;
 ActionSelector(lag_action_profile,
                selector_hash,
//	               SelectorMode_t.FAIR,
                SelectorMode_t.RESILIENT,
                LAG_MAX_MEMBERS_PER_GROUP,
                LAG_GROUP_TABLE_SIZE) lag_selector;

 // ----------------------------------------------
 // Table: LAG
 // ----------------------------------------------

 bit<4> indirect_counter_index_;

 DirectCounter<bit<32> >(type=CounterType_t.PACKETS_AND_BYTES) stats_in; // direct counter
# 366 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/port.p4"
 action set_lag_port(switch_port_t port) {

  stats_in.count();

  egress_port = port;



 }

 action lag_miss() { stats_in.count(); }

 table lag {
  key = {



   ig_md.egress_port_lag_index : exact @name("port_lag_index");

   hash[31:16] : selector;
  }

  actions = {
   lag_miss;
   set_lag_port;



  }

  const default_action = lag_miss;
  size = LAG_TABLE_SIZE;
  counters = stats_in;
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
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in switch_port_t port
) (
 switch_uint32_t table_size=288
) {

 PortMirror(table_size) port_mirror;


 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 action cpu_rewrite() {


  // ----- add fabric header -----







  // ----- add cpu header -----
  hdr.cpu.setValid();
  hdr.cpu.egress_queue = 0;
  hdr.cpu.tx_bypass = 0;
  hdr.cpu.capture_ts = 0;
  hdr.cpu.reserved = 0;
  hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;

  hdr.cpu.port_lag_index = (bit<16>) eg_md.port;



  hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
  hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
  hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;



  hdr.outer.ethernet.ether_type = 0x9001;


 }

 action port_normal(
  switch_port_lag_index_t port_lag_index
 ) {
  stats.count();

  eg_md.port_lag_index = port_lag_index;
 }

 action port_cpu(
  switch_port_lag_index_t port_lag_index,
  switch_meter_index_t meter_index
 ) {
  stats.count();


  cpu_rewrite();




 }

 table port_mapping {
  key = { port : exact; }

  actions = {
   port_normal;
   port_cpu;
  }

  size = table_size;
  counters = stats;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {
  port_mapping.apply();


  port_mirror.apply(port, SWITCH_PKT_SRC_CLONED_EGRESS, eg_md.mirror, SWITCH_CPU_REASON_EG_PORT_MIRROR, eg_md.cpu_reason);

 }
}

//-----------------------------------------------------------------------------
// CPU-RX Header Insertion
//-----------------------------------------------------------------------------

control EgressCpuRewrite(
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 in switch_port_t port
) (
 switch_uint32_t table_size=288
) {
 // ----------------------------------------------
 // Table: Port Mapping
 // ----------------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 action cpu_rewrite() {
  stats.count();

/*
		hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
		hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;
#ifdef CPU_FABRIC_HEADER_ENABLE
		hdr.outer.ethernet.ether_type = ETHERTYPE_BFN;
#else
		hdr.outer.ethernet.ether_type = ETHERTYPE_BFN2;
#endif
*/
  // ----- add fabric header -----







  // ----- add cpu header -----
  hdr.cpu.setValid();
  hdr.cpu.egress_queue = 0;
  hdr.cpu.tx_bypass = 0;
  hdr.cpu.capture_ts = 0;
  hdr.cpu.reserved = 0;
  hdr.cpu.ingress_port = (bit<16>) eg_md.ingress_port;

  hdr.cpu.port_lag_index = (bit<16>) eg_md.port;



  hdr.cpu.ingress_bd = (bit<16>) eg_md.bd;
  hdr.cpu.reason_code = (bit<16>) eg_md.cpu_reason;
  hdr.cpu.ether_type = hdr.outer.ethernet.ether_type;



  hdr.outer.ethernet.ether_type = 0x9001;


 }
/*
	action normal_rewrite() {
		stats.count();
	}
*/
 table cpu_port_rewrite {
  key = { port : exact; }

  actions = {
   cpu_rewrite;
//			normal_rewrite;
  }

  size = table_size;
  counters = stats;
 }

 // ----------------------------------------------
 // Apply
 // ----------------------------------------------

 apply {



 }
}
# 51 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
//#include "../../src/validation.p4"
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 1
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
# 27 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/payload_len.p4" 1



//=================================================================================
// Egress
//=================================================================================

control PayloadLenEgress(
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
 inout switch_header_inner_inner_t hdr_3,

 inout bit<16> gre_proto,

 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md
) (
) {

 bit<16> l2_len;

 //=============================================================================
 // Table:
 //=============================================================================

 action get_l2_len_hit(bit<16> l2_len_) {
  l2_len = l2_len_;
 }

 // Find the length of the l2.  Note that since this routine is only used for
 // mirrored packets, and we don't allow decaps on mirrored packets, we only ever
 // need to look at the first ethernet, since it will always be valid....

 table get_l2_len {
  key = {
   hdr_1.e_tag.isValid() : exact;
   hdr_1.vn_tag.isValid() : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction;
   get_l2_len_hit;
  }

  const entries = {
   (false, false, false, false) : get_l2_len_hit(14); // no tag

   (true, false, false, false) : get_l2_len_hit(22); // e tag
   (false, true, false, false) : get_l2_len_hit(20); // vn tag

   (false, false, true, false) : get_l2_len_hit(18); // 1 vlan
   (false, false, true, true ) : get_l2_len_hit(22); // 2 vlan

   (true, false, true, false) : get_l2_len_hit(26); // e tag,  1 vlan
   (false, true, true, true ) : get_l2_len_hit(24); // vn tag, 2 vlan
  }
  const default_action = NoAction;
 }

 //=============================================================================
 // Table:
 //=============================================================================

 action rewrite_inner_ipv4_hdr1() {
  eg_md.payload_len = hdr_1.ipv4.total_len;
  gre_proto = 0x0800;
 }

 action rewrite_inner_ipv4_hdr2() {
  eg_md.payload_len = hdr_2.ipv4.total_len;
  gre_proto = 0x0800;
 }

 action rewrite_inner_ipv4_hdr3() {
  eg_md.payload_len = hdr_3.ipv4.total_len;
  gre_proto = 0x0800;
 }

 // --------------------------------

 action rewrite_inner_ipv6_hdr1() {
//      eg_md.payload_len = hdr_1.ipv6.payload_len + 16w40;
  eg_md.payload_len = hdr_1.ipv6.payload_len;
  gre_proto = 0x86DD;
 }

 action rewrite_inner_ipv6_hdr2() {
//      eg_md.payload_len = hdr_2.ipv6.payload_len + 16w40;
  eg_md.payload_len = hdr_2.ipv6.payload_len;
  gre_proto = 0x86DD;
 }

 action rewrite_inner_ipv6_hdr3() {
//      eg_md.payload_len = hdr_3.ipv6.payload_len + 16w40;
  eg_md.payload_len = hdr_3.ipv6.payload_len;
  gre_proto = 0x86DD;
 }

 // --------------------------------

 // Look for the first valid l3.

 table find_first_valid_l3 {
  key = {
   hdr_1.ipv4.isValid() : exact;
   hdr_1.ipv6.isValid() : exact;
   hdr_2.ipv4.isValid() : exact;
   hdr_2.ipv6.isValid() : exact;
   hdr_3.ipv4.isValid() : exact;
   hdr_3.ipv6.isValid() : exact;
  }

  actions = {
   rewrite_inner_ipv4_hdr1;
   rewrite_inner_ipv4_hdr2;
   rewrite_inner_ipv4_hdr3;

   rewrite_inner_ipv6_hdr1;
   rewrite_inner_ipv6_hdr2;
   rewrite_inner_ipv6_hdr3;

  }

  const entries = {
   // hdr_1       hdr_2         hdr_3
   // ----------- ------------- ------------
/*
			(true,  false, _,     _,     _,     _    ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(false, false, true,  false, _,     _    ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)
#ifdef IPV6_ENABLE
			(false, true,  _,     _,     _,     _    ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, false, false, true,  _,     _    ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)
#endif
*/
   (true, false, false, false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, true, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, true, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, false, true, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, false, true, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, true, true, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, true, true, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, true, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, true, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, false, true, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, false, true, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, false, true, true, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
   (true, false, true, true, true, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)

   (false, false, true, false, false, false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
   (false, false, true, false, true, false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
   (false, false, true, false, false, true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
   (false, false, true, false, true, true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)

   (false, false, false, false, true, false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)

   (false, true, false, false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, true, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, true, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, false, true, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, false, true, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, true, true, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, true, true, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, true, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, true, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, false, true, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, false, true, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, false, true, true, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
   (false, true, true, true, true, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)

   (false, false, false, true, false, false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
   (false, false, false, true, true, false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
   (false, false, false, true, false, true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
   (false, false, false, true, true, true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)

   (false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)

  }
 }

 //=============================================================================
 // Table:
 //=============================================================================

 action remove_metadata_len_hit(bit<16> length_offset) {
  eg_md.payload_len = eg_md.payload_len + length_offset;
  eg_md.mirror.type = 0;
 }

 table remove_metadata_len {
  key = { eg_md.mirror.type : exact; }
  actions = { remove_metadata_len_hit; }
  const entries = {
   //-14
   2 : remove_metadata_len_hit(0xFFF2); // TODO: derek: need to fix







   //-11
//          SWITCH_MIRROR_TYPE_PORT              : remove_metadata_len_hit(0xFFF5); // derek: not used
   3 : remove_metadata_len_hit(2);
   4 : remove_metadata_len_hit(0x0);

   //-7
   5 : remove_metadata_len_hit(0xFFF9);





   /* len(telemetry report v0.5 header)
			 * + len(telemetry drop report header) - 4 bytes of CRC */
   255 : remove_metadata_len_hit(20);

  }
 }

 //=============================================================================
 // Apply
 //=============================================================================

 apply {
  get_l2_len.apply();

  if(eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED) {

   // *** For bridged packets, we use the payload length in the l3 header directly. ***

   find_first_valid_l3.apply();

   // For ipv6, add hdr size to payload len.
   if(gre_proto == 0x86DD) {
    eg_md.payload_len = eg_md.payload_len + 16w40;
   }
  } else {
   // *** For mirrored packets, we use the packet length to derive the payload length.         ***
   // *** (this is what switch.p4 does, I believe so as not to have to parse everything again) ***

   remove_metadata_len.apply();

   // Subtract off ethernet header.
   eg_md.payload_len = eg_md.payload_len - l2_len;
  }
 }
}

//	sizeInBits(meta.mpls_resubmit)
//	sizeInBytes(meta.mpls_resubmit)
# 28 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4" 2



//#if defined(IPV6_TUNNEL_ENABLE) && !defined(IPV6_ENABLE)
//#error "IPv6 tunneling cannot be enabled without enabling IPv6"
//#endif

//-----------------------------------------------------------------------------
// Ingress Tunnel RMAC: Transport
//-----------------------------------------------------------------------------
/*
control IngressTunnelRMAC(
	inout switch_header_transport_t hdr_0,
	inout switch_lookup_fields_t lkp_0,
	inout switch_ingress_metadata_t ig_md
) (
	switch_uint32_t table_size = 128
) {

	// -------------------------------------
	// Table: RMAC
	// -------------------------------------

#ifdef BRIDGING_ENABLE
	action rmac_hit(
	) {
		ig_md.flags.rmac_hit = true;
	}

	action rmac_miss(
	) {
		ig_md.flags.rmac_hit = false;
	}

	table rmac {
		key = {
#ifdef INGRESS_PARSER_POPULATES_LKP_0
			lkp_0.mac_dst_addr      : exact;
#else
			hdr_0.ethernet.dst_addr : exact;
#endif
		}

		actions = {
			NoAction;
			rmac_hit;
			rmac_miss; // extreme added
		}

//		const default_action = NoAction;
		const default_action = rmac_miss;
		size = table_size;
	}
#endif

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply {
#ifdef BRIDGING_ENABLE
		if(hdr_0.ethernet.isValid()) {
//		if(ig_md.nsh_md.l2_fwd_en == true) {
			// network tapped
			rmac.apply();
		} else {
			// optically tapped
			ig_md.flags.rmac_hit = true;
		}
#else // BRIDGING_ENABLE
		ig_md.flags.rmac_hit = true;
#endif // BRIDGING_ENABLE
	}
}
*/
//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Transport (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnel(
 inout switch_ingress_metadata_t ig_md,
 inout switch_header_transport_t hdr_0,
 inout switch_lookup_fields_t lkp_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
) (
 switch_uint32_t ipv4_src_vtep_table_size=1024,
 switch_uint32_t ipv6_src_vtep_table_size=1024,
 switch_uint32_t ipv4_dst_vtep_table_size=1024,
 switch_uint32_t ipv6_dst_vtep_table_size=1024
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_src_vtep;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_dst_vtep;

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_src_vtepv6;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_dst_vtepv6;


 // -------------------------------------
 // Table: IPv4 Src VTEP
 // -------------------------------------

 // Derek note: These tables are unused in latest switch.p4 code from barefoot

 action src_vtep_hit(
//		switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<16> vpn
 ) {
  stats_src_vtep.count();

//		ig_md.port_lag_index = port_lag_index;
  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;
 }

 // -------------------------------------

 action src_vtep_miss(
 ) {
  stats_src_vtep.count();
 }

 // -------------------------------------

 table src_vtep {
  key = {
   // l3
   lkp_0.ip_src_addr_v4 : ternary @name("src_addr");

   // tunnel
//			tunnel_0.type           : ternary @name("tunnel_type");
   lkp_0.tunnel_type : ternary @name("tunnel_type");
  }

  actions = {
   src_vtep_miss;
   src_vtep_hit;
  }

  const default_action = src_vtep_miss;
  counters = stats_src_vtep;
  size = ipv4_src_vtep_table_size;
 }

 // -------------------------------------
 // Table: IPv6 Src VTEP
 // -------------------------------------


 action src_vtepv6_hit(
//		switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<16> vpn
 ) {
  stats_src_vtepv6.count();

//		ig_md.port_lag_index = port_lag_index;
  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;
 }

 // -------------------------------------

 action src_vtepv6_miss(
 ) {
  stats_src_vtepv6.count();
 }

 // -------------------------------------

 table src_vtepv6 {
  key = {
   // l3
   lkp_0.ip_src_addr : ternary @name("src_addr");

   // tunnel
//			tunnel_0.type       : ternary @name("tunnel_type");
   lkp_0.tunnel_type : ternary @name("tunnel_type");
  }

  actions = {
   src_vtepv6_miss;
   src_vtepv6_hit;
  }

  const default_action = src_vtepv6_miss;
  counters = stats_src_vtepv6;
  size = ipv6_src_vtep_table_size;
 }


 // -------------------------------------
 // Table: IPv4 Dst VTEP
 // -------------------------------------

 bool drop_ = false;

 action dst_vtep_hit(
//		switch_bd_t bd,

  bool drop


  ,
//		switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<16> vpn

//		,
//		bit<SPI_WIDTH>          spi,
//		bit<8>                  si,
//		bit<8>                  si_predec
  ,
  bool mirror_enable,
        switch_mirror_session_t mirror_session_id,
        switch_mirror_meter_id_t mirror_meter_index, // derek added
  switch_cpu_reason_t cpu_reason_code // derek added
 ) {
  stats_dst_vtep.count();

//		ig_md.bd = bd;






//		ig_intr_md_for_dprsr.drop_ctl = drop;
  drop_ = drop;


//		ig_md.port_lag_index   = port_lag_index;
  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;

//		ig_md.nsh_md.spi       = spi;
//		ig_md.nsh_md.si        = si;
//		ig_md.nsh_md.si_predec = si_predec;

  if(mirror_enable) {
   ig_md.mirror.type = 2;
   ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
   ig_md.mirror.session_id = mirror_session_id;



   ig_md.cpu_reason = cpu_reason_code; // derek added
  }
 }

 // -------------------------------------

//	action dst_vtep_tunid_hit(
//	) {
//		stats_dst_vtep.count();
//	}

 // -------------------------------------

 action NoAction_(
 ) {
  stats_dst_vtep.count();
 }

 // -------------------------------------

 table dst_vtep {
  key = {

   ig_md.nsh_md.sap : ternary @name("sap");

   // l3


//			lkp_0.ip_src_addr       : ternary @name("src_addr");
   lkp_0.ip_src_addr_v4 : ternary @name("src_addr");




   lkp_0.ip_type : ternary @name("type");

//			lkp_0.ip_dst_addr       : ternary @name("dst_addr");
   lkp_0.ip_dst_addr_v4 : ternary @name("dst_addr");



   lkp_0.ip_proto : ternary @name("proto");

   // l4
//#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
   lkp_0.l4_src_port : ternary @name("src_port");
   lkp_0.l4_dst_port : ternary @name("dst_port");
//#endif
   // tunnel
   lkp_0.tunnel_type : ternary @name("tunnel_type");

   lkp_0.tunnel_id : ternary @name("tunnel_id");

  }

  actions = {
   NoAction_;
   dst_vtep_hit;
//			dst_vtep_tunid_hit;
  }

  const default_action = NoAction_;
  counters = stats_dst_vtep;
  size = ipv4_dst_vtep_table_size;
 }

 // -------------------------------------
 // Table: IPv6 Dst VTEP
 // -------------------------------------


 action dst_vtepv6_hit(
//		switch_bd_t bd,

  bool drop


  ,
//		switch_port_lag_index_t port_lag_index,
  bit<16> sap,
  bit<16> vpn

//		,
//		bit<SPI_WIDTH>          spi,
//		bit<8>                  si,
//		bit<8>                  si_predec
  ,
  bool mirror_enable,
        switch_mirror_session_t mirror_session_id,
        switch_mirror_meter_id_t mirror_meter_index, // derek added
  switch_cpu_reason_t cpu_reason_code // derek added
 ) {
  stats_dst_vtepv6.count();

//		ig_md.bd = bd;






//		ig_intr_md_for_dprsr.drop_ctl = drop;
  drop_ = drop;


//		ig_md.port_lag_index   = port_lag_index;
  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;

//		ig_md.nsh_md.spi       = spi;
//		ig_md.nsh_md.si        = si;
//		ig_md.nsh_md.si_predec = si_predec;

  if(mirror_enable) {
   ig_md.mirror.type = 2;
   ig_md.mirror.src = SWITCH_PKT_SRC_CLONED_INGRESS;
   ig_md.mirror.session_id = mirror_session_id;



   ig_md.cpu_reason = cpu_reason_code; // derek added
  }
 }

 // -------------------------------------

//	action dst_vtepv6_tunid_hit(
//	) {
//		stats_dst_vtepv6.count();
//	}

 // -------------------------------------

 action NoAction_v6(
 ) {
  stats_dst_vtepv6.count();
 }

 // -------------------------------------

 table dst_vtepv6 {
  key = {

   ig_md.nsh_md.sap : ternary @name("sap");

   // l3

   lkp_0.ip_src_addr : ternary @name("src_addr");

   lkp_0.ip_type : ternary @name("ip_type");
   lkp_0.ip_dst_addr : ternary @name("dst_addr");
   lkp_0.ip_proto : ternary @name("proto");

   // l4
//#ifdef VXLAN_TRANSPORT_INGRESS_ENABLE_V4
   lkp_0.l4_src_port : ternary @name("src_port");
   lkp_0.l4_dst_port : ternary @name("dst_port");
//#endif
   // tunnel
   lkp_0.tunnel_type : ternary @name("tunnel_type");

   lkp_0.tunnel_id : ternary @name("tunnel_id");

  }

  actions = {
   NoAction_v6;
   dst_vtepv6_hit;
//			dst_vtepv6_tunid_hit;
  }

  const default_action = NoAction_v6;
  counters = stats_dst_vtepv6;
  size = ipv6_dst_vtep_table_size;
 }


 // -------------------------------------
 // Table: VNI to BD
 // -------------------------------------
/*
    // Tunnel id -> BD Translation
    table vni_to_bd_mapping {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtep_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }

	// -------------------------------------
	// -------------------------------------

#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
    // Tunnel id -> BD Translation
    table vni_to_bd_mappingv6 {
        key = {
			lkp_0.tunnel_id : exact;
		}

        actions = {
            NoAction;
            dst_vtepv6_hit;
        }

        default_action = NoAction;
        // size = VNI_MAPPING_TABLE_SIZE;
    }
#endif
*/
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

/*
		// outer RMAC lookup for tunnel termination.
//		switch(rmac.apply().action_run) {
//			rmac_hit : {
  #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4)
    #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
				if (hdr_0.ipv4.isValid()) {
//				if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV4) {
    #endif
      #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					src_vtep.apply();
      #endif // ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					switch(dst_vtep.apply().action_run) {
//						dst_vtep_tunid_hit : {
//							// Vxlan
//							vni_to_bd_mapping.apply();
//						}
						dst_vtep_hit : {
						}
					}

    #if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
				} else if (hdr_0.ipv6.isValid()) {
//				} else if (lkp_0.ip_type == SWITCH_IP_TYPE_IPV6) {
      #ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					src_vtepv6.apply();
      #endif // ifndef SFC_TRANSPORT_TUNNEL_SHARED_TABLE_ENABLE
					switch(dst_vtepv6.apply().action_run) {
//						dst_vtepv6_tunid_hit : {
//							// Vxlan
//							vni_to_bd_mappingv6.apply();
//						}
						dst_vtepv6_hit : {
						}
					}

				}
    #endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
  #endif // if defined(GRE_TRANSPORT_INGRESS_ENABLE_V4) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V4)
//			}
//		}
*/
/*
		switch(dst_vtep.apply().action_run) {
//			dst_vtep_tunid_hit : {
//				// Vxlan
//				vni_to_bd_mapping.apply();
//			}
			dst_vtep_hit : {
			}
		}
*/
  // --------------------

  if(dst_vtep.apply().hit) {

   if(drop_ == true) {
    ig_intr_md_for_dprsr.drop_ctl = 0x1;
   }

  }


 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Network SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelNetwork(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp_0,
 inout switch_header_transport_t hdr_0
) (
 switch_uint32_t sap_table_size=32w1024
) {

 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------
# 625 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {





 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Outer SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelOuter(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, // extreme added

 inout bool scope_,
 inout bool terminate_
) (
 switch_uint32_t sap_exm_table_size=32w1024,
 switch_uint32_t sap_tcam_table_size=32w1024
) {
//	DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------

//	bool terminate_ = false;
//	bool scope_     = false;
 bool drop_ = false;
/*
	action NoAction_exm (
	) {
		stats_exm.count();
	}

	action sap_exm_hit(
		bit<SSAP_ID_WIDTH> sap,
		bit<VPN_ID_WIDTH>  vpn,
		bool               scope,
		bool               terminate,
		bool               drop
//		,
//		bit<SPI_WIDTH>     spi,
//		bit<8>             si,
//		bit<8>             si_predec
	) {
		stats_exm.count();

		ig_md.nsh_md.sap       = sap;
		ig_md.nsh_md.vpn       = vpn;
		scope_                 = scope;
		terminate_             = terminate;
		drop_                  = drop;
//		ig_md.nsh_md.spi       = spi;
//		ig_md.nsh_md.si        = si;
//		ig_md.nsh_md.si_predec = si_predec;
	}

	// -------------------------------------

	table sap_exm {
		key = {
			ig_md.nsh_md.sap : exact @name("sap");

			// l3
			lkp.ip_type         : exact @name("ip_type");
			lkp.ip_src_addr     : exact @name("ip_src_addr");
			lkp.ip_dst_addr     : exact @name("ip_dst_addr");

			// tunnel
			lkp.tunnel_type     : exact @name("tunnel_type");
			lkp.tunnel_id       : exact @name("tunnel_id");
		}

		actions = {
			NoAction_exm;
			sap_exm_hit;
		}

		const default_action = NoAction_exm;
		counters = stats_exm;
		size = sap_exm_table_size;
	}
*/
 // -------------------------------------
 // -------------------------------------

 action NoAction_tcam (
 ) {
  stats_tcam.count();
 }

 action sap_tcam_hit(
  bit<16> sap,
  bit<16> vpn,
  bool scope,
  bool terminate,
  bool drop
//		,
//		bit<SPI_WIDTH>     spi,
//		bit<8>             si,
//		bit<8>             si_predec
 ) {
  stats_tcam.count();

  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;
  scope_ = scope;
  terminate_ = terminate;





  drop_ = drop;

//		ig_md.nsh_md.spi       = spi;
//		ig_md.nsh_md.si        = si;
//		ig_md.nsh_md.si_predec = si_predec;
 }

 // -------------------------------------

 table sap_tcam {
  key = {
   ig_md.nsh_md.sap : ternary @name("sap");

   // l3
   lkp.ip_type : ternary @name("ip_type");
   lkp.ip_src_addr : ternary @name("ip_src_addr");
   lkp.ip_dst_addr : ternary @name("ip_dst_addr");
   lkp.ip_proto : ternary @name("ip_proto");

   // l4
   lkp.l4_src_port : ternary @name("l4_src_port");
   lkp.l4_dst_port : ternary @name("l4_dst_port");

   // tunnel
   lkp.tunnel_type : ternary @name("tunnel_type");
   lkp.tunnel_id : ternary @name("tunnel_id");
  }

  actions = {
   NoAction_tcam;
   sap_tcam_hit;
  }

  const default_action = NoAction_tcam;
  counters = stats_tcam;
  size = sap_tcam_table_size;
 }

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		ig_md.nsh_md.scope = scope_new;
	}

	table scope_inc {
		key = {
			ig_md.nsh_md.scope : exact;
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
/*
//		if(!sap_exm.apply().hit) {
			sap_tcam.apply();
//		}
*/
/*
		if(lkp.next_lyr_valid == true) {
			if(terminate_ == true) {
				ig_md.tunnel_1.terminate           = true;
				if(ig_md.nsh_md.scope == 2) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			if(scope_ == true) {
				if(ig_md.nsh_md.scope == 1) {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
#else
					ScoperInner.apply(
						hdr_2,

						lkp
					);
#endif
				}

//				scope_inc.apply();
				ig_md.nsh_md.scope = ig_md.nsh_md.scope + 1;
			}
		}
*/
/*
		Scoper_Scope_And_Term_And_Data.apply(
			ig_md.lkp_0,
//			ig_md.lkp_1,
			ig_md.lkp_2,

			lkp,

			terminate_,
			scope_,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
*/
  // --------------------

  if(sap_tcam.apply().hit) {

   if(drop_ == true) {
    ig_intr_md_for_dprsr.drop_ctl = 0x1;
   }

  }
 }
}

//-----------------------------------------------------------------------------
// Ingress Tunnel Decap: Inner SAP (does not alter packet!)
//-----------------------------------------------------------------------------

control IngressTunnelInner(
 inout switch_ingress_metadata_t ig_md,
 inout switch_lookup_fields_t lkp,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr // extreme added
) (
 switch_uint32_t sap_exm_table_size=32w1024,
 switch_uint32_t sap_tcam_table_size=32w1024
) {
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_exm;
 DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats_tcam;

 // -------------------------------------
 // Table: SAP
 // -------------------------------------

 bool terminate_ = false;
 bool scope_ = false;
 bool drop_ = false;

 action NoAction_exm (
 ) {
  stats_exm.count();
 }

 action sap_exm_hit(
  bit<16> sap,
  bit<16> vpn,
  bool scope,
  bool terminate,
  bool drop
//		,
//		bit<SPI_WIDTH>     spi,
//		bit<8>             si,
//		bit<8>             si_predec
 ) {
  stats_exm.count();

  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;
  scope_ = scope;
  terminate_ = terminate;





  drop_ = drop;

//		ig_md.nsh_md.spi       = spi;
//		ig_md.nsh_md.si        = si;
//		ig_md.nsh_md.si_predec = si_predec;
 }

 // -------------------------------------

 table sap_exm {
  key = {
   ig_md.nsh_md.sap : exact @name("sap");

   // l3
   lkp.ip_type : ternary @name("ip_type");
   lkp.ip_src_addr : ternary @name("ip_src_addr");
   lkp.ip_dst_addr : ternary @name("ip_dst_addr");
   lkp.ip_proto : ternary @name("ip_proto");

   // l4
   lkp.l4_src_port : ternary @name("l4_src_port");
   lkp.l4_dst_port : ternary @name("l4_dst_port");

   // tunnel
   lkp.tunnel_type : exact @name("tunnel_type");
   lkp.tunnel_id : exact @name("tunnel_id");
  }

  actions = {
   NoAction_exm;
   sap_exm_hit;
  }

  const default_action = NoAction_exm;
  counters = stats_exm;
  size = sap_exm_table_size;
 }

 // -------------------------------------
 // -------------------------------------

 action NoAction_tcam (
 ) {
  stats_tcam.count();
 }

 action sap_tcam_hit(
  bit<16> sap,
  bit<16> vpn,
  bool scope,
  bool terminate,
  bool drop
//		,
//		bit<SPI_WIDTH>     spi,
//		bit<8>             si,
//		bit<8>             si_predec
 ) {
  stats_tcam.count();

  ig_md.nsh_md.sap = sap;
  ig_md.nsh_md.vpn = vpn;
  scope_ = scope;
  terminate_ = terminate;





  drop_ = drop;

//		ig_md.nsh_md.spi       = spi;
//		ig_md.nsh_md.si        = si;
//		ig_md.nsh_md.si_predec = si_predec;
 }

 // -------------------------------------

 table sap_tcam {
  key = {
   ig_md.nsh_md.sap : ternary @name("sap");

   // l3
   lkp.ip_type : ternary @name("ip_type");
   lkp.ip_src_addr : ternary @name("ip_src_addr");
   lkp.ip_dst_addr : ternary @name("ip_dst_addr");
   lkp.ip_proto : ternary @name("ip_proto");

   // l4
   lkp.l4_src_port : ternary @name("l4_src_port");
   lkp.l4_dst_port : ternary @name("l4_dst_port");

   // tunnel
   lkp.tunnel_type : ternary @name("tunnel_type");
   lkp.tunnel_id : ternary @name("tunnel_id");
  }

  actions = {
   NoAction_tcam;
   sap_tcam_hit;
  }

  const default_action = NoAction_tcam;
  counters = stats_tcam;
  size = sap_tcam_table_size;
 }

 // -------------------------------------
 // Table: Scope Increment
 // -------------------------------------
/*
	action new_scope(bit<8> scope_new) {
		ig_md.nsh_md.scope = scope_new;
	}

	table scope_inc {
		key = {
			ig_md.nsh_md.scope : exact;
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
  if(!sap_exm.apply().hit) {
   sap_tcam.apply();
  }
/*
		if(lkp.next_lyr_valid == true) {
			if(terminate_ == true) {
				ig_md.tunnel_1.terminate           = true;
				if(ig_md.nsh_md.scope == 2) {
					ig_md.tunnel_2.terminate           = true;
				}
			}

			if(scope_ == true) {
				if(ig_md.nsh_md.scope == 1) {
#ifdef INGRESS_PARSER_POPULATES_LKP_2
					Scoper.apply(
						lkp_2,
//						ig_md.drop_reason_2,

						lkp
					);
#else
					ScoperInner.apply(
						hdr_2,

						lkp
					);
#endif
				}

//				scope_inc.apply();
				ig_md.nsh_md.scope = ig_md.nsh_md.scope + 1;
			}
		}
*/
/*
		Scoper_Scope_And_Term_And_Data.apply(
			ig_md.lkp_0,
//			ig_md.lkp_1,
			ig_md.lkp_2,

			lkp,

			terminate_,
			scope_,
			ig_md.nsh_md.scope,
			ig_md.tunnel_0.terminate,
			ig_md.tunnel_1.terminate,
			ig_md.tunnel_2.terminate
		);
*/
  // --------------------


  if(drop_ == true) {
   ig_intr_md_for_dprsr.drop_ctl = 0x1;
  }

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Transport
//-----------------------------------------------------------------------------

control TunnelDecapTransportIngress(
 inout switch_header_transport_t hdr_0,
 // ----- current header data -----
//	inout switch_header_transport_t hdr_0,
 in switch_tunnel_metadata_t tunnel_0,
 // ----- next header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536,
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Table
 // -------------------------------------

 action decap_l234() {
  // don't need to do anything, since we don't deparse these headers
 }

 action decap_l234_update_eth (bit<16> new_eth) { hdr_1.ethernet.ether_type = new_eth; hdr_1.ethernet.setValid(); decap_l234(); }

 table decap {
  key = {
   tunnel_0.terminate : exact;
   hdr_1.ethernet.isValid() : exact;
   hdr_1.ipv4.isValid() : exact;
  }

  actions = {
   NoAction;
   decap_l234_update_eth;
  }

  const entries = {
   // hdr hdr_1
   // --- ------------
   (false, false, false) : NoAction();
   (false, false, true ) : NoAction();
   (false, true, false) : NoAction();
   (false, true, true ) : NoAction();
   (true, false, false) : decap_l234_update_eth(0x86dd);
   (true, false, true ) : decap_l234_update_eth(0x0800);
   (true, true, false) : NoAction(); // next layer already has an ethernet header
   (true, true, true ) : NoAction(); // next layer already has an ethernet header
  }
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {
  decap.apply();
/*
        if(tunnel_0.terminate) {
  #ifndef FIX_L3_TUN_ALL_AT_ONCE
            if(!hdr_1.ethernet.isValid()) {
                if(hdr_1.ipv4.isValid()) {
					decap_l234_update_eth(ETHERTYPE_IPV4);
                } else {
					decap_l234_update_eth(ETHERTYPE_IPV6);
                }
            }
  #endif
		}
*/
 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Outer
//-----------------------------------------------------------------------------

control TunnelDecapOuter(
 // ----- current header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- next header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536,
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Table
 // -------------------------------------

 action decap_l2() {
  // ----- l2 -----
  hdr_1.ethernet.setInvalid();
  hdr_1.e_tag.setInvalid();
  hdr_1.vn_tag.setInvalid();
  hdr_1.vlan_tag[0].setInvalid(); // extreme added
  hdr_1.vlan_tag[1].setInvalid(); // extreme added
 }

 bool hdr_1_geneve_setInvalid = false;
 bool hdr_1_vxlan_setInvalid = false;
 bool hdr_1_nvgre_setInvalid = false;

 action decap_l34() {
  // ----- l2.5 -----
# 1253 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
  // ----- l3 -----
  hdr_1.ipv4.setInvalid();

  hdr_1.ipv6.setInvalid();


  // ----- l4 -----
  hdr_1.tcp.setInvalid();
  hdr_1.udp.setInvalid();
  hdr_1.sctp.setInvalid(); // extreme added

  // ----- tunnel -----
//		hdr_1.geneve.setInvalid();
  hdr_1_geneve_setInvalid = true;
//		hdr_1.vxlan.setInvalid();
  hdr_1_vxlan_setInvalid = true;
  hdr_1.gre.setInvalid();
  hdr_1.gre_optional.setInvalid();
//		hdr_1.nvgre.setInvalid();
  hdr_1_nvgre_setInvalid = true;

  hdr_1.gtp_v1_base.setInvalid(); // extreme added
  hdr_1.gtp_v1_optional.setInvalid(); // extreme added

 }

 action decap_l_34_update_vlan1(bit<16> new_eth) { hdr_1.vlan_tag[1].ether_type = new_eth; decap_l34(); }
 action decap_l_34_update_vlan0(bit<16> new_eth) { hdr_1.vlan_tag[0].ether_type = new_eth; decap_l34(); }
 action decap_l_34_update_e (bit<16> new_eth) { hdr_1.e_tag.ether_type = new_eth; decap_l34(); }
 action decap_l_34_update_vn (bit<16> new_eth) { hdr_1.vn_tag.ether_type = new_eth; decap_l34(); }
 action decap_l_34_update_eth (bit<16> new_eth) { hdr_1.ethernet.ether_type = new_eth; decap_l34(); }

 action decap_l234_update_vlan1(bit<16> new_eth) { hdr_1.vlan_tag[1].ether_type = new_eth; decap_l2(); decap_l34(); }
 action decap_l234_update_vlan0(bit<16> new_eth) { hdr_1.vlan_tag[0].ether_type = new_eth; decap_l2(); decap_l34(); }
 action decap_l234_update_e (bit<16> new_eth) { hdr_1.e_tag.ether_type = new_eth; decap_l2(); decap_l34(); }
 action decap_l234_update_vn (bit<16> new_eth) { hdr_1.vn_tag.ether_type = new_eth; decap_l2(); decap_l34(); }
 action decap_l234_update_eth (bit<16> new_eth) { hdr_1.ethernet.ether_type = new_eth; decap_l2(); decap_l34(); }

 // -------------------------------------

 @name("decap")
 table decap {
  key = {
   tunnel_1.terminate : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;

   tunnel_2.terminate : exact;
   hdr_2.ethernet.isValid() : ternary;
   hdr_2.ipv4.isValid() : ternary;

   hdr_3.ethernet.isValid() : ternary;
   hdr_3.ipv4.isValid() : ternary;
  }

  actions = {
   decap_l_34_update_vlan1;
   decap_l_34_update_vlan0;
//			decap_l_34_update_e;
//			decap_l_34_update_vn;
   decap_l_34_update_eth;

   decap_l234_update_vlan1;
   decap_l234_update_vlan0;
//			decap_l234_update_e;
//			decap_l234_update_vn;
   decap_l234_update_eth;
  }

  // My original equation for when to remove the outer l2 header:
  //
  // only remove l2 when the next layer's is valid
  // if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
  // }

   // hdr_1                            hdr__2               hdr_3
   // -------------------------------- -------------------- ------------
  const entries = {
   (true, true, false, false, false, true, _, _ ) : decap_l_34_update_vlan0(0x0800);
   (true, true, false, false, false, false, _, _ ) : decap_l_34_update_vlan0(0x86dd);
   (true, true, true, false, false, true, _, _ ) : decap_l_34_update_vlan1(0x0800);
   (true, true, true, false, false, false, _, _ ) : decap_l_34_update_vlan1(0x86dd);
   (true, false, false, false, false, true, _, _ ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, false, false, _, _ ) : decap_l_34_update_eth (0x86dd);

   (true, true, false, false, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, true, false, false, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, true, true, false, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, true, true, false, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, false, false, false, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, true, false, true, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, true, false, true, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, true, true, true, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, true, true, true, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, false, false, true, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, true, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, true, false, true, _, _, false, true ) : decap_l_34_update_vlan0(0x0800);
   (true, true, false, true, _, _, false, false) : decap_l_34_update_vlan0(0x86dd);
   (true, true, true, true, _, _, false, true ) : decap_l_34_update_vlan1(0x0800);
   (true, true, true, true, _, _, false, false) : decap_l_34_update_vlan1(0x86dd);
   (true, false, false, true, _, _, false, true ) : decap_l_34_update_eth (0x0800);
   (true, false, false, true, _, _, false, false) : decap_l_34_update_eth (0x86dd);

   (true, true, false, true, _, _, true, true ) : decap_l234_update_vlan0(0x0800);
   (true, true, false, true, _, _, true, false) : decap_l234_update_vlan0(0x86dd);
   (true, true, true, true, _, _, true, true ) : decap_l234_update_vlan1(0x0800);
   (true, true, true, true, _, _, true, false) : decap_l234_update_vlan1(0x86dd);
   (true, false, false, true, _, _, true, true ) : decap_l234_update_eth (0x0800);
   (true, false, false, true, _, _, true, false) : decap_l234_update_eth (0x86dd);
  }
 }

 // -------------------------------------

 @name("decap")
 table decap_etag {
  key = {
   tunnel_1.terminate : exact;
   hdr_1.e_tag.isValid() : ternary;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;

   tunnel_2.terminate : exact;
   hdr_2.ethernet.isValid() : ternary;
   hdr_2.ipv4.isValid() : ternary;

   hdr_3.ethernet.isValid() : ternary;
   hdr_3.ipv4.isValid() : ternary;
  }

  actions = {
   decap_l_34_update_vlan1;
   decap_l_34_update_vlan0;
   decap_l_34_update_e;
//			decap_l_34_update_vn;
   decap_l_34_update_eth;

   decap_l234_update_vlan1;
   decap_l234_update_vlan0;
   decap_l234_update_e;
//			decap_l234_update_vn;
   decap_l234_update_eth;
  }

  // My original equation for when to remove the outer l2 header:
  //
  // only remove l2 when the next layer's is valid
  // if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
  // }

   // hdr_1                            hdr__2               hdr_3
   // -------------------------------- -------------------- ------------
  const entries = {
   (true, _, true, false, false, false, true, _, _ ) : decap_l_34_update_vlan0(0x0800);
   (true, _, true, false, false, false, false, _, _ ) : decap_l_34_update_vlan0(0x86dd);
   (true, _, true, true, false, false, true, _, _ ) : decap_l_34_update_vlan1(0x0800);
   (true, _, true, true, false, false, false, _, _ ) : decap_l_34_update_vlan1(0x86dd);
   (true, true, false, false, false, false, true, _, _ ) : decap_l_34_update_e (0x0800);
   (true, true, false, false, false, false, false, _, _ ) : decap_l_34_update_e (0x86dd);
   (true, false, false, false, false, false, true, _, _ ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, false, false, false, _, _ ) : decap_l_34_update_eth (0x86dd);

   (true, _, true, false, false, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, _, true, false, false, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, _, true, true, false, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, _, true, true, false, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, false, true, true, _, _ ) : decap_l234_update_e (0x0800);
   (true, true, false, false, false, true, false, _, _ ) : decap_l234_update_e (0x86dd);
   (true, false, false, false, false, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, false, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, _, true, false, true, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, _, true, false, true, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, _, true, true, true, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, _, true, true, true, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, true, true, true, _, _ ) : decap_l234_update_e (0x0800);
   (true, true, false, false, true, true, false, _, _ ) : decap_l234_update_e (0x86dd);
   (true, false, false, false, true, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, true, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, _, true, false, true, _, _, false, true ) : decap_l_34_update_vlan0(0x0800);
   (true, _, true, false, true, _, _, false, false) : decap_l_34_update_vlan0(0x86dd);
   (true, _, true, true, true, _, _, false, true ) : decap_l_34_update_vlan1(0x0800);
   (true, _, true, true, true, _, _, false, false) : decap_l_34_update_vlan1(0x86dd);
   (true, true, false, false, true, _, _, false, true ) : decap_l_34_update_e (0x0800);
   (true, true, false, false, true, _, _, false, false) : decap_l_34_update_e (0x86dd);
   (true, false, false, false, true, _, _, false, true ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, true, _, _, false, false) : decap_l_34_update_eth (0x86dd);

   (true, _, true, false, true, _, _, true, true ) : decap_l234_update_vlan0(0x0800);
   (true, _, true, false, true, _, _, true, false) : decap_l234_update_vlan0(0x86dd);
   (true, _, true, true, true, _, _, true, true ) : decap_l234_update_vlan1(0x0800);
   (true, _, true, true, true, _, _, true, false) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, true, _, _, true, true ) : decap_l234_update_e (0x0800);
   (true, true, false, false, true, _, _, true, false) : decap_l234_update_e (0x86dd);
   (true, false, false, false, true, _, _, true, true ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, true, _, _, true, false) : decap_l234_update_eth (0x86dd);
  }
 }

 // -------------------------------------

 @name("decap")
 table decap_vntag {
  key = {
   tunnel_1.terminate : exact;
   hdr_1.vn_tag.isValid() : ternary;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;

   tunnel_2.terminate : exact;
   hdr_2.ethernet.isValid() : ternary;
   hdr_2.ipv4.isValid() : ternary;

   hdr_3.ethernet.isValid() : ternary;
   hdr_3.ipv4.isValid() : ternary;
  }

  actions = {
   decap_l_34_update_vlan1;
   decap_l_34_update_vlan0;
//			decap_l_34_update_e;
   decap_l_34_update_vn;
   decap_l_34_update_eth;

   decap_l234_update_vlan1;
   decap_l234_update_vlan0;
//			decap_l234_update_e;
   decap_l234_update_vn;
   decap_l234_update_eth;
  }

  // My original equation for when to remove the outer l2 header:
  //
  // only remove l2 when the next layer's is valid
  // if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
  // }

   // hdr_1                            hdr__2               hdr_3
   // -------------------------------- -------------------- ------------
  const entries = {
   (true, _, true, false, false, false, true, _, _ ) : decap_l_34_update_vlan0(0x0800);
   (true, _, true, false, false, false, false, _, _ ) : decap_l_34_update_vlan0(0x86dd);
   (true, _, true, true, false, false, true, _, _ ) : decap_l_34_update_vlan1(0x0800);
   (true, _, true, true, false, false, false, _, _ ) : decap_l_34_update_vlan1(0x86dd);
   (true, true, false, false, false, false, true, _, _ ) : decap_l_34_update_vn (0x0800);
   (true, true, false, false, false, false, false, _, _ ) : decap_l_34_update_vn (0x86dd);
   (true, false, false, false, false, false, true, _, _ ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, false, false, false, _, _ ) : decap_l_34_update_eth (0x86dd);

   (true, _, true, false, false, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, _, true, false, false, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, _, true, true, false, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, _, true, true, false, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, false, true, true, _, _ ) : decap_l234_update_vn (0x0800);
   (true, true, false, false, false, true, false, _, _ ) : decap_l234_update_vn (0x86dd);
   (true, false, false, false, false, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, false, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, _, true, false, true, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, _, true, false, true, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, _, true, true, true, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, _, true, true, true, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, true, true, true, _, _ ) : decap_l234_update_vn (0x0800);
   (true, true, false, false, true, true, false, _, _ ) : decap_l234_update_vn (0x86dd);
   (true, false, false, false, true, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, true, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, _, true, false, true, _, _, false, true ) : decap_l_34_update_vlan0(0x0800);
   (true, _, true, false, true, _, _, false, false) : decap_l_34_update_vlan0(0x86dd);
   (true, _, true, true, true, _, _, false, true ) : decap_l_34_update_vlan1(0x0800);
   (true, _, true, true, true, _, _, false, false) : decap_l_34_update_vlan1(0x86dd);
   (true, true, false, false, true, _, _, false, true ) : decap_l_34_update_vn (0x0800);
   (true, true, false, false, true, _, _, false, false) : decap_l_34_update_vn (0x86dd);
   (true, false, false, false, true, _, _, false, true ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, true, _, _, false, false) : decap_l_34_update_eth (0x86dd);

   (true, _, true, false, true, _, _, true, true ) : decap_l234_update_vlan0(0x0800);
   (true, _, true, false, true, _, _, true, false) : decap_l234_update_vlan0(0x86dd);
   (true, _, true, true, true, _, _, true, true ) : decap_l234_update_vlan1(0x0800);
   (true, _, true, true, true, _, _, true, false) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, true, _, _, true, true ) : decap_l234_update_vn (0x0800);
   (true, true, false, false, true, _, _, true, false) : decap_l234_update_vn (0x86dd);
   (true, false, false, false, true, _, _, true, true ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, true, _, _, true, false) : decap_l234_update_eth (0x86dd);
  }
 }

 // -------------------------------------

 @name("decap")
 table decap_etag_vntag {
  key = {
   tunnel_1.terminate : exact;
   hdr_1.e_tag.isValid() : ternary;
   hdr_1.vn_tag.isValid() : ternary;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;

   tunnel_2.terminate : exact;
   hdr_2.ethernet.isValid() : ternary;
   hdr_2.ipv4.isValid() : ternary;

   hdr_3.ethernet.isValid() : ternary;
   hdr_3.ipv4.isValid() : ternary;
  }

  actions = {
   decap_l_34_update_vlan1;
   decap_l_34_update_vlan0;
   decap_l_34_update_e;
   decap_l_34_update_vn;
   decap_l_34_update_eth;

   decap_l234_update_vlan1;
   decap_l234_update_vlan0;
   decap_l234_update_e;
   decap_l234_update_vn;
   decap_l234_update_eth;
  }

  // My original equation for when to remove the outer l2 header:
  //
  // only remove l2 when the next layer's is valid
  // if(hdr_2.ethernet.isValid() || (tunnel_2.terminate && hdr_3.ethernet.isValid())) {
  // }

   // hdr_1                            hdr__2               hdr_3
   // -------------------------------- -------------------- ------------
  const entries = {
   (true, _, _, true, false, false, false, true, _, _ ) : decap_l_34_update_vlan0(0x0800);
   (true, _, _, true, false, false, false, false, _, _ ) : decap_l_34_update_vlan0(0x86dd);
   (true, _, _, true, true, false, false, true, _, _ ) : decap_l_34_update_vlan1(0x0800);
   (true, _, _, true, true, false, false, false, _, _ ) : decap_l_34_update_vlan1(0x86dd);
   (true, true, false, false, false, false, false, true, _, _ ) : decap_l_34_update_e (0x0800);
   (true, true, false, false, false, false, false, false, _, _ ) : decap_l_34_update_e (0x86dd);
   (true, false, true, false, false, false, false, true, _, _ ) : decap_l_34_update_vn (0x0800);
   (true, false, true, false, false, false, false, false, _, _ ) : decap_l_34_update_vn (0x86dd);
   (true, false, false, false, false, false, false, true, _, _ ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, false, false, false, false, _, _ ) : decap_l_34_update_eth (0x86dd);

   (true, _, _, true, false, false, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, _, _, true, false, false, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, _, _, true, true, false, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, _, _, true, true, false, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, false, false, true, true, _, _ ) : decap_l234_update_e (0x0800);
   (true, true, false, false, false, false, true, false, _, _ ) : decap_l234_update_e (0x86dd);
   (true, false, true, false, false, false, true, true, _, _ ) : decap_l234_update_vn (0x0800);
   (true, false, true, false, false, false, true, false, _, _ ) : decap_l234_update_vn (0x86dd);
   (true, false, false, false, false, false, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, false, false, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, _, _, true, false, true, true, true, _, _ ) : decap_l234_update_vlan0(0x0800);
   (true, _, _, true, false, true, true, false, _, _ ) : decap_l234_update_vlan0(0x86dd);
   (true, _, _, true, true, true, true, true, _, _ ) : decap_l234_update_vlan1(0x0800);
   (true, _, _, true, true, true, true, false, _, _ ) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, false, true, true, true, _, _ ) : decap_l234_update_e (0x0800);
   (true, true, false, false, false, true, true, false, _, _ ) : decap_l234_update_e (0x86dd);
   (true, false, true, false, false, true, true, true, _, _ ) : decap_l234_update_vn (0x0800);
   (true, false, true, false, false, true, true, false, _, _ ) : decap_l234_update_vn (0x86dd);
   (true, false, false, false, false, true, true, true, _, _ ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, false, true, true, false, _, _ ) : decap_l234_update_eth (0x86dd);

   (true, _, _, true, false, true, _, _, false, true ) : decap_l_34_update_vlan0(0x0800);
   (true, _, _, true, false, true, _, _, false, false) : decap_l_34_update_vlan0(0x86dd);
   (true, _, _, true, true, true, _, _, false, true ) : decap_l_34_update_vlan1(0x0800);
   (true, _, _, true, true, true, _, _, false, false) : decap_l_34_update_vlan1(0x86dd);
   (true, true, false, false, false, true, _, _, false, true ) : decap_l_34_update_e (0x0800);
   (true, true, false, false, false, true, _, _, false, false) : decap_l_34_update_e (0x86dd);
   (true, false, true, false, false, true, _, _, false, true ) : decap_l_34_update_vn (0x0800);
   (true, false, true, false, false, true, _, _, false, false) : decap_l_34_update_vn (0x86dd);
   (true, false, false, false, false, true, _, _, false, true ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false, false, true, _, _, false, false) : decap_l_34_update_eth (0x86dd);

   (true, _, _, true, false, true, _, _, true, true ) : decap_l234_update_vlan0(0x0800);
   (true, _, _, true, false, true, _, _, true, false) : decap_l234_update_vlan0(0x86dd);
   (true, _, _, true, true, true, _, _, true, true ) : decap_l234_update_vlan1(0x0800);
   (true, _, _, true, true, true, _, _, true, false) : decap_l234_update_vlan1(0x86dd);
   (true, true, false, false, false, true, _, _, true, true ) : decap_l234_update_e (0x0800);
   (true, true, false, false, false, true, _, _, true, false) : decap_l234_update_e (0x86dd);
   (true, false, true, false, false, true, _, _, true, true ) : decap_l234_update_vn (0x0800);
   (true, false, true, false, false, true, _, _, true, false) : decap_l234_update_vn (0x86dd);
   (true, false, false, false, false, true, _, _, true, true ) : decap_l234_update_eth (0x0800);
   (true, false, false, false, false, true, _, _, true, false) : decap_l234_update_eth (0x86dd);
  }
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
   decap_etag_vntag.apply();
  } else if(OUTER_ETAG_ENABLE) {
   decap_etag.apply();
  } else if(OUTER_VNTAG_ENABLE) {
   decap_vntag.apply();
  } else {
   decap.apply();
  }

  if(OUTER_GENEVE_ENABLE) {
   if(hdr_1_geneve_setInvalid) {
    hdr_1.geneve.setInvalid();
   }
  }
  if(OUTER_VXLAN_ENABLE) {
   if(hdr_1_vxlan_setInvalid) {
    hdr_1.vxlan.setInvalid();
   }
  }
  if(OUTER_NVGRE_ENABLE) {
   if(hdr_1_nvgre_setInvalid) {
    hdr_1.nvgre.setInvalid();
   }
  }

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Inner
//-----------------------------------------------------------------------------

control TunnelDecapInner(
 // ----- previous header data -----
 inout switch_header_outer_t hdr_1,
 in switch_tunnel_metadata_reduced_t tunnel_1,
 // ----- current header data -----
 inout switch_header_inner_t hdr_2,
 in switch_tunnel_metadata_reduced_t tunnel_2,
 // ----- next header data -----
 in switch_header_inner_inner_t hdr_3
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536,
 switch_tunnel_mode_t mode
) {
 // -------------------------------------
 // Table
 // -------------------------------------

 action decap_l2() {
  // ----- l2 -----
  hdr_2.ethernet.setInvalid();
  hdr_2.vlan_tag[0].setInvalid(); // extreme added
 }

 action decap_l34() {
  // ----- l3 -----
  hdr_2.ipv4.setInvalid();

  hdr_2.ipv6.setInvalid();


  // ----- l4 -----
  hdr_2.tcp.setInvalid();
  hdr_2.udp.setInvalid();
  hdr_2.sctp.setInvalid(); // extreme added

  // ----- tunnel -----

  hdr_2.gre.setInvalid();
  hdr_2.gre_optional.setInvalid();


  hdr_2.gtp_v1_base.setInvalid(); // extreme added
  hdr_2.gtp_v1_optional.setInvalid(); // extreme added

 }

 action decap_l_34_update_vlan0(bit<16> new_eth) { hdr_2.vlan_tag[0].ether_type = new_eth; decap_l34(); }
 action decap_l_34_update_eth (bit<16> new_eth) { hdr_2.ethernet.ether_type = new_eth; decap_l34(); }
 action decap_l234_update_vlan0(bit<16> new_eth) { hdr_2.vlan_tag[0].ether_type = new_eth; decap_l2(); decap_l34(); }
 action decap_l234_update_eth (bit<16> new_eth) { hdr_2.ethernet.ether_type = new_eth; decap_l2(); decap_l34(); }

 table decap {
  key = {
   tunnel_2.terminate : exact;
   hdr_2.vlan_tag[0].isValid() : exact;

   hdr_3.ethernet.isValid() : exact;
   hdr_3.ipv4.isValid() : exact;
  }

  actions = {
   decap_l_34_update_vlan0;
   decap_l_34_update_eth;

   decap_l234_update_vlan0;
   decap_l234_update_eth;
  }

  const entries = {
   // hdr_2       hdr_3
   // ----------- ------------
   (true, true, false, true ) : decap_l_34_update_vlan0(0x0800);
   (true, true, false, false) : decap_l_34_update_vlan0(0x86dd);
   (true, false, false, true ) : decap_l_34_update_eth (0x0800);
   (true, false, false, false) : decap_l_34_update_eth (0x86dd);

   (true, true, true, true ) : decap_l234_update_vlan0(0x0800);
   (true, true, true, false) : decap_l234_update_vlan0(0x86dd);
   (true, false, true, true ) : decap_l234_update_eth (0x0800);
   (true, false, true, false) : decap_l234_update_eth (0x86dd);
  }
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  decap.apply();

 }
}

//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - L2 Ethertype Fix
//-----------------------------------------------------------------------------
/*
control TunnelDecapFixEthertype(
	// ----- current header data -----
	inout switch_header_outer_t hdr_1,
	in    switch_tunnel_metadata_reduced_t tunnel_1,
	// ----- next header data -----
	inout switch_header_inner_t hdr_2,
	in    switch_tunnel_metadata_reduced_t tunnel_2,
	// ----- next header data -----
	in    switch_header_inner_inner_t hdr_3
) (
) {
	// -------------------------------------
	// Table
	// -------------------------------------

	action fix_l2_decap_hdr_1() {
		hdr_1.ethernet.setInvalid();
		hdr_1.e_tag.setInvalid();
		hdr_1.vn_tag.setInvalid();
		hdr_1.vlan_tag[0].setInvalid(); // extreme added
		hdr_1.vlan_tag[1].setInvalid(); // extreme added
	}

	action fix_l2_decap_hdr_2() {
		hdr_2.ethernet.setInvalid();
		hdr_2.vlan_tag[0].setInvalid(); // extreme added
	}

  #ifdef FIX_L3_TUN_ALL_AT_ONCE

	action fix_l2_etype_vlan_tag1_v4(bit<16> ether_type) {
		hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_vlan_tag0_v4(bit<16> ether_type) {
		hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_vn_tag_v4(bit<16> ether_type) {
		hdr_1.vn_tag.ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_e_tag_v4(bit<16> ether_type) {
		hdr_1.e_tag.ether_type = ETHERTYPE_IPV4;
	}

	action fix_l2_etype_eth_v4(bit<16> ether_type) {
		hdr_1.ethernet.ether_type = ETHERTYPE_IPV4;

		hdr_1.ethernet.setValid(); // always set valid (it may already be valid)
	}

	// -----------------------------------

	action fix_l2_etype_vlan_tag1_v6(bit<16> ether_type) {
		hdr_1.vlan_tag[1].ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_vlan_tag0_v6(bit<16> ether_type) {
		hdr_1.vlan_tag[0].ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_vn_tag_v6(bit<16> ether_type) {
		hdr_1.vn_tag.ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_e_tag_v6(bit<16> ether_type) {
		hdr_1.e_tag.ether_type = ETHERTYPE_IPV6;
	}

	action fix_l2_etype_eth_v6(bit<16> ether_type) {
		hdr_1.ethernet.ether_type = ETHERTYPE_IPV6;

		hdr_1.ethernet.setValid(); // always set valid (it may already be valid)
	}

	// -----------------------------------

	table fix_l2_etype {
		key = {
			tunnel_1.terminate          : ternary;
			tunnel_2.terminate          : ternary;

			hdr_1.ethernet.isValid()    : ternary;
			hdr_1.e_tag.isValid()       : ternary;
			hdr_1.vn_tag.isValid()      : ternary;
			hdr_1.vlan_tag[0].isValid() : ternary;
			hdr_1.vlan_tag[1].isValid() : ternary;
			hdr_1.ipv4.isValid()        : ternary;

			hdr_2.ethernet.isValid()    : ternary;
			hdr_2.ipv4.isValid()        : ternary;

			hdr_3.ethernet.isValid()    : ternary;
			hdr_3.ipv4.isValid()        : ternary;
		}
		actions = {
			NoAction;

			fix_l2_etype_eth_v4;
			fix_l2_etype_e_tag_v4;
			fix_l2_etype_vn_tag_v4;
			fix_l2_etype_vlan_tag0_v4;
			fix_l2_etype_vlan_tag1_v4;

			fix_l2_etype_eth_v6;
			fix_l2_etype_e_tag_v6;
			fix_l2_etype_vn_tag_v6;
			fix_l2_etype_vlan_tag0_v6;
			fix_l2_etype_vlan_tag1_v6;

			fix_l2_decap_hdr_1;
			fix_l2_decap_hdr_2;
		}
		const entries = {
			// a priority encoder

			// -----------   -----------------------------------------   -------------   -------------
			// Terminates    Hdr 1                                       Hdr 2           Hdr 3
			// -----------   -----------------------------------------   -------------   -------------
			// 0 terminates (fix hdr1's l2 etype, based on hdr1's ip type)
			(false, false,   false, _,     _,     _,     _,     true,    _,     _,       _,     _    ) : fix_l2_etype_eth_v4(ETHERTYPE_IPV4);      // do   check for eth true
			(false, false,   false, _,     _,     _,     _,     false,   _,     _,       _,     _    ) : fix_l2_etype_eth_v6(ETHERTYPE_IPV6);      // do   check for eth true

			// 0 terminates (rm  hdr1's l2, since hdr2 has one)
			(false, false,   true,  _,     _,     _,     _,     _,       _,     _,       _,     _    ) : NoAction        ();                       // do   check for eth true

			// 1 terminate  (fix hdr1's l2 etype, based on hdr2's ip type)
			(true,  false,   _,     _,     _,     _,     true,  _,       false, true,    _,     _    ) : fix_l2_etype_vlan_tag1_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     _,     _,     _,     true,  _,       false, false,   _,     _    ) : fix_l2_etype_vlan_tag1_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     _,     _,     true,  false, _,       false, true,    _,     _    ) : fix_l2_etype_vlan_tag0_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     _,     _,     true,  false, _,       false, false,   _,     _    ) : fix_l2_etype_vlan_tag0_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     _,     true,  false, false, _,       false, true,    _,     _    ) : fix_l2_etype_vn_tag_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     _,     true,  false, false, _,       false, false,   _,     _    ) : fix_l2_etype_vn_tag_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     true,  false, false, false, _,       false, true,    _,     _    ) : fix_l2_etype_e_tag_v4(ETHERTYPE_IPV4);
			(true,  false,   _,     true,  false, false, false, _,       false, false,   _,     _    ) : fix_l2_etype_e_tag_v6(ETHERTYPE_IPV6);
			(true,  false,   _,     false, false, false, false, _,       false, true,    _,     _    ) : fix_l2_etype_eth_v4(ETHERTYPE_IPV4);      // don't check for eth true...it might not be
			(true,  false,   _,     false, false, false, false, _,       false, false,   _,     _    ) : fix_l2_etype_eth_v6(ETHERTYPE_IPV6);      // don't check for eth true...it might not be

			// 1 terminate  (rm  hdr1's l2, since hdr2 has one)
			(true,  false,   _,     _,     _,     _,     _,     _,       true,  _,       _,     _    ) : fix_l2_decap_hdr_1();                     // don't check for eth true...it might not be

			// 2 terminates (fix hdr1's l2 etype, based on hdr3's ip type)
			(true,  true,    _,     _,     _,     _,     true,  _,       _,     _,       false, true ) : fix_l2_etype_vlan_tag1_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     _,     _,     _,     true,  _,       _,     _,       false, false) : fix_l2_etype_vlan_tag1_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     _,     _,     true,  false, _,       _,     _,       false, true ) : fix_l2_etype_vlan_tag0_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     _,     _,     true,  false, _,       _,     _,       false, false) : fix_l2_etype_vlan_tag0_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     _,     true,  false, false, _,       _,     _,       false, true ) : fix_l2_etype_vn_tag_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     _,     true,  false, false, _,       _,     _,       false, false) : fix_l2_etype_vn_tag_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     true,  false, false, false, _,       _,     _,       false, true ) : fix_l2_etype_e_tag_v4(ETHERTYPE_IPV4);
			(true,  true,    _,     true,  false, false, false, _,       _,     _,       false, false) : fix_l2_etype_e_tag_v6(ETHERTYPE_IPV6);
			(true,  true,    _,     false, false, false, false, _,       _,     _,       false, true ) : fix_l2_etype_eth_v4(ETHERTYPE_IPV4);      // don't check for eth true...it might not be
			(true,  true,    _,     false, false, false, false, _,       _,     _,       false, false) : fix_l2_etype_eth_v6(ETHERTYPE_IPV6);      // don't check for eth true...it might not be

			// 2 terminates (rm  hdr1's l2, since hdr3 has one)
			(true,  true,    _,     _,     _,     _,     _,     _,       _,     _,       true,  _    ) : fix_l2_decap_hdr1();                      // don't check for eth true...it might not be
		}
		const default_action = NoAction;
	}
  #endif

	// -------------------------------------
	// Apply
	// -------------------------------------

	apply{
  #ifdef FIX_L3_TUN_ALL_AT_ONCE
		fix_l2_etype.apply();
  #endif
	}
}
*/
//-----------------------------------------------------------------------------
// Tunnel Decap Helper Function - Scope Decrement
//-----------------------------------------------------------------------------

control TunnelDecapScopeDecrement (
 inout bool terminate_a,
 inout bool terminate_b,
 inout switch_header_transport_t hdr_0,
 inout bit<8> scope
) {

 action new_scope(bit<8> scope_new) {
  scope = scope_new;
//		terminate_a = false;
//		terminate_b = false;
 }

 table scope_dec {
  key = {
   scope : exact;
   terminate_a : exact;
   terminate_b : exact;
  }
  actions = {
   NoAction;
   new_scope;
  }
  const entries = {
   // no decrement
   (0, false, false) : new_scope(0);
   (1, false, false) : new_scope(1);
   (2, false, false) : new_scope(2);
   (3, false, false) : new_scope(3);
   // decrement by one
   (0, true, false) : new_scope(0); // this is an error condition (underflow) -- cap at 0
   (1, true, false) : new_scope(0);
   (2, true, false) : new_scope(1);
   (3, true, false) : new_scope(2);
   // decrement by one (these should never occur)
   (0, false, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0
   (1, false, true ) : new_scope(0);
   (2, false, true ) : new_scope(1);
   (3, false, true ) : new_scope(2);
   // decrement by two
   (0, true, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0
   (1, true, true ) : new_scope(0); // this is an error condition (underflow) -- cap at 0
   (2, true, true ) : new_scope(0);
   (3, true, true ) : new_scope(1);
  }
  const default_action = NoAction;
 }

 // -------------------------

 apply {
  scope_dec.apply();
 }
}

//-----------------------------------------------------------------------------
// Step 1: IP Tunnel Encapsulation
//
// Tunnel Nexthop Table
//   o Gets tunnel type and tunnel id
//-----------------------------------------------------------------------------

control TunnelNexthop(inout switch_header_outer_t hdr,
    inout switch_egress_metadata_t eg_md,
    inout switch_tunnel_metadata_t tunnel
) (
    switch_uint32_t nexthop_table_size
) {

 // ---------------------------------------------
 // Table: Nexthop Rewrite (aka Tunnel Nexthop)
 // ---------------------------------------------

 // Note, this table has changed a lot in the latest switch.p4.  The key has
 // changed to eg_md.tunnel_nexthop, and action data tunnel.index and ethernet.dst_addr
 // has been added to the actions.

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 action rewrite_l2_with_tunnel( // ---- + -- + tun type + -------
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

  switch_tunnel_type_t type
 ) {
  stats.count();

//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later


  tunnel.type = type;

 }

 // ---------------------------------------------

 action rewrite_l3( // dmac + bd + -------- + -------
 ) {
  stats.count();

  // DEREK: THIS ACTION IS OBSOLETE, BUT KEEP HERE SO AS NOT TO IMPACT FIRMWARE
 }

 // ---------------------------------------------

 action rewrite_l3_with_tunnel( // dmac + bd(vrf) + tun type + -------
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

  switch_tunnel_type_t type
 ) {
  stats.count();


//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = (switch_bd_t) eg_md.vrf;

  tunnel.type = type;

 }

 // ---------------------------------------------

 action rewrite_l3_with_tunnel_id( // dmac + bd + tun type + tun id
//		mac_addr_t dmac,
//		bool strip_tag_e,
//		bool strip_tag_vn,
//		bool strip_tag_vlan,

  switch_tunnel_type_t type,
  switch_tunnel_vni_t id
 ) {
  stats.count();


//		hdr.ethernet.dst_addr = dmac;
//		eg_md.strip_tag_e    = strip_tag_e; // derek: add in later
//		eg_md.strip_tag_vn   = strip_tag_vn; // derek: add in later
//		eg_md.strip_tag_vlan = strip_tag_vlan; // derek: add in later
//		eg_md.bd = SWITCH_BD_DEFAULT_VRF; // derek: add in later

  tunnel.type = type;
  tunnel.vni = id;

 }

 // ---------------------------------------------

 action rewrite_l3_with_tunnel_bd( // dmac + bd + tun type + -------
 ) {
  stats.count();

  // DEREK: THIS ACTION IS OBSOLETE, BUT KEEP HERE SO AS NOT TO IMPACT FIRMWARE
 }

 // ---------------------------------------------

 action no_action(
 ) {
  stats.count();
 }

 // ---------------------------------------------

 table nexthop_rewrite { // aka tunnel_nextuop
  key = { eg_md.nexthop : exact; }
  actions = {

//			NoAction;
   no_action;


   rewrite_l2_with_tunnel;
   rewrite_l3;
   rewrite_l3_with_tunnel;
   rewrite_l3_with_tunnel_bd;
   rewrite_l3_with_tunnel_id;



  }


//		const default_action = NoAction;
  const default_action = no_action;



  size = nexthop_table_size;
  counters = stats;
 }

 // ---------------------------------------------
 // Apply
 // ---------------------------------------------

 apply {
  if (!eg_md.flags.bypass_egress) {
   nexthop_rewrite.apply(); // aka tunnel_nexthop
  }
 }
}

//-----------------------------------------------------------------------------
// Step 2: IP/MPLS Tunnel encapsulation
//
// Encap Outer Table
//   o Gets ip payload length and type
// Tunnel Table
//   o Adds tunnel/encap headers
//     -- Fills in some fields like length, protocol, constants, etc - no addresses.
//-----------------------------------------------------------------------------

control TunnelEncap(
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
 inout switch_header_inner_inner_t hdr_3,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_tunnel_metadata_reduced_t tunnel_2
) (
 switch_tunnel_mode_t mode=switch_tunnel_mode_t.PIPE,
 switch_uint32_t vni_mapping_table_size=1024
) {

//	bit<16> payload_len;
 bit<16> gre_proto;

 //=============================================================================
 // Table #1: Encap Outer (aka Tunnel Encap 0) Copy L3/4 Outer -> Inner
 //=============================================================================
/*
	action rewrite_inner_ipv4_hdr1() {
		payload_len = hdr_1.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	action rewrite_inner_ipv4_hdr2() {
		payload_len = hdr_2.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	action rewrite_inner_ipv4_hdr3() {
		payload_len = hdr_3.ipv4.total_len;
		gre_proto = GRE_PROTOCOLS_IP;
	}

	// --------------------------------
#ifdef IPV6_ENABLE
	action rewrite_inner_ipv6_hdr1() {
//		payload_len = hdr_1.ipv6.payload_len + 16w40;
		payload_len = hdr_1.ipv6.payload_len;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}

	action rewrite_inner_ipv6_hdr2() {
//		payload_len = hdr_2.ipv6.payload_len + 16w40;
		payload_len = hdr_2.ipv6.payload_len;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}

	action rewrite_inner_ipv6_hdr3() {
//		payload_len = hdr_3.ipv6.payload_len + 16w40;
		payload_len = hdr_3.ipv6.payload_len;
		gre_proto = GRE_PROTOCOLS_IPV6;
	}
#endif
	// --------------------------------

	// Look for the first valid l3.

	table encap_outer { // aka tunnel_encap_0
		key = {
			hdr_1.ipv4.isValid() : exact;
			hdr_1.ipv6.isValid() : exact;
			hdr_2.ipv4.isValid() : exact;
			hdr_2.ipv6.isValid() : exact;
			hdr_3.ipv4.isValid() : exact;
			hdr_3.ipv6.isValid() : exact;
		}

		actions = {
			rewrite_inner_ipv4_hdr1;
			rewrite_inner_ipv4_hdr2;
			rewrite_inner_ipv4_hdr3;
#ifdef IPV6_ENABLE
			rewrite_inner_ipv6_hdr1;
			rewrite_inner_ipv6_hdr2;
			rewrite_inner_ipv6_hdr3;
#endif
		}

		const entries = {
			// hdr_1       hdr_2         hdr_3
			// ----------- ------------- ------------
//			(true,  false, _,     _,     _,     _    ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
//			(false, false, true,  false, _,     _    ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
//			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)
#ifdef IPV6_ENABLE
//			(false, true,  _,     _,     _,     _    ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
//			(false, false, false, true,  _,     _    ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
//			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)
#endif

			(true,  false, false, false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  false, false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  true,  false) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  false, true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, false, true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  false, true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, false, true,  true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)
			(true,  false, true,  true,  true,  true ) : rewrite_inner_ipv4_hdr1(); // outer v4       (note: hdr_2 and hdr_3 are don't care)

			(false, false, true,  false, false, false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, true,  false) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, false, true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)
			(false, false, true,  false, true,  true ) : rewrite_inner_ipv4_hdr2(); // inner v4       (note:           hdr_3 are don't care)

			(false, false, false, false, true,  false) : rewrite_inner_ipv4_hdr3(); // inner-inner v4 (note:                 are don't care)
#ifdef IPV6_ENABLE
			(false, true,  false, false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  false, false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  true,  false) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  false, true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, false, true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  false, true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  false, true,  true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)
			(false, true,  true,  true,  true,  true ) : rewrite_inner_ipv6_hdr1(); // outer v6       (note: hdr_2 and hdr_3 are don't care)

			(false, false, false, true,  false, false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  true,  false) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  false, true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)
			(false, false, false, true,  true,  true ) : rewrite_inner_ipv6_hdr2(); // inner v6       (note:           hdr_3 are don't care)

			(false, false, false, false, false, true ) : rewrite_inner_ipv6_hdr3(); // inner-inner v6 (note:                 are don't care)
#endif
		}
	}
*/
 //=============================================================================
 // Table #2: Tunnel (aka Tunnel Encap 1)  Copy L2 Outer -> Inner (Writes Tunnel header, rewrites some of Outer)
 //=============================================================================

 //-----------------------------------------------------------------------------
 // Helper actions to add various headers.
 //-----------------------------------------------------------------------------

 action add_udp_header(bit<16> src_port, bit<16> dst_port, bit<16> length) {







 }

 // -------------------------------------
 // Extreme Networks - Modified
 // -------------------------------------

 action add_gre_header(bit<16> proto, bit<1> K, bit<1> S) {

  hdr_0.gre.setValid();
  hdr_0.gre.proto = proto;
  hdr_0.gre.C = 0;
  hdr_0.gre.R = 0;
  hdr_0.gre.K = K;
  hdr_0.gre.S = S;
  hdr_0.gre.s = 0;
  hdr_0.gre.recurse = 0;
  hdr_0.gre.flags = 0;
  hdr_0.gre.version = 0;

 }

 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

 action add_gre_header_seq() {




 }

 action add_l2_header(bit<16> ethertype) {
  hdr_0.ethernet.setValid();
  hdr_0.ethernet.ether_type = ethertype;
 }

 // -------------------------------------

 action add_erspan_header_type2(switch_mirror_session_t session_id) {
# 2387 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 }

 // action add_erspan_header(bit<32> timestamp, switch_mirror_session_t session_id) {
 // 	hdr_0.erspan_type3.setValid();
 // 	hdr_0.erspan_type3.timestamp = timestamp;
 // 	hdr_0.erspan_type3.session_id = (bit<10>) session_id;
 // 	hdr_0.erspan_type3.version = 4w0x2;
 // 	hdr_0.erspan_type3.sgt = 0;
 // 	hdr_0.erspan_type3.vlan = 0;
 // }

 // -------------------------------------

 action add_ipv4_header(bit<8> proto, bit<3> flags) {

  hdr_0.ipv4.setValid();
  hdr_0.ipv4.version = 4w4;
  hdr_0.ipv4.ihl = 4w5;
  // hdr_0.ipv4.total_len = 0;
  hdr_0.ipv4.identification = 0;
  hdr_0.ipv4.flags = flags; // derek: was 0 originally, but request came in to set 'don't frag' bit
  hdr_0.ipv4.frag_offset = 0;
  hdr_0.ipv4.protocol = proto;
  // hdr_0.ipv4.src_addr = 0;
  // hdr_0.ipv4.dst_addr = 0;

  if (mode == switch_tunnel_mode_t.UNIFORM) {
   // NoAction.
  } else if (mode == switch_tunnel_mode_t.PIPE) {
   hdr_0.ipv4.ttl = 8w64;
   hdr_0.ipv4.tos = 0;
  }

 }

 action add_ipv6_header(bit<8> proto) {
# 2439 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 }

 //-----------------------------------------------------------------------------
 // Actual actions.
 //-----------------------------------------------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 // =====================================
 // ----- Rewrite, IPv4 Stuff -----
 // =====================================

 action rewrite_ipv4_udp() {
  stats.count();

  // ----- l2 -----
  add_l2_header(0x86dd);

  // ----- l3 -----
  add_ipv4_header(17, 2);
//		hdr_0.ipv4.total_len = eg_md.payload_len + (bit<16>)sizeInBytes(hdr_0.ipv4) + (bit<16>)sizeInBytes(hdr_0.udp);
  hdr_0.ipv4.total_len = eg_md.payload_len + 16w42; // ipv4(20) + udp(8) + eth(14)
  hdr_0.ethernet.ether_type = 0x0800;

  // ----- l4 -----
  add_udp_header(0, 0, eg_md.payload_len + 16w22); // udp(8) + eth(14)
 }

 action rewrite_ipv4_gre() {
  stats.count();


  // ----- l2 -----
  add_l2_header(0x0800);

  // ----- l3 -----
  add_ipv4_header(47, 2);
  hdr_0.ipv4.total_len = eg_md.payload_len + 16w24; // ipv4(20) + gre(4)

  // ----- tunnel -----
  add_gre_header(gre_proto, 0, 0);

 }

 action rewrite_ipv4_erspan(switch_mirror_session_t session_id) {
  stats.count();
# 2499 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 }

 // =====================================
 // ----- Rewrite, IPv6 Stuff -----
 // =====================================

 action rewrite_ipv6_udp() {
  stats.count();
# 2520 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 }

 action rewrite_ipv6_gre() {
  stats.count();
# 2536 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 }
/*
	action rewrite_ipv6_erspan(switch_mirror_session_t session_id) {
		stats.count();

		// ----- l2 -----
		add_l2_header(ETHERTYPE_IPV6);

		// ----- l3 -----
		add_ipv6_header(IP_PROTOCOLS_GRE);
		hdr_0.ipv6.payload_len = eg_md.payload_len + 16w30; // gre(8) + erspan(8) + ethernet(14)

		// ----- tunnel -----
		add_gre_header(GRE_PROTOCOLS_ERSPAN_TYPE_2, 0, 1);
		add_gre_header_seq();
		add_erspan_header_type2(session_id);
	}
*/
 // -------------------------------------
 // Extreme Networks - Added
 // -------------------------------------

 action rewrite_mac_in_mac() {
  stats.count();

  add_l2_header(0x894F);
 }

 // -------------------------------------

 action no_action() {
  stats.count();

 }

 // -------------------------------------

 table tunnel { // aka tunnel_encap_1
  key = {
   tunnel_0.type : exact @name("tunnel_.type"); // name change for backwards compatibility
  }

  actions = {
   no_action;

   rewrite_mac_in_mac; // extreme added
   rewrite_ipv4_gre; // extreme added
   rewrite_ipv6_gre; // extreme added
   rewrite_ipv4_erspan; // extreme added
//			rewrite_ipv6_erspan;          // extreme added
   rewrite_ipv4_udp; // extreme added
//			rewrite_ipv6_udp;             // extreme added
  }

  const default_action = no_action;
  counters = stats;
 }

 //=============================================================================
 // Table #3: Terminate L2 (for GRE)
 //=============================================================================

 action decap_l2_outer() {
  // ----- l2 -----
  hdr_1.ethernet.setInvalid();
  hdr_1.e_tag.setInvalid();
  hdr_1.vn_tag.setInvalid();
  hdr_1.vlan_tag[0].setInvalid();
  hdr_1.vlan_tag[1].setInvalid();
# 2620 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 }

 action decap_l2_inner() {
  // ----- l2 -----
  hdr_2.ethernet.setInvalid();
  hdr_2.vlan_tag[0].setInvalid();
 }

 action decap_l2_inner_inner() {
  // ----- l2 -----
 }

 // If we are adding an l3 tunnel, remove the first valid l2.  This could be in
 // any layer(s) prior to the first valid l3, because we could have decapped l3
 // tunnel(s) and had to leave the l2 from a previous layer.

 table decap_l2 {
  key = {
   hdr_1.ethernet.isValid() : exact;
   hdr_2.ethernet.isValid() : exact;
  }

  actions = {
   NoAction;
   decap_l2_outer;
   decap_l2_inner;
   decap_l2_inner_inner;
  }

  const entries = {
   (true, false) : decap_l2_outer; // note: inner is don't care
   (true, true ) : decap_l2_outer; // note: inner is don't care
   (false, true ) : decap_l2_inner;
   (false, false) : decap_l2_inner_inner;
  }
  const default_action = NoAction;
 }

 //=============================================================================
 // Apply
 //=============================================================================

 apply {

  if (tunnel_0.type != SWITCH_TUNNEL_TYPE_NONE) {
   // Copy L3/L4 header into inner headers.
/*
			encap_outer.apply(); // aka tunnel_encap_0 (derek: this no longer copies anything -- it just gets some lengths needed for the next table actions)

			if(gre_proto == GRE_PROTOCOLS_IPV6) {
				eg_md.payload_len = eg_md.payload_len + 16w40; // for ipv6, need to add hdr size to payload len
			}
*/
   PayloadLenEgress.apply(hdr_0, hdr_1, hdr_2, hdr_3, gre_proto, eg_md, eg_intr_md); // aka tunnel_encap_0

   // Add outer L3/L4/Tunnel headers.
//			tunnel.apply();

   switch(tunnel.apply().action_run) { // aka tunnel_encap_1
    rewrite_ipv4_gre: {
//					decap_l2.apply();

     if(hdr_1.ethernet.isValid() == true) {
      decap_l2_outer();
     } else {
      if(hdr_2.ethernet.isValid() == true) {
       decap_l2_inner();
      } else {
       decap_l2_inner_inner();
      }
     }
    }
    rewrite_ipv6_gre: {
# 2706 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
    }
    default: {
    }
   }
  }

 }
}

//-----------------------------------------------------------------------------
// Step 3: IP Tunnel Encapsulation
//
// Various Tables
//   o Fills in addresses
//     -- Outer SIP Rewrite
//     -- Outer DIP Rewrite
//     -- TTL QoS Rewrite
//     -- MPLS Rewrite 
//-----------------------------------------------------------------------------

control TunnelRewrite(
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in switch_tunnel_metadata_t tunnel
) (
 switch_uint32_t ipv4_dst_addr_rewrite_table_size=1024,
 switch_uint32_t ipv6_dst_addr_rewrite_table_size=1024,
 switch_uint32_t nexthop_rewrite_table_size=512,
 switch_uint32_t src_addr_rewrite_table_size=1024,
 switch_uint32_t smac_rewrite_table_size=1024
) {

 EgressBD(BD_TABLE_SIZE) egress_bd;
 switch_smac_index_t smac_index;

 // -------------------------------------
 // Table: Nexthop Rewrite (aka Tunnel Nexthop) (DMAC & BD)
 // -------------------------------------

 // Note, this table has been removed in the latest switch.p4.  It's contents
 // have been distributed to other tables.  The fields tunnel.index and
 // ethernet.dst_addr went to the tunnel_nexthop table, and the rest when to
 // new tables in nexthop.p4

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_nexthop; // direct counter

 // Outer nexthop rewrite
 action rewrite_tunnel(switch_bd_t bd, mac_addr_t dmac) {
  stats_nexthop.count();

  eg_md.bd = bd;
  eg_md.tunnel_0.index = (bit<8>)bd; // derek hack to try to match switch.p4 as best as I can.
  hdr_0.ethernet.dst_addr = dmac;
 }

 action no_action_nexthop() {
  stats_nexthop.count();

 }

 table nexthop_rewrite { // aka tunnel_nexthop
  key = {
   eg_md.tunnel_nexthop : exact @name("eg_md.outer_nexthop");
  }

  actions = {
   no_action_nexthop;
   rewrite_tunnel;
  }

  const default_action = no_action_nexthop;
  size = nexthop_rewrite_table_size;
  counters = stats_nexthop;
 }

 // -------------------------------------
 // Table: SIP Rewrite
 // -------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_src_addr; // direct counter

 // Tunnel source IP rewrite
 action rewrite_ipv4_src(ipv4_addr_t src_addr) {
  stats_src_addr.count();


  hdr_0.ipv4.src_addr = src_addr;

 }

 action rewrite_ipv6_src(ipv6_addr_t src_addr) {
  stats_src_addr.count();




 }

 table src_addr_rewrite {
  key = {
   eg_md.tunnel_0.index : exact @name("eg_md.bd");
  }
  actions = {
   rewrite_ipv4_src;
   rewrite_ipv6_src;
  }

  size = src_addr_rewrite_table_size;
  counters = stats_src_addr;
 }

 // -------------------------------------
 // Table: DIP Rewrite
 // -------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ipv4_dst_addr; // direct counter
 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ipv6_dst_addr; // direct counter

 // Tunnel destination IP rewrite

 action rewrite_ipv4_dst(ipv4_addr_t dst_addr) {
  stats_ipv4_dst_addr.count();

  hdr_0.ipv4.dst_addr = dst_addr;
 }
# 2842 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 table ipv4_dst_addr_rewrite {
  key = { tunnel.dip_index : exact @name("tunnel.index"); }
  actions = { rewrite_ipv4_dst; }
//		const default_action = rewrite_ipv4_dst(0); // extreme modified!
  size = ipv4_dst_addr_rewrite_table_size;
  counters = stats_ipv4_dst_addr;
 }
# 2861 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
 // -------------------------------------
 // Table: SMAC Rewrite
 // -------------------------------------

 // DEREK: As best as I can tell, this table has been absorbed into the EgressBd table in l2.p4 in the lastest swtich.p4 code....

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_smac_rewrite; // direct counter

 // Tunnel source MAC rewrite
 action rewrite_smac(mac_addr_t smac) {
  stats_smac_rewrite.count();

  hdr_0.ethernet.src_addr = smac;
 }

 action no_action_smac() {
  stats_smac_rewrite.count();

 }

 table smac_rewrite {
  key = { smac_index : exact; }
  actions = {
   no_action_smac;
   rewrite_smac;
  }

  const default_action = no_action_smac;
  size = smac_rewrite_table_size;
  counters = stats_smac_rewrite;
 }

 // -------------------------------------
 // Apply
 // -------------------------------------

 apply {

  if (tunnel.type != SWITCH_TUNNEL_TYPE_NONE) {
   nexthop_rewrite.apply(); // aka tunnel_nexthop

   // DEREK: As best as I can tell, this table is now instantiated in the top level in the latest switch.p4 code....
   egress_bd.apply(hdr_0, eg_md, smac_index);


   src_addr_rewrite.apply();

   // DEREK: As best as I can tell, these two tables have been combined into a single table in the lastest swtich.p4 code....

   if (hdr_0.ipv4.isValid()) {
    ipv4_dst_addr_rewrite.apply();
   }
# 2922 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4"
  }


  // DEREK: As best as I can tell, this table has been absorbed into the EgressBd table in l2.p4 in the lastest swtich.p4 code....
  smac_rewrite.apply();

 }
}
# 53 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/multicast.p4" 1



// =============================================================================
// =============================================================================
// =============================================================================

control MulticastReplication (
 inout switch_header_transport_t hdr_0,
 in switch_rid_t replication_id,
 in switch_port_t port,
 inout switch_egress_metadata_t eg_md
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE
) {

 // =========================================================================
 // Table #1: 
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter


 action rid_hit_unique_copies(
  switch_bd_t bd,

  bit<24> spi,
  bit<8> si,

  switch_nexthop_t nexthop_index,
  switch_tunnel_ip_index_t tunnel_index,
  switch_tunnel_nexthop_t outer_nexthop_index
 ) {
  stats.count();

  eg_md.bd = bd;

  eg_md.nsh_md.spi = spi;
  eg_md.nsh_md.si = si;

  eg_md.nexthop = nexthop_index;
  eg_md.tunnel_0.dip_index = tunnel_index;
  eg_md.tunnel_nexthop = outer_nexthop_index;
 }

 action rid_hit_identical_copies(
  switch_bd_t bd
 ) {
  stats.count();

  eg_md.bd = bd;
 }

 action rid_miss() {
  stats.count();

 }

 table rid {
  key = {
   replication_id : exact;
  }
  actions = {
   rid_miss;
   rid_hit_identical_copies;
   rid_hit_unique_copies;
  }

  size = table_size;
  const default_action = rid_miss;
  counters = stats;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Replication ID Lookup
  // =====================================


  if(replication_id != 0) {
   rid.apply();
  }

 }
}
# 54 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/meter.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4" 1
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
# 27 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/meter.p4" 2

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
// @param table_size : Size of the storm control table [per pipe]
// @param meter_size : Size of storm control meters [global pool]
// Stats table size must be 512 per pipe - each port with 6 stat entries [2 colors per pkt-type]
//-------------------------------------------------------------------------------------------------
/*
control StormControl(inout switch_ingress_metadata_t ig_md,
                     in switch_pkt_type_t pkt_type,
                     out bool flag)(
                     switch_uint32_t table_size=256,
                     switch_uint32_t meter_size=1024) {
    DirectCounter<bit<switch_counter_width>>(CounterType_t.PACKETS) storm_control_stats;
    Meter<bit<16>>(meter_size, MeterType_t.PACKETS) meter;

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
            ig_md.qos.storm_control_color: exact;
            pkt_type : ternary;
            ig_md.port: exact;
            ig_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            count;
            drop_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = storm_control_stats;
    }

    action set_meter(bit<16> index) {
        ig_md.qos.storm_control_color = (bit<2>) meter.execute(index);
    }

    table storm_control {
        key =  {
            ig_md.port : exact;
            pkt_type : ternary;
            ig_md.flags.dmac_miss : ternary;
        }

        actions = {
            @defaultonly NoAction;
            set_meter;
        }

        const default_action = NoAction;
        size = table_size;
    }

    apply {
#ifdef STORM_CONTROL_ENABLE
        if (!INGRESS_BYPASS(STORM_CONTROL))
            storm_control.apply();

        if (!INGRESS_BYPASS(STORM_CONTROL))
            stats.apply();
#endif
    }
}
*/
//-------------------------------------------------------------------------------------------------
// Ingress Mirror Meter
//-------------------------------------------------------------------------------------------------
control IngressMirrorMeter(inout switch_ingress_metadata_t ig_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        ig_md.mirror.type = 0;
    }

    @ways(2)
    table meter_action {
        key = {
            color: exact;
            ig_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            ig_md.mirror.meter_index : exact;
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

//-------------------------------------------------------------------------------------------------
// Egress Mirror Meter
//-------------------------------------------------------------------------------------------------
control EgressMirrorMeter(inout switch_egress_metadata_t eg_md)(
                     switch_uint32_t table_size=256) {
    DirectCounter<bit<32>>(CounterType_t.PACKETS_AND_BYTES) stats;
    Meter<bit<9>>(table_size, MeterType_t.PACKETS) meter;
    switch_pkt_color_t color;

    action mirror_and_count() {
        stats.count();
    }

    action no_mirror_and_count() {
        stats.count();
        eg_md.mirror.type = 0;
    }

    @ways(2)
    table meter_action {
        key = {
            color: exact;
            eg_md.mirror.meter_index: exact;
        }

        actions = {
            @defaultonly NoAction;
            mirror_and_count;
            no_mirror_and_count;
        }

        const default_action = NoAction;
        size = table_size*2;
        counters = stats;
    }

    action set_meter(bit<9> index) {
        color = (bit<2>) meter.execute(index);
    }

    table meter_index {
        key = {
            eg_md.mirror.meter_index : exact;
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
# 55 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4" 1
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




// Data-plane telemetry (DTel).

//-----------------------------------------------------------------------------
// Deflect on drop configuration checks if deflect on drop is enabled for a given queue/port pair.
// DOD must be only enabled for unicast traffic.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control DeflectOnDrop(
        in switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)(
        switch_uint32_t table_size=1024) {

 // ------------------------------------------------

    action enable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w1;
    }

    action disable_dod() {
        ig_intr_md_for_tm.deflect_on_drop = 1w0;
    }

    table config {
        key = {
            ig_md.dtel.report_type : ternary;
            ig_intr_md_for_tm.ucast_egress_port : ternary @name("egress_port");
            ig_md.qos.qid: ternary @name("qid");
            ig_md.multicast.id : ternary;
            ig_md.cpu_reason : ternary; // to avoid validity issues, replaces
                                         // ig_intr_md_for_tm.copy_to_cpu
        }

        actions = {
            enable_dod;
            disable_dod;
        }

        size = table_size;
        const default_action = disable_dod;
    }

 // ------------------------------------------------

    apply {
        config.apply();
    }
}

//-----------------------------------------------------------------------------
// Mirror on drop configuration
// Checks if mirror on drop is enabled for a given drop reason.
//
// @param report_type : Telemetry report type.
// @param ig_intr_for_tm : Ingress metadata fiels consumed by traffic manager.
// @param table_size
//-----------------------------------------------------------------------------
control MirrorOnDrop(in switch_drop_reason_t drop_reason,
                     inout switch_dtel_metadata_t dtel_md,
                     inout switch_mirror_metadata_t mirror_md) {

 // ------------------------------------------------

    action mirror() {
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    action mirror_and_set_d_bit() {
        dtel_md.report_type = dtel_md.report_type | SWITCH_DTEL_REPORT_TYPE_DROP;
        mirror_md.type = 3;
        mirror_md.src = SWITCH_PKT_SRC_CLONED_INGRESS;
    }

    table config {
        key = {
            drop_reason : ternary;
            dtel_md.report_type : ternary;
        }

        actions = {
            NoAction;
            mirror;
            mirror_and_set_d_bit;
        }

        const default_action = NoAction;
        // const entries = {
        //    (SWITCH_DROP_REASON_UNKNOWN, _) : NoAction();
        //    (_, SWITCH_DTEL_REPORT_TYPE_DROP &&& SWITCH_DTEL_REPORT_TYPE_DROP) : mirror();
        // }
    }

 // ------------------------------------------------

    apply {
        config.apply();
    }
}


//-----------------------------------------------------------------------------
// Simple bloom filter for drop report suppression to avoid generating duplicate reports.
//
// @param hash : Hash value used to query the bloom filter.
// @param flag : A flag indicating that the report needs to be suppressed.
//-----------------------------------------------------------------------------
control DropReport(in switch_header_transport_t hdr,
                   in switch_egress_metadata_t eg_md,
                   in bit<32> hash, inout bit<2> flag) {

    // Two bit arrays of 128K bits.
    Register<bit<1>, bit<17>>(1 << 17, 0) array1;
    Register<bit<1>, bit<17>>(1 << 17, 0) array2;

    RegisterAction<bit<1>, bit<17>, bit<1>>(array1) filter1 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    RegisterAction<bit<1>, bit<17>, bit<1>>(array2) filter2 = {
        void apply(inout bit<1> val, out bit<1> rv) {
            rv = val;
            val = 0b1;
        }
    };

    apply {
        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[0:0] = filter1.execute(hash[(17 - 1):0]);

        if (eg_md.dtel.report_type & (SWITCH_DTEL_REPORT_TYPE_DROP |
                                      SWITCH_DTEL_SUPPRESS_REPORT |
                                      SWITCH_DTEL_REPORT_TYPE_ETRAP_CHANGE)
            == SWITCH_DTEL_REPORT_TYPE_DROP
            && hdr.dtel_drop_report.isValid())
            flag[1:1] = filter2.execute(hash[31:(32 - 17)]);
    }
}

//-----------------------------------------------------------------------------
// Generates queue reports if hop latency (or queue depth) exceeds a configurable thresholds.
// Quota-based report suppression to avoid generating excessive amount of reports.
// @param port : Egress port
// @param qid : Queue Id.
// @param qdepth : Queue depth.
//-----------------------------------------------------------------------------
struct switch_queue_alert_threshold_t {
    bit<32> qdepth;
    bit<32> latency;
}

struct switch_queue_report_quota_t {
    bit<32> counter;
    bit<32> latency; // Qunatized latency
}

// Quota policy -- The policy maintains counters to track the number of generated reports.

// @param flag : indicating whether to generate a telemetry report or not.
control QueueReport(inout switch_egress_metadata_t eg_md,
                    in egress_intrinsic_metadata_t eg_intr_md,
                    out bit<1> qalert) {

    // Quota for a (port, queue) pair.
    bit<16> quota_;
    const bit<32> queue_table_size = 1024;
    const bit<32> queue_register_size = 2048;

 // ---------------------------------------------------------------

 // TABLE 1 AND ASSOCIATED REGISTERS (QUEUE ALERT)

    // Register to store latency/qdepth thresholds per (port, queue) pair.
    Register<switch_queue_alert_threshold_t, bit<16>>(queue_register_size) thresholds;

 // -----------------------

    RegisterAction<switch_queue_alert_threshold_t, bit<16>, bit<1>>(thresholds) check_thresholds = {
        void apply(inout switch_queue_alert_threshold_t reg, out bit<1> flag) {
            // Set the flag if either of qdepth or latency exceeds the threshold.
            if (reg.latency <= eg_md.dtel.latency || reg.qdepth <= (bit<32>) eg_md.qos.qdepth) {
                flag = 1;
            }
        }
    };

 // -----------------------

    action set_qmask(bit<32> quantization_mask) {
        // Quantize the latency.
        eg_md.dtel.latency = eg_md.dtel.latency & quantization_mask;
    }

    action set_qalert(bit<16> index, bit<16> quota, bit<32> quantization_mask) {
        qalert = check_thresholds.execute(index);
        quota_ = quota;
        set_qmask(quantization_mask);
    }

 @ways(2)
    table queue_alert {
        key = {
            eg_md.qos.qid : exact @name("qid");
            eg_md.port : exact @name("port");
        }

        actions = {
            set_qalert;
            set_qmask;
        }

        size = queue_table_size;
    }

 // ---------------------------------------------------------------

 // TABLE 2 AND ASSOCIATED REGISTERS (CHECK QUOTA)

    // Register to store last observed quantized latency and a counter to track available quota.
    Register<switch_queue_report_quota_t, bit<16>>(queue_register_size) quotas;

 // -----------------------

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) reset_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            flag = 0;
            reg.counter = (bit<32>) quota_[15:0];
        }
    };

 // -----------------------

    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) check_latency_and_update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }

            // Send a report if quantized latency is changed.
            if (reg.latency != eg_md.dtel.latency) {
                reg.latency = eg_md.dtel.latency;
                flag = 1;
            }
        }
    };

 // -----------------------

    // This is only used for deflected packets.
    RegisterAction<switch_queue_report_quota_t, bit<16>, bit<1>>(quotas) update_quota = {
        void apply(inout switch_queue_report_quota_t reg, out bit<1> flag) {
            // Send a report if number of generated reports is not exceeding the quota
            if (reg.counter > 0) {
                reg.counter = reg.counter - 1;
                flag = 1;
            }
        }
    };

 // -----------------------

    action reset_quota_(bit<16> index) {
        qalert = reset_quota.execute(index);
    }

    action update_quota_(bit<16> index) {
        qalert = update_quota.execute(index);
    }

    action check_latency_and_update_quota_(bit<16> index) {
        qalert = check_latency_and_update_quota.execute(index);
    }

    table check_quota {
        key = {
            eg_md.pkt_src : exact;
            qalert : exact;
            eg_md.qos.qid : exact @name("qid");
            eg_md.port : exact @name("port");
        }

        actions = {
            NoAction;
            reset_quota_;
            update_quota_;
            check_latency_and_update_quota_;
        }

        const default_action = NoAction;
        size = 3 * queue_table_size;
    }

 // ------------------------------------------------

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            queue_alert.apply();
        check_quota.apply();
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control FlowReport(in switch_egress_metadata_t eg_md, out bit<2> flag) {

    bit<16> digest;

    //TODO(msharif): Use a better hash
    Hash<bit<16>>(HashAlgorithm_t.CRC16) hash;

    // Two bit arrays of 32K bits. The probability of false positive is about 1% for 4K flows.
    Register<bit<16>, bit<17>>(1 << 17, 0) array1;
    Register<bit<16>, bit<17>>(1 << 17, 0) array2;

    // Encodes 2 bit information for flow state change detection
    // rv = 0b1* : New flow.
    // rv = 0b01 : No change in digest is detected.

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<17>, bit<2>>(array1) filter1 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    @reduction_or_group("filter")
    RegisterAction<bit<16>, bit<17>, bit<2>>(array2) filter2 = {
        void apply(inout bit<16> reg, out bit<2> rv) {
            if (reg == 16w0) {
               rv = 0b10;
            } else if (reg == digest) {
                rv = 0b01;
            }
            reg = digest;
        }
    };

    apply {
# 398 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control IngressDtel(in switch_header_transport_t hdr,
                    in switch_lookup_fields_t lkp,
                    inout switch_ingress_metadata_t ig_md,
                    in bit<16> hash,
                    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                    inout ingress_intrinsic_metadata_for_tm_t ig_intr_for_tm) {

    DeflectOnDrop() dod;
    MirrorOnDrop() mod;

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionProfile(DTEL_SELECTOR_TABLE_SIZE) dtel_action_profile;
    ActionSelector(dtel_action_profile,
                   selector_hash,
                   SelectorMode_t.FAIR,
                   DTEL_MAX_MEMBERS_PER_GROUP,
                   DTEL_GROUP_TABLE_SIZE) session_selector;

 // ------------------------------------------------

    action set_mirror_session(switch_mirror_session_t session_id) {
        ig_md.dtel.session_id = session_id;
    }

    table mirror_session {
        key = {
            hdr.ethernet.isValid() : ternary;
            hash : selector;
        }
        actions = {
            NoAction;
            set_mirror_session;
        }

        implementation = session_selector;
    }

 // ------------------------------------------------

    apply {
# 455 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control DtelConfig(inout switch_header_transport_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    Register<bit<32>, switch_mirror_session_t>(1024) seq_number;
    RegisterAction<bit<32>, switch_mirror_session_t, bit<32>>(seq_number) get_seq_number = {
        void apply(inout bit<32> reg, out bit<32> rv) {
# 479 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
            reg = reg + 1;

            rv = reg;
        }
    };

 // ------------------------------------------------

    action mirror_switch_local() {
        // Generate switch local telemetry report for flow/queue reports.
        eg_md.mirror.type = 4;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_switch_local_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_switch_local();
    }

    action mirror_switch_local_and_drop() {
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_f_bit_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_FLOW;
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_switch_local_and_set_q_f_bits_and_drop() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | (
            SWITCH_DTEL_REPORT_TYPE_QUEUE | SWITCH_DTEL_REPORT_TYPE_FLOW);
        mirror_switch_local();
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action mirror_drop() {
        // Generate telemetry drop report.
        eg_md.mirror.type = 3;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
    }

    action mirror_drop_and_set_q_bit() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_REPORT_TYPE_QUEUE;
        mirror_drop();
    }

    action mirror_clone() {
        // Generate (sampled) clone on behalf of downstream IFA capable devices
        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        eg_md.dtel.session_id = eg_md.dtel.clone_session_id;
    }

    action drop() {
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,




            bit<4> next_proto,

            switch_dtel_report_type_t report_type) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 564 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved = 0;
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;

    }

    action update_and_mirror_truncate(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type) {



        update(switch_id, hw_id, next_proto, report_type);

        eg_md.mirror.type = 5;
        eg_md.mirror.src = SWITCH_PKT_SRC_CLONED_EGRESS;
        // Drop the report.
        eg_intr_md_for_dprsr.drop_ctl = 0x1;
    }

    action update_and_set_etrap(
            switch_uint32_t switch_id,
            switch_dtel_hw_id_t hw_id,
            bit<4> next_proto,
            bit<8> md_length,
            bit<16> rep_md_bits,
            switch_dtel_report_type_t report_type,
            bit<2> etrap_status) {
        hdr.dtel.setValid();
        hdr.dtel.hw_id = hw_id;
        hdr.dtel.switch_id = switch_id;
        hdr.dtel.d_q_f = (bit<3>) report_type;
# 613 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
        hdr.dtel.version = 0;
        hdr.dtel.next_proto = next_proto;
        hdr.dtel.reserved[14:13] = etrap_status; // etrap indication
        hdr.dtel.seq_number = get_seq_number.execute(eg_md.mirror.session_id);
        hdr.dtel.timestamp = (bit<32>) eg_md.ingress_timestamp;

    }

    action set_ipv4_dscp_all(bit<6> dscp) {
        hdr.ipv4.tos[7:2] = dscp;
    }

    action set_ipv6_dscp_all(bit<6> dscp) {

        hdr.ipv6.tos[7:2] = dscp;

    }

    action set_ipv4_dscp_2(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[2:2] = dscp_bit_value;
    }

    action set_ipv6_dscp_2(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[2:2] = dscp_bit_value;

    }

    action set_ipv4_dscp_3(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[3:3] = dscp_bit_value;
    }

    action set_ipv6_dscp_3(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[3:3] = dscp_bit_value;

    }

    action set_ipv4_dscp_4(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[4:4] = dscp_bit_value;
    }

    action set_ipv6_dscp_4(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[4:4] = dscp_bit_value;

    }

    action set_ipv4_dscp_5(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[5:5] = dscp_bit_value;
    }

    action set_ipv6_dscp_5(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[5:5] = dscp_bit_value;

    }

    action set_ipv4_dscp_6(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[6:6] = dscp_bit_value;
    }

    action set_ipv6_dscp_6(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[6:6] = dscp_bit_value;

    }

    action set_ipv4_dscp_7(bit<1> dscp_bit_value) {
        hdr.ipv4.tos[7:7] = dscp_bit_value;
    }

    action set_ipv6_dscp_7(bit<1> dscp_bit_value) {

        hdr.ipv6.tos[7:7] = dscp_bit_value;

    }

    /* config table is responsible for triggering the flow/queue report generation for normal
     * traffic and updating the dtel report headers for telemetry reports.
     *
     * pkt_src        report_type     drop_ flow_ queue drop_  drop_ action
     *                                flag  flag  _flag reason report
     *                                                         valid
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_INGRESS DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_INGRESS DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_INGRESS DROP            0b11  *     *     *      y     drop
     * CLONED_INGRESS DROP            *     *     *     *      y     update(d)
     *
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dqf)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     1     *      *     update(dqf)
     * DEFLECTED      DROP | FLOW     *     *     1     *      *     update(dqf)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(df)
     *                | FLOW
     * DEFLECTED      DROP | FLOW     0b11  *     *     *      *     drop
     * DEFLECTED      DROP | FLOW     *     *     *     *      *     update(df)
     * DEFLECTED      DROP | SUPPRESS *     *     1     *      *     update(dq)
     * DEFLECTED      DROP            0b11  *     1     *      *     update(dq)
     * DEFLECTED      DROP            *     *     1     *      *     update(dq)
     * DEFLECTED      DROP | SUPPRESS *     *     *     *      *     update(d)
     * DEFLECTED      DROP            0b11  *     *     *      *     drop
     * DEFLECTED      DROP            *     *     *     *      *     update(d)
     * DEFLECTED      *               *     *     0     *      *     drop
     * DEFLECTED      *               *     *     1     *      *     update(q)
     *
     * CLONED_EGRESS  FLOW | QUEUE    *     *     *     *      n     update(qf)
     * CLONED_EGRESS  QUEUE           *     *     *     *      n     update(q)
     * CLONED_EGRESS  FLOW            *     *     *     *      n     update(f)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(dqf)
     *                | FLOW | QUEUE
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(df)
     *                | FLOW
     * CLONED_EGRESS  DROP | FLOW     0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP | FLOW     *     *     *     *      y     update(df)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(dq)
     *                | QUEUE
     * CLONED_EGRESS  DROP | QUEUE    0b11  *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | QUEUE    *     *     *     *      y     update(dq)
     * CLONED_EGRESS  DROP | SUPPRESS *     *     *     *      y     update(d)
     * CLONED_EGRESS  DROP            0b11  *     *     *      y     drop
     * CLONED_EGRESS  DROP            *     *     *     *      y     update(d)
     *
     * BRIDGED        FLOW | SUPPRESS *     *     1     0      *     mirror_sw
     * BRIDGED        FLOW            *     0b00  1     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  1     0      *     mirror_sw_l
     * BRIDGED        *               *     *     1     0      *     mirror_sw_l
     * BRIDGED        FLOW | SUPPRESS *     *     *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b00  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     0b1*  *     0      *     mirror_sw_l
     * BRIDGED        FLOW            *     TCPfl *     0      *     mirror_sw_l
     *
     * BRIDGED        DROP            *     *     *     0      *     NoAction
     * User specified entries for egress drop_reason values: mirror or NoAction
     * BRIDGED        DROP            *     *     1     value  *     mirror_drop
     * BRIDGED        DROP            *     *     *     value  *     action
     * BRIDGED        *               *     *     1     value  *     mirror_sw_l
     * Drop report catch all entries
     * BRIDGED        DROP            *     *     1     *      *     mirror_drop
     * BRIDGED        DROP            *     *     *     *      *     mirror_drop
     * BRIDGED        *               *     *     1     *      *     mirror_sw_l
     *
     * *              *               *     *     *     *      *     NoAction
     * This table is asymmetric as hw_id is pipe specific.
     */

    table config {
        key = {
            eg_md.pkt_src : ternary;
            eg_md.dtel.report_type : ternary;
            eg_md.dtel.drop_report_flag : ternary;
            eg_md.dtel.flow_report_flag : ternary;
            eg_md.dtel.queue_report_flag : ternary;
//          eg_md.drop_reason : ternary;
            eg_md.mirror.type : ternary;
            hdr.dtel_drop_report.isValid() : ternary;
# 790 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
        }

        actions = {
            NoAction;
            drop;
            mirror_switch_local;
            mirror_switch_local_and_set_q_bit;
            mirror_drop;
            mirror_drop_and_set_q_bit;
            update;
# 827 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
        }

        const default_action = NoAction;
    }

 // ------------------------------------------------

    apply {
        config.apply();
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control IntEdge(inout switch_egress_metadata_t eg_md)(
                switch_uint32_t port_table_size=288) {

 // ------------------------------------------------

    action set_clone_mirror_session_id(switch_mirror_session_t session_id) {
        eg_md.dtel.clone_session_id = session_id;
    }

    action set_ifa_edge() {
        eg_md.dtel.report_type = eg_md.dtel.report_type | SWITCH_DTEL_IFA_EDGE;
    }

    table port_lookup {
        key = {
            eg_md.port : exact;
        }
        actions = {
            NoAction;
            set_clone_mirror_session_id;
            set_ifa_edge;
        }

        const default_action = NoAction;
        size = port_table_size;
    }

 // ------------------------------------------------

    apply {
        if (eg_md.pkt_src == SWITCH_PKT_SRC_BRIDGED)
            port_lookup.apply();
    }
}

// =============================================================================
// =============================================================================
// =============================================================================

control EgressDtel(inout switch_header_transport_t hdr,
                   inout switch_egress_metadata_t eg_md,
                   in egress_intrinsic_metadata_t eg_intr_md,
                   in bit<32> hash) {

    DropReport() drop_report;
    QueueReport() queue_report;
    FlowReport() flow_report0;
    FlowReport() flow_report1;
    FlowReport() flow_report2;
    FlowReport() flow_report3;
    FlowReport() flow_report4;
    FlowReport() flow_report5;
    FlowReport() flow_report6;
    FlowReport() flow_report7;
    FlowReport() flow_report8;
    FlowReport() flow_report9;
    FlowReport() flow_report10;
    FlowReport() flow_report11;
    FlowReport() flow_report12;
    FlowReport() flow_report13;
    FlowReport() flow_report14;
    FlowReport() flow_report15;
    IntEdge() int_edge;

 // ------------------------------------------------

    action convert_ingress_port(switch_port_t port) {



        hdr.dtel_report.ingress_port = port;

    }

    table ingress_port_conversion {
        key = {




          hdr.dtel_report.ingress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_ingress_port;
        }

        const default_action = NoAction;
    }

 // ------------------------------------------------

    action convert_egress_port(switch_port_t port) {



        hdr.dtel_report.egress_port = port;

    }

    table egress_port_conversion {
        key = {




          hdr.dtel_report.egress_port : exact @name("port");
          hdr.dtel_report.isValid() : exact @name("dtel_report_valid");

        }
        actions = {
            NoAction;
            convert_egress_port;
        }

        const default_action = NoAction;
    }

 // ------------------------------------------------

    apply {
# 1087 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/dtel.p4"
    }
}
# 56 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2

# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4" 1



parser IngressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_ingress_metadata_t ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md
) ( // constructor parameters
    bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

    Checksum() ipv4_checksum_transport;
    Checksum() ipv4_checksum_outer;
    Checksum() ipv4_checksum_inner;

    value_set<switch_cpu_port_value_set_t>(4) cpu_port;
    value_set<bit<32>>(1) my_mac_lo;
    value_set<bit<16>>(1) my_mac_hi;

 //bit<8>  protocol_outer;
 //bit<8>  protocol_inner;

    state start {
        pkt.extract(ig_intr_md);
        ig_md.port = ig_intr_md.ingress_port;



        ig_md.timestamp = ig_intr_md.ingress_mac_tstamp[31:0];


        // Check for resubmit flag if packet is resubmitted.
        // transition select(ig_intr_md.resubmit_flag) {
        //     1 : parse_resubmit;
        //     0 : parse_port_metadata;
        // }

/*
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_0.tunnel_id = 0;
*/
/*
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_1.tunnel_id = 0; // Derek: for some reason we don't fit unless this is here.
*/
/*
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        ig_md.lkp_2.tunnel_id = 0;
*/
        //ig_md.flags.rmac_hit = false;
        ig_md.flags.transport_valid = false;
        ig_md.flags.outer_enet_in_transport = false;
# 62 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        // initialize lookup struct to zeros
/*
        ig_md.lkp_0.mac_src_addr = 0;
        ig_md.lkp_0.mac_dst_addr = 0;
        ig_md.lkp_0.mac_type = 0;
        ig_md.lkp_0.pcp = 0;
        ig_md.lkp_0.pad = 0;
        ig_md.lkp_0.vid = 0;
        ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_0.ip_proto = 0;
        ig_md.lkp_0.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_flags = 0;
        ig_md.lkp_0.ip_src_addr = 0;
        ig_md.lkp_0.ip_dst_addr = 0;
        ig_md.lkp_0.ip_len = 0;
        ig_md.lkp_0.tcp_flags = 0;
        ig_md.lkp_0.l4_src_port = 0;
        ig_md.lkp_0.l4_dst_port = 0;
        ig_md.lkp_0.drop_reason = 0;
*/



        // initialize lookup struct to zeros
/*
        ig_md.lkp_1.mac_src_addr = 0;
        ig_md.lkp_1.mac_dst_addr = 0;
        ig_md.lkp_1.mac_type = 0;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.pad = 0;
        ig_md.lkp_1.vid = 0;
        ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        ig_md.lkp_1.ip_proto = 0;
        ig_md.lkp_1.ip_tos = 0; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = 0;
        ig_md.lkp_1.ip_src_addr = 0;
        ig_md.lkp_1.ip_dst_addr = 0;
        ig_md.lkp_1.ip_len = 0;
        ig_md.lkp_1.tcp_flags = 0;
        ig_md.lkp_1.l4_src_port = 0;
        ig_md.lkp_1.l4_dst_port = 0;
        ig_md.lkp_1.drop_reason = 0;
*/
# 130 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
//      ig_md.inner_inner.ethernet_isValid = false;
//      ig_md.inner_inner.ipv4_isValid = false;
//      ig_md.inner_inner.ipv6_isValid = false;

        transition parse_port_metadata;
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Port Metadata
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_port_metadata {
        // Parse port metadata produced by ibuf

  pkt.advance(PORT_METADATA_SIZE);





//		transition check_from_cpu;
  transition select(FOLDED_ENABLE) {
   true: parse_bridged_pkt;
   false: check_from_cpu;
  }
    }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // Folded Metadata
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md_folded);
//		ig_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;

  // ---- extract base bridged metadata -----
//		ig_md.port                 = hdr.bridged_md_folded.base.ingress_port;




//      ig_md.bd                   = hdr.bridged_md_folded.base.ingress_bd;
  ig_md.nexthop = hdr.bridged_md_folded.base.nexthop;
//      ig_md.pkt_type             = hdr.bridged_md_folded.base.pkt_type;
//      ig_md.flags.bypass_egress  = hdr.bridged_md_folded.base.bypass_egress;
        ig_md.cpu_reason = hdr.bridged_md_folded.base.cpu_reason;
  ig_md.timestamp = hdr.bridged_md_folded.base.timestamp;
//		ig_md.qos.qid              = hdr.bridged_md_folded.base.qid; // can't do in parser for some reason.

  ig_md.hash = hdr.bridged_md_folded.base.hash;

  ig_md.tunnel_nexthop = hdr.bridged_md_folded.tunnel.tunnel_nexthop;
  ig_md.tunnel_0.dip_index = hdr.bridged_md_folded.tunnel.dip_index;
//      ig_md.tunnel_0.hash        = hdr.bridged_md_folded.tunnel.hash;

//      ig_md.tunnel_0.terminate   = hdr.bridged_md_folded.tunnel.terminate_0;
//      ig_md.tunnel_1.terminate   = hdr.bridged_md_folded.tunnel.terminate_1;
//      ig_md.tunnel_2.terminate   = hdr.bridged_md_folded.tunnel.terminate_2;


  // ----- extract nsh bridged metadata -----
  ig_md.flags.transport_valid= hdr.bridged_md_folded.base.transport_valid;
        ig_md.nsh_md.end_of_path = hdr.bridged_md_folded.base.nsh_md_end_of_path;
        ig_md.nsh_md.l2_fwd_en = hdr.bridged_md_folded.base.nsh_md_l2_fwd_en;
//      ig_md.nsh_md.dedup_en      = hdr.bridged_md_folded.base.nsh_md_dedup_en; // can't be done in parser, for some reason

//      transition check_from_cpu;
        transition parse_transport_nsh_internal;
 }

    state parse_transport_nsh_internal {
        pkt.extract(hdr.transport.nsh_type1_internal);

        ig_md.nsh_md.ttl = hdr.transport.nsh_type1_internal.ttl;
        ig_md.nsh_md.spi = (bit<24>)hdr.transport.nsh_type1_internal.spi;
        ig_md.nsh_md.si = hdr.transport.nsh_type1_internal.si;
        ig_md.nsh_md.vpn = (bit<16>)hdr.transport.nsh_type1_internal.vpn;
        ig_md.nsh_md.scope = hdr.transport.nsh_type1_internal.scope;
        ig_md.nsh_md.sap = (bit<16>)hdr.transport.nsh_type1_internal.sap;

        transition parse_outer_ethernet;
 }

    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // CPU Packet Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////



    state check_from_cpu {
        transition select(
            pkt.lookahead<ethernet_h>().ether_type,
            ig_intr_md.ingress_port) {

            cpu_port: construct_my_mac_check_cpu;
            default: construct_my_mac_check;
        }
    }







    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // My-MAC Check
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    //  My   L2   MAU                   First   
    //  MAC  Fwd  Path                  Stack
    //  ----------------------------    ------------
    //  0    0    SFC Optical-Tap       Outer       
    //  0    1    Bridging              Outer       
    //  1    x    SFC Network-Tap       Transport   
    //            or SFC Bypass (nsh)   Transport

    state construct_my_mac_check {
        transition select(TRANSPORT_LAYER_ENABLE) {
            true: check_my_mac_lo;
            false: parse_outer_ethernet;
        }
    }

    state check_my_mac_lo {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi;
            default: construct_transport_special_case_a; // Bridging path
        }
    }

    state check_my_mac_hi {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet; // SFC Network-Tap / SFC Bypass Path
            default: construct_transport_special_case_a; // Bridging path
       }
    }


    state construct_my_mac_check_cpu {
        transition select(TRANSPORT_LAYER_ENABLE) {
            true: check_my_mac_lo_cpu;
            false: parse_outer_ethernet_cpu;
        }
    }

    state check_my_mac_lo_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_lo) {
            my_mac_lo: check_my_mac_hi_cpu;
            default: parse_outer_ethernet_cpu; // Bridging path
        }
    }

    state check_my_mac_hi_cpu {
        transition select(pkt.lookahead<snoop_enet_my_mac_h>().dst_addr_hi) {
            my_mac_hi: parse_transport_ethernet_cpu; // SFC Network-Tap / SFC Bypass Path
            default: parse_outer_ethernet_cpu; // Bridging path
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // Special-Case Snooping Path
    // 
    // Special-case parsing path to enable deeper parsing on a small set of
    // specific packets on a my-mac miss. Information from these packets will
    // be presented to dest-vtep table (transport) instead of the traditional
    // inner-sap table (outer).
    //
    //    enet / mpls-sr
    //    enet / ipv4 / udp / vxlan
    //    enet / ipv4 / udp / geneve
    //    todo: add vlan-tag cases to this list?
    //
    // To accomplish this, we need to lookahead and in some cases begin
    // extracting headers prior to knowing where the headers belong (transport
    // versus outer). Unfortunately, all packets that experience a my-mac miss
    // will start down this path and be subjected to additional parsing states.
    //
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    state construct_transport_special_case_a {
        transition select(
            TRANSPORT_V4_VXLAN_INGRESS_ENABLE,
            TRANSPORT_V4_GENEVE_INGRESS_ENABLE,
            TRANSPORT_MPLS_SR_INGRESS_ENABLE) {
            (_, _, true): check_special_case_enet_ipv4_mpls;
            (_, true, _): check_special_case_enet_ipv4_nompls;
            (true, _, _): check_special_case_enet_ipv4_nompls;
            default: parse_outer_ethernet;
        }
    }

    // state snoop_head_unsure_tunnel {  // compile errors w/ vlan tag case
    //     transition select(
    //         pkt.lookahead<snoop_head_enet_vlan_ipv4_h>().enet_ether_type,
    //         pkt.lookahead<snoop_head_enet_vlan_ipv4_h>().vlan_ether_type,
    //         pkt.lookahead<snoop_head_enet_vlan_ipv4_h>().ipv4_protocol) {
    // 
    //         (ETHERTYPE_VLAN, ETHERTYPE_IPV4, IP_PROTOCOLS_UDP): parse_ethernet_vlan_unsure_vxlan;
    //         default                                           : parse_outer_ethernet;
    //     }
    // }

    state check_special_case_enet_ipv4_mpls {
        transition select(
            pkt.lookahead<snoop_head_enet_ipv4_h>().enet_ether_type,
            pkt.lookahead<snoop_head_enet_ipv4_h>().ipv4_protocol) {
            (0x8847, _ ): parse_transport_ethernet;
            (0x0800, 17): construct_transport_special_case_b;
            default : parse_outer_ethernet;
        }
    }

    state check_special_case_enet_ipv4_nompls {
        transition select(
            pkt.lookahead<snoop_head_enet_ipv4_h>().enet_ether_type,
            pkt.lookahead<snoop_head_enet_ipv4_h>().ipv4_protocol) {
            (0x0800, 17): construct_transport_special_case_b;
            default : parse_outer_ethernet;
        }
    }

    // todo: Insert new state check_special_case_enet_vlan_ipv4 here?

    state construct_transport_special_case_b {
        transition select(
            TRANSPORT_V4_VXLAN_INGRESS_ENABLE,
            TRANSPORT_V4_GENEVE_INGRESS_ENABLE) {
            (true, false): parse_ethernet_unsure_special_case_vxlan;
            (false, true): parse_ethernet_unsure_special_case_geneve;
            (true, true): parse_ethernet_unsure_special_case_vxlan_geneve;
        }
    }

    state parse_ethernet_unsure_special_case_vxlan {
        pkt.extract(hdr.transport.ethernet);

        hdr.outer.ethernet.setValid();
        // Compiler problems: parser tests fail - need to move header in MAU
        hdr.outer.ethernet.dst_addr = hdr.transport.ethernet.dst_addr;
        hdr.outer.ethernet.src_addr = hdr.transport.ethernet.src_addr;
        // hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;


  ig_md.lkp_0.l2_valid = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type = hdr.transport.ethernet.ether_type;



  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.transport.ethernet.ether_type;


        // error: Ran out of parser match registers
        // transition select(pkt.lookahead<snoop_ipv4_udp_geneve_h>().udp_dst_port,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_ver,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_opt_len,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_O,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_C,
        //               pkt.lookahead<snoop_ipv4_udp_geneve_h>().geneve_proto_type) {
        // 
        //   // udp_dst_port   v l O C proto_type 
        //     (UDP_PORT_VXLAN,_,_,_,_,_             ): construct_transport_ipv4;
        //     (UDP_PORT_GENV, 0,0,0,0,ETHERTYPE_ENET): construct_transport_ipv4;
        //     (UDP_PORT_GENV, 0,0,0,0,ETHERTYPE_IPV4): construct_transport_ipv4;
        //     (UDP_PORT_GENV, 0,0,0,0,ETHERTYPE_IPV6): construct_transport_ipv4;
        //     default: not_transport_special_case;
        //     //default: accept;
        // }
        transition select(pkt.lookahead<snoop_ipv4_udp_h>().udp_dst_port) {
            4789: construct_transport_ipv4;
            default: not_transport_special_case;
        }
    }

    state parse_ethernet_unsure_special_case_geneve {
        pkt.extract(hdr.transport.ethernet);

        hdr.outer.ethernet.setValid();
        // Compiler problem: parser tests fail - need to move header in MAU
        hdr.outer.ethernet.dst_addr = hdr.transport.ethernet.dst_addr;
        hdr.outer.ethernet.src_addr = hdr.transport.ethernet.src_addr;
        // hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;


  ig_md.lkp_0.l2_valid = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type = hdr.transport.ethernet.ether_type;



  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.transport.ethernet.ether_type;


        transition select(pkt.lookahead<snoop_ipv4_udp_h>().udp_dst_port) {
            6081 : construct_transport_ipv4;
            default: not_transport_special_case;
        }
    }

    state parse_ethernet_unsure_special_case_vxlan_geneve {
        pkt.extract(hdr.transport.ethernet);

        hdr.outer.ethernet.setValid();
        // Compiler problem: parser tests fail - need to move header in MAU
        hdr.outer.ethernet.dst_addr = hdr.transport.ethernet.dst_addr;
        hdr.outer.ethernet.src_addr = hdr.transport.ethernet.src_addr;
        // hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;


  ig_md.lkp_0.l2_valid = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type = hdr.transport.ethernet.ether_type;



  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.transport.ethernet.ether_type;


        transition select(pkt.lookahead<snoop_ipv4_udp_h>().udp_dst_port) {
            4789: construct_transport_ipv4;
            6081 : construct_transport_ipv4;
            default: not_transport_special_case;
        }
    }

    state not_transport_special_case {
        // hdr.transport.ethernet.setInvalid();
        ig_md.flags.outer_enet_in_transport = true;


  ig_md.lkp_0.l2_valid = false;
        ig_md.lkp_0.mac_src_addr = 0;
        ig_md.lkp_0.mac_dst_addr = 0;
        ig_md.lkp_0.mac_type = 0;


        transition parse_outer_ipv4;
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Transport" Headers / Stack (L2-U)
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Transport (ETH-T)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_transport_ethernet {
        ig_md.flags.transport_valid = true;
        pkt.extract(hdr.transport.ethernet);


  ig_md.lkp_0.l2_valid = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type = hdr.transport.ethernet.ether_type;



        // populate for L3-tunnel case (where there's no L2 present)
  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.transport.ethernet.ether_type;
# 540 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.transport.ethernet.ether_type) {
            0x894F: parse_transport_nsh;
            0x8100: parse_transport_vlan;
            0x0800: construct_transport_ipv4;
            0x86dd: construct_transport_ipv6;
            0x8847: construct_transport_mpls;
            default: accept;
        }
    }

    // -------------------------------------------------------------------------
    state parse_transport_ethernet_cpu {
        ig_md.flags.transport_valid = true;
        pkt.extract(hdr.transport.ethernet);




        pkt.extract(hdr.cpu);


  ig_md.bypass = (bit<8>)hdr.cpu.reason_code;

        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
        //ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
        ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
        //ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
        hdr.transport.ethernet.ether_type = hdr.cpu.ether_type;
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE


  ig_md.lkp_0.l2_valid = true;
        ig_md.lkp_0.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_0.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_0.mac_type = hdr.cpu.ether_type;


// populate for L3-tunnel case (where there's no L2 present)

  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.transport.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.transport.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.cpu.ether_type;


// populate for L3-tunnel case (where there's no L2 present)        
# 597 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.cpu.ether_type) {
            0x894F: parse_transport_nsh;
            0x8100: parse_transport_vlan;
            0x0800: construct_transport_ipv4;
            0x86dd: construct_transport_ipv6;
            default: accept;
        }
    }


    // -------------------------------------------------------------------------
    state parse_transport_vlan {

     pkt.extract(hdr.transport.vlan_tag[0]);

//#ifdef INGRESS_PARSER_POPULATES_LKP_0



//#endif


        ig_md.lkp_0.pcp = hdr.transport.vlan_tag[0].pcp;

        ig_md.lkp_0.vid = hdr.transport.vlan_tag[0].vid;

        ig_md.lkp_0.mac_type = hdr.transport.vlan_tag[0].ether_type;


// populate for L3-tunnel case (where there's no L2 present)

        ig_md.lkp_1.pcp = hdr.transport.vlan_tag[0].pcp;

        ig_md.lkp_1.vid = hdr.transport.vlan_tag[0].vid;

        ig_md.lkp_1.mac_type = hdr.transport.vlan_tag[0].ether_type;


// populate for L3-tunnel case (where there's no L2 present)
# 646 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            0x894F: parse_transport_nsh;
            0x0800: construct_transport_ipv4;
            0x86dd: construct_transport_ipv6;
            default: accept;
        }
    }


    //////////////////////////////////////////////////////////////////////////
    // Layer3 - Transport
    ///////////////////////////////////////////////////////////////////////////

    state construct_transport_ipv4 {
        transition select(TRANSPORT_V4_ENABLE) {
            true: qualify_transport_ipv4;
            false: reject;
        }
    }

    state qualify_transport_ipv4 {
        ig_md.flags.transport_valid = true;
     pkt.extract(hdr.transport.ipv4);

        //ig_md.lkp_0.ip_type      = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_0.ip_proto = hdr.transport.ipv4.protocol;
        ig_md.lkp_0.ip_tos = hdr.transport.ipv4.tos;
        ig_md.lkp_0.ip_flags = hdr.transport.ipv4.flags;
        ig_md.lkp_0.ip_src_addr_v4 = hdr.transport.ipv4.src_addr;
        ig_md.lkp_0.ip_dst_addr_v4 = hdr.transport.ipv4.dst_addr;
        ig_md.lkp_0.ip_len = hdr.transport.ipv4.total_len;

        transition select(hdr.transport.ipv4.ihl,
                          hdr.transport.ipv4.frag_offset) {
            (5, 0): parse_transport_ipv4;
            default: reject;
        }
    }

    state parse_transport_ipv4 {
        transition select(hdr.transport.ipv4.protocol) {
           47: construct_transport_gre;
           17: construct_transport_udp_tunnel;
           default: accept;
        }
    }

    state construct_transport_ipv6 {
        transition select(TRANSPORT_V6_ENABLE, TRANSPORT_V6_REDUCED_ADDR) {
            (true, false): parse_transport_ipv6;
            (true, true): parse_transport_ipv6_reduced_addr;
            (false, _): reject;
        }
    }

    state parse_transport_ipv6 {
        pkt.extract(hdr.transport.ipv6);

        //ig_md.lkp_0.ip_type      = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_0.ip_proto = hdr.transport.ipv6.next_hdr;
        //ig_md.lkp_0.ip_tos       = hdr.transport.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_src_addr = hdr.transport.ipv6.src_addr;
        ig_md.lkp_0.ip_dst_addr = hdr.transport.ipv6.dst_addr;
        ig_md.lkp_0.ip_len = hdr.transport.ipv6.payload_len;

        transition select(hdr.transport.ipv6.next_hdr) {
            47: construct_transport_gre;
            default: accept;
        }
    }

    state parse_transport_ipv6_reduced_addr {
        pkt.extract(hdr.transport.ipv6);

        //ig_md.lkp_0.ip_type      = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_0.ip_proto = hdr.transport.ipv6.next_hdr;
        //ig_md.lkp_0.ip_tos       = hdr.transport.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_0.ip_src_addr_v4 = hdr.transport.ipv6.src_addr[95:64];
        ig_md.lkp_0.ip_dst_addr_v4 = hdr.transport.ipv6.dst_addr[95:64];
        ig_md.lkp_0.ip_len = hdr.transport.ipv6.payload_len;

        transition select(hdr.transport.ipv6.next_hdr) {
            47: construct_transport_gre;
            default: accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer4 - UDP
    ///////////////////////////////////////////////////////////////////////////

    state construct_transport_udp_tunnel {
        transition select(TRANSPORT_V4_VXLAN_INGRESS_ENABLE,
                          TRANSPORT_V4_GENEVE_INGRESS_ENABLE) {
            (false, true): parse_transport_udp_geneve;
            (true, false): parse_transport_udp_vxlan;
            (true, true): parse_transport_udp_vxlan_geneve;
            //default: reject; // should never get here
        }
    }

    state parse_transport_udp_geneve {
        pkt.extract(hdr.transport.udp);

        ig_md.lkp_0.l4_src_port = hdr.transport.udp.src_port;
        ig_md.lkp_0.l4_dst_port = hdr.transport.udp.dst_port;

        transition select(hdr.transport.udp.dst_port) {
            6081: parse_transport_geneve;
            default: accept;
        }
    }

    state parse_transport_udp_vxlan {
        pkt.extract(hdr.transport.udp);

        ig_md.lkp_0.l4_src_port = hdr.transport.udp.src_port;
        ig_md.lkp_0.l4_dst_port = hdr.transport.udp.dst_port;

        transition select(hdr.transport.udp.dst_port) {
            4789: parse_transport_vxlan;
            default: accept;
        }
    }

    state parse_transport_udp_vxlan_geneve {
        pkt.extract(hdr.transport.udp);

        ig_md.lkp_0.l4_src_port = hdr.transport.udp.src_port;
        ig_md.lkp_0.l4_dst_port = hdr.transport.udp.dst_port;

        transition select(hdr.transport.udp.dst_port) {
            4789: parse_transport_vxlan;
            6081: parse_transport_geneve;
            default: accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Transport
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching Segment Routing (MPLS-SR) - Transport
    //-------------------------------------------------------------------------

    state construct_transport_mpls {
        transition select(TRANSPORT_MPLS_SR_INGRESS_ENABLE) {
            true: parse_transport_mpls_0;
            default: reject;
        }
    }

    state parse_transport_mpls_0 {
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_MPLS;
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls[0]);
        transition select(hdr.transport.mpls[0].bos) {
            0: parse_transport_mpls_1;
            1: parse_outer_ethernet;
        }
    }
    state parse_transport_mpls_1 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls[1]);
        transition select(hdr.transport.mpls[1].bos) {
            0: parse_transport_mpls_2;
            1: parse_outer_ethernet;
        }
    }
    state parse_transport_mpls_2 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls[2]);
        transition select(hdr.transport.mpls[2].bos) {
            0: parse_transport_mpls_3;
            1: parse_outer_ethernet;
        }
    }
    state parse_transport_mpls_3 {
        ig_md.lkp_0.tunnel_id = pkt.lookahead<bit<32>>();
        pkt.extract(hdr.transport.mpls[3]);
        transition select(hdr.transport.mpls[3].bos) {
            0: parse_transport_mpls_unsupported;
            1: parse_outer_ethernet;
        }
    }
    state parse_transport_mpls_unsupported {
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Transport
    ///////////////////////////////////////////////////////////////////////////    

    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Transport
    //-------------------------------------------------------------------------

    state parse_transport_vxlan {
        pkt.extract(hdr.transport.vxlan);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_0.tunnel_id = (bit<32>)hdr.transport.vxlan.vni;
        transition parse_outer_ethernet;
    }

    //-------------------------------------------------------------------------
    // Generic Network Virtualization Encapsulation (GENEVE) - Transport
    //-------------------------------------------------------------------------

    state parse_transport_geneve {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {
            (0,0,0,0,0x6558): parse_transport_geneve_qualified;
            (0,0,0,0,0x0800): parse_transport_geneve_qualified;
            (0,0,0,0,0x86dd): parse_transport_geneve_qualified;
            default: accept;
        }
    }

    state parse_transport_geneve_qualified {
        pkt.extract(hdr.transport.geneve);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        ig_md.lkp_0.tunnel_id = (bit<32>)hdr.outer.geneve.vni;

        transition select(hdr.transport.geneve.proto_type) {
            0x6558: parse_outer_ethernet;
            0x0800: parse_outer_ipv4;
            0x86dd: parse_outer_ipv6;
            default: accept;
        }
    }

    //-------------------------------------------------------------------------
    // GRE - Transport
    //-------------------------------------------------------------------------

    state construct_transport_gre {
        transition select(TRANSPORT_GRE_INGRESS_ENABLE,
                          TRANSPORT_ERSPAN_INGRESS_ENABLE) {
            (true, false): parse_transport_gre;
            ( _, true): parse_transport_gre_erspan;
            default: reject;
        }
    }

    state parse_transport_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {
          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_transport_gre_qualified;
            default: accept;
        }
    }

    state parse_transport_gre_erspan {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {
          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_transport_gre_erspan_qualified;
            (0,0,0,1,0,0,0,0): parse_transport_gre_erspan_qualified;
            default: accept;
        }
    }

    state parse_transport_gre_qualified {
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(hdr.transport.gre.S, hdr.transport.gre.proto) {
            (0,0x0800): parse_outer_ipv4;
            (0,0x86dd): parse_outer_ipv6;
            default: accept;
        }
    }

    state parse_transport_gre_erspan_qualified {
        pkt.extract(hdr.transport.gre);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_0.tunnel_id = 0;
        transition select(hdr.transport.gre.S, hdr.transport.gre.proto) {
            (0,0x0800): parse_outer_ipv4;
            (0,0x86dd): parse_outer_ipv6;
            (1,0x88BE): construct_transport_erspan_t2;
            //(1,GRE_PROTOCOLS_ERSPAN_TYPE_3): parse_transport_erspan_t3;
            default: accept;
        }
    }


    //-------------------------------------------------------------------------
    // ERSPAN - Transport
    //-------------------------------------------------------------------------

    state construct_transport_erspan_t2 {
        transition select(TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID) {
            false: parse_transport_erspan_t2;
            true: parse_transport_erspan_t2_set_tunnel_id;
        }
    }

    state parse_transport_erspan_t2 {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
        ig_md.lkp_0.tunnel_id = 0;
        transition parse_outer_ethernet;
    }

    state parse_transport_erspan_t2_set_tunnel_id {
        pkt.extract(hdr.transport.gre_sequence);
        pkt.extract(hdr.transport.erspan_type2);
        ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
        ig_md.lkp_0.tunnel_id = (bit<32>)hdr.transport.erspan_type2.session_id;
        transition parse_outer_ethernet;
    }

    // state parse_transport_erspan_t3 {
    //     pkt.extract(hdr.transport.gre_sequence);
    //     pkt.extract(hdr.transport.erspan_type3);
    //     ig_md.lkp_0.tunnel_type = SWITCH_TUNNEL_TYPE_ERSPAN;
    //     transition select(hdr.transport.erspan_type3.o) {
    //         1: parse_erspan_type3_platform;
    //         default: parse_inner_ethernet;
    //     }
    // }
    // 
    // state parse_transport_erspan_type3_platform {
    //     pkt.extract(hdr.transport.erspan_platform);
    //     transition parse_outer_ethernet;
    // }


    //-------------------------------------------------------------------------
    // NSH - Transport
    //-------------------------------------------------------------------------

    state parse_transport_nsh {
     pkt.extract(hdr.transport.nsh_type1);

        ig_md.nsh_md.ttl = hdr.transport.nsh_type1.ttl;
        ig_md.nsh_md.spi = (bit<24>)hdr.transport.nsh_type1.spi;
        ig_md.nsh_md.si = hdr.transport.nsh_type1.si;
        ig_md.nsh_md.ver = hdr.transport.nsh_type1.ver;
        ig_md.nsh_md.vpn = (bit<16>)hdr.transport.nsh_type1.vpn;
        ig_md.nsh_md.scope = hdr.transport.nsh_type1.scope;
        ig_md.nsh_md.sap = (bit<16>)hdr.transport.nsh_type1.sap;

        transition select(hdr.transport.nsh_type1.next_proto) {
            0x3: parse_outer_ethernet;
            default: accept; // todo: support ipv4? ipv6?
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////
    // todo: explore implementing a fanout state here to save tcam

    state parse_outer_ethernet {
        pkt.extract(hdr.outer.ethernet);


  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;


// populate for L3-tunnel case (where there's no L2 present)
# 1070 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.outer.ethernet.ether_type) {
            0x893F : parse_outer_br;
            0x8926 : parse_outer_vn;
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;



            //ETHERTYPE_ARP  : parse_outer_arp;
            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }


    state parse_outer_ethernet_cpu {
        pkt.extract(hdr.outer.ethernet);



        pkt.extract(hdr.cpu);


  ig_md.bypass = (bit<8>)hdr.cpu.reason_code;

        ig_md.port = (switch_port_t) hdr.cpu.ingress_port;
//      ig_md.egress_port_lag_index = (switch_port_lag_index_t) hdr.cpu.port_lag_index;
  ig_md.flags.bypass_egress = (bool) hdr.cpu.tx_bypass;
//		ig_md.bd = (switch_bd_t)hdr.cpu.ingress_bd;
  hdr.outer.ethernet.ether_type = hdr.cpu.ether_type;
// #ifdef PTP_ENABLE
//         ig_md.flags.capture_ts = (bool) hdr.cpu.capture_ts;  // todo
// #endif // PTP_ENABLE


  ig_md.lkp_1.l2_valid = true;
        ig_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        ig_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        ig_md.lkp_1.mac_type = hdr.cpu.ether_type;
        ig_md.lkp_1.pcp = 0;
        ig_md.lkp_1.vid = 0;


// populate for L3-tunnel case (where there's no L2 present)
# 1126 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.cpu.ether_type) {
            0x893F : parse_outer_br;
            0x8926 : parse_outer_vn;
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;



            //ETHERTYPE_ARP  : parse_outer_arp;
            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }


    state parse_outer_br {
        transition select(OUTER_ETAG_ENABLE) {
            true: extract_outer_br;
            false: accept;
        }
    }

    state extract_outer_br {
     pkt.extract(hdr.outer.e_tag);


        ig_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //ig_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag


// populate for L3-tunnel case (where there's no L2 present)







        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;



            0x0800 : parse_outer_ipv4;
            //ETHERTYPE_ARP  : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }


    state parse_outer_vn {
        transition select(OUTER_VNTAG_ENABLE) {
            true: extract_outer_vn;
            false: accept;
        }
    }

    state extract_outer_vn {
     pkt.extract(hdr.outer.vn_tag);


        ig_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;


// populate for L3-tunnel case (where there's no L2 present)






        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan;
            0x88A8 : parse_outer_vlan;



            0x0800 : parse_outer_ipv4;
            //ETHERTYPE_ARP  : parse_outer_arp;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }


    state parse_outer_vlan {
     pkt.extract(hdr.outer.vlan_tag.next);

//#ifdef INGRESS_PARSER_POPULATES_LKP_1



//#endif // INGRESS_PARSER_POPULATES_LKP_1


        ig_md.lkp_1.pcp = hdr.outer.vlan_tag.last.pcp;

        ig_md.lkp_1.vid = hdr.outer.vlan_tag.last.vid;

        ig_md.lkp_1.mac_type = hdr.outer.vlan_tag.last.ether_type;


// populate for L3-tunnel case (where there's no L2 present)
# 1242 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            0x8100 : parse_outer_vlan;



            0x0800 : parse_outer_ipv4;
            0x86dd : parse_outer_ipv6;
            default : accept;
        }
    }


    // ///////////////////////////////////////////////////////////////////////////
    // // Layer 2.5 - Outer
    // ///////////////////////////////////////////////////////////////////////////
    // 
    // state parse_outer_arp {
    //     // pkt.extract(hdr.outer.arp);
    //     // transition accept;
    //     transition accept;
    // 
    // }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

//     state parse_outer_ipv4 {
//         pkt.extract(hdr.outer.ipv4);
//         protocol_outer = hdr.outer.ipv4.protocol;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv4.protocol;
//         ig_md.lkp_1.ip_tos        = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_flags      = hdr.outer.ipv4.flags;
//         ig_md.lkp_1.ip_src_addr_v4= hdr.outer.ipv4.src_addr;
//         ig_md.lkp_1.ip_dst_addr_v4= hdr.outer.ipv4.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_outer.add(hdr.outer.ipv4);
//         transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
//             (5, 0): parse_outer_ipv4_no_options_frags;
//             default : accept;
//         }
//     }
// 
//     state parse_outer_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
//         transition select(hdr.outer.ipv4.protocol) {
//             //IP_PROTOCOLS_ICMP: parse_outer_icmp_igmp_overload;
//             //IP_PROTOCOLS_IGMP: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
//     }

    state parse_outer_ipv4 {
        pkt.extract(hdr.outer.ipv4);


        //ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv4.protocol;
        ig_md.lkp_1.ip_tos = hdr.outer.ipv4.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_flags = hdr.outer.ipv4.flags;
        ig_md.lkp_1.ip_src_addr_v4= hdr.outer.ipv4.src_addr;
        ig_md.lkp_1.ip_dst_addr_v4= hdr.outer.ipv4.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.
        //ipv4_checksum_outer.add(hdr.outer.ipv4);
        transition select(hdr.outer.ipv4.ihl, hdr.outer.ipv4.frag_offset) {
            (5, 0): parse_outer_ipv4_no_options_frags;
            default : accept;
        }
    }

    state parse_outer_ipv4_no_options_frags {
        transition select(UDF_ENABLE) {
            true: parse_outer_ipv4_no_options_frags_udf;
            false: parse_outer_ipv4_no_options_frags_no_udf;
        }
    }

    state parse_outer_ipv4_no_options_frags_udf {
        //ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
        transition select(hdr.outer.ipv4.protocol, hdr.outer.ipv4.total_len) {
            (4, _ ): parse_outer_ipinip_set_tunnel_type;
            (41, _ ): parse_outer_ipv6inip_set_tunnel_type;
            (47, _ ): parse_outer_gre;
            (17, 20 .. (20 + 8 + (128/8)) ): parse_outer_udp_noudf;
            (17, _ ): parse_outer_udp_udf;
            (6, 20 .. (20 + 20 + (128/8)) ): parse_outer_tcp_noudf;
            (6, _ ): parse_outer_tcp_udf;
            (0x84, 20 .. (20 + 12 + (128/8))): parse_outer_sctp_noudf;
            (0x84, _ ): parse_outer_sctp_udf;
            default: accept;
        }
    }

    state parse_outer_ipv4_no_options_frags_no_udf {
        //ig_md.flags.ipv4_checksum_err_1 = ipv4_checksum_outer.verify();
        transition select(hdr.outer.ipv4.protocol) {
            4: parse_outer_ipinip_set_tunnel_type;
            41: parse_outer_ipv6inip_set_tunnel_type;
            47: parse_outer_gre;
            17: parse_outer_udp_noudf;
            6: parse_outer_tcp_noudf;
            0x84: parse_outer_sctp_noudf;
            default: accept;
        }
    }




//     state parse_outer_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.outer.ipv6);
//         protocol_outer = hdr.outer.ipv6.next_hdr;
// #ifdef INGRESS_PARSER_POPULATES_LKP_1        
//         ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_1.ip_proto      = hdr.outer.ipv6.next_hdr;
//         //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_1.ip_src_addr   = hdr.outer.ipv6.src_addr;
//         ig_md.lkp_1.ip_dst_addr   = hdr.outer.ipv6.dst_addr;
//         ig_md.lkp_1.ip_len        = hdr.outer.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_1
//         transition select(hdr.outer.ipv6.next_hdr) {
//             //IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
//             default: branch_outer_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }


    state parse_outer_ipv6 {
        transition select(UDF_ENABLE) {
            true: parse_outer_ipv6_udf;
            false: parse_outer_ipv6_no_udf;
        }
    }

    state parse_outer_ipv6_udf {

        pkt.extract(hdr.outer.ipv6);


//      ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        ig_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;

        transition select(hdr.outer.ipv6.next_hdr, hdr.outer.ipv6.payload_len) {
            //IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
            (4, _ ): parse_outer_ipinip_set_tunnel_type;
            (41, _ ): parse_outer_ipv6inip_set_tunnel_type;
            (47, _ ): parse_outer_gre;
            (17, 16w0 .. ( 8 + (128/8)) ): parse_outer_udp_noudf;
            (17, _ ): parse_outer_udp_udf;
            (6, 16w0 .. ( 20 + (128/8)) ): parse_outer_tcp_noudf;
            (6, _ ): parse_outer_tcp_udf;
            (0x84, 16w0 .. ( 12 + (128/8))): parse_outer_sctp_noudf;
            (0x84, _ ): parse_outer_sctp_udf;
            default: accept;
        }



    }


    state parse_outer_ipv6_no_udf {

        pkt.extract(hdr.outer.ipv6);


//      ig_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        ig_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //ig_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        ig_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        ig_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        ig_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;

        transition select(hdr.outer.ipv6.next_hdr) {
            //IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload;
            4: parse_outer_ipinip_set_tunnel_type;
            41: parse_outer_ipv6inip_set_tunnel_type;
            47: parse_outer_gre;
            17: parse_outer_udp_noudf;
            6: parse_outer_tcp_noudf;
            0x84: parse_outer_sctp_noudf;
            default: accept;
        }



    }

    // // shared fanout/branch state to save tcam resource
    // state branch_outer_l3_protocol {
    //     transition select(protocol_outer) {
    //         IP_PROTOCOLS_IPV4: parse_outer_ipinip_set_tunnel_type;
    //         IP_PROTOCOLS_IPV6: parse_outer_ipv6inip_set_tunnel_type;
    //         IP_PROTOCOLS_UDP: parse_outer_udp;
    //         IP_PROTOCOLS_TCP: parse_outer_tcp;
    //         IP_PROTOCOLS_SCTP: parse_outer_sctp;
    //         IP_PROTOCOLS_GRE: parse_outer_gre;
    //         //IP_PROTOCOLS_ESP: parse_outer_esp_overload;
    //         default: accept;
    //    }
    // }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp_noudf {
        pkt.extract(hdr.outer.udp);


        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(
            hdr.outer.udp.src_port,
            hdr.outer.udp.dst_port) {

            (_, 6081): parse_outer_geneve;
            (_, 4789): parse_outer_vxlan;

            (_, 2123): parse_outer_gtp_c;
            (2123, _): parse_outer_gtp_c;
            (_, 2152): parse_outer_gtp_u;
            (2152, _): parse_outer_gtp_u;

            default : accept;
        }
    }


    state parse_outer_udp_udf {
        pkt.extract(hdr.outer.udp);


        ig_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(
            hdr.outer.udp.src_port,
            hdr.outer.udp.dst_port) {

            (_, 6081): parse_outer_geneve;
            (_, 4789): parse_outer_vxlan;

            (_, 2123): parse_outer_gtp_c;
            (2123, _): parse_outer_gtp_c;
            (_, 2152): parse_outer_gtp_u;
            (2152, _): parse_outer_gtp_u;

            default : parse_udf;
        }
    }


    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp_noudf {
        pkt.extract(hdr.outer.tcp);

        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition accept;
    }

    state parse_outer_tcp_udf {
        pkt.extract(hdr.outer.tcp);

        ig_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        ig_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition parse_udf;
    }


    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp_noudf {
        pkt.extract(hdr.outer.sctp);

        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition accept;
    }

    state parse_outer_sctp_udf {
        pkt.extract(hdr.outer.sctp);

        ig_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        ig_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition parse_udf;
    }



    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
    // Due to chip resource constraints, we're only supporting MPLS segment
    // routing or MPLS L2/L3VPN (not both). Valid combinations are as follows:
    //
    //  MPLS_SR_ENABLE  MPLS_L2VPN_ENABLE  MPLS_L3VPN_ENABLE
    //  -----------------------------------------------------
    //  #undef          #undef             #undef
    //  #define         #undef             #undef
    //  #undef          #undef             #define
    //  #undef          #define            #undef
    //  #undef          #define            #define
    //
    // For all MPLS enabled combinations above, the user can add MPLS-over-GRE
    // support via the following feature #define: MPLSoGRE_ENABLE
# 1670 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Generic Network Virtualization Encapsulation (GENEVE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_geneve {
        transition select(OUTER_GENEVE_ENABLE) {
            true: qualify_outer_geneve;
            false: accept;
        }
    }

    state qualify_outer_geneve {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {

          //     O C 
            (0,0,0,0,0x6558): parse_outer_geneve_qualified;
            (0,0,0,0,0x0800): parse_outer_geneve_qualified;
            (0,0,0,0,0x86dd): parse_outer_geneve_qualified;
            default: accept;
        }
    }

    state parse_outer_geneve_qualified {
        pkt.extract(hdr.outer.geneve);
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.geneve.vni;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        ig_md.lkp_2.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.geneve.vni;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition select(hdr.outer.geneve.proto_type) {
            0x6558: parse_inner_ethernet;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default: accept;
        }
    }


    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan {
        transition select(OUTER_VXLAN_ENABLE) {
            true: extract_outer_vxlan;
            false: accept;
        }
    }

    state extract_outer_vxlan {
        pkt.extract(hdr.outer.vxlan);
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.vxlan.vni;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2) 
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        ig_md.lkp_2.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.vxlan.vni;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition parse_inner_ethernet;
    }




    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_type {

//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2) 
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition parse_inner_ipv4;



    }

    state parse_outer_ipv6inip_set_tunnel_type {

//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_1.tunnel_id = 0;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2) 
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition parse_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();

//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2) 
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified;
            default: accept;
        }
    }

    state parse_outer_gre_qualified {
        pkt.extract(hdr.outer.gre);
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_1.tunnel_id = 0;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S
            (0,1,0,0x6558): parse_outer_nvgre;
            (0,0,0,0x0800): parse_inner_ipv4;
            (0,0,0,0x86dd): parse_inner_ipv6;



            (1,0,0,_): parse_outer_gre_optional;
            (0,1,0,_): parse_outer_gre_optional;
            (0,0,1,_): parse_outer_gre_optional;
            default: accept;
        }
    }


    state parse_outer_gre_optional {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;



            default: accept;
        }
    }


    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - (aka: L2 GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre {
        transition select(OUTER_NVGRE_ENABLE) {
            true: extract_outer_nvgre;
            false: accept;
        }
    }

    state extract_outer_nvgre {
     pkt.extract(hdr.outer.nvgre);
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.nvgre.vsid;
//#endif
        ig_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; // from switch
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        ig_md.lkp_2.tunnel_id = (bit<switch_tunnel_id_width>)hdr.outer.nvgre.vsid;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition parse_inner_ethernet;
    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Outer
    //-------------------------------------------------------------------------

//     state parse_outer_esp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_1)
//         ig_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         ig_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
//         transition accept;
//     }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_outer_gtp_c {
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2) 
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified {
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
     transition accept;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();

//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif

        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified {
        pkt.extract(hdr.outer.gtp_v1_base);
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.outer.gtp_v1_base.teid;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4;
            6: parse_inner_ipv6;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
//#if defined(INGRESS_PARSER_POPULATES_LKP_1)
        ig_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;
//#endif
//#if defined(INGRESS_PARSER_POPULATES_LKP_2)
/*
  #if defined(INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD)
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.outer.gtp_v1_base.teid;
  #endif // INGRESS_PARSER_INNER_TUNNEL_INFO_OVERLOAD   
*/
//#endif
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4;
            (0, 6): parse_inner_ipv6;
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
# 2091 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.inner.ethernet.ether_type) {
            //ETHERTYPE_ARP:  parse_inner_arp;
            0x8100: parse_inner_vlan;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default : accept;
        }
    }

    state parse_inner_vlan {
        pkt.extract(hdr.inner.vlan_tag[0]);

//#ifdef INGRESS_PARSER_POPULATES_LKP_2



//#endif // INGRESS_PARSER_POPULATES_LKP_2        
# 2117 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            //ETHERTYPE_ARP:  parse_inner_arp;
            0x0800: parse_inner_ipv4;
            0x86dd: parse_inner_ipv6;
            default : accept;
        }
    }


    // ///////////////////////////////////////////////////////////////////////////
    // // Layer 2.5 - Inner
    // ///////////////////////////////////////////////////////////////////////////
    // 
    // state parse_inner_arp {
    //     // pkt.extract(hdr.inner.arp);
    //     // transition accept;
    //     transition accept;
    // }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

//     state parse_inner_ipv4 {
//         pkt.extract(hdr.inner.ipv4);
//         protocol_inner = hdr.inner.ipv4.protocol;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         // todo: should the lkp struct be set in state parse_outer_ipv4_no_options_frags instead?
// 
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV4;
// 
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV4;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv4.protocol;
//         ig_md.lkp_2.ip_tos        = hdr.inner.ipv4.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_flags      = hdr.inner.ipv4.flags;
//         ig_md.lkp_2.ip_src_addr_v4= hdr.inner.ipv4.src_addr;
//         ig_md.lkp_2.ip_dst_addr_v4= hdr.inner.ipv4.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv4.total_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
//         
//         // Flag packet (to be sent to host) if it's a frag or has options.
//         ipv4_checksum_inner.add(hdr.inner.ipv4);
//         transition select(
//             hdr.inner.ipv4.ihl,
//             hdr.inner.ipv4.frag_offset) {
//             (5, 0): parse_inner_ipv4_no_options_frags;
//             default: accept;
//         }
//     }
// 
//     state parse_inner_ipv4_no_options_frags {
//         ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
//         transition select(hdr.inner.ipv4.protocol) {
//             //IP_PROTOCOLS_ICMP: parse_inner_icmp_igmp_overload;
//             //IP_PROTOCOLS_IGMP: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
//     }

    state parse_inner_ipv4 {
        pkt.extract(hdr.inner.ipv4);
# 2197 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        // Flag packet (to be sent to host) if it's a frag or has options.
//      ipv4_checksum_inner.add(hdr.inner.ipv4);
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset) {
            (5, 0): parse_inner_ipv4_no_options_frags;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags {
        transition select(UDF_ENABLE) {
            true: parse_inner_ipv4_no_options_frags_udf;
            false: parse_inner_ipv4_no_options_frags_no_udf;
        }
    }

    state parse_inner_ipv4_no_options_frags_udf {
//      ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
        transition select(hdr.inner.ipv4.protocol, hdr.inner.ipv4.total_len) {
            (4, _): parse_inner_ipinip_set_tunnel_type;
            (41, _): parse_inner_ipv6inip_set_tunnel_type;

            (47, _): parse_inner_gre;

            (17, 20 .. (20 + 8 + (128/8)) ): parse_inner_udp_noudf;
            (17, _ ): parse_inner_udp_udf;
            (6, 20 .. (20 + 20 + (128/8)) ): parse_inner_tcp_noudf;
            (6, _ ): parse_inner_tcp_udf;
            (0x84, 20 .. (20 + 12 + (128/8))): parse_inner_sctp_noudf;
            (0x84, _ ): parse_inner_sctp_udf;
            default: accept;
        }
    }

    state parse_inner_ipv4_no_options_frags_no_udf {
//      ig_md.flags.ipv4_checksum_err_2 = ipv4_checksum_inner.verify();
        transition select(hdr.inner.ipv4.protocol) {
            4: parse_inner_ipinip_set_tunnel_type;
            41: parse_inner_ipv6inip_set_tunnel_type;

            47: parse_inner_gre;

            17: parse_inner_udp_noudf;
            6: parse_inner_tcp_noudf;
            0x84: parse_inner_sctp_noudf;
            default: accept;
        }
    }


//     state parse_inner_ipv6 {
// #ifdef IPV6_ENABLE
//         pkt.extract(hdr.inner.ipv6);
//         protocol_inner = hdr.inner.ipv6.next_hdr;
// 
// #ifdef INGRESS_PARSER_POPULATES_LKP_2
//         
//         // fixup ethertype for ip-n-ip case
//         ig_md.lkp_2.mac_type      = ETHERTYPE_IPV6;
//         
//         ig_md.lkp_2.ip_type       = SWITCH_IP_TYPE_IPV6;
//         ig_md.lkp_2.ip_proto      = hdr.inner.ipv6.next_hdr;
//         //ig_md.lkp_2.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
//         ig_md.lkp_2.ip_src_addr   = hdr.inner.ipv6.src_addr;
//         ig_md.lkp_2.ip_dst_addr   = hdr.inner.ipv6.dst_addr;
//         ig_md.lkp_2.ip_len        = hdr.inner.ipv6.payload_len;
// #endif // INGRESS_PARSER_POPULATES_LKP_2        
// 
//         transition select(hdr.inner.ipv6.next_hdr) {
//             //IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload;
//             default: branch_inner_l3_protocol;
//         }
// #else
//         transition reject;
// #endif
//     }

    state parse_inner_ipv6 {
        transition select(UDF_ENABLE) {
            true: parse_inner_ipv6_udf;
            false: parse_inner_ipv6_no_udf;
        }
    }

    state parse_inner_ipv6_udf {

        pkt.extract(hdr.inner.ipv6);
# 2298 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.inner.ipv6.next_hdr, hdr.inner.ipv6.payload_len) {
            (4, _): parse_inner_ipinip_set_tunnel_type;
            (41, _): parse_inner_ipv6inip_set_tunnel_type;

            (47, _): parse_inner_gre;

            (17, 16w0 .. ( 8 + (128/8)) ): parse_inner_udp_noudf;
            (17, _ ): parse_inner_udp_udf;
            (6, 16w0 .. ( 20 + (128/8)) ): parse_inner_tcp_noudf;
            (6, _ ): parse_inner_tcp_udf;
            (0x84, 16w0 .. ( 12 + (128/8))): parse_inner_sctp_noudf;
            (0x84, _ ): parse_inner_sctp_udf;
            default: accept;
        }



    }


    state parse_inner_ipv6_no_udf {

        pkt.extract(hdr.inner.ipv6);
# 2334 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_parser.p4"
        transition select(hdr.inner.ipv6.next_hdr) {
            4: parse_inner_ipinip_set_tunnel_type;
            41: parse_inner_ipv6inip_set_tunnel_type;

            47: parse_inner_gre;

            17: parse_inner_udp_noudf;
            6: parse_inner_tcp_noudf;
            0x84: parse_inner_sctp_noudf;
            default: accept;
        }



    }


//     // shared fanout/branch state to save tcam resource
//     state branch_inner_l3_protocol {
//         transition select(protocol_inner) {
//             IP_PROTOCOLS_UDP: parse_inner_udp;
//             IP_PROTOCOLS_TCP: parse_inner_tcp;
//             IP_PROTOCOLS_SCTP: parse_inner_sctp;
// #ifdef INNER_GRE_ENABLE
//             IP_PROTOCOLS_GRE: parse_inner_gre;
// #endif // INNER_GRE_ENABLE
//             //IP_PROTOCOLS_ESP: parse_inner_esp_overload;
//             IP_PROTOCOLS_IPV4: parse_inner_ipinip_set_tunnel_type;
//             IP_PROTOCOLS_IPV6: parse_inner_ipv6inip_set_tunnel_type;
//             default : accept;
//        }
//     }    



    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_udp_noudf {
        pkt.extract(hdr.inner.udp);




        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {


            (_, 2123): parse_inner_gtp_c;
            (2123, _): parse_inner_gtp_c;
            (_, 2152): parse_inner_gtp_u;
            (2152, _): parse_inner_gtp_u;

            default: accept;
        }
    }

    state parse_inner_udp_udf {
        pkt.extract(hdr.inner.udp);




        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {


            (_, 2123): parse_inner_gtp_c;
            (2123, _): parse_inner_gtp_c;
            (_, 2152): parse_inner_gtp_u;
            (2152, _): parse_inner_gtp_u;

            default: parse_udf;
        }
    }


    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_tcp_noudf {
        pkt.extract(hdr.inner.tcp);





        transition accept;
    }

    state parse_inner_tcp_udf {
        pkt.extract(hdr.inner.tcp);





        transition parse_udf;
    }


    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_sctp_noudf {
        pkt.extract(hdr.inner.sctp);




        transition accept;
    }

    state parse_inner_sctp_udf {
        pkt.extract(hdr.inner.sctp);




        transition parse_udf;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////


    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_type {

//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
//#endif
        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_type {

//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        ig_md.lkp_2.tunnel_id = 0;
//#endif
        transition parse_inner_inner_ipv6;



    }


    //-------------------------------------------------------------------------
    // Encapsulating Security Payload (ESP) - Inner
    //-------------------------------------------------------------------------

//     state parse_inner_esp_overload {
// #if defined(PARSER_L4_PORT_OVERLOAD) && defined(INGRESS_PARSER_POPULATES_LKP_2)
//         ig_md.lkp_2.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         ig_md.lkp_2.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif
//         transition accept;
//     }    


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------



    state parse_inner_gre {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_inner_gre_qualified;
            (1,0,0,0,0,0,0,0): parse_inner_gre_qualified;
            (0,0,1,0,0,0,0,0): parse_inner_gre_qualified;
            (0,0,0,1,0,0,0,0): parse_inner_gre_qualified;
            default: accept;
        }
    }

    state parse_inner_gre_qualified {
        pkt.extract(hdr.inner.gre);
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        ig_md.lkp_2.tunnel_id = 0;
//#endif

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.proto) {

            (0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0x86dd): parse_inner_inner_ipv6;
            (1,0,0,_): parse_inner_gre_optional;
            (0,1,0,_): parse_inner_gre_optional;
            (0,0,1,_): parse_inner_gre_optional;
            default: accept;
        }
    }

    state parse_inner_gre_optional {
        pkt.extract(hdr.inner.gre_optional);
        transition select(hdr.inner.gre.proto) {
            0x0800: parse_inner_inner_ipv4;
            0x86dd: parse_inner_inner_ipv6;
            default: accept;
        }
    }






    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Inner
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_inner_gtp_c {
        //gtp_v2_base_h snoop_inner_gtp_v2_base = pkt.lookahead<gtp_v2_base_h>();
        //transition select(
        //    snoop_inner_gtp_v2_base.version,
        //    snoop_inner_gtp_v2_base.T) {

//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_inner_gtp_c_qualified;
            default: accept;
        }
    }

    state parse_inner_gtp_c_qualified {
        //pkt.extract(hdr.inner.gtp_v2_base);
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        //ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        //ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v2_base.teid;

        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        ig_md.lkp_2.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
//#endif
        transition accept;
    }

    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;
//#endif

        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_inner_gtp_u_qualified;
            (1, 1, 0, 1, 0): parse_inner_gtp_u_with_optional;
            default: accept;
        }
    }

    state parse_inner_gtp_u_qualified {
        pkt.extract(hdr.inner.gtp_v1_base);
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
//#endif
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_gtp_u_with_optional {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
//#ifdef INGRESS_PARSER_POPULATES_LKP_2
        ig_md.lkp_2.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        ig_md.lkp_2.tunnel_id = hdr.inner.gtp_v1_base.teid;
//#endif
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
  hdr.inner_inner.ipv4.setValid();
//      ig_md.inner_inner.ipv4_isValid = true;
  transition accept;
    }
    state parse_inner_inner_ipv6 {
  hdr.inner_inner.ipv6.setValid();
//      ig_md.inner_inner.ipv6_isValid = true;
  transition accept;
    }


    ///////////////////////////////////////////////////////////////////////////
    // UDF
    ///////////////////////////////////////////////////////////////////////////

    state parse_udf {
        pkt.extract(hdr.udf);
        transition accept;
    }

    // state parse_udf {
    //     transition select(UDF_ENABLE) {
    //         true: extract_udf;
    //         false: accept;
    //     }
    // }
    // 
    // state extract_udf {
    //     pkt.extract(hdr.udf);
    //     transition accept;
    // }

}
# 58 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_set_lkp.p4" 1




// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupTransport(
 inout switch_header_transport_t hdr_0, // src
 inout switch_ingress_metadata_t ig_md // dst
) {
 // Override whatever the parser set "ip_type" to.  Doing so allows the
 // signal to fit when normally it doesn't.  This code should be only
 // temporary, and can be removed at a later date when a better compiler
 // is available....

 // Set "ip_tos here:
 //
 // ipv6: would like to do this stuff in the parser, but can't because tos
 // field isn't byte aligned...
 //
 // ipv4: would like to do this stuff in the parser, but get the following error:
 //   "error: Field is extracted in the parser into multiple containers, but
 //    the container slices after the first aren't byte aligned"

 // -----------------------------
 // Table: Hdr to Lkp
 // -----------------------------

 action set_lkp_0_type_tos_v4() {
  ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_0.ip_tos = hdr_0.ipv4.tos;
 }

 action set_lkp_0_type_tos_v6() {

  ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
  ig_md.lkp_0.ip_tos = hdr_0.ipv6.tos;

 }

 action set_lkp_0_type_tos_none() {
  ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
 }

 table set_lkp_0_type_tos {
  key = {
   hdr_0.ipv4.isValid() : exact;

   hdr_0.ipv6.isValid() : exact;

   hdr_0.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
  }

  actions = {
   NoAction;
   set_lkp_0_type_tos_v4;
   set_lkp_0_type_tos_v6;
   set_lkp_0_type_tos_none;
  }

  const entries = {

   (true, false, false) : set_lkp_0_type_tos_v4();
   (false, true, false) : set_lkp_0_type_tos_v6();
   (false, false, false) : set_lkp_0_type_tos_none();
   (true, true, false) : NoAction(); // illegal
   (true, false, true ) : set_lkp_0_type_tos_v4();
   (false, true, true ) : set_lkp_0_type_tos_v6();
   (false, false, true ) : set_lkp_0_type_tos_none();
   (true, true, true ) : NoAction(); // illegal






  }
  const default_action = NoAction;
 }

 // -----------------------------
 // Table: Lkp to Lkp
 // -----------------------------

 action set_lkp_0_next_lyr_valid_value(bool value) {
  ig_md.lkp_0.next_lyr_valid = value;
 }

 table set_lkp_0_next_lyr_valid {
  key = {
   ig_md.lkp_0.tunnel_type : exact;
  }
  actions = { set_lkp_0_next_lyr_valid_value; }
  const entries = {
   (SWITCH_TUNNEL_TYPE_NONE) : set_lkp_0_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_VXLAN) : set_lkp_0_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP) : set_lkp_0_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_GTPC) : set_lkp_0_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_0_next_lyr_valid_value(false);
  }
  const default_action = set_lkp_0_next_lyr_valid_value(true);
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
/*
		if     (hdr_0.ipv4.isValid()) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV4;
#if defined(GRE_TRANSPORT_INGRESS_ENABLE_V6) || defined(ERSPAN_TRANSPORT_INGRESS_ENABLE_V6)
		} else if(hdr_0.ipv6.isValid()) {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_0.ip_tos = hdr_0.ipv6.tos;
#endif
		} else {
			ig_md.lkp_0.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
  set_lkp_0_type_tos.apply();

  // -----------------------------------------------------------------------

//		ig_md.lkp_0.next_lyr_valid = true;
/*
		if((ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_0.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_0.next_lyr_valid = true;
		} else {
			ig_md.lkp_0.next_lyr_valid = false;
		}
*/
  set_lkp_0_next_lyr_valid.apply();

 }
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupOuter(
 inout switch_header_outer_t hdr_1, // src
 inout switch_ingress_metadata_t ig_md // dst
) {
 // Override whatever the parser set "ip_type" to.  Doing so allows the
 // signal to fit when normally it doesn't.  This code should be only
 // temporary, and can be removed at a later date when a better compiler
 // is available....

 // Set "ip_tos here:
 //
 // ipv6: would like to do this stuff in the parser, but can't because tos
 // field isn't byte aligned...
 //
 // ipv4: would like to do this stuff in the parser, but get the following error:
 //   "error: Field is extracted in the parser into multiple containers, but
 //    the container slices after the first aren't byte aligned"

 // -----------------------------
 // Table: Hdr to Lkp
 // -----------------------------

 action set_lkp_1_type_tos_v4() {
  ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_1.ip_tos = hdr_1.ipv4.tos;
 }

 action set_lkp_1_type_tos_v6() {

  ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
  ig_md.lkp_1.ip_tos = hdr_1.ipv6.tos;

 }

 action set_lkp_1_type_tos_none() {
  ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
 }

 table set_lkp_1_type_tos {
  key = {
   hdr_1.ipv4.isValid() : exact;

   hdr_1.ipv6.isValid() : exact;

   hdr_1.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
  }

  actions = {
   NoAction;
   set_lkp_1_type_tos_v4;
   set_lkp_1_type_tos_v6;
   set_lkp_1_type_tos_none;
  }

  const entries = {

   (true, false, false) : set_lkp_1_type_tos_v4();
   (false, true, false) : set_lkp_1_type_tos_v6();
   (false, false, false) : set_lkp_1_type_tos_none();
   (true, true, false) : NoAction(); // illegal
   (true, false, true ) : set_lkp_1_type_tos_v4();
   (false, true, true ) : set_lkp_1_type_tos_v6();
   (false, false, true ) : set_lkp_1_type_tos_none();
   (true, true, true ) : NoAction(); // illegal






  }
  const default_action = NoAction;
 }

 // -----------------------------
 // Table: Lkp to Lkp
 // -----------------------------

 action set_lkp_1_next_lyr_valid_value(bool value) {
  ig_md.lkp_1.next_lyr_valid = value;
 }

 table set_lkp_1_next_lyr_valid {
  key = {
   ig_md.lkp_1.tunnel_type : exact;
  }
  actions = { set_lkp_1_next_lyr_valid_value; }
  const entries = {
   (SWITCH_TUNNEL_TYPE_NONE) : set_lkp_1_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_VXLAN) : set_lkp_1_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP) : set_lkp_1_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_GTPC) : set_lkp_1_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_1_next_lyr_valid_value(false);
  }
  const default_action = set_lkp_1_next_lyr_valid_value(true);
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
/*
		if     (hdr_1.ipv4.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
#ifdef IPV6_ENABLE
		}else if(hdr_1.ipv6.isValid()) {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
#endif
		} else {
			ig_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
  set_lkp_1_type_tos.apply();

  // -----------------------------------------------------------------------

/*
//		ig_md.lkp_1.next_lyr_valid = true;
		if((ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_1.next_lyr_valid = true;
		} else {
			ig_md.lkp_1.next_lyr_valid = false;
		}
*/
  set_lkp_1_next_lyr_valid.apply();

 }
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookupInner(
 inout switch_header_inner_t hdr_2, // src
 inout switch_ingress_metadata_t ig_md // dst
) {

 // Override whatever the parser set "ip_type" to.  Doing so allows the
 // signal to fit when normally it doesn't.  This code should be only
 // temporary, and can be removed at a later date when a better compiler
 // is available....

 // Set "ip_tos here:
 //
 // ipv6: would like to do this stuff in the parser, but can't because tos
 // field isn't byte aligned...
 //
 // ipv4: would like to do this stuff in the parser, but get the following error:
 //   "error: Field is extracted in the parser into multiple containers, but
 //    the container slices after the first aren't byte aligned"

 // -----------------------------
 // Table: Hdr to Lkp
 // -----------------------------

 action set_lkp_2_type_tos_v4() {
  ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
//		ig_md.lkp_2.ip_tos = hdr_2.ipv4.tos;
 }

 action set_lkp_2_type_tos_v6() {

  ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
  ig_md.lkp_2.ip_tos = hdr_2.ipv6.tos;

 }

 action set_lkp_2_type_tos_none() {
  ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
 }

 table set_lkp_2_type_tos {
  key = {
   hdr_2.ipv4.isValid() : exact;

   hdr_2.ipv6.isValid() : exact;

   hdr_2.udp.isValid() : exact; // dummy key, to get around barefoot table with less than 4 entries issue
  }

  actions = {
   NoAction;
   set_lkp_2_type_tos_v4;
   set_lkp_2_type_tos_v6;
   set_lkp_2_type_tos_none;
  }

  const entries = {

   (true, false, false) : set_lkp_2_type_tos_v4();
   (false, true, false) : set_lkp_2_type_tos_v6();
   (false, false, false) : set_lkp_2_type_tos_none();
   (true, true, false) : NoAction(); // illegal
   (true, false, true ) : set_lkp_2_type_tos_v4();
   (false, true, true ) : set_lkp_2_type_tos_v6();
   (false, false, true ) : set_lkp_2_type_tos_none();
   (true, true, true ) : NoAction(); // illegal






  }
  const default_action = NoAction;
 }

 // -----------------------------
 // Table: Lkp to Lkp
 // -----------------------------

 action set_lkp_2_next_lyr_valid_value(bool value) {
  ig_md.lkp_2.next_lyr_valid = value;
 }

 table set_lkp_2_next_lyr_valid {
  key = {
   ig_md.lkp_2.tunnel_type : exact;
  }
  actions = { set_lkp_2_next_lyr_valid_value; }
  const entries = {
   (SWITCH_TUNNEL_TYPE_NONE) : set_lkp_2_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_VXLAN) : set_lkp_2_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP) : set_lkp_2_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_GTPC) : set_lkp_2_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_2_next_lyr_valid_value(false);
  }
  const default_action = set_lkp_2_next_lyr_valid_value(true);
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {
/*
		if     (hdr_2.ipv4.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV4;
#ifdef IPV6_ENABLE
		} else if(hdr_2.ipv6.isValid()) {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_IPV6;
			ig_md.lkp_2.ip_tos = hdr_2.ipv6.tos;
#endif
		} else {
			ig_md.lkp_2.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
  set_lkp_2_type_tos.apply();

  // -----------------------------------------------------------------------

//		ig_md.lkp_2.next_lyr_valid = true;
/*
		if((ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (ig_md.lkp_2.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			ig_md.lkp_2.next_lyr_valid = true;
		} else {
			ig_md.lkp_2.next_lyr_valid = false;
		}
*/
  set_lkp_2_next_lyr_valid.apply();

 }
}

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control IngressSetLookup(
 inout switch_header_t hdr, // src
 inout switch_ingress_metadata_t ig_md // dst
) {
 apply {
        // This is for the special ipv4 / udp / vxlan case.
        // When we attempt to do this in the parser, unrelated parser tests start failing.
        if(ig_md.flags.outer_enet_in_transport == true) {
//          hdr.outer.ethernet = {
//              dst_addr   = hdr_transport.ethernet.dst_addr,
//              src_addr   = hdr_transport.ethernet.src_addr,
//              ether_type = hdr_transport.ethernet.ether_type
//			};

//          hdr.outer.ethernet.dst_addr   = hdr.transport.ethernet.dst_addr;
//          hdr.outer.ethernet.src_addr   = hdr.transport.ethernet.src_addr;
            hdr.outer.ethernet.ether_type = hdr.transport.ethernet.ether_type;
            hdr.transport.ethernet.setInvalid();
  }

  // -----------------------------------------------------------------------


  IngressSetLookupTransport.apply(hdr.transport, ig_md); // set lookup structure fields that parser couldn't


  IngressSetLookupOuter.apply (hdr.outer, ig_md); // set lookup structure fields that parser couldn't





 }
}
# 59 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4" 1



control IngressHdrStackCounters(
    in switch_header_t hdr
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {


    DirectCounter<bit<32>>(CounterType_t.PACKETS) cpu_hdr_cntrs;

    DirectCounter<bit<32>>(CounterType_t.PACKETS) transport_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) outer_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_stack_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) udf_hdr_cntrs;



    // ------------------------------------------------------------
    // CPU Header -------------------------------------------------
    // ------------------------------------------------------------

    action bump_cpu_hdr_cntr() {
        cpu_hdr_cntrs.count();
    }

    table cpu_hdr_cntr_tbl {
        key = {
            hdr.cpu.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_cpu_hdr_cntr;
        }

        size = 2;
        // todo: does setting this as default option give us an "unexpected counter"
        // const default_action = bump_cpu_hdr_cntr;
        counters = cpu_hdr_cntrs;

//         // Cannot have constant entries if we're going to clear counters in our test.
//         const entries = {
//             false: bump_cpu_hdr_cntr; 
//             true:  bump_cpu_hdr_cntr; 
//         }
    }




    // ------------------------------------------------------------
    // transport stack --------------------------------------------
    // ------------------------------------------------------------

    bool hdr_transport_ethernet_isValid;
    bool hdr_transport_vlan_tag_0_isValid;
    bool hdr_transport_nsh_type1_isValid;
    bool hdr_transport_mpls_0_isValid;
    bool hdr_transport_mpls_1_isValid;
    bool hdr_transport_mpls_2_isValid;
    bool hdr_transport_mpls_3_isValid;
    bool hdr_transport_ipv4_isValid;
    bool hdr_transport_ipv6_isValid;
    bool hdr_transport_gre_isValid;
    bool hdr_transport_gre_sequence_isValid;
    bool hdr_transport_erspan_type2_isValid;
    bool hdr_transport_udp_isValid;
    bool hdr_transport_geneve_isValid;
    bool hdr_transport_vxlan_isValid;

    action bump_transport_stack_hdr_cntr() {
        transport_stack_hdr_cntrs.count();
    }

    table transport_stack_hdr_cntr_tbl {
        key = {
            hdr_transport_ethernet_isValid: exact;
            hdr_transport_vlan_tag_0_isValid: exact;
            hdr_transport_nsh_type1_isValid: exact;
            hdr_transport_mpls_0_isValid: exact;
            hdr_transport_mpls_1_isValid: exact;
            hdr_transport_mpls_2_isValid: exact;
            hdr_transport_mpls_3_isValid: exact;
            hdr_transport_ipv4_isValid: exact;
            hdr_transport_ipv6_isValid: exact;
            hdr_transport_gre_isValid: exact;
            hdr_transport_gre_sequence_isValid: exact;
            hdr_transport_erspan_type2_isValid: exact;
            hdr_transport_udp_isValid: exact;
            hdr_transport_geneve_isValid: exact;
            hdr_transport_vxlan_isValid: exact;
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_transport_stack_hdr_cntr;
        }
        counters = transport_stack_hdr_cntrs;
        size = 32; // Little slop built-in here

    }


    // ------------------------------------------------------------
    // outer stack --------------------------------------------
    // ------------------------------------------------------------

    bool hdr_outer_ethernet_isValid;
    bool hdr_outer_e_tag_isValid;
    bool hdr_outer_vn_tag_isValid;
    bool hdr_outer_vlan_tag_0_isValid;
    bool hdr_outer_vlan_tag_1_isValid;
    bool hdr_outer_mpls_0_isValid;
    bool hdr_outer_mpls_1_isValid;
    bool hdr_outer_mpls_2_isValid;
    bool hdr_outer_mpls_3_isValid;
    bool hdr_outer_mpls_pw_cw_isValid;
    bool hdr_outer_ipv4_isValid;
    bool hdr_outer_ipv6_isValid;
    bool hdr_outer_udp_isValid;
    bool hdr_outer_tcp_isValid;
    bool hdr_outer_sctp_isValid;
    bool hdr_outer_gre_isValid;
    bool hdr_outer_gre_optional_isValid;
    bool hdr_outer_geneve_isValid;
    bool hdr_outer_vxlan_isValid;
    bool hdr_outer_nvgre_isValid;
    bool hdr_outer_gtp_v1_base_isValid;
    bool hdr_outer_gtp_v1_optional_isValid;


    action bump_outer_stack_hdr_cntr() {
        outer_stack_hdr_cntrs.count();
    }

    table outer_stack_hdr_cntr_tbl {
        key = {
            hdr_outer_ethernet_isValid: exact;
            hdr_outer_e_tag_isValid: exact;
            hdr_outer_vn_tag_isValid: exact;
            hdr_outer_vlan_tag_0_isValid: exact;
            hdr_outer_vlan_tag_1_isValid: exact;
            hdr_outer_mpls_0_isValid: exact;
            hdr_outer_mpls_1_isValid: exact;
            hdr_outer_mpls_2_isValid: exact;
            hdr_outer_mpls_3_isValid: exact;
            hdr_outer_mpls_pw_cw_isValid: exact;
            hdr_outer_ipv4_isValid: exact;
            hdr_outer_ipv6_isValid: exact;
            hdr_outer_udp_isValid: exact;
            hdr_outer_tcp_isValid: exact;
            hdr_outer_sctp_isValid: exact;
            hdr_outer_gre_isValid: exact;
            hdr_outer_gre_optional_isValid: exact;
            hdr_outer_geneve_isValid: exact;
            hdr_outer_vxlan_isValid: exact;
            hdr_outer_nvgre_isValid: exact;
            hdr_outer_gtp_v1_base_isValid: exact;
            hdr_outer_gtp_v1_optional_isValid: exact;
        }

        actions = {
            //NoAction;
            bump_outer_stack_hdr_cntr;
        }

        counters = outer_stack_hdr_cntrs;
        size = 512; // There is a little slop built-in here
    }


    // ------------------------------------------------------------
    // inner stack ------------------------------------------------
    // ------------------------------------------------------------

    bool hdr_inner_gre_isValid;
    bool hdr_inner_gre_optional_isValid;
    bool hdr_inner_gtp_v1_base_isValid;
    bool hdr_inner_gtp_v1_optional_isValid;


    action bump_inner_stack_hdr_cntr() {
        inner_stack_hdr_cntrs.count();
    }

    table inner_stack_hdr_cntr_tbl {
        key = {

            hdr.inner.ethernet.isValid(): exact;
            hdr.inner.vlan_tag[0].isValid(): exact;

            hdr.inner.ipv4.isValid(): exact;
            hdr.inner.ipv6.isValid(): exact;

            hdr.inner.udp.isValid(): exact;
            hdr.inner.tcp.isValid(): exact;
            hdr.inner.sctp.isValid(): exact;

            hdr_inner_gre_isValid: exact;
            hdr_inner_gre_optional_isValid: exact;

            hdr_inner_gtp_v1_base_isValid: exact;
            hdr_inner_gtp_v1_optional_isValid: exact;
        }

        actions = {
            //NoAction;
            bump_inner_stack_hdr_cntr;
        }

        counters = inner_stack_hdr_cntrs;
        size = 64; // There is some slop built-in here
    }



    // ------------------------------------------------------------
    // Layer7 UDF -------------------------------------------------
    // ------------------------------------------------------------

    action bump_udf_hdr_cntr() {
        udf_hdr_cntrs.count();
    }

    table udf_hdr_cntr_tbl {
        key = {
            hdr.udf.isValid(): exact;
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_udf_hdr_cntr;
        }

        size = 2;
        counters = udf_hdr_cntrs;
    }



    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {

        // ------------------------------------------------------------
        // Transport

        hdr_transport_ethernet_isValid = hdr.transport.ethernet.isValid();
        hdr_transport_vlan_tag_0_isValid = hdr.transport.vlan_tag[0].isValid();
        hdr_transport_nsh_type1_isValid = hdr.transport.nsh_type1.isValid();


        hdr_transport_mpls_0_isValid = hdr.transport.mpls[0].isValid();

        hdr_transport_mpls_1_isValid = hdr.transport.mpls[1].isValid();




        hdr_transport_mpls_2_isValid = hdr.transport.mpls[2].isValid();




        hdr_transport_mpls_3_isValid = hdr.transport.mpls[3].isValid();
# 286 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4"
        hdr_transport_ipv4_isValid = hdr.transport.ipv4.isValid();
# 296 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4"
        hdr_transport_ipv6_isValid = hdr.transport.ipv6.isValid();
# 307 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4"
            hdr_transport_gre_isValid = hdr.transport.gre.isValid();
# 318 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4"
            hdr_transport_gre_sequence_isValid = hdr.transport.gre_sequence.isValid();
            hdr_transport_erspan_type2_isValid = hdr.transport.erspan_type2.isValid();
# 329 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4"
            hdr_transport_udp_isValid = hdr.transport.udp.isValid();
# 339 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_hdr_stack_counters.p4"
            hdr_transport_geneve_isValid = false;



            hdr_transport_vxlan_isValid = hdr.transport.vxlan.isValid();






        // ------------------------------------------------------------
        // Outer

        hdr_outer_ethernet_isValid = hdr.outer.ethernet.isValid();

        if(OUTER_ETAG_ENABLE) {
            hdr_outer_e_tag_isValid = hdr.outer.e_tag.isValid();
        } else {
            hdr_outer_e_tag_isValid = false;
        }

        if(OUTER_VNTAG_ENABLE) {
            hdr_outer_vn_tag_isValid = hdr.outer.vn_tag.isValid();
        } else {
            hdr_outer_vn_tag_isValid = false;
        }

        hdr_outer_vlan_tag_0_isValid = hdr.outer.vlan_tag[0].isValid();
        hdr_outer_vlan_tag_1_isValid = hdr.outer.vlan_tag[1].isValid();







        hdr_outer_mpls_0_isValid = false;
        hdr_outer_mpls_1_isValid = false;
        hdr_outer_mpls_2_isValid = false;
        hdr_outer_mpls_3_isValid = false;





        hdr_outer_mpls_pw_cw_isValid = false;


        hdr_outer_ipv4_isValid = hdr.outer.ipv4.isValid();
        hdr_outer_ipv6_isValid = hdr.outer.ipv6.isValid();
        hdr_outer_udp_isValid = hdr.outer.udp.isValid();
        hdr_outer_tcp_isValid = hdr.outer.tcp.isValid();
        hdr_outer_sctp_isValid = hdr.outer.sctp.isValid();


        //if(OUTER_GRE_ENABLE || OUTER_NVGRE_ENABLE) {
            hdr_outer_gre_isValid = hdr.outer.gre.isValid();
            hdr_outer_gre_optional_isValid = hdr.outer.gre_optional.isValid();





        //}

        if(OUTER_GENEVE_ENABLE) {
            hdr_outer_geneve_isValid = hdr.outer.geneve.isValid();
        } else {
            hdr_outer_geneve_isValid = false;
        }

        if(OUTER_VXLAN_ENABLE) {
            hdr_outer_vxlan_isValid = hdr.outer.vxlan.isValid();
        } else {
            hdr_outer_vxlan_isValid = false;
        }

        if(OUTER_NVGRE_ENABLE) {
            hdr_outer_nvgre_isValid = hdr.outer.nvgre.isValid();
        } else {
            hdr_outer_nvgre_isValid = false;
        }


        hdr_outer_gtp_v1_base_isValid = hdr.outer.gtp_v1_base.isValid();
        hdr_outer_gtp_v1_optional_isValid = hdr.outer.gtp_v1_optional.isValid();







        // ------------------------------------------------------------
        // Inner


        hdr_inner_gre_isValid = hdr.inner.gre.isValid();
        hdr_inner_gre_optional_isValid = hdr.inner.gre_optional.isValid();





        hdr_inner_gtp_v1_base_isValid = hdr.inner.gtp_v1_base.isValid();
        hdr_inner_gtp_v1_optional_isValid = hdr.inner.gtp_v1_optional.isValid();







        // ------------------------------------------------------------
        // Tables

        cpu_hdr_cntr_tbl.apply();

        transport_stack_hdr_cntr_tbl.apply();
        outer_stack_hdr_cntr_tbl.apply();
        inner_stack_hdr_cntr_tbl.apply();

        if(UDF_ENABLE) {
            udf_hdr_cntr_tbl.apply();
        }
    }
}
# 60 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4" 1




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sfc_top.p4" 1




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/tunnel.p4" 1
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
# 6 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sfc_top.p4" 2





control Npb_Ing_Sfc_Top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536,
 switch_uint32_t port_table_size=288
) {

 bool scope_flag = false;
 bool term_flag = false;


 IngressTunnel(
  IPV4_SRC_TUNNEL_TABLE_SIZE, IPV6_SRC_TUNNEL_TABLE_SIZE,
  IPV4_DST_TUNNEL_TABLE_SIZE, IPV6_DST_TUNNEL_TABLE_SIZE
 ) tunnel_transport;
# 48 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sfc_top.p4"
//	IngressTunnelInner(NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;
 IngressTunnelOuter(NPB_ING_SFC_TUNNEL_INNER_EXM_TABLE_DEPTH, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH) tunnel_inner;


 Scoper_Hdr1_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr1_to_lkp;



 Scoper_Scope_And_Term_Only(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_scope_and_term_only;
 Scoper_Hdr2_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr2_to_lkp;

 // =========================================================================
 // W/  NSH... Table #0a:
 // =========================================================================


 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 action ing_sfc_sf_sel_hit(
  bit<8> si_predec
 ) {
  stats.count();

  ig_md.nsh_md.si_predec = si_predec;
 }

 // ---------------------------------

 action ing_sfc_sf_sel_miss(
 ) {
  stats.count();

//		ig_md.nsh_md.si_predec  = 0;
  ig_md.nsh_md.si_predec = ig_md.nsh_md.si;
 }

 // ---------------------------------

 table ing_sfc_sf_sel {
  key = {
   ig_md.nsh_md.spi : exact @name("spi");
   ig_md.nsh_md.si : exact @name("si");
  }

  actions = {
   ing_sfc_sf_sel_hit;
   ing_sfc_sf_sel_miss;
  }

  const default_action = ing_sfc_sf_sel_miss;
  size = NPB_ING_SFC_SF_SEL_TABLE_DEPTH;
  counters = stats;
 }

 // =========================================================================
 // W/  NSH... Table #0b:
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_nsh_xlate; // direct counter

 action ing_sfc_sf_sel_nsh_xlate_hit(
  bit<6> ttl,
  bit<24> spi,
  bit<8> si,
  bit<8> si_predec
 ) {
  stats_nsh_xlate.count();

  ig_md.nsh_md.ttl = ttl;
  ig_md.nsh_md.spi = spi;
  ig_md.nsh_md.si = si;
  ig_md.nsh_md.si_predec = si_predec;

  ig_md.nsh_md.ver = 0x2;
 }

 // ---------------------------------

 action ing_sfc_sf_sel_nsh_xlate_miss(
 ) {
  stats_nsh_xlate.count();

  ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
 }

 // ---------------------------------

 table ing_sfc_sf_sel_nsh_xlate {
  key = {
   ig_md.nsh_md.spi : exact @name("tool_address");
  }

  actions = {
   ing_sfc_sf_sel_nsh_xlate_hit;
   ing_sfc_sf_sel_nsh_xlate_miss;
  }

  const default_action = ing_sfc_sf_sel_nsh_xlate_miss;
  size = NPB_ING_SFC_SF_SEL_NSH_XLATE_TABLE_DEPTH;
  counters = stats_nsh_xlate;
 }

 // =========================================================================
 // W/O NSH... Table #0:
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_port_mapping; // direct counter

 action set_port_properties(
  bit<8> si_predec,

  bit<16> sap,
  bit<16> vpn,
  bit<24> spi,
  bit<8> si
 ) {
  stats_port_mapping.count();

  ig_md.nsh_md.si_predec = si_predec; //  8 bits

  ig_md.nsh_md.sap = (bit<16>)sap; // 16 bits
  ig_md.nsh_md.vpn = (bit<16>)vpn; // 16 bits
  ig_md.nsh_md.spi = spi; // 24 bits
  ig_md.nsh_md.si = si; //  8 bits
 }

 // ---------------------------------

 action no_action(
 ) {
  stats_port_mapping.count();

 }

 // ---------------------------------

 table port_mapping {
  key = {
   ig_md.port : exact @name("port");
//			ig_md.port_lag_index : exact @name("port_lag_index");
  }

  actions = {
   no_action;
   set_port_properties;
  }

  const default_action = no_action;
  size = port_table_size;
  counters = stats_port_mapping;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // ---------------------------------------------------------------------
  // Classify
  // ---------------------------------------------------------------------

  // -----------------------------------------------------------------------------------------------------
  // | transport  | transport |
  // | nsh valid  | eth valid | result
  // +------------+-----------+----------------
  // | 1          | x         | internal  fabric -> sfc no tables...instead grab fields from nsh header
  // | 0          | 1         | normally  tapped -> sfc transport table, sap mapping table, inner table
  // | 0          | 0         | optically tapped -> sfc outer     table,                    inner table
  // -----------------------------------------------------------------------------------------------------

  if(hdr_0.nsh_type1.isValid()) {

   // -----------------------------------------------------------------
   // Packet does    have a NSH header on it (is already classified)
   // -----------------------------------------------------------------

   // ----- metadata -----
//			ig_md.nsh_md.start_of_path = false;
//			ig_md.nsh_md.sfc_enable    = false;

   // ----- table -----

   if(ig_md.nsh_md.ver == 2) {

    // get predecremented si
    ing_sfc_sf_sel.apply();

   } else {
    // xlate, get predecremented si
    ing_sfc_sf_sel_nsh_xlate.apply();
   }






   // ---- advance data to match incoming scope value ----
/*
#ifdef INGRESS_MAU_NO_LKP_1
			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_0);
#else
			scoper_lkp_to_lkp.apply(ig_md.lkp_1, ig_md.lkp_0);
#endif
*/
//			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_1);

   // ---- advance data to match incoming scope value ----
/*
			Scoper_Data_Only.apply(
				ig_md.lkp_0,
//				ig_md.lkp_1,
				ig_md.lkp_2,
    
				hdr_1,
				hdr_2,
				hdr_3,

				ig_md.nsh_md.scope,
				ig_md.lkp_1
			);
*/
   if(ig_md.nsh_md.scope == 2) {
    scope_flag = true;
   }
  } else {

   // -----------------------------------------------------------------
   // Packet doesn't have a NSH header on it -- add it (needs classification)
   // -----------------------------------------------------------------

   // ----- metadata -----
//			ig_md.nsh_md.start_of_path = true;  // * see design note below
//			ig_md.nsh_md.sfc_enable    = false; // * see design note below

   ig_md.nsh_md.ttl = 0x00; // 63 is the rfc's recommended default value.

   // ----- header -----
/*
			// note: according to p4 spec, initializing a header also automatically sets it valid.
//			ig_md.nsh_md.setValid();
			ig_md.nsh_md = {
				version    = 0x0,
				o          = 0x0,
				reserved   = 0x0,
				ttl        = 0x00, // 63 is the rfc's recommended default value (0 will get dec'ed to 63).
				len        = 0x6,  // in 4-byte words (1 + 1 + 4).
				reserved2  = 0x0,
				md_type    = 0x1,  // 0 = reserved, 1 = fixed len, 2 = variable len.
				next_proto = NSH_PROTOCOLS_ETH, // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

				spi        = 0x0,
				si         = 0x0,

				ver        = 0x2,
				reserved3  = 0x0,
				lag_hash   = 0x0,

				vpn        = 0x0,
				sfc_data   = 0x0,

				reserved4  = 0x0,
				scope      = 0x0,
				sap        = 0x0,

#ifdef SFC_TIMESTAMP_ENABLE
				timestamp = ig_md.timestamp[31:0]
#else
				timestamp = 0
#endif
			};
*/

   // ----- table -----
   port_mapping.apply();

   // -----------------------------------------------------------------

   if(hdr_0.ethernet.isValid()) {
//			if(ig_md.flags.transport_valid == true) {

    // ---------------------------
    // ----- Normally Tapped -----
    // ---------------------------


    tunnel_transport.apply(
     ig_md,
     hdr_0,
     ig_md.lkp_0,
     tunnel_0,
     ig_intr_md_for_dprsr
    );
# 354 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sfc_top.p4"
   } else {

    // ----------------------------
    // ----- Optically Tapped -----
    // ----------------------------

    // -----------------------
    // Outer SAP
    // -----------------------
# 373 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sfc_top.p4"
   }

   // always terminate transport headers
   tunnel_0.terminate = true;
   ig_md.nsh_md.scope = 1;
/*
#ifdef INGRESS_MAU_NO_LKP_1
			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_0);
#else
			scoper_lkp_to_lkp.apply(ig_md.lkp_1, ig_md.lkp_0);
#endif
*/
//			scoper_hdr1_to_lkp.apply(hdr_1, hdr_2, ig_md.lkp_1, ig_md.tunnel_1.unsupported_tunnel, ig_md.lkp_1);

   // -----------------------
   // Inner SAP
   // -----------------------
   tunnel_inner.apply(
    ig_md,
    ig_md.lkp_1,
    ig_intr_md_for_dprsr,

    scope_flag,
    term_flag
   );
/*
			Scoper_ScopeAndTermAndData.apply(
				ig_md.lkp_0,
//				ig_md.lkp_1,
				ig_md.lkp_2,

				hdr_1,
				hdr_2,
				hdr_3,

				ig_md.lkp_1,

				term_flag,
				scope_flag,
				ig_md.nsh_md.scope,

				ig_md.tunnel_0.terminate,
				ig_md.tunnel_1.terminate,
				ig_md.tunnel_2.terminate
			);
*/
   scoper_scope_and_term_only.apply(
    ig_md.lkp_1,

    term_flag,
    scope_flag,
    ig_md.nsh_md.scope,

    ig_md.tunnel_0.terminate,
    ig_md.tunnel_1.terminate,
    ig_md.tunnel_2.terminate
   );

  }


  if(scope_flag && ig_md.lkp_1.next_lyr_valid) {
   scoper_hdr2_to_lkp.apply(hdr_2, hdr_3, ig_md.lkp_2, ig_md.tunnel_2.unsupported_tunnel, ig_md.lkp_1);
  }
 }
}
# 6 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_top.p4" 1



//#include "npb_ing_sf_npb_basic_adv_acl.p4"
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_sfp_sel.p4" 1




// =============================================================================
// SF #0 - SFP Hash
// =============================================================================

control Npb_Ing_Sf_Npb_Basic_Adv_Sfp_Hash (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,

 in bit<16> mac_type,
 in bit<8> ip_proto,
 in bit<16> l4_src_port,
 in bit<16> l4_dst_port,
 out bit<16> hash
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 // =========================================================================
 // Table #1 (main lkp struct):
 // =========================================================================

 bit<10> flow_class_internal = 0;

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 action ing_flow_class_hit (
  bit<10> flow_class
 ) {
  // ----- change nsh -----

  // change metadata
  flow_class_internal = flow_class;

  stats.count();
 }

 // ---------------------------------

 action no_action (
 ) {
  stats.count();
 }

 // ---------------------------------

 table ing_flow_class {
  key = {
   ig_md.nsh_md.vpn : ternary @name("vpn");
   mac_type : ternary @name("mac_type");
   ip_proto : ternary @name("ip_proto");
   l4_src_port : ternary @name("l4_src_port");
   l4_dst_port : ternary @name("l4_dst_port");
  }

  actions = {
   no_action;
   ing_flow_class_hit;
  }

  const default_action = no_action;
  counters = stats;
  size = NPB_ING_SF_0_SFP_FLW_CLS_TABLE_DEPTH;
 }

 // =========================================================================
 // Hash #1 (main lkp struct):
 // =========================================================================

//	Hash<bit<32>>(HashAlgorithm_t.CRC32) hash_func;
//	Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;
 Hash<bit<16>>(HashAlgorithm_t.CRC16) hash_func;

 action compute_hash(
 ) {
  hash = hash_func.get({
   ig_md.nsh_md.vpn,
   flow_class_internal
  });
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  ing_flow_class.apply();
  compute_hash();
 }
}

// =============================================================================
// SF #0 - SFP Select
// =============================================================================

control Npb_Ing_Sf_Npb_Basic_Adv_Sfp_Sel (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // =========================================================================
 // Table #1: Action Selector
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;



 // Use just a plain old table...
# 168 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_sfp_sel.p4"
 // ---------------------------------

 action ing_schd_hit (
  bit<24> spi,
  bit<8> si,

  bit<8> si_predec
 ) {
  ig_md.nsh_md.spi = spi;
  ig_md.nsh_md.si = si;

  // change metadata
  ig_md.nsh_md.si_predec = si_predec;

  stats.count();
 }

 // ---------------------------------

 action no_action (
 ) {
  stats.count();
 }

 // ---------------------------------

 table ing_schd {
  key = {
   ig_md.nsh_md.sfc : exact @name("sfc");





  }

  actions = {
   no_action;
   ing_schd_hit;
  }

  const default_action = no_action;
  counters = stats;
  size = NPB_ING_SF_0_SFP_SCHD_TABLE_SIZE;



 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  if(ig_md.nsh_md.sfc_enable == true) {
   ing_schd.apply();
  }
 }

}
# 6 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_top.p4" 2




control Npb_Ing_Sf_Npb_Basic_Adv_Top (
 inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_header_inner_t hdr_2,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 IngressAcl(
  TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE,



  INGRESS_IPV4_ACL_TABLE_SIZE,
  INGRESS_IPV6_ACL_TABLE_SIZE,

  INGRESS_MAC_ACL_TABLE_SIZE,
  INGRESS_L7_ACL_TABLE_SIZE
 ) acl;





 // =========================================================================
 // Table #1: SFF Action Select
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 bit<8> int_ctrl_flags = 0;

 action ing_sf_action_sel_hit(



 ) {
  stats.count();




 }

 // =====================================

 action ing_sf_action_sel_miss(
 ) {
  stats.count();

 }

 // =====================================

 table ing_sf_action_sel {
  key = {
   ig_md.nsh_md.spi : exact @name("spi");
   ig_md.nsh_md.si : exact @name("si");
  }

  actions = {
   ing_sf_action_sel_hit;
   ing_sf_action_sel_miss;
  }

  const default_action = ing_sf_action_sel_miss;
  size = NPB_ING_SF_0_BAS_ADV_SFF_TABLE_DEPTH;
  counters = stats;
 }

 // =========================================================================
 // Table #2: SF IP Length Range
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ip_len; // direct counter

 bit<8> ip_len_rng = 0;


 action ing_sf_ip_len_rng_hit(
  bit<8> rng_bitmask
 ) {
  stats_ip_len.count();

  ip_len_rng = rng_bitmask;
 }

 // =====================================

 action ing_sf_ip_len_rng_miss(
 ) {
  stats_ip_len.count();
 }

 // =====================================

 table ing_sf_ip_len_rng {
  key = {
   lkp.ip_len : range @name("ip_len");
  }

  actions = {
//			NoAction;
   ing_sf_ip_len_rng_hit;
   ing_sf_ip_len_rng_miss;
  }

  const default_action = ing_sf_ip_len_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L3_LEN_RNG_TABLE_DEPTH;
  counters = stats_ip_len;
 }


 // =========================================================================
 // Table #3: SF L4 Src Port Range
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_l4_src_port; // direct counter

 bit<8> l4_src_port_rng = 0;


 action ing_sf_l4_src_port_rng_hit(
  bit<8> rng_bitmask
 ) {
  stats_l4_src_port.count();

  l4_src_port_rng = rng_bitmask;
 }

 // =====================================

 action ing_sf_l4_src_port_rng_miss(
 ) {
  stats_l4_src_port.count();
 }

 // =====================================

 table ing_sf_l4_src_port_rng {
  key = {
   lkp.l4_src_port : range @name("l4_src_port");
  }

  actions = {
//			NoAction;
   ing_sf_l4_src_port_rng_hit;
   ing_sf_l4_src_port_rng_miss;
  }

  const default_action = ing_sf_l4_src_port_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_SRC_RNG_TABLE_DEPTH;
  counters = stats_l4_src_port;
 }


 // =========================================================================
 // Table #4: SF L4 Dst Port Range
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_l4_dst_port; // direct counter

 bit<8> l4_dst_port_rng = 0;


 action ing_sf_l4_dst_port_rng_hit(
  bit<8> rng_bitmask
 ) {
  stats_l4_dst_port.count();

  l4_dst_port_rng = rng_bitmask;
 }

 // =====================================

 action ing_sf_l4_dst_port_rng_miss(
 ) {
  stats_l4_dst_port.count();
 }

 // =====================================

 table ing_sf_l4_dst_port_rng {
  key = {
   lkp.l4_dst_port : range @name("l4_dst_port");
  }

  actions = {
//			NoAction;
   ing_sf_l4_dst_port_rng_hit;
   ing_sf_l4_dst_port_rng_miss;
  }

  const default_action = ing_sf_l4_dst_port_rng_miss;
  size = NPB_ING_SF_0_BAS_ADV_POLICY_L4_DST_RNG_TABLE_DEPTH;
  counters = stats_l4_dst_port;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================

  if(ing_sf_action_sel.apply().hit) {

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   ig_md.nsh_md.si = ig_md.nsh_md.si - 1; // decrement sp_index
   ig_md.nsh_md.si_predec = ig_md.nsh_md.si_predec - 1; // decrement sp_index





   // =====================================
   // Action(s)
   // =====================================

   // -------------------------------------
   // Action #0 - Policy
   // -------------------------------------


   ing_sf_ip_len_rng.apply();


   ing_sf_l4_src_port_rng.apply();


   ing_sf_l4_dst_port_rng.apply();


   acl.apply(
    lkp,
    ig_md,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm,
    lkp.ip_len,
    ip_len_rng,
    lkp.l4_src_port,
    l4_src_port_rng,
    lkp.l4_dst_port,
    l4_dst_port_rng,
    hdr_0,
    hdr_udf,
    int_ctrl_flags
   );

   // -------------------------------------
   // Action #1 - Deduplication
   // -------------------------------------
# 299 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_top.p4"
  }
 }
}
# 7 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4" 2
//#include "npb_ing_sf_npb_basic_adv_sfp_sel.p4"
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_multicast_top.p4" 1



control npb_ing_sf_multicast_top_part1 (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 switch_uint32_t table_size = NPB_ING_SF_1_MULTICAST_SFF_TABLE_DEPTH
) {

 // =========================================================================
 // Table #1: Action Select
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 // sets: mgid (and resets port_lag_index -- just in case the user selected the wrong action in the sff)
 action ing_sf_action_sel_hit(
  switch_mgid_t mgid
 ) {
  stats.count();

  ig_md.multicast.id = mgid;

//		ig_md.nexthop = 0; // don't reset nexthop, as this controls where the original packet will go.
//		ig_md.egress_port_lag_index = 0; // no need to reset this.
 }

 // =====================================

 action ing_sf_action_sel_miss(
 ) {
  stats.count();

 }

 // =====================================

 table ing_sf_action_sel {
  key = {
   ig_md.nsh_md.spi : exact @name("spi");
   ig_md.nsh_md.si : exact @name("si");
  }

  actions = {
   ing_sf_action_sel_hit;
   ing_sf_action_sel_miss;
  }

  size = table_size;
  const default_action = ing_sf_action_sel_miss;
  counters = stats;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =====================================
  // Action Lookup
  // =====================================

  if(ing_sf_action_sel.apply().hit) {

   // =====================================
   // Decrement SI
   // =====================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   ig_md.nsh_md.si = ig_md.nsh_md.si - 1; // decrement sp_index




  }

 }
}

//-----------------------------------------------------------------------------
// Multicast flooding
//-----------------------------------------------------------------------------
/*
control MulticastFlooding(inout switch_ingress_metadata_t ig_md)(switch_uint32_t table_size) {

	action flood(switch_mgid_t mgid) {
		ig_md.multicast.id = mgid;
	}

	table bd_flood {
		key = {
			ig_md.bd : exact @name("bd");
			ig_md.lkp.pkt_type : exact @name("pkt_type");
#ifdef MULTICAST_ENABLE
			ig_md.flags.flood_to_multicast_routers : exact @name("flood_to_multicast_routers");
#endif
		}

		actions = { flood; }
		size = table_size;
	}

	apply {
		bd_flood.apply();
	}
}
*/
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
 // Table #1: 
 // =========================================================================

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

 }
}
# 9 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sff_top.p4" 1




control npb_ing_sff_top (
 inout switch_header_transport_t hdr_0,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

 // =========================================================================
 // Table #1: FIB
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

 // =====================================

 action drop_pkt (
 ) {
  stats.count();

  ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//		ig_md.nsh_md.end_of_path = false;
 }

 // =====================================

 // sets: port_lag_index
 action unicast(
  switch_port_lag_index_t port_lag_index,

//		bool end_of_chain,
  bit<6> lag_hash_mask_en
 ) {
  stats.count();

  ig_md.egress_port_lag_index = port_lag_index;

  ig_md.nsh_md.end_of_path = true; // since we're bypassing nexthop and so can't put a tunnel on, we don't want an nsh header either.
  ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
 }

 // =====================================

 // sets: mgid (well, actually mgid set by sf#1, but it could be set here instead!)
 action multicast(
//		switch_mgid_t mgid,

//		bool end_of_chain,
  bit<6> lag_hash_mask_en
 ) {
  stats.count();

//		ig_md.multicast.id = mgid;

  ig_md.nsh_md.end_of_path = true; // since we're bypassing nexthop and so can't put a tunnel on, we don't want an nsh header either.
  ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
 }

 // =====================================

 // sets: nexthop
 action redirect(
  switch_nexthop_t nexthop_index,

  bool end_of_chain,
  bit<6> lag_hash_mask_en
 ) {
  stats.count();

  ig_md.nexthop = nexthop_index;

  ig_md.nsh_md.end_of_path = end_of_chain;
  ig_md.nsh_md.lag_hash_mask_en = lag_hash_mask_en;
 }

 // =====================================

 table ing_sff_fib {
  key = {
   ig_md.nsh_md.spi : exact @name("spi");

   ig_md.nsh_md.si_predec : exact @name("si");



  }

  actions = {
   drop_pkt;
   unicast;
   multicast;
   redirect;
  }

  // Derek: drop packet on miss...
  //
  // RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
  // do not correspond to a valid next hop in a valid SFP, that packet MUST
  // be dropped by the SFF.

  const default_action = drop_pkt;
  counters = stats;
  size = NPB_ING_SFF_ARP_TABLE_DEPTH;
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
  // -------------------------------------
  // Forwarding Lookup
  // -------------------------------------

  ing_sff_fib.apply();

 }
}
# 10 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4" 2

# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 1
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
# 12 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4" 2

control Npb_Ing_Top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,
 inout udf_h hdr_udf,

 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 Scoper_Hdr0_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr0_to_lkp;
 Scoper_Hdr1_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr1_to_lkp;
 Scoper_Hdr2_To_Lkp(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) scoper_hdr2_to_lkp;

 Npb_Ing_Sfc_Top(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_ing_sfc_top;

 Npb_Ing_Sf_Npb_Basic_Adv_Top(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_ing_sf_npb_basic_adv_top;




 Npb_Ing_Sf_Npb_Basic_Adv_Sfp_Sel(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_ing_sf_npb_basic_adv_sfp_sel;

 TunnelDecapTransportIngress(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE, switch_tunnel_mode_t.PIPE) tunnel_decap_transport_ingress;
 TunnelDecapOuter(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE, switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
 TunnelDecapInner(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE, switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // Derek: Don't know what we want to do with this signal for the 
  // npb path.  For now, just setting it to 0 here (it's set in port.p4,
  // but probably not using the fields we want to be used for the npb)

//		ig_intr_md_for_tm.level2_exclusion_id = 0;

  // -----------------------------------------------------------------
  // Set Initial Lkp Structures
  // -----------------------------------------------------------------
# 102 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4"
  // -----------------------------------------------------------------
  // Set Initial Scope (L7)
  // -----------------------------------------------------------------






  // -------------------------------------
  // SFC
  // -------------------------------------

//		if (!INGRESS_BYPASS(SFC)) {
   npb_ing_sfc_top.apply (
    hdr_0,
    tunnel_0,
    hdr_1,
    tunnel_1,
    hdr_2,
    tunnel_2,
    hdr_3,
    hdr_udf,

    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
//		}

  // -------------------------------------
  // SF #0 - SFP Hashes
  // -------------------------------------
# 155 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4"
  // -------------------------------------
  //
  // -------------------------------------
# 169 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4"
  // -------------------------------------
  // SF #0 - Policy
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SF_ACL != 0)) {
   npb_ing_sf_npb_basic_adv_top.apply (
    ig_md.lkp_1,
    hdr_0,
    hdr_1,
    hdr_2,
    hdr_udf,

    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );

   // -------------------------------------
   // SF #0 - SFP Select
   // -------------------------------------

   npb_ing_sf_npb_basic_adv_sfp_sel.apply(
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // SFF - Reframing
  // -------------------------------------

  // Decaps ------------------------------

  tunnel_decap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);



  tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
  tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		ig_md.nsh_md.scope = ig_md.nsh_md.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0, ig_md.nsh_md.scope);
# 226 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_top.p4"
  // Encaps ------------------------------

//		tunnel_0.encap = true;
//		tunnel_encap_transport_ingress.apply(hdr_0, tunnel_0, hdr_1);

  // -------------------------------------
  // SFF
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SFF != 0)) {
   npb_ing_sff_top.apply (
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // SF #1 - Multicast
  // -------------------------------------

  if (!(ig_md.bypass & SWITCH_INGRESS_BYPASS_SF_MCAST != 0)) {
   npb_ing_sf_multicast_top_part1.apply (
    hdr_0,
    ig_md,
    ig_intr_md,
    ig_intr_md_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );
  }

  // -------------------------------------
  // Add NSH header
  // -------------------------------------

  // Only add bridged metadata if we are NOT bypassing egress pipeline.
  if (ig_intr_md_for_tm.bypass_egress == 1w0) {
   hdr_0.nsh_type1_internal = {
    version = 0,
    o = 0,
    reserved = 0,
    ttl = ig_md.nsh_md.ttl,
    len = 0,
    spi = ig_md.nsh_md.spi,
    si = ig_md.nsh_md.si,
    vpn = (bit<16>)ig_md.nsh_md.vpn,
    scope = ig_md.nsh_md.scope,
    sap = (bit<16>)ig_md.nsh_md.sap
   };
  }
 }
}
# 61 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_deparser.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/headers.p4" 1
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
# 25 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_deparser.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4" 1
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
# 26 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_deparser.p4" 2

//-----------------------------------------------------------------------------
// Ingress Deparser
//-----------------------------------------------------------------------------

control IngressMirror(
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

// Ingress deparser create a copy of the original ingress packet and prepend the prepend the mirror
// header.


    Mirror() mirror;


    apply {

/*
        if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
            mirror.emit<switch_port_mirror_ingress_metadata_h>(ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                0,
                ig_md.port,
                ig_md.bd,
                0,
    #ifdef CPU_HDR_CONTAINS_EG_PORT
                ig_md.egress_port,
    #else
                ig_md.port_lag_index,
    #endif
                ig_md.timestamp,
//  #if __TARGET_TOFINO__ == 1
//               0,
//  #endif
//              ig_md.mirror.session_id
				ig_md.cpu_reason
				,
				0,
				ig_md.qos.qid,
				0,
				ig_md.qos.qdepth
            });
        } else if (ig_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
*/
        if (ig_intr_md_for_dprsr.mirror_type == 2) {

            mirror.emit<switch_cpu_mirror_ingress_metadata_h>(ig_md.mirror.session_id, {
                ig_md.mirror.src,
                ig_md.mirror.type,
                0,
                ig_md.port,
                ig_md.bd,
                0,

                ig_md.egress_port,



                ig_md.timestamp,
                ig_md.cpu_reason
/*
				,
				0,
				ig_md.qos.qid,
				0,
				ig_md.qos.qdepth
*/
            });

        } else if (ig_intr_md_for_dprsr.mirror_type == 3) {
# 121 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_deparser.p4"
        }

    }
}

//-----------------------------------------------------------------------------

control IngressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) ( // constructor parameters
    bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 IngressMirror() mirror;

    apply {
  mirror.apply(hdr, ig_md, ig_intr_md_for_dprsr);

        // ***** BRIDGED METADATA *****
        pkt.emit(hdr.bridged_md); // Ingress only.

        // ***** PRE-TRANSPORT *****
//      pkt.emit(hdr.transport.nsh_type1);
      pkt.emit(hdr.transport.nsh_type1_internal);

        // ***** TRANSPORT *****
//      pkt.emit(hdr.transport.ethernet);
//      pkt.emit(hdr.transport.vlan_tag);

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);

        if(OUTER_ETAG_ENABLE) {
            pkt.emit(hdr.outer.e_tag);
        }

        if(OUTER_VNTAG_ENABLE) {
            pkt.emit(hdr.outer.vn_tag);
        }

        pkt.emit(hdr.outer.vlan_tag);






        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        if(OUTER_GENEVE_ENABLE) {
            pkt.emit(hdr.outer.geneve);
        }

        if(OUTER_VXLAN_ENABLE) {
            pkt.emit(hdr.outer.vxlan);
        }

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);

        if(OUTER_NVGRE_ENABLE) {
            pkt.emit(hdr.outer.nvgre);
        }


        pkt.emit(hdr.outer.gtp_v1_base);
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
        pkt.emit(hdr.inner.gre_optional);


        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);


        if(UDF_ENABLE) {
            pkt.emit(hdr.udf);
        }
    }
}
# 62 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4" 1



parser EgressParser(
    packet_in pkt,
    out switch_header_t hdr,
    out switch_egress_metadata_t eg_md,
    out egress_intrinsic_metadata_t eg_intr_md
) ( // constructor parameters
    bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

    bit<8> scope;
    bool l2_fwd_en;
    bool transport_valid;

 bit<8> protocol_outer;
 bit<8> protocol_inner;


    state start {
        pkt.extract(eg_intr_md);
//      eg_md.pkt_length = eg_intr_md.pkt_length;
        eg_md.payload_len = eg_intr_md.pkt_length; // initially populate with pkt length...we will fix later
        eg_md.port = eg_intr_md.egress_port;
  eg_md.qos.qdepth = eg_intr_md.deq_qdepth;
# 35 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        // initialize lookup struct to zeros
/*
        eg_md.lkp_1.mac_src_addr = 0;
        eg_md.lkp_1.mac_dst_addr = 0;
        eg_md.lkp_1.mac_type = 0;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.pad = 0;
        eg_md.lkp_1.vid = 0;
        eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        eg_md.lkp_1.ip_proto = 0;
        eg_md.lkp_1.ip_tos = 0;
        eg_md.lkp_1.ip_flags = 0;
        eg_md.lkp_1.ip_src_addr = 0;
        eg_md.lkp_1.ip_dst_addr = 0;
        eg_md.lkp_1.ip_len = 0;
        eg_md.lkp_1.tcp_flags = 0;
        eg_md.lkp_1.l4_src_port = 0;
        eg_md.lkp_1.l4_dst_port = 0;
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NONE;
        eg_md.lkp_1.tunnel_id = 0;
        eg_md.lkp_1.tunnel_outer_type = SWITCH_TUNNEL_TYPE_NONE; // note: outer here means "current scope - 2"
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NONE; // note: inner here means "current scope - 1"
*/



        switch_cpu_mirror_ingress_metadata_h mirror_md = pkt.lookahead<switch_cpu_mirror_ingress_metadata_h>();
        transition select(eg_intr_md.deflection_flag, mirror_md.src, mirror_md.type) {
            (1, _, _ ) : parse_deflected_pkt;
            (_, SWITCH_PKT_SRC_BRIDGED, _ ) : parse_bridged_pkt;
//          (_, _,                             SWITCH_MIRROR_TYPE_PORT             ) : parse_port_mirrored_metadata;
/*
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_PORT             ) : parse_ig_port_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS,  SWITCH_MIRROR_TYPE_PORT             ) : parse_eg_port_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, SWITCH_MIRROR_TYPE_CPU              ) : parse_ig_cpu_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_EGRESS,  SWITCH_MIRROR_TYPE_CPU              ) : parse_eg_cpu_mirrored_metadata; // derek added
*/
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 2 ) : parse_ig_cpu_mirrored_metadata; // derek added
            (_, _, 2 ) : parse_eg_cpu_mirrored_metadata; // derek added
            (_, SWITCH_PKT_SRC_CLONED_INGRESS, 3 ) : parse_dtel_drop_metadata_from_ingress;
            (_, _, 3 ) : parse_dtel_drop_metadata_from_egress;
            (_, _, 4) : parse_dtel_switch_local_metadata;
            (_, _, 5 ) : parse_simple_mirrored_metadata;
        }



    }

    state parse_bridged_pkt {
  pkt.extract(hdr.bridged_md);
        eg_md.pkt_src = SWITCH_PKT_SRC_BRIDGED;

  // ---- extract base bridged metadata -----
        eg_md.ingress_port = hdr.bridged_md.base.ingress_port;




//      eg_md.bd                   = hdr.bridged_md.base.ingress_bd;
        eg_md.nexthop = hdr.bridged_md.base.nexthop;
//      eg_md.pkt_type             = hdr.bridged_md.base.pkt_type;
  eg_md.flags.bypass_egress = hdr.bridged_md.base.bypass_egress;
        eg_md.cpu_reason = hdr.bridged_md.base.cpu_reason;
        eg_md.ingress_timestamp = hdr.bridged_md.base.timestamp;
  eg_md.qos.qid = hdr.bridged_md.base.qid;

  eg_md.hash = hdr.bridged_md.base.hash;

        eg_md.tunnel_nexthop = hdr.bridged_md.tunnel.tunnel_nexthop;
        eg_md.tunnel_0.dip_index = hdr.bridged_md.tunnel.dip_index;
//      eg_md.tunnel_0.hash        = hdr.bridged_md.tunnel.hash;

//      eg_md.tunnel_0.terminate   = hdr.bridged_md.tunnel.terminate_0;
//      eg_md.tunnel_1.terminate   = hdr.bridged_md.tunnel.terminate_1;
//      eg_md.tunnel_2.terminate   = hdr.bridged_md.tunnel.terminate_2;


  // ----- extract nsh bridged metadata -----
        eg_md.flags.transport_valid= hdr.bridged_md.base.transport_valid;
  eg_md.nsh_md.end_of_path = hdr.bridged_md.base.nsh_md_end_of_path;
  eg_md.nsh_md.l2_fwd_en = hdr.bridged_md.base.nsh_md_l2_fwd_en;
  eg_md.nsh_md.dedup_en = hdr.bridged_md.base.nsh_md_dedup_en;

//      eg_md.dtel.report_type     = hdr.bridged_md.dtel.report_type;
//      eg_md.dtel.hash            = hdr.bridged_md.dtel.hash;
        eg_md.dtel.hash = hdr.bridged_md.base.hash[31:0]; // derek hack
//      eg_md.dtel.session_id      = hdr.bridged_md.dtel.session_id;

        // -----------------------------
        // packet will always have NSH present

        //  L2   My   MAU                   First   
        //  Fwd  MAC  Path                  Stack
        //  ----------------------------    ------------
        //  0    0    SFC Optical-Tap       Outer       
        //  0    1    SFC Optical-Tap       Outer       
        //  1    0    Bridging              Outer       
        //  1    1    SFC Network-Tap       Transport   
        //            or SFC Bypass (nsh)   Transport

        transition select(
            (bit<1>)hdr.bridged_md.base.nsh_md_l2_fwd_en,
            (bit<1>)hdr.bridged_md.base.transport_valid) {

            (1, 0): parse_outer_ethernet_scope0; // SFC Optical-Tap / Bridging Path
//          default: parse_transport_ethernet;    // SFC Network-Tap / SFC Bypass Path
            default: parse_transport_nsh; // SFC Network-Tap / SFC Bypass Path
        }

    }
/*
    state parse_ig_port_mirrored_metadata {
        switch_port_mirror_ingress_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;                          // for cpu header
        eg_md.bd = port_md.bd;                                // for cpu header (derek added)
		eg_md.ingress_port = port_md.port;                    // for cpu header (derek added)
#ifdef CPU_HDR_CONTAINS_EG_PORT
        eg_md.port = port_md.eg_port;                         // for cpu header (derek added)
#else
        eg_md.port_lag_index = port_md.port_lag_index;        // for cpu header (derek added)
#endif
//		eg_md.cpu_reason = SWITCH_CPU_REASON_IG_PORT_MIRROR;  // for cpu header (derek added)
		eg_md.cpu_reason = port_md.reason_code;               // for cpu header
//      eg_md.mirror.session_id = port_md.session_id;         // for ??? header
////    eg_md.ingress_timestamp = port_md.timestamp;          // for ??? header
		eg_md.flags.bypass_egress = true;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = port_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.qos.qid = port_md.qos_qid;
        eg_md.qos.qdepth = port_md.qos_qdepth;
        transition accept;
    }
*/
/*
    state parse_eg_port_mirrored_metadata {
        switch_port_mirror_egress_metadata_h port_md;
        pkt.extract(port_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = port_md.src;                          // for cpu header
        eg_md.bd = port_md.bd;                                // for cpu header (derek added)
		eg_md.ingress_port = port_md.port;                    // for cpu header (derek added)
#ifdef CPU_HDR_CONTAINS_EG_PORT
        eg_md.port = port_md.eg_port;                         // for cpu header (derek added)
#else
        eg_md.port_lag_index = port_md.port_lag_index;        // for cpu header (derek added)
#endif
//		eg_md.cpu_reason = SWITCH_CPU_REASON_EG_PORT_MIRROR;  // for cpu header (derek added)
		eg_md.cpu_reason = port_md.reason_code;               // for cpu header
//      eg_md.mirror.session_id = port_md.session_id;         // for ??? header
////    eg_md.ingress_timestamp = port_md.timestamp;          // for ??? header
		eg_md.flags.bypass_egress = true;
#ifdef PACKET_LENGTH_ADJUSTMENT
        eg_md.mirror.type = port_md.type;
#endif
#ifdef DTEL_ENABLE
        // Initialize eg_md.dtel.session_id to prevent it from being marked @pa_no_init.
        eg_md.dtel.session_id = 0;
#endif
        eg_md.qos.qid = port_md.qos_qid;
        eg_md.qos.qdepth = port_md.qos_qdepth;
        transition accept;
    }
*/
    state parse_ig_cpu_mirrored_metadata {
        switch_cpu_mirror_ingress_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src; // for cpu header
  eg_md.flags.bypass_egress = true;
        eg_md.bd = cpu_md.bd; // for cpu header
        eg_md.ingress_port = cpu_md.port; // for cpu header

        eg_md.port = cpu_md.eg_port; // for cpu header (derek added)



        eg_md.ingress_timestamp = cpu_md.timestamp; // for ??? header
        eg_md.cpu_reason = cpu_md.reason_code; // for cpu header







/*
        eg_md.qos.qid = cpu_md.qos_qid;
        eg_md.qos.qdepth = cpu_md.qos_qdepth;
*/
        transition accept;
    }

    state parse_eg_cpu_mirrored_metadata {
        switch_cpu_mirror_egress_metadata_h cpu_md;
        pkt.extract(cpu_md);
        pkt.extract(hdr.outer.ethernet);
        eg_md.pkt_src = cpu_md.src; // for cpu header
  eg_md.flags.bypass_egress = true;
        eg_md.bd = cpu_md.bd; // for cpu header
        eg_md.ingress_port = cpu_md.port; // for cpu header

        eg_md.port = cpu_md.eg_port; // for cpu header (derek added)



        eg_md.ingress_timestamp = cpu_md.timestamp; // for ??? header
        eg_md.cpu_reason = cpu_md.reason_code; // for cpu header







        eg_md.qos.qid = cpu_md.qos_qid;
        eg_md.qos.qdepth = cpu_md.qos_qdepth;
        transition accept;
    }

    state parse_deflected_pkt {
# 307 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition reject;

    }

    state parse_dtel_drop_metadata_from_egress {
# 351 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition reject;

    }

    /* Separate parse state for drop metadata from ingress, in order to set
     * hdr.transport.dtel_report.egress_port to SWITCH_PORT_INVALID */
    state parse_dtel_drop_metadata_from_ingress {
# 397 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition reject;

    }

    state parse_dtel_switch_local_metadata {
# 449 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition reject;

    }

    state parse_simple_mirrored_metadata {
# 469 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition reject;

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
            0x894F: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_vlan {
        pkt.extract(hdr.transport.vlan_tag[0]);
        transition select(hdr.transport.vlan_tag[0].ether_type) {
            0x894F: parse_transport_nsh;
            default: accept; // should never get here
        }
    }
    state parse_transport_nsh {
/*
	    pkt.extract(hdr.transport.nsh_type1);
        scope = hdr.transport.nsh_type1.scope;

        transition select(scope, hdr.transport.nsh_type1.next_proto) {
            (0, NSH_PROTOCOLS_ETH): parse_outer_ethernet_scope0;

#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
            (1, NSH_PROTOCOLS_ETH): parse_outer_ethernet_scope1;
#else
            (1, NSH_PROTOCOLS_ETH): parse_outer_ethernet_scope0;
#endif // EGRESS_PARSER_POPULATES_LKP_SCOPED
            
            default: reject;  // todo: support ipv4? ipv6?
        }
*/
     pkt.extract(hdr.transport.nsh_type1_internal);
        scope = hdr.transport.nsh_type1_internal.scope;

  eg_md.nsh_md.ttl = hdr.transport.nsh_type1_internal.ttl;
  eg_md.nsh_md.spi = hdr.transport.nsh_type1_internal.spi;
  eg_md.nsh_md.si = hdr.transport.nsh_type1_internal.si;
  eg_md.nsh_md.vpn = hdr.transport.nsh_type1_internal.vpn;
  eg_md.nsh_md.scope = hdr.transport.nsh_type1_internal.scope;
  eg_md.nsh_md.sap = hdr.transport.nsh_type1_internal.sap;

        transition select(scope) {
            (1): parse_outer_ethernet_scope0;


            (2): parse_outer_ethernet_scope1;




            default: reject; // todo: support ipv4? ipv6?
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Outer" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    ///////////////////////////////////////////////////////////////////////////
    // Layer2 - Outer (ETH)
    ///////////////////////////////////////////////////////////////////////////

    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_outer_ethernet_scope0 {
        pkt.extract(hdr.outer.ethernet);

        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;


        transition select(hdr.outer.ethernet.ether_type) {
            0x893F : parse_outer_br_scope0;
            0x8926 : parse_outer_vn_scope0;
            0x8100 : parse_outer_vlan_scope0;
            0x88A8 : parse_outer_vlan_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }

    state parse_outer_br_scope0 {
        transition select(OUTER_ETAG_ENABLE) {
            true: extract_outer_br_scope0;
            false: accept;
        }
    }

    state extract_outer_br_scope0 {
     pkt.extract(hdr.outer.e_tag);

        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;
        //eg_md.lkp_1.pcp = hdr.outer.e_tag.pcp;  // do not populate w/ e-tag

        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_scope0;
            0x88A8 : parse_outer_vlan_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_vn_scope0 {
        transition select(OUTER_VNTAG_ENABLE) {
            true: extract_outer_vn_scope0;
            false: accept;
        }
    }

    state extract_outer_vn_scope0 {
     pkt.extract(hdr.outer.vn_tag);

        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;

        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_scope0;
            0x88A8 : parse_outer_vlan_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    state parse_outer_vlan_scope0 {
     pkt.extract(hdr.outer.vlan_tag.next);


        eg_md.lkp_1.pcp = hdr.outer.vlan_tag.last.pcp;

  eg_md.lkp_1.vid = hdr.outer.vlan_tag.last.vid;

        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag.last.ether_type;
# 644 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            0x8100 : parse_outer_vlan_scope0;



            0x0800 : parse_outer_ipv4_scope0;
            0x86dd : parse_outer_ipv6_scope0;
            default : accept;
        }
    }


    // todo: Can we implement scope0/1 as single sub-parser, w/ parameters
    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_outer_ethernet_scope1 {
        pkt.extract(hdr.outer.ethernet);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_src_addr = hdr.outer.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.outer.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.outer.ethernet.ether_type;


        transition select(hdr.outer.ethernet.ether_type) {
            0x893F : parse_outer_br_scope1;
            0x8926 : parse_outer_vn_scope1;
            0x8100 : parse_outer_vlan_scope1;
            0x88A8 : parse_outer_vlan_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }

    state parse_outer_br_scope1 {
        transition select(OUTER_ETAG_ENABLE) {
            true: extract_outer_br_scope1;
            false: accept;
        }
    }

    state extract_outer_br_scope1 {
     pkt.extract(hdr.outer.e_tag);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_type = hdr.outer.e_tag.ether_type;


        transition select(hdr.outer.e_tag.ether_type) {
            0x8100 : parse_outer_vlan_scope1;
            0x88A8 : parse_outer_vlan_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_vn_scope1 {
        transition select(OUTER_VNTAG_ENABLE) {
            true: extract_outer_vn_scope1;
            false: accept;
        }
    }

    state extract_outer_vn_scope1 {
     pkt.extract(hdr.outer.vn_tag);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.mac_type = hdr.outer.vn_tag.ether_type;


        transition select(hdr.outer.vn_tag.ether_type) {
            0x8100 : parse_outer_vlan_scope1;
            0x88A8 : parse_outer_vlan_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    state parse_outer_vlan_scope1 {
     pkt.extract(hdr.outer.vlan_tag.next);

// populate for L3-tunnel case (where there's no L2 present)

        eg_md.lkp_1.pcp = hdr.outer.vlan_tag.last.pcp;

  eg_md.lkp_1.vid = hdr.outer.vlan_tag.last.vid;

        eg_md.lkp_1.mac_type = hdr.outer.vlan_tag.last.ether_type;
# 759 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
        transition select(hdr.outer.vlan_tag.last.ether_type) {
            0x8100 : parse_outer_vlan_scope1;



            0x0800 : parse_outer_ipv4_scope1;
            0x86dd : parse_outer_ipv6_scope1;
            default : accept;
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_outer_ipv4_scope0 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;

        // todo: should the lkp struct be set only if no frag and options?
//      eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto = hdr.outer.ipv4.protocol;
        eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
        eg_md.lkp_1.ip_flags = hdr.outer.ipv4.flags;
        eg_md.lkp_1.ip_src_addr_v4= hdr.outer.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr_v4= hdr.outer.ipv4.dst_addr;
        eg_md.lkp_1.ip_len = hdr.outer.ipv4.total_len;


        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset,
            hdr.outer.ipv4.protocol) {

            //(5, 0, IP_PROTOCOLS_ICMP): parse_outer_icmp_igmp_overload_scope0;
            //(5, 0, IP_PROTOCOLS_IGMP): parse_outer_icmp_igmp_overload_scope0;
            (5, 0, _): branch_outer_l3_protocol_scope0;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope0 {

        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;

//      eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto = hdr.outer.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.outer.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr = hdr.outer.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.outer.ipv6.dst_addr;
        eg_md.lkp_1.ip_len = hdr.outer.ipv6.payload_len;


        transition branch_outer_l3_protocol_scope0;
        // transition select(hdr.outer.ipv6.next_hdr) {
        //     IP_PROTOCOLS_ICMPV6: parse_outer_icmp_igmp_overload_scope0;
        //     default: branch_outer_l3_protocol_scope0;
        // }



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope0 {
        transition select(protocol_outer) {
           4: parse_outer_ipinip_set_tunnel_scope0;
           41: parse_outer_ipv6inip_set_tunnel_scope0;
           17: parse_outer_udp_scope0;
           6: parse_outer_tcp_scope0;
           0x84: parse_outer_sctp_scope0;
           47: parse_outer_gre_scope0;
           //IP_PROTOCOLS_ESP: parse_outer_esp_overload_scope0;
           default: accept;
       }
    }


    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_outer_ipv4_scope1 {
        pkt.extract(hdr.outer.ipv4);
        protocol_outer = hdr.outer.ipv4.protocol;
        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.outer.ipv4.ihl,
            hdr.outer.ipv4.frag_offset) {

            (5, 0): branch_outer_l3_protocol_scope1;
            default: accept;
        }
    }

    state parse_outer_ipv6_scope1 {

        pkt.extract(hdr.outer.ipv6);
        protocol_outer = hdr.outer.ipv6.next_hdr;
        transition branch_outer_l3_protocol_scope1;



    }

    // shared fanout/branch state to save tcam resource
    state branch_outer_l3_protocol_scope1 {
        transition select(protocol_outer) {
           4: parse_outer_ipinip_set_tunnel_scope1;
           41: parse_outer_ipv6inip_set_tunnel_scope1;
           17: parse_outer_udp_scope1;
           6: parse_outer_tcp_scope1;
           0x84: parse_outer_sctp_scope1;
           47: parse_outer_gre_scope1;
           default: accept;
       }
    }


//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_outer_icmp_igmp_overload_scope0 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 4 - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // User Datagram Protocol (UDP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_udp_scope0 {
        pkt.extract(hdr.outer.udp);


        eg_md.lkp_1.l4_src_port = hdr.outer.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.udp.dst_port;


        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {

            (_, 6081): parse_outer_geneve_scope0;
            (_, 4789): parse_outer_vxlan_scope0;

            (_, 2123): parse_outer_gtp_c_scope0;
            (2123, _): parse_outer_gtp_c_scope0;
            (_, 2152): parse_outer_gtp_u_scope0;
            (2152, _): parse_outer_gtp_u_scope0;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope0;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope0;

            default : accept;
        }
    }

    state parse_outer_udp_scope1 {
        pkt.extract(hdr.outer.udp);
        transition select(hdr.outer.udp.src_port, hdr.outer.udp.dst_port) {

            (_, 6081): parse_outer_geneve_scope1;
            (_, 4789): parse_outer_vxlan_scope1;

            (_, 2123): parse_outer_gtp_c_scope1;
            (2123, _): parse_outer_gtp_c_scope1;
            (_, 2152): parse_outer_gtp_u_scope1;
            (2152, _): parse_outer_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_outer_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_outer_gtp_u_scope1;

            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Transmission Control Protocol (TCP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_tcp_scope0 {
        pkt.extract(hdr.outer.tcp);

        eg_md.lkp_1.l4_src_port = hdr.outer.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.tcp.dst_port;
        eg_md.lkp_1.tcp_flags = hdr.outer.tcp.flags;

        transition accept;
    }

    state parse_outer_tcp_scope1 {
        pkt.extract(hdr.outer.tcp);
        transition accept;
    }

    //-------------------------------------------------------------------------
    // Stream Control Transmission Protocol (SCTP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_sctp_scope0 {
        pkt.extract(hdr.outer.sctp);

        eg_md.lkp_1.l4_src_port = hdr.outer.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.outer.sctp.dst_port;

        transition accept;
    }

    state parse_outer_sctp_scope1 {
        pkt.extract(hdr.outer.sctp);
        transition accept;
    }

    ///////////////////////////////////////////////////////////////////////////////
    // Layer X - Outer
    ///////////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Multi-Protocol Label Switching (MPLS) - Outer
    //-------------------------------------------------------------------------
    // Due to chip resource constraints, we're only supporting MPLS segment
    // routing or MPLS L2/L3VPN (not both). Valid combinations are as follows:
    //
    //  MPLS_SR_ENABLE  MPLS_L2VPN_ENABLE  MPLS_L3VPN_ENABLE
    //  -----------------------------------------------------
    //  #undef          #undef             #undef
    //  #define         #undef             #undef
    //  #undef          #undef             #define
    //  #undef          #define            #undef
    //  #undef          #define            #define
    //
    // For all MPLS enabled combinations above, the user can add MPLS-over-GRE
    // support via the following feature #define: MPLSoGRE_ENABLE
# 1167 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_parser.p4"
    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Outer
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Generic Network Virtualization Encapsulation (GENEVE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_geneve_scope0 {
        transition select(OUTER_GENEVE_ENABLE) {
            true: qualify_outer_geneve_scope0;
            false: accept;
        }
    }

    state qualify_outer_geneve_scope0 {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {

          //     O C 
            (0,0,0,0,0x6558): parse_outer_geneve_qualified_scope0;
            (0,0,0,0,0x0800): parse_outer_geneve_qualified_scope0;
            (0,0,0,0,0x86dd): parse_outer_geneve_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_geneve_qualified_scope0 {
        pkt.extract(hdr.outer.geneve);


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GENEVE;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.geneve.vni;


        transition select(hdr.outer.geneve.proto_type) {
            0x6558: parse_inner_ethernet_scope0;
            0x0800: parse_inner_ipv4_scope0;
            0x86dd: parse_inner_ipv6_scope0;
            default: accept;
        }
    }


    state parse_outer_geneve_scope1 {
        transition select(OUTER_GENEVE_ENABLE) {
            true: qualify_outer_geneve_scope1;
            false: accept;
        }
    }

    state qualify_outer_geneve_scope1 {
        geneve_h snoop_geneve = pkt.lookahead<geneve_h>();
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            snoop_geneve.ver,
            snoop_geneve.opt_len,
            snoop_geneve.O,
            snoop_geneve.C,
            snoop_geneve.proto_type) {

          //     O C 
            (0,0,0,0,0x6558): parse_outer_geneve_qualified_scope1;
            (0,0,0,0,0x0800): parse_outer_geneve_qualified_scope1;
            (0,0,0,0,0x86dd): parse_outer_geneve_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_geneve_qualified_scope1 {
        pkt.extract(hdr.outer.geneve);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GENEVE; // note: inner here means "current scope - 1"
        transition select(hdr.outer.geneve.proto_type) {
            0x6558: parse_inner_ethernet_scope1;
            0x0800: parse_inner_ipv4_scope1;
            0x86dd: parse_inner_ipv6_scope1;
            default: accept;
        }
    }


    //-------------------------------------------------------------------------
    // Virtual Extensible Local Area Network (VXLAN) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_vxlan_scope0 {
        transition select(OUTER_VXLAN_ENABLE) {
            true: extract_outer_vxlan_scope0;
            false: accept;
        }
    }

    state extract_outer_vxlan_scope0 {
        pkt.extract(hdr.outer.vxlan);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_VXLAN;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.vxlan.vni;

        transition parse_inner_ethernet_scope0;
    }


    state parse_outer_vxlan_scope1 {
        transition select(OUTER_VXLAN_ENABLE) {
            true: extract_outer_vxlan_scope1;
            false: accept;
        }
    }

    state extract_outer_vxlan_scope1 {
        pkt.extract(hdr.outer.vxlan);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_VXLAN; // note: inner here means "current scope - 1"
        transition parse_inner_ethernet_scope1;
    }



    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_ipinip_set_tunnel_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_ipv4_scope0;



    }

    state parse_outer_ipv6inip_set_tunnel_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_ipv6_scope0;



    }


    state parse_outer_ipinip_set_tunnel_scope1 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv4_scope1;



    }

    state parse_outer_ipv6inip_set_tunnel_scope1 {

        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_IPINIP; // note: inner here means "current scope - 1"
        transition parse_inner_ipv6_scope1;



    }



    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_gre_scope0 {
        gre_h snoop_gre = pkt.lookahead<gre_h>();


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified_scope0;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_scope1 {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (1,0,0,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (0,0,1,0,0,0,0,0): parse_outer_gre_qualified_scope1;
            (0,0,0,1,0,0,0,0): parse_outer_gre_qualified_scope1;
            default: accept;
        }
    }


    state parse_outer_gre_qualified_scope0 {
        pkt.extract(hdr.outer.gre);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;


        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S
            (0,1,0,0x6558): parse_outer_nvgre_scope0;
            (0,0,0,0x0800): parse_inner_ipv4_scope0;
            (0,0,0,0x86dd): parse_inner_ipv6_scope0;



            (1,0,0,_): parse_outer_gre_optional_scope0;
            (0,1,0,_): parse_outer_gre_optional_scope0;
            (0,0,1,_): parse_outer_gre_optional_scope0;
            default: accept;
        }
    }

    state parse_outer_gre_qualified_scope1 {
        pkt.extract(hdr.outer.gre);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GRE; // note: inner here means "current scope - 1"

        transition select(
            hdr.outer.gre.C,
            hdr.outer.gre.K,
            hdr.outer.gre.S,
            hdr.outer.gre.proto) {

          // C K S
            (0,1,0,0x6558): parse_outer_nvgre_scope1;
            (0,0,0,0x0800): parse_inner_ipv4_scope1;
            (0,0,0,0x86dd): parse_inner_ipv6_scope1;



            (1,0,0,_): parse_outer_gre_optional_scope1;
            (0,1,0,_): parse_outer_gre_optional_scope1;
            (0,0,1,_): parse_outer_gre_optional_scope1;
            default: accept;
        }
    }


    state parse_outer_gre_optional_scope0 {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4_scope0;
            0x86dd: parse_inner_ipv6_scope0;



            default: accept;
        }
    }

    state parse_outer_gre_optional_scope1 {
        pkt.extract(hdr.outer.gre_optional);
        transition select(hdr.outer.gre.proto) {

            0x0800: parse_inner_ipv4_scope1;
            0x86dd: parse_inner_ipv6_scope1;



            default: accept;
        }
    }


    //-------------------------------------------------------------------------
    // Network Virtualization using GRE (NVGRE) - (aka: L2 GRE) - Outer
    //-------------------------------------------------------------------------

    state parse_outer_nvgre_scope0 {
        transition select(OUTER_NVGRE_ENABLE) {
            true: extract_outer_nvgre_scope0;
            false: accept;
        }
    }

    state extract_outer_nvgre_scope0 {
     pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_NVGRE;
        eg_md.lkp_1.tunnel_id = (bit<32>)hdr.outer.nvgre.vsid;

     transition parse_inner_ethernet_scope0;
    }


    state parse_outer_nvgre_scope1 {
        transition select(OUTER_NVGRE_ENABLE) {
            true: extract_outer_nvgre_scope1;
            false: accept;
        }
    }

    state extract_outer_nvgre_scope1 {
     pkt.extract(hdr.outer.nvgre);
        eg_md.tunnel_1.nvgre_flow_id = hdr.outer.nvgre.flow_id; //todo: ingress-only in switch
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_NVGRE; // note: inner here means "current scope - 1"
     transition parse_inner_ethernet_scope1;
    }


//     //-------------------------------------------------------------------------
//     // Encapsulating Security Payload (ESP) - Outer
//     //-------------------------------------------------------------------------
//     
//     state parse_outer_esp_overload_scope0 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
// #if defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
//          eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//          eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif // defined(EGRESS_PARSER_POPULATES_LKP_SCOPED) || defined(EGRESS_PARSER_POPULATES_LKP_WITH_OUTER)
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Outer
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):



    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_outer_gtp_c_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified_scope0 {

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;

     transition accept;
    }

    state parse_outer_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_outer_gtp_c_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_c_qualified_scope1 {
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPC; // note: inner here means "current scope - 1"
     transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_outer_gtp_u_scope0 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;


        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified_scope0;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional_qualified_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope0;
            6: parse_inner_ipv6_scope0;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional_qualified_scope0 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);

        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.outer.gtp_v1_base.teid;

        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope0;
            (0, 6): parse_inner_ipv6_scope0;
            default: accept;
        }
    }


    state parse_outer_gtp_u_scope1 {
        gtp_v1_base_h snoop_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED; // note: inner here means "current scope - 1"

        transition select(
            snoop_gtp_v1_base.version,
            snoop_gtp_v1_base.PT,
            snoop_gtp_v1_base.E,
            snoop_gtp_v1_base.S,
            snoop_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_outer_gtp_u_qualified_scope1;
            (1, 1, 0, 1, 0): parse_outer_gtp_u_with_optional_qualified_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_u_qualified_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_ipv4_scope1;
            6: parse_inner_ipv6_scope1;
            default: accept;
        }
    }

    state parse_outer_gtp_u_with_optional_qualified_scope1 {
        pkt.extract(hdr.outer.gtp_v1_base);
        pkt.extract(hdr.outer.gtp_v1_optional);
        eg_md.lkp_1.tunnel_inner_type = SWITCH_TUNNEL_TYPE_GTPU; // note: inner here means "current scope - 1"
        transition select(
            hdr.outer.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_ipv4_scope1;
            (0, 6): parse_inner_ipv6_scope1;
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

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------

    state parse_inner_ethernet_scope0 {
        pkt.extract(hdr.inner.ethernet);
        transition select(hdr.inner.ethernet.ether_type) {
            0x8100 : parse_inner_vlan_scope0;
            0x0800 : parse_inner_ipv4_scope0;
            0x86dd : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    state parse_inner_vlan_scope0 {
        pkt.extract(hdr.inner.vlan_tag[0]);
        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0800 : parse_inner_ipv4_scope0;
            0x86dd : parse_inner_ipv6_scope0;
            default : accept;
        }
    }

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------            

    state parse_inner_ethernet_scope1 {
        pkt.extract(hdr.inner.ethernet);

        eg_md.lkp_1.mac_src_addr = hdr.inner.ethernet.src_addr;
        eg_md.lkp_1.mac_dst_addr = hdr.inner.ethernet.dst_addr;
        eg_md.lkp_1.mac_type = hdr.inner.ethernet.ether_type;
        eg_md.lkp_1.pcp = 0;
        eg_md.lkp_1.vid = 0;

        transition select(hdr.inner.ethernet.ether_type) {
            0x8100 : parse_inner_vlan_scope1;
            0x0800 : parse_inner_ipv4_scope1;
            0x86dd : parse_inner_ipv6_scope1;
            default : accept;
        }
    }

    state parse_inner_vlan_scope1 {
        pkt.extract(hdr.inner.vlan_tag[0]);

        eg_md.lkp_1.pcp = hdr.inner.vlan_tag[0].pcp;

  eg_md.lkp_1.vid = hdr.inner.vlan_tag[0].vid;

        eg_md.lkp_1.mac_type = hdr.inner.vlan_tag[0].ether_type;






        transition select(hdr.inner.vlan_tag[0].ether_type) {
            0x0800 : parse_inner_ipv4_scope1;
            0x86dd : parse_inner_ipv6_scope1;
            default : accept;
        }
    }



    ///////////////////////////////////////////////////////////////////////////
    // Layer 3 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 0
    //-------------------------------------------------------------------------            

    // For scope0 inner parsing, l2 and v4 or v6 is all that's needed downstream.

    state parse_inner_ipv4_scope0 {
        pkt.extract(hdr.inner.ipv4);
        transition accept;
    }

    state parse_inner_ipv6_scope0 {

        pkt.extract(hdr.inner.ipv6);
        transition accept;



    }


    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_ipv4_scope1 {
        pkt.extract(hdr.inner.ipv4);
        protocol_inner = hdr.inner.ipv4.protocol;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type = 0x0800;

        // todo: should the lkp struct be set only if no frag and options?
//      eg_md.lkp_1.ip_type     = SWITCH_IP_TYPE_IPV4;
        eg_md.lkp_1.ip_proto = hdr.inner.ipv4.protocol;
        eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
        eg_md.lkp_1.ip_flags = hdr.inner.ipv4.flags;
        eg_md.lkp_1.ip_src_addr_v4 = hdr.inner.ipv4.src_addr;
        eg_md.lkp_1.ip_dst_addr_v4 = hdr.inner.ipv4.dst_addr;
        eg_md.lkp_1.ip_len = hdr.inner.ipv4.total_len;

        // Flag packet (to be sent to host) if it's a frag or has options.
        transition select(
            hdr.inner.ipv4.ihl,
            hdr.inner.ipv4.frag_offset,
            hdr.inner.ipv4.protocol) {
            //(5, 0, IP_PROTOCOLS_ICMP): parse_inner_icmp_igmp_overload_scope1;
            //(5, 0, IP_PROTOCOLS_IGMP): parse_inner_icmp_igmp_overload_scope1;
            (5, 0, _): branch_inner_l3_protocol_scope1;
            default : accept;
       }
    }

    state parse_inner_ipv6_scope1 {

        pkt.extract(hdr.inner.ipv6);
        protocol_inner = hdr.inner.ipv6.next_hdr;

        // fixup ethertype for ip-n-ip case
        eg_md.lkp_1.mac_type = 0x86dd;

//      eg_md.lkp_1.ip_type       = SWITCH_IP_TYPE_IPV6;
        eg_md.lkp_1.ip_proto = hdr.inner.ipv6.next_hdr;
        //eg_md.lkp_1.ip_tos        = hdr.inner.ipv6.tos; // not byte-aligned so set in mau
        eg_md.lkp_1.ip_src_addr = hdr.inner.ipv6.src_addr;
        eg_md.lkp_1.ip_dst_addr = hdr.inner.ipv6.dst_addr;
        eg_md.lkp_1.ip_len = hdr.inner.ipv6.payload_len;

        transition branch_inner_l3_protocol_scope1;
        // transition select(hdr.inner.ipv6.next_hdr) {
        //     IP_PROTOCOLS_ICMPV6: parse_inner_icmp_igmp_overload_scope1;
        //     default: branch_inner_l3_protocol_scope1;
        // }



    }

    state branch_inner_l3_protocol_scope1 {
        transition select(protocol_inner) {
           17: parse_inner_udp_scope1;
           6: parse_inner_tcp_scope1;
           0x84: parse_inner_sctp_scope1;

           47: parse_inner_gre_scope1;

           //IP_PROTOCOLS_ESP:  parse_inner_esp_overload_scope1;
           4: parse_inner_ipinip_set_tunnel_scope1;
           41: parse_inner_ipv6inip_set_tunnel_scope1;
        }
    }


//     // For ICMP and IGMP, we're not actually extracting the header;
//     // We're simply over-loading L4-port info for policy via lookahead.    
//     state parse_inner_icmp_igmp_overload_scope1 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<bit<16>>();
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    ///////////////////////////////////////////////////////////////////////////
    // Inner Layer 4 - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Scope 1
    //-------------------------------------------------------------------------

    state parse_inner_udp_scope1 {
        pkt.extract(hdr.inner.udp);
        eg_md.lkp_1.l4_src_port = hdr.inner.udp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.udp.dst_port;
        transition select(
            hdr.inner.udp.src_port,
            hdr.inner.udp.dst_port) {


            (_, 2123): parse_inner_gtp_c_scope1;
            (2123, _): parse_inner_gtp_c_scope1;
            (_, 2152): parse_inner_gtp_u_scope1;
            (2152, _): parse_inner_gtp_u_scope1;
            // (UDP_PORT_GTP_C, UDP_PORT_GTP_C): parse_inner_gtp_c_scope1;
            // (UDP_PORT_GTP_U, UDP_PORT_GTP_U): parse_inner_gtp_u_scope1;

            default: accept;
        }
    }

    state parse_inner_tcp_scope1 {
        pkt.extract(hdr.inner.tcp);
        eg_md.lkp_1.tcp_flags = hdr.inner.tcp.flags;
        eg_md.lkp_1.l4_src_port = hdr.inner.tcp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.tcp.dst_port;
        transition accept;
    }

    state parse_inner_sctp_scope1 {
        pkt.extract(hdr.inner.sctp);
        eg_md.lkp_1.l4_src_port = hdr.inner.sctp.src_port;
        eg_md.lkp_1.l4_dst_port = hdr.inner.sctp.dst_port;
        transition accept;
    }



    ///////////////////////////////////////////////////////////////////////////
    // Tunnels - Inner
    ///////////////////////////////////////////////////////////////////////////

    //-------------------------------------------------------------------------
    // Internet Protocol (IP) - Inner
    //-------------------------------------------------------------------------

    state parse_inner_ipinip_set_tunnel_scope1 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_inner_ipv4;



    }

    state parse_inner_ipv6inip_set_tunnel_scope1 {


        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_IPINIP;
        eg_md.lkp_1.tunnel_id = 0;

        transition parse_inner_inner_ipv6;



    }


//     //-------------------------------------------------------------------------
//     // Encapsulating Security Payload (ESP) - Inner
//     //-------------------------------------------------------------------------
//      
//     state parse_inner_esp_overload_scope1 {
// #ifdef PARSER_L4_PORT_OVERLOAD   
//         eg_md.lkp_1.l4_src_port = pkt.lookahead<esp_h>().spi_hi;
//         eg_md.lkp_1.l4_dst_port = pkt.lookahead<esp_h>().spi_lo;
// #endif // PARSER_L4_PORT_OVERLOAD
//         transition accept;
//     }


    //-------------------------------------------------------------------------
    // Generic Routing Encapsulation (GRE) - Inner
    //-------------------------------------------------------------------------



    state parse_inner_gre_scope1 {
        gre_h snoop_gre = pkt.lookahead<gre_h>();
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_gre.C,
            snoop_gre.R,
            snoop_gre.K,
            snoop_gre.S,
            snoop_gre.s,
            snoop_gre.recurse,
            snoop_gre.flags,
            snoop_gre.version) {

          // C R K S s r f v
            (0,0,0,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (1,0,0,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (0,0,1,0,0,0,0,0): parse_inner_gre_qualified_scope1;
            (0,0,0,1,0,0,0,0): parse_inner_gre_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gre_qualified_scope1 {
        pkt.extract(hdr.inner.gre);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GRE;
        eg_md.lkp_1.tunnel_id = 0;

        transition select(
            hdr.inner.gre.C,
            hdr.inner.gre.K,
            hdr.inner.gre.S,
            hdr.inner.gre.proto) {

            (0,0,0,0x0800): parse_inner_inner_ipv4;
            (0,0,0,0x86dd): parse_inner_inner_ipv6;
            (1,0,0,_): parse_inner_gre_optional;
            (0,1,0,_): parse_inner_gre_optional;
            (0,0,1,_): parse_inner_gre_optional;
            default: accept;
        }
    }

    state parse_inner_gre_optional {
        pkt.extract(hdr.inner.gre_optional);
        transition select(hdr.inner.gre.proto) {
            0x0800: parse_inner_inner_ipv4;
            0x86dd: parse_inner_inner_ipv6;
            default: accept;
        }
    }






    //-------------------------------------------------------------------------
    // GPRS (General Packet Radio Service) Tunneling Protocol (GTP) - Inner
    //-------------------------------------------------------------------------
    // Based on pseudo code from Glenn (see email from 03/11/2019):

    // GTP-C
    //-------------------------------------------------------------------------
    // Simply set tunnel type and ID for policy via lookahead (no extraction).

    state parse_inner_gtp_c_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            pkt.lookahead<gtp_v2_base_h>().version,
            pkt.lookahead<gtp_v2_base_h>().T
        ) {
            (2, 1): parse_inner_gtp_c_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gtp_c_qualified_scope1 {
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPC;
        eg_md.lkp_1.tunnel_id = pkt.lookahead<gtp_v2_base_h>().teid;
        transition accept;
    }


    // GTP-U
    //-------------------------------------------------------------------------
    // Only supports optional header for sequence-number
    // Does not support parsing (TLV) extension headers

    state parse_inner_gtp_u_scope1 {
        gtp_v1_base_h snoop_inner_gtp_v1_base = pkt.lookahead<gtp_v1_base_h>();
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_UNSUPPORTED;

        transition select(
            snoop_inner_gtp_v1_base.version,
            snoop_inner_gtp_v1_base.PT,
            snoop_inner_gtp_v1_base.E,
            snoop_inner_gtp_v1_base.S,
            snoop_inner_gtp_v1_base.PN) {

            (1, 1, 0, 0, 0): parse_inner_gtp_u_qualified_scope1;
            (1, 1, 0, 1, 0): parse_inner_gtp_u_with_optional_qualified_scope1;
            default: accept;
        }
    }

    state parse_inner_gtp_u_qualified_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(pkt.lookahead<bit<4>>()) {
            4: parse_inner_inner_ipv4;
            6: parse_inner_inner_ipv6;
            default: accept;
        }
    }

    state parse_inner_gtp_u_with_optional_qualified_scope1 {
        pkt.extract(hdr.inner.gtp_v1_base);
        pkt.extract(hdr.inner.gtp_v1_optional);
        eg_md.lkp_1.tunnel_type = SWITCH_TUNNEL_TYPE_GTPU;
        eg_md.lkp_1.tunnel_id = hdr.inner.gtp_v1_base.teid;
        transition select(
            hdr.inner.gtp_v1_base.E,
            pkt.lookahead<bit<4>>()) {
            (0, 4): parse_inner_inner_ipv4;
            (0, 6): parse_inner_inner_ipv6;
            default: accept;
        }
    }





    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////
    // "Inner Inner" Headers / Stack
    ///////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////

    state parse_inner_inner_ipv4 {
     hdr.inner_inner.ipv4.setValid();

        hdr.inner_inner.ipv4.total_len = pkt.lookahead<ipv4_h>().total_len;


     transition accept;
    }
    state parse_inner_inner_ipv6 {
  hdr.inner_inner.ipv6.setValid();

        hdr.inner_inner.ipv6.payload_len = pkt.lookahead<ipv6_truncated_h>().payload_len;


     transition accept;
    }

}
# 63 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_set_lkp.p4" 1




// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control EgressSetLookup(
 in switch_header_outer_t hdr_1, // src
 in switch_header_inner_t hdr_2, // src
 inout switch_egress_metadata_t eg_md, // dst

 in egress_intrinsic_metadata_t eg_intr_md
) {

 // Override whatever the parser set "ip_type" to.  Doing so allows the
 // signal to fit when normally it doesn't.  This code should be only
 // temporary, and can be removed at a later date when a better compiler
 // is available....

 // Set "ip_tos" here:
 //
 // ipv6: would like to do this stuff in the parser, but can't because tos
 // field isn't byte aligned...
 //
 // ipv4: would like to do this stuff in the parser, but get the following error:
 //   "error: Field is extracted in the parser into multiple containers, but
 //    the container slices after the first aren't byte aligned"

 // -----------------------------
 // Table: Hdr to Lkp
 // -----------------------------



 action set_lkp_1_type_tos_v4() {
  eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr_1.ipv4.tos;
 }

 action set_lkp_1_type_tos_v6() {
  eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
  eg_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
 }

 action set_lkp_1_type_tos_none() {
  eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
 }

 action set_lkp_2_v4() {
  eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
//		eg_md.lkp_1.ip_tos = hdr_2.ipv4.tos;
 }

 action set_lkp_2_v6() {
  eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
  eg_md.lkp_1.ip_tos = hdr_2.ipv6.tos;
 }

 action set_lkp_2_none() {
  eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
 }

 table set_lkp_1_type_tos {
  key = {
   eg_md.nsh_md.scope : exact;
   hdr_1.ipv4.isValid() : exact;
   hdr_1.ipv6.isValid() : exact;
   hdr_2.ipv4.isValid() : exact;
   hdr_2.ipv6.isValid() : exact;
  }

  actions = {
   NoAction;
   set_lkp_1_type_tos_v4;
   set_lkp_1_type_tos_v6;
   set_lkp_1_type_tos_none;
   set_lkp_2_v4;
   set_lkp_2_v6;
   set_lkp_2_none;
  }

  const entries = {
/*
			(0, true,  false, _,     _    ) : set_lkp_1_type_tos_v4();   // inner is a don't care
			(0, false, true,  _,     _    ) : set_lkp_1_type_tos_v6();   // inner is a don't care
			(0, false, false, _,     _    ) : set_lkp_1_type_tos_none(); // inner is a don't care
			(1, _,     _,     true,  false) : set_lkp_2_v4();   // outer is a don't care
			(1, _,     _,     false, true ) : set_lkp_2_v6();   // outer is a don't care
			(1, _,     _,     false, false) : set_lkp_2_none(); // outer is a don't care
*/
   (1, true, false, false, false) : set_lkp_1_type_tos_v4(); // note: inner is a don't care
   (1, true, false, true, false) : set_lkp_1_type_tos_v4(); // note: inner is a don't care
   (1, true, false, false, true ) : set_lkp_1_type_tos_v4(); // note: inner is a don't care
   (1, true, false, true, true ) : set_lkp_1_type_tos_v4(); // note: inner is a don't care

   (1, false, true, false, false) : set_lkp_1_type_tos_v6(); // note: inner is a don't care
   (1, false, true, true, false) : set_lkp_1_type_tos_v6(); // note: inner is a don't care
   (1, false, true, false, true ) : set_lkp_1_type_tos_v6(); // note: inner is a don't care
   (1, false, true, true, true ) : set_lkp_1_type_tos_v6(); // note: inner is a don't care

   (1, false, false, false, false) : set_lkp_1_type_tos_none(); // note: inner is a don't care
   (1, false, false, true, false) : set_lkp_1_type_tos_none(); // note: inner is a don't care
   (1, false, false, false, true ) : set_lkp_1_type_tos_none(); // note: inner is a don't care
   (1, false, false, true, true ) : set_lkp_1_type_tos_none(); // note: inner is a don't care

   (2, false, false, true, false) : set_lkp_2_v4(); // note: outer is a don't care
   (2, true, false, true, false) : set_lkp_2_v4(); // note: outer is a don't care
   (2, false, true, true, false) : set_lkp_2_v4(); // note: outer is a don't care
   (2, true, true, true, false) : set_lkp_2_v4(); // note: outer is a don't care

   (2, false, false, false, true ) : set_lkp_2_v6(); // note: outer is a don't care
   (2, true, false, false, true ) : set_lkp_2_v6(); // note: outer is a don't care
   (2, false, true, false, true ) : set_lkp_2_v6(); // note: outer is a don't care
   (2, true, true, false, true ) : set_lkp_2_v6(); // note: outer is a don't care

   (2, false, false, false, false) : set_lkp_2_none(); // note: outer is a don't care
   (2, true, false, false, false) : set_lkp_2_none(); // note: outer is a don't care
   (2, false, true, false, false) : set_lkp_2_none(); // note: outer is a don't care
   (2, true, true, false, false) : set_lkp_2_none(); // note: outer is a don't care
  }
  const default_action = NoAction;
 }
# 168 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_set_lkp.p4"
 // -----------------------------
 // Table: Lkp to Lkp
 // -----------------------------

 action set_lkp_1_next_lyr_valid_value(bool value) {
  eg_md.lkp_1.next_lyr_valid = value;
 }

 table set_lkp_1_next_lyr_valid {
  key = {
   eg_md.lkp_1.tunnel_type : exact;
  }
  actions = { set_lkp_1_next_lyr_valid_value; }
  const entries = {
   (SWITCH_TUNNEL_TYPE_NONE) : set_lkp_1_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_VXLAN) : set_lkp_1_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_IPINIP) : set_lkp_1_next_lyr_valid_value(true); // filler entries to get rid of compiler bug when less than 4 constant entries
   (SWITCH_TUNNEL_TYPE_GTPC) : set_lkp_1_next_lyr_valid_value(false);
   (SWITCH_TUNNEL_TYPE_UNSUPPORTED) : set_lkp_1_next_lyr_valid_value(false);
  }
  const default_action = set_lkp_1_next_lyr_valid_value(true);
 }

 // -----------------------------
 // Apply
 // -----------------------------

 apply {

//		eg_md.tunnel_1.terminate = false;


/*
		if(eg_md.nsh_md.scope == 1) {
			if     (hdr_1.ipv4.isValid())
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
			else if(hdr_1.ipv6.isValid()) {
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
				eg_md.lkp_1.ip_tos = hdr_1.ipv6.tos;
			} else
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		} else {
			if     (hdr_2.ipv4.isValid())
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
			else if(hdr_2.ipv6.isValid()) {
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
				eg_md.lkp_1.ip_tos = hdr_2.ipv6.tos;
			} else
				eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
		}
*/
  set_lkp_1_type_tos.apply();
# 232 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_set_lkp.p4"
  // -----------------------------------------------------------------------


/*
//		eg_md.lkp_1.next_lyr_valid = true;

		if((eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_NONE) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_GTPC) && (eg_md.lkp_1.tunnel_type != SWITCH_TUNNEL_TYPE_UNSUPPORTED)) {
			eg_md.lkp_1.next_lyr_valid = true;
		} else {
			eg_md.lkp_1.next_lyr_valid = false;
		}
*/
  set_lkp_1_next_lyr_valid.apply();


  // -----------------------------------------------------------------------

  // This code does not work for detecting copy-to-cpu packets, due to bug in chip....
  // (note: leaving in, because removing it causes design to take 21 stages?!?!)
/*
		if((eg_intr_md.egress_rid == 0) && (eg_intr_md.egress_rid_first == 1)) {
			eg_md.flags.bypass_egress = true;
		}
*/
 }
}
# 64 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4" 1




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sff_top.p4" 1




control npb_egr_sff_top (
 inout switch_header_transport_t hdr_0,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

 // =========================================================================
 // Table #1: 
 // =========================================================================

 // RFC 8300, Page 9: Decrementing (the TTL) from an incoming value of 0 shall
 // result in a TTL value of 63.   The handling of an incoming 0 TTL allows
 // for better, although not perfect, interoperation with pre-standard
 // implementations that do not support this TTL field.

    action new_ttl(bit<6> ttl) {
        eg_md.nsh_md.ttl = ttl;
    }

    action discard() {
//        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { eg_md.nsh_md.ttl : exact; }
        actions = { new_ttl; discard; }
  size = 64;
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
 // Table #2: SFF - Reformat to slx style, if needed
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter


 action drop_pkt(
 ) {
  stats.count();




 }

 // =====================================

 action fwd_pkt_nsh_hdr_ver_1(
  bit<24> tool_address
 ) {
  stats.count();

  // hdr reformat to old type 1 format (slx-style)
  eg_md.nsh_md.spi = tool_address;
  eg_md.nsh_md.si = 0x1;

  eg_md.nsh_md.ver = 0x1;
//		eg_md.nsh_md.reserved3  = 0x0; // not necessary, but allows the design to fit.
 }

 // =====================================

 action fwd_pkt_nsh_hdr_ver_2(
 ) {
  stats.count();

  eg_md.nsh_md.ver = 0x2;
//		eg_md.nsh_md.reserved3  = 0x0; // not necessary, but allows the design to fit.
 }

 // =====================================

 table egr_sff_fib {
  key = {
   eg_md.nsh_md.spi : exact @name("spi");
   eg_md.nsh_md.si : exact @name("si");
  }

  actions = {
   drop_pkt;
   fwd_pkt_nsh_hdr_ver_1;
   fwd_pkt_nsh_hdr_ver_2;
  }

  // Derek: drop packet on miss...
  //
  // RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
  // do not correspond to a valid next hop in a valid SFP, that packet MUST
  // be dropped by the SFF.

//		const default_action = drop_pkt;
  const default_action = fwd_pkt_nsh_hdr_ver_2; // for backwards compatibility with firmware
  size = NPB_EGR_SFF_ARP_TABLE_DEPTH;
  counters = stats;
 }


 // =========================================================================
 // Table #3: Add header, if needed
 // =========================================================================

    action end_of_path() {
//		eg_md.nsh_md.setInvalid(); // it's the end of the line for this nsh chain....
    }

 action middle_of_path_drop() {
  eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
 }

 action middle_of_path() {

            // note: according to p4 spec, initializing a header also automatically sets it valid.
//          hdr_0.nsh_type1.setValid();
            hdr_0.nsh_type1 = {
                version = 0x0,
                o = 0x0,
                reserved = 0x0,
                ttl = (bit<6>)eg_md.nsh_md.ttl, // 63 is the rfc's recommended default value (0 will get dec'ed to 63).
                len = 0x6, // in 4-byte words (1 + 1 + 4).
                reserved2 = 0x0,
                md_type = 0x1, // 0 = reserved, 1 = fixed len, 2 = variable len.
                next_proto = 0x3, // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

                spi = (bit<24>)eg_md.nsh_md.spi,
                si = eg_md.nsh_md.si,

                ver = eg_md.nsh_md.ver,
                reserved3 = 0x0,

//				lag_hash   = eg_md.hash[switch_hash_width-1:switch_hash_width/2],
    lag_hash = eg_md.hash[31:16],




                vpn = (bit<16>)eg_md.nsh_md.vpn,
                sfc_data = 0x0,

                reserved4 = 0x0,
                scope = (bit<8>)eg_md.nsh_md.scope,
                sap = (bit<16>)eg_md.nsh_md.sap,




                timestamp = 0

  };
 }

    table npb_egr_sff_final {
        key = {
   eg_md.nsh_md.end_of_path : exact;
   eg_md.nsh_md.ttl : ternary;
   eg_md.nsh_md.si : ternary;
  }
        actions = { end_of_path; middle_of_path_drop; middle_of_path; }
  default_action = middle_of_path;
        const entries = {
            (true, _, _ ) : end_of_path;
            (false, 0, _ ) : middle_of_path_drop;
            (false, _, 0 ) : middle_of_path_drop;
  }
 }

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // =============================
  // SFF (continued)
  // =============================

  // -------------------------------------
  // Check TTL & SI
  // -------------------------------------

  // RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
  // will discard any NSH packet with an SI of 0, as there will be no
  // valid next SF information."

  npb_egr_sff_dec_ttl.apply();

  // -------------------------------------
  // Fowrarding Lookup
  // -------------------------------------

  // Derek: The forwarding lookup would normally
  // be done here.  However, since Tofino requires the outport
  // to set in ingress, it has to be done there instead....

  egr_sff_fib.apply();




  npb_egr_sff_final.apply();
 }

}
# 6 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4" 2

# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4" 1



# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_hdr_strip.p4" 1



control Npb_Egr_Sf_Proxy_Hdr_Strip (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // -----------------------------------------------------------------
 // Table
 // -----------------------------------------------------------------

 action hdr_strip_1__from_vlan_tag0__to_eth() {
  hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();
 }

 action hdr_strip_1__from_vlan_tag0__to_e_tag() {
  hdr_1.e_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();
 }

 action hdr_strip_1__from_vlan_tag0__to_vn_tag() {
  hdr_1.vn_tag.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.vlan_tag[0].setInvalid();
 }

 // --------------------------------

 action hdr_strip_1__from_vn_tag_____to_eth() {
  hdr_1.ethernet.ether_type = hdr_1.vn_tag.ether_type;
  hdr_1.vn_tag.setInvalid();
 }

 // --------------------------------

 action hdr_strip_1__from_e_tag______to_eth() {
  hdr_1.ethernet.ether_type = hdr_1.e_tag.ether_type;
  hdr_1.e_tag.setInvalid();
 }

 // --------------------------------

 action hdr_strip_2__from_vlan_tag0__to_eth() {
  // tag0 to eth
  hdr_1.ethernet.ether_type = hdr_1.vlan_tag[0].ether_type;
  hdr_1.e_tag.setInvalid();
  hdr_1.vn_tag.setInvalid();
  hdr_1.vlan_tag[0].setInvalid();
 }

 // --------------------------------

 @name("hdr_strip")
 table hdr_strip {
  key = {
   hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;

   eg_md.nsh_md.strip_tag_vlan : ternary;
  }

  actions = {
   NoAction();
//			hdr_strip_1__from_e_tag______to_eth();
//			hdr_strip_1__from_vn_tag_____to_eth();
   hdr_strip_1__from_vlan_tag0__to_eth();
   hdr_strip_1__from_vlan_tag0__to_e_tag();
   hdr_strip_1__from_vlan_tag0__to_vn_tag();

   hdr_strip_2__from_vlan_tag0__to_eth();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // ==============         ==============      
   // Packet                 Enables
   // {vn/e,  vlan}          {e/vn,  vlan}
   // ==============         ==============      
   // {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
   // {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
   // {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
   // {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
   // --------------         --------------      
   // {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
   // {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
   // {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
   // {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
   // --------------         --------------      
   // {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
   // {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
   // {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
   // {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
   // --------------         --------------      
   // {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
   // {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
   // {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
   // {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet

   // case 0 (---- + vlan delete, only vlan          are valid):
   ( true, true ): hdr_strip_1__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

  }
 }

 // --------------------------------

 @name("hdr_strip")
 table hdr_strip_etag {
  key = {
   hdr_1.e_tag.isValid() : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;

   eg_md.nsh_md.strip_tag_e : ternary;
   eg_md.nsh_md.strip_tag_vlan : ternary;
  }

  actions = {
   NoAction();
   hdr_strip_1__from_e_tag______to_eth();
//			hdr_strip_1__from_vn_tag_____to_eth();
   hdr_strip_1__from_vlan_tag0__to_eth();
   hdr_strip_1__from_vlan_tag0__to_e_tag();
   hdr_strip_1__from_vlan_tag0__to_vn_tag();

   hdr_strip_2__from_vlan_tag0__to_eth();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // ==============         ==============      
   // Packet                 Enables
   // {vn/e,  vlan}          {e/vn,  vlan}
   // ==============         ==============      
   // {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
   // {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
   // {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
   // {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
   // --------------         --------------      
   // {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
   // {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
   // {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
   // {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
   // --------------         --------------      
   // {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
   // {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
   // {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
   // {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
   // --------------         --------------      
   // {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
   // {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
   // {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
   // {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet

   // case 0 (---- + vlan delete, only vlan          are valid):
   (false, true, _, true ): hdr_strip_1__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

   // case 1 (e/vn + ---- delete, only e/vn          are valid):
   (true, false, true, _ ): hdr_strip_1__from_e_tag______to_eth(); // pkt: 0   tags + e  ==> delete e        (e    to eth)

   // case 2 (---  + vlan delete, both e/vn and vlan are valid):
   (true, true, false, true ): hdr_strip_1__from_vlan_tag0__to_e_tag(); // pkt: 1-2 tags + e  ==> delete vlan0    (vlan to e)

   // case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
   (true, true, true, false): hdr_strip_1__from_e_tag______to_eth(); // pkt: 1-2 tags + e  ==> delete e        (e    to eth)

   // case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
   (true, true, true, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + e  ==> delete vlan0+e  (vlan to eth)
  }
 }

 // --------------------------------

 @name("hdr_strip")
 table hdr_strip_vntag {
  key = {
   hdr_1.vn_tag.isValid() : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;

   eg_md.nsh_md.strip_tag_vn : ternary;
   eg_md.nsh_md.strip_tag_vlan : ternary;
  }

  actions = {
   NoAction();
//			hdr_strip_1__from_e_tag______to_eth();
   hdr_strip_1__from_vn_tag_____to_eth();
   hdr_strip_1__from_vlan_tag0__to_eth();
   hdr_strip_1__from_vlan_tag0__to_e_tag();
   hdr_strip_1__from_vlan_tag0__to_vn_tag();

   hdr_strip_2__from_vlan_tag0__to_eth();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // ==============         ==============      
   // Packet                 Enables
   // {vn/e,  vlan}          {e/vn,  vlan}
   // ==============         ==============      
   // {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
   // {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
   // {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
   // {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
   // --------------         --------------      
   // {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
   // {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
   // {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
   // {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
   // --------------         --------------      
   // {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
   // {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
   // {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
   // {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
   // --------------         --------------      
   // {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
   // {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
   // {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
   // {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet

   // case 0 (---- + vlan delete, only vlan          are valid):
   ( false, true, _, true ): hdr_strip_1__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

   // case 1 (e/vn + ---- delete, only e/vn          are valid):
   ( true, false, true, _ ): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 0   tags + vn ==> delete vn       (vn   to eth)

   // case 2 (---  + vlan delete, both e/vn and vlan are valid):
   ( true, true, false, true ): hdr_strip_1__from_vlan_tag0__to_vn_tag(); // pkt: 1-2 tags + vn ==> delete vlan0    (vlan to vn)

   // case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
   ( true, true, true, false): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 1-2 tags + vn ==> delete vn       (vn   to eth)

   // case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
   ( true, true, true, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + vn ==> delete vlan0+vn (vlan to eth)
  }
 }

 // --------------------------------

 @name("hdr_strip")
 table hdr_strip_etag_vntag {
  key = {
   hdr_1.e_tag.isValid() : exact;
   hdr_1.vn_tag.isValid() : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
//			hdr_1.vlan_tag[1].isValid() : exact;

   eg_md.nsh_md.strip_tag_e : ternary;
   eg_md.nsh_md.strip_tag_vn : ternary;
   eg_md.nsh_md.strip_tag_vlan : ternary;
  }

  actions = {
   NoAction();
   hdr_strip_1__from_e_tag______to_eth();
   hdr_strip_1__from_vn_tag_____to_eth();
   hdr_strip_1__from_vlan_tag0__to_eth();
   hdr_strip_1__from_vlan_tag0__to_e_tag();
   hdr_strip_1__from_vlan_tag0__to_vn_tag();

   hdr_strip_2__from_vlan_tag0__to_eth();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // ==============         ==============      
   // Packet                 Enables
   // {vn/e,  vlan}          {e/vn,  vlan}
   // ==============         ==============      
   // {false, false}         {false, false}          --> nothing   enabled, nothing in pkt   --> no action
   // {false, false}         {false, true }          --> vlan      enabled, nothing in pkt   --> no action
   // {false, false}         {true,  false}          --> vn        enabled, nothing in pkt   --> no action
   // {false, false}         {true,  true }          --> vn + vlan enabled, nothing in pkt   --> no action
   // --------------         --------------      
   // {false, true }         {false, false}          --> nothing   enabled, vlan in pkt      --> no action
   // {false, true }         {false, true }          --> vlan      enabled, vlan in pkt      --> vlan to eth : case 0
   // {false, true }         {true,  false}          --> vn        enabled, vlan in pkt      --> no action
   // {false, true }         {true,  true }          --> vn + vlan enabled, vlan in pkt      --> vlan to eth : case 0
   // --------------         --------------      
   // {true,  false}         {false, false}          --> nothing   enabled, vn in pkt        --> no action
   // {true,  false}         {false, true }          --> vlan      enabled, vn in pkt        --> no action
   // {true,  false}         {true,  false}          --> vn        enabled, vn in pkt        --> vn   to eth : case 1
   // {true,  false}         {true,  true }          --> vn + vlan enabled  vn in pkt        --> vn   to eth : case 1
   // --------------         --------------      
   // {true,  true }         {false, false}          --> nothing   enabled, vn + vlan in pkt --> no action
   // {true,  true }         {false, true }          --> vlan      enabled, vn + vlan in pkt --> vlan to VN  : case 2
   // {true,  true }         {true,  false}          --> vn        enabled, vn + vlan in pkt --> vn   to eth : case 3
   // {true,  true }         {true,  true }          --> vn + vlan enabled, vn + vlan in pkt --> vlan to eth : case 4 (double delete case)

// ipv4,	 vl[0], vn,    e,   ethernet

   // case 0 (---- + vlan delete, only vlan          are valid):
   (false, false, true, _, _, true ): hdr_strip_1__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + -  ==> delete vlan0    (vlan to eth)

   // case 1 (e/vn + ---- delete, only e/vn          are valid):
   (true, false, false, true, _, _ ): hdr_strip_1__from_e_tag______to_eth(); // pkt: 0   tags + e  ==> delete e        (e    to eth)
   (false, true, false, _, true, _ ): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 0   tags + vn ==> delete vn       (vn   to eth)

   // case 2 (---  + vlan delete, both e/vn and vlan are valid):
   (true, false, true, false, _, true ): hdr_strip_1__from_vlan_tag0__to_e_tag(); // pkt: 1-2 tags + e  ==> delete vlan0    (vlan to e)
   (false, true, true, _, false, true ): hdr_strip_1__from_vlan_tag0__to_vn_tag(); // pkt: 1-2 tags + vn ==> delete vlan0    (vlan to vn)

   // case 3 (e/vn + ---- delete, both e/vn and vlan are valid):
   (true, false, true, true, _, false): hdr_strip_1__from_e_tag______to_eth(); // pkt: 1-2 tags + e  ==> delete e        (e    to eth)
   (false, true, true, _, true, false): hdr_strip_1__from_vn_tag_____to_eth(); // pkt: 1-2 tags + vn ==> delete vn       (vn   to eth)

   // case 4 (e/vn + vlan delete, both e/vn and vlan are valid): -- double delete case
   (true, false, true, true, _, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + e  ==> delete vlan0+e  (vlan to eth)
   (false, true, true, _, true, true ): hdr_strip_2__from_vlan_tag0__to_eth(); // pkt: 1-2 tags + vn ==> delete vlan0+vn (vlan to eth)
  }
 }

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
  if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
   hdr_strip_etag_vntag.apply();
  } else if(OUTER_ETAG_ENABLE) {
   hdr_strip_etag.apply();
  } else if(OUTER_VNTAG_ENABLE) {
   hdr_strip_vntag.apply();
  } else {
   hdr_strip.apply();
  }
 }

}
# 5 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_hdr_edit.p4" 1



control Npb_Egr_Sf_Proxy_Hdr_Edit (
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 bool hit = false;
 bit<3> pcp_ = 0;
 vlan_id_t vid_ = 0;

 bool hdr_1_ethernet_isEtypeStag;
 bool hdr_1_e_tag_isEtypeStag;
 bool hdr_1_vn_tag_isEtypeStag;

 // -----------------------------------------------------------------
 // Table: bd_to_vlan_mapping
 // -----------------------------------------------------------------

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats;

    action set_vlan_tagged(vlan_id_t vid, bit<3> pcp) {
  stats.count();

  hit = true;
  pcp_ = pcp;
  vid_ = vid;
    }

 action no_action() {
  stats.count();
 }

    table bd_to_vlan_mapping {
        key = { eg_md.nsh_md.add_tag_vlan_bd : exact @name("bd"); }
        actions = {
//			NoAction;
   no_action;
   set_vlan_tagged;
        }

        const default_action = no_action;
        size = 512;
  counters = stats;
    }

 // -----------------------------------------------------------------
 // Table: hdr_add
 // -----------------------------------------------------------------

 // helper action
 action hdr_add_vlan_tag(vlan_id_t vid, bit<3> pcp) {
  // copy from 0 to 1
//		hdr_1.vlan_tag[1].setValid(); // will be set by the individual actions
  hdr_1.vlan_tag[1].pcp = hdr_1.vlan_tag[0].pcp;
  hdr_1.vlan_tag[1].cfi = hdr_1.vlan_tag[0].cfi;
  hdr_1.vlan_tag[1].vid = hdr_1.vlan_tag[0].vid;
  hdr_1.vlan_tag[1].ether_type = hdr_1.vlan_tag[0].ether_type;

  // add 0
  hdr_1.vlan_tag[0].setValid(); // might already be valid, which is fine
  hdr_1.vlan_tag[0].pcp = pcp;
  hdr_1.vlan_tag[0].cfi = 0;
  hdr_1.vlan_tag[0].vid = vid;
//		hdr_1.vlan_tag[0].ether_type = ?; // will be set by the individual actions
 }

 // --------------------------------

 action hdr_add_0__from_eth_____to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

  hdr_1.ethernet.ether_type = 0x8100;
 }

 action hdr_add_0__from_e_tag___to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

  hdr_1.e_tag.ether_type = 0x8100;
 }

 action hdr_add_0__from_vn_tag__to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

  hdr_1.vn_tag.ether_type = 0x8100;
 }

 // --------------------------------

 action hdr_add_1__from_eth_____to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.ethernet.ether_type;

  hdr_1.ethernet.ether_type = 0x8100;
 }

 action hdr_add_1__from_e_tag___to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.e_tag.ether_type;

  hdr_1.e_tag.ether_type = 0x8100;
 }

 action hdr_add_1__from_vn_tag__to_vlan_tag0() {
  hdr_add_vlan_tag(vid_, pcp_);
  hdr_1.vlan_tag[1].setValid();
  hdr_1.vlan_tag[0].ether_type = hdr_1.vn_tag.ether_type;

  hdr_1.vn_tag.ether_type = 0x8100;
 }

 // --------------------------------

 @name("hdr_add")
 table hdr_add {
  key = {
   hit : exact;

   hdr_1_ethernet_isEtypeStag : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction();
   hdr_add_0__from_eth_____to_vlan_tag0();
//			hdr_add_0__from_e_tag___to_vlan_tag0();
//			hdr_add_0__from_vn_tag__to_vlan_tag0();
   hdr_add_1__from_eth_____to_vlan_tag0();
//			hdr_add_1__from_e_tag___to_vlan_tag0();
//			hdr_add_1__from_vn_tag__to_vlan_tag0();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // =====================
   // Packet               
   // {e/vn,  vl[0], vl[1]}
   // =====================
   // {false, false, false}   --> empty,      disabled --> no action
   // {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
   // {false, false, true }   --> impossible, disabled --> no action
   // {false, false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {false, true,  false}   --> one full,   disabled --> no action
   // {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
   // {false, true,  true }   --> both full,  disabled --> no action
   // {false, true,  true }   --> both full,  enabled  --> no action
   // ---------------------
   // {true,  false, false}   --> empty,      disabled --> no action
   // {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
   // {true,  false, true }   --> impossible, disabled --> no action
   // {true,  false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {true,  true,  false}   --> one full,   disabled --> no action
   // {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
   // {true,  true,  true }   --> both full,  disabled --> no action
   // {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4

   // ===    ======   =============   =============   =====    =====
   // hit    eth      e               vn              vl[0]    vl[1]
   // ===    ======   =============   =============   =====    =====

   // case 0 (eth  to vlan)
   (true, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

   // case 1 (eth  to vlan)
   (true, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
  }
 }

 // --------------------------------

 @name("hdr_add")
 table hdr_add_etag {
  key = {
   hit : exact;

   hdr_1_ethernet_isEtypeStag : exact;
   hdr_1.e_tag.isValid() : exact;
   hdr_1_e_tag_isEtypeStag : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction();
   hdr_add_0__from_eth_____to_vlan_tag0();
   hdr_add_0__from_e_tag___to_vlan_tag0();
//			hdr_add_0__from_vn_tag__to_vlan_tag0();
   hdr_add_1__from_eth_____to_vlan_tag0();
   hdr_add_1__from_e_tag___to_vlan_tag0();
//			hdr_add_1__from_vn_tag__to_vlan_tag0();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // =====================
   // Packet               
   // {e/vn,  vl[0], vl[1]}
   // =====================
   // {false, false, false}   --> empty,      disabled --> no action
   // {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
   // {false, false, true }   --> impossible, disabled --> no action
   // {false, false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {false, true,  false}   --> one full,   disabled --> no action
   // {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
   // {false, true,  true }   --> both full,  disabled --> no action
   // {false, true,  true }   --> both full,  enabled  --> no action
   // ---------------------
   // {true,  false, false}   --> empty,      disabled --> no action
   // {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
   // {true,  false, true }   --> impossible, disabled --> no action
   // {true,  false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {true,  true,  false}   --> one full,   disabled --> no action
   // {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
   // {true,  true,  true }   --> both full,  disabled --> no action
   // {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4

   // ===    ======   =============   =============   =====    =====
   // hit    eth      e               vn              vl[0]    vl[1]
   // ===    ======   =============   =============   =====    =====

   // case 0 (eth  to vlan)
   (true, false, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (true, false, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

   // case 1 (eth  to vlan)
   (true, false, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (true, false, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

   // case 2 (e/vn to vlan)
   (true, false, true, false, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty

   // case 3 (e/vn to vlan)
   (true, false, true, false, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full
  }
 }

 // --------------------------------

 @name("hdr_add")
 table hdr_add_vntag {
  key = {
   hit : exact;

   hdr_1_ethernet_isEtypeStag : exact;
   hdr_1.vn_tag.isValid() : exact;
   hdr_1_vn_tag_isEtypeStag : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction();
   hdr_add_0__from_eth_____to_vlan_tag0();
//			hdr_add_0__from_e_tag___to_vlan_tag0();
   hdr_add_0__from_vn_tag__to_vlan_tag0();
   hdr_add_1__from_eth_____to_vlan_tag0();
//			hdr_add_1__from_e_tag___to_vlan_tag0();
   hdr_add_1__from_vn_tag__to_vlan_tag0();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // =====================
   // Packet               
   // {e/vn,  vl[0], vl[1]}
   // =====================
   // {false, false, false}   --> empty,      disabled --> no action
   // {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
   // {false, false, true }   --> impossible, disabled --> no action
   // {false, false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {false, true,  false}   --> one full,   disabled --> no action
   // {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
   // {false, true,  true }   --> both full,  disabled --> no action
   // {false, true,  true }   --> both full,  enabled  --> no action
   // ---------------------
   // {true,  false, false}   --> empty,      disabled --> no action
   // {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
   // {true,  false, true }   --> impossible, disabled --> no action
   // {true,  false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {true,  true,  false}   --> one full,   disabled --> no action
   // {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
   // {true,  true,  true }   --> both full,  disabled --> no action
   // {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4

   // ===    ======   =============   =============   =====    =====
   // hit    eth      e               vn              vl[0]    vl[1]
   // ===    ======   =============   =============   =====    =====

   // case 0 (eth  to vlan)
   (true, false, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (true, false, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

   // case 1 (eth  to vlan)
   (true, false, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (true, false, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

   // case 2 (e/vn to vlan)
   (true, false, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty
   (true, false, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty

   // case 3 (e/vn to vlan)
   (true, false, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
   (true, false, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
  }
 }

 // --------------------------------

 @name("hdr_add")
 table hdr_add_etag_vntag {
  key = {
   hit : exact;

   hdr_1_ethernet_isEtypeStag : exact;
   hdr_1.e_tag.isValid() : exact;
   hdr_1_e_tag_isEtypeStag : exact;
   hdr_1.vn_tag.isValid() : exact;
   hdr_1_vn_tag_isEtypeStag : exact;
   hdr_1.vlan_tag[0].isValid() : exact;
   hdr_1.vlan_tag[1].isValid() : exact;
  }

  actions = {
   NoAction();
   hdr_add_0__from_eth_____to_vlan_tag0();
   hdr_add_0__from_e_tag___to_vlan_tag0();
   hdr_add_0__from_vn_tag__to_vlan_tag0();
   hdr_add_1__from_eth_____to_vlan_tag0();
   hdr_add_1__from_e_tag___to_vlan_tag0();
   hdr_add_1__from_vn_tag__to_vlan_tag0();
  }
  const entries = {

   // My notes on a complete truth table for just two things (e/vn and vlan)
   // =====================
   // Packet               
   // {e/vn,  vl[0], vl[1]}
   // =====================
   // {false, false, false}   --> empty,      disabled --> no action
   // {false, false, false}   --> empty,      enabled  --> eth  to vlan : case 0
   // {false, false, true }   --> impossible, disabled --> no action
   // {false, false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {false, true,  false}   --> one full,   disabled --> no action
   // {false, true,  false}   --> one full,   enabled  --> eth  to vlan : case 1
   // {false, true,  true }   --> both full,  disabled --> no action
   // {false, true,  true }   --> both full,  enabled  --> no action
   // ---------------------
   // {true,  false, false}   --> empty,      disabled --> no action
   // {true,  false, false}   --> empty,      enabled  --> e/vn to vlan : case 2
   // {true,  false, true }   --> impossible, disabled --> no action
   // {true,  false, true }   --> impossible, enabled  --> no action
   // ---------------------
   // {true,  true,  false}   --> one full,   disabled --> no action
   // {true,  true,  false}   --> one full,   enabled  --> e/vn to vlan : case 3
   // {true,  true,  true }   --> both full,  disabled --> no action
   // {true,  true,  true }   --> both full,  enabled  --> no action

// eth,		e, vn, vl[0], vl[1], ipv4

   // ===    ======   =============   =============   =====    =====
   // hit    eth      e               vn              vl[0]    vl[1]
   // ===    ======   =============   =============   =====    =====

   // case 0 (eth  to vlan)
   (true, false, false, false, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (true, false, false, true, false, false, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (true, false, false, false, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty
   (true, false, false, true, false, true, false, false): hdr_add_0__from_eth_____to_vlan_tag0(); // empty

   // case 1 (eth  to vlan)
   (true, false, false, false, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (true, false, false, true, false, false, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (true, false, false, false, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full
   (true, false, false, true, false, true, true, false): hdr_add_1__from_eth_____to_vlan_tag0(); // one full

   // case 2 (e/vn to vlan)
   (true, false, true, false, false, false, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty
   (true, false, true, false, false, true, false, false): hdr_add_0__from_e_tag___to_vlan_tag0(); // empty

   (true, false, false, false, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty
   (true, false, false, true, true, false, false, false): hdr_add_0__from_vn_tag__to_vlan_tag0(); // empty

   // case 3 (e/vn to vlan)
   (true, false, true, false, false, false, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full
   (true, false, true, false, false, true, true, false): hdr_add_1__from_e_tag___to_vlan_tag0(); // one full

   (true, false, false, false, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
   (true, false, false, true, true, false, true, false): hdr_add_1__from_vn_tag__to_vlan_tag0(); // one full
  }
 }

 // -----------------------------------------------------------------
 // Apply
 // -----------------------------------------------------------------

 apply {
  if(hdr_1.ethernet.ether_type == 0x88a8) hdr_1_ethernet_isEtypeStag = true; else hdr_1_ethernet_isEtypeStag = false;
  if(OUTER_ETAG_ENABLE) {
   if(hdr_1.e_tag.ether_type == 0x88a8) hdr_1_e_tag_isEtypeStag = true; else hdr_1_e_tag_isEtypeStag = false;
  } else {
   hdr_1_e_tag_isEtypeStag = false;
  }
  if(OUTER_VNTAG_ENABLE) {
   if(hdr_1.vn_tag.ether_type == 0x88a8) hdr_1_vn_tag_isEtypeStag = true; else hdr_1_vn_tag_isEtypeStag = false;
  } else {
   hdr_1_vn_tag_isEtypeStag = false;
  }


/*
		if(bd_to_vlan_mapping.apply().hit) {
			if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
				hdr_add_etag_vntag.apply();
			} else if(OUTER_ETAG_ENABLE) {
				hdr_add_etag.apply();
			} else if(OUTER_VNTAG_ENABLE) {
				hdr_add_vntag.apply();
			} else {
				hdr_add.apply();
			}
		}
*/
  bd_to_vlan_mapping.apply();

  if(OUTER_ETAG_ENABLE && OUTER_VNTAG_ENABLE) {
   hdr_add_etag_vntag.apply();
  } else if(OUTER_ETAG_ENABLE) {
   hdr_add_etag.apply();
  } else if(OUTER_VNTAG_ENABLE) {
   hdr_add_vntag.apply();
  } else {
   hdr_add.apply();
  }

 }

}
# 6 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_truncate.p4" 1



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
    if(eg_md.nsh_md.truncate_enable) {

        eg_intr_md_for_dprsr.mtu_trunc_len = eg_md.nsh_md.truncate_len;

        }

 }

}
# 7 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4" 2
//#include "npb_egr_sf_proxy_meter.p4"




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/acl.p4" 1
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
# 13 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4" 2

control Npb_Egr_Sf_Proxy_Top (
 inout switch_lookup_fields_t lkp,
 inout switch_header_transport_t hdr_0,
 inout switch_header_outer_t hdr_1,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 EgressAcl(
  TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE,

  EGRESS_IPV4_ACL_TABLE_SIZE,


  EGRESS_IPV6_ACL_TABLE_SIZE,

  EGRESS_MAC_ACL_TABLE_SIZE
 ) acl;

 Npb_Egr_Sf_Proxy_Hdr_Strip(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_egr_sf_proxy_hdr_strip;
 Npb_Egr_Sf_Proxy_Hdr_Edit (TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_egr_sf_proxy_hdr_edit;





 // =========================================================================
 // Table #1: SFF Action Select
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats; // direct counter

 bit<8> int_ctrl_flags = 0;

 action egr_sf_action_sel_hit(



  bit<16> dsap
 ) {
  stats.count();




  eg_md.nsh_md.dsap = dsap;
 }

 // =====================================

 action egr_sf_action_sel_miss(
 ) {
  stats.count();

//		int_ctrl_flags                = 0;
//		eg_md.nsh_md.dsap             = 0;
 }

 // =====================================

 table egr_sf_action_sel {
  key = {
      eg_md.nsh_md.spi : exact @name("spi");
      eg_md.nsh_md.si : exact @name("si");
  }

  actions = {
      egr_sf_action_sel_hit;
      egr_sf_action_sel_miss;
  }

  const default_action = egr_sf_action_sel_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_SFF_TABLE_DEPTH;
  counters = stats;
 }

 // =========================================================================
 // Table #x: SF Ip Length Range
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_ip_len; // direct counter

 bit<8> ip_len_rng = 0;


 action egr_sf_ip_len_rng_hit(
  bit<8> rng_bitmask
 ) {
  stats_ip_len.count();

  ip_len_rng = rng_bitmask;
 }

 // =====================================

 action egr_sf_ip_len_rng_miss(
 ) {
  stats_ip_len.count();
 }

 // =====================================

 table egr_sf_ip_len_rng {
  key = {
   lkp.ip_len : range @name("ip_len");
  }

  actions = {
//			NoAction;
   egr_sf_ip_len_rng_hit;
   egr_sf_ip_len_rng_miss;
  }

  const default_action = egr_sf_ip_len_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L3_LEN_RNG_TABLE_DEPTH;
  counters = stats_ip_len;
 }


 // =========================================================================
 // Table #2: SF L4 Src Port Range
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_l4_src_port; // direct counter

 bit<8> l4_src_port_rng = 0;


 action egr_sf_l4_src_port_rng_hit(
  bit<8> rng_bitmask
 ) {
  stats_l4_src_port.count();

  l4_src_port_rng = rng_bitmask;
 }

 // =====================================

 action egr_sf_l4_src_port_rng_miss(
 ) {
  stats_l4_src_port.count();
 }

 // =====================================

 table egr_sf_l4_src_port_rng {
  key = {
   lkp.l4_src_port : range @name("l4_src_port");
  }

  actions = {
//			NoAction;
   egr_sf_l4_src_port_rng_hit;
   egr_sf_l4_src_port_rng_miss;
  }

  const default_action = egr_sf_l4_src_port_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_SRC_RNG_TABLE_DEPTH;
  counters = stats_l4_src_port;
 }


 // =========================================================================
 // Table #2: SF L4 Dst Port Range
 // =========================================================================

 DirectCounter<bit<32>>(type=CounterType_t.PACKETS_AND_BYTES) stats_l4_dst_port; // direct counter

 bit<8> l4_dst_port_rng = 0;


 action egr_sf_l4_dst_port_rng_hit(
  bit<8> rng_bitmask
 ) {
  stats_l4_dst_port.count();

  l4_dst_port_rng = rng_bitmask;
 }

 // =====================================

 action egr_sf_l4_dst_port_rng_miss(
 ) {
  stats_l4_dst_port.count();
 }

 // =====================================

 table egr_sf_l4_dst_port_rng {
  key = {
   lkp.l4_dst_port : range @name("l4_dst_port");
  }

  actions = {
//			NoAction;
   egr_sf_l4_dst_port_rng_hit;
   egr_sf_l4_dst_port_rng_miss;
  }

  const default_action = egr_sf_l4_dst_port_rng_miss;
  size = NPB_EGR_SF_2_EGRESS_SFP_POLICY_L4_DST_RNG_TABLE_DEPTH;
  counters = stats_l4_dst_port;
 }


 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  eg_md.nsh_md.dsap = 0;

  // ==================================
  // Action Lookup
  // ==================================

  if(egr_sf_action_sel.apply().hit) {

   // ==================================
   // Decrement SI
   // ==================================

   // Derek: We have moved this here, rather than at the end of the sf,
   // in violation of RFC8300.  This is because of an issue were a sf
   // can reclassify the packet with a new si, which would then get immediately
   // decremented.  This means firmware would have to add 1 to the si value
   // the really wanted.  So we move it here so that is gets decremented after
   // the lookup that uses it, but before any actions have run....


   eg_md.nsh_md.si = eg_md.nsh_md.si - 1; // decrement sp_index




   // ==================================
   // Actions(s)
   // ==================================

   // ----------------------------------
   // Action #0 - Policy
   // ----------------------------------


   egr_sf_ip_len_rng.apply();


   egr_sf_l4_src_port_rng.apply();


   egr_sf_l4_dst_port_rng.apply();


   acl.apply(
    lkp,
    eg_md,
    eg_intr_md_for_dprsr,
    lkp.ip_len,
    ip_len_rng,
    lkp.l4_src_port,
    l4_src_port_rng,
    lkp.l4_dst_port,
    l4_dst_port_rng,
    hdr_0,
    int_ctrl_flags
   );

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
/*
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
*/
   // ----------------------------------
   // Action #4 - Meter
   // ----------------------------------
# 338 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4"
   // ----------------------------------
   // Action #5 - Deduplication
   // ----------------------------------
# 353 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_sf_proxy_top.p4"
  }
 }
}
# 8 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_dedup.p4" 1
/* -*- P4_16 -*- */
# 14 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_ing_sf_npb_basic_adv_dedup.p4"
// =============================================================================
// =============================================================================
// =============================================================================
// Register (Ingress & Egress Shared Code)
// =============================================================================
// =============================================================================
// =============================================================================

struct pair_t {
 bit<16> hash_l34;
//	bit<16> data;  // ssap
//	bit<16> data;  // sport
 bit<16> data; // {count[15:12], unused[11:9], sport[8:0]}
};

// =============================================================================

// note: this register code has been structured such that multiple registers can
// be laid down, perhaps using upper bits of the hash to select between them....

control npb_dedup_reg (
 in bit<12> hash_l2, // address (high bits), data (low bits)
 in bit<16> hash_l34, // address (high bits), data (low bits)
 in bit<16> ssap, // data
 in bit<16> vpn, // data
 in bit<9> sport, // data

 out bit<1> drop
) (
 switch_uint32_t addr_width_ = 16 // 64k deep
) {

 // =========================================================================
 // Register Array
 // =========================================================================

 // This code works similar to how vpp's flow collector works...on a hash
 // collision, the current flow occupying the slot is simply replaced with
 // the new flow (i.e. the old flow is simply booted out of the cache).

 Register <pair_t, bit<16>>(1 << 16) array1; // syntax seems to be <data type, index type>

 // =========================================================================

 RegisterAction<pair_t, bit<16>, bit<1>>(array1) filter1 = { // syntax seems to be <data type, index type, return type>
  void apply(
   inout pair_t reg_value, // register entry
   out bit<1> return_value // return value
  ) {
   if(reg_value.hash_l34 == (bit<16>)hash_l34[15:0]) {
    // existing flow
    // --------
//				if(reg_value.data == (bit<16>)ssap) {
//				if(reg_value.data <= (bit<16>)sport + 0xf000) { // check count
    if(reg_value.data <= (bit<16>)hash_l2[11:0] + 0xf000) { // check count
// DEREK: WE WANT THIS ONE, BUT IT GETS A COMPILER ERROR.  CASE OPENED WITH INTEL: 
//				if((reg_value.data & 0x01ff == (bit<16>)sport) && (reg_value.data & 0xf000 < 0xf000)) { // check count
//				if((reg_value.data & 0x0fff == (bit<16>)hash_l2[11:0]) && (reg_value.data & 0xf000 < 0xf000)) { // check count
     // same source
     // ---------
     reg_value.data = (bit<16>)reg_value.data + 0x1000; // increment count
     return_value = 0; // pass packet
    } else {
     // different source
     // ---------
     reg_value.data = (bit<16>)reg_value.data; // same count
     return_value = 1; // drop packet
    }
   } else {
    // new flow (overwrite any existing flow)
    // --------
    // update entry
    reg_value.hash_l34 = (bit<16>)hash_l34[15:0];
//				reg_value.data     = (bit<16>)ssap;
//				reg_value.data     = (bit<16>)sport; // clear count
    reg_value.data = (bit<16>)hash_l2[11:0]; // clear count

    return_value = 0; // pass packet
   }
  }
 };

 // =========================================================================
 // Apply Block
 // =========================================================================

 apply {
  drop = filter1.execute(hash_l34[(16 - 1):0]);
 }

}

// =============================================================================
// =============================================================================
// =============================================================================
// 
// =============================================================================
// =============================================================================
// =============================================================================

control npb_dedup_ (
 in bool enable,
 in switch_lookup_fields_t lkp, // for hash
 in bit<32> hash_l2,
 in bit<32> hash_l34,
 in bit<16> ssap, // for dedup
 in bit<16> vpn, // for dedup
 in bit<9> sport, // for dedup
 inout bit<3> drop_ctl
) (
 switch_uint32_t num_blocks = 1,
 switch_uint32_t addr_width_ = 16 // 64k deep
) {
 npb_dedup_reg(addr_width_) npb_dedup_reg_0;
 npb_dedup_reg(addr_width_) npb_dedup_reg_1;
 npb_dedup_reg(addr_width_) npb_dedup_reg_2;
 npb_dedup_reg(addr_width_) npb_dedup_reg_3;
 npb_dedup_reg(addr_width_) npb_dedup_reg_4;
 npb_dedup_reg(addr_width_) npb_dedup_reg_5;
 npb_dedup_reg(addr_width_) npb_dedup_reg_6;
 npb_dedup_reg(addr_width_) npb_dedup_reg_7;
 npb_dedup_reg(addr_width_) npb_dedup_reg_8;
 npb_dedup_reg(addr_width_) npb_dedup_reg_9;
 npb_dedup_reg(addr_width_) npb_dedup_reg_10;
 npb_dedup_reg(addr_width_) npb_dedup_reg_11;
 npb_dedup_reg(addr_width_) npb_dedup_reg_12;
 npb_dedup_reg(addr_width_) npb_dedup_reg_13;
 npb_dedup_reg(addr_width_) npb_dedup_reg_14;
 npb_dedup_reg(addr_width_) npb_dedup_reg_15;
 npb_dedup_reg(addr_width_) npb_dedup_reg_16;
 npb_dedup_reg(addr_width_) npb_dedup_reg_17;
 npb_dedup_reg(addr_width_) npb_dedup_reg_18;
 npb_dedup_reg(addr_width_) npb_dedup_reg_19;
 npb_dedup_reg(addr_width_) npb_dedup_reg_20;
 npb_dedup_reg(addr_width_) npb_dedup_reg_21;
 npb_dedup_reg(addr_width_) npb_dedup_reg_22;
 npb_dedup_reg(addr_width_) npb_dedup_reg_23;
 npb_dedup_reg(addr_width_) npb_dedup_reg_24;
 npb_dedup_reg(addr_width_) npb_dedup_reg_25;
 npb_dedup_reg(addr_width_) npb_dedup_reg_26;
 npb_dedup_reg(addr_width_) npb_dedup_reg_27;
 npb_dedup_reg(addr_width_) npb_dedup_reg_28;
 npb_dedup_reg(addr_width_) npb_dedup_reg_29;
 npb_dedup_reg(addr_width_) npb_dedup_reg_30;
 npb_dedup_reg(addr_width_) npb_dedup_reg_31;

 bit<1> drop;

 // =========================================================================
 // Hash (shrink to 12 bits)
 // =========================================================================

//	bit<12> hash_l2_reduced;

//	Hash<bit<12>>(HashAlgorithm_t.IDENTITY) hash_1;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {
//		hash_l2_reduced[11:0] = hash_1.get({hash_l2});

  // ***** call dedup function *****
  if(enable) {
   if(num_blocks == 1) {
    npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
   } else if(num_blocks == 2) {
    bit<1> upper_addr = hash_l34[31:31];
    if (upper_addr == 0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    }
   } else if(num_blocks == 4) {
    bit<2> upper_addr = hash_l34[31:30];
    if (upper_addr == 0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    }
   } else if(num_blocks == 8) {
    bit<3> upper_addr = hash_l34[31:29];
    if (upper_addr == 0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 3) { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 4) { npb_dedup_reg_4.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 5) { npb_dedup_reg_5.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 6) { npb_dedup_reg_6.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else { npb_dedup_reg_7.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    }
   } else if(num_blocks == 16) {
    bit<4> upper_addr = hash_l34[31:28];
    if (upper_addr == 0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 3) { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 4) { npb_dedup_reg_4.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 5) { npb_dedup_reg_5.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 6) { npb_dedup_reg_6.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 7) { npb_dedup_reg_7.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 8) { npb_dedup_reg_8.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 9) { npb_dedup_reg_9.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 10) { npb_dedup_reg_10.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 11) { npb_dedup_reg_11.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 12) { npb_dedup_reg_12.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 13) { npb_dedup_reg_13.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 14) { npb_dedup_reg_14.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else { npb_dedup_reg_15.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    }
   } else {
    bit<5> upper_addr = hash_l34[31:27];
    if (upper_addr == 0) { npb_dedup_reg_0.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 1) { npb_dedup_reg_1.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 2) { npb_dedup_reg_2.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 3) { npb_dedup_reg_3.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 4) { npb_dedup_reg_4.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 5) { npb_dedup_reg_5.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 6) { npb_dedup_reg_6.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 7) { npb_dedup_reg_7.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 8) { npb_dedup_reg_8.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 9) { npb_dedup_reg_9.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 10) { npb_dedup_reg_10.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 11) { npb_dedup_reg_11.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 12) { npb_dedup_reg_12.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 13) { npb_dedup_reg_13.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 14) { npb_dedup_reg_14.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 15) { npb_dedup_reg_15.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 16) { npb_dedup_reg_16.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 17) { npb_dedup_reg_17.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 18) { npb_dedup_reg_18.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 19) { npb_dedup_reg_19.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 20) { npb_dedup_reg_20.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 21) { npb_dedup_reg_21.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 22) { npb_dedup_reg_22.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 23) { npb_dedup_reg_23.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 24) { npb_dedup_reg_24.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 25) { npb_dedup_reg_25.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 26) { npb_dedup_reg_26.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 27) { npb_dedup_reg_27.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 28) { npb_dedup_reg_28.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 29) { npb_dedup_reg_29.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else if(upper_addr == 30) { npb_dedup_reg_30.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    } else { npb_dedup_reg_31.apply (hash_l2[11:0], hash_l34[15:0], ssap, vpn, sport, drop);
    }
   }
  }

  if(drop == 1) {
   drop_ctl = 0x1;
  }
 }
}
# 9 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4" 2

# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/scoper.p4" 1
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
# 11 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4" 2

control Npb_Egr_Top (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,

 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 Npb_Egr_Sf_Proxy_Top(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_egr_sf_proxy_top;

 TunnelDecapOuter(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE, switch_tunnel_mode_t.PIPE) tunnel_decap_outer;
 TunnelDecapInner(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE, switch_tunnel_mode_t.PIPE) tunnel_decap_inner;

 npb_dedup_(1, dedup_addr_width_) npb_dedup;

 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // -------------------------------------
  // Ingress Dedup (continued from ingress side)
  // -------------------------------------
# 76 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4"
  // -------------------------------------
  // Set Initial Scope
  // -------------------------------------

  if(eg_md.nsh_md.scope == 1) {

   // do nothing
# 91 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4"
  } else {

   // do nothing
# 102 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_top.p4"
  }

  // -------------------------------------
  // SF #1 - Multicast
  // -------------------------------------
/*
		npb_egr_sf_multicast_top_part2.apply (
			hdr_0,
			eg_intr_md.egress_rid,
			eg_intr_md.egress_port,
			eg_md
		);
*/
  // -------------------------------------
  // SF #2 - Policy
  // -------------------------------------

//		if (!eg_md.flags.bypass_egress) {
   npb_egr_sf_proxy_top.apply (
    eg_md.lkp_1,
    hdr_0,
    hdr_1,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
//		}

  // -------------------------------------
  // SFF - Pkt Decap(s)
  // -------------------------------------

  // Decaps ------------------------------

  tunnel_decap_outer.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);
  tunnel_decap_inner.apply(hdr_1, tunnel_1, hdr_2, tunnel_2, hdr_3);

//		eg_md.nsh_md.scope = eg_md.nsh_md.scope - (bit<8>)eg_md.nsh_md.terminate_popcount;
  TunnelDecapScopeDecrement.apply(tunnel_1.terminate, tunnel_2.terminate, hdr_0, eg_md.nsh_md.scope);

  // -------------------------------------
  // SFF - Hdr Decap / Encap
  // -------------------------------------

//		if (!eg_md.flags.bypass_egress) {
   npb_egr_sff_top.apply (
    hdr_0,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
//		}

 }
}

control Npb_Egr_Top_Folded (
 inout switch_header_transport_t hdr_0,
 inout switch_tunnel_metadata_t tunnel_0,
 inout switch_header_outer_t hdr_1,
 inout switch_tunnel_metadata_reduced_t tunnel_1,
 inout switch_header_inner_t hdr_2,
 inout switch_tunnel_metadata_reduced_t tunnel_2,
 inout switch_header_inner_inner_t hdr_3,

 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {
 // =========================================================================
 // Apply
 // =========================================================================

 apply {

  // -------------------------------------
  // SFF - Hdr Decap / Encap
  // -------------------------------------

//		if (!eg_md.flags.bypass_egress) {
   npb_egr_sff_top.apply (
    hdr_0,
    eg_md,
    eg_intr_md,
    eg_intr_md_from_prsr,
    eg_intr_md_for_dprsr,
    eg_intr_md_for_oport
   );
//		}
 }
}
# 65 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4" 1
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




# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/headers.p4" 1
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
# 25 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4" 2
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/types.p4" 1
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
# 26 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4" 2

//-----------------------------------------------------------------------------
// Egress Deparser
//-----------------------------------------------------------------------------

control EgressMirror(
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
// Egress deparser first construct the output packet and then prepend the mirror header.

    Mirror() mirror;


    apply {

/*
        if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_PORT) {
  #ifdef MIRROR_EGRESS_PORT_ENABLE
            mirror.emit<switch_port_mirror_egress_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,
    #ifdef CPU_HDR_CONTAINS_EG_PORT
                eg_md.port,
    #else
                eg_md.port_lag_index,
    #endif
                eg_md.ingress_timestamp,
//  #if __TARGET_TOFINO__ == 1
//              0,
//  #endif
//              eg_md.mirror.session_id
                eg_md.cpu_reason
				,
				0,
				eg_md.qos.qid,
				0,
				eg_md.qos.qdepth
            });
  #endif
        } else if (eg_intr_md_for_dprsr.mirror_type == SWITCH_MIRROR_TYPE_CPU) {
*/
        if (eg_intr_md_for_dprsr.mirror_type == 2) {

            mirror.emit<switch_cpu_mirror_egress_metadata_h>(eg_md.mirror.session_id, {
                eg_md.mirror.src,
                eg_md.mirror.type,
                0,
                eg_md.ingress_port,
                eg_md.bd,
                0,

                eg_md.port,



                eg_md.ingress_timestamp,
                eg_md.cpu_reason
    ,
    0,
    eg_md.qos.qid,
    0,
    eg_md.qos.qdepth
            });

        } else if (eg_intr_md_for_dprsr.mirror_type == 4) {
# 118 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 3) {
# 139 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4"
        } else if (eg_intr_md_for_dprsr.mirror_type == 5) {
# 150 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4"
        }

    }
}

//-----------------------------------------------------------------------------

control EgressDeparser(
    packet_out pkt,
    inout switch_header_t hdr,
    in switch_egress_metadata_t eg_md,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) ( // constructor parameters
    bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 EgressMirror() mirror;

    Checksum() ipv4_checksum_transport;

    Checksum() ipv4_checksum_outer;

    apply {
  mirror.apply(hdr, eg_md, eg_intr_md_for_dprsr);


        if (hdr.transport.ipv4.isValid()) {
            hdr.transport.ipv4.hdr_checksum = ipv4_checksum_transport.update({
                hdr.transport.ipv4.version,
                hdr.transport.ipv4.ihl,
                hdr.transport.ipv4.tos,
                hdr.transport.ipv4.total_len,
                hdr.transport.ipv4.identification,
                hdr.transport.ipv4.flags,
                hdr.transport.ipv4.frag_offset,
                hdr.transport.ipv4.ttl,
                hdr.transport.ipv4.protocol,
                hdr.transport.ipv4.src_addr,
                hdr.transport.ipv4.dst_addr});
        }



/*
        if (hdr.outer.ipv4.isValid()) {
            hdr.outer.ipv4.hdr_checksum = ipv4_checksum_outer.update({
                    hdr.outer.ipv4.version,
                    hdr.outer.ipv4.ihl,
                    hdr.outer.ipv4.tos,
                    hdr.outer.ipv4.total_len,
                    hdr.outer.ipv4.identification,
                    hdr.outer.ipv4.flags,
                    hdr.outer.ipv4.frag_offset,
                    hdr.outer.ipv4.ttl,
                    hdr.outer.ipv4.protocol,
                    hdr.outer.ipv4.src_addr,
                    hdr.outer.ipv4.dst_addr});
        }
*/


        // ***** TRANSPORT *****
  if(FOLDED_ENABLE) {
   pkt.emit(hdr.bridged_md_folded);
   pkt.emit(hdr.transport.nsh_type1_internal);
  } else {
   pkt.emit(hdr.transport.ethernet);
   pkt.emit(hdr.transport.vlan_tag);
   pkt.emit(hdr.transport.nsh_type1);


         pkt.emit(hdr.transport.ipv4);







         pkt.emit(hdr.transport.gre);
# 241 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/../../src/npb_egr_deparser.p4"
         pkt.emit(hdr.transport.udp);




         pkt.emit(hdr.transport.dtel); // Egress only.







         pkt.emit(hdr.transport.dtel_report); // Egress only.
         pkt.emit(hdr.transport.dtel_switch_local_report); // Egress only.

         pkt.emit(hdr.transport.dtel_drop_report); // Egress only.
  }

        // ***** OUTER *****
        pkt.emit(hdr.outer.ethernet);




  pkt.emit(hdr.cpu);


        if(OUTER_ETAG_ENABLE) {
            pkt.emit(hdr.outer.e_tag);
        }

        if(OUTER_VNTAG_ENABLE) {
            pkt.emit(hdr.outer.vn_tag);
        }

        pkt.emit(hdr.outer.vlan_tag);






        pkt.emit(hdr.outer.ipv4);

        pkt.emit(hdr.outer.ipv6);

        pkt.emit(hdr.outer.udp);
        pkt.emit(hdr.outer.tcp);
        pkt.emit(hdr.outer.sctp);

        if(OUTER_GENEVE_ENABLE) {
            pkt.emit(hdr.outer.geneve);
        }

        if(OUTER_VXLAN_ENABLE) {
            pkt.emit(hdr.outer.vxlan);
        }

        pkt.emit(hdr.outer.gre);
        pkt.emit(hdr.outer.gre_optional);

        if(OUTER_NVGRE_ENABLE) {
            pkt.emit(hdr.outer.nvgre);
        }


        pkt.emit(hdr.outer.gtp_v1_base);
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
        pkt.emit(hdr.inner.gre_optional);


        pkt.emit(hdr.inner.gtp_v1_base);
        pkt.emit(hdr.inner.gtp_v1_optional);


    }
}
# 66 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2


// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// List pragmas here that are needed to function properly
@pa_auto_init_metadata
@pa_no_overlay("ingress", "hdr.transport.ipv4.src_addr")
@pa_no_overlay("ingress", "hdr.transport.ipv4.dst_addr")


@pa_parser_group_monogress //grep for monogress in phv_allocation log to confirm
# 89 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4"
// Add pragmas to pragmas.p4 that are needed to fit design
# 1 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/pragmas.p4" 1




@pa_atomic("ingress" , "ig_md.lkp_1.ip_type")




//@pa_atomic("egress" , "eg_md.bypass")
# 91 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4" 2

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control IngressControl(
 inout switch_header_t hdr,
 inout switch_ingress_metadata_t ig_md,
 in ingress_intrinsic_metadata_t ig_intr_md,
 in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // ---------------------------------------------------------------------

 IngressSetLookup() ingress_set_lookup;
 IngressPortMapping(PORT_VLAN_TABLE_SIZE, BD_TABLE_SIZE, PORT_TABLE_SIZE, VLAN_TABLE_SIZE) ingress_port_mapping;






 DMAC(MAC_TABLE_SIZE) dmac;

//	IngressBd(BD_TABLE_SIZE) bd_stats;
//	IngressUnicast(RMAC_TABLE_SIZE) unicast;
 Ipv4HashSymmetric() ipv4_hash_symmetric;
 Ipv6HashSymmetric() ipv6_hash_symmetric;
 NonIpHashSymmetric() non_ip_hash_symmetric;
// 	IngressIpAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
 IngressMirrorMeter() ingress_mirror_meter;
//	IngressIpDtelSampleAcl(INGRESS_IP_DTEL_ACL_TABLE_SIZE) ingress_ip_dtel_acl;
 Nexthop(NEXTHOP_TABLE_SIZE, ECMP_GROUP_TABLE_SIZE, ECMP_SELECT_TABLE_SIZE) nexthop;

 OuterFib(OUTER_NEXTHOP_TABLE_SIZE, OUTER_ECMP_GROUP_TABLE_SIZE, OUTER_ECMP_SELECT_TABLE_SIZE) outer_fib;

 LAG() lag;
//	MulticastFlooding(BD_FLOOD_TABLE_SIZE) flood;



 IngressHdrStackCounters(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) IngressHdrStackCounters_inst;
 Npb_Ing_Top(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_ing_top;

 // ---------------------------------------------------------------------

 apply {

//		ig_intr_md_for_dprsr.drop_ctl = 0;  // no longer present in latest switch.p4
//		ig_md.multicast.id = 0;             // no longer present in latest switch.p4
# 153 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4"
  ingress_set_lookup.apply(hdr, ig_md); // set lookup structure fields that parser couldn't

  // -----------------------------------------------------
# 173 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4"
  ingress_port_mapping.apply(hdr, ig_md, ig_intr_md_for_tm, ig_intr_md_for_dprsr);

  if(INGRESS_ENABLE == true) {


  IngressHdrStackCounters_inst.apply(hdr);


//		unicast.apply(hdr.transport, ig_md);


 // the new parser puts bridging in outer
 dmac.apply(ig_md.lkp_1.mac_dst_addr, ig_md.lkp_1, ig_md, hdr);


//		if((hdr.transport.ethernet.isValid() == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
  if((ig_md.flags.transport_valid == false) && (ig_md.nsh_md.l2_fwd_en == true)) {
   // ----- Bridging Path -----
  } else {
   // ----- NPB Path -----
   npb_ing_top.apply (
    hdr.transport,
    ig_md.tunnel_0,
    hdr.outer,
    ig_md.tunnel_1,
    hdr.inner,
    ig_md.tunnel_2,
    hdr.inner_inner,
    hdr.udf,

    ig_md,
    ig_intr_md,
    ig_intr_from_prsr,
    ig_intr_md_for_dprsr,
    ig_intr_md_for_tm
   );

  }


  ingress_mirror_meter.apply(ig_md);


  // if lag hash masking enabled, move this before the hash
  nexthop.apply(ig_md);

  outer_fib.apply(ig_md);


  HashMask.apply(ig_md.lkp_1, ig_md.nsh_md.lag_hash_mask_en);
# 241 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4"
  if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_NONE) {
   non_ip_hash_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  } else if (ig_md.lkp_1.ip_type == SWITCH_IP_TYPE_IPV4) {
   ipv4_hash_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  } else {
   ipv6_hash_symmetric.apply(ig_md.lkp_1, ig_md.hash[31:0]);
  }
# 258 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4"
//#ifdef LAG_HASH_IN_NSH_HDR_ENABLE
//		hdr.transport.nsh_type1.lag_hash = ig_md.hash[switch_hash_width-1:switch_hash_width/2];
//#endif

//		if (ig_md.egress_port_lag_index == SWITCH_FLOOD) {
//			flood.apply(ig_md);
//		} else {
//			lag.apply(ig_md.lkp_1, ig_md, ig_md.hash[31:16], ig_intr_md_for_tm.ucast_egress_port);
   lag.apply(ig_md.lkp_1, ig_md, ig_md.hash, ig_intr_md_for_tm.ucast_egress_port);
//		}

  } else { // INGRESS ENABLE
   // NECESSARY STUFF JUST TO GET A VALID PACKET TO EGRESS

   // set egress port
   ig_intr_md_for_tm.ucast_egress_port = ig_md.port; // by default, set ingress port equal to egress port -- for testing
//			ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet

   // add internal nsh header
   ig_md.nsh_md.ttl = 0;
   ig_md.nsh_md.scope = 1;
   ig_md.nsh_md.end_of_path = true;

   hdr.transport.nsh_type1_internal.setValid(); // by default, egress parser expects this header -- for testing
   hdr.transport.nsh_type1_internal.ttl = ig_md.nsh_md.ttl; // by default, egress parser expects this header -- for testing
   hdr.transport.nsh_type1_internal.scope = ig_md.nsh_md.scope; // by default, egress parser expects this header -- for testing
  } // INGRESS ENABLE

  // -----------------------------------------------------

  // Only add bridged metadata if we are NOT bypassing egress pipeline.
  if (ig_intr_md_for_tm.bypass_egress == 1w0) {
   add_bridged_md.apply(hdr.bridged_md, ig_md);
  }




  set_ig_intr_md(ig_md, ig_intr_md_for_dprsr, ig_intr_md_for_tm);
# 308 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/../../../p4_pipelines/pipeline_npb/src/npb_core.p4"
 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control EgressControl(
 inout switch_header_t hdr,
 inout switch_egress_metadata_t eg_md,
 in egress_intrinsic_metadata_t eg_intr_md,
 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
 bool TRANSPORT_GRE_EGRESS_ENABLE = true, bool INGRESS_ENABLE = true, bool TRANSPORT_V6_ENABLE = true, bool OUTER_VXLAN_ENABLE = true, bit<32> EGRESS_IPV4_ACL_TABLE_SIZE = 512, bit<32> INGRESS_IPV6_ACL_TABLE_SIZE = 2048, bool TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID = false, bool FOLDED_ENABLE = false, bool UDF_ENABLE = false, bool TRANSPORT_ERSPAN_EGRESS_ENABLE = true, bool OUTER_ETAG_ENABLE = true, bool OUTER_GENEVE_ENABLE = false, bool EGRESS_ENABLE = true, bit<32> IPV4_DST_TUNNEL_TABLE_SIZE = 1024, bool TRANSPORT_V4_VXLAN_INGRESS_ENABLE = true, bool TRANSPORT_V6_REDUCED_ADDR = true, bool TRANSPORT_V4_ENABLE = true, bool TRANSPORT_ERSPAN_INGRESS_ENABLE = true, bool TRANSPORT_V4_GENEVE_INGRESS_ENABLE = false, bool OUTER_NVGRE_ENABLE = true, bool OUTER_VNTAG_ENABLE = true, bool TRANSPORT_MPLS_SR_INGRESS_ENABLE = true, bit<32> NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH = 2048, bit<32> EGRESS_IPV6_ACL_TABLE_SIZE = 512, bit<32> INGRESS_L7_ACL_TABLE_SIZE = 1024, bool TRANSPORT_GRE_INGRESS_ENABLE = true, bit<32> INGRESS_IPV4_ACL_TABLE_SIZE = 6144, bool TRANSPORT_LAYER_ENABLE = true, bit<32> EGRESS_MAC_ACL_TABLE_SIZE = 512, bit<32> INGRESS_MAC_ACL_TABLE_SIZE = 1536
) {

 // -------------------------------------------------------------------------

 EgressSetLookup() egress_set_lookup;
 EgressPortMapping(PORT_TABLE_SIZE) egress_port_mapping;
 EgressMirrorMeter() egress_mirror_meter;

 VlanXlate(VLAN_TABLE_SIZE, PORT_VLAN_TABLE_SIZE) vlan_xlate;
 VlanDecap() vlan_decap;
//	TunnelDecap() tunnel_decap;
 TunnelNexthop(NEXTHOP_TABLE_SIZE) rewrite;
 TunnelEncap(switch_tunnel_mode_t.PIPE) tunnel_encap;
 TunnelRewrite() tunnel_rewrite;
//	NSHTypeFixer() nsh_type_fixer;
//	MulticastReplication(RID_TABLE_SIZE) multicast_replication;
 MulticastReplication(NPB_ING_SF_1_MULTICAST_RID_TABLE_SIZE) multicast_replication;




 EgressCpuRewrite(PORT_TABLE_SIZE) cpu_rewrite;
 Npb_Egr_Top(TRANSPORT_GRE_EGRESS_ENABLE, INGRESS_ENABLE, TRANSPORT_V6_ENABLE, OUTER_VXLAN_ENABLE, EGRESS_IPV4_ACL_TABLE_SIZE, INGRESS_IPV6_ACL_TABLE_SIZE, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID, FOLDED_ENABLE, UDF_ENABLE, TRANSPORT_ERSPAN_EGRESS_ENABLE, OUTER_ETAG_ENABLE, OUTER_GENEVE_ENABLE, EGRESS_ENABLE, IPV4_DST_TUNNEL_TABLE_SIZE, TRANSPORT_V4_VXLAN_INGRESS_ENABLE, TRANSPORT_V6_REDUCED_ADDR, TRANSPORT_V4_ENABLE, TRANSPORT_ERSPAN_INGRESS_ENABLE, TRANSPORT_V4_GENEVE_INGRESS_ENABLE, OUTER_NVGRE_ENABLE, OUTER_VNTAG_ENABLE, TRANSPORT_MPLS_SR_INGRESS_ENABLE, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH, EGRESS_IPV6_ACL_TABLE_SIZE, INGRESS_L7_ACL_TABLE_SIZE, TRANSPORT_GRE_INGRESS_ENABLE, INGRESS_IPV4_ACL_TABLE_SIZE, TRANSPORT_LAYER_ENABLE, EGRESS_MAC_ACL_TABLE_SIZE, INGRESS_MAC_ACL_TABLE_SIZE) npb_egr_top;

 // -------------------------------------------------------------------------

 apply {

//		eg_intr_md_for_dprsr.drop_ctl = 0;



  eg_md.timestamp = eg_intr_md_from_prsr.global_tstamp[31:0];





  egress_set_lookup.apply(hdr.outer, hdr.inner, eg_md, eg_intr_md); // set lookup structure fields that parser couldn't

  egress_port_mapping.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);


  if(EGRESS_ENABLE == true) {
  if(eg_md.flags.bypass_egress == false) {
   multicast_replication.apply (
    hdr.transport,
    eg_intr_md.egress_rid,
    eg_intr_md.egress_port,
    eg_md
   );


   if((eg_md.flags.transport_valid == false) && (eg_md.nsh_md.l2_fwd_en == true)) {
    // do nothing (bridging the packet)
   } else {

    npb_egr_top.apply (
     hdr.transport,
     eg_md.tunnel_0,
     hdr.outer,
     eg_md.tunnel_1,
     hdr.inner,
     eg_md.tunnel_2,
     hdr.inner_inner,

     eg_md,
     eg_intr_md,
     eg_intr_md_from_prsr,
     eg_intr_md_for_dprsr,
     eg_intr_md_for_oport
    );

   }


   egress_mirror_meter.apply(eg_md);

   // ----- nexthop               code: operates on 'outer' ----
   rewrite.apply(hdr.outer, eg_md, eg_md.tunnel_0);
//			npb_egr_sf_proxy_hdr_strip.apply(hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);
//			npb_egr_sf_proxy_hdr_edit.apply (hdr.transport, hdr.outer, eg_md, eg_intr_md, eg_intr_md_from_prsr, eg_intr_md_for_dprsr, eg_intr_md_for_oport);

   // ---- outer nexthop (tunnel) code: operates on 'transport' ----
//			vlan_decap.apply(hdr.transport, eg_md);
   tunnel_encap.apply(hdr.transport, hdr.outer, hdr.inner, hdr.inner_inner, eg_md, eg_intr_md, eg_md.tunnel_0, eg_md.tunnel_1, eg_md.tunnel_2);
   tunnel_rewrite.apply(hdr.transport, eg_md, eg_md.tunnel_0);
   vlan_xlate.apply(hdr.transport, eg_md);
/*
			// fix ip total length field if packet is being truncated (todo: adjust by 16w20 in case of vlan tag present)
			if(hdr.transport.ipv4.total_len > (bit<16>)eg_md.nsh_md.truncate_len - 16w14) {
				hdr.transport.ipv4.total_len = (bit<16>)eg_md.nsh_md.truncate_len - 16w14;
			}
*/





  }
  } // EGRESS ENABLE
  cpu_rewrite.apply(hdr, eg_md, eg_intr_md_for_dprsr, eg_intr_md.egress_port);
  set_eg_intr_md(eg_md, eg_intr_md_for_dprsr, eg_intr_md_for_oport);


 }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

// MOVED TO P4-PROGRAMS
// 
// Pipeline(
//         NpbIngressParser(),
//         SwitchIngress(INSTANCE_DEPLOYMENT_PARAMS_VCPFW),
//         SwitchIngressDeparser(),
//         NpbEgressParser(),
//         SwitchEgress(INSTANCE_DEPLOYMENT_PARAMS_VCPFW),
//         SwitchEgressDeparser()) pipe;
// 
// Switch(pipe) main;
# 12 "/mnt/ws_tofino/extreme/p4c-4425/p4_programs/pgm_sp_npb_vcpFw/src/pgm_sp_npb_vcpFw_top.p4" 2

Pipeline(
    IngressParser(TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, FOLDED_ENABLE_PIPELINE_NPB_VCPFW, UDF_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_ENABLE_PIPELINE_NPB_VCPFW, IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW),
    IngressControl(TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, FOLDED_ENABLE_PIPELINE_NPB_VCPFW, UDF_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_ENABLE_PIPELINE_NPB_VCPFW, IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW),
    IngressDeparser(TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, FOLDED_ENABLE_PIPELINE_NPB_VCPFW, UDF_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_ENABLE_PIPELINE_NPB_VCPFW, IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW),
    EgressParser(TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, FOLDED_ENABLE_PIPELINE_NPB_VCPFW, UDF_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_ENABLE_PIPELINE_NPB_VCPFW, IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW),
    EgressControl(TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, FOLDED_ENABLE_PIPELINE_NPB_VCPFW, UDF_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_ENABLE_PIPELINE_NPB_VCPFW, IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW),
    EgressDeparser(TRANSPORT_GRE_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VXLAN_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_SET_TUNNEL_ID_PIPELINE_NPB_VCPFW, FOLDED_ENABLE_PIPELINE_NPB_VCPFW, UDF_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_EGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_ETAG_ENABLE_PIPELINE_NPB_VCPFW, OUTER_GENEVE_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_ENABLE_PIPELINE_NPB_VCPFW, IPV4_DST_TUNNEL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_VXLAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V6_REDUCED_ADDR_PIPELINE_NPB_VCPFW, TRANSPORT_V4_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_ERSPAN_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_V4_GENEVE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, OUTER_NVGRE_ENABLE_PIPELINE_NPB_VCPFW, OUTER_VNTAG_ENABLE_PIPELINE_NPB_VCPFW, TRANSPORT_MPLS_SR_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, NPB_ING_SFC_TUNNEL_INNER_TCAM_TABLE_DEPTH_PIPELINE_NPB_VCPFW, EGRESS_IPV6_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_L7_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_GRE_INGRESS_ENABLE_PIPELINE_NPB_VCPFW, INGRESS_IPV4_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, TRANSPORT_LAYER_ENABLE_PIPELINE_NPB_VCPFW, EGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW, INGRESS_MAC_ACL_TABLE_SIZE_PIPELINE_NPB_VCPFW)) pipeline_npb_vcpFw;

Switch(pipeline_npb_vcpFw) main;
