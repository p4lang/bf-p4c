@pragma command_line --decaf

header_type data_t {
    fields {
        m : 8;
        k : 8;
        a : 32;
        b : 32;
        c : 32;
        d : 32;
    }
}

header data_t data;

parser start {
      set_metadata(standard_metadata.egress_spec, 0x2);
      extract(data);
      return ingress;
}

action a1() {
    modify_field(data.d, data.a);
}

action a2() {
    modify_field(data.d, data.b);
}

action a3() {
    modify_field(data.d, data.c);
}

table mux_3to1 {
    reads {
        data.m : exact;
    }
    actions {
       a1; 
       a2;
       a3; 
    }
}

action a4() {
    modify_field(data.a, data.d);
}

action a5() {
    modify_field(data.b, data.d);
}

action a6() {
    modify_field(data.c, data.d);
}

table demux_1to3 {
    reads {
        data.k : exact;
    }
    actions {
       a4;
       a5;
       a6;
    }
}

control ingress {
    apply(mux_3to1);
}

control egress {
    apply(demux_1to3);
}
