#include <t3na.p4>

header data8_h {
    bit<8> value;
}

header data16_h {
    bit<16> value;
}

header data32_h {
    bit<32> value;
}

struct custom_header_t {
    data8_h  ha;
    data16_h hb;
    data32_h hc;
    data8_h  hd;
    data16_h he;
    data32_h hf;
    data8_h  hg;
    data16_h hh;
    data16_h action_tag;
}

struct custom_metadata_t { }

/**
 * Pipeline a ingress
 */

parser SwitchIngressParser_a(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_a;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition parse_select;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.ha.value) {
            1: parse_b;
            2: parse_c;
            3: parse_d;
            4: parse_e;
            5: parse_f;
            6: parse_g;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_a(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.ha.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 111;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hc.value : exact; }
        actions = { encap_tag; }
        size = 1111111;
    }

    apply {
        if (hdr.ha.isValid()) {
            send_table.apply();
        }
        if (hdr.hc.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_a(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline b ingress
 */

parser SwitchIngressParser_b(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_b;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition parse_select;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.hb.value) {
            1: parse_a;
            2: parse_c;
            3: parse_d;
            4: parse_e;
            5: parse_f;
            6: parse_g;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_b(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.hb.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 22222;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.ha.value : exact; }
        actions = { encap_tag; }
        size = 222;
    }

    apply {
        if (hdr.hb.isValid()) {
            send_table.apply();
        }
        if (hdr.ha.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_b(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline c ingress
 */

parser SwitchIngressParser_c(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_c;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition parse_select;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.hc.value) {
            1: parse_a;
            2: parse_b;
            3: parse_d;
            4: parse_e;
            5: parse_f;
            6: parse_g;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_c(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.hc.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 333333;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hb.value : exact; }
        actions = { encap_tag; }
        size = 33333;
    }

    apply {
        if (hdr.hc.isValid()) {
            send_table.apply();
        }
        if (hdr.hb.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_c(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline d ingress
 */

parser SwitchIngressParser_d(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_d;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition parse_select;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.hd.value) {
            1: parse_a;
            2: parse_b;
            3: parse_c;
            4: parse_e;
            5: parse_f;
            6: parse_g;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_d(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.hd.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 44;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hb.value : exact; }
        actions = { encap_tag; }
        size = 4444;
    }

    apply {
        if (hdr.hd.isValid()) {
            send_table.apply();
        }
        if (hdr.hb.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_d(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline e ingress
 */

parser SwitchIngressParser_e(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_e;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition parse_select;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.he.value) {
            1: parse_a;
            2: parse_b;
            3: parse_c;
            4: parse_d;
            5: parse_f;
            6: parse_g;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_e(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.he.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 55555;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hb.value : exact; }
        actions = { encap_tag; }
        size = 55555;
    }

    apply {
        if (hdr.he.isValid()) {
            send_table.apply();
        }
        if (hdr.hb.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_e(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline f ingress
 */

parser SwitchIngressParser_f(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_f;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition parse_select;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.hf.value) {
            1: parse_a;
            2: parse_b;
            3: parse_c;
            4: parse_d;
            5: parse_e;
            6: parse_g;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_f(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.hf.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 666666;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hc.value : exact; }
        actions = { encap_tag; }
        size = 666666;
    }

    apply {
        if (hdr.hf.isValid()) {
            send_table.apply();
        }
        if (hdr.hc.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_f(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline g ingress
 */

parser SwitchIngressParser_g(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_g;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition parse_select;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition accept;
    }

    state parse_select {
        transition select(hdr.hg.value) {
            1: parse_a;
            2: parse_b;
            3: parse_c;
            4: parse_d;
            5: parse_e;
            6: parse_f;
            7: parse_h;
            default: accept;
        }
    }
}

control SwitchIngress_g(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.hg.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 77;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hb.value : exact; }
        actions = { encap_tag; }
        size = 7777;
    }

    apply {
        if (hdr.hg.isValid()) {
            send_table.apply();
        }
        if (hdr.hb.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_g(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

/**
 * Pipeline h ingress
 */

parser SwitchIngressParser_h(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_h;
    }

    state parse_a {
        pkt.extract(hdr.ha);
        transition accept;
    }

    state parse_b {
        pkt.extract(hdr.hb);
        transition accept;
    }

    state parse_c {
        pkt.extract(hdr.hc);
        transition accept;
    }

    state parse_d {
        pkt.extract(hdr.hd);
        transition accept;
    }

    state parse_e {
        pkt.extract(hdr.he);
        transition accept;
    }

    state parse_f {
        pkt.extract(hdr.hf);
        transition accept;
    }

    state parse_g {
        pkt.extract(hdr.hg);
        transition accept;
    }

    state parse_h {
        pkt.extract(hdr.hh);
        transition parse_select;
    }

    state parse_select {
        transition select(hdr.hh.value) {
            1: parse_a;
            2: parse_b;
            3: parse_c;
            4: parse_d;
            5: parse_e;
            6: parse_f;
            7: parse_g;
            default: accept;
        }
    }
}

control SwitchIngress_h(
        inout custom_header_t hdr,
        inout custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    table send_table {
        key = { hdr.hh.value : exact; }
        actions = { send; }
        const default_action = send(0);
        size = 8888;
    }

    action encap_tag(bit<16> tag) {
        hdr.action_tag.setValid();
        hdr.action_tag.value = tag;
    }

    table encap_tag_table {
        key = { hdr.hc.value : exact; }
        actions = { encap_tag; }
        size = 888888;
    }

    apply {
        if (hdr.hh.isValid()) {
            send_table.apply();
        }
        if (hdr.hc.isValid()) {
            encap_tag_table.apply();
        }
    }
}

control SwitchIngressDeparser_h(
        packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {
        pkt.emit(hdr.action_tag);
        pkt.emit(hdr.ha);
        pkt.emit(hdr.hb);
        pkt.emit(hdr.hc);
        pkt.emit(hdr.hd);
        pkt.emit(hdr.he);
        pkt.emit(hdr.hf);
        pkt.emit(hdr.hg);
        pkt.emit(hdr.hh);
    }
}

parser SwitchEgressParser(
        packet_in pkt,
        out custom_header_t hdr,
        out custom_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control SwitchEgress(
    inout custom_header_t hdr,
    inout custom_metadata_t eg_md,
    in egress_intrinsic_metadata_t eg_intr_md,
    in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
    inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprs,
    inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

    apply { }
}

control SwitchEgressDeparser(packet_out pkt,
        inout custom_header_t hdr,
        in custom_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {

    apply { }
}

Pipeline(SwitchIngressParser_a(),
         SwitchIngress_a(),
         SwitchIngressDeparser_a(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_a;

Pipeline(SwitchIngressParser_b(),
         SwitchIngress_b(),
         SwitchIngressDeparser_b(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_b;

Pipeline(SwitchIngressParser_c(),
         SwitchIngress_c(),
         SwitchIngressDeparser_c(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_c;

Pipeline(SwitchIngressParser_d(),
         SwitchIngress_d(),
         SwitchIngressDeparser_d(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_d;

Pipeline(SwitchIngressParser_e(),
         SwitchIngress_e(),
         SwitchIngressDeparser_e(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_e;

Pipeline(SwitchIngressParser_f(),
         SwitchIngress_f(),
         SwitchIngressDeparser_f(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_f;

Pipeline(SwitchIngressParser_g(),
         SwitchIngress_g(),
         SwitchIngressDeparser_g(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_g;

Pipeline(SwitchIngressParser_h(),
         SwitchIngress_h(),
         SwitchIngressDeparser_h(),
         SwitchEgressParser(),
         SwitchEgress(),
         SwitchEgressDeparser()) pipeline_profile_h;

Switch(pipeline_profile_a, pipeline_profile_b,
       pipeline_profile_c, pipeline_profile_d,
       pipeline_profile_e, pipeline_profile_f,
       pipeline_profile_g, pipeline_profile_h) main;