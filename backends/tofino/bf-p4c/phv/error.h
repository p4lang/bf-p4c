#ifndef BF_P4C_PHV_ERROR_H_
#define BF_P4C_PHV_ERROR_H_

#include <sstream>

namespace PHV {

/// ErrorCode is the specific reason of failure of function invoke.
enum class ErrorCode {
    ok = 0,
    unknown,
    // utils::is_well_formed
    slicelist_sz_mismatch,
};

/// Error represents an error of internal phv
/// function call. It stores a string of reason for debug
/// and an error code.
class Error : public std::stringstream {
 public:
    ErrorCode code;
    Error(): code(ErrorCode::ok) {}
    void set(ErrorCode c) { code = c; }
    bool is(ErrorCode c) { return code == c; }
};

}  // namespace PHV

#endif  /* BF_P4C_PHV_ERROR_H_ */
