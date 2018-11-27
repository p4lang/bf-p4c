#include "tofino/intrinsic_metadata.p4"

#define LOOP_BACK         68
#define MATCH_SCORE        2
#define MISMATCH_PENALTY   1
#define INSERTION_PENALTY  1
#define DELETION_PENALTY   1
#define MATRIX_SIZE        4 
#define NUM_I              2
#define NUM_J              2 

/* Sample P4 program */
header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type context_t {
    fields {
        i : 8;
        j : 8;
        insert : 8;
        delete : 8;
        match : 8;
	del_greater_ins : 8;
        del_greater_mat : 8;
        del_greater_zer : 8;
        ins_greater_mat : 8;
        ins_greater_zer : 8;
        mat_greater_zer : 8;
    }
}

header_type matrix_t {
    fields {
        val0 : 8;
        val1 : 8;
        val2 : 8;
        val3 : 8;
    }
}

header_type seq_t {
    fields {
        char : 8;
    }
}

parser start {
    return parse_smith_waterman;
}

header ethernet_t ethernet;
header seq_t seq1;
header seq_t seq2;
header matrix_t matrix;
header context_t ctx;

parser parse_smith_waterman {
    extract(ethernet);
    extract(seq1);
    extract(seq2);	
    extract(matrix);
    extract(ctx);	
    return ingress;
}

action fwd(){
  modify_field(ig_intr_md_for_tm.ucast_egress_port, 1);
}

action incr_column(){
  add_to_field(ctx.j, 1);
  modify_field(ig_intr_md_for_tm.ucast_egress_port, LOOP_BACK);
}

action incr_row(){
  add_to_field(ctx.i, 1);
  modify_field(ctx.j, 0);
  modify_field(ig_intr_md_for_tm.ucast_egress_port, LOOP_BACK);
}

action write_max1() {
  modify_field(matrix.val3, 0);
}  

action do_match() {
  add(ctx.match, matrix.val0, MATCH_SCORE);
  subtract(ctx.delete, matrix.val2, DELETION_PENALTY);
  subtract(ctx.insert, matrix.val1, INSERTION_PENALTY);
}  

action do_mismatch() {
  subtract(ctx.match, matrix.val0, MISMATCH_PENALTY);
  subtract(ctx.delete, matrix.val2, DELETION_PENALTY);
  subtract(ctx.insert, matrix.val1, INSERTION_PENALTY);
}  

action candidates()
{
    subtract(ctx.del_greater_ins, ctx.delete, ctx.insert);
    subtract(ctx.del_greater_mat, ctx.delete, ctx.match);
    subtract(ctx.del_greater_zer, ctx.delete, 0);
    subtract(ctx.ins_greater_mat, ctx.insert, ctx.match);
    subtract(ctx.ins_greater_zer, ctx.insert, 0);
    subtract(ctx.mat_greater_zer, ctx.insert, 0);
}

table seq_match { actions { compare; } default_action : compare; }
table subtract { actions { candidates; } default_action : candidates; }

table resolve {
  reads
  {
      ctx.del_greater_ins mask 0x80 : exact;
      ctx.del_greater_mat mask 0x80 : exact;
      ctx.del_greater_zer mask 0x80 : exact;	    
      ctx.ins_greater_mat mask 0x80 : exact;
      ctx.ins_greater_zer mask 0x80 : exact;
      ctx.mat_greater_zer mask 0x80 : exact;      
  }
  actions {
      write_max1;
  }    
}

table forward { actions { fwd; } default_action : fwd; }
table next_row { actions { incr_row; } default_action : incr_row; }
table next_column { actions { incr_column; } default_action : incr_column; }
table match { actions { do_match; } default_action : do_match; }
table mismatch { actions { do_mismatch; } default_action : do_mismatch; }

control ingress {
    if (valid(ethernet)) {
        if (seq1.char == seq2.char) {
           apply(match);
        } else {
           apply(mismatch);
        }
        apply(subtract);
	apply(resolve);
        apply(forward);
    }
}



