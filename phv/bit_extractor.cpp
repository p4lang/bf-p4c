#include "bit_extractor.h"
#include "ir/ir.h"

std::set<std::pair<PHV::Bit, PHV::Bit>>
BitExtractor::GetBitPairs(const IR::Expression *e1, const IR::Expression *e2) {
    std::set<std::pair<PHV::Bit, PHV::Bit>> bit_pairs;
    PhvInfo::Field::bitrange f1_bits, f2_bits;
    auto *f1 = phv.field(e1, &f1_bits);
    auto *f2 = phv.field(e2, &f2_bits);
    if (f1 && f2) {
        int width = std::min(f1_bits.size(), f2_bits.size());
        for (int i = 0; i < width; ++i) {
            PHV::Bit bit1 = f1->bit(i + f1_bits.lo);
            PHV::Bit bit2 = f2->bit(i + f2_bits.lo);
            if (bit_pairs.count(std::make_pair(bit1, bit2)) == 0) {
                bit_pairs.insert(std::make_pair(bit2, bit1)); } } }
    return bit_pairs;
}

std::list<PHV::Bit> BitExtractor::GetBits(const IR::Expression *e1) const {
    PhvInfo::Field::bitrange bits;
    std::list<PHV::Bit> rv;
    if (auto *f = phv.field(e1, &bits)) {
        for (int i = bits.lo; i <= bits.hi; ++i)
            rv.push_back(f->bit(i));
    } else if (auto *hr = e1->to<IR::HeaderRef>()) {
        for (auto fid : ReverseRange(*phv.header(hr))) {
            auto *f = phv.field(fid);
            for (int i = 0; i <= f->size; ++i)
                rv.push_back(f->bit(i)); } }
    return rv;
}

std::list<PHV::Byte>
BitExtractor::GetBytes(const IR::Expression *e1, const IR::Expression *e2) {
    PhvInfo::Field::bitrange f1_bits, f2_bits;
    auto *f1 = phv.field(e1, &f1_bits);
    auto *f2 = phv.field(e2, &f2_bits);
    std::list<PHV::Byte> bytes;
    if (f1) {
        int offset = 0;
        if (f2) offset = (f2->offset + f2_bits.lo) % 8;
        for (int i = f1_bits.lo; i <= f1_bits.hi; offset=0) {
            PHV::Byte new_byte;
            for (int j = 0; j < std::min(8 - offset, f1_bits.hi - i + 1); ++j) {
                new_byte.at(j + offset) = f1->bit(i + j); }
            bytes.push_back(new_byte);
            i += (8 - offset); }
    } else if (auto *hr = e1->to<IR::HeaderRef>()) {
        int i = 0;
        for (auto fid : ReverseRange(*phv.header(hr))) {
            auto *f = phv.field(fid);
            for (int j = 0; j < f->size; ++j, ++i) {
                if (i % 8U == 0)
                    bytes.emplace_back();
                bytes.back().at(i % 8U) = f->bit(j); } }
    } else {
        BUG("Unexpected in BitExtractor::GetBytes: %s", e1); }
    return bytes;
}
