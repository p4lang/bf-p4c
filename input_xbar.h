#ifndef _input_xbar_h_
#define _input_xbar_h_

#include "tables.h"

class InputXbar {
    Stage	*stage;
public:
    InputXbar(Table *table, bool ternary, VECTOR(pair_t) &data);
};

#endif /* _input_xbar_h_ */
