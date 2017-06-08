/*
 * Meter processing
 */

/*
 * Meter metadata
 */
 header_type meter_metadata_t {
     fields {
         meter_color : 2;                /* meter color */
         meter_index : 16;               /* meter index */
     }
 }

#ifndef METER_DISABLE
@pragma pa_atomic ingress meter_metadata.meter_color
@pragma pa_solitary ingress meter_metadata.meter_color

@pragma pa_atomic ingress meter_metadata.meter_index
@pragma pa_solitary ingress meter_metadata.meter_index
#endif /* METER_DISABLE */

metadata meter_metadata_t meter_metadata;

/*****************************************************************************/
/* Meters                                                                    */
/*****************************************************************************/
#ifndef METER_DISABLE
action meter_deny() {
    drop();
}

action meter_permit() {
}

#ifndef STATS_DISABLE
counter meter_stats {
    type : packets;
    direct : meter_action;
}
#endif /* STATS_DISABLE */

table meter_action {
    reads {
        meter_metadata.meter_color : exact;
        meter_metadata.meter_index : exact;
    }

    actions {
        meter_permit;
        meter_deny;
    }
    size: METER_ACTION_TABLE_SIZE;
}

meter meter_index {
    type : bytes;
    direct : meter_index;
    result : meter_metadata.meter_color;
}

@pragma ternary 1
table meter_index {
    reads {
        meter_metadata.meter_index: exact;
    }
    actions {
        nop;
    }
    size: METER_INDEX_TABLE_SIZE;
}
#endif /* METER_DISABLE */

control process_meter_index {
#ifndef METER_DISABLE
    if (DO_LOOKUP(METER)) {
        apply(meter_index);
    }
#endif /* METER_DISABLE */
}

control process_meter_action {
#ifndef METER_DISABLE
    if (DO_LOOKUP(METER)) {
        apply(meter_action);
    }
#endif /* METER_DISABLE */
}
