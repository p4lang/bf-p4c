header_type madonnas {
  fields {
    forbearing : 48;
    betterment : 16 (saturating);
  }
}

header_type hairballs {
  fields {
    hijackings : 32 (signed);
    hardheartedly : 64 (signed);
    edema : 64;
    kfcs : 48 (signed, saturating);
  }
}

header_type menorahs {
  fields {
    grandeur : 16;
    workroom : 16;
    loathsome : 8 (signed);
    medallists : 16;
    nuthouses : 16;
  }
}

header_type manners {
  fields {
    rarebits : 128;
    impiety : 48 (signed, saturating);
    guam : 32;
    persimmon : 48;
    deductibles : 16;
    walkover : 16;
  }
}

header_type ascot {
  fields {
    hilbert : 48;
    rapacious : 16;
    shoeshines : 32;
    troops : 64;
  }
}

header madonnas gormandize;

header hairballs numerology;

header menorahs melissa;

header manners numskulls;

header ascot regent;

parser start {
  return parse_gormandize;
}

parser parse_gormandize {
  extract(gormandize);
  return select (current(0, 8)) {
    2 : parse_numerology;
    255 : parse_numskulls;
  }
}

parser parse_numerology {
  extract(numerology);
  return select (current(0, 8)) {
    0 : parse_numskulls;
    122 : parse_melissa;
  }
}

parser parse_melissa {
  extract(melissa);
  return select (latest.medallists) {
    29064 : parse_numskulls;
  }
}

parser parse_numskulls {
  extract(numskulls);
  return select (current(0, 8)) {
    113 : parse_regent;
  }
}

parser parse_regent {
  extract(regent);
  return ingress;
}

control ingress { }
