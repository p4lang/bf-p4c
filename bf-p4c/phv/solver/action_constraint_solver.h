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

/// ContainerID is a cstring that uniquely represents a container.
/// Empty string is reserved to represent const or action data.
using ContainerID = cstring;

/// base class for all instructions.
/// TODO(yumin): currenly instruction classes only print a readable string representation.
/// To print asm-compatible string, we need
/// (1) distinguish inline const v.s. action data.
/// (2) allow replacing action data with actual address.
class Instruction {
 public:
    virtual cstring name() const = 0;
    virtual cstring to_cstring() const = 0;
};

/// deposit-field instruction.
///   dest = ((src1 << shift) & mask) | (src2 & ~mask)
/// Note that in some docs, deposit-field is using right rotate instead of left rotate here.
/// Since left/right rotate is isomorphic, we will simply use left rotate in this
/// module.
class DepositField : public Instruction {
 public:
    ContainerID dest;
    ContainerID src1;
    int left_rotate;
    bitvec mask;
    ContainerID src2;
    DepositField(ContainerID dest, ContainerID src1, int left_rotate, bitvec mask,
                 ContainerID src2)
        : dest(dest), src1(src1), left_rotate(left_rotate), mask(mask), src2(src2) {}
    cstring name() const override { return "deposit-field"; };
    cstring to_cstring() const override;
};

/// bitmasked-set:
///     dest = (src1 & mask) | (src2 & ~mask)
class BitmaskedSet : public Instruction {
 public:
    ContainerID dest;
    ContainerID src1;
    ContainerID src2;
    bitvec mask;
    BitmaskedSet(ContainerID dest, ContainerID src1, ContainerID src2, bitvec mask)
        : dest(dest), src1(src1), src2(src2), mask(mask) {}
    cstring name() const override { return "bitmasked-set"; };
    cstring to_cstring() const override;
};

/// byte-rotate-merge:
///   dest = ((src1 << src1_shift) & mask) | ((src2 << src2_shift) & ~mask)
class ByteRotateMerge : public Instruction {
 public:
    ContainerID dest;
    ContainerID src1;
    int shift1;
    ContainerID src2;
    int shift2;
    bitvec mask;
    ByteRotateMerge(ContainerID dest, ContainerID src1, int shift1, ContainerID src2, int shift2,
                    bitvec mask)
        : dest(dest), src1(src1), shift1(shift1), src2(src2), shift2(shift2), mask(mask) {}
    cstring name() const override { return "byte-rotate-merge"; };
    cstring to_cstring() const override;
};

/// ContainerSet is a simple container set op that writes all aligned bits in dest by src.
/// It is the only instruction to set dark or mocha container.
///   dest = src.
class ContainerSet : public Instruction {
 public:
    ContainerID dest;
    ContainerID src;
    ContainerSet(ContainerID dest, ContainerID src)
        : dest(dest), src(src) {}
    cstring name() const override { return "set"; };
    cstring to_cstring() const override;
};

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

// ContainerSpec container specification.
struct ContainerSpec {
    int size;
    bitvec live;  // bits that *will* have live fieldslices allocated, after action.
};

// Result contains either an error or all instructions for an action.
struct Result {
    boost::optional<Error> err;
    std::vector<const Instruction*> instructions;
    Result(){}
    explicit Result(const Error& err): err(err) {}
    explicit Result(const Instruction* inst): instructions({inst}) {}
    explicit Result(const std::vector<const Instruction*>& instructions)
        : instructions(instructions) {}
    bool ok() { return !err; }
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
    bool enable_bitmasked_set_i = true;

 protected:
    /// validate_input run misc basic checks on input, see comments in
    /// function body for details.
    boost::optional<Error> validate_input() const;

    /// try to use container set to synthesize all assignments to @p dest, either
    /// (1) sources are all constants: can be merge into one constant or action data, or
    /// (2) sources are of one container: all aligned, or
    /// (3) sources are all action data.
    /// Also, We need to ensure that other allocated bits in the container will not be corrupted,
    /// i.e., all other bits of dest that are not set in this action need to be not live.
    Result try_container_set(const ContainerID dest,
                             const RotateClassifiedAssigns& offset_assigns) const;

 public:
    // set true to enable bitmasked_set set, otherwise disable. default: enable.
    void enable_bitmasked_set(bool enable) {
        enable_bitmasked_set_i = enable;
    }

    // add an assignment from the action.
    virtual void add_assign(const Operand& dst, Operand src);

    // set_container_spec will update the container spec.
    virtual void set_container_spec(ContainerID id, int size, bitvec live);

    // return solve result.
    virtual Result solve() const = 0;

    // clear all states and will reset enable_bitmasked_set to true.
    virtual void clear() {
        dest_assigns_i.clear();
        specs_i.clear();
        enable_bitmasked_set_i = true;
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
    // When src2 is empty, src2 is assumed to be dest.
    Result run_deposit_field_symbolic_bitvec_solver(
        const ContainerID dest,
        const std::vector<Assign>& src1, const std::vector<Assign>& src2) const;

    // an indirection to symbolic bitvec solver, potentially can be other solvers.
    Result run_deposit_field_solver(
        const ContainerID dest,
        const std::vector<Assign>& src1, const std::vector<Assign>& src2) const;

    // try solve this assignment using deposit-field.
    Result try_deposit_field(
        const ContainerID dest, const RotateClassifiedAssigns& assigns) const;

    // Build and run a symbolic solver to check possibility of assignments on dest from
    // src1 and src2. When src2 is empty, src2 is assumed to be dest.
    Result run_byte_rotate_merge_symbolic_bitvec_solver(
        const ContainerID dest, const std::vector<Assign>& src1,
        const std::vector<Assign>& src2) const;

    // an indirection to symbolic solver. For byte-rotate-merge,
    // only symbolic solver is implemented.
    Result run_byte_rotate_merge_solver(
        const ContainerID dest, const std::vector<Assign>& src1,
        const std::vector<Assign>& src2) const;

    // try to solve this assignment using byte_rotate_merge.
    // dest = ((src1 << src1_shift) & mask) | ((src2 << src2_shift) & ~mask)
    Result try_byte_rotate_merge(
        const ContainerID dest, const RotateClassifiedAssigns& assigns) const;

    // try to solve this assignment using bitmasked-set.
    // Note that, even if it's possible to just use a simple ContainerSet, this function
    // will return a BitmaskedSet. Since a simple containerSet can be considered as a
    // special form of deposit-field with 0 shift and full mask, make sure to try use
    // deposit-field first.
    Result try_bitmasked_set(
        const ContainerID dest, const RotateClassifiedAssigns& assigns) const;

 public:
    Result solve() const override;
};

/// ActionMochaSolver checks basic mocha set constraints for an action that either
/// (1) sources are all constants or action data: can be merge into one operand.
/// (2) sources are of one container: all aligned.
/// Also, we need to ensure that other allocated bits in the container will not be corrupted,
/// and since set instruction on mocha are whole-container-set, all other bits that
/// are not set in this action need to be not live.
class ActionMochaSolver : public ActionSolverBase {
 public:
    ActionMochaSolver() {};
    Result solve() const override;
};

/// ActionDarkSolver checks basic dark set constraints for an action that either
/// (1) sources are of one container: all aligned.
/// Also, we need to ensure that other allocated bits in the container will not be corrupted,
/// and since set instruction on mocha/dark are whole-container-set, all other bits that
/// are not set in this action need not to be not live.
class ActionDarkSolver : public ActionSolverBase {
 public:
    ActionDarkSolver() {};
    Result solve() const override;
};

}  // namespace solver

#endif /* BF_P4C_PHV_SOLVER_ACTION_CONSTRAINT_SOLVER_H_ */