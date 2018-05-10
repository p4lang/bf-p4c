header_type h_t {
  fields {
    f : 32;
  }
}

header h_t h;

parser start {
  return parse_h;
}

parser parse_h {
  extract(h);
  return ingress;
}

action a() {
  subtract_from_field(h.f, 10);
}


table t {
  actions {
    a;
    }
  }

control ingress {
  if (valid(h)) {
    apply(t);
  }
}
