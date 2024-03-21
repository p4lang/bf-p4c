# 1 "sai_p4/instantiations/google/sai.p4"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "sai_p4/instantiations/google/sai.p4"
# 1 "sai_p4/instantiations/google/../../fixed/arch.p4" 1



# 1 "/home/rvantipalli/p4factory/install/share/p4c/p4include/psa.p4" 1



# 1 "/home/rvantipalli/p4factory/install/share/p4c/p4include/core.p4" 1
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
# 5 "/home/rvantipalli/p4factory/install/share/p4c/p4include/psa.p4" 2




/**
 *   P4-16 declaration of the Portable Switch Architecture
 */

/**
 * These types need to be defined before including the architecture file
 * and the macro protecting them should be defined.
 */


/* These are defined using `typedef`, not `type`, so they are truly
 * just different names for the type bit<W> for the particular width W
 * shown.  Unlike the `type` definitions below, values declared with
 * the `typedef` type names can be freely mingled in expressions, just
 * as any value declared with type bit<W> can.  Values declared with
 * one of the `type` names below _cannot_ be so freely mingled, unless
 * you first cast them to the corresponding `typedef` type.  While
 * that may be inconvenient when you need to do arithmetic on such
 * values, it is the price to pay for having all occurrences of values
 * of the `type` types marked as such in the automatically generated
 * control plane API.
 *
 * Note that the width of typedef <name>Uint_t will always be the same
 * as the width of type <name>_t. */
typedef bit<9> PortIdUint_t;
typedef bit<16> MulticastGroupUint_t;
typedef bit<10> CloneSessionIdUint_t;
typedef bit<3> ClassOfServiceUint_t;
typedef bit<14> PacketLengthUint_t;
typedef bit<16> EgressInstanceUint_t;
typedef bit<48> TimestampUint_t;

/* Note: clone_spec in BMv2 simple_switch v1model is 32 bits wide, but
 * it is used such that 16 of its bits contain a clone/mirror session
 * id, and 16 bits contain the numeric id of a field_list.  Only the
 * 16 bits of clone/mirror session id are comparable to the type
 * CloneSessionIdUint_t here.  See occurrences of clone_spec in this
 * file for details:
 * https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp
 */

@p4runtime_translation("p4.org/psa/v1/PortId_t", 32)
type PortIdUint_t PortId_t;
@p4runtime_translation("p4.org/psa/v1/MulticastGroup_t", 32)
type MulticastGroupUint_t MulticastGroup_t;
@p4runtime_translation("p4.org/psa/v1/CloneSessionId_t", 16)
type CloneSessionIdUint_t CloneSessionId_t;
@p4runtime_translation("p4.org/psa/v1/ClassOfService_t", 8)
type ClassOfServiceUint_t ClassOfService_t;
@p4runtime_translation("p4.org/psa/v1/PacketLength_t", 16)
type PacketLengthUint_t PacketLength_t;
@p4runtime_translation("p4.org/psa/v1/EgressInstance_t", 16)
type EgressInstanceUint_t EgressInstance_t;
@p4runtime_translation("p4.org/psa/v1/Timestamp_t", 64)
type TimestampUint_t Timestamp_t;

typedef error ParserError_t;

const PortId_t PSA_PORT_RECIRCULATE = (PortId_t) 0x44;
const PortId_t PSA_PORT_CPU = (PortId_t) 0x1ff;

const CloneSessionId_t PSA_CLONE_SESSION_TO_CPU = (CloneSessionId_t) 0;
# 122 "/home/rvantipalli/p4factory/install/share/p4c/p4include/psa.p4"
// BEGIN:Type_defns2

/* Note: All of the types with `InHeader` in their name are intended
 * only to carry values of the corresponding types in packet headers
 * between a PSA device and the P4Runtime Server software that manages
 * it.
 *
 * The widths are intended to be at least as large as any PSA device
 * will ever have for that type.  Thus these types may also be useful
 * to define packet headers that are sent directly between a PSA
 * device and other devices, without going through P4Runtime Server
 * software (e.g. this could be useful for sending packets to a
 * controller or data collection system using higher packet rates than
 * the P4Runtime Server can handle).  If used for this purpose, there
 * is no requirement that the PSA data plane _automatically_ perform
 * the numerical translation of these types that would occur if the
 * header went through the P4Runtime Server.  Any such desired
 * translation is up to the author of the P4 program to perform with
 * explicit code.
 *
 * All widths must be a multiple of 8, so that any subset of these
 * fields may be used in a single P4 header definition, even on P4
 * implementations that restrict headers to contain fields with a
 * total length that is a multiple of 8 bits. */

/* See the comments near the definition of PortIdUint_t for why these
 * typedef definitions exist. */
typedef bit<32> PortIdInHeaderUint_t;
typedef bit<32> MulticastGroupInHeaderUint_t;
typedef bit<16> CloneSessionIdInHeaderUint_t;
typedef bit<8> ClassOfServiceInHeaderUint_t;
typedef bit<16> PacketLengthInHeaderUint_t;
typedef bit<16> EgressInstanceInHeaderUint_t;
typedef bit<64> TimestampInHeaderUint_t;

@p4runtime_translation("p4.org/psa/v1/PortIdInHeader_t", 32)
type PortIdInHeaderUint_t PortIdInHeader_t;
@p4runtime_translation("p4.org/psa/v1/MulticastGroupInHeader_t", 32)
type MulticastGroupInHeaderUint_t MulticastGroupInHeader_t;
@p4runtime_translation("p4.org/psa/v1/CloneSessionIdInHeader_t", 16)
type CloneSessionIdInHeaderUint_t CloneSessionIdInHeader_t;
@p4runtime_translation("p4.org/psa/v1/ClassOfServiceInHeader_t", 8)
type ClassOfServiceInHeaderUint_t ClassOfServiceInHeader_t;
@p4runtime_translation("p4.org/psa/v1/PacketLengthInHeader_t", 16)
type PacketLengthInHeaderUint_t PacketLengthInHeader_t;
@p4runtime_translation("p4.org/psa/v1/EgressInstanceInHeader_t", 16)
type EgressInstanceInHeaderUint_t EgressInstanceInHeader_t;
@p4runtime_translation("p4.org/psa/v1/TimestampInHeader_t", 64)
type TimestampInHeaderUint_t TimestampInHeader_t;
// END:Type_defns2

/* The _int_to_header functions were written to convert a value of
 * type <name>_t (a value INTernal to the data path) to a value of
 * type <name>InHeader_t inside a header that will be sent to the CPU
 * port.
 *
 * The _header_to_int functions were written to convert values in the
 * opposite direction, typically for assigning a value in a header
 * received from the CPU port, to a value you wish to use in the rest
 * of your code.
 *
 * The reason that three casts are needed is that each of the original
 * and target types is declared via P4_16 'type', so without a cast
 * they can only be assigned to values of that identical type.  The
 * first cast changes it from the original 'type' to a 'bit<W1>' value
 * of the same bit width W1.  The second cast changes its bit width,
 * either prepending 0s if it becomes wider, or discarding the most
 * significant bits if it becomes narrower.  The third cast changes it
 * from a 'bit<W2>' value to the final 'type', with the same width
 * W2. */

PortId_t psa_PortId_header_to_int (in PortIdInHeader_t x) {
    return (PortId_t) (PortIdUint_t) (PortIdInHeaderUint_t) x;
}
MulticastGroup_t psa_MulticastGroup_header_to_int (in MulticastGroupInHeader_t x) {
    return (MulticastGroup_t) (MulticastGroupUint_t) (MulticastGroupInHeaderUint_t) x;
}
CloneSessionId_t psa_CloneSessionId_header_to_int (in CloneSessionIdInHeader_t x) {
    return (CloneSessionId_t) (CloneSessionIdUint_t) (CloneSessionIdInHeaderUint_t) x;
}
ClassOfService_t psa_ClassOfService_header_to_int (in ClassOfServiceInHeader_t x) {
    return (ClassOfService_t) (ClassOfServiceUint_t) (ClassOfServiceInHeaderUint_t) x;
}
PacketLength_t psa_PacketLength_header_to_int (in PacketLengthInHeader_t x) {
    return (PacketLength_t) (PacketLengthUint_t) (PacketLengthInHeaderUint_t) x;
}
EgressInstance_t psa_EgressInstance_header_to_int (in EgressInstanceInHeader_t x) {
    return (EgressInstance_t) (EgressInstanceUint_t) (EgressInstanceInHeaderUint_t) x;
}
Timestamp_t psa_Timestamp_header_to_int (in TimestampInHeader_t x) {
    return (Timestamp_t) (TimestampUint_t) (TimestampInHeaderUint_t) x;
}

PortIdInHeader_t psa_PortId_int_to_header (in PortId_t x) {
    return (PortIdInHeader_t) (PortIdInHeaderUint_t) (PortIdUint_t) x;
}
MulticastGroupInHeader_t psa_MulticastGroup_int_to_header (in MulticastGroup_t x) {
    return (MulticastGroupInHeader_t) (MulticastGroupInHeaderUint_t) (MulticastGroupUint_t) x;
}
CloneSessionIdInHeader_t psa_CloneSessionId_int_to_header (in CloneSessionId_t x) {
    return (CloneSessionIdInHeader_t) (CloneSessionIdInHeaderUint_t) (CloneSessionIdUint_t) x;
}
ClassOfServiceInHeader_t psa_ClassOfService_int_to_header (in ClassOfService_t x) {
    return (ClassOfServiceInHeader_t) (ClassOfServiceInHeaderUint_t) (ClassOfServiceUint_t) x;
}
PacketLengthInHeader_t psa_PacketLength_int_to_header (in PacketLength_t x) {
    return (PacketLengthInHeader_t) (PacketLengthInHeaderUint_t) (PacketLengthUint_t) x;
}
EgressInstanceInHeader_t psa_EgressInstance_int_to_header (in EgressInstance_t x) {
    return (EgressInstanceInHeader_t) (EgressInstanceInHeaderUint_t) (EgressInstanceUint_t) x;
}
TimestampInHeader_t psa_Timestamp_int_to_header (in Timestamp_t x) {
    return (TimestampInHeader_t) (TimestampInHeaderUint_t) (TimestampUint_t) x;
}

/// Supported range of values for the psa_idle_timeout table properties
enum PSA_IdleTimeout_t {
  NO_TIMEOUT,
  NOTIFY_CONTROL
};

// BEGIN:Metadata_types
enum PSA_PacketPath_t {
    NORMAL, /// Packet received by ingress that is none of the cases below.
    NORMAL_UNICAST, /// Normal packet received by egress which is unicast
    NORMAL_MULTICAST, /// Normal packet received by egress which is multicast
    CLONE_I2E, /// Packet created via a clone operation in ingress,
                /// destined for egress
    CLONE_E2E, /// Packet created via a clone operation in egress,
                /// destined for egress
    RESUBMIT, /// Packet arrival is the result of a resubmit operation
    RECIRCULATE /// Packet arrival is the result of a recirculate operation
}

struct psa_ingress_parser_input_metadata_t {
  PortId_t ingress_port;
  PSA_PacketPath_t packet_path;
}

struct psa_egress_parser_input_metadata_t {
  PortId_t egress_port;
  PSA_PacketPath_t packet_path;
}

struct psa_ingress_input_metadata_t {
  // All of these values are initialized by the architecture before
  // the Ingress control block begins executing.
  PortId_t ingress_port;
  PSA_PacketPath_t packet_path;
  Timestamp_t ingress_timestamp;
  ParserError_t parser_error;
}
// BEGIN:Metadata_ingress_output
struct psa_ingress_output_metadata_t {
  // The comment after each field specifies its initial value when the
  // Ingress control block begins executing.
  ClassOfService_t class_of_service; // 0
  bool clone; // false
  CloneSessionId_t clone_session_id; // initial value is undefined
  bool drop; // true
  bool resubmit; // false
  MulticastGroup_t multicast_group; // 0
  PortId_t egress_port; // initial value is undefined
}
// END:Metadata_ingress_output
struct psa_egress_input_metadata_t {
  ClassOfService_t class_of_service;
  PortId_t egress_port;
  PSA_PacketPath_t packet_path;
  EgressInstance_t instance; /// instance comes from the PacketReplicationEngine
  Timestamp_t egress_timestamp;
  ParserError_t parser_error;
}

/// This struct is an 'in' parameter to the egress deparser.  It
/// includes enough data for the egress deparser to distinguish
/// whether the packet should be recirculated or not.
struct psa_egress_deparser_input_metadata_t {
  PortId_t egress_port;
}
// BEGIN:Metadata_egress_output
struct psa_egress_output_metadata_t {
  // The comment after each field specifies its initial value when the
  // Egress control block begins executing.
  bool clone; // false
  CloneSessionId_t clone_session_id; // initial value is undefined
  bool drop; // false
}
// END:Metadata_egress_output
// END:Metadata_types

/// During the IngressDeparser execution, psa_clone_i2e returns true
/// if and only if a clone of the ingress packet is being made to
/// egress for the packet being processed.  If there are any
/// assignments to the out parameter clone_i2e_meta in the
/// IngressDeparser, they must be inside an if statement that only
/// allows those assignments to execute if psa_clone_i2e(istd) returns
/// true.  psa_clone_i2e can be implemented by returning istd.clone

@pure
extern bool psa_clone_i2e(in psa_ingress_output_metadata_t istd);

/// During the IngressDeparser execution, psa_resubmit returns true if
/// and only if the packet is being resubmitted.  If there are any
/// assignments to the out parameter resubmit_meta in the
/// IngressDeparser, they must be inside an if statement that only
/// allows those assignments to execute if psa_resubmit(istd) returns
/// true.  psa_resubmit can be implemented by returning (!istd.drop &&
/// istd.resubmit)

@pure
extern bool psa_resubmit(in psa_ingress_output_metadata_t istd);

/// During the IngressDeparser execution, psa_normal returns true if
/// and only if the packet is being sent 'normally' as unicast or
/// multicast to egress.  If there are any assignments to the out
/// parameter normal_meta in the IngressDeparser, they must be inside
/// an if statement that only allows those assignments to execute if
/// psa_normal(istd) returns true.  psa_normal can be implemented by
/// returning (!istd.drop && !istd.resubmit)

@pure
extern bool psa_normal(in psa_ingress_output_metadata_t istd);

/// During the EgressDeparser execution, psa_clone_e2e returns true if
/// and only if a clone of the egress packet is being made to egress
/// for the packet being processed.  If there are any assignments to
/// the out parameter clone_e2e_meta in the EgressDeparser, they must
/// be inside an if statement that only allows those assignments to
/// execute if psa_clone_e2e(istd) returns true.  psa_clone_e2e can be
/// implemented by returning istd.clone

@pure
extern bool psa_clone_e2e(in psa_egress_output_metadata_t istd);

/// During the EgressDeparser execution, psa_recirculate returns true
/// if and only if the packet is being recirculated.  If there are any
/// assignments to recirculate_meta in the EgressDeparser, they must
/// be inside an if statement that only allows those assignments to
/// execute if psa_recirculate(istd) returns true.  psa_recirculate
/// can be implemented by returning (!istd.drop && (edstd.egress_port
/// == PSA_PORT_RECIRCULATE))

@pure
extern bool psa_recirculate(in psa_egress_output_metadata_t istd,
                            in psa_egress_deparser_input_metadata_t edstd);


extern void assert(in bool check);
extern void assume(in bool check);

// BEGIN:Match_kinds
match_kind {
    range, /// Used to represent min..max intervals
    selector /// Used for dynamic action selection via the ActionSelector extern
}
// END:Match_kinds

// BEGIN:Action_send_to_port
/// Modify ingress output metadata to cause one packet to be sent to
/// egress processing, and then to the output port egress_port.
/// (Egress processing may choose to drop the packet instead.)

/// This action does not change whether a clone or resubmit operation
/// will occur.

@noWarnUnused
action send_to_port(inout psa_ingress_output_metadata_t meta,
                    in PortId_t egress_port)
{
    meta.drop = false;
    meta.multicast_group = (MulticastGroup_t) 0;
    meta.egress_port = egress_port;
}
// END:Action_send_to_port

// BEGIN:Action_multicast
/// Modify ingress output metadata to cause 0 or more copies of the
/// packet to be sent to egress processing.

/// This action does not change whether a clone or resubmit operation
/// will occur.

@noWarnUnused
action multicast(inout psa_ingress_output_metadata_t meta,
                 in MulticastGroup_t multicast_group)
{
    meta.drop = false;
    meta.multicast_group = multicast_group;
}
// END:Action_multicast

// BEGIN:Action_ingress_drop
/// Modify ingress output metadata to cause no packet to be sent for
/// normal egress processing.

/// This action does not change whether a clone will occur.  It will
/// prevent a packet from being resubmitted.

@noWarnUnused
action ingress_drop(inout psa_ingress_output_metadata_t meta)
{
    meta.drop = true;
}
// END:Action_ingress_drop

// BEGIN:Action_egress_drop
/// Modify egress output metadata to cause no packet to be sent out of
/// the device.

/// This action does not change whether a clone will occur.

@noWarnUnused
action egress_drop(inout psa_egress_output_metadata_t meta)
{
    meta.drop = true;
}
// END:Action_egress_drop

extern PacketReplicationEngine {
    PacketReplicationEngine();
    // There are no methods for this object callable from a P4
    // program.  This extern exists so it will have an instance with a
    // name that the control plane can use to make control plane API
    // calls on this object.
}

extern BufferingQueueingEngine {
    BufferingQueueingEngine();
    // There are no methods for this object callable from a P4
    // program.  See comments for PacketReplicationEngine.
}

// BEGIN:Hash_algorithms
enum PSA_HashAlgorithm_t {
  IDENTITY,
  CRC32,
  CRC32_CUSTOM,
  CRC16,
  CRC16_CUSTOM,
  ONES_COMPLEMENT16, /// One's complement 16-bit sum used for IPv4 headers,
                      /// TCP, and UDP.
  TARGET_DEFAULT /// target implementation defined
}
// END:Hash_algorithms

// BEGIN:Hash_extern
extern Hash<O> {
  /// Constructor
  Hash(PSA_HashAlgorithm_t algo);

  /// Compute the hash for data.
  /// @param data The data over which to calculate the hash.
  /// @return The hash value.
  @pure
  O get_hash<D>(in D data);

  /// Compute the hash for data, with modulo by max, then add base.
  /// @param base Minimum return value.
  /// @param data The data over which to calculate the hash.
  /// @param max The hash value is divided by max to get modulo.
  ///        An implementation may limit the largest value supported,
  ///        e.g. to a value like 32, or 256, and may also only
  ///        support powers of 2 for this value.  P4 developers should
  ///        limit their choice to such values if they wish to
  ///        maximize portability.
  /// @return (base + (h % max)) where h is the hash value.
  @pure
  O get_hash<T, D>(in T base, in D data, in T max);
}
// END:Hash_extern

// BEGIN:Checksum_extern
extern Checksum<W> {
  /// Constructor
  Checksum(PSA_HashAlgorithm_t hash);

  /// Reset internal state and prepare unit for computation.
  /// Every instance of a Checksum object is automatically initialized as
  /// if clear() had been called on it. This initialization happens every
  /// time the object is instantiated, that is, whenever the parser or control
  /// containing the Checksum object are applied.
  /// All state maintained by the Checksum object is independent per packet.
  void clear();

  /// Add data to checksum
  void update<T>(in T data);

  /// Get checksum for data added (and not removed) since last clear
  @noSideEffects
  W get();
}
// END:Checksum_extern

// BEGIN:InternetChecksum_extern
// Checksum based on `ONES_COMPLEMENT16` algorithm used in IPv4, TCP, and UDP.
// Supports incremental updating via `subtract` method.
// See IETF RFC 1624.
extern InternetChecksum {
  /// Constructor
  InternetChecksum();

  /// Reset internal state and prepare unit for computation.  Every
  /// instance of an InternetChecksum object is automatically
  /// initialized as if clear() had been called on it, once for each
  /// time the parser or control it is instantiated within is
  /// executed.  All state maintained by it is independent per packet.
  void clear();

  /// Add data to checksum.  data must be a multiple of 16 bits long.
  void add<T>(in T data);

  /// Subtract data from existing checksum.  data must be a multiple of
  /// 16 bits long.
  void subtract<T>(in T data);

  /// Get checksum for data added (and not removed) since last clear
  @noSideEffects
  bit<16> get();

  /// Get current state of checksum computation.  The return value is
  /// only intended to be used for a future call to the set_state
  /// method.
  @noSideEffects
  bit<16> get_state();

  /// Restore the state of the InternetChecksum instance to one
  /// returned from an earlier call to the get_state method.  This
  /// state could have been returned from the same instance of the
  /// InternetChecksum extern, or a different one.
  void set_state(in bit<16> checksum_state);
}
// END:InternetChecksum_extern

// BEGIN:CounterType_defn
enum PSA_CounterType_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}
// END:CounterType_defn

// BEGIN:Counter_extern
/// Indirect counter with n_counters independent counter values, where
/// every counter value has a data plane size specified by type W.

extern Counter<W, S> {
  Counter(bit<32> n_counters, PSA_CounterType_t type);
  void count(in S index);

  /*
  /// The control plane API uses 64-bit wide counter values.  It is
  /// not intended to represent the size of counters as they are
  /// stored in the data plane.  It is expected that control plane
  /// software will periodically read the data plane counter values,
  /// and accumulate them into larger counters that are large enough
  /// to avoid reaching their maximum values for a suitably long
  /// operational time.  A 64-bit byte counter increased at maximum
  /// line rate for a 100 gigabit port would take over 46 years to
  /// wrap.

  @ControlPlaneAPI
  {
    bit<64> read      (in S index);
    bit<64> sync_read (in S index);
    void set          (in S index, in bit<64> seed);
    void reset        (in S index);
    void start        (in S index);
    void stop         (in S index);
  }
  */
}
// END:Counter_extern

// BEGIN:DirectCounter_extern
extern DirectCounter<W> {
  DirectCounter(PSA_CounterType_t type);
  void count();

  /*
  @ControlPlaneAPI
  {
    W    read<W>      (in TableEntry key);
    W    sync_read<W> (in TableEntry key);
    void set          (in TableEntry key, in W seed);
    void reset        (in TableEntry key);
    void start        (in TableEntry key);
    void stop         (in TableEntry key);
  }
  */
}
// END:DirectCounter_extern

// BEGIN:MeterType_defn
enum PSA_MeterType_t {
    PACKETS,
    BYTES
}
// END:MeterType_defn

// BEGIN:MeterColor_defn

typedef bit<8> PSA_MeterColorUint_t;
@p4runtime_translation("p4.org/psa/v1/PSA_MeterColor_t", 8)
type PSA_MeterColorUint_t PSA_MeterColor_t;

const PSA_MeterColor_t PSA_METERCOLOR_GREEN = (PSA_MeterColor_t) 8w0;
const PSA_MeterColor_t PSA_METERCOLOR_YELLOW = (PSA_MeterColor_t) 8w1;
const PSA_MeterColor_t PSA_METERCOLOR_RED = (PSA_MeterColor_t) 8w3;
# 642 "/home/rvantipalli/p4factory/install/share/p4c/p4include/psa.p4"
// END:MeterColor_defn

// BEGIN:Meter_extern
// Indexed meter with n_meters independent meter states.

extern Meter<S> {
  Meter(bit<32> n_meters, PSA_MeterType_t type);

  // Use this method call to perform a color aware meter update (see
  // RFC 2698). The color of the packet before the method call was
  // made is specified by the color parameter.
  PSA_MeterColor_t execute(in S index, in PSA_MeterColor_t color);

  // Use this method call to perform a color blind meter update (see
  // RFC 2698).  It may be implemented via a call to execute(index,
  // MeterColor_t.GREEN), which has the same behavior.
  PSA_MeterColor_t execute(in S index);

  /*
  @ControlPlaneAPI
  {
    reset(in MeterColor_t color);
    setParams(in S index, in MeterConfig config);
    getParams(in S index, out MeterConfig config);
  }
  */
}
// END:Meter_extern

// BEGIN:DirectMeter_extern
extern DirectMeter {
  DirectMeter(PSA_MeterType_t type);
  // See the corresponding methods for extern Meter.
  PSA_MeterColor_t execute(in PSA_MeterColor_t color);
  PSA_MeterColor_t execute();

  /*
  @ControlPlaneAPI
  {
    reset(in TableEntry entry, in MeterColor_t color);
    void setConfig(in TableEntry entry, in MeterConfig config);
    void getConfig(in TableEntry entry, out MeterConfig config);
  }
  */
}
// END:DirectMeter_extern

// BEGIN:Register_extern
extern Register<T, S> {
  /// Instantiate an array of <size> registers. The initial value is
  /// undefined.
  Register(bit<32> size);
  /// Initialize an array of <size> registers and set their value to
  /// initial_value.
  Register(bit<32> size, T initial_value);

  @noSideEffects
  T read (in S index);
  void write (in S index, in T value);

  /*
  @ControlPlaneAPI
  {
    T    read<T>      (in S index);
    void set          (in S index, in T seed);
    void reset        (in S index);
  }
  */
}
// END:Register_extern

// BEGIN:Random_extern
extern Random<T> {

  /// Return a random value in the range [min, max], inclusive.
  /// Implementations are allowed to support only ranges where (max -
  /// min + 1) is a power of 2.  P4 developers should limit their
  /// arguments to such values if they wish to maximize portability.

  Random(T min, T max);
  T read();

  /*
  @ControlPlaneAPI
  {
    void reset();
    void setSeed(in T seed);
  }
  */
}
// END:Random_extern

// BEGIN:ActionProfile_extern
extern ActionProfile {
  /// Construct an action profile of 'size' entries
  ActionProfile(bit<32> size);

  /*
  @ControlPlaneAPI
  {
     entry_handle add_member    (action_ref, action_data);
     void         delete_member (entry_handle);
     entry_handle modify_member (entry_handle, action_ref, action_data);
  }
  */
}
// END:ActionProfile_extern

// BEGIN:ActionSelector_extern
extern ActionSelector {
  /// Construct an action selector of 'size' entries
  /// @param algo hash algorithm to select a member in a group
  /// @param size number of entries in the action selector
  /// @param outputWidth size of the key
  ActionSelector(PSA_HashAlgorithm_t algo, bit<32> size, bit<32> outputWidth);

  /*
  @ControlPlaneAPI
  {
     entry_handle add_member        (action_ref, action_data);
     void         delete_member     (entry_handle);
     entry_handle modify_member     (entry_handle, action_ref, action_data);
     group_handle create_group      ();
     void         delete_group      (group_handle);
     void         add_to_group      (group_handle, entry_handle);
     void         delete_from_group (group_handle, entry_handle);
  }
  */
}
// END:ActionSelector_extern

// BEGIN:Digest_extern
extern Digest<T> {
  Digest(); /// define a digest stream to the control plane
  void pack(in T data); /// emit data into the stream

  /*
  @ControlPlaneAPI
  {
  T data;                           /// If T is a list, control plane generates a struct.
  int unpack(T& data);              /// unpacked data is in T&, int return status code.
  }
  */
}
// END:Digest_extern

// BEGIN:Programmable_blocks
parser IngressParser<H, M, RESUBM, RECIRCM>(
    packet_in buffer,
    out H parsed_hdr,
    inout M user_meta,
    in psa_ingress_parser_input_metadata_t istd,
    in RESUBM resubmit_meta,
    in RECIRCM recirculate_meta);

control Ingress<H, M>(
    inout H hdr, inout M user_meta,
    in psa_ingress_input_metadata_t istd,
    inout psa_ingress_output_metadata_t ostd);

control IngressDeparser<H, M, CI2EM, RESUBM, NM>(
    packet_out buffer,
    out CI2EM clone_i2e_meta,
    out RESUBM resubmit_meta,
    out NM normal_meta,
    inout H hdr,
    in M meta,
    in psa_ingress_output_metadata_t istd);

parser EgressParser<H, M, NM, CI2EM, CE2EM>(
    packet_in buffer,
    out H parsed_hdr,
    inout M user_meta,
    in psa_egress_parser_input_metadata_t istd,
    in NM normal_meta,
    in CI2EM clone_i2e_meta,
    in CE2EM clone_e2e_meta);

control Egress<H, M>(
    inout H hdr, inout M user_meta,
    in psa_egress_input_metadata_t istd,
    inout psa_egress_output_metadata_t ostd);

control EgressDeparser<H, M, CE2EM, RECIRCM>(
    packet_out buffer,
    out CE2EM clone_e2e_meta,
    out RECIRCM recirculate_meta,
    inout H hdr,
    in M meta,
    in psa_egress_output_metadata_t istd,
    in psa_egress_deparser_input_metadata_t edstd);

package IngressPipeline<IH, IM, NM, CI2EM, RESUBM, RECIRCM>(
    IngressParser<IH, IM, RESUBM, RECIRCM> ip,
    Ingress<IH, IM> ig,
    IngressDeparser<IH, IM, CI2EM, RESUBM, NM> id);

package EgressPipeline<EH, EM, NM, CI2EM, CE2EM, RECIRCM>(
    EgressParser<EH, EM, NM, CI2EM, CE2EM> ep,
    Egress<EH, EM> eg,
    EgressDeparser<EH, EM, CE2EM, RECIRCM> ed);

package PSA_Switch<IH, IM, EH, EM, NM, CI2EM, CE2EM, RESUBM, RECIRCM> (
    IngressPipeline<IH, IM, NM, CI2EM, RESUBM, RECIRCM> ingress,
    PacketReplicationEngine pre,
    EgressPipeline<EH, EM, NM, CI2EM, CE2EM, RECIRCM> egress,
    BufferingQueueingEngine bqe);

// END:Programmable_blocks
# 5 "sai_p4/instantiations/google/../../fixed/arch.p4" 2






// psa defs
error {
    UnhandledIPv4Options,
    BadIPv4HeaderChecksum
}
# 2 "sai_p4/instantiations/google/sai.p4" 2

// These headers have to come first, to override their fixed counterparts.
# 1 "sai_p4/instantiations/google/roles.h" 1
# 5 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/bitwidths.p4" 1
# 6 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/minimum_guaranteed_sizes.p4" 1



// -- Fixed Table sizes --------------------------------------------------------
# 14 "sai_p4/instantiations/google/minimum_guaranteed_sizes.p4"
# copybara:strip_begin(comment only applies internally)
// The IPv4 and IPv6 minimums appear to hold in practice, but Broadcom's
// Algorithmic LPM implementation is subtle, and we do not understand it well
// enough to guarantee these limits. If you are planning to develop a feature
// that relies on these minimums, please talk to us first.
//
// These limits are taken from Sandcastle:
// http://google3/platforms/networking/sandblaze/stack/hal/target/config/tomahawk3_l3_lpm_profiles.txt
# copybara:strip_end
// The implementation of ALPM varies across ASICs and requires more
// custom P4 externs to accurately program ALPM
# 37 "sai_p4/instantiations/google/minimum_guaranteed_sizes.p4"
// The maximum number of wcmp groups.


// The maximum sum of weights across all wcmp groups.


// The maximum sum of weights for each wcmp group.


// -- ACL Table sizes ----------------------------------------------------------




// Maximum channelization for current use-cases is 96 ports, and each port may
// have up to 2 linkqual flows associated with it.


// 1 entry for LLDP, 1 entry for ND, and 6 entries for traceroute: TTL 0,1,2 for
// IPv4 and IPv6
# 7 "sai_p4/instantiations/google/sai.p4" 2

# 1 "sai_p4/instantiations/google/../../fixed/headers.p4" 1
# 22 "sai_p4/instantiations/google/../../fixed/headers.p4"
// move these to a sai_ids.h







typedef bit<48> ethernet_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<128> ipv6_addr_t;
typedef bit<12> vlan_id_t;

// -- Protocol headers ---------------------------------------------------------



header ethernet_t {
  ethernet_addr_t dst_addr;
  ethernet_addr_t src_addr;
  bit<16> ether_type;
}

header vlan_t {
  bit<3> pcp;
  bit<1> cfi;
  vlan_id_t vid;
  bit<16> ether_type;
}



header ipv4_t {
  bit<4> version;
  bit<4> ihl;
  bit<6> dscp; // The 6 most significant bits of the diff_serv field.
  bit<2> ecn; // The 2 least significant bits of the diff_serv field.
  bit<16> total_len;
  bit<16> identification;
  bit<1> reserved;
  bit<1> do_not_fragment;
  bit<1> more_fragments;
  bit<13> frag_offset;
  bit<8> ttl;
  bit<8> protocol;
  bit<16> header_checksum;
  ipv4_addr_t src_addr;
  ipv4_addr_t dst_addr;
}



header ipv6_t {
  bit<4> version;
  bit<6> dscp; // The 6 most significant bits of the traffic_class field.
  bit<2> ecn; // The 2 least significant bits of the traffic_class field.
  bit<20> flow_label;
  bit<16> payload_length;
  bit<8> next_header;
  bit<8> hop_limit;
  ipv6_addr_t src_addr;
  ipv6_addr_t dst_addr;
}

header udp_t {
  bit<16> src_port;
  bit<16> dst_port;
  bit<16> hdr_length;
  bit<16> checksum;
}

header tcp_t {
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

header icmp_t {
  bit<8> type;
  bit<8> code;
  bit<16> checksum;
}

header arp_t {
  bit<16> hw_type;
  bit<16> proto_type;
  bit<8> hw_addr_len;
  bit<8> proto_addr_len;
  bit<16> opcode;
  bit<48> sender_hw_addr;
  bit<32> sender_proto_addr;
  bit<48> target_hw_addr;
  bit<32> target_proto_addr;
}



header gre_t {
  bit<1> checksum_present;
  bit<1> routing_present;
  bit<1> key_present;
  bit<1> sequence_present;
  bit<1> strict_source_route;
  bit<3> recursion_control;
  bit<1> acknowledgement_present;
  bit<4> flags;
  bit<3> version;
  bit<16> protocol;
}

// VXLAN -- RFC 7348
header vxlan_t {
  bit<8> flags;
  bit<24> reserved;
  bit<24> vni;
  bit<8> reserved2;
}


struct empty_metadata_t {
}
# 9 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/metadata.p4" 1



##include "arch.p4"
# 1 "sai_p4/instantiations/google/../../fixed/ids.h" 1



// All declarations (tables, actions, action profiles, meters, counters) have a
// stable ID. This list will evolve as new declarations are added. IDs cannot be
// reused. If a declaration is removed, its ID macro is kept and marked reserved
// to avoid the ID being reused.
//
// The IDs are classified using the 8 most significant bits to be compatible
// with "6.3. ID Allocation for P4Info Objects" in the P4Runtime specification.

// --- Tables ------------------------------------------------------------------

// IDs of fixed SAI tables (8 most significant bits = 0x02).
# 26 "sai_p4/instantiations/google/../../fixed/ids.h"
// L2 tables





// Tunnel tables







// --- Actions -----------------------------------------------------------------

// IDs of fixed SAI actions (8 most significant bits = 0x01).
# 70 "sai_p4/instantiations/google/../../fixed/ids.h"
// --- Copy to CPU session -----------------------------------------------------

// The COPY_TO_CPU_SESSION_ID must be programmed in the target using P4Runtime:
//
// type: INSERT
// entity {
//   packet_replication_engine_entry {
//     clone_session_entry {
//       session_id: COPY_TO_CPU_SESSION_ID
//       replicas { egress_port: 0xfffffffd } # to CPU
//     }
//   }
// }
//


// --- Packet-IO ---------------------------------------------------------------

// Packet-in ingress port field. Indicates which port the packet arrived at.
// Uses @p4runtime_translation(.., string).


// Packet-in target egress port field. Indicates the port a packet would have
// taken if it had not gotten trapped. Uses @p4runtime_translation(.., string).


// Packet-out egress port field. Indicates the egress port for the packet-out to
// be taken. Mutually exclusive with "submit_to_ingress". Uses
// @p4runtime_translation(.., string).


// Packet-out submit_to_ingress field. Indicates that the packet should go
// through the ingress pipeline to determine which port to take (if any).
// Mutually exclusive with "egress_port".


//--- Packet Replication Engine Instances --------------------------------------

// Egress instance type definitions.
// The egress instance is a 32-bit standard metadata set by the packet
// replication engine (PRE) in the V1Model architecture. However, the values are
// not defined by the P4 specification. Here we define our own values; these may
// be changed when we adopt another architecture.
# 6 "sai_p4/instantiations/google/../../fixed/metadata.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/headers.p4" 1
# 7 "sai_p4/instantiations/google/../../fixed/metadata.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/bitwidths.p4" 1
# 8 "sai_p4/instantiations/google/../../fixed/metadata.p4" 2

// -- Translated Types ---------------------------------------------------------

// BMv2 does not support @p4runtime_translation.


@p4runtime_translation("", string)

type bit<10> nexthop_id_t;


@p4runtime_translation("", string)

type bit<12> wcmp_group_id_t;


@p4runtime_translation("", string)

type bit<10> vrf_id_t;


@p4runtime_translation("", string)

type bit<10> router_interface_id_t;


@p4runtime_translation("", string)

type bit<10> neighbor_id_t;


@p4runtime_translation("", string)

type bit<9> port_id_t;


@p4runtime_translation("", string)

type bit<10> mirror_session_id_t;


@p4runtime_translation("", string)

type bit<8> qos_queue_t;


@p4runtime_translation("", string)

type bit<8> tunnel_id_t;


@p4runtime_translation("", string)

type bit<24> vni_id_t;


@p4runtime_translation("", string)

type bit<8> samplepacket_id_t;

@p4runtime_translation("", string)
type bit<8> traffic_class_t;

@p4runtime_translation("", string)
type bit<8> etrap_index_t;

// -- Meters -------------------------------------------------------------------

enum MeterColor_t { GREEN, YELLOW, RED };

// -- Packet IO headers --------------------------------------------------------

// TODO: extend the P4 program to actually define the semantics of these.

@controller_header("packet_in")
header packet_in_header_t {
  // The port the packet ingressed on.

  bit<7> _pad1;

  @id(1)
  port_id_t ingress_port;

  bit<7> _pad2;

  // The initial intended egress port decided for the packet by the pipeline.
  @id(2)
  port_id_t target_egress_port;
}

@controller_header("packet_out")
header packet_out_header_t {
  // The port this packet should egress out of when `submit_to_ingress == 0`.
  // Meaningless when `submit_to_ingress == 1`.
  @id(1)
  port_id_t egress_port;
  // Should the packet be submitted to the ingress pipeline instead of being
  // sent directly?
  @id(2)
  bit<1> submit_to_ingress;
  // BMV2 backend requires headers to be multiple of 8-bits.
  @id(3)

  bit<6> unused_pad;



}

// -- Per Packet State ---------------------------------------------------------

header i2e_t {
  bit<4> bridge_type;
  bit<12> bridge_id;
  bit<16> bridge_port;
  ethernet_addr_t src_mac;
  ethernet_addr_t dst_mac;
  bool admit_to_l3;
  bit<7> pad;
}

struct headers_t {
  i2e_t i2e;
  // ERSPAN headers, not extracted during parsing.
  ethernet_t erspan_ethernet;
  ipv4_t erspan_ipv4;
  gre_t erspan_gre;

  ethernet_t ethernet;
  vlan_t vlan;
  ipv4_t ipv4;
  ipv6_t ipv6;
  icmp_t icmp;
  tcp_t tcp;
  udp_t udp;
  arp_t arp;
  vxlan_t vxlan;
  ethernet_t inner_ethernet;
  ipv4_t inner_ipv4;
  ipv6_t inner_ipv6;
  udp_t inner_udp;
  tcp_t inner_tcp;
  icmp_t inner_icmp;
}

// Header fields rewritten by the ingress pipeline. Rewrites are computed and
// stored in this struct, but actual rewriting is dealyed until the egress
// pipeline so that the original values aren't overridden and get be matched on.
struct packet_rewrites_t {
  ethernet_addr_t src_mac;
  ethernet_addr_t dst_mac;
}

struct port_metadata_t {
  bool admin_state; /* SAI_PORT_ATTR_ADMIN_STATE              */
  bool ingress_filtering; /* SAI_PORT_ATTR_INGRESS_FILTERING        */
  bool drop_untagged; /* SAI_PORT_ATTR_DROP_UNTAGGED            */
  bool drop_tagged; /* SAI_PORT_ATTR_DROP_UNTAGGED            */
  bit<12> port_vlan_id; /* SAI_PORT_ATTR_VLAN_ID                  */
  bit<16> mtu; /* SAI_PORT_ATTR_MTU                      */
  bit<3> default_vlan_priority; /* SAI_PORT_ATTR_DEFAULT_VLAN_PRIORITY    */
}

struct bridge_metadata_t {
  bit<4> type;
  bit<12> id;
  bool learn_disable;
  bit<16> mac_addr_count; // register check to learn on smac miss?
  bit<12> vlan; // could merge with id as alias
  bool tag; // tagged mode
  bool admin_state;
  bit<2> pad;
}

struct vlan_metadata_t {
  bit<8> stp_instance;
  bit<1> learn;
  bit<16> iacl;
  bit<16> eacl;
  bit<1> member;
}

struct tunnel_metadata_t {
  tunnel_id_t id;
  vni_id_t vni;
  bit<4> type;
  bit<8> map_id;
  bit<8> map_type;
  bool terminate;
  bit<16> hash;
}

@flexible
struct smac_learn_digest {
  bit<16> bridge_port;
  bit<48> mac;
  bit<12> bridge_id;
  bit<4> bridge_type;
}

// Local metadata for each packet being processed.
struct local_metadata_t {
  bool admit_to_l3;
  vrf_id_t vrf_id;
  packet_rewrites_t packet_rewrites;
  bit<16> l4_src_port;
  bit<16> l4_dst_port;
  bit<16> wcmp_selector_input;
  // mirroring data, we can't group the into a struct, because BMv2 doesn't
  // support passing structs in clone3.
  bool mirror_session_id_valid;
  mirror_session_id_t mirror_session_id_value;
  ipv4_addr_t mirroring_src_ip;
  ipv4_addr_t mirroring_dst_ip;
  ethernet_addr_t mirroring_src_mac;
  ethernet_addr_t mirroring_dst_mac;
  bit<8> mirroring_ttl;
  bit<8> mirroring_tos;
  // TODO: consider modeling metering beyond control plane API.
  PSA_MeterColor_t color;
  // We consistently use local_metadata.ingress_port instead of
  // standard_metadata.ingress_port in the P4 tables to ensure that the P4Info
  // has port_id_t as the type for all fields that match on ports. This allows
  // tools to treat ports specially (e.g. a fuzzer).
  port_id_t ingress_port;

  // L2 metadata
  port_metadata_t port;
  bridge_metadata_t bridge;
  vlan_metadata_t vlan;
  bit<16> mgid;
  // ingress_vlan and bridge.id for all intents have same value for 1Q
  bit<12> ingress_vlan;
  smac_learn_digest smac_learn;
  bit<16> learn_port;
  bit<1> smac_learn_enable;
  bit<16> ibridge_port;
  bit<16> obridge_port;

  // Tunnel metadata
  tunnel_metadata_t tunnel;
  ethernet_addr_t inner_dst_mac;
  ipv4_addr_t outer_ip_src_addr;
  ipv4_addr_t outer_ip_dst_addr;

  // sflow
  samplepacket_id_t samplepacket_id;

  traffic_class_t tc;

}

action copy_i2e_metadata(inout headers_t headers,
                         in local_metadata_t local_metadata) {
  headers.i2e.setValid();
  headers.i2e.bridge_type = local_metadata.bridge.type;
  headers.i2e.bridge_id = local_metadata.bridge.id;
  headers.i2e.bridge_port = local_metadata.obridge_port;
  headers.i2e.src_mac = local_metadata.packet_rewrites.src_mac;
  headers.i2e.dst_mac = local_metadata.packet_rewrites.dst_mac;
  headers.i2e.admit_to_l3 = local_metadata.admit_to_l3;
}
# 10 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/parser.p4" 1



# 1 "sai_p4/instantiations/google/../../fixed/arch.p4" 1
# 5 "sai_p4/instantiations/google/../../fixed/parser.p4" 2

# 1 "sai_p4/instantiations/google/../../fixed/metadata.p4" 1
# 7 "sai_p4/instantiations/google/../../fixed/parser.p4" 2

parser packet_parser(packet_in packet, out headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_ingress_parser_input_metadata_t standard_metadata, in empty_metadata_t resub_meta, in empty_metadata_t recirc_meta) {

  InternetChecksum() csum;

  state start {
    // Initialize local metadata fields.
    // TODO: Currently, all packets are admitted to L3 pipeline.
    local_metadata.admit_to_l3 = true;
    // local_metadata.admit_to_l3 = false;
    local_metadata.vrf_id = 0;
    local_metadata.packet_rewrites.src_mac = 0;
    local_metadata.packet_rewrites.dst_mac = 0;
    local_metadata.l4_src_port = 0;
    local_metadata.l4_dst_port = 0;
    local_metadata.wcmp_selector_input = 0;
    local_metadata.mirror_session_id_valid = false;
    local_metadata.color = PSA_METERCOLOR_GREEN;
    local_metadata.ingress_port = (port_id_t)(PortIdUint_t)standard_metadata.ingress_port;

    transition parse_ethernet;
  }

  state parse_ethernet {
    packet.extract(headers.ethernet);
    transition select(headers.ethernet.ether_type) {
      0x0800: parse_ipv4;
      0x86dd: parse_ipv6;
      0x0806: parse_arp;
      0x8100: parse_vlan;
      _: accept;
    }
  }

  state parse_vlan {
    packet.extract(headers.vlan);
    transition select(headers.vlan.ether_type) {
      0x0800: parse_ipv4;
      0x86dd: parse_ipv6;
      0x0806: parse_arp;
      _: accept;
    }
  }

  state parse_ipv4 {
    packet.extract(headers.ipv4);

    csum.add({
        /* 16-bit word  0   */ headers.ipv4.version, headers.ipv4.ihl, headers.ipv4.dscp, headers.ipv4.ecn,
        /* 16-bit word  1   */ headers.ipv4.total_len,
        /* 16-bit word  2   */ headers.ipv4.identification,
        /* 16-bit word  3   */ headers.ipv4.reserved, headers.ipv4.do_not_fragment, headers.ipv4.more_fragments, headers.ipv4.frag_offset,
        /* 16-bit word  4   */ headers.ipv4.ttl, headers.ipv4.protocol,
        /* 16-bit word  5 skip hdr.ipv4.header_checksum, */
        /* 16-bit words 6-7 */ headers.ipv4.src_addr,
        /* 16-bit words 8-9 */ headers.ipv4.dst_addr
    });
    // The verify statement below will cause the parser to enter
    // the reject state, and thus terminate parsing immediately,
    // if the IPv4 header checksum is wrong.  It will also record
    // the error error.BadIPv4HeaderChecksum, which will be
    // available in a metadata field in the ingress control block.
    verify(csum.get() == headers.ipv4.header_checksum, error.BadIPv4HeaderChecksum);

    transition select(headers.ipv4.protocol) {
      0x01: parse_icmp;
      0x06: parse_tcp;
      0x11: parse_udp;
      _: accept;
    }
  }

  state parse_ipv6 {
    packet.extract(headers.ipv6);
    transition select(headers.ipv6.next_header) {
      0x3a: parse_icmp;
      0x06: parse_tcp;
      0x11: parse_udp;
      _: accept;
    }
  }

  state parse_tcp {
    packet.extract(headers.tcp);
    // Normalize TCP port metadata to common port metadata.
    local_metadata.l4_src_port = headers.tcp.src_port;
    local_metadata.l4_dst_port = headers.tcp.dst_port;
    transition accept;
  }

  state parse_udp {
    packet.extract(headers.udp);
    // Normalize UDP port metadata to common port metadata.
    local_metadata.l4_src_port = headers.udp.src_port;
    local_metadata.l4_dst_port = headers.udp.dst_port;
    transition select(headers.udp.dst_port) {
      4379: parse_vxlan;
      default: accept;
    }
  }

  state parse_icmp {
    packet.extract(headers.icmp);
    transition accept;
  }

  state parse_arp {
    packet.extract(headers.arp);
    transition accept;
  }

  state parse_vxlan {
    packet.extract(headers.vxlan);
    local_metadata.tunnel.type = 4w1;
    local_metadata.tunnel.vni = (vni_id_t)(bit<24>)headers.vxlan.vni;
    transition parse_inner_ethernet;
  }

  state parse_ipinip {




    transition accept;

  }

  state parse_ipv6inip {




      transition accept;

  }

  state parse_inner_ethernet {
    packet.extract(headers.inner_ethernet);
    transition select(headers.inner_ethernet.ether_type) {
      0x0800 : parse_inner_ipv4;
      0x86dd : parse_inner_ipv6;
      default : accept;
    }
  }

  state parse_inner_ipv4 {
    packet.extract(headers.inner_ipv4);
    // inner_ipv4_checksum.add(hdr.inner_ipv4);
    // ig_md.flags.inner_ipv4_checksum_err = inner_ipv4_checksum.verify();
    transition select(headers.inner_ipv4.protocol) {
      0x01 : parse_inner_icmp;
      0x06 : parse_inner_tcp;
      0x11 : parse_inner_udp;
      default : accept;
    }
  }

  state parse_inner_ipv6 {
    packet.extract(headers.inner_ipv6);
    transition select(headers.inner_ipv6.next_header) {
      0x3a : parse_inner_icmp;
      0x06 : parse_inner_tcp;
      0x11 : parse_inner_udp;
      default : accept;
    }
  }

  state parse_inner_udp {
    packet.extract(headers.inner_udp);
    transition accept;
  }

  state parse_inner_tcp {
    packet.extract(headers.inner_tcp);
    transition accept;
  }

  state parse_inner_icmp {
    packet.extract(headers.inner_icmp);
    transition accept;
  }
} // parser packet_parser

control packet_deparser(packet_out packet, out empty_metadata_t clone_i2e_meta, out empty_metadata_t resubmit_meta, out empty_metadata_t normal_meta, inout headers_t headers, in local_metadata_t local_metadata, in psa_ingress_output_metadata_t istd) {

  Digest<smac_learn_digest>() smac_digest;
  apply {
    if (local_metadata.smac_learn_enable == 1w1) {
      smac_digest.pack(local_metadata.smac_learn);
    }



    packet.emit(headers.i2e);
    packet.emit(headers.erspan_ethernet);
    packet.emit(headers.erspan_ipv4);
    packet.emit(headers.erspan_gre);
    packet.emit(headers.ethernet);
    packet.emit(headers.vlan);
    packet.emit(headers.ipv4);
    packet.emit(headers.ipv6);
    packet.emit(headers.arp);
    packet.emit(headers.icmp);
    packet.emit(headers.tcp);
    packet.emit(headers.udp);
    packet.emit(headers.inner_ethernet);
    packet.emit(headers.inner_ipv4);
    packet.emit(headers.inner_ipv6);
    packet.emit(headers.inner_icmp);
    packet.emit(headers.inner_tcp);
    packet.emit(headers.inner_udp);
  }
} // control packet_deparser


// egress parser
parser egress_parser(packet_in buffer,
                      out headers_t headers,
                      inout local_metadata_t local_metadata,
                      in psa_egress_parser_input_metadata_t istd,
                      in empty_metadata_t normal_meta,
                      in empty_metadata_t clone_i2e_meta,
                      in empty_metadata_t clone_e2e_meta)
{
  state start {






    transition parse_i2e;

  }
  state parse_mirror {
    transition accept;
  }
  state parse_i2e {
    buffer.extract(headers.i2e);
    local_metadata.bridge.type = headers.i2e.bridge_type;
    local_metadata.bridge.id = headers.i2e.bridge_id;
    local_metadata.obridge_port = headers.i2e.bridge_port;
    local_metadata.packet_rewrites.src_mac = headers.i2e.src_mac;
    local_metadata.packet_rewrites.dst_mac = headers.i2e.dst_mac;
    local_metadata.admit_to_l3 = headers.i2e.admit_to_l3;

    transition parse_ethernet;
  }
  state parse_ethernet {
    buffer.extract(headers.ethernet);
    transition select(headers.ethernet.ether_type) {
      0x8100: parse_vlan;
      0x0800: parse_ipv4;
      0x86dd: parse_ipv6;
      0x0806: parse_arp;
      default : accept;
    }
  }
  state parse_vlan {
    buffer.extract(headers.vlan);
    transition select(headers.vlan.ether_type) {
      0x0800: parse_ipv4;
      0x86dd: parse_ipv6;
      0x0806: parse_arp;
      _: accept;
    }
  }

  state parse_ipv4 {
    buffer.extract(headers.ipv4);
    transition accept;
  }

  state parse_ipv6 {
    buffer.extract(headers.ipv6);
    transition accept;
  }

  state parse_arp {
    buffer.extract(headers.arp);
    transition accept;
  }
}

control egress_deparser(packet_out packet,
                        out empty_metadata_t clone_e2e_meta,
                        out empty_metadata_t recirculate_meta,
                        inout headers_t headers,
                        in local_metadata_t local_metadata,
                        in psa_egress_output_metadata_t istd,
                        in psa_egress_deparser_input_metadata_t edstd) {
  InternetChecksum() csum;
  InternetChecksum() outer_csum;
  apply {
    csum.add({
      /* 16-bit word  0   */ headers.ipv4.version, headers.ipv4.ihl, headers.ipv4.dscp, headers.ipv4.ecn,
      /* 16-bit word  1   */ headers.ipv4.total_len,
      /* 16-bit word  2   */ headers.ipv4.identification,
      /* 16-bit word  3   */ headers.ipv4.reserved, headers.ipv4.do_not_fragment, headers.ipv4.more_fragments, headers.ipv4.frag_offset,
      /* 16-bit word  4   */ headers.ipv4.ttl, headers.ipv4.protocol,
      /* 16-bit word  5 skip headers.ipv4.header_checksum, */
      /* 16-bit words 6-7 */ headers.ipv4.src_addr,
      /* 16-bit words 8-9 */ headers.ipv4.dst_addr
    });
    headers.ipv4.header_checksum = csum.get();

    if (headers.erspan_ipv4.isValid()) {
      outer_csum.add({
        /* 16-bit word  0   */ headers.erspan_ipv4.version, headers.erspan_ipv4.ihl, headers.erspan_ipv4.dscp, headers.erspan_ipv4.ecn,
        /* 16-bit word  1   */ headers.erspan_ipv4.total_len,
        /* 16-bit word  2   */ headers.erspan_ipv4.identification,
        /* 16-bit word  3   */ headers.erspan_ipv4.reserved, headers.erspan_ipv4.do_not_fragment, headers.erspan_ipv4.more_fragments, headers.erspan_ipv4.frag_offset,
        /* 16-bit word  4   */ headers.erspan_ipv4.ttl, headers.erspan_ipv4.protocol,
        /* 16-bit word  5 skip headers.erspan_ipv4.header_checksum, */
        /* 16-bit words 6-7 */ headers.erspan_ipv4.src_addr,
        /* 16-bit words 8-9 */ headers.erspan_ipv4.dst_addr
      });
      headers.erspan_ipv4.header_checksum = outer_csum.get();
    }
    packet.emit(headers);
  }
}
# 11 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/routing.p4" 1







# 1 "sai_p4/instantiations/google/../../fixed/roles.h" 1





// Instantiations of SAI P4 can override these roles by defining the macros.
# 9 "sai_p4/instantiations/google/../../fixed/routing.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/minimum_guaranteed_sizes.p4" 1



// A table's size specifies the minimum number of entries that must be supported
// by the given table.
//
// Consider for example a hash table with 1024 buckets, where each bucket can
// store two values. The table's size would be 2, because after installing
// two entries that land in the same bucket B, the third entry will be rejected
// if it also lands in B. Note that such collisions are unlikely, so the switch
// will very likely accept a much larger number of table entries than 2.
//
// Instantiations of SAI P4 can override these sizes by defining the following
// macros.
# 48 "sai_p4/instantiations/google/../../fixed/minimum_guaranteed_sizes.p4"
// The maximum sum of weights across all wcmp groups.




// The maximum sum of weights for each wcmp group.
# 10 "sai_p4/instantiations/google/../../fixed/routing.p4" 2

// This control block models the L3 routing pipeline.
//
// +-------+   +-------+ wcmp  +---------+       +-----------+
// |  lpm  |-->| group |------>| nexthop |----+->| router    |--> egress_port
// |       |   |       |------>|         |-+  |  | interface |--> src_mac
// +-------+   +-------+       +---------+ |  |  +-----------+
//   |   |                         ^       |  |  +-----------+
//   |   |                         |       |  +->| neighbor  |
//   V   +-------------------------+       +---->|           |--> dst_mac
//  drop                                         +-----------+
//
// The pipeline first performs a longest prefix match on the packet's
// destination IP address. The action associated with the match then either
// drops the packet, points to a nexthop, or points to a wcmp group which uses a
// hash of the packet to choose from a set of nexthops. The nexthop points to a
// router interface, which determines the packet's src_mac and the egress_port
// to forward the packet to. The nexthop also points to a neighbor which,
// together with the router_interface, determines the packet's dst_mac.
//
// Note that this block does not rewrite any header fields directly, but only
// records rewrites in `local_metadata.packet_rewrites`, from where they will be
// read and applied in the egress stage.
control routing(in headers_t headers,
                inout local_metadata_t local_metadata,
                in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  // Wcmp group id, only valid if `wcmp_group_id_valid` is true.
  bool wcmp_group_id_valid = false;
  wcmp_group_id_t wcmp_group_id_value;

  // Nexthop id, only valid if `nexthop_id_valid` is true.
  bool nexthop_id_valid = false;
  nexthop_id_t nexthop_id_value;

  // Router interface id, only valid if `router_interface_id_valid` is true.
  bool router_interface_id_valid = false;
  router_interface_id_t router_interface_id_value;

  // Neighbor id, only valid if `neighbor_id_valid` is true.
  bool neighbor_id_valid = false;
  neighbor_id_t neighbor_id_value;

  // Sets SAI_NEIGHBOR_ENTRY_ATTR_DST_MAC_ADDRESS.
  @id(0x01000001)
  action set_dst_mac(@id(1) @format(MAC_ADDRESS) ethernet_addr_t dst_mac) {
    local_metadata.packet_rewrites.dst_mac = dst_mac;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000040)
  table neighbor_table {
    key = {
      // Sets rif_id in sai_neighbor_entry_t. Can only refer to values that are
      // already programmed in the `router_interface_table`.
      router_interface_id_value : exact @id(1) @name("router_interface_id")
          @refers_to(router_interface_table, router_interface_id);
      // Sets ip_address in sai_neighbor_entry_t.
      neighbor_id_value : exact @id(2) @name("neighbor_id");
    }
    actions = {
      @proto_id(1) set_dst_mac;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  // Sets SAI_ROUTER_INTERFACE_ATTR_TYPE to SAI_ROUTER_INTERFACE_TYPE_PORT, and
  // SAI_ROUTER_INTERFACE_ATTR_PORT_ID, and
  // SAI_ROUTER_INTERFACE_ATTR_SRC_MAC_ADDRESS.
  @id(0x01000002)
  action set_port_and_src_mac(@id(1) port_id_t port,
                              @id(2) @format(MAC_ADDRESS)
                              ethernet_addr_t src_mac) {
    // Cast is necessary, because v1model does not define port using `type`.
    ostd.egress_port = (PortId_t)(PortIdUint_t)port;
    local_metadata.packet_rewrites.src_mac = src_mac;
  }

  // Sets SAI_ROUTER_INTERFACE_ATTR_TYPE to SAI_ROUTER_INTERFACE_TYPE_VLAN
  action set_vlan(@id(1) bit<12> bridge_id,
                  @id(2) @format(MAC_ADDRESS) ethernet_addr_t src_mac) {
    local_metadata.bridge.id = bridge_id;
    local_metadata.packet_rewrites.src_mac = src_mac;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000041)
  table router_interface_table {
    key = {
      router_interface_id_value : exact @id(1)
                                        @name("router_interface_id");
    }
    actions = {
      @proto_id(1) set_port_and_src_mac;
      @proto_id(2) set_vlan;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  // Sets SAI_NEXT_HOP_ATTR_TYPE to SAI_NEXT_HOP_TYPE_IP, and
  // SAI_NEXT_HOP_ATTR_ROUTER_INTERFACE_ID, and SAI_NEXT_HOP_ATTR_IP.
  //
  // This action can only refer to `router_interface_id`s and `neighbor_id`s,
  // if `router_interface_id` is a key in the `router_interface_table`, and
  // the `(router_interface_id, neighbor_id)` pair is a key in the
  // `neighbor_table`.
  //
  // Note that the @refers_to annotation could be more precise if it allowed
  // specifying that the pair (router_interface_id, neighbor_id) refers to the
  // two match fields in neighbor_table. This is still correct, but less
  // precise.
  // SAI_NEXT_HOP_ATTR_TYPE_IP
  @id(0x01000003)
  action set_nexthop(@id(1)
                     @refers_to(router_interface_table, router_interface_id)
                     @refers_to(neighbor_table, router_interface_id)
                     router_interface_id_t router_interface_id,
                     @id(2) @refers_to(neighbor_table, neighbor_id)
                     neighbor_id_t neighbor_id) {
    router_interface_id_valid = true;
    router_interface_id_value = router_interface_id;
    neighbor_id_valid = true;
    neighbor_id_value = neighbor_id;
  }

  // SAI_NEXT_HOP_ATTR_TYPE_TUNNEL_ENCAP
  @id(0x01000013)
  action set_tunnel(@id(1) @refers_to(tunnel_table, tunnel_id)
                    tunnel_id_t tunnel_id,
                    @id(2) ipv4_addr_t ip_addr,
                    @id(3) vni_id_t tunnel_vni,
                    @id(4) @format(MAC_ADDRESS)
                    ethernet_addr_t tunnel_mac) {
    local_metadata.tunnel.id = tunnel_id;
    local_metadata.outer_ip_dst_addr = ip_addr;
    local_metadata.inner_dst_mac = tunnel_mac;
    local_metadata.tunnel.vni = tunnel_vni;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000042)
  table nexthop_table {
    key = {
      nexthop_id_value : exact @id(1) @name("nexthop_id");
    }
    actions = {
      @proto_id(1) set_nexthop;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 1024;
  }

  // When called from a route, sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to
  // SAI_PACKET_ACTION_FORWARD, and SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a
  // SAI_OBJECT_TYPE_NEXT_HOP.
  //
  // When called from a group, sets SAI_NEXT_HOP_GROUP_MEMBER_ATTR_NEXT_HOP_ID.
  // When called from a group, sets SAI_NEXT_HOP_GROUP_MEMBER_ATTR_WEIGHT.
  //
  // This action can only refer to `nexthop_id`s that are programmed in the
  // `nexthop_table`.
  @id(0x01000005)
  action set_nexthop_id(@id(1) @refers_to(nexthop_table, nexthop_id)
                        nexthop_id_t nexthop_id) {
    nexthop_id_valid = true;
    nexthop_id_value = nexthop_id;
  }

  @max_group_size(1024)
  ActionSelector(PSA_HashAlgorithm_t.IDENTITY, 65536, 16) wcmp_group_selector;



  @p4runtime_role("sdn_controller")
  @id(0x02000043)
  @oneshot()
  table wcmp_group_table {
    key = {
      wcmp_group_id_value : exact @id(1) @name("wcmp_group_id");
      local_metadata.wcmp_selector_input : selector;
    }
    actions = {
      @proto_id(1) set_nexthop_id;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    psa_implementation = wcmp_group_selector;
    size = 4096;
  }

  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_DROP.
  @id(0x01000006)
  action drop() {
    ingress_drop(ostd);
  }

  // Sets SAI_ROUTE_ENTRY_ATTR_PACKET_ACTION to SAI_PACKET_ACTION_FORWARD, and
  // SAI_ROUTE_ENTRY_ATTR_NEXT_HOP_ID to a SAI_OBJECT_TYPE_NEXT_HOP_GROUP.
  //
  // This action can only refer to `wcmp_group_id`s that are programmed in the
  // `wcmp_group_table`.
  @id(0x01000004)
  action set_wcmp_group_id(@id(1) @refers_to(wcmp_group_table, wcmp_group_id)
                           wcmp_group_id_t wcmp_group_id) {
    wcmp_group_id_valid = true;
    wcmp_group_id_value = wcmp_group_id;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000044)
  table ipv4_table {
    key = {
      // Sets vr_id in sai_route_entry_t.
      local_metadata.vrf_id : exact @id(1) @name("vrf_id");
      // Sets destination in sai_route_entry_t to an IPv4 prefix.
      headers.ipv4.dst_addr : lpm @format(IPV4_ADDRESS) @id(2)
                                  @name("ipv4_dst");
    }
    actions = {
      @proto_id(1) drop;
      @proto_id(2) set_nexthop_id;
      @proto_id(3) set_wcmp_group_id;
    }
    const default_action = drop;
    size = 512;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000045)
  table ipv6_table {
    key = {
      // Sets vr_id in sai_route_entry_t.
      local_metadata.vrf_id : exact @id(1) @name("vrf_id");
      // Sets destination in sai_route_entry_t to an IPv6 prefix.
      headers.ipv6.dst_addr : lpm @format(IPV6_ADDRESS) @id(2)
                                  @name("ipv6_dst");
    }
    actions = {
      @proto_id(1) drop;
      @proto_id(2) set_nexthop_id;
      @proto_id(3) set_wcmp_group_id;
    }
    const default_action = drop;
    size = 512;
  }

  apply {
    // Drop packets by default, then override in the router_interface_table.
    // TODO: This should just be the default behavior of v1model:
    // https://github.com/p4lang/behavioral-model/issues/992
    ingress_drop(ostd);

    if (local_metadata.admit_to_l3) {

      if (headers.ipv4.isValid()) {
        ipv4_table.apply();
      } else if (headers.ipv6.isValid()) {
        ipv6_table.apply();
      }

      // The lpm tables may not set a valid `wcmp_group_id`, e.g. they may drop.
      if (wcmp_group_id_valid) {
        wcmp_group_table.apply();
      }

      // The lpm tables may not set a valid `nexthop_id`, e.g. they may drop.
      // The `wcmp_group_table` should always set a valid `nexthop_id`.
      if (nexthop_id_valid) {
        nexthop_table.apply();

        // The `nexthop_table` should always set a valid
        // `router_interface_id` and `neighbor_id`.
        if (router_interface_id_valid && neighbor_id_valid) {
          router_interface_table.apply();
          neighbor_table.apply();
        }
      }
    } else {
      local_metadata.packet_rewrites.dst_mac = headers.ethernet.dst_addr;
    }
  }
} // control routing
# 12 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/bridging.p4" 1
# 9 "sai_p4/instantiations/google/../../fixed/bridging.p4"
// This control block models the bridging pipeline
//
// +-------+  PID  +---------+  .1D   +---------+
// | port  |------>|  bridge |------->| bridge  |
// |       |       |  port   |        |         |
// +-------+       +---------+        +---------+
//      |                                   |
//      | PVID                              |
//      |            /------\              \|/
// +--------+       /  vrf   \    l3=no   +---------+
// |  vlan  |------/    +     \---------->|  FDB    |---> egress_port
// |        |      \   dmac   /           |         |
// +--------+       \        /            +---------+
//                   \------/                  /|//                       |                      |

//                l3=yes |              +-----------+
//                       |              |  routing  |
//                       +------------->|           |---> egress_port
//                                      +-----------+
//
// PID  - Port ID
// PVID - Port Vlan ID
// VID  - Vlan ID
// The pipeline expresess a DOT1D and DOT1Q datapath.
// For DOT1Q bridge
// 1. Untagged packet ingress on port
//    - if bridge port, get PVID from port, forwarded by DMAC
//    - if l3 port, get VRF from port and check for l3_admit
//    - if SVI, get VRF from vlan and check for l3_admit
// 2. Tagged packet, ingress on port
//    - if bridge port, get VID from packet, forwarded by DMAC
//    - if SVI, get VRF from packet and check for l3_admit
//
// Note:
// ingress_port is the phsyical port ID
// ibridge_port is the bridge port
// port_lag_id is the logical port ID. It is not used now but will be required once LAG support is added
// For a DOT1Q bridge, both bridge.id and vlan are treated same for all intents

control ingress_bridge(in headers_t headers,
                       inout local_metadata_t local_metadata,
                       in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {

  // SAI_PORT_ATTR_PORT_VLAN_ID
  // Set VRF, if this port is an L3 port
  @id(0x0100000D)
  action set_port_config(@id(1) @sai_attr_key(SAI_PORT_ATTR_PORT_VLAN_ID, 1)
                                bit<12> port_vlan_id,
                         @id(2) @sai_attr_key(SAI_PORT_ATTR_INGRESS_SAMPLEPACKET_ENABLE)
                                @sai_object_ref(SAI_OBJECT_TYPE_SAMPLEPACKET)
                                @refers_to(samplepacket_table, samplepacket_id)
                                samplepacket_id_t samplepacket_id,
                         @id(3) bit<16> bridge_port_id) {
    local_metadata.port.port_vlan_id = port_vlan_id;
    local_metadata.samplepacket_id = samplepacket_id;
    local_metadata.ibridge_port = bridge_port_id;
  }

  @id(0x0200004A)
  table port_table {
    key = {
      local_metadata.ingress_port : exact @name("port") @id(1);
    }
    actions = {
      @proto_id(1) set_port_config;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }




  action set_sub_port_details(@id(1) bit<16> bridge_port_id) {
    local_metadata.ibridge_port = bridge_port_id;
  }

  // Match on SAI_BRIDGE_PORT_ATTR_PORT_ID and SAI_BRIDGE_PORT_ATTR_VLAN_ID
  // match port_id and vlan_id when SAI_BRIDGE_PORT_TYPE_SUB_PORT
  // This table is only a placeholder for now. It helps understands how the
  // bridge metadata fields will eventually be used for 1D sub port
  table vport_table {
    key = {
      local_metadata.ingress_port : exact @name("port") @id(1);
      local_metadata.ingress_vlan : ternary @name("vlan_id") @id(2);
    }
    actions = {
      @proto_id(1) set_sub_port_details;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  // Sets SAI_BRIDGE_PORT_ATTR_FDB_LEARNING_MODE for learn
  // Sets SAI_BRIDGE_ATTR_TYPE to SAI_BRIDGE_TYPE_1Q
  // This is a little unconventional. The port/vport table tells the pipeline if the port is an L2 interface. Bridge port object creation requires the underlying port object. The port param is hence is just a placeholder to pass information down
  @id(0x0100000E)
  @sai_attr_action_key_value(SAI_BRIDGE_PORT_ATTR_TYPE SAI_BRIDGE_PORT_TYPE_PORT)
  action set_1q_bridge_port(@id(1) @sai_attr_key(SAI_BRIDGE_PORT_ATTR_PORT_ID, 1) @sai_object_ref(SAI_OBJECT_TYPE_PORT, 1) port_id_t port,
                            @id(2) @sai_attr_key(SAI_BRIDGE_PORT_ATTR_FDB_LEARNING_MODE, 2) bit<3> learn,
                            @id(3) @sai_attr_key(SAI_BRIDGE_PORT_ATTR_ADMIN_STATE, 3) bit<1> admin_state) {
    local_metadata.bridge.id = local_metadata.ingress_vlan;
    local_metadata.bridge.type = 0;
  }

  @id(0x0200004B)
  @proto_package("sai")
  table bridge_port_table {
    key = {
      local_metadata.ibridge_port : exact @name("bridge_port_id") @id(1);
    }
    actions = {
      @proto_id(1) set_1q_bridge_port;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  // This table is only a placeholder for now. It helps understands how the
  // bridge metadata fields will eventually be used
  action set_bridge_details(@id(1) bit<16> mgid) {
    local_metadata.mgid = mgid;
  }
  table bridge_table {
    key = {
      local_metadata.bridge.id: exact @name("bridge_id") @id(1);
      local_metadata.bridge.type: exact @name("bridge_type") @id(2);
    }
    actions = {
      @proto_id(1) set_bridge_details;
    }
  }

  // membership check

  Hash<bit<32>>(PSA_HashAlgorithm_t.IDENTITY) hash;
  const bit<32> vlan_membership_size = 1 << 21;
  Register<bit<1>, bit<32>>(vlan_membership_size, 0) vlan_membership;

  // Sets flood group for this vlan
  // SAI_VLAN_ATTR_LEARN_DISABLE
  @id(0x01000010)
  action set_vlan_config(@id(1) bit<16> mgid,
                         @id(2) @sai_attr_key(SAI_VLAN_ATTR_LEARN_DISABLE, 1) bit<1> learn_disable) {
    local_metadata.mgid = mgid;
    local_metadata.vlan.learn = learn_disable;
    // membership check
    bit<32> v_hash = hash.get_hash({(bit<9>)local_metadata.ingress_port, headers.vlan.vid});
    local_metadata.vlan.member = vlan_membership.read(v_hash);
  }

  @id(0x0200004C)
  @proto_package("sai")
  table vlan_table {
    key = {
      local_metadata.ingress_vlan : exact @name("vlan_id") @id(1) @sai_attr_key(SAI_VLAN_ATTR_VLAN_ID, 1);
    }
    actions = {
      @proto_id(1) set_vlan_config;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  action learn() {
    local_metadata.smac_learn.bridge_port = local_metadata.ibridge_port;
    local_metadata.smac_learn.bridge_id = local_metadata.bridge.id;
    local_metadata.smac_learn.bridge_type = local_metadata.bridge.type;
    local_metadata.smac_learn.mac = headers.ethernet.src_addr;
    local_metadata.smac_learn_enable = 1w1;;
  }

  action set_mac_learn(bit<16> bridge_port_id) {
    // alu to check for move
    // (port xor local_metadata.iport != 0) learn()
    learn();
    local_metadata.learn_port = bridge_port_id ^ local_metadata.ibridge_port;
  }

  // Bridge ID. for .1D and Vlan ID for .1Q
  table smac {
    key = {
      local_metadata.bridge.type : exact @name("bridge_type") @id(1);
      local_metadata.bridge.id : exact @name("bridge_id") @id(2);
      headers.ethernet.src_addr: exact @format(MAC_ADDRESS) @id(3)
                                       @name("mac_address");
    }
    actions = {
      @proto_id(1) set_mac_learn;
      @defaultonly learn;
    }
  }

  action set_bridge_port(bit<16> bridge_port_id) {
    local_metadata.obridge_port = bridge_port_id;
  }

  apply {
    port_table.apply();
    if (headers.vlan.isValid()) {
      local_metadata.ingress_vlan = headers.vlan.vid;
    } else {
      local_metadata.ingress_vlan = local_metadata.port.port_vlan_id;
    }
    bridge_port_table.apply();
    vlan_table.apply();
    if(local_metadata.vlan.learn == 1w1) {
      smac.apply();
      if(local_metadata.learn_port == 0) {
        local_metadata.smac_learn_enable = 1w0;
      }
    }
  }

} // control ingress_bridge

control vlan_encap(inout headers_t headers,
                   inout local_metadata_t local_metadata,
                   in psa_egress_input_metadata_t standard_metadata, inout psa_egress_output_metadata_t ostd) {
  // Add a vlan tag when SAI_VLAN_MEMBER_ATTR_TAGGING_MODE is
  // SAI_VLAN_MEMBER_ATTR_TAGGING_MODE_TAGGED
  @id(0x01000011)
  @sai_attr_action_key_value(SAI_VLAN_MEMBER_ATTR_VLAN_TAGGING_MODE SAI_VLAN_TAGGING_MODE_TAGGED)
  action set_tagged(@id(1) bit<12> vlan_id) {
    headers.vlan.setValid();
    headers.vlan.vid = vlan_id;
    headers.vlan.ether_type = headers.ethernet.ether_type;
    headers.ethernet.ether_type = 0x8100;
  }

  @id(0x01000012)
  @sai_attr_action_key_value(SAI_VLAN_MEMBER_ATTR_VLAN_TAGGING_MODE SAI_VLAN_TAGGING_MODE_UNTAGGED)
  action set_untagged() {
    headers.vlan.setInvalid();
  }

  @id(0x0200004D)
  @proto_package("sai")
  table vlan_member_table {
    key = {
      local_metadata.bridge.id : exact @name("vlan_id") @id(1)
                                       @sai_attr_key(SAI_VLAN_MEMBER_ATTR_VLAN_ID ,1)
                                       @sai_object_ref(SAI_OBJECT_TYPE_VLAN, 1)
                                       @refers_to(vlan_table, vlan_id);
      local_metadata.obridge_port : exact @name("bridge_port_id") @id(2)
                                          @sai_attr_key(SAI_VLAN_MEMBER_ATTR_BRIDGE_PORT_ID, 2)
                                          @sai_object_ref(SAI_OBJECT_TYPE_BRIDGE_PORT, 2)
                                          @refers_to(bridge_port_table, bridge_port_id);
    }
    actions = {
      @proto_id(1) set_tagged;
      @proto_id(2) set_untagged;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  apply {
    // strip the vlan header by default if already tagged
    // add it again based on egress vlan membership properties
    // this keeps the vlan_member table actions simple
    if (headers.vlan.isValid()) {
      headers.vlan.setInvalid();
      headers.ethernet.ether_type = headers.vlan.ether_type;
    }
    vlan_member_table.apply();
  }

} // control vlan_encap

control fdb(in headers_t headers,
            inout local_metadata_t local_metadata,
            in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {

  @sai_attr_action_key_value(SAI_FDB_ENTRY_PACKET_ACTION SAI_PACKET_ACTION_FORWARD)
  action set_bridge_port(@id(1)
                         @sai_attr_key(SAI_FDB_ENTRY_ATTR_BRIDGE_PORT_ID, 1)
                         @sai_object_ref(SAI_OBJECT_TYPE_BRIDGE_PORT, 2)
                         bit<16> bridge_port_id) {
    local_metadata.obridge_port = bridge_port_id;
  }

  @sai_attr_action_key_value(SAI_FDB_ENTRY_PACKET_ACTION SAI_PACKET_ACTION_TRAP)
  action trap() {
    // TODO
  }

  @sai_attr_action_key_value(SAI_FDB_ENTRY_PACKET_ACTION SAI_PACKET_ACTION_DROP)
  action drop() {
    ingress_drop(ostd);
  }

  action set_flood() {
  multicast(ostd,
             (MulticastGroup_t) (MulticastGroupUint_t) local_metadata.mgid);
  }

  // Bridge ID. for .1D and Vlan ID for .1Q
  // This is the egress bridge ID for IP over vlan packets
  // This is the ingress bridge ID for bridged packets
  @proto_package("sai")
  table fdb_entry_table {
    key = {
      // Sets bv_id in sai_fdb_entry_t
      local_metadata.bridge.id : exact @name("bv_id") @id(1)
                                       @sai_attr_key(SAI_VLAN_MEMBER_ATTR_VLAN_ID ,1)
                                       @sai_object_ref(SAI_OBJECT_TYPE_VLAN, 1)
                                       @refers_to(vlan_table, vlan_id);
      // Sets mac_address in sai_fdb_entry_t
      local_metadata.packet_rewrites.dst_mac: exact @format(MAC_ADDRESS) @id(2)
                                                    @name("mac_address");
    }
    actions = {
      @proto_id(1) set_bridge_port;
      @proto_id(2) trap;
      @proto_id(3) drop;
      @defaultonly set_flood;
    }
    const default_action = set_flood;
  }

  // This eventually needs another indirection when LAG comes into play
  action set_out_port(@id(1) port_id_t port_id) {
    ostd.egress_port = (PortId_t)(PortIdUint_t)port_id;
  }

  table egress_bridge_port_table {
    key = {
      local_metadata.obridge_port : exact @name("bridge_port_id") @id(1);
    }
    actions = {
      @proto_id(1) set_out_port;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  apply {
    if (ostd.egress_port == (PortId_t)0) {
      fdb_entry_table.apply();
    }
    egress_bridge_port_table.apply();
  }

} // control fdb
# 13 "sai_p4/instantiations/google/sai.p4" 2



# 1 "sai_p4/instantiations/google/../../fixed/mirroring_encap.p4" 1
# 10 "sai_p4/instantiations/google/../../fixed/mirroring_encap.p4"
control mirroring_encap(inout headers_t headers,
                        inout local_metadata_t local_metadata,
                        in psa_egress_input_metadata_t standard_metadata, inout psa_egress_output_metadata_t ostd) {
  apply {

    if (standard_metadata.packet_path == PSA_PacketPath_t.CLONE_I2E) {




      // Reference for ERSPAN Type II header construction
      // https://tools.ietf.org/html/draft-foschiano-erspan-00
      headers.erspan_ethernet.setValid();
      headers.erspan_ethernet.src_addr = local_metadata.mirroring_src_mac;
      headers.erspan_ethernet.dst_addr = local_metadata.mirroring_dst_mac;
      headers.erspan_ethernet.ether_type = 0x0800;

      headers.erspan_ipv4.setValid();
      headers.erspan_ipv4.src_addr = local_metadata.mirroring_src_ip;
      headers.erspan_ipv4.dst_addr = local_metadata.mirroring_dst_ip;
      headers.erspan_ipv4.version = 4w4;
      headers.erspan_ipv4.ihl = 4w5;
      headers.erspan_ipv4.protocol = 0x2f;
      headers.erspan_ipv4.ttl = local_metadata.mirroring_ttl;
      headers.erspan_ipv4.dscp = local_metadata.mirroring_tos[7:2];
      headers.erspan_ipv4.ecn = local_metadata.mirroring_tos[1:0];





      headers.erspan_ipv4.identification = 0;
      headers.erspan_ipv4.reserved = 0;
      headers.erspan_ipv4.do_not_fragment = 1;
      headers.erspan_ipv4.more_fragments = 0;
      headers.erspan_ipv4.frag_offset = 0;
      headers.erspan_ipv4.header_checksum = 0;

      headers.erspan_gre.setValid();
      headers.erspan_gre.checksum_present = 0;
      headers.erspan_gre.routing_present = 0;
      headers.erspan_gre.key_present = 0;
      headers.erspan_gre.sequence_present = 0;
      headers.erspan_gre.strict_source_route = 0;
      headers.erspan_gre.recursion_control = 0;
      headers.erspan_gre.acknowledgement_present = 0;
      headers.erspan_gre.flags = 0;
      headers.erspan_gre.version = 0;
      headers.erspan_gre.protocol = 0x88be;
    }
  }
} // control mirroring_encap
# 17 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/mirroring_clone.p4" 1
# 11 "sai_p4/instantiations/google/../../fixed/mirroring_clone.p4"
control mirroring_clone(inout headers_t headers,
                        inout local_metadata_t local_metadata,
                        in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  port_id_t mirror_port;
  CloneSessionId_t pre_session;

  // Sets
  // SAI_MIRROR_SESSION_ATTR_TYPE to ENHANCED_REMOTE,
  // SAI_MIRROR_SESSION_ATTR_ERSPAN_ENCAPSULATION_TYPE to L3_GRE_TUNNEL,
  // SAI_MIRROR_SESSION_ATTR_IPHDR_VERSION to 4,
  // SAI_MIRROR_SESSION_ATTR_GRE_PROTOCOL_TYPE to 0x88BE,
  // SAI_MIRROR_SESSION_ATTR_MONITOR_PORT,
  // SAI_MIRROR_SESSION_ATTR_SRC_IP_ADDRESS,
  // SAI_MIRROR_SESSION_ATTR_DST_IP_ADDRESS,
  // SAI_MIRROR_SESSION_ATTR_SRC_MAC_ADDRESS
  // SAI_MIRROR_SESSION_ATTR_DST_MAC_ADDRESS
  // SAI_MIRROR_SESSION_ATTR_TTL
  // SAI_MIRROR_SESSION_ATTR_TOS
  @id(0x01000007)
  action mirror_as_ipv4_erspan(
      @id(1) port_id_t port,
      @id(2) @format(IPV4_ADDRESS) ipv4_addr_t src_ip,
      @id(3) @format(IPV4_ADDRESS) ipv4_addr_t dst_ip,
      @id(4) @format(MAC_ADDRESS) ethernet_addr_t src_mac,
      @id(5) @format(MAC_ADDRESS) ethernet_addr_t dst_mac,
      @id(6) bit<8> ttl,
      @id(7) bit<8> tos) {
    mirror_port = port;
    local_metadata.mirroring_src_ip = src_ip;
    local_metadata.mirroring_dst_ip = dst_ip;
    local_metadata.mirroring_src_mac = src_mac;
    local_metadata.mirroring_dst_mac = dst_mac;
    local_metadata.mirroring_ttl = ttl;
    local_metadata.mirroring_tos = tos;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000046)
  table mirror_session_table {
    key = {
      local_metadata.mirror_session_id_value : exact @id(1)
                                                     @name("mirror_session_id");
    }
    actions = {
      @proto_id(1) mirror_as_ipv4_erspan;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 2;
  }

  @id(0x01000009)
  action set_pre_session(CloneSessionId_t id) {
    pre_session = id;
  }

  @p4runtime_role("packet_replication_engine_manager")
  @id(0x02000048)
  table mirror_port_to_pre_session_table {
    key = {
      mirror_port : exact @id(1);
    }
    actions = {
      @proto_id(1) set_pre_session;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  apply {
    if (local_metadata.mirror_session_id_valid) {
      // Map mirror session id to mirroring data.
      if (mirror_session_table.apply().hit) {
        // Map mirror port to Packet Replication Engine session.
        if (mirror_port_to_pre_session_table.apply().hit) {
          ostd.clone_session_id = (CloneSessionId_t)pre_session; ostd.clone = true;







        }
      }
    }
  }
} // control mirroring_clone
# 18 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/l3_admit.p4" 1
# 12 "sai_p4/instantiations/google/../../fixed/l3_admit.p4"
control l3_admit(in headers_t headers,
                 inout local_metadata_t local_metadata,
                 in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  @id(0x01000008)
  action admit_to_l3() {
    local_metadata.admit_to_l3 = true;
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000047)
  table l3_admit_table {
    key = {
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(1)
                                          @format(MAC_ADDRESS);
      local_metadata.ingress_port : ternary @name("in_port") @id(2);
      local_metadata.ingress_vlan : ternary @name("vlan_id") @id(3);
    }
    actions = {
      @proto_id(1) admit_to_l3;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 512;
  }

  apply {
    l3_admit_table.apply();
  }
} // control l3_admit
# 19 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/ttl.p4" 1







control ttl(inout headers_t headers,
                  inout local_metadata_t local_metadata,
                  in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  apply {
    if (local_metadata.admit_to_l3) {
      if (headers.ipv4.isValid()) {
        if (headers.ipv4.ttl <= 1) {
          ingress_drop(ostd);
        } else {
          headers.ipv4.ttl = headers.ipv4.ttl - 1;
        }
      }

      if (headers.ipv6.isValid()) {
        if (headers.ipv6.hop_limit <= 1) {
          ingress_drop(ostd);
        } else {
          headers.ipv6.hop_limit = headers.ipv6.hop_limit - 1;
        }
      }
    }
  }
} // control ttl
# 20 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/../../fixed/packet_rewrites.p4" 1
# 9 "sai_p4/instantiations/google/../../fixed/packet_rewrites.p4"
// This control block applies the rewrites computed during the the ingress
// stage to the actual packet.
control packet_rewrites(inout headers_t headers,
                        in local_metadata_t local_metadata) {
  apply {
    if (local_metadata.admit_to_l3) {
      headers.ethernet.src_addr = local_metadata.packet_rewrites.src_mac;
      headers.ethernet.dst_addr = local_metadata.packet_rewrites.dst_mac;
    }
    if (local_metadata.tunnel.id != (tunnel_id_t)0) {
      headers.ipv4.src_addr = local_metadata.outer_ip_src_addr;
      headers.ipv4.dst_addr = local_metadata.outer_ip_dst_addr;
    }
  }
} // control packet_rewrites
# 21 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/acl_ingress.p4" 1






# 1 "sai_p4/instantiations/google/ids.h" 1



# 1 "sai_p4/instantiations/google/../../fixed/ids.h" 1
# 5 "sai_p4/instantiations/google/ids.h" 2

// All declarations (tables, actions, action profiles, meters, counters) have a
// stable ID. This list will evolve as new declarations are added. IDs cannot be
// reused. If a declaration is removed, its ID macro is kept and marked reserved
// to avoid the ID being reused.
//
// The IDs are classified using the 8 most significant bits to be compatible
// with "6.3. ID Allocation for P4Info Objects" in the P4Runtime specification.

// --- Tables ------------------------------------------------------------------

// IDs of ACL tables (8 most significant bits = 0x02).
// Since these IDs are user defined, they need to be separate from the fixed SAI
// table ID space. We achieve this by starting the IDs at 0x100.





// --- Actions -----------------------------------------------------------------

// IDs of ACL actions (8 most significant bits = 0x01).
// Since these IDs are user defined, they need to be separate from the fixed SAI
// actions ID space. We achieve this by starting the IDs at 0x100.
# 39 "sai_p4/instantiations/google/ids.h"
// --- Meters ------------------------------------------------------------------



// --- Counters ----------------------------------------------------------------
# 8 "sai_p4/instantiations/google/acl_ingress.p4" 2



control acl_ingress(in headers_t headers,
                    inout local_metadata_t local_metadata,
                    in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  // IPv4 TTL or IPv6 hoplimit bits (or 0, for non-IP packets)
  bit<8> ttl = 0;
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;
  // Last 2 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<2> ecn = 0;
  // IPv4 IP protocol or IPv6 next_header (or 0, for non-IP packets)
  bit<8> ip_protocol = 0;

  @id(0x15000100)
  DirectMeter(PSA_MeterType_t.BYTES) acl_ingress_meter;

  @id(0x13000102)
  DirectCounter<bit<32>>(PSA_CounterType_t.PACKETS_AND_BYTES) acl_ingress_counter;

  // Copy the packet to the CPU, and forward the original packet.
  @id(0x01000101)
  @sai_action(SAI_PACKET_ACTION_COPY)
  action copy(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    ostd.clone_session_id = (CloneSessionId_t)1024; ostd.clone = true;
    acl_ingress_counter.count();
  }

  // Copy the packet to the CPU. The original packet is dropped.
  @id(0x01000102)
  @sai_action(SAI_PACKET_ACTION_TRAP)
  action trap(@sai_action_param(QOS_QUEUE) @id(1) qos_queue_t qos_queue) {
    copy(qos_queue);
    ingress_drop(ostd);
  }

  // Forward the packet normally (i.e., perform no action). This is useful as
  // the default action, and to specify a meter but not otherwise perform any
  // action.
  @id(0x01000103)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action forward() {
    // METER_EXEC(local_metadata.color, acl_ingress_meter);
    acl_ingress_counter.count();
  }

  @id(0x01000104)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action mirror(@sai_action_param(SAI_ACL_ENTRY_ATTR_ACTION_MIRROR_INGRESS)
                @id(1) @refers_to(mirror_session_table, mirror_session_id)
                mirror_session_id_t mirror_session_id) {
    local_metadata.mirror_session_id_valid = true;
    local_metadata.mirror_session_id_value = mirror_session_id;
    acl_ingress_counter.count();
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000100)
  @sai_acl(INGRESS)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dst_ip::mask != 0 -> is_ipv4 == 1;
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    ttl::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ecn::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    ip_protocol::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    // Forbit using ether_type for IP packets (by convention, use is_ip* instead).
    ether_type != 0x0800 && ether_type != 0x86dd;
    // Only allow arp_tpa for ARP packets
    arp_tpa::mask != 0 -> ether_type == 0x0806;
    // Only allow icmp_type for ICMP packets
    icmpv6_type::mask != 0 -> ((is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1) && ip_protocol == 58);
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_ingress_table {
    key = {




      headers.ipv4.isValid() : ternary @name("is_ipv4") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : ternary @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      headers.ethernet.ether_type : ternary @name("ether_type") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ETHER_TYPE);
      headers.ethernet.dst_addr : ternary @name("dst_mac") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_MAC) @format(MAC_ADDRESS);
      headers.ipv4.src_addr : ternary @name("src_ip") @id(6)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IP) @format(IPV4_ADDRESS);
      headers.ipv4.dst_addr : ternary @name("dst_ip") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.src_addr : ternary @name("src_ipv6") @id(8)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_IPV6) @format(IPV6_ADDRESS);
      headers.ipv6.dst_addr : ternary @name("dst_ipv6") @id(9)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6) @format(IPV6_ADDRESS);
      // Field for v4 TTL and v6 hop_limit
      ttl : ternary @name("ttl") @id(10)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_TTL);
      // Field for v4 and v6 DSCP bits.
      dscp : ternary @name("dscp") @id(11)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      // Field for v4 and v6 ECN bits.
      ecn : ternary @name("ecn") @id(12)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ECN);
      // Field for v4 IP protocol and v6 next header.
      ip_protocol : ternary @name("ip_protocol") @id(13)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IP_PROTOCOL);
      headers.icmp.type : ternary @name("icmpv6_type") @id(14)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ICMPV6_TYPE);
      local_metadata.l4_dst_port : ternary @name("l4_dst_port") @id(15)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_L4_DST_PORT);
      headers.arp.target_proto_addr : ternary @name("arp_tpa") @id(16)
          @composite_field(
              @sai_udf(base=SAI_UDF_BASE_L3, offset=24, length=2),
              @sai_udf(base=SAI_UDF_BASE_L3, offset=26, length=2)
          ) @format(IPV4_ADDRESS);
    }
    actions = {
      // TODO: add action to set color to yellow
      @proto_id(1) copy();
      @proto_id(2) trap();
      @proto_id(3) forward();
      @proto_id(4) mirror();
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    // DIRECT_METER_DECLARATION(acl_ingress_meter);
    psa_direct_counter = acl_ingress_counter;
    size = 128;
  }

  apply {
    if (headers.ipv4.isValid()) {
      ttl = headers.ipv4.ttl;
      dscp = headers.ipv4.dscp;
      ecn = headers.ipv4.ecn;
      ip_protocol = headers.ipv4.protocol;
    } else if (headers.ipv6.isValid()) {
      ttl = headers.ipv6.hop_limit;
      dscp = headers.ipv6.dscp;
      ecn = headers.ipv6.ecn;
      ip_protocol = headers.ipv6.next_header;
    }

    acl_ingress_table.apply();
  }
} // control ACL_INGRESS
# 22 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/acl_lookup.p4" 1
# 11 "sai_p4/instantiations/google/acl_lookup.p4"
control acl_lookup(in headers_t headers,
                   inout local_metadata_t local_metadata,
                    in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  // First 6 bits of IPv4 TOS or IPv6 traffic class (or 0, for non-IP packets)
  bit<6> dscp = 0;

  @id(0x13000101)
  DirectCounter<bit<32>>(PSA_CounterType_t.PACKETS_AND_BYTES) acl_lookup_counter;

  @id(0x01000100)
  @sai_action(SAI_PACKET_ACTION_FORWARD)
  action set_vrf(@sai_action_param(SAI_ACL_ENTRY_ATTR_EXTENSIONS_ACTION_SET_VRF)
                 @id(1) vrf_id_t vrf_id) {
    local_metadata.vrf_id = vrf_id;
    acl_lookup_counter.count();
  }

  @p4runtime_role("sdn_controller")
  @id(0x02000101)
  @sai_acl(LOOKUP)
  @entry_restriction("
    // Only allow IP field matches for IP packets.
    dscp::mask != 0 -> (is_ip == 1 || is_ipv4 == 1 || is_ipv6 == 1);
    dst_ip::mask != 0 -> is_ipv4 == 1;
    dst_ipv6::mask != 0 -> is_ipv6 == 1;
    // Forbid illegal combinations of IP_TYPE fields.
    is_ip::mask != 0 -> (is_ipv4::mask == 0 && is_ipv6::mask == 0);
    is_ipv4::mask != 0 -> (is_ip::mask == 0 && is_ipv6::mask == 0);
    is_ipv6::mask != 0 -> (is_ip::mask == 0 && is_ipv4::mask == 0);
    // Forbid unsupported combinations of IP_TYPE fields.
    is_ipv4::mask != 0 -> (is_ipv4 == 1);
    is_ipv6::mask != 0 -> (is_ipv6 == 1);
  ")
  table acl_lookup_table {
    key = {




      headers.ipv4.isValid() : ternary @name("is_ipv4") @id(2)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV4ANY);
      headers.ipv6.isValid() : ternary @name("is_ipv6") @id(3)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_ACL_IP_TYPE/IPV6ANY);
      headers.ethernet.src_addr : ternary @name("src_mac") @id(4)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_SRC_MAC) @format(MAC_ADDRESS);
      headers.ipv4.dst_addr : ternary @name("dst_ip") @id(5)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IP) @format(IPV4_ADDRESS);
      headers.ipv6.dst_addr : ternary @name("dst_ipv6") @id(6)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DST_IPV6) @format(IPV6_ADDRESS);
      dscp : ternary @name("dscp") @id(7)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_DSCP);
      local_metadata.ingress_port : ternary @name("in_port") @id(8)
          @sai_field(SAI_ACL_TABLE_ATTR_FIELD_IN_PORT);
    }
    actions = {
      @proto_id(1) set_vrf;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    psa_direct_counter = acl_lookup_counter;
    size = 256;
  }

  apply {
    if (headers.ipv4.isValid()) {
      dscp = headers.ipv4.dscp;
    } else if (headers.ipv6.isValid()) {
      dscp = headers.ipv6.dscp;
    }

    acl_lookup_table.apply();
  }
} // control acl_lookup
# 23 "sai_p4/instantiations/google/sai.p4" 2
# 1 "sai_p4/instantiations/google/hashing.p4" 1



# 1 "./sai_p4/fixed/arch.p4" 1
# 5 "sai_p4/instantiations/google/hashing.p4" 2



# 1 "sai_p4/instantiations/google/../../fixed/minimum_guaranteed_sizes.p4" 1
# 9 "sai_p4/instantiations/google/hashing.p4" 2




control hashing(in headers_t headers,
                inout local_metadata_t local_metadata) {
  bit<32> seed = 0;
  bit<4> offset = 0;

  Hash<bit<16>>(PSA_HashAlgorithm_t.CRC16) hash_v4;
  Hash<bit<16>>(PSA_HashAlgorithm_t.CRC16) hash_v6;


  // TODO: need to set these values differently for S2 and S3
  // S2 is SAI_HASH_ALGORITHM_CRC_CCITT with offset 4
  // S3 is SAI_HASH_ALGORITHM_CRC       with offset 8
  @sai_hash_algorithm(SAI_HASH_ALGORITHM_CRC_32LO)
  @sai_hash_seed(0)
  @sai_hash_offset(0)
  @id(0x010000A)
  action select_emcp_hash_algorithm() {
    // TODO:
    // this action should set a local `hash_algorithm` variable to the hash
    // algorithm, e.g. `HashAlgorithm.crc32`, which would then be used by
    // `compute_ecmp_hash_ipv4` and `compute_ecmp_hash_ipv6`. However, BMv2 does
    // not support variables of Enum types at this point. BMv2 generates this
    // error:
    //
    //     type not yet handled on this target
    //
    //     enum HashAlgorithm {
    //          ^^^^^^^^^^^^^
    seed = 0;
    offset = 0;
  }

  @sai_ecmp_hash(SAI_SWITCH_ATTR_ECMP_HASH_IPV4)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_SRC_IPV4)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_DST_IPV4)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_L4_SRC_PORT)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_L4_DST_PORT)
  @id(0x0100000B)
  action compute_ecmp_hash_ipv4() {
    local_metadata.wcmp_selector_input = (bit<16>)hash_v4.get_hash({seed, headers.ipv4.src_addr, headers.ipv4.dst_addr, local_metadata.l4_src_port, local_metadata.l4_dst_port});




     // Rotate the wcmp_selector_input by offset bits to the right.






  }

  @sai_ecmp_hash(SAI_SWITCH_ATTR_ECMP_HASH_IPV6)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_SRC_IPV6)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_DST_IPV6)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_L4_SRC_PORT)
  @sai_native_hash_field(SAI_NATIVE_HASH_FIELD_L4_DST_PORT)
  // TODO: add flow label once supported.
  @id(0x0100000C)
  action compute_ecmp_hash_ipv6() {
     local_metadata.wcmp_selector_input = (bit<16>)hash_v6.get_hash({seed, headers.ipv6.src_addr, headers.ipv6.dst_addr, headers.ipv6.flow_label[15:0], local_metadata.l4_src_port, local_metadata.l4_dst_port});





     // Rotate the wcmp_selector_input by offset bits to the right.






  }

  apply {
    select_emcp_hash_algorithm();
    if (headers.ipv4.isValid()) {
      compute_ecmp_hash_ipv4();
    } else if (headers.ipv6.isValid()) {
      compute_ecmp_hash_ipv6();
    }
  }
} // control hashing
# 24 "sai_p4/instantiations/google/sai.p4" 2
# 1 "./sai_p4/fixed/tunnel.p4" 1



# 1 "./sai_p4/fixed/arch.p4" 1
# 5 "./sai_p4/fixed/tunnel.p4" 2
# 1 "./sai_p4/fixed/headers.p4" 1
# 6 "./sai_p4/fixed/tunnel.p4" 2
# 1 "./sai_p4/fixed/metadata.p4" 1
# 7 "./sai_p4/fixed/tunnel.p4" 2
# 1 "./sai_p4/fixed/ids.h" 1
# 8 "./sai_p4/fixed/tunnel.p4" 2

control tunnel_resolution(in headers_t headers,
                          inout local_metadata_t local_metadata,
                          in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {

  // This table has to move after the nexthop tables and before the RIF table
  // It is basically a 2nd route table for the outer IP given by the inner
  // nexthop table
  table outer_route_table {
    key = {
      local_metadata.outer_ip_dst_addr : exact @name("port") @id(1);
    }
    actions = {
      @defaultonly NoAction;
    }
    const default_action = NoAction;
  }

  apply {
  }

} // control tunnel_resolution

control tunnel_decap(inout headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {

  action dst_vtep_hit(@id(1)tunnel_id_t tunnel_id) {
    local_metadata.tunnel.id = tunnel_id;
    local_metadata.tunnel.terminate = true;
  }

  table ipv4_tunnel_term_table {
    key = {
      headers.ipv4.src_addr : ternary @name("ipv4_src");
      headers.ipv4.dst_addr : ternary @name("ipv4_dst");
      local_metadata.vrf_id : exact;
      local_metadata.tunnel.type : exact;
    }

    actions = {
      @defaultonly NoAction;
      @proto_id(1) dst_vtep_hit;
    }

    const default_action = NoAction;
  }

  table ipv6_tunnel_term_table {
    key = {
      headers.ipv6.src_addr : ternary @name("ipv6_src");
      headers.ipv6.dst_addr : ternary @name("ipv6_dst");
      local_metadata.vrf_id : exact;
      local_metadata.tunnel.type : exact;
    }

    actions = {
      @defaultonly NoAction;
      @proto_id(1) dst_vtep_hit;
    }

    const default_action = NoAction;
  }

  action set_tunnel_map(@id(1) bit<8> tunnel_map_id) {
    local_metadata.tunnel.map_id = tunnel_map_id;
  }

  table ingress_tunnel_table {
    key = {
      local_metadata.tunnel.id : exact;
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_tunnel_map;
    }

    const default_action = NoAction;
  }

  action set_tunnel_map_entry(@id(1) bit<8> tunnel_map_type) {
    local_metadata.tunnel.map_type = tunnel_map_type;
  }
  table decap_tunnel_map {
    key = {
      local_metadata.tunnel.map_id : exact;
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_tunnel_map_entry;
    }

    const default_action = NoAction;
  }

  action set_ingress_vrf(@id(1) vrf_id_t vrf_id) {
    local_metadata.vrf_id = vrf_id;
  }

  table decap_tunnel_map_entry {
    key = {
      local_metadata.tunnel.map_id : exact;
      local_metadata.tunnel.map_type : exact;
      headers.vxlan.vni : exact;
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_ingress_vrf;
    }

    const default_action = NoAction;
  }

  action decap_inner_udp() {
    headers.udp = headers.inner_udp;
    headers.inner_udp.setInvalid();
  }

  action copy_ipv4_header() {
    headers.ipv4.setValid();
    headers.ipv4.version = headers.inner_ipv4.version;
    headers.ipv4.ihl = headers.inner_ipv4.ihl;
    headers.ipv4.dscp = headers.inner_ipv4.dscp;
    headers.ipv4.ecn = headers.inner_ipv4.ecn;
    headers.ipv4.total_len = headers.inner_ipv4.total_len;
    headers.ipv4.identification = headers.inner_ipv4.identification;
    headers.ipv4.reserved = headers.inner_ipv4.reserved;
    headers.ipv4.do_not_fragment = headers.inner_ipv4.do_not_fragment;
    headers.ipv4.more_fragments = headers.inner_ipv4.more_fragments;
    headers.ipv4.frag_offset = headers.inner_ipv4.frag_offset;
    headers.ipv4.ttl = headers.inner_ipv4.ttl;
    headers.ipv4.protocol = headers.inner_ipv4.protocol;
    // headers.ipv4.headers_checksum = headers.inner_ipv4.headers_checksum;
    headers.ipv4.src_addr = headers.inner_ipv4.src_addr;
    headers.ipv4.dst_addr = headers.inner_ipv4.dst_addr;

    headers.inner_ipv4.setInvalid();
  }

  action copy_ipv6_header() {
    headers.ipv6.setValid();
    headers.ipv6.version = headers.inner_ipv6.version;
    headers.ipv6.dscp = headers.inner_ipv6.dscp;
    headers.ipv6.ecn = headers.inner_ipv6.ecn;
    headers.ipv6.flow_label = headers.inner_ipv6.flow_label;
    headers.ipv6.payload_length = headers.inner_ipv6.payload_length;
    headers.ipv6.next_header = headers.inner_ipv6.next_header;
    headers.ipv6.hop_limit = headers.inner_ipv6.hop_limit;
    headers.ipv6.src_addr = headers.inner_ipv6.src_addr;
    headers.ipv6.dst_addr = headers.inner_ipv6.dst_addr;

    headers.inner_ipv6.setInvalid();
  }

  action invalidate_vxlan_header() {
    headers.vxlan.setInvalid();
  }

  action invalidate_vlan_tag0() {
    headers.vlan.setInvalid();
  }

  action decap_inner_ethernet_ipv4() {
    invalidate_vlan_tag0();
    decap_inner_udp();
    headers.ethernet = headers.inner_ethernet;
    copy_ipv4_header();
    headers.ipv6.setInvalid();
    headers.inner_ethernet.setInvalid();
    invalidate_vxlan_header();
  }

  action decap_inner_ethernet_ipv6() {
    invalidate_vlan_tag0();
    decap_inner_udp();
    headers.ethernet = headers.inner_ethernet;
    copy_ipv6_header();
    headers.ipv4.setInvalid();
    headers.inner_ethernet.setInvalid();
    invalidate_vxlan_header();
  }

  action decap_inner_ethernet_non_ip() {
    invalidate_vlan_tag0();
    decap_inner_udp();
    headers.ethernet = headers.inner_ethernet;
    headers.ipv4.setInvalid();
    headers.ipv6.setInvalid();
    headers.inner_ethernet.setInvalid();
    invalidate_vxlan_header();
  }

  action decap_inner_ipv4() {
    invalidate_vlan_tag0();
    headers.ethernet.ether_type = 0x0800;
    copy_ipv4_header();
    headers.ipv6.setInvalid();
  }

  action decap_inner_ipv6() {
    invalidate_vlan_tag0();
    headers.ethernet.ether_type = 0x86dd;
    copy_ipv6_header();
    headers.ipv4.setInvalid();
  }

  table decap_tunnel_headers {
    key = {
      headers.udp.isValid() : exact;
      headers.inner_ethernet.isValid() : exact;
      headers.inner_ipv4.isValid() : exact;
      headers.inner_ipv6.isValid() : exact;
    }

    actions = {
      @proto_id(1) decap_inner_ethernet_ipv4;
      @proto_id(2) decap_inner_ethernet_ipv6;
      @proto_id(3) decap_inner_ethernet_non_ip;
      @proto_id(4) decap_inner_ipv4;
      @proto_id(5) decap_inner_ipv6;
      @defaultonly NoAction;
    }

    const default_action = NoAction;

    const entries = {
      (true, true, true, false) : decap_inner_ethernet_ipv4;
      (true, true, false, true) : decap_inner_ethernet_ipv6;
      (true, true, false, false) : decap_inner_ethernet_non_ip;
      (false, false, true, false) : decap_inner_ipv4;
      (false, false, false, true) : decap_inner_ipv6;
    }
  }

  apply {
    if (headers.ipv4.isValid()) {
      ipv4_tunnel_term_table.apply();
    } else {
      ipv6_tunnel_term_table.apply();
    }
    ingress_tunnel_table.apply();
    decap_tunnel_map.apply();
    decap_tunnel_map_entry.apply();
    if (local_metadata.tunnel.terminate) {
      decap_tunnel_headers.apply();
    }
  }
} // control tunnel_decap

control tunnel_encap(inout headers_t headers,
                     inout local_metadata_t local_metadata,
                     in psa_egress_input_metadata_t standard_metadata, inout psa_egress_output_metadata_t ostd) {

  bit<16> payload_len;
  bit<8> ip_proto;

  //
  // ************ Copy outer to inner **************************
  //
  action copy_ipv4_header() {
    // Copy all of the IPv4 header fields.
    headers.inner_ipv4.setValid();
    headers.inner_ipv4.version = headers.ipv4.version;
    headers.inner_ipv4.ihl = headers.ipv4.ihl;
    headers.inner_ipv4.dscp = headers.ipv4.dscp;
    headers.inner_ipv4.ecn = headers.ipv4.ecn;
    headers.inner_ipv4.total_len = headers.ipv4.total_len;
    headers.inner_ipv4.identification = headers.ipv4.identification;
    headers.inner_ipv4.reserved = headers.ipv4.reserved;
    headers.inner_ipv4.do_not_fragment = headers.ipv4.do_not_fragment;
    headers.inner_ipv4.frag_offset = headers.ipv4.frag_offset;
    headers.inner_ipv4.ttl = headers.ipv4.ttl;
    headers.inner_ipv4.protocol = headers.ipv4.protocol;
    // headers.inner_ipv4.hdr_checksum = headers.ipv4.hdr_checksum;
    headers.inner_ipv4.src_addr = headers.ipv4.src_addr;
    headers.inner_ipv4.dst_addr = headers.ipv4.dst_addr;
    headers.ipv4.setInvalid();
    // local_metadata.inner_ipv4_checksum_update_en = true;
  }

  action copy_ipv6_header() {
    headers.inner_ipv6.version = headers.ipv6.version;
    headers.inner_ipv6.dscp = headers.ipv6.dscp;
    headers.inner_ipv6.ecn = headers.ipv6.ecn;
    headers.inner_ipv6.flow_label = headers.ipv6.flow_label;
    headers.inner_ipv6.payload_length = headers.ipv6.payload_length;
    headers.inner_ipv6.next_header = headers.ipv6.next_header;
    headers.inner_ipv6.hop_limit = headers.ipv6.hop_limit;
    headers.inner_ipv6.src_addr = headers.ipv6.src_addr;
    headers.inner_ipv6.dst_addr = headers.ipv6.dst_addr;
    headers.ipv6.setInvalid();
  }

    action rewrite_inner_ipv4_udp() {
    payload_len = headers.ipv4.total_len;
    copy_ipv4_header();
    headers.inner_udp = headers.udp;
    headers.udp.setInvalid();
    ip_proto = 0x04;
  }

/*
  action rewrite_inner_ipv4_tcp() {
    payload_len = headers.ipv4.total_len;
    copy_ipv4_header();
    headers.inner_tcp = headers.tcp;
    headers.tcp.setInvalid();
    ip_proto = IP_PROTOCOL_IPV4;
  }
*/
  action rewrite_inner_ipv4_unknown() {
    payload_len = headers.ipv4.total_len;
    copy_ipv4_header();
    ip_proto = 0x04;
  }

  action rewrite_inner_ipv6_udp() {
    payload_len = headers.ipv6.payload_length + 16w40;
    copy_ipv6_header();
    headers.inner_udp = headers.udp;
    headers.udp.setInvalid();
    headers.ipv6.setInvalid();
    ip_proto = 0x29;
  }

/*
  action rewrite_inner_ipv6_tcp() {
    payload_len = headers.ipv6.payload_len + 16w40;
    headers.inner_ipv6 = headers.ipv6;
    headers.inner_tcp = headers.tcp;
    headers.tcp.setInvalid();
    headers.ipv6.setInvalid();
    ip_proto = IP_PROTOCOL_IPV6;
  }
*/
  action rewrite_inner_ipv6_unknown() {
    payload_len = headers.ipv6.payload_length + 16w40;
    copy_ipv6_header();
    headers.ipv6.setInvalid();
    ip_proto = 0x29;
  }

  table tunnel_encap_0 {
    key = {
      headers.ipv4.isValid() : exact;
      headers.ipv6.isValid() : exact;
      headers.udp.isValid() : exact;
      // headers.tcp.isValid() : exact; uncomment and add tcp actions if tcp header is parsed in egress
    }

    actions = {
      @proto_id(1) rewrite_inner_ipv4_udp;
      @proto_id(2) rewrite_inner_ipv4_unknown;
      @proto_id(3) rewrite_inner_ipv6_udp;
      @proto_id(4) rewrite_inner_ipv6_unknown;
      @defaultonly NoAction;
    }

    const entries = {
      (true, false, false) : rewrite_inner_ipv4_unknown();
      (false, true, false) : rewrite_inner_ipv6_unknown();
      (true, false, true) : rewrite_inner_ipv4_udp();
      (false, true, true) : rewrite_inner_ipv6_udp();
    }
    // size = MIN_TABLE_SIZE;
  }

  //
  // ************ Add outer IP encapsulation **************************
  //
  action add_udp_header(bit<16> src_port, bit<16> dst_port) {
    headers.udp.setValid();
    headers.udp.src_port = src_port;
    headers.udp.dst_port = dst_port;
    headers.udp.checksum = 0;
    // hdr.udp.length = 0;
  }

  action add_vxlan_header(bit<24> vni) {
    headers.vxlan.setValid();
    headers.vxlan.flags = 8w0x08;
    // headers.vxlan.reserved = 0;
    headers.vxlan.vni = vni;
    // headers.vxlan.reserved2 = 0;
  }

  action add_gre_header(bit<16> proto) {
# 407 "./sai_p4/fixed/tunnel.p4"
  }

  action add_ipv4_header(bit<8> proto) {
    headers.ipv4.setValid();
    headers.ipv4.version = 4w4;
    headers.ipv4.ihl = 4w5;
    // headers.ipv4.total_len = 0;
    headers.ipv4.identification = 0;
    headers.ipv4.reserved = 0;
    headers.ipv4.do_not_fragment = 0;
    headers.ipv4.frag_offset = 0;
    headers.ipv4.protocol = proto;
    headers.ipv4.ecn = 0;
  }

  action add_ipv6_header(bit<8> proto) {
    headers.ipv6.setValid();
    headers.ipv6.version = 4w6;
    headers.ipv6.flow_label = 0;
    // headers.ipv6.payload_length = 0;
    headers.ipv6.next_header = proto;
    headers.ipv6.ecn = 0;
  }

  action rewrite_ipv4_vxlan(@id(2) bit<16> vxlan_port) {
    headers.inner_ethernet = headers.ethernet;
    add_ipv4_header(0x11);
    headers.ipv4.do_not_fragment = 1w1;
    // Total length = packet length + 50
    //   IPv4 (20) + UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    headers.ipv4.total_len = payload_len + 16w50;

    add_udp_header(local_metadata.tunnel.hash, vxlan_port);
    // UDP length = packet length + 30
    //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    headers.udp.hdr_length = payload_len + 16w30;

    add_vxlan_header((bit<24>)local_metadata.tunnel.vni);
    headers.ethernet.ether_type = 0x0800;
  }

  action rewrite_ipv6_vxlan(@id(1) bit<16> vxlan_port) {
    headers.inner_ethernet = headers.ethernet;
    add_ipv6_header(0x11);
    // Payload length = packet length + 50
    //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    headers.ipv6.payload_length = payload_len + 16w30;

    add_udp_header(local_metadata.tunnel.hash, vxlan_port);
    // UDP length = packet length + 30
    //   UDP (8) + VXLAN (8)+ Inner Ethernet (14)
    headers.udp.hdr_length = payload_len + 16w30;

    add_vxlan_header((bit<24>)local_metadata.tunnel.vni);
    headers.ethernet.ether_type = 0x86dd;
  }

  action rewrite_ipv4_ip() {
    add_ipv4_header(ip_proto);
    // Total length = packet length + 20
    //   IPv4 (20)
    headers.ipv4.total_len = payload_len + 16w20;
    headers.ethernet.ether_type = 0x0800;
  }

  action rewrite_ipv6_ip() {
    add_ipv6_header(ip_proto);
    // Payload length = packet length
    headers.ipv6.payload_length = payload_len;
    headers.ethernet.ether_type = 0x86dd;
  }

  table tunnel_encap_1 {
    key = {
      local_metadata.tunnel.type : exact;
    }

    actions = {
      @proto_id(1) rewrite_ipv4_vxlan;
      @proto_id(2) rewrite_ipv6_vxlan;
      @proto_id(3) rewrite_ipv4_ip;
      @proto_id(4) rewrite_ipv6_ip;
      @defaultonly NoAction;
    }

    const default_action = NoAction;
    // size = MIN_TABLE_SIZE;
  }

  // rewrite inner headers before adding outer header
  action set_inner_src_mac(@id(1) @format(MAC_ADDRESS)
                           ethernet_addr_t src_mac) {
    headers.ethernet.src_addr = src_mac;
    // find a better location for this rewrite
    headers.ethernet.dst_addr = local_metadata.inner_dst_mac;
  }

  table vrf_table {
    key = {
      local_metadata.vrf_id : exact;
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_inner_src_mac;
    }
  }

  router_interface_id_t underlay_rif_value;

  @id(0x01000014)
  @sai_attr_action_key_value(SAI_TUNNEL_ATTR_TYPE SAI_TUNNEL_TYPE_VXLAN)
  action set_tunnel_config(@id(1) @sai_attr_key(SAI_TUNNEL_ATTR_UNDERLAY_INTERFACE)
                                  @sai_object_ref(SAI_OBJECT_TYPE_ROUTER_INTERFACE)
                                  @refers_to(router_interface_table, router_interface_id)
                                  router_interface_id_t router_interface_id,
                           @id(2) @format(IPV4_ADDRESS)
                                  @sai_attr_key(SAI_TUNNEL_ATTR_ENCAP_SRC_IP)
                                  ipv4_addr_t src_addr,
                           @id(3) @sai_attr_key(SAI_TUNNEL_ATTR_ENCAP_MAPPERS)
                                  @sai_object_ref(SAI_OBJECT_TYPE_TUNNEL_MAP)
                                  @refers_to(tunnel_map_table, tunnel_map_id)
                                  bit<8> encap_tunnel_map_id,
                           @id(4) @sai_attr_key(SAI_TUNNEL_ATTR_DECAP_MAPPERS)
                                  @sai_object_ref(SAI_OBJECT_TYPE_TUNNEL_MAP)
                                  @refers_to(tunnel_map_table, tunnel_map_id)
                                  bit<8> decap_tunnel_map_id) {
    underlay_rif_value = router_interface_id;
    local_metadata.outer_ip_src_addr = src_addr;
    local_metadata.tunnel.type = 2;
    local_metadata.tunnel.map_id = encap_tunnel_map_id;
  }

  @id(0x0200004E)
  @proto_package("sai")
  table tunnel_table {
    key = {
      local_metadata.tunnel.id : exact @id(1) @name("tunnel_id");
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_tunnel_config;
    }

    const default_action = NoAction;
  }

  @id(0x01000015)
  @sai_attr_action_key_value(SAI_TUNNEL_MAP_ATTR_TYPE SAI_TUNNEL_MAP_TYPE_VIRTUAL_ROUTER_ID_TO_VNI)
  action set_tunnel_map_vrf_to_vni() {
    local_metadata.tunnel.map_type = 0x7;
  }

  @id(0x01000016)
  @sai_attr_action_key_value(SAI_TUNNEL_MAP_ATTR_TYPE SAI_TUNNEL_MAP_TYPE_VNI_TO_VIRTUAL_ROUTER_ID)
  action set_tunnel_map_vni_to_vrf() {
    local_metadata.tunnel.map_type = 0x6;
  }

  @id(0x0200004F)
  @proto_package("sai")
  table tunnel_map_table {
    key = {
      local_metadata.tunnel.map_id : exact @id(1) @name("tunnel_map_id");
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_tunnel_map_vrf_to_vni;
      @proto_id(2) set_tunnel_map_vni_to_vrf;
    }

    const default_action = NoAction;
  }

  // this action is not really useful here except for control plane config
  // the decap_tunnel_map_entry table ingress does the reverse mapping
  @id(0x01000017)
  @sai_attr_action_key_value(SAI_TUNNEL_MAP_ENTRY_ATTR_TUNNEL_MAP_TYPE SAI_TUNNEL_MAP_TYPE_VNI_TO_VIRTUAL_ROUTER_ID)
  action set_vrf(@id(1) @sai_attr_key(SAI_TUNNEL_MAP_ENTRY_ATTR_VIRTUAL_ROUTER_ID_VALUE)
                        vrf_id_t vrf_id) {
    // nop
  }

  @id(0x01000018)
  @sai_attr_action_key_value(SAI_TUNNEL_MAP_ENTRY_ATTR_TUNNEL_MAP_TYPE SAI_TUNNEL_MAP_TYPE_VIRTUAL_ROUTER_ID_TO_VNI)
  action set_vni(@id(1) @sai_attr_key(SAI_TUNNEL_MAP_ENTRY_ATTR_VNI_ID_VALUE)
                        vni_id_t vni_id) {
    local_metadata.tunnel.vni = vni_id;
  }

  @id(0x02000050)
  @proto_package("sai")
  table tunnel_map_entry_table {
    key = {
      local_metadata.tunnel.map_id : exact @name("tunnel_map_id") @id(1)
                                           @sai_attr_key(SAI_TUNNEL_MAP_ENTRY_ATTR_TUNNEL_MAP)
                                           @sai_object_ref(SAI_OBJECT_TYPE_TUNNEL_MAP)
                                           @refers_to(tunnel_map_table, tunnel_map_id);
      local_metadata.tunnel.map_type : exact @id(2) @name("tunnel_map_type");
      // optional
      local_metadata.vrf_id : ternary @name("vrf_id") @id(3)
                                      @sai_attr_key(SAI_TUNNEL_MAP_ENTRY_ATTR_VIRTUAL_ROUTER_ID_KEY);
      // optional
      local_metadata.tunnel.vni : ternary @name("vni_id") @id(4)
                                          @sai_attr_key(SAI_TUNNEL_MAP_ENTRY_ATTR_VNI_ID_KEY);
    }
    actions = {
      @defaultonly NoAction;
      @proto_id(1) set_vni;
      @proto_id(1) set_vrf;
    }

    const default_action = NoAction;
  }

  apply {
    vrf_table.apply();
    tunnel_table.apply();
    tunnel_map_table.apply();
    tunnel_map_entry_table.apply();
    tunnel_encap_0.apply();
    tunnel_encap_1.apply();
  }

} // control tunnel_encap
# 25 "sai_p4/instantiations/google/sai.p4" 2
# 1 "./sai_p4/fixed/samplepacket.p4" 1
# 9 "./sai_p4/fixed/samplepacket.p4"
# 1 "./sai_p4/fixed/roles.h" 1
# 10 "./sai_p4/fixed/samplepacket.p4" 2
# 1 "./sai_p4/fixed/minimum_guaranteed_sizes.p4" 1
# 11 "./sai_p4/fixed/samplepacket.p4" 2

control samplepacket(in headers_t headers,
                 inout local_metadata_t local_metadata,
                 in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {


  bit<32> rate_value;
  bit<32> current_value;
  const bit<32> samplepacket_size = 256;
  Register<bit<32>, bit<8>>(samplepacket_size) samplers;

  @id(0x01000019)
  @sai_attr_action_key_value(SAI_SAMPLEPACKET_ATTR_TYPE SAI_SAMPLEPACKET_TYPE_SLOW_PATH)
  action set_sampling_config(@id(1) @sai_attr_key(SAI_SAMPLEPACKET_ATTR_SAMPLE_RATE)
                                    bit<32> rate) {
    rate_value = rate;
  }

  @id(0x02000052)
  table samplepacket_table {
    key = {
      local_metadata.samplepacket_id : exact @name("samplepacket_id") @id(1);
    }
    actions = {
      @proto_id(1) set_sampling_config;
      @defaultonly NoAction;
    }
    const default_action = NoAction;
    size = 256;
  }

  apply {
    if (samplepacket_table.apply().hit) {
      @atomic {
      current_value = samplers.read((bit<8>)local_metadata.samplepacket_id);
      if (current_value == (bit<32>)0) {
        current_value = rate_value;
        // TODO set sample flag
      } else {
        current_value = current_value - 1;
      }
      // P4C bug
      // samplers.write((bit<8>)local_metadata.samplepacket_id, current_value);
      }
    }
  }
} // control samplepacket
# 26 "sai_p4/instantiations/google/sai.p4" 2
# 1 "./sai_p4/fixed/etrap.p4" 1
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




//-------------------------------------------------------------------------------------------------
// Heavy-Hitter or Elephant Detection
// Identify source or desitnation IP with traffic rate exceeding a programmable threshold
//-------------------------------------------------------------------------------------------------



control etrap(in headers_t headers,
                inout local_metadata_t local_metadata,
                in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {

    etrap_index_t etrap_index_value;
    PSA_MeterColor_t etrap_color_value;
    traffic_class_t etrap_tc_value;

    Meter<etrap_index_t>(2048, PSA_MeterType_t.BYTES) meter;

    @name(".set_meter_and_tc") action set_meter_and_tc(etrap_index_t index,
                                                       traffic_class_t tc) {
        etrap_index_value = index;
        etrap_tc_value = tc;
    }

    @proto_package("saip4ext")
    @name(".etrap_ipv4_flow") table ipv4_acl {
        key = {
            headers.ipv4.dst_addr : ternary @format(IPV4_ADDRESS) @name("src_addr");
            headers.ipv4.dst_addr : ternary @format(IPV4_ADDRESS) @name("dst_addr");
        }
        actions = {
            @proto_id(1) set_meter_and_tc;
        }
        size = 2048/2;
    }

    @name(".etrap_ipv6_flow") table ipv6_acl {
        key = {
            headers.ipv6.src_addr : ternary @format(IPV6_ADDRESS) @name("src_addr");
            headers.ipv6.dst_addr : ternary @format(IPV6_ADDRESS) @name("dst_addr");
        }
        actions = {
            @proto_id(1) set_meter_and_tc;
        }
        size = 2048/2;
    }

    @name(".meter_action") action meter_action(etrap_index_t index) {
        etrap_color_value = meter.execute(index);
    }

    @name(".etrap_meter_index") table meter_index {
        key = {
            etrap_index_value : exact @name("etrap_index");
        }
        actions = {
            @proto_id(1) meter_action;
        }
        size = 2048;
    }

    /*
    Register<bit<8>, bit<11>>(ETRAP_TABLE_SIZE, 0) etrap_state_reg;
    RegisterAction<bit<8>, bit<11>, bit<8>>(etrap_state_reg) etrap_state_red_action = {
        void apply(inout bit<8> val, out bit<8> rv) {
            rv = etrap_tc_value;
            val = 0x1;
        }
    };

    RegisterAction<bit<8>, bit<11>, bit<8>>(etrap_state_reg) etrap_state_green_action = {
        void apply(inout bit<8> val, out bit<8> rv) {
            bit<8> temp;
            if (val == 0x1) {
                temp = etrap_tc_value;
            } else {
                temp = local_metadata.tc;
            }
            rv = temp;
        }
    };
    */

    @name(".etrap_red_state") action etrap_red_state() {
        local_metadata.tc = 4; // etrap_state_red_action.execute(etrap_index_value);
    }

    @name(".etrap_green_state") action etrap_green_state() {
        local_metadata.tc = 8; //etrap_state_green_action.execute(etrap_index_value);
    }

    @name(".etrap_state") table etrap_state {
        key = {
            etrap_color_value : exact @name("etrap_color");
        }
        actions = {
            @proto_id(1) etrap_red_state;
            @proto_id(2) etrap_green_state;
        }
        const entries = {
          (PSA_METERCOLOR_GREEN) : etrap_green_state();
          (PSA_METERCOLOR_RED) : etrap_red_state();
        }
        size = 3;
    }

    apply {
        if (headers.ipv6.isValid()) {
            ipv6_acl.apply();
        } else if (headers.ipv4.isValid()) {
            ipv4_acl.apply();
        }
        meter_index.apply();
        etrap_state.apply();
    }
}
# 27 "sai_p4/instantiations/google/sai.p4" 2


// #define TUNNEL_ENABLE



control ingress(inout headers_t headers,
                inout local_metadata_t local_metadata,
                in psa_ingress_input_metadata_t istd, inout psa_ingress_output_metadata_t ostd) {
  apply {




    ingress_bridge.apply(headers, local_metadata, istd, ostd);


    samplepacket.apply(headers, local_metadata, istd, ostd);

    etrap.apply(headers, local_metadata, istd, ostd);
    acl_lookup.apply(headers, local_metadata, istd, ostd);
    l3_admit.apply(headers, local_metadata, istd, ostd);
    hashing.apply(headers, local_metadata);
    routing.apply(headers, local_metadata, istd, ostd);

    fdb.apply(headers, local_metadata, istd, ostd);

    acl_ingress.apply(headers, local_metadata, istd, ostd);
    ttl.apply(headers, local_metadata, istd, ostd);

    mirroring_clone.apply(headers, local_metadata, istd, ostd);

    copy_i2e_metadata(headers, local_metadata);
  }
} // control ingress

control egress(inout headers_t headers,
               inout local_metadata_t local_metadata,
               in psa_egress_input_metadata_t istd, inout psa_egress_output_metadata_t ostd) {
  apply {
    headers.i2e.setInvalid();



    packet_rewrites.apply(headers, local_metadata);
    mirroring_encap.apply(headers, local_metadata, istd, ostd);
    vlan_encap.apply(headers, local_metadata, istd, ostd);
  }
} // control egress


IngressPipeline(packet_parser(), ingress(), packet_deparser()) ingress_pipeline;

EgressPipeline(egress_parser(), egress(), egress_deparser()) egress_pipeline;

PSA_Switch(ingress_pipeline, PacketReplicationEngine(), egress_pipeline,
         BufferingQueueingEngine()) main;
