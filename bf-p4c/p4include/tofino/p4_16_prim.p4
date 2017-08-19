
enum hash_algorithm_t {
    CRC16
}

extern checksum<W> {
    checksum(hash_algorithm_t algorithm);
    void add<T>(in T data);
    bool verify();
    void update<T>(in T data, out W csum, @optional in W residul_csum);
    W residual_checksum<T>(in T data);
}

