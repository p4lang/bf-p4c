header_type pkt_t {
    fields {
        srcAddr : 32;
        dstAddr : 32;
        protocol : 8;
        srcPort : 16;
        dstPort : 16;
        
        a : 32;
        b : 32;
        c : 32;
        d : 32;
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

counter stats1 { 
    type : packets_and_bytes; 
    instance_count : 64; 
}

counter stats2 { 
    type : packets_and_bytes; 
    instance_count : 64; 
}

action action1(){ 
    count(stats1, 1); 
}

action action2(){ 
    count(stats2, 1); 
}

table table1 {
   actions{ 
     action1; 
   }
}

table table2 {
    reads{ 
      pkt.b : exact; 
    }
    actions{ 
      action2; 
    }
}

control ingress {
    if (valid(pkt)){ 
        apply(table1); 
    }

    if (pkt.valid == 1){
        apply(table2);
    }
}