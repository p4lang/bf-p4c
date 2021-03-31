/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2019 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 ******************************************************************************/

// DEREK: NOT USING THIS TABLE ANYMORE -- USING THE TABLE IN TUNNEL.P4 INSTEAD.

#include "acl.p4"
#include "l2.p4"

//-----------------------------------------------------------------------------
// Router MAC lookup
// key: destination MAC address.
// - Route the packet if the destination MAC address is owned by the switch.
//-----------------------------------------------------------------------------
#ifdef TUNNEL_ENABLE
#define RMAC_KEYS                              \
  ig_md.rmac_group : exact;                    \
  ig_md.lkp.mac_dst_addr : exact;              \
  ig_md.tunnel.type : exact;                   \
  ig_md.tunnel.terminate : exact;
#else
#define RMAC_KEYS                              \
  ig_md.rmac_group : exact;                    \
  ig_md.lkp.mac_dst_addr : exact;
#endif
#define RMAC                                             \
    action rmac_hit() { ig_md.flags.rmac_hit = true; }   \
    action rmac_miss() { ig_md.flags.rmac_hit = false; } \
    table rmac {                                         \
        key = {                                          \
            RMAC_KEYS                                    \
        }                                                \
        actions = {                                      \
            rmac_hit;                                    \
            @defaultonly rmac_miss;                      \
        }                                                \
        const default_action = rmac_miss;                \
        size = 1024;                                     \
    }

//-----------------------------------------------------------------------------
// @param lkp : Lookup fields used to perform L2/L3 lookups.
// @param ig_md : Ingress metadata fields.
// @param dmac : DMAC instance (See l2.p4)
//-----------------------------------------------------------------------------
control IngressUnicast(
    in switch_lookup_fields_t lkp,
    inout switch_ingress_metadata_t ig_md
) (
) {

//  RMAC

	//-----------------------------------------------------------------------------
	// Apply
	//-----------------------------------------------------------------------------

    apply {
//      if (rmac.apply().hit) {
//      } else {
//      }
    }
}
