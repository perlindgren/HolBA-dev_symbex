structure bir_conc_execLib : bir_conc_execLib =
struct

(* HOL_Interactive.toggle_quietdec(); *)
  open HolKernel boolLib liteLib simpLib Parse bossLib;
  open pairLib listSyntax stringSyntax wordsSyntax optionSyntax;
  open bir_symb_execLib;
  open bir_symb_masterLib;
  open experimentsLib;
(* HOL_Interactive.toggle_quietdec(); *)

  (* error handling *)
  val libname  = "bir_conc_execLib"
  val ERR      = Feedback.mk_HOL_ERR libname
  val wrap_exn = Feedback.wrap_exn libname


  val (mem_state) = ref (machstate_empty Arbnum.zero);

  val toTerm = rhs o concl
  fun econcl exp = (toTerm o EVAL) exp
  fun fromTerm tm = Arbnum.fromString (Parse.term_to_string tm);

  fun t2n tm = tm |> strip_comb |> #2 |> (fn a::b::_ => (fromTerm a , fromTerm b));
  fun mk_mem_state defval tms = (8, defval, Redblackmap.fromList Arbnum.compare (map (fn p => t2n p) tms));
  fun is_state_mem_emp (MACHSTATE (_, (_, _, m))) =
    (Redblackmap.numItems m = 0);
  val add_reg_state = machstate_add_reg;
  val replace_mem_state = machstate_replace_mem;

  fun update_env name value env = 
      let
        val hname = fromMLstring name
        val wordval = mk_wordi (value, 64);
      in
	  (toTerm o EVAL) ``bir_symb_env_update ^hname (BExp_Const (Imm64 ^wordval)) (BType_Imm Bit64) ^env``
      end;

  fun gen_symb_updates s env =
    foldr (fn ((n,v),e) => update_env n v e) (env) s;

  (* ---------------------- Simplification conversions ---------------------- *)

  val bir_endian_ss = rewrites (type_rws ``:bir_endian_t``)
  val EVAL_CONV =
      computeLib.compset_conv (reduceLib.num_compset())
        [computeLib.Defs
	     [pred_setTheory.NOT_IN_EMPTY, pred_setTheory.IN_INSERT,
	      REWRITE_RULE [GSYM arithmeticTheory.DIV2_def] wordsTheory.BIT_SET_def,
	      listTheory.EVERY_DEF, listTheory.FOLDL,
	      numLib.SUC_RULE rich_listTheory.COUNT_LIST_AUX_def,
	      GSYM rich_listTheory.COUNT_LIST_GENLIST,
	      rich_listTheory.COUNT_LIST_compute,
	      numeral_bitTheory.numeral_log2, numeral_bitTheory.numeral_ilog2,
	      numeral_bitTheory.LOG_compute, GSYM DISJ_ASSOC],
	 computeLib.Convs
	     [(``fcp$dimindex:'a itself -> num``, 1, wordsLib.SIZES_CONV),
	      (``words$word_mod:'a word -> 'a word -> 'a word``, 2,
	       wordsLib.WORD_MOD_BITS_CONV)]];

  local
    open bir_inst_liftingHelpersLib;
  in
  fun syntax_fns n d m = HolKernel.syntax_fns {n = n, dest = d, make = m} "bir_exp_mem";
  val syntax_fns6 = syntax_fns 6 dest_sexop mk_sexop;
  val (bir_load_from_mem_tm,  mk_bir_load_from_mem, dest_bir_load_from_mem, is_bir_load_from_mem)  =
      (syntax_fns6 ) "bir_load_from_mem";

  fun syntax_fns n d m = HolKernel.syntax_fns {n = n, dest = d, make = m} "bir_exp_mem";
  val syntax_fnss2 = syntax_fns 2 HolKernel.dest_binop HolKernel.mk_binop;
  val (bitstring_split_tm,  mk_bitstring_split, dest_bitstring_split, is_bitstring_split)  =
      (syntax_fnss2 ) "bitstring_split";
  end

  fun load_store_simp_unchange_conv tm =
      let 
	  open bir_exp_memTheory
	  open bir_exec_expLib

	  val (_,mmp,a,_) = dest_bir_update_mmap ( find_term is_bir_update_mmap tm);
	  val (vty,aty,_,_,en,addr) = (dest_bir_load_from_mem) (find_term is_bir_load_from_mem tm)
	  val thm  = ISPECL[a, en, vty, aty, ``(Imm64 (dummy :word64))``, mmp] bir_store_in_mem_used_addrs_THM
	  val thm' = SIMP_RULE ((std_ss++HolBACoreSimps.holBACore_ss)) [bir_store_in_mem_def, LET_DEF] thm
      in  
	  (toTerm o EVAL_CONV) (concl (SIMP_RULE (arith_ss) [] (SPECL[addr] thm')))
      end

  fun load_store_simp_unchange1_conv tm =
      let
	  open bir_exp_memTheory
	  open bir_exec_expLib
      in
	  tm |> SIMP_CONV(std_ss++HolBACoreSimps.bir_load_store_ss)[bir_eval_load_def, bir_eval_store_def]
	     |> computeLib.RESTR_EVAL_RULE [``bir_eval_load``, ``bir_eval_store``]
	     |> (toTerm o SIMP_RULE (std_ss++HolBACoreSimps.bir_load_store_ss) [])
	     |> load_store_simp_unchange_conv
	     |> SIMP_CONV (std_ss) [bir_mem_addr_def, bitTheory.MOD_2EXP_def, size_of_bir_immtype_def]
	     |> (#2 o dest_eq o toTerm)
      end

  fun load_store_simp_unchange2_conv tm =
      let 
	  open bir_exp_memTheory
	  open bir_exec_expLib
	  open listTheory
	  open bitTheory bitstringTheory

	  val tm1 = toTerm (SIMP_CONV (std_ss++HolBACoreSimps.bir_load_store_ss++bir_endian_ss) 
		      [bir_eval_load_def, bir_eval_store_def, bir_store_in_mem_def, type_of_bir_imm_def,
  		            bir_number_of_mem_splits_def, size_of_bir_immtype_def, LET_DEF] tm)
	  val tm2 = load_store_simp_unchange_conv tm1 
		|> (SIMP_CONV(srw_ss())[bir_mem_addr_def,size_of_bir_immtype_def,b2n_def]) 
		|> (#2 o dest_eq o toTerm)

	  val (aty,mmp,a,vs) = dest_bir_update_mmap (find_term is_bir_update_mmap tm2)
	  val (_,addr) = dest_comb tm2
	  val tm3 = (ISPECL[aty, mmp, a, vs, addr] bir_update_mmap_UNCHANGED);
	  val res = (toTerm o EVAL_CONV)(concl(SIMP_RULE(arith_ss)[bir_mem_addr_def, MOD_2EXP_def, LENGTH_REVERSE] tm3))

	  val (n, bs) = dest_bitstring_split (find_term is_bitstring_split res);
	  val m = (toTerm o EVAL) ``(LENGTH ^bs) DIV ^n``;
	  val thm = (SIMP_RULE (srw_ss()) [length_w2v] (ISPECL[``^n``, ``^m``,``^bs``] bitstring_split_LENGTHS));
      in
	  tm3 |> SIMP_RULE (srw_ss() ++ ARITH_ss) [thm, bir_mem_addr_def, bitTheory.MOD_2EXP_def, size_of_bir_immtype_def] 
	      |> EVAL_RULE
	      |> (#2 o dest_eq o concl) 
      end
  (* ------------------------------------------------------------------------ *)

  fun mem_init_conc_exec exp ([],v_) =
      let 
          val v = numSyntax.term_of_int(Arbnum.toInt(v_));
	  open bir_expSyntax
	  open bir_immSyntax
	  open bir_valuesSyntax
	  open bir_exp_substitutionsSyntax
	  
	  fun distinct [] = []
	    | distinct (x::xs) = x::distinct(List.filter (fn y => not (identical y x)) xs);

	  val mem = mk_var ("MEM",Type`:num |-> num`)
	  val loadList = find_terms is_BExp_Load (econcl exp)
	  val addrList = map (fn ldexp => 
				 let
				     val (_, a, _, _) = dest_BExp_Load ldexp
				     val addr = case (find_terms is_BExp_Load a) of
					         [] => a
						| _ =>  let val (_, a', _, _) = dest_BExp_Load ((hd o find_terms is_BExp_Load) a) in a' end
				 in
				     econcl ``bir_eval_exp ^addr (BEnv (K NONE))``
				 end) loadList;

	  val memLocInit = map (fn waddr => 
				   let
				       val wa = ( snd o gen_dest_Imm o dest_BVal_Imm) ((snd o dest_comb) waddr) 
				       val na = (econcl ``w2n ^wa``)
				   in
				       [``(^na,  ^v) ``, ``(^na+1, ^v)``, ``(^na+2, ^v)``, ``(^na+3, ^v)``,
					``(^na+4, ^v)``, ``(^na+5, ^v)``, ``(^na+6, ^v)``, ``(^na+7, ^v)``]
				   end) (distinct addrList)

	  val evalMemLocAddr = map (fn el => econcl el ) (flatten memLocInit);
	  val memInit = foldl (fn (x,y) => ``^y |+ ^x``) ``(FEMPTY: num |-> num)`` evalMemLocAddr
	  val memSubs = subst [mem |-> memInit] (econcl exp)
	  val memAssignments = mk_mem_state v_ evalMemLocAddr
      in
	  (memSubs, memAssignments)
      end
    | mem_init_conc_exec exp (xs,v_) =
      let
          open numSyntax
	  open Arbnum

	  val val_pairt = map (fn (a,b) => ( mk_pair((term_of_int o toInt) a, (term_of_int o toInt) b))) xs
	  val mem = mk_var ("MEM",Type`:num |-> num`);
	  val memInit = foldl (fn (x,y) => ``^y |+ ^x``) ``(FEMPTY: num |-> num)`` val_pairt
	  val memSubs = subst [mem |-> memInit] (econcl exp)
      in
	  (memSubs,(mk_mem_state v_ []))
      end;

  fun conc_exec_program depth prog envfo (mls,v_) =
      let 
          val v = numSyntax.term_of_int(Arbnum.toInt(v_));
	  val holba_ss = ((std_ss++HolBACoreSimps.holBACore_ss))
	  val precond  = ``BExp_Const (Imm1 1w)``
	  val states   = symb_exec_process_to_leafs_pdecide (fn x => true) envfo depth precond prog

	  (* filter for the concrete path *)
	  fun eq_true t = identical t ``SOME (BVal_Imm (Imm1 1w))``
	  fun pathcond_val s =
	      let
		  val (bsst_pred_init_mem, ms) = mem_init_conc_exec ``(^s).bsst_pred`` (mls,v_)
		  val _ =  mem_state := replace_mem_state ms (!mem_state);
		  val restr_eval_tm = (toTerm o computeLib.RESTR_EVAL_CONV [``bir_eval_load``, ``bir_eval_store``])
					  ``bir_eval_exp (^bsst_pred_init_mem) (BEnv (K NONE))``;
		  val bsst_simp_tm = 
                      (let 
			   val tm = ((toTerm) (SIMP_CONV (std_ss++HolBACoreSimps.bir_load_store_ss) [] (restr_eval_tm)))  
			       handle _ => restr_eval_tm
			   val (f,t) = Lib.first (fn (tac,t) => (Lib.can tac) t)
			   			 [( load_store_simp_unchange_conv,tm ), 
						  (load_store_simp_unchange1_conv,tm ), 
						  (load_store_simp_unchange2_conv, tm)]
			       handle _ => ((fn t => t), tm)
			   val res = f t
		       in
			   res
		       end)
	      in
		  (snd o dest_eq o concl o EVAL) bsst_simp_tm
	      end
	  val filteredStates = List.filter (eq_true o pathcond_val) states
	  val final_state = case filteredStates of
				[s] => s
			      | []  => raise ERR "conc_obs_compute" "no state has a true path condition?!?!?!"
                              | _   => raise ERR "conc_obs_compute" "more than one state has a true path condition?!?!?!";

      in
	  final_state
      end;

  fun conc_exec_obs_extract obs_projection symb_state (mls,v_) =
    let
      val v = numSyntax.term_of_int(Arbnum.toInt(v_));
      open numSyntax;
      fun eval_exp t = (toTerm o EVAL) t;
      fun eval_exp_to_val t =
        let
	    val esimp = computeLib.RESTR_EVAL_CONV [``bir_eval_load``, ``bir_eval_store``] ``bir_eval_exp (^t) (BEnv (K NONE))``;
	    val res =
                eval_exp
	    	    (let
	    	     val tm = (toTerm (SIMP_CONV (std_ss++HolBACoreSimps.bir_load_store_ss) [] (toTerm esimp)))
	    		 handle _ => (toTerm esimp)
	    	     val res = load_store_simp_unchange_conv tm
	    		 handle _ => tm
	    	 in
	    	     res
	    	 end)

          val res_v = if is_some res 
		      then dest_some res 
		      else let val ex = rhs res in (``(BVal_Imm (Imm64 ((n2w ^ex):word64)))``) end
                  (* raise ERR "conc_exec_obs_extract::eval_exp_to_val" "could not evaluate down to a value"; *)
        in
          res_v
        end;
      fun eval_explist_to_vallist t =
        let
          val (tl, tt) = dest_list t
                         handle _ => raise ERR "conc_exec_obs_extract::eval_explist_to_vallist" "input is not a list";
          val _ = if tt = ``:bir_exp_t`` then ()
                  else raise ERR "conc_exec_obs_extract::eval_explist_to_vallist" "wrong list type";
        in
          mk_list (map eval_exp_to_val tl, ``:bir_val_t``)
        end;
      val state_ = symb_state;

      val _ = if symb_is_BST_Halted state_ then () else
              raise ERR "conc_exec_program" "the final state is not halted, something is off";
      val (_,_,_,_,observation) = dest_bir_symb_state state_;
      val bsst_obs_init_mem = #1(mem_init_conc_exec observation (mls,v_)) 

      val nonemp_obs = filter (fn ob => (not o List.null o snd o strip_comb) ob) [bsst_obs_init_mem];
      val obs_elem = map (fn ob => (fst o dest_list) ob)nonemp_obs;
      val obs_exp = map dest_bir_symb_obs (flatten obs_elem);
      val res = List.concat
                    (map (fn (id,cond,ob,f) =>
                             if identical (eval_exp_to_val cond) ``BVal_Imm (Imm1 1w)`` andalso int_of_term id <> obs_projection
                             then let val t = mk_comb (f, eval_explist_to_vallist ob)
                                  in [(int_of_term id,eval_exp t)] end
                             else [])
                                 obs_exp);
    in res end;



  fun conc_exec_obs_compute obs_projection prog s =
    let
      val (MACHSTATE (regmap, (wsz, defval, memmap))) = s;

      val _ =  mem_state := machstate_empty defval;

      val _ = if wsz = 8 then () else
              raise ERR "conc_exec_obs_compute" "can only handle byte addressed memory";

      val regmap' = Redblackmap.listItems regmap;
      val memmap' = Redblackmap.listItems memmap;

      val envfo = SOME (gen_symb_updates regmap');

      val (m, v) = (memmap', defval);

      val state_ = conc_exec_program 200 prog envfo (m,v)
      val obs = conc_exec_obs_extract obs_projection state_ (m,v)

      val _ = map (fn (id,ob) => (print (Int.toString id ^ " "); print_term ob)) obs
      val _ = print "\n";
    in
      (obs, state_)
    end;

  fun conc_exec_obs_compare obs_projection prog (s1, s2) =
      let
	      val (obs1, _) = conc_exec_obs_compute obs_projection prog s1;
	      val (obs2, _) = conc_exec_obs_compute obs_projection prog s2;
      in
	  (list_eq (fn (i1,t1) => fn (i2,t2) => i1 = i2 andalso identical t1 t2) obs1 obs2)
      end;


(*

open bir_cfgVizLib;
open bir_obs_modelLib;
open bir_prog_genLib;
open persistenceLib;

open optionSyntax;
open bir_valuesSyntax;
open bir_immSyntax;
open wordsSyntax;

(*
export HOLBA_EMBEXP_LOGS="/home/xmate/Projects/HolBA/logs/EmbExp-Logs";
*)

val obs_model_id = "cache_tag_index";

(*
val exp_ids = ["arm8/exps2/exp_cache_multiw/7d4fd31c0865567aae1ab23c57256c3e6dc6215d"];
*)

val listname = "hamperiments32_eqobs";
val exp_ids = bir_embexp_load_exp_ids listname;

(*
val exp_id = hd exp_ids;
val exp_ids = tl exp_ids;
val _ = print "\n\n\n\n";
val _ = print exp_id;
val _ = print "\n=============================\n";
*)

fun compare_obss_of_exp obs_model_id exp_id =
  let
    val (asm_lines, (s1,s2)) = bir_embexp_load_exp exp_id;

    val (_, lifted_prog) = prog_gen_store_fromlines asm_lines ();

    val add_obs = #add_obs (get_obs_model obs_model_id)
    val prog = add_obs lifted_prog;
    (*
    fun convobs_fun obs = (Arbnum.toHexString o (fn x => Arbnum.* (x, Arbnum.fromInt 64)) o dest_word_literal o dest_Imm64 o dest_BVal_Imm o dest_some) obs;
    val convobsl_fun = List.map convobs_fun;

    val obsl1 = conc_exec_obs_compute prog s1;
    val obsl2 = conc_exec_obs_compute prog s2;

    val obsl1_ = convobsl_fun obsl1;
    val obsl2_ = convobsl_fun obsl2;
    *)
  in
    conc_exec_obs_compare prog (s1,s2)
  end;

val results = List.map (fn x => (compare_obss_of_exp obs_model_id x, x)) exp_ids;


val _ = List.map (fn (b, s) => if b then print (s ^ "\n") else ()) results;


val exp_id = "arm8/exps2/exp_cache_multiw/113126365c7e68aa0b83ef9f42ff6ee6407b418b";
val (asm_lines, (s1,s2)) = bir_embexp_load_exp exp_id;
val (_, lifted_prog) = prog_gen_store_fromlines asm_lines ();
val add_obs = #add_obs (get_obs_model obs_model_id)
val prog = add_obs lifted_prog;

conc_exec_obs_compute prog s1;
conc_exec_obs_compute prog s2;
conc_exec_obs_compare prog (s1,s2);


val dot_path = "/home/xmate/Projects/HolBA/HolBA/src/tools/scamv/tempdir/cfg.dot";
bir_cfgVizLib.bir_export_graph_from_prog prog dot_path;
*)
end (* struct *)
