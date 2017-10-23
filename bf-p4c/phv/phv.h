#ifndef BF_P4C_PHV_PHV_H_
#define BF_P4C_PHV_PHV_H_

#include <iosfwd>
#include <limits>
#include "lib/ordered_set.h"

class bitvec;
class cstring;
class JSONGenerator;
class JSONLoader;

namespace PHV {

enum class Kind : unsigned short {  // all possible PHV kinds in BFN devices
    normal   = 0,
    tagalong = 1
};

enum class Size : unsigned short {  // all possible PHV sizes in BFN devices
    null = 0,
    b8   = 8,
    b16  = 16,
    b32  = 32
};

class Type {
    Kind        kind_;
    Size        size_;

 public:
    enum TypeEnum {  // Enumeration of all possible types in BFN devices:
        B,           //     8-bit  normal
        H,           //     16-bit normal
        W,           //     32-bit normal
        TB,          //     8-bit  tagalong
        TH,          //     16-bit tagalong
        TW           //     32-bit tagalong
    };

    Type() : kind_(Kind::normal), size_(Size::null) {}
    Type(Kind k, Size s) : kind_(k), size_(s) {}
    Type(const Type& t) : kind_(t.kind_), size_(t.size_) {}

    Type(TypeEnum te);       // NOLINT(runtime/explicit)
    Type(const char* name);  // NOLINT(runtime/explicit)

    unsigned log2sz() const;
    Kind kind() const { return kind_; }
    Size size() const { return size_; }

    Type& operator=(const Type& t) {
        kind_ = t.kind_;
        size_ = t.size_;
        return *this;
    }

    bool operator==(Type c) const {
        return kind_ == c.kind_ && size_ == c.size_;
    }

    bool operator!=(Type c) const {
        return !(*this == c);
    }

    bool operator<(Type c) const {
        if (kind_ < c.kind_) return true;
        if (c.kind_ < kind_) return false;
        if (size_ < c.size_) return true;
        if (size_ > c.size_) return false;
        return false;
    }

    bool valid() const { return size_ != Size::null; }

    /// @return a string representation of this container type.
    cstring toString() const;
};

class Container {
    static constexpr unsigned MAX_INDEX = std::numeric_limits<unsigned>::max();

    Type        type_;
    unsigned    index_;

    Container(Kind k, Size s, unsigned i) : type_(k, s), index_(i) {}

 public:
    /// Construct an empty container. Most operations aren't defined on empty
    /// containers. (Use `operator bool()` to check if a container is empty.)
    Container() : type_(), index_(0) {}

    /// Construct a container from @name - e.g., "B0" for container B0.
    Container(const char *name);       // NOLINT(runtime/explicit)

    /// Construct a container from @kind and @index - e.g., (Kind::B, 0) for
    /// container B0.
    Container(PHV::Type t, unsigned index) : type_(t), index_(index) {}

    size_t size() const { return size_t(type_.size()); }
    unsigned log2sz() const { return type_.log2sz(); }
    size_t msb() const { return size() - 1; }
    size_t lsb() const { return 0; }

    PHV::Type type() const { return type_; }
    unsigned index() const { return index_; }

    bool is(PHV::Kind k) const { return k == type_.kind(); }
    bool is(PHV::Size sz) const { return sz == type_.size(); }

    /// @return true if this container is nonempty (i.e., refers to an actual
    /// PHV container).
    explicit operator bool() const { return type_.valid(); }

    Container operator++() {
        if (index_ != MAX_INDEX) ++index_;
        return *this; }
    Container operator++(int) { Container rv = *this; ++*this; return rv; }
    bool operator==(Container c) const {
        return type_ == c.type_ && index_ == c.index_; }
    bool operator!=(Container c) const { return !(*this == c); }
    bool operator<(Container c) const {
        if (type_ < c.type_) return true;
        if (c.type_ < type_) return false;
        if (index_ < c.index_) return true;
        if (c.index_ < index_) return false;
        return false; }

    /// JSON serialization/deserialization.
    void toJSON(JSONGenerator& json) const;
    static Container fromJSON(JSONLoader& json);

    /// @return a string representation of this container.
    cstring toString() const;
};

std::ostream& operator<<(std::ostream& out, const PHV::Kind k);
std::ostream& operator<<(std::ostream& out, const PHV::Size sz);
std::ostream& operator<<(std::ostream& out, const PHV::Type t);
std::ostream& operator<<(std::ostream& out, const PHV::Container c);
JSONGenerator& operator<<(JSONGenerator& out, const PHV::Container c);
std::ostream& operator<<(std::ostream& out, ordered_set<const PHV::Container *>& c_set);

}  // namespace PHV

#endif /* BF_P4C_PHV_PHV_H_ */
