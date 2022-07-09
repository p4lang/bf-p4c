#ifndef _EXTENSIONS_BF_P4C_LOGGING_BF_ERROR_REPORTER_H_
#define _EXTENSIONS_BF_P4C_LOGGING_BF_ERROR_REPORTER_H_

#include "lib/error_reporter.h"

bool   get_has_output_already_been_silenced();
void reset_has_output_already_been_silenced();

class BfErrorReporter : public ErrorReporter {
 protected:
    void emit_message(const ErrorMessage &msg) override;

    void emit_message(const ParserErrorMessage &msg) override;
};

#endif  /* _EXTENSIONS_BF_P4C_LOGGING_BF_ERROR_REPORTER_H_ */
