@pragma command_line --decaf

header_type data_t {
    fields {
        m : 8;
        k : 8;
        a : 24;
        b : 24;
    }
}

header data_t data;

parser start {
      set_metadata(standard_metadata.egress_spec, 0x2);
      extract(data);
      return ingress;
}

action a1(param) {
    modify_field(data.a, param);
}

action a2() {
    bit_not(data.a, data.a);
}

action a3() {
    modify_field(data.b, data.a);
}

table t1 {
    reads {
        data.m : exact;
    }
    actions {
       a1;
       a2;
    }
}

table t2 {
    reads {
        data.k : exact;
    }
    actions {
       a3; 
    }
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress {}
