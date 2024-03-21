
control npb_egr_sf_proxy_meter (
	inout switch_header_transport_t                   hdr_0,
	inout switch_egress_metadata_t                    eg_md,
	in    egress_intrinsic_metadata_t                 eg_intr_md,
	in    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	bit<8> temp;

	// -----------------------------------------------------------------

	DirectMeter(MeterType_t.BYTES) direct_meter;

	action set_color_direct() {
		// Execute the Direct meter and write the color to the ipv4 header diffserv field
//		hdr_0.ipv4.diffserv = direct_meter.execute();
		temp                 = direct_meter.execute();
	}

	table direct_meter_color {
		key = {
//			hdr_0.ethernet.src_addr : exact;
			eg_md.action_3_meter_id : exact;
		}

		actions = {
			set_color_direct;
		}
		meters = direct_meter;
		size = 1024;
	}

	// -----------------------------------------------------------------

	apply {

		// logic here

		direct_meter_color.apply();

		if(temp == 0) {
			eg_intr_md_for_dprsr.drop_ctl = 0x1;
		}

	}

}
