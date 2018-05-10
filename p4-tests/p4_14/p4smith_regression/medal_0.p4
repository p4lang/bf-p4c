/* p4smith seed: 846188594 */
#include <tofino/intrinsic_metadata.p4>
header_type onetime {
  fields {
    nightstick : 32;
    dreamer : 8;
    nitroglycerines : 16;
  }
}

header_type plodding {
  fields {
    comatose : 32;
    commits : 32;
    adders : 16;
    pictographs : 16;
    succoured : 16;
    placekickers : 16;
  }
}

header onetime cragginess;

header plodding barometric;

parser start {
  return parse_cragginess;
}

parser parse_cragginess {
  extract(cragginess);
  return select (latest.dreamer) {
    46 : parse_barometric;
  }
}

parser parse_barometric {
  extract(barometric);
  return ingress;
}

action debates() {
  modify_field(standard_metadata.egress_spec, 1);
}

action humanoids(guardsman) {
  subtract(barometric.commits, cragginess.nightstick, 346816442);
  bit_xor(barometric.succoured, 1040, barometric.placekickers);
  bit_and(cragginess.dreamer, cragginess.dreamer, cragginess.dreamer);
  add_to_field(barometric.adders, barometric.placekickers);
}

action bernays(lurker) {
  remove_header(barometric);
}

table hairdryers {
  actions {
    debates;
    }
  }

table polymorphous {
  reads {
    cragginess : valid;
    cragginess.nitroglycerines : exact;
    barometric : valid;
  }
  actions {
    bernays;
  }
}

control ingress {
  if ((not((cragginess.dreamer == cragginess.dreamer)) and (2186 <= cragginess.dreamer))) {
    apply(hairdryers);
  }
  if ((311 > 3794)) {
    apply(polymorphous);
  }
}
