header_type ipv4_t {
 fields {
  _pad0 : 4;
  ihl : 4;
  protocol : 8;
 }
}

header ipv4_t outer_ipv4;
header ipv4_t inner_ipv4;
header_type skip_4_t { fields { useless : 32; } }
header_type skip_40_t { fields { useless : 320; } }
header skip_4_t skip_4[3];
header skip_40_t skip_40[3];

parser start {
 extract(outer_ipv4);
 return select(outer_ipv4.ihl) {
  0x6: outer_ipv4_determine_after_skip_4;
  0xF: outer_ipv4_determine_after_skip_40;
 }
}
parser outer_ipv4_determine_after {
 return select(outer_ipv4.protocol) {
  0x04 : parse_inner_ipv4;
 }
}
parser outer_ipv4_determine_after_skip_4 {
 extract(skip_4[0]);
 return outer_ipv4_determine_after;
}
parser outer_ipv4_determine_after_skip_40 {
 extract(skip_40[0]);
 return outer_ipv4_determine_after;
}
parser parse_inner_ipv4 {
 extract(inner_ipv4);
 return ingress;
}
parser inner_ipv4_determine_after_skip_40 {
 extract(skip_40[1]);
 return ingress;
}

control ingress { }
