#include <core.p4>
#include <v1model.p4>

// This program is meant to test correctness of ingress checksum
// computation. It is meant to receive an IPv4 packet. This packet will be
// encapsulated with an MPLS tag in the ingress pipeline and the IPv4 TTL will
// be decremented. The egress parser will stop parsing at the MPLS tag, which
// means that the IPv4 header will be treated as payload during egress
// processing. The egress pipeline will pop the MPLS tag which means that we
// will get a regular IPv4 packet in the end. If the new IPv4 checksum is
// computed correctly by the ingress deparser, this modified IPv4 packet should
// be valid.

// This is a very artificial program which does not do anything sensible
// networking-wise...

const bit<16> ETHERTYPE_MPLS = 0x8847;
const bit<16> ETHERTYPE_IPV4 = 0x0800;

// ---------------------- HEADERS ----------------------

struct metadata_t {
}

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> ethertype;
}

header mpls_t {
    bit<20> label;
    bit<3> tc;
    bit<1> bos;
    bit<8> ttl;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

struct headers_t {
    ethernet_t ethernet;
    mpls_t mpls;
    ipv4_t ipv4;
}

// -------------------- PARSER ------------------------

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta,
                    inout standard_metadata_t standard_metadata) {
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethertype){
            ETHERTYPE_MPLS: parse_mpls;
            ETHERTYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_mpls {
        packet.extract(hdr.mpls);
        transition accept;
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

    state start {
        transition parse_ethernet;
    }
}

// ------------------- CONTROLS ------------------

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
        if (hdr.ipv4.isValid()) {
            hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
            hdr.mpls.setValid();
            // currently broken in P4RuntimeSerializer
            // TODO(antonin): create issue on p4lang/p4c
            // hdr.mpls = {20w666, 3w0, 1w1, 8w64};
            hdr.ethernet.ethertype = ETHERTYPE_MPLS;
            standard_metadata.egress_spec = standard_metadata.ingress_port;
        }
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
        if (hdr.mpls.isValid()) {
            hdr.mpls.setInvalid();
            hdr.ethernet.ethertype = ETHERTYPE_IPV4;
        }
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.mpls);
        packet.emit(hdr.ipv4);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        // Nothing to do
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
        update_checksum(hdr.ipv4.isValid(),
            {
                hdr.ipv4.version,
                hdr.ipv4.ihl,
                hdr.ipv4.diffserv,
                hdr.ipv4.total_len,
                hdr.ipv4.identification,
                hdr.ipv4.flags,
                hdr.ipv4.frag_offset,
                hdr.ipv4.ttl,
                hdr.ipv4.protocol,
                hdr.ipv4.src_addr,
                hdr.ipv4.dst_addr
            },
            hdr.ipv4.hdr_checksum,
            HashAlgorithm.csum16
        );
    }
}
V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
