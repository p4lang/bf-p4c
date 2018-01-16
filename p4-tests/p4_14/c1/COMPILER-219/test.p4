// Copyright (c) 2016 Arista Networks, Inc. All rights reserved. 
// Arista Networks, Inc. Confidential and Proprietary.

header_type EthernetHdr { 
    fields { 
        dmac : 48; 
        smac : 48; 
        etherType : 16; 
    } 
} 

header_type ipv4_t { 
    fields { 
        version : 4; 
        ihl : 4; 
        diffserv : 8; 
        totalLen : 16; 
        identification : 16; 
        flags : 3; 
        fragOffset : 13; 
        ttl : 8; 
        protocol : 8; 
        hdrChecksum : 16; 
        srcAddr : 32; 
        dstAddr: 32; 
    } 
}
 
header EthernetHdr eth; 
header ipv4_t ipv4;

header_type M { 
    fields { 
        a : 1; 
        b : 1; 
        c : 6; 
    } 
} 

metadata M m;

parser start { 
    return parseEthernet; 
}

parser parseEthernet { 
    extract(eth); 
    return parse_ipv4; 
}

parser parse_ipv4 { 
    extract(ipv4); 
    return ingress; 
}

action a1() {}

table T1 { 
    actions { 
        a1; 
    } 
    size : 1; 
}

control ingress { 
    if ( m.a==0 and ipv4.ttl > 0 ) { 
        apply( T1 ); 
    } 
}   
