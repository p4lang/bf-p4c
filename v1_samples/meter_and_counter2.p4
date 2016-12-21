header_type data_t {
    fields {
        f1 : 32;
        f2 : 32;
        f3 : 32;
        h1 : 16;
        h2 : 16;
        h3 : 16;
        h4 : 16;
        h5 : 16;
        h6 : 16;
        h7 : 16;
        h8 : 16;
        h9 : 16;
        color_1 : 8;
        color_2 : 8;
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
    execute_meter(meter1, 7, data.color_1);
}

action h4_6(val4, val5, val6) {
    modify_field(data.h4, val4);
    modify_field(data.h5, val5);
    modify_field(data.h6, val6);
}

action h7_9(val7, val8, val9) {
    modify_field(data.h7, val7);
    modify_field(data.h8, val8);
    modify_field(data.h9, val9);
    execute_meter(meter2, 7, data.color_2);
}

meter meter1 {
    type : bytes;
    static : test1;
    result : data.color_1;
    instance_count : 1000;
    implementation : lpf;
}

meter meter2 {
    type : bytes;
    static : test3;
    result : data.color_2;
    instance_count : 2000;
    implementation : wred;
}

counter counter2 {
    type : packets;
    direct : test2;
}

table test1 {
    reads {
        data.f1 : exact;
    } actions {
        h1_3;
    }
    size : 32000;
}

table test2 {
    reads {
        data.f2 : exact;
    } actions {
         h4_6;
    }
    size : 2048;
}

table test3 {
    reads {
        data.f3 : exact;
    } actions {
        h7_9;
    }
    size : 10000;
}

control ingress {
    apply(test1);
    apply(test2);
    apply(test3);
}
