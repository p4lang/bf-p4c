#include "tofino/intrinsic_metadata.p4"

header_type hdr0_t {
  fields {
    a : 4;
    b : 6;
    c : 2;
    d : 20;
    e : 16;
    f : 8;
    g : 8;
    h : 128;
    i : 128;
  }
}

@pragma pa_container_size ingress hdr0.a 32
@pragma pa_container_size ingress hdr0.b 32
@pragma pa_container_size ingress hdr0.c 32

@pragma pa_container_size ingress hdr0.e 16
@pragma pa_solitary ingress hdr0.e
@pragma pa_solitary ingress hdr0.f
@pragma pa_container_size ingress hdr0.g 16
@pragma pa_container_size ingress hdr0.h 16

header hdr0_t hdr0;

parser start {
  return p_hdr0;
}

parser p_hdr0 {
  extract (hdr0);
  return ingress;
}

action act1 (port) {
  modify_field (ig_intr_md_for_tm.ucast_egress_port, port);
}

table table_i0 {
  reads {
    hdr0.a : exact;
    hdr0.b : ternary;
    hdr0.c : ternary;
    hdr0.d : exact;
    hdr0.e : exact;
    hdr0.f : exact;
    hdr0.g : exact;
    hdr0.h : exact;
    hdr0.i : exact;
  }
  actions {
    act1;
  }
  size: 1024;
}

control ingress {
  apply (table_i0);
}


