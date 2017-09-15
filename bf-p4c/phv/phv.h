#ifndef BF_P4C_PHV_PHV_H_
#define BF_P4C_PHV_PHV_H_

#include <iosfwd>
#include "bf-p4c/device.h"
#include "lib/ordered_set.h"

class bitvec;
class cstring;

namespace PHV {

class Container {
    bool        tagalong_ : 1;
    unsigned    log2sz_ : 2;   // 3 (8 byte) means invalid
    unsigned    index_ : 13;
    Container(bool t, unsigned ls, unsigned i) : tagalong_(t), log2sz_(ls), index_(i) {}

 public:
    /// Construct an empty container. Most operations aren't defined on empty
    /// containers. (Use `operator bool()` to check if a container is empty.)
    Container() : tagalong_(false), log2sz_(3), index_(0) {}

    /// Construct a container from @name - e.g., "B0" for container B0.
    Container(const char *name);       // NOLINT(runtime/explicit)

    /// Construct a container from @kind and @index - e.g., (Kind::B, 0) for
    /// container B0.
    Container(PHV::Kind kind, unsigned index);

    /// @return the container with the given @id number, which you can obtain
    /// from the id() method. Useful when storing containers in bitvecs.
    static Container fromId(unsigned id) {
        return Container(Kind(id % PHV::NumKinds), id / PHV::NumKinds);
    }

    size_t size() const { return 8U << log2sz_; }
    unsigned log2sz() const { return log2sz_; }
    size_t msb() const { return size() - 1; }
    size_t lsb() const { return 0; }

    PHV::Kind kind() const;
    unsigned index() const { return index_; }
    bool tagalong() const { return tagalong_; }

    /// @return a numerical id that uniquely identifies this container. Useful
    /// when storing Containers in bitvecs.
    unsigned id() const {
        // There are six kinds: B, H, W, and the tagalong variants of each.
        const unsigned kindId = log2sz_ + (tagalong_ ? 3 : 0);
        // Ids are assigned in ascending order by index, with kinds interleaved.
        // For example: B0, H0, W0, TB0, TH0, TW0, B1, H1, W1, ...
        return index_ * PHV::NumKinds + kindId;
    }

    /// @return true if this container is nonempty (i.e., refers to an actual
    /// PHV container).
    explicit operator bool() const { return log2sz_ != 3; }

    Container operator++() {
        if (index_ != 0x7ff) ++index_;
        return *this; }
    Container operator++(int) { Container rv = *this; ++*this; return rv; }
    bool operator==(Container c) const {
        return tagalong_ == c.tagalong_ && log2sz_ == c.log2sz_ && index_ == c.index_; }
    bool operator!=(Container c) const { return !(*this == c); }
    bool operator<(Container c) const {
        return (tagalong_ << 15) + (log2sz_ << 13) + index_ <
               (c.tagalong_ << 15) + (c.log2sz_ << 13) + c.index_; }

    friend std::ostream &operator<<(std::ostream &out, Container c);
    friend std::ostream &operator<<(std::ostream &out, PHV::Kind k);

    static Container B(unsigned idx) { return Container(false, 0, idx); }
    static Container H(unsigned idx) { return Container(false, 1, idx); }
    static Container W(unsigned idx) { return Container(false, 2, idx); }
    static Container TB(unsigned idx) { return Container(true, 0, idx); }
    static Container TH(unsigned idx) { return Container(true, 1, idx); }
    static Container TW(unsigned idx) { return Container(true, 2, idx); }

    bitvec group() const;

    /**
     * Generates a bitvec containing a range of containers. This kind of bitvec
     * can be used to implement efficient set operations on large numbers of
     * containers.
     *
     * To generate the range [B10, B16), use `range(Kind::B, 10, 6)`.
     *
     * @param kind The type of container.
     * @param start The index of first container in the range.
     * @param length The number of containers in the range. May be zero.
     */
    static bitvec range(PHV::Kind kind, unsigned start, unsigned length) {
        return Device::phvSpec().range(kind, start, length); }

    /// @return a bitvec of the containers which are hard-wired to ingress.
    static const bitvec& ingressOnly() {
        return Device::phvSpec().ingressOnly(); }

    /// @return a bitvec of the containers which are hard-wired to egress.
    static const bitvec& egressOnly() {
        return Device::phvSpec().egressOnly(); }

    /// @return the ids of every container in the given tagalong group.
    static bitvec tagalongGroup(unsigned groupIndex) {
        return Device::phvSpec().tagalongGroup(groupIndex); }

     /// @return the ids of containers that can be assigned to a thread
     /// individually.
    static const bitvec& individuallyAssignedContainers() {
        return Device::phvSpec().individuallyAssignedContainers(); }

     /// @return the ids of all containers which actually exist on the Tofino
     /// hardware - i.e., all non-overflow containers.
    static const bitvec& physicalContainers() {
        return Device::phvSpec().physicalContainers(); }

    /// @return a string representation of this container.
    cstring toString() const;

    /// @return a string representation of the provided @group of containers.
    static cstring groupToString(const bitvec& group);
};

std::ostream &operator<<(std::ostream &out, const PHV::Container c);
std::ostream& operator<<(std::ostream &out, ordered_set<const PHV::Container *>& c_set);

}  // namespace PHV

#endif /* BF_P4C_PHV_PHV_H_ */
