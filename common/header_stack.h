#ifndef TOFINO_COMMON_HEADER_STACK_H_
#define TOFINO_COMMON_HEADER_STACK_H_

#include "ir/ir.h"
#include "lib/map.h"

class HeaderStackInfo : public Inspector {
 public:
    struct Info {
        cstring name;
        gress_t gress;
        int     size = 0, maxpush = 0, maxpop = 0;
    };

 private:
    std::map<cstring, Info>     info;
    profile_t init_apply(const IR::Node *root) override;
    bool preorder(const IR::Primitive *) override;
    bool preorder(const IR::HeaderStack *) override;

 public:
    auto begin() const -> decltype(Values(info).begin()) { return Values(info).begin(); }
    auto begin() -> decltype(Values(info).begin()) { return Values(info).begin(); }
    auto end() const -> decltype(Values(info).end()) { return Values(info).end(); }
    auto end() -> decltype(Values(info).end()) { return Values(info).end(); }
    auto at(cstring n) const -> decltype(info.at(n)) { return info.at(n); }
    auto at(cstring n) -> decltype(info.at(n)) { return info.at(n); }
};

#endif /* TOFINO_COMMON_HEADER_STACK_H_ */
