#include <core.p4>
#include <tofino.p4>

struct tuple_0 {
    bit<8> field;
    bit<8> field_0;
    bit<8> field_1;
    bit<8> field_2;
    bit<8> field_3;
    bit<8> field_4;
    bit<8> field_5;
    bit<8> field_6;
    bit<8> field_7;
    bit<8> field_8;
    bit<8> field_9;
    bit<8> field_10;
    bit<8> field_11;
    bit<8> field_12;
    bit<8> field_13;
    bit<8> field_14;
}
#include <tna.p4>

header MemcachedHdr_t {
    bit<8>  magic;
    bit<8>  opcode;
    bit<16> keyLen;
    bit<8>  extrasLen;
    bit<8>  dataType;
    bit<16> vBucketIdOrStatus;
    bit<32> totalBodyLen;
    bit<32> opaque;
    bit<64> CAS;
}

header MemachedExtras_t {
    bit<32> flags;
}

header MemcachedFixedSizeKey_t {
    bit<128> key;
}

struct headers_t {
    MemcachedHdr_t          memcached_hdr;
    MemachedExtras_t        memcached_extras;
    MemcachedFixedSizeKey_t memcached_fixed_size_key;
}

struct metadata_t {
}

parser MemcachedIngressParser(packet_in pkt, out headers_t hdr, out metadata_t meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    MemcachedHdr_t hdr_0_memcached_hdr;
    MemachedExtras_t hdr_0_memcached_extras;
    MemcachedFixedSizeKey_t hdr_0_memcached_fixed_size_key;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w1: parse_resubmit;
            1w0: parse_port_metadata;
            default: noMatch;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        hdr_0_memcached_hdr.setInvalid();
        hdr_0_memcached_extras.setInvalid();
        hdr_0_memcached_fixed_size_key.setInvalid();
        pkt.extract<MemcachedHdr_t>(hdr_0_memcached_hdr);
        transition select(hdr_0_memcached_hdr.magic) {
            8w0x80: MemcachedCommonParser_parse_memcached_req;
            default: parse_port_metadata_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_req {
        transition select(hdr_0_memcached_hdr.opcode) {
            8w0x0: MemcachedCommonParser_parse_memcached_key;
            8w0x1: MemcachedCommonParser_parse_memcached_extras;
            8w0x2: MemcachedCommonParser_parse_memcached_extras;
            8w0x3: MemcachedCommonParser_parse_memcached_extras;
            8w0x4: MemcachedCommonParser_parse_memcached_key;
            default: parse_port_metadata_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key {
        transition select(hdr_0_memcached_hdr.keyLen) {
            16w16: MemcachedCommonParser_parse_memcached_key_16B;
            default: parse_port_metadata_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key_16B {
        pkt.extract<MemcachedFixedSizeKey_t>(hdr_0_memcached_fixed_size_key);
        transition parse_port_metadata_0;
    }
    state MemcachedCommonParser_parse_memcached_extras {
        pkt.extract<MemachedExtras_t>(hdr_0_memcached_extras);
        transition parse_port_metadata_0;
    }
    state parse_port_metadata_0 {
        hdr.memcached_hdr = hdr_0_memcached_hdr;
        hdr.memcached_extras = hdr_0_memcached_extras;
        hdr.memcached_fixed_size_key = hdr_0_memcached_fixed_size_key;
        transition accept;
    }
    state noMatch {
        verify(false, error.NoMatch);
        transition reject;
    }
}

parser MemcachedEgressParser(packet_in pkt, out headers_t hdr, out metadata_t meta, out egress_intrinsic_metadata_t eg_intr_md) {
    MemcachedHdr_t hdr_1_memcached_hdr;
    MemachedExtras_t hdr_1_memcached_extras;
    MemcachedFixedSizeKey_t hdr_1_memcached_fixed_size_key;
    state start {
        hdr_1_memcached_hdr.setInvalid();
        hdr_1_memcached_extras.setInvalid();
        hdr_1_memcached_fixed_size_key.setInvalid();
        pkt.extract<MemcachedHdr_t>(hdr_1_memcached_hdr);
        transition select(hdr_1_memcached_hdr.magic) {
            8w0x80: MemcachedCommonParser_parse_memcached_req_0;
            default: start_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_req_0 {
        transition select(hdr_1_memcached_hdr.opcode) {
            8w0x0: MemcachedCommonParser_parse_memcached_key_0;
            8w0x1: MemcachedCommonParser_parse_memcached_extras_0;
            8w0x2: MemcachedCommonParser_parse_memcached_extras_0;
            8w0x3: MemcachedCommonParser_parse_memcached_extras_0;
            8w0x4: MemcachedCommonParser_parse_memcached_key_0;
            default: start_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key_0 {
        transition select(hdr_1_memcached_hdr.keyLen) {
            16w16: MemcachedCommonParser_parse_memcached_key_16B_0;
            default: start_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key_16B_0 {
        pkt.extract<MemcachedFixedSizeKey_t>(hdr_1_memcached_fixed_size_key);
        transition start_0;
    }
    state MemcachedCommonParser_parse_memcached_extras_0 {
        pkt.extract<MemachedExtras_t>(hdr_1_memcached_extras);
        transition start_0;
    }
    state start_0 {
        hdr.memcached_hdr = hdr_1_memcached_hdr;
        hdr.memcached_extras = hdr_1_memcached_extras;
        hdr.memcached_fixed_size_key = hdr_1_memcached_fixed_size_key;
        transition accept;
    }
}

control MemcachedEgress(inout headers_t hdr, inout metadata_t meta, in egress_intrinsic_metadata_t eg_intr_md, in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr, inout egress_intrinsic_metadata_for_deparser_t ig_intr_dprs_md, inout egress_intrinsic_metadata_for_output_port_t eg_intr_oport_md) {
    apply {
    }
}

control MemcachedIngress(inout headers_t hdr, inout metadata_t ig_md, in ingress_intrinsic_metadata_t ig_intr_md, in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md, inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md, inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {
    apply {
    }
}

control MemcachedIngressDeparser(packet_out pkt, inout headers_t hdr, in metadata_t ig_md, in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {
    apply {
    }
}

control MemcachedEgressDeparser(packet_out pkt, inout headers_t hdr, in metadata_t eg_md, in egress_intrinsic_metadata_for_deparser_t eg_intr_dprsr_md) {
    apply {
    }
}

Pipeline<headers_t, metadata_t, headers_t, metadata_t>(MemcachedIngressParser(), MemcachedIngress(), MemcachedIngressDeparser(), MemcachedEgressParser(), MemcachedEgress(), MemcachedEgressDeparser()) pipe0;

Switch<headers_t, metadata_t, headers_t, metadata_t, _, _, _, _, _, _, _, _, _, _, _, _>(pipe0) main;

