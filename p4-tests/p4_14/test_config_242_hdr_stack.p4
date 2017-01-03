header_type hdr0_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
    }
}

header_type hdr1_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
   }
}

header_type hdr2_t {
    fields {
        a : 16;
        b : 8;
        c : 8;
   }
}

header_type meta_t {
    fields {
       x : 8;
       y : 8;
       z : 16;
    }
}

header_type stack_t {
    fields {
       w : 4;
       x : 4;
       y : 8;
       z : 16;
    }
}

header hdr0_t hdr0;
header hdr1_t hdr1;
header hdr2_t hdr2;
header stack_t stack[3];

metadata meta_t meta;


parser start {
   return p_hdr0;
}

parser p_hdr0 {
   extract(hdr0);
   return select(hdr0.c){
      0 : p_hdr1;
      1 : p_hdr2;
   }
}

parser p_hdr1 {
   extract(hdr1);
   return p_stack;
}

parser p_hdr2 {
   extract(hdr2);
   return ingress;
}

parser p_stack {
   extract(stack[next]);
   return select (latest.x) {
       0 : p_stack;
       1 : p_hdr2;
       default : ingress;
   }
}

action do_nothing(){}

action action_0(p){
   modify_field(stack[0].z, meta.z);  
}
action action_1(p){
   modify_field(stack[1].w, stack[2].x);  
}

table table_i0 {
    reads {
        hdr0.a : ternary;
    }
    actions {
        do_nothing;
        action_0;
    }
    size : 512;
}
table table_i1 {
    reads {
        hdr0.a : ternary;
    }
    actions {
        do_nothing;
        action_1;
    }
    size : 1024;
}

control ingress {
  apply(table_i0);
  apply(table_i1);
}