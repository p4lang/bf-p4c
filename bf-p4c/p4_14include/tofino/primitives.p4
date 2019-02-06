/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

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

#ifndef TOFINO_LIB_PRIMITIVES
#define TOFINO_LIB_PRIMITIVES 1

/////////////////////////////////////////////////////////////
// Primitive aliases

#define clone_i2e clone_ingress_pkt_to_egress
#define clone_e2e clone_egress_pkt_to_egress

action deflect_on_drop(enable_dod) {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, enable_dod);
}

#define _ingress_global_tstamp_     ig_intr_md_from_parser_aux.ingress_global_tstamp

#define _parser_counter_ ig_prsr_ctrl.parser_counter

#define pkt_is_mirrored (eg_intr_md_from_parser_aux.clone_src != NOT_CLONED)
#define pkt_is_not_mirrored (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED)

#define pkt_is_i2e_mirrored (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_INGRESS)
#define pkt_is_e2e_mirrored (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_EGRESS)
#define pkt_is_coalesced (eg_intr_md_from_parser_aux.clone_src == COALESCED)
#define pkt_is_not_coalesced (eg_intr_md_from_parser_aux.clone_src != COALESCED)

#endif
