header_type pkt_t {
  fields {
    f1 : 2;
    f2 : 2;
    f3 : 2;
    f4 : 2;

    f5 : 2;
    f6 : 2;
    f7 : 2;
    f8 : 2;

    f9 : 2;
    fa : 2;
    fb : 2;
    fc : 2;
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

action action_0 () {
  modify_field (pkt.f1, pkt.f5);
}

action action_1 () {
  modify_field (pkt.f1, pkt.f8);
}

action action_2 () {
  modify_field (pkt.f1, pkt.f5);
  modify_field (pkt.f2, pkt.fa);
}

action action_3 () {
  modify_field (pkt.f1, pkt.f5);
  modify_field (pkt.f2, pkt.f6);
  modify_field (pkt.f3, pkt.fb);
  modify_field (pkt.f4, pkt.fc);
}

action action_4 () {
  modify_field (pkt.f1, pkt.f5);
  modify_field (pkt.f3, pkt.f7);
}

action setport (port) {
  modify_field (standard_metadata.egress_spec, port);
}

table table_0 {
  reads {
    pkt.f3 : exact;
    pkt.f4 : exact;
    pkt.f6 : exact;
    pkt.f7 : exact;
  }
  actions {
    action_0;
    action_1;
    action_2;
    action_3;
    action_4;
  }
  size:1024;
}

table setting_port {
  reads {
    pkt.fc : exact;
  }
  actions {
    setport;
  }
}

control ingress {
  apply(table_0);
  apply(setting_port);
}

