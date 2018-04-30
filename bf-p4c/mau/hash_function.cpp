#include "ir/ir.h"
#include "ir/json_loader.h"
#include "lib/hex.h"

bool IR::MAU::hash_function::setup(const IR::Expression *e) {
    memset(this, 0, sizeof *this);
    srcInfo = e->srcInfo;
    size = 0;
    if (auto m = e->to<IR::Member>()) {
        if (m->member == "identity" || m->member == "IDENTITY") {
            type = IDENTITY;
        } else if (m->member == "csum16" || m->member == "CSUM16") {
            type = CSUM;
            size = 16;
        } else if (m->member == "xor16" || m->member == "XOR16") {
            type = XOR;
            size = 16;
        } else if (m->member == "random" || m->member == "RANDOM") {
            type = RANDOM;
        } else if (m->member == "crc16" || m->member == "crc16_custom" || m->member == "CRC16") {
            type = CRC;
            size = 16;
            poly = 0x8fdb;
        } else if (m->member == "crc32" || m->member == "crc32_custom" || m->member == "CRC32") {
            type = CRC;
            size = 32;
            poly = 0xe89061db;
        } else {
            return false; }
        return true; }
    const IR::Vector<IR::Argument> *crcargs = nullptr;
    if (auto mc = e->to<IR::MethodCallExpression>()) {
        if (auto meth = mc->method->to<IR::PathExpression>())
            if (meth->path->name == "crc_poly")
                crcargs = mc->arguments;
    } else if (auto prim = e->to<IR::Primitive>()) {
        if (prim->name == "crc_poly") {
            auto ops = new IR::Vector<IR::Argument>();
            for (auto op : prim->operands) {
                ops->push_back(new IR::Argument(op));
            }
            crcargs = ops;
        }
    }
    if (crcargs) {
        type = CRC;
        switch (crcargs->size()) {
        case 5:
            if (auto k = crcargs->at(4)->expression->to<IR::Constant>())
                final_xor = k->value.get_ui();
            else
                return false;
            // fall through
        case 4:
            if (auto k = crcargs->at(3)->expression->to<IR::Constant>())
                init = k->value.get_ui();
            else
                return false;
            // fall through
        case 3:
            if (auto k = crcargs->at(2)->expression->to<IR::BoolLiteral>())
                msb = k->value;
            else
                return false;
            // fall through
        case 2:
            if (auto k = crcargs->at(1)->expression->to<IR::BoolLiteral>())
                reverse = k->value;
            else
                return false;
            // fall through
        case 1:
            if (auto k = crcargs->at(0)->expression->to<IR::Constant>())
                poly = mpz_class(k->value / 2).get_ui();
            else
                return false;
            break;
        default:
            return false; }
        return true; }
    return false;
}

std::ostream &operator<<(std::ostream &out, const IR::MAU::hash_function &h) {
    switch (h.type) {
    case IR::MAU::hash_function::IDENTITY:
        out << "identity";
        break;
    case IR::MAU::hash_function::CSUM:
        out << "csum" << h.size;
        break;
    case IR::MAU::hash_function::XOR:
        out << "xor" << h.size;
        break;
    case IR::MAU::hash_function::CRC:
        out << "crc(0x" << hex(h.poly);
        if (h.init)
            out << " init=0x" << hex(h.init);
        out << ")";
        if (h.final_xor)
            out << "^" << hex(h.final_xor);
        break;
    case IR::MAU::hash_function::RANDOM:
        out << "random";
        break;
    default:
        out << "invalid(0x" << hex(h.type) << ")";
        break; }
    return out;
}

void IR::MAU::hash_function::toJSON(JSONGenerator &json) const {
    json << json.indent << "\"type\": " << static_cast<int>(type) << ",\n"
         << json.indent << "\"size\": " << size << ",\n"
         << json.indent << "\"msb\": " << msb << ",\n"
         << json.indent << "\"reverse\": " << reverse << ",\n"
         << json.indent << "\"poly\": " << poly << ",\n"
         << json.indent << "\"init\": " << init << ",\n"
         << json.indent << "\"xor\": " << final_xor << ",\n";
}

IR::MAU::hash_function *IR::MAU::hash_function::fromJSON(JSONLoader &json) {
    if (!json.json) return nullptr;
    auto *rv = new hash_function;
    int type;
    json.load("type", type);
    rv->type = static_cast<decltype(rv->type)>(type);
    json.load("size", rv->size);
    json.load("msb", rv->msb);
    json.load("reverse", rv->reverse);
    json.load("poly", rv->poly);
    json.load("init", rv->init);
    json.load("xor", rv->final_xor);
    return rv;
}
