#ifndef BF_P4C_PHV_SOLVER_ACTION_CONSTRAINT_SOLVER_H_
#define BF_P4C_PHV_SOLVER_ACTION_CONSTRAINT_SOLVER_H_

#include <vector>
#include <boost/optional/optional.hpp>
#include "bf-p4c/ir/bitrange.h"
#include "lib/bitvec.h"
#include "lib/cstring.h"
#include "lib/ordered_map.h"
#include "bf-p4c/phv/solver/symbolic_bitvec.h"

namespace solver {

enum class ErrorCode {
    unsat = 1,
    invalid_input = 2,
    too_many_container_sources = 3,
    too_many_unaligned_sources = 4,
    invalid_for_deposit_field = 5,
    smt_sovler_unknown = 6,
    deposit_src2_must_be_dest = 7,
    non_rot_aligned_and_non_byte_shiftable = 8,
    invalid_whole_container_write = 9,
    dark_container_ad_or_const_source = 10,
};

// Error type for all solver.
struct Error {
    ErrorCode code;
    cstring msg;
    Error(ErrorCode code, cstring msg) : code(code), msg(msg){};
};

// CcontainerID is a cstring that uniquely represents a container.
using ContainerID = cstring;

// ContainerSpec container specification.
struct ContainerSpec {
    int size;
    bitvec live;  // bits that *will* have live fieldslices allocated, after action.
};

// Operand represents either a source or a destination of an instruction.
struct Operand {
    bool is_ad_or_const;
    ContainerID container;
    le_bitrange range;
    bool operator==(const Operand& b) const {
        return is_ad_or_const == b.is_ad_or_const && container == b.container && range == b.range;
    }
    bool operator!=(const Operand& b) const { return !(*this == b); }
};
std::ostream& operator<<(std::ostream& s, const Operand&);

// Constructor helper functions for operand.
Operand make_ad_or_const_operand();
Operand make_container_operand(ContainerID c, le_bitrange r);

// Assign is a set instruction that move operand src bits to dst.
struct Assign {
    Operand dst;
    Operand src;
};
std::ostream& operator<<(std::ostream& s, const Assign&);
std::ostream& operator<<(std::ostream& s, const std::vector<Assign>&);

// right-rotate-offset-indexed assignments.
using RotateClassifiedAssigns = std::map<int, std::vector<Assign>>;

/// ActionSolverBase contains basic methods and states for all solvers.
class ActionSolverBase {
 protected:
    // destination-clustered assignments.
    ordered_map<ContainerID, RotateClassifiedAssigns> dest_assigns_i;
    ordered_map<ContainerID, ContainerSpec> specs_i;

 protected:
    /// validate_input run misc basic checks on input, see comments in
    /// function body for details.
    boost::optional<Error> validate_input() const;

 public:
    // add an assignment from the action.
    virtual void add_assign(const Operand& dst, Operand src);

    // set_container_spec will update the container spec.
    virtual void set_container_spec(ContainerID id, int size, bitvec live);

    // return solve result.
    virtual boost::optional<Error> solve() const = 0;

    // clear all states.
    virtual void clear() {
        dest_assigns_i.clear();
        specs_i.clear();
    }
};

/// ActionMoveSolver check move-based instruction constraints for one action,
/// i.e., one solver per action.
/// Internally, a symbolic_bitvec solver is applied on every destination container
/// to verify the possibility of instruction synthesis.
/// This class is designed to be isolated from any concrete backend types,
/// i.e. it's a pure math model that can be easily tested.
/// premise:
///   1. All the input of container slice must have been split to the extent that
///      all instructions are sourcing or assigning to a container slice.
///   2. Any instruction operand is a container slice.
///   3. Container-group constraint has been taken care of by caller.
///   4. Destination can only be a normal container.
/// Supported move instructions:
///   * deposit-field:
///       dest = ((src1 << shift) & mask) | (src2 & ~mask)
///   * bitmasked-set:
///       dest = (src1 & mask) | (src2 & ~mask)
///   * byte-rotate-merge:
///       dest = ((src1 << src1_shift) & mask) | ((src2 << src2_shift) & ~mask)
class ActionMoveSolver : public ActionSolverBase {
 private:
    // check whether @p bv_dest satifies all assignments.
    boost::optional<Error> dest_meet_expectation(const ContainerID dest,
                                                 const std::vector<Assign>& src1,
                                                 const std::vector<Assign>& src2,
                                                 const symbolic_bitvec::BitVec& bv_dest,
                                                 const symbolic_bitvec::BitVec& bv_src1,
                                                 const symbolic_bitvec::BitVec& bv_src2) const;

    // run deposit-field instruction symbolic bitvec solver with specific src1 and src2.
    boost::optional<Error> run_deposit_field_symbolic_bitvec_solver(
        const ContainerID dest,
        const std::vector<Assign>& src1, const std::vector<Assign>& src2) const;

    // an indirection to symbolic bitvec solver, potentially can be other solvers.
    boost::optional<Error> run_deposit_field_solver(
        const ContainerID dest,
        const std::vector<Assign>& src1, const std::vector<Assign>& src2) const;

    // try solve this assignment using deposit-field or bitmasked-set.
    boost::optional<Error> try_deposit_field_or_bitmasked_set(
        const ContainerID dest, const RotateClassifiedAssigns& assigns) const;

    // with known src1 and src2 synthesis and verify.
    boost::optional<Error> run_byte_rotate_merge_symbolic_bitvec_solver(
        const ContainerID dest, const std::vector<Assign>& src1,
        const std::vector<Assign>& src2) const;

    // an indirection to symbolic solver. For byte-rotate-merge,
    // only symbolic solver is implemented.
    boost::optional<Error> run_byte_rotate_merge_solver(
        const ContainerID dest, const std::vector<Assign>& src1,
        const std::vector<Assign>& src2) const;

    // try solve this assignment using byte_rotate_merge.
    // dest = ((src1 << src1_shift) & mask) | ((src2 << src2_shift) & ~mask)
    boost::optional<Error> try_byte_rotate_merge(
        const ContainerID dest, const RotateClassifiedAssigns& assigns) const;

 public:
    ActionMoveSolver() {};

    // solve it
    boost::optional<Error> solve() const override;
};

/// ActionMochaSolver checks basic mocha set constraints for an action that either
/// (1) sources are all constants or action data: can be merge into one operand.
/// (2) sources are of one container: all aligned.
/// Also, we need to ensure that other allocated bits in the container will not be corrupted,
/// and since set instruction on mocha/dark are whole-container-set, all other bits that
/// are not set in this action need to be not live.
class ActionMochaSolver : public ActionSolverBase {
 public:
    ActionMochaSolver() {};
    boost::optional<Error> solve() const override;
};

/// ActionDarkSolver checks basic dark set constraints for an action that either
/// (1) sources are of one container: all aligned.
/// Also, we need to ensure that other allocated bits in the container will not be corrupted,
/// and since set instruction on mocha/dark are whole-container-set, all other bits that
/// are not set in this action need not to be not live.
class ActionDarkSolver : public ActionSolverBase {
 public:
    ActionDarkSolver() {};
    boost::optional<Error> solve() const override;
};

}  // namespace solver

#endif /* BF_P4C_PHV_SOLVER_ACTION_CONSTRAINT_SOLVER_H_ */
