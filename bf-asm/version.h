#pragma once
#include <string>

namespace BFASM {
// Singleton class representing the assembler version
class Version {
 public:
    static const std::string getVersion() {
        static Version v;
        return std::to_string(v.major) + "." + std::to_string(v.minor) + "." +
            std::to_string(v.patch);
    }
 private:
    static constexpr int major = 1;
    static constexpr int minor = 0;
    static constexpr int patch = 1;

    Version() {}

 public:
    // disable any other constructors
    Version(Version const&)           = delete;
    void operator=(Version const&)  = delete;
};

}  // end namespace BFAS
