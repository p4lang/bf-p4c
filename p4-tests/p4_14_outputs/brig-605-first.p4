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
        packet.extract<accessed_0>(hdr.expounded);
        packet.extract<tympanums>(hdr.zoe);
        transition accept;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".stick") action stick() {
        standard_metadata.egress_spec = 9w1;
    }
    @name(".clickers") table clickers {
        actions = {
            stick();
            @defaultonly NoAction();
        }
        key = {
            hdr.zoe.seesawing      : range @name("zoe.seesawing") ;
            hdr.expounded.reluctant: exact @name("expounded.reluctant") ;
            hdr.expounded.carmelos : ternary @name("expounded.carmelos") ;
        }
        default_action = NoAction();
    }
    @name(".parenthesised") table parenthesised {
        actions = {
            stick();
            @defaultonly NoAction();
        }
        default_action = NoAction();
    }
    @name(".spanishs") table spanishs {
        actions = {
            stick();
            @defaultonly NoAction();
        }
        key = {
            hdr.zoe.isValid()     : exact @name("zoe.$valid$") ;
            hdr.zoe.seesawing[5:4]: ternary @name("zoe.seesawing") ;
        }
        default_action = NoAction();
    }
    apply {
        parenthesised.apply();
        if (hdr.expounded.isValid() && 8w0 > hdr.expounded.carmelos) 
            clickers.apply();
        if (hdr.zoe.tycoons < 16w4) 
            spanishs.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<accessed_0>(hdr.expounded);
        packet.emit<tympanums>(hdr.zoe);
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

