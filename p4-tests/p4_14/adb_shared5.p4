
header_type hdr_t {
    fields {
       read : 32;
       b0 : 8;
       b1 : 8;
       b2 : 8;
       b3 : 8;
       b4 : 8;
       b5 : 8;
       b6 : 8;
       b7 : 8;
       b8 : 8;
       b9 : 8;
       ba : 8;
       bb : 8;
       bc : 8;
       bd : 8;
       be : 8;
       bf : 8;
       h0 : 16;
       h1 : 16;
       h2 : 16;
       h3 : 16;
       h4 : 16;
       h5 : 16;
       h6 : 16;
       h7 : 16;
       f0 : 32;
       f1 : 32;
    }
}

header hdr_t hdr;

parser start {
    extract(hdr);
    return ingress;
}

action a1(byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7,
          byte8, byte9, bytea, byteb, bytec, byted, bytee, bytef) {
    modify_field(hdr.b0, byte0);
    modify_field(hdr.b1, byte1);
    modify_field(hdr.b2, byte2);
    modify_field(hdr.b3, byte3);
    modify_field(hdr.b4, byte4);
    modify_field(hdr.b5, byte5);
    modify_field(hdr.b6, byte6);
    modify_field(hdr.b7, byte7);
    modify_field(hdr.b8, byte8);
    modify_field(hdr.b9, byte9);
    modify_field(hdr.ba, bytea);
    modify_field(hdr.bb, byteb);
    modify_field(hdr.bc, bytec);
    modify_field(hdr.bd, byted);
    modify_field(hdr.be, bytee);
    modify_field(hdr.bf, bytef);
}

action a2(half0, half1, half2, half3, half4, half5, half6, half7) {
    modify_field(hdr.h0, half0);
    modify_field(hdr.h1, half1);
    modify_field(hdr.h2, half2);
    modify_field(hdr.h3, half3);
    modify_field(hdr.h4, half4);
    modify_field(hdr.h5, half5);
    modify_field(hdr.h6, half6);
    modify_field(hdr.h7, half7);
}

action a3(byte0, byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8, byte9,
          half5, half6, half7) {
    modify_field(hdr.b0, byte0);
    modify_field(hdr.b1, byte1);
    modify_field(hdr.b2, byte2);
    modify_field(hdr.b3, byte3);
    modify_field(hdr.b4, byte4);
    modify_field(hdr.b5, byte5);
    modify_field(hdr.b6, byte6);
    modify_field(hdr.b7, byte7);
    modify_field(hdr.b8, byte8);
    modify_field(hdr.b9, byte9);
    modify_field(hdr.h5, half5);
    modify_field(hdr.h6, half6);
    modify_field(hdr.h7, half7);
}

action a4(byte0, byte1, byte2, byte3, byte4, byte5, half0, half1, half2, full0) {
    modify_field(hdr.b0, byte0);
    modify_field(hdr.b1, byte1);
    modify_field(hdr.b2, byte2);
    modify_field(hdr.b3, byte3);
    modify_field(hdr.b4, byte4);
    modify_field(hdr.b5, byte5);
    modify_field(hdr.h0, half0);
    modify_field(hdr.h1, half1);
    modify_field(hdr.h2, half2);
    modify_field(hdr.f0, full0);
} 

action setport(port) {
    modify_field(standard_metadata.egress_spec, port);
}

table t1 {
    reads {
        hdr.read : exact;
    }
    actions {
        a1;
        a2;
        a3;
        a4;
    }
}

table setting_port {
    reads {
        hdr.read : exact;
    }
    actions {
        setport;
    }
}

control ingress {
    apply(t1);
    apply(setting_port);
}
