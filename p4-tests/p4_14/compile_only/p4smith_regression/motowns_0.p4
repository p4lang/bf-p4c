/* p4smith seed: 716736243 */
#include <tofino/intrinsic_metadata.p4>
header_type maw {
  fields {
    trombonists : 16;
    dir : 32;
    bumpiness : 32;
    growls : 8;
    purified : 16;
    metacarpals : 32;
  }
}

header_type mushs {
  fields {
    de : 16;
    medicos : 8;
    constructive : 64;
    tenons : 32;
    handballs : 16;
  }
}

header_type immediacy {
  fields {
    shapiro : 8;
    sheaf : 32;
    newsier : 32;
    argentinians : 16;
  }
}

header_type date {
  fields {
    unmanliest : 8;
    clapboarded : 16;
    wanderlust : 16;
    tannin : 8;
    closings : 16;
    wifeless : 16;
  }
}

header maw raspy;

header mushs tracker;

header immediacy nabs;

header date polygamists;

parser start {
  return parse_raspy;
}

parser parse_raspy {
  extract(raspy);
  return select (latest.growls) {
    43 : parse_polygamists;
    123 : parse_nabs;
    239 : parse_tracker;
  }
}

parser parse_tracker {
  extract(tracker);
  return select (latest.medicos) {
    231 : parse_nabs;
  }
}

parser parse_nabs {
  extract(nabs);
  return select (current(0, 8)) {
    84 : parse_polygamists;
  }
}

parser parse_polygamists {
  extract(polygamists);
  return ingress;
}

action sojourning() {
  modify_field(standard_metadata.egress_spec, 1);
}

action outranks() {
  bit_or(raspy.trombonists, raspy.trombonists, polygamists.closings);
}

table vendors {
  actions {
    sojourning;
    }
  }

table folklorist {
  reads {
    nabs.sheaf mask 255 : ternary;
  }
  actions {
    outranks;
  }
}

control ingress {
  // Fails with hash parity enabled. 
  // if ((not((3819 >= polygamists.tannin)) and not(((3084 > tracker.medicos) and 
  //                                                (tracker.medicos >= 
  if (not((3819 >= polygamists.tannin))) {
    apply(vendors);
  }
  apply(folklorist);
}
