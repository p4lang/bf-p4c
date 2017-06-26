header_type hdr_t { 
    fields { 
        useless : 32; 
        opts : *; 
    } 
    length : useless * 2; 
    max_length : 60; 
}

header hdr_t hdr;

parser start { 
    extract(hdr); 
    return ingress; 
}

table tlpm { 
    reads { 
        hdr.useless : lpm; 
    } 
    actions { 
        _nop; 
    } 
}

action _nop() { no_op(); }

control ingress { 
    apply(tlpm); 
}

control egress { 
}

