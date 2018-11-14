/**
 * A source for a match key of a table.  The source can either be from the input xbar, or from the
 * galois field matrix, as indicated in uArch Section Exact Match Row Vertical/Horizontal (VH)
 * Xbars.  This class is the parent of HashMatchSource and Phv::Ref.
 */
class MatchSource {
 public:
    virtual int fieldlobit() const = 0;    
    virtual int fieldhibit() const = 0;
    virtual unsigned size() const = 0;
    virtual int slicelobit() const = 0;
    virtual int slicehibit() const = 0;
    virtual const char* name() const = 0;
    virtual int get_lineno() const = 0;
    virtual std::string toString() const = 0;
};

/**
 * The source used by proxy hash tables for their match key.
 */
class HashMatchSource : public MatchSource {
    int lo;
    int hi;
 public:
    int lineno;
    HashMatchSource(int line, int l, int h) : lineno(line), lo(l), hi(h) {}
    HashMatchSource(const HashMatchSource &hms) {
        memcpy(this, &hms, sizeof(*this));
    }
    HashMatchSource(value_t value) {
        if (CHECKTYPE(value, tCMD)) {
            lineno = value.lineno;
            if (value != "hash_group")
                error(value.lineno, "Hash Match source must come from a hash group");
            if (value.vec.size != 2)
                error(value.lineno, "Hash Match source requires a range");
            if (CHECKTYPE(value.vec[1], tRANGE)) {
                lo = value.vec[1].lo;
                hi = value.vec[1].hi;
            }
        }
    }

    int get_lineno() const override { return lineno; }
    int fieldlobit() const override { return lo < 0 ? 0 : lo; }
    int fieldhibit() const override { return hi < 0 ? 0 : hi; }
    unsigned size() const override { return hi >= lo && lo >= 0 ? hi - lo + 1 : 0; }
    int slicelobit() const override { return fieldlobit(); }
    int slicehibit() const override { return fieldhibit(); }
    const char* name() const override { return "hash_group"; }
    std::string toString() const override {
        std::stringstream str;
        str << *this;
        return str.str();
    }
    void dbprint(std::ostream &out) const { out << name() << "(" << lo << ".." << hi << ")"; } 
};
