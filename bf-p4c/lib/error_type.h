#ifndef EXTENSIONS_BF_P4C_LIB_ERROR_TYPE_H_
#define EXTENSIONS_BF_P4C_LIB_ERROR_TYPE_H_

#include <lib/error_catalog.h>

namespace BFN {

/// Barefoot specific error and warning types.
class ErrorType: public ::ErrorType {
 public:
    static const int WARN_TABLE_PLACEMENT = 1501;
    static const int WARN_PRAGMA_USE      = 1502;
    static const int WARN_SUBSTITUTION    = 1503;

    /// in case we need to
    static ErrorType &getErrorTypes() {
        static ErrorType instance;
        return instance;
    }

 private:
    /// Barefoot specific error catalog.
    /// It simply adds all the supported errors and warnings in Barefoot's backend.
    ErrorType() {
        ::ErrorCatalog::getCatalog().add(WARN_TABLE_PLACEMENT, "table-placement", "");
        ::ErrorCatalog::getCatalog().add(WARN_PRAGMA_USE, "pragma-use", "");
        ::ErrorCatalog::getCatalog().add(WARN_SUBSTITUTION, "substitution", "");
    }
};

};  // end namespace BFN

#endif  /* EXTENSIONS_BF_P4C_LIB_ERROR_TYPE_H_ */
