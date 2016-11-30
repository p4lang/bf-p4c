/* This is a test to determine whether or not the table using a meter reserves the correct
   space for immediate data, if the table choices to have immediate data.  The meter itself
   requires 8 bits of immediate data, so an action table must be selected for it
*/
header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        f4 : 32;
        h1 : 16;
        h2 : 16;
        h3 : 16;
        h4 : 16;
        h5 : 16;
        b1 : 8;
        color_1 : 8;
        color_2 : 8;
        color_3 : 8;
    }
}

header data_t data;
parser start {
    extract (data);
    return ingress;
}

action h1_2(val1, val2) {
    modify_field(data.h1, val1);
    modify_field(data.h2, val2);
    execute_meter(meter_1, 7, data.color_1); 
}

action h3_b1(val3, val1) {
    modify_field(data.h3, val3);
    modify_field(data.b1, val1);
    execute_meter(meter_2, 7, data.color_2);
}

action h4_5(val4, val5) {
    modify_field(data.h4, val4);
    modify_field(data.h5, val5);
    execute_meter(meter_3, 7, data.color_3);
}

meter meter_1 {
    type : bytes;
    static : test1;
    result : data.color_1;
    instance_count : 1024;
}

meter meter_2 {
    type : bytes;
    static : test2;
    result : data.color_2;
    instance_count : 1024;
}

meter meter_3 {
    type : bytes;
    static : test3;
    result : data.color_3;
    implementation : lpf;
    instance_count : 1024;
}


table test1 {
    reads {
        data.f1 : exact;
    } actions {
        h1_2;
    }
    size : 1024;
}

table test2 {
    reads {
        data.f2 : exact;
    } actions {
        h3_b1;
    }
    size : 1024;
}

table test3 {
    reads {
        data.f3 : exact;
    }
    actions {
        h4_5;
    }
    size : 1024;
}


control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
}
