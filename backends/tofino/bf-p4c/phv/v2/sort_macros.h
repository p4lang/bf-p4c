#ifndef BF_P4C_PHV_V2_SORT_MACROS_H_
#define BF_P4C_PHV_V2_SORT_MACROS_H_

/// convenience macros.
#define IF_NEQ_RETURN_IS_LESS(a, b) if ((a) != (b)) return (a) < (b);
#define IF_NEQ_RETURN_IS_GREATER(a, b) if ((a) != (b)) return (a) > (b);

#endif /* BF_P4C_PHV_V2_SORT_MACROS_H_ */
