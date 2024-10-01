/* p4smith seed: 239056274 */
#include <tofino/intrinsic_metadata.p4>
header_type ujungpandang {
  fields {
    mycenae : 64;
    poms : 48;
    blevinss : 48;
    heehaws : 16 (signed);
  }
}

header_type berating {
  fields {
    overemphasizing : 64;
  }
}

header_type illumines {
  fields {
    speechlessly : 8 (signed, saturating);
    teleprinters : 16;
    oligarch : 8 (signed);
    salweens : 8;
    attachments : 32;
    pope : 48;
  }
}

header_type bunny {
  fields {
    marathoners : 48;
    kneecap : 16;
    accordionist : 32;
    mightier : 16;
    punnet : 16;
  }
}

header_type fleeciest {
  fields {
    aryans : 16;
    littles : 32;
    livestocks : 16;
  }
}

header ujungpandang pyromania;

header berating rockfall;

header illumines astronomical;

header bunny tininesss;

header fleeciest restitches;

register kelvins {
  width : 8;
  instance_count : 331;
}

register elapsing {
  width : 8;
  instance_count : 447;
}

register pillowed {
  width : 16;
  instance_count : 1024;
}

register pacer {
  width : 128;
  instance_count : 567;
}

register triennials {
  width : 32;
  instance_count : 532;
}

register teetotalisms {
  width : 32;
  instance_count : 581;
}

register mindanao {
  width : 48;
  instance_count : 368;
}

register ratlike {
  width : 16;
  instance_count : 643;
}

register rattly {
  width : 48;
  instance_count : 851;
}

register destinations {
  width : 16;
  instance_count : 505;
}

parser start {
  return parse_pyromania;
}

parser parse_pyromania {
  extract(pyromania);
  return select (current(0, 8)) {
    54 : parse_rockfall;
    255 : parse_restitches;
  }
}

parser parse_rockfall {
  extract(rockfall);
  return select (current(0, 8)) {
    8 : parse_tininesss;
    255 : parse_restitches;
    41 : parse_astronomical;
  }
}

parser parse_astronomical {
  extract(astronomical);
  return select (latest.oligarch) {
    64 : parse_tininesss;
  }
}

parser parse_tininesss {
  extract(tininesss);
  return select (latest.mightier) {
    49426 : parse_restitches;
  }
}

parser parse_restitches {
  extract(restitches);
  return ingress;
}

field_list marlas {
  astronomical.oligarch;
  pyromania.poms;
  rockfall.overemphasizing;
  pyromania.heehaws;
  restitches.littles;
  restitches.littles;
  astronomical.pope;
  pyromania.mycenae;
  tininesss.accordionist;
  227;
  restitches.livestocks;
}

field_list allocates {
  astronomical.pope;
  rockfall.overemphasizing;
}

field_list pdt {
  tininesss.accordionist;
  pyromania.heehaws;
  pyromania.heehaws;
  rockfall;
}

field_list foils {
  tininesss.marathoners;
  tininesss.accordionist;
  10;
  tininesss.marathoners;
  120;
  restitches.livestocks;
  restitches;
  tininesss;
  tininesss;
  pyromania.heehaws;
  tininesss;
  tininesss;
  restitches;
}

field_list_calculation aprons {
  input {
    pdt;
  }
  algorithm : csum16;
  output_width : 8;
}

calculated_field tininesss.punnet {
  update aprons if (valid(restitches));
  update aprons if (valid(astronomical));
  update aprons if (valid(astronomical));
}

action doomsters() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action bear(grindstones, napiers) {
  add_to_field(tininesss.accordionist, astronomical.attachments);
}

action makarios() {
  subtract_from_field(astronomical.speechlessly, astronomical.salweens);
}

action clorets() {
  remove_header(tininesss);
  copy_header(tininesss, tininesss);
  //register_write(teetotalisms, 184, restitches.littles);
  remove_header(tininesss);
  add_to_field(restitches.livestocks, restitches.aryans);
}

action unsure() {
  subtract(tininesss.punnet, tininesss.punnet, tininesss.punnet);
}

table broilers {
  actions {
    doomsters;
    }
  }

table consigns {
  reads {
    tininesss : valid;
    tininesss.kneecap mask 252 : ternary;
    tininesss.mightier : range;
    tininesss.punnet : range;
  }
  actions {
    clorets;
    doomsters;
    makarios;
    unsure;
  }
}

control ingress {
  if (not((not((not(not((tininesss.mightier == tininesss.accordionist))) or 
               valid(tininesss))) or (valid(pyromania) and true)))) {
    apply(broilers);
  }
  apply(consigns);
}
