header_type pkt_t {
  fields {
    a : 32;
    b : 32;
    c : 32;
    d : 8;
    e : 16;
  }
}

parser start {
  return parse_pkt;
}

header pkt_t pkt;

parser parse_pkt {
  extract (pkt);
  return ingress;
}

action action_0 (word) {
  bit_or (pkt.c, word, pkt.c);
  modify_field (pkt.d, 0);
  modify_field (pkt.e, 0);
}

action action_1 (halfword) {
  bit_or (pkt.e, pkt.e, halfword);
  modify_field (pkt.c, 0);
  modify_field (pkt.d, 0);
}

action action_2 (byte) {
  add_to_field (pkt.d, byte);
  modify_field (pkt.c, 0);
  modify_field (pkt.e, 0);
}

action setport (port) {
  modify_field (standard_metadata.egress_spec, port);
}

table table_0 {
  reads {
    pkt.b : exact;
  }
  actions {
    action_0;
    action_1;
    action_2;
  }
  size:1024;
}

table setting_port {
  reads {
    pkt.a : exact;
  }
  actions {
    setport;
  }
}

control ingress {
  apply(table_0);
  apply(setting_port);
}

