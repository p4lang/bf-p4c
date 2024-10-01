/* p4smith seed: 562080674 */
#include <tofino/intrinsic_metadata.p4>
header_type unacknowledged {
  fields {
    modelled : 64;
    bowed : 64;
    demagnetize : 16;
    renumbered : 48;
  }
}

header_type endocrinologists {
  fields {
    valets : 32;
  }
}

header_type hellos {
  fields {
    craftspeople : 16;
  }
}

header_type photosynthesiss {
  fields {
    ginsus : 16;
    journal : 16;
    hitchhikers : 32;
    footballs : 16;
    wellingtons : 16;
    appurtenance : 16;
  }
}

header_type remissions {
  fields {
    garb : 16;
    curers : 32;
    punching : 8;
    satiating : 48;
    prawns : 32;
    cherts : 32;
  }
}

header unacknowledged simians;

header endocrinologists flooder;

header hellos gaff;

header photosynthesiss iota;

header remissions milkens;

parser start {
  return parse_simians;
}

parser parse_simians {
  extract(simians);
  return select (current(0, 8)) {
    255 : parse_flooder;
    48 : parse_iota;
    43 : parse_milkens;
  }
}

parser parse_flooder {
  extract(flooder);
  return select (current(0, 8)) {
    226 : parse_gaff;
    0 : parse_iota;
  }
}

parser parse_gaff {
  extract(gaff);
  return select (latest.craftspeople) {
    25114 : parse_iota;
  }
}

parser parse_iota {
  extract(iota);
  return select (latest.appurtenance) {
    52218 : parse_milkens;
  }
}

parser parse_milkens {
  extract(milkens);
  return ingress;
}

action classicists() {
  modify_field(standard_metadata.egress_spec, 1);
}

action beads() {
  remove_header(simians);
  bit_and(milkens.punching, 2, gaff.craftspeople);
  bit_or(gaff.craftspeople, 2, iota.journal);
}

table tarball {
  actions {
    classicists;
    }
  }

table halcyon {
  actions {
    beads;
    classicists;
    }
  }

table incredibilitys {
  actions {
    classicists;
    }
  }

table travailing {
  actions {
    beads;
    }
  }

table armistices {
  reads {
    flooder.valets : ternary;
    flooder.valets : ternary;
  }
  actions {
    beads;
  }
}

control ingress {
  apply(tarball);
  if (((2 >= milkens.punching) and valid(gaff))) {
    apply(halcyon);
  }
  if (((milkens.punching > milkens.punching) or ((milkens.punching <= 
                                                 milkens.punching) or 
                                                (valid(milkens) and (
                                                                    milkens.punching > 
                                                                    5))))) {
    apply(incredibilitys);
  }
  apply(travailing);
  apply(armistices);
}
