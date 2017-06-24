#ifdef __TARGET_TOFINO__ 
#include <tofino/constants.p4> 
#include <tofino/intrinsic_metadata.p4> 
#include <tofino/primitives.p4> 
#include <tofino/pktgen_headers.p4> 
#include <tofino/stateful_alu_blackbox.p4> 
#endif

parser start { 
    return ingress; 
}

table supertable { 
    reads { 
        ig_intr_md.ingress_port : exact; 
    } 
    actions { 
        superaction; 
    } 
}

header_type useless { 
    fields { 
        f : 32; 
    } 
} 
header useless h;

action superaction() { 
    add_header(h); 
}

control ingress {
    apply(supertable); 
}

control egress { 
}

