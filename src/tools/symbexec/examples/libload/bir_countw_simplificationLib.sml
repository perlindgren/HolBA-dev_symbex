structure bir_countw_simplificationLib =
struct
local

  open HolKernel Parse;
  open bossLib;
  open boolSyntax;

  open bir_symbexec_stateLib;

  open bir_constpropLib;

  open bir_envSyntax;
  open bir_expSyntax;

  open bir_exp_helperLib;

  val ERR      = Feedback.mk_HOL_ERR "bir_countw_simplificationLib"
  val wrap_exn = Feedback.wrap_exn   "bir_countw_simplificationLib"
(*
val var = bv_countw_fr;
*)
fun expand_exp_symbv vals symbv =
  let
    val exp = case symbv of
                 SymbValBE (be,_) => be
               | x => raise ERR "expand_exp_symbv"
                        ("unhandled symbolic value type: " ^ (symbv_to_string symbv) ^ " and " ^ (symbv_to_string x));

    val vars = get_birexp_vars exp;

    val valsl = ((Redblackmap.listItems) vals);
    val subexps_raw = List.filter ((fn x => List.exists (fn y => identical x y) vars) o fst) valsl;
    (* recursion on varexpressions first *)
    val subexps = List.map (fn (x, _) =>
                       (x, expand_exp_symbv vals
                             (find_bv_val "expand_exp_symbv" vals x)))
                  subexps_raw;

    val exp_ = List.foldl (fn ((bv, e), exp_) => subst_exp (bv, e, exp_)) exp subexps;
  in
    exp_
  end
  handle e => raise wrap_exn
               ("expand_exp_symbv: " ^ (symbv_to_string symbv))
               e;

(*
(hd(SYST_get_env syst))

val syst = List.nth(systs,0)

val env = (SYST_get_env syst);
val pred = (SYST_get_pred syst);

val (p::ps) = pred;
val benvmap = ((snd o dest_comb) ``BEnv (K NONE)``);

simple_pred_to_benvmap pred benvmap
*)

(*
             mk_comb (combinSyntax.mk_update (``2:num``,``"c"``),
                      ``\x. if x = 5:num then "a" else "b"``)
*)

open bir_exp_immSyntax;

val benvmap_empty = ((snd o dest_comb) ``BEnv (K NONE)``);
val bvalo_true = ``SOME (BVal_Imm (Imm1 1w))``;
val bvalo_false = ``SOME (BVal_Imm (Imm1 0w))``;
fun simple_pred_to_benvmap [] benvmap = benvmap
  | simple_pred_to_benvmap (p::ps) benvmap =
      let
        val benvmap_ =
          if not (is_BExp_Den p) then
            if not (is_BExp_UnaryExp p) orelse
               not (identical ((fst o dest_BExp_UnaryExp) p) BIExp_Not_tm) orelse
               not ((is_BExp_Den o snd o dest_BExp_UnaryExp) p)
            then
              let
                val _ = print (term_to_string p);
                val _ = print "\n\n";
              in
                benvmap
              end
            else
              let
                val p_ = (snd o dest_BExp_UnaryExp) p;
                val (vn, _) = (dest_BVar o dest_BExp_Den) p_;
              in
                mk_comb (combinSyntax.mk_update(vn,bvalo_false), benvmap)
              end
          else
          let val (vn, _) = (dest_BVar o dest_BExp_Den) p; in
             mk_comb (combinSyntax.mk_update(vn,bvalo_true), benvmap)
          end
      in
        simple_pred_to_benvmap ps benvmap_
      end;

fun simple_p_to_subst p =
  if is_BExp_UnaryExp p andalso
     identical ((fst o dest_BExp_UnaryExp) p) BIExp_Not_tm then
    subst [((snd o dest_BExp_UnaryExp) p) |-> ``(BExp_Const (Imm1 0w))``]
  else
    subst [p |-> ``(BExp_Const (Imm1 1w))``];

fun simple_pred_to_subst pred exp =
  List.foldl (fn (p, exp) => simple_p_to_subst p exp) exp pred;


in (* local *)

val bv_countw = mk_BVar_string ("countw", ``(BType_Imm Bit64)``);
val bv_mem = ``BVar "MEM" (BType_Mem Bit32 Bit8)``;
val bv_sp = ``BVar "SP_process" (BType_Imm Bit32)``;

(*
val syst = hd systs;
*)
fun expand_bv_fr_in_syst bv_fr syst =
  let
    val vals = (SYST_get_vals syst);

    (*
    val exp = simple_pred_to_subst pred exp_;
    *)

    val symbv = find_bv_val "expand_bv_fr_in_syst" vals bv_fr;
  in
    (expand_exp_symbv vals symbv, Redblackset.listItems (deps_of_symbval "expand_bv_fr_in_syst" symbv))
  end;

fun expand_bv_in_syst bv syst =
  let
    val env  = (SYST_get_env  syst);

    val bv_fr = find_bv_val "expand_bv_in_syst" env bv;
  in
    (fst o expand_bv_fr_in_syst bv_fr) syst
  end;

fun eval_exp_in_syst exp syst =
  let
    val vals = (SYST_get_vals syst);

    (*
    val pred = (SYST_get_pred syst);
    val env  = (SYST_get_env  syst);
    val benv = mk_BEnv (simple_pred_to_benvmap pred benvmap_empty);
    *)

    open bir_symbexec_coreLib;
    val symbv = compute_valbe exp syst;
    val exp_ = expand_exp_symbv vals symbv;

    val benv = ``BEnv (K NONE)``;
  in
    (snd o dest_eq o concl o EVAL) ``bir_eval_exp ^exp_ ^benv``
  end;

fun eval_exp_no_deps exp =
  let
    (*
    val pred = (SYST_get_pred syst);
    val env  = (SYST_get_env  syst);
    val vals = (SYST_get_vals syst);
    *)

    val benv = ``BEnv (K NONE)``;
  in
    (snd o dest_eq o concl o EVAL) ``bir_eval_exp ^exp ^benv``
  end;


fun eval_countw_in_syst syst =
    eval_exp_in_syst (expand_bv_in_syst bv_countw syst) syst;

end (* local *)
end (* struct *)
