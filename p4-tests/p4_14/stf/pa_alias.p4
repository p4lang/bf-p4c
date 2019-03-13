@pragma pa_alias ingress pkt.f2 meta.m1
header_type pkt_t {
  fields {
    f1 : 8;
    f2 : 8;
    f3 : 8;
  }
}

header_type metadata_t {
  fields {
    m1 : 8;
    m2 : 8;
  }
}

parser start {
  return parse_pkt;
}

header pkt_t pkt;
metadata metadata_t meta;

parser parse_pkt {
  extract(pkt);
  set_metadata(meta.m2, 0x3);
  return ingress;
}

action first () {
  modify_field (pkt.f1, 0x8);
  modify_field (pkt.f2, 0x4);
  modify_field (pkt.f3, 0x2);
}

action second (param) {
  modify_field (pkt.f1, param);
  modify_field (pkt.f2, meta.m2);
  modify_field (pkt.f3, 0x5);
}

action setport (port) {
  modify_field (standard_metadata.egress_spec, port);
}

table test1 {
  reads {
    meta.m1 : exact;
  }
  actions {
    first;
    second;
  }
  size:1024;
}

table setting_port {
  reads {
    pkt.f1 : exact;
  }
  actions {
    setport;
  }
}

control ingress {
  apply(setting_port);
  apply(test1);
}
