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

#include <core.p4>
#include <tna.p4>

struct metadata {}

// Empty ingress/egress blocks and headers.
#include "../includes/trivial_parser.h"

control ingress(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    @dynamic_table_key_masks(1) table bad_table {
        key = {
            hdr.data.f1 : exact;
            hdr.data.f2 : ternary; //////////////////// Error, must be 'exact'.
            hdr.data.h1 : ternary; //////////////////// Error, must be 'exact'.
        }
        actions = {}
    }

    apply {
        bad_table.apply();
    }
}

// Empty ingress/egress blocks & Pipe.
#include "../includes/common_tna_test.h"

