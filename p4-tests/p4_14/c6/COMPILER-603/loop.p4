
header_type mpls_t {
    fields {
        label : 20;
        exp : 3;
        bos : 1;
        ttl : 8;
    }
}

parser start {
    return parse_mpls;
}

#define MPLS_DEPTH 4 
header mpls_t mpls[MPLS_DEPTH]; 
header mpls_t mpls_bos;

#define MPLS_BOS current(23,1)

parser parse_mpls { 
    return select(MPLS_BOS) { 
        0 : parse_mpls_no_bos; 
        1 : parse_mpls_bos; 
        // default : ingress; 
    } 
}

parser parse_mpls_no_bos{ 
    extract(mpls[next]); 
    return parse_mpls; 
}

parser parse_mpls_bos{ 
    extract(mpls_bos); 
    return ingress; 
}

action do_nothing(){}
action action_1(){
    modify_field(mpls_bos.label, 0);
}

table table1 {
    reads {
         mpls_bos : valid;
    }
    actions {
        do_nothing;
        action_1;
    }
}


control ingress {

    apply(table1);

}