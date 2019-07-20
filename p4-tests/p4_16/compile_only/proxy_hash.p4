#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

struct compiler_generated_metadata_t {
    bit<10> mirror_id;
    bit<8>  mirror_source;
    bit<4>  clone_src;
    bit<4>  clone_digest_id;
    bit<32> instance_type;
}

struct standard_metadata_t {
    bit<9>  ingress_port;
    bit<32> packet_length;
    bit<9>  egress_spec;
    bit<9>  egress_port;
    bit<16> egress_instance;
    bit<32> instance_type;
    bit<8>  parser_status;
    bit<8>  parser_error_location;
}

header bridged_header_t {
    bit<8> bridged_metadata_indicator;
}

@name("generator_metadata_t") header generator_metadata_t_0 {
    bit<16> app_id;
    bit<16> batch_id;
    bit<16> instance_id;
}

header pkt_t {
    bit<32>  field_a_32;
    bit<32>  field_b_32;
    bit<32>  field_c_32;
    bit<32>  field_d_32;
    bit<16>  field_e_16;
    bit<16>  field_f_16;
    bit<16>  field_g_16;
    bit<16>  field_h_16;
    bit<8>   field_i_8;
    bit<8>   field_j_8;
    bit<8>   color_0;
    bit<24>  pad_0;
    bit<160> pad_1;
    bit<24>  pad_2;
    bit<8>   color_1;
    bit<24>  pad_3;
    bit<16>  lpf;
}

struct metadata {
    @name(".compiler_generated_meta")
    compiler_generated_metadata_t               compiler_generated_meta;
    @name(".eg_intr_md")
    egress_intrinsic_metadata_t                 eg_intr_md;
    @name(".eg_intr_md_for_dprsr")
    egress_intrinsic_metadata_for_deparser_t    eg_intr_md_for_dprsr;
    @name(".eg_intr_md_for_oport")
    egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport;
    @name(".eg_intr_md_from_parser_aux")
    egress_intrinsic_metadata_from_parser_t     eg_intr_md_from_parser_aux;
    @name(".ig_intr_md")
    ingress_intrinsic_metadata_t                ig_intr_md;
    @name(".ig_intr_md_for_tm")
    ingress_intrinsic_metadata_for_tm_t         ig_intr_md_for_tm;
    @name(".ig_intr_md_from_parser_aux")
    ingress_intrinsic_metadata_from_parser_t    ig_intr_md_from_parser_aux;
    @name(".standard_metadata")
    standard_metadata_t                         standard_metadata;
}

struct headers {
    @name(".bridged_header")
    bridged_header_t bridged_header;
    @name(".pkt")
    pkt_t            pkt;
}

parser IngressParserImpl(packet_in pkt, out headers hdr, out metadata meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    @name(".parse_ethernet") state parse_ethernet {
        pkt.extract(hdr.pkt);
        transition accept;
    }
    @name(".start") state __ingress_p4_entry_point {
        transition parse_ethernet;
    }
    @name("$skip_to_packet") state __skip_to_packet {
        pkt.advance(32w0);
        transition __ingress_p4_entry_point;
    }
    @name("$check_resubmit") state __check_resubmit {
        pkt.advance(32w64);
        transition __skip_to_packet;
    }
    @name("$ingress_metadata") state __ingress_metadata {
        pkt.extract(ig_intr_md);
        hdr.bridged_header.bridged_metadata_indicator = 8w0;
        hdr.bridged_header.setValid();
        transition __check_resubmit;
    }
    @name("$ingress_tna_entry_point") state start {
        transition __ingress_metadata;
    }
}

parser EgressParserImpl(packet_in pkt, out headers hdr, out metadata meta, out egress_intrinsic_metadata_t eg_intr_md) {
    @name(".parse_ethernet") state parse_ethernet {
        pkt.extract(hdr.pkt);
        transition accept;
    }
    @name(".start") state __egress_p4_entry_point {
        transition parse_ethernet;
    }
    @name("$bridged_metadata") state __bridged_metadata {
        pkt.advance(32w8);
        transition __egress_p4_entry_point;
    }
    @name("$mirrored") state __mirrored {
        transition select(pkt.lookahead<bit<8>>()) {
        }
    }
    @name("$check_mirrored") state __check_mirrored {
        transition select(pkt.lookahead<bit<8>>()) {
            8w0 &&& 8w8: __bridged_metadata;
            8w8 &&& 8w8: __mirrored;
        }
    }
    @name("$egress_metadata") state __egress_metadata {
        pkt.extract(eg_intr_md);
        transition __check_mirrored;
    }
    @name("$egress_tna_entry_point") state start {
        transition __egress_metadata;
    }
}

control ingress(inout headers hdr, inout metadata meta, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_parser_aux, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr, inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm) {
    @name(".action_0") action action_0(bit<32> param0, bit<16> param1) {
        hdr.pkt.field_c_32 = param0;
        hdr.pkt.field_g_16 = param1;
    }
    @name(".action_1") action action_1() {
        ig_intr_md_for_dprsr.drop_ctl = 3w1;
    }
    @name(".table_0") table table_0 {
        actions = {
            action_0;
            action_1;
        }
        key = {
            hdr.pkt.field_a_32: exact;
            hdr.pkt.field_b_32: exact;
            hdr.pkt.field_e_16: exact;
            hdr.pkt.field_f_16: exact;
        }
        size = 16384;
        proxy_hash = Hash<bit<24>>(HashAlgorithm_t.CRC16);
    }
    apply {
        table_0.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_parser_aux, inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr, inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {
    apply {
    }
}

control IngressDeparserImpl(packet_out pkt, inout headers hdr, in metadata meta, in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.bridged_header);
        pkt.emit(hdr.pkt);
    }
}

control EgressDeparserImpl(packet_out pkt, inout headers hdr, in metadata meta, in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr) {
    apply {
        pkt.emit(hdr.pkt);
    }
}

Pipeline(IngressParserImpl(), ingress(), IngressDeparserImpl(), EgressParserImpl(), egress(), EgressDeparserImpl()) pipe;

Switch(pipe) main;

