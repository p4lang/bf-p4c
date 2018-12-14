#include "bf-p4c/phv/utils/report.h"
#include <numeric>
#include "bf-p4c/common/table_printer.h"

using ContainerAllocStatus = PHV::Allocation::ContainerAllocStatus;

void PHV::AllocationReport::collectStatus() {
    // TODO(yumin): code duplication of available_spots()
    // Compute status.
    for (auto kv : alloc) {
        PHV::Container c = kv.first;
        ContainerAllocStatus status = ContainerAllocStatus::EMPTY;
        container_to_bits_used[c] = 0;
        container_to_bits_allocated[c] = 0;
        bitvec allocatedBits;
        auto& slices = kv.second.slices;

        auto gress = kv.second.gress;
        container_to_gress[c] = gress;

        for (auto slice : slices) {
            allocatedBits |= bitvec(slice.container_slice().lo, slice.container_slice().size());
            total_allocated_bits += slice.width();
            container_to_bits_allocated[c] += slice.width();
        }

        if (allocatedBits == bitvec(0, c.size())) {
            status = ContainerAllocStatus::FULL;
            container_to_bits_used[c] = c.size();
        } else if (!allocatedBits.empty()) {
            int used = std::accumulate(allocatedBits.begin(),
                                       allocatedBits.end(), 0,
                                       [] (int a, int) { return a + 1; });
            partial_containers_stat[c] = c.size() - used;
            container_to_bits_used[c] = used;
            total_unallocated_bits += partial_containers_stat[c];
            if (slices.size() > 1
                || (slices.size() == 1 && !slices.begin()->field()->no_pack())) {
                if (gress == INGRESS) {
                    valid_ingress_unallocated_bits += partial_containers_stat[c];
                } else {
                    valid_egress_unallocated_bits += partial_containers_stat[c];
                }
            }
            status = ContainerAllocStatus::PARTIAL;
        }

        alloc_status[(*alloc.getStatus(c)).gress][c.type()][status]++;
    }
}

cstring
PHV::AllocationReport::printOverlayStatus() const {
    std::stringstream ss;

    // Compute overlay status.
    ordered_map<PHV::Container, int> overlay_result;
    int overlay_statistics[2][2] = {{0}};
    for (auto kv : alloc) {
        PHV::Container c = kv.first;
        int n_overlay = -c.size();
        for (auto i = c.lsb(); i <= c.msb(); ++i) {
            const auto& slices = kv.second.slices;
            n_overlay += std::accumulate(
                slices.begin(), slices.end(), 0,
                [&] (int l, const PHV::AllocSlice& r) {
                    return l + r.container_slice().contains(i); }); }
        if (n_overlay > 0) {
            overlay_result[c] = n_overlay;
            if (c.type().kind() == PHV::Kind::tagalong) {
                overlay_statistics[*kv.second.gress][0] += n_overlay;
            } else {
                overlay_statistics[*kv.second.gress][1] += n_overlay; } } }

    if (LOGGING(2)) {
        ss << "======== CONTAINER OVERLAY STAT ===========" << std::endl;
        ss << "TOTAL INGRESS T-PHV OVERLAY BITS: " << overlay_statistics[INGRESS][0] << std::endl;
        ss << "TOTAL INGRESS PHV OVERLAY BITS: "   << overlay_statistics[INGRESS][1] << std::endl;
        ss << "TOTAL EGRESS T-PHV OVERLAY BITS: "  << overlay_statistics[EGRESS][0] << std::endl;
        ss << "TOTAL EGRESS PHV OVERLAY BITS: "    << overlay_statistics[EGRESS][1] << std::endl;

        if (LOGGING(3) && !overlay_result.empty()) {
            TablePrinter tp(ss, { "Container", "Gress", "Container Slice", "Field Slice" },
                           TablePrinter::Align::LEFT);

            for (auto& kv : overlay_result) {
                auto container = kv.first;
                auto gress = container_to_gress.at(container);

                bool first = true;
                for (const auto& slice : alloc.slices(kv.first)) {
                    std::stringstream container_slice, field_slice;

                    if (slice.container_slice().size() != int(slice.container().size()))
                        container_slice << "[" << slice.container_slice().lo << ":" <<
                        slice.container_slice().hi << "]";
                    if (slice.field_slice().size() != slice.field()->size)
                        field_slice << "[" << slice.field_slice().lo << ":" <<
                        slice.field_slice().hi << "]";

                    tp.addRow({first ? std::string(container.toString().c_str()) : "",
                               first ? std::string(toSymbol(*gress).c_str()) : "",
                               container_slice.str(),
                               std::string(slice.field()->name) + field_slice.str()
                              });
                    first = false;
                }

                tp.addRow({"", "", "", std::to_string(kv.second) + " bits overlaid"});
                tp.addBlank();
            }

            tp.print();
        }

        // Output Partial Containers
        ss << "======== PARTIAL CONTAINERS STAT ==========" << std::endl;
        ss << "TOTAL UNALLOCATED BITS: " << total_unallocated_bits << std::endl;
        ss << "VALID INGRESS UNALLOCATED BITS: " << valid_ingress_unallocated_bits << std::endl;
        ss << "VALID EGRESS UNALLOCATED BITS: " << valid_egress_unallocated_bits << std::endl;

        if (LOGGING(3)) {
            for (const auto& kv : partial_containers_stat) {
                ss << kv.first << " has unallocated bits: " << kv.second << std::endl;
                for (const auto& slice : alloc.slices(kv.first)) {
                    ss << slice << std::endl; } } }

        // compute tphv fields allocated on phv fields
        int total_tphv_on_phv = 0;
        ordered_map<PHV::Container, int> tphv_on_phv;
        for (auto kv : alloc) {
            PHV::Container c = kv.first;
            if (c.is(PHV::Kind::tagalong)) {
                continue; }
            int n_tphvs = 0;
            for (auto slice : kv.second.slices) {
                if (slice.field()->is_tphv_candidate(uses)) {
                    n_tphvs += slice.width(); } }
            if (n_tphvs == 0) continue;
            tphv_on_phv[c] = n_tphvs;
            total_tphv_on_phv += n_tphvs; }

        ss << "======== TPHV ON PHV STAT ========" << std::endl;
        ss << "Total bits: " << total_tphv_on_phv << std::endl;

        if (LOGGING(3)) {
            for (auto kv : tphv_on_phv) {
                ss << kv.first << " has " << kv.second << " bits " << std::endl;
                for (const auto& slice : alloc.slices(kv.first)) {
                    if (slice.field()->is_tphv_candidate(uses)) {
                        ss << slice << std::endl; } } } } }

    return ss.str();
}

cstring
PHV::AllocationReport::printContainerStatus() {
    std::stringstream ss;

    if (LOGGING(3)) {
        // Print container status.
        ss << "CONTAINER STATUS (after allocation so far):" << std::endl;
        ss << boost::format("%1% %|10t| %2% %|20t| %3% %|30t| %4%\n")
            % "GRESS" % "TYPE" % "STATUS" % "COUNT";

        bool first_by_gress = true;
        auto gresses = std::vector<boost::optional<gress_t>>({INGRESS, EGRESS, boost::none});
        auto statuses = {ContainerAllocStatus::EMPTY,
                         ContainerAllocStatus::PARTIAL,
                         ContainerAllocStatus::FULL};
        for (auto gress : gresses) {
            first_by_gress = true;
            for (auto status : statuses) {
                for (auto type : Device::phvSpec().containerTypes()) {
                    if (alloc_status[gress][type][status] == 0)
                        continue;
                    std::stringstream ss_gress;
                    std::string s_status;
                    ss_gress << gress;
                    switch (status) {
                      case ContainerAllocStatus::EMPTY:   s_status = "EMPTY"; break;
                      case ContainerAllocStatus::PARTIAL: s_status = "PARTIAL"; break;
                      case ContainerAllocStatus::FULL:    s_status = "FULL"; break; }
                    ss << boost::format("%1% %|10t| %3% %|20t| %2% %|30t| %4%\n")
                          % (first_by_gress  ? ss_gress.str() : "")
                          % type.toString()
                          % s_status
                          % alloc_status[gress][type][status];
                    first_by_gress = false; } } }
        ss << std::endl;
    }

    return ss.str();
}

cstring
PHV::AllocationReport::printMauGroupsOccupancyMetrics() const {
    const auto& phvSpec = Device::phvSpec();

    ordered_map<bitvec, MauGroupInfo> mauGroupInfos;

    // Extract MAU group specific information from phvSpec
    std::pair<int, int> numBytes = phvSpec.mauGroupNumAndSize(PHV::Type::B);
    std::pair<int, int> numHalfs = phvSpec.mauGroupNumAndSize(PHV::Type::H);
    std::pair<int, int> numWords = phvSpec.mauGroupNumAndSize(PHV::Type::W);

    for (auto cid : Device::phvSpec().physicalContainers()) {
        PHV::Container c = Device::phvSpec().idToContainer(cid);

        if (boost::optional<bitvec> mauGroup = phvSpec.mauGroup(cid)) {
            int groupID = -1;
            // groupID represents the unique string that identifies an MAU group
            size_t numContainers = 0;
            if (c.type() == PHV::Type::B) {
                groupID = (c.index() / numBytes.second) + numWords.first;
                numContainers = numBytes.second;
            } else if (c.type() == PHV::Type::H) {
                groupID = (c.index() / numHalfs.second) + numWords.first + numBytes.first;
                numContainers = numHalfs.second;
            } else if (c.type() == PHV::Type::W) {
                groupID = c.index() / numWords.second;
                numContainers = numWords.second;
            } else {
                // xxx(Deep): Handle non-normal PHV containers
                continue;
            }

            bool containerUsed = (container_to_bits_used.at(c) != 0);
            auto bits_used = container_to_bits_used.at(c);
            auto bits_allocated = container_to_bits_allocated.at(c);
            auto gress = container_to_gress.at(c);

            if (mauGroupInfos.count(mauGroup.get())) {
                mauGroupInfos[mauGroup.get()].update(containerUsed,
                        bits_used, bits_allocated, gress);
            } else {
                mauGroupInfos[mauGroup.get()] = MauGroupInfo(c.size(), groupID,
                        containerUsed, bits_used, bits_allocated, numContainers, gress);
            }
        }
    }

    std::stringstream ss;
    ss << std::endl << "MAU Groups:" << std::endl;

    TablePrinter tp(ss, {
       "MAU Group", "Gress", "Containers Used", "Bits Used", "Bits Allocated", "Available Bits"
       }, TablePrinter::Align::CENTER);

    auto tContainersUsed = 0, tBitsUsed = 0, tBitsAllocated = 0,
         tTotalBits = 0, tTotalContainers = 0;

    for (auto containerSize : Device::phvSpec().containerSizes()) {
        // Calculate total size-wise
        auto sz_containersUsed = 0, sz_bitsUsed = 0, sz_bitsAllocated = 0,
             sz_totalBits = 0, sz_totalContainers = 0, size = 0;

        for (auto mauGroup : Device::phvSpec().mauGroups(containerSize)) {
            auto& info = mauGroupInfos[mauGroup];

            size = (size == 0) ? info.size : size;
            sz_containersUsed += info.containersUsed;
            sz_bitsUsed += info.bitsUsed;
            sz_bitsAllocated += info.bitsAllocated;
            auto totalBits = info.totalContainers * info.size;
            sz_totalBits += totalBits;
            sz_totalContainers += info.totalContainers;

            std::stringstream group, containers, bits;
            group << Device::phvSpec().idToContainer(*mauGroup.min()) << "--"
                  << Device::phvSpec().idToContainer(*mauGroup.max());

            tp.addRow({group.str(),
                       info.bitsUsed ? to_string(info.gress) : "",
                       formatUsage(info.containersUsed, info.totalContainers),
                       formatUsage(info.bitsUsed, totalBits),
                       formatUsage(info.bitsAllocated, totalBits),
                       std::to_string(totalBits)});
        }

        if (Device::phvSpec().mauGroups(containerSize).size() != 0) {
            // Size wise occupancy metrics
            // Ensure that these lines appears only for B, H, and W; not for TB, TH, TW
            tContainersUsed += sz_containersUsed;
            tBitsUsed += sz_bitsUsed;
            tBitsAllocated += sz_bitsAllocated;
            tTotalBits += sz_totalBits;
            tTotalContainers += sz_totalContainers;

            std::stringstream group;
            group << "Usage for " << size << "b";

            tp.addBlank();

            tp.addRow({group.str(),
                       "",
                       formatUsage(sz_containersUsed, sz_totalContainers),
                       formatUsage(sz_bitsUsed, sz_totalBits),
                       formatUsage(sz_bitsAllocated, sz_totalBits),
                       std::to_string(sz_totalBits)
                      });

            tp.addSep();
        }
    }

    // Print "Overal usage" stats.

    tp.addRow({"Overall PHV Usage",
               "",
               formatUsage(tContainersUsed, tTotalContainers),
               formatUsage(tBitsUsed, tTotalBits),
               formatUsage(tBitsAllocated, tTotalBits),
               std::to_string(tTotalBits)
              });

    tp.print();

    return ss.str();
}

cstring
PHV::AllocationReport::printTagalongCollectionsOccupancyMetrics() const {
    const auto& phvSpec = Device::phvSpec();

    std::map<unsigned, TagalongCollectionInfo> tagalongCollectionInfos;

    auto tagalongCollectionSpec = phvSpec.getTagalongCollectionSpec();

    for (unsigned i = 0; i < phvSpec.getNumTagalongCollections(); i++) {
        auto& collectionInfo = tagalongCollectionInfos[i];

        for (auto& kv : tagalongCollectionSpec)
            collectionInfo.totalContainers[kv.first] = kv.second;
    }

    for (auto& kv : container_to_bits_used) {
        auto container = kv.first;
        auto bits_used_in_container = kv.second;
        auto bits_allocated_in_container = container_to_bits_allocated.at(container);
        auto gress = container_to_gress.at(container);

        if (!container.is(PHV::Kind::tagalong))
            continue;

        if (bits_used_in_container == 0)
            continue;

        int collectionID = phvSpec.getTagalongCollectionId(container);
        auto& collectionInfo = tagalongCollectionInfos[collectionID];

        collectionInfo.containersUsed[container.type()]++;
        collectionInfo.bitsUsed[container.type()] += bits_used_in_container;
        collectionInfo.bitsAllocated[container.type()] += bits_allocated_in_container;

        if (collectionInfo.gress && gress) {
            BUG_CHECK(*(collectionInfo.gress) == *gress,
                    "Tagalong collection for container %1% assigned with fields from both "
                    "ingress and egress?", container);
        }

        collectionInfo.gress = gress;
    }

    std::stringstream ss;
    ss << std::endl << "Tagalong Collections:" << std::endl;

    TablePrinter tp(ss, {
       "Collection",
       "Gress",
       "8b Containers Used",
       "16b Containers Used",
       "32b Containers Used",
       "Bits Used",
       "Bits Allocated"
    });

    std::map<PHV::Type, int> totalUsed;
    std::map<PHV::Type, int> totalAvail;

    int totalUsedBits = 0, totalAllocatedBits = 0, totalAvailBits = 0;

    for (auto& kv : tagalongCollectionInfos) {
        auto& info = kv.second;

        tp.addRow({std::to_string(kv.first),
                  info.getTotalUsedBits() ? std::string(toSymbol(*(info.gress)).c_str()) : "",
                  info.printUsage(PHV::Type::TB),
                  info.printUsage(PHV::Type::TH),
                  info.printUsage(PHV::Type::TW),
                  info.printTotalUsage(),
                  info.printTotalAlloc()});

        for (auto type : { PHV::Type::TB, PHV::Type::TH, PHV::Type::TW }) {
            totalUsed[type] += info.containersUsed[type];
            totalAvail[type] += info.totalContainers[type];
        }

        totalUsedBits += info.getTotalUsedBits();
        totalAllocatedBits += info.getTotalAllocatedBits();
        totalAvailBits += info.getTotalAvailableBits();
    }

    tp.addRow({"Total",
               "",
               formatUsage(totalUsed[PHV::Type::TB], totalAvail[PHV::Type::TB]),
               formatUsage(totalUsed[PHV::Type::TH], totalAvail[PHV::Type::TH]),
               formatUsage(totalUsed[PHV::Type::TW], totalAvail[PHV::Type::TW]),
               formatUsage(totalUsedBits, totalAvailBits),
               formatUsage(totalAllocatedBits, totalAvailBits)});

    tp.print();

    return ss.str();
}

cstring
PHV::AllocationReport::printOccupancyMetrics() const {
    std::stringstream ss;
    ss << std::endl << "PHV Allocation State" << std::endl;
    ss << printMauGroupsOccupancyMetrics();
    ss << std::endl;
    if (Device::currentDevice() == Device::TOFINO)
        ss << printTagalongCollectionsOccupancyMetrics();
    return ss.str();
}
