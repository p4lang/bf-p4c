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
    TablePrinter(std::ostream &s, std::vector<std::string> headers)
      : _s(s), _headers(headers) {
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

    void print() const {
        printSep();

        printRow(_headers);

        printSep();

        for (auto row : _data)
            printRow(row);

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
    std::vector<std::string> _headers;
    std::vector<unsigned> _colWidth;

    const unsigned cellPad = 2;
};

#endif  /* BF_P4C_COMMON_TABLE_PRINTER_H_ */
