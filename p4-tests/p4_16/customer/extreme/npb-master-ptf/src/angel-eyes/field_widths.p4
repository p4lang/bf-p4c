#ifndef _P4_FIELD_WIDTHS_
#define _P4_FIELD_WIDTHS_

#ifdef FIELD_WIDTHS_REDUCED // to help w/ fitting

    // -------------------------------------
    // Switch Widths
    // -------------------------------------
    
    #define switch_port_lag_index_width     10                                // original value: 10 (must be 10)
    #define switch_bd_width                  8                                // original value: 16
    #define switch_nexthop_width            12                                // original value: 16
    #define switch_tunnel_nexthop_width     12                                // original value: 16
    #define switch_smac_index_width         16                                // original value: 16
    #define switch_cpu_reason_width          8                                // original value: 16
    #define switch_drop_reason_width         8                                // original value:  8
    
    #define switch_copp_meter_id_width       8                                // original value:  8
    #define switch_meter_index_width        10                                // original value: 10
    #define switch_mirror_meter_id_width     8                                // original value:  8
    
    #define switch_tunnel_index_width       16                                // original value: 16
    #define switch_tunnel_id_width          32 // 32 for teid field           // original value: 24
    
    #define switch_lag_hash_width           32 // smallest can go is 26       // original value: 32
    
    // -------------------------------------
    // NPB Widths
    // -------------------------------------
    
    #define SSAP_ID_WIDTH                   16                                // original value: 16
    #define DSAP_ID_WIDTH                   16                                // original value: 16
    #define VPN_ID_WIDTH                    16                                // original value: 16
    #define SF_FLOW_CLASS_WIDTH_A            8 // for sf0...acl               // original value:  8 (unused if udf disabled)
    #define SF_FLOW_CLASS_WIDTH_B           10 // for sf0...sfp select        // original value: 10 (unused if simple sfp sel enabled)
    #define SF_HASH_WIDTH                   16 // for sf0...sfp select        // original value: 16(?)
    #define SF_INT_CTRL_FLAGS_WIDTH          8 // for sf0 and sf2             // original value: 16
    #define SF_SRVC_FUNC_CHAIN_WIDTH        12 // for sf0                     // original value: 16
    #define SF_L3_LEN_RNG_WIDTH              8 // for sf0 and sf2             // original value: 16
    #define SF_L4_SRC_RNG_WIDTH              8 // for sf0 and sf2             // original value: 16
    #define SF_L4_DST_RNG_WIDTH              8 // for sf0 and sf2             // original value: 16
    #define SF_L2_EDIT_BD_PTR_WIDTH          8                                // original value: xx
    #define UDF_WIDTH                      128 // 16B

  #ifdef BUG_00593008_WORKAROUND
	#define BRIDGED_METADATA_WIDTH          38 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs
  #else
	#define BRIDGED_METADATA_WIDTH          37 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs
  #endif

#else // Full field widths

    // -------------------------------------
    // Switch Widths
    // -------------------------------------
    
    #define switch_port_lag_index_width     10                                // original value: 10 (must be 10)
    #define switch_bd_width                 16                                // original value: 16
    #define switch_nexthop_width            16                                // original value: 16
    #define switch_tunnel_nexthop_width     16                                // original value: 16
    #define switch_smac_index_width         16                                // original value: 16
    #define switch_cpu_reason_width          8                                // original value: 16
    #define switch_drop_reason_width         8                                // original value:  8
    
    #define switch_copp_meter_id_width       8                                // original value:  8
    #define switch_meter_index_width        10                                // original value: 10
    #define switch_mirror_meter_id_width     8                                // original value:  8
    
    #define switch_tunnel_index_width       16                                // original value: 16
    #define switch_tunnel_id_width          32 // 32 for teid field           // original value: 24
    
    #define switch_lag_hash_width           32 // smallest can go is 26       // original value: 32
    
    // -------------------------------------
    // NPB Widths
    // -------------------------------------
    
    #define SSAP_ID_WIDTH                   16                                // original value: 16
    #define DSAP_ID_WIDTH                   16                                // original value: 16
    #define VPN_ID_WIDTH                    16                                // original value: 16
    #define SF_FLOW_CLASS_WIDTH_A            8 // for sf0...acl               // original value:  8 (unused if udf disabled)
    #define SF_FLOW_CLASS_WIDTH_B           10 // for sf0...sfp select        // original value: 10 (unused if simple sfp sel enabled)
    #define SF_HASH_WIDTH                   16 // for sf0...sfp select        // original value: 16(?)
    #define SF_INT_CTRL_FLAGS_WIDTH         16 // for sf0 and sf2             // original value: 16
    #define SF_SRVC_FUNC_CHAIN_WIDTH        16 // for sf0                     // original value: 16
    #define SF_L3_LEN_RNG_WIDTH             16 // for sf0 and sf2             // original value: 16
    #define SF_L4_SRC_RNG_WIDTH             16 // for sf0 and sf2             // original value: 16
    #define SF_L4_DST_RNG_WIDTH             16 // for sf0 and sf2             // original value: 16
    #define SF_L2_EDIT_BD_PTR_WIDTH         16                                // original value: xx
    #define UDF_WIDTH                      256 // 32B

  #ifdef BUG_00593008_WORKAROUND
	#define BRIDGED_METADATA_WIDTH          38 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs
  #else
	#define BRIDGED_METADATA_WIDTH          37 // number of bytes in the bridged metadata -- must be set manually -- can change between compiler runs
  #endif

#endif // FIELD_WIDTHS_REDUCED

#endif // _P4_FIELD_WIDTH_
