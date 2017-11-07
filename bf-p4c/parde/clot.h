#ifndef EXTENSIONS_BF_P4C_PARDE_CLOT_H_
#define EXTENSIONS_BF_P4C_PARDE_CLOT_H_

#include <vector>

#include "lib/cstring.h"
#include "ir/json_loader.h"
#include "bf-p4c/phv/phv_fields.h"

class Clot {
 public:
    Clot() { tag = tagCnt++; }
    explicit Clot(cstring);

    cstring toString() const;

    bool operator==(const Clot& c) const {
        return tag == c.tag;
    }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static Clot fromJSON(JSONLoader& json);

    unsigned tag = 0;

    // unsigned start = 0;  // start byte offset in the packet
                            // this will become clear during parser lowering?

    unsigned length() {
       unsigned len = 0;
       for (auto f : all_fields)
           len += f->size;
       return len;
    }

    std::vector<const PHV::Field*> all_fields;  // all fields covered in this clot
    std::vector<const PHV::Field*> phv_fields;  // fields that need to be replaced by
                                                // phvs when deparsed
    static int tagCnt;
};

std::ostream& operator<<(std::ostream& out, const Clot c);
JSONGenerator& operator<<(JSONGenerator& out, const Clot c);

#endif /* EXTENSIONS_BF_P4C_PARDE_CLOT_H_ */
