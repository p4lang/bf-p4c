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

#include <core.p4>
#if __TARGET_TOFINO__ == 2
  #include <t2na.p4>
#else
  #include <tna.p4>
#endif

typedef bit<48> mac_addr_t;

header ethernet_h {
    mac_addr_t dst_addr;
    mac_addr_t src_addr;
    bit<16>    ether_type;
}

// TEST: Empty port metadata struct to be used with the port_metadata_unpack extern
struct port_metadata_t {
	// bit<8> b1;
}

struct ingress_metadata_t {
}

struct egress_metadata_t {
}

struct header_t {
	ethernet_h ethernet;
}

parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);

        transition parse_port_metadata;
    }

    state parse_port_metadata {
        // TEST: Use the port_metadata_unpack extern with an empty port metadata struct instead of
		// pkt.advance(PORT_METADATA_SIZE);
        port_metadata_t port_md = port_metadata_unpack<port_metadata_t>(pkt);

        transition parse_transport_ethernet;
    }

    state parse_transport_ethernet {
		pkt.extract(hdr.ethernet);

        transition accept;
    }
}

control SwitchIngress(
	inout header_t hdr,
	inout ingress_metadata_t ig_md,
	in ingress_intrinsic_metadata_t ig_intr_md,
	in ingress_intrinsic_metadata_from_parser_t ig_intr_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm
) {

	action dst_mac_check_err() {
        ig_intr_md_for_dprsr.drop_ctl = 1;
    }

    action dst_mac_check_ok() {
        ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
        hdr.ethernet.ether_type = 0xABCD;
    }

    table dst_mac_check {
        key = {
            hdr.ethernet.dst_addr : ternary;
        }
        actions = {
            dst_mac_check_ok;
            dst_mac_check_err;
        }
        size = 1;
        const default_action = dst_mac_check_err();
        const entries = {
            (0x5162738495A6 &&& 0xFFFFFFFFFFFF) : dst_mac_check_ok();
        }
    }

	apply {
		if (hdr.ethernet.isValid()) {
			dst_mac_check.apply();
		} else {
			dst_mac_check_err();
		}
	}
}

control SwitchIngressDeparser(
    packet_out pkt,
    inout header_t hdr,
    in ingress_metadata_t ig_md,
    in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {

    apply {
		pkt.emit(hdr);
    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

parser SwitchEgressParser(
        packet_in pkt,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        transition accept;
    }
}

control SwitchEgress(
	inout header_t hdr,
	inout egress_metadata_t eg_md,
	in egress_intrinsic_metadata_t eg_intr_md,
	in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
	inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
	inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport
) {

	apply {
	}
}

control SwitchEgressDeparser(
        packet_out pkt,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {

    apply {
    }
}

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

Pipeline(
        SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;

Switch(pipe) main;
