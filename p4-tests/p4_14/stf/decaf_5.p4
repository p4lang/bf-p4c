@pragma command_line --decaf

header_type data_t {
    fields {
        a : 16;
        b : 16;
    }
}

header data_t data;

parser start {
      set_metadata(standard_metadata.egress_spec, 0x2);
      extract(data);
      return ingress;
}

action push() {
    modify_field(data.b, data.a);
}

action pop() {
    modify_field(data.a, data.b);
}

table do_push {
    reads {
        data.a : exact;
    }
    actions {
       push;
    }
}

table do_pop {
    reads {
        data.a : exact;
    }
    actions {
       pop;
    }
}

control ingress {
    apply(do_push);
    apply(do_pop);
}

control egress {}
