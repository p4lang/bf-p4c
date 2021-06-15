#include "phv/solver/action_constraint_solver.h"

#include <chrono>
#include <sstream>
#include <unordered_set>
#include "bf-p4c/ir/bitrange.h"
#include "lib/exceptions.h"
#include "lib/log.h"
#include "lib/ordered_set.h"

namespace solver {

namespace {

struct SourceClassifiedAssigns {
    std::vector<Assign> ad_or_const;
    ordered_map<ContainerID, std::vector<Assign>> containers;

    // return the number of sources.
    int n_sources() const { return int(!ad_or_const.empty()) + containers.size(); }

    // n can be 1 or 2, represent the src1 and src2 for the instruction.
    // prefer to use ad_or_const as src.
    const std::vector<Assign>& get_src(int n) const {
        BUG_CHECK(n_sources() >= n, "get src out of index %1%", n);
        BUG_CHECK(n <= 2 && n > 0, "SourceClassifiedAssigns can only return src1 or src2");
        if (!ad_or_const.empty()) {
            if (n == 1) {
                return ad_or_const;
            } else {
                return containers.begin()->second;
            }
        } else {
            if (n == 1) {
                return containers.begin()->second;
            } else {
                return std::next(containers.begin())->second;
            }
        }
    }
};

SourceClassifiedAssigns classify_by_sources(const std::vector<Assign>& assigns) {
    SourceClassifiedAssigns rst;
    for (const auto& assign : assigns) {
        if (assign.src.is_ad_or_const) {
            rst.ad_or_const.push_back(assign);
        } else {
            rst.containers[assign.src.container].push_back(assign);
        }
    }
    return rst;
}

int right_rotate_offset(const Assign& assign, int container_sz) {
    if (assign.src.is_ad_or_const) {
        return 0;
    }
    int n_right_shift_bits = assign.src.range.lo - assign.dst.range.lo;
    if (n_right_shift_bits < 0) {
        n_right_shift_bits += container_sz;  // wrap-around case
    }
    return n_right_shift_bits;
}

int right_rotate_to_left_rotate(int n, int container_sz) {
    n = container_sz - n;
    if (n > container_sz) {
        n -= container_sz;
    } else if (n < 0) {
        n += container_sz;
    }
    return n;
}

bitvec byte_rotate_merge_src1_mask(const std::vector<Assign>& assigns) {
    bitvec mask;
    for (const auto& v : assigns) {
        const int lo = (v.dst.range.lo / 8) * 8;
        const int width = (v.dst.range.hi / 8) * 8 - lo + 8;
        mask.setrange(lo, width);
    }
    return mask;
}

int n_left_shift_bits(int container_sz, const std::vector<Assign>& assigns) {
    if (assigns.empty()) {
        return 0;
    }
    return right_rotate_to_left_rotate(right_rotate_offset(assigns.front(), container_sz),
                                       container_sz);
}

void assign_input_bug_check(const ordered_map<ContainerID, ContainerSpec>& specs,
                            const Assign& assign) {
    for (const auto op : {assign.src, assign.dst}) {
        if (op.is_ad_or_const) {
            continue;
        }
        BUG_CHECK(specs.count(op.container), "container used missing spec: %1%", op.container);
        BUG_CHECK(op.range.lo <= op.range.hi, "range must be less or equal to  hi: %1%", op);
        BUG_CHECK(op.range.lo >= 0 && op.range.hi < specs.at(op.container).size,
                  "out of index range: %1% of %2%, container size: %3%", op, assign,
                  specs.at(op.container).size);
    }
    // check assigned destination bits are live because we should never move bits
    // to non-field bit position in a container - usually it's a bug from caller.
    for (int i = assign.dst.range.lo; i <= assign.dst.range.hi; i++) {
        BUG_CHECK(specs.at(assign.dst.container).live[i],
                  "container %1%'s %2%th bit is not claimed live, but was set by %3%",
                  assign.dst.container, i, assign);
    }

    BUG_CHECK(!assign.dst.is_ad_or_const, "destination cannot be const or action data: %1%");
    if (!assign.src.is_ad_or_const) {
        BUG_CHECK(assign.dst.range.size() == assign.src.range.size(),
                  "assignment range mismatch: %1%", assign);
        BUG_CHECK(specs.at(assign.dst.container).size == specs.at(assign.src.container).size,
                  "container size mismatch: %1%", assign);
    }
}

/// return the first container bit that are live but not set for by assigns. A non-none return
/// value means that the bit@i is corrupted because of the whole container set instruction.
boost::optional<int> invalid_whole_container_set(const std::vector<Assign>& assigns,
                                                 const bitvec& live, const int container_sz) {
    bitvec set_bits;
    for (const auto& assign : assigns) {
        set_bits.setrange(assign.dst.range.lo, assign.dst.range.size());
    }
    for (int i = 0; i < container_sz; i++) {
        if (live[i] && !set_bits[i]) {
            return i;
        }
    }
    return boost::none;
}

}  // namespace

Operand make_ad_or_const_operand() { return Operand{true, "", le_bitrange()}; }

Operand make_container_operand(ContainerID c, le_bitrange r) {
    return Operand{false, c, r};
}

void ActionSolverBase::add_assign(const Operand& dst, Operand src) {
    // Assume that ad_or_const sources are always aligned with dst.
    if (src.is_ad_or_const) {
        src.range = dst.range;
    }
    // move-based instructions can ignore move to itself.
    if (src == dst) {
        return;
    }
    const Assign assign{dst, src};
    LOG5("Solver add new assign: " << assign);
    assign_input_bug_check(specs_i, assign);
    const int offset = right_rotate_offset(assign, specs_i.at(dst.container).size);
    dest_assigns_i[dst.container][offset].push_back(assign);
}

void ActionSolverBase::set_container_spec(ContainerID id, int size, bitvec live) {
    BUG_CHECK(size <= 32, "container larger than 32-bit is not supported");
    specs_i[id] = ContainerSpec{size, live};
}

boost::optional<Error> ActionSolverBase::validate_input() const {
    std::stringstream err_msg;
    for (const auto& dest_assigns : dest_assigns_i) {
        bitvec assigned;
        for (const auto& offset_assigns : dest_assigns.second) {
            for (const auto& assign : offset_assigns.second) {
                const auto& dst = assign.dst;
                // no bit is assigned more than once.
                for (int i = dst.range.lo; i <= dst.range.hi; i++) {
                    if (assigned[i]) {
                        err_msg << "container " << dst.container << "'s " << i << "th bit is "
                                << "assigned multiple times";
                        return Error(ErrorCode::invalid_input, err_msg.str());
                    }
                }
                assigned.setrange(dst.range.lo, dst.range.size());
            }
        }
    }
    return boost::none;
}

boost::optional<Error> ActionMoveSolver::dest_meet_expectation(
    const ContainerID dest, const std::vector<Assign>& src1, const std::vector<Assign>& src2,
    const symbolic_bitvec::BitVec& bv_dest, const symbolic_bitvec::BitVec& bv_src1,
    const symbolic_bitvec::BitVec& bv_src2) const {
    std::stringstream ss;
    // For live bits, they must be either
    // (1) unchanged.
    // (2) set by a correct bit from one of the source.
    // checking (2) here:
    bitvec set_bits;
    for (const auto& assigns : {std::make_pair(src1, bv_src1), std::make_pair(src2, bv_src2)}) {
        const auto& source_bv = assigns.second;
        for (const auto& assign : assigns.first) {
            const int dst_lo = assign.dst.range.lo;
            const int src_lo = assign.src.range.lo;
            const int sz = assign.dst.range.size();
            set_bits.setrange(dst_lo, sz);
            if (!bv_dest.slice(dst_lo, sz).eq(source_bv.slice(src_lo, sz))) {
                ss << "solver unsat because " << assign << " cannot be satisfied";
                return Error(ErrorCode::unsat, ss.str());
            }
        }
    }

    // Any bit that is live (occupied by some non-mutex fields) and not set,
    // it cannot be changed. The only possible case that it will not be changed is
    // when src2 and dest are the same container, for both deposit-field or byte-rotate-merge.
    // Because in this solver, we always use src2 as background if needed.
    bool require_src2_be_dest = false;
    const auto& live_bits = specs_i.at(dest).live;
    for (int i = 0; i < specs_i.at(dest).size; i++) {
        // bits occupied by other field not involved in this action.
        // It's safe to assume that those bits are from s2, as long as
        // we called this function with both (s1, s2) and (s2, s1).
        if (live_bits[i] && !set_bits[i]) {
            require_src2_be_dest = true;
            if (!bv_dest.get(i)->eq(bv_src2.get(i))) {
                ss << "solver unsat because dest[" << i << "] is overwritten unexpectedly";
                return Error(ErrorCode::unsat, ss.str());
            }
        }
    }
    if (require_src2_be_dest && !src2.empty() && dest != src2.front().src.container) {
        std::stringstream ss;
        ss << "destination " << dest << " will be corrupted because src2 "
           << src2.front().src.container << " is not equal to dest";
        return Error(ErrorCode::deposit_src2_must_be_dest, ss.str());
    }
    return boost::none;
}

boost::optional<Error> ActionMoveSolver::run_deposit_field_symbolic_bitvec_solver(
    const ContainerID dest, const std::vector<Assign>& src1,
    const std::vector<Assign>& src2) const {
    LOG5("deposit-field.src1 assigns: " << src1);
    LOG5("deposit-field.src2 assigns: " << src2);
    const int width = specs_i.at(dest).size;
    // pre-compute rot
    int n_right_rotate = right_rotate_offset(src1.front(), width);
    // pre-compute mask
    int mask_l = width;
    int mask_h = -1;
    for (const auto& assign : src1) {
        mask_l = std::min(mask_l, assign.dst.range.lo);
        mask_h = std::max(mask_h, assign.dst.range.hi);
    }
    bitvec mask;
    mask.setrange(mask_l, mask_h - mask_l + 1);

    // build solver
    using namespace solver::symbolic_bitvec;
    BvContext ctx;
    const auto bv_src1 = ctx.new_bv(width);
    const auto bv_src2 = ctx.new_bv(width);
    const auto bv_mask = ctx.new_bv_const(width, mask);
    const auto bv_dest = (((bv_src1 >> n_right_rotate) & bv_mask) | (bv_src2 & (~bv_mask)));
    LOG3("deposit-field mask.l = " << mask_l);
    LOG3("deposit-field mask.h = " << mask_h);
    LOG3("deposit-field rot = " << n_right_rotate);
    return dest_meet_expectation(dest, src1, src2, bv_dest, bv_src1, bv_src2);
}

// run deposit-field instruction symbolic bitvec solver.
boost::optional<Error> ActionMoveSolver::run_deposit_field_solver(
    const ContainerID dest, const std::vector<Assign>& src1,
    const std::vector<Assign>& src2) const {
    return run_deposit_field_symbolic_bitvec_solver(dest, src1, src2);
}

boost::optional<Error> ActionMoveSolver::try_deposit_field_or_bitmasked_set(
    const ContainerID dest, const RotateClassifiedAssigns& assigns) const {
    std::stringstream err_msg;
    if (assigns.size() > 2 || (assigns.size() == 2 && !assigns.count(0))) {
        err_msg << "container " << dest
                << " has too many unaligned or non-rotationally aligned sources";
        return Error(ErrorCode::too_many_unaligned_sources, err_msg.str());
    }
    // all possible cases and possible way to synthesize instruction is listed:
    if (assigns.size() == 1) {
        // case-1 only one offset.
        const auto source_classified = classify_by_sources(assigns.begin()->second);
        if (assigns.count(0)) {
            // case-1.1 align
            if (source_classified.n_sources() == 1) {
                // case-1.1.1 all assignments were from the same container(or ad),
                // this case is always possible with bitmasked-set.
                return boost::none;
            } else if (source_classified.n_sources() == 2) {
                // case-1.1.2 assignments were from 2 containers(or ad),
                // might be possible by splitting into two operand for deposit-field.
                auto err = run_deposit_field_solver(dest, source_classified.get_src(1),
                                                    source_classified.get_src(2));
                if (err && source_classified.ad_or_const.empty()) {
                    // a special case that when two sources are aligned and both are container
                    // sources, we can try swap src1 and src2 to see if we can get correct
                    // mask.
                    return run_deposit_field_solver(dest, source_classified.get_src(2),
                                                    source_classified.get_src(1));
                }
                return err;
            } else {
                // case-1.1.3 more than 2 sources, not possible
                err_msg << "container " << dest << " has too many different container sources: "
                        << source_classified.n_sources();
                return Error(ErrorCode::too_many_container_sources, err_msg.str());
            }
        } else {
            // case-1.2 not aligned
            if (source_classified.n_sources() == 1) {
                // case-1.2.1 only one source, not always possible because of the mask
                // need to run solver to check.
                return run_deposit_field_solver(dest, source_classified.get_src(1), {});
            } else {
                // case-1.2.2 more than 1 unaligned sources, no possible
                err_msg << "container " << dest << " has too many unaligned container sources: "
                        << source_classified.n_sources();
                return Error(ErrorCode::too_many_unaligned_sources, err_msg.str());
            }
        }
    } else if (assigns.size() == 2) {
        // case-2
        if (!assigns.count(0)) {
            // case-2.1 more than 1 unaligned sources, no possible
            BUG("impossible to reach this point, should have been caught by above checks.");
        } else {
            // case-2.2 1 aligned, 1 rotationally aligned.
            // The aligned source must be src2, and cannot be ad_or_const source
            // The rotationally aligned source must be src1.
            const auto src2 = classify_by_sources(assigns.begin()->second);
            const auto src1 = classify_by_sources(std::next(assigns.begin())->second);
            for (const auto& src : {src1, src2}) {
                if (src.n_sources() > 1) {
                    err_msg << "container " << dest
                            << " has too many different container sources for one same offset: "
                            << src1.n_sources();
                    return Error(ErrorCode::too_many_container_sources, err_msg.str());
                }
            }
            if (!src2.ad_or_const.empty()) {
                err_msg << "container " << dest << " cannot have ad_or_const source as src2";
                return Error(ErrorCode::invalid_for_deposit_field, err_msg.str());
            }
            return run_deposit_field_solver(dest, src1.get_src(1), src2.get_src(1));
        }
    } else {
        // case-3, more than 2 shift offst, not possible
        BUG("impossible to reach this point, should have been caught by above checks.");
    }
}

boost::optional<Error> ActionMoveSolver::run_byte_rotate_merge_symbolic_bitvec_solver(
    const ContainerID dest, const std::vector<Assign>& src1,
    const std::vector<Assign>& src2) const {
    LOG5("byte-rotate-merge.src1 assigns: " << src1);
    LOG5("byte-rotate-merge.src2 assigns: " << src2);

    // generate mask2 from src1, that always exists.
    const int width = specs_i.at(dest).size;
    const bitvec mask1 = byte_rotate_merge_src1_mask(src1);
    const int src1_shift = n_left_shift_bits(width, src1);
    const int src2_shift = n_left_shift_bits(width, src2);
    using namespace solver::symbolic_bitvec;
    BvContext ctx;
    const auto bv_src1 = ctx.new_bv(width);
    const auto bv_src2 = ctx.new_bv(width);
    const auto bv_mask1 = ctx.new_bv_const(width, mask1);
    const auto bv_dest =
        (((bv_src1 << src1_shift) & bv_mask1) | ((bv_src2 << src2_shift) & (~bv_mask1)));

    LOG3("mask bv: " << mask1);
    LOG3("byte-rotate-merge.src1_left_shift: " << src1_shift);
    LOG3("byte-rotate-merge.src2_left_shift: " << src2_shift);
    LOG3("byte-rotate-merge.src1_mask: " << bv_mask1.to_cstring());
    return dest_meet_expectation(dest, src1, src2, bv_dest, bv_src1, bv_src2);
}

boost::optional<Error> ActionMoveSolver::run_byte_rotate_merge_solver(
    const ContainerID dest, const std::vector<Assign>& src1,
    const std::vector<Assign>& src2) const {
    return run_byte_rotate_merge_symbolic_bitvec_solver(dest, src1, src2);
}

// try solve this assignment using byte_rotate_merge.
// classify assignments by
// (1) shift offset.
// (2) sources.
// There can only be up to 2 shifts, and per each shift, only one source, and ad_or_const
// data must all have the same shifts in src1. (no need to check this, because we
// assume it's always possible).
boost::optional<Error> ActionMoveSolver::try_byte_rotate_merge(
    const ContainerID dest, const RotateClassifiedAssigns& assigns) const {
    std::stringstream ss;
    // more than two different shift offsets.
    if (assigns.size() > 2) {
        ss << "too many different-offset byte shifts required: " << assigns.size();
        return Error(ErrorCode::too_many_unaligned_sources, ss.str());
    }

    // non-byte-aligned shifts not possible for byte_rotate_merge.
    for (const auto& offset_assigns : assigns) {
        const int& offset = offset_assigns.first;
        if (offset % 8 != 0) {
            ss << "dest " << dest << " has non-byte-shiftable source: " << offset_assigns.first
               << ", " << offset_assigns.second;
            return Error(ErrorCode::non_rot_aligned_and_non_byte_shiftable, ss.str());
        }
    }

    // run a solver for different cases.
    if (assigns.size() == 1) {
        // (1) only one shift offset, can have up to 2 different sources.
        SourceClassifiedAssigns sources = classify_by_sources(assigns.begin()->second);
        if (sources.n_sources() == 1) {
            // if only one source, put it in src1, src2 is empty and will be destination
            return run_byte_rotate_merge_solver(dest, assigns.begin()->second, {});
        } else if (sources.n_sources() == 2) {
            // two sources with one offset, we can split them into two set for this
            // instruction.
            return run_byte_rotate_merge_solver(dest, sources.get_src(1), sources.get_src(2));
        } else {
            ss << "too many container sources for dest " << dest;
            return Error(ErrorCode::too_many_container_sources, ss.str());
        }
    } else {
        // when there's two sets of different-offset assignments,
        // each can only have one container source.
        for (const auto& offset_assign : assigns) {
            SourceClassifiedAssigns sources = classify_by_sources(offset_assign.second);
            if (sources.n_sources() > 1) {
                ss << "too many container sources for dest " << dest;
                return Error(ErrorCode::too_many_container_sources, ss.str());
            }
        }
        // It's guaranteed that src1 will be ad_or_const assignments because their offset
        // will always be zero and @p assigns are sorted in map<int, T>.
        return run_byte_rotate_merge_solver(dest, assigns.begin()->second,
                                            std::next(assigns.begin())->second);
    }
}

boost::optional<Error> ActionMoveSolver::solve() const {
    if (auto err = validate_input()) {
        return err;
    }
    for (const auto& kv : dest_assigns_i) {
        ErrorCode code = ErrorCode::unsat;
        std::stringstream ss;
        ContainerID dest = kv.first;
        const auto& offset_assigns = kv.second;
        if (auto err = try_byte_rotate_merge(dest, offset_assigns)) {
            ss << "cannot be synthesized by byte-rotate-merge: " << err->msg << ";";
        } else {
            LOG5("synthesized with byte-rotate-merge: " << dest);
            continue;
        }
        if (auto err = try_deposit_field_or_bitmasked_set(dest, offset_assigns)) {
            ss << "\ncannot be synthesized by deposit-field or bitmasked-set: " << err->msg << ";";
            // prefer to return deposit-field error code because it's more common.
            code = err->code;
        } else {
            LOG5("synthesized with deposit-field or bitmasked-set: " << dest);
            continue;
        }
        return Error(code, ss.str());
    }
    return boost::none;
}

/// solve checks
/// (1) sources are all constants: can be merge into one constant or action data
/// (2) sources are of one container: all aligned.
/// (3) sources are all action data.
/// We need to ensure that other allocated bits in the container will not be corrupted,
/// and since set instruction on mocha/dark are whole-container-set, all other bits that
/// are not set in this action need to be not live.
boost::optional<Error> ActionMochaSolver::solve() const {
    std::stringstream ss;
    for (const auto& dest_assigns : dest_assigns_i) {
        const auto& dest = dest_assigns.first;
        const auto& offset_assigns = dest_assigns.second;
        if (offset_assigns.size() != 1 || !offset_assigns.count(0)) {
            ss << "destination " << dest
               << " has too many unaligned sources: " << offset_assigns.size();
            return Error(ErrorCode::too_many_unaligned_sources, ss.str());
        }
        const auto& source_classified = classify_by_sources(offset_assigns.at(0));
        if (source_classified.n_sources() > 1) {
            ss << "destination " << dest
               << " has too many sources: " << source_classified.n_sources();
            return Error(ErrorCode::too_many_container_sources, ss.str());
        }
        const auto& assigns = source_classified.get_src(1);
        auto invalid_write_bit =
            invalid_whole_container_set(assigns, specs_i.at(dest).live, specs_i.at(dest).size);
        if (invalid_write_bit) {
            ss << "whole container write on destination " << dest
               << " will corrupt bit : " << *invalid_write_bit;
            return Error(ErrorCode::invalid_whole_container_write, ss.str());
        }
    }
    return boost::none;
}

/// (1) sources are of one container: all aligned.
/// Also, we need to ensure that other allocated bits in the container will not be corrupted,
/// and since set instruction on mocha/dark are whole-container-set, all other bits that
/// are not set in this action need to be not live.
boost::optional<Error> ActionDarkSolver::solve() const {
    std::stringstream ss;
    for (const auto& dest_assigns : dest_assigns_i) {
        const auto& dest = dest_assigns.first;
        const auto& offset_assigns = dest_assigns.second;
        if (offset_assigns.size() != 1 || !offset_assigns.count(0)) {
            ss << "destination " << dest
               << " has too many unaligned sources: " << offset_assigns.size();
            return Error(ErrorCode::too_many_unaligned_sources, ss.str());
        }
        const auto& source_classified = classify_by_sources(offset_assigns.at(0));
        if (source_classified.n_sources() > 1) {
            ss << "destination " << dest
               << " has too many sources: " << source_classified.n_sources();
            return Error(ErrorCode::too_many_container_sources, ss.str());
        }
        if (!source_classified.ad_or_const.empty()) {
            ss << "dark container destination " << dest
               << " has ad/const source: " << offset_assigns.at(0);
            return Error(ErrorCode::dark_container_ad_or_const_source, ss.str());
        }
        const auto& assigns = source_classified.get_src(1);
        auto invalid_write_bit =
            invalid_whole_container_set(assigns, specs_i.at(dest).live, specs_i.at(dest).size);
        if (invalid_write_bit) {
            ss << "whole container write on destination " << dest
               << " will corrupt bit : " << *invalid_write_bit;
            return Error(ErrorCode::invalid_whole_container_write, ss.str());
        }
    }
    return boost::none;
}

std::ostream& operator<<(std::ostream& s, const Operand& c) {
    if (c.is_ad_or_const) {
        s << "ad_or_const";
    } else {
        s << c.container << " " << c.range;
    }
    return s;
}

std::ostream& operator<<(std::ostream& s, const Assign& c) {
    s << c.dst << " = " << c.src;
    return s;
}

std::ostream& operator<<(std::ostream& s, const std::vector<Assign>& c) {
    s << "{\n";
    for (const auto& v : c) {
        s << "\t" << v << "\n";
    }
    s << "}";
    return s;
}

}  // namespace solver
