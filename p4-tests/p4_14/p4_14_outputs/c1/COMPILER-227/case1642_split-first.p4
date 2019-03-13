#include <core.p4>
#include <v1model.p4>

@name("XHdr1") header XHdr1_0 {
    bit<24> f1;
}

@name("XHdr2") header XHdr2_0 {
    bit<16> f2;
}

struct metadata {
}

struct headers {
    @name(".x1") 
    XHdr1_0 x1;
    @name(".x2") 
    XHdr2_0 x2;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parseBar") state parseBar {
        transition accept;
    }
    @name(".parseFoo") state parseFoo {
        packet.extract<XHdr2_0>(hdr.x2);
        transition select(hdr.x2.f2) {
            16w0x3: parseBar;
            default: accept;
        }
    }
    @name(".parseFooBar") state parseFooBar {
        transition accept;
    }
    @name(".parseX") state parseX {
        packet.extract<XHdr1_0>(hdr.x1);
        transition select(hdr.x1.f1) {
            24w0x2: parseFoo;
            24w0x1 &&& 24w0x1: parseFooBar;
            default: accept;
        }
    }
    @name(".start") state start {
        transition parseX;
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".t1a") action t1a() {
    }
    @name(".T1") table T1 {
        actions = {
            t1a();
            @defaultonly NoAction();
        }
        size = 1;
        default_action = NoAction();
    }
    apply {
        T1.apply();
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<XHdr1_0>(hdr.x1);
        packet.emit<XHdr2_0>(hdr.x2);
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

