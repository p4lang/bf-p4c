#ifndef EXTENSIONS_BF_P4C_COMMON_UTILS_H_
#define EXTENSIONS_BF_P4C_COMMON_UTILS_H_

#include <iostream>

struct DumpPipe : public Inspector {
    const char *heading;
    DumpPipe() : heading(nullptr) {}
    explicit DumpPipe(const char *h) : heading(h) {}
    bool preorder(const IR::Node *pipe) override {
        if (Log::verbose() || LOGGING(1)) {
            if (heading)
                std::cout << "-------------------------------------------------" << std::endl
                          << heading << std::endl
                          << "-------------------------------------------------" << std::endl;
            if (LOGGING(2))
                dump(pipe);
            else
                std::cout << *pipe << std::endl; }
        return false; }
};

#endif /* EXTENSIONS_BF_P4C_COMMON_UTILS_H_ */
