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

#include "rewrite.p4"

//-----------------------------------------------------------------------------
// Ingress Port Mapping
//-----------------------------------------------------------------------------

control IngressPortMapping(
        inout switch_header_transport_t hdr,
        inout switch_ingress_metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr
) (
        switch_uint32_t port_vlan_table_size,
		switch_uint32_t bd_table_size,
        switch_uint32_t port_table_size=288,
		switch_uint32_t vlan_table_size=4096
) {
    ActionProfile(bd_table_size) bd_action_profile;

	// ----------------------------------------------
	// Table: Port Mapping
	// ----------------------------------------------

	action set_port_properties_with_nsh(
		switch_yid_t exclusion_id,

		bool                            l2_fwd_en,
		bit<3>                          sf_bitmask
	) {
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

		ig_md.nsh_type1.l2_fwd_en  = l2_fwd_en;   //  1 bit
		ig_md.nsh_type1.sf_bitmask = sf_bitmask;  //  8 bits
	}

	action set_port_properties_without_nsh(
		switch_yid_t exclusion_id,

		bit<SAP_ID_WIDTH>               sap,
		bit<VPN_ID_WIDTH>               vpn,
		bit<24>                         spi,
		bit<8>                          si,
		bool                            l2_fwd_en,
		bit<3>                          sf_bitmask
	) {
		ig_intr_md_for_tm.level2_exclusion_id = exclusion_id;

  		hdr.nsh_type1.sap          = sap;         // 16 bits
  		hdr.nsh_type1.vpn          = vpn;         // 16 bits
  		hdr.nsh_type1.spi          = spi;         // 24 bits
  		hdr.nsh_type1.si           = si;          //  8 bits
		ig_md.nsh_type1.l2_fwd_en  = l2_fwd_en;   //  1 bit
		ig_md.nsh_type1.sf_bitmask = sf_bitmask;  //  8 bits
	}

	table port_mapping {
		key = {
			ig_md.port : exact;
			hdr.nsh_type1.isValid() : exact;
		}

		actions = {
			set_port_properties_with_nsh;
			set_port_properties_without_nsh;
		}

		size = port_table_size * 2;
	}

	// ----------------------------------------------
	// Table: BD Mapping
	// ----------------------------------------------

    action port_vlan_miss() {
        //ig_md.flags.port_vlan_miss = true;
    }

    action set_bd_properties(
		switch_bd_t bd
    ) {
        ig_md.bd = bd;
	}

    table port_vlan_to_bd_mapping {
        key = {
            ig_md.port_lag_index : exact;
            hdr.vlan_tag[0].isValid() : ternary;
            hdr.vlan_tag[0].vid : ternary;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = NoAction;
        implementation = bd_action_profile;
        size = port_vlan_table_size;
    }

    // (*, vlan) --> bd mapping
    table vlan_to_bd_mapping {
        key = {
            hdr.vlan_tag[0].vid : exact;
        }

        actions = {
            NoAction;
            port_vlan_miss;
            set_bd_properties;
        }

        const default_action = port_vlan_miss;
        implementation = bd_action_profile;
        size = vlan_table_size;
    }

	// ----------------------------------------------
	// Apply
	// ----------------------------------------------

    apply {
/*
        switch (port_mapping.apply().action_run) {
            set_port_properties : {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
			}
        }
*/
        if(port_mapping.apply().hit) {
				if (!port_vlan_to_bd_mapping.apply().hit) {
					if (hdr.vlan_tag[0].isValid()) {
						vlan_to_bd_mapping.apply();
					}
				}
		}
    }
}

// ----------------------------------------------------------------------------
// Link Aggregation (LAG) resolution
//
// @param ig_md : Ingress metadata fields.
// @param hash : Hash value used for port selection.
// @param egress_port : Egress port.
// ----------------------------------------------------------------------------

control LAG(
    inout switch_ingress_metadata_t ig_md,
    in bit<16> hash,
    out switch_port_t egress_port
) (
	switch_uint32_t table_size_lag_group = LAG_GROUP_TABLE_SIZE,
	switch_uint32_t table_size_lag_selector = LAG_SELECT_TABLE_SIZE
) {

    Hash<switch_uint16_t>(HashAlgorithm_t.IDENTITY) selector_hash;
    ActionSelector(table_size_lag_selector, selector_hash, SelectorMode_t.FAIR) lag_selector;

	// ----------------------------------------------
	// Table: LAG
	// ----------------------------------------------

    action set_lag_port(switch_port_t port) {
        egress_port = port;
    }









    action lag_miss() { egress_port = 0; }

    table lag {
        key = {



            ig_md.egress_port_lag_index : exact @name("port_lag_index");

            hash : selector;
        }

        actions = {
            lag_miss;
            set_lag_port;

        }

        const default_action = lag_miss;
        size = table_size_lag_group;
        implementation = lag_selector;
    }

	// ----------------------------------------------
	// Apply
	// ----------------------------------------------

    apply {
        lag.apply();
    }
}

//-----------------------------------------------------------------------------
// Egress Port Mapping
//-----------------------------------------------------------------------------

control EgressPortMapping(
        inout switch_header_transport_t hdr,
        inout switch_egress_metadata_t eg_md,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        in switch_port_t port
) (
        switch_uint32_t table_size=288
) {

	// ----------------------------------------------
	// Table: Port Mapping
	// ----------------------------------------------

    action port_normal(
		switch_port_lag_index_t port_lag_index
    ) {
        eg_md.port_lag_index = port_lag_index;
    }

    table port_mapping {
        key = {
			port : exact;
		}

        actions = {
            port_normal;
        }

        size = table_size;
    }

	// ----------------------------------------------
	// Apply
	// ----------------------------------------------

    apply {
        port_mapping.apply();
    }
}
