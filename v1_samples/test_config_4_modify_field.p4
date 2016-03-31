#include "tofino/intrinsic_metadata.p4"

header_type my_test_config_1_t {
   fields {
       a_32 : 32;
       b_8 : 8;
       c_8 : 8;
       d_16 : 16;
       e_32 : 32;
       f_32 : 32;
       g_32 : 32;
       h_32 : 32;
       i_32 : 32;
       j_16 : 16;
       k_16 : 16;
       l_16 : 16;
       m_16 : 16;
       n_4  : 4;
       o_1  : 1;
       p_3  : 3;
   }
}


header my_test_config_1_t my_test_config_1;

parser start{
   return parse_my_test_config_1;
}

parser parse_my_test_config_1 {
   extract(my_test_config_1);
   return ingress;
}

action modify_from_constant(){
   modify_field(my_test_config_1.e_32, 3);
}

action modify_from_field(){
   modify_field(my_test_config_1.h_32, my_test_config_1.g_32);
}


action modify_from_param(param1_32){
   modify_field(my_test_config_1.f_32, param1_32);
}


table my_test_config_1_table {
   reads {
      my_test_config_1.a_32 : lpm;
   }

   actions {
      modify_from_constant;
      modify_from_field;
      modify_from_param;
   }
   max_size : 1024;
}

control ingress {
   apply(my_test_config_1_table);
}
