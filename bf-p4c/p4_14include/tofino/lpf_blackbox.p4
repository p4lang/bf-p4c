/*
Copyright (c) 2015-2019 Barefoot Networks, Inc.

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

blackbox_type lpf {

    attribute filter_input {
        /*  Reference to the input field to compute the filter on.
            The maximum input bit width supported is 32 bits.  */
        type: bit<32>;
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


    /*
    Execute the low pass filter for a given cell in the array and writes
    the result to the output parameter.
    If the low pass filter is direct, then 'index' is ignored as the table
    entry determines which cell to reference.

    Callable from:
    - Actions

    Parameters:
    - destination: A field reference to store the low pass filter state.
                   The maximum output bit width is 32 bits.
    - index: Optional. The offset in the low pass filter array to update. Necessary
             unless the low pass filter is declared as direct, in which case it should
             not be present.
    */
    method execute (out bit<32> destination, optional in int index){
        reads {filter_input}
    }
}

/***************************************************************************/
