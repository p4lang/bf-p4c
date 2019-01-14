#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/mau/dynhash.h"

namespace BFN {

bool DynamicHashJson::preorder(const IR::MAU::Table *tbl) {
    LOG1(" Table: " << tbl->name);
    if (tbl->gateway_only()) return true;
    if (auto res = tbl->resources) {
        Util::JsonObject *_dynHashCalc = new Util::JsonObject();
        if (auto match_table = tbl->match_table->to<IR::P4Table>()) {
            cstring fieldListCalcName = "";
            cstring fieldListName = "";
            IR::NameList algorithms;
            int hash_bit_width = -1;
            LOG5("Annotations : " << match_table->annotations);
            for (auto annot : match_table->annotations->annotations) {
                if (annot->name == "action_selector_hash_field_calc_name")
                    fieldListCalcName = annot->expr[0]->to<IR::StringLiteral>()->value;
                else if (annot->name == "action_selector_hash_field_list_name")
                    fieldListName = annot->expr[0]->to<IR::StringLiteral>()->value;
                else if (annot->name == "action_selector_hash_field_calc_output_width")
                    hash_bit_width = annot->expr[0]->to<IR::Constant>()->asInt();
                else if (annot->name == "algorithm")
                    algorithms.names.push_back(annot->expr[0]->to<IR::StringLiteral>()->value);
            }
            // If none of the above values are populated dont proceed.
            LOG5("fieldListCalcName: " << fieldListCalcName << " fieldListName: "
                    << fieldListName << " hash_bit_width: "
                    << hash_bit_width << "Algo size: " << algorithms.names.size());
            if (!fieldListCalcName.isNullOrEmpty() && !fieldListName.isNullOrEmpty()
                    && (hash_bit_width > 0) && (algorithms.names.size() > 0)) {
                _dynHashCalc->emplace("name", fieldListCalcName);
                _dynHashCalc->emplace("handle", dynHashHandleBase + dynHashHandle++);
                LOG4("Generating dynamic hash schema for "
                        << fieldListCalcName << " and field list " << fieldListName);
                gen_ixbar_json(res->selector_ixbar, _dynHashCalc, tbl->stage(),
                                fieldListName, &algorithms, hash_bit_width);
                _dynHashNode->append(_dynHashCalc);
            }
        }
        auto hash_dists = res->hash_dists;
        for (auto &hash_dist : hash_dists) {
            auto ixbar_use = hash_dist.use;
            Util::JsonObject *_dynHashCalc = new Util::JsonObject();
            if (auto orig_hd = hash_dist.original_hd) {
                if (auto field_list = orig_hd->field_list->to<IR::HashListExpression>()) {
                    if (field_list->fieldListCalcName.isNullOrEmpty()) continue;
                    if (auto field_list_names = field_list->fieldListNames)
                        if (field_list_names->names.empty()) continue;
                    LOG4("Generating dynamic hash schema for "
                            << field_list->fieldListCalcName <<
                            " and field list " << field_list->fieldListNames->names[0]);
                    _dynHashCalc->emplace("name", field_list->fieldListCalcName);
                    _dynHashCalc->emplace("handle", dynHashHandleBase + dynHashHandle++);
                    auto fieldListName = field_list->fieldListNames->names[0];
                    gen_ixbar_json(ixbar_use, _dynHashCalc, tbl->stage(),
                                    fieldListName, field_list->algorithms);
                    _dynHashNode->append(_dynHashCalc);
                    return true;
                }
            }
        }
    }
    return true;
}

void DynamicHashJson::gen_ixbar_json(const IXBar::Use &ixbar_use,
        Util::JsonObject *_dhc, int stage, const cstring field_list_name,
        const IR::NameList *algorithms, int hash_width) {
    Util::JsonArray *_field_lists = new Util::JsonArray();
    Util::JsonObject *_field_list = new Util::JsonObject();
    Util::JsonArray *_fields = new Util::JsonArray();
    _field_list->emplace("name", field_list_name);
    _field_list->emplace("handle", fieldListHandleBase + fieldListHandle++);
    // Multiple field lists not supported,
    // is_default is always true, remove field?
    _field_list->emplace("is_default", true);
    // can_permute & can_rotate need to be passed in (as annotations?) to be set
    // here. these fields are optional in schema
    _field_list->emplace("can_permute", false);
    _field_list->emplace("can_rotate", false);
    int numConstants = 0;
    std::map<cstring, cstring> fieldNames;
    for (auto* field : ixbar_use.field_list_order) {
        Util::JsonObject *_field = new Util::JsonObject();
        cstring name = "";
        auto range = field->range();
        if (field->is<PHV::Constant>()) {
            // Constant fields have unique field names with the format
            // constant<id>_<size>_<value>
            // id increments by 1 for every constant field.
            name = "constant" + std::to_string(numConstants++);
            name = name + "_" + std::to_string(range.size());
            name = name + "_" + field->to<PHV::Constant>()->value->toString();
        } else if (field->field()) {
            name = canon_name(field->field()->externalName());
            fieldNames[field->field()->name] = name;
        } else {
            continue;  // error out here?
        }
        _field->emplace("name", name);
        _field->emplace("start_bit", range.lo);
        _field->emplace("bit_width", range.size());
        // All fields optional by default, remove field?
        _field->emplace("optional", true);
        _field->emplace("is_constant", field->is<PHV::Constant>());
        _fields->append(_field);
    }
    _field_list->emplace("fields", _fields);
    Util::JsonArray *_xbar_cfgs = new Util::JsonArray();
    Util::JsonObject *_xbar_cfg = new Util::JsonObject();
    _xbar_cfg->emplace("stage_number", stage);
    Util::JsonArray *_xbar = new Util::JsonArray();
    for (auto &byte : ixbar_use.use) {
        for (auto &fieldinfo : byte.field_bytes) {
            for (int i = fieldinfo.lo; i <= fieldinfo.hi; i++) {
                Util::JsonObject *_xbar_byte = new Util::JsonObject();
                _xbar_byte->emplace("byte_number", (byte.loc.group * 16 + byte.loc.byte));
                _xbar_byte->emplace("bit_in_byte", (i - fieldinfo.lo));
                _xbar_byte->emplace("name", fieldNames[fieldinfo.field]);
                _xbar_byte->emplace("field_bit", i);
                _xbar->append(_xbar_byte);
            }
        }
    }
    _xbar_cfg->emplace("crossbar", _xbar);
    // TODO: Add wide hash support to populate 'crossbar_mod'
    _xbar_cfg->emplace("crossbar_mod", new Util::JsonArray());
    _xbar_cfgs->append(_xbar_cfg);
    _field_list->emplace("crossbar_configuration", _xbar_cfgs);
    _field_lists->append(_field_list);
    _dhc->emplace("field_lists", _field_lists);
    IR::MAU::HashFunction *hashAlgo = nullptr;
    int hashGroup = -1;
    Util::JsonArray *_hash_bits = new Util::JsonArray();
    int num_hash_bits = 0;
    int hash_bit_width = -1;
    if (ixbar_use.hash_dist_hash.allocated) {
        auto hdh = ixbar_use.hash_dist_hash;
        hashAlgo = &hdh.algorithm;
        hashGroup = hdh.group;
        hash_bit_width = hashAlgo->size;
        // calculate the output hash bits from a hash table
        for (auto &b : hdh.bit_starts) {
            auto hash_bit = b.first;
            num_hash_bits = b.second.size();
            for (auto bit = b.second.lo; bit <= b.second.hi; bit++) {
                Util::JsonObject *_hash_bit = new Util::JsonObject();
                _hash_bit->emplace("gfm_hash_bit", hash_bit++);
                _hash_bit->emplace("p4_hash_bit", bit);
                _hash_bits->append(_hash_bit);
            }
        }
    } else if (ixbar_use.meter_alu_hash.allocated) {
        auto mah = ixbar_use.meter_alu_hash;
        hashAlgo = &mah.algorithm;
        hashGroup = mah.group;
        // hash_bit_width = hashAlgo->size;
        hash_bit_width = hash_width;
        num_hash_bits = mah.bit_mask.is_contiguous() && (mah.bit_mask.min().index() == 0) ?
                            mah.bit_mask.max().index() + 1 : 0;
        if (!num_hash_bits) return;  // invalid bit mask
        for (auto hash_bit = 0; hash_bit < num_hash_bits; hash_bit++) {
            Util::JsonObject *_hash_bit = new Util::JsonObject();
            _hash_bit->emplace("gfm_hash_bit", hash_bit);
            _hash_bit->emplace("p4_hash_bit", hash_bit);
            _hash_bits->append(_hash_bit);
        }
    }
    // any_hash_algorithm_allowed is an optional field
    _dhc->emplace("any_hash_algorithm_allowed", false);
    Util::JsonArray *_algos = new Util::JsonArray();
    if (algorithms) {
        bool is_default = true;
        for (auto a : algorithms->names) {
            // Call Dyn Hash Library and generate a hash function object for
            // given algorithm
            auto algoExpr = IR::MAU::HashFunction::convertHashAlgorithmBFN(
                    hashAlgo->srcInfo, a.name, nullptr);
            auto algorithm = new IR::MAU::HashFunction();
            if (algorithm->setup(algoExpr)) {
                Util::JsonObject *_algo = new Util::JsonObject();
                _algo->emplace("name", a);  // p4 algo name
                _algo->emplace("type", algorithm->algo_type());
                unsigned aHandle = algoHandleBase + algoHandle;
                if (algoHandles.count(a) > 0) {
                    aHandle = algoHandles[a];
                } else {
                    algoHandles[a] = aHandle;
                    algoHandle++;
                }
                _algo->emplace("handle", aHandle);
                _algo->emplace("is_default", is_default);
                _algo->emplace("msb", algorithm->msb);
                _algo->emplace("extend", algorithm->extend);
                _algo->emplace("reverse", algorithm->reverse);
                // Convert poly in koopman notation to actual value
                mpz_class poly, init, final_xor;
                mpz_import(poly.get_mpz_t(), 1, 0, sizeof(algorithm->poly), 0, 0, &algorithm->poly);
                poly = (poly << 1) + 1;
                _algo->emplace("poly", "0x" + poly.get_str(16));
                mpz_import(init.get_mpz_t(), 1, 0, sizeof(algorithm->init), 0, 0, &algorithm->init);
                _algo->emplace("init", "0x" + init.get_str(16));
                mpz_import(final_xor.get_mpz_t(), 1, 0, sizeof(algorithm->final_xor),
                                                                    0, 0, &algorithm->final_xor);
                _algo->emplace("final_xor", "0x" + final_xor.get_str(16));
                _algos->append(_algo);
                is_default = false;  // only set 1st algo to default
            }
        }
    }
    _dhc->emplace("algorithms", _algos);
    Util::JsonArray *_hash_cfgs = new Util::JsonArray();
    Util::JsonObject *_hash_cfg = new Util::JsonObject();
    _hash_cfg->emplace("stage_number", stage);
    Util::JsonObject *_hash = new Util::JsonObject();
    _hash->emplace("hash_id", hashGroup);
    _dhc->emplace("hash_bit_width", hash_bit_width);
    _hash->emplace("num_hash_bits", num_hash_bits);
    _hash->emplace("hash_bits", _hash_bits);
    _hash_cfg->emplace("hash", _hash);
    // TODO: Add wide hash support to populate 'hash_mod'
    Util::JsonObject *_hash_mod = new Util::JsonObject();
    _hash_mod->emplace("hash_id", 0);
    _hash_mod->emplace("num_hash_bits", 0);
    _hash_mod->emplace("hash_bits", new Util::JsonArray());
    _hash_cfg->emplace("hash_mod", _hash_mod);
    _hash_cfgs->append(_hash_cfg);
    _dhc->emplace("hash_configuration", _hash_cfgs);
}

std::ostream &operator<<(std::ostream &out, const DynamicHashJson &dyn) {
    auto dyn_json = new Util::JsonObject();
    if (dyn._dynHashNode)
        dyn_json->emplace("dynamic_hash_calculations", dyn._dynHashNode);
    else
        dyn_json->emplace("dynamic_hash_calculations", new Util::JsonObject());
    dyn_json->serialize(out);
    return out;
}

DynamicHashJson::DynamicHashJson() {
    _dynHashNode = new Util::JsonArray();
}

}  // namespace BFN
