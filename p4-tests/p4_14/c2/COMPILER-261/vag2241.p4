#include <tofino/intrinsic_metadata.p4>

parser start {
    return ingress;
}

action a() {}

table t {
    reads {
        ig_intr_md.ingress_port : exact; 
    } 
    actions { 
        a; 
    } 
}
        
control ingress {
}

control egress {
    apply(t);
}

