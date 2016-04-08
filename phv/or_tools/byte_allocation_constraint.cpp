#include "container_var_creator.h"
#include "header_bits.h"
#include "header_bit.h"
#include "ir/ir.h"
#include "backends/tofino/parde/parde_visitor.h"
#include "backends/tofino/mau/mau_visitor.h"
#include <constraint_solver/constraint_solver.h>
#include "phv.h"
#include <array>
#include <climits>

class PardeVarCreator : public PardeInspector {
 public:
  PardeVarCreator(
    HeaderBits &header_bits) : header_bits_(header_bits) { }
  void CreateVars(const IR::Tofino::Pipe *maupipe) {
    maupipe->apply(*this);
  }
 protected:
  void SetVars(const IR::HeaderRef *header_ref, const int &lsb, const int &msb,
               int start_offset = 0) {
    HeaderBit *prev_bit = nullptr;
    for (int i = lsb; i <= msb; ++i, ++start_offset) {
      auto bit = header_bits_.get(header_ref->toString(), i);
      if (start_offset == 8) start_offset = 0;
      if (bit->container() == nullptr) {
        if ((prev_bit == nullptr) || start_offset == 0) {
          LOG2("Create new container for " << bit->name() <<
                 " with start offset " << start_offset);
          CHECK(bit->container_in_group() == nullptr) <<
            "; Container in group variable already exists for " << bit->name();
          std::array<operations_research::IntVar*, 3> is_xb;
          auto group = header_bits_.MakeGroupVar(bit->name(), &is_xb);
          bit->set_group(group, is_xb);
          auto container_in_group = header_bits_.MakeContainerInGroupVar(
                                      bit->name());
          auto container = header_bits_.MakeContainerExpr(group,
                                                          container_in_group);
          bit->set_container(container_in_group, container);
          bit->set_offset(
            header_bits_.MakeByteAlignedOffsetVar(bit->name()),
            start_offset, header_bits_.solver());
        }
        else {
          bit->CopyContainer(prev_bit);
          bit->set_offset(*prev_bit, 1, *(header_bits_.solver()));
        }
        prev_bit = bit;
      }
      else {
        prev_bit = nullptr;
      }
    }
  }
 private:
  HeaderBits &header_bits_;
};

class DeparserVarCreator : public PardeVarCreator {
 public:
  DeparserVarCreator(HeaderBits &header_bits) : PardeVarCreator(header_bits) { }
  bool preorder(const IR::Primitive *prim) override {
    if (prim->name == "emit") {
      CHECK(prim->operands.size() == 1) << "; Illegal parameters in " <<
        prim->toString();
      auto hsr = prim->operands[0]->to<const IR::HeaderSliceRef>();
      LOG1("Found deparsed slice " << hsr->toString());
      CHECK(nullptr != hsr) << "; Invalid operand for " << prim->toString();
      SetVars(hsr->header_ref(), hsr->lsb(), hsr->msb(), 0);
    }
    return false;
  }
};

class ParserVarCreator : public PardeVarCreator {
 public:
  ParserVarCreator(HeaderBits &header_bits) : PardeVarCreator(header_bits) { }
  bool preorder(const IR::Primitive *prim) override {
    if (prim->name == "set_metadata") {
      CHECK(prim->operands.size() == 2 || prim->operands.size() == 1) <<
        "; Invalid operands for " << prim->toString();
      auto hsr = prim->operands[0]->to<const IR::HeaderSliceRef>();
      LOG2("Applying set_metadata constraint for " << prim);
      if (nullptr != hsr) {
        int offset = 0;
        auto src_hsr = prim->operands[1]->to<const IR::HeaderSliceRef>();
        if (nullptr != src_hsr) offset = (src_hsr->offset_bits() % 8);
        // FIXME: This just handles the case where the destination of
        // set_metadata needs the same byte-alignment as the source packet
        // field. However, if a constant is written to a metadata, there is no
        // constraint on alignment. That is not handled here.
        SetVars(hsr->header_ref(), hsr->lsb(), hsr->msb(), offset);
      }
      else LOG1("Skipping " << prim);
    }
    return false;
  }
};

class MauVarCreator : public MauInspector {
 public:
  MauVarCreator(HeaderBits &header_bits) :
    header_bits_(header_bits) { }
  void CreateContainerVars(const IR::Tofino::Pipe *maupipe) {
    maupipe->apply(*this);
  }
 protected:
  void
  SetGroupEquality(const std::set<HeaderBit*> &group_bits) const {
    auto it = std::find_if(
                group_bits.begin(), group_bits.end(),
                [](const HeaderBit *h) -> bool { return h->group() == nullptr; });
    if (it != group_bits.end()) {
      LOG2("Found nullptr group for " << (*it)->name());
      it = std::find_if(
             group_bits.begin(), group_bits.end(),
             [](const HeaderBit *h) -> bool { return h->group() != nullptr; });
      operations_research::IntVar *group = nullptr;
      std::array<operations_research::IntVar*, 3> is_xb = {{nullptr, nullptr,
                                                            nullptr}};
      if (it != group_bits.end()) {
        LOG3("Copying group from " << (*it)->name());
        group = (*it)->group();
        is_xb = (*it)->width_flags();
      }
      else {
        group = header_bits_.MakeGroupVar(
                  cstring("metadata-group-") +
                    std::to_string(header_bits_.unique_id()), &is_xb);
      }
      CHECK(group != nullptr);
      for (it = group_bits.begin(); it != group_bits.end(); ++it) {
        if (nullptr == (*it)->group()) {
          LOG3("Setting group for " << (*it)->name());
          (*it)->set_group(group, is_xb);
        }
        else LOG3((*it)->name() << " already has a group");
      }
    }
    // Collect all the MAU group variables into a std::set (vars) and set
    // equality constraint between them.
    auto vars = std::accumulate(
                  group_bits.begin(), group_bits.end(),
                  std::set<operations_research::IntVar*>(),
                  [](std::set<operations_research::IntVar*> &group_vars,
                     const HeaderBit *h) { group_vars.insert(h->group());
                                           return group_vars; });
    auto group_var = *(vars.begin());
    for (auto it2 = vars.begin(); it2 != vars.end(); ++it2) {
      header_bits_.SetEqualityConstraint(group_var, *it2);
    }
  }
  HeaderBits &header_bits_;
};

class AtomicOperandVarCreator : public MauVarCreator {
 public:
  AtomicOperandVarCreator(HeaderBits &header_bits) :
    MauVarCreator(header_bits) { }
  bool preorder(const IR::Primitive *prim) {
    std::set<cstring> arithmetic_primitives({"add", "add_to_field", "subtract"
                                             "subtract_from_field"});
    if (arithmetic_primitives.count(prim->name) != 0) {
      // Put all the bits of the arithmetic operation into the same container.
      std::set<HeaderBit*> bits;
      for (auto &operand : prim->operands) {
        const IR::HeaderSliceRef *hsr = operand->to<const IR::HeaderSliceRef>();
        if (nullptr != hsr) {
          for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
            bits.insert(header_bits_.get(hsr->header_ref()->toString(), i));
          }
        }
      }
      SetGroupEquality(bits);
      // In this block of code, make the header slice atomic if it is used in
      // any arithmetic primitive.
      for (auto &operand : prim->operands) {
        const IR::HeaderSliceRef *hsr = operand->to<const IR::HeaderSliceRef>();
        if (nullptr != hsr) {
          HeaderBit *bit_with_container = nullptr;
          operations_research::IntVar *group = nullptr;
          for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
            auto bit = header_bits_.get(hsr->header_ref()->toString(), i);
            if (nullptr == group) group = bit->group();
            if (nullptr != bit->container()) {
              bit_with_container = bit;
              group = bit->group();
            }
          } // endfor over bits of header slice.
          operations_research::IntVar *container_in_group = nullptr;
          operations_research::IntExpr *container = nullptr;
          if (nullptr == bit_with_container) {
            CHECK(nullptr != group);
            auto cname = std::to_string(header_bits_.unique_id()) + "-container";
            container_in_group = header_bits_.MakeContainerInGroupVar(cname);
            container = header_bits_.MakeContainerExpr(group,
                                                       container_in_group);
          }
          else {
            container = bit_with_container->container();
            container_in_group = bit_with_container->container_in_group();
          }
          for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
            auto bit = header_bits_.get(hsr->header_ref()->toString(), i);
            if (bit->container_in_group() == nullptr) {
              CHECK(header_bits_.IsEqual(group, bit->group()));
              bit->set_container(container_in_group, container);
            }
            else {
              header_bits_.SetEqualityConstraint(bit->container(), container);
              header_bits_.SetEqualityConstraint(bit->container_in_group(),
                                                 container_in_group);
            }
          } // endfor over bits of header slice.
          HeaderBit *prev_bit = nullptr;
          for (int i = hsr->lsb(); i <= hsr->msb(); ++i) {
            auto bit = header_bits_.get(hsr->header_ref()->toString(), i);
            auto solver = header_bits_.solver();
            if (bit->base_offset() == nullptr) {
              CHECK(bit->offset() == nullptr);
              if (prev_bit == nullptr) {
                bit->set_offset(header_bits_.MakeOffsetVar(bit->name().c_str()),
                                0, solver);
              }
              else {
                operations_research::IntVar *offset =
                  solver->MakeSum(prev_bit->offset(), 1)->Var();
                bit->set_offset(offset, 0, solver);
              }
            }
            else if (prev_bit != nullptr) {
              if (prev_bit->base_offset() == bit->base_offset()) {
                CHECK(prev_bit->relative_offset() + 1 == bit->relative_offset()) <<
                  "; Contradicting constraint between " << bit->name() <<
                  " and " << prev_bit->name() << " " << bit->relative_offset() << " " << prev_bit->relative_offset();
              }
              else {
                solver->AddConstraint(
                  solver->MakeEquality(solver->MakeSum(prev_bit->offset(), 1),
                                       bit->offset()));
              }
            }
            prev_bit = bit;
          } // endfor over bits of header slice.
        }
        else LOG1("Skipping " << operand << " in arithmetic constraint");
      } // endfor over operands of primitive.
    }
    return false;
  }
};

class OperandVarCreator : public MauVarCreator {
 public:
  OperandVarCreator(HeaderBits &header_bits) :
    MauVarCreator(header_bits) { }
  bool preorder(const IR::Primitive *prim) {
    if (prim->name == "set") {
      LOG2("Setting group constraint for " << prim);
      CHECK(prim->operands.size() == 2) << "; Invalid primitive " <<
        prim->toString();
      auto dst = prim->operands[0]->to<IR::HeaderSliceRef>();
      auto src = prim->operands[1]->to<IR::HeaderSliceRef>();
      if ((nullptr != dst) && (nullptr != src) &&
          (dst->type->width_bits() != src->type->width_bits())) {
        WARNING("Width mismatch in " << prim->toString());
      }
      auto width = std::min(dst->type->width_bits(),
                            nullptr == src ? INT_MAX : src->type->width_bits());
      for (int i = 0; i < width; ++i) {
        std::set<HeaderBit*> bits;
        if (dst != nullptr)
          bits.insert(header_bits_.get(dst->header_ref()->toString(),
                                       dst->lsb() + i));
        if (src != nullptr)
          bits.insert(header_bits_.get(src->header_ref()->toString(),
                                       src->lsb() + i));
        SetGroupEquality(bits);
        for (auto bit : bits) {
          if (nullptr == bit->container()) {
            auto cname = std::to_string(header_bits_.unique_id()) + "-container";
            auto container_in_group = header_bits_.MakeContainerInGroupVar(cname);
            bit->set_container(container_in_group,
                               header_bits_.MakeContainerExpr(
                                 bit->group(), container_in_group));
          }
          if (nullptr == bit->base_offset()) {
            bit->set_offset(header_bits_.MakeOffsetVar(bit->name().c_str()), 0,
                            header_bits_.solver());
          }
        }
      }
    }
    return false;
  }
};

void
ContainerVarCreator::CreateContainerVars(const IR::Tofino::Pipe *maupipe) {
  DeparserVarCreator dvc(header_bits_);
  dvc.CreateVars(maupipe);
  ParserVarCreator pvc(header_bits_);
  pvc.CreateVars(maupipe);
  AtomicOperandVarCreator aovc(header_bits_);
  aovc.CreateContainerVars(maupipe);
  OperandVarCreator ovc(header_bits_);
  ovc.CreateContainerVars(maupipe);
}
