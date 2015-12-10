#include "or_tools_allocator.h"
#include "phv.h"
#include "tofino/parde/parde_visitor.h"
#include "tofino/mau/mau_visitor.h"
#include <constraint_solver/constraint_solver.h>
#include <map>
#include <set>

using namespace operations_research;

// This class contains contraint variables for a byte in the P4 program.
class HeaderByteVars {
 public:
  HeaderByteVars(Solver &solver, const std::string &byte_name,
                 const HeaderByteVars *previous_byte)
  : is_next_byte_(nullptr), previous_byte_(previous_byte) {
    group_ = solver.MakeIntVar(0, 13, byte_name + "-group");
    container_in_group_ = solver.MakeIntVar(0, Phv::kNumContainersPerPhvGroup - 1,
                                            byte_name + "-container");
    container_ = solver.MakeSum(solver.MakeProd(group_,
                                                Phv::kNumContainersPerPhvGroup),
                                container_in_group_);
    byte_offset_ = solver.MakeIntVar(0, 3, byte_name + "-byte-offset");
    byte_ = solver.MakeSum(solver.MakeProd(container_, 4), byte_offset_);
    offset_ = solver.MakeProd(byte_offset_, 8);
    is8b_ = solver.MakeBoolVar(byte_name + "-is8b");
    is16b_ = solver.MakeBoolVar(byte_name + "-is16b");
    is32b_ = solver.MakeBoolVar(byte_name + "-is32b");
    SetGroupFlag(solver, Phv::k8bPhvGroups,
                 std::vector<int> ({8, 16, 24}), is8b_);
    SetGroupFlag(solver, Phv::k16bPhvGroups,
                 std::vector<int> ({16, 24}), is16b_);
    SetGroupFlag(solver, Phv::k32bPhvGroups,
                 std::vector<int> (), is32b_);
  }

  void
  AddDeparserConstraints(Solver &solver) {
    auto last_byte_expr = solver.MakeSum(std::vector<IntVar *> ({
      is8b_, solver.MakeIsEqualVar(is16b_, solver.MakeDifference(
                                             solver.MakeIntConst(9), offset_)),
      solver.MakeIsEqualVar(is32b_, solver.MakeDifference(
                                      solver.MakeIntConst(25), offset_))}));
    is_last_byte_ = solver.MakeIsEqualVar(last_byte_expr,
                                          solver.MakeIntConst(1));
    if (nullptr != previous_byte_) {
      assert (nullptr != previous_byte_->byte_offset_);
      is_next_byte_ = solver.MakeIsEqualVar(
                        solver.MakeSum(
                          solver.MakeIsEqualVar(
                            container(), previous_byte_->container()),
                          solver.MakeIsEqualVar(
                            byte_offset_,
                            solver.MakeSum(previous_byte_->byte_offset_, 1))),
                        solver.MakeIntConst(2));
      solver.AddConstraint(
        solver.MakeEquality(solver.MakeSum(is_next_byte_,
                                           previous_byte_->is_last_byte()), 1));
      solver.AddConstraint(
        solver.MakeEquality(solver.MakeProd(previous_byte_->is_last_byte(),
                                            byte_offset_), 0));
    }
    // If this is the first byte of a header, pin it to byte offset 0.
    else byte_offset_->RemoveValues({1, 2, 3});
  }

  void
  set_last_byte(Solver &solver) {
    solver.AddConstraint(solver.MakeEquality(is_last_byte_, 1));
  }

  std::vector<IntVar *>
  allocation_vars() const {
    std::vector<IntVar *> v = {group_, container_in_group_, byte_offset_,
                               is8b_, is16b_, is32b_, is_last_byte_};
    if (nullptr != is_next_byte_) {
      v.push_back(is_next_byte_);
    }
    return v;
  }

  IntVar *
  is8b() const {
    return is8b_;
  }

  IntVar *
  is16b() const {
    return is16b_;
  }

  IntVar *
  is32b() const {
    return is32b_;
  }

  IntVar *
  is_last_byte() const {
    return is_last_byte_;
  }

  IntVar *
  group() const {
    return group_;
  }

  IntVar* container_in_group() const {
    return container_in_group_;
  }

  IntExpr *
  container() const {
    return container_;
  }

  IntVar* byte_offset() const {
    return byte_offset_;
  }

  IntExpr* byte() const {
    return byte_;
  }
 private:
  void SetGroupFlag(Solver &s, const std::vector<int> &groups,
                    const std::vector<int> &offsets, IntVar *v) {
    std::vector<IntVar *> is_equal_vars;
    for (auto it = groups.begin(); it != groups.end(); ++it) {
      is_equal_vars.push_back(s.MakeIsEqualVar(s.MakeIntConst(*it), group_));
    }
    s.AddConstraint(s.MakeEquality(s.MakeSum(is_equal_vars), v));
    for (auto it = offsets.begin(); it != offsets.end(); ++it) {
      auto is_equal_var = s.MakeIsEqualVar(offset_, s.MakeIntConst(*it));
      auto sum = s.MakeSum(v, is_equal_var);
      s.AddConstraint(s.MakeNonEquality(sum, 2));
    }
  }
  // PHV group of this byte.
  IntVar *group_;
  // Container in PHV group of this byte. For Tofino, this has range [0, 15].
  IntVar *container_in_group_;
  // Byte within a PHV container of this byte.
  IntVar *byte_offset_;
  // Bit-offset within a PHV container of this byte. This is byte_offset_ * 8
  // for packet header bytes.
  IntExpr *offset_;
  IntExpr *container_, *byte_;
  // Flags to indicate PHV container width for this byte. Each is a boolean
  // variable. Their sum must be 1.
  IntVar *is8b_, *is16b_, *is32b_;
  IntVar *is_last_byte_, *is_next_byte_;
  const HeaderByteVars *const previous_byte_;
};

class HeaderVars {
 public:
  HeaderVars(Solver &s, const cstring &header_name, const gress_t gress,
             const long &max_length) :
    header_bytes_(), name_(header_name), max_length_bits_(max_length),
    gress_(gress) {
    HeaderByteVars *previous_byte = nullptr;
    for (long i = 0; i < max_length; i+=8) {
      auto byte_name = header_name + "[" + std::to_string(i >> 3) + "]";
      header_bytes_.emplace_back(new HeaderByteVars(s, byte_name,
                                                    previous_byte));
      previous_byte = header_bytes_.back().get();
    }
  }

  void AddDeparserConstraints(Solver &s) {
    for (auto &hdr_byte : header_bytes_) {
      hdr_byte->AddDeparserConstraints(s);
    }
    header_bytes_.back()->set_last_byte(s);
  }

  void AddParserConstraints(Solver &s) {
    std::vector<IntVar *> is8b, is16b, is32b;
    for (auto &b : header_bytes_) {
      is8b.push_back(b->is8b());
      is16b.push_back(b->is16b());
      is32b.push_back(b->is32b());
    }
    // Setting parser bandwidth constraints.
    long max_cycles = ((max_length_bits_ >> 3) / 7) + 3;
    s.AddConstraint(
      s.MakeSumLessOrEqual(is8b, max_cycles));
    s.AddConstraint(
      s.MakeSumLessOrEqual(is16b, max_cycles * 2));
    s.AddConstraint(
      s.MakeSumLessOrEqual(is32b, max_cycles * 4));

    // Make sure bytes of a header are not overlayed. This is not needed for
    // metadata. For deparsed headers, the user may want the same value two
    // fields always. So, don't enforce for deparsed headers either.
    for (auto header_byte1 = header_bytes_.begin();
         header_byte1 != header_bytes_.end(); ++header_byte1) {
      auto header_byte2 = header_byte1 + 1;
      while (header_byte2 != header_bytes_.end()) {
        assert(header_byte1->get() != header_byte2->get());
        s.AddConstraint(
          s.MakeNonEquality(header_byte1->get()->byte(),
                            header_byte2->get()->byte()));
        ++header_byte2;
      }
    }
  }

  void
  AddHeaderConflictConstraint(Solver &solver, HeaderVars *header_vars) {
    for (auto &header_byte1 : header_bytes_) {
      for (auto &header_byte2 : header_vars->header_bytes_) {
        solver.AddConstraint(
          solver.MakeNonEquality(header_byte1->byte(), header_byte2->byte()));
      }
    }
  }

  std::vector<IntVar *>
  allocation_vars() const {
    std::vector<IntVar *> vars;
    for (auto &b : header_bytes_) {
      auto v = b->allocation_vars();
      vars.insert(vars.end(), v.begin(), v.end());
    }
    return vars;
  }

  void
  PrintAllocation(const cstring &name) const {
    unsigned int byte_offset = 0;
    for (auto &header_byte : header_bytes_) {
      auto allocation_vars = header_byte->allocation_vars();
    std::cout << "|" << std::setw(30) <<
      (name + "[" + std::to_string(byte_offset++) + "]") << "|" <<
      std::setw(10) << allocation_vars[0]->Value() <<  "|" <<
      std::setw(10) << allocation_vars[1]->Value() <<  "|" <<
      std::setw(10) << allocation_vars[2]->Value() << "|" << std::endl;
    }
  }

  HeaderByteVars* header_byte(int offset) const {
    assert ((size_t)offset < header_bytes_.size());
    return header_bytes_[offset].get();
  }

  cstring name() const {
    return name_;
  }

  cstring name(const long &offset) const {
    return name() + "[" + std::to_string(offset) + "]";
  }

  long max_length_bits() const {
    return max_length_bits_;
  }

  gress_t gress() const {
    return gress_;
  }
 private:
  HeaderVars(const HeaderVars &) = delete;
  std::vector<std::unique_ptr<HeaderByteVars>> header_bytes_;
  const cstring name_;
  const long max_length_bits_;
  const gress_t gress_;
};

class PardeConstraintsInspector : public PardeInspector {
 public:
  PardeConstraintsInspector(ORToolsAllocator &allocator)
  : PardeInspector(), is_extract_(false), allocator_(allocator) {
    visitDagOnce = false;
  }

 private:
  bool preorder(const IR::Tofino::Parser *p) {
    gress_ = p->gress;
    return true;
  }

  bool preorder(const IR::Tofino::ParserState *) {
    num_headers_stack_.push_back(header_names_.size());
    return true;
  }

  void postorder(const IR::Tofino::ParserState *) {
    assert(num_headers_stack_.back() <= header_names_.size());
    // Pop off headers seen in the current parse state.
    header_names_.resize(num_headers_stack_.back());
    num_headers_stack_.pop_back();
  }

  bool preorder(const IR::Primitive *primitive) {
    if (primitive->name == "extract") is_extract_ = true;
    return true;
  }

  bool preorder(const IR::HeaderRef *header_ref) {
    if (true == is_extract_) {
      cstring header_name = header_ref->toString();
      header_names_.remove_if([&](const cstring &v) -> bool
                                 { return v == header_name; });
      if (conflict_map_.find(header_name) == conflict_map_.end()) {
        conflict_map_.insert(std::make_pair(header_name, std::set<cstring>()));
      }
      std::list<cstring> new_conflicts(header_names_);
      new_conflicts.remove_if([this, &header_name] (const cstring &v) -> bool {
                                return conflict_map_.at(header_name).find(v) !=
                                         conflict_map_.at(header_name).end();
                              });
      allocator_.AddParserConstraints(header_ref, gress_, new_conflicts);
      conflict_map_.at(header_name).insert(header_names_.begin(),
                                           header_names_.end());
      header_names_.push_back(header_name);
      is_extract_ = false;
    }
    return true;
  }

  // This stack stores the number of headers seen in a packet till the current
  // parse state was reached.
  std::list<std::list<cstring>::size_type> num_headers_stack_;
  std::list<cstring> header_names_;
  bool is_extract_;
  gress_t gress_;
  std::map<cstring, std::set<cstring>> conflict_map_;
  ORToolsAllocator &allocator_;
};

ORToolsAllocator::ORToolsAllocator() :
  solver_("Allocator"), parde_inspector_(new PardeConstraintsInspector(*this))
{
}

ORToolsAllocator::~ORToolsAllocator() {
}

void
ORToolsAllocator::AddParserConstraints(const IR::HeaderRef *header_ref,
                                       const gress_t &gress,
                                       const std::list<cstring> header_names) {
  const cstring header_name = header_ref->toString();
  if (header_vars_.find(header_name) == header_vars_.end()) {
    header_vars_.emplace(
      header_name, std::unique_ptr<HeaderVars>(
                     new HeaderVars(solver_, header_name, gress,
                                    header_ref->type->width_bits())));
    header_vars_.at(header_name)->AddParserConstraints(solver_);
    // FIXME: Assuming that all parsed headers are deparsed. This is not true
    // (esp for bridged metadata). Fix this when deparser IR is ready.
    header_vars_.at(header_name)->AddDeparserConstraints(solver_);
    for (auto &h : header_vars_) {
      if (h.second->gress() != gress)
        header_vars_.at(header_name)->AddHeaderConflictConstraint(
          solver_, h.second.get());
    }
  }
  for (auto hdr_name : header_names) {
    header_vars_.at(header_name)->AddHeaderConflictConstraint(
      solver_, header_vars_.at(hdr_name).get());
  }
}

void
ORToolsAllocator::Solve() {
  for (auto &h : header_vars_) {
    const auto &v =  h.second->allocation_vars();
    allocation_vars_.insert(allocation_vars_.end(), v.begin(), v.end());
  }
  auto db = solver_.MakePhase(allocation_vars_, Solver::CHOOSE_FIRST_UNBOUND,
                              Solver::ASSIGN_MIN_VALUE);
  solver_.NewSearch(db);
  CHECK(solver_.NextSolution());
  std::cout << "Generating solution for PHV allocation" << std::endl;
  for (auto i : allocation_vars_) {
    std::cout << i->name() << " : " << i->Value() << std::endl;
  }
  std::cout << "|" << std::setw(30) << "Header" << "|" <<
    std::setw(10) << "Group" <<  "|" <<
    std::setw(10) << "Container" <<  "|" <<
    std::setw(10) << "Byte" << "|" << std::endl;
  for (auto &header : header_vars_) {
    header.second->PrintAllocation(header.first);
  }
  for (int group = 0; group < Phv::kNumGroups; ++group) {
    for (int container = 0; container < Phv::kNumContainersPerPhvGroup;
         ++container) {
      std::cout << "|" << std::setw(10) <<
        std::string(std::to_string(group) + ":" + std::to_string(container)) <<
        "|" << std::setw(30) << "" << "|" << std::endl;
      for (auto &header : header_vars_) {
        for (long offset = 0; offset < header.second->max_length_bits();
             offset += 8) {
          HeaderByteVars *byte = header.second->header_byte(offset / 8);
          if (group == byte->group()->Value() &&
              container == byte->container_in_group()->Value() &&
              0 == byte->byte_offset()->Value()) {
            std::cout << "|" << std::setw(10) << "" << "|" << std::setw(20) <<
              header.second->name(offset) << "|" << std::endl;
          }
        }
      }
    }
  }
}
