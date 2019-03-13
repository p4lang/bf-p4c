header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr: 32;
    }
}

header_type magic_t {
    fields {
        glue : 16;
        powder : 8;
        hat  : 5;
        trick  : 3;
    }
}

header_type boring_t {
    fields {
        yawn : 128;
    }
}

header ipv4_t     ipv4;
header magic_t    magic;
header boring_t   boring;

parser start {
    extract(ipv4);
    return select(latest.flags, latest.fragOffset, latest.ihl, latest.protocol) {
        0x50508080 : parse_magic;
        default : ingress;
    }
}

parser parse_magic {
    extract(magic);
    return select(latest.hat, latest.trick, latest.powder, latest.glue)  {
        0x12345678 : parse_boring;
        default : ingress;
    }
}

parser parse_boring {
    extract(boring);
    return ingress;
}

control ingress { }
control egress { }
