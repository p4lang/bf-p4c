@pragma pa_do_not_bridge ingress meta.m
@pragma pa_container_size ingress pkt.f1 8
@pragma pa_container_size ingress pkt.f2 8
@pragma pa_container_size ingress pkt.f3 8
@pragma pa_container_size egress pkt.f1 8
@pragma pa_container_size egress pkt.f2 8
@pragma pa_container_size egress pkt.f3 8
@pragma pa_container_size ingress meta.m 8
@pragma pa_container_size egress meta.m 8
header_type pkt_t {
  fields {
    f1 : 8;
    f2 : 8;
    f3 : 8;
  }
}

header_type metadata_t {
  fields {
    m : 8;
  }
}

parser start {
  return parse_pkt;
}

header pkt_t pkt;
metadata metadata_t meta;

parser parse_pkt {
  extract(pkt);
  return ingress;
}

action first () {
  modify_field (pkt.f1, 0x8);
  modify_field (pkt.f2, meta.m);
  modify_field (meta.m, 0x2);
}

action second (param) {
  modify_field (pkt.f1, param);
  modify_field (pkt.f3, meta.m);
}

action setport (port) {
  modify_field (standard_metadata.egress_spec, port);
}

table test1 {
  reads {
    pkt.f2 : exact;
  }
  actions {
    first;
  }
  size:1024;
}

table test2 {
  reads {
    meta.m : exact;
  }
  actions {
    second;
  }
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
  apply(test1);
  apply(setting_port);
}

control egress {
  apply(test2);
}
