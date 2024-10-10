#include "match_register.h"

#include <sstream>
#include "ir/ir.h"
#include "ir/json_generator.h"
#include "ir/json_loader.h"

#if HAVE_FLATROCK
#include "bf-p4c/common/flatrock.h"
#endif

int MatchRegister::s_id = 0;

cstring MatchRegister::toString() const {
    std::stringstream tmp;
    tmp << *this;
    return tmp.str();
}

MatchRegister::MatchRegister() : name(""), size(0), id(0) {
}

MatchRegister::MatchRegister(cstring n) : name(n), id(s_id++) {
    if (name.find("byte"))
        size = 1;
    else if (name.find("half"))
        size = 2;
#if HAVE_FLATROCK
    else if (name.find("W"))
        size = ::Flatrock::PARSER_W_WIDTH;
#endif
    else
        BUG("Invalid parser match register %s", name);
}

void MatchRegister::toJSON(JSONGenerator& json) const {
    json << *this;
}

/* static */
MatchRegister MatchRegister::fromJSON(JSONLoader& json) {
    if (auto* v = json.json->to<JsonString>())
        return MatchRegister(cstring(v->c_str()));
    BUG("Couldn't decode JSON value to parser match register");
    return MatchRegister();
}

P4::JSONGenerator& operator<<(P4::JSONGenerator& out, const MatchRegister& c) {
    return out << c.toString();
}
