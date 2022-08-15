#ifndef _NPB_EGR_SFF_TOP_
#define _NPB_EGR_SFF_TOP_

control Npb_Egr_Sff_Top (
	inout switch_header_transport_t                   hdr_0,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) (
	MODULE_DEPLOYMENT_PARAMS
) {

	// =========================================================================
	// Table #1: 
	// =========================================================================

	// RFC 8300, Page 9: Decrementing (the TTL) from an incoming value of 0 shall
	// result in a TTL value of 63.   The handling of an incoming 0 TTL allows
	// for better, although not perfect, interoperation with pre-standard
	// implementations that do not support this TTL field.

    action new_ttl(bit<6> ttl) {
        eg_md.nsh_md.ttl = ttl;
    }

    action discard() {
//        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { eg_md.nsh_md.ttl : exact; }
        actions = { new_ttl; discard; }
		size = 64;
        const entries = {
            0  : new_ttl(63);
//          1  : discard();
            1  : new_ttl(0);
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

	// =========================================================================
	// Table #2: SFF - Reformat to slx style, if needed
	// =========================================================================

	DirectCounter<bit<switch_counter_width>>(type=CounterType_t.PACKETS_AND_BYTES) stats;  // direct counter

#ifdef EGRESS_NSH_HDR_VER_1_SUPPORT
	action drop_pkt(
	) {
		stats.count();

  #ifndef BUG_00593238_WORKAROUND
		eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
  #endif
	}

	// =====================================

	action fwd_pkt_nsh_hdr_ver_1(
		bit<SPI_WIDTH> tool_address
	) {
		stats.count();

		// hdr reformat to old type 1 format (slx-style)
		eg_md.nsh_md.spi        = tool_address;
		eg_md.nsh_md.si         = 0x1;

		eg_md.nsh_md.ver        = 0x1;
//		eg_md.nsh_md.reserved3  = 0x0; // not necessary, but allows the design to fit.
	}
#endif
	// =====================================

	action fwd_pkt_nsh_hdr_ver_2(
	) {
		stats.count();

		eg_md.nsh_md.ver        = 0x2;
//		eg_md.nsh_md.reserved3  = 0x0; // not necessary, but allows the design to fit.
	}

	// =====================================
#ifdef EGRESS_NSH_HDR_VER_1_SUPPORT
	table egr_sff_fib {
		key = {
			eg_md.nsh_md.spi     : exact @name("spi");
			eg_md.nsh_md.si      : exact @name("si");
		}

		actions = {
			drop_pkt;
			fwd_pkt_nsh_hdr_ver_1;
			fwd_pkt_nsh_hdr_ver_2;
		}

		// Derek: drop packet on miss...
		//
		// RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
		// do not correspond to a valid next hop in a valid SFP, that packet MUST
		// be dropped by the SFF.

//		const default_action = drop_pkt;
		const default_action = fwd_pkt_nsh_hdr_ver_2; // for backwards compatibility with firmware
		size = NPB_EGR_SFF_ARP_TABLE_DEPTH;
		counters = stats;
	}
#endif

	// =========================================================================
	// Table #3: Add header, if needed
	// =========================================================================

    action end_of_path() {
//		eg_md.nsh_md.setInvalid(); // it's the end of the line for this nsh chain....
    }

	action middle_of_path_drop() {
		eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
	}

	action middle_of_path() {

            // note: according to p4 spec, initializing a header also automatically sets it valid.
//          hdr_0.nsh_type1.setValid();
            hdr_0.nsh_type1 = {
                version    = 0x0,
                o          = 0x0,
                reserved   = 0x0,
                ttl        = (bit<6>)eg_md.nsh_md.ttl, // 63 is the rfc's recommended default value (0 will get dec'ed to 63).
                len        = 0x6,  // in 4-byte words (1 + 1 + 4).
                reserved2  = 0x0,
                md_type    = 0x1,  // 0 = reserved, 1 = fixed len, 2 = variable len.
                next_proto = NSH_PROTOCOLS_ETH, // 1 = ipv4, 2 = ipv6, 3 = ethernet, 4 = nsh, 5 = mpls.

                spi        = (bit<24>)eg_md.nsh_md.spi,
                si         = eg_md.nsh_md.si,

                ver        = eg_md.nsh_md.ver,
                reserved3  = 0x0,
#ifdef LAG_HASH_IN_NSH_HDR_ENABLE
//				lag_hash   = eg_md.hash[switch_hash_width-1:switch_hash_width/2],
				lag_hash   = eg_md.hash[31:16],
#else
                lag_hash   = 0x0,
#endif

                vpn        = (bit<16>)eg_md.nsh_md.vpn,
                sfc_data   = 0x0,

                reserved4  = 0x0,
                scope      = (bit<8>)eg_md.nsh_md.scope,
                sap        = (bit<16>)eg_md.nsh_md.sap,

#ifdef SFC_TIMESTAMP_ENABLE
                timestamp = eg_md.egress_timestamp[31:0]
#else
                timestamp = 0
#endif
			};
	}

    table npb_egr_sff_final {
        key = {
			eg_md.nsh_md.end_of_path : exact;
			eg_md.nsh_md.ttl : ternary;
			eg_md.nsh_md.si : ternary;
		}
        actions = { end_of_path; middle_of_path_drop; middle_of_path; }
		default_action = middle_of_path;
        const entries = {
            (true,  _,     _    )  : end_of_path;
            (false, 0,     _    )  : middle_of_path_drop;
            (false, _,     0    )  : middle_of_path_drop;
		}
	}

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// =============================
		// SFF (continued)
		// =============================

		// -------------------------------------
		// Check TTL & SI
		// -------------------------------------

		// RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
		// will discard any NSH packet with an SI of 0, as there will be no
		// valid next SF information."

		npb_egr_sff_dec_ttl.apply();

		// -------------------------------------
		// Fowrarding Lookup
		// -------------------------------------

		// Derek: The forwarding lookup would normally
		// be done here.  However, since Tofino requires the outport
		// to set in ingress, it has to be done there instead....
  #ifdef EGRESS_NSH_HDR_VER_1_SUPPORT
		egr_sff_fib.apply();
  #else
		fwd_pkt_nsh_hdr_ver_2();
  #endif

		npb_egr_sff_final.apply();
	}

}

#endif /* _NPB_EGR_SFF_TOP_ */
