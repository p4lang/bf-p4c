#include <core.p4>
#include <v1model.p4>

@name("XHdr") header XHdr_0 {
    bit<24> f1;
    bit<12> f2;
    bit<4>  _pad;
}

struct metadata {
}

struct headers {
    @name(".x") 
    XHdr_0 x;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parseBar") state parseBar {
        transition accept;
    }
    @name(".parseFoo") state parseFoo {
        transition select(hdr.x.f2) {
            12w0x3: parseBar;
            default: accept;
        }
    }
    @name(".parseFooBar") state parseFooBar {
        transition accept;
    }
    @name(".parseX") state parseX {
        packet.extract(hdr.x);
        transition select(hdr.x.f1) {
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
            t1a;
        }
        size = 1;
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
        packet.emit(hdr.x);
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

