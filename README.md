# Tofino back-end details

The backend is where most of the resource allocation decisions take
place.  Resource allocation passes should take extra ‘hints’ inputs to
drive decisions based on previous failed attempts that triggered
backtracking.  This is a potential exponential blowup, so care needs
to be taken to avoid attempts that are probably unprofitable -- tuning
will be needed.

To the extent that it does not complicate the code too much, it should
be parameterized based on architecture details.  The intent is
that the code should be reusable for multiple architecture families.

The code here is organized into `parde` (parser-deparser), `mau`
(match-action table), and `phv` (phv allocation and management) directories.
To some extent these are independent, but there are interdependecies.

#### parde

**TBD**

* Parser state splitting -- states that do too much (write too many
  output bytes) need to be split into multiple states

* Parser state combining -- small consecutive states can be combined.


#### mau

The mau code is organized around the `IR::MAU::Table` ir class, which
represents a Tofino-specific logical table.  Such a table has an (optional)
gateway, with an expression, condition, and (optional) payload action, an
(optional) match table, and zero or more attached tables (indirect, action
data, selector, meter, counter, ...).  There is a next table map that
contains references to sequences of other tables to run based on the
gateway result or action run.

Mau processing begins by converting the P4 IR into this form (this is
the 'mid-end'), which is prototyped in `extract_maupipe.cpp`.  Then the
code can reorganized by various optimization passes that will be needed:

- Gateway analysis and splitting -- gateway tables that are too complex
  for tofino must be split int multiple gateways.

- Gateway merging -- simple consecutive gateways can be combined into
  a single gateway

- Gateway duplication -- gateways that have multiple tables dependent
  on their result can be duplicated, with each duplicated gateway having
  fewer dependent tables.  This allows more flexibility for table scehduling
  and may only be done if table placement fails and backtracks.  A
  prototype implemention exists in `split_gateways.cpp`.

- Table analysis -- figure out what resources a logical table will need
  (at least number of memories, ixbar space, other units) for table
  placement to refer to.  Decide on width, exact match groups, ways, putting
  immediate data into overhead vs action data table etc.  Another place
  that we may backtrack to if table placement fails.  A partial prototype
  exists in `table_layout.cpp`

- Table insertion -- if later passes decide they need to insert new tables,
  we need a 'pass' to backtrack to and do that.  First time through this
  pass will do nothing, then other passes may trigger a 'new table needed'
  backtrack that backtracks to this pass to insert the table.

- Table reorg -- any optimizations that involve splitting or combining
  tables may occur here.  For example, actions that are too complex for
  tofino could be implemented by splitting off part of the action into a
  followon table.

- Table dependency analysis -- find match, action, and write(reverse)
  dependencies between tables

Once the these initial passes are complete, we can do the main table
placement analysis.  This pass will map logical tables to specific
stages and logical ids.  Gateways with no match table may be combined with
match tables with no gateway as part of this process.  Table sequences may
be reordered if dependencies allow to better fit.  Tables that do not fit
within a stage will be split into multiple tables.  A prototype implementation
exists in `table_placement.cpp`, but not properly support backtracking.

After table placement, tables will be allocated to specific resources
in their stage (some of this may be concurrent with placement, to the
extent that it affects placement).  Unused resources (memories) may be
added to tables to allow them to expand to larger than minimum required
size.

Flow analysis of metadata and header field use in tables then determines
which metadata fields are independent, as well as identifying all the
phv use constraints on fields based on how they are use in tables.

Once final PHV allocation has been done, tables may need to be modified to
work with the allocation.

- transform action statements that operate on fields that have been split
  by phv allocation into mulitple statements.

- allocate action data to the action bus based on which PHV registers need
  access to it.

a single pass over the final IR should suffice for generating asm code.

#### phv

PHV allocation and management interacts heavily with the other parts of the
compiler.  The basic design is to have an initial PHV pass that gathers
basic information on all header and metadata fields in the program, then passes
in mau and parde can augment this information with additional constraints as
the run.

Once most of the allocation decisions for other passes have been made, PHV
allocation will assign physical PHV slots for each field, possibly splitting
fields.  When this fails, PHV allocation needs to provide information about
why it is failing (running out of a particular size, or group, or ?) that
can be used by passes we backtrack to to modify their uses.

We can build an interference graph for all fields, allowing use to experiment
with graph coloring algorithms for PHV allocation, as well as simpler
greedy allocation.

