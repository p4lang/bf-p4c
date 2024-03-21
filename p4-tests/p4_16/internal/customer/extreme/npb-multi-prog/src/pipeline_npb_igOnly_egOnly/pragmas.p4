#ifndef _P4_PRAGMAS_
#define _P4_PRAGMAS_

// These pragmas are needed to function properly
// -----------------------------------------------------------------------------
@pa_auto_init_metadata
//@pa_no_overlay("ingress", "hdr.transport.ipv4.src_addr")
//@pa_no_overlay("ingress", "hdr.transport.ipv4.dst_addr")

#ifdef PA_MONOGRESS
@pa_parser_group_monogress  //grep for monogress in phv_allocation log to confirm
#endif
#ifdef PA_NO_INIT
@pa_no_init("ingress", "ig_intr_md_for_tm.bypass_egress")  // reset in port.p4
@pa_no_init("egress",  "eg_md.tunnel_1.terminate")         // reset in npb_egr_parser.p4
@pa_no_init("egress",  "eg_md.lkp_1.next_lyr_valid")       // reset in npb_egr_set_lkp.p4
@pa_no_init("egress",  "eg_intr_md_for_dprsr.mirror_type") // reset in this file (below)
@pa_no_init("ingress", "ig_md.tunnel_2.terminate")         // reset in npb_ing_parser.p4
//@pa_no_init("ingress", "ig_md.mirror.src")                 // reset in this file (below) NOT NEEDED
#endif // PA_NO_INIT
@pa_no_init("ingress", "ig_intr_md_for_tm.ucast_egress_port") // added per case 00779712 patch


// These pragmas are needed to fit design
// -----------------------------------------------------------------------------
#ifdef INGRESS_PARSER_POPULATES_LKP_1
//@pa_atomic("ingress" , "ig_md.lkp_1.ip_type")
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_2
//@pa_atomic("ingress" , "ig_md.lkp_2.ip_type")
#endif
//@pa_atomic("egress" , "eg_md.bypass")
//@pa_container_size("egress", "eg_md.flags.bypass_egress", 8)
//@pa_solitary("egress" , "eg_md.lkp_1.ip_flags")

// comment these to get uni-dir p4-program to compile w/ SDE v9.9.0-pr10985 (see case 00678071)
// @pa_container_size("egress" , "protocol_outer_0" , 8)
// @pa_container_size("egress" , "protocol_inner_0" , 8)
// @pa_container_size("egress" , "eg_md.lkp_1.tcp_flags", 8)
// 
// //Needed to fit design w/ SDE v9.8.0-pr10582 (see case 00675487)
// @pa_container_size("ingress", "ig_intr_md_for_tm.level2_mcast_hash", 16)
// @pa_container_size("ingress", "ig_intr_md_for_tm.level2_exclusion_id", 16)
// @pa_container_size("ingress", "ig_intr_md_for_tm.rid", 16)
// @pa_container_size("ingress", "ig_intr_md_for_dprsr.mtu_trunc_len", 16)
// @pa_container_size("egress", "eg_intr_md_for_dprsr.mtu_trunc_len", 16) 


// These pragmas are need to fit design (v6 encap)
// -----------------------------------------------------------------------------

// remove following pragmas:
// -----------------------
//@pa_container_size("ingress", "ig_md.mirror.src", 8)
//@pa_container_size("ingress", "ig_md.mirror.type", 8)
@pa_alias("ingress", "ig_md.qos.qid", "ig_intr_md_for_tm.qid")
//@pa_container_size("egress", "eg_md.mirror.src", 8)
//@pa_container_size("egress", "eg_md.mirror.type", 8)

// Add the following pragmas:
// -----------------------
//@pa_prioritize_ara_inits
//@pa_no_overlay("ingress", "hdr.bridged_md.base_qid", "ig_md.qos.qid")
//@pa_no_overlay("ingress", "ig_intr_md_for_tm.qid", "ig_md.qos.qid")
//@pa_no_overlay("ingress", "ig_md.lkp_1.ip_type", "hdr.transport.ethernet.ether_type") // added per case 00776085 patch

#endif // _P4_PRAGMAS_
