#include "bf-p4c-options.h"
#include <boost/algorithm/string.hpp>

safe_vector<cstring> BFN_Options::supported_targets =
    {   "tofino-v1model-barefoot"
      , "tofino-native-barefoot"
#if HAVE_JBAY
      , "jbay-v1model-barefoot"
      , "jbay-native-barefoot"
#endif /* HAVE_JBAY */
    };

std::vector<const char*>* BFN_Options::process(int argc, char* const argv[]) {
    auto remainingOptions = CompilerOptions::process(argc, argv);

    std::vector<std::string> splits;

    std::string target_str(target.c_str());
    boost::split(splits, target_str, [](char c){return c == '-';});

    if (splits.size() != 3)
        BUG("Invalid target %s", target);

    device = splits[0];
    arch   = splits[1];
    vendor = splits[2];

    if (device == "tofino")
        preprocessor_options += " -D__TARGET_TOFINO__";
    else if (device == "jbay")
        preprocessor_options += " -D__TARGET_JBAY__";

    return remainingOptions;
}

