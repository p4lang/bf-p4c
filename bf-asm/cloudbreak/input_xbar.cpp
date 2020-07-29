template void InputXbar::write_regs(Target::Cloudbreak::mau_regs &);

template<> void InputXbar::write_galois_matrix(Target::Cloudbreak::mau_regs &regs,
                                               int id, const std::map<int, HashCol> &mat) {
    int parity_col = -1;
    if (hash_table_parity.count(id) && !options.disable_gfm_parity) {
        parity_col = hash_table_parity[id];
    }
    auto &hash = regs.dp.xbar_hash.hash;
    std::set<int> gfm_rows;
    for (auto &col : mat) {
        int c = col.first;
        // Skip parity column encoding, if parity is set overall parity is
        // computed later below
        if (c == parity_col) continue;
        const HashCol &h = col.second;
        for (int word = 0; word < 4; word++) {
            unsigned data = h.data.getrange(word*16, 16);
            if (data == 0) continue;
            auto &w = hash.galois_field_matrix[id*4 + word][c];
            w.byte0 = data & 0xff;
            w.byte1 = (data >> 8) & 0xff; 
            gfm_rows.insert(id*4 + word);
        } 
    }
    // A GFM row can be shared by multiple tables. In most cases the columns are
    // non overlapping but if they are overlapping the GFM encodings must be the
    // same (e.g. ATCAM tables). The input xbar has checks to determine which
    // cases are valid. 
    // The parity must be computed for all columns within the row and set into
    // the parity column. 
    if (parity_col >= 0) {
        for (auto r : gfm_rows) {
            int hp_byte0 = 0, hp_byte1 = 0;
            for (auto c = 0; c < 52; c++) {
                if (c == parity_col) continue;
                auto &w = hash.galois_field_matrix[r][c];
                hp_byte0 ^= w.byte0; 
                hp_byte1 ^= w.byte1; 
            }
            auto &w_hp = hash.galois_field_matrix[r][parity_col];
            w_hp.byte0 = hp_byte0;
            w_hp.byte1 = hp_byte1;
        }
    }
}