#include <core.p4>
#include <tofino.p4>
#include <tna.p4>

enum bit<8> MemcachedOpcode {
    Get = 0x0,
    Set = 0x1,
    Add = 0x2,
    Replace = 0x3,
    Delete = 0x4
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

const bit<16> MEMCACHED_UDP_PORT = 11211;
const bit<8> MEMCACHED_MAGIC_REQ_CLIENT_TO_SERVER = 0x80;
struct headers_t {
    MemcachedHdr_t          memcached_hdr;
    MemachedExtras_t        memcached_extras;
    MemcachedFixedSizeKey_t memcached_fixed_size_key;
}

struct metadata_t {
}

parser MemcachedCommonParser(packet_in pkt, out headers_t hdr) {
    state start {
        transition parse_memcached;
    }
    state parse_memcached {
        pkt.extract(hdr.memcached_hdr);
        transition select(hdr.memcached_hdr.magic) {
            MEMCACHED_MAGIC_REQ_CLIENT_TO_SERVER: parse_memcached_req;
            default: accept;
        }
    }
    state parse_memcached_req {
        transition select(hdr.memcached_hdr.opcode) {
            MemcachedOpcode.Get: parse_memcached_key;
            MemcachedOpcode.Set: parse_memcached_extras;
            MemcachedOpcode.Add: parse_memcached_extras;
            MemcachedOpcode.Replace: parse_memcached_extras;
            MemcachedOpcode.Delete: parse_memcached_key;
            default: accept;
        }
    }
    state parse_memcached_key {
        transition select(hdr.memcached_hdr.keyLen) {
            16: parse_memcached_key_16B;
            default: accept;
        }
    }
    state parse_memcached_key_16B {
        pkt.extract(hdr.memcached_fixed_size_key);
        transition accept;
    }
    state parse_memcached_extras {
        pkt.extract(hdr.memcached_extras);
        transition accept;
    }
}

parser MemcachedIngressParser(packet_in pkt, out headers_t hdr, out metadata_t meta, out ingress_intrinsic_metadata_t ig_intr_md) {
    MemcachedCommonParser() common_parser;
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1: parse_resubmit;
            0: parse_port_metadata;
        }
    }
    state parse_resubmit {
        transition reject;
    }
    state parse_port_metadata {
        pkt.advance(64);
        transition parse_packet;
    }
    state parse_packet {
        common_parser.apply(pkt, hdr);
        transition accept;
    }
}

parser MemcachedEgressParser(packet_in pkt, out headers_t hdr, out metadata_t meta, out egress_intrinsic_metadata_t eg_intr_md) {
    MemcachedCommonParser() common_parser;
    state start {
        transition parse_bridged_metadata;
    }
    state parse_bridged_metadata {
        transition parse_packet;
    }
    state parse_packet {
        common_parser.apply(pkt, hdr);
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

Pipeline(MemcachedIngressParser(), MemcachedIngress(), MemcachedIngressDeparser(), MemcachedEgressParser(), MemcachedEgress(), MemcachedEgressDeparser()) pipe0;

Switch(pipe0) main;

