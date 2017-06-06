#ifndef PARTITION_REFINEMENT_H
#define PARTITION_REFINEMENT_H

#include <vector>
#include <set>

template <class T>
class PartitionRefinement {

    typedef std::vector<T> UniverseV;
    typedef typename UniverseV::size_type SetMarker;
    typedef typename std::vector<SetMarker> SetMarkerV;

    // All the elements of the universe.
    UniverseV elts;

    // The partitioning of the universe into sets.  Each element is the
    // starting index of this set in elts.
    SetMarkerV sets;

    // Map from element to the index in sets of the set containing it.
    std::map<T, SetMarker> elt_to_set;

    public:
        PartitionRefinement(std::set<T> in) {
            SetMarker initial = 0;
            sets.push_back(initial);

            for (auto it = in.begin(); it != in.end(); ++it) {
                elts.push_back(*it);
                elt_to_set[*it] = initial;
            }
        }

        /* Given a refinement set X, return a pair of sets (Y /\ X, Y \ X) for
         * each Y in the partition such that Y /\ X and Y \ X are not empty. */
        std::set< std::pair< std::set<T>, std::set<T> > >
        refine(std::set<T> refinement)
        {
            // Set indices that are undergoing partitioning in this refinement.
            std::map<SetMarker, std::set<T>> split_sets;

            for (auto it = refinement.begin(); it != refinement.end(); ++it) {
                T elt = *it;

                if (elt_to_set.find(elt) == elt_to_set.end())
                    continue;

                // Set currently containing elt.
                SetMarker set = elt_to_set.at(elt);

                // Index of the set that WILL contain elt at the end of the
                // operation.  (May not exist yet.)
                typename SetMarkerV::size_type set_idx = 0;
                for (; set_idx < sets.size(); set_idx++)
                    if (set == sets[set_idx])
                        break;
                assert(set_idx < sets.size());
                typename SetMarkerV::size_type split_set_idx = set_idx + 1;

                // If this is the first time splitting this set, create the new
                // set.
                if (split_sets.find(set) == split_sets.end()) {
                    sets.insert(
                        sets.begin() + split_set_idx,
                        split_set_idx == sets.size() ?
                            elts.size() : sets[split_set_idx]);
                    split_sets[set] = {elt};
                }
                // Otherwise, mark which (original) set this element was in.
                else {
                    split_sets[set].insert(elt);
                }

                SetMarker& split_set = sets[split_set_idx];

                // Find the position of elt in elts.
                typename UniverseV::size_type elt_idx = set;
                while (elts[elt_idx] != elt) {
                    elt_idx++;
                    assert(elt_idx < split_set);
                }

                // Swap the element with the last element in the set, then
                // decrement split_set to move the (new) last element from the
                // original set to the split_set set.
                T tmp = elts[split_set - 1];
                elts[split_set - 1] = elts[elt_idx];
                elts[elt_idx] = tmp;
                split_set--;
            }

            // If we discover a set Y such that Y \ X is empty, remove the
            // split Y + 1 (i.e. Y /\ X).  Note that because Y is now empty, *Y
            // = *Y + 1.
            for ( auto sets_it = sets.begin();
                  sets_it != sets.end();
                  ++sets_it )
            {
                if (split_sets.find(*sets_it) == split_sets.end())
                    continue;

                auto split_set = sets_it + 1;
                assert(split_set != sets.end());

                if (*sets_it == *split_set) {
                    split_sets.erase(*sets_it);
                    sets_it = sets.erase(sets_it);
                }
            }

            // Update the element-to-set map.
            for ( auto sets_it = sets.begin();
                  sets_it != sets.end();
                  ++sets_it )
            {
                if ( split_sets.find(*sets_it) == split_sets.end() )
                    continue;
                std::set<T> split_elts = split_sets[*sets_it];
                for ( auto split_elts_it = split_elts.begin();
                      split_elts_it != split_elts.end();
                      ++split_elts_it )
                {
                    elt_to_set[*split_elts_it] = *(sets_it + 1);
                }
            }

            // For each set in the in split_sets, copy its elements (Y /\ X)
            // and the next set (Y \ X) into a pair of sets to return.
            std::set< std::pair< std::set<T>, std::set<T> > > rv;
            for ( auto ss_it = split_sets.begin();
                  ss_it != split_sets.end();
                  ++ss_it)
            {
                std::set<T> y_minus_x = ss_it->second;
                std::set<T> y_and_x;

                SetMarker elt_end;
                auto sets_it = sets.begin();
                for ( ;
                      sets_it < sets.end();
                      ++sets_it)
                {
                    if (*sets_it == ss_it->first) {
                        auto next = sets_it + 1;
                        elt_end = next == sets.end() ?  elts.size() : *next;
                        break;
                    }
                }
                assert( sets_it != sets.end() );

                for ( auto elts_it = elts.begin() + ss_it->first;
                      elts_it < elts.begin() + elt_end;
                      ++elts_it )
                {
                    y_and_x.insert(*elts_it);
                }

                assert(y_and_x.size() > 0);
                assert(y_minus_x.size() > 0);
                rv.insert({ y_and_x, y_minus_x });
            }
            return rv;
        }

        /* Return the current partitioning (set of sets). */
        std::set< std::set<T> > get_partition(void) {
            std::set< std::set<T> > rv;
            for ( auto sets_it = sets.begin();
                  sets_it != sets.end();
                  ++sets_it )
            {
                typename UniverseV::size_type end_elt_idx =
                    sets_it + 1 >= sets.end() ? elts.size() : *(sets_it + 1);

                std::set<T> s;
                for ( typename UniverseV::size_type elt_idx = *sets_it;
                      elt_idx < end_elt_idx;
                      ++elt_idx )
                {
                    s.insert(elts[elt_idx]);
                }
                if (s.size() > 0)
                    rv.insert(s);
            }
            return rv;
        }

/* TODO: remove. 
        void print_debug(void) {
            cout << "elts: [ ";
            for (auto it = elts.begin(); it != elts.end(); it++)
                cout << *it << " ";
            cout << "]" << endl;

            cout << "sets: [ ";
            for (auto it = sets.begin(); it != sets.end(); ++it)
                cout << *it << " ";
            cout << "]" << endl;

            cout << "elt_to_set: { " << endl;
            for (auto it = elt_to_set.begin(); it != elt_to_set.end(); it++) {
                cout << "    " << it->first << " : " << it->second << endl;
            }
            cout << "}" << endl;
        }
*/

};

#endif /* PARTITION_REFINEMENT_H */
