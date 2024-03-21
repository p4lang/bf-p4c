# 1 "../../p4c-5323/src/DefeatFlows.p4"
# 1 "../../p4c-5323/src/DefeatFlows.p4"

#include <core.p4>
#include <t2na.p4>

/* -*- P4_16 -*- */
# 7 "../../p4c-5323/src/architecture.p4" 2






//Helper to avoid juggling command line arguments





@disable_reserved_i2e_drop_implementation







# 1 "../../p4c-5323/src/common.p4" 1
/* -*- P4_16 -*- */
       

# 1 "/usr/local/include/boost/preprocessor.hpp" 1
# 17 "/usr/local/include/boost/preprocessor.hpp"
# 1 "/usr/local/include/boost/preprocessor/library.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/library.hpp"
# 1 "/usr/local/include/boost/preprocessor/arithmetic.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/arithmetic.hpp"
# 1 "/usr/local/include/boost/preprocessor/arithmetic/add.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/arithmetic/add.hpp"
# 1 "/usr/local/include/boost/preprocessor/arithmetic/dec.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/arithmetic/dec.hpp"
# 1 "/usr/local/include/boost/preprocessor/config/config.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/arithmetic/dec.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/arithmetic/add.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/arithmetic/inc.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/arithmetic/add.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/control/while.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/control/while.hpp"
# 1 "/usr/local/include/boost/preprocessor/cat.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/control/while.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/debug/error.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/control/while.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp"
# 1 "/usr/local/include/boost/preprocessor/control/iif.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/control/while.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/fold_left.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/list/fold_left.hpp"
# 1 "/usr/local/include/boost/preprocessor/control/while.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/list/fold_left.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/list/fold_left.hpp" 2
# 41 "/usr/local/include/boost/preprocessor/list/fold_left.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/detail/fold_left.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/list/detail/fold_left.hpp"
# 1 "/usr/local/include/boost/preprocessor/control/expr_iif.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/list/detail/fold_left.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/list/adt.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/list/adt.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/is_binary.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/detail/is_binary.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/check.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/detail/is_binary.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/list/adt.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/logical/compl.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/list/adt.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/eat.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/list/adt.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/list/detail/fold_left.hpp" 2
# 42 "/usr/local/include/boost/preprocessor/list/fold_left.hpp" 2
# 22 "/usr/local/include/boost/preprocessor/control/while.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/fold_right.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/list/fold_right.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/list/fold_right.hpp" 2
# 37 "/usr/local/include/boost/preprocessor/list/fold_right.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/detail/fold_right.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/list/detail/fold_right.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/reverse.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/list/detail/fold_right.hpp" 2
# 38 "/usr/local/include/boost/preprocessor/list/fold_right.hpp" 2
# 23 "/usr/local/include/boost/preprocessor/control/while.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/logical/bitand.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/control/while.hpp" 2
# 48 "/usr/local/include/boost/preprocessor/control/while.hpp"
# 1 "/usr/local/include/boost/preprocessor/control/detail/while.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/control/detail/while.hpp"
# 1 "/usr/local/include/boost/preprocessor/logical/bool.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/control/detail/while.hpp" 2
# 49 "/usr/local/include/boost/preprocessor/control/while.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/arithmetic/add.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/elem.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/tuple/elem.hpp"
# 1 "/usr/local/include/boost/preprocessor/facilities/expand.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/tuple/elem.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/facilities/overload.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/facilities/overload.hpp"
# 1 "/usr/local/include/boost/preprocessor/variadic/size.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/facilities/overload.hpp" 2
# 22 "/usr/local/include/boost/preprocessor/tuple/elem.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/rem.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/tuple/rem.hpp"
# 1 "/usr/local/include/boost/preprocessor/tuple/detail/is_single_return.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/tuple/rem.hpp" 2
# 36 "/usr/local/include/boost/preprocessor/tuple/rem.hpp"
/*
  VC++8.0 cannot handle the variadic version of BOOST_PP_TUPLE_REM(size)
*/
# 23 "/usr/local/include/boost/preprocessor/tuple/elem.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/variadic/elem.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/tuple/elem.hpp" 2
# 22 "/usr/local/include/boost/preprocessor/arithmetic/add.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/arithmetic.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/arithmetic/div.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/arithmetic/div.hpp"
# 1 "/usr/local/include/boost/preprocessor/arithmetic/detail/div_base.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/arithmetic/detail/div_base.hpp"
# 1 "/usr/local/include/boost/preprocessor/arithmetic/sub.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/arithmetic/detail/div_base.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/comparison/less_equal.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/comparison/less_equal.hpp"
# 1 "/usr/local/include/boost/preprocessor/logical/not.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/comparison/less_equal.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/arithmetic/detail/div_base.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/arithmetic/div.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/arithmetic.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/arithmetic/mod.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/arithmetic.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/arithmetic/mul.hpp" 1
# 23 "/usr/local/include/boost/preprocessor/arithmetic.hpp" 2
# 17 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/array.hpp"
# 1 "/usr/local/include/boost/preprocessor/array/data.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/elem.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/array/elem.hpp"
# 1 "/usr/local/include/boost/preprocessor/array/size.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/array/elem.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/enum.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/insert.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/array/insert.hpp"
# 1 "/usr/local/include/boost/preprocessor/array/push_back.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/array/push_back.hpp"
# 1 "/usr/local/include/boost/preprocessor/punctuation/comma_if.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/punctuation/comma_if.hpp"
# 1 "/usr/local/include/boost/preprocessor/control/if.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/punctuation/comma_if.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/facilities/empty.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/punctuation/comma_if.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/punctuation/comma.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/punctuation/comma_if.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/array/push_back.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/array/detail/get_data.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/array/detail/get_data.hpp"
# 1 "/usr/local/include/boost/preprocessor/facilities/is_1.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/facilities/is_1.hpp"
# 1 "/usr/local/include/boost/preprocessor/facilities/is_empty.hpp" 1
# 26 "/usr/local/include/boost/preprocessor/facilities/is_empty.hpp"
# 1 "/usr/local/include/boost/preprocessor/facilities/identity.hpp" 1
# 27 "/usr/local/include/boost/preprocessor/facilities/is_empty.hpp" 2
# 17 "/usr/local/include/boost/preprocessor/facilities/is_1.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/array/detail/get_data.hpp" 2
# 23 "/usr/local/include/boost/preprocessor/array/push_back.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/array/insert.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/comparison/not_equal.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/array/insert.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/control/deduce_d.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/control/deduce_d.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/control/deduce_d.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/array/insert.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/pop_back.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/array/pop_back.hpp"
# 1 "/usr/local/include/boost/preprocessor/repetition/enum.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/repetition/enum.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/repetition/enum.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/repetition/repeat.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/repetition/repeat.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/repetition/repeat.hpp" 2
# 23 "/usr/local/include/boost/preprocessor/repetition/enum.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/array/pop_back.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/deduce_z.hpp" 1
# 15 "/usr/local/include/boost/preprocessor/repetition/deduce_z.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/repetition/deduce_z.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/array/pop_back.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/pop_front.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/array.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/array/push_front.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/remove.hpp" 1
# 25 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/replace.hpp" 1
# 26 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/reverse.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/array/reverse.hpp"
# 1 "/usr/local/include/boost/preprocessor/tuple/reverse.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/tuple/reverse.hpp"
# 1 "/usr/local/include/boost/preprocessor/tuple/size.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/tuple/reverse.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/array/reverse.hpp" 2
# 27 "/usr/local/include/boost/preprocessor/array.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/array/to_list.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/array/to_list.hpp"
# 1 "/usr/local/include/boost/preprocessor/tuple/to_list.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/array/to_list.hpp" 2
# 29 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/to_seq.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/array/to_seq.hpp"
# 1 "/usr/local/include/boost/preprocessor/tuple/to_seq.hpp" 1
# 51 "/usr/local/include/boost/preprocessor/tuple/to_seq.hpp"
/* An empty array can be passed */
# 21 "/usr/local/include/boost/preprocessor/array/to_seq.hpp" 2
# 30 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/array/to_tuple.hpp" 1
# 31 "/usr/local/include/boost/preprocessor/array.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/library.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/comparison.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/comparison.hpp"
# 1 "/usr/local/include/boost/preprocessor/comparison/equal.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/comparison.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/comparison/greater.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/comparison/greater.hpp"
# 1 "/usr/local/include/boost/preprocessor/comparison/less.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/comparison/greater.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/comparison.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/comparison/greater_equal.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/comparison.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/config/limits.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/control.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/control.hpp"
# 1 "/usr/local/include/boost/preprocessor/control/expr_if.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/control.hpp" 2
# 22 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/debug.hpp" 1
# 15 "/usr/local/include/boost/preprocessor/debug.hpp"
# 1 "/usr/local/include/boost/preprocessor/debug/assert.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/debug.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/debug/line.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/debug/line.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/iterate.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/iteration/iterate.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/slot.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/slot/slot.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/def.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/slot/slot.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/iteration/iterate.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/debug/line.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/stringize.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/debug/line.hpp" 2
# 17 "/usr/local/include/boost/preprocessor/debug.hpp" 2
# 23 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/facilities.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/facilities.hpp"
# 1 "/usr/local/include/boost/preprocessor/facilities/apply.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/facilities/apply.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/is_unary.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/facilities/apply.hpp" 2
# 17 "/usr/local/include/boost/preprocessor/facilities.hpp" 2



# 1 "/usr/local/include/boost/preprocessor/facilities/intercept.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/facilities.hpp" 2
# 24 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/iteration.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/iteration.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/local.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/iteration.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/iteration/self.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/iteration.hpp" 2
# 25 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/list.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/append.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/at.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/list/at.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/rest_n.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/list/at.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/cat.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/enum.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/list/enum.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/for_each_i.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/list/for_each_i.hpp"
# 1 "/usr/local/include/boost/preprocessor/repetition/for.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/repetition/for.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/repetition/for.hpp" 2
# 44 "/usr/local/include/boost/preprocessor/repetition/for.hpp"
# 1 "/usr/local/include/boost/preprocessor/repetition/detail/for.hpp" 1
# 45 "/usr/local/include/boost/preprocessor/repetition/for.hpp" 2
# 63 "/usr/local/include/boost/preprocessor/repetition/for.hpp"
// # define BOOST_PP_FOR_257(s, p, o, m) BOOST_PP_ERROR(0x0002)
# 21 "/usr/local/include/boost/preprocessor/list/for_each_i.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/list/enum.hpp" 2
# 22 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/filter.hpp" 1
# 23 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/first_n.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/list.hpp" 2


# 1 "/usr/local/include/boost/preprocessor/list/for_each.hpp" 1
# 27 "/usr/local/include/boost/preprocessor/list.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/list/for_each_product.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/list/for_each_product.hpp"
# 1 "/usr/local/include/boost/preprocessor/list/to_tuple.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/list/for_each_product.hpp" 2
# 29 "/usr/local/include/boost/preprocessor/list.hpp" 2


# 1 "/usr/local/include/boost/preprocessor/list/size.hpp" 1
# 32 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/to_array.hpp" 1
# 33 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/list/to_seq.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/list.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/list/transform.hpp" 1
# 36 "/usr/local/include/boost/preprocessor/list.hpp" 2
# 26 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/logical.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/logical.hpp"
# 1 "/usr/local/include/boost/preprocessor/logical/and.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/logical.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/logical/bitnor.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/logical.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/logical/bitor.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/logical.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/logical/bitxor.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/logical.hpp" 2


# 1 "/usr/local/include/boost/preprocessor/logical/nor.hpp" 1
# 25 "/usr/local/include/boost/preprocessor/logical.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/logical/or.hpp" 1
# 27 "/usr/local/include/boost/preprocessor/logical.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/logical/xor.hpp" 1
# 28 "/usr/local/include/boost/preprocessor/logical.hpp" 2
# 27 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/punctuation.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/punctuation.hpp"
# 1 "/usr/local/include/boost/preprocessor/punctuation/is_begin_parens.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/punctuation.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/punctuation/paren.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/punctuation.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/punctuation/paren_if.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/punctuation.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/punctuation/remove_parens.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/punctuation.hpp" 2
# 28 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition.hpp" 1
# 15 "/usr/local/include/boost/preprocessor/repetition.hpp"
# 1 "/usr/local/include/boost/preprocessor/repetition/deduce_r.hpp" 1
# 15 "/usr/local/include/boost/preprocessor/repetition/deduce_r.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/repetition/deduce_r.hpp" 2
# 16 "/usr/local/include/boost/preprocessor/repetition.hpp" 2


# 1 "/usr/local/include/boost/preprocessor/repetition/enum_binary_params.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_params.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_params_with_a_default.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_params_with_defaults.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_shifted.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/repetition/enum_shifted.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 23 "/usr/local/include/boost/preprocessor/repetition/enum_shifted.hpp" 2
# 23 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_shifted_binary_params.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_shifted_params.hpp" 1
# 25 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_trailing.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/repetition/enum_trailing.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/repetition/enum_trailing.hpp" 2
# 26 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_trailing_binary_params.hpp" 1
# 27 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/repetition/enum_trailing_params.hpp" 1
# 28 "/usr/local/include/boost/preprocessor/repetition.hpp" 2


# 1 "/usr/local/include/boost/preprocessor/repetition/repeat_from_to.hpp" 1
# 23 "/usr/local/include/boost/preprocessor/repetition/repeat_from_to.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/repetition/repeat_from_to.hpp" 2
# 31 "/usr/local/include/boost/preprocessor/repetition.hpp" 2
# 29 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/selection.hpp" 1
# 15 "/usr/local/include/boost/preprocessor/selection.hpp"
# 1 "/usr/local/include/boost/preprocessor/selection/max.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/selection.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/selection/min.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/selection.hpp" 2
# 30 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/seq.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/cat.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/seq/cat.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/fold_left.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/seq/fold_left.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/seq/fold_left.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/seq.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/seq/seq.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/elem.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/seq/seq.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/seq/fold_left.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/size.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/seq/fold_left.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/seq/cat.hpp" 2
# 17 "/usr/local/include/boost/preprocessor/seq.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/seq/enum.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/filter.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/first_n.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/seq/first_n.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/detail/split.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/seq/first_n.hpp" 2
# 21 "/usr/local/include/boost/preprocessor/seq.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/seq/fold_right.hpp" 1
# 16 "/usr/local/include/boost/preprocessor/seq/fold_right.hpp"
# 1 "/usr/local/include/boost/preprocessor/detail/auto_rec.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/seq/fold_right.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/seq/reverse.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/seq/fold_right.hpp" 2
# 23 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/for_each.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/seq/for_each.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/detail/is_empty.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/seq/detail/is_empty.hpp"
/* An empty seq is one that is just BOOST_PP_SEQ_NIL */
# 23 "/usr/local/include/boost/preprocessor/seq/for_each.hpp" 2
# 24 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/for_each_i.hpp" 1
# 25 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/for_each_product.hpp" 1
# 26 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/insert.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/seq/insert.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/rest_n.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/seq/insert.hpp" 2
# 27 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/pop_back.hpp" 1
# 28 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/pop_front.hpp" 1
# 29 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/push_back.hpp" 1
# 30 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/push_front.hpp" 1
# 31 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/remove.hpp" 1
# 32 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/replace.hpp" 1
# 33 "/usr/local/include/boost/preprocessor/seq.hpp" 2




# 1 "/usr/local/include/boost/preprocessor/seq/subseq.hpp" 1
# 38 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/to_array.hpp" 1
# 39 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/to_list.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/seq/to_list.hpp"
# 1 "/usr/local/include/boost/preprocessor/seq/detail/binary_transform.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/seq/detail/binary_transform.hpp"
# 1 "/usr/local/include/boost/preprocessor/variadic/detail/is_single_return.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/seq/detail/binary_transform.hpp" 2
# 19 "/usr/local/include/boost/preprocessor/seq/to_list.hpp" 2
# 40 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/to_tuple.hpp" 1
# 41 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/transform.hpp" 1
# 42 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/seq/variadic_seq_to_seq.hpp" 1
# 43 "/usr/local/include/boost/preprocessor/seq.hpp" 2
# 31 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/slot.hpp" 1
# 32 "/usr/local/include/boost/preprocessor/library.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/tuple.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/tuple.hpp"
# 1 "/usr/local/include/boost/preprocessor/tuple/enum.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/insert.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/pop_back.hpp" 1
# 23 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/pop_front.hpp" 1
# 24 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/push_back.hpp" 1
# 25 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/push_front.hpp" 1
# 26 "/usr/local/include/boost/preprocessor/tuple.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/tuple/remove.hpp" 1
# 28 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/tuple/replace.hpp" 1
# 29 "/usr/local/include/boost/preprocessor/tuple.hpp" 2


# 1 "/usr/local/include/boost/preprocessor/tuple/to_array.hpp" 1
# 32 "/usr/local/include/boost/preprocessor/tuple.hpp" 2
# 34 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/variadic.hpp" 1
# 18 "/usr/local/include/boost/preprocessor/variadic.hpp"
# 1 "/usr/local/include/boost/preprocessor/variadic/to_array.hpp" 1
# 19 "/usr/local/include/boost/preprocessor/variadic.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/variadic/to_list.hpp" 1
# 20 "/usr/local/include/boost/preprocessor/variadic.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/variadic/to_seq.hpp" 1
# 21 "/usr/local/include/boost/preprocessor/variadic.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/variadic/to_tuple.hpp" 1
# 22 "/usr/local/include/boost/preprocessor/variadic.hpp" 2
# 35 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 1 "/usr/local/include/boost/preprocessor/wstringize.hpp" 1
# 36 "/usr/local/include/boost/preprocessor/library.hpp" 2
# 18 "/usr/local/include/boost/preprocessor.hpp" 2
# 5 "../../p4c-5323/src/common.p4" 2

# 1 "/data/bf-p4c-compilers/build/master-git-rel2/p4c/p4include/core.p4" 1
/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */
# 7 "../../p4c-5323/src/common.p4" 2




//Persistent bugs with large ALPM keys currently preclude this
//Pure TCAM v6 CIDR severely restricts sizes, but gives reliable behavior
//#define USE_ALPM_CIDR6_TABLES






//Allow for an external override
# 36 "../../p4c-5323/src/common.p4"
typedef bit<5> GroupId_t;
typedef bit<4> Priority_t;
typedef bit<16> RuleId_t;






//Bifurcate - most significant bit indicates special use case
enum bit<8> WrapperType_t {
  Raw = 0,
  NO_TYPE = 0,
  UBUS = 0b000000001,
  Aggregation = 0b000000010,
  AristaTime = 0b000000100,
  VLanFlow = 0b000001000,
  GFP = 0b000010000,
  MPLS = 0b000100000,
  VLanSads = 0b001000000
}



//Contemplate making WrapperType_t and OutputType two separate types
//OutputType would then be a contextual blob:

enum bit<5> ContextualType_t {
  OUTPUT_Raw = 0, //Egress inputs
  OUTPUT_UBUS = 1,
  OUTPUT_Aggregation = 2,
  OUTPUT_AristaTime = 3,
  OUTPUT_VLanFlow = 4,

  EXPECT_NO_TYPE = 0, //Decision inputs
  EXPECT_ETHERNET = 1,
  EXPECT_VLAN = 2,
  EXPECT_MPLS = 3,
  EXPECT_FRAGMENT = 4,

  IP_EXT_LEN_TOO_GREAT = 0x1F
}



struct PortConfig_t{
  bit<32> flowID;
  bit<8> inputType;
  GroupId_t patchPanelGroup;
  Priority_t patchPriority;
  bit<8> flags;
}
# 96 "../../p4c-5323/src/common.p4"
enum bit<2> FramingType_t {
  None = 0,
  NonEth = 1,
  Eth = 2,
  NonRetentionEth = 3
}

//Defines provided for some clarity in setting framingInfo in ingress
//Unfortunately doesn't seem possible to directly use enum as part of the set




enum bit<3> FlowIdType_t {
  UNREAD = 0,
  AGGREGATE = 1,
  MPLS = 2,
  VLAN = 3,
  UBUS = 4,
  VLAN_SADS = 5
}

enum bit<8> GfpType_t{
  ETHERNET = 0x01,
  MPLS = 0x0d,
  MPLSm = 0x0e,
  IPV4 = 0x10,
  IPV6 = 0x11,
  PPP = 0x02,
  ENCODED_ETHERNET = 0x13
}

enum bit<16> EtherType_t {
  IPV4 = 0x0800,
  ARISTA=0xD28B,
  GFP = 0x4F46,
  AGGREGATION_PROTOCOL = 0x7260,
  VLAN = 0x8100,
  IPV6 = 0x86DD,
  MPLS = 0x8847,
  MPLSm= 0x8848,
  PPPoE= 0x8864,
  VLANAD=0x88A8,
  CESOE =0x88D8,
  MACSEC=0x88E5,
  PBB = 0x88E7, // 802.1AH / PBB / Mac-in-Mac
  VLANADX=0x9100,
  VLAN2= 0x9200,
  VLAN3= 0x9300,
  VLANQA=0xA100,
  ETHERNET_BRIDGING=0x6558,
  ARP = 0x0806
}

header SixteenBytes_h {
  bit<128> bits;
}

header TwelveBytes_h {
  bit<96> bits;
}

header EightBytes_h {
  bit<64> bits;
}

header FourBytes_h {
  bit<32> bits;
}

header ThreeBytes_h {
  bit<24> bits;
}

header TwoBytes_h {
  bit<16> bits;
}

header OneByte_h {
  bit<8> bits;
}

struct Unknown_t {
  FourBytes_h[16] word;
}

header FramingMap_h {
  bit<16> typeIndicator;
  bit<20> pad;
  bit<4> gfpExt;
  bit<8> gfpProtocol;
}

header Gfp_h {
  bit<16> len;
  bit<16> hec;
  bit<3> pti; //payload type identifier {0:data, 1:client mgmt, 2:mgmt}
  bit<1> fcsFlag;
  bit<4> extHdr; //variable extension header {0:null, 1:linear, 2:ring}
  GfpType_t nextProto;
  bit<16> tHec;
}

header Ethernet_h {
  bit<48> dstAddr;
  bit<48> srcAddr;
  EtherType_t etherType;
}

header EthernetAddresses_h {
  bit<48> dstAddr;
  bit<48> srcAddr;
}

header Aggregation_h {
  bit<4> version;
  bit<5> optionalFlags;
  bit<7> len;
  bit<16> payloadType;
  bit<3> verMod;
  bit<5> sigFlags;
  bit<8> pad;
  bit<32> flowID;
}

header UBus_h {
  bit<4> ver;
  bit<5> toggle;
  bit<7> len;
  bit<16> nextProto;
  bit<64> timestamp;
  bit<32> DFID;
}

header Vlan_h {
  bit<3> pcp;
  bit<1> cfi;
  bit<12> vid;
  EtherType_t etherType;
}

header VlanOutputFlow_h {
  bit<16> vid;
  EtherType_t etherType;
}

header Mpls_h {
  bit<20> label;
  bit<3> tc;
  bit<1> bos;
  bit<8> ttl;
}

header IPv4_h {
  bit<4> version;
  bit<4> header_len;
  bit<8> tos;
  bit<16> total_len;
  bit<16> ipid;
  bit<1> reserved;
  bit<1> dontFragment;
  bit<1> moreFrags;
  bit<13> frag_offset;
  bit<8> ttl;
  bit<8> nextProto;
  bit<16> hdr_checksum;
  bit<32> src_addr;
  bit<32> dst_addr;
}

header IPv4_Basics_h {
  bit<4> version;
  bit<4> header_len;
  bit<8> tos;
  bit<16> total_len;
  bit<16> ipid;
  bit<1> reserved;
  bit<1> dontFragment;
  bit<1> moreFrags;
  bit<13> frag_offset;
  bit<8> ttl;
  bit<8> nextProto;
  bit<16> hdr_checksum;
}

header IPv4_Addresses_h {
  bit<32> src_addr;
  bit<32> dst_addr;
}

header IPv6_Basics_h {
  bit<4> version;
  bit<8> traffic_class;
  bit<20> flow_label;
  bit<16> total_len;
  bit<8> nextProto;
  bit<8> ttl;
}

header IPv6_Ext_h {
  bit<8> nextProto;
  bit<8> header_len;
  bit<48> options_and_padding;
}

struct IpExtensionBytes_s {
    SixteenBytes_h B16;
    TwelveBytes_h B12;
    EightBytes_h B8;
    FourBytes_h B4;
}

header CloningHeader_h {
  bit<32> cloneMarker;
}

header IPv6_Fragment_h {
  bit<8> nextProto;
  bit<8> reserved1;
  bit<13> frag_offset;
  bit<2> reserved2;
  bit<1> moreFrags;
  bit<32> ipid;
}

header Transport_h {
  bit<16> src_port;
  bit<16> dst_port;
}

header TCP_Middle_h {
  bit<32> sequenceNumber;
  bit<32> ackNumber;
  bit<4> header_len;
  bit<6> reserved;
  bit<6> flags;
  bit<16> windowSize;
} //Ports and last four bytes omitted here

header BytesBlock_h {
  bit<32> pad;
  bit<16> hw1;
  bit<16> hw2;
  bit<16> hw3;
  bit<16> hw4;
  bit<16> hw5;
  bit<16> hw6;
}

header PPPoE_h {
  bit<4> version;
  bit<4> type;
  bit<8> code;
  bit<16> sess_id;
  bit<16> len;
  bit<16> nextProto;
}

header PPPoE_Short_h {
  bit<4> version;
  bit<4> type;
  bit<8> code;
  bit<16> sess_id;
  bit<16> len;
  bit<8> nextProto;
}

header PPP_h {
  bit<8> flag;
  bit<8> address;
  bit<8> ctrl;
  bit<16> nextProto;
}

/// Header to pass state/meta between different Ingress/Egress/Ingress/Egress stages
//NOTE: Two-byte value in bytes 12 and 13 MUST have a value >= 0x0800 at all times.
header Internal_h {
  bit<8> layer2Skip;

  FramingType_t framedPacket;
  bit<1> maybeIPv6;
  bit<1> contextualFlag; //WasIP/RetainHash Decision, Don't Scan DeepInspection, Start of Flow DefeatFlow
  Priority_t priority;

  bit<3> PayloadDepth12;
  GroupId_t outputGroup;

  bit<1> haveUBus;
  @padding bit<2> pad;
  ContextualType_t contextualType;
  bit<64> timestamp;
  bit<32> hash;
  bit<32> flowID;
}

//Structure notes:
//Tofino 1 requires that bytes 12 and 13 look like a valid ethertype
//Therefore one of the 5 most significant bits must be set
//No existing field supports this, handled by editing hash value
//Small loss of entropy, unavoidable
//Forces position of hash value
//Timestamp position therefore also forced - processing values must be first 4 bytes,
//Timestamp is the only field that fills the intervening 8 bytes
//flowID then also forced.
//Priority and outputGroup must be in separate bytes to facilitate use in egress
//Both must also be wholly contained in one byte
# 28 "../../p4c-5323/src/architecture.p4" 2



# 1 "../../p4c-5323/src/Ghost.p4" 1
       

typedef bit<8> GhostRegValue;
typedef bit<13> GhostKeyValue;

Register<GhostRegValue, GhostKeyValue >(1<<13, 0) sfc_reg_qdepth;
Register<bit<1>, GhostKeyValue>(1<<13,0) flag_reg;

control GhostSfc(in ghost_intrinsic_metadata_t g_intr_md) {


    // Ghost thread: queue depth value
    RegisterAction<GhostRegValue, GhostKeyValue, GhostRegValue>(sfc_reg_qdepth) qdepth_write_over = {
        void apply(inout GhostRegValue value) {
            value = 8w1;
        }
    };
    RegisterAction<GhostRegValue, GhostKeyValue, GhostRegValue>(sfc_reg_qdepth) qdepth_write_under = {
        void apply(inout GhostRegValue value) {
            value = 8w0;
        }
    };
    RegisterAction<bit<1>, GhostKeyValue, bit<1>>(flag_reg) qdepth_write_flag = {
        void apply(inout bit<1> value) {
            value = 1w1;
        }
    };

    action do_set_under_threshold() {
        qdepth_write_over.execute(g_intr_md.pipe_id ++ g_intr_md.qid);
    }

    action do_set_over_threshold() {
        qdepth_write_under.execute(g_intr_md.pipe_id ++ g_intr_md.qid);
    }

    action do_set_flag() {
        qdepth_write_flag.execute(g_intr_md.pipe_id ++ g_intr_md.qid);
    }

    table ghost_check_threshold_tbl {
        key = {
            g_intr_md.qlength : range@name("qdepth");
        }
        actions = {
            do_set_under_threshold;
            do_set_over_threshold;
            NoAction;
        }
        const default_action = NoAction();
        size = 32;
    }

    apply {
        ghost_check_threshold_tbl.apply();
        do_set_flag();
    }
}

control GhostMetrics(in ghost_intrinsic_metadata_t g_intr_md) {
    Counter<bit<32>, bit<15>>(1<<15,CounterType_t.PACKETS) queue_depth_histogram;
    action count() {
        queue_depth_histogram.count(g_intr_md.pipe_id[0:0] ++ g_intr_md.qid ++ g_intr_md.qlength[17:15]);
    }
    @stage(19)
    table doCount {
      actions = {count;}
      const default_action = count();
    }
    apply {
      doCount.apply();
    }
}

control GhostDualMetrics(in ghost_intrinsic_metadata_t g_intr_md) {
    Counter<bit<32>, bit<13>>(1<<13,CounterType_t.PACKETS) overloads;
    Counter<bit<32>, bit<13>>(1<<13,CounterType_t.PACKETS) lowqueue;
    bit<2> triggerCount = 0;

    action set_overload() {triggerCount = 1;}
    action set_low() {triggerCount = 2;}

    table ghost_check_threshold_tbl {
        key = {
            g_intr_md.qlength : range@name("qdepth");
        }
        actions = {
            set_overload;
            set_low;
            NoAction;
        }
        const default_action = NoAction();
        size = 32;
    }

    apply {
        ghost_check_threshold_tbl.apply();
        if(triggerCount == 1)
          overloads.count(g_intr_md.pipe_id ++ g_intr_md.qid);
        else if(triggerCount == 2)
          lowqueue.count(g_intr_md.pipe_id ++ g_intr_md.qid);
    }
}
# 32 "../../p4c-5323/src/architecture.p4" 2
# 4 "../../p4c-5323/src/DefeatFlows.p4" 2



# 1 "../../p4c-5323/src/throttle.p4" 1
/* -*- P4_16 -*- */
       

# 1 "/data/bf-p4c-compilers/build/master-git-rel2/p4c/p4include/core.p4" 1
/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

/* This is the P4-16 core library, which declares some built-in P4 constructs using P4 */
# 5 "../../p4c-5323/src/throttle.p4" 2


# 1 "../../p4c-5323/src/CommonCode/NetFlowCloner.p4" 1
       

# 1 "../../p4c-5323/src/CommonCode/RouteHashing.p4" 1
       

# 1 "../../p4c-5323/src/CommonCode/Hasher.p4" 1
       

control SimpleHasher
  (out bit<32> hash, in bit<32> src, in bit<32> dst, in bit<16> sp, in bit<16> dp)
  (bit<32> Polynomial, int pprio) {
    CRCPolynomial<bit<32>>(Polynomial, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) algo;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, algo) hasher;
    action do_hash() {hash = hasher.get({src,dst,sp,dp});}
    @pragma placement_priority pprio
    @hidden table calc_hash {
        actions = {do_hash;}
        const default_action = do_hash();
    }
    apply {
        calc_hash.apply();
    }
}

//NOTE: Likely this will stop working in the near future
control SimpleFieldHasher<FieldType>
  (out bit<32> hash, in FieldType field)
  (bit<32> Polynomial, int pprio) {
    CRCPolynomial<bit<32>>(Polynomial, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) algo;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, algo) hasher;
    action do_hash() {hash = hasher.get({field});}
    @pragma placement_priority pprio
    @hidden table calc_hash {
        actions = {do_hash;}
        const default_action = do_hash();
    }
    apply {
        calc_hash.apply();
    }
}

control RandomGenerator(out bit<32> value) {
    Random<bit<32>>() rng;
    action doRng() {value = rng.get();}
    @hidden table calcRng {
        actions = {doRng;}
        const default_action = doRng();
    }
    apply {
        calcRng.apply();
    }
}

control RandomGenerator16(out bit<16> value) {
    Random<bit<16>>() rng;
    action doRng() {value = rng.get();}
    @hidden table calcRng {
        actions = {doRng;}
        const default_action = doRng();
    }
    apply {
        calcRng.apply();
    }
}

control DualWordHasher
  (out bit<32> hash, in bit<32> src, in bit<32> dst)
  (bit<32> Polynomial, int pprio) {
    CRCPolynomial<bit<32>>(Polynomial, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) algo;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, algo) hasher;
    action do_hash() {hash = hasher.get({src,dst});}
    @pragma placement_priority pprio
    @hidden table calc_hash {
        actions = {do_hash;}
        const default_action = do_hash();
    }
    apply {
        calc_hash.apply();
    }
}

control EightWordHasher
  (out bit<32> hash, in bit<32> w1, in bit<32> w2, in bit<32> w3, in bit<32> w4, in bit<32> w5, in bit<32> w6, in bit<32> w7, in bit<32> w8)
  (bit<32> Polynomial, int pprio) {
    CRCPolynomial<bit<32>>(Polynomial, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) algo;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, algo) hasher;
    action do_hash() {hash = hasher.get({w1,w2,w3,w4,w5,w6,w7,w8});}
    @pragma placement_priority pprio
    @hidden table calc_hash {
        actions = {do_hash;}
        const default_action = do_hash();
    }
    apply {
        calc_hash.apply();
    }
}

control FlowAndEthHasher
  (out bit<32> hash, in bit<48> src, in bit<48> dst, in bit<32> flowId, in bit<8> offset, in bit<16> type)
  (bit<32> Polynomial, int pprio) {
    CRCPolynomial<bit<32>>(Polynomial, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) algo;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, algo) hasher;
    action do_hash() {hash = hasher.get({src,dst,flowId,offset,type});}
    @pragma placement_priority pprio
    table calc_hash {
        actions = {do_hash;}
        const default_action = do_hash();
    }
    apply {
        calc_hash.apply();
    }
}
# 4 "../../p4c-5323/src/CommonCode/RouteHashing.p4" 2

struct RouteHashes_s {
    bit<32> hash1;
    bit<32> hash2;
    bit<32> hash3;
};

control SimpleFlowHash(out RouteHashes_s routing, in bit<32> sourceHash, in bit<32> destHash, in bit<16> srcPort, in bit<16> dstPort)
{
    SimpleHasher(0x04C11DB7,1) calc_hash1;//MSBit 1 omitted from CRC parameter
    SimpleHasher(0x1EDC6F41,1) calc_hash2;
    SimpleHasher(0xA833982B,1) calc_hash3;
    apply {
        calc_hash1.apply(routing.hash1,sourceHash,destHash,srcPort,dstPort);
        calc_hash2.apply(routing.hash2,sourceHash,destHash,srcPort,dstPort);
        calc_hash3.apply(routing.hash3,sourceHash,destHash,srcPort,dstPort);
    }
}
# 4 "../../p4c-5323/src/CommonCode/NetFlowCloner.p4" 2


control PacketCloner(inout ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata,
                     inout MirrorId_t mirrorSession, in bit<32> sourceId, in bit<8> headersLength, in RouteHashes_s routing)
{
    action mirror(MirrorId_t session, PortId_t port) {

        ingressDeparserMetadata.mirror_egress_port = port;

        ingressDeparserMetadata.mirror_type = 1;
        mirrorSession = session;
    }
    table routingControl {
        key = {
            sourceId : ternary;
        }
        actions = {NoAction;}
        size = 512;
        const default_action = NoAction();
    }

    Hash<bit<66>>(HashAlgorithm_t.IDENTITY) final_hash;
    ActionSelector(2048, final_hash, SelectorMode_t.RESILIENT) balancer;
    @selector_max_group_size(128)
    @pragma placement_priority 2
    table mirrorControl {
        key = {
            headersLength : ternary;
            routing.hash1 : selector;
            routing.hash2 : selector;
            routing.hash3 : selector;}
        actions = {mirror; NoAction;}
        size = 256;
        implementation = balancer;
        const default_action = NoAction();
    }
    apply {
        if(routingControl.apply().hit)
        {
            mirrorControl.apply();
        }
    }
}

control FairPacketCloner(inout ingress_intrinsic_metadata_for_deparser_t ingressDeparserMetadata,
                     inout MirrorId_t mirrorSession, in bit<32> sourceId, in bit<8> headersLength, in bit<32> randomKey,
                     in bit<32> routing, in bool promote, in Priority_t priority, in GroupId_t group, inout bit<32> cloneMarker)
{
    action mirror(MirrorId_t session, PortId_t port) {

        ingressDeparserMetadata.mirror_egress_port = port;

        ingressDeparserMetadata.mirror_type = 1;
        cloneMarker = 0x7AC35A1F;
        mirrorSession = session;
    }
    table routingControl {
        key = {
            priority : ternary;
            group : ternary;
            promote : ternary; //Allow limiting cloning to packets dropped by throttling
            sourceId : ternary;
            randomKey : ternary;
        }
        actions = {NoAction;}
        size = 512;
        const default_action = NoAction();
    }

    Hash<bit<32>>(HashAlgorithm_t.IDENTITY) final_hash;
    ActionSelector(2048, final_hash, SelectorMode_t.FAIR) balancer;
    @selector_max_group_size(128)
    table mirrorControl {
        key = {
            headersLength : ternary;
            routing : selector;
        }
        actions = {mirror; NoAction;}
        size = 256;
        implementation = balancer;
        const default_action = NoAction();
    }
    apply {
        if(routingControl.apply().hit)
        {
            mirrorControl.apply();
        }
    }
}
# 8 "../../p4c-5323/src/throttle.p4" 2

struct throttle_meta_t
{
  bool continueLooping;
  bool returnedPacket;//Save this information to prevent IPFIX cloning
  MirrorId_t mirrorSession;
  bit<32> cloneMarker;
}

struct throttle_headers_t
{



  Internal_h internal;
}

parser ThrottleParser(packet_in pkt,
                      out throttle_headers_t hdr,
                      out throttle_meta_t meta,
                      out ingress_intrinsic_metadata_t ig_intr_md)
{
  state start {
    meta.continueLooping = false;
    meta.returnedPacket = false;
    meta.mirrorSession = 0;
    meta.cloneMarker = 0;
    pkt.extract(ig_intr_md);

    pkt.advance(PORT_METADATA_SIZE); // required

    pkt.extract(hdr.internal);

//Optimization breaks Tofino 1 build for unclear reasons
    transition handleOutputType;
  }

  state handleOutputType {

    transition select((bit<5>)hdr.internal.contextualType) {
      (bit<5>)ContextualType_t.EXPECT_NO_TYPE : accept;




      (bit<5>)ContextualType_t.EXPECT_NO_TYPE : handleOutputType; //Dummy state

      default : loopingContinues;
    }
  }







  state loopingContinues {
    meta.continueLooping = true;
    transition accept;
  }
  state returnedPacket {
    meta.returnedPacket = true;
    transition accept;
  }
}


control Throttle(inout throttle_headers_t hdr,
                 inout throttle_meta_t meta,
                 in ingress_intrinsic_metadata_t ig_intr_md,
                 in ingress_intrinsic_metadata_from_parser_t ig_intr_md_from_prsr,
                 inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
                 inout ingress_intrinsic_metadata_for_tm_t ig_intr_md_for_tm)
{
  Hash<bit<16>>(HashAlgorithm_t.CRC16) timeHash;
  Counter<bit<32>, bit<1>>(2, CounterType_t.PACKETS) IngrPkts;
  Counter<bit<32>, bit<10>>(1<<(9 +1), CounterType_t.PACKETS_AND_BYTES) ThrottleTraffic;
  Counter<bit<32>, GroupId_t>(1<<5, CounterType_t.PACKETS_AND_BYTES) promoteGroup;
  Counter<bit<32>, GroupId_t>(1<<5, CounterType_t.PACKETS_AND_BYTES) randomGroup;
  Counter<bit<32>, GroupId_t>(1<<5, CounterType_t.PACKETS_AND_BYTES) dropGroup;

  Counter<bit<32>, bit<9>>(1<<9, CounterType_t.PACKETS_AND_BYTES) allGroupPriority;

  bit<32> flowHash = 0;
  Hash<bit<32>>(HashAlgorithm_t.IDENTITY) no_hash;
  ActionProfile(size=16384) OutputProfile;
  ActionSelector(OutputProfile, no_hash, SelectorMode_t.FAIR, 512, 32) OutputSelector;
  action OutputMulticast(MulticastGroupId_t mcast, GroupId_t realGroup) { //Allow packet replication to multiple outputs
    ig_intr_md_for_tm.mcast_grp_a = mcast;
    ig_intr_md_for_dprsr.drop_ctl = 0;
  }
  action OutputPort(PortId_t port) { ig_intr_md_for_dprsr.drop_ctl = 0; ig_intr_md_for_tm.ucast_egress_port = port; }
  action Drop() { ig_intr_md_for_dprsr.drop_ctl = 1; }
  table OutputMapper {
    actions = { OutputPort; Drop; OutputMulticast; }
    default_action = Drop();
    key = {
      hdr.internal.outputGroup : exact @name("outputGroup");
      flowHash : selector @name("flowHash");
    }
    size = 1<<5;
    implementation = OutputSelector;
  }

  Random<bit<32>>() randPort;
  action Normal(ContextualType_t outputType) { hdr.internal.contextualType = outputType; flowHash = hdr.internal.hash; }
  action RoundRobinOutputPort(ContextualType_t outputType) { hdr.internal.contextualType = outputType; flowHash = randPort.get(); }
  table OutputGroupConfig
  {
    actions = { Normal; RoundRobinOutputPort; }
    default_action = Normal(ContextualType_t.OUTPUT_UBUS);
    key = { hdr.internal.outputGroup : exact @name("outputGroup"); }
    size = 1<<5;
  }

  GroupId_t rndGroup;
  bit<32> randomKey;
  Random<bit<32>>() randKey;
  action SameGroup() { rndGroup = hdr.internal.outputGroup; randomKey = hdr.internal.hash; }
  action ChangeGroup(GroupId_t newGroup) { rndGroup = newGroup; randomKey = hdr.internal.hash; }
  action SampledGroup() {rndGroup = hdr.internal.outputGroup; randomKey = randKey.get();}
  action SampledChangedGroup(GroupId_t newGroup) {rndGroup = newGroup; randomKey = randKey.get();}
  table SelectRandomGroup {
    actions = { SameGroup; ChangeGroup; SampledGroup; SampledChangedGroup;}
    key = { hdr.internal.outputGroup : exact @name("outputGroup"); }
    default_action = SameGroup();
    size = 1<<5;
  }

  Meter<GroupId_t>(1<<5, MeterType_t.BYTES) PromotionMeter;
  Register<bit<16>, GroupId_t>(1<<5, ((((1<<4)-1)<<8)|255)) PromotionLevelAndStep;
  RegisterAction<bit<16>, GroupId_t, bit<16>>(PromotionLevelAndStep) getPromoLevel = {
    void apply(inout bit<16> reg, out bit<16> val)
    {
      val = reg;
    }
  };
  bit<8> color;
  DirectCounter<bit<32> >(CounterType_t.BYTES) promotionColorCount;
  action CountPromotionColor() { promotionColorCount.count(); }
  table PromoteColorMonitor {
    actions = { CountPromotionColor; }
    key = {
      hdr.internal.outputGroup : exact @name("outputGroup");
      color[2:0] : exact @name("color");
    }
    const default_action = CountPromotionColor();
    const entries = {





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,0): CountPromotionColor(); (0,1): CountPromotionColor(); (0,3): CountPromotionColor();


        (1,0): CountPromotionColor(); (1,1): CountPromotionColor(); (1,3): CountPromotionColor();


        (2,0): CountPromotionColor(); (2,1): CountPromotionColor(); (2,3): CountPromotionColor();


        (3,0): CountPromotionColor(); (3,1): CountPromotionColor(); (3,3): CountPromotionColor();


        (4,0): CountPromotionColor(); (4,1): CountPromotionColor(); (4,3): CountPromotionColor();


        (5,0): CountPromotionColor(); (5,1): CountPromotionColor(); (5,3): CountPromotionColor();


        (6,0): CountPromotionColor(); (6,1): CountPromotionColor(); (6,3): CountPromotionColor();


        (7,0): CountPromotionColor(); (7,1): CountPromotionColor(); (7,3): CountPromotionColor();


        (8,0): CountPromotionColor(); (8,1): CountPromotionColor(); (8,3): CountPromotionColor();


        (9,0): CountPromotionColor(); (9,1): CountPromotionColor(); (9,3): CountPromotionColor();


        (10,0): CountPromotionColor(); (10,1): CountPromotionColor(); (10,3): CountPromotionColor();


        (11,0): CountPromotionColor(); (11,1): CountPromotionColor(); (11,3): CountPromotionColor();


        (12,0): CountPromotionColor(); (12,1): CountPromotionColor(); (12,3): CountPromotionColor();


        (13,0): CountPromotionColor(); (13,1): CountPromotionColor(); (13,3): CountPromotionColor();


        (14,0): CountPromotionColor(); (14,1): CountPromotionColor(); (14,3): CountPromotionColor();


        (15,0): CountPromotionColor(); (15,1): CountPromotionColor(); (15,3): CountPromotionColor();


        (16,0): CountPromotionColor(); (16,1): CountPromotionColor(); (16,3): CountPromotionColor();


        (17,0): CountPromotionColor(); (17,1): CountPromotionColor(); (17,3): CountPromotionColor();


        (18,0): CountPromotionColor(); (18,1): CountPromotionColor(); (18,3): CountPromotionColor();


        (19,0): CountPromotionColor(); (19,1): CountPromotionColor(); (19,3): CountPromotionColor();


        (20,0): CountPromotionColor(); (20,1): CountPromotionColor(); (20,3): CountPromotionColor();


        (21,0): CountPromotionColor(); (21,1): CountPromotionColor(); (21,3): CountPromotionColor();


        (22,0): CountPromotionColor(); (22,1): CountPromotionColor(); (22,3): CountPromotionColor();


        (23,0): CountPromotionColor(); (23,1): CountPromotionColor(); (23,3): CountPromotionColor();


        (24,0): CountPromotionColor(); (24,1): CountPromotionColor(); (24,3): CountPromotionColor();


        (25,0): CountPromotionColor(); (25,1): CountPromotionColor(); (25,3): CountPromotionColor();


        (26,0): CountPromotionColor(); (26,1): CountPromotionColor(); (26,3): CountPromotionColor();


        (27,0): CountPromotionColor(); (27,1): CountPromotionColor(); (27,3): CountPromotionColor();


        (28,0): CountPromotionColor(); (28,1): CountPromotionColor(); (28,3): CountPromotionColor();


        (29,0): CountPromotionColor(); (29,1): CountPromotionColor(); (29,3): CountPromotionColor();


        (30,0): CountPromotionColor(); (30,1): CountPromotionColor(); (30,3): CountPromotionColor();


        (31,0): CountPromotionColor(); (31,1): CountPromotionColor(); (31,3): CountPromotionColor();
# 163 "../../p4c-5323/src/throttle.p4" 2
    }
    size = 3 * (1<<5);
    counters = promotionColorCount;
  }

  Register<bit<16>, GroupId_t>(1<<5, 0xFFC0) RandomRotate; // ffc0 roates every ~270 seconds
  RegisterAction<bit<16>, GroupId_t, bit<16>>(RandomRotate) getRotate = {
    void apply(inout bit<16> reg, out bit<16> val)
    {
      val = reg;
    }
  };
  Meter<GroupId_t>(1<<5, MeterType_t.BYTES) RandomMeter;
  Register<bit<16>, GroupId_t>(1<<5, 0x0) RandomLevel;
  RegisterAction<bit<16>, GroupId_t, bit<16>>(RandomLevel) getRandomLevel = {
    void apply(inout bit<16> reg, out bit<16> val)
    {
      val = reg;
    }
  };
  DirectCounter<bit<32> >(CounterType_t.BYTES) randomColorCount;
  action CountRandomColor() { randomColorCount.count(); }
  table RandomColorMonitor {
    actions = { CountRandomColor; }
    key = {
      hdr.internal.outputGroup : exact @name("outputGroup");
      color[2:0] : exact @name("color");
    }
    const default_action = CountRandomColor();
    const entries = {





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,0): CountRandomColor(); (0,1): CountRandomColor(); (0,3): CountRandomColor();


        (1,0): CountRandomColor(); (1,1): CountRandomColor(); (1,3): CountRandomColor();


        (2,0): CountRandomColor(); (2,1): CountRandomColor(); (2,3): CountRandomColor();


        (3,0): CountRandomColor(); (3,1): CountRandomColor(); (3,3): CountRandomColor();


        (4,0): CountRandomColor(); (4,1): CountRandomColor(); (4,3): CountRandomColor();


        (5,0): CountRandomColor(); (5,1): CountRandomColor(); (5,3): CountRandomColor();


        (6,0): CountRandomColor(); (6,1): CountRandomColor(); (6,3): CountRandomColor();


        (7,0): CountRandomColor(); (7,1): CountRandomColor(); (7,3): CountRandomColor();


        (8,0): CountRandomColor(); (8,1): CountRandomColor(); (8,3): CountRandomColor();


        (9,0): CountRandomColor(); (9,1): CountRandomColor(); (9,3): CountRandomColor();


        (10,0): CountRandomColor(); (10,1): CountRandomColor(); (10,3): CountRandomColor();


        (11,0): CountRandomColor(); (11,1): CountRandomColor(); (11,3): CountRandomColor();


        (12,0): CountRandomColor(); (12,1): CountRandomColor(); (12,3): CountRandomColor();


        (13,0): CountRandomColor(); (13,1): CountRandomColor(); (13,3): CountRandomColor();


        (14,0): CountRandomColor(); (14,1): CountRandomColor(); (14,3): CountRandomColor();


        (15,0): CountRandomColor(); (15,1): CountRandomColor(); (15,3): CountRandomColor();


        (16,0): CountRandomColor(); (16,1): CountRandomColor(); (16,3): CountRandomColor();


        (17,0): CountRandomColor(); (17,1): CountRandomColor(); (17,3): CountRandomColor();


        (18,0): CountRandomColor(); (18,1): CountRandomColor(); (18,3): CountRandomColor();


        (19,0): CountRandomColor(); (19,1): CountRandomColor(); (19,3): CountRandomColor();


        (20,0): CountRandomColor(); (20,1): CountRandomColor(); (20,3): CountRandomColor();


        (21,0): CountRandomColor(); (21,1): CountRandomColor(); (21,3): CountRandomColor();


        (22,0): CountRandomColor(); (22,1): CountRandomColor(); (22,3): CountRandomColor();


        (23,0): CountRandomColor(); (23,1): CountRandomColor(); (23,3): CountRandomColor();


        (24,0): CountRandomColor(); (24,1): CountRandomColor(); (24,3): CountRandomColor();


        (25,0): CountRandomColor(); (25,1): CountRandomColor(); (25,3): CountRandomColor();


        (26,0): CountRandomColor(); (26,1): CountRandomColor(); (26,3): CountRandomColor();


        (27,0): CountRandomColor(); (27,1): CountRandomColor(); (27,3): CountRandomColor();


        (28,0): CountRandomColor(); (28,1): CountRandomColor(); (28,3): CountRandomColor();


        (29,0): CountRandomColor(); (29,1): CountRandomColor(); (29,3): CountRandomColor();


        (30,0): CountRandomColor(); (30,1): CountRandomColor(); (30,3): CountRandomColor();


        (31,0): CountRandomColor(); (31,1): CountRandomColor(); (31,3): CountRandomColor();
# 199 "../../p4c-5323/src/throttle.p4" 2
    }
    size = 3 * (1<<5);
    counters = randomColorCount;
  }
  FairPacketCloner() packetCloner;

  //This uses one SRAM block, generally in stage 1 - which will reliably have free SRAM.
  //Significantly shrinks the throttle dependency chain
  bit<16> promoLevel = 0;
  action setPromoLevel(bit<16> level) {promoLevel = level |-| promoLevel;}
  @hidden table calculatePromoLevel {
    key = {hdr.internal.priority : exact; hdr.internal.hash[7:0] : exact @name("hashByte");}
    actions = {setPromoLevel;}
    const default_action = setPromoLevel(0x7F00);
    const entries = { //setPromoLevel parameter = ((priority<<8)|hash)+1


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 1
# 17 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/lower1.hpp" 2
# 18 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2

# 1 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 1
# 12 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp"
# 1 "/usr/local/include/boost/preprocessor/slot/detail/shared.hpp" 1
# 13 "/usr/local/include/boost/preprocessor/iteration/detail/bounds/upper1.hpp" 2
# 20 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp"
# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,0) : setPromoLevel(((0<<8)|0)+1);


        (1,0) : setPromoLevel(((1<<8)|0)+1);


        (2,0) : setPromoLevel(((2<<8)|0)+1);


        (3,0) : setPromoLevel(((3<<8)|0)+1);


        (4,0) : setPromoLevel(((4<<8)|0)+1);


        (5,0) : setPromoLevel(((5<<8)|0)+1);


        (6,0) : setPromoLevel(((6<<8)|0)+1);


        (7,0) : setPromoLevel(((7<<8)|0)+1);


        (8,0) : setPromoLevel(((8<<8)|0)+1);


        (9,0) : setPromoLevel(((9<<8)|0)+1);


        (10,0) : setPromoLevel(((10<<8)|0)+1);


        (11,0) : setPromoLevel(((11<<8)|0)+1);


        (12,0) : setPromoLevel(((12<<8)|0)+1);


        (13,0) : setPromoLevel(((13<<8)|0)+1);


        (14,0) : setPromoLevel(((14<<8)|0)+1);


        (15,0) : setPromoLevel(((15<<8)|0)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 48 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,1) : setPromoLevel(((0<<8)|1)+1);


        (1,1) : setPromoLevel(((1<<8)|1)+1);


        (2,1) : setPromoLevel(((2<<8)|1)+1);


        (3,1) : setPromoLevel(((3<<8)|1)+1);


        (4,1) : setPromoLevel(((4<<8)|1)+1);


        (5,1) : setPromoLevel(((5<<8)|1)+1);


        (6,1) : setPromoLevel(((6<<8)|1)+1);


        (7,1) : setPromoLevel(((7<<8)|1)+1);


        (8,1) : setPromoLevel(((8<<8)|1)+1);


        (9,1) : setPromoLevel(((9<<8)|1)+1);


        (10,1) : setPromoLevel(((10<<8)|1)+1);


        (11,1) : setPromoLevel(((11<<8)|1)+1);


        (12,1) : setPromoLevel(((12<<8)|1)+1);


        (13,1) : setPromoLevel(((13<<8)|1)+1);


        (14,1) : setPromoLevel(((14<<8)|1)+1);


        (15,1) : setPromoLevel(((15<<8)|1)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 53 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,2) : setPromoLevel(((0<<8)|2)+1);


        (1,2) : setPromoLevel(((1<<8)|2)+1);


        (2,2) : setPromoLevel(((2<<8)|2)+1);


        (3,2) : setPromoLevel(((3<<8)|2)+1);


        (4,2) : setPromoLevel(((4<<8)|2)+1);


        (5,2) : setPromoLevel(((5<<8)|2)+1);


        (6,2) : setPromoLevel(((6<<8)|2)+1);


        (7,2) : setPromoLevel(((7<<8)|2)+1);


        (8,2) : setPromoLevel(((8<<8)|2)+1);


        (9,2) : setPromoLevel(((9<<8)|2)+1);


        (10,2) : setPromoLevel(((10<<8)|2)+1);


        (11,2) : setPromoLevel(((11<<8)|2)+1);


        (12,2) : setPromoLevel(((12<<8)|2)+1);


        (13,2) : setPromoLevel(((13<<8)|2)+1);


        (14,2) : setPromoLevel(((14<<8)|2)+1);


        (15,2) : setPromoLevel(((15<<8)|2)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,3) : setPromoLevel(((0<<8)|3)+1);


        (1,3) : setPromoLevel(((1<<8)|3)+1);


        (2,3) : setPromoLevel(((2<<8)|3)+1);


        (3,3) : setPromoLevel(((3<<8)|3)+1);


        (4,3) : setPromoLevel(((4<<8)|3)+1);


        (5,3) : setPromoLevel(((5<<8)|3)+1);


        (6,3) : setPromoLevel(((6<<8)|3)+1);


        (7,3) : setPromoLevel(((7<<8)|3)+1);


        (8,3) : setPromoLevel(((8<<8)|3)+1);


        (9,3) : setPromoLevel(((9<<8)|3)+1);


        (10,3) : setPromoLevel(((10<<8)|3)+1);


        (11,3) : setPromoLevel(((11<<8)|3)+1);


        (12,3) : setPromoLevel(((12<<8)|3)+1);


        (13,3) : setPromoLevel(((13<<8)|3)+1);


        (14,3) : setPromoLevel(((14<<8)|3)+1);


        (15,3) : setPromoLevel(((15<<8)|3)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 63 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,4) : setPromoLevel(((0<<8)|4)+1);


        (1,4) : setPromoLevel(((1<<8)|4)+1);


        (2,4) : setPromoLevel(((2<<8)|4)+1);


        (3,4) : setPromoLevel(((3<<8)|4)+1);


        (4,4) : setPromoLevel(((4<<8)|4)+1);


        (5,4) : setPromoLevel(((5<<8)|4)+1);


        (6,4) : setPromoLevel(((6<<8)|4)+1);


        (7,4) : setPromoLevel(((7<<8)|4)+1);


        (8,4) : setPromoLevel(((8<<8)|4)+1);


        (9,4) : setPromoLevel(((9<<8)|4)+1);


        (10,4) : setPromoLevel(((10<<8)|4)+1);


        (11,4) : setPromoLevel(((11<<8)|4)+1);


        (12,4) : setPromoLevel(((12<<8)|4)+1);


        (13,4) : setPromoLevel(((13<<8)|4)+1);


        (14,4) : setPromoLevel(((14<<8)|4)+1);


        (15,4) : setPromoLevel(((15<<8)|4)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 68 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,5) : setPromoLevel(((0<<8)|5)+1);


        (1,5) : setPromoLevel(((1<<8)|5)+1);


        (2,5) : setPromoLevel(((2<<8)|5)+1);


        (3,5) : setPromoLevel(((3<<8)|5)+1);


        (4,5) : setPromoLevel(((4<<8)|5)+1);


        (5,5) : setPromoLevel(((5<<8)|5)+1);


        (6,5) : setPromoLevel(((6<<8)|5)+1);


        (7,5) : setPromoLevel(((7<<8)|5)+1);


        (8,5) : setPromoLevel(((8<<8)|5)+1);


        (9,5) : setPromoLevel(((9<<8)|5)+1);


        (10,5) : setPromoLevel(((10<<8)|5)+1);


        (11,5) : setPromoLevel(((11<<8)|5)+1);


        (12,5) : setPromoLevel(((12<<8)|5)+1);


        (13,5) : setPromoLevel(((13<<8)|5)+1);


        (14,5) : setPromoLevel(((14<<8)|5)+1);


        (15,5) : setPromoLevel(((15<<8)|5)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 73 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,6) : setPromoLevel(((0<<8)|6)+1);


        (1,6) : setPromoLevel(((1<<8)|6)+1);


        (2,6) : setPromoLevel(((2<<8)|6)+1);


        (3,6) : setPromoLevel(((3<<8)|6)+1);


        (4,6) : setPromoLevel(((4<<8)|6)+1);


        (5,6) : setPromoLevel(((5<<8)|6)+1);


        (6,6) : setPromoLevel(((6<<8)|6)+1);


        (7,6) : setPromoLevel(((7<<8)|6)+1);


        (8,6) : setPromoLevel(((8<<8)|6)+1);


        (9,6) : setPromoLevel(((9<<8)|6)+1);


        (10,6) : setPromoLevel(((10<<8)|6)+1);


        (11,6) : setPromoLevel(((11<<8)|6)+1);


        (12,6) : setPromoLevel(((12<<8)|6)+1);


        (13,6) : setPromoLevel(((13<<8)|6)+1);


        (14,6) : setPromoLevel(((14<<8)|6)+1);


        (15,6) : setPromoLevel(((15<<8)|6)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 78 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,7) : setPromoLevel(((0<<8)|7)+1);


        (1,7) : setPromoLevel(((1<<8)|7)+1);


        (2,7) : setPromoLevel(((2<<8)|7)+1);


        (3,7) : setPromoLevel(((3<<8)|7)+1);


        (4,7) : setPromoLevel(((4<<8)|7)+1);


        (5,7) : setPromoLevel(((5<<8)|7)+1);


        (6,7) : setPromoLevel(((6<<8)|7)+1);


        (7,7) : setPromoLevel(((7<<8)|7)+1);


        (8,7) : setPromoLevel(((8<<8)|7)+1);


        (9,7) : setPromoLevel(((9<<8)|7)+1);


        (10,7) : setPromoLevel(((10<<8)|7)+1);


        (11,7) : setPromoLevel(((11<<8)|7)+1);


        (12,7) : setPromoLevel(((12<<8)|7)+1);


        (13,7) : setPromoLevel(((13<<8)|7)+1);


        (14,7) : setPromoLevel(((14<<8)|7)+1);


        (15,7) : setPromoLevel(((15<<8)|7)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 83 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,8) : setPromoLevel(((0<<8)|8)+1);


        (1,8) : setPromoLevel(((1<<8)|8)+1);


        (2,8) : setPromoLevel(((2<<8)|8)+1);


        (3,8) : setPromoLevel(((3<<8)|8)+1);


        (4,8) : setPromoLevel(((4<<8)|8)+1);


        (5,8) : setPromoLevel(((5<<8)|8)+1);


        (6,8) : setPromoLevel(((6<<8)|8)+1);


        (7,8) : setPromoLevel(((7<<8)|8)+1);


        (8,8) : setPromoLevel(((8<<8)|8)+1);


        (9,8) : setPromoLevel(((9<<8)|8)+1);


        (10,8) : setPromoLevel(((10<<8)|8)+1);


        (11,8) : setPromoLevel(((11<<8)|8)+1);


        (12,8) : setPromoLevel(((12<<8)|8)+1);


        (13,8) : setPromoLevel(((13<<8)|8)+1);


        (14,8) : setPromoLevel(((14<<8)|8)+1);


        (15,8) : setPromoLevel(((15<<8)|8)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 88 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,9) : setPromoLevel(((0<<8)|9)+1);


        (1,9) : setPromoLevel(((1<<8)|9)+1);


        (2,9) : setPromoLevel(((2<<8)|9)+1);


        (3,9) : setPromoLevel(((3<<8)|9)+1);


        (4,9) : setPromoLevel(((4<<8)|9)+1);


        (5,9) : setPromoLevel(((5<<8)|9)+1);


        (6,9) : setPromoLevel(((6<<8)|9)+1);


        (7,9) : setPromoLevel(((7<<8)|9)+1);


        (8,9) : setPromoLevel(((8<<8)|9)+1);


        (9,9) : setPromoLevel(((9<<8)|9)+1);


        (10,9) : setPromoLevel(((10<<8)|9)+1);


        (11,9) : setPromoLevel(((11<<8)|9)+1);


        (12,9) : setPromoLevel(((12<<8)|9)+1);


        (13,9) : setPromoLevel(((13<<8)|9)+1);


        (14,9) : setPromoLevel(((14<<8)|9)+1);


        (15,9) : setPromoLevel(((15<<8)|9)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 93 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,10) : setPromoLevel(((0<<8)|10)+1);


        (1,10) : setPromoLevel(((1<<8)|10)+1);


        (2,10) : setPromoLevel(((2<<8)|10)+1);


        (3,10) : setPromoLevel(((3<<8)|10)+1);


        (4,10) : setPromoLevel(((4<<8)|10)+1);


        (5,10) : setPromoLevel(((5<<8)|10)+1);


        (6,10) : setPromoLevel(((6<<8)|10)+1);


        (7,10) : setPromoLevel(((7<<8)|10)+1);


        (8,10) : setPromoLevel(((8<<8)|10)+1);


        (9,10) : setPromoLevel(((9<<8)|10)+1);


        (10,10) : setPromoLevel(((10<<8)|10)+1);


        (11,10) : setPromoLevel(((11<<8)|10)+1);


        (12,10) : setPromoLevel(((12<<8)|10)+1);


        (13,10) : setPromoLevel(((13<<8)|10)+1);


        (14,10) : setPromoLevel(((14<<8)|10)+1);


        (15,10) : setPromoLevel(((15<<8)|10)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 98 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,11) : setPromoLevel(((0<<8)|11)+1);


        (1,11) : setPromoLevel(((1<<8)|11)+1);


        (2,11) : setPromoLevel(((2<<8)|11)+1);


        (3,11) : setPromoLevel(((3<<8)|11)+1);


        (4,11) : setPromoLevel(((4<<8)|11)+1);


        (5,11) : setPromoLevel(((5<<8)|11)+1);


        (6,11) : setPromoLevel(((6<<8)|11)+1);


        (7,11) : setPromoLevel(((7<<8)|11)+1);


        (8,11) : setPromoLevel(((8<<8)|11)+1);


        (9,11) : setPromoLevel(((9<<8)|11)+1);


        (10,11) : setPromoLevel(((10<<8)|11)+1);


        (11,11) : setPromoLevel(((11<<8)|11)+1);


        (12,11) : setPromoLevel(((12<<8)|11)+1);


        (13,11) : setPromoLevel(((13<<8)|11)+1);


        (14,11) : setPromoLevel(((14<<8)|11)+1);


        (15,11) : setPromoLevel(((15<<8)|11)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 103 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,12) : setPromoLevel(((0<<8)|12)+1);


        (1,12) : setPromoLevel(((1<<8)|12)+1);


        (2,12) : setPromoLevel(((2<<8)|12)+1);


        (3,12) : setPromoLevel(((3<<8)|12)+1);


        (4,12) : setPromoLevel(((4<<8)|12)+1);


        (5,12) : setPromoLevel(((5<<8)|12)+1);


        (6,12) : setPromoLevel(((6<<8)|12)+1);


        (7,12) : setPromoLevel(((7<<8)|12)+1);


        (8,12) : setPromoLevel(((8<<8)|12)+1);


        (9,12) : setPromoLevel(((9<<8)|12)+1);


        (10,12) : setPromoLevel(((10<<8)|12)+1);


        (11,12) : setPromoLevel(((11<<8)|12)+1);


        (12,12) : setPromoLevel(((12<<8)|12)+1);


        (13,12) : setPromoLevel(((13<<8)|12)+1);


        (14,12) : setPromoLevel(((14<<8)|12)+1);


        (15,12) : setPromoLevel(((15<<8)|12)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 108 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,13) : setPromoLevel(((0<<8)|13)+1);


        (1,13) : setPromoLevel(((1<<8)|13)+1);


        (2,13) : setPromoLevel(((2<<8)|13)+1);


        (3,13) : setPromoLevel(((3<<8)|13)+1);


        (4,13) : setPromoLevel(((4<<8)|13)+1);


        (5,13) : setPromoLevel(((5<<8)|13)+1);


        (6,13) : setPromoLevel(((6<<8)|13)+1);


        (7,13) : setPromoLevel(((7<<8)|13)+1);


        (8,13) : setPromoLevel(((8<<8)|13)+1);


        (9,13) : setPromoLevel(((9<<8)|13)+1);


        (10,13) : setPromoLevel(((10<<8)|13)+1);


        (11,13) : setPromoLevel(((11<<8)|13)+1);


        (12,13) : setPromoLevel(((12<<8)|13)+1);


        (13,13) : setPromoLevel(((13<<8)|13)+1);


        (14,13) : setPromoLevel(((14<<8)|13)+1);


        (15,13) : setPromoLevel(((15<<8)|13)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 113 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,14) : setPromoLevel(((0<<8)|14)+1);


        (1,14) : setPromoLevel(((1<<8)|14)+1);


        (2,14) : setPromoLevel(((2<<8)|14)+1);


        (3,14) : setPromoLevel(((3<<8)|14)+1);


        (4,14) : setPromoLevel(((4<<8)|14)+1);


        (5,14) : setPromoLevel(((5<<8)|14)+1);


        (6,14) : setPromoLevel(((6<<8)|14)+1);


        (7,14) : setPromoLevel(((7<<8)|14)+1);


        (8,14) : setPromoLevel(((8<<8)|14)+1);


        (9,14) : setPromoLevel(((9<<8)|14)+1);


        (10,14) : setPromoLevel(((10<<8)|14)+1);


        (11,14) : setPromoLevel(((11<<8)|14)+1);


        (12,14) : setPromoLevel(((12<<8)|14)+1);


        (13,14) : setPromoLevel(((13<<8)|14)+1);


        (14,14) : setPromoLevel(((14<<8)|14)+1);


        (15,14) : setPromoLevel(((15<<8)|14)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 118 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,15) : setPromoLevel(((0<<8)|15)+1);


        (1,15) : setPromoLevel(((1<<8)|15)+1);


        (2,15) : setPromoLevel(((2<<8)|15)+1);


        (3,15) : setPromoLevel(((3<<8)|15)+1);


        (4,15) : setPromoLevel(((4<<8)|15)+1);


        (5,15) : setPromoLevel(((5<<8)|15)+1);


        (6,15) : setPromoLevel(((6<<8)|15)+1);


        (7,15) : setPromoLevel(((7<<8)|15)+1);


        (8,15) : setPromoLevel(((8<<8)|15)+1);


        (9,15) : setPromoLevel(((9<<8)|15)+1);


        (10,15) : setPromoLevel(((10<<8)|15)+1);


        (11,15) : setPromoLevel(((11<<8)|15)+1);


        (12,15) : setPromoLevel(((12<<8)|15)+1);


        (13,15) : setPromoLevel(((13<<8)|15)+1);


        (14,15) : setPromoLevel(((14<<8)|15)+1);


        (15,15) : setPromoLevel(((15<<8)|15)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 123 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,16) : setPromoLevel(((0<<8)|16)+1);


        (1,16) : setPromoLevel(((1<<8)|16)+1);


        (2,16) : setPromoLevel(((2<<8)|16)+1);


        (3,16) : setPromoLevel(((3<<8)|16)+1);


        (4,16) : setPromoLevel(((4<<8)|16)+1);


        (5,16) : setPromoLevel(((5<<8)|16)+1);


        (6,16) : setPromoLevel(((6<<8)|16)+1);


        (7,16) : setPromoLevel(((7<<8)|16)+1);


        (8,16) : setPromoLevel(((8<<8)|16)+1);


        (9,16) : setPromoLevel(((9<<8)|16)+1);


        (10,16) : setPromoLevel(((10<<8)|16)+1);


        (11,16) : setPromoLevel(((11<<8)|16)+1);


        (12,16) : setPromoLevel(((12<<8)|16)+1);


        (13,16) : setPromoLevel(((13<<8)|16)+1);


        (14,16) : setPromoLevel(((14<<8)|16)+1);


        (15,16) : setPromoLevel(((15<<8)|16)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 128 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,17) : setPromoLevel(((0<<8)|17)+1);


        (1,17) : setPromoLevel(((1<<8)|17)+1);


        (2,17) : setPromoLevel(((2<<8)|17)+1);


        (3,17) : setPromoLevel(((3<<8)|17)+1);


        (4,17) : setPromoLevel(((4<<8)|17)+1);


        (5,17) : setPromoLevel(((5<<8)|17)+1);


        (6,17) : setPromoLevel(((6<<8)|17)+1);


        (7,17) : setPromoLevel(((7<<8)|17)+1);


        (8,17) : setPromoLevel(((8<<8)|17)+1);


        (9,17) : setPromoLevel(((9<<8)|17)+1);


        (10,17) : setPromoLevel(((10<<8)|17)+1);


        (11,17) : setPromoLevel(((11<<8)|17)+1);


        (12,17) : setPromoLevel(((12<<8)|17)+1);


        (13,17) : setPromoLevel(((13<<8)|17)+1);


        (14,17) : setPromoLevel(((14<<8)|17)+1);


        (15,17) : setPromoLevel(((15<<8)|17)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 133 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,18) : setPromoLevel(((0<<8)|18)+1);


        (1,18) : setPromoLevel(((1<<8)|18)+1);


        (2,18) : setPromoLevel(((2<<8)|18)+1);


        (3,18) : setPromoLevel(((3<<8)|18)+1);


        (4,18) : setPromoLevel(((4<<8)|18)+1);


        (5,18) : setPromoLevel(((5<<8)|18)+1);


        (6,18) : setPromoLevel(((6<<8)|18)+1);


        (7,18) : setPromoLevel(((7<<8)|18)+1);


        (8,18) : setPromoLevel(((8<<8)|18)+1);


        (9,18) : setPromoLevel(((9<<8)|18)+1);


        (10,18) : setPromoLevel(((10<<8)|18)+1);


        (11,18) : setPromoLevel(((11<<8)|18)+1);


        (12,18) : setPromoLevel(((12<<8)|18)+1);


        (13,18) : setPromoLevel(((13<<8)|18)+1);


        (14,18) : setPromoLevel(((14<<8)|18)+1);


        (15,18) : setPromoLevel(((15<<8)|18)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 138 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,19) : setPromoLevel(((0<<8)|19)+1);


        (1,19) : setPromoLevel(((1<<8)|19)+1);


        (2,19) : setPromoLevel(((2<<8)|19)+1);


        (3,19) : setPromoLevel(((3<<8)|19)+1);


        (4,19) : setPromoLevel(((4<<8)|19)+1);


        (5,19) : setPromoLevel(((5<<8)|19)+1);


        (6,19) : setPromoLevel(((6<<8)|19)+1);


        (7,19) : setPromoLevel(((7<<8)|19)+1);


        (8,19) : setPromoLevel(((8<<8)|19)+1);


        (9,19) : setPromoLevel(((9<<8)|19)+1);


        (10,19) : setPromoLevel(((10<<8)|19)+1);


        (11,19) : setPromoLevel(((11<<8)|19)+1);


        (12,19) : setPromoLevel(((12<<8)|19)+1);


        (13,19) : setPromoLevel(((13<<8)|19)+1);


        (14,19) : setPromoLevel(((14<<8)|19)+1);


        (15,19) : setPromoLevel(((15<<8)|19)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 143 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,20) : setPromoLevel(((0<<8)|20)+1);


        (1,20) : setPromoLevel(((1<<8)|20)+1);


        (2,20) : setPromoLevel(((2<<8)|20)+1);


        (3,20) : setPromoLevel(((3<<8)|20)+1);


        (4,20) : setPromoLevel(((4<<8)|20)+1);


        (5,20) : setPromoLevel(((5<<8)|20)+1);


        (6,20) : setPromoLevel(((6<<8)|20)+1);


        (7,20) : setPromoLevel(((7<<8)|20)+1);


        (8,20) : setPromoLevel(((8<<8)|20)+1);


        (9,20) : setPromoLevel(((9<<8)|20)+1);


        (10,20) : setPromoLevel(((10<<8)|20)+1);


        (11,20) : setPromoLevel(((11<<8)|20)+1);


        (12,20) : setPromoLevel(((12<<8)|20)+1);


        (13,20) : setPromoLevel(((13<<8)|20)+1);


        (14,20) : setPromoLevel(((14<<8)|20)+1);


        (15,20) : setPromoLevel(((15<<8)|20)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 148 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,21) : setPromoLevel(((0<<8)|21)+1);


        (1,21) : setPromoLevel(((1<<8)|21)+1);


        (2,21) : setPromoLevel(((2<<8)|21)+1);


        (3,21) : setPromoLevel(((3<<8)|21)+1);


        (4,21) : setPromoLevel(((4<<8)|21)+1);


        (5,21) : setPromoLevel(((5<<8)|21)+1);


        (6,21) : setPromoLevel(((6<<8)|21)+1);


        (7,21) : setPromoLevel(((7<<8)|21)+1);


        (8,21) : setPromoLevel(((8<<8)|21)+1);


        (9,21) : setPromoLevel(((9<<8)|21)+1);


        (10,21) : setPromoLevel(((10<<8)|21)+1);


        (11,21) : setPromoLevel(((11<<8)|21)+1);


        (12,21) : setPromoLevel(((12<<8)|21)+1);


        (13,21) : setPromoLevel(((13<<8)|21)+1);


        (14,21) : setPromoLevel(((14<<8)|21)+1);


        (15,21) : setPromoLevel(((15<<8)|21)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 153 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,22) : setPromoLevel(((0<<8)|22)+1);


        (1,22) : setPromoLevel(((1<<8)|22)+1);


        (2,22) : setPromoLevel(((2<<8)|22)+1);


        (3,22) : setPromoLevel(((3<<8)|22)+1);


        (4,22) : setPromoLevel(((4<<8)|22)+1);


        (5,22) : setPromoLevel(((5<<8)|22)+1);


        (6,22) : setPromoLevel(((6<<8)|22)+1);


        (7,22) : setPromoLevel(((7<<8)|22)+1);


        (8,22) : setPromoLevel(((8<<8)|22)+1);


        (9,22) : setPromoLevel(((9<<8)|22)+1);


        (10,22) : setPromoLevel(((10<<8)|22)+1);


        (11,22) : setPromoLevel(((11<<8)|22)+1);


        (12,22) : setPromoLevel(((12<<8)|22)+1);


        (13,22) : setPromoLevel(((13<<8)|22)+1);


        (14,22) : setPromoLevel(((14<<8)|22)+1);


        (15,22) : setPromoLevel(((15<<8)|22)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 158 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,23) : setPromoLevel(((0<<8)|23)+1);


        (1,23) : setPromoLevel(((1<<8)|23)+1);


        (2,23) : setPromoLevel(((2<<8)|23)+1);


        (3,23) : setPromoLevel(((3<<8)|23)+1);


        (4,23) : setPromoLevel(((4<<8)|23)+1);


        (5,23) : setPromoLevel(((5<<8)|23)+1);


        (6,23) : setPromoLevel(((6<<8)|23)+1);


        (7,23) : setPromoLevel(((7<<8)|23)+1);


        (8,23) : setPromoLevel(((8<<8)|23)+1);


        (9,23) : setPromoLevel(((9<<8)|23)+1);


        (10,23) : setPromoLevel(((10<<8)|23)+1);


        (11,23) : setPromoLevel(((11<<8)|23)+1);


        (12,23) : setPromoLevel(((12<<8)|23)+1);


        (13,23) : setPromoLevel(((13<<8)|23)+1);


        (14,23) : setPromoLevel(((14<<8)|23)+1);


        (15,23) : setPromoLevel(((15<<8)|23)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 163 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,24) : setPromoLevel(((0<<8)|24)+1);


        (1,24) : setPromoLevel(((1<<8)|24)+1);


        (2,24) : setPromoLevel(((2<<8)|24)+1);


        (3,24) : setPromoLevel(((3<<8)|24)+1);


        (4,24) : setPromoLevel(((4<<8)|24)+1);


        (5,24) : setPromoLevel(((5<<8)|24)+1);


        (6,24) : setPromoLevel(((6<<8)|24)+1);


        (7,24) : setPromoLevel(((7<<8)|24)+1);


        (8,24) : setPromoLevel(((8<<8)|24)+1);


        (9,24) : setPromoLevel(((9<<8)|24)+1);


        (10,24) : setPromoLevel(((10<<8)|24)+1);


        (11,24) : setPromoLevel(((11<<8)|24)+1);


        (12,24) : setPromoLevel(((12<<8)|24)+1);


        (13,24) : setPromoLevel(((13<<8)|24)+1);


        (14,24) : setPromoLevel(((14<<8)|24)+1);


        (15,24) : setPromoLevel(((15<<8)|24)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 168 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,25) : setPromoLevel(((0<<8)|25)+1);


        (1,25) : setPromoLevel(((1<<8)|25)+1);


        (2,25) : setPromoLevel(((2<<8)|25)+1);


        (3,25) : setPromoLevel(((3<<8)|25)+1);


        (4,25) : setPromoLevel(((4<<8)|25)+1);


        (5,25) : setPromoLevel(((5<<8)|25)+1);


        (6,25) : setPromoLevel(((6<<8)|25)+1);


        (7,25) : setPromoLevel(((7<<8)|25)+1);


        (8,25) : setPromoLevel(((8<<8)|25)+1);


        (9,25) : setPromoLevel(((9<<8)|25)+1);


        (10,25) : setPromoLevel(((10<<8)|25)+1);


        (11,25) : setPromoLevel(((11<<8)|25)+1);


        (12,25) : setPromoLevel(((12<<8)|25)+1);


        (13,25) : setPromoLevel(((13<<8)|25)+1);


        (14,25) : setPromoLevel(((14<<8)|25)+1);


        (15,25) : setPromoLevel(((15<<8)|25)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 173 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,26) : setPromoLevel(((0<<8)|26)+1);


        (1,26) : setPromoLevel(((1<<8)|26)+1);


        (2,26) : setPromoLevel(((2<<8)|26)+1);


        (3,26) : setPromoLevel(((3<<8)|26)+1);


        (4,26) : setPromoLevel(((4<<8)|26)+1);


        (5,26) : setPromoLevel(((5<<8)|26)+1);


        (6,26) : setPromoLevel(((6<<8)|26)+1);


        (7,26) : setPromoLevel(((7<<8)|26)+1);


        (8,26) : setPromoLevel(((8<<8)|26)+1);


        (9,26) : setPromoLevel(((9<<8)|26)+1);


        (10,26) : setPromoLevel(((10<<8)|26)+1);


        (11,26) : setPromoLevel(((11<<8)|26)+1);


        (12,26) : setPromoLevel(((12<<8)|26)+1);


        (13,26) : setPromoLevel(((13<<8)|26)+1);


        (14,26) : setPromoLevel(((14<<8)|26)+1);


        (15,26) : setPromoLevel(((15<<8)|26)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 178 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,27) : setPromoLevel(((0<<8)|27)+1);


        (1,27) : setPromoLevel(((1<<8)|27)+1);


        (2,27) : setPromoLevel(((2<<8)|27)+1);


        (3,27) : setPromoLevel(((3<<8)|27)+1);


        (4,27) : setPromoLevel(((4<<8)|27)+1);


        (5,27) : setPromoLevel(((5<<8)|27)+1);


        (6,27) : setPromoLevel(((6<<8)|27)+1);


        (7,27) : setPromoLevel(((7<<8)|27)+1);


        (8,27) : setPromoLevel(((8<<8)|27)+1);


        (9,27) : setPromoLevel(((9<<8)|27)+1);


        (10,27) : setPromoLevel(((10<<8)|27)+1);


        (11,27) : setPromoLevel(((11<<8)|27)+1);


        (12,27) : setPromoLevel(((12<<8)|27)+1);


        (13,27) : setPromoLevel(((13<<8)|27)+1);


        (14,27) : setPromoLevel(((14<<8)|27)+1);


        (15,27) : setPromoLevel(((15<<8)|27)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 183 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,28) : setPromoLevel(((0<<8)|28)+1);


        (1,28) : setPromoLevel(((1<<8)|28)+1);


        (2,28) : setPromoLevel(((2<<8)|28)+1);


        (3,28) : setPromoLevel(((3<<8)|28)+1);


        (4,28) : setPromoLevel(((4<<8)|28)+1);


        (5,28) : setPromoLevel(((5<<8)|28)+1);


        (6,28) : setPromoLevel(((6<<8)|28)+1);


        (7,28) : setPromoLevel(((7<<8)|28)+1);


        (8,28) : setPromoLevel(((8<<8)|28)+1);


        (9,28) : setPromoLevel(((9<<8)|28)+1);


        (10,28) : setPromoLevel(((10<<8)|28)+1);


        (11,28) : setPromoLevel(((11<<8)|28)+1);


        (12,28) : setPromoLevel(((12<<8)|28)+1);


        (13,28) : setPromoLevel(((13<<8)|28)+1);


        (14,28) : setPromoLevel(((14<<8)|28)+1);


        (15,28) : setPromoLevel(((15<<8)|28)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 188 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,29) : setPromoLevel(((0<<8)|29)+1);


        (1,29) : setPromoLevel(((1<<8)|29)+1);


        (2,29) : setPromoLevel(((2<<8)|29)+1);


        (3,29) : setPromoLevel(((3<<8)|29)+1);


        (4,29) : setPromoLevel(((4<<8)|29)+1);


        (5,29) : setPromoLevel(((5<<8)|29)+1);


        (6,29) : setPromoLevel(((6<<8)|29)+1);


        (7,29) : setPromoLevel(((7<<8)|29)+1);


        (8,29) : setPromoLevel(((8<<8)|29)+1);


        (9,29) : setPromoLevel(((9<<8)|29)+1);


        (10,29) : setPromoLevel(((10<<8)|29)+1);


        (11,29) : setPromoLevel(((11<<8)|29)+1);


        (12,29) : setPromoLevel(((12<<8)|29)+1);


        (13,29) : setPromoLevel(((13<<8)|29)+1);


        (14,29) : setPromoLevel(((14<<8)|29)+1);


        (15,29) : setPromoLevel(((15<<8)|29)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 193 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,30) : setPromoLevel(((0<<8)|30)+1);


        (1,30) : setPromoLevel(((1<<8)|30)+1);


        (2,30) : setPromoLevel(((2<<8)|30)+1);


        (3,30) : setPromoLevel(((3<<8)|30)+1);


        (4,30) : setPromoLevel(((4<<8)|30)+1);


        (5,30) : setPromoLevel(((5<<8)|30)+1);


        (6,30) : setPromoLevel(((6<<8)|30)+1);


        (7,30) : setPromoLevel(((7<<8)|30)+1);


        (8,30) : setPromoLevel(((8<<8)|30)+1);


        (9,30) : setPromoLevel(((9<<8)|30)+1);


        (10,30) : setPromoLevel(((10<<8)|30)+1);


        (11,30) : setPromoLevel(((11<<8)|30)+1);


        (12,30) : setPromoLevel(((12<<8)|30)+1);


        (13,30) : setPromoLevel(((13<<8)|30)+1);


        (14,30) : setPromoLevel(((14<<8)|30)+1);


        (15,30) : setPromoLevel(((15<<8)|30)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 198 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,31) : setPromoLevel(((0<<8)|31)+1);


        (1,31) : setPromoLevel(((1<<8)|31)+1);


        (2,31) : setPromoLevel(((2<<8)|31)+1);


        (3,31) : setPromoLevel(((3<<8)|31)+1);


        (4,31) : setPromoLevel(((4<<8)|31)+1);


        (5,31) : setPromoLevel(((5<<8)|31)+1);


        (6,31) : setPromoLevel(((6<<8)|31)+1);


        (7,31) : setPromoLevel(((7<<8)|31)+1);


        (8,31) : setPromoLevel(((8<<8)|31)+1);


        (9,31) : setPromoLevel(((9<<8)|31)+1);


        (10,31) : setPromoLevel(((10<<8)|31)+1);


        (11,31) : setPromoLevel(((11<<8)|31)+1);


        (12,31) : setPromoLevel(((12<<8)|31)+1);


        (13,31) : setPromoLevel(((13<<8)|31)+1);


        (14,31) : setPromoLevel(((14<<8)|31)+1);


        (15,31) : setPromoLevel(((15<<8)|31)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 203 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,32) : setPromoLevel(((0<<8)|32)+1);


        (1,32) : setPromoLevel(((1<<8)|32)+1);


        (2,32) : setPromoLevel(((2<<8)|32)+1);


        (3,32) : setPromoLevel(((3<<8)|32)+1);


        (4,32) : setPromoLevel(((4<<8)|32)+1);


        (5,32) : setPromoLevel(((5<<8)|32)+1);


        (6,32) : setPromoLevel(((6<<8)|32)+1);


        (7,32) : setPromoLevel(((7<<8)|32)+1);


        (8,32) : setPromoLevel(((8<<8)|32)+1);


        (9,32) : setPromoLevel(((9<<8)|32)+1);


        (10,32) : setPromoLevel(((10<<8)|32)+1);


        (11,32) : setPromoLevel(((11<<8)|32)+1);


        (12,32) : setPromoLevel(((12<<8)|32)+1);


        (13,32) : setPromoLevel(((13<<8)|32)+1);


        (14,32) : setPromoLevel(((14<<8)|32)+1);


        (15,32) : setPromoLevel(((15<<8)|32)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 208 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2





# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,33) : setPromoLevel(((0<<8)|33)+1);


        (1,33) : setPromoLevel(((1<<8)|33)+1);


        (2,33) : setPromoLevel(((2<<8)|33)+1);


        (3,33) : setPromoLevel(((3<<8)|33)+1);


        (4,33) : setPromoLevel(((4<<8)|33)+1);


        (5,33) : setPromoLevel(((5<<8)|33)+1);


        (6,33) : setPromoLevel(((6<<8)|33)+1);


        (7,33) : setPromoLevel(((7<<8)|33)+1);


        (8,33) : setPromoLevel(((8<<8)|33)+1);


        (9,33) : setPromoLevel(((9<<8)|33)+1);


        (10,33) : setPromoLevel(((10<<8)|33)+1);


        (11,33) : setPromoLevel(((11<<8)|33)+1);


        (12,33) : setPromoLevel(((12<<8)|33)+1);


        (13,33) : setPromoLevel(((13<<8)|33)+1);


        (14,33) : setPromoLevel(((14<<8)|33)+1);


        (15,33) : setPromoLevel(((15<<8)|33)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 213 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,34) : setPromoLevel(((0<<8)|34)+1);


        (1,34) : setPromoLevel(((1<<8)|34)+1);


        (2,34) : setPromoLevel(((2<<8)|34)+1);


        (3,34) : setPromoLevel(((3<<8)|34)+1);


        (4,34) : setPromoLevel(((4<<8)|34)+1);


        (5,34) : setPromoLevel(((5<<8)|34)+1);


        (6,34) : setPromoLevel(((6<<8)|34)+1);


        (7,34) : setPromoLevel(((7<<8)|34)+1);


        (8,34) : setPromoLevel(((8<<8)|34)+1);


        (9,34) : setPromoLevel(((9<<8)|34)+1);


        (10,34) : setPromoLevel(((10<<8)|34)+1);


        (11,34) : setPromoLevel(((11<<8)|34)+1);


        (12,34) : setPromoLevel(((12<<8)|34)+1);


        (13,34) : setPromoLevel(((13<<8)|34)+1);


        (14,34) : setPromoLevel(((14<<8)|34)+1);


        (15,34) : setPromoLevel(((15<<8)|34)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 218 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,35) : setPromoLevel(((0<<8)|35)+1);


        (1,35) : setPromoLevel(((1<<8)|35)+1);


        (2,35) : setPromoLevel(((2<<8)|35)+1);


        (3,35) : setPromoLevel(((3<<8)|35)+1);


        (4,35) : setPromoLevel(((4<<8)|35)+1);


        (5,35) : setPromoLevel(((5<<8)|35)+1);


        (6,35) : setPromoLevel(((6<<8)|35)+1);


        (7,35) : setPromoLevel(((7<<8)|35)+1);


        (8,35) : setPromoLevel(((8<<8)|35)+1);


        (9,35) : setPromoLevel(((9<<8)|35)+1);


        (10,35) : setPromoLevel(((10<<8)|35)+1);


        (11,35) : setPromoLevel(((11<<8)|35)+1);


        (12,35) : setPromoLevel(((12<<8)|35)+1);


        (13,35) : setPromoLevel(((13<<8)|35)+1);


        (14,35) : setPromoLevel(((14<<8)|35)+1);


        (15,35) : setPromoLevel(((15<<8)|35)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 223 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,36) : setPromoLevel(((0<<8)|36)+1);


        (1,36) : setPromoLevel(((1<<8)|36)+1);


        (2,36) : setPromoLevel(((2<<8)|36)+1);


        (3,36) : setPromoLevel(((3<<8)|36)+1);


        (4,36) : setPromoLevel(((4<<8)|36)+1);


        (5,36) : setPromoLevel(((5<<8)|36)+1);


        (6,36) : setPromoLevel(((6<<8)|36)+1);


        (7,36) : setPromoLevel(((7<<8)|36)+1);


        (8,36) : setPromoLevel(((8<<8)|36)+1);


        (9,36) : setPromoLevel(((9<<8)|36)+1);


        (10,36) : setPromoLevel(((10<<8)|36)+1);


        (11,36) : setPromoLevel(((11<<8)|36)+1);


        (12,36) : setPromoLevel(((12<<8)|36)+1);


        (13,36) : setPromoLevel(((13<<8)|36)+1);


        (14,36) : setPromoLevel(((14<<8)|36)+1);


        (15,36) : setPromoLevel(((15<<8)|36)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 228 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,37) : setPromoLevel(((0<<8)|37)+1);


        (1,37) : setPromoLevel(((1<<8)|37)+1);


        (2,37) : setPromoLevel(((2<<8)|37)+1);


        (3,37) : setPromoLevel(((3<<8)|37)+1);


        (4,37) : setPromoLevel(((4<<8)|37)+1);


        (5,37) : setPromoLevel(((5<<8)|37)+1);


        (6,37) : setPromoLevel(((6<<8)|37)+1);


        (7,37) : setPromoLevel(((7<<8)|37)+1);


        (8,37) : setPromoLevel(((8<<8)|37)+1);


        (9,37) : setPromoLevel(((9<<8)|37)+1);


        (10,37) : setPromoLevel(((10<<8)|37)+1);


        (11,37) : setPromoLevel(((11<<8)|37)+1);


        (12,37) : setPromoLevel(((12<<8)|37)+1);


        (13,37) : setPromoLevel(((13<<8)|37)+1);


        (14,37) : setPromoLevel(((14<<8)|37)+1);


        (15,37) : setPromoLevel(((15<<8)|37)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 233 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,38) : setPromoLevel(((0<<8)|38)+1);


        (1,38) : setPromoLevel(((1<<8)|38)+1);


        (2,38) : setPromoLevel(((2<<8)|38)+1);


        (3,38) : setPromoLevel(((3<<8)|38)+1);


        (4,38) : setPromoLevel(((4<<8)|38)+1);


        (5,38) : setPromoLevel(((5<<8)|38)+1);


        (6,38) : setPromoLevel(((6<<8)|38)+1);


        (7,38) : setPromoLevel(((7<<8)|38)+1);


        (8,38) : setPromoLevel(((8<<8)|38)+1);


        (9,38) : setPromoLevel(((9<<8)|38)+1);


        (10,38) : setPromoLevel(((10<<8)|38)+1);


        (11,38) : setPromoLevel(((11<<8)|38)+1);


        (12,38) : setPromoLevel(((12<<8)|38)+1);


        (13,38) : setPromoLevel(((13<<8)|38)+1);


        (14,38) : setPromoLevel(((14<<8)|38)+1);


        (15,38) : setPromoLevel(((15<<8)|38)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 238 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,39) : setPromoLevel(((0<<8)|39)+1);


        (1,39) : setPromoLevel(((1<<8)|39)+1);


        (2,39) : setPromoLevel(((2<<8)|39)+1);


        (3,39) : setPromoLevel(((3<<8)|39)+1);


        (4,39) : setPromoLevel(((4<<8)|39)+1);


        (5,39) : setPromoLevel(((5<<8)|39)+1);


        (6,39) : setPromoLevel(((6<<8)|39)+1);


        (7,39) : setPromoLevel(((7<<8)|39)+1);


        (8,39) : setPromoLevel(((8<<8)|39)+1);


        (9,39) : setPromoLevel(((9<<8)|39)+1);


        (10,39) : setPromoLevel(((10<<8)|39)+1);


        (11,39) : setPromoLevel(((11<<8)|39)+1);


        (12,39) : setPromoLevel(((12<<8)|39)+1);


        (13,39) : setPromoLevel(((13<<8)|39)+1);


        (14,39) : setPromoLevel(((14<<8)|39)+1);


        (15,39) : setPromoLevel(((15<<8)|39)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 243 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,40) : setPromoLevel(((0<<8)|40)+1);


        (1,40) : setPromoLevel(((1<<8)|40)+1);


        (2,40) : setPromoLevel(((2<<8)|40)+1);


        (3,40) : setPromoLevel(((3<<8)|40)+1);


        (4,40) : setPromoLevel(((4<<8)|40)+1);


        (5,40) : setPromoLevel(((5<<8)|40)+1);


        (6,40) : setPromoLevel(((6<<8)|40)+1);


        (7,40) : setPromoLevel(((7<<8)|40)+1);


        (8,40) : setPromoLevel(((8<<8)|40)+1);


        (9,40) : setPromoLevel(((9<<8)|40)+1);


        (10,40) : setPromoLevel(((10<<8)|40)+1);


        (11,40) : setPromoLevel(((11<<8)|40)+1);


        (12,40) : setPromoLevel(((12<<8)|40)+1);


        (13,40) : setPromoLevel(((13<<8)|40)+1);


        (14,40) : setPromoLevel(((14<<8)|40)+1);


        (15,40) : setPromoLevel(((15<<8)|40)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 248 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,41) : setPromoLevel(((0<<8)|41)+1);


        (1,41) : setPromoLevel(((1<<8)|41)+1);


        (2,41) : setPromoLevel(((2<<8)|41)+1);


        (3,41) : setPromoLevel(((3<<8)|41)+1);


        (4,41) : setPromoLevel(((4<<8)|41)+1);


        (5,41) : setPromoLevel(((5<<8)|41)+1);


        (6,41) : setPromoLevel(((6<<8)|41)+1);


        (7,41) : setPromoLevel(((7<<8)|41)+1);


        (8,41) : setPromoLevel(((8<<8)|41)+1);


        (9,41) : setPromoLevel(((9<<8)|41)+1);


        (10,41) : setPromoLevel(((10<<8)|41)+1);


        (11,41) : setPromoLevel(((11<<8)|41)+1);


        (12,41) : setPromoLevel(((12<<8)|41)+1);


        (13,41) : setPromoLevel(((13<<8)|41)+1);


        (14,41) : setPromoLevel(((14<<8)|41)+1);


        (15,41) : setPromoLevel(((15<<8)|41)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 253 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,42) : setPromoLevel(((0<<8)|42)+1);


        (1,42) : setPromoLevel(((1<<8)|42)+1);


        (2,42) : setPromoLevel(((2<<8)|42)+1);


        (3,42) : setPromoLevel(((3<<8)|42)+1);


        (4,42) : setPromoLevel(((4<<8)|42)+1);


        (5,42) : setPromoLevel(((5<<8)|42)+1);


        (6,42) : setPromoLevel(((6<<8)|42)+1);


        (7,42) : setPromoLevel(((7<<8)|42)+1);


        (8,42) : setPromoLevel(((8<<8)|42)+1);


        (9,42) : setPromoLevel(((9<<8)|42)+1);


        (10,42) : setPromoLevel(((10<<8)|42)+1);


        (11,42) : setPromoLevel(((11<<8)|42)+1);


        (12,42) : setPromoLevel(((12<<8)|42)+1);


        (13,42) : setPromoLevel(((13<<8)|42)+1);


        (14,42) : setPromoLevel(((14<<8)|42)+1);


        (15,42) : setPromoLevel(((15<<8)|42)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 258 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,43) : setPromoLevel(((0<<8)|43)+1);


        (1,43) : setPromoLevel(((1<<8)|43)+1);


        (2,43) : setPromoLevel(((2<<8)|43)+1);


        (3,43) : setPromoLevel(((3<<8)|43)+1);


        (4,43) : setPromoLevel(((4<<8)|43)+1);


        (5,43) : setPromoLevel(((5<<8)|43)+1);


        (6,43) : setPromoLevel(((6<<8)|43)+1);


        (7,43) : setPromoLevel(((7<<8)|43)+1);


        (8,43) : setPromoLevel(((8<<8)|43)+1);


        (9,43) : setPromoLevel(((9<<8)|43)+1);


        (10,43) : setPromoLevel(((10<<8)|43)+1);


        (11,43) : setPromoLevel(((11<<8)|43)+1);


        (12,43) : setPromoLevel(((12<<8)|43)+1);


        (13,43) : setPromoLevel(((13<<8)|43)+1);


        (14,43) : setPromoLevel(((14<<8)|43)+1);


        (15,43) : setPromoLevel(((15<<8)|43)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 263 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,44) : setPromoLevel(((0<<8)|44)+1);


        (1,44) : setPromoLevel(((1<<8)|44)+1);


        (2,44) : setPromoLevel(((2<<8)|44)+1);


        (3,44) : setPromoLevel(((3<<8)|44)+1);


        (4,44) : setPromoLevel(((4<<8)|44)+1);


        (5,44) : setPromoLevel(((5<<8)|44)+1);


        (6,44) : setPromoLevel(((6<<8)|44)+1);


        (7,44) : setPromoLevel(((7<<8)|44)+1);


        (8,44) : setPromoLevel(((8<<8)|44)+1);


        (9,44) : setPromoLevel(((9<<8)|44)+1);


        (10,44) : setPromoLevel(((10<<8)|44)+1);


        (11,44) : setPromoLevel(((11<<8)|44)+1);


        (12,44) : setPromoLevel(((12<<8)|44)+1);


        (13,44) : setPromoLevel(((13<<8)|44)+1);


        (14,44) : setPromoLevel(((14<<8)|44)+1);


        (15,44) : setPromoLevel(((15<<8)|44)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 268 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,45) : setPromoLevel(((0<<8)|45)+1);


        (1,45) : setPromoLevel(((1<<8)|45)+1);


        (2,45) : setPromoLevel(((2<<8)|45)+1);


        (3,45) : setPromoLevel(((3<<8)|45)+1);


        (4,45) : setPromoLevel(((4<<8)|45)+1);


        (5,45) : setPromoLevel(((5<<8)|45)+1);


        (6,45) : setPromoLevel(((6<<8)|45)+1);


        (7,45) : setPromoLevel(((7<<8)|45)+1);


        (8,45) : setPromoLevel(((8<<8)|45)+1);


        (9,45) : setPromoLevel(((9<<8)|45)+1);


        (10,45) : setPromoLevel(((10<<8)|45)+1);


        (11,45) : setPromoLevel(((11<<8)|45)+1);


        (12,45) : setPromoLevel(((12<<8)|45)+1);


        (13,45) : setPromoLevel(((13<<8)|45)+1);


        (14,45) : setPromoLevel(((14<<8)|45)+1);


        (15,45) : setPromoLevel(((15<<8)|45)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 273 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,46) : setPromoLevel(((0<<8)|46)+1);


        (1,46) : setPromoLevel(((1<<8)|46)+1);


        (2,46) : setPromoLevel(((2<<8)|46)+1);


        (3,46) : setPromoLevel(((3<<8)|46)+1);


        (4,46) : setPromoLevel(((4<<8)|46)+1);


        (5,46) : setPromoLevel(((5<<8)|46)+1);


        (6,46) : setPromoLevel(((6<<8)|46)+1);


        (7,46) : setPromoLevel(((7<<8)|46)+1);


        (8,46) : setPromoLevel(((8<<8)|46)+1);


        (9,46) : setPromoLevel(((9<<8)|46)+1);


        (10,46) : setPromoLevel(((10<<8)|46)+1);


        (11,46) : setPromoLevel(((11<<8)|46)+1);


        (12,46) : setPromoLevel(((12<<8)|46)+1);


        (13,46) : setPromoLevel(((13<<8)|46)+1);


        (14,46) : setPromoLevel(((14<<8)|46)+1);


        (15,46) : setPromoLevel(((15<<8)|46)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 278 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,47) : setPromoLevel(((0<<8)|47)+1);


        (1,47) : setPromoLevel(((1<<8)|47)+1);


        (2,47) : setPromoLevel(((2<<8)|47)+1);


        (3,47) : setPromoLevel(((3<<8)|47)+1);


        (4,47) : setPromoLevel(((4<<8)|47)+1);


        (5,47) : setPromoLevel(((5<<8)|47)+1);


        (6,47) : setPromoLevel(((6<<8)|47)+1);


        (7,47) : setPromoLevel(((7<<8)|47)+1);


        (8,47) : setPromoLevel(((8<<8)|47)+1);


        (9,47) : setPromoLevel(((9<<8)|47)+1);


        (10,47) : setPromoLevel(((10<<8)|47)+1);


        (11,47) : setPromoLevel(((11<<8)|47)+1);


        (12,47) : setPromoLevel(((12<<8)|47)+1);


        (13,47) : setPromoLevel(((13<<8)|47)+1);


        (14,47) : setPromoLevel(((14<<8)|47)+1);


        (15,47) : setPromoLevel(((15<<8)|47)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 283 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,48) : setPromoLevel(((0<<8)|48)+1);


        (1,48) : setPromoLevel(((1<<8)|48)+1);


        (2,48) : setPromoLevel(((2<<8)|48)+1);


        (3,48) : setPromoLevel(((3<<8)|48)+1);


        (4,48) : setPromoLevel(((4<<8)|48)+1);


        (5,48) : setPromoLevel(((5<<8)|48)+1);


        (6,48) : setPromoLevel(((6<<8)|48)+1);


        (7,48) : setPromoLevel(((7<<8)|48)+1);


        (8,48) : setPromoLevel(((8<<8)|48)+1);


        (9,48) : setPromoLevel(((9<<8)|48)+1);


        (10,48) : setPromoLevel(((10<<8)|48)+1);


        (11,48) : setPromoLevel(((11<<8)|48)+1);


        (12,48) : setPromoLevel(((12<<8)|48)+1);


        (13,48) : setPromoLevel(((13<<8)|48)+1);


        (14,48) : setPromoLevel(((14<<8)|48)+1);


        (15,48) : setPromoLevel(((15<<8)|48)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 288 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,49) : setPromoLevel(((0<<8)|49)+1);


        (1,49) : setPromoLevel(((1<<8)|49)+1);


        (2,49) : setPromoLevel(((2<<8)|49)+1);


        (3,49) : setPromoLevel(((3<<8)|49)+1);


        (4,49) : setPromoLevel(((4<<8)|49)+1);


        (5,49) : setPromoLevel(((5<<8)|49)+1);


        (6,49) : setPromoLevel(((6<<8)|49)+1);


        (7,49) : setPromoLevel(((7<<8)|49)+1);


        (8,49) : setPromoLevel(((8<<8)|49)+1);


        (9,49) : setPromoLevel(((9<<8)|49)+1);


        (10,49) : setPromoLevel(((10<<8)|49)+1);


        (11,49) : setPromoLevel(((11<<8)|49)+1);


        (12,49) : setPromoLevel(((12<<8)|49)+1);


        (13,49) : setPromoLevel(((13<<8)|49)+1);


        (14,49) : setPromoLevel(((14<<8)|49)+1);


        (15,49) : setPromoLevel(((15<<8)|49)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 293 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,50) : setPromoLevel(((0<<8)|50)+1);


        (1,50) : setPromoLevel(((1<<8)|50)+1);


        (2,50) : setPromoLevel(((2<<8)|50)+1);


        (3,50) : setPromoLevel(((3<<8)|50)+1);


        (4,50) : setPromoLevel(((4<<8)|50)+1);


        (5,50) : setPromoLevel(((5<<8)|50)+1);


        (6,50) : setPromoLevel(((6<<8)|50)+1);


        (7,50) : setPromoLevel(((7<<8)|50)+1);


        (8,50) : setPromoLevel(((8<<8)|50)+1);


        (9,50) : setPromoLevel(((9<<8)|50)+1);


        (10,50) : setPromoLevel(((10<<8)|50)+1);


        (11,50) : setPromoLevel(((11<<8)|50)+1);


        (12,50) : setPromoLevel(((12<<8)|50)+1);


        (13,50) : setPromoLevel(((13<<8)|50)+1);


        (14,50) : setPromoLevel(((14<<8)|50)+1);


        (15,50) : setPromoLevel(((15<<8)|50)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 298 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,51) : setPromoLevel(((0<<8)|51)+1);


        (1,51) : setPromoLevel(((1<<8)|51)+1);


        (2,51) : setPromoLevel(((2<<8)|51)+1);


        (3,51) : setPromoLevel(((3<<8)|51)+1);


        (4,51) : setPromoLevel(((4<<8)|51)+1);


        (5,51) : setPromoLevel(((5<<8)|51)+1);


        (6,51) : setPromoLevel(((6<<8)|51)+1);


        (7,51) : setPromoLevel(((7<<8)|51)+1);


        (8,51) : setPromoLevel(((8<<8)|51)+1);


        (9,51) : setPromoLevel(((9<<8)|51)+1);


        (10,51) : setPromoLevel(((10<<8)|51)+1);


        (11,51) : setPromoLevel(((11<<8)|51)+1);


        (12,51) : setPromoLevel(((12<<8)|51)+1);


        (13,51) : setPromoLevel(((13<<8)|51)+1);


        (14,51) : setPromoLevel(((14<<8)|51)+1);


        (15,51) : setPromoLevel(((15<<8)|51)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 303 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,52) : setPromoLevel(((0<<8)|52)+1);


        (1,52) : setPromoLevel(((1<<8)|52)+1);


        (2,52) : setPromoLevel(((2<<8)|52)+1);


        (3,52) : setPromoLevel(((3<<8)|52)+1);


        (4,52) : setPromoLevel(((4<<8)|52)+1);


        (5,52) : setPromoLevel(((5<<8)|52)+1);


        (6,52) : setPromoLevel(((6<<8)|52)+1);


        (7,52) : setPromoLevel(((7<<8)|52)+1);


        (8,52) : setPromoLevel(((8<<8)|52)+1);


        (9,52) : setPromoLevel(((9<<8)|52)+1);


        (10,52) : setPromoLevel(((10<<8)|52)+1);


        (11,52) : setPromoLevel(((11<<8)|52)+1);


        (12,52) : setPromoLevel(((12<<8)|52)+1);


        (13,52) : setPromoLevel(((13<<8)|52)+1);


        (14,52) : setPromoLevel(((14<<8)|52)+1);


        (15,52) : setPromoLevel(((15<<8)|52)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 308 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,53) : setPromoLevel(((0<<8)|53)+1);


        (1,53) : setPromoLevel(((1<<8)|53)+1);


        (2,53) : setPromoLevel(((2<<8)|53)+1);


        (3,53) : setPromoLevel(((3<<8)|53)+1);


        (4,53) : setPromoLevel(((4<<8)|53)+1);


        (5,53) : setPromoLevel(((5<<8)|53)+1);


        (6,53) : setPromoLevel(((6<<8)|53)+1);


        (7,53) : setPromoLevel(((7<<8)|53)+1);


        (8,53) : setPromoLevel(((8<<8)|53)+1);


        (9,53) : setPromoLevel(((9<<8)|53)+1);


        (10,53) : setPromoLevel(((10<<8)|53)+1);


        (11,53) : setPromoLevel(((11<<8)|53)+1);


        (12,53) : setPromoLevel(((12<<8)|53)+1);


        (13,53) : setPromoLevel(((13<<8)|53)+1);


        (14,53) : setPromoLevel(((14<<8)|53)+1);


        (15,53) : setPromoLevel(((15<<8)|53)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 313 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,54) : setPromoLevel(((0<<8)|54)+1);


        (1,54) : setPromoLevel(((1<<8)|54)+1);


        (2,54) : setPromoLevel(((2<<8)|54)+1);


        (3,54) : setPromoLevel(((3<<8)|54)+1);


        (4,54) : setPromoLevel(((4<<8)|54)+1);


        (5,54) : setPromoLevel(((5<<8)|54)+1);


        (6,54) : setPromoLevel(((6<<8)|54)+1);


        (7,54) : setPromoLevel(((7<<8)|54)+1);


        (8,54) : setPromoLevel(((8<<8)|54)+1);


        (9,54) : setPromoLevel(((9<<8)|54)+1);


        (10,54) : setPromoLevel(((10<<8)|54)+1);


        (11,54) : setPromoLevel(((11<<8)|54)+1);


        (12,54) : setPromoLevel(((12<<8)|54)+1);


        (13,54) : setPromoLevel(((13<<8)|54)+1);


        (14,54) : setPromoLevel(((14<<8)|54)+1);


        (15,54) : setPromoLevel(((15<<8)|54)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 318 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,55) : setPromoLevel(((0<<8)|55)+1);


        (1,55) : setPromoLevel(((1<<8)|55)+1);


        (2,55) : setPromoLevel(((2<<8)|55)+1);


        (3,55) : setPromoLevel(((3<<8)|55)+1);


        (4,55) : setPromoLevel(((4<<8)|55)+1);


        (5,55) : setPromoLevel(((5<<8)|55)+1);


        (6,55) : setPromoLevel(((6<<8)|55)+1);


        (7,55) : setPromoLevel(((7<<8)|55)+1);


        (8,55) : setPromoLevel(((8<<8)|55)+1);


        (9,55) : setPromoLevel(((9<<8)|55)+1);


        (10,55) : setPromoLevel(((10<<8)|55)+1);


        (11,55) : setPromoLevel(((11<<8)|55)+1);


        (12,55) : setPromoLevel(((12<<8)|55)+1);


        (13,55) : setPromoLevel(((13<<8)|55)+1);


        (14,55) : setPromoLevel(((14<<8)|55)+1);


        (15,55) : setPromoLevel(((15<<8)|55)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 323 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,56) : setPromoLevel(((0<<8)|56)+1);


        (1,56) : setPromoLevel(((1<<8)|56)+1);


        (2,56) : setPromoLevel(((2<<8)|56)+1);


        (3,56) : setPromoLevel(((3<<8)|56)+1);


        (4,56) : setPromoLevel(((4<<8)|56)+1);


        (5,56) : setPromoLevel(((5<<8)|56)+1);


        (6,56) : setPromoLevel(((6<<8)|56)+1);


        (7,56) : setPromoLevel(((7<<8)|56)+1);


        (8,56) : setPromoLevel(((8<<8)|56)+1);


        (9,56) : setPromoLevel(((9<<8)|56)+1);


        (10,56) : setPromoLevel(((10<<8)|56)+1);


        (11,56) : setPromoLevel(((11<<8)|56)+1);


        (12,56) : setPromoLevel(((12<<8)|56)+1);


        (13,56) : setPromoLevel(((13<<8)|56)+1);


        (14,56) : setPromoLevel(((14<<8)|56)+1);


        (15,56) : setPromoLevel(((15<<8)|56)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 328 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,57) : setPromoLevel(((0<<8)|57)+1);


        (1,57) : setPromoLevel(((1<<8)|57)+1);


        (2,57) : setPromoLevel(((2<<8)|57)+1);


        (3,57) : setPromoLevel(((3<<8)|57)+1);


        (4,57) : setPromoLevel(((4<<8)|57)+1);


        (5,57) : setPromoLevel(((5<<8)|57)+1);


        (6,57) : setPromoLevel(((6<<8)|57)+1);


        (7,57) : setPromoLevel(((7<<8)|57)+1);


        (8,57) : setPromoLevel(((8<<8)|57)+1);


        (9,57) : setPromoLevel(((9<<8)|57)+1);


        (10,57) : setPromoLevel(((10<<8)|57)+1);


        (11,57) : setPromoLevel(((11<<8)|57)+1);


        (12,57) : setPromoLevel(((12<<8)|57)+1);


        (13,57) : setPromoLevel(((13<<8)|57)+1);


        (14,57) : setPromoLevel(((14<<8)|57)+1);


        (15,57) : setPromoLevel(((15<<8)|57)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 333 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,58) : setPromoLevel(((0<<8)|58)+1);


        (1,58) : setPromoLevel(((1<<8)|58)+1);


        (2,58) : setPromoLevel(((2<<8)|58)+1);


        (3,58) : setPromoLevel(((3<<8)|58)+1);


        (4,58) : setPromoLevel(((4<<8)|58)+1);


        (5,58) : setPromoLevel(((5<<8)|58)+1);


        (6,58) : setPromoLevel(((6<<8)|58)+1);


        (7,58) : setPromoLevel(((7<<8)|58)+1);


        (8,58) : setPromoLevel(((8<<8)|58)+1);


        (9,58) : setPromoLevel(((9<<8)|58)+1);


        (10,58) : setPromoLevel(((10<<8)|58)+1);


        (11,58) : setPromoLevel(((11<<8)|58)+1);


        (12,58) : setPromoLevel(((12<<8)|58)+1);


        (13,58) : setPromoLevel(((13<<8)|58)+1);


        (14,58) : setPromoLevel(((14<<8)|58)+1);


        (15,58) : setPromoLevel(((15<<8)|58)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 338 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,59) : setPromoLevel(((0<<8)|59)+1);


        (1,59) : setPromoLevel(((1<<8)|59)+1);


        (2,59) : setPromoLevel(((2<<8)|59)+1);


        (3,59) : setPromoLevel(((3<<8)|59)+1);


        (4,59) : setPromoLevel(((4<<8)|59)+1);


        (5,59) : setPromoLevel(((5<<8)|59)+1);


        (6,59) : setPromoLevel(((6<<8)|59)+1);


        (7,59) : setPromoLevel(((7<<8)|59)+1);


        (8,59) : setPromoLevel(((8<<8)|59)+1);


        (9,59) : setPromoLevel(((9<<8)|59)+1);


        (10,59) : setPromoLevel(((10<<8)|59)+1);


        (11,59) : setPromoLevel(((11<<8)|59)+1);


        (12,59) : setPromoLevel(((12<<8)|59)+1);


        (13,59) : setPromoLevel(((13<<8)|59)+1);


        (14,59) : setPromoLevel(((14<<8)|59)+1);


        (15,59) : setPromoLevel(((15<<8)|59)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 343 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,60) : setPromoLevel(((0<<8)|60)+1);


        (1,60) : setPromoLevel(((1<<8)|60)+1);


        (2,60) : setPromoLevel(((2<<8)|60)+1);


        (3,60) : setPromoLevel(((3<<8)|60)+1);


        (4,60) : setPromoLevel(((4<<8)|60)+1);


        (5,60) : setPromoLevel(((5<<8)|60)+1);


        (6,60) : setPromoLevel(((6<<8)|60)+1);


        (7,60) : setPromoLevel(((7<<8)|60)+1);


        (8,60) : setPromoLevel(((8<<8)|60)+1);


        (9,60) : setPromoLevel(((9<<8)|60)+1);


        (10,60) : setPromoLevel(((10<<8)|60)+1);


        (11,60) : setPromoLevel(((11<<8)|60)+1);


        (12,60) : setPromoLevel(((12<<8)|60)+1);


        (13,60) : setPromoLevel(((13<<8)|60)+1);


        (14,60) : setPromoLevel(((14<<8)|60)+1);


        (15,60) : setPromoLevel(((15<<8)|60)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 348 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,61) : setPromoLevel(((0<<8)|61)+1);


        (1,61) : setPromoLevel(((1<<8)|61)+1);


        (2,61) : setPromoLevel(((2<<8)|61)+1);


        (3,61) : setPromoLevel(((3<<8)|61)+1);


        (4,61) : setPromoLevel(((4<<8)|61)+1);


        (5,61) : setPromoLevel(((5<<8)|61)+1);


        (6,61) : setPromoLevel(((6<<8)|61)+1);


        (7,61) : setPromoLevel(((7<<8)|61)+1);


        (8,61) : setPromoLevel(((8<<8)|61)+1);


        (9,61) : setPromoLevel(((9<<8)|61)+1);


        (10,61) : setPromoLevel(((10<<8)|61)+1);


        (11,61) : setPromoLevel(((11<<8)|61)+1);


        (12,61) : setPromoLevel(((12<<8)|61)+1);


        (13,61) : setPromoLevel(((13<<8)|61)+1);


        (14,61) : setPromoLevel(((14<<8)|61)+1);


        (15,61) : setPromoLevel(((15<<8)|61)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 353 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,62) : setPromoLevel(((0<<8)|62)+1);


        (1,62) : setPromoLevel(((1<<8)|62)+1);


        (2,62) : setPromoLevel(((2<<8)|62)+1);


        (3,62) : setPromoLevel(((3<<8)|62)+1);


        (4,62) : setPromoLevel(((4<<8)|62)+1);


        (5,62) : setPromoLevel(((5<<8)|62)+1);


        (6,62) : setPromoLevel(((6<<8)|62)+1);


        (7,62) : setPromoLevel(((7<<8)|62)+1);


        (8,62) : setPromoLevel(((8<<8)|62)+1);


        (9,62) : setPromoLevel(((9<<8)|62)+1);


        (10,62) : setPromoLevel(((10<<8)|62)+1);


        (11,62) : setPromoLevel(((11<<8)|62)+1);


        (12,62) : setPromoLevel(((12<<8)|62)+1);


        (13,62) : setPromoLevel(((13<<8)|62)+1);


        (14,62) : setPromoLevel(((14<<8)|62)+1);


        (15,62) : setPromoLevel(((15<<8)|62)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 358 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,63) : setPromoLevel(((0<<8)|63)+1);


        (1,63) : setPromoLevel(((1<<8)|63)+1);


        (2,63) : setPromoLevel(((2<<8)|63)+1);


        (3,63) : setPromoLevel(((3<<8)|63)+1);


        (4,63) : setPromoLevel(((4<<8)|63)+1);


        (5,63) : setPromoLevel(((5<<8)|63)+1);


        (6,63) : setPromoLevel(((6<<8)|63)+1);


        (7,63) : setPromoLevel(((7<<8)|63)+1);


        (8,63) : setPromoLevel(((8<<8)|63)+1);


        (9,63) : setPromoLevel(((9<<8)|63)+1);


        (10,63) : setPromoLevel(((10<<8)|63)+1);


        (11,63) : setPromoLevel(((11<<8)|63)+1);


        (12,63) : setPromoLevel(((12<<8)|63)+1);


        (13,63) : setPromoLevel(((13<<8)|63)+1);


        (14,63) : setPromoLevel(((14<<8)|63)+1);


        (15,63) : setPromoLevel(((15<<8)|63)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 363 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,64) : setPromoLevel(((0<<8)|64)+1);


        (1,64) : setPromoLevel(((1<<8)|64)+1);


        (2,64) : setPromoLevel(((2<<8)|64)+1);


        (3,64) : setPromoLevel(((3<<8)|64)+1);


        (4,64) : setPromoLevel(((4<<8)|64)+1);


        (5,64) : setPromoLevel(((5<<8)|64)+1);


        (6,64) : setPromoLevel(((6<<8)|64)+1);


        (7,64) : setPromoLevel(((7<<8)|64)+1);


        (8,64) : setPromoLevel(((8<<8)|64)+1);


        (9,64) : setPromoLevel(((9<<8)|64)+1);


        (10,64) : setPromoLevel(((10<<8)|64)+1);


        (11,64) : setPromoLevel(((11<<8)|64)+1);


        (12,64) : setPromoLevel(((12<<8)|64)+1);


        (13,64) : setPromoLevel(((13<<8)|64)+1);


        (14,64) : setPromoLevel(((14<<8)|64)+1);


        (15,64) : setPromoLevel(((15<<8)|64)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 368 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,65) : setPromoLevel(((0<<8)|65)+1);


        (1,65) : setPromoLevel(((1<<8)|65)+1);


        (2,65) : setPromoLevel(((2<<8)|65)+1);


        (3,65) : setPromoLevel(((3<<8)|65)+1);


        (4,65) : setPromoLevel(((4<<8)|65)+1);


        (5,65) : setPromoLevel(((5<<8)|65)+1);


        (6,65) : setPromoLevel(((6<<8)|65)+1);


        (7,65) : setPromoLevel(((7<<8)|65)+1);


        (8,65) : setPromoLevel(((8<<8)|65)+1);


        (9,65) : setPromoLevel(((9<<8)|65)+1);


        (10,65) : setPromoLevel(((10<<8)|65)+1);


        (11,65) : setPromoLevel(((11<<8)|65)+1);


        (12,65) : setPromoLevel(((12<<8)|65)+1);


        (13,65) : setPromoLevel(((13<<8)|65)+1);


        (14,65) : setPromoLevel(((14<<8)|65)+1);


        (15,65) : setPromoLevel(((15<<8)|65)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 373 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,66) : setPromoLevel(((0<<8)|66)+1);


        (1,66) : setPromoLevel(((1<<8)|66)+1);


        (2,66) : setPromoLevel(((2<<8)|66)+1);


        (3,66) : setPromoLevel(((3<<8)|66)+1);


        (4,66) : setPromoLevel(((4<<8)|66)+1);


        (5,66) : setPromoLevel(((5<<8)|66)+1);


        (6,66) : setPromoLevel(((6<<8)|66)+1);


        (7,66) : setPromoLevel(((7<<8)|66)+1);


        (8,66) : setPromoLevel(((8<<8)|66)+1);


        (9,66) : setPromoLevel(((9<<8)|66)+1);


        (10,66) : setPromoLevel(((10<<8)|66)+1);


        (11,66) : setPromoLevel(((11<<8)|66)+1);


        (12,66) : setPromoLevel(((12<<8)|66)+1);


        (13,66) : setPromoLevel(((13<<8)|66)+1);


        (14,66) : setPromoLevel(((14<<8)|66)+1);


        (15,66) : setPromoLevel(((15<<8)|66)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 378 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,67) : setPromoLevel(((0<<8)|67)+1);


        (1,67) : setPromoLevel(((1<<8)|67)+1);


        (2,67) : setPromoLevel(((2<<8)|67)+1);


        (3,67) : setPromoLevel(((3<<8)|67)+1);


        (4,67) : setPromoLevel(((4<<8)|67)+1);


        (5,67) : setPromoLevel(((5<<8)|67)+1);


        (6,67) : setPromoLevel(((6<<8)|67)+1);


        (7,67) : setPromoLevel(((7<<8)|67)+1);


        (8,67) : setPromoLevel(((8<<8)|67)+1);


        (9,67) : setPromoLevel(((9<<8)|67)+1);


        (10,67) : setPromoLevel(((10<<8)|67)+1);


        (11,67) : setPromoLevel(((11<<8)|67)+1);


        (12,67) : setPromoLevel(((12<<8)|67)+1);


        (13,67) : setPromoLevel(((13<<8)|67)+1);


        (14,67) : setPromoLevel(((14<<8)|67)+1);


        (15,67) : setPromoLevel(((15<<8)|67)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 383 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,68) : setPromoLevel(((0<<8)|68)+1);


        (1,68) : setPromoLevel(((1<<8)|68)+1);


        (2,68) : setPromoLevel(((2<<8)|68)+1);


        (3,68) : setPromoLevel(((3<<8)|68)+1);


        (4,68) : setPromoLevel(((4<<8)|68)+1);


        (5,68) : setPromoLevel(((5<<8)|68)+1);


        (6,68) : setPromoLevel(((6<<8)|68)+1);


        (7,68) : setPromoLevel(((7<<8)|68)+1);


        (8,68) : setPromoLevel(((8<<8)|68)+1);


        (9,68) : setPromoLevel(((9<<8)|68)+1);


        (10,68) : setPromoLevel(((10<<8)|68)+1);


        (11,68) : setPromoLevel(((11<<8)|68)+1);


        (12,68) : setPromoLevel(((12<<8)|68)+1);


        (13,68) : setPromoLevel(((13<<8)|68)+1);


        (14,68) : setPromoLevel(((14<<8)|68)+1);


        (15,68) : setPromoLevel(((15<<8)|68)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 388 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,69) : setPromoLevel(((0<<8)|69)+1);


        (1,69) : setPromoLevel(((1<<8)|69)+1);


        (2,69) : setPromoLevel(((2<<8)|69)+1);


        (3,69) : setPromoLevel(((3<<8)|69)+1);


        (4,69) : setPromoLevel(((4<<8)|69)+1);


        (5,69) : setPromoLevel(((5<<8)|69)+1);


        (6,69) : setPromoLevel(((6<<8)|69)+1);


        (7,69) : setPromoLevel(((7<<8)|69)+1);


        (8,69) : setPromoLevel(((8<<8)|69)+1);


        (9,69) : setPromoLevel(((9<<8)|69)+1);


        (10,69) : setPromoLevel(((10<<8)|69)+1);


        (11,69) : setPromoLevel(((11<<8)|69)+1);


        (12,69) : setPromoLevel(((12<<8)|69)+1);


        (13,69) : setPromoLevel(((13<<8)|69)+1);


        (14,69) : setPromoLevel(((14<<8)|69)+1);


        (15,69) : setPromoLevel(((15<<8)|69)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 393 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,70) : setPromoLevel(((0<<8)|70)+1);


        (1,70) : setPromoLevel(((1<<8)|70)+1);


        (2,70) : setPromoLevel(((2<<8)|70)+1);


        (3,70) : setPromoLevel(((3<<8)|70)+1);


        (4,70) : setPromoLevel(((4<<8)|70)+1);


        (5,70) : setPromoLevel(((5<<8)|70)+1);


        (6,70) : setPromoLevel(((6<<8)|70)+1);


        (7,70) : setPromoLevel(((7<<8)|70)+1);


        (8,70) : setPromoLevel(((8<<8)|70)+1);


        (9,70) : setPromoLevel(((9<<8)|70)+1);


        (10,70) : setPromoLevel(((10<<8)|70)+1);


        (11,70) : setPromoLevel(((11<<8)|70)+1);


        (12,70) : setPromoLevel(((12<<8)|70)+1);


        (13,70) : setPromoLevel(((13<<8)|70)+1);


        (14,70) : setPromoLevel(((14<<8)|70)+1);


        (15,70) : setPromoLevel(((15<<8)|70)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 398 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,71) : setPromoLevel(((0<<8)|71)+1);


        (1,71) : setPromoLevel(((1<<8)|71)+1);


        (2,71) : setPromoLevel(((2<<8)|71)+1);


        (3,71) : setPromoLevel(((3<<8)|71)+1);


        (4,71) : setPromoLevel(((4<<8)|71)+1);


        (5,71) : setPromoLevel(((5<<8)|71)+1);


        (6,71) : setPromoLevel(((6<<8)|71)+1);


        (7,71) : setPromoLevel(((7<<8)|71)+1);


        (8,71) : setPromoLevel(((8<<8)|71)+1);


        (9,71) : setPromoLevel(((9<<8)|71)+1);


        (10,71) : setPromoLevel(((10<<8)|71)+1);


        (11,71) : setPromoLevel(((11<<8)|71)+1);


        (12,71) : setPromoLevel(((12<<8)|71)+1);


        (13,71) : setPromoLevel(((13<<8)|71)+1);


        (14,71) : setPromoLevel(((14<<8)|71)+1);


        (15,71) : setPromoLevel(((15<<8)|71)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 403 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,72) : setPromoLevel(((0<<8)|72)+1);


        (1,72) : setPromoLevel(((1<<8)|72)+1);


        (2,72) : setPromoLevel(((2<<8)|72)+1);


        (3,72) : setPromoLevel(((3<<8)|72)+1);


        (4,72) : setPromoLevel(((4<<8)|72)+1);


        (5,72) : setPromoLevel(((5<<8)|72)+1);


        (6,72) : setPromoLevel(((6<<8)|72)+1);


        (7,72) : setPromoLevel(((7<<8)|72)+1);


        (8,72) : setPromoLevel(((8<<8)|72)+1);


        (9,72) : setPromoLevel(((9<<8)|72)+1);


        (10,72) : setPromoLevel(((10<<8)|72)+1);


        (11,72) : setPromoLevel(((11<<8)|72)+1);


        (12,72) : setPromoLevel(((12<<8)|72)+1);


        (13,72) : setPromoLevel(((13<<8)|72)+1);


        (14,72) : setPromoLevel(((14<<8)|72)+1);


        (15,72) : setPromoLevel(((15<<8)|72)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 408 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,73) : setPromoLevel(((0<<8)|73)+1);


        (1,73) : setPromoLevel(((1<<8)|73)+1);


        (2,73) : setPromoLevel(((2<<8)|73)+1);


        (3,73) : setPromoLevel(((3<<8)|73)+1);


        (4,73) : setPromoLevel(((4<<8)|73)+1);


        (5,73) : setPromoLevel(((5<<8)|73)+1);


        (6,73) : setPromoLevel(((6<<8)|73)+1);


        (7,73) : setPromoLevel(((7<<8)|73)+1);


        (8,73) : setPromoLevel(((8<<8)|73)+1);


        (9,73) : setPromoLevel(((9<<8)|73)+1);


        (10,73) : setPromoLevel(((10<<8)|73)+1);


        (11,73) : setPromoLevel(((11<<8)|73)+1);


        (12,73) : setPromoLevel(((12<<8)|73)+1);


        (13,73) : setPromoLevel(((13<<8)|73)+1);


        (14,73) : setPromoLevel(((14<<8)|73)+1);


        (15,73) : setPromoLevel(((15<<8)|73)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 413 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,74) : setPromoLevel(((0<<8)|74)+1);


        (1,74) : setPromoLevel(((1<<8)|74)+1);


        (2,74) : setPromoLevel(((2<<8)|74)+1);


        (3,74) : setPromoLevel(((3<<8)|74)+1);


        (4,74) : setPromoLevel(((4<<8)|74)+1);


        (5,74) : setPromoLevel(((5<<8)|74)+1);


        (6,74) : setPromoLevel(((6<<8)|74)+1);


        (7,74) : setPromoLevel(((7<<8)|74)+1);


        (8,74) : setPromoLevel(((8<<8)|74)+1);


        (9,74) : setPromoLevel(((9<<8)|74)+1);


        (10,74) : setPromoLevel(((10<<8)|74)+1);


        (11,74) : setPromoLevel(((11<<8)|74)+1);


        (12,74) : setPromoLevel(((12<<8)|74)+1);


        (13,74) : setPromoLevel(((13<<8)|74)+1);


        (14,74) : setPromoLevel(((14<<8)|74)+1);


        (15,74) : setPromoLevel(((15<<8)|74)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 418 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,75) : setPromoLevel(((0<<8)|75)+1);


        (1,75) : setPromoLevel(((1<<8)|75)+1);


        (2,75) : setPromoLevel(((2<<8)|75)+1);


        (3,75) : setPromoLevel(((3<<8)|75)+1);


        (4,75) : setPromoLevel(((4<<8)|75)+1);


        (5,75) : setPromoLevel(((5<<8)|75)+1);


        (6,75) : setPromoLevel(((6<<8)|75)+1);


        (7,75) : setPromoLevel(((7<<8)|75)+1);


        (8,75) : setPromoLevel(((8<<8)|75)+1);


        (9,75) : setPromoLevel(((9<<8)|75)+1);


        (10,75) : setPromoLevel(((10<<8)|75)+1);


        (11,75) : setPromoLevel(((11<<8)|75)+1);


        (12,75) : setPromoLevel(((12<<8)|75)+1);


        (13,75) : setPromoLevel(((13<<8)|75)+1);


        (14,75) : setPromoLevel(((14<<8)|75)+1);


        (15,75) : setPromoLevel(((15<<8)|75)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 423 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,76) : setPromoLevel(((0<<8)|76)+1);


        (1,76) : setPromoLevel(((1<<8)|76)+1);


        (2,76) : setPromoLevel(((2<<8)|76)+1);


        (3,76) : setPromoLevel(((3<<8)|76)+1);


        (4,76) : setPromoLevel(((4<<8)|76)+1);


        (5,76) : setPromoLevel(((5<<8)|76)+1);


        (6,76) : setPromoLevel(((6<<8)|76)+1);


        (7,76) : setPromoLevel(((7<<8)|76)+1);


        (8,76) : setPromoLevel(((8<<8)|76)+1);


        (9,76) : setPromoLevel(((9<<8)|76)+1);


        (10,76) : setPromoLevel(((10<<8)|76)+1);


        (11,76) : setPromoLevel(((11<<8)|76)+1);


        (12,76) : setPromoLevel(((12<<8)|76)+1);


        (13,76) : setPromoLevel(((13<<8)|76)+1);


        (14,76) : setPromoLevel(((14<<8)|76)+1);


        (15,76) : setPromoLevel(((15<<8)|76)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 428 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,77) : setPromoLevel(((0<<8)|77)+1);


        (1,77) : setPromoLevel(((1<<8)|77)+1);


        (2,77) : setPromoLevel(((2<<8)|77)+1);


        (3,77) : setPromoLevel(((3<<8)|77)+1);


        (4,77) : setPromoLevel(((4<<8)|77)+1);


        (5,77) : setPromoLevel(((5<<8)|77)+1);


        (6,77) : setPromoLevel(((6<<8)|77)+1);


        (7,77) : setPromoLevel(((7<<8)|77)+1);


        (8,77) : setPromoLevel(((8<<8)|77)+1);


        (9,77) : setPromoLevel(((9<<8)|77)+1);


        (10,77) : setPromoLevel(((10<<8)|77)+1);


        (11,77) : setPromoLevel(((11<<8)|77)+1);


        (12,77) : setPromoLevel(((12<<8)|77)+1);


        (13,77) : setPromoLevel(((13<<8)|77)+1);


        (14,77) : setPromoLevel(((14<<8)|77)+1);


        (15,77) : setPromoLevel(((15<<8)|77)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 433 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,78) : setPromoLevel(((0<<8)|78)+1);


        (1,78) : setPromoLevel(((1<<8)|78)+1);


        (2,78) : setPromoLevel(((2<<8)|78)+1);


        (3,78) : setPromoLevel(((3<<8)|78)+1);


        (4,78) : setPromoLevel(((4<<8)|78)+1);


        (5,78) : setPromoLevel(((5<<8)|78)+1);


        (6,78) : setPromoLevel(((6<<8)|78)+1);


        (7,78) : setPromoLevel(((7<<8)|78)+1);


        (8,78) : setPromoLevel(((8<<8)|78)+1);


        (9,78) : setPromoLevel(((9<<8)|78)+1);


        (10,78) : setPromoLevel(((10<<8)|78)+1);


        (11,78) : setPromoLevel(((11<<8)|78)+1);


        (12,78) : setPromoLevel(((12<<8)|78)+1);


        (13,78) : setPromoLevel(((13<<8)|78)+1);


        (14,78) : setPromoLevel(((14<<8)|78)+1);


        (15,78) : setPromoLevel(((15<<8)|78)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 438 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,79) : setPromoLevel(((0<<8)|79)+1);


        (1,79) : setPromoLevel(((1<<8)|79)+1);


        (2,79) : setPromoLevel(((2<<8)|79)+1);


        (3,79) : setPromoLevel(((3<<8)|79)+1);


        (4,79) : setPromoLevel(((4<<8)|79)+1);


        (5,79) : setPromoLevel(((5<<8)|79)+1);


        (6,79) : setPromoLevel(((6<<8)|79)+1);


        (7,79) : setPromoLevel(((7<<8)|79)+1);


        (8,79) : setPromoLevel(((8<<8)|79)+1);


        (9,79) : setPromoLevel(((9<<8)|79)+1);


        (10,79) : setPromoLevel(((10<<8)|79)+1);


        (11,79) : setPromoLevel(((11<<8)|79)+1);


        (12,79) : setPromoLevel(((12<<8)|79)+1);


        (13,79) : setPromoLevel(((13<<8)|79)+1);


        (14,79) : setPromoLevel(((14<<8)|79)+1);


        (15,79) : setPromoLevel(((15<<8)|79)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 443 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,80) : setPromoLevel(((0<<8)|80)+1);


        (1,80) : setPromoLevel(((1<<8)|80)+1);


        (2,80) : setPromoLevel(((2<<8)|80)+1);


        (3,80) : setPromoLevel(((3<<8)|80)+1);


        (4,80) : setPromoLevel(((4<<8)|80)+1);


        (5,80) : setPromoLevel(((5<<8)|80)+1);


        (6,80) : setPromoLevel(((6<<8)|80)+1);


        (7,80) : setPromoLevel(((7<<8)|80)+1);


        (8,80) : setPromoLevel(((8<<8)|80)+1);


        (9,80) : setPromoLevel(((9<<8)|80)+1);


        (10,80) : setPromoLevel(((10<<8)|80)+1);


        (11,80) : setPromoLevel(((11<<8)|80)+1);


        (12,80) : setPromoLevel(((12<<8)|80)+1);


        (13,80) : setPromoLevel(((13<<8)|80)+1);


        (14,80) : setPromoLevel(((14<<8)|80)+1);


        (15,80) : setPromoLevel(((15<<8)|80)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 448 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,81) : setPromoLevel(((0<<8)|81)+1);


        (1,81) : setPromoLevel(((1<<8)|81)+1);


        (2,81) : setPromoLevel(((2<<8)|81)+1);


        (3,81) : setPromoLevel(((3<<8)|81)+1);


        (4,81) : setPromoLevel(((4<<8)|81)+1);


        (5,81) : setPromoLevel(((5<<8)|81)+1);


        (6,81) : setPromoLevel(((6<<8)|81)+1);


        (7,81) : setPromoLevel(((7<<8)|81)+1);


        (8,81) : setPromoLevel(((8<<8)|81)+1);


        (9,81) : setPromoLevel(((9<<8)|81)+1);


        (10,81) : setPromoLevel(((10<<8)|81)+1);


        (11,81) : setPromoLevel(((11<<8)|81)+1);


        (12,81) : setPromoLevel(((12<<8)|81)+1);


        (13,81) : setPromoLevel(((13<<8)|81)+1);


        (14,81) : setPromoLevel(((14<<8)|81)+1);


        (15,81) : setPromoLevel(((15<<8)|81)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 453 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,82) : setPromoLevel(((0<<8)|82)+1);


        (1,82) : setPromoLevel(((1<<8)|82)+1);


        (2,82) : setPromoLevel(((2<<8)|82)+1);


        (3,82) : setPromoLevel(((3<<8)|82)+1);


        (4,82) : setPromoLevel(((4<<8)|82)+1);


        (5,82) : setPromoLevel(((5<<8)|82)+1);


        (6,82) : setPromoLevel(((6<<8)|82)+1);


        (7,82) : setPromoLevel(((7<<8)|82)+1);


        (8,82) : setPromoLevel(((8<<8)|82)+1);


        (9,82) : setPromoLevel(((9<<8)|82)+1);


        (10,82) : setPromoLevel(((10<<8)|82)+1);


        (11,82) : setPromoLevel(((11<<8)|82)+1);


        (12,82) : setPromoLevel(((12<<8)|82)+1);


        (13,82) : setPromoLevel(((13<<8)|82)+1);


        (14,82) : setPromoLevel(((14<<8)|82)+1);


        (15,82) : setPromoLevel(((15<<8)|82)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 458 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,83) : setPromoLevel(((0<<8)|83)+1);


        (1,83) : setPromoLevel(((1<<8)|83)+1);


        (2,83) : setPromoLevel(((2<<8)|83)+1);


        (3,83) : setPromoLevel(((3<<8)|83)+1);


        (4,83) : setPromoLevel(((4<<8)|83)+1);


        (5,83) : setPromoLevel(((5<<8)|83)+1);


        (6,83) : setPromoLevel(((6<<8)|83)+1);


        (7,83) : setPromoLevel(((7<<8)|83)+1);


        (8,83) : setPromoLevel(((8<<8)|83)+1);


        (9,83) : setPromoLevel(((9<<8)|83)+1);


        (10,83) : setPromoLevel(((10<<8)|83)+1);


        (11,83) : setPromoLevel(((11<<8)|83)+1);


        (12,83) : setPromoLevel(((12<<8)|83)+1);


        (13,83) : setPromoLevel(((13<<8)|83)+1);


        (14,83) : setPromoLevel(((14<<8)|83)+1);


        (15,83) : setPromoLevel(((15<<8)|83)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 463 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,84) : setPromoLevel(((0<<8)|84)+1);


        (1,84) : setPromoLevel(((1<<8)|84)+1);


        (2,84) : setPromoLevel(((2<<8)|84)+1);


        (3,84) : setPromoLevel(((3<<8)|84)+1);


        (4,84) : setPromoLevel(((4<<8)|84)+1);


        (5,84) : setPromoLevel(((5<<8)|84)+1);


        (6,84) : setPromoLevel(((6<<8)|84)+1);


        (7,84) : setPromoLevel(((7<<8)|84)+1);


        (8,84) : setPromoLevel(((8<<8)|84)+1);


        (9,84) : setPromoLevel(((9<<8)|84)+1);


        (10,84) : setPromoLevel(((10<<8)|84)+1);


        (11,84) : setPromoLevel(((11<<8)|84)+1);


        (12,84) : setPromoLevel(((12<<8)|84)+1);


        (13,84) : setPromoLevel(((13<<8)|84)+1);


        (14,84) : setPromoLevel(((14<<8)|84)+1);


        (15,84) : setPromoLevel(((15<<8)|84)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 468 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,85) : setPromoLevel(((0<<8)|85)+1);


        (1,85) : setPromoLevel(((1<<8)|85)+1);


        (2,85) : setPromoLevel(((2<<8)|85)+1);


        (3,85) : setPromoLevel(((3<<8)|85)+1);


        (4,85) : setPromoLevel(((4<<8)|85)+1);


        (5,85) : setPromoLevel(((5<<8)|85)+1);


        (6,85) : setPromoLevel(((6<<8)|85)+1);


        (7,85) : setPromoLevel(((7<<8)|85)+1);


        (8,85) : setPromoLevel(((8<<8)|85)+1);


        (9,85) : setPromoLevel(((9<<8)|85)+1);


        (10,85) : setPromoLevel(((10<<8)|85)+1);


        (11,85) : setPromoLevel(((11<<8)|85)+1);


        (12,85) : setPromoLevel(((12<<8)|85)+1);


        (13,85) : setPromoLevel(((13<<8)|85)+1);


        (14,85) : setPromoLevel(((14<<8)|85)+1);


        (15,85) : setPromoLevel(((15<<8)|85)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 473 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,86) : setPromoLevel(((0<<8)|86)+1);


        (1,86) : setPromoLevel(((1<<8)|86)+1);


        (2,86) : setPromoLevel(((2<<8)|86)+1);


        (3,86) : setPromoLevel(((3<<8)|86)+1);


        (4,86) : setPromoLevel(((4<<8)|86)+1);


        (5,86) : setPromoLevel(((5<<8)|86)+1);


        (6,86) : setPromoLevel(((6<<8)|86)+1);


        (7,86) : setPromoLevel(((7<<8)|86)+1);


        (8,86) : setPromoLevel(((8<<8)|86)+1);


        (9,86) : setPromoLevel(((9<<8)|86)+1);


        (10,86) : setPromoLevel(((10<<8)|86)+1);


        (11,86) : setPromoLevel(((11<<8)|86)+1);


        (12,86) : setPromoLevel(((12<<8)|86)+1);


        (13,86) : setPromoLevel(((13<<8)|86)+1);


        (14,86) : setPromoLevel(((14<<8)|86)+1);


        (15,86) : setPromoLevel(((15<<8)|86)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 478 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,87) : setPromoLevel(((0<<8)|87)+1);


        (1,87) : setPromoLevel(((1<<8)|87)+1);


        (2,87) : setPromoLevel(((2<<8)|87)+1);


        (3,87) : setPromoLevel(((3<<8)|87)+1);


        (4,87) : setPromoLevel(((4<<8)|87)+1);


        (5,87) : setPromoLevel(((5<<8)|87)+1);


        (6,87) : setPromoLevel(((6<<8)|87)+1);


        (7,87) : setPromoLevel(((7<<8)|87)+1);


        (8,87) : setPromoLevel(((8<<8)|87)+1);


        (9,87) : setPromoLevel(((9<<8)|87)+1);


        (10,87) : setPromoLevel(((10<<8)|87)+1);


        (11,87) : setPromoLevel(((11<<8)|87)+1);


        (12,87) : setPromoLevel(((12<<8)|87)+1);


        (13,87) : setPromoLevel(((13<<8)|87)+1);


        (14,87) : setPromoLevel(((14<<8)|87)+1);


        (15,87) : setPromoLevel(((15<<8)|87)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 483 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,88) : setPromoLevel(((0<<8)|88)+1);


        (1,88) : setPromoLevel(((1<<8)|88)+1);


        (2,88) : setPromoLevel(((2<<8)|88)+1);


        (3,88) : setPromoLevel(((3<<8)|88)+1);


        (4,88) : setPromoLevel(((4<<8)|88)+1);


        (5,88) : setPromoLevel(((5<<8)|88)+1);


        (6,88) : setPromoLevel(((6<<8)|88)+1);


        (7,88) : setPromoLevel(((7<<8)|88)+1);


        (8,88) : setPromoLevel(((8<<8)|88)+1);


        (9,88) : setPromoLevel(((9<<8)|88)+1);


        (10,88) : setPromoLevel(((10<<8)|88)+1);


        (11,88) : setPromoLevel(((11<<8)|88)+1);


        (12,88) : setPromoLevel(((12<<8)|88)+1);


        (13,88) : setPromoLevel(((13<<8)|88)+1);


        (14,88) : setPromoLevel(((14<<8)|88)+1);


        (15,88) : setPromoLevel(((15<<8)|88)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 488 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,89) : setPromoLevel(((0<<8)|89)+1);


        (1,89) : setPromoLevel(((1<<8)|89)+1);


        (2,89) : setPromoLevel(((2<<8)|89)+1);


        (3,89) : setPromoLevel(((3<<8)|89)+1);


        (4,89) : setPromoLevel(((4<<8)|89)+1);


        (5,89) : setPromoLevel(((5<<8)|89)+1);


        (6,89) : setPromoLevel(((6<<8)|89)+1);


        (7,89) : setPromoLevel(((7<<8)|89)+1);


        (8,89) : setPromoLevel(((8<<8)|89)+1);


        (9,89) : setPromoLevel(((9<<8)|89)+1);


        (10,89) : setPromoLevel(((10<<8)|89)+1);


        (11,89) : setPromoLevel(((11<<8)|89)+1);


        (12,89) : setPromoLevel(((12<<8)|89)+1);


        (13,89) : setPromoLevel(((13<<8)|89)+1);


        (14,89) : setPromoLevel(((14<<8)|89)+1);


        (15,89) : setPromoLevel(((15<<8)|89)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 493 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,90) : setPromoLevel(((0<<8)|90)+1);


        (1,90) : setPromoLevel(((1<<8)|90)+1);


        (2,90) : setPromoLevel(((2<<8)|90)+1);


        (3,90) : setPromoLevel(((3<<8)|90)+1);


        (4,90) : setPromoLevel(((4<<8)|90)+1);


        (5,90) : setPromoLevel(((5<<8)|90)+1);


        (6,90) : setPromoLevel(((6<<8)|90)+1);


        (7,90) : setPromoLevel(((7<<8)|90)+1);


        (8,90) : setPromoLevel(((8<<8)|90)+1);


        (9,90) : setPromoLevel(((9<<8)|90)+1);


        (10,90) : setPromoLevel(((10<<8)|90)+1);


        (11,90) : setPromoLevel(((11<<8)|90)+1);


        (12,90) : setPromoLevel(((12<<8)|90)+1);


        (13,90) : setPromoLevel(((13<<8)|90)+1);


        (14,90) : setPromoLevel(((14<<8)|90)+1);


        (15,90) : setPromoLevel(((15<<8)|90)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 498 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,91) : setPromoLevel(((0<<8)|91)+1);


        (1,91) : setPromoLevel(((1<<8)|91)+1);


        (2,91) : setPromoLevel(((2<<8)|91)+1);


        (3,91) : setPromoLevel(((3<<8)|91)+1);


        (4,91) : setPromoLevel(((4<<8)|91)+1);


        (5,91) : setPromoLevel(((5<<8)|91)+1);


        (6,91) : setPromoLevel(((6<<8)|91)+1);


        (7,91) : setPromoLevel(((7<<8)|91)+1);


        (8,91) : setPromoLevel(((8<<8)|91)+1);


        (9,91) : setPromoLevel(((9<<8)|91)+1);


        (10,91) : setPromoLevel(((10<<8)|91)+1);


        (11,91) : setPromoLevel(((11<<8)|91)+1);


        (12,91) : setPromoLevel(((12<<8)|91)+1);


        (13,91) : setPromoLevel(((13<<8)|91)+1);


        (14,91) : setPromoLevel(((14<<8)|91)+1);


        (15,91) : setPromoLevel(((15<<8)|91)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 503 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,92) : setPromoLevel(((0<<8)|92)+1);


        (1,92) : setPromoLevel(((1<<8)|92)+1);


        (2,92) : setPromoLevel(((2<<8)|92)+1);


        (3,92) : setPromoLevel(((3<<8)|92)+1);


        (4,92) : setPromoLevel(((4<<8)|92)+1);


        (5,92) : setPromoLevel(((5<<8)|92)+1);


        (6,92) : setPromoLevel(((6<<8)|92)+1);


        (7,92) : setPromoLevel(((7<<8)|92)+1);


        (8,92) : setPromoLevel(((8<<8)|92)+1);


        (9,92) : setPromoLevel(((9<<8)|92)+1);


        (10,92) : setPromoLevel(((10<<8)|92)+1);


        (11,92) : setPromoLevel(((11<<8)|92)+1);


        (12,92) : setPromoLevel(((12<<8)|92)+1);


        (13,92) : setPromoLevel(((13<<8)|92)+1);


        (14,92) : setPromoLevel(((14<<8)|92)+1);


        (15,92) : setPromoLevel(((15<<8)|92)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 508 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,93) : setPromoLevel(((0<<8)|93)+1);


        (1,93) : setPromoLevel(((1<<8)|93)+1);


        (2,93) : setPromoLevel(((2<<8)|93)+1);


        (3,93) : setPromoLevel(((3<<8)|93)+1);


        (4,93) : setPromoLevel(((4<<8)|93)+1);


        (5,93) : setPromoLevel(((5<<8)|93)+1);


        (6,93) : setPromoLevel(((6<<8)|93)+1);


        (7,93) : setPromoLevel(((7<<8)|93)+1);


        (8,93) : setPromoLevel(((8<<8)|93)+1);


        (9,93) : setPromoLevel(((9<<8)|93)+1);


        (10,93) : setPromoLevel(((10<<8)|93)+1);


        (11,93) : setPromoLevel(((11<<8)|93)+1);


        (12,93) : setPromoLevel(((12<<8)|93)+1);


        (13,93) : setPromoLevel(((13<<8)|93)+1);


        (14,93) : setPromoLevel(((14<<8)|93)+1);


        (15,93) : setPromoLevel(((15<<8)|93)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 513 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,94) : setPromoLevel(((0<<8)|94)+1);


        (1,94) : setPromoLevel(((1<<8)|94)+1);


        (2,94) : setPromoLevel(((2<<8)|94)+1);


        (3,94) : setPromoLevel(((3<<8)|94)+1);


        (4,94) : setPromoLevel(((4<<8)|94)+1);


        (5,94) : setPromoLevel(((5<<8)|94)+1);


        (6,94) : setPromoLevel(((6<<8)|94)+1);


        (7,94) : setPromoLevel(((7<<8)|94)+1);


        (8,94) : setPromoLevel(((8<<8)|94)+1);


        (9,94) : setPromoLevel(((9<<8)|94)+1);


        (10,94) : setPromoLevel(((10<<8)|94)+1);


        (11,94) : setPromoLevel(((11<<8)|94)+1);


        (12,94) : setPromoLevel(((12<<8)|94)+1);


        (13,94) : setPromoLevel(((13<<8)|94)+1);


        (14,94) : setPromoLevel(((14<<8)|94)+1);


        (15,94) : setPromoLevel(((15<<8)|94)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 518 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,95) : setPromoLevel(((0<<8)|95)+1);


        (1,95) : setPromoLevel(((1<<8)|95)+1);


        (2,95) : setPromoLevel(((2<<8)|95)+1);


        (3,95) : setPromoLevel(((3<<8)|95)+1);


        (4,95) : setPromoLevel(((4<<8)|95)+1);


        (5,95) : setPromoLevel(((5<<8)|95)+1);


        (6,95) : setPromoLevel(((6<<8)|95)+1);


        (7,95) : setPromoLevel(((7<<8)|95)+1);


        (8,95) : setPromoLevel(((8<<8)|95)+1);


        (9,95) : setPromoLevel(((9<<8)|95)+1);


        (10,95) : setPromoLevel(((10<<8)|95)+1);


        (11,95) : setPromoLevel(((11<<8)|95)+1);


        (12,95) : setPromoLevel(((12<<8)|95)+1);


        (13,95) : setPromoLevel(((13<<8)|95)+1);


        (14,95) : setPromoLevel(((14<<8)|95)+1);


        (15,95) : setPromoLevel(((15<<8)|95)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 523 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,96) : setPromoLevel(((0<<8)|96)+1);


        (1,96) : setPromoLevel(((1<<8)|96)+1);


        (2,96) : setPromoLevel(((2<<8)|96)+1);


        (3,96) : setPromoLevel(((3<<8)|96)+1);


        (4,96) : setPromoLevel(((4<<8)|96)+1);


        (5,96) : setPromoLevel(((5<<8)|96)+1);


        (6,96) : setPromoLevel(((6<<8)|96)+1);


        (7,96) : setPromoLevel(((7<<8)|96)+1);


        (8,96) : setPromoLevel(((8<<8)|96)+1);


        (9,96) : setPromoLevel(((9<<8)|96)+1);


        (10,96) : setPromoLevel(((10<<8)|96)+1);


        (11,96) : setPromoLevel(((11<<8)|96)+1);


        (12,96) : setPromoLevel(((12<<8)|96)+1);


        (13,96) : setPromoLevel(((13<<8)|96)+1);


        (14,96) : setPromoLevel(((14<<8)|96)+1);


        (15,96) : setPromoLevel(((15<<8)|96)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 528 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,97) : setPromoLevel(((0<<8)|97)+1);


        (1,97) : setPromoLevel(((1<<8)|97)+1);


        (2,97) : setPromoLevel(((2<<8)|97)+1);


        (3,97) : setPromoLevel(((3<<8)|97)+1);


        (4,97) : setPromoLevel(((4<<8)|97)+1);


        (5,97) : setPromoLevel(((5<<8)|97)+1);


        (6,97) : setPromoLevel(((6<<8)|97)+1);


        (7,97) : setPromoLevel(((7<<8)|97)+1);


        (8,97) : setPromoLevel(((8<<8)|97)+1);


        (9,97) : setPromoLevel(((9<<8)|97)+1);


        (10,97) : setPromoLevel(((10<<8)|97)+1);


        (11,97) : setPromoLevel(((11<<8)|97)+1);


        (12,97) : setPromoLevel(((12<<8)|97)+1);


        (13,97) : setPromoLevel(((13<<8)|97)+1);


        (14,97) : setPromoLevel(((14<<8)|97)+1);


        (15,97) : setPromoLevel(((15<<8)|97)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 533 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,98) : setPromoLevel(((0<<8)|98)+1);


        (1,98) : setPromoLevel(((1<<8)|98)+1);


        (2,98) : setPromoLevel(((2<<8)|98)+1);


        (3,98) : setPromoLevel(((3<<8)|98)+1);


        (4,98) : setPromoLevel(((4<<8)|98)+1);


        (5,98) : setPromoLevel(((5<<8)|98)+1);


        (6,98) : setPromoLevel(((6<<8)|98)+1);


        (7,98) : setPromoLevel(((7<<8)|98)+1);


        (8,98) : setPromoLevel(((8<<8)|98)+1);


        (9,98) : setPromoLevel(((9<<8)|98)+1);


        (10,98) : setPromoLevel(((10<<8)|98)+1);


        (11,98) : setPromoLevel(((11<<8)|98)+1);


        (12,98) : setPromoLevel(((12<<8)|98)+1);


        (13,98) : setPromoLevel(((13<<8)|98)+1);


        (14,98) : setPromoLevel(((14<<8)|98)+1);


        (15,98) : setPromoLevel(((15<<8)|98)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 538 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,99) : setPromoLevel(((0<<8)|99)+1);


        (1,99) : setPromoLevel(((1<<8)|99)+1);


        (2,99) : setPromoLevel(((2<<8)|99)+1);


        (3,99) : setPromoLevel(((3<<8)|99)+1);


        (4,99) : setPromoLevel(((4<<8)|99)+1);


        (5,99) : setPromoLevel(((5<<8)|99)+1);


        (6,99) : setPromoLevel(((6<<8)|99)+1);


        (7,99) : setPromoLevel(((7<<8)|99)+1);


        (8,99) : setPromoLevel(((8<<8)|99)+1);


        (9,99) : setPromoLevel(((9<<8)|99)+1);


        (10,99) : setPromoLevel(((10<<8)|99)+1);


        (11,99) : setPromoLevel(((11<<8)|99)+1);


        (12,99) : setPromoLevel(((12<<8)|99)+1);


        (13,99) : setPromoLevel(((13<<8)|99)+1);


        (14,99) : setPromoLevel(((14<<8)|99)+1);


        (15,99) : setPromoLevel(((15<<8)|99)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 543 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,100) : setPromoLevel(((0<<8)|100)+1);


        (1,100) : setPromoLevel(((1<<8)|100)+1);


        (2,100) : setPromoLevel(((2<<8)|100)+1);


        (3,100) : setPromoLevel(((3<<8)|100)+1);


        (4,100) : setPromoLevel(((4<<8)|100)+1);


        (5,100) : setPromoLevel(((5<<8)|100)+1);


        (6,100) : setPromoLevel(((6<<8)|100)+1);


        (7,100) : setPromoLevel(((7<<8)|100)+1);


        (8,100) : setPromoLevel(((8<<8)|100)+1);


        (9,100) : setPromoLevel(((9<<8)|100)+1);


        (10,100) : setPromoLevel(((10<<8)|100)+1);


        (11,100) : setPromoLevel(((11<<8)|100)+1);


        (12,100) : setPromoLevel(((12<<8)|100)+1);


        (13,100) : setPromoLevel(((13<<8)|100)+1);


        (14,100) : setPromoLevel(((14<<8)|100)+1);


        (15,100) : setPromoLevel(((15<<8)|100)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 548 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,101) : setPromoLevel(((0<<8)|101)+1);


        (1,101) : setPromoLevel(((1<<8)|101)+1);


        (2,101) : setPromoLevel(((2<<8)|101)+1);


        (3,101) : setPromoLevel(((3<<8)|101)+1);


        (4,101) : setPromoLevel(((4<<8)|101)+1);


        (5,101) : setPromoLevel(((5<<8)|101)+1);


        (6,101) : setPromoLevel(((6<<8)|101)+1);


        (7,101) : setPromoLevel(((7<<8)|101)+1);


        (8,101) : setPromoLevel(((8<<8)|101)+1);


        (9,101) : setPromoLevel(((9<<8)|101)+1);


        (10,101) : setPromoLevel(((10<<8)|101)+1);


        (11,101) : setPromoLevel(((11<<8)|101)+1);


        (12,101) : setPromoLevel(((12<<8)|101)+1);


        (13,101) : setPromoLevel(((13<<8)|101)+1);


        (14,101) : setPromoLevel(((14<<8)|101)+1);


        (15,101) : setPromoLevel(((15<<8)|101)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 553 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,102) : setPromoLevel(((0<<8)|102)+1);


        (1,102) : setPromoLevel(((1<<8)|102)+1);


        (2,102) : setPromoLevel(((2<<8)|102)+1);


        (3,102) : setPromoLevel(((3<<8)|102)+1);


        (4,102) : setPromoLevel(((4<<8)|102)+1);


        (5,102) : setPromoLevel(((5<<8)|102)+1);


        (6,102) : setPromoLevel(((6<<8)|102)+1);


        (7,102) : setPromoLevel(((7<<8)|102)+1);


        (8,102) : setPromoLevel(((8<<8)|102)+1);


        (9,102) : setPromoLevel(((9<<8)|102)+1);


        (10,102) : setPromoLevel(((10<<8)|102)+1);


        (11,102) : setPromoLevel(((11<<8)|102)+1);


        (12,102) : setPromoLevel(((12<<8)|102)+1);


        (13,102) : setPromoLevel(((13<<8)|102)+1);


        (14,102) : setPromoLevel(((14<<8)|102)+1);


        (15,102) : setPromoLevel(((15<<8)|102)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 558 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,103) : setPromoLevel(((0<<8)|103)+1);


        (1,103) : setPromoLevel(((1<<8)|103)+1);


        (2,103) : setPromoLevel(((2<<8)|103)+1);


        (3,103) : setPromoLevel(((3<<8)|103)+1);


        (4,103) : setPromoLevel(((4<<8)|103)+1);


        (5,103) : setPromoLevel(((5<<8)|103)+1);


        (6,103) : setPromoLevel(((6<<8)|103)+1);


        (7,103) : setPromoLevel(((7<<8)|103)+1);


        (8,103) : setPromoLevel(((8<<8)|103)+1);


        (9,103) : setPromoLevel(((9<<8)|103)+1);


        (10,103) : setPromoLevel(((10<<8)|103)+1);


        (11,103) : setPromoLevel(((11<<8)|103)+1);


        (12,103) : setPromoLevel(((12<<8)|103)+1);


        (13,103) : setPromoLevel(((13<<8)|103)+1);


        (14,103) : setPromoLevel(((14<<8)|103)+1);


        (15,103) : setPromoLevel(((15<<8)|103)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 563 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,104) : setPromoLevel(((0<<8)|104)+1);


        (1,104) : setPromoLevel(((1<<8)|104)+1);


        (2,104) : setPromoLevel(((2<<8)|104)+1);


        (3,104) : setPromoLevel(((3<<8)|104)+1);


        (4,104) : setPromoLevel(((4<<8)|104)+1);


        (5,104) : setPromoLevel(((5<<8)|104)+1);


        (6,104) : setPromoLevel(((6<<8)|104)+1);


        (7,104) : setPromoLevel(((7<<8)|104)+1);


        (8,104) : setPromoLevel(((8<<8)|104)+1);


        (9,104) : setPromoLevel(((9<<8)|104)+1);


        (10,104) : setPromoLevel(((10<<8)|104)+1);


        (11,104) : setPromoLevel(((11<<8)|104)+1);


        (12,104) : setPromoLevel(((12<<8)|104)+1);


        (13,104) : setPromoLevel(((13<<8)|104)+1);


        (14,104) : setPromoLevel(((14<<8)|104)+1);


        (15,104) : setPromoLevel(((15<<8)|104)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 568 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,105) : setPromoLevel(((0<<8)|105)+1);


        (1,105) : setPromoLevel(((1<<8)|105)+1);


        (2,105) : setPromoLevel(((2<<8)|105)+1);


        (3,105) : setPromoLevel(((3<<8)|105)+1);


        (4,105) : setPromoLevel(((4<<8)|105)+1);


        (5,105) : setPromoLevel(((5<<8)|105)+1);


        (6,105) : setPromoLevel(((6<<8)|105)+1);


        (7,105) : setPromoLevel(((7<<8)|105)+1);


        (8,105) : setPromoLevel(((8<<8)|105)+1);


        (9,105) : setPromoLevel(((9<<8)|105)+1);


        (10,105) : setPromoLevel(((10<<8)|105)+1);


        (11,105) : setPromoLevel(((11<<8)|105)+1);


        (12,105) : setPromoLevel(((12<<8)|105)+1);


        (13,105) : setPromoLevel(((13<<8)|105)+1);


        (14,105) : setPromoLevel(((14<<8)|105)+1);


        (15,105) : setPromoLevel(((15<<8)|105)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 573 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,106) : setPromoLevel(((0<<8)|106)+1);


        (1,106) : setPromoLevel(((1<<8)|106)+1);


        (2,106) : setPromoLevel(((2<<8)|106)+1);


        (3,106) : setPromoLevel(((3<<8)|106)+1);


        (4,106) : setPromoLevel(((4<<8)|106)+1);


        (5,106) : setPromoLevel(((5<<8)|106)+1);


        (6,106) : setPromoLevel(((6<<8)|106)+1);


        (7,106) : setPromoLevel(((7<<8)|106)+1);


        (8,106) : setPromoLevel(((8<<8)|106)+1);


        (9,106) : setPromoLevel(((9<<8)|106)+1);


        (10,106) : setPromoLevel(((10<<8)|106)+1);


        (11,106) : setPromoLevel(((11<<8)|106)+1);


        (12,106) : setPromoLevel(((12<<8)|106)+1);


        (13,106) : setPromoLevel(((13<<8)|106)+1);


        (14,106) : setPromoLevel(((14<<8)|106)+1);


        (15,106) : setPromoLevel(((15<<8)|106)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 578 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,107) : setPromoLevel(((0<<8)|107)+1);


        (1,107) : setPromoLevel(((1<<8)|107)+1);


        (2,107) : setPromoLevel(((2<<8)|107)+1);


        (3,107) : setPromoLevel(((3<<8)|107)+1);


        (4,107) : setPromoLevel(((4<<8)|107)+1);


        (5,107) : setPromoLevel(((5<<8)|107)+1);


        (6,107) : setPromoLevel(((6<<8)|107)+1);


        (7,107) : setPromoLevel(((7<<8)|107)+1);


        (8,107) : setPromoLevel(((8<<8)|107)+1);


        (9,107) : setPromoLevel(((9<<8)|107)+1);


        (10,107) : setPromoLevel(((10<<8)|107)+1);


        (11,107) : setPromoLevel(((11<<8)|107)+1);


        (12,107) : setPromoLevel(((12<<8)|107)+1);


        (13,107) : setPromoLevel(((13<<8)|107)+1);


        (14,107) : setPromoLevel(((14<<8)|107)+1);


        (15,107) : setPromoLevel(((15<<8)|107)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 583 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,108) : setPromoLevel(((0<<8)|108)+1);


        (1,108) : setPromoLevel(((1<<8)|108)+1);


        (2,108) : setPromoLevel(((2<<8)|108)+1);


        (3,108) : setPromoLevel(((3<<8)|108)+1);


        (4,108) : setPromoLevel(((4<<8)|108)+1);


        (5,108) : setPromoLevel(((5<<8)|108)+1);


        (6,108) : setPromoLevel(((6<<8)|108)+1);


        (7,108) : setPromoLevel(((7<<8)|108)+1);


        (8,108) : setPromoLevel(((8<<8)|108)+1);


        (9,108) : setPromoLevel(((9<<8)|108)+1);


        (10,108) : setPromoLevel(((10<<8)|108)+1);


        (11,108) : setPromoLevel(((11<<8)|108)+1);


        (12,108) : setPromoLevel(((12<<8)|108)+1);


        (13,108) : setPromoLevel(((13<<8)|108)+1);


        (14,108) : setPromoLevel(((14<<8)|108)+1);


        (15,108) : setPromoLevel(((15<<8)|108)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 588 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,109) : setPromoLevel(((0<<8)|109)+1);


        (1,109) : setPromoLevel(((1<<8)|109)+1);


        (2,109) : setPromoLevel(((2<<8)|109)+1);


        (3,109) : setPromoLevel(((3<<8)|109)+1);


        (4,109) : setPromoLevel(((4<<8)|109)+1);


        (5,109) : setPromoLevel(((5<<8)|109)+1);


        (6,109) : setPromoLevel(((6<<8)|109)+1);


        (7,109) : setPromoLevel(((7<<8)|109)+1);


        (8,109) : setPromoLevel(((8<<8)|109)+1);


        (9,109) : setPromoLevel(((9<<8)|109)+1);


        (10,109) : setPromoLevel(((10<<8)|109)+1);


        (11,109) : setPromoLevel(((11<<8)|109)+1);


        (12,109) : setPromoLevel(((12<<8)|109)+1);


        (13,109) : setPromoLevel(((13<<8)|109)+1);


        (14,109) : setPromoLevel(((14<<8)|109)+1);


        (15,109) : setPromoLevel(((15<<8)|109)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 593 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,110) : setPromoLevel(((0<<8)|110)+1);


        (1,110) : setPromoLevel(((1<<8)|110)+1);


        (2,110) : setPromoLevel(((2<<8)|110)+1);


        (3,110) : setPromoLevel(((3<<8)|110)+1);


        (4,110) : setPromoLevel(((4<<8)|110)+1);


        (5,110) : setPromoLevel(((5<<8)|110)+1);


        (6,110) : setPromoLevel(((6<<8)|110)+1);


        (7,110) : setPromoLevel(((7<<8)|110)+1);


        (8,110) : setPromoLevel(((8<<8)|110)+1);


        (9,110) : setPromoLevel(((9<<8)|110)+1);


        (10,110) : setPromoLevel(((10<<8)|110)+1);


        (11,110) : setPromoLevel(((11<<8)|110)+1);


        (12,110) : setPromoLevel(((12<<8)|110)+1);


        (13,110) : setPromoLevel(((13<<8)|110)+1);


        (14,110) : setPromoLevel(((14<<8)|110)+1);


        (15,110) : setPromoLevel(((15<<8)|110)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 598 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,111) : setPromoLevel(((0<<8)|111)+1);


        (1,111) : setPromoLevel(((1<<8)|111)+1);


        (2,111) : setPromoLevel(((2<<8)|111)+1);


        (3,111) : setPromoLevel(((3<<8)|111)+1);


        (4,111) : setPromoLevel(((4<<8)|111)+1);


        (5,111) : setPromoLevel(((5<<8)|111)+1);


        (6,111) : setPromoLevel(((6<<8)|111)+1);


        (7,111) : setPromoLevel(((7<<8)|111)+1);


        (8,111) : setPromoLevel(((8<<8)|111)+1);


        (9,111) : setPromoLevel(((9<<8)|111)+1);


        (10,111) : setPromoLevel(((10<<8)|111)+1);


        (11,111) : setPromoLevel(((11<<8)|111)+1);


        (12,111) : setPromoLevel(((12<<8)|111)+1);


        (13,111) : setPromoLevel(((13<<8)|111)+1);


        (14,111) : setPromoLevel(((14<<8)|111)+1);


        (15,111) : setPromoLevel(((15<<8)|111)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 603 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,112) : setPromoLevel(((0<<8)|112)+1);


        (1,112) : setPromoLevel(((1<<8)|112)+1);


        (2,112) : setPromoLevel(((2<<8)|112)+1);


        (3,112) : setPromoLevel(((3<<8)|112)+1);


        (4,112) : setPromoLevel(((4<<8)|112)+1);


        (5,112) : setPromoLevel(((5<<8)|112)+1);


        (6,112) : setPromoLevel(((6<<8)|112)+1);


        (7,112) : setPromoLevel(((7<<8)|112)+1);


        (8,112) : setPromoLevel(((8<<8)|112)+1);


        (9,112) : setPromoLevel(((9<<8)|112)+1);


        (10,112) : setPromoLevel(((10<<8)|112)+1);


        (11,112) : setPromoLevel(((11<<8)|112)+1);


        (12,112) : setPromoLevel(((12<<8)|112)+1);


        (13,112) : setPromoLevel(((13<<8)|112)+1);


        (14,112) : setPromoLevel(((14<<8)|112)+1);


        (15,112) : setPromoLevel(((15<<8)|112)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 608 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,113) : setPromoLevel(((0<<8)|113)+1);


        (1,113) : setPromoLevel(((1<<8)|113)+1);


        (2,113) : setPromoLevel(((2<<8)|113)+1);


        (3,113) : setPromoLevel(((3<<8)|113)+1);


        (4,113) : setPromoLevel(((4<<8)|113)+1);


        (5,113) : setPromoLevel(((5<<8)|113)+1);


        (6,113) : setPromoLevel(((6<<8)|113)+1);


        (7,113) : setPromoLevel(((7<<8)|113)+1);


        (8,113) : setPromoLevel(((8<<8)|113)+1);


        (9,113) : setPromoLevel(((9<<8)|113)+1);


        (10,113) : setPromoLevel(((10<<8)|113)+1);


        (11,113) : setPromoLevel(((11<<8)|113)+1);


        (12,113) : setPromoLevel(((12<<8)|113)+1);


        (13,113) : setPromoLevel(((13<<8)|113)+1);


        (14,113) : setPromoLevel(((14<<8)|113)+1);


        (15,113) : setPromoLevel(((15<<8)|113)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 613 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,114) : setPromoLevel(((0<<8)|114)+1);


        (1,114) : setPromoLevel(((1<<8)|114)+1);


        (2,114) : setPromoLevel(((2<<8)|114)+1);


        (3,114) : setPromoLevel(((3<<8)|114)+1);


        (4,114) : setPromoLevel(((4<<8)|114)+1);


        (5,114) : setPromoLevel(((5<<8)|114)+1);


        (6,114) : setPromoLevel(((6<<8)|114)+1);


        (7,114) : setPromoLevel(((7<<8)|114)+1);


        (8,114) : setPromoLevel(((8<<8)|114)+1);


        (9,114) : setPromoLevel(((9<<8)|114)+1);


        (10,114) : setPromoLevel(((10<<8)|114)+1);


        (11,114) : setPromoLevel(((11<<8)|114)+1);


        (12,114) : setPromoLevel(((12<<8)|114)+1);


        (13,114) : setPromoLevel(((13<<8)|114)+1);


        (14,114) : setPromoLevel(((14<<8)|114)+1);


        (15,114) : setPromoLevel(((15<<8)|114)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 618 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,115) : setPromoLevel(((0<<8)|115)+1);


        (1,115) : setPromoLevel(((1<<8)|115)+1);


        (2,115) : setPromoLevel(((2<<8)|115)+1);


        (3,115) : setPromoLevel(((3<<8)|115)+1);


        (4,115) : setPromoLevel(((4<<8)|115)+1);


        (5,115) : setPromoLevel(((5<<8)|115)+1);


        (6,115) : setPromoLevel(((6<<8)|115)+1);


        (7,115) : setPromoLevel(((7<<8)|115)+1);


        (8,115) : setPromoLevel(((8<<8)|115)+1);


        (9,115) : setPromoLevel(((9<<8)|115)+1);


        (10,115) : setPromoLevel(((10<<8)|115)+1);


        (11,115) : setPromoLevel(((11<<8)|115)+1);


        (12,115) : setPromoLevel(((12<<8)|115)+1);


        (13,115) : setPromoLevel(((13<<8)|115)+1);


        (14,115) : setPromoLevel(((14<<8)|115)+1);


        (15,115) : setPromoLevel(((15<<8)|115)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 623 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,116) : setPromoLevel(((0<<8)|116)+1);


        (1,116) : setPromoLevel(((1<<8)|116)+1);


        (2,116) : setPromoLevel(((2<<8)|116)+1);


        (3,116) : setPromoLevel(((3<<8)|116)+1);


        (4,116) : setPromoLevel(((4<<8)|116)+1);


        (5,116) : setPromoLevel(((5<<8)|116)+1);


        (6,116) : setPromoLevel(((6<<8)|116)+1);


        (7,116) : setPromoLevel(((7<<8)|116)+1);


        (8,116) : setPromoLevel(((8<<8)|116)+1);


        (9,116) : setPromoLevel(((9<<8)|116)+1);


        (10,116) : setPromoLevel(((10<<8)|116)+1);


        (11,116) : setPromoLevel(((11<<8)|116)+1);


        (12,116) : setPromoLevel(((12<<8)|116)+1);


        (13,116) : setPromoLevel(((13<<8)|116)+1);


        (14,116) : setPromoLevel(((14<<8)|116)+1);


        (15,116) : setPromoLevel(((15<<8)|116)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 628 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,117) : setPromoLevel(((0<<8)|117)+1);


        (1,117) : setPromoLevel(((1<<8)|117)+1);


        (2,117) : setPromoLevel(((2<<8)|117)+1);


        (3,117) : setPromoLevel(((3<<8)|117)+1);


        (4,117) : setPromoLevel(((4<<8)|117)+1);


        (5,117) : setPromoLevel(((5<<8)|117)+1);


        (6,117) : setPromoLevel(((6<<8)|117)+1);


        (7,117) : setPromoLevel(((7<<8)|117)+1);


        (8,117) : setPromoLevel(((8<<8)|117)+1);


        (9,117) : setPromoLevel(((9<<8)|117)+1);


        (10,117) : setPromoLevel(((10<<8)|117)+1);


        (11,117) : setPromoLevel(((11<<8)|117)+1);


        (12,117) : setPromoLevel(((12<<8)|117)+1);


        (13,117) : setPromoLevel(((13<<8)|117)+1);


        (14,117) : setPromoLevel(((14<<8)|117)+1);


        (15,117) : setPromoLevel(((15<<8)|117)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 633 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,118) : setPromoLevel(((0<<8)|118)+1);


        (1,118) : setPromoLevel(((1<<8)|118)+1);


        (2,118) : setPromoLevel(((2<<8)|118)+1);


        (3,118) : setPromoLevel(((3<<8)|118)+1);


        (4,118) : setPromoLevel(((4<<8)|118)+1);


        (5,118) : setPromoLevel(((5<<8)|118)+1);


        (6,118) : setPromoLevel(((6<<8)|118)+1);


        (7,118) : setPromoLevel(((7<<8)|118)+1);


        (8,118) : setPromoLevel(((8<<8)|118)+1);


        (9,118) : setPromoLevel(((9<<8)|118)+1);


        (10,118) : setPromoLevel(((10<<8)|118)+1);


        (11,118) : setPromoLevel(((11<<8)|118)+1);


        (12,118) : setPromoLevel(((12<<8)|118)+1);


        (13,118) : setPromoLevel(((13<<8)|118)+1);


        (14,118) : setPromoLevel(((14<<8)|118)+1);


        (15,118) : setPromoLevel(((15<<8)|118)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 638 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,119) : setPromoLevel(((0<<8)|119)+1);


        (1,119) : setPromoLevel(((1<<8)|119)+1);


        (2,119) : setPromoLevel(((2<<8)|119)+1);


        (3,119) : setPromoLevel(((3<<8)|119)+1);


        (4,119) : setPromoLevel(((4<<8)|119)+1);


        (5,119) : setPromoLevel(((5<<8)|119)+1);


        (6,119) : setPromoLevel(((6<<8)|119)+1);


        (7,119) : setPromoLevel(((7<<8)|119)+1);


        (8,119) : setPromoLevel(((8<<8)|119)+1);


        (9,119) : setPromoLevel(((9<<8)|119)+1);


        (10,119) : setPromoLevel(((10<<8)|119)+1);


        (11,119) : setPromoLevel(((11<<8)|119)+1);


        (12,119) : setPromoLevel(((12<<8)|119)+1);


        (13,119) : setPromoLevel(((13<<8)|119)+1);


        (14,119) : setPromoLevel(((14<<8)|119)+1);


        (15,119) : setPromoLevel(((15<<8)|119)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 643 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,120) : setPromoLevel(((0<<8)|120)+1);


        (1,120) : setPromoLevel(((1<<8)|120)+1);


        (2,120) : setPromoLevel(((2<<8)|120)+1);


        (3,120) : setPromoLevel(((3<<8)|120)+1);


        (4,120) : setPromoLevel(((4<<8)|120)+1);


        (5,120) : setPromoLevel(((5<<8)|120)+1);


        (6,120) : setPromoLevel(((6<<8)|120)+1);


        (7,120) : setPromoLevel(((7<<8)|120)+1);


        (8,120) : setPromoLevel(((8<<8)|120)+1);


        (9,120) : setPromoLevel(((9<<8)|120)+1);


        (10,120) : setPromoLevel(((10<<8)|120)+1);


        (11,120) : setPromoLevel(((11<<8)|120)+1);


        (12,120) : setPromoLevel(((12<<8)|120)+1);


        (13,120) : setPromoLevel(((13<<8)|120)+1);


        (14,120) : setPromoLevel(((14<<8)|120)+1);


        (15,120) : setPromoLevel(((15<<8)|120)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 648 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,121) : setPromoLevel(((0<<8)|121)+1);


        (1,121) : setPromoLevel(((1<<8)|121)+1);


        (2,121) : setPromoLevel(((2<<8)|121)+1);


        (3,121) : setPromoLevel(((3<<8)|121)+1);


        (4,121) : setPromoLevel(((4<<8)|121)+1);


        (5,121) : setPromoLevel(((5<<8)|121)+1);


        (6,121) : setPromoLevel(((6<<8)|121)+1);


        (7,121) : setPromoLevel(((7<<8)|121)+1);


        (8,121) : setPromoLevel(((8<<8)|121)+1);


        (9,121) : setPromoLevel(((9<<8)|121)+1);


        (10,121) : setPromoLevel(((10<<8)|121)+1);


        (11,121) : setPromoLevel(((11<<8)|121)+1);


        (12,121) : setPromoLevel(((12<<8)|121)+1);


        (13,121) : setPromoLevel(((13<<8)|121)+1);


        (14,121) : setPromoLevel(((14<<8)|121)+1);


        (15,121) : setPromoLevel(((15<<8)|121)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 653 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,122) : setPromoLevel(((0<<8)|122)+1);


        (1,122) : setPromoLevel(((1<<8)|122)+1);


        (2,122) : setPromoLevel(((2<<8)|122)+1);


        (3,122) : setPromoLevel(((3<<8)|122)+1);


        (4,122) : setPromoLevel(((4<<8)|122)+1);


        (5,122) : setPromoLevel(((5<<8)|122)+1);


        (6,122) : setPromoLevel(((6<<8)|122)+1);


        (7,122) : setPromoLevel(((7<<8)|122)+1);


        (8,122) : setPromoLevel(((8<<8)|122)+1);


        (9,122) : setPromoLevel(((9<<8)|122)+1);


        (10,122) : setPromoLevel(((10<<8)|122)+1);


        (11,122) : setPromoLevel(((11<<8)|122)+1);


        (12,122) : setPromoLevel(((12<<8)|122)+1);


        (13,122) : setPromoLevel(((13<<8)|122)+1);


        (14,122) : setPromoLevel(((14<<8)|122)+1);


        (15,122) : setPromoLevel(((15<<8)|122)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 658 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,123) : setPromoLevel(((0<<8)|123)+1);


        (1,123) : setPromoLevel(((1<<8)|123)+1);


        (2,123) : setPromoLevel(((2<<8)|123)+1);


        (3,123) : setPromoLevel(((3<<8)|123)+1);


        (4,123) : setPromoLevel(((4<<8)|123)+1);


        (5,123) : setPromoLevel(((5<<8)|123)+1);


        (6,123) : setPromoLevel(((6<<8)|123)+1);


        (7,123) : setPromoLevel(((7<<8)|123)+1);


        (8,123) : setPromoLevel(((8<<8)|123)+1);


        (9,123) : setPromoLevel(((9<<8)|123)+1);


        (10,123) : setPromoLevel(((10<<8)|123)+1);


        (11,123) : setPromoLevel(((11<<8)|123)+1);


        (12,123) : setPromoLevel(((12<<8)|123)+1);


        (13,123) : setPromoLevel(((13<<8)|123)+1);


        (14,123) : setPromoLevel(((14<<8)|123)+1);


        (15,123) : setPromoLevel(((15<<8)|123)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 663 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,124) : setPromoLevel(((0<<8)|124)+1);


        (1,124) : setPromoLevel(((1<<8)|124)+1);


        (2,124) : setPromoLevel(((2<<8)|124)+1);


        (3,124) : setPromoLevel(((3<<8)|124)+1);


        (4,124) : setPromoLevel(((4<<8)|124)+1);


        (5,124) : setPromoLevel(((5<<8)|124)+1);


        (6,124) : setPromoLevel(((6<<8)|124)+1);


        (7,124) : setPromoLevel(((7<<8)|124)+1);


        (8,124) : setPromoLevel(((8<<8)|124)+1);


        (9,124) : setPromoLevel(((9<<8)|124)+1);


        (10,124) : setPromoLevel(((10<<8)|124)+1);


        (11,124) : setPromoLevel(((11<<8)|124)+1);


        (12,124) : setPromoLevel(((12<<8)|124)+1);


        (13,124) : setPromoLevel(((13<<8)|124)+1);


        (14,124) : setPromoLevel(((14<<8)|124)+1);


        (15,124) : setPromoLevel(((15<<8)|124)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 668 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,125) : setPromoLevel(((0<<8)|125)+1);


        (1,125) : setPromoLevel(((1<<8)|125)+1);


        (2,125) : setPromoLevel(((2<<8)|125)+1);


        (3,125) : setPromoLevel(((3<<8)|125)+1);


        (4,125) : setPromoLevel(((4<<8)|125)+1);


        (5,125) : setPromoLevel(((5<<8)|125)+1);


        (6,125) : setPromoLevel(((6<<8)|125)+1);


        (7,125) : setPromoLevel(((7<<8)|125)+1);


        (8,125) : setPromoLevel(((8<<8)|125)+1);


        (9,125) : setPromoLevel(((9<<8)|125)+1);


        (10,125) : setPromoLevel(((10<<8)|125)+1);


        (11,125) : setPromoLevel(((11<<8)|125)+1);


        (12,125) : setPromoLevel(((12<<8)|125)+1);


        (13,125) : setPromoLevel(((13<<8)|125)+1);


        (14,125) : setPromoLevel(((14<<8)|125)+1);


        (15,125) : setPromoLevel(((15<<8)|125)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 673 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,126) : setPromoLevel(((0<<8)|126)+1);


        (1,126) : setPromoLevel(((1<<8)|126)+1);


        (2,126) : setPromoLevel(((2<<8)|126)+1);


        (3,126) : setPromoLevel(((3<<8)|126)+1);


        (4,126) : setPromoLevel(((4<<8)|126)+1);


        (5,126) : setPromoLevel(((5<<8)|126)+1);


        (6,126) : setPromoLevel(((6<<8)|126)+1);


        (7,126) : setPromoLevel(((7<<8)|126)+1);


        (8,126) : setPromoLevel(((8<<8)|126)+1);


        (9,126) : setPromoLevel(((9<<8)|126)+1);


        (10,126) : setPromoLevel(((10<<8)|126)+1);


        (11,126) : setPromoLevel(((11<<8)|126)+1);


        (12,126) : setPromoLevel(((12<<8)|126)+1);


        (13,126) : setPromoLevel(((13<<8)|126)+1);


        (14,126) : setPromoLevel(((14<<8)|126)+1);


        (15,126) : setPromoLevel(((15<<8)|126)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 678 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,127) : setPromoLevel(((0<<8)|127)+1);


        (1,127) : setPromoLevel(((1<<8)|127)+1);


        (2,127) : setPromoLevel(((2<<8)|127)+1);


        (3,127) : setPromoLevel(((3<<8)|127)+1);


        (4,127) : setPromoLevel(((4<<8)|127)+1);


        (5,127) : setPromoLevel(((5<<8)|127)+1);


        (6,127) : setPromoLevel(((6<<8)|127)+1);


        (7,127) : setPromoLevel(((7<<8)|127)+1);


        (8,127) : setPromoLevel(((8<<8)|127)+1);


        (9,127) : setPromoLevel(((9<<8)|127)+1);


        (10,127) : setPromoLevel(((10<<8)|127)+1);


        (11,127) : setPromoLevel(((11<<8)|127)+1);


        (12,127) : setPromoLevel(((12<<8)|127)+1);


        (13,127) : setPromoLevel(((13<<8)|127)+1);


        (14,127) : setPromoLevel(((14<<8)|127)+1);


        (15,127) : setPromoLevel(((15<<8)|127)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 683 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,128) : setPromoLevel(((0<<8)|128)+1);


        (1,128) : setPromoLevel(((1<<8)|128)+1);


        (2,128) : setPromoLevel(((2<<8)|128)+1);


        (3,128) : setPromoLevel(((3<<8)|128)+1);


        (4,128) : setPromoLevel(((4<<8)|128)+1);


        (5,128) : setPromoLevel(((5<<8)|128)+1);


        (6,128) : setPromoLevel(((6<<8)|128)+1);


        (7,128) : setPromoLevel(((7<<8)|128)+1);


        (8,128) : setPromoLevel(((8<<8)|128)+1);


        (9,128) : setPromoLevel(((9<<8)|128)+1);


        (10,128) : setPromoLevel(((10<<8)|128)+1);


        (11,128) : setPromoLevel(((11<<8)|128)+1);


        (12,128) : setPromoLevel(((12<<8)|128)+1);


        (13,128) : setPromoLevel(((13<<8)|128)+1);


        (14,128) : setPromoLevel(((14<<8)|128)+1);


        (15,128) : setPromoLevel(((15<<8)|128)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 688 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,129) : setPromoLevel(((0<<8)|129)+1);


        (1,129) : setPromoLevel(((1<<8)|129)+1);


        (2,129) : setPromoLevel(((2<<8)|129)+1);


        (3,129) : setPromoLevel(((3<<8)|129)+1);


        (4,129) : setPromoLevel(((4<<8)|129)+1);


        (5,129) : setPromoLevel(((5<<8)|129)+1);


        (6,129) : setPromoLevel(((6<<8)|129)+1);


        (7,129) : setPromoLevel(((7<<8)|129)+1);


        (8,129) : setPromoLevel(((8<<8)|129)+1);


        (9,129) : setPromoLevel(((9<<8)|129)+1);


        (10,129) : setPromoLevel(((10<<8)|129)+1);


        (11,129) : setPromoLevel(((11<<8)|129)+1);


        (12,129) : setPromoLevel(((12<<8)|129)+1);


        (13,129) : setPromoLevel(((13<<8)|129)+1);


        (14,129) : setPromoLevel(((14<<8)|129)+1);


        (15,129) : setPromoLevel(((15<<8)|129)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 693 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,130) : setPromoLevel(((0<<8)|130)+1);


        (1,130) : setPromoLevel(((1<<8)|130)+1);


        (2,130) : setPromoLevel(((2<<8)|130)+1);


        (3,130) : setPromoLevel(((3<<8)|130)+1);


        (4,130) : setPromoLevel(((4<<8)|130)+1);


        (5,130) : setPromoLevel(((5<<8)|130)+1);


        (6,130) : setPromoLevel(((6<<8)|130)+1);


        (7,130) : setPromoLevel(((7<<8)|130)+1);


        (8,130) : setPromoLevel(((8<<8)|130)+1);


        (9,130) : setPromoLevel(((9<<8)|130)+1);


        (10,130) : setPromoLevel(((10<<8)|130)+1);


        (11,130) : setPromoLevel(((11<<8)|130)+1);


        (12,130) : setPromoLevel(((12<<8)|130)+1);


        (13,130) : setPromoLevel(((13<<8)|130)+1);


        (14,130) : setPromoLevel(((14<<8)|130)+1);


        (15,130) : setPromoLevel(((15<<8)|130)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 698 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,131) : setPromoLevel(((0<<8)|131)+1);


        (1,131) : setPromoLevel(((1<<8)|131)+1);


        (2,131) : setPromoLevel(((2<<8)|131)+1);


        (3,131) : setPromoLevel(((3<<8)|131)+1);


        (4,131) : setPromoLevel(((4<<8)|131)+1);


        (5,131) : setPromoLevel(((5<<8)|131)+1);


        (6,131) : setPromoLevel(((6<<8)|131)+1);


        (7,131) : setPromoLevel(((7<<8)|131)+1);


        (8,131) : setPromoLevel(((8<<8)|131)+1);


        (9,131) : setPromoLevel(((9<<8)|131)+1);


        (10,131) : setPromoLevel(((10<<8)|131)+1);


        (11,131) : setPromoLevel(((11<<8)|131)+1);


        (12,131) : setPromoLevel(((12<<8)|131)+1);


        (13,131) : setPromoLevel(((13<<8)|131)+1);


        (14,131) : setPromoLevel(((14<<8)|131)+1);


        (15,131) : setPromoLevel(((15<<8)|131)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 703 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,132) : setPromoLevel(((0<<8)|132)+1);


        (1,132) : setPromoLevel(((1<<8)|132)+1);


        (2,132) : setPromoLevel(((2<<8)|132)+1);


        (3,132) : setPromoLevel(((3<<8)|132)+1);


        (4,132) : setPromoLevel(((4<<8)|132)+1);


        (5,132) : setPromoLevel(((5<<8)|132)+1);


        (6,132) : setPromoLevel(((6<<8)|132)+1);


        (7,132) : setPromoLevel(((7<<8)|132)+1);


        (8,132) : setPromoLevel(((8<<8)|132)+1);


        (9,132) : setPromoLevel(((9<<8)|132)+1);


        (10,132) : setPromoLevel(((10<<8)|132)+1);


        (11,132) : setPromoLevel(((11<<8)|132)+1);


        (12,132) : setPromoLevel(((12<<8)|132)+1);


        (13,132) : setPromoLevel(((13<<8)|132)+1);


        (14,132) : setPromoLevel(((14<<8)|132)+1);


        (15,132) : setPromoLevel(((15<<8)|132)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 708 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,133) : setPromoLevel(((0<<8)|133)+1);


        (1,133) : setPromoLevel(((1<<8)|133)+1);


        (2,133) : setPromoLevel(((2<<8)|133)+1);


        (3,133) : setPromoLevel(((3<<8)|133)+1);


        (4,133) : setPromoLevel(((4<<8)|133)+1);


        (5,133) : setPromoLevel(((5<<8)|133)+1);


        (6,133) : setPromoLevel(((6<<8)|133)+1);


        (7,133) : setPromoLevel(((7<<8)|133)+1);


        (8,133) : setPromoLevel(((8<<8)|133)+1);


        (9,133) : setPromoLevel(((9<<8)|133)+1);


        (10,133) : setPromoLevel(((10<<8)|133)+1);


        (11,133) : setPromoLevel(((11<<8)|133)+1);


        (12,133) : setPromoLevel(((12<<8)|133)+1);


        (13,133) : setPromoLevel(((13<<8)|133)+1);


        (14,133) : setPromoLevel(((14<<8)|133)+1);


        (15,133) : setPromoLevel(((15<<8)|133)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 713 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,134) : setPromoLevel(((0<<8)|134)+1);


        (1,134) : setPromoLevel(((1<<8)|134)+1);


        (2,134) : setPromoLevel(((2<<8)|134)+1);


        (3,134) : setPromoLevel(((3<<8)|134)+1);


        (4,134) : setPromoLevel(((4<<8)|134)+1);


        (5,134) : setPromoLevel(((5<<8)|134)+1);


        (6,134) : setPromoLevel(((6<<8)|134)+1);


        (7,134) : setPromoLevel(((7<<8)|134)+1);


        (8,134) : setPromoLevel(((8<<8)|134)+1);


        (9,134) : setPromoLevel(((9<<8)|134)+1);


        (10,134) : setPromoLevel(((10<<8)|134)+1);


        (11,134) : setPromoLevel(((11<<8)|134)+1);


        (12,134) : setPromoLevel(((12<<8)|134)+1);


        (13,134) : setPromoLevel(((13<<8)|134)+1);


        (14,134) : setPromoLevel(((14<<8)|134)+1);


        (15,134) : setPromoLevel(((15<<8)|134)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 718 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,135) : setPromoLevel(((0<<8)|135)+1);


        (1,135) : setPromoLevel(((1<<8)|135)+1);


        (2,135) : setPromoLevel(((2<<8)|135)+1);


        (3,135) : setPromoLevel(((3<<8)|135)+1);


        (4,135) : setPromoLevel(((4<<8)|135)+1);


        (5,135) : setPromoLevel(((5<<8)|135)+1);


        (6,135) : setPromoLevel(((6<<8)|135)+1);


        (7,135) : setPromoLevel(((7<<8)|135)+1);


        (8,135) : setPromoLevel(((8<<8)|135)+1);


        (9,135) : setPromoLevel(((9<<8)|135)+1);


        (10,135) : setPromoLevel(((10<<8)|135)+1);


        (11,135) : setPromoLevel(((11<<8)|135)+1);


        (12,135) : setPromoLevel(((12<<8)|135)+1);


        (13,135) : setPromoLevel(((13<<8)|135)+1);


        (14,135) : setPromoLevel(((14<<8)|135)+1);


        (15,135) : setPromoLevel(((15<<8)|135)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 723 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,136) : setPromoLevel(((0<<8)|136)+1);


        (1,136) : setPromoLevel(((1<<8)|136)+1);


        (2,136) : setPromoLevel(((2<<8)|136)+1);


        (3,136) : setPromoLevel(((3<<8)|136)+1);


        (4,136) : setPromoLevel(((4<<8)|136)+1);


        (5,136) : setPromoLevel(((5<<8)|136)+1);


        (6,136) : setPromoLevel(((6<<8)|136)+1);


        (7,136) : setPromoLevel(((7<<8)|136)+1);


        (8,136) : setPromoLevel(((8<<8)|136)+1);


        (9,136) : setPromoLevel(((9<<8)|136)+1);


        (10,136) : setPromoLevel(((10<<8)|136)+1);


        (11,136) : setPromoLevel(((11<<8)|136)+1);


        (12,136) : setPromoLevel(((12<<8)|136)+1);


        (13,136) : setPromoLevel(((13<<8)|136)+1);


        (14,136) : setPromoLevel(((14<<8)|136)+1);


        (15,136) : setPromoLevel(((15<<8)|136)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 728 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,137) : setPromoLevel(((0<<8)|137)+1);


        (1,137) : setPromoLevel(((1<<8)|137)+1);


        (2,137) : setPromoLevel(((2<<8)|137)+1);


        (3,137) : setPromoLevel(((3<<8)|137)+1);


        (4,137) : setPromoLevel(((4<<8)|137)+1);


        (5,137) : setPromoLevel(((5<<8)|137)+1);


        (6,137) : setPromoLevel(((6<<8)|137)+1);


        (7,137) : setPromoLevel(((7<<8)|137)+1);


        (8,137) : setPromoLevel(((8<<8)|137)+1);


        (9,137) : setPromoLevel(((9<<8)|137)+1);


        (10,137) : setPromoLevel(((10<<8)|137)+1);


        (11,137) : setPromoLevel(((11<<8)|137)+1);


        (12,137) : setPromoLevel(((12<<8)|137)+1);


        (13,137) : setPromoLevel(((13<<8)|137)+1);


        (14,137) : setPromoLevel(((14<<8)|137)+1);


        (15,137) : setPromoLevel(((15<<8)|137)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 733 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,138) : setPromoLevel(((0<<8)|138)+1);


        (1,138) : setPromoLevel(((1<<8)|138)+1);


        (2,138) : setPromoLevel(((2<<8)|138)+1);


        (3,138) : setPromoLevel(((3<<8)|138)+1);


        (4,138) : setPromoLevel(((4<<8)|138)+1);


        (5,138) : setPromoLevel(((5<<8)|138)+1);


        (6,138) : setPromoLevel(((6<<8)|138)+1);


        (7,138) : setPromoLevel(((7<<8)|138)+1);


        (8,138) : setPromoLevel(((8<<8)|138)+1);


        (9,138) : setPromoLevel(((9<<8)|138)+1);


        (10,138) : setPromoLevel(((10<<8)|138)+1);


        (11,138) : setPromoLevel(((11<<8)|138)+1);


        (12,138) : setPromoLevel(((12<<8)|138)+1);


        (13,138) : setPromoLevel(((13<<8)|138)+1);


        (14,138) : setPromoLevel(((14<<8)|138)+1);


        (15,138) : setPromoLevel(((15<<8)|138)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 738 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,139) : setPromoLevel(((0<<8)|139)+1);


        (1,139) : setPromoLevel(((1<<8)|139)+1);


        (2,139) : setPromoLevel(((2<<8)|139)+1);


        (3,139) : setPromoLevel(((3<<8)|139)+1);


        (4,139) : setPromoLevel(((4<<8)|139)+1);


        (5,139) : setPromoLevel(((5<<8)|139)+1);


        (6,139) : setPromoLevel(((6<<8)|139)+1);


        (7,139) : setPromoLevel(((7<<8)|139)+1);


        (8,139) : setPromoLevel(((8<<8)|139)+1);


        (9,139) : setPromoLevel(((9<<8)|139)+1);


        (10,139) : setPromoLevel(((10<<8)|139)+1);


        (11,139) : setPromoLevel(((11<<8)|139)+1);


        (12,139) : setPromoLevel(((12<<8)|139)+1);


        (13,139) : setPromoLevel(((13<<8)|139)+1);


        (14,139) : setPromoLevel(((14<<8)|139)+1);


        (15,139) : setPromoLevel(((15<<8)|139)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 743 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,140) : setPromoLevel(((0<<8)|140)+1);


        (1,140) : setPromoLevel(((1<<8)|140)+1);


        (2,140) : setPromoLevel(((2<<8)|140)+1);


        (3,140) : setPromoLevel(((3<<8)|140)+1);


        (4,140) : setPromoLevel(((4<<8)|140)+1);


        (5,140) : setPromoLevel(((5<<8)|140)+1);


        (6,140) : setPromoLevel(((6<<8)|140)+1);


        (7,140) : setPromoLevel(((7<<8)|140)+1);


        (8,140) : setPromoLevel(((8<<8)|140)+1);


        (9,140) : setPromoLevel(((9<<8)|140)+1);


        (10,140) : setPromoLevel(((10<<8)|140)+1);


        (11,140) : setPromoLevel(((11<<8)|140)+1);


        (12,140) : setPromoLevel(((12<<8)|140)+1);


        (13,140) : setPromoLevel(((13<<8)|140)+1);


        (14,140) : setPromoLevel(((14<<8)|140)+1);


        (15,140) : setPromoLevel(((15<<8)|140)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 748 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,141) : setPromoLevel(((0<<8)|141)+1);


        (1,141) : setPromoLevel(((1<<8)|141)+1);


        (2,141) : setPromoLevel(((2<<8)|141)+1);


        (3,141) : setPromoLevel(((3<<8)|141)+1);


        (4,141) : setPromoLevel(((4<<8)|141)+1);


        (5,141) : setPromoLevel(((5<<8)|141)+1);


        (6,141) : setPromoLevel(((6<<8)|141)+1);


        (7,141) : setPromoLevel(((7<<8)|141)+1);


        (8,141) : setPromoLevel(((8<<8)|141)+1);


        (9,141) : setPromoLevel(((9<<8)|141)+1);


        (10,141) : setPromoLevel(((10<<8)|141)+1);


        (11,141) : setPromoLevel(((11<<8)|141)+1);


        (12,141) : setPromoLevel(((12<<8)|141)+1);


        (13,141) : setPromoLevel(((13<<8)|141)+1);


        (14,141) : setPromoLevel(((14<<8)|141)+1);


        (15,141) : setPromoLevel(((15<<8)|141)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 753 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,142) : setPromoLevel(((0<<8)|142)+1);


        (1,142) : setPromoLevel(((1<<8)|142)+1);


        (2,142) : setPromoLevel(((2<<8)|142)+1);


        (3,142) : setPromoLevel(((3<<8)|142)+1);


        (4,142) : setPromoLevel(((4<<8)|142)+1);


        (5,142) : setPromoLevel(((5<<8)|142)+1);


        (6,142) : setPromoLevel(((6<<8)|142)+1);


        (7,142) : setPromoLevel(((7<<8)|142)+1);


        (8,142) : setPromoLevel(((8<<8)|142)+1);


        (9,142) : setPromoLevel(((9<<8)|142)+1);


        (10,142) : setPromoLevel(((10<<8)|142)+1);


        (11,142) : setPromoLevel(((11<<8)|142)+1);


        (12,142) : setPromoLevel(((12<<8)|142)+1);


        (13,142) : setPromoLevel(((13<<8)|142)+1);


        (14,142) : setPromoLevel(((14<<8)|142)+1);


        (15,142) : setPromoLevel(((15<<8)|142)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 758 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,143) : setPromoLevel(((0<<8)|143)+1);


        (1,143) : setPromoLevel(((1<<8)|143)+1);


        (2,143) : setPromoLevel(((2<<8)|143)+1);


        (3,143) : setPromoLevel(((3<<8)|143)+1);


        (4,143) : setPromoLevel(((4<<8)|143)+1);


        (5,143) : setPromoLevel(((5<<8)|143)+1);


        (6,143) : setPromoLevel(((6<<8)|143)+1);


        (7,143) : setPromoLevel(((7<<8)|143)+1);


        (8,143) : setPromoLevel(((8<<8)|143)+1);


        (9,143) : setPromoLevel(((9<<8)|143)+1);


        (10,143) : setPromoLevel(((10<<8)|143)+1);


        (11,143) : setPromoLevel(((11<<8)|143)+1);


        (12,143) : setPromoLevel(((12<<8)|143)+1);


        (13,143) : setPromoLevel(((13<<8)|143)+1);


        (14,143) : setPromoLevel(((14<<8)|143)+1);


        (15,143) : setPromoLevel(((15<<8)|143)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 763 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,144) : setPromoLevel(((0<<8)|144)+1);


        (1,144) : setPromoLevel(((1<<8)|144)+1);


        (2,144) : setPromoLevel(((2<<8)|144)+1);


        (3,144) : setPromoLevel(((3<<8)|144)+1);


        (4,144) : setPromoLevel(((4<<8)|144)+1);


        (5,144) : setPromoLevel(((5<<8)|144)+1);


        (6,144) : setPromoLevel(((6<<8)|144)+1);


        (7,144) : setPromoLevel(((7<<8)|144)+1);


        (8,144) : setPromoLevel(((8<<8)|144)+1);


        (9,144) : setPromoLevel(((9<<8)|144)+1);


        (10,144) : setPromoLevel(((10<<8)|144)+1);


        (11,144) : setPromoLevel(((11<<8)|144)+1);


        (12,144) : setPromoLevel(((12<<8)|144)+1);


        (13,144) : setPromoLevel(((13<<8)|144)+1);


        (14,144) : setPromoLevel(((14<<8)|144)+1);


        (15,144) : setPromoLevel(((15<<8)|144)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 768 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,145) : setPromoLevel(((0<<8)|145)+1);


        (1,145) : setPromoLevel(((1<<8)|145)+1);


        (2,145) : setPromoLevel(((2<<8)|145)+1);


        (3,145) : setPromoLevel(((3<<8)|145)+1);


        (4,145) : setPromoLevel(((4<<8)|145)+1);


        (5,145) : setPromoLevel(((5<<8)|145)+1);


        (6,145) : setPromoLevel(((6<<8)|145)+1);


        (7,145) : setPromoLevel(((7<<8)|145)+1);


        (8,145) : setPromoLevel(((8<<8)|145)+1);


        (9,145) : setPromoLevel(((9<<8)|145)+1);


        (10,145) : setPromoLevel(((10<<8)|145)+1);


        (11,145) : setPromoLevel(((11<<8)|145)+1);


        (12,145) : setPromoLevel(((12<<8)|145)+1);


        (13,145) : setPromoLevel(((13<<8)|145)+1);


        (14,145) : setPromoLevel(((14<<8)|145)+1);


        (15,145) : setPromoLevel(((15<<8)|145)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 773 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,146) : setPromoLevel(((0<<8)|146)+1);


        (1,146) : setPromoLevel(((1<<8)|146)+1);


        (2,146) : setPromoLevel(((2<<8)|146)+1);


        (3,146) : setPromoLevel(((3<<8)|146)+1);


        (4,146) : setPromoLevel(((4<<8)|146)+1);


        (5,146) : setPromoLevel(((5<<8)|146)+1);


        (6,146) : setPromoLevel(((6<<8)|146)+1);


        (7,146) : setPromoLevel(((7<<8)|146)+1);


        (8,146) : setPromoLevel(((8<<8)|146)+1);


        (9,146) : setPromoLevel(((9<<8)|146)+1);


        (10,146) : setPromoLevel(((10<<8)|146)+1);


        (11,146) : setPromoLevel(((11<<8)|146)+1);


        (12,146) : setPromoLevel(((12<<8)|146)+1);


        (13,146) : setPromoLevel(((13<<8)|146)+1);


        (14,146) : setPromoLevel(((14<<8)|146)+1);


        (15,146) : setPromoLevel(((15<<8)|146)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 778 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,147) : setPromoLevel(((0<<8)|147)+1);


        (1,147) : setPromoLevel(((1<<8)|147)+1);


        (2,147) : setPromoLevel(((2<<8)|147)+1);


        (3,147) : setPromoLevel(((3<<8)|147)+1);


        (4,147) : setPromoLevel(((4<<8)|147)+1);


        (5,147) : setPromoLevel(((5<<8)|147)+1);


        (6,147) : setPromoLevel(((6<<8)|147)+1);


        (7,147) : setPromoLevel(((7<<8)|147)+1);


        (8,147) : setPromoLevel(((8<<8)|147)+1);


        (9,147) : setPromoLevel(((9<<8)|147)+1);


        (10,147) : setPromoLevel(((10<<8)|147)+1);


        (11,147) : setPromoLevel(((11<<8)|147)+1);


        (12,147) : setPromoLevel(((12<<8)|147)+1);


        (13,147) : setPromoLevel(((13<<8)|147)+1);


        (14,147) : setPromoLevel(((14<<8)|147)+1);


        (15,147) : setPromoLevel(((15<<8)|147)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 783 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,148) : setPromoLevel(((0<<8)|148)+1);


        (1,148) : setPromoLevel(((1<<8)|148)+1);


        (2,148) : setPromoLevel(((2<<8)|148)+1);


        (3,148) : setPromoLevel(((3<<8)|148)+1);


        (4,148) : setPromoLevel(((4<<8)|148)+1);


        (5,148) : setPromoLevel(((5<<8)|148)+1);


        (6,148) : setPromoLevel(((6<<8)|148)+1);


        (7,148) : setPromoLevel(((7<<8)|148)+1);


        (8,148) : setPromoLevel(((8<<8)|148)+1);


        (9,148) : setPromoLevel(((9<<8)|148)+1);


        (10,148) : setPromoLevel(((10<<8)|148)+1);


        (11,148) : setPromoLevel(((11<<8)|148)+1);


        (12,148) : setPromoLevel(((12<<8)|148)+1);


        (13,148) : setPromoLevel(((13<<8)|148)+1);


        (14,148) : setPromoLevel(((14<<8)|148)+1);


        (15,148) : setPromoLevel(((15<<8)|148)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 788 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,149) : setPromoLevel(((0<<8)|149)+1);


        (1,149) : setPromoLevel(((1<<8)|149)+1);


        (2,149) : setPromoLevel(((2<<8)|149)+1);


        (3,149) : setPromoLevel(((3<<8)|149)+1);


        (4,149) : setPromoLevel(((4<<8)|149)+1);


        (5,149) : setPromoLevel(((5<<8)|149)+1);


        (6,149) : setPromoLevel(((6<<8)|149)+1);


        (7,149) : setPromoLevel(((7<<8)|149)+1);


        (8,149) : setPromoLevel(((8<<8)|149)+1);


        (9,149) : setPromoLevel(((9<<8)|149)+1);


        (10,149) : setPromoLevel(((10<<8)|149)+1);


        (11,149) : setPromoLevel(((11<<8)|149)+1);


        (12,149) : setPromoLevel(((12<<8)|149)+1);


        (13,149) : setPromoLevel(((13<<8)|149)+1);


        (14,149) : setPromoLevel(((14<<8)|149)+1);


        (15,149) : setPromoLevel(((15<<8)|149)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 793 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,150) : setPromoLevel(((0<<8)|150)+1);


        (1,150) : setPromoLevel(((1<<8)|150)+1);


        (2,150) : setPromoLevel(((2<<8)|150)+1);


        (3,150) : setPromoLevel(((3<<8)|150)+1);


        (4,150) : setPromoLevel(((4<<8)|150)+1);


        (5,150) : setPromoLevel(((5<<8)|150)+1);


        (6,150) : setPromoLevel(((6<<8)|150)+1);


        (7,150) : setPromoLevel(((7<<8)|150)+1);


        (8,150) : setPromoLevel(((8<<8)|150)+1);


        (9,150) : setPromoLevel(((9<<8)|150)+1);


        (10,150) : setPromoLevel(((10<<8)|150)+1);


        (11,150) : setPromoLevel(((11<<8)|150)+1);


        (12,150) : setPromoLevel(((12<<8)|150)+1);


        (13,150) : setPromoLevel(((13<<8)|150)+1);


        (14,150) : setPromoLevel(((14<<8)|150)+1);


        (15,150) : setPromoLevel(((15<<8)|150)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 798 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,151) : setPromoLevel(((0<<8)|151)+1);


        (1,151) : setPromoLevel(((1<<8)|151)+1);


        (2,151) : setPromoLevel(((2<<8)|151)+1);


        (3,151) : setPromoLevel(((3<<8)|151)+1);


        (4,151) : setPromoLevel(((4<<8)|151)+1);


        (5,151) : setPromoLevel(((5<<8)|151)+1);


        (6,151) : setPromoLevel(((6<<8)|151)+1);


        (7,151) : setPromoLevel(((7<<8)|151)+1);


        (8,151) : setPromoLevel(((8<<8)|151)+1);


        (9,151) : setPromoLevel(((9<<8)|151)+1);


        (10,151) : setPromoLevel(((10<<8)|151)+1);


        (11,151) : setPromoLevel(((11<<8)|151)+1);


        (12,151) : setPromoLevel(((12<<8)|151)+1);


        (13,151) : setPromoLevel(((13<<8)|151)+1);


        (14,151) : setPromoLevel(((14<<8)|151)+1);


        (15,151) : setPromoLevel(((15<<8)|151)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 803 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,152) : setPromoLevel(((0<<8)|152)+1);


        (1,152) : setPromoLevel(((1<<8)|152)+1);


        (2,152) : setPromoLevel(((2<<8)|152)+1);


        (3,152) : setPromoLevel(((3<<8)|152)+1);


        (4,152) : setPromoLevel(((4<<8)|152)+1);


        (5,152) : setPromoLevel(((5<<8)|152)+1);


        (6,152) : setPromoLevel(((6<<8)|152)+1);


        (7,152) : setPromoLevel(((7<<8)|152)+1);


        (8,152) : setPromoLevel(((8<<8)|152)+1);


        (9,152) : setPromoLevel(((9<<8)|152)+1);


        (10,152) : setPromoLevel(((10<<8)|152)+1);


        (11,152) : setPromoLevel(((11<<8)|152)+1);


        (12,152) : setPromoLevel(((12<<8)|152)+1);


        (13,152) : setPromoLevel(((13<<8)|152)+1);


        (14,152) : setPromoLevel(((14<<8)|152)+1);


        (15,152) : setPromoLevel(((15<<8)|152)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 808 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,153) : setPromoLevel(((0<<8)|153)+1);


        (1,153) : setPromoLevel(((1<<8)|153)+1);


        (2,153) : setPromoLevel(((2<<8)|153)+1);


        (3,153) : setPromoLevel(((3<<8)|153)+1);


        (4,153) : setPromoLevel(((4<<8)|153)+1);


        (5,153) : setPromoLevel(((5<<8)|153)+1);


        (6,153) : setPromoLevel(((6<<8)|153)+1);


        (7,153) : setPromoLevel(((7<<8)|153)+1);


        (8,153) : setPromoLevel(((8<<8)|153)+1);


        (9,153) : setPromoLevel(((9<<8)|153)+1);


        (10,153) : setPromoLevel(((10<<8)|153)+1);


        (11,153) : setPromoLevel(((11<<8)|153)+1);


        (12,153) : setPromoLevel(((12<<8)|153)+1);


        (13,153) : setPromoLevel(((13<<8)|153)+1);


        (14,153) : setPromoLevel(((14<<8)|153)+1);


        (15,153) : setPromoLevel(((15<<8)|153)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 813 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,154) : setPromoLevel(((0<<8)|154)+1);


        (1,154) : setPromoLevel(((1<<8)|154)+1);


        (2,154) : setPromoLevel(((2<<8)|154)+1);


        (3,154) : setPromoLevel(((3<<8)|154)+1);


        (4,154) : setPromoLevel(((4<<8)|154)+1);


        (5,154) : setPromoLevel(((5<<8)|154)+1);


        (6,154) : setPromoLevel(((6<<8)|154)+1);


        (7,154) : setPromoLevel(((7<<8)|154)+1);


        (8,154) : setPromoLevel(((8<<8)|154)+1);


        (9,154) : setPromoLevel(((9<<8)|154)+1);


        (10,154) : setPromoLevel(((10<<8)|154)+1);


        (11,154) : setPromoLevel(((11<<8)|154)+1);


        (12,154) : setPromoLevel(((12<<8)|154)+1);


        (13,154) : setPromoLevel(((13<<8)|154)+1);


        (14,154) : setPromoLevel(((14<<8)|154)+1);


        (15,154) : setPromoLevel(((15<<8)|154)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 818 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,155) : setPromoLevel(((0<<8)|155)+1);


        (1,155) : setPromoLevel(((1<<8)|155)+1);


        (2,155) : setPromoLevel(((2<<8)|155)+1);


        (3,155) : setPromoLevel(((3<<8)|155)+1);


        (4,155) : setPromoLevel(((4<<8)|155)+1);


        (5,155) : setPromoLevel(((5<<8)|155)+1);


        (6,155) : setPromoLevel(((6<<8)|155)+1);


        (7,155) : setPromoLevel(((7<<8)|155)+1);


        (8,155) : setPromoLevel(((8<<8)|155)+1);


        (9,155) : setPromoLevel(((9<<8)|155)+1);


        (10,155) : setPromoLevel(((10<<8)|155)+1);


        (11,155) : setPromoLevel(((11<<8)|155)+1);


        (12,155) : setPromoLevel(((12<<8)|155)+1);


        (13,155) : setPromoLevel(((13<<8)|155)+1);


        (14,155) : setPromoLevel(((14<<8)|155)+1);


        (15,155) : setPromoLevel(((15<<8)|155)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 823 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,156) : setPromoLevel(((0<<8)|156)+1);


        (1,156) : setPromoLevel(((1<<8)|156)+1);


        (2,156) : setPromoLevel(((2<<8)|156)+1);


        (3,156) : setPromoLevel(((3<<8)|156)+1);


        (4,156) : setPromoLevel(((4<<8)|156)+1);


        (5,156) : setPromoLevel(((5<<8)|156)+1);


        (6,156) : setPromoLevel(((6<<8)|156)+1);


        (7,156) : setPromoLevel(((7<<8)|156)+1);


        (8,156) : setPromoLevel(((8<<8)|156)+1);


        (9,156) : setPromoLevel(((9<<8)|156)+1);


        (10,156) : setPromoLevel(((10<<8)|156)+1);


        (11,156) : setPromoLevel(((11<<8)|156)+1);


        (12,156) : setPromoLevel(((12<<8)|156)+1);


        (13,156) : setPromoLevel(((13<<8)|156)+1);


        (14,156) : setPromoLevel(((14<<8)|156)+1);


        (15,156) : setPromoLevel(((15<<8)|156)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 828 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,157) : setPromoLevel(((0<<8)|157)+1);


        (1,157) : setPromoLevel(((1<<8)|157)+1);


        (2,157) : setPromoLevel(((2<<8)|157)+1);


        (3,157) : setPromoLevel(((3<<8)|157)+1);


        (4,157) : setPromoLevel(((4<<8)|157)+1);


        (5,157) : setPromoLevel(((5<<8)|157)+1);


        (6,157) : setPromoLevel(((6<<8)|157)+1);


        (7,157) : setPromoLevel(((7<<8)|157)+1);


        (8,157) : setPromoLevel(((8<<8)|157)+1);


        (9,157) : setPromoLevel(((9<<8)|157)+1);


        (10,157) : setPromoLevel(((10<<8)|157)+1);


        (11,157) : setPromoLevel(((11<<8)|157)+1);


        (12,157) : setPromoLevel(((12<<8)|157)+1);


        (13,157) : setPromoLevel(((13<<8)|157)+1);


        (14,157) : setPromoLevel(((14<<8)|157)+1);


        (15,157) : setPromoLevel(((15<<8)|157)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 833 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,158) : setPromoLevel(((0<<8)|158)+1);


        (1,158) : setPromoLevel(((1<<8)|158)+1);


        (2,158) : setPromoLevel(((2<<8)|158)+1);


        (3,158) : setPromoLevel(((3<<8)|158)+1);


        (4,158) : setPromoLevel(((4<<8)|158)+1);


        (5,158) : setPromoLevel(((5<<8)|158)+1);


        (6,158) : setPromoLevel(((6<<8)|158)+1);


        (7,158) : setPromoLevel(((7<<8)|158)+1);


        (8,158) : setPromoLevel(((8<<8)|158)+1);


        (9,158) : setPromoLevel(((9<<8)|158)+1);


        (10,158) : setPromoLevel(((10<<8)|158)+1);


        (11,158) : setPromoLevel(((11<<8)|158)+1);


        (12,158) : setPromoLevel(((12<<8)|158)+1);


        (13,158) : setPromoLevel(((13<<8)|158)+1);


        (14,158) : setPromoLevel(((14<<8)|158)+1);


        (15,158) : setPromoLevel(((15<<8)|158)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 838 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,159) : setPromoLevel(((0<<8)|159)+1);


        (1,159) : setPromoLevel(((1<<8)|159)+1);


        (2,159) : setPromoLevel(((2<<8)|159)+1);


        (3,159) : setPromoLevel(((3<<8)|159)+1);


        (4,159) : setPromoLevel(((4<<8)|159)+1);


        (5,159) : setPromoLevel(((5<<8)|159)+1);


        (6,159) : setPromoLevel(((6<<8)|159)+1);


        (7,159) : setPromoLevel(((7<<8)|159)+1);


        (8,159) : setPromoLevel(((8<<8)|159)+1);


        (9,159) : setPromoLevel(((9<<8)|159)+1);


        (10,159) : setPromoLevel(((10<<8)|159)+1);


        (11,159) : setPromoLevel(((11<<8)|159)+1);


        (12,159) : setPromoLevel(((12<<8)|159)+1);


        (13,159) : setPromoLevel(((13<<8)|159)+1);


        (14,159) : setPromoLevel(((14<<8)|159)+1);


        (15,159) : setPromoLevel(((15<<8)|159)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 843 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,160) : setPromoLevel(((0<<8)|160)+1);


        (1,160) : setPromoLevel(((1<<8)|160)+1);


        (2,160) : setPromoLevel(((2<<8)|160)+1);


        (3,160) : setPromoLevel(((3<<8)|160)+1);


        (4,160) : setPromoLevel(((4<<8)|160)+1);


        (5,160) : setPromoLevel(((5<<8)|160)+1);


        (6,160) : setPromoLevel(((6<<8)|160)+1);


        (7,160) : setPromoLevel(((7<<8)|160)+1);


        (8,160) : setPromoLevel(((8<<8)|160)+1);


        (9,160) : setPromoLevel(((9<<8)|160)+1);


        (10,160) : setPromoLevel(((10<<8)|160)+1);


        (11,160) : setPromoLevel(((11<<8)|160)+1);


        (12,160) : setPromoLevel(((12<<8)|160)+1);


        (13,160) : setPromoLevel(((13<<8)|160)+1);


        (14,160) : setPromoLevel(((14<<8)|160)+1);


        (15,160) : setPromoLevel(((15<<8)|160)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 848 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,161) : setPromoLevel(((0<<8)|161)+1);


        (1,161) : setPromoLevel(((1<<8)|161)+1);


        (2,161) : setPromoLevel(((2<<8)|161)+1);


        (3,161) : setPromoLevel(((3<<8)|161)+1);


        (4,161) : setPromoLevel(((4<<8)|161)+1);


        (5,161) : setPromoLevel(((5<<8)|161)+1);


        (6,161) : setPromoLevel(((6<<8)|161)+1);


        (7,161) : setPromoLevel(((7<<8)|161)+1);


        (8,161) : setPromoLevel(((8<<8)|161)+1);


        (9,161) : setPromoLevel(((9<<8)|161)+1);


        (10,161) : setPromoLevel(((10<<8)|161)+1);


        (11,161) : setPromoLevel(((11<<8)|161)+1);


        (12,161) : setPromoLevel(((12<<8)|161)+1);


        (13,161) : setPromoLevel(((13<<8)|161)+1);


        (14,161) : setPromoLevel(((14<<8)|161)+1);


        (15,161) : setPromoLevel(((15<<8)|161)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 853 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,162) : setPromoLevel(((0<<8)|162)+1);


        (1,162) : setPromoLevel(((1<<8)|162)+1);


        (2,162) : setPromoLevel(((2<<8)|162)+1);


        (3,162) : setPromoLevel(((3<<8)|162)+1);


        (4,162) : setPromoLevel(((4<<8)|162)+1);


        (5,162) : setPromoLevel(((5<<8)|162)+1);


        (6,162) : setPromoLevel(((6<<8)|162)+1);


        (7,162) : setPromoLevel(((7<<8)|162)+1);


        (8,162) : setPromoLevel(((8<<8)|162)+1);


        (9,162) : setPromoLevel(((9<<8)|162)+1);


        (10,162) : setPromoLevel(((10<<8)|162)+1);


        (11,162) : setPromoLevel(((11<<8)|162)+1);


        (12,162) : setPromoLevel(((12<<8)|162)+1);


        (13,162) : setPromoLevel(((13<<8)|162)+1);


        (14,162) : setPromoLevel(((14<<8)|162)+1);


        (15,162) : setPromoLevel(((15<<8)|162)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 858 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,163) : setPromoLevel(((0<<8)|163)+1);


        (1,163) : setPromoLevel(((1<<8)|163)+1);


        (2,163) : setPromoLevel(((2<<8)|163)+1);


        (3,163) : setPromoLevel(((3<<8)|163)+1);


        (4,163) : setPromoLevel(((4<<8)|163)+1);


        (5,163) : setPromoLevel(((5<<8)|163)+1);


        (6,163) : setPromoLevel(((6<<8)|163)+1);


        (7,163) : setPromoLevel(((7<<8)|163)+1);


        (8,163) : setPromoLevel(((8<<8)|163)+1);


        (9,163) : setPromoLevel(((9<<8)|163)+1);


        (10,163) : setPromoLevel(((10<<8)|163)+1);


        (11,163) : setPromoLevel(((11<<8)|163)+1);


        (12,163) : setPromoLevel(((12<<8)|163)+1);


        (13,163) : setPromoLevel(((13<<8)|163)+1);


        (14,163) : setPromoLevel(((14<<8)|163)+1);


        (15,163) : setPromoLevel(((15<<8)|163)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 863 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,164) : setPromoLevel(((0<<8)|164)+1);


        (1,164) : setPromoLevel(((1<<8)|164)+1);


        (2,164) : setPromoLevel(((2<<8)|164)+1);


        (3,164) : setPromoLevel(((3<<8)|164)+1);


        (4,164) : setPromoLevel(((4<<8)|164)+1);


        (5,164) : setPromoLevel(((5<<8)|164)+1);


        (6,164) : setPromoLevel(((6<<8)|164)+1);


        (7,164) : setPromoLevel(((7<<8)|164)+1);


        (8,164) : setPromoLevel(((8<<8)|164)+1);


        (9,164) : setPromoLevel(((9<<8)|164)+1);


        (10,164) : setPromoLevel(((10<<8)|164)+1);


        (11,164) : setPromoLevel(((11<<8)|164)+1);


        (12,164) : setPromoLevel(((12<<8)|164)+1);


        (13,164) : setPromoLevel(((13<<8)|164)+1);


        (14,164) : setPromoLevel(((14<<8)|164)+1);


        (15,164) : setPromoLevel(((15<<8)|164)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 868 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,165) : setPromoLevel(((0<<8)|165)+1);


        (1,165) : setPromoLevel(((1<<8)|165)+1);


        (2,165) : setPromoLevel(((2<<8)|165)+1);


        (3,165) : setPromoLevel(((3<<8)|165)+1);


        (4,165) : setPromoLevel(((4<<8)|165)+1);


        (5,165) : setPromoLevel(((5<<8)|165)+1);


        (6,165) : setPromoLevel(((6<<8)|165)+1);


        (7,165) : setPromoLevel(((7<<8)|165)+1);


        (8,165) : setPromoLevel(((8<<8)|165)+1);


        (9,165) : setPromoLevel(((9<<8)|165)+1);


        (10,165) : setPromoLevel(((10<<8)|165)+1);


        (11,165) : setPromoLevel(((11<<8)|165)+1);


        (12,165) : setPromoLevel(((12<<8)|165)+1);


        (13,165) : setPromoLevel(((13<<8)|165)+1);


        (14,165) : setPromoLevel(((14<<8)|165)+1);


        (15,165) : setPromoLevel(((15<<8)|165)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 873 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,166) : setPromoLevel(((0<<8)|166)+1);


        (1,166) : setPromoLevel(((1<<8)|166)+1);


        (2,166) : setPromoLevel(((2<<8)|166)+1);


        (3,166) : setPromoLevel(((3<<8)|166)+1);


        (4,166) : setPromoLevel(((4<<8)|166)+1);


        (5,166) : setPromoLevel(((5<<8)|166)+1);


        (6,166) : setPromoLevel(((6<<8)|166)+1);


        (7,166) : setPromoLevel(((7<<8)|166)+1);


        (8,166) : setPromoLevel(((8<<8)|166)+1);


        (9,166) : setPromoLevel(((9<<8)|166)+1);


        (10,166) : setPromoLevel(((10<<8)|166)+1);


        (11,166) : setPromoLevel(((11<<8)|166)+1);


        (12,166) : setPromoLevel(((12<<8)|166)+1);


        (13,166) : setPromoLevel(((13<<8)|166)+1);


        (14,166) : setPromoLevel(((14<<8)|166)+1);


        (15,166) : setPromoLevel(((15<<8)|166)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 878 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,167) : setPromoLevel(((0<<8)|167)+1);


        (1,167) : setPromoLevel(((1<<8)|167)+1);


        (2,167) : setPromoLevel(((2<<8)|167)+1);


        (3,167) : setPromoLevel(((3<<8)|167)+1);


        (4,167) : setPromoLevel(((4<<8)|167)+1);


        (5,167) : setPromoLevel(((5<<8)|167)+1);


        (6,167) : setPromoLevel(((6<<8)|167)+1);


        (7,167) : setPromoLevel(((7<<8)|167)+1);


        (8,167) : setPromoLevel(((8<<8)|167)+1);


        (9,167) : setPromoLevel(((9<<8)|167)+1);


        (10,167) : setPromoLevel(((10<<8)|167)+1);


        (11,167) : setPromoLevel(((11<<8)|167)+1);


        (12,167) : setPromoLevel(((12<<8)|167)+1);


        (13,167) : setPromoLevel(((13<<8)|167)+1);


        (14,167) : setPromoLevel(((14<<8)|167)+1);


        (15,167) : setPromoLevel(((15<<8)|167)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 883 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,168) : setPromoLevel(((0<<8)|168)+1);


        (1,168) : setPromoLevel(((1<<8)|168)+1);


        (2,168) : setPromoLevel(((2<<8)|168)+1);


        (3,168) : setPromoLevel(((3<<8)|168)+1);


        (4,168) : setPromoLevel(((4<<8)|168)+1);


        (5,168) : setPromoLevel(((5<<8)|168)+1);


        (6,168) : setPromoLevel(((6<<8)|168)+1);


        (7,168) : setPromoLevel(((7<<8)|168)+1);


        (8,168) : setPromoLevel(((8<<8)|168)+1);


        (9,168) : setPromoLevel(((9<<8)|168)+1);


        (10,168) : setPromoLevel(((10<<8)|168)+1);


        (11,168) : setPromoLevel(((11<<8)|168)+1);


        (12,168) : setPromoLevel(((12<<8)|168)+1);


        (13,168) : setPromoLevel(((13<<8)|168)+1);


        (14,168) : setPromoLevel(((14<<8)|168)+1);


        (15,168) : setPromoLevel(((15<<8)|168)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 888 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,169) : setPromoLevel(((0<<8)|169)+1);


        (1,169) : setPromoLevel(((1<<8)|169)+1);


        (2,169) : setPromoLevel(((2<<8)|169)+1);


        (3,169) : setPromoLevel(((3<<8)|169)+1);


        (4,169) : setPromoLevel(((4<<8)|169)+1);


        (5,169) : setPromoLevel(((5<<8)|169)+1);


        (6,169) : setPromoLevel(((6<<8)|169)+1);


        (7,169) : setPromoLevel(((7<<8)|169)+1);


        (8,169) : setPromoLevel(((8<<8)|169)+1);


        (9,169) : setPromoLevel(((9<<8)|169)+1);


        (10,169) : setPromoLevel(((10<<8)|169)+1);


        (11,169) : setPromoLevel(((11<<8)|169)+1);


        (12,169) : setPromoLevel(((12<<8)|169)+1);


        (13,169) : setPromoLevel(((13<<8)|169)+1);


        (14,169) : setPromoLevel(((14<<8)|169)+1);


        (15,169) : setPromoLevel(((15<<8)|169)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 893 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,170) : setPromoLevel(((0<<8)|170)+1);


        (1,170) : setPromoLevel(((1<<8)|170)+1);


        (2,170) : setPromoLevel(((2<<8)|170)+1);


        (3,170) : setPromoLevel(((3<<8)|170)+1);


        (4,170) : setPromoLevel(((4<<8)|170)+1);


        (5,170) : setPromoLevel(((5<<8)|170)+1);


        (6,170) : setPromoLevel(((6<<8)|170)+1);


        (7,170) : setPromoLevel(((7<<8)|170)+1);


        (8,170) : setPromoLevel(((8<<8)|170)+1);


        (9,170) : setPromoLevel(((9<<8)|170)+1);


        (10,170) : setPromoLevel(((10<<8)|170)+1);


        (11,170) : setPromoLevel(((11<<8)|170)+1);


        (12,170) : setPromoLevel(((12<<8)|170)+1);


        (13,170) : setPromoLevel(((13<<8)|170)+1);


        (14,170) : setPromoLevel(((14<<8)|170)+1);


        (15,170) : setPromoLevel(((15<<8)|170)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 898 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,171) : setPromoLevel(((0<<8)|171)+1);


        (1,171) : setPromoLevel(((1<<8)|171)+1);


        (2,171) : setPromoLevel(((2<<8)|171)+1);


        (3,171) : setPromoLevel(((3<<8)|171)+1);


        (4,171) : setPromoLevel(((4<<8)|171)+1);


        (5,171) : setPromoLevel(((5<<8)|171)+1);


        (6,171) : setPromoLevel(((6<<8)|171)+1);


        (7,171) : setPromoLevel(((7<<8)|171)+1);


        (8,171) : setPromoLevel(((8<<8)|171)+1);


        (9,171) : setPromoLevel(((9<<8)|171)+1);


        (10,171) : setPromoLevel(((10<<8)|171)+1);


        (11,171) : setPromoLevel(((11<<8)|171)+1);


        (12,171) : setPromoLevel(((12<<8)|171)+1);


        (13,171) : setPromoLevel(((13<<8)|171)+1);


        (14,171) : setPromoLevel(((14<<8)|171)+1);


        (15,171) : setPromoLevel(((15<<8)|171)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 903 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,172) : setPromoLevel(((0<<8)|172)+1);


        (1,172) : setPromoLevel(((1<<8)|172)+1);


        (2,172) : setPromoLevel(((2<<8)|172)+1);


        (3,172) : setPromoLevel(((3<<8)|172)+1);


        (4,172) : setPromoLevel(((4<<8)|172)+1);


        (5,172) : setPromoLevel(((5<<8)|172)+1);


        (6,172) : setPromoLevel(((6<<8)|172)+1);


        (7,172) : setPromoLevel(((7<<8)|172)+1);


        (8,172) : setPromoLevel(((8<<8)|172)+1);


        (9,172) : setPromoLevel(((9<<8)|172)+1);


        (10,172) : setPromoLevel(((10<<8)|172)+1);


        (11,172) : setPromoLevel(((11<<8)|172)+1);


        (12,172) : setPromoLevel(((12<<8)|172)+1);


        (13,172) : setPromoLevel(((13<<8)|172)+1);


        (14,172) : setPromoLevel(((14<<8)|172)+1);


        (15,172) : setPromoLevel(((15<<8)|172)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 908 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,173) : setPromoLevel(((0<<8)|173)+1);


        (1,173) : setPromoLevel(((1<<8)|173)+1);


        (2,173) : setPromoLevel(((2<<8)|173)+1);


        (3,173) : setPromoLevel(((3<<8)|173)+1);


        (4,173) : setPromoLevel(((4<<8)|173)+1);


        (5,173) : setPromoLevel(((5<<8)|173)+1);


        (6,173) : setPromoLevel(((6<<8)|173)+1);


        (7,173) : setPromoLevel(((7<<8)|173)+1);


        (8,173) : setPromoLevel(((8<<8)|173)+1);


        (9,173) : setPromoLevel(((9<<8)|173)+1);


        (10,173) : setPromoLevel(((10<<8)|173)+1);


        (11,173) : setPromoLevel(((11<<8)|173)+1);


        (12,173) : setPromoLevel(((12<<8)|173)+1);


        (13,173) : setPromoLevel(((13<<8)|173)+1);


        (14,173) : setPromoLevel(((14<<8)|173)+1);


        (15,173) : setPromoLevel(((15<<8)|173)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 913 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,174) : setPromoLevel(((0<<8)|174)+1);


        (1,174) : setPromoLevel(((1<<8)|174)+1);


        (2,174) : setPromoLevel(((2<<8)|174)+1);


        (3,174) : setPromoLevel(((3<<8)|174)+1);


        (4,174) : setPromoLevel(((4<<8)|174)+1);


        (5,174) : setPromoLevel(((5<<8)|174)+1);


        (6,174) : setPromoLevel(((6<<8)|174)+1);


        (7,174) : setPromoLevel(((7<<8)|174)+1);


        (8,174) : setPromoLevel(((8<<8)|174)+1);


        (9,174) : setPromoLevel(((9<<8)|174)+1);


        (10,174) : setPromoLevel(((10<<8)|174)+1);


        (11,174) : setPromoLevel(((11<<8)|174)+1);


        (12,174) : setPromoLevel(((12<<8)|174)+1);


        (13,174) : setPromoLevel(((13<<8)|174)+1);


        (14,174) : setPromoLevel(((14<<8)|174)+1);


        (15,174) : setPromoLevel(((15<<8)|174)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 918 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,175) : setPromoLevel(((0<<8)|175)+1);


        (1,175) : setPromoLevel(((1<<8)|175)+1);


        (2,175) : setPromoLevel(((2<<8)|175)+1);


        (3,175) : setPromoLevel(((3<<8)|175)+1);


        (4,175) : setPromoLevel(((4<<8)|175)+1);


        (5,175) : setPromoLevel(((5<<8)|175)+1);


        (6,175) : setPromoLevel(((6<<8)|175)+1);


        (7,175) : setPromoLevel(((7<<8)|175)+1);


        (8,175) : setPromoLevel(((8<<8)|175)+1);


        (9,175) : setPromoLevel(((9<<8)|175)+1);


        (10,175) : setPromoLevel(((10<<8)|175)+1);


        (11,175) : setPromoLevel(((11<<8)|175)+1);


        (12,175) : setPromoLevel(((12<<8)|175)+1);


        (13,175) : setPromoLevel(((13<<8)|175)+1);


        (14,175) : setPromoLevel(((14<<8)|175)+1);


        (15,175) : setPromoLevel(((15<<8)|175)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 923 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,176) : setPromoLevel(((0<<8)|176)+1);


        (1,176) : setPromoLevel(((1<<8)|176)+1);


        (2,176) : setPromoLevel(((2<<8)|176)+1);


        (3,176) : setPromoLevel(((3<<8)|176)+1);


        (4,176) : setPromoLevel(((4<<8)|176)+1);


        (5,176) : setPromoLevel(((5<<8)|176)+1);


        (6,176) : setPromoLevel(((6<<8)|176)+1);


        (7,176) : setPromoLevel(((7<<8)|176)+1);


        (8,176) : setPromoLevel(((8<<8)|176)+1);


        (9,176) : setPromoLevel(((9<<8)|176)+1);


        (10,176) : setPromoLevel(((10<<8)|176)+1);


        (11,176) : setPromoLevel(((11<<8)|176)+1);


        (12,176) : setPromoLevel(((12<<8)|176)+1);


        (13,176) : setPromoLevel(((13<<8)|176)+1);


        (14,176) : setPromoLevel(((14<<8)|176)+1);


        (15,176) : setPromoLevel(((15<<8)|176)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 928 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,177) : setPromoLevel(((0<<8)|177)+1);


        (1,177) : setPromoLevel(((1<<8)|177)+1);


        (2,177) : setPromoLevel(((2<<8)|177)+1);


        (3,177) : setPromoLevel(((3<<8)|177)+1);


        (4,177) : setPromoLevel(((4<<8)|177)+1);


        (5,177) : setPromoLevel(((5<<8)|177)+1);


        (6,177) : setPromoLevel(((6<<8)|177)+1);


        (7,177) : setPromoLevel(((7<<8)|177)+1);


        (8,177) : setPromoLevel(((8<<8)|177)+1);


        (9,177) : setPromoLevel(((9<<8)|177)+1);


        (10,177) : setPromoLevel(((10<<8)|177)+1);


        (11,177) : setPromoLevel(((11<<8)|177)+1);


        (12,177) : setPromoLevel(((12<<8)|177)+1);


        (13,177) : setPromoLevel(((13<<8)|177)+1);


        (14,177) : setPromoLevel(((14<<8)|177)+1);


        (15,177) : setPromoLevel(((15<<8)|177)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 933 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,178) : setPromoLevel(((0<<8)|178)+1);


        (1,178) : setPromoLevel(((1<<8)|178)+1);


        (2,178) : setPromoLevel(((2<<8)|178)+1);


        (3,178) : setPromoLevel(((3<<8)|178)+1);


        (4,178) : setPromoLevel(((4<<8)|178)+1);


        (5,178) : setPromoLevel(((5<<8)|178)+1);


        (6,178) : setPromoLevel(((6<<8)|178)+1);


        (7,178) : setPromoLevel(((7<<8)|178)+1);


        (8,178) : setPromoLevel(((8<<8)|178)+1);


        (9,178) : setPromoLevel(((9<<8)|178)+1);


        (10,178) : setPromoLevel(((10<<8)|178)+1);


        (11,178) : setPromoLevel(((11<<8)|178)+1);


        (12,178) : setPromoLevel(((12<<8)|178)+1);


        (13,178) : setPromoLevel(((13<<8)|178)+1);


        (14,178) : setPromoLevel(((14<<8)|178)+1);


        (15,178) : setPromoLevel(((15<<8)|178)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 938 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,179) : setPromoLevel(((0<<8)|179)+1);


        (1,179) : setPromoLevel(((1<<8)|179)+1);


        (2,179) : setPromoLevel(((2<<8)|179)+1);


        (3,179) : setPromoLevel(((3<<8)|179)+1);


        (4,179) : setPromoLevel(((4<<8)|179)+1);


        (5,179) : setPromoLevel(((5<<8)|179)+1);


        (6,179) : setPromoLevel(((6<<8)|179)+1);


        (7,179) : setPromoLevel(((7<<8)|179)+1);


        (8,179) : setPromoLevel(((8<<8)|179)+1);


        (9,179) : setPromoLevel(((9<<8)|179)+1);


        (10,179) : setPromoLevel(((10<<8)|179)+1);


        (11,179) : setPromoLevel(((11<<8)|179)+1);


        (12,179) : setPromoLevel(((12<<8)|179)+1);


        (13,179) : setPromoLevel(((13<<8)|179)+1);


        (14,179) : setPromoLevel(((14<<8)|179)+1);


        (15,179) : setPromoLevel(((15<<8)|179)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 943 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,180) : setPromoLevel(((0<<8)|180)+1);


        (1,180) : setPromoLevel(((1<<8)|180)+1);


        (2,180) : setPromoLevel(((2<<8)|180)+1);


        (3,180) : setPromoLevel(((3<<8)|180)+1);


        (4,180) : setPromoLevel(((4<<8)|180)+1);


        (5,180) : setPromoLevel(((5<<8)|180)+1);


        (6,180) : setPromoLevel(((6<<8)|180)+1);


        (7,180) : setPromoLevel(((7<<8)|180)+1);


        (8,180) : setPromoLevel(((8<<8)|180)+1);


        (9,180) : setPromoLevel(((9<<8)|180)+1);


        (10,180) : setPromoLevel(((10<<8)|180)+1);


        (11,180) : setPromoLevel(((11<<8)|180)+1);


        (12,180) : setPromoLevel(((12<<8)|180)+1);


        (13,180) : setPromoLevel(((13<<8)|180)+1);


        (14,180) : setPromoLevel(((14<<8)|180)+1);


        (15,180) : setPromoLevel(((15<<8)|180)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 948 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,181) : setPromoLevel(((0<<8)|181)+1);


        (1,181) : setPromoLevel(((1<<8)|181)+1);


        (2,181) : setPromoLevel(((2<<8)|181)+1);


        (3,181) : setPromoLevel(((3<<8)|181)+1);


        (4,181) : setPromoLevel(((4<<8)|181)+1);


        (5,181) : setPromoLevel(((5<<8)|181)+1);


        (6,181) : setPromoLevel(((6<<8)|181)+1);


        (7,181) : setPromoLevel(((7<<8)|181)+1);


        (8,181) : setPromoLevel(((8<<8)|181)+1);


        (9,181) : setPromoLevel(((9<<8)|181)+1);


        (10,181) : setPromoLevel(((10<<8)|181)+1);


        (11,181) : setPromoLevel(((11<<8)|181)+1);


        (12,181) : setPromoLevel(((12<<8)|181)+1);


        (13,181) : setPromoLevel(((13<<8)|181)+1);


        (14,181) : setPromoLevel(((14<<8)|181)+1);


        (15,181) : setPromoLevel(((15<<8)|181)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 953 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,182) : setPromoLevel(((0<<8)|182)+1);


        (1,182) : setPromoLevel(((1<<8)|182)+1);


        (2,182) : setPromoLevel(((2<<8)|182)+1);


        (3,182) : setPromoLevel(((3<<8)|182)+1);


        (4,182) : setPromoLevel(((4<<8)|182)+1);


        (5,182) : setPromoLevel(((5<<8)|182)+1);


        (6,182) : setPromoLevel(((6<<8)|182)+1);


        (7,182) : setPromoLevel(((7<<8)|182)+1);


        (8,182) : setPromoLevel(((8<<8)|182)+1);


        (9,182) : setPromoLevel(((9<<8)|182)+1);


        (10,182) : setPromoLevel(((10<<8)|182)+1);


        (11,182) : setPromoLevel(((11<<8)|182)+1);


        (12,182) : setPromoLevel(((12<<8)|182)+1);


        (13,182) : setPromoLevel(((13<<8)|182)+1);


        (14,182) : setPromoLevel(((14<<8)|182)+1);


        (15,182) : setPromoLevel(((15<<8)|182)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 958 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,183) : setPromoLevel(((0<<8)|183)+1);


        (1,183) : setPromoLevel(((1<<8)|183)+1);


        (2,183) : setPromoLevel(((2<<8)|183)+1);


        (3,183) : setPromoLevel(((3<<8)|183)+1);


        (4,183) : setPromoLevel(((4<<8)|183)+1);


        (5,183) : setPromoLevel(((5<<8)|183)+1);


        (6,183) : setPromoLevel(((6<<8)|183)+1);


        (7,183) : setPromoLevel(((7<<8)|183)+1);


        (8,183) : setPromoLevel(((8<<8)|183)+1);


        (9,183) : setPromoLevel(((9<<8)|183)+1);


        (10,183) : setPromoLevel(((10<<8)|183)+1);


        (11,183) : setPromoLevel(((11<<8)|183)+1);


        (12,183) : setPromoLevel(((12<<8)|183)+1);


        (13,183) : setPromoLevel(((13<<8)|183)+1);


        (14,183) : setPromoLevel(((14<<8)|183)+1);


        (15,183) : setPromoLevel(((15<<8)|183)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 963 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,184) : setPromoLevel(((0<<8)|184)+1);


        (1,184) : setPromoLevel(((1<<8)|184)+1);


        (2,184) : setPromoLevel(((2<<8)|184)+1);


        (3,184) : setPromoLevel(((3<<8)|184)+1);


        (4,184) : setPromoLevel(((4<<8)|184)+1);


        (5,184) : setPromoLevel(((5<<8)|184)+1);


        (6,184) : setPromoLevel(((6<<8)|184)+1);


        (7,184) : setPromoLevel(((7<<8)|184)+1);


        (8,184) : setPromoLevel(((8<<8)|184)+1);


        (9,184) : setPromoLevel(((9<<8)|184)+1);


        (10,184) : setPromoLevel(((10<<8)|184)+1);


        (11,184) : setPromoLevel(((11<<8)|184)+1);


        (12,184) : setPromoLevel(((12<<8)|184)+1);


        (13,184) : setPromoLevel(((13<<8)|184)+1);


        (14,184) : setPromoLevel(((14<<8)|184)+1);


        (15,184) : setPromoLevel(((15<<8)|184)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 968 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,185) : setPromoLevel(((0<<8)|185)+1);


        (1,185) : setPromoLevel(((1<<8)|185)+1);


        (2,185) : setPromoLevel(((2<<8)|185)+1);


        (3,185) : setPromoLevel(((3<<8)|185)+1);


        (4,185) : setPromoLevel(((4<<8)|185)+1);


        (5,185) : setPromoLevel(((5<<8)|185)+1);


        (6,185) : setPromoLevel(((6<<8)|185)+1);


        (7,185) : setPromoLevel(((7<<8)|185)+1);


        (8,185) : setPromoLevel(((8<<8)|185)+1);


        (9,185) : setPromoLevel(((9<<8)|185)+1);


        (10,185) : setPromoLevel(((10<<8)|185)+1);


        (11,185) : setPromoLevel(((11<<8)|185)+1);


        (12,185) : setPromoLevel(((12<<8)|185)+1);


        (13,185) : setPromoLevel(((13<<8)|185)+1);


        (14,185) : setPromoLevel(((14<<8)|185)+1);


        (15,185) : setPromoLevel(((15<<8)|185)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 973 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,186) : setPromoLevel(((0<<8)|186)+1);


        (1,186) : setPromoLevel(((1<<8)|186)+1);


        (2,186) : setPromoLevel(((2<<8)|186)+1);


        (3,186) : setPromoLevel(((3<<8)|186)+1);


        (4,186) : setPromoLevel(((4<<8)|186)+1);


        (5,186) : setPromoLevel(((5<<8)|186)+1);


        (6,186) : setPromoLevel(((6<<8)|186)+1);


        (7,186) : setPromoLevel(((7<<8)|186)+1);


        (8,186) : setPromoLevel(((8<<8)|186)+1);


        (9,186) : setPromoLevel(((9<<8)|186)+1);


        (10,186) : setPromoLevel(((10<<8)|186)+1);


        (11,186) : setPromoLevel(((11<<8)|186)+1);


        (12,186) : setPromoLevel(((12<<8)|186)+1);


        (13,186) : setPromoLevel(((13<<8)|186)+1);


        (14,186) : setPromoLevel(((14<<8)|186)+1);


        (15,186) : setPromoLevel(((15<<8)|186)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 978 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,187) : setPromoLevel(((0<<8)|187)+1);


        (1,187) : setPromoLevel(((1<<8)|187)+1);


        (2,187) : setPromoLevel(((2<<8)|187)+1);


        (3,187) : setPromoLevel(((3<<8)|187)+1);


        (4,187) : setPromoLevel(((4<<8)|187)+1);


        (5,187) : setPromoLevel(((5<<8)|187)+1);


        (6,187) : setPromoLevel(((6<<8)|187)+1);


        (7,187) : setPromoLevel(((7<<8)|187)+1);


        (8,187) : setPromoLevel(((8<<8)|187)+1);


        (9,187) : setPromoLevel(((9<<8)|187)+1);


        (10,187) : setPromoLevel(((10<<8)|187)+1);


        (11,187) : setPromoLevel(((11<<8)|187)+1);


        (12,187) : setPromoLevel(((12<<8)|187)+1);


        (13,187) : setPromoLevel(((13<<8)|187)+1);


        (14,187) : setPromoLevel(((14<<8)|187)+1);


        (15,187) : setPromoLevel(((15<<8)|187)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 983 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,188) : setPromoLevel(((0<<8)|188)+1);


        (1,188) : setPromoLevel(((1<<8)|188)+1);


        (2,188) : setPromoLevel(((2<<8)|188)+1);


        (3,188) : setPromoLevel(((3<<8)|188)+1);


        (4,188) : setPromoLevel(((4<<8)|188)+1);


        (5,188) : setPromoLevel(((5<<8)|188)+1);


        (6,188) : setPromoLevel(((6<<8)|188)+1);


        (7,188) : setPromoLevel(((7<<8)|188)+1);


        (8,188) : setPromoLevel(((8<<8)|188)+1);


        (9,188) : setPromoLevel(((9<<8)|188)+1);


        (10,188) : setPromoLevel(((10<<8)|188)+1);


        (11,188) : setPromoLevel(((11<<8)|188)+1);


        (12,188) : setPromoLevel(((12<<8)|188)+1);


        (13,188) : setPromoLevel(((13<<8)|188)+1);


        (14,188) : setPromoLevel(((14<<8)|188)+1);


        (15,188) : setPromoLevel(((15<<8)|188)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 988 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,189) : setPromoLevel(((0<<8)|189)+1);


        (1,189) : setPromoLevel(((1<<8)|189)+1);


        (2,189) : setPromoLevel(((2<<8)|189)+1);


        (3,189) : setPromoLevel(((3<<8)|189)+1);


        (4,189) : setPromoLevel(((4<<8)|189)+1);


        (5,189) : setPromoLevel(((5<<8)|189)+1);


        (6,189) : setPromoLevel(((6<<8)|189)+1);


        (7,189) : setPromoLevel(((7<<8)|189)+1);


        (8,189) : setPromoLevel(((8<<8)|189)+1);


        (9,189) : setPromoLevel(((9<<8)|189)+1);


        (10,189) : setPromoLevel(((10<<8)|189)+1);


        (11,189) : setPromoLevel(((11<<8)|189)+1);


        (12,189) : setPromoLevel(((12<<8)|189)+1);


        (13,189) : setPromoLevel(((13<<8)|189)+1);


        (14,189) : setPromoLevel(((14<<8)|189)+1);


        (15,189) : setPromoLevel(((15<<8)|189)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 993 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,190) : setPromoLevel(((0<<8)|190)+1);


        (1,190) : setPromoLevel(((1<<8)|190)+1);


        (2,190) : setPromoLevel(((2<<8)|190)+1);


        (3,190) : setPromoLevel(((3<<8)|190)+1);


        (4,190) : setPromoLevel(((4<<8)|190)+1);


        (5,190) : setPromoLevel(((5<<8)|190)+1);


        (6,190) : setPromoLevel(((6<<8)|190)+1);


        (7,190) : setPromoLevel(((7<<8)|190)+1);


        (8,190) : setPromoLevel(((8<<8)|190)+1);


        (9,190) : setPromoLevel(((9<<8)|190)+1);


        (10,190) : setPromoLevel(((10<<8)|190)+1);


        (11,190) : setPromoLevel(((11<<8)|190)+1);


        (12,190) : setPromoLevel(((12<<8)|190)+1);


        (13,190) : setPromoLevel(((13<<8)|190)+1);


        (14,190) : setPromoLevel(((14<<8)|190)+1);


        (15,190) : setPromoLevel(((15<<8)|190)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 998 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,191) : setPromoLevel(((0<<8)|191)+1);


        (1,191) : setPromoLevel(((1<<8)|191)+1);


        (2,191) : setPromoLevel(((2<<8)|191)+1);


        (3,191) : setPromoLevel(((3<<8)|191)+1);


        (4,191) : setPromoLevel(((4<<8)|191)+1);


        (5,191) : setPromoLevel(((5<<8)|191)+1);


        (6,191) : setPromoLevel(((6<<8)|191)+1);


        (7,191) : setPromoLevel(((7<<8)|191)+1);


        (8,191) : setPromoLevel(((8<<8)|191)+1);


        (9,191) : setPromoLevel(((9<<8)|191)+1);


        (10,191) : setPromoLevel(((10<<8)|191)+1);


        (11,191) : setPromoLevel(((11<<8)|191)+1);


        (12,191) : setPromoLevel(((12<<8)|191)+1);


        (13,191) : setPromoLevel(((13<<8)|191)+1);


        (14,191) : setPromoLevel(((14<<8)|191)+1);


        (15,191) : setPromoLevel(((15<<8)|191)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1003 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,192) : setPromoLevel(((0<<8)|192)+1);


        (1,192) : setPromoLevel(((1<<8)|192)+1);


        (2,192) : setPromoLevel(((2<<8)|192)+1);


        (3,192) : setPromoLevel(((3<<8)|192)+1);


        (4,192) : setPromoLevel(((4<<8)|192)+1);


        (5,192) : setPromoLevel(((5<<8)|192)+1);


        (6,192) : setPromoLevel(((6<<8)|192)+1);


        (7,192) : setPromoLevel(((7<<8)|192)+1);


        (8,192) : setPromoLevel(((8<<8)|192)+1);


        (9,192) : setPromoLevel(((9<<8)|192)+1);


        (10,192) : setPromoLevel(((10<<8)|192)+1);


        (11,192) : setPromoLevel(((11<<8)|192)+1);


        (12,192) : setPromoLevel(((12<<8)|192)+1);


        (13,192) : setPromoLevel(((13<<8)|192)+1);


        (14,192) : setPromoLevel(((14<<8)|192)+1);


        (15,192) : setPromoLevel(((15<<8)|192)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1008 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,193) : setPromoLevel(((0<<8)|193)+1);


        (1,193) : setPromoLevel(((1<<8)|193)+1);


        (2,193) : setPromoLevel(((2<<8)|193)+1);


        (3,193) : setPromoLevel(((3<<8)|193)+1);


        (4,193) : setPromoLevel(((4<<8)|193)+1);


        (5,193) : setPromoLevel(((5<<8)|193)+1);


        (6,193) : setPromoLevel(((6<<8)|193)+1);


        (7,193) : setPromoLevel(((7<<8)|193)+1);


        (8,193) : setPromoLevel(((8<<8)|193)+1);


        (9,193) : setPromoLevel(((9<<8)|193)+1);


        (10,193) : setPromoLevel(((10<<8)|193)+1);


        (11,193) : setPromoLevel(((11<<8)|193)+1);


        (12,193) : setPromoLevel(((12<<8)|193)+1);


        (13,193) : setPromoLevel(((13<<8)|193)+1);


        (14,193) : setPromoLevel(((14<<8)|193)+1);


        (15,193) : setPromoLevel(((15<<8)|193)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1013 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,194) : setPromoLevel(((0<<8)|194)+1);


        (1,194) : setPromoLevel(((1<<8)|194)+1);


        (2,194) : setPromoLevel(((2<<8)|194)+1);


        (3,194) : setPromoLevel(((3<<8)|194)+1);


        (4,194) : setPromoLevel(((4<<8)|194)+1);


        (5,194) : setPromoLevel(((5<<8)|194)+1);


        (6,194) : setPromoLevel(((6<<8)|194)+1);


        (7,194) : setPromoLevel(((7<<8)|194)+1);


        (8,194) : setPromoLevel(((8<<8)|194)+1);


        (9,194) : setPromoLevel(((9<<8)|194)+1);


        (10,194) : setPromoLevel(((10<<8)|194)+1);


        (11,194) : setPromoLevel(((11<<8)|194)+1);


        (12,194) : setPromoLevel(((12<<8)|194)+1);


        (13,194) : setPromoLevel(((13<<8)|194)+1);


        (14,194) : setPromoLevel(((14<<8)|194)+1);


        (15,194) : setPromoLevel(((15<<8)|194)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1018 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,195) : setPromoLevel(((0<<8)|195)+1);


        (1,195) : setPromoLevel(((1<<8)|195)+1);


        (2,195) : setPromoLevel(((2<<8)|195)+1);


        (3,195) : setPromoLevel(((3<<8)|195)+1);


        (4,195) : setPromoLevel(((4<<8)|195)+1);


        (5,195) : setPromoLevel(((5<<8)|195)+1);


        (6,195) : setPromoLevel(((6<<8)|195)+1);


        (7,195) : setPromoLevel(((7<<8)|195)+1);


        (8,195) : setPromoLevel(((8<<8)|195)+1);


        (9,195) : setPromoLevel(((9<<8)|195)+1);


        (10,195) : setPromoLevel(((10<<8)|195)+1);


        (11,195) : setPromoLevel(((11<<8)|195)+1);


        (12,195) : setPromoLevel(((12<<8)|195)+1);


        (13,195) : setPromoLevel(((13<<8)|195)+1);


        (14,195) : setPromoLevel(((14<<8)|195)+1);


        (15,195) : setPromoLevel(((15<<8)|195)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1023 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,196) : setPromoLevel(((0<<8)|196)+1);


        (1,196) : setPromoLevel(((1<<8)|196)+1);


        (2,196) : setPromoLevel(((2<<8)|196)+1);


        (3,196) : setPromoLevel(((3<<8)|196)+1);


        (4,196) : setPromoLevel(((4<<8)|196)+1);


        (5,196) : setPromoLevel(((5<<8)|196)+1);


        (6,196) : setPromoLevel(((6<<8)|196)+1);


        (7,196) : setPromoLevel(((7<<8)|196)+1);


        (8,196) : setPromoLevel(((8<<8)|196)+1);


        (9,196) : setPromoLevel(((9<<8)|196)+1);


        (10,196) : setPromoLevel(((10<<8)|196)+1);


        (11,196) : setPromoLevel(((11<<8)|196)+1);


        (12,196) : setPromoLevel(((12<<8)|196)+1);


        (13,196) : setPromoLevel(((13<<8)|196)+1);


        (14,196) : setPromoLevel(((14<<8)|196)+1);


        (15,196) : setPromoLevel(((15<<8)|196)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1028 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,197) : setPromoLevel(((0<<8)|197)+1);


        (1,197) : setPromoLevel(((1<<8)|197)+1);


        (2,197) : setPromoLevel(((2<<8)|197)+1);


        (3,197) : setPromoLevel(((3<<8)|197)+1);


        (4,197) : setPromoLevel(((4<<8)|197)+1);


        (5,197) : setPromoLevel(((5<<8)|197)+1);


        (6,197) : setPromoLevel(((6<<8)|197)+1);


        (7,197) : setPromoLevel(((7<<8)|197)+1);


        (8,197) : setPromoLevel(((8<<8)|197)+1);


        (9,197) : setPromoLevel(((9<<8)|197)+1);


        (10,197) : setPromoLevel(((10<<8)|197)+1);


        (11,197) : setPromoLevel(((11<<8)|197)+1);


        (12,197) : setPromoLevel(((12<<8)|197)+1);


        (13,197) : setPromoLevel(((13<<8)|197)+1);


        (14,197) : setPromoLevel(((14<<8)|197)+1);


        (15,197) : setPromoLevel(((15<<8)|197)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1033 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,198) : setPromoLevel(((0<<8)|198)+1);


        (1,198) : setPromoLevel(((1<<8)|198)+1);


        (2,198) : setPromoLevel(((2<<8)|198)+1);


        (3,198) : setPromoLevel(((3<<8)|198)+1);


        (4,198) : setPromoLevel(((4<<8)|198)+1);


        (5,198) : setPromoLevel(((5<<8)|198)+1);


        (6,198) : setPromoLevel(((6<<8)|198)+1);


        (7,198) : setPromoLevel(((7<<8)|198)+1);


        (8,198) : setPromoLevel(((8<<8)|198)+1);


        (9,198) : setPromoLevel(((9<<8)|198)+1);


        (10,198) : setPromoLevel(((10<<8)|198)+1);


        (11,198) : setPromoLevel(((11<<8)|198)+1);


        (12,198) : setPromoLevel(((12<<8)|198)+1);


        (13,198) : setPromoLevel(((13<<8)|198)+1);


        (14,198) : setPromoLevel(((14<<8)|198)+1);


        (15,198) : setPromoLevel(((15<<8)|198)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1038 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,199) : setPromoLevel(((0<<8)|199)+1);


        (1,199) : setPromoLevel(((1<<8)|199)+1);


        (2,199) : setPromoLevel(((2<<8)|199)+1);


        (3,199) : setPromoLevel(((3<<8)|199)+1);


        (4,199) : setPromoLevel(((4<<8)|199)+1);


        (5,199) : setPromoLevel(((5<<8)|199)+1);


        (6,199) : setPromoLevel(((6<<8)|199)+1);


        (7,199) : setPromoLevel(((7<<8)|199)+1);


        (8,199) : setPromoLevel(((8<<8)|199)+1);


        (9,199) : setPromoLevel(((9<<8)|199)+1);


        (10,199) : setPromoLevel(((10<<8)|199)+1);


        (11,199) : setPromoLevel(((11<<8)|199)+1);


        (12,199) : setPromoLevel(((12<<8)|199)+1);


        (13,199) : setPromoLevel(((13<<8)|199)+1);


        (14,199) : setPromoLevel(((14<<8)|199)+1);


        (15,199) : setPromoLevel(((15<<8)|199)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1043 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,200) : setPromoLevel(((0<<8)|200)+1);


        (1,200) : setPromoLevel(((1<<8)|200)+1);


        (2,200) : setPromoLevel(((2<<8)|200)+1);


        (3,200) : setPromoLevel(((3<<8)|200)+1);


        (4,200) : setPromoLevel(((4<<8)|200)+1);


        (5,200) : setPromoLevel(((5<<8)|200)+1);


        (6,200) : setPromoLevel(((6<<8)|200)+1);


        (7,200) : setPromoLevel(((7<<8)|200)+1);


        (8,200) : setPromoLevel(((8<<8)|200)+1);


        (9,200) : setPromoLevel(((9<<8)|200)+1);


        (10,200) : setPromoLevel(((10<<8)|200)+1);


        (11,200) : setPromoLevel(((11<<8)|200)+1);


        (12,200) : setPromoLevel(((12<<8)|200)+1);


        (13,200) : setPromoLevel(((13<<8)|200)+1);


        (14,200) : setPromoLevel(((14<<8)|200)+1);


        (15,200) : setPromoLevel(((15<<8)|200)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1048 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,201) : setPromoLevel(((0<<8)|201)+1);


        (1,201) : setPromoLevel(((1<<8)|201)+1);


        (2,201) : setPromoLevel(((2<<8)|201)+1);


        (3,201) : setPromoLevel(((3<<8)|201)+1);


        (4,201) : setPromoLevel(((4<<8)|201)+1);


        (5,201) : setPromoLevel(((5<<8)|201)+1);


        (6,201) : setPromoLevel(((6<<8)|201)+1);


        (7,201) : setPromoLevel(((7<<8)|201)+1);


        (8,201) : setPromoLevel(((8<<8)|201)+1);


        (9,201) : setPromoLevel(((9<<8)|201)+1);


        (10,201) : setPromoLevel(((10<<8)|201)+1);


        (11,201) : setPromoLevel(((11<<8)|201)+1);


        (12,201) : setPromoLevel(((12<<8)|201)+1);


        (13,201) : setPromoLevel(((13<<8)|201)+1);


        (14,201) : setPromoLevel(((14<<8)|201)+1);


        (15,201) : setPromoLevel(((15<<8)|201)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1053 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,202) : setPromoLevel(((0<<8)|202)+1);


        (1,202) : setPromoLevel(((1<<8)|202)+1);


        (2,202) : setPromoLevel(((2<<8)|202)+1);


        (3,202) : setPromoLevel(((3<<8)|202)+1);


        (4,202) : setPromoLevel(((4<<8)|202)+1);


        (5,202) : setPromoLevel(((5<<8)|202)+1);


        (6,202) : setPromoLevel(((6<<8)|202)+1);


        (7,202) : setPromoLevel(((7<<8)|202)+1);


        (8,202) : setPromoLevel(((8<<8)|202)+1);


        (9,202) : setPromoLevel(((9<<8)|202)+1);


        (10,202) : setPromoLevel(((10<<8)|202)+1);


        (11,202) : setPromoLevel(((11<<8)|202)+1);


        (12,202) : setPromoLevel(((12<<8)|202)+1);


        (13,202) : setPromoLevel(((13<<8)|202)+1);


        (14,202) : setPromoLevel(((14<<8)|202)+1);


        (15,202) : setPromoLevel(((15<<8)|202)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1058 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,203) : setPromoLevel(((0<<8)|203)+1);


        (1,203) : setPromoLevel(((1<<8)|203)+1);


        (2,203) : setPromoLevel(((2<<8)|203)+1);


        (3,203) : setPromoLevel(((3<<8)|203)+1);


        (4,203) : setPromoLevel(((4<<8)|203)+1);


        (5,203) : setPromoLevel(((5<<8)|203)+1);


        (6,203) : setPromoLevel(((6<<8)|203)+1);


        (7,203) : setPromoLevel(((7<<8)|203)+1);


        (8,203) : setPromoLevel(((8<<8)|203)+1);


        (9,203) : setPromoLevel(((9<<8)|203)+1);


        (10,203) : setPromoLevel(((10<<8)|203)+1);


        (11,203) : setPromoLevel(((11<<8)|203)+1);


        (12,203) : setPromoLevel(((12<<8)|203)+1);


        (13,203) : setPromoLevel(((13<<8)|203)+1);


        (14,203) : setPromoLevel(((14<<8)|203)+1);


        (15,203) : setPromoLevel(((15<<8)|203)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1063 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,204) : setPromoLevel(((0<<8)|204)+1);


        (1,204) : setPromoLevel(((1<<8)|204)+1);


        (2,204) : setPromoLevel(((2<<8)|204)+1);


        (3,204) : setPromoLevel(((3<<8)|204)+1);


        (4,204) : setPromoLevel(((4<<8)|204)+1);


        (5,204) : setPromoLevel(((5<<8)|204)+1);


        (6,204) : setPromoLevel(((6<<8)|204)+1);


        (7,204) : setPromoLevel(((7<<8)|204)+1);


        (8,204) : setPromoLevel(((8<<8)|204)+1);


        (9,204) : setPromoLevel(((9<<8)|204)+1);


        (10,204) : setPromoLevel(((10<<8)|204)+1);


        (11,204) : setPromoLevel(((11<<8)|204)+1);


        (12,204) : setPromoLevel(((12<<8)|204)+1);


        (13,204) : setPromoLevel(((13<<8)|204)+1);


        (14,204) : setPromoLevel(((14<<8)|204)+1);


        (15,204) : setPromoLevel(((15<<8)|204)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1068 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,205) : setPromoLevel(((0<<8)|205)+1);


        (1,205) : setPromoLevel(((1<<8)|205)+1);


        (2,205) : setPromoLevel(((2<<8)|205)+1);


        (3,205) : setPromoLevel(((3<<8)|205)+1);


        (4,205) : setPromoLevel(((4<<8)|205)+1);


        (5,205) : setPromoLevel(((5<<8)|205)+1);


        (6,205) : setPromoLevel(((6<<8)|205)+1);


        (7,205) : setPromoLevel(((7<<8)|205)+1);


        (8,205) : setPromoLevel(((8<<8)|205)+1);


        (9,205) : setPromoLevel(((9<<8)|205)+1);


        (10,205) : setPromoLevel(((10<<8)|205)+1);


        (11,205) : setPromoLevel(((11<<8)|205)+1);


        (12,205) : setPromoLevel(((12<<8)|205)+1);


        (13,205) : setPromoLevel(((13<<8)|205)+1);


        (14,205) : setPromoLevel(((14<<8)|205)+1);


        (15,205) : setPromoLevel(((15<<8)|205)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1073 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,206) : setPromoLevel(((0<<8)|206)+1);


        (1,206) : setPromoLevel(((1<<8)|206)+1);


        (2,206) : setPromoLevel(((2<<8)|206)+1);


        (3,206) : setPromoLevel(((3<<8)|206)+1);


        (4,206) : setPromoLevel(((4<<8)|206)+1);


        (5,206) : setPromoLevel(((5<<8)|206)+1);


        (6,206) : setPromoLevel(((6<<8)|206)+1);


        (7,206) : setPromoLevel(((7<<8)|206)+1);


        (8,206) : setPromoLevel(((8<<8)|206)+1);


        (9,206) : setPromoLevel(((9<<8)|206)+1);


        (10,206) : setPromoLevel(((10<<8)|206)+1);


        (11,206) : setPromoLevel(((11<<8)|206)+1);


        (12,206) : setPromoLevel(((12<<8)|206)+1);


        (13,206) : setPromoLevel(((13<<8)|206)+1);


        (14,206) : setPromoLevel(((14<<8)|206)+1);


        (15,206) : setPromoLevel(((15<<8)|206)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1078 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,207) : setPromoLevel(((0<<8)|207)+1);


        (1,207) : setPromoLevel(((1<<8)|207)+1);


        (2,207) : setPromoLevel(((2<<8)|207)+1);


        (3,207) : setPromoLevel(((3<<8)|207)+1);


        (4,207) : setPromoLevel(((4<<8)|207)+1);


        (5,207) : setPromoLevel(((5<<8)|207)+1);


        (6,207) : setPromoLevel(((6<<8)|207)+1);


        (7,207) : setPromoLevel(((7<<8)|207)+1);


        (8,207) : setPromoLevel(((8<<8)|207)+1);


        (9,207) : setPromoLevel(((9<<8)|207)+1);


        (10,207) : setPromoLevel(((10<<8)|207)+1);


        (11,207) : setPromoLevel(((11<<8)|207)+1);


        (12,207) : setPromoLevel(((12<<8)|207)+1);


        (13,207) : setPromoLevel(((13<<8)|207)+1);


        (14,207) : setPromoLevel(((14<<8)|207)+1);


        (15,207) : setPromoLevel(((15<<8)|207)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1083 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,208) : setPromoLevel(((0<<8)|208)+1);


        (1,208) : setPromoLevel(((1<<8)|208)+1);


        (2,208) : setPromoLevel(((2<<8)|208)+1);


        (3,208) : setPromoLevel(((3<<8)|208)+1);


        (4,208) : setPromoLevel(((4<<8)|208)+1);


        (5,208) : setPromoLevel(((5<<8)|208)+1);


        (6,208) : setPromoLevel(((6<<8)|208)+1);


        (7,208) : setPromoLevel(((7<<8)|208)+1);


        (8,208) : setPromoLevel(((8<<8)|208)+1);


        (9,208) : setPromoLevel(((9<<8)|208)+1);


        (10,208) : setPromoLevel(((10<<8)|208)+1);


        (11,208) : setPromoLevel(((11<<8)|208)+1);


        (12,208) : setPromoLevel(((12<<8)|208)+1);


        (13,208) : setPromoLevel(((13<<8)|208)+1);


        (14,208) : setPromoLevel(((14<<8)|208)+1);


        (15,208) : setPromoLevel(((15<<8)|208)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1088 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,209) : setPromoLevel(((0<<8)|209)+1);


        (1,209) : setPromoLevel(((1<<8)|209)+1);


        (2,209) : setPromoLevel(((2<<8)|209)+1);


        (3,209) : setPromoLevel(((3<<8)|209)+1);


        (4,209) : setPromoLevel(((4<<8)|209)+1);


        (5,209) : setPromoLevel(((5<<8)|209)+1);


        (6,209) : setPromoLevel(((6<<8)|209)+1);


        (7,209) : setPromoLevel(((7<<8)|209)+1);


        (8,209) : setPromoLevel(((8<<8)|209)+1);


        (9,209) : setPromoLevel(((9<<8)|209)+1);


        (10,209) : setPromoLevel(((10<<8)|209)+1);


        (11,209) : setPromoLevel(((11<<8)|209)+1);


        (12,209) : setPromoLevel(((12<<8)|209)+1);


        (13,209) : setPromoLevel(((13<<8)|209)+1);


        (14,209) : setPromoLevel(((14<<8)|209)+1);


        (15,209) : setPromoLevel(((15<<8)|209)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1093 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,210) : setPromoLevel(((0<<8)|210)+1);


        (1,210) : setPromoLevel(((1<<8)|210)+1);


        (2,210) : setPromoLevel(((2<<8)|210)+1);


        (3,210) : setPromoLevel(((3<<8)|210)+1);


        (4,210) : setPromoLevel(((4<<8)|210)+1);


        (5,210) : setPromoLevel(((5<<8)|210)+1);


        (6,210) : setPromoLevel(((6<<8)|210)+1);


        (7,210) : setPromoLevel(((7<<8)|210)+1);


        (8,210) : setPromoLevel(((8<<8)|210)+1);


        (9,210) : setPromoLevel(((9<<8)|210)+1);


        (10,210) : setPromoLevel(((10<<8)|210)+1);


        (11,210) : setPromoLevel(((11<<8)|210)+1);


        (12,210) : setPromoLevel(((12<<8)|210)+1);


        (13,210) : setPromoLevel(((13<<8)|210)+1);


        (14,210) : setPromoLevel(((14<<8)|210)+1);


        (15,210) : setPromoLevel(((15<<8)|210)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1098 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,211) : setPromoLevel(((0<<8)|211)+1);


        (1,211) : setPromoLevel(((1<<8)|211)+1);


        (2,211) : setPromoLevel(((2<<8)|211)+1);


        (3,211) : setPromoLevel(((3<<8)|211)+1);


        (4,211) : setPromoLevel(((4<<8)|211)+1);


        (5,211) : setPromoLevel(((5<<8)|211)+1);


        (6,211) : setPromoLevel(((6<<8)|211)+1);


        (7,211) : setPromoLevel(((7<<8)|211)+1);


        (8,211) : setPromoLevel(((8<<8)|211)+1);


        (9,211) : setPromoLevel(((9<<8)|211)+1);


        (10,211) : setPromoLevel(((10<<8)|211)+1);


        (11,211) : setPromoLevel(((11<<8)|211)+1);


        (12,211) : setPromoLevel(((12<<8)|211)+1);


        (13,211) : setPromoLevel(((13<<8)|211)+1);


        (14,211) : setPromoLevel(((14<<8)|211)+1);


        (15,211) : setPromoLevel(((15<<8)|211)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1103 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,212) : setPromoLevel(((0<<8)|212)+1);


        (1,212) : setPromoLevel(((1<<8)|212)+1);


        (2,212) : setPromoLevel(((2<<8)|212)+1);


        (3,212) : setPromoLevel(((3<<8)|212)+1);


        (4,212) : setPromoLevel(((4<<8)|212)+1);


        (5,212) : setPromoLevel(((5<<8)|212)+1);


        (6,212) : setPromoLevel(((6<<8)|212)+1);


        (7,212) : setPromoLevel(((7<<8)|212)+1);


        (8,212) : setPromoLevel(((8<<8)|212)+1);


        (9,212) : setPromoLevel(((9<<8)|212)+1);


        (10,212) : setPromoLevel(((10<<8)|212)+1);


        (11,212) : setPromoLevel(((11<<8)|212)+1);


        (12,212) : setPromoLevel(((12<<8)|212)+1);


        (13,212) : setPromoLevel(((13<<8)|212)+1);


        (14,212) : setPromoLevel(((14<<8)|212)+1);


        (15,212) : setPromoLevel(((15<<8)|212)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1108 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,213) : setPromoLevel(((0<<8)|213)+1);


        (1,213) : setPromoLevel(((1<<8)|213)+1);


        (2,213) : setPromoLevel(((2<<8)|213)+1);


        (3,213) : setPromoLevel(((3<<8)|213)+1);


        (4,213) : setPromoLevel(((4<<8)|213)+1);


        (5,213) : setPromoLevel(((5<<8)|213)+1);


        (6,213) : setPromoLevel(((6<<8)|213)+1);


        (7,213) : setPromoLevel(((7<<8)|213)+1);


        (8,213) : setPromoLevel(((8<<8)|213)+1);


        (9,213) : setPromoLevel(((9<<8)|213)+1);


        (10,213) : setPromoLevel(((10<<8)|213)+1);


        (11,213) : setPromoLevel(((11<<8)|213)+1);


        (12,213) : setPromoLevel(((12<<8)|213)+1);


        (13,213) : setPromoLevel(((13<<8)|213)+1);


        (14,213) : setPromoLevel(((14<<8)|213)+1);


        (15,213) : setPromoLevel(((15<<8)|213)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1113 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,214) : setPromoLevel(((0<<8)|214)+1);


        (1,214) : setPromoLevel(((1<<8)|214)+1);


        (2,214) : setPromoLevel(((2<<8)|214)+1);


        (3,214) : setPromoLevel(((3<<8)|214)+1);


        (4,214) : setPromoLevel(((4<<8)|214)+1);


        (5,214) : setPromoLevel(((5<<8)|214)+1);


        (6,214) : setPromoLevel(((6<<8)|214)+1);


        (7,214) : setPromoLevel(((7<<8)|214)+1);


        (8,214) : setPromoLevel(((8<<8)|214)+1);


        (9,214) : setPromoLevel(((9<<8)|214)+1);


        (10,214) : setPromoLevel(((10<<8)|214)+1);


        (11,214) : setPromoLevel(((11<<8)|214)+1);


        (12,214) : setPromoLevel(((12<<8)|214)+1);


        (13,214) : setPromoLevel(((13<<8)|214)+1);


        (14,214) : setPromoLevel(((14<<8)|214)+1);


        (15,214) : setPromoLevel(((15<<8)|214)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1118 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,215) : setPromoLevel(((0<<8)|215)+1);


        (1,215) : setPromoLevel(((1<<8)|215)+1);


        (2,215) : setPromoLevel(((2<<8)|215)+1);


        (3,215) : setPromoLevel(((3<<8)|215)+1);


        (4,215) : setPromoLevel(((4<<8)|215)+1);


        (5,215) : setPromoLevel(((5<<8)|215)+1);


        (6,215) : setPromoLevel(((6<<8)|215)+1);


        (7,215) : setPromoLevel(((7<<8)|215)+1);


        (8,215) : setPromoLevel(((8<<8)|215)+1);


        (9,215) : setPromoLevel(((9<<8)|215)+1);


        (10,215) : setPromoLevel(((10<<8)|215)+1);


        (11,215) : setPromoLevel(((11<<8)|215)+1);


        (12,215) : setPromoLevel(((12<<8)|215)+1);


        (13,215) : setPromoLevel(((13<<8)|215)+1);


        (14,215) : setPromoLevel(((14<<8)|215)+1);


        (15,215) : setPromoLevel(((15<<8)|215)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1123 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,216) : setPromoLevel(((0<<8)|216)+1);


        (1,216) : setPromoLevel(((1<<8)|216)+1);


        (2,216) : setPromoLevel(((2<<8)|216)+1);


        (3,216) : setPromoLevel(((3<<8)|216)+1);


        (4,216) : setPromoLevel(((4<<8)|216)+1);


        (5,216) : setPromoLevel(((5<<8)|216)+1);


        (6,216) : setPromoLevel(((6<<8)|216)+1);


        (7,216) : setPromoLevel(((7<<8)|216)+1);


        (8,216) : setPromoLevel(((8<<8)|216)+1);


        (9,216) : setPromoLevel(((9<<8)|216)+1);


        (10,216) : setPromoLevel(((10<<8)|216)+1);


        (11,216) : setPromoLevel(((11<<8)|216)+1);


        (12,216) : setPromoLevel(((12<<8)|216)+1);


        (13,216) : setPromoLevel(((13<<8)|216)+1);


        (14,216) : setPromoLevel(((14<<8)|216)+1);


        (15,216) : setPromoLevel(((15<<8)|216)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1128 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,217) : setPromoLevel(((0<<8)|217)+1);


        (1,217) : setPromoLevel(((1<<8)|217)+1);


        (2,217) : setPromoLevel(((2<<8)|217)+1);


        (3,217) : setPromoLevel(((3<<8)|217)+1);


        (4,217) : setPromoLevel(((4<<8)|217)+1);


        (5,217) : setPromoLevel(((5<<8)|217)+1);


        (6,217) : setPromoLevel(((6<<8)|217)+1);


        (7,217) : setPromoLevel(((7<<8)|217)+1);


        (8,217) : setPromoLevel(((8<<8)|217)+1);


        (9,217) : setPromoLevel(((9<<8)|217)+1);


        (10,217) : setPromoLevel(((10<<8)|217)+1);


        (11,217) : setPromoLevel(((11<<8)|217)+1);


        (12,217) : setPromoLevel(((12<<8)|217)+1);


        (13,217) : setPromoLevel(((13<<8)|217)+1);


        (14,217) : setPromoLevel(((14<<8)|217)+1);


        (15,217) : setPromoLevel(((15<<8)|217)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1133 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,218) : setPromoLevel(((0<<8)|218)+1);


        (1,218) : setPromoLevel(((1<<8)|218)+1);


        (2,218) : setPromoLevel(((2<<8)|218)+1);


        (3,218) : setPromoLevel(((3<<8)|218)+1);


        (4,218) : setPromoLevel(((4<<8)|218)+1);


        (5,218) : setPromoLevel(((5<<8)|218)+1);


        (6,218) : setPromoLevel(((6<<8)|218)+1);


        (7,218) : setPromoLevel(((7<<8)|218)+1);


        (8,218) : setPromoLevel(((8<<8)|218)+1);


        (9,218) : setPromoLevel(((9<<8)|218)+1);


        (10,218) : setPromoLevel(((10<<8)|218)+1);


        (11,218) : setPromoLevel(((11<<8)|218)+1);


        (12,218) : setPromoLevel(((12<<8)|218)+1);


        (13,218) : setPromoLevel(((13<<8)|218)+1);


        (14,218) : setPromoLevel(((14<<8)|218)+1);


        (15,218) : setPromoLevel(((15<<8)|218)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1138 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,219) : setPromoLevel(((0<<8)|219)+1);


        (1,219) : setPromoLevel(((1<<8)|219)+1);


        (2,219) : setPromoLevel(((2<<8)|219)+1);


        (3,219) : setPromoLevel(((3<<8)|219)+1);


        (4,219) : setPromoLevel(((4<<8)|219)+1);


        (5,219) : setPromoLevel(((5<<8)|219)+1);


        (6,219) : setPromoLevel(((6<<8)|219)+1);


        (7,219) : setPromoLevel(((7<<8)|219)+1);


        (8,219) : setPromoLevel(((8<<8)|219)+1);


        (9,219) : setPromoLevel(((9<<8)|219)+1);


        (10,219) : setPromoLevel(((10<<8)|219)+1);


        (11,219) : setPromoLevel(((11<<8)|219)+1);


        (12,219) : setPromoLevel(((12<<8)|219)+1);


        (13,219) : setPromoLevel(((13<<8)|219)+1);


        (14,219) : setPromoLevel(((14<<8)|219)+1);


        (15,219) : setPromoLevel(((15<<8)|219)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1143 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,220) : setPromoLevel(((0<<8)|220)+1);


        (1,220) : setPromoLevel(((1<<8)|220)+1);


        (2,220) : setPromoLevel(((2<<8)|220)+1);


        (3,220) : setPromoLevel(((3<<8)|220)+1);


        (4,220) : setPromoLevel(((4<<8)|220)+1);


        (5,220) : setPromoLevel(((5<<8)|220)+1);


        (6,220) : setPromoLevel(((6<<8)|220)+1);


        (7,220) : setPromoLevel(((7<<8)|220)+1);


        (8,220) : setPromoLevel(((8<<8)|220)+1);


        (9,220) : setPromoLevel(((9<<8)|220)+1);


        (10,220) : setPromoLevel(((10<<8)|220)+1);


        (11,220) : setPromoLevel(((11<<8)|220)+1);


        (12,220) : setPromoLevel(((12<<8)|220)+1);


        (13,220) : setPromoLevel(((13<<8)|220)+1);


        (14,220) : setPromoLevel(((14<<8)|220)+1);


        (15,220) : setPromoLevel(((15<<8)|220)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1148 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,221) : setPromoLevel(((0<<8)|221)+1);


        (1,221) : setPromoLevel(((1<<8)|221)+1);


        (2,221) : setPromoLevel(((2<<8)|221)+1);


        (3,221) : setPromoLevel(((3<<8)|221)+1);


        (4,221) : setPromoLevel(((4<<8)|221)+1);


        (5,221) : setPromoLevel(((5<<8)|221)+1);


        (6,221) : setPromoLevel(((6<<8)|221)+1);


        (7,221) : setPromoLevel(((7<<8)|221)+1);


        (8,221) : setPromoLevel(((8<<8)|221)+1);


        (9,221) : setPromoLevel(((9<<8)|221)+1);


        (10,221) : setPromoLevel(((10<<8)|221)+1);


        (11,221) : setPromoLevel(((11<<8)|221)+1);


        (12,221) : setPromoLevel(((12<<8)|221)+1);


        (13,221) : setPromoLevel(((13<<8)|221)+1);


        (14,221) : setPromoLevel(((14<<8)|221)+1);


        (15,221) : setPromoLevel(((15<<8)|221)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1153 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,222) : setPromoLevel(((0<<8)|222)+1);


        (1,222) : setPromoLevel(((1<<8)|222)+1);


        (2,222) : setPromoLevel(((2<<8)|222)+1);


        (3,222) : setPromoLevel(((3<<8)|222)+1);


        (4,222) : setPromoLevel(((4<<8)|222)+1);


        (5,222) : setPromoLevel(((5<<8)|222)+1);


        (6,222) : setPromoLevel(((6<<8)|222)+1);


        (7,222) : setPromoLevel(((7<<8)|222)+1);


        (8,222) : setPromoLevel(((8<<8)|222)+1);


        (9,222) : setPromoLevel(((9<<8)|222)+1);


        (10,222) : setPromoLevel(((10<<8)|222)+1);


        (11,222) : setPromoLevel(((11<<8)|222)+1);


        (12,222) : setPromoLevel(((12<<8)|222)+1);


        (13,222) : setPromoLevel(((13<<8)|222)+1);


        (14,222) : setPromoLevel(((14<<8)|222)+1);


        (15,222) : setPromoLevel(((15<<8)|222)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1158 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,223) : setPromoLevel(((0<<8)|223)+1);


        (1,223) : setPromoLevel(((1<<8)|223)+1);


        (2,223) : setPromoLevel(((2<<8)|223)+1);


        (3,223) : setPromoLevel(((3<<8)|223)+1);


        (4,223) : setPromoLevel(((4<<8)|223)+1);


        (5,223) : setPromoLevel(((5<<8)|223)+1);


        (6,223) : setPromoLevel(((6<<8)|223)+1);


        (7,223) : setPromoLevel(((7<<8)|223)+1);


        (8,223) : setPromoLevel(((8<<8)|223)+1);


        (9,223) : setPromoLevel(((9<<8)|223)+1);


        (10,223) : setPromoLevel(((10<<8)|223)+1);


        (11,223) : setPromoLevel(((11<<8)|223)+1);


        (12,223) : setPromoLevel(((12<<8)|223)+1);


        (13,223) : setPromoLevel(((13<<8)|223)+1);


        (14,223) : setPromoLevel(((14<<8)|223)+1);


        (15,223) : setPromoLevel(((15<<8)|223)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1163 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,224) : setPromoLevel(((0<<8)|224)+1);


        (1,224) : setPromoLevel(((1<<8)|224)+1);


        (2,224) : setPromoLevel(((2<<8)|224)+1);


        (3,224) : setPromoLevel(((3<<8)|224)+1);


        (4,224) : setPromoLevel(((4<<8)|224)+1);


        (5,224) : setPromoLevel(((5<<8)|224)+1);


        (6,224) : setPromoLevel(((6<<8)|224)+1);


        (7,224) : setPromoLevel(((7<<8)|224)+1);


        (8,224) : setPromoLevel(((8<<8)|224)+1);


        (9,224) : setPromoLevel(((9<<8)|224)+1);


        (10,224) : setPromoLevel(((10<<8)|224)+1);


        (11,224) : setPromoLevel(((11<<8)|224)+1);


        (12,224) : setPromoLevel(((12<<8)|224)+1);


        (13,224) : setPromoLevel(((13<<8)|224)+1);


        (14,224) : setPromoLevel(((14<<8)|224)+1);


        (15,224) : setPromoLevel(((15<<8)|224)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1168 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,225) : setPromoLevel(((0<<8)|225)+1);


        (1,225) : setPromoLevel(((1<<8)|225)+1);


        (2,225) : setPromoLevel(((2<<8)|225)+1);


        (3,225) : setPromoLevel(((3<<8)|225)+1);


        (4,225) : setPromoLevel(((4<<8)|225)+1);


        (5,225) : setPromoLevel(((5<<8)|225)+1);


        (6,225) : setPromoLevel(((6<<8)|225)+1);


        (7,225) : setPromoLevel(((7<<8)|225)+1);


        (8,225) : setPromoLevel(((8<<8)|225)+1);


        (9,225) : setPromoLevel(((9<<8)|225)+1);


        (10,225) : setPromoLevel(((10<<8)|225)+1);


        (11,225) : setPromoLevel(((11<<8)|225)+1);


        (12,225) : setPromoLevel(((12<<8)|225)+1);


        (13,225) : setPromoLevel(((13<<8)|225)+1);


        (14,225) : setPromoLevel(((14<<8)|225)+1);


        (15,225) : setPromoLevel(((15<<8)|225)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1173 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,226) : setPromoLevel(((0<<8)|226)+1);


        (1,226) : setPromoLevel(((1<<8)|226)+1);


        (2,226) : setPromoLevel(((2<<8)|226)+1);


        (3,226) : setPromoLevel(((3<<8)|226)+1);


        (4,226) : setPromoLevel(((4<<8)|226)+1);


        (5,226) : setPromoLevel(((5<<8)|226)+1);


        (6,226) : setPromoLevel(((6<<8)|226)+1);


        (7,226) : setPromoLevel(((7<<8)|226)+1);


        (8,226) : setPromoLevel(((8<<8)|226)+1);


        (9,226) : setPromoLevel(((9<<8)|226)+1);


        (10,226) : setPromoLevel(((10<<8)|226)+1);


        (11,226) : setPromoLevel(((11<<8)|226)+1);


        (12,226) : setPromoLevel(((12<<8)|226)+1);


        (13,226) : setPromoLevel(((13<<8)|226)+1);


        (14,226) : setPromoLevel(((14<<8)|226)+1);


        (15,226) : setPromoLevel(((15<<8)|226)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1178 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,227) : setPromoLevel(((0<<8)|227)+1);


        (1,227) : setPromoLevel(((1<<8)|227)+1);


        (2,227) : setPromoLevel(((2<<8)|227)+1);


        (3,227) : setPromoLevel(((3<<8)|227)+1);


        (4,227) : setPromoLevel(((4<<8)|227)+1);


        (5,227) : setPromoLevel(((5<<8)|227)+1);


        (6,227) : setPromoLevel(((6<<8)|227)+1);


        (7,227) : setPromoLevel(((7<<8)|227)+1);


        (8,227) : setPromoLevel(((8<<8)|227)+1);


        (9,227) : setPromoLevel(((9<<8)|227)+1);


        (10,227) : setPromoLevel(((10<<8)|227)+1);


        (11,227) : setPromoLevel(((11<<8)|227)+1);


        (12,227) : setPromoLevel(((12<<8)|227)+1);


        (13,227) : setPromoLevel(((13<<8)|227)+1);


        (14,227) : setPromoLevel(((14<<8)|227)+1);


        (15,227) : setPromoLevel(((15<<8)|227)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1183 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,228) : setPromoLevel(((0<<8)|228)+1);


        (1,228) : setPromoLevel(((1<<8)|228)+1);


        (2,228) : setPromoLevel(((2<<8)|228)+1);


        (3,228) : setPromoLevel(((3<<8)|228)+1);


        (4,228) : setPromoLevel(((4<<8)|228)+1);


        (5,228) : setPromoLevel(((5<<8)|228)+1);


        (6,228) : setPromoLevel(((6<<8)|228)+1);


        (7,228) : setPromoLevel(((7<<8)|228)+1);


        (8,228) : setPromoLevel(((8<<8)|228)+1);


        (9,228) : setPromoLevel(((9<<8)|228)+1);


        (10,228) : setPromoLevel(((10<<8)|228)+1);


        (11,228) : setPromoLevel(((11<<8)|228)+1);


        (12,228) : setPromoLevel(((12<<8)|228)+1);


        (13,228) : setPromoLevel(((13<<8)|228)+1);


        (14,228) : setPromoLevel(((14<<8)|228)+1);


        (15,228) : setPromoLevel(((15<<8)|228)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1188 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,229) : setPromoLevel(((0<<8)|229)+1);


        (1,229) : setPromoLevel(((1<<8)|229)+1);


        (2,229) : setPromoLevel(((2<<8)|229)+1);


        (3,229) : setPromoLevel(((3<<8)|229)+1);


        (4,229) : setPromoLevel(((4<<8)|229)+1);


        (5,229) : setPromoLevel(((5<<8)|229)+1);


        (6,229) : setPromoLevel(((6<<8)|229)+1);


        (7,229) : setPromoLevel(((7<<8)|229)+1);


        (8,229) : setPromoLevel(((8<<8)|229)+1);


        (9,229) : setPromoLevel(((9<<8)|229)+1);


        (10,229) : setPromoLevel(((10<<8)|229)+1);


        (11,229) : setPromoLevel(((11<<8)|229)+1);


        (12,229) : setPromoLevel(((12<<8)|229)+1);


        (13,229) : setPromoLevel(((13<<8)|229)+1);


        (14,229) : setPromoLevel(((14<<8)|229)+1);


        (15,229) : setPromoLevel(((15<<8)|229)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1193 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,230) : setPromoLevel(((0<<8)|230)+1);


        (1,230) : setPromoLevel(((1<<8)|230)+1);


        (2,230) : setPromoLevel(((2<<8)|230)+1);


        (3,230) : setPromoLevel(((3<<8)|230)+1);


        (4,230) : setPromoLevel(((4<<8)|230)+1);


        (5,230) : setPromoLevel(((5<<8)|230)+1);


        (6,230) : setPromoLevel(((6<<8)|230)+1);


        (7,230) : setPromoLevel(((7<<8)|230)+1);


        (8,230) : setPromoLevel(((8<<8)|230)+1);


        (9,230) : setPromoLevel(((9<<8)|230)+1);


        (10,230) : setPromoLevel(((10<<8)|230)+1);


        (11,230) : setPromoLevel(((11<<8)|230)+1);


        (12,230) : setPromoLevel(((12<<8)|230)+1);


        (13,230) : setPromoLevel(((13<<8)|230)+1);


        (14,230) : setPromoLevel(((14<<8)|230)+1);


        (15,230) : setPromoLevel(((15<<8)|230)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1198 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,231) : setPromoLevel(((0<<8)|231)+1);


        (1,231) : setPromoLevel(((1<<8)|231)+1);


        (2,231) : setPromoLevel(((2<<8)|231)+1);


        (3,231) : setPromoLevel(((3<<8)|231)+1);


        (4,231) : setPromoLevel(((4<<8)|231)+1);


        (5,231) : setPromoLevel(((5<<8)|231)+1);


        (6,231) : setPromoLevel(((6<<8)|231)+1);


        (7,231) : setPromoLevel(((7<<8)|231)+1);


        (8,231) : setPromoLevel(((8<<8)|231)+1);


        (9,231) : setPromoLevel(((9<<8)|231)+1);


        (10,231) : setPromoLevel(((10<<8)|231)+1);


        (11,231) : setPromoLevel(((11<<8)|231)+1);


        (12,231) : setPromoLevel(((12<<8)|231)+1);


        (13,231) : setPromoLevel(((13<<8)|231)+1);


        (14,231) : setPromoLevel(((14<<8)|231)+1);


        (15,231) : setPromoLevel(((15<<8)|231)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1203 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,232) : setPromoLevel(((0<<8)|232)+1);


        (1,232) : setPromoLevel(((1<<8)|232)+1);


        (2,232) : setPromoLevel(((2<<8)|232)+1);


        (3,232) : setPromoLevel(((3<<8)|232)+1);


        (4,232) : setPromoLevel(((4<<8)|232)+1);


        (5,232) : setPromoLevel(((5<<8)|232)+1);


        (6,232) : setPromoLevel(((6<<8)|232)+1);


        (7,232) : setPromoLevel(((7<<8)|232)+1);


        (8,232) : setPromoLevel(((8<<8)|232)+1);


        (9,232) : setPromoLevel(((9<<8)|232)+1);


        (10,232) : setPromoLevel(((10<<8)|232)+1);


        (11,232) : setPromoLevel(((11<<8)|232)+1);


        (12,232) : setPromoLevel(((12<<8)|232)+1);


        (13,232) : setPromoLevel(((13<<8)|232)+1);


        (14,232) : setPromoLevel(((14<<8)|232)+1);


        (15,232) : setPromoLevel(((15<<8)|232)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1208 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,233) : setPromoLevel(((0<<8)|233)+1);


        (1,233) : setPromoLevel(((1<<8)|233)+1);


        (2,233) : setPromoLevel(((2<<8)|233)+1);


        (3,233) : setPromoLevel(((3<<8)|233)+1);


        (4,233) : setPromoLevel(((4<<8)|233)+1);


        (5,233) : setPromoLevel(((5<<8)|233)+1);


        (6,233) : setPromoLevel(((6<<8)|233)+1);


        (7,233) : setPromoLevel(((7<<8)|233)+1);


        (8,233) : setPromoLevel(((8<<8)|233)+1);


        (9,233) : setPromoLevel(((9<<8)|233)+1);


        (10,233) : setPromoLevel(((10<<8)|233)+1);


        (11,233) : setPromoLevel(((11<<8)|233)+1);


        (12,233) : setPromoLevel(((12<<8)|233)+1);


        (13,233) : setPromoLevel(((13<<8)|233)+1);


        (14,233) : setPromoLevel(((14<<8)|233)+1);


        (15,233) : setPromoLevel(((15<<8)|233)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1213 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,234) : setPromoLevel(((0<<8)|234)+1);


        (1,234) : setPromoLevel(((1<<8)|234)+1);


        (2,234) : setPromoLevel(((2<<8)|234)+1);


        (3,234) : setPromoLevel(((3<<8)|234)+1);


        (4,234) : setPromoLevel(((4<<8)|234)+1);


        (5,234) : setPromoLevel(((5<<8)|234)+1);


        (6,234) : setPromoLevel(((6<<8)|234)+1);


        (7,234) : setPromoLevel(((7<<8)|234)+1);


        (8,234) : setPromoLevel(((8<<8)|234)+1);


        (9,234) : setPromoLevel(((9<<8)|234)+1);


        (10,234) : setPromoLevel(((10<<8)|234)+1);


        (11,234) : setPromoLevel(((11<<8)|234)+1);


        (12,234) : setPromoLevel(((12<<8)|234)+1);


        (13,234) : setPromoLevel(((13<<8)|234)+1);


        (14,234) : setPromoLevel(((14<<8)|234)+1);


        (15,234) : setPromoLevel(((15<<8)|234)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1218 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,235) : setPromoLevel(((0<<8)|235)+1);


        (1,235) : setPromoLevel(((1<<8)|235)+1);


        (2,235) : setPromoLevel(((2<<8)|235)+1);


        (3,235) : setPromoLevel(((3<<8)|235)+1);


        (4,235) : setPromoLevel(((4<<8)|235)+1);


        (5,235) : setPromoLevel(((5<<8)|235)+1);


        (6,235) : setPromoLevel(((6<<8)|235)+1);


        (7,235) : setPromoLevel(((7<<8)|235)+1);


        (8,235) : setPromoLevel(((8<<8)|235)+1);


        (9,235) : setPromoLevel(((9<<8)|235)+1);


        (10,235) : setPromoLevel(((10<<8)|235)+1);


        (11,235) : setPromoLevel(((11<<8)|235)+1);


        (12,235) : setPromoLevel(((12<<8)|235)+1);


        (13,235) : setPromoLevel(((13<<8)|235)+1);


        (14,235) : setPromoLevel(((14<<8)|235)+1);


        (15,235) : setPromoLevel(((15<<8)|235)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1223 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,236) : setPromoLevel(((0<<8)|236)+1);


        (1,236) : setPromoLevel(((1<<8)|236)+1);


        (2,236) : setPromoLevel(((2<<8)|236)+1);


        (3,236) : setPromoLevel(((3<<8)|236)+1);


        (4,236) : setPromoLevel(((4<<8)|236)+1);


        (5,236) : setPromoLevel(((5<<8)|236)+1);


        (6,236) : setPromoLevel(((6<<8)|236)+1);


        (7,236) : setPromoLevel(((7<<8)|236)+1);


        (8,236) : setPromoLevel(((8<<8)|236)+1);


        (9,236) : setPromoLevel(((9<<8)|236)+1);


        (10,236) : setPromoLevel(((10<<8)|236)+1);


        (11,236) : setPromoLevel(((11<<8)|236)+1);


        (12,236) : setPromoLevel(((12<<8)|236)+1);


        (13,236) : setPromoLevel(((13<<8)|236)+1);


        (14,236) : setPromoLevel(((14<<8)|236)+1);


        (15,236) : setPromoLevel(((15<<8)|236)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1228 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,237) : setPromoLevel(((0<<8)|237)+1);


        (1,237) : setPromoLevel(((1<<8)|237)+1);


        (2,237) : setPromoLevel(((2<<8)|237)+1);


        (3,237) : setPromoLevel(((3<<8)|237)+1);


        (4,237) : setPromoLevel(((4<<8)|237)+1);


        (5,237) : setPromoLevel(((5<<8)|237)+1);


        (6,237) : setPromoLevel(((6<<8)|237)+1);


        (7,237) : setPromoLevel(((7<<8)|237)+1);


        (8,237) : setPromoLevel(((8<<8)|237)+1);


        (9,237) : setPromoLevel(((9<<8)|237)+1);


        (10,237) : setPromoLevel(((10<<8)|237)+1);


        (11,237) : setPromoLevel(((11<<8)|237)+1);


        (12,237) : setPromoLevel(((12<<8)|237)+1);


        (13,237) : setPromoLevel(((13<<8)|237)+1);


        (14,237) : setPromoLevel(((14<<8)|237)+1);


        (15,237) : setPromoLevel(((15<<8)|237)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1233 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,238) : setPromoLevel(((0<<8)|238)+1);


        (1,238) : setPromoLevel(((1<<8)|238)+1);


        (2,238) : setPromoLevel(((2<<8)|238)+1);


        (3,238) : setPromoLevel(((3<<8)|238)+1);


        (4,238) : setPromoLevel(((4<<8)|238)+1);


        (5,238) : setPromoLevel(((5<<8)|238)+1);


        (6,238) : setPromoLevel(((6<<8)|238)+1);


        (7,238) : setPromoLevel(((7<<8)|238)+1);


        (8,238) : setPromoLevel(((8<<8)|238)+1);


        (9,238) : setPromoLevel(((9<<8)|238)+1);


        (10,238) : setPromoLevel(((10<<8)|238)+1);


        (11,238) : setPromoLevel(((11<<8)|238)+1);


        (12,238) : setPromoLevel(((12<<8)|238)+1);


        (13,238) : setPromoLevel(((13<<8)|238)+1);


        (14,238) : setPromoLevel(((14<<8)|238)+1);


        (15,238) : setPromoLevel(((15<<8)|238)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1238 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,239) : setPromoLevel(((0<<8)|239)+1);


        (1,239) : setPromoLevel(((1<<8)|239)+1);


        (2,239) : setPromoLevel(((2<<8)|239)+1);


        (3,239) : setPromoLevel(((3<<8)|239)+1);


        (4,239) : setPromoLevel(((4<<8)|239)+1);


        (5,239) : setPromoLevel(((5<<8)|239)+1);


        (6,239) : setPromoLevel(((6<<8)|239)+1);


        (7,239) : setPromoLevel(((7<<8)|239)+1);


        (8,239) : setPromoLevel(((8<<8)|239)+1);


        (9,239) : setPromoLevel(((9<<8)|239)+1);


        (10,239) : setPromoLevel(((10<<8)|239)+1);


        (11,239) : setPromoLevel(((11<<8)|239)+1);


        (12,239) : setPromoLevel(((12<<8)|239)+1);


        (13,239) : setPromoLevel(((13<<8)|239)+1);


        (14,239) : setPromoLevel(((14<<8)|239)+1);


        (15,239) : setPromoLevel(((15<<8)|239)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1243 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,240) : setPromoLevel(((0<<8)|240)+1);


        (1,240) : setPromoLevel(((1<<8)|240)+1);


        (2,240) : setPromoLevel(((2<<8)|240)+1);


        (3,240) : setPromoLevel(((3<<8)|240)+1);


        (4,240) : setPromoLevel(((4<<8)|240)+1);


        (5,240) : setPromoLevel(((5<<8)|240)+1);


        (6,240) : setPromoLevel(((6<<8)|240)+1);


        (7,240) : setPromoLevel(((7<<8)|240)+1);


        (8,240) : setPromoLevel(((8<<8)|240)+1);


        (9,240) : setPromoLevel(((9<<8)|240)+1);


        (10,240) : setPromoLevel(((10<<8)|240)+1);


        (11,240) : setPromoLevel(((11<<8)|240)+1);


        (12,240) : setPromoLevel(((12<<8)|240)+1);


        (13,240) : setPromoLevel(((13<<8)|240)+1);


        (14,240) : setPromoLevel(((14<<8)|240)+1);


        (15,240) : setPromoLevel(((15<<8)|240)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1248 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,241) : setPromoLevel(((0<<8)|241)+1);


        (1,241) : setPromoLevel(((1<<8)|241)+1);


        (2,241) : setPromoLevel(((2<<8)|241)+1);


        (3,241) : setPromoLevel(((3<<8)|241)+1);


        (4,241) : setPromoLevel(((4<<8)|241)+1);


        (5,241) : setPromoLevel(((5<<8)|241)+1);


        (6,241) : setPromoLevel(((6<<8)|241)+1);


        (7,241) : setPromoLevel(((7<<8)|241)+1);


        (8,241) : setPromoLevel(((8<<8)|241)+1);


        (9,241) : setPromoLevel(((9<<8)|241)+1);


        (10,241) : setPromoLevel(((10<<8)|241)+1);


        (11,241) : setPromoLevel(((11<<8)|241)+1);


        (12,241) : setPromoLevel(((12<<8)|241)+1);


        (13,241) : setPromoLevel(((13<<8)|241)+1);


        (14,241) : setPromoLevel(((14<<8)|241)+1);


        (15,241) : setPromoLevel(((15<<8)|241)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1253 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,242) : setPromoLevel(((0<<8)|242)+1);


        (1,242) : setPromoLevel(((1<<8)|242)+1);


        (2,242) : setPromoLevel(((2<<8)|242)+1);


        (3,242) : setPromoLevel(((3<<8)|242)+1);


        (4,242) : setPromoLevel(((4<<8)|242)+1);


        (5,242) : setPromoLevel(((5<<8)|242)+1);


        (6,242) : setPromoLevel(((6<<8)|242)+1);


        (7,242) : setPromoLevel(((7<<8)|242)+1);


        (8,242) : setPromoLevel(((8<<8)|242)+1);


        (9,242) : setPromoLevel(((9<<8)|242)+1);


        (10,242) : setPromoLevel(((10<<8)|242)+1);


        (11,242) : setPromoLevel(((11<<8)|242)+1);


        (12,242) : setPromoLevel(((12<<8)|242)+1);


        (13,242) : setPromoLevel(((13<<8)|242)+1);


        (14,242) : setPromoLevel(((14<<8)|242)+1);


        (15,242) : setPromoLevel(((15<<8)|242)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1258 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,243) : setPromoLevel(((0<<8)|243)+1);


        (1,243) : setPromoLevel(((1<<8)|243)+1);


        (2,243) : setPromoLevel(((2<<8)|243)+1);


        (3,243) : setPromoLevel(((3<<8)|243)+1);


        (4,243) : setPromoLevel(((4<<8)|243)+1);


        (5,243) : setPromoLevel(((5<<8)|243)+1);


        (6,243) : setPromoLevel(((6<<8)|243)+1);


        (7,243) : setPromoLevel(((7<<8)|243)+1);


        (8,243) : setPromoLevel(((8<<8)|243)+1);


        (9,243) : setPromoLevel(((9<<8)|243)+1);


        (10,243) : setPromoLevel(((10<<8)|243)+1);


        (11,243) : setPromoLevel(((11<<8)|243)+1);


        (12,243) : setPromoLevel(((12<<8)|243)+1);


        (13,243) : setPromoLevel(((13<<8)|243)+1);


        (14,243) : setPromoLevel(((14<<8)|243)+1);


        (15,243) : setPromoLevel(((15<<8)|243)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1263 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,244) : setPromoLevel(((0<<8)|244)+1);


        (1,244) : setPromoLevel(((1<<8)|244)+1);


        (2,244) : setPromoLevel(((2<<8)|244)+1);


        (3,244) : setPromoLevel(((3<<8)|244)+1);


        (4,244) : setPromoLevel(((4<<8)|244)+1);


        (5,244) : setPromoLevel(((5<<8)|244)+1);


        (6,244) : setPromoLevel(((6<<8)|244)+1);


        (7,244) : setPromoLevel(((7<<8)|244)+1);


        (8,244) : setPromoLevel(((8<<8)|244)+1);


        (9,244) : setPromoLevel(((9<<8)|244)+1);


        (10,244) : setPromoLevel(((10<<8)|244)+1);


        (11,244) : setPromoLevel(((11<<8)|244)+1);


        (12,244) : setPromoLevel(((12<<8)|244)+1);


        (13,244) : setPromoLevel(((13<<8)|244)+1);


        (14,244) : setPromoLevel(((14<<8)|244)+1);


        (15,244) : setPromoLevel(((15<<8)|244)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1268 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,245) : setPromoLevel(((0<<8)|245)+1);


        (1,245) : setPromoLevel(((1<<8)|245)+1);


        (2,245) : setPromoLevel(((2<<8)|245)+1);


        (3,245) : setPromoLevel(((3<<8)|245)+1);


        (4,245) : setPromoLevel(((4<<8)|245)+1);


        (5,245) : setPromoLevel(((5<<8)|245)+1);


        (6,245) : setPromoLevel(((6<<8)|245)+1);


        (7,245) : setPromoLevel(((7<<8)|245)+1);


        (8,245) : setPromoLevel(((8<<8)|245)+1);


        (9,245) : setPromoLevel(((9<<8)|245)+1);


        (10,245) : setPromoLevel(((10<<8)|245)+1);


        (11,245) : setPromoLevel(((11<<8)|245)+1);


        (12,245) : setPromoLevel(((12<<8)|245)+1);


        (13,245) : setPromoLevel(((13<<8)|245)+1);


        (14,245) : setPromoLevel(((14<<8)|245)+1);


        (15,245) : setPromoLevel(((15<<8)|245)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1273 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,246) : setPromoLevel(((0<<8)|246)+1);


        (1,246) : setPromoLevel(((1<<8)|246)+1);


        (2,246) : setPromoLevel(((2<<8)|246)+1);


        (3,246) : setPromoLevel(((3<<8)|246)+1);


        (4,246) : setPromoLevel(((4<<8)|246)+1);


        (5,246) : setPromoLevel(((5<<8)|246)+1);


        (6,246) : setPromoLevel(((6<<8)|246)+1);


        (7,246) : setPromoLevel(((7<<8)|246)+1);


        (8,246) : setPromoLevel(((8<<8)|246)+1);


        (9,246) : setPromoLevel(((9<<8)|246)+1);


        (10,246) : setPromoLevel(((10<<8)|246)+1);


        (11,246) : setPromoLevel(((11<<8)|246)+1);


        (12,246) : setPromoLevel(((12<<8)|246)+1);


        (13,246) : setPromoLevel(((13<<8)|246)+1);


        (14,246) : setPromoLevel(((14<<8)|246)+1);


        (15,246) : setPromoLevel(((15<<8)|246)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1278 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,247) : setPromoLevel(((0<<8)|247)+1);


        (1,247) : setPromoLevel(((1<<8)|247)+1);


        (2,247) : setPromoLevel(((2<<8)|247)+1);


        (3,247) : setPromoLevel(((3<<8)|247)+1);


        (4,247) : setPromoLevel(((4<<8)|247)+1);


        (5,247) : setPromoLevel(((5<<8)|247)+1);


        (6,247) : setPromoLevel(((6<<8)|247)+1);


        (7,247) : setPromoLevel(((7<<8)|247)+1);


        (8,247) : setPromoLevel(((8<<8)|247)+1);


        (9,247) : setPromoLevel(((9<<8)|247)+1);


        (10,247) : setPromoLevel(((10<<8)|247)+1);


        (11,247) : setPromoLevel(((11<<8)|247)+1);


        (12,247) : setPromoLevel(((12<<8)|247)+1);


        (13,247) : setPromoLevel(((13<<8)|247)+1);


        (14,247) : setPromoLevel(((14<<8)|247)+1);


        (15,247) : setPromoLevel(((15<<8)|247)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1283 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,248) : setPromoLevel(((0<<8)|248)+1);


        (1,248) : setPromoLevel(((1<<8)|248)+1);


        (2,248) : setPromoLevel(((2<<8)|248)+1);


        (3,248) : setPromoLevel(((3<<8)|248)+1);


        (4,248) : setPromoLevel(((4<<8)|248)+1);


        (5,248) : setPromoLevel(((5<<8)|248)+1);


        (6,248) : setPromoLevel(((6<<8)|248)+1);


        (7,248) : setPromoLevel(((7<<8)|248)+1);


        (8,248) : setPromoLevel(((8<<8)|248)+1);


        (9,248) : setPromoLevel(((9<<8)|248)+1);


        (10,248) : setPromoLevel(((10<<8)|248)+1);


        (11,248) : setPromoLevel(((11<<8)|248)+1);


        (12,248) : setPromoLevel(((12<<8)|248)+1);


        (13,248) : setPromoLevel(((13<<8)|248)+1);


        (14,248) : setPromoLevel(((14<<8)|248)+1);


        (15,248) : setPromoLevel(((15<<8)|248)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1288 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,249) : setPromoLevel(((0<<8)|249)+1);


        (1,249) : setPromoLevel(((1<<8)|249)+1);


        (2,249) : setPromoLevel(((2<<8)|249)+1);


        (3,249) : setPromoLevel(((3<<8)|249)+1);


        (4,249) : setPromoLevel(((4<<8)|249)+1);


        (5,249) : setPromoLevel(((5<<8)|249)+1);


        (6,249) : setPromoLevel(((6<<8)|249)+1);


        (7,249) : setPromoLevel(((7<<8)|249)+1);


        (8,249) : setPromoLevel(((8<<8)|249)+1);


        (9,249) : setPromoLevel(((9<<8)|249)+1);


        (10,249) : setPromoLevel(((10<<8)|249)+1);


        (11,249) : setPromoLevel(((11<<8)|249)+1);


        (12,249) : setPromoLevel(((12<<8)|249)+1);


        (13,249) : setPromoLevel(((13<<8)|249)+1);


        (14,249) : setPromoLevel(((14<<8)|249)+1);


        (15,249) : setPromoLevel(((15<<8)|249)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1293 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,250) : setPromoLevel(((0<<8)|250)+1);


        (1,250) : setPromoLevel(((1<<8)|250)+1);


        (2,250) : setPromoLevel(((2<<8)|250)+1);


        (3,250) : setPromoLevel(((3<<8)|250)+1);


        (4,250) : setPromoLevel(((4<<8)|250)+1);


        (5,250) : setPromoLevel(((5<<8)|250)+1);


        (6,250) : setPromoLevel(((6<<8)|250)+1);


        (7,250) : setPromoLevel(((7<<8)|250)+1);


        (8,250) : setPromoLevel(((8<<8)|250)+1);


        (9,250) : setPromoLevel(((9<<8)|250)+1);


        (10,250) : setPromoLevel(((10<<8)|250)+1);


        (11,250) : setPromoLevel(((11<<8)|250)+1);


        (12,250) : setPromoLevel(((12<<8)|250)+1);


        (13,250) : setPromoLevel(((13<<8)|250)+1);


        (14,250) : setPromoLevel(((14<<8)|250)+1);


        (15,250) : setPromoLevel(((15<<8)|250)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1298 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,251) : setPromoLevel(((0<<8)|251)+1);


        (1,251) : setPromoLevel(((1<<8)|251)+1);


        (2,251) : setPromoLevel(((2<<8)|251)+1);


        (3,251) : setPromoLevel(((3<<8)|251)+1);


        (4,251) : setPromoLevel(((4<<8)|251)+1);


        (5,251) : setPromoLevel(((5<<8)|251)+1);


        (6,251) : setPromoLevel(((6<<8)|251)+1);


        (7,251) : setPromoLevel(((7<<8)|251)+1);


        (8,251) : setPromoLevel(((8<<8)|251)+1);


        (9,251) : setPromoLevel(((9<<8)|251)+1);


        (10,251) : setPromoLevel(((10<<8)|251)+1);


        (11,251) : setPromoLevel(((11<<8)|251)+1);


        (12,251) : setPromoLevel(((12<<8)|251)+1);


        (13,251) : setPromoLevel(((13<<8)|251)+1);


        (14,251) : setPromoLevel(((14<<8)|251)+1);


        (15,251) : setPromoLevel(((15<<8)|251)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1303 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,252) : setPromoLevel(((0<<8)|252)+1);


        (1,252) : setPromoLevel(((1<<8)|252)+1);


        (2,252) : setPromoLevel(((2<<8)|252)+1);


        (3,252) : setPromoLevel(((3<<8)|252)+1);


        (4,252) : setPromoLevel(((4<<8)|252)+1);


        (5,252) : setPromoLevel(((5<<8)|252)+1);


        (6,252) : setPromoLevel(((6<<8)|252)+1);


        (7,252) : setPromoLevel(((7<<8)|252)+1);


        (8,252) : setPromoLevel(((8<<8)|252)+1);


        (9,252) : setPromoLevel(((9<<8)|252)+1);


        (10,252) : setPromoLevel(((10<<8)|252)+1);


        (11,252) : setPromoLevel(((11<<8)|252)+1);


        (12,252) : setPromoLevel(((12<<8)|252)+1);


        (13,252) : setPromoLevel(((13<<8)|252)+1);


        (14,252) : setPromoLevel(((14<<8)|252)+1);


        (15,252) : setPromoLevel(((15<<8)|252)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1308 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,253) : setPromoLevel(((0<<8)|253)+1);


        (1,253) : setPromoLevel(((1<<8)|253)+1);


        (2,253) : setPromoLevel(((2<<8)|253)+1);


        (3,253) : setPromoLevel(((3<<8)|253)+1);


        (4,253) : setPromoLevel(((4<<8)|253)+1);


        (5,253) : setPromoLevel(((5<<8)|253)+1);


        (6,253) : setPromoLevel(((6<<8)|253)+1);


        (7,253) : setPromoLevel(((7<<8)|253)+1);


        (8,253) : setPromoLevel(((8<<8)|253)+1);


        (9,253) : setPromoLevel(((9<<8)|253)+1);


        (10,253) : setPromoLevel(((10<<8)|253)+1);


        (11,253) : setPromoLevel(((11<<8)|253)+1);


        (12,253) : setPromoLevel(((12<<8)|253)+1);


        (13,253) : setPromoLevel(((13<<8)|253)+1);


        (14,253) : setPromoLevel(((14<<8)|253)+1);


        (15,253) : setPromoLevel(((15<<8)|253)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1313 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,254) : setPromoLevel(((0<<8)|254)+1);


        (1,254) : setPromoLevel(((1<<8)|254)+1);


        (2,254) : setPromoLevel(((2<<8)|254)+1);


        (3,254) : setPromoLevel(((3<<8)|254)+1);


        (4,254) : setPromoLevel(((4<<8)|254)+1);


        (5,254) : setPromoLevel(((5<<8)|254)+1);


        (6,254) : setPromoLevel(((6<<8)|254)+1);


        (7,254) : setPromoLevel(((7<<8)|254)+1);


        (8,254) : setPromoLevel(((8<<8)|254)+1);


        (9,254) : setPromoLevel(((9<<8)|254)+1);


        (10,254) : setPromoLevel(((10<<8)|254)+1);


        (11,254) : setPromoLevel(((11<<8)|254)+1);


        (12,254) : setPromoLevel(((12<<8)|254)+1);


        (13,254) : setPromoLevel(((13<<8)|254)+1);


        (14,254) : setPromoLevel(((14<<8)|254)+1);


        (15,254) : setPromoLevel(((15<<8)|254)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1318 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2




# 1 "../../p4c-5323/src/gen_promo_level_sets.p4" 1





# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        (0,255) : setPromoLevel(((0<<8)|255)+1);


        (1,255) : setPromoLevel(((1<<8)|255)+1);


        (2,255) : setPromoLevel(((2<<8)|255)+1);


        (3,255) : setPromoLevel(((3<<8)|255)+1);


        (4,255) : setPromoLevel(((4<<8)|255)+1);


        (5,255) : setPromoLevel(((5<<8)|255)+1);


        (6,255) : setPromoLevel(((6<<8)|255)+1);


        (7,255) : setPromoLevel(((7<<8)|255)+1);


        (8,255) : setPromoLevel(((8<<8)|255)+1);


        (9,255) : setPromoLevel(((9<<8)|255)+1);


        (10,255) : setPromoLevel(((10<<8)|255)+1);


        (11,255) : setPromoLevel(((11<<8)|255)+1);


        (12,255) : setPromoLevel(((12<<8)|255)+1);


        (13,255) : setPromoLevel(((13<<8)|255)+1);


        (14,255) : setPromoLevel(((14<<8)|255)+1);


        (15,255) : setPromoLevel(((15<<8)|255)+1);
# 6 "../../p4c-5323/src/gen_promo_level_sets.p4" 2
# 1323 "/usr/local/include/boost/preprocessor/iteration/detail/iter/forward1.hpp" 2
# 217 "../../p4c-5323/src/throttle.p4" 2
    }
    size = (1<<(4 +8));
  }

  action copyDeepLoopToCpu() {ig_intr_md_for_tm.copy_to_cpu = 1;}
  table doCopyToCpu {
    actions = {copyDeepLoopToCpu; NoAction;}
    default_action = copyDeepLoopToCpu();
  }

  Random<bit<32>>() randomCloneKeyGen;

  apply {
    bit<1> errored = 0;
    if(ig_intr_md_from_prsr.parser_err != 0) // must check this value or p4 will silently reject all errored packets
      errored = 1;
    IngrPkts.count(errored);
    ThrottleTraffic.count((bit<1>)meta.continueLooping ++ ig_intr_md.ingress_port);//Combine loop/non-loop
    if(!meta.continueLooping) {
      allGroupPriority.count(hdr.internal.outputGroup ++ hdr.internal.priority);
    }

    bool promote = false;
    promoLevel = getPromoLevel.execute(hdr.internal.outputGroup);
    calculatePromoLevel.apply();
    if (!meta.continueLooping && promoLevel == 0)
    {

      color = (bit<8>)PromotionMeter.execute(hdr.internal.outputGroup);
      PromoteColorMonitor.apply();

      promote = true;
      promoteGroup.count(hdr.internal.outputGroup);
    }
    SelectRandomGroup.apply();

    if(!meta.continueLooping)
      OutputGroupConfig.apply();

    @pa_container_size("DefeatFlows", "ingress", "useRand_0", 16)
    bit<16> useRand = ig_intr_md_from_prsr.global_tstamp[47:32] & getRotate.execute(rndGroup);
    useRand = timeHash.get({useRand, randomKey});
    @pa_container_size("DefeatFlows", "ingress", "randLevel_0", 16)
    bit<16> randLevel = getRandomLevel.execute(rndGroup);
    useRand = useRand |-| randLevel;
    if (!meta.continueLooping && !promote && useRand == 0 && randLevel != 0)
    {
      promote = true;
      hdr.internal.contextualFlag = 1;//Mark this as a random promote
      hdr.internal.outputGroup = rndGroup;

      color = (bit<8>)RandomMeter.execute(rndGroup);
      RandomColorMonitor.apply();

      randomGroup.count(hdr.internal.outputGroup);
    }

    if(meta.continueLooping)
    {
      ig_intr_md_for_dprsr.drop_ctl = 0;
      ig_intr_md_for_tm.ucast_egress_port = ig_intr_md.ingress_port;
    }
    else if(!meta.continueLooping && !promote)
    {
      dropGroup.count(hdr.internal.outputGroup);
      Drop();
    }
    else if(promote && !meta.continueLooping)
    {
      OutputMapper.apply();
    }

    bit<32> randomCloneKey = randomCloneKeyGen.get();
    if(!meta.returnedPacket && !meta.continueLooping) {
      packetCloner.apply(ig_intr_md_for_dprsr,meta.mirrorSession,hdr.internal.flowID,hdr.internal.layer2Skip,randomCloneKey,hdr.internal.hash,promote,hdr.internal.priority,hdr.internal.outputGroup,meta.cloneMarker);
    }
    if(meta.continueLooping)
      doCopyToCpu.apply();
  }
}
# 503 "../../p4c-5323/src/throttle.p4"
control ThrottleDeparser(packet_out pkt,
                         inout throttle_headers_t hdr,
                         in throttle_meta_t meta,
                         in ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr)
{
    Mirror() mirror;
    apply {
        if(ig_intr_md_for_dprsr.mirror_type == 1) {
            mirror.emit<CloningHeader_h>(meta.mirrorSession,{meta.cloneMarker});//0 is the only allowed constant value, so we have to sneak this in
        }
        pkt.emit(hdr);
    }
}
# 8 "../../p4c-5323/src/DefeatFlows.p4" 2
# 1 "../../p4c-5323/src/DefeatFlowTracker.p4" 1
struct defeat_flow_headers_t
{
  Internal_h internal;
  TwelveBytes_h ethernetAddresses;
}

struct defeat_flow_meta_t {
  bit<32> flowHash;
  bit<8> reduceLength;
  bit<8> occupancyKey;
  bool set;
}

parser DefeatFlowParser(packet_in pkt,
                      out defeat_flow_headers_t hdr,
                      out defeat_flow_meta_t meta,
                      out egress_intrinsic_metadata_t eg_intr_md)
{
  bit<16> aggKey = 0;
  bit<16> eType = 0;
  state start {
    pkt.extract(eg_intr_md);
    meta.reduceLength = 0;
    meta.occupancyKey = 0;
    meta.set = false;
    meta.flowHash = pkt.lookahead<bit<32>>();
    pkt.advance(32);
    pkt.extract(hdr.internal);
    transition occupancyKeySet;
  }

  state occupancyKeySet {
    transition select(hdr.internal.contextualFlag, meta.flowHash[2:0], (bit<2>)hdr.internal.framedPacket) {






# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        ( 1,0 , (bit<2>)FramingType_t.None) : setSKeyAccept0 ; ( 1,0 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet0 ; ( 1,0 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet0 ; ( 1,0 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther0 ;


        ( 1,1 , (bit<2>)FramingType_t.None) : setSKeyAccept1 ; ( 1,1 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet1 ; ( 1,1 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet1 ; ( 1,1 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther1 ;


        ( 1,2 , (bit<2>)FramingType_t.None) : setSKeyAccept2 ; ( 1,2 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet2 ; ( 1,2 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet2 ; ( 1,2 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther2 ;


        ( 1,3 , (bit<2>)FramingType_t.None) : setSKeyAccept3 ; ( 1,3 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet3 ; ( 1,3 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet3 ; ( 1,3 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther3 ;


        ( 1,4 , (bit<2>)FramingType_t.None) : setSKeyAccept4 ; ( 1,4 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet4 ; ( 1,4 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet4 ; ( 1,4 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther4 ;


        ( 1,5 , (bit<2>)FramingType_t.None) : setSKeyAccept5 ; ( 1,5 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet5 ; ( 1,5 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet5 ; ( 1,5 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther5 ;


        ( 1,6 , (bit<2>)FramingType_t.None) : setSKeyAccept6 ; ( 1,6 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet6 ; ( 1,6 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet6 ; ( 1,6 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther6 ;


        ( 1,7 , (bit<2>)FramingType_t.None) : setSKeyAccept7 ; ( 1,7 , (bit<2>)FramingType_t.NonRetentionEth) : setSKeyDropNonRet7 ; ( 1,7 , (bit<2>)FramingType_t.Eth) : setSKeyDropRet7 ; ( 1,7 , (bit<2>)FramingType_t.NonEth) : setSKeyDropOther7 ;
# 41 "../../p4c-5323/src/DefeatFlowTracker.p4" 2
      ( _, _, (bit<2>)FramingType_t.None) : accept;
      ( _, _, (bit<2>)FramingType_t.NonRetentionEth) : drop_non_retention_eth;
      ( _, _, (bit<2>)FramingType_t.Eth) : drop_retention_eth;
      ( _, _, (bit<2>)FramingType_t.NonEth) : drop_other_framing;

      (_, 0, (bit<2>)FramingType_t.None) : occupancyKeySet; //Dummy rule
    }
  }
# 75 "../../p4c-5323/src/DefeatFlowTracker.p4"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        state setSKeyAccept0 { meta.set = true; meta.occupancyKey = 1 << 0; transition accept; } state setSKeyDropNonRet0 { meta.set = true; meta.occupancyKey = 1 << 0; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet0 { meta.set = true; meta.occupancyKey = 1 << 0; transition drop_retention_eth; } state setSKeyDropOther0 { meta.set = true; meta.occupancyKey = 1 << 0; transition drop_other_framing; }


        state setSKeyAccept1 { meta.set = true; meta.occupancyKey = 1 << 1; transition accept; } state setSKeyDropNonRet1 { meta.set = true; meta.occupancyKey = 1 << 1; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet1 { meta.set = true; meta.occupancyKey = 1 << 1; transition drop_retention_eth; } state setSKeyDropOther1 { meta.set = true; meta.occupancyKey = 1 << 1; transition drop_other_framing; }


        state setSKeyAccept2 { meta.set = true; meta.occupancyKey = 1 << 2; transition accept; } state setSKeyDropNonRet2 { meta.set = true; meta.occupancyKey = 1 << 2; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet2 { meta.set = true; meta.occupancyKey = 1 << 2; transition drop_retention_eth; } state setSKeyDropOther2 { meta.set = true; meta.occupancyKey = 1 << 2; transition drop_other_framing; }


        state setSKeyAccept3 { meta.set = true; meta.occupancyKey = 1 << 3; transition accept; } state setSKeyDropNonRet3 { meta.set = true; meta.occupancyKey = 1 << 3; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet3 { meta.set = true; meta.occupancyKey = 1 << 3; transition drop_retention_eth; } state setSKeyDropOther3 { meta.set = true; meta.occupancyKey = 1 << 3; transition drop_other_framing; }


        state setSKeyAccept4 { meta.set = true; meta.occupancyKey = 1 << 4; transition accept; } state setSKeyDropNonRet4 { meta.set = true; meta.occupancyKey = 1 << 4; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet4 { meta.set = true; meta.occupancyKey = 1 << 4; transition drop_retention_eth; } state setSKeyDropOther4 { meta.set = true; meta.occupancyKey = 1 << 4; transition drop_other_framing; }


        state setSKeyAccept5 { meta.set = true; meta.occupancyKey = 1 << 5; transition accept; } state setSKeyDropNonRet5 { meta.set = true; meta.occupancyKey = 1 << 5; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet5 { meta.set = true; meta.occupancyKey = 1 << 5; transition drop_retention_eth; } state setSKeyDropOther5 { meta.set = true; meta.occupancyKey = 1 << 5; transition drop_other_framing; }


        state setSKeyAccept6 { meta.set = true; meta.occupancyKey = 1 << 6; transition accept; } state setSKeyDropNonRet6 { meta.set = true; meta.occupancyKey = 1 << 6; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet6 { meta.set = true; meta.occupancyKey = 1 << 6; transition drop_retention_eth; } state setSKeyDropOther6 { meta.set = true; meta.occupancyKey = 1 << 6; transition drop_other_framing; }


        state setSKeyAccept7 { meta.set = true; meta.occupancyKey = 1 << 7; transition accept; } state setSKeyDropNonRet7 { meta.set = true; meta.occupancyKey = 1 << 7; eType = pkt.lookahead<bit<112>>()[15:0]; aggKey = pkt.lookahead<bit<128>>()[15:0]; pkt.advance(144); transition drop_non_retention_eth2; } state setSKeyDropRet7 { meta.set = true; meta.occupancyKey = 1 << 7; transition drop_retention_eth; } state setSKeyDropOther7 { meta.set = true; meta.occupancyKey = 1 << 7; transition drop_other_framing; }
# 76 "../../p4c-5323/src/DefeatFlowTracker.p4" 2

  state drop_non_retention_eth {
    eType = pkt.lookahead<bit<112>>()[15:0];
    aggKey = pkt.lookahead<bit<128>>()[15:0];
    pkt.advance(144); //Skip 18 bytes
    transition drop_non_retention_eth2;
  }

  state drop_non_retention_eth2 {
    transition select(eType, aggKey) {
      ((bit<16>)EtherType_t.VLAN, _) : nonRetentionVlan;
      ((bit<16>)EtherType_t.MPLS, _) : nonRetentionVlan;
      (_, 0x0100 &&& 0x0380): frameBytes7Plus;
      (_, 0x0200 &&& 0x0380): frameBytes5Plus;
      (_, 0x0300 &&& 0x0380): frameBytes8Plus;
      (_, 0x0080 &&& 0x0380): frameBytes12Plus;
      (_, 0x0180 &&& 0x0380): frameBytes15Plus;
      (_, 0x0280 &&& 0x0380): frameBytes13Plus;
      (_, 0x0380 &&& 0x0380): frameBytes16Plus;
      default : frameBytes4Plus; //All key bits 0
    }
  }

  state nonRetentionVlan {
    meta.reduceLength = 18;
    transition accept;
  }

  state drop_other_framing {
    FramingMap_h framing = pkt.lookahead<FramingMap_h>();
    transition select(framing.typeIndicator, framing.gfpExt, framing.gfpProtocol) {
      (0x0F00 &&& 0x0FFF, _, _) : frameBytes4;
      (0xFF03, _, _) : parsePppHdlc;
      (0xAAAA, _, _) : frameBytes8;
      (_, 0, (bit<8>)GfpType_t.ETHERNET) : frameBytes8;
      (_, 0, (bit<8>)GfpType_t.PPP) : parseGfpPpp;
      (_, 0, (bit<8>)GfpType_t.ENCODED_ETHERNET) : frameBytes16;
      default : frameBytes8;
    }
  }
# 130 "../../p4c-5323/src/DefeatFlowTracker.p4"
# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 46 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        state frameBytes4 { pkt.advance(8*4); meta.reduceLength = 4; transition accept; } state frameBytes4Plus { pkt.advance(8*4); pkt.advance(16); meta.reduceLength = 4 +20; transition accept; }


        state frameBytes5 { pkt.advance(8*5); meta.reduceLength = 5; transition accept; } state frameBytes5Plus { pkt.advance(8*5); pkt.advance(16); meta.reduceLength = 5 +20; transition accept; }


        state frameBytes6 { pkt.advance(8*6); meta.reduceLength = 6; transition accept; } state frameBytes6Plus { pkt.advance(8*6); pkt.advance(16); meta.reduceLength = 6 +20; transition accept; }


        state frameBytes7 { pkt.advance(8*7); meta.reduceLength = 7; transition accept; } state frameBytes7Plus { pkt.advance(8*7); pkt.advance(16); meta.reduceLength = 7 +20; transition accept; }


        state frameBytes8 { pkt.advance(8*8); meta.reduceLength = 8; transition accept; } state frameBytes8Plus { pkt.advance(8*8); pkt.advance(16); meta.reduceLength = 8 +20; transition accept; }


        state frameBytes9 { pkt.advance(8*9); meta.reduceLength = 9; transition accept; } state frameBytes9Plus { pkt.advance(8*9); pkt.advance(16); meta.reduceLength = 9 +20; transition accept; }


        state frameBytes10 { pkt.advance(8*10); meta.reduceLength = 10; transition accept; } state frameBytes10Plus { pkt.advance(8*10); pkt.advance(16); meta.reduceLength = 10 +20; transition accept; }


        state frameBytes11 { pkt.advance(8*11); meta.reduceLength = 11; transition accept; } state frameBytes11Plus { pkt.advance(8*11); pkt.advance(16); meta.reduceLength = 11 +20; transition accept; }


        state frameBytes12 { pkt.advance(8*12); meta.reduceLength = 12; transition accept; } state frameBytes12Plus { pkt.advance(8*12); pkt.advance(16); meta.reduceLength = 12 +20; transition accept; }


        state frameBytes13 { pkt.advance(8*13); meta.reduceLength = 13; transition accept; } state frameBytes13Plus { pkt.advance(8*13); pkt.advance(16); meta.reduceLength = 13 +20; transition accept; }


        state frameBytes14 { pkt.advance(8*14); meta.reduceLength = 14; transition accept; } state frameBytes14Plus { pkt.advance(8*14); pkt.advance(16); meta.reduceLength = 14 +20; transition accept; }


        state frameBytes15 { pkt.advance(8*15); meta.reduceLength = 15; transition accept; } state frameBytes15Plus { pkt.advance(8*15); pkt.advance(16); meta.reduceLength = 15 +20; transition accept; }


        state frameBytes16 { pkt.advance(8*16); meta.reduceLength = 16; transition accept; } state frameBytes16Plus { pkt.advance(8*16); pkt.advance(16); meta.reduceLength = 16 +20; transition accept; }


        state frameBytes17 { pkt.advance(8*17); meta.reduceLength = 17; transition accept; } state frameBytes17Plus { pkt.advance(8*17); pkt.advance(16); meta.reduceLength = 17 +20; transition accept; }


        state frameBytes18 { pkt.advance(8*18); meta.reduceLength = 18; transition accept; } state frameBytes18Plus { pkt.advance(8*18); pkt.advance(16); meta.reduceLength = 18 +20; transition accept; }


        state frameBytes19 { pkt.advance(8*19); meta.reduceLength = 19; transition accept; } state frameBytes19Plus { pkt.advance(8*19); pkt.advance(16); meta.reduceLength = 19 +20; transition accept; }


        state frameBytes20 { pkt.advance(8*20); meta.reduceLength = 20; transition accept; } state frameBytes20Plus { pkt.advance(8*20); pkt.advance(16); meta.reduceLength = 20 +20; transition accept; }


        state frameBytes21 { pkt.advance(8*21); meta.reduceLength = 21; transition accept; } state frameBytes21Plus { pkt.advance(8*21); pkt.advance(16); meta.reduceLength = 21 +20; transition accept; }


        state frameBytes22 { pkt.advance(8*22); meta.reduceLength = 22; transition accept; } state frameBytes22Plus { pkt.advance(8*22); pkt.advance(16); meta.reduceLength = 22 +20; transition accept; }


        state frameBytes23 { pkt.advance(8*23); meta.reduceLength = 23; transition accept; } state frameBytes23Plus { pkt.advance(8*23); pkt.advance(16); meta.reduceLength = 23 +20; transition accept; }


        state frameBytes24 { pkt.advance(8*24); meta.reduceLength = 24; transition accept; } state frameBytes24Plus { pkt.advance(8*24); pkt.advance(16); meta.reduceLength = 24 +20; transition accept; }


        state frameBytes25 { pkt.advance(8*25); meta.reduceLength = 25; transition accept; } state frameBytes25Plus { pkt.advance(8*25); pkt.advance(16); meta.reduceLength = 25 +20; transition accept; }


        state frameBytes26 { pkt.advance(8*26); meta.reduceLength = 26; transition accept; } state frameBytes26Plus { pkt.advance(8*26); pkt.advance(16); meta.reduceLength = 26 +20; transition accept; }


        state frameBytes27 { pkt.advance(8*27); meta.reduceLength = 27; transition accept; } state frameBytes27Plus { pkt.advance(8*27); pkt.advance(16); meta.reduceLength = 27 +20; transition accept; }


        state frameBytes28 { pkt.advance(8*28); meta.reduceLength = 28; transition accept; } state frameBytes28Plus { pkt.advance(8*28); pkt.advance(16); meta.reduceLength = 28 +20; transition accept; }


        state frameBytes29 { pkt.advance(8*29); meta.reduceLength = 29; transition accept; } state frameBytes29Plus { pkt.advance(8*29); pkt.advance(16); meta.reduceLength = 29 +20; transition accept; }


        state frameBytes30 { pkt.advance(8*30); meta.reduceLength = 30; transition accept; } state frameBytes30Plus { pkt.advance(8*30); pkt.advance(16); meta.reduceLength = 30 +20; transition accept; }


        state frameBytes31 { pkt.advance(8*31); meta.reduceLength = 31; transition accept; } state frameBytes31Plus { pkt.advance(8*31); pkt.advance(16); meta.reduceLength = 31 +20; transition accept; }


        state frameBytes32 { pkt.advance(8*32); meta.reduceLength = 32; transition accept; } state frameBytes32Plus { pkt.advance(8*32); pkt.advance(16); meta.reduceLength = 32 +20; transition accept; }


        state frameBytes33 { pkt.advance(8*33); meta.reduceLength = 33; transition accept; } state frameBytes33Plus { pkt.advance(8*33); pkt.advance(16); meta.reduceLength = 33 +20; transition accept; }


        state frameBytes34 { pkt.advance(8*34); meta.reduceLength = 34; transition accept; } state frameBytes34Plus { pkt.advance(8*34); pkt.advance(16); meta.reduceLength = 34 +20; transition accept; }


        state frameBytes35 { pkt.advance(8*35); meta.reduceLength = 35; transition accept; } state frameBytes35Plus { pkt.advance(8*35); pkt.advance(16); meta.reduceLength = 35 +20; transition accept; }


        state frameBytes36 { pkt.advance(8*36); meta.reduceLength = 36; transition accept; } state frameBytes36Plus { pkt.advance(8*36); pkt.advance(16); meta.reduceLength = 36 +20; transition accept; }
# 131 "../../p4c-5323/src/DefeatFlowTracker.p4" 2

  state parseGfpPpp {
    transition select (pkt.lookahead<bit<104>>()[15:0]){
      0x0031 : frameBytes15;
      default: frameBytes13;
    }
  }

  state parsePppHdlc {
    transition select (pkt.lookahead<bit<32>>()[15:0]){
      0x0031: frameBytes6;
      default: frameBytes4;
    }
  }

  state drop_retention_eth {
    transition select(pkt.lookahead<bit<112>>()[15:0], pkt.lookahead<bit<224>>()[15:0]) {
      ((bit<16>)EtherType_t.VLAN, _) : drop_vlan_flow;
      (_, (bit<16>)EtherType_t.VLAN) : drop_arista_vlan_flow;
      default : parse_arista_ether_type;
    }
  }

  state drop_vlan_flow {
    pkt.extract(hdr.ethernetAddresses);
    pkt.advance(32);
    meta.reduceLength = 4;
    transition accept;
  }

  state drop_arista_vlan_flow {
    pkt.extract(hdr.ethernetAddresses);
    pkt.advance(144);
    meta.reduceLength = 18;
    transition accept;
  }

  state parse_arista_ether_type {
    pkt.extract(hdr.ethernetAddresses);
    pkt.advance(112);
    meta.reduceLength = 14;
    transition accept;
  }
}

# 1 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 1







control SplitRegisterStatefulHashTable(in bit<32> hashKey, in bool set,
  in bit<16> keyPattern, inout bit<16> kp1, inout bit<16> kp2,
  in bit<8> occupied)(bit<3> Match, int stage) {

  Register<bit<16>, bit<17>>(1<<17, 0) dataA;
  Register<bit<16>, bit<17>>(1<<17, 0) dataB;
  RegisterAction<bit<16>, bit<17>, bit<16>>(dataA) getDataA = {
    void apply(inout bit<16> reg, out bit<16> val) {
      val = reg;
    }
  };
  RegisterAction<bit<16>, bit<17>, bit<16>>(dataA) setDataA = {
    void apply(inout bit<16> reg) {
      reg = keyPattern;
    }
  };
  RegisterAction<bit<16>, bit<17>, bit<16>>(dataB) getDataB = {
    void apply(inout bit<16> reg, out bit<16> val) {
      val = reg;
    }
  };
  RegisterAction<bit<16>, bit<17>, bit<16>>(dataB) setDataB = {
    void apply(inout bit<16> reg) {
      reg = keyPattern;
    }
  };

  action actionSetDataA() {
    setDataA.execute(hashKey[16:0]);
  }

  @stage(stage)
  table executeSetDataA {
    actions = { actionSetDataA; }
    default_action = actionSetDataA;
    size = 1;
  }

  action actionSetDataB() {
    setDataB.execute(hashKey[16:0]);
  }

  @stage(stage)
  table executeSetDataB {
    actions = { actionSetDataB; }
    default_action = actionSetDataB;
    size = 1;
  }

  action actionGetDataA() {
    kp1 = getDataA.execute(hashKey[16:0]);
  }

  @stage(stage)
  table executeGetDataA {
    actions = { actionGetDataA; }
    default_action = actionGetDataA;
    size = 1;
  }

  action actionGetDataB() {
    kp2 = getDataB.execute(hashKey[16:0]);
  }

  @stage(stage)
  table executeGetDataB {
    actions = { actionGetDataB; }
    default_action = actionGetDataB;
    size = 1;
  }

  apply {
    if(set && hashKey[19:17] == Match && occupied == 0)
      executeSetDataA.apply();
    else if(set && hashKey[19:17] == Match)
      executeSetDataB.apply();
    else if(hashKey[19:17] == Match) {
      executeGetDataA.apply();
      executeGetDataB.apply();
    }
  }
}

control SplitRegisterStatefulHashTableGID(in bit<32> hashKey, in bool set,
  in bit<8> group, inout bit<8> g1, inout bit<8> g2,
  in bit<8> occupied)(bit<2> Match, int stage) {

  Register<bit<8>, bit<18>>(1<<18, 0) dataGA;
  Register<bit<8>, bit<18>>(1<<18, 0) dataGB;
  RegisterAction<bit<8>, bit<18>, bit<8>>(dataGA) getGDataA = {
    void apply(inout bit<8> reg, out bit<8> val) {
      val = reg;
    }
  };
  RegisterAction<bit<8>, bit<18>, bit<8>>(dataGA) setGDataA = {
    void apply(inout bit<8> reg) {
      reg = group;
    }
  };
  RegisterAction<bit<8>, bit<18>, bit<8>>(dataGB) getGDataB = {
    void apply(inout bit<8> reg, out bit<8> val) {
      val = reg;
    }
  };
  RegisterAction<bit<8>, bit<18>, bit<8>>(dataGB) setGDataB = {
    void apply(inout bit<8> reg) {
      reg = group;
    }
  };

  action actionSetDataA() {setGDataA.execute(hashKey[17:0]);}
  action actionSetDataB() {setGDataB.execute(hashKey[17:0]);}
  action actionGetDataA() {g1 = getGDataA.execute(hashKey[17:0]);}
  action actionGetDataB() {g2 = getGDataB.execute(hashKey[17:0]);}

  @stage(stage)
  table executeSetDataA {
    actions = { actionSetDataA; }
    default_action = actionSetDataA;
    size = 1;
  }

  @stage(stage)
  table executeSetDataB {
    actions = { actionSetDataB; }
    default_action = actionSetDataB;
    size = 1;
  }

  @stage(stage)
  table executeGetDataA {
    actions = { actionGetDataA; }
    default_action = actionGetDataA;
    size = 1;
  }

  @stage(stage)
  table executeGetDataB {
    actions = { actionGetDataB; }
    default_action = actionGetDataB;
    size = 1;
  }

  apply {
    if(set && hashKey[19:18] == Match && occupied == 0)
      executeSetDataA.apply();
    else if(set && hashKey[19:18] == Match)
      executeSetDataB.apply();
    else if(hashKey[19:18] == Match) {
      executeGetDataA.apply();
      executeGetDataB.apply();
    }
  }
}

control ComplexRegister(in bit<32> hash, inout bit<8> result, in bit<8> occupancyKey) {
  Register<bit<8>, bit<17>>(1<<17, 0) occupancy;
  RegisterAction<bit<8>, bit<17>, bit<8>>(occupancy) doOccupancy = {
    void apply(inout bit<8> reg, out bit<8> val) {
      val = reg;
      reg = reg ^ occupancyKey;
    }
  };

  apply {
    result = doOccupancy.execute(hash[19:3]) & occupancyKey;
  }
}

@pa_solitary("DefeatFlows", "egress", "resolver_matched")
@pa_solitary("DefeatFlows", "egress", "resolver_stateGroup")
@pa_solitary("DefeatFlows", "egress", "resolver_statePriority")
@pa_solitary("DefeatFlows", "egress", "resolver_g1")
@pa_solitary("DefeatFlows", "egress", "resolver_g2")

control DefeatFlowResolver(inout Internal_h internal, inout bit<3> drop_ctl, in defeat_flow_meta_t meta) {

  ComplexRegister() toggleReg;
  Priority_t statePriority = 0;
  GroupId_t stateGroup = 0;
  bool matched = false;
  action CommonCleanup() {
    internal.contextualType = ContextualType_t.EXPECT_NO_TYPE;
    internal.framedPacket = FramingType_t.None;
    internal.contextualFlag = 0;
  }

  Register<bit<1>, bit<20>>(1<<20, 0) activeA;
  RegisterAction<bit<1>, bit<20>, bit<1>>(activeA) doActivityA = {
    void apply(inout bit<1> reg) {
      reg = 1;
    }
  };
  Register<bit<1>, bit<20>>(1<<20, 0) activeB;
  RegisterAction<bit<1>, bit<20>, bit<1>>(activeB) doActivityB = {
    void apply(inout bit<1> reg) {
      reg = 1;
    }
  };

  action Drop() {matched = true; drop_ctl = 1;}
  action ChangeOutput(GroupId_t group, Priority_t priority) {matched = true; stateGroup = group; statePriority = priority; drop_ctl = 0;}
  action DefaultAction() {drop_ctl = 0; matched = false;}
  //Sizes tuned to use all MAP RAMs not otherwise used
  //NOTE: High risk of table placement issues with design changes
  //Example user annotations to work with prototype CPP handler
  @digest_controlled_table
  @digest_control_data('{"defaultAction": "DefaultAction", "actionKey": "drop_ctl", "actionMapping": {"0": "ChangeOutput"}, "defaultKeys": {"flowHash1": 0}, "digest": "digestFlow"}')
  //@digest_action_key(drop_ctl)
  //@digest_key_ChangeOutput(0)
  //@digest_key_DefaultAction(1024)
  //@digest_data_default_DOLLAR_SIGN_ENTRY_TTL(2500)
  @idletime_precision(3)
  @stage(0,67584)
  @stage(1,18432)
  @stage(2,18432)
  @stage(3,20480)
  @stage(4,24576)
  @stage(5,24576)
  @stage(6,24576)
  @stage(7,24576)


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 58 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        @stage(8,26624)


        @stage(9,26624)


        @stage(10,26624)


        @stage(11,26624)


        @stage(12,26624)
# 232 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 2


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 73 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        @stage(13,98304)


        @stage(14,98304)


        @stage(15,98304)


        @stage(16,98304)


        @stage(17,98304)
# 235 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 2
  @stage(18)
  table defeatFlow {
    key = {meta.flowHash : exact @name("flowHash2");}
    actions = {Drop; ChangeOutput; @defaultonly DefaultAction;}
    const default_action = DefaultAction();
    idle_timeout = true;
    size = 950000;
  }


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        SplitRegisterStatefulHashTable(0,1) reg0 ;


        SplitRegisterStatefulHashTable(1,2) reg1 ;


        SplitRegisterStatefulHashTable(2,3) reg2 ;


        SplitRegisterStatefulHashTable(3,4) reg3 ;


        SplitRegisterStatefulHashTable(4,5) reg4 ;


        SplitRegisterStatefulHashTable(5,6) reg5 ;


        SplitRegisterStatefulHashTable(6,7) reg6 ;


        SplitRegisterStatefulHashTable(7,8) reg7 ;
# 246 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 2



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        SplitRegisterStatefulHashTableGID(0,9) greg0 ;


        SplitRegisterStatefulHashTableGID(1,10) greg1 ;


        SplitRegisterStatefulHashTableGID(2,11) greg2 ;


        SplitRegisterStatefulHashTableGID(3,12) greg3 ;
# 250 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 2

  apply {
    bit<8> occupancy = 0;
    if(meta.set) toggleReg.apply(meta.flowHash, occupancy, meta.occupancyKey);
    CommonCleanup();
    bit<16> kp1 = 0xF;//Make sure unused if not set
    bit<16> kp2 = 0xF;
    bit<16> keyPattern = meta.flowHash[31:20] ++ internal.priority;
    bit<8> g1 = 0;
    bit<8> g2 = 0;
    bit<8> iGroup = 3w0x0 ++ internal.outputGroup;


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        reg0 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg1 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg2 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg3 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg4 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg5 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg6 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);


        reg7 .apply(meta.flowHash, meta.set, keyPattern, kp1, kp2, occupancy);
# 264 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 2



# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 34 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        greg0 .apply(meta.flowHash, meta.set, iGroup, g1, g2, occupancy);


        greg1 .apply(meta.flowHash, meta.set, iGroup, g1, g2, occupancy);


        greg2 .apply(meta.flowHash, meta.set, iGroup, g1, g2, occupancy);


        greg3 .apply(meta.flowHash, meta.set, iGroup, g1, g2, occupancy);
# 268 "../../p4c-5323/src/FlowTrackerDualRegister.p4" 2

    defeatFlow.apply();
    if(matched &&
        (( internal.priority[3:3] == 1 && statePriority[3:3] == 0 ) ||
         ( internal.priority[2:2] == 1 && statePriority[2:2] == 0 && internal.priority[3:3] == statePriority[3:3]) ||
         ( internal.priority[1:1] == 1 && statePriority[1:1] == 0 && internal.priority[3:3] == statePriority[3:3] && internal.priority[2:2] == statePriority[2:2]) ||
         ( internal.priority[0:0] == 1 && statePriority[0:0] == 0 && internal.priority[3:3] == statePriority[3:3] && internal.priority[2:2] == statePriority[2:2] && internal.priority[1:1] == statePriority[1:1])))
    {
      internal.outputGroup = stateGroup;
      internal.priority = statePriority;
    }
    else if(!matched && meta.flowHash[31:20] == kp1[15:4] &&
        (( internal.priority[3:3] == 1 && kp1[3:3] == 0 ) ||
         ( internal.priority[2:2] == 1 && kp1[2:2] == 0 && internal.priority[3:3] == kp1[3:3]) ||
         ( internal.priority[1:1] == 1 && kp1[1:1] == 0 && internal.priority[3:3] == kp1[3:3] && internal.priority[2:2] == kp1[2:2]) ||
         ( internal.priority[0:0] == 1 && kp1[0:0] == 0 && internal.priority[3:3] == kp1[3:3] && internal.priority[2:2] == kp1[2:2] && internal.priority[1:1] == kp1[1:1])))
    {
      doActivityA.execute(meta.flowHash[19:0]);
      internal.outputGroup = g1[4:0];
      internal.priority = kp1[3:0];
    }
    else if(!matched && meta.flowHash[31:20] == kp2[15:4] &&
        (( internal.priority[3:3] == 1 && kp2[3:3] == 0 ) ||
         ( internal.priority[2:2] == 1 && kp2[2:2] == 0 && internal.priority[3:3] == kp2[3:3]) ||
         ( internal.priority[1:1] == 1 && kp2[1:1] == 0 && internal.priority[3:3] == kp2[3:3] && internal.priority[2:2] == kp2[2:2]) ||
         ( internal.priority[0:0] == 1 && kp2[0:0] == 0 && internal.priority[3:3] == kp2[3:3] && internal.priority[2:2] == kp2[2:2] && internal.priority[1:1] == kp2[1:1])))
    {
      doActivityB.execute(meta.flowHash[19:0]);
      internal.outputGroup = g2[4:0];
      internal.priority = kp2[3:0];
    }
  }
}
# 177 "../../p4c-5323/src/DefeatFlowTracker.p4" 2

control DefeatFlowTracker(inout defeat_flow_headers_t hdr,
                 inout defeat_flow_meta_t meta,
                 in egress_intrinsic_metadata_t eg_intr_md,
                 in egress_intrinsic_metadata_from_parser_t eg_intr_md_from_prsr,
                 inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
                 inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport)
{
  action adjustOffset(bit<8> reduceSkip) {
    hdr.internal.layer2Skip = reduceSkip + hdr.internal.layer2Skip;
  }
  table offsetAdjustment {
    key = {meta.reduceLength : exact;}
    actions = {adjustOffset;}
    const default_action = adjustOffset(0);
    const entries = {


# 1 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp" 1
# 37 "/usr/local/include/boost/preprocessor/iteration/detail/local.hpp"
        1 : adjustOffset(256-1);


        2 : adjustOffset(256-2);


        3 : adjustOffset(256-3);


        4 : adjustOffset(256-4);


        5 : adjustOffset(256-5);


        6 : adjustOffset(256-6);


        7 : adjustOffset(256-7);


        8 : adjustOffset(256-8);


        9 : adjustOffset(256-9);


        10 : adjustOffset(256-10);


        11 : adjustOffset(256-11);


        12 : adjustOffset(256-12);


        13 : adjustOffset(256-13);


        14 : adjustOffset(256-14);


        15 : adjustOffset(256-15);


        16 : adjustOffset(256-16);


        17 : adjustOffset(256-17);


        18 : adjustOffset(256-18);


        19 : adjustOffset(256-19);


        20 : adjustOffset(256-20);


        21 : adjustOffset(256-21);


        22 : adjustOffset(256-22);


        23 : adjustOffset(256-23);


        24 : adjustOffset(256-24);


        25 : adjustOffset(256-25);


        26 : adjustOffset(256-26);


        27 : adjustOffset(256-27);


        28 : adjustOffset(256-28);


        29 : adjustOffset(256-29);


        30 : adjustOffset(256-30);


        31 : adjustOffset(256-31);


        32 : adjustOffset(256-32);


        33 : adjustOffset(256-33);


        34 : adjustOffset(256-34);


        35 : adjustOffset(256-35);


        36 : adjustOffset(256-36);


        37 : adjustOffset(256-37);


        38 : adjustOffset(256-38);


        39 : adjustOffset(256-39);


        40 : adjustOffset(256-40);


        41 : adjustOffset(256-41);


        42 : adjustOffset(256-42);


        43 : adjustOffset(256-43);


        44 : adjustOffset(256-44);


        45 : adjustOffset(256-45);


        46 : adjustOffset(256-46);


        47 : adjustOffset(256-47);


        48 : adjustOffset(256-48);


        49 : adjustOffset(256-49);


        50 : adjustOffset(256-50);


        51 : adjustOffset(256-51);


        52 : adjustOffset(256-52);


        53 : adjustOffset(256-53);


        54 : adjustOffset(256-54);


        55 : adjustOffset(256-55);


        56 : adjustOffset(256-56);


        57 : adjustOffset(256-57);


        58 : adjustOffset(256-58);


        59 : adjustOffset(256-59);


        60 : adjustOffset(256-60);


        61 : adjustOffset(256-61);


        62 : adjustOffset(256-62);


        63 : adjustOffset(256-63);
# 196 "../../p4c-5323/src/DefeatFlowTracker.p4" 2
    }
    size = 256;
  }

  DefeatFlowResolver() resolver;

  apply {
    if(hdr.internal.layer2Skip != 255) offsetAdjustment.apply();
    resolver.apply(hdr.internal, eg_intr_md_for_dprsr.drop_ctl, meta);
  }
}

control DefeatFlowDeparser(packet_out pkt,
                         inout defeat_flow_headers_t hdr,
                         in defeat_flow_meta_t meta,
                         in egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr)
{
  apply { pkt.emit(hdr); }
}
# 9 "../../p4c-5323/src/DefeatFlows.p4" 2
Pipeline(
    ThrottleParser(),
    Throttle(),
    ThrottleDeparser(),
    DefeatFlowParser(),
    DefeatFlowTracker(),
    DefeatFlowDeparser()

    , GhostMetrics()

    )
DefeatFlows;

Switch(DefeatFlows) main;
