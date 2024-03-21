#include "npb_ing_sf_npb_basic_adv_top.p4"
//#include "npb_ing_sf_repli_top.p4"

control npb_ing_sff_top (
	inout switch_header_t                           hdr,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	// Derek TODO:
	//
	// What should be the default action on a miss -- the l2 miss action, or the
	// l3 miss action?  It seems like anything that got here would have been
	// addressed to us, so I'm thinking the l3 miss action....

	// =========================================================================
	// Table #1
	// =========================================================================

	// =====================================
	// L2 Actions
	// =====================================

	action dmac_miss(
	) {
		ig_md.egress_ifindex          = SWITCH_IFINDEX_FLOOD;

		ig_md.nsh_extr.end_of_chain   = 1;
	}

	// =====================================

	action dmac_hit(
		switch_ifindex_t        ifindex,
		switch_port_lag_index_t port_lag_index,

		bit<1>                  end_of_chain
	) {
		ig_md.egress_ifindex          = ifindex;
		ig_md.egress_port_lag_index   = port_lag_index;
		ig_md.checks.same_if          = ig_md.ifindex ^ ifindex;

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
	}

	// =====================================

	action dmac_multicast(
		switch_mgid_t           index,

		bit<1>                  end_of_chain
	) {
		ig_intr_md_for_tm.mcast_grp_b = index;

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
	}

	// =====================================

	action dmac_redirect(
		switch_nexthop_t        nexthop_index,

		bit<1>                  end_of_chain
	) {
		ig_md.nexthop                 = nexthop_index;

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
	}

	// =====================================

	action dmac_drop(
		bit<1>                  end_of_chain
	) {
		//TODO(msharif): Drop the packet.

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
	}

	// =====================================
	// L3 Unicast Actions
	// =====================================

	action fib_hit(
		switch_nexthop_t        nexthop_index,

		bit<1>                  end_of_chain
	) {
		ig_md.nexthop                 = nexthop_index;
		ig_md.flags.routed            = true;

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
	}
            
	// =====================================

	action fib_miss(
	) {
		ig_md.flags.routed            = false;

		ig_md.nsh_extr.end_of_chain   = 1;
	}

	// =====================================

	action fib_myip(
		bit<1>                  end_of_chain
	) {
		ig_md.flags.myip              = true;

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
	}

	// =====================================
	// L3 Multicast Actions
	// =====================================

    action set_multicast_route(
		switch_multicast_mode_t mode,
		switch_mgid_t           index,
		bit<1>                  end_of_chain
	) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = true;
        ig_md.flags.routed = true;
        ig_md.flags.flood_to_multicast_routers = false;
        ig_md.checks.same_bd = 0x3fff;

		ig_md.multicast.mode          = mode;
		ig_intr_md_for_tm.mcast_grp_b = index;
		ig_md.nsh_extr.end_of_chain   = end_of_chain;
    }

	// =====================================

    action set_multicast_bridge(
		bool mrpf,

		switch_mgid_t           index,
		bit<1>                  end_of_chain
	) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = 0;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = false;

		ig_intr_md_for_tm.mcast_grp_b = index;
		ig_md.nsh_extr.end_of_chain   = end_of_chain;
    }

	// =====================================

    action set_multicast_flood(
		bool mrpf,
		bool flood,

		bit<1>                  end_of_chain
	) {
        ig_md.egress_port_lag_index = 0;
        ig_md.egress_ifindex = SWITCH_IFINDEX_FLOOD;
        ig_md.checks.mrpf = mrpf;
        ig_md.flags.routed = false;
        ig_md.flags.flood_to_multicast_routers = flood;

		ig_md.nsh_extr.end_of_chain   = end_of_chain;
    }

	// =====================================
	// Table
	// =====================================

	table nbp_ing_sff_table_1 {
		key = {
			ig_md.nsh_extr.spi : exact;
			ig_md.nsh_extr.si  : exact;
		}

		actions = {
			// l2 actions
			dmac_miss;
			dmac_hit;
			dmac_multicast;
			dmac_redirect;
			dmac_drop;

			// l3 unicast actions
			fib_miss;
			fib_hit;
			fib_myip;

			// l3 multicast actions
            set_multicast_bridge;
            set_multicast_route;
            set_multicast_flood;
		}

//		const default_action = dmac_miss;
		const default_action = fib_miss;
		size = NPB_ING_SFF_TABLE_DEPTH;
	}

	// =========================================================================
	// Table - TTL Decrement
	// =========================================================================

/*
    action new_ttl(bit<6> ttl) {
        ig_md.nsh_extr.ttl = ttl;
    }

    action discard() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
    }

    table nbp_ing_sff_dec_ttl {
        key = { ig_md.nsh_extr.ttl : exact; }
        actions = { new_ttl; discard; }
        const entries = {
            0  : new_ttl(63);
            1  : discard();
            2  : new_ttl(1);
            3  : new_ttl(2);
            4  : new_ttl(3);
            5  : new_ttl(4);
            6  : new_ttl(5);
            7  : new_ttl(6);
            8  : new_ttl(7);
            9  : new_ttl(8);
            10 : new_ttl(9);
            11 : new_ttl(10);
            12 : new_ttl(11);
            13 : new_ttl(12);
            14 : new_ttl(13);
            15 : new_ttl(14);
            16 : new_ttl(15);
            17 : new_ttl(16);
            18 : new_ttl(17);
            19 : new_ttl(18);
            20 : new_ttl(19);
            21 : new_ttl(20);
            22 : new_ttl(21);
            23 : new_ttl(22);
            24 : new_ttl(23);
            25 : new_ttl(24);
            26 : new_ttl(25);
            27 : new_ttl(26);
            28 : new_ttl(27);
            29 : new_ttl(28);
            30 : new_ttl(29);
            31 : new_ttl(30);
            32 : new_ttl(31);
            33 : new_ttl(32);
            34 : new_ttl(33);
            35 : new_ttl(34);
            36 : new_ttl(35);
            37 : new_ttl(36);
            38 : new_ttl(37);
            39 : new_ttl(38);
            40 : new_ttl(39);
            41 : new_ttl(40);
            42 : new_ttl(41);
            43 : new_ttl(42);
            44 : new_ttl(43);
            45 : new_ttl(44);
            46 : new_ttl(45);
            47 : new_ttl(46);
            48 : new_ttl(47);
            49 : new_ttl(48);
            50 : new_ttl(49);
            51 : new_ttl(50);
            52 : new_ttl(51);
            53 : new_ttl(52);
            54 : new_ttl(53);
            55 : new_ttl(54);
            56 : new_ttl(55);
            57 : new_ttl(56);
            58 : new_ttl(57);
            59 : new_ttl(58);
            60 : new_ttl(59);
            61 : new_ttl(60);
            62 : new_ttl(61);
            63 : new_ttl(62);
        }
    }
*/

	// =========================================================================
	// Apply
	// =========================================================================

	// Need to do two table lookups here?
	//
	// 1: service func lookup to get sf bitmask.
	// 2: forwarding lookup, after any sf's have reclassified the packet.

	apply {

		if(ig_md.nsh_extr.valid == 1) {

			// -------------------------------------
			// Decrement and Check TTL
			// -------------------------------------

			// Note: according to RFC: "each SFF MUST decrement the TTL value
			// "prior to the NSH forwarding lookup".

//        	npb_ing_sff_dec_ttl.apply();

/*
			// -------------------------------------
			// Forwarding Lookup
			// -------------------------------------

			// table here:

			nbp_ing_sff_table_1.apply();
*/

			// -------------------------------------
			// SF(s)
			// -------------------------------------

			if(ig_md.nsh_extr.extr_srvc_func_bitmask_local[0:0] == 1) {

				// -------------------------------------
				// SF #0
				// -------------------------------------

				npb_ing_sf_npb_basic_adv_top.apply (
					hdr,
					ig_md,
					ig_intr_md,
					ig_intr_md_from_prsr,
					ig_intr_md_for_dprsr,
					ig_intr_md_for_tm
				);

				// check sp index
				if(ig_md.nsh_extr.si == 0) {
					ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
				}
			}

			// -------------------------------------
			// Forwarding Lookup
			// -------------------------------------

			// table here:

			nbp_ing_sff_table_1.apply();

		}

	}

}
