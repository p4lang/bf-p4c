/*
Copyright (c) 2015-2017 Barefoot Networks, Inc.

All Rights Reserved.

NOTICE: All information contained herein is, and remains the property of
Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
technical concepts contained herein are proprietary to Barefoot Networks, Inc.
and its suppliers and may be covered by U.S. and Foreign Patents, patents in
process, and are protected by trade secret or copyright law. Dissemination of
this information or reproduction of this material is strictly forbidden unless
prior written permission is obtained from Barefoot Networks, Inc.

No warranty, explicit or implicit is provided, unless granted under a written
agreement with Barefoot Networks, Inc.
*/

/***************************************************************************/

blackbox_type meter {

    attribute type {
        /* Must be either:
            bytes
            packets */
        type: string;
    }

    attribute direct {
        /* Mutually exclusive with 'static' attribute.
           Must be a match table reference */
        type: table;
        optional;
    }

    attribute static {
        /* Mutually exclusive with 'direct' attribute.
           Must be a table reference */
        type: table;
        optional;
    }

    attribute instance_count {
        /* Mutually exclusive with 'direct' attribute. */
        type: int;
        optional;
    }

    attribute green_value {
        /* An 8-bit value that can be output if the packet is to be marked as green.
           The default value is 0. */
        type: int;
        optional;
    }
    attribute yellow_value {
        /* An 8-bit value that can be output if the packet is to be marked as yellow.
           The default value is 1. */
        type: int;
        optional;
    }
    attribute red_value {
        /* An 8-bit value that can be output if the packet is to be marked as red.
           The default value is 3. */
        type: int;
        optional;
    }

    /*
    Execute the metering operation for a given cell in the array. If
    the  meter is direct, then 'index' is ignored as the table
    entry determines which cell to reference. The length of the packet
    is implicitly passed to the meter. The state of meter is updated
    and the meter returns information (a 'color') which is stored in
    'destination'. If the parent header of 'destination' is not valid,
    the meter  state is updated, but resulting output is discarded.

    Callable from:
    - Actions

    Parameters:
    - destination: A field reference to store the low pass filter state.
                   The maximum output bit width is 32 bits.
    - index: Optional. The offset in the low pass filter array to update. Necessary
             unless the low pass filter is declared as direct, in which case it should
             not be present.
    */
    method execute (out bit<32> destination, optional in int index){}

    /* Same as execute, but destination field is OR'd with meter result. */
    method execute_with_or (out bit<32> destination, optional in int index){}

    /*  Same as execute, but the precolor attribute specifies the minimum color the packet
        may be tagged with.
        Pre-color encoding (which is not programmable):
        0 = green
        1 = yellow
        2 = yellow
        3 = red
     */
    method execute_with_pre_color (out bit<32> destination, in bit<32> precolor, optional in int index){}

    /* Same as execute_with_pre_color, but destination field is OR'd with meter result.  */
    method execute_with_pre_color_with_or(out bit<32> destination, in bit<32> precolor, optional in int index){}
}

/***************************************************************************/
