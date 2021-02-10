#ifndef BF_P4C_PHV_PRAGMA_PRETTY_PRINT_H_
#define BF_P4C_PHV_PRAGMA_PRETTY_PRINT_H_

#include <string>
// Pretty-print Pragma classes for debugging and logging purpose

namespace Pragma {

// defines a common interface for pretty printing collected pragmas, also a
// place to hold common pretty print routines if there is any.
class PrettyPrint {
 public:
    virtual std::string pretty_print() const = 0;
};

}

#endif /* BF_P4C_PHV_PRAGMA_PRETTY_PRINT_H_ */
