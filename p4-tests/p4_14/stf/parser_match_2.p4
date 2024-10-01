header_type homework_t {
    fields {
        juicebox : 4;
        bully : 4;
        detergent : 16;
        flags : 3;
        lunchbox : 13;
    }
}

header_type boring_t {
    fields {
        yawn : 32;
    }
}

header homework_t homework;
header boring_t   boring;

parser start {
    extract(homework);
    return select(latest.bully, latest.flags, latest.lunchbox) {
        0x50000 mask 0xf0000: parse_schoolbus;
        default : ingress;
    }
}

parser parse_schoolbus {
    extract(boring);
    return select(homework.flags, homework.lunchbox, homework.juicebox)  {
        0x00006 mask 0x0000f: parse_boring;
        default : ingress;
    }
}

parser parse_boring {
    set_metadata(standard_metadata.egress_spec, 0x2);
    return ingress;
}

control ingress { }
