#include "flatrock/hdr.h"

Hdr Hdr::hdr;

void Hdr::start(int lineno, VECTOR(value_t) args) {
    if (args.size > 0) {
        error(lineno, "no arguments allowed for the hdr section");
    }
}

void Hdr::input_map(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (!CHECKTYPE(kv.value, tINT)) return;
        _hdr_id_check_range(kv.value);
        map[kv.key.s] = kv.value.i;
    }
    map_init = true;
}

void Hdr::input_seq(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE(kv.value, tVEC)) return;
        check_range(kv.key, 0, Target::Flatrock::PARSER_SEQ_ID_MAX);
        for (int i = 0; i < kv.value.vec.size; i++) {
            if (!CHECKTYPE2(kv.value.vec[i], tINT, tSTR)) return;
            int hdr_id;
            if (kv.value.vec[i].type == tSTR) {
                hdr_id = _hdr_id(kv.value.vec[i].lineno, kv.value.vec[i].s);
            } else {
                _hdr_id_check_range(kv.value.vec[i]);
                hdr_id = kv.value.vec[i].i;
            }
            // Inserts if does not exist
            seq[kv.key.i].push_back(hdr_id);
        }
    }
}

void Hdr::input_len(VECTOR(value_t) args, value_t data) {
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, true)) {
        if (!CHECKTYPE2(kv.key, tINT, tSTR) || !CHECKTYPE(kv.value, tMAP)) return;
        int hdr_id;
        if (kv.key.type == tSTR) {
            hdr_id = _hdr_id(kv.key.lineno, kv.key.s);
        } else {
            _hdr_id_check_range(kv.key);
            hdr_id = kv.key.i;
        }
        len_enc _len;
        for (auto &kv2 : MapIterChecked(kv.value.map, false)) {
            if (kv2.key == "base_len") {
                check_range(kv2.value, 0, Target::Flatrock::PARSER_BASE_LEN_MAX);
                _len.base_len = kv2.value.i;
            } else if (kv2.key == "num_comp_bits") {
                check_range(kv2.value, 0, Target::Flatrock::PARSER_NUM_COMP_BITS_MAX);
                _len.num_comp_bits = kv2.value.i;
            } else if (kv2.key == "scale") {
                check_range(kv2.value, 0, Target::Flatrock::PARSER_SCALE_MAX);
                _len.scale = kv2.value.i;
            } else {
                error(kv2.value.lineno, "invalid key: %s; expected one of "
                    "base_len, num_comp_bits, and scale", kv2.key.s);
            }
        }
        len[hdr_id] = _len;
    }
}

void Hdr::input(VECTOR(value_t) args, value_t data) {
    if (options.target != Target::Flatrock::tag) {
        error(data.lineno, "the hdr section allowed only for Tofino 5");
    }
    if (!CHECKTYPE(data, tMAP)) return;
    for (auto &kv : MapIterChecked(data.map, false)) {
        if (kv.key == "map") {
            input_map(args, kv.value);
        } else if (kv.key == "seq") {
            input_seq(args, kv.value);
        } else if (kv.key == "seq_pos") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1);
            seq_pos = kv.value.i;
        } else if (kv.key == "len") {
            input_len(args, kv.value);
        } else if (kv.key == "len_pos") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1);
            len_pos = kv.value.i;
        } else if (kv.key == "off_pos") {
            check_range(kv.value, 0, Target::Flatrock::PARSER_BRIDGE_MD_WIDTH - 1);
            off_pos = kv.value.i;
        } else {
            error(kv.key.lineno, "unrecognized key");
        }
    }
}
