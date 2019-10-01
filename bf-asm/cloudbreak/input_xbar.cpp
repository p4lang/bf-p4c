template void InputXbar::write_regs(Target::Cloudbreak::mau_regs &);

template<> void InputXbar::write_galois_matrix(Target::Cloudbreak::mau_regs &regs,
                                               int id, const std::map<int, HashCol> &mat) {
    auto &hash = regs.dp.xbar_hash.hash;
    for (auto &col : mat) {
        int c = col.first;
        const HashCol &h = col.second;
        for (int word = 0; word < 4; word++) {
            unsigned data = h.data.getrange(word*16, 16);
            if (data == 0) continue;
            auto &w = hash.galois_field_matrix[id*4 + word][c];
            w.byte0 = data & 0xff;
            w.byte1 = (data >> 8) & 0xff; } }
}
