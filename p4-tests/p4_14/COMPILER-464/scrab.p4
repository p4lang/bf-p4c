#include <tofino/intrinsic_metadata.p4>
header_type an {
  fields {
    traumatologies : 112;
  }
}

header_type triandria {
  fields {
    hoofprints : 8;
  }
}

header_type nonaligned {
  fields {
    homekeeping : 8;
    kurrajongs : 8;
  }
}

header_type thorpe {
  fields {
    gif : 16;
    haledons : 32;
    internment : 8;
    aquaphobes : 32;
    launders : 8;
  }
}

header_type pupated {
  fields {
    unreclaimed : 32;
    tellingly : 8;
  }
}

header an nyalas;

header triandria independence;

header triandria chalybean[12];

header nonaligned departure;

header pupated fairys;

header nonaligned pipeage;

header nonaligned yamunas;

header nonaligned cladodial;

header pupated broodys;

header thorpe malleate;

header pupated vane;

parser start {
  return parse_nyalas;
}

parser parse_nyalas {
  extract(nyalas);
  return parse_independence;
}

parser parse_independence {
  extract(independence);
  return parse_chalybean;
}

parser parse_chalybean {
  extract(chalybean[next]);
  return select (latest.hoofprints) {
    0 : parse_departure;
    default : parse_chalybean;
  }
}

parser parse_departure {
  extract(departure);
  return select (latest.kurrajongs) {
    0 : parse_fairys;
    1 : parse_malleate;
    default : ingress;
  }
}

parser parse_fairys {
  extract(fairys);
  return parse_pipeage;
}

parser parse_pipeage {
  extract(pipeage);
  return select (latest.kurrajongs) {
    0 : parse_cladodial;
    1 : parse_yamunas;
    2 : parse_broodys;
    default : ingress;
  }
}

parser parse_yamunas {
  extract(yamunas);
  return select (latest.kurrajongs) {
    0 : parse_cladodial;
    1 : parse_vane;
    default : ingress;
  }
}

parser parse_cladodial {
  extract(cladodial);
  return select (latest.kurrajongs) {
    0 : parse_broodys;
    1 : parse_vane;
    2 : parse_malleate;
    default : ingress;
  }
}

parser parse_broodys {
  extract(broodys);
  return parse_malleate;
}

parser parse_malleate {
  extract(malleate);
  return parse_vane;
}

parser parse_vane {
  extract(vane);
  return ingress;
}

action before() {
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
  bypass_egress();
}

action after() {
  remove_header(independence);
}

action skip() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
}

action del_departure() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(departure);
}

action add_departure() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(departure);
  modify_field(departure.homekeeping, 0);
  modify_field(departure.kurrajongs, 0);
}

action del_fairys() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(fairys);
}

action add_fairys() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(fairys);
  modify_field(fairys.unreclaimed, 0);
  modify_field(fairys.tellingly, 0);
}

action del_pipeage() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(pipeage);
}

action add_pipeage() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(pipeage);
  modify_field(pipeage.homekeeping, 0);
  modify_field(pipeage.kurrajongs, 0);
}

action del_yamunas() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(yamunas);
}

action add_yamunas() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(yamunas);
  modify_field(yamunas.homekeeping, 0);
  modify_field(yamunas.kurrajongs, 0);
}

action del_cladodial() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(cladodial);
}

action add_cladodial() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(cladodial);
  modify_field(cladodial.homekeeping, 0);
  modify_field(cladodial.kurrajongs, 0);
}

action del_broodys() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(broodys);
}

action add_broodys() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(broodys);
  modify_field(broodys.unreclaimed, 0);
  modify_field(broodys.tellingly, 0);
}

action del_malleate() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(malleate);
}

action add_malleate() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(malleate);
  modify_field(malleate.gif, 0);
  modify_field(malleate.haledons, 0);
  modify_field(malleate.internment, 0);
  modify_field(malleate.aquaphobes, 0);
  modify_field(malleate.launders, 0);
}

action del_vane() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  remove_header(vane);
}

action add_vane() {
  modify_field(independence.hoofprints, chalybean[0].hoofprints);
  pop(chalybean, 1);
  add_header(vane);
  modify_field(vane.unreclaimed, 0);
  modify_field(vane.tellingly, 0);
}

table agios {
  actions {
    before;
    }
    size : 1;
  }

table falsifiers {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    add_departure;
    add_fairys;
    add_pipeage;
    add_yamunas;
    add_cladodial;
    add_broodys;
    add_malleate;
    add_vane;
  }
  size : 64;
}

table criticalities {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    add_departure;
    add_fairys;
    add_pipeage;
    add_yamunas;
    add_cladodial;
    add_broodys;
    add_malleate;
    add_vane;
  }
  size : 64;
}

table furcation {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    add_departure;
    add_fairys;
    add_pipeage;
    add_yamunas;
    add_cladodial;
    add_broodys;
    add_malleate;
    add_vane;
  }
  size : 64;
}

table algona {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    add_departure;
    add_fairys;
    add_pipeage;
    add_yamunas;
    add_cladodial;
    add_broodys;
    add_malleate;
    add_vane;
  }
  size : 64;
}

table facticity {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    add_departure;
    add_fairys;
    add_pipeage;
    add_yamunas;
    add_cladodial;
    add_broodys;
    add_malleate;
    add_vane;
  }
  size : 64;
}

table tenpins {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    add_departure;
    add_fairys;
    add_pipeage;
    add_yamunas;
    add_cladodial;
    add_broodys;
    add_malleate;
    add_vane;
  }
  size : 64;
}

table successiveness {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    del_departure;
    del_fairys;
    del_pipeage;
    del_yamunas;
    del_cladodial;
    del_broodys;
    del_malleate;
    del_vane;
  }
  size : 64;
}

table bigfoots {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    del_departure;
    del_fairys;
    del_pipeage;
    del_yamunas;
    del_cladodial;
    del_broodys;
    del_malleate;
    del_vane;
  }
  size : 64;
}

table laterites {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    del_departure;
    del_fairys;
    del_pipeage;
    del_yamunas;
    del_cladodial;
    del_broodys;
    del_malleate;
    del_vane;
  }
  size : 64;
}

table acrilan {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    del_departure;
    del_fairys;
    del_pipeage;
    del_yamunas;
    del_cladodial;
    del_broodys;
    del_malleate;
    del_vane;
  }
  size : 64;
}

table offenbach {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    del_departure;
    del_fairys;
    del_pipeage;
    del_yamunas;
    del_cladodial;
    del_broodys;
    del_malleate;
    del_vane;
  }
  size : 64;
}

table induration {
  reads {
    independence.hoofprints : exact;
  }
  actions {
    skip;
    del_departure;
    del_fairys;
    del_pipeage;
    del_yamunas;
    del_cladodial;
    del_broodys;
    del_malleate;
    del_vane;
  }
  size : 64;
}

table anticorrosives {
  actions {
    after;
    }
    size : 1;
  }

control ingress {
  apply(agios);
  apply(successiveness);
  apply(bigfoots);
  apply(laterites);
  apply(acrilan);
  apply(offenbach);
  apply(induration);
  apply(falsifiers);
  apply(criticalities);
  apply(furcation);
  apply(algona);
  apply(facticity);
  apply(tenpins);
  apply(anticorrosives);
}
