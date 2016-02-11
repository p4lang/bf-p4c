#ifndef _json_h_
#define _json_h_

#include <iostream>
#include <map>
#include <memory>
#include "ordered_map.h"
#include "rvalue_reference_wrapper.h"
#include <stdexcept>
#include <string>
#include <typeindex>
#include <vector>
#include <assert.h>

namespace json {

/* this is std::make_unique, except that is missing in some compilers/versions */
template<class T, class...Args>
std::unique_ptr<T> make_unique(Args&&... args) {
    std::unique_ptr<T> ret (new T(std::forward<Args>(args)...));
    return ret;
}

class number;
class string;
class vector;
class map;

class obj {
public:
    obj() {}
    obj(const obj &) = default;
    obj(obj &&) = default;
    obj &operator=(const obj &) & = default;
    obj &operator=(obj &&) & = default;
    virtual ~obj() {}
    virtual bool operator <(const obj &a) const = 0;
    bool operator >=(const obj &a) const { return !(*this < a); }
    bool operator >(const obj &a) const { return a < *this; }
    bool operator <=(const obj &a) const { return !(a < *this); }
    virtual bool operator ==(const obj &a) const = 0;
    bool operator !=(const obj &a) const { return !(*this == a); }
    virtual bool operator ==(const char *str) const { return false; }
    bool operator !=(const char *str) const { return !(*this == str); }
    virtual bool operator ==(long val) const { return false; }
    bool operator !=(long val) const { return !(*this == val); }
    struct ptrless {
	bool operator()(const obj *a, const obj *b) const
	    { return b ? a ? *a < *b : true : false; }
	bool operator()(const std::unique_ptr<obj> &a, const std::unique_ptr<obj> &b) const
	    { return b ? a ? *a < *b : true : false; }
    };
    virtual void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const = 0;
    virtual bool test_width(int &limit) const = 0;
    virtual number *as_number() { return nullptr; }
    virtual const number *as_number() const { return nullptr; }
    virtual string *as_string() { return nullptr; }
    virtual const string *as_string() const { return nullptr; }
    virtual vector *as_vector() { return nullptr; }
    virtual const vector *as_vector() const { return nullptr; }
    virtual map *as_map() { return nullptr; }
    virtual const map *as_map() const { return nullptr; }
    virtual const char *c_str() const { return nullptr; }
    template<class T> bool is() const { return dynamic_cast<const T *>(this) != nullptr; }
    template<class T> T &to() { return dynamic_cast<T &>(*this); }
    template<class T> const T &to() const { return dynamic_cast<const T &>(*this); }
    virtual std::unique_ptr<obj> copy() && = 0;
    std::string toString() const;
};

class True : public obj {
    bool operator <(const obj &a) const {
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const { return dynamic_cast<const True *>(&a) != 0; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const
        { out << "true"; }
    bool test_width(int &limit) const { limit -= 4; return limit >= 0; }
    std::unique_ptr<obj> copy() && { return make_unique<True>(std::move(*this)); }
};

class False : public obj {
    bool operator <(const obj &a) const {
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const { return dynamic_cast<const False *>(&a) != 0; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const
        { out << "false"; }
    bool test_width(int &limit) const { limit -= 5; return limit >= 0; }
    std::unique_ptr<obj> copy() && { return make_unique<False>(std::move(*this)); }
};

class number : public obj {
public:
    long	val;
    number(long l) : val(l) {}
    ~number() {}
    bool operator <(const obj &a) const {
	if (auto *b = dynamic_cast<const number *>(&a)) return val < b->val;
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (auto *b = dynamic_cast<const number *>(&a)) return val == b->val;
	return false; }
    bool operator==(long v) const { return val == v; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const {
        out << val; }
    bool test_width(int &limit) const
	{ char buf[32]; limit -= sprintf(buf, "%ld", val); return limit >= 0; }
    number *as_number() { return this; }
    const number *as_number() const { return this; }
    std::unique_ptr<obj> copy() && { return make_unique<number>(std::move(*this)); }
};

class string : public obj, public std::string {
public:
    string() {}
    string(const string &) = default;
    string(const std::string &a) : std::string(a) {}
    string(const char *a) : std::string(a) {}
    string(string &&) = default;
    string(std::string &&a) : std::string(a) {}
    string &operator=(const string &) & = default;
    string &operator=(string &&) & = default;
    ~string() {}
    bool operator <(const obj &a) const {
	if (const string *b = dynamic_cast<const string *>(&a))
	    return static_cast<const std::string &>(*this) <
		   static_cast<const std::string &>(*b);
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (const string *b = dynamic_cast<const string *>(&a))
	    return static_cast<const std::string &>(*this) ==
		   static_cast<const std::string &>(*b);
	return false; }
    bool operator ==(const char *str) const {
        return static_cast<const std::string &>(*this) == str; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const {
	out << '"' << *this << '"'; }
    bool test_width(int &limit) const { limit -= size()+2; return limit >= 0; }
    const char *c_str() const { return std::string::c_str(); }
    string *as_string() { return this; }
    const string *as_string() const { return this; }
    std::unique_ptr<obj> copy() && { return make_unique<string>(std::move(*this)); }
};

class map; // forward decl

typedef std::vector<std::unique_ptr<obj>> vector_base;
class vector : public obj, public vector_base {
public:
    vector() {}
    vector(const vector &) = default;
    vector(vector &&) = default;
    vector(const std::initializer_list<rvalue_reference_wrapper<obj>> &init) {
        for (auto o : init)
            push_back(o.get().copy()); }
    vector &operator=(const vector &) & = default;
    vector &operator=(vector &&) & = default;
    ~vector() {}
    bool operator <(const obj &a) const {
	if (const vector *b = dynamic_cast<const vector *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (**p1 < **p2) return true;
		if (**p1 != **p2) return false;
		p1++; p2++; }
	    return p2 != b->end(); }
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (const vector *b = dynamic_cast<const vector *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (**p1 != **p2) return false;
		p1++; p2++; } 
	    return (p1 == end() && p2 == b->end()); }
	return false; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const;
    bool test_width(int &limit) const {
	limit -= 2;
	for (auto &e : *this) {
	    if (!e->test_width(limit)) return false;
	    if ((limit -= 2) < 0 ) return false; }
	return true; }
    using vector_base::push_back;
    void push_back(bool t) {
        if (t) push_back(make_unique<True>(True()));
        else push_back(make_unique<False>(False())); }
    void push_back(long n) { push_back(make_unique<number>(number(n))); }
    void push_back(int n) { push_back((long)n); }
    void push_back(unsigned int n) { push_back((long)n); }
    void push_back(unsigned long n) { push_back((long)n); }
    void push_back(const char *s) { push_back(make_unique<string>(string(s))); }
    void push_back(vector &&v) { push_back(make_unique<vector>(std::move(v))); }
    void push_back(json::map &&);
    vector *as_vector() { return this; }
    const vector *as_vector() const { return this; }
    std::unique_ptr<obj> copy() && { return make_unique<vector>(std::move(*this)); }
};

typedef ordered_map<obj *, std::unique_ptr<obj>, obj::ptrless> map_base;
class map : public obj, public map_base {
public:
    map() {}
    map(const map &) = default;
    map(map &&) = default;
    map(const std::initializer_list<std::pair<std::string, obj &&>> &init) {
        for (auto &pair : init)
            (*this)[pair.first] = std::move(pair.second).copy(); }
    map &operator=(const map &) & = default;
    map &operator=(map &&) & = default;
    ~map() { for (auto &e : *this) delete e.first; }
    bool operator <(const obj &a) const {
	if (const map *b = dynamic_cast<const map *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (*p1->first < *p2->first) return true;
		if (*p1->first != *p2->first) return false;
		if (*p1->second < *p2->second) return true;
		if (*p1->second != *p2->second) return false;
		p1++; p2++; }
	    return p2 != b->end(); }
	return std::type_index(typeid(*this)) < std::type_index(typeid(a)); }
    bool operator ==(const obj &a) const {
	if (const map *b = dynamic_cast<const map *>(&a)) {
	    auto p1 = begin(), p2 = b->begin();
	    while (p1 != end() && p2 != b->end()) {
		if (*p1->first != *p2->first) return false;
		if (*p1->second != *p2->second) return false;
		p1++; p2++; }
	    return (p1 == end() && p2 == b->end()); }
	return false; }
    void print_on(std::ostream &out, int indent=0, int width=80, const char *pfx="") const;
    bool test_width(int &limit) const {
	limit -= 2;
	for (auto &e : *this) {
	    if (!e.first->test_width(limit)) return false;
	    if (!e.second->test_width(limit)) return false;
	    if ((limit -= 4) < 0 ) return false; }
	return true; }
    using map_base::count;
    map_base::size_type count(const char *str) const {
	string tmp(str);
        return count(&tmp); }
    map_base::size_type count(long n) const {
	number tmp(n);
        return count(&tmp); }
    //using map_base::operator[];
    obj *operator[](const std::unique_ptr<obj> &i) const {
	auto rv = find(i.get());
	if (rv != end()) return rv->second.get();
	return 0; }
    obj *operator[](const char *str) const {
	string tmp(str);
	auto rv = find(&tmp);
	if (rv != end()) return rv->second.get();
	return 0; }
    obj *operator[](const std::string &str) const {
	string tmp(str);
	auto rv = find(&tmp);
	if (rv != end()) return rv->second.get();
	return 0; }
    obj *operator[](long n) const {
	number tmp(n);
	auto rv = find(&tmp);
	if (rv != end()) return rv->second.get();
	return 0; }
private:
    class element_ref {
        map                     &self;
        std::unique_ptr<obj>    key;
        map_base::iterator      iter;
    public:
        element_ref(map &s, const char *k) : self(s) {
            string tmp(k);
            iter = self.find(&tmp);
            if (iter == self.end())
                key.reset(new string(std::move(tmp))); }
        element_ref(map &s, long k) : self(s) {
            number tmp(k);
            iter = self.find(&tmp);
            if (iter == self.end())
                key.reset(new number(std::move(tmp))); }
        element_ref(map &s, std::unique_ptr<obj> &&k) : self(s) {
            iter = self.find(k.get());
            if (iter == self.end())
                key = std::move(k); }
        bool operator=(bool t) {
            if (key)
                iter = self.emplace(key.release(),
                        std::unique_ptr<obj>(t ? (obj*)new True() : (obj*)new False())).first;
            else { assert(iter != self.end());
                iter->second.reset(t ? (obj*)new True() : (obj*)new False()); }
            return t; }
        const char *operator=(const char *v) {
            if (key)
                iter = self.emplace(key.release(), std::unique_ptr<obj>(new string(v))).first;
            else { assert(iter != self.end());
                iter->second.reset(new string(v)); }
            return v; }
        const std::string &operator=(const std::string &v) {
            if (key)
                iter = self.emplace(key.release(), std::unique_ptr<obj>(new string(v))).first;
            else { assert(iter != self.end());
                iter->second.reset(new string(v)); }
            return v; }
        long operator=(long v) {
            if (key)
                iter = self.emplace(key.release(), std::unique_ptr<obj>(new number(v))).first;
            else { assert(iter != self.end());
                iter->second.reset(new number(v)); }
            return v; }
        int operator=(int v) { return (int)(*this = (long)v); }
        unsigned int operator=(unsigned int v) { return (unsigned int)(*this = (long)v); }
        unsigned long operator=(unsigned long v) { return (unsigned long)(*this = (long)v); }
        vector &operator=(vector &&v) {
            if (key)
                iter = self.emplace(key.release(), make_unique<vector>(std::move(v))).first;
            else { assert(iter != self.end());
                iter->second = make_unique<vector>(std::move(v)); }
            return dynamic_cast<vector &>(*iter->second); }
        map &operator=(map &&v) {
            if (key)
                iter = self.emplace(key.release(), make_unique<map>(std::move(v))).first;
            else { assert(iter != self.end());
                iter->second = make_unique<map>(std::move(v)); }
            return dynamic_cast<map &>(*iter->second); }
        const std::unique_ptr<obj> &operator=(std::unique_ptr<obj> &&v) {
            if (key) iter = self.emplace(key.release(), std::move(v)).first;
            else { assert(iter != self.end());
                iter->second = std::move(v); }
            return iter->second; }
        obj &operator*() {
            assert(!key && iter != self.end());
            return *iter->second; }
        explicit operator bool() const { return !key; }
        obj *get() const { return key ? 0 : iter->second.get(); }
        obj *operator->() const { return key ? 0 : iter->second.get(); }
        operator vector&() {
            if (key) iter = self.emplace(key.release(), make_unique<vector>()).first;
            return dynamic_cast<vector &>(*iter->second); }
        operator map&() {
            if (key) iter = self.emplace(key.release(), make_unique<map>()).first;
            return dynamic_cast<map &>(*iter->second); }
        element_ref operator[](const char *str) {
            if (key) iter = self.emplace(key.release(), make_unique<map>()).first;
            map *m = dynamic_cast<map *>(iter->second.get());
            if (!m) throw std::runtime_error("lookup in non-map json object");
            return element_ref(*m, str); }
        element_ref operator[](const std::string &str) {
            if (key) iter = self.emplace(key.release(), make_unique<map>()).first;
            map *m = dynamic_cast<map *>(iter->second.get());
            if (!m) throw std::runtime_error("lookup in non-map json object");
            return element_ref(*m, str.c_str()); }
        element_ref operator[](long n) {
            if (key) iter = self.emplace(key.release(), make_unique<map>()).first;
            map *m = dynamic_cast<map *>(iter->second.get());
            if (!m) throw std::runtime_error("lookup in non-map json object");
            return element_ref(*m, n); }
        element_ref operator[](std::unique_ptr<obj> &&i) {
            if (key) iter = self.emplace(key.release(), make_unique<map>()).first;
            map *m = dynamic_cast<map *>(iter->second.get());
            if (!m) throw std::runtime_error("lookup in non-map json object");
            return element_ref(*m, std::move(i)); }
        template <class T> T &to() {
            if (key) iter = self.emplace(key.release(), make_unique<T>()).first;
            return dynamic_cast<T &>(*iter->second); }
    };
    friend std::ostream &operator<<(std::ostream &out, const element_ref &el);
public:
    element_ref operator[](const char *str) { return element_ref(*this, str); }
    element_ref operator[](const std::string &str) { return element_ref(*this, str.c_str()); }
    element_ref operator[](long n) { return element_ref(*this, n); }
    element_ref operator[](std::unique_ptr<obj> &&i) { return element_ref(*this, std::move(i)); }
    map_base::size_type erase(const char *str) {
	string tmp(str);
        return map_base::erase(&tmp); }
    map_base::size_type erase(long n) {
	number tmp(n);
        return map_base::erase(&tmp); }
    map *as_map() { return this; }
    const map *as_map() const { return this; }
    std::unique_ptr<obj> copy() && { return make_unique<map>(std::move(*this)); }
};

inline void vector::push_back(map &&m) { emplace_back(make_unique<map>(std::move(m))); }

std::istream &operator>>(std::istream &in, std::unique_ptr<obj> &json);
inline std::istream &operator>>(std::istream &in, obj *&json) {
    std::unique_ptr<obj> p;
    in >> p;
    if (in) json = p.release();
    return in;
}

inline std::ostream &operator<<(std::ostream &out, const obj *json) {
    json->print_on(out);
    return out; }
inline std::ostream &operator<<(std::ostream &out, const std::unique_ptr<obj> &json) {
    return out << json.get(); }
inline std::ostream &operator<<(std::ostream &out, const map::element_ref &el) {
    el->print_on(out);
    return out; }

class istream : public virtual std::istream {
public:
    istream(std::istream &s) : std::istream(s.rdbuf()) {}
};

class ostream : public virtual std::ostream {
public:
    ostream(std::ostream &s) : std::ostream(s.rdbuf()) {}
};

class iostream : public virtual istream, virtual ostream, virtual std::iostream {
public:
    iostream(std::iostream &s) : istream(s), ostream(s), std::iostream(s.rdbuf()) {}
};

}  // end namespace json

#endif /* _json_h_ */
