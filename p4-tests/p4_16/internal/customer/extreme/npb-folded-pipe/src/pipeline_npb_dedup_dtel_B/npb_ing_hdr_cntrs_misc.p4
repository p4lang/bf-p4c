// Copyright 2020-2021 Extreme Networks, Inc.
// All rights reserved.

#ifndef _NPB_ING_HDR_CNTRS_MISC_
#define _NPB_ING_HDR_CNTRS_MISC_

control IngressHdrCntrsMisc(
    in switch_header_t hdr
) (
	MODULE_DEPLOYMENT_PARAMS
) {

    DirectCounter<bit<32>>(CounterType_t.PACKETS) cpu_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) inner_inner_hdr_cntrs;
    DirectCounter<bit<32>>(CounterType_t.PACKETS) udf_hdr_cntrs;


    // -------------------------------------------------------------------------
    // CPU Header --------------------------------------------------------------
    // -------------------------------------------------------------------------

    action bump_cpu_hdr_cntr() {
        cpu_hdr_cntrs.count();
    }

    table cpu_hdr_cntr_tbl {
        key = {
            hdr.cpu.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_cpu_hdr_cntr;
        }

        size = 2;
        // todo: does setting this as default yield an "unexpected counter"
        // const default_action = bump_cpu_hdr_cntr;
        counters = cpu_hdr_cntrs;

        // No constant entries allowed if clearing these in PTF
        // const entries = {
        //     false: bump_cpu_hdr_cntr; 
        //     true:  bump_cpu_hdr_cntr; 
        // }
    }

    
    // ------------------------------------------------------------
    // inner inner stack ------------------------------------------
    // ------------------------------------------------------------

    action bump_inner_inner_stack_hdr_cntr() {
        inner_inner_hdr_cntrs.count();
    }
    
    table inner_inner_stack_hdr_cntr_tbl {
        key = {
            hdr.inner_inner.ipv4.isValid(): exact;
            hdr.inner_inner.ipv6.isValid(): exact;
        }

        actions = {
            //NoAction;
            bump_inner_inner_stack_hdr_cntr;
        }

        counters = inner_inner_hdr_cntrs;
        size = 4;
    }

    
    // ------------------------------------------------------------
    // Layer7 UDF -------------------------------------------------
    // ------------------------------------------------------------

    action bump_udf_hdr_cntr() {
        udf_hdr_cntrs.count();
    }

    table udf_hdr_cntr_tbl {
        key = {
            hdr.udf.isValid(): exact;
        }

        actions = {
            //NoAction;
            //bump_transport_stack_unexpected_hdr_cntr;
            bump_udf_hdr_cntr;
        }

        size = 2;
        counters = udf_hdr_cntrs;
    }

    
    // ------------------------------------------------------------
    // apply ------------------------------------------------------
    // ------------------------------------------------------------

    apply {        
        cpu_hdr_cntr_tbl.apply();
        //inner_inner_stack_hdr_cntr_tbl.apply(); // design doesn't fit

        if(UDF_ENABLE) {
            udf_hdr_cntr_tbl.apply();
        }
    }
}

#endif /* _NPB_ING_HDR_CNTRS_MISC_ */
            
