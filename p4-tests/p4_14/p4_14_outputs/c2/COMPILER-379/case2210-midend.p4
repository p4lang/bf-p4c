header hdr_t_1 {
    bit<32> useless;
}

#include <core.p4>
#include <v1model.p4>

header hdr_t {
    bit<32>     useless;
    @length((useless << 1 << 3) + 32w4294967264) 
    varbit<448> opts;
}

struct metadata {
}

struct headers {
    @name(".hdr") 
    hdr_t hdr;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    hdr_t_1 tmp_hdr_0;
    hdr_t_1 tmp;
    bit<32> tmp_0;
    @name(".start") state start {
        tmp_0 = packet.lookahead<bit<32>>();
        tmp.setValid();
        tmp.useless = tmp_0[31:0];
        tmp_hdr_0 = tmp;
        packet.extract<hdr_t>(hdr.hdr, (tmp_hdr_0.useless << 1 << 3) + 32w4294967264);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".NoAction") action NoAction_0() {
    }
    @name("._nop") action _nop() {
    }
    @name(".tlpm") table tlpm_0 {
        actions = {
            _nop();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.hdr.useless: lpm @name("hdr.useless") ;
        }
        default_action = NoAction_0();
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

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch<headers, metadata>(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

