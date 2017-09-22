#ifndef EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_
#define EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_

#include "lib/bitvec.h"
#include "lib/ordered_map.h"

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

    explicit Type(unsigned typeId);

    Type(TypeEnum te);       // NOLINT(runtime/explicit)
    Type(const char* name);  // NOLINT(runtime/explicit)

    unsigned id() const;

    unsigned log2sz() const {  // TODO(zma) get rid of this function
         switch (size_) {
             case Size::b8:   return 0;
             case Size::b16:  return 1;
             case Size::b32:  return 2;
             case Size::null: return 3;
             default: BUG("Called log2sz() on an invalid container"); }
     }

    Kind kind() const { return kind_; }
    Size size() const { return size_; }

    Type& operator=(const Type& t) {
        kind_ = t.kind_;
        size_ = t.size_;
        return *this; }

    bool operator==(Type c) const {
        return kind_ == c.kind_ && size_ == c.size_; }

    bool operator<(Type c) const {
        if (kind_ < c.kind_) return true;
        if (c.kind_ < kind_) return false;
        if (size_ < c.size_) return true;
        if (size_ > c.size_) return false;
        return false; }

    bool valid() const { return size_ != Size::null; }
};

std::ostream &operator<<(std::ostream &out, const Type& t);

}  // namespace PHV

class PhvSpec {
    friend class PHV::Type;

 protected:
    static ordered_map<PHV::Type, unsigned> typeIdMap;
    static ordered_map<unsigned, PHV::Type> idTypeMap;

    static void addType(PHV::Type t);

 public:
    static unsigned numTypes() { return typeIdMap.size(); }

    virtual void defineTypes() const = 0;

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
    virtual bitvec group(unsigned id) const = 0;

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
    virtual bitvec range(PHV::Type t, unsigned start, unsigned length) const = 0;

    /// @return a bitvec of the containers which are hard-wired to ingress.
    virtual const bitvec& ingressOnly() const = 0;

    /// @return a bitvec of the containers which are hard-wired to egress.
    virtual const bitvec& egressOnly() const = 0;

    /// @return the ids of every container in the given tagalong group.
    virtual bitvec tagalongGroup(unsigned groupIndex) const = 0;

    /// @return the ids of containers that can be assigned to a thread
    /// individually.
    virtual const bitvec& individuallyAssignedContainers() const = 0;

    /// @return the ids of all containers which actually exist on the Tofino
    /// hardware - i.e., all non-overflow containers.
    virtual const bitvec& physicalContainers() const = 0;
};


class TofinoPhvSpec : public PhvSpec {
 public:
    TofinoPhvSpec() {
        defineTypes();
    }

    void defineTypes() const override;

    bitvec group(unsigned id) const override;

    bitvec range(PHV::Type t, unsigned start, unsigned length) const override;

    const bitvec& ingressOnly() const override;

    const bitvec& egressOnly() const override;

    bitvec tagalongGroup(unsigned groupIndex) const override;

    const bitvec& individuallyAssignedContainers() const override;

    const bitvec& physicalContainers() const override;
};

#if HAVE_JBAY
class JBayPhvSpec : public PhvSpec {
 public:
    JBayPhvSpec() {
        defineTypes();
    }

    void defineTypes() const override;

    bitvec group(unsigned id) const override;

    bitvec range(PHV::Type t, unsigned start, unsigned length) const override;

    const bitvec& ingressOnly() const override;

    const bitvec& egressOnly() const override;

    bitvec tagalongGroup(unsigned groupIndex) const override;

    const bitvec& individuallyAssignedContainers() const override;

    const bitvec& physicalContainers() const override;
};
#endif /* HAVE_JBAY */

#endif /* EXTENSIONS_BF_P4C_PHV_PHV_SPEC_H_ */
