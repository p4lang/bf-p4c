#ifndef EXTENSIONS_BF_P4C_MIDEND_FLATTEN_EMIT_ARGS_H_
#define EXTENSIONS_BF_P4C_MIDEND_FLATTEN_EMIT_ARGS_H_

#include "ir/ir.h"

class FlattenEmitArgs : public Modifier {
    void postorder(IR::MethodCallExpression* mc) override;
    IR::ListExpression* flatten_args(const IR::ListExpression* args);
    void  explode(const IR::Expression*, IR::Vector<IR::Expression>*);
};

#endif /* EXTENSIONS_BF_P4C_MIDEND_FLATTEN_EMIT_ARGS_H_ */
