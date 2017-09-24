#include "bf-p4c-options.h"

vector<cstring> BFN_Options::supported_targets =
    { "tofino-v1model-barefoot"
      , "tofino-native-barefoot"
#if HAVE_JBAY
      , "jbay-v1model-barefoot"
#endif /* HAVE_JBAY */
    };
