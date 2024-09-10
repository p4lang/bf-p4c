#include "backends/tofino/common/run_id.h"

#include <sstream>
#include <iomanip>

#include <boost/uuid/random_generator.hpp>

RunId::RunId() {
    auto uuid = boost::uuids::random_generator()();
    auto uuidBytes = std::vector<uint8_t>(uuid.begin(), uuid.end());
    std::stringstream ss;
    ss << std::hex;
    for (uint8_t b : uuidBytes) {
        ss << std::setw(2) << std::setfill('0') << (int)b;
    }
    _runId = ss.str();
    // Take only the first 16 characters to keep backward-compatibility with previous
    // implementations.
    _runId.resize(16);
}
