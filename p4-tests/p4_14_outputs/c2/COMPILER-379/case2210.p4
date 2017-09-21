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
    @length((bit<32>)useless * 32w2 * 8 - 32) 
    varbit<448> opts;
}

struct metadata {
}

struct headers {
    @name(".hdr") 
    hdr_t hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    hdr_t_1 tmp_hdr;
    hdr_t_2 tmp_hdr_0;
    @name(".start") state start {
        packet.extract(tmp_hdr);
        packet.extract(tmp_hdr_0, (bit<32>)((bit<32>)tmp_hdr.useless * 32w2 * 8 - 32));
        hdr.hdr.setValid();
        hdr.hdr.useless = tmp_hdr.useless;
        hdr.hdr.opts = tmp_hdr_0.opts;
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("._nop") action _nop() {
        ;
    }
    @name(".tlpm") table tlpm {
        actions = {
            _nop;
        }
        key = {
            hdr.hdr.useless: lpm;
        }
    }
    apply {
        tlpm.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.hdr);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
