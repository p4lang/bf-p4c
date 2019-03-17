#ifndef BF_P4C_PHV_UTILS_REPORT_H_
#define BF_P4C_PHV_UTILS_REPORT_H_

#include "bf-p4c/phv/utils/utils.h"

namespace PHV {

class AllocationReport {
    const PhvUse& uses;
    const Allocation& alloc;
    bool printMetricsOnly = false;

    ordered_map<boost::optional<gress_t>,
        ordered_map<PHV::Type,
          ordered_map<Allocation::ContainerAllocStatus, int>>> alloc_status;

    ordered_map<PHV::Container, int> partial_containers_stat;

    ordered_map<PHV::Container, int> container_to_bits_used;

    ordered_map<PHV::Container, int> container_to_bits_allocated;

    ordered_map<PHV::Container, boost::optional<gress_t>> container_to_gress;

    int total_allocated_bits = 0;
    int total_unallocated_bits = 0;
    int valid_ingress_unallocated_bits = 0;
    int valid_egress_unallocated_bits = 0;

    static std::string
    formatPercent(int div, int den) {
        std::stringstream ss;
        ss << boost::format("(%=6.3g%%)") % (100.0 * div / den);
        return ss.str();
    }

    static std::string
    formatUsage(int used, int total, bool show_total = false) {
        std::stringstream ss;
        ss << used << " ";
        if (show_total) ss << "/ " << total << " ";
        ss << formatPercent(used, total);
        return ss.str();
    }

    static std::string
    to_string(const std::set<gress_t>& gress) {
       std::stringstream ss;
       std::string sep = "";
       for (auto gr : gress) {
           ss << sep;
           ss << toSymbol(gr);
           sep = "/";
       }
       return ss.str();
    }

    /// Information about PHV containers in each MAU group
    struct MauGroupInfo {
        size_t  size = 0;
        int     groupID = 0;
        size_t  containersUsed = 0;
        size_t  bitsUsed = 0;
        size_t  bitsAllocated = 0;
        size_t  totalContainers = 0;
        std::set<gress_t> gress;   // MAU group can consists containers of mixed gress

        MauGroupInfo() {}

        explicit MauGroupInfo(size_t sz, int i, bool cont, size_t used, size_t allocated,
                boost::optional<gress_t> gr)
            : size(sz), groupID(i), bitsUsed(used), bitsAllocated(allocated) {
            containersUsed = cont ? 1 : 0;
            if (gr) gress.insert(*gr);
            totalContainers = Device::phvSpec().numContainersInGroup();
        }

        void update(bool cont, size_t used, size_t allocated, boost::optional<gress_t> gr) {
            containersUsed += (cont ? 1 : 0);
            bitsUsed += used;
            bitsAllocated += allocated;
            if (gr) gress.insert(*gr);
        }
    };

    /// Information about T-PHV containers in each collection
    struct TagalongCollectionInfo {
        std::map<PHV::Type, size_t> containersUsed;
        std::map<PHV::Type, size_t> bitsUsed;
        std::map<PHV::Type, size_t> bitsAllocated;
        std::map<PHV::Type, size_t> totalContainers;

        boost::optional<gress_t> gress;

        size_t getTotalUsedBits() {
            size_t rv = 0;
            for (auto kv : bitsUsed)
                rv += kv.second;
            return rv;
        }

        size_t getTotalAllocatedBits() {
            size_t rv = 0;
            for (auto kv : bitsAllocated)
                rv += kv.second;
            return rv;
        }

        size_t getTotalAvailableBits() {
            size_t rv = 0;
            for (auto& kv : totalContainers)
                rv += (size_t)kv.first.size() * kv.second;
            return rv;
        }

        std::string printUsage(PHV::Type type) {
            auto used = containersUsed[type];
            auto total = totalContainers[type];

            return formatUsage(used, total);
        }

        std::string printTotalUsage() {
            auto total = getTotalAvailableBits();
            auto used = getTotalUsedBits();

            return formatUsage(used, total);
        }

        std::string printTotalAlloc() {
            auto total = getTotalAvailableBits();
            auto alloced = getTotalAllocatedBits();

            return formatUsage(alloced, total);
        }
    };

 public:
    explicit AllocationReport(const Allocation& alloc, bool printMetricsOnly = false)
        : uses(*(alloc.uses_i)), alloc(alloc), printMetricsOnly(printMetricsOnly) { }

    /// @returns a summary of the status of each container by type and gress.
    cstring printSummary() {
        collectStatus();

        std::stringstream ss;

        if (!printMetricsOnly)
            ss << printAllocation() << std::endl;

        ss << printContainerStatus() << std::endl;
        ss << printOverlayStatus() << std::endl;
        ss << printOccupancyMetrics() << std::endl;

        return ss.str();
    }

 private:
    void collectStatus();

    cstring printAllocation() const;
    cstring printOverlayStatus() const;
    cstring printContainerStatus();
    cstring printOccupancyMetrics() const;
    cstring printMauGroupsOccupancyMetrics() const;
    cstring printTagalongCollectionsOccupancyMetrics() const;
};

}  // namespace PHV

#endif  /* BF_P4C_PHV_UTILS_REPORT_H_ */
