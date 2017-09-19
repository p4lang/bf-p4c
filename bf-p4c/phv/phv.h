#ifndef BF_P4C_PHV_PHV_H_
#define BF_P4C_PHV_PHV_H_

#include <iosfwd>
#include <limits>
#include "bf-p4c/device.h"
#include "lib/ordered_set.h"
#include "phv_spec.h"

class bitvec;
class cstring;

namespace PHV {

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

    /// @return the container with the given @id number, which you can obtain
    /// from the id() method. Useful when storing containers in bitvecs.
    static Container fromId(unsigned id) {
        return Container(Type(id % Device::phvSpec().numTypes()),
                         id / Device::phvSpec().numTypes());
    }

    /// @return a numerical id that uniquely identifies this container. Useful
    /// when storing Containers in bitvecs.
    unsigned id() const {
        // There are six kinds: B, H, W, and the tagalong variants of each.
        // Ids are assigned in ascending order by index, with kinds interleaved.
        // For example: B0, H0, W0, TB0, TH0, TW0, B1, H1, W1, ...
        return index_ * Device::phvSpec().numTypes() + type_.id();
    }

    size_t size() const { return (size_t)type_.size(); }
    unsigned log2sz() const { return type_.log2sz(); }
    size_t msb() const { return size() - 1; }
    size_t lsb() const { return 0; }

    PHV::Type type() const { return type_; }

    unsigned index() const { return index_; }
    bool tagalong() const { return type_.tagalong(); }

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

    static Container B(unsigned idx) { return Container(Kind::normal, Size::b8, idx); }
    static Container H(unsigned idx) { return Container(Kind::normal, Size::b16, idx); }
    static Container W(unsigned idx) { return Container(Kind::normal, Size::b32, idx); }
    static Container TB(unsigned idx) { return Container(Kind::tagalong, Size::b8, idx); }
    static Container TH(unsigned idx) { return Container(Kind::tagalong, Size::b16, idx); }
    static Container TW(unsigned idx) { return Container(Kind::tagalong, Size::b32, idx); }

    bitvec group() const { return Device::phvSpec().group(id()); }

    /// @return a string representation of this container.
    cstring toString() const;

    /// @return a string representation of the provided @group of containers.
    static cstring groupToString(const bitvec& group);
};

std::ostream &operator<<(std::ostream &out, const PHV::Container c);
std::ostream &operator<<(std::ostream &out, ordered_set<const PHV::Container *>& c_set);

}  // namespace PHV

#endif /* BF_P4C_PHV_PHV_H_ */
