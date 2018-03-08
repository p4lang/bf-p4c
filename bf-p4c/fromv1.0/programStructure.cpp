#include "programStructure.h"

namespace {

int digit(char ch) {
    if (isdigit(ch)) return ch - '0';
    if (islower(ch)) return ch - 'a' + 10;
    if (isupper(ch)) return ch - 'A' + 10;
    return -1;
}

// mpz equiv of strtol, missing from the GNU GMP lib
mpz_class strtompz(const char *s, const char **end, int base) {
    mpz_class rv;
    if (base == 0) {
        if (*s == '0') {
            base = 8;
            if (*++s == 'x' || *s == 'X') {
                base = 16;
                s++; }
        } else {
            base = 10; } }
    int d;
    while ((d = digit(*s)) >= 0 && d < base) {
        rv = rv * base + d;
        s++; }
    if (end) *end = s;
    return rv;
}

struct crc_func {
    mpz_class   poly, init, xout;
    bool        reverse = true, msb = false, error = false;
    int         size;
    explicit crc_func(const char *s) {
        if (strncmp(s, "poly_", 5)) {
            error = true;
            return; }
        s += 5;
        if (((poly = strtompz(s, &s, 0)) & 1) == 0)  // poly must be odd
            error = true;
        while (!error && *s) {
            if (!strncmp(s, "_init_", 6)) {
                if (init != 0) error = true;
                init = strtompz(s+6, &s, 0);
            } else if (!strncmp(s, "_not_rev", 8)) {
                reverse = false;
                s += 8;
            } else if (!strncmp(s, "_xout_", 6)) {
                if (xout != 0) error = true;
                xout = strtompz(s+6, &s, 0);
            } else if (!strncmp(s, "_lsb", 4)) {
                msb = false;
                s += 4;
            } else if (!strncmp(s, "_msb", 4)) {
                msb = true;
                s += 4;
            } else if (!strncmp(s, "_extend", 7)) {
                s += 7;
            } else {
                error = true; } }
        size = mpz_sizeinbase(poly.get_mpz_t(), 2) - 1; }
};

// table copied from glass llir/mau/stage/resources/hash_function.py
static std::map<cstring, cstring> standard_crcs = {
    { "crc_8", "poly_0x107" },
    { "crc_8_darc", "poly_0x139_not_rev" },
    { "crc_8_i_code", "poly_0x11d_init_0xfd" },
    { "crc_8_itu", "poly_0x107_init_0x55_xout_0x55" },
    { "crc_8_maxim", "poly_0x131_not_rev" },
    { "crc_8_rohc", "poly_0x107_not_rev_init_0xff" },
    { "crc_8_wcdma", "poly_0x19b_not_rev" },
    { "crc16", "poly_0x18005" },
    { "crc16_lsb", "poly_0x18005" },
    { "crc16_msb", "poly_0x18005_msb" },
    { "crc16_extend", "poly_0x18005" },
    { "crc_16", "poly_0x18005_not_rev" },
    { "crc_16_bypass", "poly_0x18005" },
    { "crc_16_dds_110", "poly_0x18005_init_0x800d" },
    { "crc_16_dect", "poly_0x10589_init_1_xout_1" },
    { "crc_16_dnp", "poly_0x13d65_not_rev_init_0xffff_xout_0xffff" },
    { "crc_16_en_13757", "poly_0x13d65_init_0xffff_xout_0xffff" },
    { "crc_16_genibus", "poly_0x11021_xout_0xffff" },
    { "crc_16_maxim", "poly_0x18005_not_rev_init_0xffff_xout_0xffff" },
    { "crc_16_mcrf4xx", "poly_0x11021_not_rev_init_0xffff" },
    { "crc_16_riello", "poly_0x11021_not_rev_init_0x554d" },
    { "crc_16_t10_dif", "poly_0x18bb7" },
    { "crc_16_teledisk", "poly_0x1a097" },
    { "crc_16_usb", "poly_0x18005_not_rev_xout_0xffff" },
    { "x_25", "poly_0x11021_not_rev_xout_0xffff" },
    { "xmodem", "poly_0x11021" },
    { "modbus", "poly_0x18005_not_rev_init_0xffff" },
    { "kermit", "poly_0x11021_not_rev" },
    { "crc_ccitt_false", "poly_0x11021_init_0xffff" },
    { "crc_aug_ccitt", "poly_0x11021_init_0x1d0f" },
    { "crc32", "poly_0x104c11db7_xout_0xffffffff" },
    { "crc32_lsb", "poly_0x104c11db7_xout_0xffffffff" },
    { "crc32_msb", "poly_0x104c11db7_msb_xout_0xffffffff" },
    { "crc32_extend", "poly_0x104c11db7_xout_0xffffffff" },
    { "crc_32", "poly_0x104c11db7_not_rev_xout_0xffffffff" },
    { "crc_32_bzip2", "poly_0x104c11db7_xout_0xffffffff" },
    { "crc_32c", "poly_0x11edc6f41_not_rev_xout_0xffffffff" },
    { "crc_32d", "poly_0x1a833982b_not_rev_xout_0xffffffff" },
    { "crc_32_mpeg", "poly_0x104c11db7_init_0xffffffff" },
    { "posix", "poly_0x104c11db7_init_0xffffffff_xout_0xffffffff" },
    { "crc_32q", "poly_0x1814141ab" },
    { "jamcrc", "poly_0x104c11db7_not_rev_init_0xffffffff" },
    { "xfer", "poly_0x1000000af" },
    { "crc_64", "poly_0x1000000000000001b_not_rev" },
    { "crc_64_we", "poly_0x142f0e1eba9ea3693_xout_0xffffffffffffffff" },
    { "crc_64_jones", "poly_0x1ad93d23594c935a9_not_rev_init_0xffffffffffffffff" },
};

}  // end anonymous namespace

const IR::Expression *P4V1::TNA_ProgramStructure::convertHashAlgorithm(IR::ID algorithm) {
    if (algorithm == "identity" || algorithm == "identity_lsb" || algorithm == "identity_msb")
        return new IR::Member(new IR::TypeNameExpression("HashAlgorithm"), "identity");
    if (algorithm == "random" || algorithm == "csum16" || algorithm == "xor16")
        return new IR::Member(new IR::TypeNameExpression("HashAlgorithm"), algorithm);
    auto crc = algorithm.name;
    bool msb = false;
    if (crc.endsWith("_extend")) {
        crc = crc.substr(0, crc.size() - 7);
    } else if (crc.endsWith("_lsb")) {
        crc = crc.substr(0, crc.size() - 4);
    } else if (crc.endsWith("_msb")) {
        crc = crc.substr(0, crc.size() - 4);
        msb = true; }
    if (standard_crcs.count(crc))
        crc = standard_crcs.at(crc);
    crc_func params(crc.c_str());
    if (params.error) {
        ::warning("%1%: unexpected algorithm", algorithm);
        return new IR::Member(new IR::TypeNameExpression("HashAlgorithm"), algorithm); }
    if (msb) params.msb = true;
    // FIXME -- we're still converting to v1model and then subsequently to TNA;
    // FIXME -- should convert directly to TNA
    include("tofino/p4_14_prim.p4", "-D_TRANSLATE_TO_V1MODEL");
    auto typeT = IR::Type::Bits::get(params.size + 1);
    auto args = new IR::Vector<IR::Expression>({ new IR::Constant(typeT, params.poly),
                                                 new IR::BoolLiteral(params.reverse),
                                                 new IR::BoolLiteral(params.msb) });
    if (params.init != 0 || params.xout != 0)
        args->push_back(new IR::Constant(typeT, params.init));
    if (params.xout != 0)
        args->push_back(new IR::Constant(typeT, params.xout));
    return new IR::MethodCallExpression(algorithm.srcInfo,
                    new IR::PathExpression("crc_poly"), args);
}
