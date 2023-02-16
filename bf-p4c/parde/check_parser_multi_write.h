#ifndef BF_P4C_PARDE_CHECK_PARSER_MULTI_WRITE_H_
#define BF_P4C_PARDE_CHECK_PARSER_MULTI_WRITE_H_

#include <ir/ir.h>
#include "ir/pass_manager.h"

/**
 * @ingroup parde
 * @brief Checks multiple writes to the same field on non-mutually exclusive paths.
 */
struct CheckParserMultiWrite : public PassManager {
    const PhvInfo& phv;

    explicit CheckParserMultiWrite(const PhvInfo& phv);
};

#endif /*BF_P4C_PARDE_CHECK_PARSER_MULTI_WRITE_H_*/
