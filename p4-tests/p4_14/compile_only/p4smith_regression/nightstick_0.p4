/* p4smith seed: 542908619 */
#include <tofino/intrinsic_metadata.p4>
header_type overgrowing {
  fields {
    label : 4;
    fixatives : 48;
    disharmony : 4;
  }
}

header_type plateful {
  fields {
    raillerys : 1;
    mammograms : 7;
    billhook : 16;
    sleepers : 8;
    winnipeg : 16 (saturating);
    morgue : 16;
  }
}

header_type cyclopedia {
  fields {
    bernard : 5;
    positives : 3;
    marijuana : 32 (signed);
    farriers : 16;
  }
}

header_type eloise {
  fields {
    bloodied : 48;
    surmounting : 16;
  }
}

header_type maladjustment {
  fields {
    wm : 4;
    sultans : 4;
  }
}

header_type unaffiliated {
  fields {
    warmers : 4;
    zingers : 4;
    broader : 48;
    pinewood : 48 (signed);
  }
}

header_type fungicides {
  fields {
    catchphrase : 6;
    tautologically : 48;
    groynes : 8;
    carefulnesss : 32;
    crampons : 2;
    fondly : 48 (signed);
  }
}

header_type backslides {
  fields {
    diked : 8;
  }
}

header overgrowing statuette;

header plateful ridiculous;

header cyclopedia hook;

header eloise refuters;

header maladjustment collieries;

header unaffiliated carlys;

header fungicides ymca;

header backslides dogtrotted;

parser start {
  return parse_statuette;
}

parser parse_statuette {
  extract(statuette);
  return select (latest.disharmony) {
    4 : parse_refuters;
    2 : parse_ridiculous;
    0 : parse_carlys;
  }
}

parser parse_ridiculous {
  extract(ridiculous);
  return select (latest.billhook) {
    14089 : parse_hook;
    32767 : parse_ymca;
  }
}

parser parse_hook {
  extract(hook);
  return select (current(0, 8)) {
    0 : parse_refuters;
    34 : parse_ymca;
    127 : parse_collieries;
  }
}

parser parse_refuters {
  extract(refuters);
  return select (latest.surmounting) {
    21890 : parse_dogtrotted;
    9903 : parse_collieries;
    12698 : parse_carlys;
  }
}

parser parse_collieries {
  extract(collieries);
  return select (latest.wm) {
    3 : parse_dogtrotted;
    6 : parse_carlys;
  }
}

parser parse_carlys {
  extract(carlys);
  return select (latest.zingers) {
    6 : parse_dogtrotted;
    2 : parse_ymca;
  }
}

parser parse_ymca {
  extract(ymca);
  return select (latest.groynes) {
    7 : parse_dogtrotted;
  }
}

parser parse_dogtrotted {
  extract(dogtrotted);
  return ingress;
}

field_list malay {
  hook.farriers;
  refuters.surmounting;
}

field_list sanchezs {
  ymca.fondly;
  ridiculous.sleepers;
  ridiculous.billhook;
  carlys.pinewood;
  hook;
  refuters.bloodied;
  dogtrotted.diked;
}

field_list bizarre {
  dogtrotted.diked;
  carlys.broader;
}

field_list looseness {
  ridiculous.sleepers;
  ridiculous.winnipeg;
  refuters.surmounting;
}

field_list_calculation sambaing {
  input {
    sanchezs;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation cavings {
  input {
    sanchezs;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation juncture {
  input {
    bizarre;
  }
  algorithm : csum16;
  output_width : 16;
}

field_list_calculation supertankers {
  input {
    bizarre;
  }
  algorithm : csum16;
  output_width : 16;
}

calculated_field ridiculous.billhook {
  verify sambaing;
}

calculated_field refuters.surmounting {
  verify cavings;
  update sambaing;
  update supertankers;
}

calculated_field ridiculous.winnipeg {
  update cavings;
  verify supertankers;
}

action erickas() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action catalans(inconsiderable) {
  modify_field(ridiculous.mammograms, 90);
  modify_field_rng_uniform(statuette.label, 0, 3);
}

action_profile considered {
  actions {
    erickas;
  }
  size : 8;
}

action_profile substantiate {
  actions {
    erickas;
  }
  size : 26;
}

table swills {
  actions {
    erickas;
    }
  }

table womanlinesss {
  reads {
    statuette : valid;
    ridiculous.raillerys : ternary;
    ridiculous.mammograms : exact;
    ridiculous.billhook : ternary;
    ridiculous.sleepers : lpm;
    ridiculous.winnipeg mask 2 : lpm;
    hook : valid;
    hook.farriers : exact;
  }
  actions {
    
  }
}

table interlinings {
  reads {
    ymca : valid;
    ymca.catchphrase : exact;
    ymca.tautologically : exact;
    ymca.groynes : lpm;
    ymca.crampons : exact;
    ymca.fondly : ternary;
    dogtrotted : valid;
    dogtrotted.diked : ternary;
  }
  action_profile : substantiate;
}

table fauvisms {
  actions {
    catalans;
    }
  }

table unlocked {
  reads {
    statuette : valid;
    hook : valid;
    hook.bernard mask 2 : exact;
    hook.positives : exact;
    hook.marijuana : exact;
    hook.farriers : ternary;
  }
  action_profile : considered;
}

table snatchers {
  reads {
    ridiculous : valid;
    ridiculous.raillerys : ternary;
    ridiculous.mammograms : lpm;
    ridiculous.billhook : exact;
    ridiculous.winnipeg : exact;
    ridiculous.morgue mask 12 : range;
    refuters.bloodied mask 19 : ternary;
    refuters.surmounting mask 11 : lpm;
    collieries : valid;
  }
  actions {
    catalans;
  }
}

table abs {
  actions {
    
    }
  }

table deloress {
  reads {
    collieries : valid;
    collieries.wm : exact;
    collieries.sultans : exact;
  }
  actions {
    
  }
}

table shillong {
  actions {
    catalans;
    erickas;
    }
  }

table denture {
  reads {
    statuette.label : range;
    statuette.fixatives mask 40 : exact;
    statuette.disharmony : exact;
    hook : valid;
    refuters : valid;
    refuters.bloodied mask 42 : exact;
    refuters.surmounting mask 5 : lpm;
  }
  actions {
    
  }
}

table titicaca {
  reads {
    statuette.disharmony : ternary;
    ridiculous.morgue : exact;
    hook : valid;
    hook.bernard mask 3 : exact;
    hook.positives : exact;
    hook.marijuana : exact;
    hook.farriers : range;
    carlys.warmers : ternary;
    ymca.tautologically : lpm;
    ymca.groynes mask 7 : ternary;
    ymca.crampons : exact;
  }
  actions {
    erickas;
  }
}

table ratlines {
  reads {
    refuters.bloodied mask 17 : lpm;
  }
  actions {
    erickas;
  }
}

table unbosoms {
  reads {
    statuette.disharmony : lpm;
    hook.bernard : exact;
    hook.positives : range;
    hook.farriers : ternary;
    refuters : valid;
    refuters.bloodied : exact;
    carlys : valid;
  }
  actions {
    catalans;
  }
}

table prayed {
  reads {
    statuette : valid;
    refuters.bloodied : exact;
    refuters.surmounting mask 0 : exact;
  }
  actions {
    
  }
}

table fundraiser {
  reads {
    hook : valid;
    refuters : valid;
    refuters.bloodied : exact;
    refuters.surmounting : lpm;
    collieries : valid;
    collieries.sultans : ternary;
  }
  actions {
    
  }
}

table fairbanks {
  actions {
    catalans;
    erickas;
    }
  }

table paralysiss {
  reads {
    dogtrotted : valid;
    dogtrotted.diked : exact;
  }
  actions {
    catalans;
  }
}

table pusses {
  reads {
    ridiculous : valid;
    ridiculous.mammograms : exact;
    ridiculous.billhook : exact;
    ridiculous.sleepers : ternary;
    hook : valid;
    collieries : valid;
    ymca : valid;
    ymca.catchphrase mask 4 : exact;
    ymca.carefulnesss : exact;
    ymca.crampons : ternary;
    ymca.fondly : exact;
    dogtrotted : valid;
  }
  actions {
    
  }
}

table brigs {
  reads {
    hook : valid;
    hook.bernard : lpm;
    hook.positives : ternary;
    hook.marijuana mask 24 : exact;
    hook.farriers : ternary;
    refuters : valid;
    refuters.bloodied : ternary;
    carlys : valid;
  }
  actions {
    
  }
}

table virulence {
  actions {
    catalans;
    erickas;
    }
  }

table yorkie {
  reads {
    ridiculous : valid;
    ridiculous.sleepers mask 7 : ternary;
    ridiculous.winnipeg : lpm;
  }
  actions {
    erickas;
  }
}

table dreadnoughts {
  reads {
    dogtrotted : valid;
  }
  actions {
    catalans;
  }
}

table bumblers {
  reads {
    ridiculous.winnipeg : lpm;
    ridiculous.morgue mask 3 : ternary;
    hook : valid;
    hook.bernard : exact;
    hook.positives mask 0 : exact;
    hook.marijuana : ternary;
    hook.farriers : exact;
  }
  actions {
    
  }
}

table brutishly {
  reads {
    ridiculous : valid;
    ridiculous.billhook : lpm;
    ridiculous.sleepers : exact;
    ridiculous.winnipeg : range;
    ridiculous.morgue : exact;
    refuters : valid;
    refuters.surmounting mask 0 : ternary;
  }
  actions {
    catalans;
    erickas;
  }
}

table cokes {
  reads {
    ridiculous.billhook : exact;
    ridiculous.sleepers : exact;
    hook.farriers : exact;
    carlys : valid;
    carlys.pinewood : exact;
    ymca.catchphrase mask 4 : exact;
    ymca.tautologically : exact;
    ymca.groynes : range;
    ymca.carefulnesss : exact;
    dogtrotted : valid;
  }
  actions {
    catalans;
  }
}

table unsanctioned {
  actions {
    catalans;
    erickas;
    }
  }

table annealed {
  actions {
    erickas;
    }
  }

table bullring {
  reads {
    statuette.label mask 3 : exact;
    statuette.fixatives : exact;
    hook : valid;
    refuters : valid;
    refuters.surmounting : exact;
    ymca : valid;
    ymca.fondly mask 10 : exact;
    dogtrotted.diked : ternary;
  }
  actions {
    catalans;
  }
}

table shines {
  reads {
    statuette : valid;
    refuters.surmounting : exact;
    ymca : valid;
    dogtrotted : valid;
  }
  actions {
    erickas;
  }
}

control ingress {
  if ((not(valid(statuette)) or (true or
      (ridiculous.winnipeg == hook.farriers)))) {
    
  } else {
    if (((hook.marijuana != 190757812) or (69 <= ridiculous.sleepers))) {
      if (not((false or true))) {
        if (not(((ridiculous.sleepers < 149) or
            (hook.marijuana != 1475719634)))) {
          
        }
        if ((not(valid(ridiculous)) and not(false))) {
          apply(womanlinesss);
        } else {
          apply(interlinings);
          apply(fauvisms);
          if (not(((hook.positives < 148) and
              (ridiculous.billhook != ridiculous.morgue)))) {
            apply(unlocked);
          } else {
            apply(snatchers);
          }
        }
        if (((224 >= dogtrotted.diked) and (statuette.label >= 21))) {
          
        } else {
          apply(abs);
          apply(deloress);
          apply(shillong);
        }
      }
    } else {
      apply(denture);
    }
    if ((36 <= hook.positives)) {
      if (false) {
        
      }
      if (not(((ymca.fondly == carlys.broader) or
          (refuters.bloodied != carlys.pinewood)))) {
        apply(titicaca) {
          miss { }
          hit {
            apply(ratlines);
            apply(unbosoms);
          }
        }
        apply(prayed);
        if ((not(valid(statuette)) and not(valid(carlys)))) {
          
        } else {
          apply(fundraiser);
          apply(fairbanks);
        }
      } else {
        apply(paralysiss);
        if (not((241 > ridiculous.raillerys))) {
          apply(pusses);
          apply(brigs);
        } else {
          apply(virulence);
        }
        if ((true and true)) {
          apply(yorkie);
          apply(dreadnoughts);
          apply(bumblers);
        } else {
          apply(brutishly);
        }
      }
      if (not((false or (statuette.label <= 40)))) {
        
      } else {
        apply(cokes);
        apply(unsanctioned);
        apply(annealed);
      }
    } else {
      apply(bullring);
    }
  }
  apply(shines);
}
