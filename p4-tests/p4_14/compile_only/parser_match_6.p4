header_type intl45_head_header_t {
    fields {
        int_type :8;
        len :16;
        rsvd1 :8;
    }
}

header_type intl45_tail_header_t {
    fields {
        next_proto :8;
        proto_param :16;
        rsvd :8;
    }
}

header_type int_header_t {
    fields {
        ver : 4;
        rep : 2;
        c : 1;
        e : 1;
        d : 1;
        rsvd1 : 2;
        ins_cnt : 5;
        max_hop_cnt : 8;
        total_hop_cnt : 8;
        instruction_bitmap_0003 : 4;
        instruction_bitmap_0407 : 4;
        instruction_bitmap_0811 : 4;
        instruction_bitmap_1215 : 4;
        rsvd2_digest : 16;
    }
}

header intl45_head_header_t intl45_head_header;
header intl45_tail_header_t intl45_tail_header;
header int_header_t int_header;

parser start {
    extract(intl45_head_header);
    return parse_int_header;
}

parser parse_int_header {
    extract(int_header);
    return select (latest.rsvd1, latest.total_hop_cnt) {
        0x000 mask 0xf00: parse_int_stack;
        default : ingress;
    }
}

parser parse_intl45_ipv4_next{
    extract(intl45_tail_header);
    return ingress;
}

parser parse_int_stack {
    return select(intl45_head_header.len) {
        0x10 mask 0x10 : parse_int_stack_L1_16_1;
        0x08 mask 0x08 : parse_int_stack_L1_8;
        0x04 mask 0x04 : parse_int_stack_L1_4;
        default : ingress;
    }
}

@pragma force_shift ingress 128
parser parse_int_stack_L1_16_1{
    return parse_int_stack_L1_16_2;
}

@pragma force_shift ingress 128
parser parse_int_stack_L1_16_2{
    return parse_int_stack_L1_16_3;
}

@pragma force_shift ingress 128
parser parse_int_stack_L1_16_3{
    return select(intl45_head_header.len) {
        0x08 mask 0x08 : parse_int_stack_L2_8_1;
        0x04 mask 0x04 : parse_int_stack_L2_4;
        0x03 mask 0x03 : parse_int_stack_L2_3;
        0x02 mask 0x02 : parse_int_stack_L2_2;
        0x01 mask 0x01 : parse_int_stack_L2_1;
        default : parse_intl45_ipv4_next;
    }
}

@pragma force_shift ingress 128
parser parse_int_stack_L1_8{
    return select(intl45_head_header.len) {
        0x04 mask 0x04 : parse_int_stack_L2_4;
        0x03 mask 0x03 : parse_int_stack_L2_3;
        0x02 mask 0x02 : parse_int_stack_L2_2;
        0x01 mask 0x01 : parse_int_stack_L2_1;
        default : parse_intl45_ipv4_next;
    }
}

parser parse_int_stack_L1_4{
    return select(intl45_head_header.len) {
        0x03 mask 0x03 : parse_int_stack_L2_3;
        0x02 mask 0x02 : parse_int_stack_L2_2;
        0x01 mask 0x01 : parse_int_stack_L2_1;
        default : parse_intl45_ipv4_next;
    }
}

@pragma force_shift ingress 128
parser parse_int_stack_L2_8_1{
    return parse_int_stack_L2_8_2;
}

@pragma force_shift ingress 128
parser parse_int_stack_L2_8_2{
    return select(intl45_head_header.len) {
        0x04 mask 0x04 : parse_int_stack_L2_4;
        0x03 mask 0x03 : parse_int_stack_L2_3;
        0x02 mask 0x02 : parse_int_stack_L2_2;
        0x01 mask 0x01 : parse_int_stack_L2_1;
        default : parse_intl45_ipv4_next;
    }
}

@pragma force_shift ingress 128
parser parse_int_stack_L2_4{
    return select(intl45_head_header.len) {
        0x03 mask 0x03 : parse_int_stack_L2_3;
        0x02 mask 0x02 : parse_int_stack_L2_2;
        0x01 mask 0x01 : parse_int_stack_L2_1;
        default : parse_intl45_ipv4_next;
    }
}

@pragma force_shift ingress 96
parser parse_int_stack_L2_3{
    return parse_intl45_ipv4_next;
}

@pragma force_shift ingress 64
parser parse_int_stack_L2_2{
    return parse_intl45_ipv4_next;
}

@pragma force_shift ingress 32
parser parse_int_stack_L2_1{
    return parse_intl45_ipv4_next;
}

control ingress { }
