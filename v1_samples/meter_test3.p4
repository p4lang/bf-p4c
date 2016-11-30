/* Test for lpf meters and wred meters requiring the action bus on the */
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
        h6 : 16;
        h7 : 16;
        h8 : 16;
        h9 : 16;
        h10 : 16;
        h11 : 16;
        h12 : 16;
        color_1 : 8;
        color_2 : 8;
        color_3 : 8;
        color_4 : 8;
    }
}

header data_t data;
parser start {
    extract (data);
    return ingress;
}

action h1_3(val1, val2, val3) {
    modify_field(data.h1, val1);
    modify_field(data.h2, val2);
    modify_field(data.h3, val3);
    execute_meter(meter_1, 7, data.color_1);
}

action h4_6(val4, val5, val6) {
    modify_field(data.h4, val4);
    modify_field(data.h5, val5);
    modify_field(data.h6, val6);
    execute_meter(meter_2, 7, data.color_2);
}

action h7_9(val7, val8, val9) {
    modify_field(data.h7, val7);
    modify_field(data.h8, val8);
    modify_field(data.h9, val9);
    execute_meter(meter_3, 7, data.color_3); 
}

action h10_12(val10, val11, val12) {
    modify_field(data.h10, val10);
    modify_field(data.h11, val11);
    modify_field(data.h12, val12);
    execute_meter(meter_4, 7, data.color_4);
}

action set_port(port) {
    modify_field(standard_metadata.egress_spec, port);
} 


meter meter_1 {
    type : bytes;
    static : test1;
    result : data.color_1;
    implementation : lpf;
    instance_count : 12000;
}

meter meter_2 {
    type : bytes;
    static : test2;
    result : data.color_2;
    implementation : lpf;
    instance_count : 1024;
}

meter meter_3 {
    type : bytes;
    static : test3;
    result : data.color_3;
    instance_count : 6000;
}

meter meter_4 {
    type : bytes;
    static : test4;
    result : data.color_4;
    implementation : wred;
    instance_count : 1024;
}


table test1 {
    reads {
        data.f1 : exact;
    } actions {
        h1_3;
    }
    size : 6000;
}

table test2 {
    reads {
        data.f2 : exact;
    } actions {
        h4_6;
    }
    size : 10000;
}

table test3 {
    reads {
        data.f3 : exact;
    }
    actions {
        h7_9;
    }
    size : 1000;
}

table test4 {
    reads {
        data.f4 : exact;
    }
    actions {
        h10_12;
    }
    size : 1000;
}


control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
    apply(test4);
}
