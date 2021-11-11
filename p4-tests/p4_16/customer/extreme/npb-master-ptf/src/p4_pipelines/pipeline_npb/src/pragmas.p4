#ifndef _P4_PRAGMAS_
#define _P4_PRAGMAS_

#ifdef INGRESS_PARSER_POPULATES_LKP_1
@pa_atomic("ingress" , "ig_md.lkp_1.ip_type")
#endif
#ifdef INGRESS_PARSER_POPULATES_LKP_2
@pa_atomic("ingress" , "ig_md.lkp_2.ip_type")
#endif
//@pa_atomic("egress" , "eg_md.bypass")
@pa_container_size("egress", "eg_md.flags.bypass_egress", 8)
@pa_solitary("egress" , "eg_md.lkp_1.ip_flags")
@pa_container_size("egress" , "protocol_outer_0" , 8)
@pa_container_size("egress" , "protocol_inner_0" , 8)
@pa_container_size("egress" , "eg_md.lkp_1.tcp_flags", 8)

#endif // _P4_PRAGMAS_
