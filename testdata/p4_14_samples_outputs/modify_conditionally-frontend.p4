#include <core.p4>
#include <v1model.p4>

struct metadata_global_t {
    bit<1> do_goto_table;
    bit<8> goto_table_id;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    @name(".metadata_global") 
    metadata_global_t metadata_global;
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".start") state start {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition accept;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @noWarnUnused @name(".NoAction") action NoAction_0() {
    }
    bit<8> tmp;
    @name(".table0_actionlist") action table0_actionlist(bit<1> do_goto_table, bit<8> goto_table_id) {
        meta.metadata_global.do_goto_table = do_goto_table;
        if (do_goto_table != 1w0) {
            tmp = goto_table_id;
        } else {
            tmp = meta.metadata_global.goto_table_id;
        }
    }
    @name(".table0") table table0_0 {
        actions = {
            table0_actionlist();
            @defaultonly NoAction_0();
        }
        key = {
            hdr.ethernet.etherType: ternary @name("ethernet.etherType") ;
        }
        size = 2000;
        default_action = NoAction_0();
    }
    apply {
        if (meta.metadata_global.goto_table_id == 8w0) {
            table0_0.apply();
        }
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
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
