header_type pkt_t {
    fields {
        srcAddr : 32;
        dstAddr : 32;
        protocol : 8;
        srcPort : 16;
        dstPort : 16;
    }
}

parser start {
    return parse_ethernet;
}

header pkt_t pkt;

parser parse_ethernet {
    extract(pkt);
    return ingress;
}

action do_nothing(){}

action action1(){ 
    modify_field(pkt.srcAddr, 1);
}

action action2(){ 
    modify_field(pkt.dstAddr, 2);
}

table table1 {
   reads {
       pkt.srcPort : ternary;
   }
   actions {
       action1;
       do_nothing;
   }
}

table table2 {
    reads{ 
      pkt.dstPort : exact; 
    }
    actions{ 
      action2; 
      do_nothing;
    }
}

control ingress {
   if (valid(pkt)){
      if (pkt.protocol == 0){
           apply(table1);
           apply(table2);
      }
   }
}