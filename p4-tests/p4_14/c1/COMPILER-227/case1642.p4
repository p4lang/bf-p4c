// Copyright (c) 2016 Arista Networks, Inc.  All rights reserved.
// Arista Networks, Inc. Confidential and Proprietary.

header_type XHdr {
   fields {
      f1 : 24;
      f2 : 12;
   }
}
header XHdr x;

parser start { 
   return parseX; 
}

parser parseX {
   extract( x );
   return select( x.f1 ) {
      0x2 : parseFoo;
      0x00001 mask 0x00001 : parseFooBar;
      default : ingress;
   }
}

parser parseFoo {
   return select( x.f2 ) {
      0x3 : parseBar;
      default        : ingress;
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
