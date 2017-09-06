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

/// XXX(hanw): This is a temporary architecture file to assist the
/// v1model to tofino translation, it will be removed once the
/// translation to tofino native architeture is complete.

#ifndef _V1MODEL_P4_
#define _V1MODEL_P4_

#include "core.p4"

match_kind {
    range,
    // Used for implementing dynamic_action_selection
    selector
}

// Are these correct?
@metadata @name("standard_metadata")
struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<32> clone_spec;
    bit<32> instance_type;
    bit<1>  drop;
    bit<16> recirculate_port;
    bit<32> packet_length;
    //
    // @alias is used to generate the field_alias section of the BMV2 JSON.
    // Field alias creates a mapping from the metadata name in P4 program to
    // the behavioral model's internal metadata name. Here we use it to
    // expose all metadata supported by simple switch to the user through
    // standard_metadata_t.
    //
    // flattening fields that exist in bmv2-ss
    // queueing metadata
    @alias("queueing_metadata.enq_timestamp") bit<32> enq_timestamp;
    @alias("queueing_metadata.enq_qdepth")    bit<19> enq_qdepth;
    @alias("queueing_metadata.deq_timedelta") bit<32> deq_timedelta;
    @alias("queueing_metadata.deq_qdepth")    bit<19> deq_qdepth;
    // intrinsic metadata
    @alias("intrinsic_metadata.ingress_global_timestamp") bit<48> ingress_global_timestamp;
    @alias("intrinsic_metadata.lf_field_list") bit<32> lf_field_list;
    @alias("intrinsic_metadata.mcast_grp")     bit<16> mcast_grp;
    @alias("intrinsic_metadata.resubmit_flag") bit<1>  resubmit_flag;
    @alias("intrinsic_metadata.egress_rid")    bit<16> egress_rid;
}

extern Checksum16 {
    Checksum16();
    bit<16> get<D>(in D data);
}

/// Counter
enum counter_type_t {
    PACKETS,
    BYTES,
    PACKETS_AND_BYTES
}

enum meter_type_t {
    PACKETS,
    BYTES
}

/// Counter
extern counter<I> {
    counter(counter_type_t type, @optional I instance_count);
    void count(@optional in I index);
}

/// Meter
extern meter<I> {
    meter(meter_type_t type, @optional I instance_count);
    bit<8> execute(@optional in I index, @optional in bit<8> color);
}

/// Register
extern register<T> {
    register(@optional bit<32> instance_count, @optional T initial_value);

    ///XXX(hanw): BRIG-212
    /// following two methods are not supported in brig backend
    /// they are present to help with the transition from v1model to tofino.p4
    /// after the transition, these two methods should be removed
    /// and the corresponding test cases should be marked as XFAILs.
    void read(out T result, in bit<32> index);
    void write(in bit<32> index, in T value);
}

extern register_params<T> {
    register_params();
    register_params(T value);
    register_params(T v1, T v2);
    register_params(T v1, T v2, T v3);
    register_params(T v1, T v2, T v3, T v4);
    T read(bit<2> index);
}

extern math_unit<T, U> {
    math_unit(bool invert, int<2> shift, int<6> scale, U data);
    T execute(in T x);
}

extern register_action<T, U> {
    register_action(register<T> reg, @optional math_unit<U, _> math,
                                     @optional register_params<U> params);
    abstract void apply(inout T value, @optional out U rv, @optional register_params<U> params);
    U execute(@optional in bit<32> index); /* {
        U rv;
        T value = reg.read(index);
        apply(value, rv);
        reg.write(index, value);
        return rv;
    } */
}

// used as table implementation attribute
extern action_profile {
    action_profile(bit<32> size);
}

/// Random number generator
extern random<T> {
    random();
    T get(@optional in T mask);
}

// If the type T is a named struct, the name is used
// to generate the control-plane API.
extern void digest<T>(in bit<32> receiver, in T data);

extern void mark_to_drop();

enum hash_algorithm_t {
    IDENTITY,
    RANDOM,
    CRC16,
    CRC32
}
extern hash<D, T, M> {
    /// Constructor
    hash(hash_algorithm_t algo);

    /// compute the hash for data
    ///  @base :
    ///  @max :
    T get_hash(in D data, @optional in T base, @optional in M max);
}

extern action_selector {
    action_selector(hash_algorithm_t algorithm, bit<32> size, bit<32> outputWidth);
}

enum CloneType {
    I2E,
    E2E
}

extern void resubmit<T>(in T data);
extern void recirculate<T>(in T data);
extern void clone(in CloneType type, in bit<32> session);
extern void clone3<T>(in CloneType type, in bit<32> session, in T data);

extern void truncate(in bit<32> length);

// The name 'standard_metadata' is reserved

// Architecture.
// M should be a struct of structs
// H should be a struct of headers or stacks

parser Parser<H, M>(packet_in b,
                    out H parsedHdr,
                    inout M meta,
                    inout standard_metadata_t standard_metadata);
control VerifyChecksum<H, M>(in H hdr,
                             inout M meta);
@pipeline
control Ingress<H, M>(inout H hdr,
                      inout M meta,
                      inout standard_metadata_t standard_metadata);
@pipeline
control Egress<H, M>(inout H hdr,
                     inout M meta,
                     inout standard_metadata_t standard_metadata);
control ComputeChecksum<H, M>(inout H hdr,
                              inout M meta);
@deparser
control Deparser<H>(packet_out b, in H hdr);

package V1Switch<H, M>(Parser<H, M> p,
                       VerifyChecksum<H, M> vr,
                       Ingress<H, M> ig,
                       Egress<H, M> eg,
                       ComputeChecksum<H, M> ck,
                       Deparser<H> dep
                       );

#endif  /* _V1MODEL_P4_ */
