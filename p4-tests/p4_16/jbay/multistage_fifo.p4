#include <jna.p4>

typedef bit<32> b32;
struct metadata {
    b32 address;
}

struct pair {
    bit<64>     lo;
    bit<64>     hi;
}

#define METADATA_INIT(M)\
    M.address = 0;      \

#include "ethernet_parser.h"

control ingress(inout headers hdr, inout metadata meta,
                in ingress_intrinsic_metadata_t ig_intr_md,
                in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
                inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
                inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    /*
     * Multi-stage FIFO
     */
    action nop() { }

    @chain_total_size(3072)
    @name("fifo") Register<pair>(1024) fifo_1_of_3; // First stage
    @name("fifo") Register<pair>(1024) fifo_2_of_3; // Second stage
    @name("fifo") Register<pair>(1024) fifo_3_of_3; // Third stage

    @chain_address(meta.address)
    RegisterAction<pair, b32>(fifo_1_of_3) read_1 = {
        void apply(inout pair value, out b32 rv) { rv = value.lo[31:0]; } };
    @chain_address(meta.address)
    RegisterAction<pair, b32>(fifo_2_of_3) read_2 = {
        void apply(inout pair value, out b32 rv) { rv = value.lo[31:0]; } };
    RegisterAction<pair, b32>(fifo_3_of_3) read_3 = {
        void apply(inout pair value, out b32 rv) { rv = value.lo[31:0]; } };
    action multi_stage_1_dequeue() {
        ig_intr_tm_md.ucast_egress_port = 1;
        hdr.ethernet.src_addr[31:0] = read_1.dequeue();
        meta.address = read_1.address(); }
    action multi_stage_2_dequeue() {
        hdr.ethernet.src_addr[31:0] = hdr.ethernet.src_addr[31:0] | read_2.execute(meta.address);
        meta.address = read_2.address(); }
    action multi_stage_3_dequeue() {
        hdr.ethernet.src_addr[31:0] = hdr.ethernet.src_addr[31:0] | read_3.execute(meta.address); }

    @name("multi_stage_dequeue") table do_multi_stage_1_dequeue {
        key = { hdr.ethernet.dst_addr : ternary; }
        actions = { multi_stage_1_dequeue; @default_only nop; }
        default_action = nop();
    }
    table do_multi_stage_2_dequeue {
        actions = { multi_stage_2_dequeue; }
        default_action = multi_stage_2_dequeue();
    }
    table do_multi_stage_3_dequeue {
        actions = { multi_stage_3_dequeue; }
        default_action = multi_stage_3_dequeue();
    }

    @chain_address(meta.address)
    RegisterAction<pair, b32>(fifo_1_of_3) write_1 = {
        void apply(inout pair value) { value.lo[31:0] = hdr.ethernet.src_addr[31:0]; } };
    @chain_address(meta.address)
    RegisterAction<pair, b32>(fifo_2_of_3) write_2 = {
        void apply(inout pair value) { value.lo[31:0] = hdr.ethernet.src_addr[31:0]; } };
    RegisterAction<pair, b32>(fifo_3_of_3) write_3 = {
        void apply(inout pair value) { value.lo[31:0] = hdr.ethernet.src_addr[31:0]; } };
    action multi_stage_1_enqueue() {
        ig_intr_tm_md.ucast_egress_port = 2;
        write_1.enqueue();
        meta.address = write_1.address(); }
    action multi_stage_2_enqueue() {
        write_2.execute(meta.address);
        meta.address = write_2.address();}
    action multi_stage_3_enqueue() {
        write_3.execute(meta.address); }

    @name("multi_stage_enqueue") table do_multi_stage_1_enqueue {
        key = { hdr.ethernet.dst_addr : ternary; }
        actions = { multi_stage_1_enqueue; @default_only nop; }
        default_action = nop();
    }
    table do_multi_stage_2_enqueue {
        actions = { multi_stage_2_enqueue; }
        default_action = multi_stage_2_enqueue();
    }
    table do_multi_stage_3_enqueue {
        actions = { multi_stage_3_enqueue; }
        default_action = multi_stage_3_enqueue();
    }


    apply {
        if (hdr.ethernet.dst_addr[47:47] == 0) {
            if (do_multi_stage_1_dequeue.apply().hit) {
                do_multi_stage_2_dequeue.apply();
                do_multi_stage_3_dequeue.apply();
            }
        } else {
            if (do_multi_stage_1_enqueue.apply().hit) {
                do_multi_stage_2_enqueue.apply();
                do_multi_stage_3_enqueue.apply();
            }
        }
    }
}

#include "common_jna_test.h"
