#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

enum bit<8> MemcachedOpcode {
    Get = 8w0x0,
    Set = 8w0x1,
    Add = 8w0x2,
    Replace = 8w0x3,
    Delete = 8w0x4
}

header MemcachedHdr_t {
    bit<8>          magic;
    MemcachedOpcode opcode;
    bit<16>         keyLen;
    bit<8>          extrasLen;
    bit<8>          dataType;
    bit<16>         vBucketIdOrStatus;
    bit<32>         totalBodyLen;
    bit<32>         opaque;
    bit<64>         CAS;
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
    headers_t hdr_0;
    state start {
        pkt.extract<ingress_intrinsic_metadata_t>(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1w1: parse_resubmit;
            1w0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(32w64);
        hdr_0.memcached_hdr.setInvalid();
        hdr_0.memcached_extras.setInvalid();
        hdr_0.memcached_fixed_size_key.setInvalid();
        transition MemcachedCommonParser_start;
    }
    state MemcachedCommonParser_start {
        pkt.extract<MemcachedHdr_t>(hdr_0.memcached_hdr);
        transition select(hdr_0.memcached_hdr.magic) {
            8w0x80: MemcachedCommonParser_parse_memcached_req;
            default: parse_port_metadata_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_req {
        transition select(hdr_0.memcached_hdr.opcode) {
            MemcachedOpcode.Get: MemcachedCommonParser_parse_memcached_key;
            MemcachedOpcode.Set: MemcachedCommonParser_parse_memcached_extras;
            MemcachedOpcode.Add: MemcachedCommonParser_parse_memcached_extras;
            MemcachedOpcode.Replace: MemcachedCommonParser_parse_memcached_extras;
            MemcachedOpcode.Delete: MemcachedCommonParser_parse_memcached_key;
            default: parse_port_metadata_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key {
        transition select(hdr_0.memcached_hdr.keyLen) {
            16w16: MemcachedCommonParser_parse_memcached_key_16B;
            default: parse_port_metadata_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key_16B {
        pkt.extract<MemcachedFixedSizeKey_t>(hdr_0.memcached_fixed_size_key);
        transition parse_port_metadata_0;
    }
    state MemcachedCommonParser_parse_memcached_extras {
        pkt.extract<MemachedExtras_t>(hdr_0.memcached_extras);
        transition parse_port_metadata_0;
    }
    state parse_port_metadata_0 {
        hdr = hdr_0;
        transition accept;
    }
}

parser MemcachedEgressParser(packet_in pkt, out headers_t hdr, out metadata_t meta, out egress_intrinsic_metadata_t eg_intr_md) {
    headers_t hdr_1;
    state start {
        hdr_1.memcached_hdr.setInvalid();
        hdr_1.memcached_extras.setInvalid();
        hdr_1.memcached_fixed_size_key.setInvalid();
        transition MemcachedCommonParser_start_0;
    }
    state MemcachedCommonParser_start_0 {
        pkt.extract<MemcachedHdr_t>(hdr_1.memcached_hdr);
        transition select(hdr_1.memcached_hdr.magic) {
            8w0x80: MemcachedCommonParser_parse_memcached_req_0;
            default: start_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_req_0 {
        transition select(hdr_1.memcached_hdr.opcode) {
            MemcachedOpcode.Get: MemcachedCommonParser_parse_memcached_key_0;
            MemcachedOpcode.Set: MemcachedCommonParser_parse_memcached_extras_0;
            MemcachedOpcode.Add: MemcachedCommonParser_parse_memcached_extras_0;
            MemcachedOpcode.Replace: MemcachedCommonParser_parse_memcached_extras_0;
            MemcachedOpcode.Delete: MemcachedCommonParser_parse_memcached_key_0;
            default: start_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key_0 {
        transition select(hdr_1.memcached_hdr.keyLen) {
            16w16: MemcachedCommonParser_parse_memcached_key_16B_0;
            default: start_0;
        }
    }
    state MemcachedCommonParser_parse_memcached_key_16B_0 {
        pkt.extract<MemcachedFixedSizeKey_t>(hdr_1.memcached_fixed_size_key);
        transition start_0;
    }
    state MemcachedCommonParser_parse_memcached_extras_0 {
        pkt.extract<MemachedExtras_t>(hdr_1.memcached_extras);
        transition start_0;
    }
    state start_0 {
        hdr = hdr_1;
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

