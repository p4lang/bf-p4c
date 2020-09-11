control npb_ing_sff_top (
	inout switch_header_transport_t                 hdr_0,
	inout switch_ingress_metadata_t                 ig_md,
	in    ingress_intrinsic_metadata_t              ig_intr_md,
	in    ingress_intrinsic_metadata_from_parser_t  ig_intr_md_from_prsr,
	inout ingress_intrinsic_metadata_for_deparser_t ig_intr_md_for_dprsr,
	inout ingress_intrinsic_metadata_for_tm_t       ig_intr_md_for_tm
) {

	bit<8> hdr_nsh_type1_si_predec; // local copy used for pre-decrementing prior to forwarding lookup.

	// =========================================================================
	// Notes
	// =========================================================================

	// Note: bitmask defined as follows....
	//
	//   [0:0] sf  #1: ingress basic/advanced
	//   [1:1] sf  #2: unused (was multicast)
	//   [2:2] sf  #3: egress proxy

	// =========================================================================
	// Table #1 - SI  Decrement
	// =========================================================================

	// this table just does a 'pop count' on the bitmask....

//	bit<8> nsh_si_dec_amount;
	bit<2> ig_md_nsh_md_sf_bitmask_2_1;

	action new_si(
		bit<8> dec
	) {
//		ig_md.nsh_md.si = ig_md.nsh_md.si |-| (bit<8>)dec; // saturating subtract
//		nsh_si_dec_amount = dec;
		hdr_nsh_type1_si_predec = dec;
	}

	// NOTE: SINCE THE FIRST SF HAS ALREADY RUN, WE ONLY NEED TO ACCOUNT FOR
	// THE REMAINING SFs...

	// this is code we'd like to use, but it doesn't work! -- barefoot bug?
/*
	table ing_sff_dec_si {
		key = {
			ig_md.nsh_md.sf_bitmask[2:1] : exact;
		}
		actions = {
			new_si;
		}
		const entries = {
			(0)  : new_si(0); // 0 bits set
			(1)  : new_si(1); // 1 bits set
			(2)  : new_si(1); // 1 bits set
			(3)  : new_si(2); // 2 bits set
		}
	}
*/
/*
	table ing_sff_dec_si {
		key = {
			hdr_0.nsh_type1.si : exact;
//			ig_md.nsh_md.sf_bitmask[2:1] : exact;
			ig_md_nsh_md_sf_bitmask_2_1 : exact;
		}
		actions = {
			new_si;
		}
		const entries = {
			(   0 , 0 ) : new_si(   0 );  (   0 , 1 ) : new_si(   0 );  (   0 , 2 ) : new_si(   0 );  (   0 , 3 ) : new_si(   0 );
			(   1 , 0 ) : new_si(   1 );  (   1 , 1 ) : new_si(   0 );  (   1 , 2 ) : new_si(   0 );  (   1 , 3 ) : new_si(   0 );
			(   2 , 0 ) : new_si(   2 );  (   2 , 1 ) : new_si(   1 );  (   2 , 2 ) : new_si(   1 );  (   2 , 3 ) : new_si(   0 );
			(   3 , 0 ) : new_si(   3 );  (   3 , 1 ) : new_si(   2 );  (   3 , 2 ) : new_si(   2 );  (   3 , 3 ) : new_si(   1 );
			(   4 , 0 ) : new_si(   4 );  (   4 , 1 ) : new_si(   3 );  (   4 , 2 ) : new_si(   3 );  (   4 , 3 ) : new_si(   2 );
			(   5 , 0 ) : new_si(   5 );  (   5 , 1 ) : new_si(   4 );  (   5 , 2 ) : new_si(   4 );  (   5 , 3 ) : new_si(   3 );
			(   6 , 0 ) : new_si(   6 );  (   6 , 1 ) : new_si(   5 );  (   6 , 2 ) : new_si(   5 );  (   6 , 3 ) : new_si(   4 );
			(   7 , 0 ) : new_si(   7 );  (   7 , 1 ) : new_si(   6 );  (   7 , 2 ) : new_si(   6 );  (   7 , 3 ) : new_si(   5 );
			(   8 , 0 ) : new_si(   8 );  (   8 , 1 ) : new_si(   7 );  (   8 , 2 ) : new_si(   7 );  (   8 , 3 ) : new_si(   6 );
			(   9 , 0 ) : new_si(   9 );  (   9 , 1 ) : new_si(   8 );  (   9 , 2 ) : new_si(   8 );  (   9 , 3 ) : new_si(   7 );
			(  10 , 0 ) : new_si(  10 );  (  10 , 1 ) : new_si(   9 );  (  10 , 2 ) : new_si(   9 );  (  10 , 3 ) : new_si(   8 );
			(  11 , 0 ) : new_si(  11 );  (  11 , 1 ) : new_si(  10 );  (  11 , 2 ) : new_si(  10 );  (  11 , 3 ) : new_si(   9 );
			(  12 , 0 ) : new_si(  12 );  (  12 , 1 ) : new_si(  11 );  (  12 , 2 ) : new_si(  11 );  (  12 , 3 ) : new_si(  10 );
			(  13 , 0 ) : new_si(  13 );  (  13 , 1 ) : new_si(  12 );  (  13 , 2 ) : new_si(  12 );  (  13 , 3 ) : new_si(  11 );
			(  14 , 0 ) : new_si(  14 );  (  14 , 1 ) : new_si(  13 );  (  14 , 2 ) : new_si(  13 );  (  14 , 3 ) : new_si(  12 );
			(  15 , 0 ) : new_si(  15 );  (  15 , 1 ) : new_si(  14 );  (  15 , 2 ) : new_si(  14 );  (  15 , 3 ) : new_si(  13 );
			(  16 , 0 ) : new_si(  16 );  (  16 , 1 ) : new_si(  15 );  (  16 , 2 ) : new_si(  15 );  (  16 , 3 ) : new_si(  14 );
			(  17 , 0 ) : new_si(  17 );  (  17 , 1 ) : new_si(  16 );  (  17 , 2 ) : new_si(  16 );  (  17 , 3 ) : new_si(  15 );
			(  18 , 0 ) : new_si(  18 );  (  18 , 1 ) : new_si(  17 );  (  18 , 2 ) : new_si(  17 );  (  18 , 3 ) : new_si(  16 );
			(  19 , 0 ) : new_si(  19 );  (  19 , 1 ) : new_si(  18 );  (  19 , 2 ) : new_si(  18 );  (  19 , 3 ) : new_si(  17 );
			(  20 , 0 ) : new_si(  20 );  (  20 , 1 ) : new_si(  19 );  (  20 , 2 ) : new_si(  19 );  (  20 , 3 ) : new_si(  18 );
			(  21 , 0 ) : new_si(  21 );  (  21 , 1 ) : new_si(  20 );  (  21 , 2 ) : new_si(  20 );  (  21 , 3 ) : new_si(  19 );
			(  22 , 0 ) : new_si(  22 );  (  22 , 1 ) : new_si(  21 );  (  22 , 2 ) : new_si(  21 );  (  22 , 3 ) : new_si(  20 );
			(  23 , 0 ) : new_si(  23 );  (  23 , 1 ) : new_si(  22 );  (  23 , 2 ) : new_si(  22 );  (  23 , 3 ) : new_si(  21 );
			(  24 , 0 ) : new_si(  24 );  (  24 , 1 ) : new_si(  23 );  (  24 , 2 ) : new_si(  23 );  (  24 , 3 ) : new_si(  22 );
			(  25 , 0 ) : new_si(  25 );  (  25 , 1 ) : new_si(  24 );  (  25 , 2 ) : new_si(  24 );  (  25 , 3 ) : new_si(  23 );
			(  26 , 0 ) : new_si(  26 );  (  26 , 1 ) : new_si(  25 );  (  26 , 2 ) : new_si(  25 );  (  26 , 3 ) : new_si(  24 );
			(  27 , 0 ) : new_si(  27 );  (  27 , 1 ) : new_si(  26 );  (  27 , 2 ) : new_si(  26 );  (  27 , 3 ) : new_si(  25 );
			(  28 , 0 ) : new_si(  28 );  (  28 , 1 ) : new_si(  27 );  (  28 , 2 ) : new_si(  27 );  (  28 , 3 ) : new_si(  26 );
			(  29 , 0 ) : new_si(  29 );  (  29 , 1 ) : new_si(  28 );  (  29 , 2 ) : new_si(  28 );  (  29 , 3 ) : new_si(  27 );
			(  30 , 0 ) : new_si(  30 );  (  30 , 1 ) : new_si(  29 );  (  30 , 2 ) : new_si(  29 );  (  30 , 3 ) : new_si(  28 );
			(  31 , 0 ) : new_si(  31 );  (  31 , 1 ) : new_si(  30 );  (  31 , 2 ) : new_si(  30 );  (  31 , 3 ) : new_si(  29 );
			(  32 , 0 ) : new_si(  32 );  (  32 , 1 ) : new_si(  31 );  (  32 , 2 ) : new_si(  31 );  (  32 , 3 ) : new_si(  30 );
			(  33 , 0 ) : new_si(  33 );  (  33 , 1 ) : new_si(  32 );  (  33 , 2 ) : new_si(  32 );  (  33 , 3 ) : new_si(  31 );
			(  34 , 0 ) : new_si(  34 );  (  34 , 1 ) : new_si(  33 );  (  34 , 2 ) : new_si(  33 );  (  34 , 3 ) : new_si(  32 );
			(  35 , 0 ) : new_si(  35 );  (  35 , 1 ) : new_si(  34 );  (  35 , 2 ) : new_si(  34 );  (  35 , 3 ) : new_si(  33 );
			(  36 , 0 ) : new_si(  36 );  (  36 , 1 ) : new_si(  35 );  (  36 , 2 ) : new_si(  35 );  (  36 , 3 ) : new_si(  34 );
			(  37 , 0 ) : new_si(  37 );  (  37 , 1 ) : new_si(  36 );  (  37 , 2 ) : new_si(  36 );  (  37 , 3 ) : new_si(  35 );
			(  38 , 0 ) : new_si(  38 );  (  38 , 1 ) : new_si(  37 );  (  38 , 2 ) : new_si(  37 );  (  38 , 3 ) : new_si(  36 );
			(  39 , 0 ) : new_si(  39 );  (  39 , 1 ) : new_si(  38 );  (  39 , 2 ) : new_si(  38 );  (  39 , 3 ) : new_si(  37 );
			(  40 , 0 ) : new_si(  40 );  (  40 , 1 ) : new_si(  39 );  (  40 , 2 ) : new_si(  39 );  (  40 , 3 ) : new_si(  38 );
			(  41 , 0 ) : new_si(  41 );  (  41 , 1 ) : new_si(  40 );  (  41 , 2 ) : new_si(  40 );  (  41 , 3 ) : new_si(  39 );
			(  42 , 0 ) : new_si(  42 );  (  42 , 1 ) : new_si(  41 );  (  42 , 2 ) : new_si(  41 );  (  42 , 3 ) : new_si(  40 );
			(  43 , 0 ) : new_si(  43 );  (  43 , 1 ) : new_si(  42 );  (  43 , 2 ) : new_si(  42 );  (  43 , 3 ) : new_si(  41 );
			(  44 , 0 ) : new_si(  44 );  (  44 , 1 ) : new_si(  43 );  (  44 , 2 ) : new_si(  43 );  (  44 , 3 ) : new_si(  42 );
			(  45 , 0 ) : new_si(  45 );  (  45 , 1 ) : new_si(  44 );  (  45 , 2 ) : new_si(  44 );  (  45 , 3 ) : new_si(  43 );
			(  46 , 0 ) : new_si(  46 );  (  46 , 1 ) : new_si(  45 );  (  46 , 2 ) : new_si(  45 );  (  46 , 3 ) : new_si(  44 );
			(  47 , 0 ) : new_si(  47 );  (  47 , 1 ) : new_si(  46 );  (  47 , 2 ) : new_si(  46 );  (  47 , 3 ) : new_si(  45 );
			(  48 , 0 ) : new_si(  48 );  (  48 , 1 ) : new_si(  47 );  (  48 , 2 ) : new_si(  47 );  (  48 , 3 ) : new_si(  46 );
			(  49 , 0 ) : new_si(  49 );  (  49 , 1 ) : new_si(  48 );  (  49 , 2 ) : new_si(  48 );  (  49 , 3 ) : new_si(  47 );
			(  50 , 0 ) : new_si(  50 );  (  50 , 1 ) : new_si(  49 );  (  50 , 2 ) : new_si(  49 );  (  50 , 3 ) : new_si(  48 );
			(  51 , 0 ) : new_si(  51 );  (  51 , 1 ) : new_si(  50 );  (  51 , 2 ) : new_si(  50 );  (  51 , 3 ) : new_si(  49 );
			(  52 , 0 ) : new_si(  52 );  (  52 , 1 ) : new_si(  51 );  (  52 , 2 ) : new_si(  51 );  (  52 , 3 ) : new_si(  50 );
			(  53 , 0 ) : new_si(  53 );  (  53 , 1 ) : new_si(  52 );  (  53 , 2 ) : new_si(  52 );  (  53 , 3 ) : new_si(  51 );
			(  54 , 0 ) : new_si(  54 );  (  54 , 1 ) : new_si(  53 );  (  54 , 2 ) : new_si(  53 );  (  54 , 3 ) : new_si(  52 );
			(  55 , 0 ) : new_si(  55 );  (  55 , 1 ) : new_si(  54 );  (  55 , 2 ) : new_si(  54 );  (  55 , 3 ) : new_si(  53 );
			(  56 , 0 ) : new_si(  56 );  (  56 , 1 ) : new_si(  55 );  (  56 , 2 ) : new_si(  55 );  (  56 , 3 ) : new_si(  54 );
			(  57 , 0 ) : new_si(  57 );  (  57 , 1 ) : new_si(  56 );  (  57 , 2 ) : new_si(  56 );  (  57 , 3 ) : new_si(  55 );
			(  58 , 0 ) : new_si(  58 );  (  58 , 1 ) : new_si(  57 );  (  58 , 2 ) : new_si(  57 );  (  58 , 3 ) : new_si(  56 );
			(  59 , 0 ) : new_si(  59 );  (  59 , 1 ) : new_si(  58 );  (  59 , 2 ) : new_si(  58 );  (  59 , 3 ) : new_si(  57 );
			(  60 , 0 ) : new_si(  60 );  (  60 , 1 ) : new_si(  59 );  (  60 , 2 ) : new_si(  59 );  (  60 , 3 ) : new_si(  58 );
			(  61 , 0 ) : new_si(  61 );  (  61 , 1 ) : new_si(  60 );  (  61 , 2 ) : new_si(  60 );  (  61 , 3 ) : new_si(  59 );
			(  62 , 0 ) : new_si(  62 );  (  62 , 1 ) : new_si(  61 );  (  62 , 2 ) : new_si(  61 );  (  62 , 3 ) : new_si(  60 );
			(  63 , 0 ) : new_si(  63 );  (  63 , 1 ) : new_si(  62 );  (  63 , 2 ) : new_si(  62 );  (  63 , 3 ) : new_si(  61 );
			(  64 , 0 ) : new_si(  64 );  (  64 , 1 ) : new_si(  63 );  (  64 , 2 ) : new_si(  63 );  (  64 , 3 ) : new_si(  62 );
			(  65 , 0 ) : new_si(  65 );  (  65 , 1 ) : new_si(  64 );  (  65 , 2 ) : new_si(  64 );  (  65 , 3 ) : new_si(  63 );
			(  66 , 0 ) : new_si(  66 );  (  66 , 1 ) : new_si(  65 );  (  66 , 2 ) : new_si(  65 );  (  66 , 3 ) : new_si(  64 );
			(  67 , 0 ) : new_si(  67 );  (  67 , 1 ) : new_si(  66 );  (  67 , 2 ) : new_si(  66 );  (  67 , 3 ) : new_si(  65 );
			(  68 , 0 ) : new_si(  68 );  (  68 , 1 ) : new_si(  67 );  (  68 , 2 ) : new_si(  67 );  (  68 , 3 ) : new_si(  66 );
			(  69 , 0 ) : new_si(  69 );  (  69 , 1 ) : new_si(  68 );  (  69 , 2 ) : new_si(  68 );  (  69 , 3 ) : new_si(  67 );
			(  70 , 0 ) : new_si(  70 );  (  70 , 1 ) : new_si(  69 );  (  70 , 2 ) : new_si(  69 );  (  70 , 3 ) : new_si(  68 );
			(  71 , 0 ) : new_si(  71 );  (  71 , 1 ) : new_si(  70 );  (  71 , 2 ) : new_si(  70 );  (  71 , 3 ) : new_si(  69 );
			(  72 , 0 ) : new_si(  72 );  (  72 , 1 ) : new_si(  71 );  (  72 , 2 ) : new_si(  71 );  (  72 , 3 ) : new_si(  70 );
			(  73 , 0 ) : new_si(  73 );  (  73 , 1 ) : new_si(  72 );  (  73 , 2 ) : new_si(  72 );  (  73 , 3 ) : new_si(  71 );
			(  74 , 0 ) : new_si(  74 );  (  74 , 1 ) : new_si(  73 );  (  74 , 2 ) : new_si(  73 );  (  74 , 3 ) : new_si(  72 );
			(  75 , 0 ) : new_si(  75 );  (  75 , 1 ) : new_si(  74 );  (  75 , 2 ) : new_si(  74 );  (  75 , 3 ) : new_si(  73 );
			(  76 , 0 ) : new_si(  76 );  (  76 , 1 ) : new_si(  75 );  (  76 , 2 ) : new_si(  75 );  (  76 , 3 ) : new_si(  74 );
			(  77 , 0 ) : new_si(  77 );  (  77 , 1 ) : new_si(  76 );  (  77 , 2 ) : new_si(  76 );  (  77 , 3 ) : new_si(  75 );
			(  78 , 0 ) : new_si(  78 );  (  78 , 1 ) : new_si(  77 );  (  78 , 2 ) : new_si(  77 );  (  78 , 3 ) : new_si(  76 );
			(  79 , 0 ) : new_si(  79 );  (  79 , 1 ) : new_si(  78 );  (  79 , 2 ) : new_si(  78 );  (  79 , 3 ) : new_si(  77 );
			(  80 , 0 ) : new_si(  80 );  (  80 , 1 ) : new_si(  79 );  (  80 , 2 ) : new_si(  79 );  (  80 , 3 ) : new_si(  78 );
			(  81 , 0 ) : new_si(  81 );  (  81 , 1 ) : new_si(  80 );  (  81 , 2 ) : new_si(  80 );  (  81 , 3 ) : new_si(  79 );
			(  82 , 0 ) : new_si(  82 );  (  82 , 1 ) : new_si(  81 );  (  82 , 2 ) : new_si(  81 );  (  82 , 3 ) : new_si(  80 );
			(  83 , 0 ) : new_si(  83 );  (  83 , 1 ) : new_si(  82 );  (  83 , 2 ) : new_si(  82 );  (  83 , 3 ) : new_si(  81 );
			(  84 , 0 ) : new_si(  84 );  (  84 , 1 ) : new_si(  83 );  (  84 , 2 ) : new_si(  83 );  (  84 , 3 ) : new_si(  82 );
			(  85 , 0 ) : new_si(  85 );  (  85 , 1 ) : new_si(  84 );  (  85 , 2 ) : new_si(  84 );  (  85 , 3 ) : new_si(  83 );
			(  86 , 0 ) : new_si(  86 );  (  86 , 1 ) : new_si(  85 );  (  86 , 2 ) : new_si(  85 );  (  86 , 3 ) : new_si(  84 );
			(  87 , 0 ) : new_si(  87 );  (  87 , 1 ) : new_si(  86 );  (  87 , 2 ) : new_si(  86 );  (  87 , 3 ) : new_si(  85 );
			(  88 , 0 ) : new_si(  88 );  (  88 , 1 ) : new_si(  87 );  (  88 , 2 ) : new_si(  87 );  (  88 , 3 ) : new_si(  86 );
			(  89 , 0 ) : new_si(  89 );  (  89 , 1 ) : new_si(  88 );  (  89 , 2 ) : new_si(  88 );  (  89 , 3 ) : new_si(  87 );
			(  90 , 0 ) : new_si(  90 );  (  90 , 1 ) : new_si(  89 );  (  90 , 2 ) : new_si(  89 );  (  90 , 3 ) : new_si(  88 );
			(  91 , 0 ) : new_si(  91 );  (  91 , 1 ) : new_si(  90 );  (  91 , 2 ) : new_si(  90 );  (  91 , 3 ) : new_si(  89 );
			(  92 , 0 ) : new_si(  92 );  (  92 , 1 ) : new_si(  91 );  (  92 , 2 ) : new_si(  91 );  (  92 , 3 ) : new_si(  90 );
			(  93 , 0 ) : new_si(  93 );  (  93 , 1 ) : new_si(  92 );  (  93 , 2 ) : new_si(  92 );  (  93 , 3 ) : new_si(  91 );
			(  94 , 0 ) : new_si(  94 );  (  94 , 1 ) : new_si(  93 );  (  94 , 2 ) : new_si(  93 );  (  94 , 3 ) : new_si(  92 );
			(  95 , 0 ) : new_si(  95 );  (  95 , 1 ) : new_si(  94 );  (  95 , 2 ) : new_si(  94 );  (  95 , 3 ) : new_si(  93 );
			(  96 , 0 ) : new_si(  96 );  (  96 , 1 ) : new_si(  95 );  (  96 , 2 ) : new_si(  95 );  (  96 , 3 ) : new_si(  94 );
			(  97 , 0 ) : new_si(  97 );  (  97 , 1 ) : new_si(  96 );  (  97 , 2 ) : new_si(  96 );  (  97 , 3 ) : new_si(  95 );
			(  98 , 0 ) : new_si(  98 );  (  98 , 1 ) : new_si(  97 );  (  98 , 2 ) : new_si(  97 );  (  98 , 3 ) : new_si(  96 );
			(  99 , 0 ) : new_si(  99 );  (  99 , 1 ) : new_si(  98 );  (  99 , 2 ) : new_si(  98 );  (  99 , 3 ) : new_si(  97 );
			( 100 , 0 ) : new_si( 100 );  ( 100 , 1 ) : new_si(  99 );  ( 100 , 2 ) : new_si(  99 );  ( 100 , 3 ) : new_si(  98 );
			( 101 , 0 ) : new_si( 101 );  ( 101 , 1 ) : new_si( 100 );  ( 101 , 2 ) : new_si( 100 );  ( 101 , 3 ) : new_si(  99 );
			( 102 , 0 ) : new_si( 102 );  ( 102 , 1 ) : new_si( 101 );  ( 102 , 2 ) : new_si( 101 );  ( 102 , 3 ) : new_si( 100 );
			( 103 , 0 ) : new_si( 103 );  ( 103 , 1 ) : new_si( 102 );  ( 103 , 2 ) : new_si( 102 );  ( 103 , 3 ) : new_si( 101 );
			( 104 , 0 ) : new_si( 104 );  ( 104 , 1 ) : new_si( 103 );  ( 104 , 2 ) : new_si( 103 );  ( 104 , 3 ) : new_si( 102 );
			( 105 , 0 ) : new_si( 105 );  ( 105 , 1 ) : new_si( 104 );  ( 105 , 2 ) : new_si( 104 );  ( 105 , 3 ) : new_si( 103 );
			( 106 , 0 ) : new_si( 106 );  ( 106 , 1 ) : new_si( 105 );  ( 106 , 2 ) : new_si( 105 );  ( 106 , 3 ) : new_si( 104 );
			( 107 , 0 ) : new_si( 107 );  ( 107 , 1 ) : new_si( 106 );  ( 107 , 2 ) : new_si( 106 );  ( 107 , 3 ) : new_si( 105 );
			( 108 , 0 ) : new_si( 108 );  ( 108 , 1 ) : new_si( 107 );  ( 108 , 2 ) : new_si( 107 );  ( 108 , 3 ) : new_si( 106 );
			( 109 , 0 ) : new_si( 109 );  ( 109 , 1 ) : new_si( 108 );  ( 109 , 2 ) : new_si( 108 );  ( 109 , 3 ) : new_si( 107 );
			( 110 , 0 ) : new_si( 110 );  ( 110 , 1 ) : new_si( 109 );  ( 110 , 2 ) : new_si( 109 );  ( 110 , 3 ) : new_si( 108 );
			( 111 , 0 ) : new_si( 111 );  ( 111 , 1 ) : new_si( 110 );  ( 111 , 2 ) : new_si( 110 );  ( 111 , 3 ) : new_si( 109 );
			( 112 , 0 ) : new_si( 112 );  ( 112 , 1 ) : new_si( 111 );  ( 112 , 2 ) : new_si( 111 );  ( 112 , 3 ) : new_si( 110 );
			( 113 , 0 ) : new_si( 113 );  ( 113 , 1 ) : new_si( 112 );  ( 113 , 2 ) : new_si( 112 );  ( 113 , 3 ) : new_si( 111 );
			( 114 , 0 ) : new_si( 114 );  ( 114 , 1 ) : new_si( 113 );  ( 114 , 2 ) : new_si( 113 );  ( 114 , 3 ) : new_si( 112 );
			( 115 , 0 ) : new_si( 115 );  ( 115 , 1 ) : new_si( 114 );  ( 115 , 2 ) : new_si( 114 );  ( 115 , 3 ) : new_si( 113 );
			( 116 , 0 ) : new_si( 116 );  ( 116 , 1 ) : new_si( 115 );  ( 116 , 2 ) : new_si( 115 );  ( 116 , 3 ) : new_si( 114 );
			( 117 , 0 ) : new_si( 117 );  ( 117 , 1 ) : new_si( 116 );  ( 117 , 2 ) : new_si( 116 );  ( 117 , 3 ) : new_si( 115 );
			( 118 , 0 ) : new_si( 118 );  ( 118 , 1 ) : new_si( 117 );  ( 118 , 2 ) : new_si( 117 );  ( 118 , 3 ) : new_si( 116 );
			( 119 , 0 ) : new_si( 119 );  ( 119 , 1 ) : new_si( 118 );  ( 119 , 2 ) : new_si( 118 );  ( 119 , 3 ) : new_si( 117 );
			( 120 , 0 ) : new_si( 120 );  ( 120 , 1 ) : new_si( 119 );  ( 120 , 2 ) : new_si( 119 );  ( 120 , 3 ) : new_si( 118 );
			( 121 , 0 ) : new_si( 121 );  ( 121 , 1 ) : new_si( 120 );  ( 121 , 2 ) : new_si( 120 );  ( 121 , 3 ) : new_si( 119 );
			( 122 , 0 ) : new_si( 122 );  ( 122 , 1 ) : new_si( 121 );  ( 122 , 2 ) : new_si( 121 );  ( 122 , 3 ) : new_si( 120 );
			( 123 , 0 ) : new_si( 123 );  ( 123 , 1 ) : new_si( 122 );  ( 123 , 2 ) : new_si( 122 );  ( 123 , 3 ) : new_si( 121 );
			( 124 , 0 ) : new_si( 124 );  ( 124 , 1 ) : new_si( 123 );  ( 124 , 2 ) : new_si( 123 );  ( 124 , 3 ) : new_si( 122 );
			( 125 , 0 ) : new_si( 125 );  ( 125 , 1 ) : new_si( 124 );  ( 125 , 2 ) : new_si( 124 );  ( 125 , 3 ) : new_si( 123 );
			( 126 , 0 ) : new_si( 126 );  ( 126 , 1 ) : new_si( 125 );  ( 126 , 2 ) : new_si( 125 );  ( 126 , 3 ) : new_si( 124 );
			( 127 , 0 ) : new_si( 127 );  ( 127 , 1 ) : new_si( 126 );  ( 127 , 2 ) : new_si( 126 );  ( 127 , 3 ) : new_si( 125 );
			( 128 , 0 ) : new_si( 128 );  ( 128 , 1 ) : new_si( 127 );  ( 128 , 2 ) : new_si( 127 );  ( 128 , 3 ) : new_si( 126 );
			( 129 , 0 ) : new_si( 129 );  ( 129 , 1 ) : new_si( 128 );  ( 129 , 2 ) : new_si( 128 );  ( 129 , 3 ) : new_si( 127 );
			( 130 , 0 ) : new_si( 130 );  ( 130 , 1 ) : new_si( 129 );  ( 130 , 2 ) : new_si( 129 );  ( 130 , 3 ) : new_si( 128 );
			( 131 , 0 ) : new_si( 131 );  ( 131 , 1 ) : new_si( 130 );  ( 131 , 2 ) : new_si( 130 );  ( 131 , 3 ) : new_si( 129 );
			( 132 , 0 ) : new_si( 132 );  ( 132 , 1 ) : new_si( 131 );  ( 132 , 2 ) : new_si( 131 );  ( 132 , 3 ) : new_si( 130 );
			( 133 , 0 ) : new_si( 133 );  ( 133 , 1 ) : new_si( 132 );  ( 133 , 2 ) : new_si( 132 );  ( 133 , 3 ) : new_si( 131 );
			( 134 , 0 ) : new_si( 134 );  ( 134 , 1 ) : new_si( 133 );  ( 134 , 2 ) : new_si( 133 );  ( 134 , 3 ) : new_si( 132 );
			( 135 , 0 ) : new_si( 135 );  ( 135 , 1 ) : new_si( 134 );  ( 135 , 2 ) : new_si( 134 );  ( 135 , 3 ) : new_si( 133 );
			( 136 , 0 ) : new_si( 136 );  ( 136 , 1 ) : new_si( 135 );  ( 136 , 2 ) : new_si( 135 );  ( 136 , 3 ) : new_si( 134 );
			( 137 , 0 ) : new_si( 137 );  ( 137 , 1 ) : new_si( 136 );  ( 137 , 2 ) : new_si( 136 );  ( 137 , 3 ) : new_si( 135 );
			( 138 , 0 ) : new_si( 138 );  ( 138 , 1 ) : new_si( 137 );  ( 138 , 2 ) : new_si( 137 );  ( 138 , 3 ) : new_si( 136 );
			( 139 , 0 ) : new_si( 139 );  ( 139 , 1 ) : new_si( 138 );  ( 139 , 2 ) : new_si( 138 );  ( 139 , 3 ) : new_si( 137 );
			( 140 , 0 ) : new_si( 140 );  ( 140 , 1 ) : new_si( 139 );  ( 140 , 2 ) : new_si( 139 );  ( 140 , 3 ) : new_si( 138 );
			( 141 , 0 ) : new_si( 141 );  ( 141 , 1 ) : new_si( 140 );  ( 141 , 2 ) : new_si( 140 );  ( 141 , 3 ) : new_si( 139 );
			( 142 , 0 ) : new_si( 142 );  ( 142 , 1 ) : new_si( 141 );  ( 142 , 2 ) : new_si( 141 );  ( 142 , 3 ) : new_si( 140 );
			( 143 , 0 ) : new_si( 143 );  ( 143 , 1 ) : new_si( 142 );  ( 143 , 2 ) : new_si( 142 );  ( 143 , 3 ) : new_si( 141 );
			( 144 , 0 ) : new_si( 144 );  ( 144 , 1 ) : new_si( 143 );  ( 144 , 2 ) : new_si( 143 );  ( 144 , 3 ) : new_si( 142 );
			( 145 , 0 ) : new_si( 145 );  ( 145 , 1 ) : new_si( 144 );  ( 145 , 2 ) : new_si( 144 );  ( 145 , 3 ) : new_si( 143 );
			( 146 , 0 ) : new_si( 146 );  ( 146 , 1 ) : new_si( 145 );  ( 146 , 2 ) : new_si( 145 );  ( 146 , 3 ) : new_si( 144 );
			( 147 , 0 ) : new_si( 147 );  ( 147 , 1 ) : new_si( 146 );  ( 147 , 2 ) : new_si( 146 );  ( 147 , 3 ) : new_si( 145 );
			( 148 , 0 ) : new_si( 148 );  ( 148 , 1 ) : new_si( 147 );  ( 148 , 2 ) : new_si( 147 );  ( 148 , 3 ) : new_si( 146 );
			( 149 , 0 ) : new_si( 149 );  ( 149 , 1 ) : new_si( 148 );  ( 149 , 2 ) : new_si( 148 );  ( 149 , 3 ) : new_si( 147 );
			( 150 , 0 ) : new_si( 150 );  ( 150 , 1 ) : new_si( 149 );  ( 150 , 2 ) : new_si( 149 );  ( 150 , 3 ) : new_si( 148 );
			( 151 , 0 ) : new_si( 151 );  ( 151 , 1 ) : new_si( 150 );  ( 151 , 2 ) : new_si( 150 );  ( 151 , 3 ) : new_si( 149 );
			( 152 , 0 ) : new_si( 152 );  ( 152 , 1 ) : new_si( 151 );  ( 152 , 2 ) : new_si( 151 );  ( 152 , 3 ) : new_si( 150 );
			( 153 , 0 ) : new_si( 153 );  ( 153 , 1 ) : new_si( 152 );  ( 153 , 2 ) : new_si( 152 );  ( 153 , 3 ) : new_si( 151 );
			( 154 , 0 ) : new_si( 154 );  ( 154 , 1 ) : new_si( 153 );  ( 154 , 2 ) : new_si( 153 );  ( 154 , 3 ) : new_si( 152 );
			( 155 , 0 ) : new_si( 155 );  ( 155 , 1 ) : new_si( 154 );  ( 155 , 2 ) : new_si( 154 );  ( 155 , 3 ) : new_si( 153 );
			( 156 , 0 ) : new_si( 156 );  ( 156 , 1 ) : new_si( 155 );  ( 156 , 2 ) : new_si( 155 );  ( 156 , 3 ) : new_si( 154 );
			( 157 , 0 ) : new_si( 157 );  ( 157 , 1 ) : new_si( 156 );  ( 157 , 2 ) : new_si( 156 );  ( 157 , 3 ) : new_si( 155 );
			( 158 , 0 ) : new_si( 158 );  ( 158 , 1 ) : new_si( 157 );  ( 158 , 2 ) : new_si( 157 );  ( 158 , 3 ) : new_si( 156 );
			( 159 , 0 ) : new_si( 159 );  ( 159 , 1 ) : new_si( 158 );  ( 159 , 2 ) : new_si( 158 );  ( 159 , 3 ) : new_si( 157 );
			( 160 , 0 ) : new_si( 160 );  ( 160 , 1 ) : new_si( 159 );  ( 160 , 2 ) : new_si( 159 );  ( 160 , 3 ) : new_si( 158 );
			( 161 , 0 ) : new_si( 161 );  ( 161 , 1 ) : new_si( 160 );  ( 161 , 2 ) : new_si( 160 );  ( 161 , 3 ) : new_si( 159 );
			( 162 , 0 ) : new_si( 162 );  ( 162 , 1 ) : new_si( 161 );  ( 162 , 2 ) : new_si( 161 );  ( 162 , 3 ) : new_si( 160 );
			( 163 , 0 ) : new_si( 163 );  ( 163 , 1 ) : new_si( 162 );  ( 163 , 2 ) : new_si( 162 );  ( 163 , 3 ) : new_si( 161 );
			( 164 , 0 ) : new_si( 164 );  ( 164 , 1 ) : new_si( 163 );  ( 164 , 2 ) : new_si( 163 );  ( 164 , 3 ) : new_si( 162 );
			( 165 , 0 ) : new_si( 165 );  ( 165 , 1 ) : new_si( 164 );  ( 165 , 2 ) : new_si( 164 );  ( 165 , 3 ) : new_si( 163 );
			( 166 , 0 ) : new_si( 166 );  ( 166 , 1 ) : new_si( 165 );  ( 166 , 2 ) : new_si( 165 );  ( 166 , 3 ) : new_si( 164 );
			( 167 , 0 ) : new_si( 167 );  ( 167 , 1 ) : new_si( 166 );  ( 167 , 2 ) : new_si( 166 );  ( 167 , 3 ) : new_si( 165 );
			( 168 , 0 ) : new_si( 168 );  ( 168 , 1 ) : new_si( 167 );  ( 168 , 2 ) : new_si( 167 );  ( 168 , 3 ) : new_si( 166 );
			( 169 , 0 ) : new_si( 169 );  ( 169 , 1 ) : new_si( 168 );  ( 169 , 2 ) : new_si( 168 );  ( 169 , 3 ) : new_si( 167 );
			( 170 , 0 ) : new_si( 170 );  ( 170 , 1 ) : new_si( 169 );  ( 170 , 2 ) : new_si( 169 );  ( 170 , 3 ) : new_si( 168 );
			( 171 , 0 ) : new_si( 171 );  ( 171 , 1 ) : new_si( 170 );  ( 171 , 2 ) : new_si( 170 );  ( 171 , 3 ) : new_si( 169 );
			( 172 , 0 ) : new_si( 172 );  ( 172 , 1 ) : new_si( 171 );  ( 172 , 2 ) : new_si( 171 );  ( 172 , 3 ) : new_si( 170 );
			( 173 , 0 ) : new_si( 173 );  ( 173 , 1 ) : new_si( 172 );  ( 173 , 2 ) : new_si( 172 );  ( 173 , 3 ) : new_si( 171 );
			( 174 , 0 ) : new_si( 174 );  ( 174 , 1 ) : new_si( 173 );  ( 174 , 2 ) : new_si( 173 );  ( 174 , 3 ) : new_si( 172 );
			( 175 , 0 ) : new_si( 175 );  ( 175 , 1 ) : new_si( 174 );  ( 175 , 2 ) : new_si( 174 );  ( 175 , 3 ) : new_si( 173 );
			( 176 , 0 ) : new_si( 176 );  ( 176 , 1 ) : new_si( 175 );  ( 176 , 2 ) : new_si( 175 );  ( 176 , 3 ) : new_si( 174 );
			( 177 , 0 ) : new_si( 177 );  ( 177 , 1 ) : new_si( 176 );  ( 177 , 2 ) : new_si( 176 );  ( 177 , 3 ) : new_si( 175 );
			( 178 , 0 ) : new_si( 178 );  ( 178 , 1 ) : new_si( 177 );  ( 178 , 2 ) : new_si( 177 );  ( 178 , 3 ) : new_si( 176 );
			( 179 , 0 ) : new_si( 179 );  ( 179 , 1 ) : new_si( 178 );  ( 179 , 2 ) : new_si( 178 );  ( 179 , 3 ) : new_si( 177 );
			( 180 , 0 ) : new_si( 180 );  ( 180 , 1 ) : new_si( 179 );  ( 180 , 2 ) : new_si( 179 );  ( 180 , 3 ) : new_si( 178 );
			( 181 , 0 ) : new_si( 181 );  ( 181 , 1 ) : new_si( 180 );  ( 181 , 2 ) : new_si( 180 );  ( 181 , 3 ) : new_si( 179 );
			( 182 , 0 ) : new_si( 182 );  ( 182 , 1 ) : new_si( 181 );  ( 182 , 2 ) : new_si( 181 );  ( 182 , 3 ) : new_si( 180 );
			( 183 , 0 ) : new_si( 183 );  ( 183 , 1 ) : new_si( 182 );  ( 183 , 2 ) : new_si( 182 );  ( 183 , 3 ) : new_si( 181 );
			( 184 , 0 ) : new_si( 184 );  ( 184 , 1 ) : new_si( 183 );  ( 184 , 2 ) : new_si( 183 );  ( 184 , 3 ) : new_si( 182 );
			( 185 , 0 ) : new_si( 185 );  ( 185 , 1 ) : new_si( 184 );  ( 185 , 2 ) : new_si( 184 );  ( 185 , 3 ) : new_si( 183 );
			( 186 , 0 ) : new_si( 186 );  ( 186 , 1 ) : new_si( 185 );  ( 186 , 2 ) : new_si( 185 );  ( 186 , 3 ) : new_si( 184 );
			( 187 , 0 ) : new_si( 187 );  ( 187 , 1 ) : new_si( 186 );  ( 187 , 2 ) : new_si( 186 );  ( 187 , 3 ) : new_si( 185 );
			( 188 , 0 ) : new_si( 188 );  ( 188 , 1 ) : new_si( 187 );  ( 188 , 2 ) : new_si( 187 );  ( 188 , 3 ) : new_si( 186 );
			( 189 , 0 ) : new_si( 189 );  ( 189 , 1 ) : new_si( 188 );  ( 189 , 2 ) : new_si( 188 );  ( 189 , 3 ) : new_si( 187 );
			( 190 , 0 ) : new_si( 190 );  ( 190 , 1 ) : new_si( 189 );  ( 190 , 2 ) : new_si( 189 );  ( 190 , 3 ) : new_si( 188 );
			( 191 , 0 ) : new_si( 191 );  ( 191 , 1 ) : new_si( 190 );  ( 191 , 2 ) : new_si( 190 );  ( 191 , 3 ) : new_si( 189 );
			( 192 , 0 ) : new_si( 192 );  ( 192 , 1 ) : new_si( 191 );  ( 192 , 2 ) : new_si( 191 );  ( 192 , 3 ) : new_si( 190 );
			( 193 , 0 ) : new_si( 193 );  ( 193 , 1 ) : new_si( 192 );  ( 193 , 2 ) : new_si( 192 );  ( 193 , 3 ) : new_si( 191 );
			( 194 , 0 ) : new_si( 194 );  ( 194 , 1 ) : new_si( 193 );  ( 194 , 2 ) : new_si( 193 );  ( 194 , 3 ) : new_si( 192 );
			( 195 , 0 ) : new_si( 195 );  ( 195 , 1 ) : new_si( 194 );  ( 195 , 2 ) : new_si( 194 );  ( 195 , 3 ) : new_si( 193 );
			( 196 , 0 ) : new_si( 196 );  ( 196 , 1 ) : new_si( 195 );  ( 196 , 2 ) : new_si( 195 );  ( 196 , 3 ) : new_si( 194 );
			( 197 , 0 ) : new_si( 197 );  ( 197 , 1 ) : new_si( 196 );  ( 197 , 2 ) : new_si( 196 );  ( 197 , 3 ) : new_si( 195 );
			( 198 , 0 ) : new_si( 198 );  ( 198 , 1 ) : new_si( 197 );  ( 198 , 2 ) : new_si( 197 );  ( 198 , 3 ) : new_si( 196 );
			( 199 , 0 ) : new_si( 199 );  ( 199 , 1 ) : new_si( 198 );  ( 199 , 2 ) : new_si( 198 );  ( 199 , 3 ) : new_si( 197 );
			( 200 , 0 ) : new_si( 200 );  ( 200 , 1 ) : new_si( 199 );  ( 200 , 2 ) : new_si( 199 );  ( 200 , 3 ) : new_si( 198 );
			( 201 , 0 ) : new_si( 201 );  ( 201 , 1 ) : new_si( 200 );  ( 201 , 2 ) : new_si( 200 );  ( 201 , 3 ) : new_si( 199 );
			( 202 , 0 ) : new_si( 202 );  ( 202 , 1 ) : new_si( 201 );  ( 202 , 2 ) : new_si( 201 );  ( 202 , 3 ) : new_si( 200 );
			( 203 , 0 ) : new_si( 203 );  ( 203 , 1 ) : new_si( 202 );  ( 203 , 2 ) : new_si( 202 );  ( 203 , 3 ) : new_si( 201 );
			( 204 , 0 ) : new_si( 204 );  ( 204 , 1 ) : new_si( 203 );  ( 204 , 2 ) : new_si( 203 );  ( 204 , 3 ) : new_si( 202 );
			( 205 , 0 ) : new_si( 205 );  ( 205 , 1 ) : new_si( 204 );  ( 205 , 2 ) : new_si( 204 );  ( 205 , 3 ) : new_si( 203 );
			( 206 , 0 ) : new_si( 206 );  ( 206 , 1 ) : new_si( 205 );  ( 206 , 2 ) : new_si( 205 );  ( 206 , 3 ) : new_si( 204 );
			( 207 , 0 ) : new_si( 207 );  ( 207 , 1 ) : new_si( 206 );  ( 207 , 2 ) : new_si( 206 );  ( 207 , 3 ) : new_si( 205 );
			( 208 , 0 ) : new_si( 208 );  ( 208 , 1 ) : new_si( 207 );  ( 208 , 2 ) : new_si( 207 );  ( 208 , 3 ) : new_si( 206 );
			( 209 , 0 ) : new_si( 209 );  ( 209 , 1 ) : new_si( 208 );  ( 209 , 2 ) : new_si( 208 );  ( 209 , 3 ) : new_si( 207 );
			( 210 , 0 ) : new_si( 210 );  ( 210 , 1 ) : new_si( 209 );  ( 210 , 2 ) : new_si( 209 );  ( 210 , 3 ) : new_si( 208 );
			( 211 , 0 ) : new_si( 211 );  ( 211 , 1 ) : new_si( 210 );  ( 211 , 2 ) : new_si( 210 );  ( 211 , 3 ) : new_si( 209 );
			( 212 , 0 ) : new_si( 212 );  ( 212 , 1 ) : new_si( 211 );  ( 212 , 2 ) : new_si( 211 );  ( 212 , 3 ) : new_si( 210 );
			( 213 , 0 ) : new_si( 213 );  ( 213 , 1 ) : new_si( 212 );  ( 213 , 2 ) : new_si( 212 );  ( 213 , 3 ) : new_si( 211 );
			( 214 , 0 ) : new_si( 214 );  ( 214 , 1 ) : new_si( 213 );  ( 214 , 2 ) : new_si( 213 );  ( 214 , 3 ) : new_si( 212 );
			( 215 , 0 ) : new_si( 215 );  ( 215 , 1 ) : new_si( 214 );  ( 215 , 2 ) : new_si( 214 );  ( 215 , 3 ) : new_si( 213 );
			( 216 , 0 ) : new_si( 216 );  ( 216 , 1 ) : new_si( 215 );  ( 216 , 2 ) : new_si( 215 );  ( 216 , 3 ) : new_si( 214 );
			( 217 , 0 ) : new_si( 217 );  ( 217 , 1 ) : new_si( 216 );  ( 217 , 2 ) : new_si( 216 );  ( 217 , 3 ) : new_si( 215 );
			( 218 , 0 ) : new_si( 218 );  ( 218 , 1 ) : new_si( 217 );  ( 218 , 2 ) : new_si( 217 );  ( 218 , 3 ) : new_si( 216 );
			( 219 , 0 ) : new_si( 219 );  ( 219 , 1 ) : new_si( 218 );  ( 219 , 2 ) : new_si( 218 );  ( 219 , 3 ) : new_si( 217 );
			( 220 , 0 ) : new_si( 220 );  ( 220 , 1 ) : new_si( 219 );  ( 220 , 2 ) : new_si( 219 );  ( 220 , 3 ) : new_si( 218 );
			( 221 , 0 ) : new_si( 221 );  ( 221 , 1 ) : new_si( 220 );  ( 221 , 2 ) : new_si( 220 );  ( 221 , 3 ) : new_si( 219 );
			( 222 , 0 ) : new_si( 222 );  ( 222 , 1 ) : new_si( 221 );  ( 222 , 2 ) : new_si( 221 );  ( 222 , 3 ) : new_si( 220 );
			( 223 , 0 ) : new_si( 223 );  ( 223 , 1 ) : new_si( 222 );  ( 223 , 2 ) : new_si( 222 );  ( 223 , 3 ) : new_si( 221 );
			( 224 , 0 ) : new_si( 224 );  ( 224 , 1 ) : new_si( 223 );  ( 224 , 2 ) : new_si( 223 );  ( 224 , 3 ) : new_si( 222 );
			( 225 , 0 ) : new_si( 225 );  ( 225 , 1 ) : new_si( 224 );  ( 225 , 2 ) : new_si( 224 );  ( 225 , 3 ) : new_si( 223 );
			( 226 , 0 ) : new_si( 226 );  ( 226 , 1 ) : new_si( 225 );  ( 226 , 2 ) : new_si( 225 );  ( 226 , 3 ) : new_si( 224 );
			( 227 , 0 ) : new_si( 227 );  ( 227 , 1 ) : new_si( 226 );  ( 227 , 2 ) : new_si( 226 );  ( 227 , 3 ) : new_si( 225 );
			( 228 , 0 ) : new_si( 228 );  ( 228 , 1 ) : new_si( 227 );  ( 228 , 2 ) : new_si( 227 );  ( 228 , 3 ) : new_si( 226 );
			( 229 , 0 ) : new_si( 229 );  ( 229 , 1 ) : new_si( 228 );  ( 229 , 2 ) : new_si( 228 );  ( 229 , 3 ) : new_si( 227 );
			( 230 , 0 ) : new_si( 230 );  ( 230 , 1 ) : new_si( 229 );  ( 230 , 2 ) : new_si( 229 );  ( 230 , 3 ) : new_si( 228 );
			( 231 , 0 ) : new_si( 231 );  ( 231 , 1 ) : new_si( 230 );  ( 231 , 2 ) : new_si( 230 );  ( 231 , 3 ) : new_si( 229 );
			( 232 , 0 ) : new_si( 232 );  ( 232 , 1 ) : new_si( 231 );  ( 232 , 2 ) : new_si( 231 );  ( 232 , 3 ) : new_si( 230 );
			( 233 , 0 ) : new_si( 233 );  ( 233 , 1 ) : new_si( 232 );  ( 233 , 2 ) : new_si( 232 );  ( 233 , 3 ) : new_si( 231 );
			( 234 , 0 ) : new_si( 234 );  ( 234 , 1 ) : new_si( 233 );  ( 234 , 2 ) : new_si( 233 );  ( 234 , 3 ) : new_si( 232 );
			( 235 , 0 ) : new_si( 235 );  ( 235 , 1 ) : new_si( 234 );  ( 235 , 2 ) : new_si( 234 );  ( 235 , 3 ) : new_si( 233 );
			( 236 , 0 ) : new_si( 236 );  ( 236 , 1 ) : new_si( 235 );  ( 236 , 2 ) : new_si( 235 );  ( 236 , 3 ) : new_si( 234 );
			( 237 , 0 ) : new_si( 237 );  ( 237 , 1 ) : new_si( 236 );  ( 237 , 2 ) : new_si( 236 );  ( 237 , 3 ) : new_si( 235 );
			( 238 , 0 ) : new_si( 238 );  ( 238 , 1 ) : new_si( 237 );  ( 238 , 2 ) : new_si( 237 );  ( 238 , 3 ) : new_si( 236 );
			( 239 , 0 ) : new_si( 239 );  ( 239 , 1 ) : new_si( 238 );  ( 239 , 2 ) : new_si( 238 );  ( 239 , 3 ) : new_si( 237 );
			( 240 , 0 ) : new_si( 240 );  ( 240 , 1 ) : new_si( 239 );  ( 240 , 2 ) : new_si( 239 );  ( 240 , 3 ) : new_si( 238 );
			( 241 , 0 ) : new_si( 241 );  ( 241 , 1 ) : new_si( 240 );  ( 241 , 2 ) : new_si( 240 );  ( 241 , 3 ) : new_si( 239 );
			( 242 , 0 ) : new_si( 242 );  ( 242 , 1 ) : new_si( 241 );  ( 242 , 2 ) : new_si( 241 );  ( 242 , 3 ) : new_si( 240 );
			( 243 , 0 ) : new_si( 243 );  ( 243 , 1 ) : new_si( 242 );  ( 243 , 2 ) : new_si( 242 );  ( 243 , 3 ) : new_si( 241 );
			( 244 , 0 ) : new_si( 244 );  ( 244 , 1 ) : new_si( 243 );  ( 244 , 2 ) : new_si( 243 );  ( 244 , 3 ) : new_si( 242 );
			( 245 , 0 ) : new_si( 245 );  ( 245 , 1 ) : new_si( 244 );  ( 245 , 2 ) : new_si( 244 );  ( 245 , 3 ) : new_si( 243 );
			( 246 , 0 ) : new_si( 246 );  ( 246 , 1 ) : new_si( 245 );  ( 246 , 2 ) : new_si( 245 );  ( 246 , 3 ) : new_si( 244 );
			( 247 , 0 ) : new_si( 247 );  ( 247 , 1 ) : new_si( 246 );  ( 247 , 2 ) : new_si( 246 );  ( 247 , 3 ) : new_si( 245 );
			( 248 , 0 ) : new_si( 248 );  ( 248 , 1 ) : new_si( 247 );  ( 248 , 2 ) : new_si( 247 );  ( 248 , 3 ) : new_si( 246 );
			( 249 , 0 ) : new_si( 249 );  ( 249 , 1 ) : new_si( 248 );  ( 249 , 2 ) : new_si( 248 );  ( 249 , 3 ) : new_si( 247 );
			( 250 , 0 ) : new_si( 250 );  ( 250 , 1 ) : new_si( 249 );  ( 250 , 2 ) : new_si( 249 );  ( 250 , 3 ) : new_si( 248 );
			( 251 , 0 ) : new_si( 251 );  ( 251 , 1 ) : new_si( 250 );  ( 251 , 2 ) : new_si( 250 );  ( 251 , 3 ) : new_si( 249 );
			( 252 , 0 ) : new_si( 252 );  ( 252 , 1 ) : new_si( 251 );  ( 252 , 2 ) : new_si( 251 );  ( 252 , 3 ) : new_si( 250 );
			( 253 , 0 ) : new_si( 253 );  ( 253 , 1 ) : new_si( 252 );  ( 253 , 2 ) : new_si( 252 );  ( 253 , 3 ) : new_si( 251 );
			( 254 , 0 ) : new_si( 254 );  ( 254 , 1 ) : new_si( 253 );  ( 254 , 2 ) : new_si( 253 );  ( 254 , 3 ) : new_si( 252 );
			( 255 , 0 ) : new_si( 255 );  ( 255 , 1 ) : new_si( 254 );  ( 255 , 2 ) : new_si( 254 );  ( 255 , 3 ) : new_si( 253 );
		}
	}
*/
/*
	table ing_sff_dec_si {
		key = {
			ig_md.nsh_md.sf_bitmask : exact;
		}
		actions = {
			new_si;
		 }
		const entries = {
			0  : new_si(0); // 0 bits set
			1  : new_si(0); // 1 bits set -- but don't count bit 0
			2  : new_si(1); // 1 bits set
			3  : new_si(1); // 2 bits set -- but don't count bit 0
			4  : new_si(1); // 1 bits set
			5  : new_si(1); // 2 bits set -- but don't count bit 0
			6  : new_si(2); // 2 bits set
			7  : new_si(2); // 3 bits set -- but don't count bit 0
		}
		const default_action = new_si(0);
	}
*/

	// =========================================================================
	// Table #2: ARP
	// =========================================================================

	action drop_pkt (
	) {
		ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
		ig_md.nsh_md.end_of_path = false;
	}

	// =====================================

	action unicast(
		switch_nexthop_t nexthop_index,

		bool end_of_chain

#ifdef COLLAPSE_NEXTHOP_TABLES
		,
		switch_tunnel_index_t tunnel_index,
		switch_port_lag_index_t port_lag_index,
		switch_outer_nexthop_t outer_nexthop_index
#endif
#ifdef COLLAPSE_SPI_SI_TABLES
		,
		bit<DSAP_ID_WIDTH> dsap
#endif
	) {
		ig_md.nexthop = nexthop_index;

		ig_md.nsh_md.end_of_path = end_of_chain;

#ifdef COLLAPSE_NEXTHOP_TABLES
		ig_md.tunnel_0.index = tunnel_index;
		ig_md.outer_nexthop = outer_nexthop_index;
		ig_md.egress_port_lag_index = port_lag_index;
#endif
#ifdef COLLAPSE_SPI_SI_TABLES
		ig_md.nsh_md.dsap             = dsap;
#endif
	}

	// =====================================

	action multicast(
		bool end_of_chain

#ifdef COLLAPSE_NEXTHOP_TABLES
		// derek; not sure that these lines are needed for the multicast case...
		,
		switch_nexthop_t nexthop_index,
		switch_tunnel_index_t tunnel_index,
		switch_outer_nexthop_t outer_nexthop_index
#endif
#ifdef COLLAPSE_SPI_SI_TABLES
		,
		switch_mgid_t mgid,

		// derek; not sure that these lines are needed for the multicast case...
		bit<DSAP_ID_WIDTH> dsap
#endif
	) {
		ig_md.nsh_md.end_of_path = end_of_chain;

#ifdef COLLAPSE_NEXTHOP_TABLES
		// derek; not sure that these lines are needed for the multicast case...
		ig_md.nexthop = nexthop_index;
		ig_md.tunnel_0.index = tunnel_index;
		ig_md.outer_nexthop = outer_nexthop_index;
#endif
#ifdef COLLAPSE_SPI_SI_TABLES
		ig_md.multicast.id  = mgid;
		ig_md.egress_port_lag_index = 0;

		// derek; not sure that these lines are needed for the multicast case...
		ig_md.nsh_md.dsap             = dsap;
#endif
	}

	// =====================================
	// Table
	// =====================================

	table ing_sff_fib {
		key = {
			hdr_0.nsh_type1.spi     : exact @name("spi");
#ifdef SFF_PREDECREMENTED_SI_ENABLE
//			hdr_nsh_type1_si_predec : exact @name("si");
			ig_md.nsh_md.si_predec  : exact @name("si");
#else
			hdr_0.nsh_type1.si      : exact @name("si");
#endif
		}

		actions = {
			drop_pkt;
			multicast;
			unicast;
		}

		// Derek: drop packet on miss...
		//
		// RFC 8300, Page 15: If an SFF receives a packet with an SPI and SI that
		// do not correspond to a valid next hop in a valid SFP, that packet MUST
		// be dropped by the SFF.

		const default_action = drop_pkt;
		size = NPB_ING_SFF_ARP_TABLE_DEPTH;
	}

	// =========================================================================
	// Apply
	// =========================================================================

	// Need to do one table lookups here:
	//
	// 1: forwarding lookup, after any sf's have reclassified the packet.

	apply {
//		ig_md.nsh_md.end_of_path = false;

		// +---------------+---------------+-----------------------------+
		// | hdr nsh valid | our nsh valid | signals / actions           |
		// +---------------+---------------+-----------------------------+
		// | n/a           | FALSE         | --> (classification failed) |
		// | FALSE         | TRUE          | --> we  classified          |
		// | TRUE          | TRUE          | --> was classified          |
		// +---------------+---------------+-----------------------------+

//		if(ig_md.nsh_md.valid == 1) {

			// Note: All of this code has to come after, serially, the first service function.
			// This is because the first service function can reclassify / change just about
			// anything with regard to the packet and it's service path.

			// -------------------------------------
			// Perform Flow Scheduling
			// -------------------------------------
/*
			npb_ing_sf_npb_basic_adv_sfp_sel.apply(
				hdr,
				ig_md,
				ig_intr_md,
				ig_intr_md_from_prsr,
				ig_intr_md_for_dprsr,
				ig_intr_md_for_tm
			);
*/
			// -------------------------------------
			// Pre-Decrement SI
			// -------------------------------------

			// Here we decrement the SI for all SF's we are going to do in the
			// chip.  We have to do all the decrements prior to the forwarding
			// lookup.  However, each SF still needs to do it's own decrement so
			// the the next SF gets the correct value.  Thus we don't want to
			// save this value permanently....

#ifdef SFF_PREDECREMENTED_SI_ENABLE
//			ig_md_nsh_md_sf_bitmask_2_1 = ig_md.nsh_md.sf_bitmask[2:1];

//			ing_sff_dec_si.apply(); // do a pop-count on the bitmask

//			hdr_nsh_type1_si_predec = hdr_0.nsh_type1.si |-| (bit<8>)nsh_si_dec_amount; // saturating subtract
//			hdr_nsh_type1_si_predec = (bit<8>)nsh_si_dec_amount; // saturating subtract
#endif
			// -------------------------------------
			// Perform Forwarding Lookup
			// -------------------------------------

			ing_sff_fib.apply();

			// -------------------------------------
			// Check SI
			// -------------------------------------

			// RFC 8300, Page 12: "an SFF that is not the terminal SFF for an SFP
			// will discard any NSH packet with an SI of 0, as there will be no
			// valid next SF information."

//			if((ig_md_nsh_md_si == 0) && (ig_md.tunnel_0.terminate == false)) { // check for si of 0 (or underflow, since we used a saturating subtract)
//				ig_intr_md_for_dprsr.drop_ctl = 0x1; // drop packet
//			}

			// NOTE: MOVED TO EGRESS

//		}

	}

}
