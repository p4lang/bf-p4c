#ifndef BF_ASM_FLATROCK_HDR_H_
#define BF_ASM_FLATROCK_HDR_H_

#include "sections.h"
#include "target.h"
#include "misc.h"

class Hdr : public Section {
    void start(int lineno, VECTOR(value_t) args) override;
    void input_map(VECTOR(value_t) args, value_t data);
    void input_seq(VECTOR(value_t) args, value_t data);
    void input_len(VECTOR(value_t) args, value_t data);
    void input(VECTOR(value_t) args, value_t data) override;
    void output(json::map &) override {};
    Hdr() : Section("hdr") {}
    Hdr(const Hdr &) = delete;
    Hdr &operator=(const Hdr &) = delete;
    ~Hdr() {}

    bool map_init = false;
    std::map<std::string, int> map;  // header name -> hdr_id
    int _hdr_id(int lineno, std::string name) {
        if (!map_init)
            error(lineno, "hdr -> map has not been initialized; "
                          "only header IDs can be used until initialization");
        if (map.count(name) == 0) {
            error(lineno, "undefined header name: %s", name.c_str());
            return -1;
        }
        return map.at(name);
    }
    void _hdr_id_check_range(value_t hdr_id) {
        check_range(hdr_id, 0, Target::Flatrock::PARSER_HDR_ID_MAX);
    }

 public:
    /// Compressed header sequence encoding in bridge metadata
    /// header sequence id -> header sequence
    std::map<int, std::vector<int>> seq;
    /// Byte location of compressed header sequence number in bridge metadata
    int seq_pos = -1;

    /// Compressed header length encoding
    struct len_enc {
        int base_len;
        int num_comp_bits;
        int scale;
    };
    /// Compressed header length encoding in bridge metadata
    /// hdr_id -> header length encoding
    std::map<int, len_enc> len;
    /// Byte location of compressed header length information in bridge metadata
    int len_pos = -1;

    /// Byte location of the offset of the first header in bridge metadata
    int off_pos = -1;

    static int id(int lineno, std::string name) {
        return hdr._hdr_id(lineno, name);
    }

    // For use by gtests
    static void test_clear() {
        hdr.map_init = false;
        hdr.map.clear();
        hdr.seq.clear();
        hdr.seq_pos = -1;
        hdr.len.clear();
        hdr.len_pos = -1;
        hdr.off_pos = -1;
    }

    static Hdr hdr;
};

#endif /* BF_ASM_FLATROCK_HDR_H_ */
