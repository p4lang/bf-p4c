/* p4smith seed: 172670217 */
#include <tofino/intrinsic_metadata.p4>
header_type hoping {
  fields {
    particularize : 6;
    centipede : 4 (saturating);
    rosewoods : 6;
  }
}

header_type putties {
  fields {
    brigantines : 4;
    tubelesss : 12;
    receivers : 32;
    concentric : 16;
    guerras : 16;
    rating : 48 (signed, saturating);
  }
}

header_type hatreds {
  fields {
    slaking : 4;
    bicycled : 4;
  }
}

header hoping adolfo;

header putties freebies;

header hatreds lucille;

register deliberates {
  width : 1;
  instance_count : 125;
}

register tripwires {
  width : 64;
  instance_count : 650;
}

register neighborly {
  width : 32;
  instance_count : 105;
}

register rigas {
  width : 16;
  instance_count : 975;
}

register cottagers {
  width : 64;
  instance_count : 224;
}

register coyly {
  width : 16;
  instance_count : 110;
}

register placebos {
  width : 1;
  instance_count : 1024;
}

register explicating {
  width : 8;
  instance_count : 847;
}

parser start {
  return parse_adolfo;
}

parser parse_adolfo {
  extract(adolfo);
  return select (latest.rosewoods) {
    5 : parse_lucille;
    29 : parse_freebies;
  }
}

parser parse_freebies {
  extract(freebies);
  return select (latest.brigantines) {
    6 : parse_lucille;
  }
}

parser parse_lucille {
  extract(lucille);
  return ingress;
}

field_list squeezes {
  freebies.guerras;
}

field_list_calculation iciness {
  input {
    squeezes;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field freebies.guerras {
  update iciness;
  update iciness;
  verify iciness;
  update iciness;
}

action wavelengths() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action shebangs(physios, petioles) {
  add_header(adolfo);
  add_to_field(freebies.receivers, freebies.receivers);
  bit_and(freebies.concentric, freebies.concentric, 3196849635614224227);
  add_header(freebies);
  bit_or(freebies.guerras, freebies.guerras, 3118852013962153576);
}

action ageism(holing, kilogram) {
  add_to_field(freebies.concentric, freebies.concentric);
  add(freebies.guerras, 4611686018427387903, 2728446865345586695);
  bit_or(freebies.receivers, 3537577083758640751, 3684662727473020981);
}

action acadia(bespangle) {
  modify_field_rng_uniform(lucille.slaking, 0, 15);
  bit_or(freebies.receivers, 4611686018427387903, 120967943045954190);
  bit_and(freebies.guerras, 4245896931873123217, freebies.guerras);
  bit_and(freebies.concentric, 1459096803899544812, freebies.concentric);
  add_header(freebies);
  add_header(lucille);
  add_header(adolfo);
  add_header(lucille);
}

action secrets(alcoa) {
  subtract_from_field(freebies.receivers, freebies.receivers);
  add_to_field(freebies.concentric, freebies.guerras);
  remove_header(lucille);
  bit_or(freebies.guerras, 1003429134393215338, 4611686018427387903);
  modify_field_rng_uniform(adolfo.particularize, 0, 63);
  modify_field(freebies.rating, 110422659);
  add_header(adolfo);
  copy_header(lucille, lucille);
}

action_profile choirs {
  actions {
    secrets;
    acadia;
    shebangs;
  }
  size : 19;
}

action_profile glamorously {
  actions {
    acadia;
    ageism;
    wavelengths;
  }
  size : 30;
}

action_profile barnacles {
  actions {
    secrets;
    acadia;
    ageism;
    shebangs;
    wavelengths;
  }
  size : 6;
}

action_profile pronounceable {
  actions {
    secrets;
    acadia;
    ageism;
  }
  size : 13;
}

table absurdly {
  actions {
    wavelengths;
    }
  }

table extant {
  action_profile : choirs;
  }

table bravenesss {
  reads {
    adolfo : valid;
    adolfo.centipede : exact;
    adolfo.rosewoods : exact;
    freebies : valid;
    freebies.concentric : lpm;
    freebies.guerras : range;
    lucille : valid;
    lucille.slaking : exact;
    lucille.bicycled mask 3 : exact;
  }
  action_profile : barnacles;
}

table kilometres {
  actions {
    acadia;
    }
  }

table teachings {
  reads {
    adolfo : valid;
    adolfo.centipede : exact;
    adolfo.rosewoods : range;
  }
  actions {
    shebangs;
    wavelengths;
  }
}

table administrating {
  reads {
    freebies : valid;
    lucille.slaking : ternary;
  }
  action_profile : pronounceable;
}

table arroyo {
  action_profile : glamorously;
  }

table scoliosiss {
  reads {
    lucille : valid;
    lucille.slaking : ternary;
    lucille.bicycled : ternary;
  }
  actions {
    acadia;
    secrets;
    wavelengths;
  }
}

table jabot {
  reads {
    lucille.slaking : exact;
    lucille.bicycled : ternary;
  }
  actions {
    
  }
}

table fishmongers {
  actions {
    
    }
  }

table performer {
  actions {
    acadia;
    shebangs;
    }
  }

table interrupted {
  reads {
    lucille : valid;
    lucille.slaking : exact;
    lucille.bicycled : exact;
  }
  actions {
    acadia;
    ageism;
    wavelengths;
  }
}

table rnas {
  reads {
    adolfo : valid;
    freebies.brigantines : exact;
    freebies.tubelesss mask 0 : ternary;
    freebies.receivers : exact;
    freebies.concentric : exact;
  }
  actions {
    
  }
}

table quackery {
  reads {
    adolfo : valid;
  }
  actions {
    ageism;
  }
}

table attenders {
  actions {
    ageism;
    shebangs;
    wavelengths;
    }
  }

table signified {
  reads {
    adolfo.particularize : exact;
    freebies : valid;
    freebies.receivers : exact;
    freebies.guerras mask 15 : exact;
    freebies.rating mask 39 : exact;
    lucille.slaking : exact;
  }
  actions {
    ageism;
    shebangs;
    wavelengths;
  }
}

table broods {
  reads {
    adolfo.centipede : exact;
    adolfo.rosewoods : exact;
    lucille : valid;
    lucille.slaking mask 1 : exact;
  }
  actions {
    acadia;
    secrets;
  }
}

control ingress {
  apply(extant);
  if (((true and (lucille.bicycled < 32)) or (false and
      (2861 != freebies.rating)))) {
    if (not(false)) {
      apply(bravenesss);
    }
    if (valid(lucille)) {
      apply(kilometres);
      if ((valid(freebies) or false)) {
        apply(teachings) {
          hit { }
        }
      } else {
        apply(administrating);
        apply(arroyo);
      }
    }
  } else {
    apply(scoliosiss);
    apply(jabot);
  }
  if ((freebies.guerras == freebies.guerras)) {
    apply(fishmongers);
    apply(performer);
  } else {
    if (not(valid(freebies))) {
      apply(interrupted);
    } else {
      apply(rnas);
      apply(quackery);
      apply(attenders);
    }
  }
  apply(signified);
  apply(broods);
}

