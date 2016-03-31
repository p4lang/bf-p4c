#ifndef _TOFINO_LIB_PRIMITIVES
#define _TOFINO_LIB_PRIMITIVES 1

/////////////////////////////////////////////////////////////
// Primitive aliases

#define clone_i2e clone_ingress_pkt_to_egress
#define clone_e2e clone_egress_pkt_to_egress

action deflect_on_drop() {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, 1);
}

#define _ingress_global_tstamp_     ig_intr_md_from_parser_aux.ingress_global_tstamp

#define pkt_is_mirrored (eg_intr_md_from_parser_aux.clone_src != NOT_CLONED)
#define pkt_is_not_mirrored (eg_intr_md_from_parser_aux.clone_src == NOT_CLONED)

#define pkt_is_i2e_mirrored (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_INGRESS)
#define pkt_is_e2e_mirrored (eg_intr_md_from_parser_aux.clone_src == CLONED_FROM_EGRESS)

#endif
