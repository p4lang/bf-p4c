#ifndef BF_ASM_CLOUDBREAK_INPUT_XBAR_H_
#define BF_ASM_CLOUDBREAK_INPUT_XBAR_H_

#include <input_xbar.h>

#if HAVE_CLOUDBREAK
template<> void InputXbar::write_galois_matrix(Target::Cloudbreak::mau_regs &regs,
                                               HashTable id, const std::map<int, HashCol> &mat);
#endif /* HAVE_CLOUDBREAK */

#endif /* BF_ASM_CLOUDBREAK_INPUT_XBAR_H_ */
