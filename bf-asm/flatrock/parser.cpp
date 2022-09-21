#include "flatrock/parser.h"

#include <cstring>
#include <string>
#include <unordered_map>

#include "bitvec.h"
#include "flatrock/hdr.h"
#include "misc.h"
#include "phv.h"
#include "target.h"
#include "top_level.h"

namespace {

void report_invalid_directive(const char *message, value_t key) {
    std::string key_name(": ");
    if (key.type == tSTR) {
        key_name += key.s;
    } else if (key.type == tCMD && key.vec.size > 0 && key[0].type == tSTR) {
        key_name += key[0].s;
    } else {
        key_name = "";
    }
    error(key.lineno, "%s%s", message, key_name.c_str());
}

bool input_match_constant(match_t &target, const value_t value, int bit_width) {
    if (!CHECKTYPE3(value, tINT, tBIGINT, tMATCH)) return false;
    return input_int_match(value, target, bit_width);
}

bool input_boolean(bool &target, const value_t value) {
    if (!CHECKTYPE(value, tSTR)) return false;
    if (value == "true") {
        target = true;
        return true;
    } else if (value == "false") {
        target = false;
        return true;
    } else {
        error(value.lineno, "invalid boolean literal: %s", value.s);
        return false;
    }
}

void input_phv_builder_group(PhvBuilderGroup *phv_builder, int phv_builder_size,
        VECTOR(value_t) args, value_t key, value_t value) {
    if (key.type == tSTR) {
        /* -- The key is just one string, no parameters. This could be handled by
         *    CHECKTYPE macro, but we check it here to have more specific error message. */
        error(key.lineno, "number of PHV builder group is missing");
        return;
    }
    if (!CHECKTYPE(key, tCMD))
        return;
    if (key.vec.size < 2) {
        error(key.lineno, "number of PHV builder group is missing");
        return;
    }
    if (key.vec.size > 2) {
        error(key.lineno, "too many parameters of the phv_builder_group directive");
        return;
    }
    if (!check_range(key[1], 0, phv_builder_size - 1))
        return;
    const int group_id = key[1].i;
    phv_builder[group_id].input(args, key.lineno, group_id, value);
}

}  // namespace

bool check_range_state_subfield(value_t msb, value_t lsb, bool only8b) {
    /* -- The LSB equals the offset operand in the instruction. There are just 6 bits for
     *    the offset, hence the offset might be in the range <0, 63>. Two bits of the
     *    len operand can define subfield widths 2/4/8/16 bits. That means the MSB
     *    can be in the range <min{LSB} + min{len} - 1, max{LSB} + max{len} - 1>,
     *    i.e. <1, 78>. */
    if (!check_range(msb, 1, Target::Flatrock::PARSER_STATE_WIDTH * 8 - 2)) return false;
    if (!check_range(lsb, 0, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8 - 1)) return false;
    int _width = msb.i - lsb.i + 1;
    if (only8b) {
        if (_width != 8) {
            error(msb.lineno, "width of the sub-state field must be 8 bits");
            return false;
        }
    } else if (_width != 16 && _width != 8 && _width != 4 && _width != 2) {
        error(msb.lineno, "width of the sub-state field must be 16, 8, 4, or 2 bits");
        return false;
    }
    return true;
}

bool PovSelect::input(value_t data) {
    if (!CHECKTYPE(data, tVEC))
        return false;
    if (data.vec.size > Target::Flatrock::PARSER_POV_SELECT_NUM) {
        error(data.lineno, "invalid number of POV bytes specified: %d, valid: 0-%d",
                data.vec.size, Target::Flatrock::PARSER_POV_SELECT_NUM);
        return false;
    }

    bool ok = true;

    for (int i = 0; i < data.vec.size; ++i) {
        if (!CHECKTYPE(data.vec[i], tCMD)) {
            ok = false;
            continue;
        }
        if (data.vec[i].vec.size != 2) {
            error(data.vec[i].lineno, "invalid POV byte specification");
            ok = false;
            continue;
        }

        if (data.vec[i] == "flags") {
            key[i].src = PovSelectKey::FLAGS;
        } else if (data.vec[i] == "state") {
            key[i].src = PovSelectKey::STATE;
        } else {
            error(data.vec[i].lineno, "invalid POV byte specification");
            ok = false;
            continue;
        }
        if (!check_range(data.vec[i].vec[1], 0, 0x7)) {
            ok = false;
            continue;
        }
        key[i].start = data.vec[i].vec[1].i;
        key[i].used = true;
    }
    return ok;
}

#define MATCH_CONSTANT_BYTE(word, byte_offset) \
        (((word) & (0xffULL << ((byte_offset) * 8))) >> ((byte_offset) * 8))

bool PovSelect::check_match(const match_t match) const {
    for (int i = 0; i < Target::Flatrock::PARSER_POV_SELECT_NUM; ++i) {
        if (!key[i].used && (MATCH_CONSTANT_BYTE(match.word0, i) != 0xffULL ||
                MATCH_CONSTANT_BYTE(match.word1, i) != 0xffULL))
            return false;
    }
    return true;
}

bool PhvBuilderGroup::check_register(value_t reg_name, int phe_source_id,
        int slice_size, bitvec &used_regs, int &val_index) {
    Phv::Ref reg_ref(gress, 0, reg_name);
    if (!reg_ref.check()) {
        error(reg_name.lineno, "invalid register for other PHE source");
        return false;
    }

    int reg_min = *group_id * 8 + phe_source_id * 4;
    int reg_max = reg_min + 3;
    int reg_id = reg_ref->reg.parser_id();
    int slice_id = reg_ref.lobit() / slice_size;

    if (reg_id < reg_min || reg_id > reg_max) {
        error(reg_name.lineno, "invalid register for group %d and PHE source %d",
                *group_id, phe_source_id);
        return false;
    }
    if (reg_ref.lobit() % slice_size != 0 || reg_ref.size() != slice_size) {
        error(reg_name.lineno,
                "invalid register slice, slice has to be aligned to %d bits with size %d",
                slice_size, slice_size);
        return false;
    }
    if (used_regs.getbit(reg_id + slice_id)) {
        error(reg_name.lineno, "same register/slice can not be used multiple times");
        return false;
    }
    used_regs.setbit(reg_id + slice_id);
    val_index = ((reg_id - reg_min) / (slice_size / 8)) + slice_id;
    return true;
}

bool PhvBuilderGroup::check_gress(OtherInputConfig &config, value_t value) {
    bool ok = true;
    const char *parser_str;
    switch (config.where_valid) {
    case PARSER:
        ok = (gress == INGRESS);
        parser_str = "parser";
        break;
    case PSEUDO_PARSER:
        ok = (gress == EGRESS);
        parser_str = "pseudo parser";
        break;
    }
    if (!ok)
        error(value.lineno, "%s is not valid in %s", value.s, parser_str);
    return ok;
}

bool PhvBuilderGroup::input_other_phe_source(VECTOR(value_t) args,
        Extract::PheSource& phe_source, const int phe_source_id, value_t data) {
    if (!CHECKTYPE(data, tMAP))
        return false;
    if (data.map.size > Target::Flatrock::PARSER_PHV_BUILDER_OTHER_PHE_SOURCES) {
        error(data.lineno, "%d values exceed limit of %d other type values allowed per PHE source",
                data.map.size, Target::Flatrock::PARSER_PHV_BUILDER_OTHER_PHE_SOURCES);
        return false;
    }

    /* -- initialize all slots for other type to NONE in case they were not set */
    for (int j = 0; j < Target::Flatrock::PARSER_PHV_BUILDER_OTHER_PHE_SOURCES; ++j) {
        phe_source.other[j] = {other_subtype::NONE, 0};
    }

    static std::unordered_map<std::string, OtherInputConfig> other_source_input_config = {
        {"constant",  {0xff, BOTH, CONSTANT}},
        {"pov_flags", {0x07, BOTH, POV_FLAGS}},
        {"pov_state", {0x07, BOTH, POV_STATE}},
        {"ghost",     {0x07, PARSER, GHOST}},
        {"udf0",      {0x07, PARSER, UDF0}},
        {"udf1",      {0x07, PARSER, UDF1}},
        {"udf2",      {0x07, PARSER, UDF2}},
        {"udf3",      {0x07, PARSER, UDF3}},
        {"tm",        {0x1f, PSEUDO_PARSER, TM}},
        {"bridge",    {0x3f, PSEUDO_PARSER, BRIDGE}},
    };

    bitvec used_regs;
    bool ok = true;
    for (auto &kv : MapIterChecked(data.map, true)) {
        /* -- Check register if it is in correct PHV builder group and correct PHE
         *    source and if it hasn't been used yet. */
        int index;
        if (!check_register(kv.key, phe_source_id, 8, used_regs, index)) {
            ok = false;
            continue;
        }

        if (!CHECKTYPE2(kv.value, tCMD, tSTR)) {
            ok = false;
            continue;
        }

        if (kv.value.type == tSTR) {
            if (kv.value == "none") {
                /* -- phe source type was initialized to NONE, no need to set it here */
            } else if (kv.value == "checksum_and_error") {
                if (gress != INGRESS) {
                    error(kv.value.lineno, "checksum_and_error is valid only in parser");
                    ok = false;
                    continue;
                }
                phe_source.other[index].subtype = other_subtype::CHKSUM_ERROR;
            } else {
                error(kv.value.lineno, "invalid other type");
                ok = false;
                continue;
            }
        } else if (kv.value.vec.size == 2 && kv.value.vec[0].type == tSTR) {
            /* -- tCMD */
            std::string source_subtype{kv.value.vec[0].s};
            if (other_source_input_config.count(source_subtype)) {
                auto &source = other_source_input_config.at(source_subtype);
                if (!check_range(kv.value.vec[1], 0, source.max) ||
                        !check_gress(source, kv.value.vec[0])) {
                    ok = false;
                    continue;
                }
                phe_source.other[index].subtype = source.subtype;
                phe_source.other[index].value = kv.value.vec[1].i;
            } else {
                error(kv.value.lineno, "invalid other type");
                ok = false;
                continue;
            }
        } else {
            error(kv.value.lineno, "incorrect syntax of other type PHE source value");
            ok = false;
            continue;
        }
    }
    phe_source.type = Extract::PheSource::OTHER_SOURCE;
    return ok;
}

bool PhvBuilderGroup::input_packet_phe_source(VECTOR(value_t) args,
        Extract::PheSource& phe_source, const int phe_source_id, value_t data) {
    if (data.vec.size < 3) {
        /* -- Size should be 3 for 'packet8' and 'packet16' and 5 or 6 for
         *    'packet32'. */
        error(data.lineno, "invalid packet PHE source");
        return false;
    }

    if (!CHECKTYPE2(data.vec[1], tSTR, tINT))
        return false;
    value_t hdr_id;
    if (data.vec[1].type == tSTR) {
        hdr_id.type = tINT;
        hdr_id.i = Hdr::id(data.vec[1].lineno, data.vec[1].s);
    } else {
        /* -- tINT */
        hdr_id = data.vec[1];
    }
    if (!check_range(hdr_id, 0, 0xff))
        return false;

    bool ok = true;

    auto &packet_phe = data.vec[0];
    if (packet_phe == "packet8") {
        if (*group_id < Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_MIN ||
                *group_id > Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_MAX) {
            error(packet_phe.lineno,
                    "PHV builder group %d invalid for PHE8 packet source (valid %d-%d)",
                    *group_id, Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_MIN,
                    Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE8_MAX);
            return false;
        }
        if (data.vec.size != 3) {
            error(packet_phe.lineno, "invalid packet8 PHE source");
            return false;
        }
        if (!CHECKTYPE(data.vec[2], tVEC))
            return false;
        auto &offsets = data.vec[2];
        if (offsets.vec.size < 1 || offsets.vec.size > 4) {
            error(packet_phe.lineno,
                    "invalid number (%d) of packet8 PHE source values (valid 1-4)",
                    offsets.vec.size);
            return false;
        }
        for (int i = 0; i < Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES; ++i) {
            phe_source.packet8.offset[i] = 0;
        }
        bitvec used_regs;
        for (int i = 0; i < offsets.vec.size; ++i) {
            if (!CHECKTYPE(offsets.vec[i], tCMD)) {
                ok = false;
                continue;
            }
            if (offsets.vec[i].vec.size != 3) {
                error(offsets.vec[i].lineno, "invalid packet8 offset specification");
                ok = false;
                continue;
            }
            /* -- Check register if it is in correct PHV builder group and correct PHE
             *    source and if it hasn't been used yet. */
            int index;
            if (!check_register(offsets.vec[i].vec[0], phe_source_id, 8, used_regs, index)) {
                ok = false;
                continue;
            }
            if (offsets.vec[i].vec[1] != "offset") {
                error(packet_phe.lineno, "invalid packet8 offset specification");
                ok = false;
                continue;
            }
            if (!check_range(offsets.vec[i].vec[2], 0, 0xff)) {
                ok = false;
                continue;
            }
            phe_source.packet8.offset[index] = static_cast<uint8_t>(offsets.vec[i].vec[2].i);
        }
        if (ok) {
            phe_source.packet8.hdr_id = static_cast<uint8_t>(hdr_id.i);
            phe_source.type = Extract::PheSource::PACKET8_SOURCE;
        }
    } else if (packet_phe == "packet16") {
        if (*group_id < Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_MIN ||
                *group_id > Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_MAX) {
            error(packet_phe.lineno,
                    "PHV builder group %d invalid for PHE16 packet source (valid %d-%d)",
                    *group_id, Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_MIN,
                    Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE16_MAX);
            return false;
        }
        if (data.vec.size != 3) {
            error(packet_phe.lineno, "invalid packet16 PHE source");
            return false;
        }
        if (!CHECKTYPE(data.vec[2], tVEC))
            return false;
        auto &offsets = data.vec[2];
        if (offsets.vec.size < 1 || offsets.vec.size > 2) {
            error(packet_phe.lineno,
                    "invalid number (%d) of packet16 PHE source values (valid 1-2)",
                    offsets.vec.size);
            return false;
        }
        for (int i = 0; i < Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES; ++i) {
            phe_source.packet16.offset[i] = 0;
            phe_source.packet16.swap[i] = false;
        }
        bitvec used_regs;
        for (int i = 0; i < offsets.vec.size; ++i) {
            if (!CHECKTYPE(offsets.vec[i], tCMD)) {
                ok = false;
                continue;
            }
            if (offsets.vec[i].vec.size < 3 || offsets.vec[i].vec.size > 4) {
                error(offsets.vec[i].lineno, "invalid packet16 offset specification");
                ok = false;
                continue;
            }
            /* -- Check register if it is in correct PHV builder group and correct PHE
             *    source and if it hasn't been used yet. */
            int index;
            if (!check_register(offsets.vec[i].vec[0], phe_source_id, 16, used_regs, index)) {
                ok = false;
                continue;
            }
            if (offsets.vec[i].vec[1] != "msb_offset") {
                error(packet_phe.lineno, "invalid packet16 offset specification");
                ok = false;
                continue;
            }
            if (!check_range(offsets.vec[i].vec[2], 0, 0xff)) {
                ok = false;
                continue;
            }
            if (offsets.vec[i].vec.size == 4) {
                if (!CHECKTYPE(offsets.vec[i].vec[3], tSTR)) {
                    ok = false;
                    continue;
                }
                if (offsets.vec[i].vec[3] == "swap") {
                    phe_source.packet16.swap[index] = true;
                } else {
                    error(packet_phe.lineno, "invalid packet16 offset specification");
                    ok = false;
                    continue;
                }
            }
            phe_source.packet16.offset[index] = static_cast<uint8_t>(offsets.vec[i].vec[2].i);
        }
        if (ok) {
            phe_source.packet16.hdr_id = static_cast<uint8_t>(hdr_id.i);
            phe_source.type = Extract::PheSource::PACKET16_SOURCE;
        }
    } else if (packet_phe == "packet32") {
        if (*group_id < Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_MIN ||
                *group_id > Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_MAX) {
            error(packet_phe.lineno,
                    "PHV builder group %d invalid for PHE32 packet source (valid %d-%d)",
                    *group_id, Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_MIN,
                    Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE32_MAX);
            return false;
        }
        if (data.vec.size < 5 || data.vec.size > 6) {
            error(packet_phe.lineno, "invalid packet32 PHE source");
            return false;
        }
        /* -- Check register if it is in correct PHV builder group and correct PHE source. */
        bitvec used_regs;  // not used here
        int index;  // not used here
        if (!check_register(data.vec[2], phe_source_id, 32, used_regs, index))
            return false;
        if (data.vec[3] != "msb_offset") {
            error(packet_phe.lineno, "invalid packet32 PHE source");
            return false;
        }
        if (!check_range(data.vec[4], 0, 0xff))
            return false;
        if (data.vec.size == 6) {
            if (!CHECKTYPE(data.vec[5], tSTR))
                return false;
            if (data.vec[5] == "reverse") {
                phe_source.packet32.reverse = PheSourcePacket32::REVERSE;
            } else if (data.vec[5] == "reverse_16b_words") {
                phe_source.packet32.reverse = PheSourcePacket32::REVERSE_16B_WORDS;
            } else {
                error(packet_phe.lineno, "invalid packet32 PHE source");
                return false;
            }
        }
        phe_source.packet32.offset = static_cast<uint8_t>(data.vec[4].i);
        phe_source.packet32.hdr_id = static_cast<uint8_t>(hdr_id.i);
        phe_source.type = Extract::PheSource::PACKET32_SOURCE;
    } else {
        error(packet_phe.lineno, "invalid PHE source type");
        return false;
    }

    return ok;
}

bool PhvBuilderGroup::input_phe_source_pair(VECTOR(value_t) args,
        Extract& extract, value_t data) {
    if (!CHECKTYPE(data, tVEC))
        return false;
    if (data.vec.size > Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES) {
        error(data.lineno, "more than %d PHE sources are not allowed",
                Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES);
        return false;
    }
    bool ok = true;
    for (int i = 0; i < data.vec.size; ++i) {
        if (!CHECKTYPE2(data.vec[i], tMAP, tCMD)) {
            ok = false;
            continue;
        }
        if (data.vec[i].type == tMAP) {
            /* -- <other8-sources> */
            if (!input_other_phe_source(args, extract.phe_source[i], i, data.vec[i])) {
                ok = false;
                continue;
            }
        } else {
            /* -- data.vec[i].type == tCMD: 'packet8', 'packet16' or 'packet32' */
            if (!input_packet_phe_source(args, extract.phe_source[i], i, data.vec[i])) {
                ok = false;
                continue;
            }
        }
    }
    return ok;
}

bool PhvBuilderGroup::input_extract(VECTOR(value_t) args, value_t key,
        value_t data) {
    if (key.type == tSTR) {
        error(key.lineno, "index of the extract is missing");
        return false;
    }
    if (!CHECKTYPE(key, tCMD))
        return false;
    if (key.vec.size < 2) {
        error(key.lineno, "index of the extract is missing");
        return false;
    }
    if (key.vec.size > 2) {
        error(key.lineno, "too many parameters of the PHV builder group extract");
        return false;
    }
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_PHV_BUILDER_GROUP_EXTRACTS_NUM - 1))
        return false;

    const int extract_id = key[1].i;

    if (extracts[extract_id].extract_id) {
        error(key.lineno, "redefinition of extract (%d) in PHV builder group not allowed",
                extract_id);
        return false;
    }

    if (!CHECKTYPE(data, tMAP))
        return false;

    bool ok = true;
    for (auto &kv : MapIterChecked(data.map)) {
        if (kv.key == "match") {
            if (!input_match_constant(extracts[extract_id].match_pov, kv.value,
                    Target::Flatrock::PARSER_POV_SELECT_NUM * 8)) {
                ok = false;
                continue;
            }
            if (!pov_select.check_match(extracts[extract_id].match_pov)) {
                error(kv.value.lineno, "match constant references unused POV byte");
                ok = false;
                continue;
            }
        } else if (kv.key == "source") {
            if (!input_phe_source_pair(args, extracts[extract_id], kv.value)) {
                ok = false;
                continue;
            }
        } else {
            report_invalid_directive("invalid PHV builder group extract directive", kv.key);
            ok = false;
            continue;
        }
    }

    if (ok)
        extracts[extract_id].extract_id = extract_id;
    return ok;
}

void PhvBuilderGroup::input(VECTOR(value_t) args, const int lineno,
        const int group, value_t data) {
    if (group_id) {
        error(lineno, "redefinition of PHV builder group (number %d) not allowed", group);
        return;
    }
    if (!CHECKTYPE(data, tMAP) || !require_keys(data, {"pov_select"}))
        return;

    group_id = group;
    gress = (args.size == 1 && args[0] == "ingress") ? INGRESS : EGRESS;
    bool pov_select_parsed = false;

    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE2(kv.key, tSTR, tCMD))
            continue;
        if (kv.key == "pov_select") {
            if (!CHECKTYPE(kv.key, tSTR))
                continue;
            if (!pov_select.input(kv.value))
                continue;
            pov_select_parsed = true;
        } else if (kv.key == "extract") {
            if (!pov_select_parsed) {
                error(kv.key.lineno,
                      "POV selection has to be defined before extracts");
                continue;
            }
            if (!input_extract(args, kv.key, kv.value))
                continue;
        } else {
            report_invalid_directive("invalid phv builder group directive", kv.key);
            continue;
        }
    }
}

void PhvBuilderGroup::write_config(RegisterSetBase &regs, json::map &json,
                                                   bool legacy) {
    auto &fr_regs(dynamic_cast<Target::Flatrock::parser_regs &>(regs));

    /* -- the PHV builder group is not specified, leave the registers at defaults */
    if (!group_id)
        return;

    static std::unordered_map<other_subtype, OtherWriteConfig> other_source_write_config {
        {other_subtype::CONSTANT,     {0x0,  0x0, 8}},
        /* -- bit[7] = 0 is POV / 1 is CSUM
         *    bit[3] = 0 is flags / 1 is state
         *    bit[2:0] is value */
        {other_subtype::POV_FLAGS,    {0x1,  0x0, 3}},
        {other_subtype::POV_STATE,    {0x1,  0x1, 3}},
        {other_subtype::CHKSUM_ERROR, {0x1, 0x80, 0}},
        /* -- bit[7:6] to select UDF0/1/2/3
         *    bit[2:0] to select byte from UDF */
        {other_subtype::UDF0,         {0x2,  0x0, 3}},
        {other_subtype::UDF1,         {0x2,  0x8, 3}},
        {other_subtype::UDF2,         {0x2, 0x10, 3}},
        {other_subtype::UDF3,         {0x2, 0x18, 3}},
        /* -- bit[4:0] to select byte from TM_eMETA(tm_q_out_meta_s) */
        {other_subtype::TM,           {0x2,    0, 5}},
        /* -- bit[2:0] to select byte from TM.QStat (35bit) */
        {other_subtype::GHOST,        {0x3,    0, 3}},
        /* -- bit[5:0] to select byte from BridgeMETA(64B) */
        {other_subtype::BRIDGE,       {0x3,    0, 6}},
    };

    /* -- POV key bytes selection */
    for (int i = 0; i < Target::Flatrock::PARSER_POV_SELECT_NUM; ++i) {
        if (gress == INGRESS) {
            /* -- parser */
            fr_regs.prsr.pov_keys_ext.pov_key_ext[*group_id].src[i] = pov_select.key[i].src;
            fr_regs.prsr.pov_keys_ext.pov_key_ext[*group_id].start[i] = pov_select.key[i].start;
        } else {
            /* -- pseudo parser */
            fr_regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[*group_id].src[i] = pov_select.key[i].src;
            fr_regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[*group_id].start[i] =
                    pov_select.key[i].start;
        }
    }

    for (int i = 0; i < Target::Flatrock::PARSER_PHV_BUILDER_GROUP_EXTRACTS_NUM; ++i) {
        if (!extracts[i].extract_id)
            /* -- extract is not specified, leave the registers at defaults */
            continue;

        /* -- TCAM match key */
        if (gress == INGRESS) {
            /* -- parser */
            fr_regs.prsr_mem.phv_tcam.phv_tcam[*group_id][i].key_wh = extracts[i].match_pov.word0;
            fr_regs.prsr_mem.phv_tcam.phv_tcam[*group_id][i].key_wl = extracts[i].match_pov.word1;
        } else {
            /* -- pseudo parser */
            fr_regs.pprsr_mem.phv_tcam.phv_tcam[*group_id][i].key_wh = extracts[i].match_pov.word0;
            fr_regs.pprsr_mem.phv_tcam.phv_tcam[*group_id][i].key_wl = extracts[i].match_pov.word1;
        }

        /* -- SRAM PHE sources */
        for (int j = 0; j < Target::Flatrock::PARSER_PHV_BUILDER_GROUP_PHE_SOURCES; ++j) {
            auto &type = (j == 0) ?
                ( (gress == INGRESS) ?
                    /* -- parser */
                    fr_regs.prsr_mem.phv_action_ram.iphv_action_mem16[*group_id][i].type0 :
                    /* -- pseudo parser */
                    fr_regs.pprsr_mem.phv_action_ram.ephv_action_mem16[*group_id][i].type0) :
                ( (gress == INGRESS) ?
                    /* -- parser */
                    fr_regs.prsr_mem.phv_action_ram.iphv_action_mem16[*group_id][i].type1 :
                    /* -- pseudo parser */
                    fr_regs.pprsr_mem.phv_action_ram.ephv_action_mem16[*group_id][i].type1);
            auto &type_field = (j == 0) ?
                ( (gress == INGRESS) ?
                    /* -- parser */
                    fr_regs.prsr_mem.phv_action_ram.iphv_action_mem16[*group_id][i].type0_field :
                    /* -- pseudo parser */
                    fr_regs.pprsr_mem.phv_action_ram.ephv_action_mem16[*group_id][i].type0_field) :
                ( (gress == INGRESS) ?
                    /* -- parser */
                    fr_regs.prsr_mem.phv_action_ram.iphv_action_mem16[*group_id][i].type1_field :
                    /* -- pseudo parser */
                    fr_regs.pprsr_mem.phv_action_ram.ephv_action_mem16[*group_id][i].type1_field);

            switch (extracts[i].phe_source[j].type) {
            case Extract::PheSource::OTHER_SOURCE:
            {
                type = 1;
                for (int k = 0; k < Target::Flatrock::PARSER_PHV_BUILDER_OTHER_PHE_SOURCES; ++k) {
                    auto &other = extracts[i].phe_source[j].other[k];
                    if (other_source_write_config.count(other.subtype)) {
                        auto &source = other_source_write_config.at(other.subtype);
                        // FIXME: compiler/model have reversed expectations on
                        // type_field indexing; awaiting HW team feedback
                        /* -- set 2 bit subtype */
                        // type_field[0].set_subfield(source.subtype_value, k * 2, 2);
                        type_field[4].set_subfield(source.subtype_value, k * 2, 2);
                        /* -- set value */
                        // type_field[k+1].set_subfield(source.fixed_val, source.var_width,
                        //         8 - source.var_width);
                        // type_field[k+1].set_subfield(other.value, 0, source.var_width);
                        type_field[3-k].set_subfield(source.fixed_val, source.var_width,
                                8 - source.var_width);
                        type_field[3-k].set_subfield(other.value, 0, source.var_width);
                    } /* -- else other_subtype::NONE */
                }
                break;
            }
            case Extract::PheSource::PACKET8_SOURCE:
            {
                type = 0;
                auto &packet = extracts[i].phe_source[j].packet8;
                // FIXME: compiler/model have reversed expectations on
                // type_field indexing; awaiting HW team feedback
                /* -- header_id: 0-254, 255 = unused */
                // type_field[0] = packet.hdr_id;
                type_field[4] = packet.hdr_id;
                /* -- offsets for PHE8 */
                for (int k = 0; k < Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE8_SOURCES; ++k) {
                    // type_field[k+1] = packet.offset[k];
                    type_field[3-k] = packet.offset[k];
                }
                break;
            }
            case Extract::PheSource::PACKET16_SOURCE:
            {
                type = 0;
                auto &packet = extracts[i].phe_source[j].packet16;
                // FIXME: compiler/model have reversed expectations on
                // type_field indexing; awaiting HW team feedback
                /* -- header_id: 0-254, 255 = unused */
                // type_field[0] = packet.hdr_id;
                type_field[4] = packet.hdr_id;
                /* -- offsets for PHE16 */
                for (int k = 0; k < Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES;
                        ++k) {
                    // type_field[(k*2)+1] = packet.offset[k];
                    type_field[3-(k*2)] = packet.offset[k];
                }
                /* -- byte swaps */
                for (int k = 0; k < Target::Flatrock::PARSER_PHV_BUILDER_PACKET_PHE16_SOURCES;
                        ++k) {
                    /* -- bit[0] = 0 no swap
                     *    bit[0] = 1 swap */
                    // type_field[(k*2)+2].set_subfield(packet.swap[k] ? 0x1 : 0x0, 0, 1);
                    type_field[3-(k*2)-1].set_subfield(packet.swap[k] ? 0x1 : 0x0, 0, 1);
                }
                break;
            }
            case Extract::PheSource::PACKET32_SOURCE:
            {
                type = 0;
                auto &packet = extracts[i].phe_source[j].packet32;
                // FIXME: compiler/model have reversed expectations on
                // type_field indexing; awaiting HW team feedback
                /* -- header_id: 0-254, 255 = unused */
                // type_field[0] = packet.hdr_id;
                type_field[4] = packet.hdr_id;
                /* -- offset for PHE32 */
                // type_field[1] = packet.offset;
                type_field[3] = packet.offset;
                /* -- byte swap */
                if (packet.reverse == PheSourcePacket32::REVERSE) {
                    /* -- bit[1:0] = 2 ... 4Byte SWAP: B3,B2,B1,B0 -> B0,B1,B2,B3 */
                    // type_field[2].set_subfield(0x2, 0, 2);
                    type_field[2].set_subfield(0x2, 0, 2);
                } else if (packet.reverse == PheSourcePacket32::REVERSE_16B_WORDS) {
                    /* -- bit[1:0] = 1 ... 2Byte SWAP: B3,B2,B1,B0 -> B2,B3,B0,B1 */
                    type_field[2].set_subfield(0x1, 0, 2);
                    // type_field[2].set_subfield(0x1, 0, 2);
                } else {
                    /* -- PheSourcePacket32::NO_REVERSE
                     *    bit[1:0] = 0 or bit[1:0] = 3 ... no swap
                     *    We leave the default value (0) here. */
                }
                break;
            }
            default: /* -- Extract::PheSource::INVALID */
                /* -- PHE source is not specified, leave the registers at defaults */
                break;
            }
        }
    }
}

void FlatrockParser::input_states(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(value, tMAP)) return;
    for (auto &kv : MapIterChecked(value.map, false)) {
        if (!CHECKTYPE2(kv.value, tINT, tMATCH)) return;
        match_t match;
        input_int_match(kv.value, match, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8);
        // Inserts if does not exist
        states[kv.key.s] = match;
    }
    states_init = true;
}

void FlatrockParser::PortMetadataItem::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tVEC)) return;
    value_t size = {.type = tINT, .lineno = data.lineno};
    size.i = data.vec.size;
    if (!check_range(size, 0, Target::Flatrock::PARSER_PORT_METADATA_WIDTH)) return;
    for (int i = 0; i < data.vec.size; i++) {
        check_range(data.vec[i], 0, Target::Flatrock::PARSER_PORT_METADATA_ITEM_MAX);
        this->data[i] = data.vec[i].i;
    }
}

void FlatrockParser::PortMetadataItem::write_config(RegisterSetBase &regs, json::map &json,
                                                    bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    for (int i = 0; i < Target::Flatrock::PARSER_PORT_METADATA_WIDTH; i++)
        _regs.prsr_mem.port_md_tbl.port_md_mem[*port].md[i] = data[i];
}

void FlatrockParser::Profile::input_match(VECTOR(value_t) args, value_t key, value_t value) {
    if (key == "match_port") {
        if (!CHECKTYPE2(value, tINT, tMATCH)) return;
        input_int_match(value, match.port, Target::Flatrock::PARSER_PROFILE_PORT_BIT_WIDTH);
    } else if (key == "match_inband_metadata") {
        if (!CHECKTYPE2(value, tINT, tMATCH)) return;
        input_int_match(value, match.inband_metadata,
                        Target::Flatrock::PARSER_INBAND_METADATA_WIDTH * 8);
    }
}

void FlatrockParser::alu0_instruction::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    boost::optional<value_t> opcode, msb, lsb, shift, mask, add;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "opcode") {
            if (!CHECKTYPE2(kv.value, tINT, tSTR)) return;
            if (kv.value.type == tINT) {
                opcode = kv.value;
            } else {
                if (kv.value != "noop") {
                    error(kv.value.lineno,
                          "unexpected opcode %s; "
                          "expected an opcode number or noop",
                          kv.value.s);
                } else {
                    value_t noop_value = {.type = tINT, .lineno = kv.value.lineno};
                    noop_value.i = Flatrock::alu0_instruction::OPCODE_NOOP;
                    opcode = noop_value;
                }
            }
        } else if (kv.key == "msb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            msb = kv.value;
        } else if (kv.key == "lsb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            lsb = kv.value;
        } else if (kv.key == "shift") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            shift = kv.value;
        } else if (kv.key == "mask") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            mask = kv.value;
        } else if (kv.key == "add") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            add = kv.value;
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
    if (opcode->i != Flatrock::alu0_instruction::OPCODE_NOOP &&
        !check_range(*opcode, Flatrock::alu0_instruction::OPCODE_0,
        Flatrock::alu0_instruction::OPCODE_6)) return;
    this->opcode = static_cast<Flatrock::alu0_instruction::opcode_enum>(opcode->i);
    switch (this->opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        // ptr += 0  ->  { opcode: noop }
        if (msb || lsb || shift || mask || add) {
            error(opcode->lineno, "unexpected: msb, lsb, shift, mask, or add");
        }
        add = value_t();
        add->type = tINT;
        add->lineno = opcode->lineno;
        add->i = 0;
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
        // opcode 0: ptr += imm8s  ->  { opcode: 0, add: <constant> }
    case Flatrock::alu0_instruction::OPCODE_1:
        // opcode 1: ptr += w2[7:0] + imm8s  ->  { opcode: 1, add: <constant> }
        if (msb || lsb || shift || mask) {
            error(opcode->lineno, "unexpected: msb, lsb, shift, or mask");
        } else if (!add) {
            error(opcode->lineno, "missing: add");
        } else {
            check_range(*add, -128, 127);  // add_imm8s
            opcode_0_1.add_imm8s = add->i;
        }
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
        // opcode 2: ptr += state[MSB:LSB], MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 2, msb: <constant>, lsb: <constant>}
    case Flatrock::alu0_instruction::OPCODE_3:
        // opcode 3: ptr += (state[MSB:LSB] << 2), MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 3, msb: <constant>, lsb: <constant>}
        if (shift || mask || add) {
            error(opcode->lineno, "unexpected: shift, mask, or add");
        } else if (!msb || !lsb) {
            error(opcode->lineno, "missing one of: msb, lsb");
        } else {
            check_range_state_subfield(*msb, *lsb);
            opcode_2_3.state_msb = msb->i;
            opcode_2_3.state_lsb = lsb->i;
        }
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
        // opcode 4: ptr += ((w2[7:0] & imm8u) << imm2u) + (imm2u << 2)
        //   -> { opcode: 4, mask: <constant>, shift: <constant>, add: <constant> }
    case Flatrock::alu0_instruction::OPCODE_5:
        // opcode 5: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        //   -> { opcode: 5, mask: <constant>, shift: <constant>, add: <constant> }
    case Flatrock::alu0_instruction::OPCODE_6:
        // opcode 6: ptr += ((w2[7:0] & imm8u) >> imm2u) + (imm2u << 2)
        //           if ((w2[7:0] & imm8u) >> imm2u) != 0,
        //           then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   -> { opcode: 6, mask: <constant>, shift: <constant>, add: <constant> }
        if (msb || lsb) {
            error(opcode->lineno, "unexpected: msb, or lsb");
        } else if (!mask || !shift || !add) {
            error(opcode->lineno, "missing one of: mask, shift, add");
        } else {
            check_range(*mask, 0, 0xff);  // mask_imm8u
            check_range(*shift, 0, 3);    // shift_imm2u
            check_range(*add, 0, 3);      // add_imm2u
            opcode_4_5_6.mask_imm8u = mask->i;
            opcode_4_5_6.shift_imm2u = shift->i;
            opcode_4_5_6.add_imm2u = add->i;
        }
        break;
    case Flatrock::alu0_instruction::INVALID:
    default:
        error(opcode->lineno, "invalid opcode for ALU0");
        break;
    }
}

uint32_t FlatrockParser::alu0_instruction::build_opcode() const {
    BUG_CHECK(!is_invalid(), "building opcode from invalid ALU0 instruction");

    uint32_t op0 = 0;
    switch (opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
    case Flatrock::alu0_instruction::OPCODE_0:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE0_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_1:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE1_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE2_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_3:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE3_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE4_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_5:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE5_ENC;
        break;
    case Flatrock::alu0_instruction::OPCODE_6:
        op0 = Target::Flatrock::PARSER_ALU0_OPCODE6_ENC;
        break;
    }
    int __len;
    uint8_t _len, _off, _mask, _shift, _add;
    switch (opcode) {
    case Flatrock::alu0_instruction::OPCODE_NOOP:
        break;
    case Flatrock::alu0_instruction::OPCODE_0:
    case Flatrock::alu0_instruction::OPCODE_1:
        // op0[7:0] : imm (signed)
        // op0[11:8] : reserved
        op0 |= opcode_0_1.add_imm8s & 0xff;
        break;
    case Flatrock::alu0_instruction::OPCODE_2:
    case Flatrock::alu0_instruction::OPCODE_3:
        // op0[7:6] : len
        // op0[5:0] : off
        // op0[11:8] : reserved
        __len = opcode_2_3.state_msb - opcode_2_3.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _off = opcode_2_3.state_lsb;
        op0 |= (_len & 0x3) << 6 | (_off & 0x3f);
        break;
    case Flatrock::alu0_instruction::OPCODE_4:
    case Flatrock::alu0_instruction::OPCODE_5:
    case Flatrock::alu0_instruction::OPCODE_6:
        // op0[7:0] : mask
        // op0[11:10] : shift
        // op0[9:8] : imm (unsigned)
        _mask = opcode_4_5_6.mask_imm8u;
        _shift = opcode_4_5_6.shift_imm2u;
        _add = opcode_4_5_6.add_imm2u;
        op0 |= (_shift & 0x3) << 10 | (_add & 0x3) << 8 | (_mask & 0xff);
        break;
    }
    return op0;
}

void FlatrockParser::alu1_instruction::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    boost::optional<value_t> opcode, msb, lsb, shift_dir, shift, mask_mode, mask, add, set;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "opcode") {
            if (!CHECKTYPE2(kv.value, tINT, tSTR)) return;
            if (kv.value.type == tINT) {
                opcode = kv.value;
            } else {
                if (kv.value != "noop") {
                    error(kv.value.lineno,
                          "unexpected opcode %s; "
                          "expected an opcode number or noop",
                          kv.value.s);
                } else {
                    value_t noop_value = {.type = tINT, .lineno = kv.value.lineno};
                    noop_value.i = Flatrock::alu1_instruction::OPCODE_NOOP;
                    opcode = noop_value;
                }
            }
        } else if (kv.key == "msb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            msb = kv.value;
        } else if (kv.key == "lsb") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            lsb = kv.value;
        } else if (kv.key == "shift_dir") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            shift_dir = kv.value;
        } else if (kv.key == "shift") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            shift = kv.value;
        } else if (kv.key == "mask_mode") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            mask_mode = kv.value;
        } else if (kv.key == "mask") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            mask = kv.value;
        } else if (kv.key == "add") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            add = kv.value;
        } else if (kv.key == "set") {
            if (!CHECKTYPE(kv.value, tINT)) return;
            set = kv.value;
        } else {
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
        }
    }
    if (opcode->i != Flatrock::alu1_instruction::OPCODE_NOOP &&
        !check_range(*opcode, Flatrock::alu1_instruction::OPCODE_0,
        Flatrock::alu1_instruction::OPCODE_7)) return;
    this->opcode = static_cast<Flatrock::alu1_instruction::opcode_enum>(opcode->i);
    switch (this->opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        if (shift_dir || shift || mask_mode || mask || add || set || msb || lsb) {
            error(opcode->lineno,
                "unexpected: shift_dir, shift, mask_mode, mask, add, set, msb, or lsb");
        }
        shift = value_t();
        shift->type = tINT;
        shift->lineno = opcode->lineno;
        shift->i = 0;
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
        // opcode 0: state[MSB:LSB] >>= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
        //  -> { opcode: 0, msb: <constant>, lsb: <constant>, shift: <constant> }
    case Flatrock::alu1_instruction::OPCODE_1:
        // opcode 1: state[MSB:LSB] <<= imm4u, MSB&LSB -> 2/4/8/16-bit state sub-field
        //  -> { opcode: 1, msb: <constant>, lsb: <constant>, shift: <constant> }
        if (shift_dir || mask_mode || mask || add || set) {
            error(opcode->lineno, "unexpected: shift_dir, mask_mode, mask, add, or set");
        } else if (!msb || !lsb || !shift) {
            error(opcode->lineno, "missing one of: msb, lsb, shift");
        } else {
            check_range_state_subfield(*msb, *lsb);
            check_range(*shift, 0, 15);  // shift_imm4u
            opcode_0_1.state_msb = msb->i;
            opcode_0_1.state_lsb = lsb->i;
            opcode_0_1.shift_imm4u = shift->i;
        }
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        // opcode 2: state[MSB:LSB] += imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> { opcode: 2, msb: <constant>, lsb: <constant>, add: <constant> }
        if (shift_dir || shift || mask_mode || mask || set) {
            error(opcode->lineno, "unexpected: shift_dir, shift, mask_mode, mask, or set");
        } else if (!msb || !lsb || !add) {
            error(opcode->lineno, "missing one of: msb, lsb, add");
        } else {
            check_range_state_subfield(*msb, *lsb);
            check_range(*add, -128, 127);  // add_set_imm8s
            opcode_2_3.state_msb = msb->i;
            opcode_2_3.state_lsb = lsb->i;
            opcode_2_3.add_set_imm8s = add->i;
        }
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        // opcode 3: state[MSB:LSB] = imm8s, MSB&LSB -> 2/4/8/16-bit state sub-field
        //   -> * { opcode: 3, msb: <constant>, lsb: <constant>, value: <constant> }
        if (shift_dir || shift || mask_mode || mask || add) {
            error(opcode->lineno, "unexpected: shift_dir, shift, mask_mode, mask, or add");
        } else if (!msb || !lsb || !set) {
            error(opcode->lineno, "missing one of: msb, lsb, set");
        } else {
            check_range_state_subfield(*msb, *lsb);
            check_range(*set, -128, 127);
            opcode_2_3.state_msb = msb->i;
            opcode_2_3.state_lsb = lsb->i;
            opcode_2_3.add_set_imm8s = set->i;
        }
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
        // opcode 4:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 4, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case Flatrock::alu1_instruction::OPCODE_5:
        // opcode 5:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 5, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case Flatrock::alu1_instruction::OPCODE_6:
        // opcode 6:
        //   shift_dir = 0: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] += ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 6, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
    case Flatrock::alu1_instruction::OPCODE_7:
        // opcode 7:
        //   shift_dir = 0: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) << imm2u) + (imm2u << 2)
        //   shift_dir = 1: state[MSB:LSB] -= ((w2[7:0] & mask_mode(imm4u)) >> imm2u) + (imm2u << 2)
        //   if ((w2[7:0] & imm8u) >> imm2u) != 0, then + 4 - ((w2[7:0] & imm8u) >> imm2u)
        //   mask_mode = 0: each bit of the mask is a half-nibble mask
        //   mask_mode = 1: the mask is a full bit mask on the lower bits; upper bits are 0xF
        //   -> { opcode: 7, msb: <constant>, lsb: <constant>, mask_mode: <constant>,
        //        mask: <constant>, shift_dir: <constant>, shift: <constant>, add: <constant> }
        // MSB&LSB -> 8-bit state sub-field
        if (set) {
            error(opcode->lineno, "unexpected: set");
        } else if (!msb || !lsb || !mask_mode || !mask || !shift_dir || !shift || !add) {
            error(opcode->lineno,
                  "missing one of: msb, lsb, mask_mode, mask, shift_dir, shift, add");
        } else {
            check_range_state_subfield(*msb, *lsb, true);
            check_range(*mask_mode, 0, 0x1);  // mask_mode
            check_range(*mask, 0, 0xf);  // mask_imm4u
            check_range(*shift_dir, 0, 1);  // shift_dir
            check_range(*shift, 0, 3);  // shift_imm2u
            check_range(*add, 0, 3);  // add_imm2u
            opcode_4_5_6_7.state_msb = msb->i;
            opcode_4_5_6_7.state_lsb = lsb->i;
            opcode_4_5_6_7.mask_imm4u = mask->i;
            opcode_4_5_6_7.shift_dir = shift_dir->i;
            opcode_4_5_6_7.shift_imm2u = shift->i;
            opcode_4_5_6_7.add_imm2u = add->i;
        }
        break;
    case Flatrock::alu0_instruction::INVALID:
    default:
        error(opcode->lineno, "invalid opcode for ALU1");
        break;
    }
}

uint32_t FlatrockParser::alu1_instruction::build_opcode() const {
    BUG_CHECK(!is_invalid(), "building opcode from invalid ALU1 instruction");

    uint32_t op1 = 0;
    switch (opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
    case Flatrock::alu1_instruction::OPCODE_0:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE0_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_1:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE1_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE2_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_3:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE3_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE4_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_5:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE5_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_6:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE6_ENC;
        break;
    case Flatrock::alu1_instruction::OPCODE_7:
        op1 = Target::Flatrock::PARSER_ALU1_OPCODE7_ENC;
        break;
    }
    int __len;
    uint8_t _len, _off, _mask, _shift, _add;
    switch (opcode) {
    case Flatrock::alu1_instruction::OPCODE_NOOP:
        break;
    case Flatrock::alu1_instruction::OPCODE_0:
    case Flatrock::alu1_instruction::OPCODE_1:
        // op1[15:10] : offset
        // op1[9:8] : len
        // op1[7:4] : reserved
        // op1[3:0] : imm
        _off = opcode_0_1.state_lsb;
        __len = opcode_0_1.state_msb - opcode_0_1.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _shift = opcode_0_1.shift_imm4u;
        op1 |= (_off & 0x3f) << 10 | (_len & 0x3) << 8 | (_shift & 0xf);
        break;
    case Flatrock::alu1_instruction::OPCODE_2:
    case Flatrock::alu1_instruction::OPCODE_3:
        // op1[15:10] : offset
        // op1[9:8] : len
        // op1[7:0] : imm (signed)
        _off = opcode_2_3.state_lsb;
        __len = opcode_2_3.state_msb - opcode_2_3.state_lsb + 1;
        _len = (__len == 16) ? 3 : (__len == 8) ? 2 : (__len == 4) ? 1 : 0;
        _add = opcode_2_3.add_set_imm8s;
        op1 |= (_off & 0x3f) << 10 | (_len & 0x3) << 8 | (_add & 0xff);
        break;
    case Flatrock::alu1_instruction::OPCODE_4:
    case Flatrock::alu1_instruction::OPCODE_5:
    case Flatrock::alu1_instruction::OPCODE_6:
    case Flatrock::alu1_instruction::OPCODE_7:
        // op1[15:10] : offset
        // op1[9] : mask_mode
        // op1[8] : shift_dir
        // op1[7:4] : mask
        // op1[3:2] : shift
        // op1[1:0] : imm
        _off = opcode_4_5_6_7.state_lsb;
        uint8_t _mask_mode = opcode_4_5_6_7.mask_mode;
        uint8_t _shift_dir = opcode_4_5_6_7.shift_dir;
        _mask = opcode_4_5_6_7.mask_imm4u;
        _shift = opcode_4_5_6_7.shift_imm2u;
        _add = opcode_4_5_6_7.add_imm2u;
        op1 |= (_off & 0x3f) << 10 | (_mask_mode & 0x1) << 9 | (_shift_dir & 0x1) << 8 |
               (_mask & 0xf) << 4 | (_shift & 0x3) << 2 | (_add & 0x3);
        break;
    }
    return op1;
}

FlatrockParser::ParserStateVector::ParserStateVector() {
    std::memset(value, 0, sizeof(value));
    std::memset(mask, 0, sizeof(mask));
}

FlatrockParser::ParserStateVector::ParserStateVector(match_t match) {
    static_assert(sizeof(match.word0) == 8);
    static_assert(sizeof(match.word1) == 8);
    static_assert(Target::Flatrock::PARSER_STATE_WIDTH == 10);

    /* -- the all-match bits are initialized with zeros. We need that for the
     *    initial state value. */
    auto derived_value(match.word1 & (match.word0 ^ match.word1));
    value[0] = static_cast<uint8_t>(derived_value);
    value[1] = static_cast<uint8_t>(derived_value >> 8);
    value[2] = static_cast<uint8_t>(derived_value >> 16);
    value[3] = static_cast<uint8_t>(derived_value >> 24);
    value[4] = static_cast<uint8_t>(derived_value >> 32);
    value[5] = static_cast<uint8_t>(derived_value >> 40);
    value[6] = static_cast<uint8_t>(derived_value >> 48);
    value[7] = static_cast<uint8_t>(derived_value >> 56);

    auto derived_mask(match.word0 ^ match.word1);
    mask[0] = static_cast<uint8_t>(derived_mask);
    mask[1] = static_cast<uint8_t>(derived_mask >> 8);
    mask[2] = static_cast<uint8_t>(derived_mask >> 16);
    mask[3] = static_cast<uint8_t>(derived_mask >> 24);
    mask[4] = static_cast<uint8_t>(derived_mask >> 32);
    mask[5] = static_cast<uint8_t>(derived_mask >> 40);
    mask[6] = static_cast<uint8_t>(derived_mask >> 48);
    mask[7] = static_cast<uint8_t>(derived_mask >> 56);

    // Upper-most two bytes fixed 0
    value[8] = 0;
    mask[8] = 0;
    value[9] = 0;
    mask[9] = 0;
}

FlatrockParser::ParserStateVector::ParserStateVector(match_t hi, match_t lo)
    : ParserStateVector(lo) {
    static_assert(sizeof(match_t::word0) == 8);
    static_assert(sizeof(match_t::word1) == 8);
    static_assert(Target::Flatrock::PARSER_STATE_WIDTH == 10);

    /* -- the all-match bits are initialized with zeros. We need that for the
     *    initial state value. */
    auto derived_value(hi.word1 & (hi.word0 ^ hi.word1));
    value[8] = static_cast<uint8_t>(derived_value);
    value[9] = static_cast<uint8_t>(derived_value >> 8);

    auto derived_mask(hi.word0 ^ hi.word1);
    mask[8] = static_cast<uint8_t>(derived_mask);
    mask[9] = static_cast<uint8_t>(derived_mask >> 8);
}

bool FlatrockParser::ParserStateVector::input_state_value(
    uint8_t target[Target::Flatrock::PARSER_STATE_WIDTH * 8], const value_t value) {
    static_assert(sizeof(value.i) == 8);
    static_assert(Target::Flatrock::PARSER_STATE_WIDTH >= 8);

    /* -- small constants are parsed as tINT. Thus we must support both integer types. */
    if (!CHECKTYPE2(value, tINT, tBIGINT)) return false;

    if (value.type == tBIGINT) {
        if (!check_bigint_unsigned(value, Target::Flatrock::PARSER_STATE_WIDTH)) return false;

        int dword_index(0);
        int byte_mask(0);
        for (int i(0); i < Target::Flatrock::PARSER_STATE_WIDTH; ++i) {
            if (dword_index < value.bigi.size) {
                target[i] = static_cast<uint8_t>(value.bigi.data[dword_index] >> byte_mask);
            } else {
                target[i] = 0;
            }
            byte_mask += 8;
            if (byte_mask >= sizeof(value.bigi.data[0]) * 8) {
                byte_mask = 0;
                ++dword_index;
            }
        }
    } else {
        if (value.i < 0) {
            error(value.lineno, "the next_state constant is negative");
            return false;
        }
        target[0] = static_cast<uint8_t>(value.i);
        target[1] = static_cast<uint8_t>(value.i >> 8);
        target[2] = static_cast<uint8_t>(value.i >> 16);
        target[3] = static_cast<uint8_t>(value.i >> 24);
        target[4] = static_cast<uint8_t>(value.i >> 32);
        target[5] = static_cast<uint8_t>(value.i >> 40);
        target[6] = static_cast<uint8_t>(value.i >> 48);
        target[7] = static_cast<uint8_t>(value.i >> 56);

        for (int i(8); i < Target::Flatrock::PARSER_STATE_WIDTH; ++i) target[i] = 0;
    }

    return true;
}

void FlatrockParser::ParserStateVector::forceSetMask() {
    for (unsigned char & byte : mask)
        byte = 0xff;
}

void FlatrockParser::ParserStateVector::writeValue(ubits<16> &hi, ubits<32> &mid,
                                                   ubits<32> &lo) const {
    hi = (static_cast<uint16_t>(value[9]) << 8) | static_cast<uint16_t>(value[8]);
    mid = (static_cast<uint32_t>(value[7]) << 24) | (static_cast<uint32_t>(value[6]) << 16) |
          (static_cast<uint32_t>(value[5]) << 8) | static_cast<uint32_t>(value[4]);
    lo = (static_cast<uint32_t>(value[3]) << 24) | (static_cast<uint32_t>(value[2]) << 16) |
         (static_cast<uint32_t>(value[1]) << 8) | static_cast<uint32_t>(value[0]);
}

void FlatrockParser::ParserStateVector::writeMask(ubits<16> &hi, ubits<32> &mid,
                                                  ubits<32> &lo) const {
    hi = (static_cast<uint16_t>(mask[9]) << 8) | static_cast<uint16_t>(mask[8]);
    mid = (static_cast<uint32_t>(mask[7]) << 24) | (static_cast<uint32_t>(mask[6]) << 16) |
          (static_cast<uint32_t>(mask[5]) << 8) | static_cast<uint32_t>(mask[4]);
    lo = (static_cast<uint32_t>(mask[3]) << 24) | (static_cast<uint32_t>(mask[2]) << 16) |
         (static_cast<uint32_t>(mask[1]) << 8) | static_cast<uint32_t>(mask[0]);
}

bool FlatrockParser::ParserStateVector::parse_state_vector(ParserStateVector &target,
                                                           value_t value) {
    ParserStateVector tmp;

    if (value.type == tINT || value.type == tBIGINT) {
        if (!input_state_value(tmp.value, value)) return false;
        tmp.forceSetMask();
    } else if (value.type == tMATCH) {
        /* -- even though the match value is already parsed in value.m, check the correct range */
        match_t match;
        if (!input_int_match(value, match, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8))
            return false;
        tmp = ParserStateVector(match);
    } else if (value.type == tMAP) {
        match_t hi;
        match_t lo;
        std::memset(&hi, 0, sizeof(hi));
        std::memset(&lo, 0, sizeof(lo));
        for (const auto &kv : MapIterChecked(value.map, true)) {
            if (kv.key == "lo") {
                if (!input_int_match(kv.value, lo, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8))
                    return false;
            } else if (kv.key == "hi") {
                if (!input_int_match(kv.value, hi,
                                     (Target::Flatrock::PARSER_STATE_WIDTH -
                                      Target::Flatrock::PARSER_STATE_MATCH_WIDTH) *
                                         8))
                    return false;
            } else {
                report_invalid_directive("invalid specification of the state vector", kv.key);
                return false;
            }
        }
        tmp = ParserStateVector(hi, lo);
    } else {
        error(value.lineno, "invalid specification of the state vector");
        return false;
    }

    target = tmp; /* -- strong guarantee */
    return true;
}

void FlatrockParser::Profile::input_metadata_select(VECTOR(value_t) args, value_t key,
                                                    value_t value) {
    if (!CHECKTYPE(value, tVEC)) return;
    value_t size = {.type = tINT, .lineno = value.lineno};
    size.i = value.vec.size;
    if (!check_range(size, 0, Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM)) return;
    for (int i = 0; i < value.vec.size; i++) {
        if (!CHECKTYPE3(value.vec[i], tINT, tSTR, tCMD)) return;
        if (value.vec[i].type == tINT) {
            metadata_select[i].type = Flatrock::metadata_select::CONSTANT;
            metadata_select[i].constant.value = value.vec[i].i;
        } else if (value.vec[i].type == tSTR) {
            if (value.vec[i] == "logical_port_number") {
                metadata_select[i].type = Flatrock::metadata_select::LOGICAL_PORT_NUMBER;
            } else {
                error(value.vec[i].lineno, "invalid key: %s", value.vec[i].s);
            }
        } else {
            if (value.vec[i].vec.size < 2) error(value.vec[i].lineno, "missing operand");
            if (value.vec[i] == "port_metadata") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PORT_METADATA_WIDTH - 1);
                metadata_select[i].type = Flatrock::metadata_select::PORT_METADATA;
                metadata_select[i].port_metadata.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "inband_metadata") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_INBAND_METADATA_WIDTH - 1);
                metadata_select[i].type = Flatrock::metadata_select::INBAND_METADATA;
                metadata_select[i].inband_metadata.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "timestamp") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_INDEX_MAX);
                metadata_select[i].type = Flatrock::metadata_select::TIMESTAMP;
                metadata_select[i].timestamp.index = value.vec[i].vec[1].i;
            } else if (value.vec[i] == "counter") {
                check_range(value.vec[i].vec[1],
                    0, Target::Flatrock::PARSER_PROFILE_MD_SEL_COUNTER_INDEX_MAX);
                metadata_select[i].type = Flatrock::metadata_select::COUNTER;
                metadata_select[i].timestamp.index = value.vec[i].vec[1].i;
            } else {
                report_invalid_directive("invalid key", value.vec[i]);
            }
        }
    }
}

void FlatrockParser::Profile::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;

    /* -- Set initial ALU instructions to noop by default. */
    initial_alu0_instruction.opcode = alu0_instruction::OPCODE_NOOP;
    initial_alu1_instruction.opcode = alu1_instruction::OPCODE_NOOP;

    /* -- Require match attributes to be present in the ASM file. The default values that the
     * compiler sets for them is "match everything" already, so them not being present in the ASM
     * file is most likely a bug. */
    auto match_port_present = false;
    auto match_inband_metadata_present = false;

    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "match_port") {
            match_port_present = true;
            input_match(args, kv.key, kv.value);
        } else if (kv.key == "match_inband_metadata") {
            match_inband_metadata_present = true;
            input_match(args, kv.key, kv.value);
        } else if (kv.key == "initial_pktlen") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_PROFILE_PKTLEN_MAX);
            initial_pktlen = kv.value.i;
        } else if (kv.key == "initial_seglen") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_PROFILE_SEGLEN_MAX);
            initial_seglen = kv.value.i;
        } else if (kv.key == "initial_state") {
            if (kv.value.type == tSTR) {
                match_t match = parser->state(kv.value);
                initial_state = ParserStateVector(match);
            } else {
                ParserStateVector tmp;
                if (!ParserStateVector::parse_state_vector(tmp, kv.value)) return;
                initial_state = tmp;
            }
        } else if (kv.key == "initial_flags") {
            if (!CHECKTYPE(kv.value, tBIGINT)) return;
            initial_flags[0] = kv.value.bigi.data[0];
            initial_flags[1] = kv.value.bigi.data[0] >> 8;
            initial_flags[2] = kv.value.bigi.data[0] >> 16;
            initial_flags[3] = kv.value.bigi.data[0] >> 24;
            initial_flags[4] = kv.value.bigi.data[0] >> 32;
            initial_flags[5] = kv.value.bigi.data[0] >> 40;
            initial_flags[6] = kv.value.bigi.data[0] >> 48;
            initial_flags[7] = kv.value.bigi.data[0] >> 56;
        } else if (kv.key == "initial_ptr") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_PTR_MAX);
            initial_ptr = kv.value.i;
        } else if (kv.key == "initial_w0_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            initial_w0_offset = kv.value.i;
        } else if (kv.key == "initial_w1_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            initial_w1_offset = kv.value.i;
        } else if (kv.key == "initial_w2_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            initial_w2_offset = kv.value.i;
        } else if (kv.key == "initial_alu0_instruction") {
            initial_alu0_instruction.input(args, kv.value);
        } else if (kv.key == "initial_alu1_instruction") {
            initial_alu1_instruction.input(args, kv.value);
        } else if (kv.key == "metadata_select") {
            input_metadata_select(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }

    if (!match_port_present) {
        error(data.lineno, "mandatory profile's match_port attribute is missing");
    }
    if (!match_inband_metadata_present) {
        error(data.lineno, "mandatory profile's match_inband_metadata attribute is missing");
    }
}

void FlatrockParser::Profile::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    /*
     * TCAM:
     * WH  WL  Input  Hit
     * 1   0   0      Yes
     * 1   0   1      No
     * 0   1   0      No
     * 0   1   1      Yes
     * 1   1   *      Yes
     * 0   0   *      No
     */
    // 4Byte of inband metadata: inband_meta[4:7][7:0]
    // inband_metadata is in network byte order
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wh_0 =
        match.inband_metadata.word0 & 0xffffffff;
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wl_0 =
        match.inband_metadata.word1 & 0xffffffff;
    // 4Byte of inband metadata: inband_meta[0:3][7:0]
    // inband_metadata is in network byte order
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wh_1 = match.inband_metadata.word0 >> 32;
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wl_1 = match.inband_metadata.word1 >> 32;
    // 8bit port_info = {2'b0, logic_port#(6b)}
    // The 2 MSBs are part of the key and must be matched on, either with an explicit zero-match or
    // a wildcard match.
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wh_2 = 0xc0 | (match.port.word0 & 0x3f);
    _regs.prsr_mem.md_prof_tcam.md_prof_tcam[*id].key_wl_2 = 0x00 | (match.port.word1 & 0x3f);
    // RAM
    // initial state
    initial_state.writeValue(_regs.prsr_mem.md_prof_ram.md_prof[*id].start_state_hi,
                             _regs.prsr_mem.md_prof_ram.md_prof[*id].start_state_mid,
                             _regs.prsr_mem.md_prof_ram.md_prof[*id].start_state_lo);
    // initial flags
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_flags_hi =
        initial_flags[7] << 24 | initial_flags[6] << 16 | initial_flags[5] << 8 | initial_flags[4];
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_flags_lo =
        initial_flags[3] << 24 | initial_flags[2] << 16 | initial_flags[1] << 8 | initial_flags[0];
    // initial ptr
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_ptr = initial_ptr;
    // initial w0 offset
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_w0 = initial_w0_offset;
    // initial w1 offset
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_w1 = initial_w1_offset;
    // initial w2 offset
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_w2 = initial_w2_offset;
    // initial ALU0 instruction
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_op0 = initial_alu0_instruction.build_opcode();
    // initial ALU1 instruction
    _regs.prsr_mem.md_prof_ram.md_prof[*id].start_op1 = initial_alu1_instruction.build_opcode();
    // metadata select
    for (int i = 0; i < Target::Flatrock::PARSER_PROFILE_MD_SEL_NUM; i++) {
        // Skip uninitialized fields
        if (metadata_select[i].type == Flatrock::metadata_select::INVALID) continue;
        _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel_const[i] =
            (metadata_select[i].type == Flatrock::metadata_select::CONSTANT);
        switch (metadata_select[i].type) {
        case Flatrock::metadata_select::CONSTANT:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                metadata_select[i].constant.value;
            break;
        case Flatrock::metadata_select::LOGICAL_PORT_NUMBER:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC |
                Target::Flatrock::PARSER_PROFILE_MD_SEL_LOGICAL_PORT_NUMBER_INDEX;
            break;
        case Flatrock::metadata_select::PORT_METADATA:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_PORT_METADATA_ENC |
                metadata_select[i].port_metadata.index;
            break;
        case Flatrock::metadata_select::INBAND_METADATA:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_INBAND_METADATA_ENC |
                metadata_select[i].inband_metadata.index;
            break;
        case Flatrock::metadata_select::TIMESTAMP:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_TIMESTAMP_ENC |
                metadata_select[i].timestamp.index;
            break;
        case Flatrock::metadata_select::COUNTER:
            _regs.prsr_mem.md_prof_ram.md_prof[*id].md_sel[i] =
                Target::Flatrock::PARSER_PROFILE_MD_SEL_COUNTER_ENC |
                metadata_select[i].counter.index;
            break;
        }
    }
}

bool FlatrockParser::AnalyzerStage::input_push_hdr(
    FlatrockParser::AnalyzerStage::Rule& rule,
    value_t value) {
    if (!CHECKTYPE(value, tMAP))
        return false;
    if (value.map.size != 2) {
        error(value.lineno, "invalid number of push_hdr_id parameters");
        return false;
    }

    Rule::PushHdrId push_hdr_id;
    for (const auto &kv_hdr : MapIterChecked(value.map, false)) {
        if (kv_hdr.key == "hdr") {
            if (kv_hdr.value.type == tSTR) {
                int hdr_id(Hdr::id(kv_hdr.value.lineno, kv_hdr.value.s));
                if (hdr_id < 0) return false;
                push_hdr_id.hdr_id = static_cast<uint8_t>(hdr_id);
            } else if (kv_hdr.value.type == tINT) {
                if (!check_range(kv_hdr.value, 0, 0xff)) return false;
                push_hdr_id.hdr_id = kv_hdr.value.i;
            } else {
                error(kv_hdr.value.lineno,
                    "id attribute of the push_hdr_id must be a symbolic header name "
                    "or a numeric id");
                return false;
            }
        } else if (kv_hdr.key == "offset") {
            if (!check_range(kv_hdr.value, 0, 0xfe)) {
                error(kv_hdr.value.lineno,
                    "offset attribute the push_hdr_id must be a numeric offset in the "
                    "interval <0, 0xff>.");
                return false;
            }
            push_hdr_id.offset = static_cast<int8_t>(kv_hdr.value.i);
        } else {
            report_invalid_directive("invalid attribute of push_hdr_id directive",
                kv_hdr.key);
            return false;
        }
    }
    rule.push_hdr_id = push_hdr_id;
    return true;
}

template <uint8_t width>
boost::optional<FlatrockParser::AnalyzerStage::Rule::ModifyFlags<width>>
FlatrockParser::AnalyzerStage::load_modify_flags(
    FlatrockParser::AnalyzerStage::Rule& rule,
    value_t value) {
    if (!CHECKTYPE(value, tMAP) || !require_keys(value, {"src", "imm", "mask", "shift"}))
        return boost::none;

    Rule::ModifyFlags<width> modify_flags;
    constexpr unsigned max_value = (1 << width) - 1;
    for (const auto &kv : MapIterChecked(value.map, false)) {
        if (kv.key == "src") {
            if (kv.value == "w0")
                modify_flags.src = 0;
            else if (kv.value == "w1")
                modify_flags.src = 1;
            else if (kv.value == "w2")
                modify_flags.src = 2;
            else if (kv.value == "imm")
                modify_flags.src = 3;
            else {
                std::stringstream ss;
                ss << "the src attribute of modify_flags" << width
                   << " must be one of W0, W1, W2, imm.";
                report_invalid_directive(ss.str().c_str(), kv.value);
                return boost::none;
            }
        } else if (kv.key == "imm") {
            if (!check_range(kv.value, 0, max_value)) {
                error(kv.value.lineno,
                      "the imm attribute of modify_flags%u must be a number in "
                      "the interval [0, %u].",
                      width, max_value);
                return boost::none;
            }
            modify_flags.imm = kv.value.i;
        } else if (kv.key == "mask") {
            if (!check_range(kv.value, 0, max_value)) {
                error(kv.value.lineno,
                    "the mask attribute of modify_flags%u must be a number in "
                    "the interval [0, %u].", width, max_value);
                return boost::none;
            }
            modify_flags.mask = kv.value.i;
        } else if (kv.key == "shift") {
            if (!check_range(kv.value, 0, 63)) {
                error(kv.value.lineno,
                      "the shift attribute of modify_flags%u must be a number in "
                      "the interval [0, 63].", width);
                return boost::none;
            }
            modify_flags.shift = kv.value.i;
        } else {
            std::stringstream ss;
            ss << "invalid attribute of modify_flags" << width << " directive";
            report_invalid_directive(ss.str().c_str(), kv.key);
            return boost::none;
        }
    }

    return modify_flags;
}

boost::optional<FlatrockParser::AnalyzerStage::Rule::ModifyFlag>
FlatrockParser::AnalyzerStage::load_modify_flag(
    FlatrockParser::AnalyzerStage::Rule &rule,
    value_t value) {
    if (!CHECKTYPE(value, tMAP))
        return boost::none;

    bool command_met = false;
    Rule::ModifyFlag modify_flag;
    for (const auto &kv : MapIterChecked(value.map, false)) {
        if (command_met) {
            report_invalid_directive("multiple operations for a single modify_flag instruction",
                                     kv.key);
            return boost::none;
        } else if (kv.key == "set" || kv.key == "clear") {
            if (!check_range(kv.value, 0, 63)) {
                error(kv.value.lineno,
                      "the idx attribute of modify_flag must be a number in "
                      "the interval [0, 63].");
                return boost::none;
            }
            modify_flag.imm = kv.key == "set" ? true : false;
            modify_flag.shift = kv.value.i;
            command_met = true;
        } else {
            report_invalid_directive("invalid attribute of modify_flag directive", kv.key);
            return boost::none;
        }
    }

    if (!command_met) {
        report_invalid_directive("modify_flag has to either set or clear a flag", value);
        return boost::none;
    }

    return modify_flag;
}

bool FlatrockParser::AnalyzerStage::input_modify_checksum(
    FlatrockParser::AnalyzerStage::Rule &rule,
    value_t value) {
    if (!CHECKTYPE(value, tMAP) || !require_keys(value, {"idx", "enabled"}))
        return false;

    Rule::ModifyChecksum modify_checksum;
    for (const auto &kv : MapIterChecked(value.map, false)) {
        if (kv.key == "idx") {
            if (!check_range(kv.value, 0, 1)) {
                error(kv.value.lineno,
                      "the idx attribute of modify_checksum must be a number in "
                      "the interval [0, 1].");
                return false;
            }
            modify_checksum.cksum_idx = kv.value.i;
        } else if (kv.key == "enabled") {
            if (!CHECKTYPE(kv.value, tSTR) || (kv.value != "true" && kv.value != "false")) {
                error(kv.value.lineno,
                      "the enabled attribute of modify_checksum must be a boolean");
                return false;
            }
            modify_checksum.enabled = kv.value == "true" ? true : false;
        } else {
            report_invalid_directive("invalid attribute of modify_checksum directive",
            kv.key);
            return false;
        }
    }

    rule.modify_checksum = modify_checksum;
    return true;
}

void FlatrockParser::AnalyzerStage::input_rule(VECTOR(value_t) args, value_t key, value_t data) {
    if (key.type == tSTR) {
        /* -- This is handled by the CHECKTYPE macro but I want nicer
         *    error message. */
        error(key.lineno, "index of the rule is missing");
        return;
    }
    if (!CHECKTYPE(key, tCMD))
        return;
    if (key.vec.size < 2) {
        error(key.lineno, "index of the rule is missing");
        return;
    }
    if (key.vec.size > 2) {
        error(key.lineno, "too many parameters of the analyzer rule");
        return;
    }
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_ANALYZER_STAGE_RULES - 1))
        return;
    const int rule_index(key[1].i);
    auto &rule(rules[rule_index]);

    /* -- if the analyzer stage is attached to a state, use the state */
    if (name) {
        if (!parser->get_state_match(rule.match.state, *name))
            return;
    }

    if (!CHECKTYPE(data, tMAP))
        return;

    /* -- Require match attributes to be present in the ASM file. The default values that the
     * compiler sets for them is "match everything" already, so them not being present in the ASM
     * file is most likely a bug. */
    auto match_w0_present = false;
    auto match_w1_present = false;
    auto match_state_present = name.is_initialized();  // not needed in named stages

    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE2(kv.key, tSTR, tCMD))
            continue;
        if (kv.key == "match_state") {
            match_state_present = true;
            if (name) {
                error(kv.key.lineno,
                      "named analyzer stage must not contain any rule with the match_state "
                      "attribute");
                continue;
            }
            if (kv.value.type == tSTR) {
                if (!parser->get_state_match(rule.match.state, kv.value))
                    continue;
            } else {
                input_match_constant(
                    rule.match.state, kv.value, Target::Flatrock::PARSER_STATE_MATCH_WIDTH * 8);
            }
        } else if (kv.key == "match_w0") {
            match_w0_present = true;
            input_match_constant(
                rule.match.w0, kv.value, Target::Flatrock::PARSER_W_WIDTH * 8);
        } else if (kv.key == "match_w1") {
            match_w1_present = true;
            input_match_constant(
                rule.match.w1, kv.value, Target::Flatrock::PARSER_W_WIDTH * 8);
        } else if (kv.key == "next_state") {
            ParserStateVector next_state;
            if (kv.value.type == tSTR) {
                match_t state_match;
                if (parser->get_state_match(state_match, kv.value))
                    next_state = ParserStateVector(state_match);
            } else {
                ParserStateVector::parse_state_vector(next_state, kv.value);
            }
            rule.next_state = next_state;
        } else if (kv.key == "next_skip_extractions") {
            input_boolean(rule.next_skip_extraction, kv.value);
        } else if (kv.key == "next_w0_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            rule.next_w0_offset = kv.value.i;
        } else if (kv.key == "next_w1_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            rule.next_w1_offset = kv.value.i;
        } else if (kv.key == "next_w2_offset") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_W_OFFSET_MAX);
            rule.next_w2_offset = kv.value.i;
        } else if (kv.key == "next_alu0_instruction") {
            rule.next_alu0_instruction.input(args, kv.value);
        } else if (kv.key == "next_alu1_instruction") {
            rule.next_alu1_instruction.input(args, kv.value);
        } else if (kv.key == "push_hdr_id") {
            input_push_hdr(rule, kv.value);
        } else if (kv.key == "modify_flags4") {
            rule.modify_flags4 = load_modify_flags<4>(rule, kv.value);
        } else if (kv.key == "modify_flags16") {
            rule.modify_flags16 = load_modify_flags<16>(rule, kv.value);
        } else if (kv.key == "modify_flag0") {
            rule.modify_flag0 = load_modify_flag(rule, kv.value);
        } else if (kv.key == "modify_flag1") {
            rule.modify_flag1 = load_modify_flag(rule, kv.value);
        } else if (kv.key == "modify_checksum") {
            input_modify_checksum(rule, kv.value);
        } else {
            report_invalid_directive("invalid rule attribute", kv.key);
        }
    }

    /* -- There is no sensible default for next instructions. Check if they have been set. */
    if (rule.next_alu0_instruction.is_invalid()) {
        error(key.lineno, "mandatory rule's next_alu0_instruction field is missing");
    }
    if (rule.next_alu1_instruction.is_invalid()) {
        error(key.lineno, "mandatory rule's next_alu1_instruction field is missing");
    }

    if (!match_w0_present) {
        error(key.lineno, "mandatory rule's match_w0 field is missing");
    }
    if (!match_w1_present) {
        error(key.lineno, "mandatory rule's match_w1 field is missing");
    }
    if (!match_state_present) {
        error(key.lineno,
              "mandatory rule's match_state field is missing, as it's inside an unnamed stage");
    }
}

void FlatrockParser::AnalyzerStage::input(VECTOR(value_t) args, int stage_,
                                          boost::optional<value_t> name_, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;

    stage = stage_;
    name = name_;

    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE2(kv.key, tSTR, tCMD)) return;
        if (kv.key == "rule") {
            input_rule(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid analyzer directive", kv.key);
        }
    }
}

void FlatrockParser::AnalyzerStage::write_config(RegisterSetBase &regs, json::map &json,
                                                 bool legacy) {
    auto &fr_regs(dynamic_cast<Target::Flatrock::parser_regs &>(regs));

    if (!stage) return; /* -- the stage is not specified, leave the registers at defaults */

    for (unsigned int rule_idx(0); rule_idx < Target::Flatrock::PARSER_ANALYZER_STAGE_RULES;
         ++rule_idx) {
        const auto &rule(rules[rule_idx]);

        /*
         * TCAM:
         * WH  WL  Input  Hit
         * 1   0   0      Yes
         * 1   0   1      No
         * 0   1   0      No
         * 0   1   1      Yes
         * 1   1   *      Yes
         * 0   0   *      No
         */

        /* -- match state[63:0] */
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wh_0 =
            rule.match.state.word0 & 0xffffffff;
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wl_0 =
            rule.match.state.word1 & 0xffffffff;
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wh_1 =
            rule.match.state.word0 >> 32;
        fr_regs.prsr_mem.parser_key_s.key_s[*stage][rule_idx].key_wl_1 =
            rule.match.state.word1 >> 32;

        /* -- match w0 and w1 */
        fr_regs.prsr_mem.parser_key_w.key_w[*stage][rule_idx].key_wh =
            (rule.match.w0.word0 & 0xffff) | ((rule.match.w1.word0 & 0xffff) << 16);
        fr_regs.prsr_mem.parser_key_w.key_w[*stage][rule_idx].key_wl =
            (rule.match.w0.word1 & 0xffff) | ((rule.match.w1.word1 & 0xffff) << 16);

        /* -- w0, w1, w2 offsets */
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].exw_skip =
            rule.next_skip_extraction ? 1 : 0;
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].next_w0_offset = rule.next_w0_offset;
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].next_w1_offset = rule.next_w1_offset;
        fr_regs.prsr_mem.parser_ana_w.ana_w[*stage][rule_idx].next_w2_offset = rule.next_w2_offset;

        /* -- next state value and mask */
        rule.next_state.writeValue(
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_val_79_64,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_val_63_32,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_val_31_0);
        rule.next_state.writeMask(
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_mask_79_64,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_mask_63_32,
            fr_regs.prsr_mem.parser_ana_s.ana_s[*stage][rule_idx].state_mask_31_0);

        /* -- ALU0 and ALU1 instructions */
        fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op0 = 0;
        if (!rule.next_alu0_instruction.is_invalid()) {
            fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op0 =
                rule.next_alu0_instruction.build_opcode();
        }
        uint32_t next_op1 = 0;
        if (!rule.next_alu1_instruction.is_invalid()) {
            next_op1 = rule.next_alu1_instruction.build_opcode();
        }
        fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op1_0 = next_op1;
        fr_regs.prsr_mem.parser_ana_a.ana_a[*stage][rule_idx].next_op1_1 = next_op1 >> 16;

        /* -- push extracted headers */
        if (rule.push_hdr_id) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].push_hdr_id =
                (static_cast<uint32_t>(1) << 16) /* vld == '1' => push hdr_id into next slot */ |
                (static_cast<uint32_t>(rule.push_hdr_id->hdr_id) << 8) |
                (static_cast<uint32_t>(rule.push_hdr_id->offset));
        }
        if (rule.modify_flags16) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].mod_flags16 =
                (static_cast<uint64_t>(rule.modify_flags16->src) << 38) |
                (static_cast<uint64_t>(rule.modify_flags16->imm) << 22) |
                (static_cast<uint64_t>(rule.modify_flags16->mask) << 6) |
                (static_cast<uint64_t>(rule.modify_flags16->shift));
        }
        if (rule.modify_flags4) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].mod_flags4 =
                (static_cast<uint32_t>(rule.modify_flags4->src) << 14) |
                (static_cast<uint32_t>(rule.modify_flags4->imm) << 10) |
                (static_cast<uint32_t>(rule.modify_flags4->mask) << 6) |
                (static_cast<uint32_t>(rule.modify_flags4->shift));
        }
        if (rule.modify_flag0) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].mod_flag0 =
                (static_cast<uint32_t>(rule.modify_flag0->imm) << 6) |
                (static_cast<uint32_t>(rule.modify_flag0->shift));
        }
        if (rule.modify_flag1) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].mod_flag1 =
                (static_cast<uint32_t>(rule.modify_flag1->imm) << 6) |
                (static_cast<uint32_t>(rule.modify_flag1->shift));
        }
        if (rule.modify_checksum) {
            fr_regs.prsr_mem.parser_ana_ext.ana_ext[*stage][rule_idx].mod_csum =
                (static_cast<uint32_t>(1) << 2) |  // valid
                (static_cast<uint32_t>(rule.modify_checksum->cksum_idx) << 1) |
                (static_cast<uint32_t>(rule.modify_checksum->enabled));
        }
    }
}

void FlatrockParser::ChecksumCheckers::input_unit(std::size_t id, value_t &data) {
    if (!CHECKTYPE(data, tMAP)) {
        return;
    }

    auto is_config_key = [](value_t &val) {
        if (!CHECKTYPE(val, tCMD)) {
            return false;
        }
        if (val.vec.size != 2) {
            error(val.lineno, "expected 1 parameter for the 'config' key, got %d", val.vec.size);
            return false;
        }
        return CHECKTYPE(val.vec[0], tSTR) &&
               CHECKTYPE(val.vec[1], tINT) &&
               check_range(val.vec[1], 0, Target::Flatrock::PARSER_PROFILES - 1);
    };

    bool saw_pov_select = false;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "pov_select") {
            if (CHECKTYPE(kv.key, tSTR)) {
                units[id].pov_select.input(kv.value);
            }
            saw_pov_select = true;
        } else if (kv.key == "config") {
            if (is_config_key(kv.key)) {
                input_config(id, kv.key.vec[1].i, kv.value);
            }
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
    if (!saw_pov_select) {
        error(data.lineno, "each checksum unit must have pov_select specified");
    }
    units[id].used = true;
    units[id].lineno = data.lineno;
}

void FlatrockParser::ChecksumCheckers::input_config(std::size_t unit_id, std::size_t id,
                                                   value_t &data) {
    if (!CHECKTYPE(data, tMAP)) {
        return;
    }

    auto parse_hdr_id = [](value_t &val) -> boost::optional<uint8_t> {
        if (!CHECKTYPE2(val, tSTR, tINT)) {
            error(val.lineno,
                  "id attribute of the push_hdr_id must be a symbolic header name "
                  "or a numeric id");
            return boost::none;
        }
        if (val.type == tSTR) {
            int id = Hdr::id(val.lineno, val.s);
            value_t idVal;
            idVal.type = tINT;
            idVal.lineno = val.lineno;
            idVal.i = id;
            if (!check_range(idVal, 0, Target::Flatrock::PARSER_HDR_ID_MAX)) {
                return boost::none;
            }
            return static_cast<uint8_t>(id);
        } else if (val.type == tINT) {
            if (!check_range(val, 0, Target::Flatrock::PARSER_HDR_ID_MAX)) {
                return boost::none;
            }
            return static_cast<uint8_t>(val.i);
        }
        return boost::none;
    };

    auto &config = units[unit_id].configs[id];
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "match_pov") {
            if (!CHECKTYPE(kv.key, tSTR) || !CHECKTYPE(kv.value, tMATCH)) {
                continue;
            }
            input_match_constant(config.match_pov, kv.value,
                                 Target::Flatrock::PARSER_CSUM_MATCH_WIDTH);
        } else if (kv.key == "mask_sel") {
            if (!CHECKTYPE(kv.key, tSTR) ||
                !check_range(kv.value, 0, Target::Flatrock::PARSER_CSUM_MASKS - 1)) {
                continue;
            }
            config.mask_sel = kv.value.i;
        } else if (kv.key == "hdr") {
            auto hdr_id = parse_hdr_id(kv.value);
            if (!CHECKTYPE(kv.key, tSTR) || !hdr_id) {
                continue;
            }
            config.hdr_id = hdr_id.value();
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
    config.lineno = data.lineno;
    config.used = true;
}

void FlatrockParser::ChecksumCheckers::input_mask(std::size_t id, value_t &data) {
    if (!CHECKTYPE2(data, tBIGINT, tINT)) {
        return;
    }
    bitvec bv = get_bitvec(data, Target::Flatrock::PARSER_CSUM_MASK_BITS,
                           "checksum mask cannot be wider than 224b");
    for (std::size_t i = 0; i < Target::Flatrock::PARSER_CSUM_MASK_WIDTH; ++i) {
        constexpr std::size_t stride = Target::Flatrock::PARSER_CSUM_MASK_REG_WIDTH;
        masks[id].words[i] = static_cast<uint32_t>(bv.getrange(i * stride, stride));
    }
    masks[id].lineno = data.lineno;
    masks[id].used = true;
}

void FlatrockParser::ChecksumCheckers::write_unit(std::size_t id,
                                                  Target::Flatrock::parser_regs &regs) {
    if (!units[id].used) {
        return;
    }
    write_pov_select(id, regs);
    for (std::size_t i = 0; i < Target::Flatrock::PARSER_PROFILES; ++i) {
        write_config(id, i, regs);
    }
}

void FlatrockParser::ChecksumCheckers::write_pov_select(std::size_t unit_id,
                                                        Target::Flatrock::parser_regs &regs) {
    auto &pov_select = units[unit_id].pov_select;
    auto &pov_regs = regs.prsr.csum_key_ext[unit_id];
    for (std::size_t i = 0; i < Target::Flatrock::PARSER_POV_SELECT_NUM; ++i) {
        pov_regs.src[i] = pov_select.key[i].src;
        pov_regs.start[i] = pov_select.key[i].start;
    }
}

void FlatrockParser::ChecksumCheckers::write_config(std::size_t unit_id, std::size_t id,
                                                   Target::Flatrock::parser_regs &regs) {
    if (!units[unit_id].configs[id].used) {
        return;
    }
    auto &config_regs = regs.prsr.csum_chk_ram[unit_id].csum_chk[id];
    auto &config = units[unit_id].configs[id];
    config_regs.csum_hdr_id = config.hdr_id;
    config_regs.csum_mask_sel = config.mask_sel;
    auto &config_mem = regs.prsr_mem.csum_chk_tcam.csum_tcam[unit_id][id];
    config_mem.key_wh = config.match_pov.word0;
    config_mem.key_wl = config.match_pov.word1;
}

void FlatrockParser::ChecksumCheckers::write_mask(std::size_t id,
                                                  Target::Flatrock::parser_regs &regs) {
    if (!masks[id].used) {
        return;
    }
    auto &mask_regs = regs.prsr.csum_mask.csum_mask[id];
    for (std::size_t i = 0; i < Target::Flatrock::PARSER_CSUM_MASK_WIDTH; ++i) {
        mask_regs.en32[i] = masks[id].words[i];
    }
}

void FlatrockParser::ChecksumCheckers::validate() {
    auto check_mask = [&](Config &conf) {
        if (!conf.used) {
            return;
        }
        if (!masks[conf.mask_sel].used) {
            error(conf.lineno, "cannot reference unused mask %d", conf.mask_sel);
        }
    };

    auto check_match_pov = [](PovSelect &ps) {
        return [ps](Config &conf) {
            if (!conf.used) {
                return;
            }
            bool success = ps.check_match(conf.match_pov);
            if (!success) {
                error(conf.lineno, "match constant references unused POV byte");
            }
        };
    };

    for (auto &unit : units) {
        if (!unit.used) {
            continue;
        }
        std::for_each(std::begin(unit.configs), std::end(unit.configs), check_mask);
        std::for_each(std::begin(unit.configs), std::end(unit.configs),
                      check_match_pov(unit.pov_select));
    }
}

void FlatrockParser::ChecksumCheckers::input(VECTOR(value_t) args, value_t data) {
    auto is_mask_key = [](value_t &val) {
        if (!CHECKTYPE(val, tCMD)) {
            return false;
        }
        if (val.vec.size != 2) {
            error(val.lineno, "expected 1 parameter for the 'mask' key, got %d", val.vec.size);
            return false;
        }
        return CHECKTYPE(val.vec[0], tSTR) &&
               CHECKTYPE(val.vec[1], tINT) &&
               check_range(val.vec[1], 0, Target::Flatrock::PARSER_CSUM_MASKS - 1);
    };

    auto is_unit_key = [](value_t &val) {
        if (!CHECKTYPE(val, tCMD)) {
            return false;
        }
        if (val.vec.size != 2) {
            error(val.lineno, "expected 1 parameter for the 'unit' key, got %d", val.vec.size);
            return false;
        }
        return CHECKTYPE(val.vec[0], tSTR) &&
               CHECKTYPE(val.vec[1], tINT) &&
               check_range(val.vec[1], 0, Target::Flatrock::PARSER_CHECKSUM_UNITS - 1);
    };

    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "mask") {
            if (is_mask_key(kv.key)) {
                input_mask(kv.key.vec[1].i, kv.value);
            }
        } else if (kv.key == "unit") {
            if (is_unit_key(kv.key)) {
                input_unit(kv.key.vec[1].i, kv.value);
            }
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
    validate();
}

void FlatrockParser::ChecksumCheckers::write_config(RegisterSetBase &regs, json::map &json,
                                                   bool legacy) {
    auto *fr_regs = dynamic_cast<Target::Flatrock::parser_regs *>(&regs);
    BUG_CHECK(fr_regs, "the registers must be Flatrock registers");

    for (std::size_t i = 0; i < Target::Flatrock::PARSER_CSUM_MASKS; ++i) {
        write_mask(i, *fr_regs);
    }
    for (std::size_t i = 0; i < Target::Flatrock::PARSER_CHECKSUM_UNITS; ++i) {
        write_unit(i, *fr_regs);
    }
}

void FlatrockParser::input_port_metadata(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tSTR) || !CHECKTYPE(value, tMAP)) return;
    for (auto &item : value.map) {
        if (!check_range(item.key, 0, Target::Flatrock::PARSER_PORT_METADATA_ITEMS - 1)) return;
        int port = item.key.i;
        port_metadata[port].port = port;
        port_metadata[port].input(args, item.value);
    }
}

void FlatrockParser::input_profile(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tCMD)) return;
    if (key.vec.size < 2) error(key.lineno, "profile ID missing");
    if (key.vec.size > 2) error(key.lineno, "too many parameters");
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_PROFILES - 1)) return;
    int id = key[1].i;
    profiles[id].id = id;
    profiles[id].input(args, value);
}

void FlatrockParser::input_analyzer_stage(VECTOR(value_t) args, value_t key, value_t value) {
    if (key.type == tSTR) {
        /* -- The key is just one string -> no parameters. This situation
         *    can be handled by the CHECKTYPE macro, but I want to show
         *    a nicer error message. */
        error(key.lineno, "number of analyzer stage is missing");
        return;
    }
    if (!CHECKTYPE(key, tCMD)) return;
    if (key.vec.size < 2) {
        error(key.lineno, "number of analyzer stage is missing");
        return;
    }
    if (key.vec.size > 3) {
        error(key.lineno, "too many parameters of the analyzer_stage directive");
        return;
    }

    /* -- parse number of the stage */
    if (!check_range(key[1], 0, Target::Flatrock::PARSER_ANALYZER_STAGES - 1)) return;
    const int stage_index(key[1].i);

    /* -- parse optional name */
    boost::optional<value_t> state_name;
    if (key.vec.size > 2) {
        if (!CHECKTYPE(key[2], tSTR)) return;
        state_name = key[2];
    }

    /* -- set the analyzer and parse its context */
    analyzer[stage_index].input(args, stage_index, state_name, value);
}

bool InitialPredicationVector::input_mappings(const value_t &v) {
    unsigned next_tbl_idx = 0;
    auto prefix = gress == GHOST
        ? "the ghost next table configuration"
        : "the next table configuration";
    if (!CHECKTYPE(v, tMAP)) { return false; }

    for (const auto &row : MapIterChecked(v.map, true)) {
        value_t next_table = row.value;
        match_t match_key;

        if (!check_range(next_table, 0, 255)) {
            return false;
        } else if (next_tbl_idx >= Target::Flatrock::PARSER_PRED_VEC_TCAM_DEPTH) {
            error(v.lineno, "%s can hold at most %d entries", prefix,
                Target::Flatrock::PARSER_PRED_VEC_TCAM_DEPTH);
            return false;
        } else if (!input_match_constant(match_key, row.key,
            Target::Flatrock::PARSER_POV_SELECT_NUM * 8)) {
            error(row.key.lineno,
                  "the match key has to be a valid match constant of the correct width");
            return false;
        } else if (!pov_select.check_match(match_key)) {
            error(row.key.lineno, "match constant references unused POV byte");
            return false;
        }

        next_tbl_config[next_tbl_idx++] = NextTblConfig{
            .key = match_key,
            .next_tbl = static_cast<uint8_t>(next_table.i),
        };
    }

    return true;
}

void InitialPredicationVector::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP) || !require_keys(data, {"pov_select"})) { return; }

    bool pov_select_parsed = false;
    for (const auto &kv : MapIterChecked(data.map)) {
        if (kv.key == "next_tbl_config") {
            if (!pov_select_parsed) {
                error(kv.key.lineno,
                    "POV selection has to be defined before next table configuration");
                return;
            }
            if (!input_mappings(kv.value)) return;
        } else if (kv.key == "pov_select") {
            if (!pov_select.input(kv.value)) return;
            pov_select_parsed = true;
        } else {
            report_invalid_directive(
                "this key is not valid in the initial predication vector configuration",
                kv.key);
            return;
        }
    }
}

void InitialPredicationVector::write_config_parser(Target::Flatrock::parser_regs &regs,
                                                   json::map &json) const {
    unsigned thread = gress == GHOST;
    unsigned i = 0;
    for (const auto &entry : next_tbl_config) {
        auto &pred_tcam = regs.prsr_mem.pred_vec_tcam.pred_tcam[thread][i];
        auto &pred_info = regs.prsr.pred_info_ram[thread].pred_info[i];

        pred_tcam.key_wh = entry.key.word0;
        pred_tcam.key_wl = entry.key.word1;
        pred_info.next_tbl = entry.next_tbl;

        i++;
    }

    auto &key_ext = regs.prsr.pov_keys_ext.pov_key_ext[
        Target::Flatrock::PARSER_PHV_BUILDER_GROUPS + thread
    ];
    for (i = 0; i < Target::Flatrock::PARSER_POV_SELECT_NUM; i++) {
        key_ext.src[i]   = pov_select.key[i].src;
        key_ext.start[i] = pov_select.key[i].start;
    }
}

void InitialPredicationVector::write_config_pseudo_parser(Target::Flatrock::parser_regs &regs,
                                                          json::map &json) const {
    unsigned i = 0;
    for (const auto &entry : next_tbl_config) {
        auto &pred_tcam = regs.pprsr_mem.pred_vec_tcam.pred_tcam[i];
        auto &pred_info = regs.pprsr.pred_info_ram.pred_info[i];

        pred_tcam.key_wh = entry.key.word0;
        pred_tcam.key_wl = entry.key.word1;
        pred_info.next_tbl = entry.next_tbl;

        i++;
    }

    auto &key_ext = regs.pprsr.pprsr_pov_keys_ext.pov_key_ext[
        Target::Flatrock::PARSER_PHV_BUILDER_GROUPS
    ];
    for (i = 0; i < Target::Flatrock::PARSER_POV_SELECT_NUM; i++) {
        key_ext.src[i]   = pov_select.key[i].src;
        key_ext.start[i] = pov_select.key[i].start;
    }
}

void InitialPredicationVector::write_config(RegisterSetBase &_regs,
                                            json::map &json,
                                            bool legacy) {
    auto &regs = dynamic_cast<Target::Flatrock::parser_regs &>(_regs);
    switch (gress) {
        case INGRESS:
        case GHOST:
            write_config_parser(regs, json);
            break;
        case EGRESS:
            write_config_pseudo_parser(regs, json);
            break;
        case NUM_GRESS_T:
            error(0, "invalid gress value");
            break;
    }
}

void FlatrockParser::input_checksum_checkers(VECTOR(value_t) args, value_t key, value_t value) {
    if (!CHECKTYPE(key, tSTR) || !CHECKTYPE(value, tMAP)) {
        return;
    }
    csum_checkers.input(args, value);
}

void FlatrockParser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "states") {
            input_states(args, kv.key, kv.value);
        } else if (kv.key == "port_metadata") {
            input_port_metadata(args, kv.key, kv.value);
        } else if (kv.key == "profile") {
            input_profile(args, kv.key, kv.value);
        } else if (kv.key == "analyzer_stage") {
            input_analyzer_stage(args, kv.key, kv.value);
        } else if (kv.key == "phv_builder_group") {
            input_phv_builder_group(phv_builder, Target::Flatrock::PARSER_PHV_BUILDER_GROUPS,
                    args, kv.key, kv.value);
        } else if (kv.key == "initial_predication_vector" && CHECKTYPE(kv.key, tSTR)) {
            initial_predication_vector[0].input(args, kv.value);
        } else if (kv.key == "ghost_initial_predication_vector" && CHECKTYPE(kv.key, tSTR)) {
            initial_predication_vector[1].input(args, kv.value);
        } else if (kv.key == "checksum_checkers") {
            input_checksum_checkers(args, kv.key, kv.value);
        } else {
            report_invalid_directive("invalid key", kv.key);
        }
    }
}

void FlatrockParser::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    for (unsigned int i = 0; i < Target::Flatrock::PARSER_PORT_METADATA_ITEMS; i++)
        if (port_metadata[i].port)
            // Process only initialized items
            port_metadata[i].write_config(regs, json, legacy);
    for (unsigned int i = 0; i < Target::Flatrock::PARSER_PROFILES; i++)
        if (profiles[i].id)
            // Process only initialized items
            profiles[i].write_config(regs, json, legacy);
    for (unsigned int i(0); i < Target::Flatrock::PARSER_ANALYZER_STAGES; ++i) {
        analyzer[i].write_config(regs, json, legacy);
    }
    for (unsigned int i = 0; i < Target::Flatrock::PARSER_PHV_BUILDER_GROUPS; ++i) {
        phv_builder[i].write_config(regs, json, legacy);
    }
    initial_predication_vector[0].write_config(regs, json, legacy);
    initial_predication_vector[1].write_config(regs, json, legacy);
    csum_checkers.write_config(regs, json, legacy);
    if (auto *top = TopLevel::regs<Target::Flatrock>()) {
        top->mem_pipe.prsr_mem.set("mem.prsr_mem", &_regs.prsr_mem);
        top->reg_pipe.prsr.set("reg.prsr", &_regs.prsr);
    }
}

match_t FlatrockParser::state(value_t name) const {
    BUG_CHECK(name.type == tSTR, "invalid name type");

    match_t retval{};
    std::memset(&retval, 0, sizeof(retval));
    const auto *found_match(_state_mask(name.lineno, name.s));
    if (found_match != nullptr) {
        retval = *found_match;
    }
    return retval;
}

bool FlatrockParser::get_state_match(match_t &state_match, value_t name) const {
    BUG_CHECK(name.type == tSTR, "invalid name type");

    const auto *found_match(_state_mask(name.lineno, name.s));
    if (found_match != nullptr) {
        state_match = *found_match;
        return true;
    }
    return false;
}

void FlatrockPseudoParser::input(VECTOR(value_t) args, value_t data) {
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (kv.key == "pov_flags_pos") {
            if (!CHECKTYPE(kv.key, tSTR)) return;
            if (!check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1)) return;
            pov_flags_pos = kv.value.i;
        } else if (kv.key == "pov_state_pos") {
            if (!CHECKTYPE(kv.key, tSTR)) return;
            if (!check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1)) return;
            pov_state_pos = kv.value.i;
        } else if (kv.key == "phv_builder_group") {
            input_phv_builder_group(phv_builder, Target::Flatrock::PARSER_PHV_BUILDER_GROUPS,
                    args, kv.key, kv.value);
        } else if (kv.key == "initial_predication_vector" && CHECKTYPE(kv.key, tSTR)) {
            initial_predication_vector.input(args, kv.value);
        } else {
            error(kv.key.lineno, "invalid key: %s", kv.key.s);
        }
    }
}

void FlatrockPseudoParser::write_hdr_config(Target::Flatrock::parser_regs &regs){
    for (const auto &kv : Hdr::hdr.len) {
        const int id = kv.first;
        const auto enc = kv.second;

        auto &mem = regs.pprsr_mem.hdr_len_tbl.hdr_len_mem[id];
        mem.base_len = enc.base_len;
        mem.num_comp_bits = enc.num_comp_bits;
        mem.scale = enc.scale;
    }
}

void FlatrockPseudoParser::write_config(RegisterSetBase &regs, json::map &json, bool legacy) {
    auto &_regs = dynamic_cast<Target::Flatrock::parser_regs &>(regs);
    _regs.pprsr.pprsr_pov_bmd_ext.st_start = pov_state_pos;
    _regs.pprsr.pprsr_pov_bmd_ext.flg_start = pov_flags_pos;
    for (unsigned int i = 0; i < Target::Flatrock::PARSER_PHV_BUILDER_GROUPS; ++i) {
        phv_builder[i].write_config(regs, json, legacy);
    }
    initial_predication_vector.write_config(regs, json, legacy);
    write_hdr_config(_regs);
    if (auto *top = TopLevel::regs<Target::Flatrock>()) {
        top->mem_pipe.pprsr_mem.set("mem.pprsr_mem", &_regs.pprsr_mem);
        top->reg_pipe.pprsr.set("reg.pprsr", &_regs.pprsr);
    }
}

FlatrockAsmParser::FlatrockAsmParser() : BaseAsmParser("parser") {
    /* -- register the register instance into the ubits *** singleton map */
    declare_registers(&cfg_registers);
}

FlatrockAsmParser::~FlatrockAsmParser() {
    /* -- unregister from the ubit *** singleton map */
    undeclare_registers(&cfg_registers);
}

const Target::Flatrock::parser_regs &FlatrockAsmParser::get_cfg_registers() const {
    return cfg_registers;
}

void FlatrockAsmParser::start(int lineno, VECTOR(value_t) args) {
    if (args.size != 1 || (args[0] != "ingress" && args[0] != "egress"))
        error(lineno,
              "parser must specify ingress or egress;"
              " ingress represents parser and egress represents pseudo parser");
}

void FlatrockAsmParser::input(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    if (args.size == 1 && args[0] == "ingress") {
        parser.input(args, data);
    } else {
        pseudo_parser.input(args, data);
    }
}

void FlatrockAsmParser::output(json::map &ctxt_json) {
    ctxt_json["parser"]["ingress"] = json::vector();
    parser.write_config(cfg_registers, ctxt_json, false);
    ctxt_json["parser"]["egress"] = json::vector();
    pseudo_parser.write_config(cfg_registers, ctxt_json, false);
}
