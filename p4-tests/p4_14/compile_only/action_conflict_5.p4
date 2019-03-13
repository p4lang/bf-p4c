header_type pkt_t {
  fields {
    f1 : 10;
    f2 : 10;
    f3 : 10;
    f4 : 2;
  }
}

header_type metadata_t {
    fields {
        f : 8;
    }
}

parser start {
  return parse_pkt;
}

header pkt_t pkt;
metadata metadata_t m;

parser parse_pkt {
  extract (pkt);
  set_metadata(m.f, 0x4);
  return ingress;
}

// Tofino ALU requires m.f and pkt.f1 to be placed at the exact same alignment
// If this does not happen, test will fail with the instruction slot message
action action_0 () {
  modify_field (pkt.f1, m.f);
  modify_field (pkt.f2, 0);
  modify_field (pkt.f3, 3);
  modify_field (pkt.f4, 1);
}

action setport (port) {
  modify_field (standard_metadata.egress_spec, port);
}

table table_0 {
  reads {
    pkt.f1 : exact;
  }
  actions {
    action_0;
  }
  size:1024;
}

table setting_port {
  reads {
    pkt.f2 : exact;
  }
  actions {
    setport;
  }
}

control ingress {
  apply(table_0);
  apply(setting_port);
}

