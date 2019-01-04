#include "bf-p4c/common/asm_output.h"
#include "bf-p4c/mau/dynhash.h"

namespace BFN {

bool DynamicHashJson::preorder(const IR::MAU::Table *tbl) {
    LOG1(" Table: " << tbl->name);
    if (auto res = tbl->resources) {
        auto hash_dists = res->hash_dists;
        for (auto &hash_dist : hash_dists) {
            auto ixbar_use = hash_dist.use;
            Util::JsonObject *_dynHashCalc = new Util::JsonObject();
            if (auto orig_hd = hash_dist.original_hd) {
                if (orig_hd->field_list_calc_name.isNullOrEmpty()
                    || orig_hd->field_list_name.isNullOrEmpty())
                    continue;
                LOG4("Generating dynamic hash schema for "
                        << orig_hd->field_list_calc_name <<
                        " and field list " << orig_hd->field_list_name);
                _dynHashCalc->emplace("name", orig_hd->field_list_calc_name);
                _dynHashCalc->emplace("handle", dynHashHandleBase + dynHashHandle++);
                gen_ixbar_json(ixbar_use, _dynHashCalc, tbl->stage(), orig_hd->field_list_name);
                _dynHashNode->append(_dynHashCalc);
            }
        }
    }
    return false;
}

void DynamicHashJson::gen_ixbar_json(const IXBar::Use &ixbar_use,
        Util::JsonObject *_dhc, int stage, cstring fl_name) {
    Util::JsonArray *_field_lists = new Util::JsonArray();
    Util::JsonObject *_field_list = new Util::JsonObject();
    Util::JsonArray *_fields = new Util::JsonArray();
    // Generate unique field list names based on field list handle. The field
    // list name as specified in p4 is not accessible here. Glass generates the
    // field list name as a combination of p4 field list name and a bit mask
    // specifying which fields are not optional.
    // e.g. f1_1_011 (field list name = f1_1, mask = 011 first field is optional
    // rest are not)
    // With new schema this may not be required?
    // _field_list->emplace("name", "field_list_" + std::to_string(fieldListHandle));
    _field_list->emplace("name", fl_name);
    _field_list->emplace("handle", fieldListHandleBase + fieldListHandle++);
    // Multiple field lists not supported,
    // is_default is always true, remove field?
    _field_list->emplace("is_default", true);
    // can_permute & can_rotate need to be passed in (as annotations?) to be set
    // here. these fields are optional in schema
    _field_list->emplace("can_permute", false);
    _field_list->emplace("can_rotate", false);
    int numConstants = 0;
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
            name = canon_name(field->field()->name);
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
                _xbar_byte->emplace("name", canon_name(fieldinfo.field));
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
    if (ixbar_use.hash_dist_hash.allocated) {
        auto hdh = ixbar_use.hash_dist_hash;
        // any_hash_algorithm_allowed is an optional field
        _dhc->emplace("any_hash_algorithm_allowed", false);
        auto algorithm = hdh.algorithm;
        Util::JsonArray *_algos = new Util::JsonArray();
        Util::JsonObject *_algo = new Util::JsonObject();
        _algo->emplace("name", algorithm.name());
        _algo->emplace("type", algorithm.algo_type());
        _algo->emplace("handle", algoHandleBase + algoHandle++);
        _algo->emplace("is_default", true);
        _algo->emplace("msb", algorithm.msb);
        _algo->emplace("extend", algorithm.extend);
        _algo->emplace("reverse", algorithm.reverse);
        std::stringstream poly;
        poly << std::hex << (algorithm.poly << 1) + 1;
        _algo->emplace("poly", "0x" + poly.str());
        std::stringstream init;
        init << std::hex << algorithm.init;
        _algo->emplace("init", "0x" + init.str());
        std::stringstream final_xor;
        final_xor << std::hex << algorithm.final_xor;
        _algo->emplace("final_xor", "0x" + final_xor.str());
        _algos->append(_algo);
        _dhc->emplace("algorithms", _algos);
        Util::JsonArray *_hash_cfgs = new Util::JsonArray();
        Util::JsonObject *_hash_cfg = new Util::JsonObject();
        _hash_cfg->emplace("stage_number", stage);
        Util::JsonObject *_hash = new Util::JsonObject();
        _hash->emplace("hash_id", hdh.group);
        Util::JsonArray *_hash_bits = new Util::JsonArray();
        // calculate the output hash bits from a hash table
        int num_hash_bits = 0;
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
        // auto hash_table_input = ixbar_use.hash_table_inputs[hdh.group];
        // auto num_hash_tables = bitvec(hash_table_input).popcount();
        // auto hash_bit_width = num_hash_bits * num_hash_tables;
        // _dhc->emplace("hash_bit_width", hash_bit_width);
        _dhc->emplace("hash_bit_width", algorithm.size);
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
}

std::ostream &operator<<(std::ostream &out, const DynamicHashJson &dyn) {
    auto dyn_json = new Util::JsonObject();
    // TODO: Will be reverted to the original 'dynamic_hash_calculation' once
    // this node is tested with driver
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
