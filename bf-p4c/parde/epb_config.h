#ifndef EXTENSIONS_BF_P4C_PARDE_EPB_CONFIG_H_
#define EXTENSIONS_BF_P4C_PARDE_EPB_CONFIG_H_

#include <cstdint>

/// Configuration information for the egress parser buffer. The interpretation is
/// device-specific; use the methods on PardeSpec to interact with this
/// information.
struct EgressParserBufferConfig {
    uint16_t fieldsEnabled;
};

#endif /* EXTENSIONS_BF_P4C_PARDE_EPB_CONFIG_H_ */
