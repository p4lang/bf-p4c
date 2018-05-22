/* p4smith seed: 28957075 */
#include <tofino/intrinsic_metadata.p4>
header_type storefronts {
  fields {
    catalytic : 16;
    comedic : 32;
  }
}

header_type loin {
  fields {
    funnel : 32;
    tepidnesss : 16;
    recruit : 32;
    nitrites : 16;
    burrs : 16;
    embellish : 16;
  }
}

header_type stats {
  fields {
    incognitos : 64;
  }
}

header storefronts amphitheatres;

header loin proverbs;

header stats ajaxs;

parser start {
  return parse_amphitheatres;
}

parser parse_amphitheatres {
  extract(amphitheatres);
  return select (current(0, 8)) {
    22 : parse_proverbs;
    74 : parse_ajaxs;
  }
}

parser parse_proverbs {
  extract(proverbs);
  return select (latest.tepidnesss) {
    37469 : parse_ajaxs;
  }
}

parser parse_ajaxs {
  extract(ajaxs);
  return ingress;
}

action tippled() {
  modify_field(standard_metadata.egress_spec, 1);
}

action knockwursts(chernenkos) {
  add(proverbs.recruit, 1407683855, proverbs.funnel);
  add(proverbs.burrs, amphitheatres.catalytic, proverbs.burrs);
  bit_xor(proverbs.tepidnesss, amphitheatres.catalytic, 27339);
  subtract(amphitheatres.catalytic, 22401, proverbs.tepidnesss);
}

action hatfield(constructions, montaigne) {
  bit_and(amphitheatres.catalytic, proverbs.burrs, 3237);
}

action defalcations(chiropodist, remedial) {
  bit_and(proverbs.recruit, proverbs.funnel, 1044694640);
  add(proverbs.funnel, 883352515, proverbs.recruit);
  subtract(proverbs.recruit, 1714282676, 1924590740);
}

action disheartening() {
  add_header(ajaxs);
}

table kong {
  actions {
    tippled;
    }
  }

table sleeves {
  reads {
    proverbs.embellish mask 255 : ternary;
    amphitheatres.catalytic : range;
  }
  actions {
    defalcations;
    disheartening;
    knockwursts;
  }
}

table quail {
  actions {
    disheartening;
    knockwursts;
    tippled;
    }
  }

table swordplay {
  actions {
    defalcations;
    disheartening;
    knockwursts;
    tippled;
    }
  }

table certainly {
  reads {
    proverbs.nitrites : exact;
    proverbs.tepidnesss : range;
  }
  actions {
    defalcations;
    tippled;
  }
}

control ingress {
  if ((1408 != 628)) {
    apply(kong);
  }
  if ((1447 != 727)) {
    apply(sleeves);
  }
  apply(quail);
  if ((4095 != 2492)) {
    apply(swordplay);
  }
  if ((232 < 2998)) {
    apply(certainly);
  }
}
