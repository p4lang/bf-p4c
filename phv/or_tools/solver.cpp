#include "solver.h"
#include "lib/log.h"
namespace ORTools {
int Solver::unique_id_ = 0;

using operations_research::IntVar;
using operations_research::IntExpr;
using operations_research::SearchMonitor;
void
Solver::SetEqualMauGroup(const std::set<PHV::Bit> &bits, const bool &is_t_phv) {
  CHECK(bits.size() > 0) << "; Received empty set";
  std::array<IntVar*, 3> size_flags;
  int max = is_t_phv ? PHV::kNumMauGroups - 1 : 13;
  IntVar *group = MakeMauGroup(bits.begin()->name(), &size_flags, max);
  for (auto &b : bits) {
    if (bits_.count(b) == 0) bits_.insert(std::make_pair(b, Bit(b.name())));
    Bit &bit = bits_.find(b)->second;
    CHECK(bit.mau_group() == nullptr);
    LOG2("Setting group for " << bit.name() << " to " << group->name());
    bit.set_mau_group(group, size_flags);
  }
}

void Solver::SetEqualContainer(const std::set<PHV::Bit> &bits) {
  IntVar *mau_group = bits_.at(*bits.begin()).mau_group();
  IntVar *container_in_group = MakeContainerInGroup(bits.begin()->name());
  IntExpr *container = MakeContainer(mau_group, container_in_group);
  for (auto &b : bits) {
    Bit &bit = bits_.at(b);
    CHECK(bit.mau_group() == mau_group);
    LOG2("Setting container in group for " << bit.name() << " to " <<
         container_in_group->name());
    bit.set_container(container_in_group, container);
  }
}

void Solver::SetOffset(const PHV::Bit &pbit, const std::vector<int> &values) {
  Bit &bit = bits_.at(pbit);
  if (nullptr != bit.base_offset()) {
    std::vector<int64> v(32);
    std::iota(v.begin(), v.end(), 0);
    for (auto i : values) {
      v.erase(std::find(v.begin(), v.end(), i - bit.relative_offset()));
    }
    // At this point, bit cannot be allocated a base_offset from v. So, remove
    // v from the domain of bit.base_offset().
    bit.base_offset()->RemoveValues(v);
  }
  else bit.set_offset(MakeOffset(bit.name(), values), 0);
}

void Solver::SetOffset(const PHV::Bit &pbit, const int &min, const int &max) {
  Bit &bit = bits_.at(pbit);
  if (nullptr != bit.base_offset()) {
    for (int i = 0; i < min - bit.relative_offset(); ++i) {
      if (bit.base_offset()->Contains(i)) {
        LOG3("Remove " << i << " from domain of " << bit.base_offset());
        bit.base_offset()->RemoveValue(i);
      }
    }
    for (int i = max + 1 - bit.relative_offset(); i <= 31; ++i) {
      if (bit.base_offset()->Contains(i)) {
        LOG3("Remove " << i << " from domain of " << bit.base_offset());
        bit.base_offset()->RemoveValue(i);
      }
    }
  }
  else {
    bit.set_offset(MakeOffset(bit.name(), min, max), 0);
  }
}

void Solver::SetBitDistance(const PHV::Bit &pbit1, const PHV::Bit &pbit2,
                            const int &distance) {
  LOG2("Setting bits " << pbit1 << " and " << pbit2 << " at distance " <<
         distance);
  Bit &bit1 = bits_.at(pbit1);
  Bit &bit2 = bits_.at(pbit2);
  CHECK(distance >= 0) << ": Invalid distance " << distance;
  SetOffset(pbit1, 0, 31 - distance);
  CHECK(nullptr != bit1.offset()) << "; Offset not set for " << bit1.name();
  if (nullptr != bit2.offset()) {
    CHECK(bit1.base_offset() != nullptr) << "; Cannot find base_offset for " <<
            bit1.name();
    CHECK(bit2.base_offset() != nullptr) << "; Cannot find base_offset for " <<
            bit2.name();
    if (bit1.base_offset() == bit2.base_offset()) {
      // FIXME: This assert will be hit if a program has conflicting
      // constraints. It must be eventually changed into a sensible error
      // message for the user.
      CHECK(bit1.relative_offset() + distance == bit2.relative_offset()) <<
              "; Invalid relative offsets for " << bit1.name() << " and " <<
              bit2.name();
    }
    else {
      // Adding a constraints between bit1.offset() and bit2.offset() will be
      // simpler. However, those variables are derived from their respective
      // base_offset() variables. Adding a constraints between the
      // base_offset() may result in faster execution because they are directly
      // assigned values from their domain by the solver.
      int diff = bit1.relative_offset() + distance - bit2.relative_offset();
      solver_.AddConstraint(
        solver_.MakeEquality(
          solver_.MakeSum(bit1.base_offset(), diff), bit2.base_offset()));
    }
  }
  else {
    CHECK(bit2.base_offset() == nullptr) << "; Invalid base offset for " <<
            bit2.name();
    bit2.set_offset(bit1.base_offset(), bit1.relative_offset() + distance);
  }
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
      break;
    }
  }
  // This if-elseif statement ensures that the first item in bits has a
  // non-NULL offset and base_offset. That way, the for-loop at the end of the
  // function never creates a new IntVar object.
  Bit &first_bit = bits_.at(*bits.begin());
  if (nullptr == base_bit.offset()) {
    // If we cannot find such a bit in bits, we have not choice but to create a
    // new IntVar object for base_offset.
    first_bit.set_offset(MakeOffset(first_bit.name()), 0);
  }
  else if (first_bit.offset() == nullptr) {
    CHECK(nullptr != base_bit.offset());
    first_bit.CopyOffset(base_bit);
  }
  auto b1 = bits.cbegin();
  for (auto b2 = std::next(b1, 1); b2 != bits.cend(); ++b2) {
    // This check is just to ensure that the call to SetBitDistance never
    // creates a new IntVar object for base_offset.
    CHECK(nullptr != bits_.at(*b1).offset());
    CHECK(nullptr != bits_.at(*b1).base_offset());
    SetBitDistance(*b1, *b2, 0);
  }
}

void Solver::SetFirstDeparsedHeaderByte(const PHV::Byte &phv_byte) {
  Byte *byte = SetByte(phv_byte);
  CHECK(nullptr != byte) << ": Cannot find ORTools::Byte object for " <<
    phv_byte.name();
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

void Solver::SetDeparserGroups(const PHV::Byte &i_pbyte,
                               const PHV::Byte &e_pbyte) {
  IntExpr *i_container = nullptr, *e_container = nullptr;
  IntVar *i_mau_group = nullptr, *e_mau_group = nullptr;
  Byte *i_byte = nullptr, *e_byte = nullptr;
  for (auto &b : i_pbyte) {
    if (i_container == nullptr) i_container = bits_.at(b).container();
    if (i_mau_group == nullptr) i_mau_group = bits_.at(b).mau_group();
    if (i_byte == nullptr) i_byte = bits_.at(b).byte();
    CHECK(nullptr != i_container) << "; Cannot find container for " << b.name();
    CHECK(i_container == bits_.at(b).container())
      ": Container mismatch in " << i_pbyte.name() << " for " << b;
  }
  for (auto &b : e_pbyte) {
    if (e_container == nullptr) e_container = bits_.at(b).container();
    if (e_mau_group == nullptr) e_mau_group = bits_.at(b).mau_group();
    if (e_byte == nullptr) e_byte = bits_.at(b).byte();
    CHECK(nullptr != e_container) << "; Cannot find container for " << b.name();
    CHECK(e_container == bits_.at(b).container()) <<
      ": Container mismatch in " << e_pbyte.name() << " for " << b;
  }
  CHECK(i_container != e_container);
  // Remove statically assigned MAU groups.
  for (auto i : PHV::kEgressMauGroups) i_mau_group->RemoveValue(i);
  for (auto i : PHV::kIngressMauGroups) e_mau_group->RemoveValue(i);
  // Get the deparser group number and make them non-equal.
  auto i_dprsr_group = MakeDeparserGroup(i_byte, i_mau_group, i_container,
                                         INGRESS, i_pbyte.name());
  auto e_dprsr_group = MakeDeparserGroup(e_byte, e_mau_group, e_container,
                                         EGRESS, e_pbyte.name());
  solver_.AddConstraint(
    solver_.MakeNonEquality(i_dprsr_group, e_dprsr_group));
}

void Solver::SetMatchXbarWidth(const std::vector<PHV::Bit> &match_phv_bits,
                               const std::array<int, 4> &widths) {
  std::vector<Bit*> match_bits;
  for (auto &b : match_phv_bits) {
    match_bits.push_back(MakeBit(b));
  }
  std::vector<IntVar*> is_unique_flags;
  for (auto bit1 = match_bits.begin(); bit1 != match_bits.end(); ++bit1) {
    std::vector<IntVar*> is_different_vars;
    for (auto bit2 = match_bits.begin(); bit2 != bit1; ++bit2) {
      CHECK((*bit1)->byte() != (*bit2)->byte()) << "; " << (*bit1)->name() <<
              " and " << (*bit2)->name() << " belong to same byte";
      // FIXME: If we know that bit1 and bit2 cannot go into the same container
      // (by looking at container-conflict matrix) we can simply push
      // MakeIntConst(1) into is_different_vars.
      is_different_vars.push_back(
        solver_.MakeIsDifferentVar((*bit1)->offset_bytes(),
                                   (*bit2)->offset_bytes()));
    }
    if (is_different_vars.size() > 0) {
      IntExpr *sum = solver_.MakeSum(is_different_vars);
      is_unique_flags.push_back(
        solver_.MakeIsEqualCstVar(sum, is_different_vars.size()));
    }
    // The else block will be executed for the first bit. It will always be
    // unique.
    else is_unique_flags.push_back(solver_.MakeIntConst(1));
  }
  // This constraint enforces the limit on the total width of the match xbar.
  int total_bits = std::accumulate(widths.begin(), widths.end(),
                                   0, std::plus<int>());
  LOG2("Fitting " << is_unique_flags.size() << " flags into " <<
         total_bits << "B");
  CHECK(match_bits.size() == is_unique_flags.size()) <<
          "; Incorrect match bits " << match_bits.size();
  solver_.AddConstraint(
    solver_.MakeLessOrEqual(
      solver_.MakeSum(is_unique_flags), total_bits));
  // Express constraints on match fields extracted from 32b containers.
  for (std::size_t i = 0; i < widths.size() &&
                          (int)is_unique_flags.size() > widths[i]; ++i) {
    std::vector<operations_research::IntVar*> is_unique_and_nth_byte;
    for (std::size_t b = 0; b < is_unique_flags.size(); ++b) {
      operations_research::IntVar *v = is_unique_flags[b];
      Bit *bit = match_bits.at(b);
      is_unique_and_nth_byte.push_back(
        solver_.MakeIsEqualCstVar(
          solver_.MakeSum(
            solver_.MakeSum(bit->is_32b(), bit->byte_flags()[i]), v),
          3));
    }
    LOG2("Constraining " << is_unique_and_nth_byte.size() << " to " <<
           widths[i] << "B in match xbar");
    solver_.AddConstraint(
      solver_.MakeLessOrEqual(
        solver_.MakeSum(is_unique_and_nth_byte), widths[i]));
  }
  SetUniqueConstraint(is_unique_flags, match_bits, widths, {{0, 2}});
  SetUniqueConstraint(is_unique_flags, match_bits, widths, {{1, 3}});
}

ORTools::Byte *Solver::SetByte(const PHV::Byte &phv_byte) {
  Byte *byte = bits_.at(phv_byte.at(0)).byte();
  // Just doing sanity check to make sure all Bit objects have a pointer to the
  // same Byte object.
  for (auto b : phv_byte) CHECK(bits_.at(b).byte() == byte);
  for (auto it = phv_byte.cfirst(); it != phv_byte.clast(); ++it) {
    CHECK(bits_.at(*it).byte() == byte) << ": Invalid Byte* in " << (*it);
  }
  // Create a new Byte* object if needed.
  if (nullptr == byte) {
    LOG2("Setting byte object for " << phv_byte.name());
    byte = new Byte();
    for (auto it = phv_byte.cfirst(); it != phv_byte.clast(); ++it) {
      Bit &bit = bits_.at(*it);
      CHECK(nullptr != bit.container());
      bit.set_byte(byte);
    }
  }
  return byte;
}

void
Solver::SetUniqueConstraint(
  const std::vector<operations_research::IntVar*> &is_unique_flags,
  const std::vector<Bit*> &bits,
  const std::array<int, 4> &unique_bytes,
  const std::array<std::size_t, 2> &byte_offsets) {
  int max_unique_bytes = 0;
  for (std::size_t i = 0; i < byte_offsets.size(); ++i) {
    max_unique_bytes += unique_bytes[byte_offsets[i]];
  }
  std::vector<operations_research::IntVar*> is_unique_and_nth_byte;
  for (std::size_t i = 0; i < byte_offsets.size(); ++i) {
    for (std::size_t b = 0; b < is_unique_flags.size(); ++b) {
      operations_research::IntVar *v = is_unique_flags.at(b);
      Bit *bit = bits.at(b);
      CHECK(bit->byte_flags().size() > byte_offsets[i]);
      // This if-else statement is just an optimization. In the else block, we
      // do not need to check if the byte is allocated to 16b or 32b container
      // because the byte offset > 0.
      if (byte_offsets[i] == 0) {
        is_unique_and_nth_byte.push_back(
          solver_.MakeIsEqualCstVar(
            solver_.MakeSum(
              solver_.MakeSum(bit->is_32b(), bit->is_16b()),
              solver_.MakeSum(v, bit->byte_flags()[byte_offsets[i]])),
            3));
      }
      else {
        is_unique_and_nth_byte.push_back(
          solver_.MakeIsEqualCstVar(
            solver_.MakeSum(v, bit->byte_flags()[byte_offsets[i]]), 2));
      }
    }
  }
  LOG2("Constraining " << is_unique_and_nth_byte.size() << " to " <<
         max_unique_bytes << "B in match xbar");
  solver_.AddConstraint(
    solver_.MakeLessOrEqual(
      solver_.MakeSum(is_unique_and_nth_byte), max_unique_bytes));
}

void Solver::SetNoTPhv(const PHV::Bit &bit) {
  LOG2("Forbidding allocation of " << bit.name() << " to T-PHV");
  if (bits_.count(bit) != 0) {
    Bit &b = bits_.at(bit);
    for (int i = 0; i < PHV::kNumTPhvMauGroups; ++i) {
      IntVar *v = b.mau_group();
      CHECK(nullptr != v) << "; Cannot find MAU group for " << bit.name();
      if (v->Contains(i + PHV::kTPhvMauGroupOffset)) {
        v->RemoveValue(i + PHV::kTPhvMauGroupOffset);
      }
    }
  }
  else WARNING("Cannot find Bit for " << bit.name());
}

void Solver::SetContainerWidthConstraints() {
  std::map<std::pair<IntVar*, IntVar*>, Bit*> mau_group_offsets;
  for (auto &b : bits_) {
    Bit &bit = b.second;
    auto p = std::make_pair(bit.mau_group(), bit.base_offset());
    if (mau_group_offsets.count(p) == 0) {
      mau_group_offsets.insert(std::make_pair(p, &bit));
    }
    if (mau_group_offsets.at(p)->relative_offset() < bit.relative_offset()) {
      mau_group_offsets.at(p) = &bit;
    }
  }
  for (auto &p : mau_group_offsets) {
    p.second->SetContainerWidthConstraints();
  }
}

void Solver::allocation(const PHV::Bit &bit, PHV::Container *container,
                        int *container_bit) {
  (*container) = PHV::Container(0, 0);
  (*container_bit) = 0;
  if (0 != bits_.count(bit)) {
    const Bit &b(bits_.at(bit));
    if ((nullptr != b.mau_group()) && (nullptr != b.container_in_group())) {
      (*container) = PHV::Container(b.mau_group()->Value(),
                                    b.container_in_group()->Value());
      if (nullptr != b.base_offset())
        (*container_bit) = b.base_offset()->Value() + b.relative_offset();
      else WARNING("Cannot find offset for "  << bit);
    }
    else {
      WARNING("Missing " <<
                (nullptr == b.container_in_group() ? "container" : "") <<
                (nullptr == b.mau_group() ? " and MAU group" : "") <<
                " for " << bit);
    }
  }
  else {
    LOG1("Cannot find allocation for " << bit);
  }
}

class PrintFailure : public SearchMonitor {
 public:
  explicit PrintFailure(operations_research::Solver* const s, const std::vector<IntVar*> &vars) :
    SearchMonitor(s), vars_(vars) {}
  void BeginFail() {
//  LOG2("Inspecting failure");
//  for (auto v : vars_) {
//    if (v->Size() == 1)
//      LOG2("Found " << v->name() << " value is " << v->Value());
//    else {
//      LOG1("Failure " << v->name());
//      break; }
//  }
  }
 private:
  const std::vector<IntVar*> vars_;
};

bool
Solver::Solve1(operations_research::Solver::IntValueStrategy int_val,
               const bool &is_luby_restart) {
  LOG1("Starting new search");
  auto int_vars = GetIntVars();
  auto db = solver_.MakePhase(int_vars,
                              operations_research::Solver::CHOOSE_FIRST_UNBOUND,
                              int_val);
  std::vector<SearchMonitor*> monitors;
  PrintFailure pf(&solver_, int_vars);
  if (is_luby_restart) monitors.push_back(solver_.MakeLubyRestart(1000));
  monitors.push_back(solver_.MakeFailuresLimit(150000));
  monitors.push_back(&pf);
  solver_.NewSearch(db, monitors);
  bool result = solver_.NextSolution();
  if (false == result) solver_.EndSearch();
  return result;
}

std::vector<IntVar*> Solver::GetIntVars() const {
  std::vector<IntVar*> rv;
  // Collect constraint variables.
  std::vector<IntVar*> group_vars(mau_groups());
  std::random_shuffle(group_vars.begin(), group_vars.end());
  while (group_vars.size() != 0) {
    rv.push_back(*group_vars.begin());
    auto vars2 = containers_and_offsets(*group_vars.begin());
    rv.insert(rv.end(), vars2.begin(), vars2.end());
    group_vars.erase(group_vars.begin());
  }
  for (auto &v : rv) {
    CHECK(nullptr != v) << "; Found nullptr in variable vector";
    LOG2("intvar vec: " << v->name());
  }
  return rv;
}

std::vector<IntVar*> Solver::mau_groups() const {
  std::set<IntVar*> rv;
  for (auto &b : bits_) {
    rv.insert(b.second.mau_group());
  }
  return std::vector<IntVar*>(rv.begin(), rv.end());
}

std::vector<IntVar*>
Solver::containers_and_offsets(IntVar *mau_group) const {
  std::set<IntVar*> container_in_groups;
  for (auto &b : bits_) {
    if (b.second.mau_group() == mau_group) {
      container_in_groups.insert(b.second.container_in_group());
    }
  }
  container_in_groups.erase(nullptr);
  // We could have made rv a std::set but we want to maintain the order of
  // variables.
  std::vector<IntVar*> rv;
  while (false == container_in_groups.empty()) {
    auto c = container_in_groups.begin();
    rv.push_back(*c);
    for (auto &b : bits_) {
      if (b.second.container_in_group() == *c &&
          b.second.base_offset() != nullptr &&
          rv.end() == std::find(rv.begin(), rv.end(), b.second.base_offset())) {
        rv.push_back(b.second.base_offset());
      }
    }
    container_in_groups.erase(c);
  }
  return rv;
}

IntVar *
Solver::MakeMauGroup(const cstring &name, std::array<IntVar*, 3> *flags,
                     const int &max) {
  auto v = solver_.MakeIntVar(0, max,
                              name + "-group-" + unique_id());
  v->RemoveValues(std::vector<int64>(PHV::kInvalidMauGroups.begin(),
                                     PHV::kInvalidMauGroups.end()));
  std::array<const std::vector<int>, 3> mau_groups =
    {{PHV::k8bMauGroups, PHV::k16bMauGroups, PHV::k32bMauGroups}};
  for (decltype(flags->size()) i = 0; i < flags->size(); ++i) {
    (*flags)[i] = GetWidthFlag(v, mau_groups[i]);
  }
  return v;
}

IntVar *
Solver::GetWidthFlag(IntVar *mau_group, const std::vector<int> &groups) {
  // This function sets constraints between is_8b or is_16b or is_32b and the
  // mau_group_ variable.
  std::vector<IntVar *> is_equal_vars;
  for (auto it = groups.begin(); it != groups.end(); ++it) {
    is_equal_vars.push_back(mau_group->IsEqual(*it));
  }
  return solver_.MakeSum(is_equal_vars)->Var();
}

IntVar *Solver::MakeContainerInGroup(const cstring &name) {
  return solver_.MakeIntVar(0, PHV::kNumContainersPerMauGroup - 1,
                            name + "-containeringroup-" + unique_id());
}

IntExpr *Solver::MakeContainer(IntVar *group, IntVar *container_in_group) {
  return solver_.MakeSum(solver_.MakeProd(group,
                                          PHV::kNumContainersPerMauGroup),
                         container_in_group);
}

IntVar *
Solver::MakeOffset(const cstring &name, const std::vector<int> &values) {
  // FIXME: For some reason, no name is being assigned to IntVar objects
  // created below.
  return solver_.MakeIntVar(values, name + "-voffset-" + unique_id());
}

IntVar *
Solver::MakeOffset(const cstring &name, const int &min, const int &max) {
  LOG2("Making offset " << name);
  return solver_.MakeIntVar(min, max,
                            name + "-offset-" + unique_id());
}

IntExpr *
Solver::MakeDeparserGroup(Byte *byte, IntVar *mau_group, IntExpr *container,
                          const gress_t &thread, const cstring &name) {
  if (nullptr == byte->deparser_group()) {
    LOG2("Making deparser group flags for " << name);
    std::vector<IntVar*> flags;
    flags.reserve(PHV::kNumDeparserGroups);
    auto lt_flags = std::array<IntVar*, PHV::kMaxContainer>();
    for (auto boundaries : PHV::kDeparserGroups) {
      if (boundaries.at(0) < PHV::kTPhvContainerOffset ||
          true == mau_group->Contains(PHV::kTPhvMauGroupOffset)) {
        flags.push_back(
          MakeDeparserGroupFlags(container, boundaries, &lt_flags));
      }
    }
    IntExpr *deparser_group = solver_.MakeSum(flags);
    // If the container is allocated to one of the "shared deparser groups", we
    // want to make sure that domain of byte->deparser_group_ does not overlap
    // for ingress and egress.
    if (thread == INGRESS) {
      std::vector<IntVar*> v;
      for (auto i : PHV::kSharedDeparserGroups) {
        v.push_back(solver_.MakeIsEqualCstVar(container, i));
      }
      deparser_group = solver_.MakeSum(deparser_group,
                         solver_.MakeProd(solver_.MakeSum(v),
                                          PHV::kNumDeparserGroups + 1));
    }
    byte->set_deparser_group(deparser_group);
  }
  return byte->deparser_group();
}

IntVar *
Solver::MakeDeparserGroupFlags(IntExpr *container,
                               const std::vector<int> &boundaries,
                               std::array<IntVar*, PHV::kMaxContainer> *lt) {
  CHECK(1 == boundaries.size() || 3 == boundaries.size() ||
          5 == boundaries.size() || 7 == boundaries.size()) << ": Found " <<
    boundaries.size() << " elements in boundary vector";
  bool is_lt = false;
  int expected_sum = 0;
  std::vector<IntVar*> cmp_flags;
  auto it = boundaries.begin();
  while (boundaries.end() != it) {
    if (true == is_lt) {
      if (nullptr == lt->at(*it)) {
        lt->at(*it) = solver_.MakeIsLessCstVar(container, *it);
      }
      cmp_flags.push_back(lt->at(*it));
    }
    else {
      ++expected_sum;
      cmp_flags.push_back(solver_.MakeIsGreaterOrEqualCstVar(container, *it));
    }
    is_lt = (!is_lt);
    ++it;
  }
  IntExpr *sum = nullptr;
  if (cmp_flags.size() == 1) sum = cmp_flags.front();
  else sum = solver_.MakeSum(cmp_flags);
  return solver_.MakeIsEqualCstVar(sum, expected_sum);
}

Bit *Solver::MakeBit(const PHV::Bit &phv_bit) {
  if (bits_.count(phv_bit) == 0) {
    bits_.emplace(std::make_pair(phv_bit, Bit(phv_bit.name())));
  }
  Bit &bit = bits_.at(phv_bit);
  if (nullptr == bit.mau_group()) {
    std::array<IntVar*, 3> size_flags;
    // MAU groups created here will be restricted to PHV (no T-PHV).
    IntVar *mau_group =
      MakeMauGroup(bit.name(), &size_flags,
                   PHV::kPhvMauGroupOffset + PHV::kNumPhvMauGroups - 1);
    bit.set_mau_group(mau_group, size_flags);
  }
  if (nullptr == bit.container_in_group()) {
    IntVar *container_in_group = MakeContainerInGroup(bit.name());
    IntExpr *container = MakeContainer(bit.mau_group(), container_in_group);
    bit.set_container(container_in_group, container);
  }
  if (nullptr == bit.base_offset()) {
    CHECK(bit.offset() == nullptr) << "; Invalid offset in " << bit.name();
    bit.set_offset(MakeOffset(bit.name()), 0);
  }
  if (nullptr == bit.byte()) {
    bit.set_byte(new Byte());
  }
  return &bit;
}
}
