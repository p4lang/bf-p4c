#include <tofino/intrinsic_metadata.p4>

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header ethernet_t ether;

parser start {
    extract(ether);
    return ingress;
}

action a1() {

}

table table1 {
    actions {
        a1;
    }
}
table table2 {
    actions {
        a1;
    }
}

control ingress {
    apply(table1);
    if (ether.etherType == 0x800) {
        apply(table1);
        apply(table2);
    }
    else {
        apply(table1);
    }
}
