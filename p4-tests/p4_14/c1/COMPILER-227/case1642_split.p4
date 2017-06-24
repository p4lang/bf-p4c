// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.

header_type XHdr1 {
   fields {
      f1 : 24;
   }
}
header_type XHdr2 {
   fields {
      f2 : 16;
   }
}

header XHdr1 x1;
header XHdr2 x2;

parser start { 
   return parseX; 
}

parser parseX {
   extract(x1);
   return select( x1.f1 ) {
      0x2 : parseFoo;
      0x01 mask 0x01 : parseFooBar;
      default : ingress;
   }
}

parser parseFoo {
   extract(x2);
   return  select( x2.f2 ) {
      0x3 : parseBar;
      default        :  ingress;
   }
}

parser parseBar {
   return ingress;
}

parser parseFooBar {
   return ingress;
}

action t1a() {
}

table T1 { 
   actions { 
      t1a;
   } 
   size : 1;
}

control ingress {
      apply( T1 );
} 
