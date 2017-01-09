/*
 * System global parameters
 */

action set_config_parameters(enable_dod, enable_flowlet) {
    deflect_on_drop(enable_dod);
#ifdef SFLOW_ENABLE
    /*
     * use 31 bit random number generator and detect overflow into upper half
     * to decide to take a sample
     */
    modify_field_rng_uniform(ingress_metadata.sflow_take_sample, 0, 0x7FFFFFFF);
#endif

    /* initialization */
    modify_field(i2e_metadata.ingress_tstamp, _ingress_global_tstamp_);
    modify_field(ingress_metadata.ingress_port, ig_intr_md.ingress_port);
    modify_field(l2_metadata.same_if_check, ingress_metadata.ifindex);
    modify_field(ig_intr_md_for_tm.ucast_egress_port, INVALID_PORT_ID);
#ifdef FLOWLET_ENABLE
    modify_field(flowlet_metadata.inactive_timeout, enable_flowlet);
#endif
}

table switch_config_params {
    actions {
        set_config_parameters;
    }
    size : 1;
}

control process_global_params {
    /* set up global controls/parameters */
    apply(switch_config_params);
}
