#ifndef BF_ASM_GTEST_REGISTER_MATCHER_H_
#define BF_ASM_GTEST_REGISTER_MATCHER_H_

#include <cstdint>
#include <iosfwd>
#include <sstream>

#include "bf-asm/ubits.h"
#include "gtest/gtest.h"
#include "p4c/lib/bitvec.h"

namespace BfAsm {

namespace Test {

class RegisterMatcher {
 private:
    bitvec expected;
    uint32_t bitsize;

 public:
    explicit RegisterMatcher(const char *spec);

    bool checkRegister(std::ostream &os, const uint8_t reg[], uint32_t size) const;

    template <int N>
    bool checkRegister(std::ostream &os, const ubits<N> &bits) const {
        static_assert(N > 0 && N <= 64);
        const uint64_t value(bits);
        return checkRegister(os, reinterpret_cast<const uint8_t *>(&value), (N + 7) / 8);
    }

 private:
    void pushBits(const bitvec& bits, uint32_t width);
};

} /* -- namespace Test */

} /* -- namespace BfAsm */

#define EXPECT_REGISTER(reg, expected)                                                          \
    do {                                                                                        \
        RegisterMatcher matcher(expected);                                                      \
        std::ostringstream oss;                                                                 \
        if (!matcher.checkRegister(oss, reg)) {                                                 \
            ADD_FAILURE() << "check of the register " << #reg << " has failed:\n" << oss.str(); \
        }                                                                                       \
    } while (false)

#endif /* BF_ASM_GTEST_REGISTER_MATCHER_H_ */
