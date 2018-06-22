/*
Copyright (c) 2015-2017 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

// -----------------------------------------------------------------------------
// stratum.p4 describes the ground-zero architecture for all derived
// Barefoot architectures.
// -----------------------------------------------------------------------------

#ifndef _STRATUM_P4_
#define _STRATUM_P4_

#include "core.p4"


enum PSA_PacketPath_t {
    NORMAL,     /// Packet received by ingress that is none of the cases below.
    NORMAL_UNICAST,   /// Normal packet received by egress which is unicast
    NORMAL_MULTICAST, /// Normal packet received by egress which is multicast
    CLONE_I2E,  /// Packet created via a clone operation in ingress,
                /// destined for egress
    CLONE_E2E,  /// Packet created via a clone operation in egress,
                /// destined for egress
    RESUBMIT,   /// Packet arrival is the result of a resubmit operation
    RECIRCULATE /// Packet arrival is the result of a recirculate operation
}

/// A hack to support v1model to tofino translation, the enum is required
/// as long as we still support v1model.p4
enum CloneType {
    I2E,
    E2E
}

parser IngressParser<H, M, CG>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md,
    out ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    out ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

parser EgressParser<H, M, CG>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md,
    out egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    /// following two arguments are bridged metadata
    inout ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

control Ingress<H, M, CG>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

control Egress<H, M, CG>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport,
    // following two arguments are bridged metadata
    inout ingress_intrinsic_metadata_t ig_intr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout CG aux);

control IngressDeparser<H, M, CG>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
    in ingress_intrinsic_metadata_t ig_intr_md,
    inout CG aux);

control EgressDeparser<H, M, CG>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    in egress_intrinsic_metadata_t eg_intr_md,
    in ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
    inout CG aux);

package Pipeline<IH, IM, EH, EM, CG>(
    IngressParser<IH, IM, CG> ingress_parser,
    Ingress<IH, IM, CG> ingress,
    IngressDeparser<IH, IM, CG> ingress_deparser,
    EgressParser<EH, EM, CG> egress_parser,
    Egress<EH, EM, CG> egress,
    EgressDeparser<EH, EM, CG> egress_deparser);

package Switch<IH0, IM0, EH0, EM0, CG0, IH1, IM1, EH1, EM1, CG1,
               IH2, IM2, EH2, EM2, CG2, IH3, IM3, EH3, EM3, CG3>(
    Pipeline<IH0, IM0, EH0, EM0, CG0> pipe0,
    @optional Pipeline<IH1, IM1, EH1, EM1, CG1> pipe1,
    @optional Pipeline<IH2, IM2, EH2, EM2, CG2> pipe2,
    @optional Pipeline<IH3, IM3, EH3, EM3, CG3> pipe3);

#endif  /* _STRATUM_P4_ */
