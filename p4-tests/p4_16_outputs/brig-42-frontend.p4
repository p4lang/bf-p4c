#include <core.p4>
#include <v1model.p4>

header instr_h {
    bit<8> instr_code;
    bit<8> instr_value;
}

header data_h {
    bit<8> data_eof;
    bit<8> data_value;
}

struct my_packet {
    instr_h[4] instr;
    data_h[10] data;
}

struct my_metadata {
}

parser MyParser(packet_in b, out my_packet p, inout my_metadata m, inout standard_metadata_t s) {
    state start {
        transition parse_instr;
    }
    state parse_instr {
        b.extract<instr_h>(p.instr.next);
        transition select(p.instr.last.instr_code) {
            8w0: accept;
            default: parse_instr;
        }
    }
}

control MyVerifyChecksum(inout my_packet hdr, inout my_metadata meta) {
    apply {
    }
}

control MyIngress(inout my_packet p, inout my_metadata m, inout standard_metadata_t s) {
    bit<8> v1_0;
    bit<8> v2_0;
    @name("nop") action nop_0() {
    }
    @name("do_push") action do_push_0() {
        p.data.push_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("do_add") action do_add_0() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("t1") table t1_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_0();
            do_push_0();
            do_add_0();
        }
        default_action = nop_0();
    }
    @name("t2") table t2_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_0();
            do_push_0();
            do_add_0();
        }
        default_action = nop_0();
    }
    @name("t3") table t3_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_0();
            do_push_0();
            do_add_0();
        }
        default_action = nop_0();
    }
    @name("t4") table t4_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_0();
            do_push_0();
            do_add_0();
        }
        default_action = nop_0();
    }
    @name("t5") table t5_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_0();
            do_push_0();
            do_add_0();
        }
        default_action = nop_0();
    }
    @name("t6") table t6_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_0();
            do_push_0();
            do_add_0();
        }
        default_action = nop_0();
    }
    apply {
        if (p.instr[0].isValid()) 
            t1_0.apply();
        if (p.instr[0].isValid()) 
            t2_0.apply();
        if (p.instr[0].isValid()) 
            t3_0.apply();
        if (p.instr[0].isValid()) 
            t4_0.apply();
        if (p.instr[0].isValid()) 
            t5_0.apply();
        if (p.instr[0].isValid()) 
            t6_0.apply();
    }
}

control MyEgress(inout my_packet p, inout my_metadata m, inout standard_metadata_t s) {
    apply {
    }
}

control MyComputeChecksum(inout my_packet p, inout my_metadata m) {
    apply {
    }
}

control MyDeparser(packet_out b, in my_packet p) {
    apply {
        b.emit<instr_h[4]>(p.instr);
        b.emit<data_h[10]>(p.data);
    }
}

V1Switch<my_packet, my_metadata>(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;

