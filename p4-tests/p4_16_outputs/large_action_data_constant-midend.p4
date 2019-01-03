#include <core.p4>
#include <v1model.p4>

struct metadata_t {
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header my_hdr_t {
    bit<7> f1;
    bit<9> f2;
}

struct headers_t {
    ethernet_t ethernet;
    @pa_container_size("ingress" , "my_hdr.f2" , 16) 
    my_hdr_t   my_hdr;
}

parser ParserImpl(packet_in packet, out headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        packet.extract<my_hdr_t>(hdr.my_hdr);
        transition accept;
    }
}

control ingress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    @name("ingress.set_f2_hit") action set_f2_hit(bit<9> v) {
        standard_metadata.egress_spec = standard_metadata.ingress_port;
        hdr.my_hdr.f2 = v;
    }
    @name("ingress.set_f2_miss") action set_f2_miss() {
        standard_metadata.egress_spec = standard_metadata.ingress_port;
        hdr.my_hdr.f2 = 9w199;
    }
    @name("ingress.t") table t_0 {
        key = {
            hdr.my_hdr.f1: exact @name("hdr.my_hdr.f1") ;
        }
        actions = {
            set_f2_hit();
            set_f2_miss();
        }
        default_action = set_f2_miss();
    }
    apply {
        t_0.apply();
    }
}

control egress(inout headers_t hdr, inout metadata_t meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers_t hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<my_hdr_t>(hdr.my_hdr);
    }
}

control verifyChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

control computeChecksum(inout headers_t hdr, inout metadata_t meta) {
    apply {
    }
}

V1Switch<headers_t, metadata_t>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

