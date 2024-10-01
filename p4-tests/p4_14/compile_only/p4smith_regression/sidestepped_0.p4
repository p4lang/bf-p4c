/* p4smith seed: 656745066 */
#include <tofino/intrinsic_metadata.p4>
header_type remain {
  fields {
    soupcons : 8;
  }
}

header_type brownout {
  fields {
    indict : 64;
    loraine : 32;
  }
}

header remain discontinuitys;

header brownout bellicose;

parser start {
  return parse_discontinuitys;
}

parser parse_discontinuitys {
  extract(discontinuitys);
  return select (latest.soupcons) {
    236 : parse_bellicose;
  }
}

parser parse_bellicose {
  extract(bellicose);
  return ingress;
}

action pretext() {
  modify_field(standard_metadata.egress_spec, 1);
}

action circumnavigation(wainscottings) {
  subtract(discontinuitys.soupcons, 106, discontinuitys.soupcons);
  copy_header(bellicose, bellicose);
  bit_or(discontinuitys.soupcons, 0, discontinuitys.soupcons);
  add(discontinuitys.soupcons, discontinuitys.soupcons, 70);
}

action fuzzily(sweetening) {
  remove_header(discontinuitys);
  modify_field(discontinuitys.soupcons, discontinuitys.soupcons);
  bit_or(bellicose.indict, 511190172, bellicose.indict);
}

action harem() {
  copy_header(bellicose, bellicose);
  add_to_field(discontinuitys.soupcons, 120);
  add(discontinuitys.soupcons, 74, 0);
}

table sting {
  actions {
    pretext;
    }
  }

table accurate {
  reads {
    discontinuitys.soupcons mask 209 : range;
    bellicose.indict mask 41 : range;
    bellicose.loraine mask 89 : ternary;
  }
  actions {
    fuzzily;
    pretext;
  }
}

table chimera {
  reads {
    bellicose.loraine mask 71 : range;
    discontinuitys.soupcons mask 149 : exact;
  }
  actions {
    circumnavigation;
    fuzzily;
    harem;
  }
}

control ingress {
  if (((93 < discontinuitys.soupcons) and ((4095 <= discontinuitys.soupcons) or 
                                          (3551 == 3405)))) {
    apply(sting);
  }
  apply(accurate);
  if (((not(not((2683 != discontinuitys.soupcons))) or not((discontinuitys.soupcons > 
                                                           2843))) and 
      (discontinuitys.soupcons >= 1116))) {
    apply(chimera);
  }
}
