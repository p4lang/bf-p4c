header_type ethernet_t {
    fields {
        etherType : 16;
    }
}

header_type cpu_t {
    fields {
        etherType : 16;
    }
}

header_type bug_t {
    fields {
        hello : 32;
    }
}

#define ETHERTYPE_CPU 0x9000, 0x010c

header ethernet_t ethernet;
header cpu_t cpu;
header bug_t bug;

parser start {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_CPU : parse_cpu_header;
        default: ingress;
    }
}

parser parse_cpu_header {
    extract(cpu);
    return select(latest.etherType) {
        0xdead : parse_bug;
        default: ingress;
    }
}

parser parse_bug {
    set_metadata(standard_metadata.egress_spec, 0x2);
    extract(bug);
    return ingress;
}

control ingress { }
