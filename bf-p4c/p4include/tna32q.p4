/*
 * Copyright (c) 2015-2017 Barefoot Networks, Inc.
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

#ifndef _TOFINO_NATIVE_ARCHITECTURE_P4_
#define _TOFINO_NATIVE_ARCHITECTURE_P4_

#include "core.p4"
#include "tofino.p4"

parser IngressParser<H, M>(
    packet_in pkt,
    out H hdr,
    out M ig_md,
    out ingress_intrinsic_metadata_t ig_intr_md);

parser EgressParser<H, M>(
    packet_in pkt,
    out H hdr,
    out M eg_md,
    out egress_intrinsic_metadata_t eg_intr_md);

control Ingress<H, M>(
    inout H hdr,
    inout M ig_md,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs,
    inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm);

control Egress<H, M>(
    inout H hdr,
    inout M eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport);

control IngressDeparser<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprs);

control EgressDeparser<H, M>(
    packet_out pkt,
    inout H hdr,
    in M metadata,
    in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs);

package Pipe<IH, IM, EH, EM>(
    IngressParser<IH, IM> ingress_parser,
    Ingress<IH, IM> ingress,
    IngressDeparser<IH, IM> ingress_deparser,
    EgressParser<EH, EM> egress_parser,
    Egress<EH, EM> egress,
    EgressDeparser<EH, EM> egress_deparser);

package Switch<IH0, IM0, EH0, EM0, IH1, IM1, EH1, EM1>(
            Pipe<IH0, IM0, EH0, EM0> pipe0,
            Pipe<IH1, IM1, EH1, EM1> pipe1);

#endif


