@pragma command_line --decaf

header_type data_t {
    fields {
        m : 8;
        k : 8;
        a : 16;
        b : 16;
        c : 16;
    }
}

header data_t data;

parser start {
      set_metadata(standard_metadata.egress_spec, 0x2);
      extract(data);
      return ingress;
}

action a1() {
    modify_field(data.a, data.b);
}

action a2() {
    modify_field(data.a, 0x0800);
}

action a3() {
    modify_field(data.a, data.c);
}

table t1 {
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
    modify_field(data.b, data.a);
}

action a5() {
    modify_field(data.b, 0x0866);
}

table t2 {
    reads {
        data.k : exact;
    }
    actions {
       a4; 
       a5; 
    }
}

control ingress {
    apply(t1);
    apply(t2);
}

control egress {}
