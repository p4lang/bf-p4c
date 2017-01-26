extern BFD_Offload {
    BFD_Offload(bit<16> size);
    void setTx(in bit<16> index, in bit<8> data);
    bit<8> getTx(in bit<16> index);
    abstract void on_rx(in bit<16> index);
    abstract bool on_tx(in bit<16> index);
}

