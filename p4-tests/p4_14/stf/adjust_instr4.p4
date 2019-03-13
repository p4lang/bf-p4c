/** This tests whether or not the two fields in the same container can be adjusted and renamed
 *  data though the action data table.  Because of the size of the parameters need, the table
 *  will be configured as an action data table, rather than as immediate
 */
header_type data_t {
    fields {
        f1 : 32;
        n1 : 4;
        n2 : 4;
        f2 : 32;
    }
}

header data_t data;

parser start {
    extract(data);
    return ingress;
}

action set_stuff(param1, param2, param3, port) {
    modify_field(data.n1, param1);
    modify_field(data.n2, param2);
    modify_field(data.f2, param3);
    modify_field(standard_metadata.egress_spec, port);
}

table test1 {
    reads {
        data.f1 : exact;
    }
    actions {
        set_stuff;
    }
}

control ingress {
    apply(test1);
}
