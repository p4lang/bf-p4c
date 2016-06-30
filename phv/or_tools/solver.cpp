#include <list>
#include <ctime>
#include "solver.h"
#include "mau_group.h"
#include "container.h"
#include "lib/log.h"
namespace or_tools {
int Solver::unique_id_ = 0;

using operations_research::IntVar;
using operations_research::IntExpr;
using operations_research::SearchMonitor;
void Solver::SetEqualContainer(const std::set<PHV::Bit> &bits) {
    Container *c = new Container(MakeContainerInGroup(bits.begin()->name()));
    LOG4("Setting equal container for " << bits.size() << " bits");
    for (auto &b : bits) {
        if (bits_.count(b) == 0) bits_.insert(std::make_pair(b, Bit(b.name())));
        Bit &bit = bits_.at(b);
        LOG5("Setting container for " << bit.name());
        bit.set_container(c); }
}

void
Solver::SetEqualMauGroup(const std::set<PHV::Bit> &bits, const bool &is_t_phv) {
    CHECK(bits.size() > 0) << "; Received empty set";
    int max = is_t_phv ? PHV::kNumMauGroups - 1 : 13;
    MauGroup *group = new MauGroup(MakeMauGroup(bits.begin()->name(), max), bits.begin()->name());
    for (auto &b : bits) {
        if (bits_.count(b) == 0) bits_.insert(std::make_pair(b, Bit(b.name())));
        Bit &bit = bits_.at(b);
        LOG4("Setting group for " << bit.name() << " to " <<
               group->mau_group()->name());
        Container *container = bit.container();
        if (nullptr == container) {
            SetEqualContainer(std::set<PHV::Bit>({b}));
            container = bit.container(); }
        CHECK(nullptr != container) << ": Cannot find container for " << b;
        container->set_mau_group(group); }
}

void Solver::SetOffset(const PHV::Bit &pbit, const std::vector<int> &values) {
    CHECK(0 != bits_.count(pbit)) << ": Cannot find " << pbit;
    Bit &bit = bits_.at(pbit);
    if (nullptr != bit.base_offset()) {
        std::vector<int64> v(32);
        std::iota(v.begin(), v.end(), 0);
        CHECK(bit.relative_offset() >= 0) << ": Wrong relative offset for " << pbit;
        for (auto i : values) {
            const int value = i - bit.relative_offset();
            if (value >= 0) {
                auto it = std::find(v.begin(), v.end(), value);
                CHECK(v.end() != it) << ": No offset " << value << " for " << pbit;
                v.erase(it); } }
        for (auto i : v) {
            if (true == bit.base_offset()->Contains(i)) {
                LOG4("Removing " << i << " from domain of " << bit.base_offset());
                // At this point, bit cannot be allocated a base_offset from v. So,
                // remove v from the domain of bit.base_offset().
                bit.base_offset()->RemoveValue(i); } }
    } else {
        bit.set_offset(MakeOffset(bit.name(), values), 0); }
}

void Solver::SetOffset(const PHV::Bit &pbit, const int &min, const int &max) {
    Bit &bit = bits_.at(pbit);
    if (nullptr != bit.base_offset()) {
        for (int i = 0; i < min - bit.relative_offset(); ++i) {
            if (bit.base_offset()->Contains(i)) {
                LOG5("Remove " << i << " from domain of " << bit.base_offset());
                bit.base_offset()->RemoveValue(i); } }
        for (int i = max + 1 - bit.relative_offset(); i <= 31; ++i) {
            if (bit.base_offset()->Contains(i)) {
                LOG5("Remove " << i << " from domain of " << bit.base_offset());
                bit.base_offset()->RemoveValue(i); } }
    } else {
        bit.set_offset(MakeOffset(bit.name(), min, max), 0); }
}

void Solver::SetBitDistance(const PHV::Bit &pbit1, const PHV::Bit &pbit2,
                            const int &distance) {
    LOG4("Setting bits " << pbit1 << " and " << pbit2 << " at distance " << distance);
    Bit &bit1 = bits_.at(pbit1);
    Bit &bit2 = bits_.at(pbit2);
    CHECK(distance >= 0) << ": Invalid distance " << distance;
    SetOffset(pbit1, 0, 31 - distance);
    CHECK(nullptr != bit1.offset()) << "; Offset not set for " << bit1.name();
    if (nullptr != bit2.offset()) {
        CHECK(bit1.base_offset() != nullptr) << "; Cannot find base_offset for " << bit1.name();
        CHECK(bit2.base_offset() != nullptr) << "; Cannot find base_offset for " << bit2.name();
        if (bit1.base_offset() == bit2.base_offset()) {
            // FIXME: This assert will be hit if a program has conflicting
            // constraints. It must be eventually changed into a sensible error
            // message for the user.
            CHECK(bit1.relative_offset() + distance == bit2.relative_offset())
                << "; Invalid relative offsets for " << bit1.name() << " and " << bit2.name();
        } else {
            LOG4("Adding offset constraint between " << pbit1 << " and " << pbit2);
            // Adding a constraints between bit1.offset() and bit2.offset() will be
            // simpler. However, those variables are derived from their respective
            // base_offset() variables. Adding a constraints between the
            // base_offset() may result in faster execution because they are directly
            // assigned values from their domain by the solver.
            int diff = bit1.relative_offset() + distance - bit2.relative_offset();
            solver_.AddConstraint(
                solver_.MakeEquality(
                    solver_.MakeSum(bit1.base_offset(), diff), bit2.base_offset())); }
    } else {
        CHECK(bit2.base_offset() == nullptr) << "; Invalid base offset for " << bit2.name();
        bit2.set_offset(bit1.base_offset(), bit1.relative_offset() + distance); }
}

// This function tries to avoid creating a new IntVar object in the solver. If
// we did not care about creating an extra IntVar object, this function could
// have just consisted of the for-loop that is at the end of the function.
void Solver::SetEqualOffset(const std::set<PHV::Bit> &bits) {
    CHECK(bits.size() > 0) << ": Set of PHV::Bit is empty";
    // Try to find a Bit object which has a non-NULL offset and store the offset
    // information (i.e base_offset, relative_offset and offset) in base_bit.
    Bit base_bit("");
    for (auto &b : bits) {
        Bit &bit = bits_.at(b);
        if (nullptr != bit.offset()) {
            base_bit.CopyOffset(bit);
            break; } }
    // This if-elseif statement ensures that the first item in bits has a
    // non-NULL offset and base_offset. That way, the for-loop at the end of the
    // function never creates a new IntVar object.
    Bit &first_bit = bits_.at(*bits.begin());
    if (nullptr == base_bit.offset()) {
        // If we cannot find such a bit in bits, we have not choice but to create a
        // new IntVar object for base_offset.
        first_bit.set_offset(MakeOffset(first_bit.name()), 0);
    } else if (first_bit.offset() == nullptr) {
        CHECK(nullptr != base_bit.offset());
        first_bit.CopyOffset(base_bit); }
    auto b1 = bits.cbegin();
    for (auto b2 = std::next(b1, 1); b2 != bits.cend(); ++b2) {
        // This check is just to ensure that the call to SetBitDistance never
        // creates a new IntVar object for base_offset.
        CHECK(nullptr != bits_.at(*b1).offset());
        CHECK(nullptr != bits_.at(*b1).base_offset());
        SetBitDistance(*b1, *b2, 0); }
}

void Solver::SetFirstDeparsedHeaderByte(const PHV::Byte &phv_byte) {
    Byte *byte = SetByte(phv_byte);
    CHECK(nullptr != byte) << ": Cannot find or_tools::Byte object for " << phv_byte.name();
    // For the last bit of a header, is_last_byte_ must be true.
    Bit &bit = bits_.at(phv_byte.at(0));
    byte->set_last_byte(bit.SetFirstDeparsedHeaderByte());
}

void Solver::SetDeparsedHeader(const PHV::Byte &byte1, const PHV::Byte &byte2) {
    Bit &bit = bits_.at(byte2.at(0));
    Bit &prev_bit = bits_.at(byte1.at(7));
    Byte *byte = SetByte(byte2);
    byte->set_last_byte(bit.SetDeparsedHeader(prev_bit, *(prev_bit.byte())));
}

void Solver::SetLastDeparsedHeaderByte(const PHV::Byte &phv_byte) {
    Byte *byte = bits_.at(phv_byte.at(0)).byte();
    // For the last bit of a header, is_last_byte_ must be true.
    solver_.AddConstraint(solver_.MakeEquality(byte->is_last_byte(), 1));
}

void Solver::SetDeparserGroups(const PHV::Byte &i_pbyte, const PHV::Byte &e_pbyte) {
    LOG4("Setting deparser groups for " << i_pbyte.name() << " and " << e_pbyte.name());
    Container *i_container = nullptr, *e_container = nullptr;
    for (auto &b : i_pbyte) {
        if (i_container == nullptr) i_container = bits_.at(b).container();
        CHECK(nullptr != i_container) << "; Cannot find container for " << b.name();
        CHECK(i_container == bits_.at(b).container())
            << ": Container mismatch in " << i_pbyte.name() << " for " << b; }
    for (auto &b : e_pbyte) {
        if (e_container == nullptr) e_container = bits_.at(b).container();
        CHECK(nullptr != e_container) << "; Cannot find container for " << b.name();
        CHECK(e_container == bits_.at(b).container())
            << ": Container mismatch in " << e_pbyte.name() << " for " << b; }
    CHECK(i_container != e_container);
    // Get the deparser group number and make them non-equal.
    solver_.AddConstraint(
        solver_.MakeNonEquality(i_container->deparser_group(INGRESS),
                                e_container->deparser_group(EGRESS)));
}

void Solver::SetDeparserGroups(const PHV::Bit &i_pbit, const PHV::Bit &e_pbit) {
    LOG4("Setting deparser groups for " << i_pbit.name() << " and " << e_pbit.name());
    Container *i_container = MakeBit(i_pbit)->container();
    Container *e_container = MakeBit(e_pbit)->container();
    CHECK(i_container != e_container);
    solver_.AddConstraint(
        solver_.MakeNonEquality(i_container->deparser_group(INGRESS),
                                e_container->deparser_group(EGRESS)));
}

void Solver::SetDeparserIngress(const PHV::Byte &pbyte) {
    LOG4("Setting ingress deparser groups for " << pbyte.name());
    Container *container = nullptr;
    for (auto &b : pbyte) {
        if (container == nullptr) container = bits_.at(b).container();
        CHECK(nullptr != container) << "; Cannot find container for " << b.name();
        CHECK(container == bits_.at(b).container())
            << ": Container mismatch in " << pbyte.name() << " for " << b; }
    container->mau_group()->SetIngressDeparser();
}

void Solver::SetDeparserIngress(const PHV::Bit &pbit) {
    LOG4("Setting ingress deparser groups for " << pbit.name());
    Container *container = MakeBit(pbit)->container();
    container->mau_group()->SetIngressDeparser();
}

void Solver::SetDeparserEgress(const PHV::Byte &pbyte) {
    LOG4("Setting egress deparser groups for " << pbyte.name());
    Container *container = nullptr;
    for (auto &b : pbyte) {
        if (container == nullptr) container = bits_.at(b).container();
        CHECK(nullptr != container) << "; Cannot find container for " << b.name();
        CHECK(container == bits_.at(b).container())
            << ": Container mismatch in " << pbyte.name() << " for " << b; }
    container->mau_group()->SetEgressDeparser();
}

void Solver::SetDeparserEgress(const PHV::Bit &pbit) {
    LOG4("Setting egress deparser groups for " << pbit.name());
    Container *container = MakeBit(pbit)->container();
    container->mau_group()->SetEgressDeparser();
}

void Solver::SetMatchXbarWidth(const std::vector<PHV::Bit> &match_phv_bits,
                               const std::array<int, 4> &widths) {
    std::vector<Bit*> match_bits;
    for (auto &b : match_phv_bits) {
        match_bits.push_back(MakeBit(b)); }
    std::vector<IntVar*> is_unique_flags;
    for (auto bit1 = match_bits.begin(); bit1 != match_bits.end(); ++bit1) {
        std::vector<IntVar*> is_different_vars;
        for (auto bit2 = match_bits.begin(); bit2 != bit1; ++bit2) {
            CHECK((*bit1)->byte() != (*bit2)->byte()) << "; " << (*bit1)->name()
                << " and " << (*bit2)->name() << " belong to same byte";
            // FIXME: If we know that bit1 and bit2 cannot go into the same container
            // (by looking at container-conflict matrix) we can simply push
            // MakeIntConst(1) into is_different_vars.
            is_different_vars.push_back(
                solver_.MakeIsDifferentVar((*bit1)->offset_bytes(),
                                           (*bit2)->offset_bytes())); }
        if (is_different_vars.size() > 0) {
            IntExpr *sum = solver_.MakeSum(is_different_vars);
            is_unique_flags.push_back(
              solver_.MakeIsEqualCstVar(sum, is_different_vars.size()));
        } else {
            // The else block will be executed for the first bit. It will always be unique.
            is_unique_flags.push_back(solver_.MakeIntConst(1)); } }
    // This constraint enforces the limit on the total width of the match xbar.
    int total_bits = std::accumulate(widths.begin(), widths.end(), 0, std::plus<int>());
    LOG4("Fitting " << is_unique_flags.size() << " flags into " << total_bits << "B");
    CHECK(match_bits.size() == is_unique_flags.size())
        << "; Incorrect match bits " << match_bits.size();
    solver_.AddConstraint(
        solver_.MakeLessOrEqual(
            solver_.MakeSum(is_unique_flags), total_bits));
    // Express constraints on match fields extracted from 32b containers.
    for (std::size_t i = 0; i < widths.size() && is_unique_flags.size() > size_t(widths[i]); ++i) {
        std::vector<operations_research::IntVar*> is_unique_and_nth_byte;
        for (std::size_t b = 0; b < is_unique_flags.size(); ++b) {
            operations_research::IntVar *v = is_unique_flags[b];
            Bit *bit = match_bits.at(b);
            IntVar *is_32b = bit->mau_group()->is_32b();
            is_unique_and_nth_byte.push_back(
                solver_.MakeIsEqualCstVar(
                    solver_.MakeSum(
                        solver_.MakeSum(is_32b, bit->byte_flags()[i]), v),
                    3)); }
        LOG4("Constraining " << is_unique_and_nth_byte.size() << " to " <<
             widths[i] << "B in match xbar");
        solver_.AddConstraint(
            solver_.MakeLessOrEqual(
                solver_.MakeSum(is_unique_and_nth_byte), widths[i])); }
    SetUniqueConstraint(is_unique_flags, match_bits, widths, {{0, 2}});
    SetUniqueConstraint(is_unique_flags, match_bits, widths, {{1, 3}});
}

Byte *Solver::SetByte(const PHV::Byte &phv_byte) {
    Byte *byte = bits_.at(phv_byte.at(0)).byte();
    // Just doing sanity check to make sure all Bit objects have a pointer to the
    // same Byte object.
    for (auto b : phv_byte) CHECK(bits_.at(b).byte() == byte);
    for (auto it = phv_byte.cfirst(); it != phv_byte.clast(); ++it) {
        CHECK(bits_.at(*it).byte() == byte) << ": Invalid Byte* in " << (*it); }
    // Create a new Byte* object if needed.
    if (nullptr == byte) {
        LOG4("Setting byte object for " << phv_byte.name());
        byte = new Byte();
        for (auto it = phv_byte.cfirst(); it != phv_byte.clast(); ++it) {
            Bit &bit = bits_.at(*it);
            CHECK(nullptr != bit.container());
            bit.set_byte(byte); } }
    return byte;
}

void
Solver::SetUniqueConstraint(const std::vector<operations_research::IntVar*> &is_unique_flags,
                            const std::vector<Bit*> &bits,
                            const std::array<int, 4> &unique_bytes,
                            const std::array<std::size_t, 2> &byte_offsets) {
    int max_unique_bytes = 0;
    for (std::size_t i = 0; i < byte_offsets.size(); ++i) {
        max_unique_bytes += unique_bytes[byte_offsets[i]]; }
    std::vector<operations_research::IntVar*> is_unique_and_nth_byte;
    for (std::size_t i = 0; i < byte_offsets.size(); ++i) {
        for (std::size_t b = 0; b < is_unique_flags.size(); ++b) {
            operations_research::IntVar *v = is_unique_flags.at(b);
            Bit *bit = bits.at(b);
            IntVar *is_32b = bit->mau_group()->is_32b();
            IntVar *is_16b = bit->mau_group()->is_16b();
            CHECK(bit->byte_flags().size() > byte_offsets[i]);
            // This if-else statement is just an optimization. In the else block, we
            // do not need to check if the byte is allocated to 16b or 32b container
            // because the byte offset > 0.
            if (byte_offsets[i] == 0) {
                is_unique_and_nth_byte.push_back(
                    solver_.MakeIsEqualCstVar(
                        solver_.MakeSum(
                            solver_.MakeSum(is_32b, is_16b),
                            solver_.MakeSum(v, bit->byte_flags()[byte_offsets[i]])),
                        3));
            } else {
                is_unique_and_nth_byte.push_back(
                    solver_.MakeIsEqualCstVar(
                        solver_.MakeSum(v, bit->byte_flags()[byte_offsets[i]]), 2)); } } }
    LOG4("Constraining " << is_unique_and_nth_byte.size() << " to " <<
         max_unique_bytes << "B in match xbar");
    solver_.AddConstraint(
        solver_.MakeLessOrEqual(
            solver_.MakeSum(is_unique_and_nth_byte), max_unique_bytes));
}

void Solver::SetNoTPhv(const PHV::Bit &bit) {
    LOG4("Forbidding allocation of " << bit.name() << " to T-PHV");
    if (bits_.count(bit) != 0)
        bits_.at(bit).mau_group()->SetNoTPhv();
    else
        WARNING("Cannot find Bit for " << bit.name());
}

void Solver::SetContainerConflict(const PHV::Bit &pb1, const PHV::Bit &pb2) {
    LOG4("Setting container-conflict between " << pb1 << " and " << pb2);
    Bit *b1 = MakeBit(pb1), *b2 = MakeBit(pb2);
    b1->container()->SetConflict(b2->container());
}

void Solver::SetBitConflict(const PHV::Bit &pb1, const PHV::Bit &pb2) {
    LOG4("Setting bit-conflict between " << pb1 << " and " << pb2);
    Bit *b1 = MakeBit(pb1), *b2 = MakeBit(pb2);
    b1->SetConflict(*b2);
}

void Solver::SetContainerWidthConstraints() {
    std::map<std::pair<IntVar*, IntVar*>, Bit*> mau_group_offsets;
    for (auto &b : bits_) {
        Bit &bit = b.second;
        auto p = std::make_pair(bit.mau_group()->mau_group(), bit.base_offset());
        if (mau_group_offsets.count(p) == 0) {
            mau_group_offsets.insert(std::make_pair(p, &bit)); }
        if (mau_group_offsets.at(p)->relative_offset() < bit.relative_offset()) {
            mau_group_offsets.at(p) = &bit; } }
    for (auto &p : mau_group_offsets) {
        p.second->SetContainerWidthConstraints(); }
}

void Solver::allocation(const PHV::Bit &bit, PHV::Container *container, int *container_bit) {
    *container = PHV::Container();
    *container_bit = 0;
    if (bits_.count(bit)) {
        const Bit &b(bits_.at(bit));
        if (b.container()) {
            *container = b.container()->Value();
            if (b.base_offset()) {
                *container_bit = b.base_offset()->Value() + b.relative_offset();
            } else {
                WARNING("Cannot find offset for "  << bit);
                *container = PHV::Container(); }
        } else {
            WARNING("Missing " << (nullptr == b.container() ? "container" : "") <<
                    (nullptr == b.mau_group() ? " and MAU group" : "") << " for " << bit); } }
}

bool
Solver::Solve1(operations_research::Solver::IntValueStrategy int_val,
               const bool &is_luby_restart, int timeout) {
    auto int_vars = GetIntVars();
    LOG1("Starting new search with " << int_vars.size() << " variables and " <<
         solver_.constraints() << " constraints");
    auto db = solver_.MakePhase(int_vars,
                                operations_research::Solver::CHOOSE_FIRST_UNBOUND,
                                int_val);
    std::vector<SearchMonitor*> monitors;
    if (is_luby_restart) monitors.push_back(solver_.MakeLubyRestart(1000));
    monitors.push_back(solver_.MakeTimeLimit(timeout * 1000));
    if (LOGGING(3))
        monitors.push_back(solver_.MakeSearchTrace(""));
    solver_.NewSearch(db, monitors);
    const std::clock_t begin_time = clock();
    const bool result = solver_.NextSolution();
    LOG2("Time=" << (clock() - begin_time) / (CLOCKS_PER_SEC / 1000) << "msecs  Mem=" <<
         solver_.MemoryUsage());
    LOG2(solver_.DebugString());
    if (false == result) solver_.EndSearch();
    return result;
}

std::vector<IntVar*> Solver::GetIntVars() const {
    std::list<IntVar*> rv;
    // Collect constraint variables.
    std::vector<IntVar*> group_vars(GetMauGroups());
    while (group_vars.size() != 0) {
        rv.push_back(*group_vars.begin());
        auto vars2 = containers_and_offsets(*group_vars.begin());
        rv.insert(rv.end(), vars2.begin(), vars2.end());
        group_vars.erase(group_vars.begin()); }
    for (auto &v : rv) {
        CHECK(nullptr != v) << "; Found nullptr in variable vector";
        LOG4("intvar vec: " << v->name() << v); }
    return std::vector<IntVar*>(rv.begin(), rv.end());
}

std::vector<IntVar*> Solver::GetMauGroups() const {
    std::set<IntVar*> t_phv_groups, phv_groups;
    for (auto &b : bits_) {
        MauGroup *mg = b.second.mau_group();
        std::set<IntVar*> *l = &phv_groups;
        if (mg->is_t_phv()) l = &t_phv_groups;
        l->insert(mg->mau_group()); }
    std::vector<IntVar*> rv(phv_groups.begin(), phv_groups.end());
    // FIXME: Set the seed.
    std::random_shuffle(rv.begin(), rv.end());
    // Push the T-PHV eligible MAU groups to the end of the list.
    // TODO: This is just a heuristic. We must try other strategies that allocate
    // T-PHV container before PHV.
    std::vector<IntVar*> rv2(t_phv_groups.begin(), t_phv_groups.end());
    std::random_shuffle(rv2.begin(), rv2.end());
    rv.insert(rv.end(), rv2.begin(), rv2.end());
    return rv;
}

std::vector<IntVar*>
Solver::containers_and_offsets(IntVar *mau_group) const {
    std::set<IntVar*> container_in_groups;
    for (auto &b : bits_) {
        if (b.second.mau_group()->mau_group() == mau_group) {
            container_in_groups.insert(b.second.container()->container_in_group()); } }
    container_in_groups.erase(nullptr);
    // We could have made rv a std::set but we want to maintain the order of
    // variables.
    std::vector<IntVar*> rv;
    for (auto c : container_in_groups) {
        rv.push_back(c);
        for (auto &b : bits_) {
            if (b.second.container()->container_in_group() == c &&
                b.second.base_offset() != nullptr &&
                rv.end() == std::find(rv.begin(), rv.end(), b.second.base_offset())) {
                rv.push_back(b.second.base_offset()); } } }
    return rv;
}

IntVar *Solver::MakeMauGroup(const cstring &name, const int &max) {
    auto v = solver_.MakeIntVar(0, max, name + "-group-" + unique_id());
    v->RemoveValues(std::vector<int64>(PHV::kInvalidMauGroups.begin(),
                                       PHV::kInvalidMauGroups.end()));
    return v;
}

IntVar *Solver::MakeContainerInGroup(const cstring &name) {
    return solver_.MakeIntVar(0, PHV::kNumContainersPerMauGroup - 1,
                              name + "-containeringroup-" + unique_id());
}

IntVar *Solver::MakeOffset(const cstring &name, const std::vector<int> &values) {
    // FIXME: For some reason, no name is being assigned to IntVar objects
    // created below.
    return solver_.MakeIntVar(values, name + "-voffset-" + unique_id());
}

IntVar *Solver::MakeOffset(const cstring &name, const int &min, const int &max) {
    LOG4("Making offset " << name);
    return solver_.MakeIntVar(min, max, name + "-offset-" + unique_id());
}


Bit *Solver::MakeBit(const PHV::Bit &phv_bit) {
    if (bits_.count(phv_bit) == 0) {
        bits_.emplace(std::make_pair(phv_bit, Bit(phv_bit.name()))); }
    Bit &bit = bits_.at(phv_bit);
    if (nullptr == bit.container()) {
        bit.set_container(new Container(MakeContainerInGroup(bit.name()))); }
    if (nullptr == bit.mau_group()) {
        // MAU groups created here will be restricted to PHV (no T-PHV).
        const int max = PHV::kPhvMauGroupOffset + PHV::kNumPhvMauGroups - 1;
        MauGroup *group = new MauGroup(MakeMauGroup(bit.name(), max), bit.name());
        bit.container()->set_mau_group(group); }
    if (nullptr == bit.base_offset()) {
        CHECK(bit.offset() == nullptr) << "; Invalid offset in " << bit.name();
        bit.set_offset(MakeOffset(bit.name()), 0); }
    if (nullptr == bit.byte()) {
        bit.set_byte(new Byte()); }
    return &bit;
}
}  // namespace or_tools
