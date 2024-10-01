#include <core.p4>
#include <v1model.p4>

typedef bit<48> EthernetAddress;
header ethernet_t {
    EthernetAddress dst_addr;
    EthernetAddress src_addr;
    bit<16>         ether_type;
}

struct my_headers_t {
    ethernet_t ethernet;
}

typedef my_headers_t headers_t;
struct local_metadata_t {
    bit<9> f;
}

parser parser_impl(packet_in packet, out headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    state start {
        local_metadata.f[1:1] = 0x1;
        transition accept;
    }
}

control ingress_impl(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
        standard_metadata.egress_spec = local_metadata.f;
    }
}

control egress_impl(inout headers_t hdr, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
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

V1Switch(parser_impl(), verify_checksum_impl(), ingress_impl(), egress_impl(), compute_checksum_impl(), deparser_impl()) main;

