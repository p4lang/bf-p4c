#include "parde.h"

#include "misc.h"

bool check_range_state_subfield(value_t msb, value_t lsb, bool only8b) {
    /* -- The LSB equals the offset operand in the instruction. There are just 6 bits for
     *    the offset, hence the offset might be in the range <0, 63>. Two bits of the
     *    len operand can define subfield widths 2/4/8/16 bits. That means the MSB
     *    can be in the range <min{LSB} + min{len} - 1, max{LSB} + max{len} - 1>,
     *    i.e. <1, 78>. */
    if (!check_range(msb, 1, Target::Flatrock::PARSER_ANA_STATE_WIDTH * 8 - 2)) return false;
    if (!check_range(lsb, 0, Target::Flatrock::PARSER_PKT_STATE_WIDTH * 8 - 1)) return false;
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
