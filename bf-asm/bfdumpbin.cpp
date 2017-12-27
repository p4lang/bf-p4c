#include <inttypes.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <string>

struct {
    bool        oneLine;
} options;

int dump_bin (FILE *fd) {

    uint32_t atom_typ = 0;
    while (fread(&atom_typ, 4, 1, fd) == 1) {

        if ((atom_typ >> 24) == 'R') {
            // R block -- writing a single 32-bit register via 32-bit PCIe address
            uint32_t reg_addr = 0, reg_data = 0;
            if (fread(&reg_addr, 4, 1, fd) != 1) return -1;
            if (fread(&reg_data, 4, 1, fd) != 1) return -1;
            printf("R%08x: %08x\n", reg_addr, reg_data);
        } else if ((atom_typ >> 24) == 'B') {
            // B block -- write a range of 32-bit registers via 64-bit PCIe address
            // size of the range is specified as count * width (in bits), which must
            // always be a multiple of 32

            uint64_t addr = 0;
            uint32_t count = 0;
            uint32_t width = 0;

            if (fread(&addr, 8, 1, fd) != 1) return -1;
            if (fread(&width, 4, 1, fd) != 1) return -1;
            if (fread(&count, 4, 1, fd) != 1) return -1;
            printf("B%08" PRIx64 ": %xx%x", addr, width, count);
            if ((uint64_t)count * width % 32 != 0)
                printf("  (not a multiple of 32 bits!)");
            count = (uint64_t)count * width / 32;
            uint32_t data, prev;
            int repeat = 0, col = 0;
            for (unsigned i = 0; i < count; ++i) {
                if (fread(&data, 4, 1, fd) != 1) return -1;
                if (i != 0 && data == prev) {
                    repeat++;
                    continue; }
                if (repeat > 0) {
                    printf(" x%-7d", repeat+1);
                    if (++col > 8) col = 0; }
                repeat = 0;
                if (!options.oneLine && col++ % 8 == 0) printf("\n   ");
                printf(" %08x", prev = data); }
            if (repeat > 0)
                printf(" x%d", repeat+1);
            printf("\n");
        } else if ((atom_typ >> 24) == 'D') {
            // D block -- write a range of 128-bit memory via 64-bit chip address
            // size of the range is specified as count * width (in bits), which must
            // always be a multiple of 64

            uint64_t addr = 0;
            uint32_t count = 0;
            uint32_t width = 0;

            if (fread(&addr, 8, 1, fd) != 1) return -1;
            if (fread(&width, 4, 1, fd) != 1) return -1;
            if (fread(&count, 4, 1, fd) != 1) return -1;
            printf("D%011" PRIx64 ": %xx%x", addr, width, count);
            if ((uint64_t)count * width % 64 != 0)
                printf("  (not a multiple of 64 bits!)");

            width /= 8;

            uint64_t chunk[2], prev_chunk[2];
            int repeat = 0, col = 0;
            for (unsigned i = 0; i < count*width; i += 16) {
                if (fread(chunk, sizeof(uint64_t), 2, fd) != 2) return -1;
                if (i != 0 && chunk[0] == prev_chunk[0] && chunk[1] == prev_chunk[1]) {
                    repeat++;
                    continue; }
                if (repeat > 0) {
                    printf(" x%d", repeat+1);
                    col = 0; }
                repeat = 0;
                if (!options.oneLine && col++ % 2 == 0) printf("\n   ");
                printf(" %016" PRIx64 "%016" PRIx64, prev_chunk[1] = chunk[1],
                       prev_chunk[0] = chunk[0]); }

            if (repeat > 0) {
                printf(" x%d", repeat+1);
                col = 0; }

            if (count * width % 16 == 8) {
                if (fread(chunk, sizeof(uint64_t), 1, fd) != 1) return -1;
                if (!options.oneLine && col % 2 == 0) printf("\n   ");
                printf(" %016" PRIx64, chunk[0]); }
            printf("\n");

        } else {
            fprintf(stderr, "\n");
            fprintf(stderr, "Parse error: atom_typ=%x (%c)\n", atom_typ, atom_typ >> 24 );
            fprintf(stderr, "fpos=%lu <%lxh>\n", ftell(fd), ftell(fd) );
            fprintf(stderr, "\n");

            return -1;
        }

    }

    return ferror(fd) ? -1 : 0;
}

int main(int ac, char **av) {
    int error = 0;
    for (int i = 1; i < ac; ++i) {
        if (*av[i] == '-') {
            for (char *arg = av[i]+1; *arg;)
                switch (*arg++) {
                case 'L':
                    options.oneLine = true;
                    break;
                default:
                    fprintf(stderr, "ignoring argument -%c\n", *arg);
                    error = 1; }
        } else if (FILE *fp = fopen(av[i], "r")) {
            unsigned char magic[4] = {};
            fread(magic, 4, 1, fp);
            if (magic[0] == 0 && magic[3] && strchr("RDB", magic[3])) {
                rewind(fp);
                error |= dump_bin(fp);
                fclose(fp);
            } else if (magic[0] == 0x1f && magic[1] == 0x8b) {
                fclose(fp);
                fp = popen((std::string("zcat < ") + av[i]).c_str(), "r");
                error |= dump_bin(fp);
                pclose(fp);
            } else {
                fprintf(stderr, "%s: Unknown file format\n", av[i]);
                fclose(fp);
            }
        } else {
            fprintf(stderr, "Can't open %s\n", av[i]);
            error = 1;
        }
    }
    if (error == 1)
        fprintf(stderr, "usage: %s <file>\n", av[0]);
    return error;
}
