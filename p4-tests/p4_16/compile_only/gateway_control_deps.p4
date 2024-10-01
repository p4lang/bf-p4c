#include <core.p4>
#include <v1model.p4>

struct metadata { }

#include "trivial_parser.h"

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action a1(bit<8> val) {
        hdr.data.b1 = val;
    }
    
    action noop() { }
    
    table t1 {
        key = {
            hdr.data.f1: exact;
        }

        actions = {
            a1; noop;
        }
    }

    table t2 {
        key = {
            hdr.data.f1 : exact;
        }
        actions = {
            noop;
        }
    }

    table t3 {
        key = {
            hdr.data.f1 : exact;
        }
        actions = {
            noop;
        }
    }

    table t4 {
        key = {
            hdr.data.f1 : exact;
        }
        actions = {
            noop;
        }
    }

    apply {
        switch (t1.apply().action_run) {
            default : {
                if (hdr.data.f2 == hdr.data.f1) {
                    t2.apply();
                    switch (t3.apply().action_run) {
                        noop : {
                            t4.apply();
                        }
                    }
                }
            }
            a1 : {
                t4.apply();
            }
        }
    }
}

#include "common_v1_test.h"
