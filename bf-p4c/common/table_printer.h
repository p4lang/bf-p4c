#ifndef BF_P4C_COMMON_TABLE_PRINTER_H_
#define BF_P4C_COMMON_TABLE_PRINTER_H_

#include <iomanip>
#include "lib/exceptions.h"
#include "lib/log.h"

/**
 *  Usage: 
 *
 *  TablePrinter tp(std::cout, {"name", "size", "price"});
 *
 *  tp.addRow({"americano", "small", "$2.25"});
 *  tp.addRow({"latte", "medium", "$2.65"});
 *  tp.addRow({"espresso", "single", "$2"});
 *  tp.addRow({"mocha", "dark", "$5"});
 *
 *  tp.print();
 */

class TablePrinter {
 public:
    TablePrinter(std::ostream &s, std::vector<std::string> headers, bool alignLeft = false)
      : _s(s), _headers(headers), _alignLeft(alignLeft) {
        for (auto& h : headers)
            _colWidth.push_back(h.length());
    }

    void addRow(std::vector<std::string> row) {
        BUG_CHECK(row.size() == _headers.size(), "row size does not match header");

        _data.push_back(row);

        for (unsigned i = 0; i < row.size(); i++)
            if (row[i].length() > _colWidth[i])
                _colWidth[i] = row[i].length();
    }

    void addSep() {
        _seps.insert(_data.size());
    }

    void print() const {
        printSep();

        printRow(_headers);

        printSep();

        for (unsigned i = 0; i < _data.size(); i++) {
            printRow(_data.at(i));
            if (_seps.count(i)) printSep();
        }

        printSep();
    }

 private:
    unsigned getTableWidth() const {
        unsigned rv = 0;
        for (auto cw : _colWidth)
            rv += cw + cellPad;
        return rv + _headers.size() + 1;
    }

    void printSep() const {
        _s << std::string(getTableWidth(), '-');
        _s << std::endl;
    }

    void printCell(unsigned col, const std::string& data) const {
        unsigned width = _colWidth.at(col);
        if (_alignLeft) _s << std::left;
        _s << std::setw(width + cellPad);
        _s << data;
    }

    void printRow(const std::vector<std::string>& row) const {
        for (unsigned i = 0; i < row.size(); i++) {
            _s << "|";

            printCell(i, row.at(i));

            if (i == row.size() - 1) _s << "|";
        }
        _s << std::endl;
    }

    std::ostream &_s;

    std::vector<std::vector<std::string>> _data;
    std::set<unsigned> _seps;

    std::vector<std::string> _headers;
    std::vector<unsigned> _colWidth;

    bool _alignLeft = false;
    const unsigned cellPad = 2;
};

#endif  /* BF_P4C_COMMON_TABLE_PRINTER_H_ */
