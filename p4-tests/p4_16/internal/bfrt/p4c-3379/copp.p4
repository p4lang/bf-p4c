#ifndef _P4_COPP_
#define _P4_COPP_

control IngressCopp (
	in bool                   copp_enable,
	in switch_copp_meter_id_t copp_meter_id,

	inout switch_ingress_metadata_t ig_md,
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) (
) {

#ifdef CPU_ENABLE
#ifdef CPU_COPP_INGRESS_ENABLE
	Meter<bit<switch_copp_meter_id_width>>(1 << switch_copp_meter_id_width, MeterType_t.PACKETS) copp_meter;
	DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;

	//-------------------------------------------------------------

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
		if(copp_enable == true) {
			ig_intr_md_for_tm.packet_color = (bit<2>) copp_meter.execute(copp_meter_id);
			copp.apply();
		}
#endif
#endif
	}

}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

control EgressCopp (
	in    bool                   copp_enable,
	in    switch_copp_meter_id_t copp_meter_id,

	inout switch_egress_metadata_t eg_md,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr
) (
) {

#ifdef CPU_ENABLE
#ifdef CPU_COPP_EGRESS_ENABLE
	Meter<bit<switch_copp_meter_id_width>>(1 << switch_copp_meter_id_width, MeterType_t.PACKETS) copp_meter;
	DirectCounter<bit<32>>(CounterType_t.PACKETS) copp_stats;
	switch_pkt_color_t copp_color;

	//-------------------------------------------------------------

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
		if(copp_enable == true) {
			copp_color = (bit<2>) copp_meter.execute(copp_meter_id);
			copp.apply();
		}
#endif
#endif
	}
}

#endif // _P4_COPP_
