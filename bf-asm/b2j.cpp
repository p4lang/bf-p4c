#include "bson.h"
#include <iostream>
#include <fstream>

int main(int ac, char **av) {
    if (ac != 3) {
        std::cerr << "usage " << av[0] << " <bson in> <json out>" << std::endl;
        return 1; }
    std::ifstream in(av[1]);
    if (!in) {
        std::cerr << "failed to open " << av[1] << std::endl;
        return 1; }
    json::obj *data = nullptr;
    if (!(in >> json::binary(data))) {
        std::cerr << "failed to read bson" << std::endl;
        return 1; }
    std::ofstream out(av[2]);
    if (!out) {
        std::cerr << "failed to open " << av[2] << std::endl;
        return 1; }
    if (!(out << data)) {
        std::cerr << "failed to write json" << std::endl;
        return 1; }
    return 0;
}
