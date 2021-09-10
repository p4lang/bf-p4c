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

#ifndef _SCOPER_
#define _SCOPER_

#include "scoper_lkp_to_lkp.p4"
#include "scoper_hdr0_to_lkp.p4"
#include "scoper_hdr1_to_lkp.p4"
#include "scoper_hdr2_to_lkp.p4"

// ============================================================================
// High Level Routines (meant to only be used by functions outside this file)
// ============================================================================

// NO  Set Terminates / Scope
// YES Set Lkp Data

control Scoper_DataOnly(
		in    bool flags_unsupported_tunnel_0_in,
		in    bool flags_unsupported_tunnel_1_in,
		in    bool flags_unsupported_tunnel_2_in,

		in    switch_lookup_fields_t lkp0_in,
//		in    switch_lookup_fields_t lkp1_in,
		in    switch_lookup_fields_t lkp2_in,

		in    switch_header_outer_t       hdr_1,
		in    switch_header_inner_t       hdr_2,
		in    switch_header_inner_inner_t hdr_3,

		in    bit<8> scope,
		inout switch_lookup_fields_t lkp
) {
	apply {
		if(scope == 0) {
#ifdef INGRESS_MAU_NO_LKP_0
//			Scoper_DataMux_Hdr0ToLkp.apply(hdr_0, hdr_1, lkp0_in, flags_unsupported_tunnel_0_in, lkp);
#else
//			Scoper_DataMux_LkpToLkp.apply(lkp0_in, lkp);
#endif
		} else if(scope == 1) {
#ifdef INGRESS_MAU_NO_LKP_1
//			Scoper_DataMux_Hdr1ToLkp.apply(hdr_1, hdr_2, lkp1_in, flags_unsupported_tunnel_1_in, lkp);
#else
//			Scoper_DataMux_LkpToLkp.apply(lkp1_in, lkp);
#endif
		} else {
#ifdef INGRESS_MAU_NO_LKP_2
			Scoper_DataMux_Hdr2ToLkp.apply(hdr_2, hdr_3, lkp2_in, flags_unsupported_tunnel_2_in, lkp);
#else
			Scoper_DataMux_LkpToLkp.apply(lkp2_in, lkp);
#endif
		}
	}
}

// ============================================================================

// YES Set Terminates / Scope
// NO  Set Lkp Data

control Scoper_ScopeAndTermOnly(
		inout switch_lookup_fields_t lkp,

		in    bool terminate_flag,
		in    bool scope_flag,
		inout bit<8> scope,
		inout bool terminate_0,
		inout bool terminate_1,
		inout bool terminate_2
) {
	action scope_0() {
//		scoper();
		scope = 1;
	}

	action scope_1() {
//		scoper();
		scope = 2;
	}

	action scope_2() {
		// we can't scope any deeper here
		scope = 3;
	}

	action term_0() {
//		terminate_0           = true;
//		scoper();
		scope = 1;
	}

	action term_1() {
		terminate_1           = true;
//		scoper();
		scope = 2;
	}

	action term_2() {
		terminate_1           = true;
		terminate_2           = true;
		// we can't scope any deeper here
		scope = 3;
	}

	table scope_inc {
		key = {
			lkp.next_lyr_valid : exact;
			terminate_flag : exact;
			scope_flag : exact;
			scope : exact;
		}
		actions = {
			NoAction;
			scope_0;
			scope_1;
			scope_2;
			term_0;
			term_1;
			term_2;
		}
		const entries = {
			(true, false, true,  0) : scope_0();
			(true, false, true,  1) : scope_1();
			(true, false, true,  2) : scope_2();

			(true, true,  true,  0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  false, 0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  true,  1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  false, 1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  true,  2) : term_2(); // scope_flag is a don't care when terminating
			(true, true,  false, 2) : term_2(); // scope_flag is a don't care when terminating
		}
		const default_action = NoAction;
	}

	apply {
		scope_inc.apply();
	}
}

// ============================================================================

// YES Set Terminates / Scope
// YES Set Lkp Data

control Scoper_ScopeAndTermAndData(
		in    bool flags_unsupported_tunnel_0_in,
		in    bool flags_unsupported_tunnel_1_in,
		in    bool flags_unsupported_tunnel_2_in,

		inout switch_lookup_fields_t lkp0_in,
//		inout switch_lookup_fields_t lkp1_in,
		inout switch_lookup_fields_t lkp2_in,

		in    switch_header_outer_t       hdr_1,
		in    switch_header_inner_t       hdr_2,
		in    switch_header_inner_inner_t hdr_3,

		inout switch_lookup_fields_t lkp,

		in    bool terminate_flag,
		in    bool scope_flag,
		inout bit<8> scope,
		inout bool terminate_0,
		inout bool terminate_1,
		inout bool terminate_2
) {
	action scope_0() {
//		scoper();
		scope = 1;
	}

	action scope_1() {
//		scoper();
		scope = 2;
	}

	action scope_2() {
		// we can't scope any deeper here
		scope = 3;
	}

	action term_0() {
//		terminate_0           = true;
//		scoper();
		scope = 1;
	}

	action term_1() {
		terminate_1           = true;
//		scoper();
		scope = 2;
	}

	action term_2() {
		terminate_1           = true;
		terminate_2           = true;
		// we can't scope any deeper here
		scope = 3;
	}

	table scope_inc {
		key = {
			lkp.next_lyr_valid : exact;
			terminate_flag : exact;
			scope_flag : exact;
			scope : exact;
		}
		actions = {
			NoAction;
			scope_0;
			scope_1;
			scope_2;
			term_0;
			term_1;
			term_2;
		}
		const entries = {
			(true, false, true,  0) : scope_0();
			(true, false, true,  1) : scope_1();
			(true, false, true,  2) : scope_2();

			(true, true,  true,  0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  false, 0) : term_0(); // scope_flag is a don't care when terminating
			(true, true,  true,  1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  false, 1) : term_1(); // scope_flag is a don't care when terminating
			(true, true,  true,  2) : term_2(); // scope_flag is a don't care when terminating
			(true, true,  false, 2) : term_2(); // scope_flag is a don't care when terminating
		}
		const default_action = NoAction;
	}

	apply {
/*
		scope_inc.apply();
		if(scope == 0) {
			Scoper_DataMux_LkpToLkp.apply(lkp0_in, lkp);
		} else if(scope == 1) {
//			Scoper_DataMux_LkpToLkp.apply(lkp1_in, lkp);
		} else {
			Scoper_DataMux_LkpToLkp.apply(lkp2_in, lkp);
		}
*/
		if(scope_inc.apply().hit) {
#ifdef INGRESS_MAU_NO_LKP_2
			Scoper_DataMux_Hdr2ToLkp.apply(hdr_2, hdr_3, lkp2_in, flags_unsupported_tunnel_2_in, lkp);
#else
			Scoper_DataMux_LkpToLkp.apply(lkp2_in, lkp);
#endif
		}
	}

}

#endif
