/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

typedef bit<32> reg_value_t;
typedef bit<8>  index_t;
typedef bit<8>  action_t;

struct metadata { }

#define DATA_T_OVERRIDE
header data_t {
    index_t     index;
    action_t    action_id;
    reg_value_t write_value;
    reg_value_t value1;
    reg_value_t value2;
    reg_value_t value3;
}

#include "trivial_parser.h"

control ingress(
    /* User */
    inout headers hdr,
    inout metadata meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    action noop() {}
    /****************** Value1 *****************/
    Register<reg_value_t, index_t>(256, 0) reg1;
    RegisterAction<reg_value_t, index_t, reg_value_t>(reg1) reg_write1 = {
        void apply(inout reg_value_t value) {
            value = hdr.data.write_value;
        }
    };
    RegisterAction<reg_value_t, index_t, reg_value_t>(reg1) reg_read1 = {
        void apply(inout reg_value_t value, out reg_value_t rv) {
            reg_value_t in_value;
            in_value = value;
            rv = in_value;
        }
    };

    action write_action1() {
        reg_write1.execute(hdr.data.index);
    }

    action read_action1() {
        hdr.data.value1 = reg_read1.execute(hdr.data.index);
    }

    table test_table1 {
        key = {
            hdr.data.action_id : exact;
        }
        actions = {
            write_action1;
            read_action1;
	    noop;
        }
	default_action = noop;
    }

    /****************** Value2 *****************/
    Register<reg_value_t, index_t>(256, 0) reg2;
    RegisterAction<reg_value_t, index_t, reg_value_t>(reg2) reg_write2 = {
        void apply(inout reg_value_t value) {
            value = hdr.data.write_value;
        }
    };
    RegisterAction<reg_value_t, index_t, reg_value_t>(reg2) reg_read2 = {
        void apply(inout reg_value_t value, out reg_value_t rv) {
            reg_value_t in_value;
            in_value = value;
            rv = in_value;
        }
    };

    action write_action2() {
        reg_write2.execute(hdr.data.index);
    }

    action read_action2() {
        hdr.data.value2 = reg_read2.execute(hdr.data.index);
    }

    table test_table2 {
        key = {
            hdr.data.action_id : exact;
        }
        actions = {
            write_action2;
            read_action2;
	    noop;
        }
	default_action = noop;
    }

    /****************** Value3 *****************/
    Register<reg_value_t, index_t>(256, 0) reg3;
    RegisterAction<reg_value_t, index_t, reg_value_t>(reg3) reg_write3 = {
        void apply(inout reg_value_t value) {
            value = hdr.data.write_value;
        }
    };
    RegisterAction<reg_value_t, index_t, reg_value_t>(reg3) reg_read3 = {
        void apply(inout reg_value_t value, out reg_value_t rv) {
            reg_value_t in_value;
            in_value = value;
            rv = in_value;
        }
    };

    action write_action3() {
        reg_write3.execute(hdr.data.index);
	// force data dependency
	hdr.data.value3 = (bit<32>)(hdr.data.index ++ hdr.data.action_id);
    }

    action read_action3() {
        hdr.data.value3 = reg_read3.execute(hdr.data.index);
    }

    table test_table3 {
        key = {
            hdr.data.action_id : exact;
        }
        actions = {
            write_action3;
            read_action3;
	    noop;
        }
	default_action = noop;
    }

    Counter<bit<32>, bit<12>>(4096, CounterType_t.PACKETS) val3_read_packet_counter;
    Counter<bit<32>, bit<12>>(4096, CounterType_t.PACKETS) val3_write_packet_counter;

    action increment_val3_read_packet(bit<12> index) {
        val3_read_packet_counter.count(index);
    }

    action increment_val3_write_packet(bit<12> index) {
        val3_write_packet_counter.count(index);
    }

    Counter<bit<32>, bit<8>>(256, CounterType_t.PACKETS) index_packet_counter;
    Counter<bit<32>, bit<8>>(256, CounterType_t.BYTES) index_bytes_counter;

    action increment_index_bytes(bit<8> index) {
        index_bytes_counter.count(index);
    }

    action increment_index_packet(bit<8> index) {
        index_packet_counter.count(index);
    }

    Counter<bit<32>, bit<8>>(256, CounterType_t.PACKETS) port_packet_counter;
    Counter<bit<32>, bit<8>>(256, CounterType_t.BYTES) port_bytes_counter;

    action increment_port_bytes(bit<8> port_idx) {
        port_bytes_counter.count(port_idx);
    }

    action increment_port_packet(bit<8> port_idx) {
        port_packet_counter.count(port_idx);
    }

    apply {
        if (test_table1.apply().miss) {
	    test_table2.apply();
	    switch (test_table3.apply().action_run) {
	        write_action3: {
		    increment_val3_write_packet(hdr.data.value3[11:0]);
		}
		read_action3: {
		    increment_val3_read_packet(hdr.data.value3[11:0]);
		}
	    }
	}
	increment_index_bytes(hdr.data.index);
	increment_index_packet(hdr.data.index);
	increment_port_bytes(ig_intr_md.ingress_port[7:0]);
	increment_port_packet(ig_intr_md.ingress_port[7:0]);

        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
    }
}

#include "common_tna_test.h"