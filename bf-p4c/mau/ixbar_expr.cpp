#include "common/slice.h"
#include "input_xbar.h"
#include "ixbar_expr.h"
#include "resource.h"


void P4HashFunction::slice(le_bitrange hash_slice) {
    le_bitrange shifted_hash_bits = hash_slice.shiftedByBits(hash_bits.lo);
    BUG_CHECK(hash_bits.contains(shifted_hash_bits), "Slice over hash function is not able "
            "to be resolved");
    hash_bits = shifted_hash_bits;
}


/**
 * Much tighter than the actual constraint, as things like identity functions could check
 * for better overlaps as well as random functions wouldn't matter in terms of order, but this
 * can be expanded much later on.  This will work quickly for dynamic hashing
 */
bool P4HashFunction::equiv(const P4HashFunction *func) const {
    if (dyn_hash_name != func->dyn_hash_name)
        return false;
    if (algorithm != func->algorithm)
        return false;
    if (hash_bits != func->hash_bits)
        return false;
    if (inputs.size() != func->inputs.size())
        return false;
    for (size_t i = 0; i < inputs.size(); i++)
        if (!inputs[i]->equiv(*func->inputs[i]))
            return false;
    return true;
}

bool BuildP4HashFunction::InsideHashGenExpr::preorder(const IR::MAU::HashGenExpression *) {
    inside_expr = true;
    return true;
}

bool BuildP4HashFunction::InsideHashGenExpr::preorder(const IR::MAU::ActionArg *aa) {
    ::error("%s: Action Data Argument %s cannot be used in a hash generation expression.  "
            "Data plane values and constants only", aa->srcInfo, aa->name);
    return false;
}

bool BuildP4HashFunction::InsideHashGenExpr::preorder(const IR::Constant *con) {
    fields.emplace_back(con);
    return false;
}

bool BuildP4HashFunction::InsideHashGenExpr::preorder(const IR::Mask *mask) {
    BUG("%s: Masks not supported by Tofino Backend for hash functions", mask->srcInfo);
    return false;
}

bool BuildP4HashFunction::InsideHashGenExpr::preorder(const IR::Cast *) {
    return true;
}

bool BuildP4HashFunction::InsideHashGenExpr::preorder(const IR::Expression *expr) {
    if (!inside_expr)
        return true;
    if (self.phv.field(expr)) {
        fields.emplace_back(expr);
        return false;
    }
    return true;
}

void BuildP4HashFunction::InsideHashGenExpr::postorder(const IR::BFN::SignExtend *se) {
    BUG_CHECK(!fields.empty(), "SignExtend on nonexistant field");
    auto expr = se->expr;
    while (auto c = expr->to<IR::Cast>())
        expr = c->expr;

    BUG_CHECK(fields.back() == expr, "SignExtend mismatch");
    int size = expr->type->width_bits();
    for (int i = se->type->width_bits(); i > size; --i) {
        fields.insert(fields.end() - 1, MakeSlice(expr, size - 1, size - 1));
    }
}

void BuildP4HashFunction::InsideHashGenExpr::postorder(const IR::MAU::HashGenExpression *hge) {
    inside_expr = false;
    self._func = new P4HashFunction();
    self._func->inputs = fields;
    self._func->hash_bits = { 0, hge->type->width_bits() - 1 };
    self._func->algorithm = hge->algorithm;
    if (hge->dynamic)
        self._func->dyn_hash_name = hge->id.name;
}


bool BuildP4HashFunction::OutsideHashGenExpr::preorder(const IR::MAU::HashGenExpression *) {
    return false;
}

void BuildP4HashFunction::OutsideHashGenExpr::postorder(const IR::Slice *sl) {
    if (self._func == nullptr)
        return;

    le_bitrange slice_bits = { static_cast<int>(sl->getL()), static_cast<int>(sl->getH()) };
    slice_bits = slice_bits.shiftedByBits(self._func->hash_bits.lo);

    BUG_CHECK(self._func->hash_bits.contains(slice_bits), "%s: Slice over hash function is "
        "not able to be resolved");
    self._func->hash_bits = slice_bits;
}

/**
 * FIXME: This is a crappy hack for dynamic hash to work.  If a table has repeated values, then
 * the dynamic hash function is not correct.  We should just fail, however, just failing would
 * cause the dyn_hash test to not compile, as these field lists get combined into one large
 * field list in the p4-14 to p4-16 converter.  This is a temporary workaround
 */
void BuildP4HashFunction::end_apply() {
    bool repeats_allowed = !_func->is_dynamic() &&
                            _func->algorithm.type != IR::MAU::HashFunction::CRC;
    LOG1("  help me " << _func->dyn_hash_name << " " << repeats_allowed);
    if (repeats_allowed)
        return;
    std::map<cstring, bitvec> field_list_check;
    for (auto it = _func->inputs.begin(); it != _func->inputs.end(); it++) {
        le_bitrange bits;
        auto field = phv.field(*it, &bits);
        if (field == nullptr)
            continue;

        bitvec used_bits(bits.lo, bits.size());

        bitvec overlap;
        if (field_list_check.count(field->name) > 0)
            overlap = field_list_check.at(field->name) & used_bits;
        if (!overlap.empty()) {
            if (overlap == used_bits) {
                it = _func->inputs.erase(it);
                it--;
            } else {
                ::error("Overlapping field %s in hash not supported with the hashing algorithm",
                    field->name);
            }
        }
        field_list_check[field->name] |= used_bits;
    }
}

bool AdjustIXBarExpression::preorder(IR::MAU::IXBarExpression *e) {
    auto *tbl = findContext<IR::MAU::Table>();
    for (auto &ce : tbl->resources->salu_ixbar.meter_alu_hash.computed_expressions) {
        if (e->expr->equiv(*ce.second)) {
            e->bit = ce.first;
            return false; } }
     if (findContext<IR::MAU::HashDist>())
         return false;
    BUG("Can't find %s in the ixbar allocation for %s", e->expr, tbl);
    return false;
}

