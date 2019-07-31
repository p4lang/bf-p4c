#ifndef BF_P4C_MAU_IXBAR_EXPR_H_
#define BF_P4C_MAU_IXBAR_EXPR_H_

#include "ir/ir.h"
#include "bf-p4c/mau/mau_visitor.h"
#include "bf-p4c/phv/phv_fields.h"

class CanBeIXBarExpr : public Inspector {
    static constexpr int MAX_HASH_BITS = 52;
    bool        rv = true;
    // FIXME -- if we want to run this *before* SimplifyReferences has converted all
    // PathExpressions into the referred to object, we need some way of resolving what the
    // path expressions refer to, or at least whether they refer to something that can be
    // accessed in the ixbar.  So we use this function on a per-use basis.  The default
    // implementation throws a BUG if ever called (as normally we're after SimplifyReferences
    // and all PathExpressions are gone), but in the case where we're before that (calling
    // from CreateSaluInstruction called from AttachTables called from extract_maupipe),
    // we use a functor that can tell a local of the RegisterAction (which can't be in the
    // ixbar) from anything else (which is assumed to be a header or metadata instance.)
    // If we ever clean up the frontend reference handling so we no longer need to resolve
    // names via the refmap, this can go away.  Or if we could do SimplifyRefernces before
    // trying to build StatefulAlu instructions.
    std::function<bool(const IR::PathExpression *)> checkPath;

    static const IR::Type_Extern *externType(const IR::Type *type) {
        if (auto *spec = type->to<IR::Type_SpecializedCanonical>())
            type = spec->baseType;
        return type->to<IR::Type_Extern>(); }

    profile_t init_apply(const IR::Node *n) {
        rv = true;
        return Inspector::init_apply(n); }
    bool preorder(const IR::Node *) { return false; }  // ignore non-expressions
    bool preorder(const IR::PathExpression *pe) {
        if (pe->type->width_bits() > MAX_HASH_BITS || !checkPath(pe)) rv = false;
        return false; }
    bool preorder(const IR::Constant *c) {
        if (c->type->width_bits() > MAX_HASH_BITS) rv = false;
        return false; }
    bool preorder(const IR::Member *m) {
        if (m->type->width_bits() > MAX_HASH_BITS) rv = false;
        auto *base = m->expr;
        while ((m = base->to<IR::Member>())) base = m->expr;
        if (auto *pe = base->to<IR::PathExpression>()) {
            if (!checkPath(pe)) rv = false;
        } else if (base->is<IR::HeaderRef>() || base->is<IR::TempVar>()) {
            // ok
        } else {
            rv = false; }
        return false; }
    bool preorder(const IR::TempVar *tv) {
        if (tv->type->width_bits() > MAX_HASH_BITS) rv = false;
        return false; }
    bool preorder(const IR::Slice *sl) {
        if (sl->type->width_bits() > MAX_HASH_BITS) {
            rv = false;
        } else if (sl->e0->is<IR::Member>() || sl->e0->is<IR::TempVar>()) {
            // can do a small slice of a field even when whole field would be too big
            return false; }
        return rv; }
    bool preorder(const IR::Concat *c) {
        if (c->type->width_bits() > MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::Cast *c) {
        if (c->type->width_bits() > MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BFN::SignExtend *e) {
        if (e->type->width_bits() > MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BFN::ReinterpretCast *e) {
        if (e->type->width_bits() > MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BXor *e) {
        if (e->type->width_bits() > MAX_HASH_BITS) rv = false;
        return rv; }
    bool preorder(const IR::BAnd *e) {
        if (e->type->width_bits() > MAX_HASH_BITS) {
            rv = false;
        } else if (!e->left->is<IR::Constant>() && e->right->is<IR::Constant>()) {
            rv = false; }
        return rv; }
    bool preorder(const IR::BOr *e) {
        if (e->type->width_bits() > MAX_HASH_BITS) {
            rv = false;
        } else if (!e->left->is<IR::Constant>() && e->right->is<IR::Constant>()) {
            rv = false; }
        return rv; }
    bool preorder(const IR::MethodCallExpression *mce) {
        if (auto *method = mce->method->to<IR::Member>()) {
            if (auto *ext = externType(method->type)) {
                if (ext->name == "Hash" && method->member == "get") {
                    return false; } } }
        return rv = false; }
    // any other expression cannot be an ixbar expression
    bool preorder(const IR::Expression *) { return rv = false; }

 public:
    explicit CanBeIXBarExpr(const IR::Expression *e,
                            std::function<bool(const IR::PathExpression *)> checkPath =
        [](const IR::PathExpression *)->bool { BUG("Unexpected path expression"); })
    : checkPath(checkPath) { e->apply(*this); }
    operator bool() const { return rv; }
};


struct P4HashFunction {
    safe_vector<const IR::Expression *> inputs;
    le_bitrange hash_bits;
    IR::MAU::HashFunction algorithm;
    cstring dyn_hash_name;
    LTBitMatrix symmetrically_hashed_inputs;

    bool is_dynamic() const {
       bool rv = !dyn_hash_name.isNull();
       // Symmetric is currently not supported with the dynamic hash library in bf-utils
       if (rv)
           BUG_CHECK(symmetrically_hashed_inputs.empty(), "Dynamically hashed values cannot "
               "have symmetric fields");
       return rv;
    }
    bool equiv_dyn(const P4HashFunction *func) const;
    bool equiv_inputs_alg(const P4HashFunction *func) const;


    void slice(le_bitrange hash_slice);
    cstring name() const { return is_dynamic() ? dyn_hash_name : "static_hash"; }
    int size() const { return hash_bits.size(); }
    bool equiv(const P4HashFunction *) const;
    bool is_next_bit_of_hash(const P4HashFunction *) const;

    bool overlap(const P4HashFunction *, le_bitrange *my_overlap, le_bitrange *hash_overlap) const;
    void dbprint(std::ostream &out) const;
};

class VerifySymmetricHashPairs {
 public:
    VerifySymmetricHashPairs(const PhvInfo &phv, safe_vector<const IR::Expression *> &field_list,
        const IR::Annotations *annotations, gress_t gress, IR::MAU::HashFunction hf,
        LTBitMatrix *sym_pairs);
    bool contains_symmetric = false;
};

/**
 * The purpose of this function is to convert an Expression into a P4HashFunction, which can
 * be used by the internal algorithms to compare, allocate, and generate JSON.  The hash function
 * is built entirely around the IR::MAU::HashGenExpression, where the HashGenExpression
 * indicate which fields are inputs and the algorithm, and the Slice on the outside can also
 * determine hash_bits
 *
 * FIXME: This pass is an extension of the IXBar::FieldManagement pass, and similar to the
 * IR::MAU::HashGenExpression, the goal would be obsolete the IXBar::FieldManagement pass,
 * which gathers up information about all xbar information for all types of inputs, and
 * gathers a list of functions to allocate
 */
class BuildP4HashFunction : public PassManager {
    P4HashFunction* _func = nullptr;
    const PhvInfo &phv;

    Visitor::profile_t init_apply(const IR::Node *node) override {
        auto rv = PassManager::init_apply(node);
        _func = nullptr;
        return rv;
    }

    class InsideHashGenExpr : public MauInspector {
        BuildP4HashFunction &self;
        bool inside_expr = false;
        safe_vector<const IR::Expression *> fields;
        LTBitMatrix sym_fields;

        Visitor::profile_t init_apply(const IR::Node *node) override {
            auto rv = MauInspector::init_apply(node);
            fields.clear();
            sym_fields.clear();
            inside_expr = false;
            return rv;
        }
        bool preorder(const IR::Constant *) override;
        bool preorder(const IR::Expression *) override;
        void postorder(const IR::BFN::SignExtend *) override;
        bool preorder(const IR::MAU::ActionArg *) override;
        bool preorder(const IR::Mask *) override;
        bool preorder(const IR::MAU::HashGenExpression *) override;
        bool preorder(const IR::MAU::FieldListExpression *) override;
        bool preorder(const IR::Cast *) override;
        void postorder(const IR::MAU::HashGenExpression *) override;

     public:
        explicit InsideHashGenExpr(BuildP4HashFunction &s) : self(s) {}
    };


    class OutsideHashGenExpr : public MauInspector {
        BuildP4HashFunction &self;
        bool preorder(const IR::MAU::HashGenExpression *) override;
        void postorder(const IR::Slice *) override;

     public:
        explicit OutsideHashGenExpr(BuildP4HashFunction &s) : self(s) {}
    };

    void end_apply() override;

 public:
    explicit BuildP4HashFunction(const PhvInfo &p) : phv(p) {
        addPasses({
            new InsideHashGenExpr(*this),
            new OutsideHashGenExpr(*this)
        });
    }

    P4HashFunction *func() { return _func; }
};

class AdjustIXBarExpression : public MauModifier {
    bool preorder(IR::MAU::IXBarExpression *e) override;
};

#endif /* BF_P4C_MAU_IXBAR_EXPR_H_ */
