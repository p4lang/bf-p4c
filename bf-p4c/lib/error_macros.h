#ifndef EXTENSIONS_BF_P4C_LIB_ERROR_MACROS_H_
#define EXTENSIONS_BF_P4C_LIB_ERROR_MACROS_H_

/// Report an error if condition e is false.
#define ERROR_CHECK(e, ...) do { if (!(e)) ::P4::error(__VA_ARGS__); } while (0)

/// Report a warning if condition e is false.
#define WARN_CHECK(e, ...) do { if (!(e)) ::P4::warning(__VA_ARGS__); } while (0)


/// Trigger a diagnostic message which is treated as a warning by default.
#define DIAGNOSE_WARN(DIAGNOSTIC_NAME, ...) \
    do { ::diagnose(DiagnosticAction::Warn, DIAGNOSTIC_NAME, __VA_ARGS__); } while (0)

/// Trigger a diagnostic message which is treated as an error by default.
#define DIAGNOSE_ERROR(DIAGNOSTIC_NAME, ...) \
    do { ::diagnose(DiagnosticAction::Error, DIAGNOSTIC_NAME, __VA_ARGS__); } while (0)

#endif  /* EXTENSIONS_BF_P4C_LIB_ERROR_MACROS_H_ */
