header_type h_t {
  fields {
    f : 8;
    g : *;
  }
  length : f;
  max_length : 32;
}

header h_t h;

parser start {
  extract(h);
  return ingress;
}

action a() {
  add_to_field(h.g, 1);
}    
    
table t {
  actions { a; }
  default_action: a;
}        

control ingress {
  apply(t);
}    
   