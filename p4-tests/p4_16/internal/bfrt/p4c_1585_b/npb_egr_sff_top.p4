#include "npb_egr_sf_proxy_top.p4"

control npb_egr_sff_top (
	inout switch_header_t                             hdr,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	// =========================================================================
	// Table
	// =========================================================================

    action new_ttl(bit<6> ttl) {
        hdr.nsh_extr_underlay.ttl = ttl;
    }

    action discard() {
        eg_intr_md_for_dprsr.drop_ctl = 1;
    }

    table npb_egr_sff_dec_ttl {
        key = { hdr.nsh_extr_underlay.ttl : exact; }
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

	// =========================================================================
	// Apply
	// =========================================================================

	apply {

		// -----------------------------------------------------------------------------
		// Get the nsh header squared away
		// -----------------------------------------------------------------------------

		// **** Write common fields that come across in the metadata to the nsh header ****

		// Note: do this here and not in the first state of the parser, because they will
		// get overwritten in the parser if the packet already has an nsh header on it.

        // base: word 0
		// (nothing to do)

        // base: word 1
        hdr.nsh_extr_underlay.spi                      = eg_md.nsh_extr.spi;
        hdr.nsh_extr_underlay.si                       = eg_md.nsh_extr.si;

        // ext: type 2 - word 0
		// (nothing to do)

        // ext: type 2 - word 1+
        hdr.nsh_extr_underlay.extr_srvc_func_bitmask   = eg_md.nsh_extr.extr_srvc_func_bitmask_remote; //  1 byte
        hdr.nsh_extr_underlay.extr_tenant_id           = eg_md.nsh_extr.extr_tenant_id;                //  3 bytes
        hdr.nsh_extr_underlay.extr_flow_type           = eg_md.nsh_extr.extr_flow_type;                //  1 byte?

		// ----------------------------------------

		if(hdr.nsh_extr_underlay.isValid()) {
			// ----------------------------------------
			// Packet already has an NSH header on it
			// ----------------------------------------

			npb_egr_sff_dec_ttl.apply();

		} else {
			// ----------------------------------------
			// Packet needs an NSH header put on it
			// ----------------------------------------

			if(eg_md.nsh_extr.valid == 1) {
					hdr.nsh_extr_underlay.setValid();
			}

			// base: word 0
			hdr.nsh_extr_underlay.version                  = 0x0;
			hdr.nsh_extr_underlay.o                        = 0x0;
			hdr.nsh_extr_underlay.reserved                 = 0x0;
			hdr.nsh_extr_underlay.ttl                      = 0x0;
			hdr.nsh_extr_underlay.len                      = 0x5; // in 4-byte words
			hdr.nsh_extr_underlay.reserved2                = 0x0;
			hdr.nsh_extr_underlay.md_type                  = 0x2;
			hdr.nsh_extr_underlay.next_proto               = 0x3;

			// base: word 1
			// (nothing to do -- these fields get set in the parser from the bridged metadata)

			// ext: type 2 - word 0
			hdr.nsh_extr_underlay.md_class                 = 0x0;
			hdr.nsh_extr_underlay.type                     = 0x0;
			hdr.nsh_extr_underlay.reserved3                = 0x0;
			hdr.nsh_extr_underlay.md_len                   = 0x8;

			// ext: type 2 - word 1+
			// (nothing to do -- these fields get set in the parser from the bridged metadata)
#if NSH_RSVD_WIDTH>0
			hdr.nsh_extr_underlay.extr_rsvd                = 0x0;
#endif
		}

		// ----------------------------

		// Regardless if the packet already had an nsh header on it or we added one,
		// invalidate it if we're at the end of the chain....
		if(eg_md.nsh_extr.end_of_chain == 1) {
			hdr.nsh_extr_underlay.setInvalid();
		}

		// -----------------------------------------------------------------------------
		// Do some work
		// -----------------------------------------------------------------------------

		if(eg_md.nsh_extr.valid == 1) {

			// -------------------------------------
			// SF(s)
			// -------------------------------------

			if(eg_md.nsh_extr.extr_srvc_func_bitmask_local[2:2] == 1) {

				// -------------------------------------
				// SF #0
				// -------------------------------------

				npb_egr_sf_proxy_top.apply (
					hdr,
					eg_md,
					eg_intr_md,
					eg_intr_md_from_prsr,
					eg_intr_md_for_dprsr,
					eg_intr_md_for_oport
				);

				// DON"T NEED TO DO THIS.  THE PROXY DELETES THE NSH HEADER SO THERES NO POINT IN CHECKING.
				// check sp index
//				if(eg_md.nsh_extr_underlay.si == 0) {
//					eg_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//				}

			} else {
				eg_md.action_bitmask = 0;
			}

		} else {
			eg_md.action_bitmask = 0;
		}

	}

}
