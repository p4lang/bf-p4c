
header_type one_t {
    fields {
        a : 16;
    }
}

header_type two_t {
    fields {
        a : 16;
    }
}

header_type three_t {
    fields {
        a : 8;
    }
}

@pragma pa_container_size ingress one.a 8
header one_t one;
header two_t two;
header three_t three;

parser start { return p_one; }
parser p_one { extract(one);     return p_two; }
parser p_two { extract(two);     return p_three; }
parser p_three { extract(three); return ingress; }

action action_0 (){
    modify_field(one.a, two.a);
}

table t_one {
    reads {
         one.a : ternary;
         two.a : ternary;
         three.a : ternary;
    }
    actions {
       action_0;
    }
    size : 512;
}

control ingress {
    apply(t_one);
}
