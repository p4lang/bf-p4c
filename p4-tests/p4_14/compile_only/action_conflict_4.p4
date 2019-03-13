header_type pkt_t {
  fields {
    a : 49;
    b : 17;
    c : 14;
  }
}

parser start {
  return parse_pkt;
}

header pkt_t pkt;
header pkt_t pkt1;

parser parse_pkt {
  extract (pkt);
  extract (pkt1);
  return ingress;
}

action action_0 (p0) {
  modify_field (pkt.a, p0);
}

action action_1 (p0) {
  modify_field (pkt.b, p0);
}


action action_2 () {
  modify_field (pkt.a, pkt1.a);
  modify_field (pkt.b, pkt1.b);
}

action action_3 () {
  modify_field (pkt.a, pkt1.a);
  modify_field (pkt.b, pkt1.b);
  modify_field (pkt.c, pkt1.c);
}

action setport (port) {
  modify_field (standard_metadata.egress_spec, port);
}

table table_0 {
  reads {
    pkt.a : exact;
    pkt.b : exact;
  }
  actions {
    action_0;
    action_1;
    action_2;
    action_3;
  }
  size:1024;
}

table setting_port {
  reads {
    pkt.c : exact;
  }
  actions {
    setport;
  }
}

control ingress {
  apply(table_0);
  apply(setting_port);
}

