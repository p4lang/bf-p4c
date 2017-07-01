header hdr_t_1 {
    bit<32> useless;
}

header hdr_t_2 {
    varbit<448> opts;
}

#include <core.p4>
#include <v1model.p4>

header hdr_t {
    bit<32>     useless;
    @length(useless << 1) 
    varbit<448> opts;
}

struct metadata {
}

struct headers {
    @name("hdr") 
    hdr_t hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    hdr_t_1 tmp_hdr_1;
    hdr_t_2 tmp_hdr_2;
    @name(".start") state start {
        packet.extract<hdr_t_1>(tmp_hdr_1);
        packet.extract<hdr_t_2>(tmp_hdr_2, tmp_hdr_1.useless << 1);
        hdr.hdr.setValid();
        hdr.hdr.useless = tmp_hdr_1.useless;
        hdr.hdr.opts = tmp_hdr_2.opts;
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("._nop") action _nop_0() {
    }
    @name(".tlpm") table tlpm_0 {
        actions = {
            _nop_0();
            @defaultonly NoAction();
        }
        key = {
            hdr.hdr.useless: lpm @name("hdr.hdr.useless") ;
        }
        default_action = NoAction();
    }
    apply {
        tlpm_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<hdr_t>(hdr.hdr);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
