#ifndef BF_ASM_TOFINO_INPUT_XBAR_H_
#define BF_ASM_TOFINO_INPUT_XBAR_H_

#include <input_xbar.h>

template<> void InputXbar::write_galois_matrix(Target::Tofino::mau_regs &regs,
                                               int id, const std::map<int, HashCol> &mat);

#endif /* BF_ASM_TOFINO_INPUT_XBAR_H_ */
