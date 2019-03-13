#include <core.p4>
#include <v1model.p4>

struct ing_md_t {
    bit<16> fib_result;
    bit<1>  field1;
    bit<1>  field4;
    bit<14> field2;
    bit<12> field3;
    bit<1>  barHit;
    bit<11> partition_index;
    bit<12> vrf;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vid;
    bit<16> etherType;
}

struct metadata {
    @name(".ing_md") 
    ing_md_t ing_md;
}

struct headers {
    @name(".ethernet") 
    ethernet_t ethernet;
    @name(".ipv4") 
    ipv4_t     ipv4;
    @name(".vlan_tag_") 
    vlan_tag_t vlan_tag_;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract<ethernet_t>(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            16w0x8100: parse_vlan;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract<ipv4_t>(hdr.ipv4);
        transition select(hdr.ipv4.fragOffset, hdr.ipv4.ihl, hdr.ipv4.protocol) {
            default: accept;
        }
    }
    @name(".parse_vlan") state parse_vlan {
        packet.extract<vlan_tag_t>(hdr.vlan_tag_);
        transition select(hdr.vlan_tag_.etherType) {
            16w0x800: parse_ipv4;
        }
    }
    @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".setBar") action setBar() {
        meta.ing_md.barHit = 1w1;
    }
    @name(".set_fib_result") action set_fib_result(bit<16> res) {
        meta.ing_md.fib_result = res;
    }
    @name(".set_partition_index") action set_partition_index(bit<11> index) {
        meta.ing_md.partition_index = index;
    }
    @name(".bar1") table bar1 {
        actions = {
            setBar();
            @defaultonly NoAction();
        }
        key = {
            meta.ing_md.field1: exact @name("ing_md.field1") ;
            meta.ing_md.field2: ternary @name("ing_md.field2") ;
            hdr.vlan_tag_.vid : ternary @name("vlan_tag_.vid") ;
            meta.ing_md.field4: exact @name("ing_md.field4") ;
        }
        size = 4096;
        default_action = NoAction();
    }
    @atcam_partition_index("ing_md.partition_index") @ways(5) @name(".fib") table fib {
        actions = {
            set_fib_result();
            @defaultonly NoAction();
        }
        key = {
            meta.ing_md.partition_index: exact @name("ing_md.partition_index") ;
            meta.ing_md.vrf            : exact @name("ing_md.vrf") ;
            hdr.ipv4.dstAddr           : lpm @name("ipv4.dstAddr") ;
        }
        size = 16384;
        default_action = NoAction();
    }
    @name(".partition") table partition {
        actions = {
            set_partition_index();
            @defaultonly NoAction();
        }
        key = {
            meta.ing_md.vrf       : exact @name("ing_md.vrf") ;
            hdr.ipv4.dstAddr[31:8]: lpm @name("ipv4.dstAddr") ;
        }
        size = 1024;
        default_action = NoAction();
    }
    apply {
        partition.apply();
        bar1.apply();
        fib.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit<ethernet_t>(hdr.ethernet);
        packet.emit<vlan_tag_t>(hdr.vlan_tag_);
        packet.emit<ipv4_t>(hdr.ipv4);
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

