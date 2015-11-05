# Tofino back-end design

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

### IR

There are a variety of Tofino-specific IR classes used to hold information
needed to track tofino resource use and manage the allocation of those
resources.

##### `IR::Tofino::Pipe`

An abstraction of a single Tofino pipeline, this object is basically just a
container for other (Parser, Deparser, and MAU) specific objects.  This becomes
the root object of the IR tree after the mid-end.

Because most visitors only care about part of the Pipe object (eg, just the MAU, or
just the Parser), we define special visitor bases `MauInspector`, `MauModifier`,
`MauTransform`, `PardeInspector`, `PardeModifier`, and `PardeTransform` that visit
just those parts of the tree of interest to Mau or Parde.  Other parts of the tree
are skipped.

##### `IR::Tofino::Parser`
##### `IR::Tofino::Deparser`

##### `IR::MAU::Table`

The mau code is largely organized around the `IR::MAU::Table` ir class, which
represents a Tofino-specific logical table.  Such a table has an (optional)
gateway, with an expression, condition, and (optional) payload action, an
(optional) match table, and zero or more attached tables (indirect, action
data, selector, meter, counter, ...).  There is a next table map that
contains references to sequences of other tables to run based on the
gateway result or action run.

- `gateway_expr`  boolean expression that the gateway tests, or `nullptr` if there is no gateway
- `gateway_payload`  action to run if the match-action table does not run
- `gateway_cond`  if `eval(gateway_expr) == gateway_cond` then the `match_table` should run.
   If there is no `gateway_expr` or no `match_table`, this is ignored.
- `match_table`  match table to run iff `gateway_expr == nullptr` or
  `eval(gateway_expr) == gateway_cond`
- `actions`  list of action functions that might be in the table.  **TBD:** probably need
  to differentiate default-only vs non-default-only vs other actions somehow?
- `attached`  list of attached support tables -- ternary indirection, action data, selection,
  meter, counter, stateful alu...
- `next`  map from gateway conditions and actions to control dependent table sequences.
  Keys are cstrings that may be action names or keywords.
  - `true` -- next to run iff `eval(gateway_expr) == true`.  Not allowed if there is a
      `match_table` and `gateway_cond == true`, since then the match table result applies.
  - `false` -- next to run iff `eval(gateway_expr) == false`.  Not allowed if there is a
      `match_table` and `gateway_cond == false`, since then the match table result applies.
  - *action*  -- next to run if the `match_table` runs this action.
  - `$miss`  -- next to run if the `match_table` runs and misses.  This will override if
	the action also specifies a next.
  - `default`  -- next to run if the `match_table` runs and nothing else applies.

`IR::MAU::Table` objects are initially created by the mid-end corresponding to each gateway
and match table in the P4 program.  These tables will then be manipulated (split, combined,
and reordered) by various passes to get them into a form where they can be fit into the
Tofino pipeline, then allocated to specific stages/logical ids/resources within the pipeline.

##### `IR::MAU::TableSeq`

A sequence of logical tables to run in order.  Each table will run, followed by any control
dependent tables, followed by the next table in the sequence.  By definition, tables in a
`TableSeq` are control-independent, but may be data-dependent.  The `TableSeq` also contains
a bit-matrix that tracks data dependencies between tables in the sequence including
their control-depedent tables.  Tables that are not data dependent may be reordered.

### Passes

#### mid-end

The first step in the Tofino backend is converting the P4-level IR into the
needed forms for the backend.  In most cases, this will be a fairly simple
wrapper around some P4-level IR objects, organizing them into the rough form
that tofino requires.

#### parde

Parser and deparser processing starts with extracting the state machine graph
from the P4-level IR.  Since the IR (currently) does not support loops, but the
state machine may involve loops, this will require using a representation that
breaks the loops.  We could extend the IR to allow loops (would require extending
the Visitor base classes to deal with loops rather than just detecting them and
throwing an error), but that may not be necessary.  A series of transformation passes
can then optimize the parser:

* Loop unrolling -- states that have backreferences (loops) can be unrolled by cloning
  the backreferenced tree, limited by the maximum header stack size involved

* Parser state splitting -- states that do too much (write too many
  output bytes) need to be split into multiple states.  States could also
  be split into minimal states that each do a single thing that will later
  bre recombined.

* Parser state combining -- small consecutive states can be combined.

It may be that simply splitting states into the smallest possible fragments and then
recombining them works well for general optimization.  Alternately, other things could
be tried.  The important thing is flexibility in the representation, to permit
experimentation.

Deparser handling in v1.1 is a matter of extracting the deparser from the parser state
machine and blackboxes that do deparser-relevant processing (checksum units, learning
filters, ...).  Its not clear whether this is best done from the P4-level parser IR,
or from some later state of the parser IR (after some backend transformations).

#### mau

Mau processing begins by converting the P4 IR into a pair of `IR::MAU::TableSeq`
objects (one for ingress, and one for egress -- this is the 'mid-end'), which is
prototyped in `extract_maupipe.cpp`.  Then the code can reorganized by various
optimization passes that will be needed:

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

Inspector passes to find constraints could logically be either part of the component
they are anaylzing (parde or mau) or part of phv allocation.


