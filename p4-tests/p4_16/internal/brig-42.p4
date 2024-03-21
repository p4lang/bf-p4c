#include <v1model.p4>

#define INSTR_STACK 4
#define DATA_STACK 10

#define PUSH 1
#define ADD 2

header instr_h {
  bit<8> instr_code;
  bit<8> instr_value;
}

header data_h {
  bit<8> data_eof;
  bit<8> data_value;
}

struct my_packet {
  instr_h[INSTR_STACK] instr;
  data_h[DATA_STACK] data;
}

struct my_metadata {

}

parser MyParser(packet_in b, out my_packet p, inout my_metadata m, inout standard_metadata_t s) {
  state start {
    transition parse_instr;
  }

  state parse_instr {
    b.extract(p.instr.next);
    transition select(p.instr.last.instr_code) {
      0: accept;
      default: parse_instr;
    }
  }
}


control MyVerifyChecksum(inout my_packet hdr, inout my_metadata meta) {
  apply { }
}


control MyIngress(inout my_packet p, inout my_metadata m, inout standard_metadata_t s) {
  action nop() {
  }
  action do_push() {
    p.data.push_front(1);
    p.data[0].setValid();
    p.data[0].data_eof = 1;
    p.data[0].data_value = p.instr[0].instr_value;
    p.instr.pop_front(1);
    s.egress_spec = 2;
  }
  action do_add() {
    bit<8> v1 = p.data[0].data_value;
    bit<8> v2 = p.data[1].data_value;
    p.data.pop_front(1);
    p.data[0].data_eof = 1;
    p.data[0].data_value = v1 + v2;
    p.instr.pop_front(1);
    s.egress_spec = 2;
  }

  table t1 {
    key = { p.instr[0].instr_code : exact; }
    actions = { nop; do_push; do_add; }
    default_action = nop;
  }
  table t2 {
    key = { p.instr[0].instr_code : exact; }
    actions = { nop; do_push; do_add; }
    default_action = nop;
  }
  table t3 {
    key = { p.instr[0].instr_code : exact; }
    actions = { nop; do_push; do_add; }
    default_action = nop;
  }
  table t4 {
    key = { p.instr[0].instr_code : exact; }
    actions = { nop; do_push; do_add; }
    default_action = nop;
  }
  table t5 {
    key = { p.instr[0].instr_code : exact; }
    actions = { nop; do_push; do_add; }
    default_action = nop;
  }
  table t6 {
    key = { p.instr[0].instr_code : exact; }
    actions = { nop; do_push; do_add; }
    default_action = nop;
  }

  apply {
    if (p.instr[0].isValid()) { t1.apply(); }
    if (p.instr[0].isValid()) { t2.apply(); }
    if (p.instr[0].isValid()) { t3.apply(); }
    if (p.instr[0].isValid()) { t4.apply(); }
    if (p.instr[0].isValid()) { t5.apply(); }
    if (p.instr[0].isValid()) { t6.apply(); }
  }
}

control MyEgress(inout my_packet p, inout my_metadata m, inout standard_metadata_t s) {
  apply { }
}

control MyComputeChecksum(inout my_packet p, inout my_metadata m) {
  apply { }
}

control MyDeparser(packet_out b, in my_packet p) {
  apply {
    b.emit(p.instr);
    b.emit(p.data);
  }
}

V1Switch(MyParser(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
