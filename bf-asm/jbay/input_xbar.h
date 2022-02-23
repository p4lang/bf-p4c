#ifndef BF_ASM_JBAY_INPUT_XBAR_H_
#define BF_ASM_JBAY_INPUT_XBAR_H_

#include <input_xbar.h>

#if HAVE_JBAY
template<> void InputXbar::write_galois_matrix(Target::JBay::mau_regs &regs,
                                               int id, const std::map<int, HashCol> &mat);
#endif /* HAVE_JBAY */

#endif /* BF_ASM_JBAY_INPUT_XBAR_H_ */
