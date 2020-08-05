#include <sections.h>
#include <string>

namespace BFASM {

// Singleton class representing the assembler flexible_headers
class FlexibleHeaders : public Section {
 private:
    std::unique_ptr<json::vector> flexHeaders;

    FlexibleHeaders() : Section("flexible_headers") {}

    void input(VECTOR(value_t) args, value_t data) {
        if (!CHECKTYPE(data, tVEC)) return;
        flexHeaders = std::move(toJson(data.vec));
    }

    void output(json::map &ctxtJson) {
        if (flexHeaders != nullptr)
            ctxtJson["flexible_headers"] = std::move(flexHeaders);
    }

 public:
    // disable any other constructors
    FlexibleHeaders(FlexibleHeaders const&)           = delete;
    void operator=(FlexibleHeaders const&)  = delete;

    static FlexibleHeaders singleton_flexHeaders;
} FlexibleHeaders::singleton_flexHeaders;

};  // namespace BFASM
