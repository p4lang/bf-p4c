/* p4smith seed: 62065434 */
#include <tofino/intrinsic_metadata.p4>
header_type kaleidoscope {
  fields {
    causeless : 8;
    ergs : 8;
    andromeda : 16;
    lumberers : 32;
  }
}

header_type stardoms {
  fields {
    fraternize : 32;
    obamas : 32;
    pillion : 16;
    appalled : 8;
    reservoirs : 48;
    gabriel : 32;
  }
}

header kaleidoscope syndicalism;

header stardoms cryogenic;

parser start {
  return parse_syndicalism;
}

parser parse_syndicalism {
  extract(syndicalism);
  return select (current(0, 8)) {
    197 : parse_cryogenic;
  }
}

parser parse_cryogenic {
  extract(cryogenic);
  return ingress;
}

action throttling() {
  modify_field(standard_metadata.egress_spec, 1);
}

action bilinguals(misappropriations) {
  bit_or(syndicalism.ergs, cryogenic.appalled, cryogenic.appalled);
}

action dyslexic() {
  bit_and(cryogenic.reservoirs, 1686310694, 552370383);
  subtract_from_field(cryogenic.appalled, 139);
  bit_xor(syndicalism.ergs, syndicalism.ergs, syndicalism.causeless);
}

action upchucking(mastiffs) {
  modify_field(cryogenic.appalled, syndicalism.causeless);
  modify_field(cryogenic.reservoirs, 1048702246);
  add_header(cryogenic);
  bit_or(cryogenic.reservoirs, cryogenic.reservoirs, cryogenic.reservoirs);
}

table kennel {
  actions {
    throttling;
    }
  }

table plats {
  reads {
    syndicalism.lumberers mask 32 : range;
    cryogenic.obamas : exact;
  }
  actions {
    bilinguals;
    dyslexic;
    throttling;
  }
}

table bernhardt {
  actions {
    dyslexic;
    throttling;
    upchucking;
    }
  }

control ingress {
  apply(kennel);
  if ((1112 == cryogenic.appalled)) {
    apply(plats);
  }
  apply(bernhardt);
}
