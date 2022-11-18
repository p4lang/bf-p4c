#include <stdio.h>

#include "gtest/gtest.h"

#include "lib/log.h"
#include "lib/compile_context.h"
#include "lib/options.h"

template <typename OptionsType>
class CompileContext : public virtual BaseCompileContext {
 public:
    /// @return the current compilation context, which must be of type
    /// CompileContext<OptionsType>.
    static CompileContext& get() { return CompileContextStack::top<CompileContext>(); }

    CompileContext() {}

    template <typename OptionsDerivedType>
    CompileContext(CompileContext<OptionsDerivedType>& context)
        : optionsInstance(context.options()) {}

    /// @return the compiler options for this compilation context.
    OptionsType& options() { return optionsInstance; }

 private:
    /// The compiler options for this compilation context.
    OptionsType optionsInstance;
};

class GTestOptions : public Util::Options {
    static const char* defaultMessage;

 public:
    GTestOptions() : Util::Options(defaultMessage) {
        registerOption(
            "-T", "loglevel",
            [](const char* arg) {
                Log::addDebugSpec(arg);
                return true;
            },
            "[Compiler debugging] Adjust logging level per file (see below)");
    }
    std::vector<const char*>* process(int argc, char* const argv[]) {
        auto remainingOptions = Util::Options::process(argc, argv);
        return remainingOptions;
    }
    const char* getIncludePath() { return ""; }
};

const char* GTestOptions::defaultMessage = "bf-asm gtest";

using GTestContext = CompileContext<GTestOptions>;

GTEST_API_ int main(int argc, char **argv) {
    printf("running gtestasm\n");

    // process gtest flags
    ::testing::InitGoogleTest(&argc, argv);

    // process debug flags
    AutoCompileContext autoGTestContext(new GTestContext);
    GTestContext::get().options().process(argc, argv);

    return RUN_ALL_TESTS();
}
