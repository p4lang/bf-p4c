
#ifndef _NPB_EGR_SET_LKP_
#define _NPB_EGR_SET_LKP_

// ============================================================================
// Set Lookup Structure with stuff the parser wasn't able to support
// ============================================================================

control EgressSetLookup(
        in    switch_header_t          hdr, // src
        inout switch_egress_metadata_t eg_md // dst
) {
    
    // -----------------------------
	// Apply
    // -----------------------------

    apply {

        // Override whatever the parser set "ip_type" to.  Doing so allows the
        // signal to fit when normally it doesn't.  This code should be only
        // temporary, and can be removed at a later date when a better compiler
        // is available....
        if(hdr.transport.nsh_type1.scope == 0) {
            if     (hdr.outer.ipv4.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
            else if(hdr.outer.ipv6.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
            else
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        } else {
            if     (hdr.inner.ipv4.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV4;
            else if(hdr.inner.ipv6.isValid())
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_IPV6;
            else
                eg_md.lkp_1.ip_type = SWITCH_IP_TYPE_NONE;
        }

        // -----------------------------------------------------------------------

		// ipv6: would like to do this stuff in the parser, but can't because tos
		// field isn't byte aligned...

		// ipv4: would like to do this stuff in the parser, but get the following error:
        //   "error: Field is extracted in the parser into multiple containers, but
        //    the container slices after the first aren't byte aligned"
#ifdef EGRESS_PARSER_POPULATES_LKP_SCOPED
		if(hdr.transport.nsh_type1.scope == 0) {
			// ----- outer -----
#ifdef IPV6_ENABLE
			if(hdr.outer.ipv6.isValid()) {
				eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
			}
#endif // IPV6_ENABLE
//			if(hdr.outer.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//			}
		} else {
			// ----- inner -----
#ifdef IPV6_ENABLE
			if(hdr.inner.ipv6.isValid()) {
				eg_md.lkp_1.ip_tos = hdr.inner.ipv6.tos;
			}
#endif // IPV6_ENABLE
//			if(hdr.inner.ipv4.isValid()) {
//				eg_md.lkp_1.ip_tos = hdr.inner.ipv4.tos;
//			}
		}
#else // EGRESS_PARSER_POPULATES_LKP_SCOPED
#ifdef EGRESS_PARSER_POPULATES_LKP_WITH_OUTER
		// ----- outer -----
#ifdef IPV6_ENABLE
		if(hdr.outer.ipv6.isValid()) {
			eg_md.lkp_1.ip_tos = hdr.outer.ipv6.tos;
		}        
#endif // IPV6_ENABLE
//		if(hdr.outer.ipv4.isValid()) {
//			eg_md.lkp_1.ip_tos = hdr.outer.ipv4.tos;
//		}        
#endif
#endif // EGRESS_PARSER_POPULATES_LKP_SCOPED

       
    }
}


#endif // _NPB_EGR_SET_LKP_
    
