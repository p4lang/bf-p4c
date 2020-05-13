#include <core.p4>
#include <v1model.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ether_type;
}

struct my_headers_t {
    ethernet_t ethernet;
}

typedef my_headers_t headers_t;
struct local_metadata_t {
    bit<16> f16;
    bit<16> m16;
    bit<16> d16;
}

parser parser_impl(packet_in packet, out headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    state start {
        transition accept;
    }
}

control ingress_impl(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control egress_impl(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
        local_metadata.f16 = (bit<16>)(standard_metadata.packet_length + 32w4294967282);
        local_metadata.m16 = (bit<16>)(standard_metadata.packet_length << 1);
        local_metadata.d16 = (bit<16>)(standard_metadata.packet_length >> 1);
    }
}

control verify_checksum_impl(inout headers_t hdr, inout local_metadata_t local_metadata) {
    apply {
    }
}

control compute_checksum_impl(inout headers_t hdr, inout local_metadata_t local_metadata) {
    apply {
    }
}

control deparser_impl(packet_out packet, in headers_t hdr) {
    apply {
    }
}

V1Switch<my_headers_t, local_metadata_t>(parser_impl(), verify_checksum_impl(), ingress_impl(), egress_impl(), compute_checksum_impl(), deparser_impl()) main;
