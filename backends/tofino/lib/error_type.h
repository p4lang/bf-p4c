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
    static const int WARN_PHV_ALLOCATION  = 1504;
    static const int WARN_UNINIT_OVERLAY  = 1505;

    static const int FIRST_BACKEND_WARNING = WARN_TABLE_PLACEMENT;

    /// in case we need to
    static ErrorType &getErrorTypes() {
        static ErrorType instance;
        return instance;
    }

    void printWarningsHelp(std::ostream& out);

 private:
    /// Barefoot specific error catalog.
    /// It simply adds all the supported errors and warnings in Barefoot's backend.
    ErrorType() {
        ::ErrorCatalog::getCatalog().add<ErrorMessage::MessageType::Warning,
                WARN_TABLE_PLACEMENT>("table-placement");
        ::ErrorCatalog::getCatalog().add<ErrorMessage::MessageType::Warning,
                WARN_PRAGMA_USE>("pragma-use");
        ::ErrorCatalog::getCatalog().add<ErrorMessage::MessageType::Warning,
                WARN_SUBSTITUTION>("substitution");
        ::ErrorCatalog::getCatalog().add<ErrorMessage::MessageType::Warning,
                WARN_PHV_ALLOCATION>("phv-allocation");
        ::ErrorCatalog::getCatalog().add<ErrorMessage::MessageType::Warning,
                WARN_UNINIT_OVERLAY>("uninitialized-overlay");
    }
};

}  // end namespace BFN

#endif  /* EXTENSIONS_BF_P4C_LIB_ERROR_TYPE_H_ */
