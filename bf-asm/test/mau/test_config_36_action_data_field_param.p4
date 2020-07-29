#include "tofino/intrinsic_metadata.p4"

header_type test_t {
   fields {
      field_a : 4;
      field_b : 8;
      field_c : 4;
      field_d : 32;
      field_e : 32;
   }
}


header test_t test;

parser start {
    return parse_test;
}

parser parse_test {
    extract(test);
    return ingress;
}


action action_0(my_param_0){
   modify_field(test.field_a, test.field_c);
   modify_field(test.field_e, my_param_0);
}


table table_0 {
   reads {
      test.field_e : ternary;
   }
   actions {
      action_0;
   }
}

control ingress {
    apply(table_0);
}