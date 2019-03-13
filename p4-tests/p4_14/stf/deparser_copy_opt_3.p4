@pragma command_line --decaf

header_type data_t {
    fields {
        m : 8;
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
    swap(data.a, data.b);
}

action a2() {
    swap(data.c, data.d);
}

action a3() {
    swap(data.a, data.c);
}

action a4() {
    swap(data.b, data.d);
}

table paws {
    reads {
        data.m : exact;
    }
    actions {
       a1; 
       a2;
       a3; 
       a4; 
    }
}

control ingress {
    apply(paws);
}

control egress {}
