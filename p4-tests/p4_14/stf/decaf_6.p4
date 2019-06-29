@pragma command_line --decaf

header_type data_t {
    fields {
        k : 16;
        f : 128;
    }
}

header data_t data;

parser start {
      set_metadata(standard_metadata.egress_spec, 0x2);
      extract(data);
      return ingress;
}

action a1() {
    modify_field(data.f, 0x5AA5BCCBDEADBEEFBABEFACE1BADCAFE);
}

table t1 {
    reads {
        data.k : exact;
    }
    actions {
       a1;
    }
}

control ingress {
    apply(t1);
}

control egress {}
