header data_h {
    bit<32>     f1;
    bit<32>     f2;
    bit<16>     h1;
    bit<8>      b1;
    bit<8>      b2;
}

struct packet_t {
    data_h      data;
}

parser TopParser(packet_in b, out packet_t hdrs, inout standard_metadata meta)
{
    state start {
        b.extract(hdrs.data);
        transition accept;
    }
}

control egress(inout packet_t hdrs, inout standard_metadata meta) {
    apply { }
}

control deparser(packet_out b, in packet_t hdrs, inout standard_metadata meta) {
    apply {
        b.emit(hdrs.data);
    }
}
