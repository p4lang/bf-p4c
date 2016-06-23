#include "phv_allocator.h"
#include "byte_constraint.h"
#include "constraints.h"
#include "container_constraint.h"
#include "lib/range.h"
#include "match_xbar_constraint.h"
#include "mau_group_constraint.h"
#include "offset_constraint.h"
#include "or_tools/min_value_solver.h"
#include "or_tools/random_value_solver.h"
#include "parse_graph_constraint.h"
#include "phv_fields.h"
#include "source_container_constraint.h"
#include "thread_constraint.h"
#include "t_phv_constraint.h"

using namespace std::placeholders;

void PopulatePhvInfo(SolverInterface &solver, PhvInfo *phv_info) {
    for (auto &field : *phv_info) {
        LOG3("PopulatePhvInfo " << field.name << " size=" << field.size <<
             " offset=" << field.offset);
        for (int field_bit = 0; field_bit < field.size; field_bit++) {
            PHV::Container container;
            int container_bit;
            solver.allocation(field.bit(field_bit), &container, &container_bit);
            if (!container) continue;
            auto iter = field.alloc.begin();
            for (; iter != field.alloc.end(); ++iter) {
                if (iter->field_bit <= field_bit &&
                    field_bit < iter->field_bit + iter->width) {
                    break; }
                // Append the bit to an existing alloc structure.
                if (iter->container == container &&
                    iter->width + iter->container_bit == container_bit &&
                    iter->width + iter->field_bit == field_bit) {
                    iter->width += 1;
                    break; }
                // Prepend the bit to an existing alloc structure.
                if (iter->container == container &&
                    iter->container_bit == container_bit + 1 &&
                    iter->field_bit == (field_bit + 1)) {
                    --(iter->field_bit);
                    --(iter->container_bit);
                    iter->width += 1;
                    break; } }
            if (iter == field.alloc.end()) {
                LOG3("adding " << container << "(" << container_bit << ") for " << field.name <<
                     "(" << field_bit << ")");
                field.alloc.emplace_back(container, field_bit, container_bit, 1); } } }
}

PhvAllocator::PhvAllocator(PhvInfo &p, const SymBitMatrix &c,
    std::function<bool(const IR::MAU::Table *, const IR::MAU::Table *)> m)
: phv(p), conflict(c), mutex(m) {
    auto *scc = new SourceContainerConstraint(phv, constraints_);
    addPasses({
        new VisitFunctor([this]() { if (phv.alloc_done()) early_exit(); }),
        new MauGroupConstraint(phv, constraints_),
        new ContainerConstraint(phv, mutex, constraints_),
        new ByteConstraint(phv, constraints_),
        new OffsetConstraint(phv, constraints_),
        new ThreadConstraint(phv, constraints_),
        // This loop should keep iterating until Constraints::SetEqual() has been
        // invoked on all pairs of source containers that have a common destination
        // container.
        new PassRepeatUntil({ scc }, [scc]()->bool { return !scc->is_updated(); }),
        // Set bits which cannot be allocated to T-PHV.
        new TPhvConstraint(phv, constraints_),
        // Set MAU match xbar constraints.
        new MatchXbarConstraint(phv, constraints_),
        new VisitFunctor([this]() {
            for (auto f1 = phv.begin(); f1 != phv.end(); ++f1) {
                if (!f1->referenced) continue;
                if (f1->size >= 2)
                    for (int b1 : Range(0, f1->size-2))
                        for (int b2 : Range(b1+1, f1->size-1))
                            constraints_.SetBitConflict(f1->bit(b1), f1->bit(b2));
                for (auto f2 = f1; ++f2 != phv.end();) {
                    if (!f2->referenced) continue;
                    if (conflict(f1->id, f2->id))
                        for (int b1 : Range(0, f1->size-1))
                            for (int b2 : Range(0, f2->size-1))
                                constraints_.SetBitConflict(f1->bit(b1), f2->bit(b2)); } }
        })
    });
}

bool PhvAllocator::Solve(StringRef opt) {
    if (phv.alloc_done()) return true;
    or_tools::Solver solver;
    auto strategy = operations_research::Solver::ASSIGN_MIN_VALUE;
    bool luby_restart = false;
    int timeout = 5;
    for (auto p : opt.split(',')) {
        p = p.trim();
        if (p == "min" || p == "default") {
            LOG1("Trying MIN_VALUE");
            strategy = operations_research::Solver::ASSIGN_MIN_VALUE;
            luby_restart = false;
        } else if (opt == "random") {
            LOG1("Trying RANDOM");
            strategy = operations_research::Solver::ASSIGN_RANDOM_VALUE;
            luby_restart = true;
        } else if (isdigit(*p)) {
            timeout = atoi(p.p);
        } else {
            error("Unknown solver option %s", p); } }
    constraints_.SetConstraints(solver);
    int count = 0;
    while (count < 20) {
        if (true == solver.Solve1(strategy, luby_restart, timeout)) {
            PopulatePhvInfo(solver, &phv);
            for (auto &field : phv)
                std::sort(field.alloc.begin(), field.alloc.end(),
                          [](const PhvInfo::Field::alloc_slice &a,
                             const PhvInfo::Field::alloc_slice &b) -> bool {
                    return a.field_bit > b.field_bit; });
            phv.alloc_done_ = true;
            return true;
        } else {
            ++count; } }
    return false;
}
