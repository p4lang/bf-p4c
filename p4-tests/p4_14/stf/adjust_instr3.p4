/** This tests whether or not the two fields in the same container can be adjusted by immediate
 *  data though action data.   About as simple of a combination instruction as possible.
 */
header_type data_t {
    fields {
        f1 : 32;
        n1 : 4;
        n2 : 4;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action set_nibbles(param1, param2) {
     modify_field(data.n1, param1);
     modify_field(data.n2, param2);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        set_nibbles;
    }
}

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table setting_port {
    actions {
        setport;
    }
    default_action: setport(2);
}

control ingress {
    apply(test1);
    apply(setting_port);
}
