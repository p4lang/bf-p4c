
/*
 * Flowlet related processing for BMv2
 */

#ifndef HARLYN
header_type flowlet_metadata_t {
    fields {
        id : 16;                            /* flowlet id */
        inactive_timeout : 32;              /* flowlet inactivity timeout */
        timestamp : 32;                     /* flowlet last time stamp */
        map_index : FLOWLET_MAP_WIDTH;      /* flowlet map index */
        inter_packet_gap : 32 (saturating); /* inter-packet gap */
    }
}

metadata flowlet_metadata_t flowlet_metadata;

register flowlet_id {
    width : 16;
    instance_count : FLOWLET_MAP_SIZE;
}

register flowlet_lastseen {
    width : 32;
    instance_count : FLOWLET_MAP_SIZE;
}

action update_flowlet_id() {
    add_to_field(flowlet_metadata.id, 1);
    register_write(flowlet_id, flowlet_metadata.map_index,
                   flowlet_metadata.id);
}

table new_flowlet {
    actions {
        update_flowlet_id;
    }
    size : 1;
}

action flowlet_lookup() {
    // this action implementation assumes sequential execution semantics.
    modify_field_with_hash_based_offset(flowlet_metadata.map_index, 0,
                                        flowlet_hash, FLOWLET_MAP_SIZE);
    modify_field(flowlet_metadata.inter_packet_gap,
                 intrinsic_metadata.ingress_global_timestamp);
    register_read(flowlet_metadata.id, flowlet_id,
                  flowlet_metadata.map_index);
    register_read(flowlet_metadata.timestamp, flowlet_lastseen,
                  flowlet_metadata.map_index);
    subtract_from_field(flowlet_metadata.inter_packet_gap,
                        flowlet_metadata.timestamp);
    register_write(flowlet_lastseen, flowlet_metadata.map_index,
                   intrinsic_metadata.ingress_global_timestamp);
    subtract_from_field(flowlet_metadata.inter_packet_gap,
                        flowlet_metadata.inactive_timeout);
}
#endif /* HARLYN */
