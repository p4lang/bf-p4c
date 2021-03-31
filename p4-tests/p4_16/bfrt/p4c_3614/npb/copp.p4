#ifndef _P4_COPP_
#define _P4_COPP_

// -----------------------------------------------------------------------------
// Ingress COPP
// -----------------------------------------------------------------------------

control IngressCopp (
	in switch_copp_meter_id_t copp_meter_id,

	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
) {

#ifdef CPU_ENABLE
#ifdef CPU_COPP_INGRESS_ENABLE
	//-------------------------------------------------------------

	Meter<bit<switch_copp_meter_id_width>>(1 << switch_copp_meter_id_width, MeterType_t.PACKETS) copp_meter;

	action meter_index(switch_copp_meter_id_t index) {
		ig_intr_md_for_tm.packet_color = (bit<2>) copp_meter.execute(index);
	}

	//-------------------------------------------------------------

	DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

	action copp_drop() {
		ig_intr_md_for_tm.copy_to_cpu = 1w0;
		copp_stats.count();
	}

	action copp_permit() {
		copp_stats.count();
	}

	table copp {
		key = {
			ig_intr_md_for_tm.packet_color : ternary;
			copp_meter_id : ternary @name("copp_meter_id");
		}

		actions = {
			copp_permit;
			copp_drop;
		}

		const default_action = copp_permit;
		size = (1 << switch_copp_meter_id_width + 1);
		counters = copp_stats;
	}
#endif
#endif

	//-------------------------------------------------------------

	apply {
#ifdef CPU_ENABLE
#ifdef CPU_COPP_INGRESS_ENABLE
		// apply the meter, then process the result
		meter_index(copp_meter_id);
		copp.apply();
#endif
#endif
	}

}

// -----------------------------------------------------------------------------
// Egress COPP
// -----------------------------------------------------------------------------

control EgressCopp (
	in    switch_copp_meter_id_t copp_meter_id,

	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) (
) {

#ifdef CPU_ENABLE
#ifdef CPU_COPP_EGRESS_ENABLE
	switch_pkt_color_t copp_color;

	//-------------------------------------------------------------

	Meter<bit<switch_copp_meter_id_width>>(1 << switch_copp_meter_id_width, MeterType_t.PACKETS) copp_meter;

	action meter_index(switch_copp_meter_id_t index) {
		copp_color = (bit<2>) copp_meter.execute(index);
	}

	//-------------------------------------------------------------

	DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

	action copp_drop() {
		eg_intr_md_for_dprsr.mirror_type = SWITCH_MIRROR_TYPE_INVALID;
		copp_stats.count();
	}

	action copp_permit() {
		copp_stats.count();
	}

	table copp {
		key = {
			copp_color : exact;
			copp_meter_id : exact;
		}

		actions = {
			copp_permit;
			copp_drop;
		}

		const default_action = copp_permit;
		size = (1 << switch_copp_meter_id_width + 1);
		counters = copp_stats;
	}
#endif
#endif

	//-------------------------------------------------------------

	apply {
#ifdef CPU_ENABLE
#ifdef CPU_COPP_EGRESS_ENABLE
		// apply the meter, then process the result
		meter_index(copp_meter_id);
		copp.apply();
#endif
#endif
	}
}

#endif // _P4_COPP_
