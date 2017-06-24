// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.

header_type M1 {
   fields {
      f1 : 12;
      f2 : 36;
      f3 : 1;
      f4 : 48;
      f5 : 48;
      f6 : 1;
      f7 : 5;
   }
}

header_type M2 {
   fields {
      f11 : 12;
      f12 : 12;
      f13 : 48;
      f14 : 48;
      f15 : 1;
      f16 : 13;
      f17 : 1;
      f18 : 1;
      f19 : 1;
      f20 : 1;
      f21 : 1;
   }
}

metadata M1 m1;
metadata M2 m2;

parser start { 
   return ingress; 
}

action a1() {
   modify_field(m2.f13, m1.f4);
   modify_field(m2.f14, m1.f5);
   modify_field(m2.f11, m1.f1);
}

table T1 {
   actions {
      a1;
   }
   size : 1;
}

control c1 {
   apply( T1 );
}

action a2() {
   modify_field(m2.f17, 1);
   modify_field(m2.f15, 1);
   add(m2.f16, m2.f11, 0x0);
}

action a3() {
}

@pragma ways 1
table T2 {
   reads {
      m1.f4 : exact;
   }
   actions {
      a2;
      a3;
   }
   size : 1;
}

action a4() {
   modify_field(m2.f18, 1);
   modify_field(m2.f21, 1);
   add(m2.f16, m2.f11, 0x1);
}

table T6 {
   actions {
      a4;
   }
   size : 1;
}

action a6() {
   modify_field(m2.f20, 1);
   add(m2.f16, m2.f11, 0x0);
}

table T3 {
   actions {
      a6;
   }
   size : 1;
}

action a7(f12) {
   modify_field(m2.f19, 1);
   modify_field(m2.f12, f12);
}

action a8(f16) {
   modify_field(m2.f18, 1);
   modify_field(m2.f16, f16);
}

action a9() {
}

table T4 {
   reads {
      m1.f4 : exact;
      m1.f1 : exact;
   }

   actions {
      a7;
      a8;
      a9;
   }
   size : 64;
}

action a10() {
}


table T5 {
   reads {
      m2.f16 : exact;
   }
   actions {
      a10;
   }
   size : 1;
}

control c2 {
   apply(T4) {
      a9 {
         apply(T2) {
            a3 {
               if (m1.f7==0x0) {
                  apply(T6);
               } else {
                  apply(T3);
               }
            }
         }
      }
   }
}

control c3 {
   apply(T5);
}

control ingress {
   c1();
   c2();
   c3();
} 
