/* p4smith seed: 484014267 */
#include <tofino/intrinsic_metadata.p4>
header_type romanticizes {
  fields {
    waterlines : 32;
    corolla : 16;
    newcomer : 32;
  }
}

header_type behavioural {
  fields {
    barns : 48;
    dr : 8;
  }
}

header romanticizes rachelle;

header behavioural chubs;

parser start {
  return parse_rachelle;
}

parser parse_rachelle {
  extract(rachelle);
  return select (latest.corolla) {
    2705 : parse_chubs;
  }
}

parser parse_chubs {
  extract(chubs);
  return ingress;
}

action unbridgeable() {
  modify_field(standard_metadata.egress_spec, 1);
}

action purposes() {
  bit_or(rachelle.waterlines, rachelle.waterlines, 513276365);
  add_to_field(rachelle.waterlines, 268841909);
  remove_header(rachelle);
  modify_field(rachelle.corolla, rachelle.corolla);
}

table stimulating {
  actions {
    unbridgeable;
    }
  }

table unplugs {
  reads {
    chubs.dr mask 51 : exact;
  }
  actions {
    purposes;
    unbridgeable;
  }
}

control ingress {
  if ((chubs.dr == 4033)) {
    apply(stimulating);
  }
  if ((chubs.dr > 1583)) {
    apply(unplugs);
  }
}
