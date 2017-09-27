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

blackbox_type wred {

    attribute wred_input {
        /*  Reference to the input field to compute the moving average on.
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

    attribute drop_value {
        /* Specifies the lower bound for which the computed moving average should result in a drop. */
        type: int;
        optional;
    }

    attribute no_drop_value {
        /* Specifies the upper bound for which the computed moving average should not result in a drop. */
        type: int;
        optional;
    }

    /*
    Execute the moving average for a given cell in the array and writes
    the result to the output parameter.
    If the wred is direct, then 'index' is ignored as the table
    entry determines which cell to reference.

    Callable from:
    - Actions

    Parameters:
    - destination: A field reference to store the moving average state.
                   The maximum output bit width is 8 bits.
    - index: Optional. The offset in the wred array to update. Necessary
             unless the wred is declared as direct, in which case it should
             not be present.
    */
    method execute (out bit<32> destination, optional in int index){
        reads {wred_input}
    }
}

/***************************************************************************/
