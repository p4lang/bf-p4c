#include "bf-p4c/ir/unique_id.h"

static const char *attached_id_to_str[] = {
    "", "tind", "idletime", "stats", "meter", "selector", "salu", "action_data"
};

static const char *speciality_to_str[] = {
    "", "atcam", "dleft"
};


std::string UniqueAttachedId::build_name() const {
    std::string rv = "";
    if (type == INVALID)
        return rv;
    rv += attached_id_to_str[type];
    if (name_valid())
        rv += "." + name;
    return rv;
}

bool UniqueId::operator==(const UniqueId &ui) const {
    return name == ui.name &&
           stage_table == ui.stage_table &&
           logical_table == ui.logical_table &&
           is_gw == ui.is_gw &&
           speciality == ui.speciality &&
           a_id == ui.a_id;
}

bool UniqueId::operator<(const UniqueId &ui) const {
    if (name != ui.name)
        return name < ui.name;
    if (stage_table != ui.stage_table)
        return stage_table < ui.stage_table;
    if (logical_table != ui.logical_table)
        return logical_table < ui.logical_table;
    if (is_gw != ui.is_gw)
        return is_gw < ui.is_gw;
    if (speciality != ui.speciality)
        return speciality < ui.speciality;
    if (a_id != ui.a_id)
        return a_id < ui.a_id;
    return false;
}

bool UniqueId::equal_table(const UniqueId &ui) const {
    return name == ui.name &&
           stage_table == ui.stage_table &&
           logical_table == ui.logical_table &&
           speciality == ui.speciality;
}

std::string UniqueId::build_name() const {
    std::string rv = "";
    rv += name + "";
    if (speciality != NONE) {
        rv += "$";
        rv += speciality_to_str[static_cast<int>(speciality)];
    }
    if (logical_table_used())
       rv += "$lt" + std::to_string(logical_table);
    if (stage_table_used())
        rv += "$st" + std::to_string(stage_table);
    if (is_gw)
        rv += "$gw";
    if (a_id)
        rv += "$" + a_id.build_name();
    return rv;
}

std::ostream &operator <<(std::ostream &out, const UniqueId &ui) {
    out << ui.build_name();
    return out;
}
