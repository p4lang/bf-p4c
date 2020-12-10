
#include "types.p4"

// Stack length tables - For determining the size of various opaque stacks

// -----------------------------------------------------------------------------
// Outer Stack (1) - Does not include layer2 

control OpaqueStackLength_1(
#ifdef OPAQUE_SIZE_AS_HDR
    inout switch_header_outer_t hdr  // src & dst
#endif
#ifdef OPAQUE_SIZE_AS_MD
    in switch_header_outer_t hdr,  // src
    out switch_stack_length_t stack_length // dst
#endif
) {

    action set_length_to_zero() {
#ifdef OPAQUE_SIZE_AS_HDR
        hdr.opaque_length.setValid();
        hdr.opaque_length.len = 0;
#endif
#ifdef OPAQUE_SIZE_AS_MD
        stack_length = 0;
#endif
    }

    action set_length(bit<10> x) {
#ifdef OPAQUE_SIZE_AS_HDR
        hdr.opaque_length.setValid();
        hdr.opaque_length.len = x;
#endif
#ifdef OPAQUE_SIZE_AS_MD
        stack_length = x;
#endif
    }
        
    table table_stack_length {
    
        key = {
            hdr.ipv4.isValid() : ternary;
    #ifdef IPV6_ENABLE
            hdr.ipv6.isValid() : ternary;
    #endif  /* IPV6_ENABLE */
            hdr.gre.isValid() : ternary;
            hdr.nvgre.isValid() : ternary;
            hdr.udp.isValid() : ternary;
            hdr.vxlan.isValid() : ternary;
            hdr.gtp_v1_base.isValid() : ternary;
        }
    
        actions = {
            //NoAction;
            set_length_to_zero;
            set_length;
        }
    
        size = 8;
        const default_action = set_length_to_zero;
        const entries = {
    
    #ifdef IPV6_ENABLE
            (true, _, _, true, _, _, _):
            set_length(STACK_IPV4_NVGRE);
            (true, _, true, false, _, _, _):
            set_length(STACK_IPV4_GRE);
            (true, _, _, _, _, true, _):
            set_length(STACK_IPV4_UDP_VXLAN);
            (true, _, _, _, _, _, true):
            set_length(STACK_IPV4_UDP_GTPU);
            (true, _, _, _, _, _, _):
            set_length(STACK_IPV4);
    
            (_, true, _, true, _, _, _):
            set_length(STACK_IPV6_NVGRE);
            (_, true, true, false, _, _, _):
            set_length(STACK_IPV6_GRE);
            (_, true, _, _, _, true, _):
            set_length(STACK_IPV6_UDP_VXLAN);
            (_, true, _, _, _, _, true):
            set_length(STACK_IPV6_UDP_GTPU);
            (_, true, _, _, _, _, _):
            set_length(STACK_IPV6);
    #else
            (true, _, true, _, _, _):
            set_length(STACK_IPV4_NVGRE);
            (true, true, false, _, _, _):
            set_length(STACK_IPV4_GRE);
            (true, _, _, _, true, _):
            set_length(STACK_IPV4_UDP_VXLAN);
            (true, _, _, _, _, true):
            set_length(STACK_IPV4_UDP_GTPU);
            (true, _, _, _, _, _):
            set_length(STACK_IPV4);
    #endif // IPV6_ENABLE
    
        }
    }

    // -----------------------------
	// Apply
    // -----------------------------

    apply {
        table_stack_length.apply();
    }
}


// -----------------------------------------------------------------------------
// Inner Stack (2)

control OpaqueStackLength_2(
#ifdef OPAQUE_SIZE_AS_HDR
    inout  switch_header_inner_t hdr  // src & dst
#endif
#ifdef OPAQUE_SIZE_AS_MD
    in  switch_header_inner_t hdr,  // src
    out switch_stack_length_t stack_length // dst
#endif
) {

    bool gtp_dummy_placeholder = false;


    action set_length_to_zero() {
#ifdef OPAQUE_SIZE_AS_HDR
        hdr.opaque_length.setValid();
        hdr.opaque_length.len = 0;
#endif
#ifdef OPAQUE_SIZE_AS_MD
        stack_length = 0;
#endif
    }

    action set_length(bit<10> x) {
#ifdef OPAQUE_SIZE_AS_HDR
        hdr.opaque_length.setValid();
        hdr.opaque_length.len = x;
#endif
#ifdef OPAQUE_SIZE_AS_MD
        stack_length = x;
#endif
    }

        
    table table_stack_length {
    
        key = {
            hdr.ethernet.isValid() : ternary;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.ipv4.isValid() : ternary;
    #ifdef IPV6_ENABLE
            hdr.ipv6.isValid() : ternary;
    #endif  /* IPV6_ENABLE */
            hdr.gre.isValid() : ternary;
            hdr.udp.isValid() : ternary;
            //hdr.gtp_v1_base.isValid() : ternary;
            gtp_dummy_placeholder : ternary;
        }
    
        actions = {
            //NoAction;
            set_length_to_zero;
            set_length;
        }
    
        size = 16;
        const default_action = set_length_to_zero;
        const entries = {
    
    #ifdef IPV6_ENABLE
            (true, false, true, _, true, _, _):
            set_length(STACK_ENET_IPV4_GRE);
            (true, true, true, _, true, _, _):
            set_length(STACK_ENET_VLAN_IPV4_GRE);
            (false, false, true, _, true, _, _):
            set_length(STACK_IPV4_GRE);

            // (true, false, true, _, _, _, true):
            // set_length(STACK_ENET_IPV4_UDP_GTPU);
            // (true, true, true, _, _, _, true):
            // set_length(STACK_ENET_VLAN_IPV4_UDP_GTPU);
            // (false, false, true, _, _, _, true):
            // set_length(STACK_IPV4_UDP_GTPU);

            (true, false, _, true, true, _, _):
            set_length(STACK_ENET_IPV6_GRE);
            (true, true, _, true, true, _, _):
            set_length(STACK_ENET_VLAN_IPV6_GRE);
            (false, false, _, true, true, _, _):
            set_length(STACK_IPV6_GRE);

            // (true, false, _, true, _, _, true):
            // set_length(STACK_ENET_IPV6_UDP_GTPU);
            // (true, true, _, true, _, _, true):
            // set_length(STACK_ENET_VLAN_IPV6_UDP_GTPU);
            // (false, false, _, true, _, _, true):
            // set_length(STACK_IPV6_UDP_GTPU);    
    #else
            (true, false, true, true, _, _):
            set_length(STACK_ENET_IPV4_GRE);
            (true, true, true, true, _, _):
            set_length(STACK_ENET_VLAN_IPV4_GRE);
            (false, false, true, true, _, _):
            set_length(STACK_IPV4_GRE);

            // (true, false, true, _, _, true):
            // set_length(STACK_ENET_IPV4_UDP_GTPU);
            // (true, true, true, _, _, true):
            // set_length(STACK_ENET_VLAN_IPV4_UDP_GTPU);
            // (false, false, true, _, _, true):
            // set_length(STACK_IPV4_UDP_GTPU);
    #endif // IPV6_ENABLE
    
        }
    }

    // -----------------------------
	// Apply
    // -----------------------------

    apply {
        table_stack_length.apply();
    }
}


/*
    ENET,        // 14B
    VLAN,        // 4B
    ETAG,        // 8B
    VNTAG,       // 6B
    IPV4,        // 20B
    IPV6         // 40B
    UDP,         // 8B
    TCP,         // 20B
    SCTP         // 12B
    NSH,         // 24B
    GRE,         // 4B
    GRE SEQ EXT, // 4B
    NVGRE EXT,   // 4B
    ERSPAN_1,    // 8B
    ERSPAN_2,    // 12B
    VXLAN        // 8B
    ESP          // 8B
    GTP          // 8B
    UDF          // 11B
*/
