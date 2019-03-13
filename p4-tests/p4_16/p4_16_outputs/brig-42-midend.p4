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
    @name("MyIngress.nop") action nop() {
    }
    @name("MyIngress.nop") action nop_6() {
    }
    @name("MyIngress.nop") action nop_7() {
    }
    @name("MyIngress.nop") action nop_8() {
    }
    @name("MyIngress.nop") action nop_9() {
    }
    @name("MyIngress.nop") action nop_10() {
    }
    @name("MyIngress.do_push") action do_push() {
        p.data.push_front(1);
        p.data[0].setValid();
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_push") action do_push_6() {
        p.data.push_front(1);
        p.data[0].setValid();
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_push") action do_push_7() {
        p.data.push_front(1);
        p.data[0].setValid();
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_push") action do_push_8() {
        p.data.push_front(1);
        p.data[0].setValid();
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_push") action do_push_9() {
        p.data.push_front(1);
        p.data[0].setValid();
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_push") action do_push_10() {
        p.data.push_front(1);
        p.data[0].setValid();
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = p.instr[0].instr_value;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_add") action do_add() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_add") action do_add_6() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_add") action do_add_7() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_add") action do_add_8() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_add") action do_add_9() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.do_add") action do_add_10() {
        v1_0 = p.data[0].data_value;
        v2_0 = p.data[1].data_value;
        p.data.pop_front(1);
        p.data[0].data_eof = 8w1;
        p.data[0].data_value = v1_0 + v2_0;
        p.instr.pop_front(1);
        s.egress_spec = 9w2;
    }
    @name("MyIngress.t1") table t1_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop();
            do_push();
            do_add();
        }
        default_action = nop();
    }
    @name("MyIngress.t2") table t2_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_6();
            do_push_6();
            do_add_6();
        }
        default_action = nop_6();
    }
    @name("MyIngress.t3") table t3_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_7();
            do_push_7();
            do_add_7();
        }
        default_action = nop_7();
    }
    @name("MyIngress.t4") table t4_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_8();
            do_push_8();
            do_add_8();
        }
        default_action = nop_8();
    }
    @name("MyIngress.t5") table t5_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_9();
            do_push_9();
            do_add_9();
        }
        default_action = nop_9();
    }
    @name("MyIngress.t6") table t6_0 {
        key = {
            p.instr[0].instr_code: exact @name("p.instr[0].instr_code") ;
        }
        actions = {
            nop_10();
            do_push_10();
            do_add_10();
        }
        default_action = nop_10();
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
        b.emit<instr_h>(p.instr[0]);
        b.emit<instr_h>(p.instr[1]);
        b.emit<instr_h>(p.instr[2]);
        b.emit<instr_h>(p.instr[3]);
        b.emit<data_h>(p.data[0]);
        b.emit<data_h>(p.data[1]);
        b.emit<data_h>(p.data[2]);
        b.emit<data_h>(p.data[3]);
        b.emit<data_h>(p.data[4]);
        b.emit<data_h>(p.data[5]);
        b.emit<data_h>(p.data[6]);
        b.emit<data_h>(p.data[7]);
        b.emit<data_h>(p.data[8]);
        b.emit<data_h>(p.data[9]);
    }
}

V1Switch<my_packet, my_metadata>(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;

