#include <core.p4>
#include <t2na.p4>

typedef bit<48> mac_addr_t;
typedef bit<16> ether_type_t;

header ethernet_h {
    mac_addr_t    dst_addr;
    mac_addr_t    src_addr;
    ether_type_t  ether_type;
}

struct headers {
    ethernet_h ethernet;
}

struct metadata {}

struct pair {
    bit<64>     first;
    bit<64>     second;
}

parser ParserImpl(
        packet_in pkt,
        out headers hdr,
        out metadata ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    state start {
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);

        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition accept;
    }
}

control ingress(
        inout headers hdr,
        inout metadata ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    pair input;
    pair output;
    
    Register<pair, bit<32>>(size=32w1024, initial_value={5, 7}) test_reg;
    RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_write = {
        void apply(inout pair value){
            value.first  = input.first;
            value.second = input.second;
        }
    };

    RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_read = {
        void apply(inout pair value, out bit<32> rv1, out bit<32> rv2, out bit<32> rv3, out bit<32> rv4){
            rv1 = value.second[63:32];
            rv2 = value.second[31:0];
            rv3 = value.first[63:32];
            rv4 = value.first[31:0];
        }
    };

    RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_read_duplicate = {
        void apply(inout pair value, out bit<32> rv1, out bit<32> rv2, out bit<32> rv3, out bit<32> rv4) {
            rv1 = value.second[63:32];
            rv2 = value.second[63:32];
            rv3 = value.second[63:32];
            rv4 = value.first[31:0];
        }
    };

    RegisterAction<pair, bit<32>, bit<32>>(test_reg) test_reg_read_duplicate_predicate = {
        void apply(inout pair value, out bit<32> rv1, out bit<32> rv2, out bit<32> rv3, out bit<32> rv4) {
            rv1 = this.predicate(value.first == 0x01020304, value.second == 0x05060708);
            rv2 = this.predicate(value.first == 0x01020304, value.second == 0x05060708);
            rv3 = value.first[63:32];
            rv4 = value.first[31:0];
        }
    };

    action register_write_action(bit<32> idx) {
        test_reg_write.execute(idx);
    }

    apply {
        if (hdr.ethernet.ether_type == 0xAAAA) {
            input.second[63:16] = hdr.ethernet.dst_addr;
            input.second[15:0]  = hdr.ethernet.src_addr[47:32];
            input.first[63:32]  = hdr.ethernet.src_addr[31:0];
            input.first[31:16]  = hdr.ethernet.ether_type;
            
            register_write_action(0);            
        }
        else {
            if (hdr.ethernet.ether_type == 0xBBBB) {
                bit<32> rv1;
                bit<32> rv2;
                bit<32> rv3;
                bit<32> rv4;
                rv1 = test_reg_read.execute(0, rv2, rv3, rv4);
                
                hdr.ethernet.dst_addr[47:16]= rv1;
                hdr.ethernet.dst_addr[15:0] = rv2[31:16];
                hdr.ethernet.src_addr[47:32]= rv2[15:0];
                hdr.ethernet.src_addr[31:0] = rv3;
                hdr.ethernet.ether_type     = rv4[31:16];
            } else if (hdr.ethernet.ether_type == 0xCCCC) {
                bit<32> rv1;
                bit<32> rv2;
                bit<32> rv3;
                bit<32> rv4;
                rv1 = test_reg_read_duplicate.execute(0, rv2, rv3, rv4);

                hdr.ethernet.dst_addr[47:16]= rv1;
                hdr.ethernet.dst_addr[15:0] = rv2[31:16];
                hdr.ethernet.src_addr[47:32]= rv2[15:0];
                hdr.ethernet.src_addr[31:0] = rv3;
                hdr.ethernet.ether_type     = rv4[31:16];
            } else if (hdr.ethernet.ether_type == 0xDDDD) {
                bit<32> rv1;
                bit<32> rv2;
                bit<32> rv3;
                bit<32> rv4;
                rv1 = test_reg_read_duplicate_predicate.execute(0, rv2, rv3, rv4);

                hdr.ethernet.dst_addr[47:16]= rv1;
                hdr.ethernet.dst_addr[15:0] = rv2[31:16];
                hdr.ethernet.src_addr[47:32]= rv2[15:0];
                hdr.ethernet.src_addr[31:0] = rv3;
                hdr.ethernet.ether_type     = rv4[31:16];
            }

            ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        }
    }
}

#include "common_tna_test.h"
