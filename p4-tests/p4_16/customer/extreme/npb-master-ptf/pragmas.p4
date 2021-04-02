
@pa_atomic("ingress" , "ig_md.lkp_1.ip_type")
@pa_atomic("ingress" , "ig_md.lkp_2.ip_type")
@pa_atomic("egress" , "eg_md.bypass")
@pa_solitary("egress" , "eg_md.lkp_1.ip_flags")
@pa_container_size("egress" , "protocol_outer_0" , 8)
@pa_container_size("egress" , "protocol_inner_0" , 8)
@pa_container_size("egress" , "eg_md.lkp_1.tcp_flags", 8)

