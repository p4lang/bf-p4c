#include <core.p4>
#include <v1model.p4>

@name("accessed") header accessed_0 {
    bit<16> precedence;
    bit<8>  reluctant;
    bit<8>  carmelos;
}

header tympanums {
    bit<32> vergers;
    bit<16> seesawing;
    bit<16> tycoons;
}

struct metadata {
}

struct headers {
    @name(".expounded") 
    accessed_0 expounded;
    @name(".zoe") 
    tympanums  zoe;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract(hdr.expounded);
        packet.extract(hdr.zoe);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".stick") action stick() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".clickers") table clickers {
        actions = {
            stick;
        }
        key = {
            hdr.zoe.seesawing      : range;
            hdr.expounded.reluctant: exact;
            hdr.expounded.carmelos : ternary;
        }
    }
    @name(".parenthesised") table parenthesised {
        actions = {
            stick;
        }
    }
    @name(".spanishs") table spanishs {
        actions = {
            stick;
        }
        key = {
            hdr.zoe.isValid()     : exact;
            hdr.zoe.seesawing[5:4]: ternary @name("zoe.seesawing") ;
        }
    }
    apply {
        parenthesised.apply();
        if (hdr.expounded.isValid() && 8w0 > hdr.expounded.carmelos) {
            clickers.apply();
        }
        if (hdr.zoe.tycoons < 16w4) {
            spanishs.apply();
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.expounded);
        packet.emit(hdr.zoe);
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

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;

