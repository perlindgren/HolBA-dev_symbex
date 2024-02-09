open HolKernel Parse boolLib bossLib;
open wordsTheory
open bir_nzcv_expTheory
open m0_stepTheory

(* ARM uses so called NZCV status flags for conditional execution. These were
   formalised in bir_nzcv_expTheory. However, the ARM step library partially evalutates
   such NZCV flag functions while generating step theorems. Therefore, we need special
   lemmata to reintroduce the simple NZCV defs.

*)

val _ = new_theory "bir_nzcv_intros";


(***************************)
(* ARM 8 general cmp / sub *)
(***************************)

val nzcv_SUB_V_fold_ARM8 = store_thm ("nzcv_SUB_V_fold_ARM8",
``!w1 w0:'a word.
  ((word_msb w0 <=> word_msb (~w1)) /\
  (word_msb w0 <=/=> BIT  (dimindex (:'a) - 1) (w2n w0 + w2n (~w1) + 1))) =
  nzcv_BIR_SUB_V w0 w1``,

REPEAT GEN_TAC >>
SIMP_TAC std_ss [nzcv_BIR_SUB_V_CARRY_DEF, awc_BIR_V_def,
  add_with_carry_def, LET_THM, word_msb_n2w]);


val nzcv_NEGS_V_fold_ARM8 = save_thm ("nzcv_NEGS_V_fold_ARM8",
  Q.GEN `a`
    (CONV_RULE (LAND_CONV (SIMP_CONV (std_ss++wordsLib.WORD_ss) []))
      (ISPECL [``a:'a word``, ``0w:'a word``] nzcv_SUB_V_fold_ARM8)
    )
);


val nzcv_SUB_C_fold_ARM8 = store_thm ("nzcv_SUB_C_fold_ARM8",
``!w1 w0.
  ((if w2n w0 + w2n (~(w1:'a word)) + 1 < dimword (:'a) then w2n w0 + w2n (~w1) + 1
   else (w2n w0 + w2n (~w1) + 1) MOD (dimword (:'a))) <>
  w2n w0 + w2n (~w1) + 1) = nzcv_BIR_SUB_C w0 w1``,

REPEAT GEN_TAC >>
SIMP_TAC (std_ss++boolSimps.LIFT_COND_ss) [nzcv_BIR_SUB_C_CARRY_DEF, add_with_carry_def, LET_THM,
   ZERO_LT_dimword, w2n_n2w, awc_BIR_C_def]);


val nzcv_SUB_Z_fold_ARM8 = store_thm ("nzcv_SUB_Z_fold_ARM8",
``!w1 w0. ((w0:'a word - w1) = 0w) = nzcv_BIR_SUB_Z w0 w1``,
SIMP_TAC std_ss [nzcv_def, LET_THM, nzcv_BIR_SUB_Z_def, GSYM word_add_def, word_sub_def]);


val nzcv_SUB_N_fold_ARM8 = store_thm ("nzcv_SUB_N_fold_ARM8",
``!w1 w0. word_msb ((w0:'a word) - w1) = nzcv_BIR_SUB_N w0 w1``,
SIMP_TAC std_ss [nzcv_def, LET_THM, nzcv_BIR_SUB_N_def, GSYM word_add_def, word_sub_def]);


val nzcv_SUB_FOLDS_ARM8_GEN = save_thm ("nzcv_SUB_FOLDS_ARM8_GEN",
  LIST_CONJ [nzcv_SUB_N_fold_ARM8, nzcv_SUB_C_fold_ARM8, nzcv_SUB_Z_fold_ARM8, nzcv_SUB_V_fold_ARM8, nzcv_NEGS_V_fold_ARM8]
);



(*************************)
(* ARM 8 general add/cmn *)
(*************************)

(* cmp uses w2 - w1, we also need a version for w1 + w2. *)

val nzcv_ADD_V_fold_ARM8 = store_thm ("nzcv_ADD_V_fold_ARM8",
``!w1:'a word w0:'a word.
  ((word_msb w0 <=> word_msb w1) /\
  (word_msb w0 <=/=> BIT (dimindex (:'a) - 1) (w2n w0 + w2n w1))) = nzcv_BIR_ADD_V w0 w1``,

SIMP_TAC std_ss [nzcv_BIR_ADD_V_CARRY_DEF, awc_BIR_V_def,
  add_with_carry_def, LET_THM, GSYM word_msb_n2w]);


(* We need a special case for w0 = w1 *)
val nzcv_ADD_V_fold_ARM8_ID = store_thm ("nzcv_ADD_V_fold_ARM8_ID",
``!w:'a word.
  (word_msb w <=/=> BIT  (dimindex (:'a) - 1) (w2n w + w2n w)) =
  nzcv_BIR_ADD_V w w``,
SIMP_TAC std_ss [GSYM nzcv_ADD_V_fold_ARM8]);


val nzcv_ADD_C_fold_ARM8 = store_thm ("nzcv_ADD_C_fold_ARM8",
``!w1 w0.
  ((if w2n w0 + w2n ((w1:'a word)) < dimword (:'a) then w2n w0 + w2n w1
   else (w2n w0 + w2n w1) MOD (dimword (:'a))) <>
  w2n w0 + w2n w1) = nzcv_BIR_ADD_C w0 w1``,

REPEAT GEN_TAC >>
SIMP_TAC (arith_ss++boolSimps.LIFT_COND_ss) [nzcv_BIR_ADD_C_CARRY_DEF, add_with_carry_def,
  LET_THM, ZERO_LT_dimword, w2n_n2w, awc_BIR_C_def]);


val nzcv_ADD_Z_fold_ARM8 = store_thm ("nzcv_ADD_Z_fold_ARM8",
``!w1 w0. (((w0:'a word) + w1) = 0w) = nzcv_BIR_ADD_Z w0 w1``,
SIMP_TAC std_ss [nzcv_BIR_ADD_Z_def, GSYM nzcv_SUB_Z_fold_ARM8,
  word_sub_def, WORD_NEG_NEG]);

val nzcv_ADD_N_fold_ARM8 = store_thm ("nzcv_ADD_N_fold_ARM8",
``!w1 w0. word_msb ((w0:'a word) + w1) = nzcv_BIR_ADD_N (w0:'a word) w1``,
SIMP_TAC std_ss [nzcv_BIR_ADD_N_def, GSYM nzcv_SUB_N_fold_ARM8,
  word_sub_def, WORD_NEG_NEG]);


val nzcv_ADD_FOLDS_ARM8_GEN = save_thm ("nzcv_ADD_FOLDS_ARM8_GEN",
  LIST_CONJ [nzcv_ADD_N_fold_ARM8, nzcv_ADD_C_fold_ARM8, nzcv_ADD_Z_fold_ARM8, nzcv_ADD_V_fold_ARM8,
    nzcv_ADD_V_fold_ARM8_ID]
)


(*************************)
(* ARM 8 add_with_carry  *)
(*************************)

(* cmp uses w2 - w1, we also need a version for w1 + w2. *)

val awc_BIR_V_fold_ARM8 = store_thm ("awc_BIR_V_fold_ARM8",
``!w1:'a word w0:'a word c.
  ((word_msb w0 <=> word_msb w1) /\
  (word_msb w0 <=/=> BIT (dimindex (:'a) - 1) (w2n w0 + w2n w1 + (if c then 1 else 0)))) = awc_BIR_V w0 w1 c``,

SIMP_TAC std_ss [awc_BIR_V_def,
  add_with_carry_def, LET_THM, GSYM word_msb_n2w]);


val awc_BIR_V_fold_ARM8_ID = store_thm ("awc_BIR_V_fold_ARM8_ID",
``!w:'a word c.
  (word_msb w <=/=> BIT (dimindex (:'a) - 1) (w2n w + w2n w + (if c then 1 else 0))) = awc_BIR_V w w c``,
SIMP_TAC std_ss [GSYM awc_BIR_V_fold_ARM8]);


val awc_BIR_V_fold_ARM8_ngcs = store_thm ("awc_BIR_V_fold_ARM8_ngcs",
``!w:'a word c.
  ((~word_msb (~w)) /\
  (BIT (dimindex (:'a) - 1) (w2n (~w) + (if c then 1 else 0)))) =
   awc_BIR_V 0w (~w) c``,

SIMP_TAC arith_ss [awc_BIR_V_def,
  add_with_carry_def, LET_THM, GSYM word_msb_n2w, WORD_0_POS, w2n_n2w,
  wordsTheory.ZERO_LT_dimword]);



val awc_BIR_C_fold_ARM8 = store_thm ("awc_BIR_C_fold_ARM8",
``!w0 w1 c.
  ((if w2n w0 + ((w2n (w1:'a word)) + if c then 1 else (0:num)) < dimword (:'a) then
       w2n w0 + (w2n w1 + if c then 1 else 0)
  else (w2n w0 + (w2n w1 + if c then 1 else 0)) MOD (dimword (:'a))) <>
  w2n w0 + (w2n w1 + if c then 1 else 0)) = awc_BIR_C w0 w1 c``,

REPEAT GEN_TAC >>
SIMP_TAC (arith_ss++boolSimps.LIFT_COND_ss) [add_with_carry_def,
  LET_THM, ZERO_LT_dimword, w2n_n2w, awc_BIR_C_def]);


val awc_BIR_C_fold_ARM8_ngcs = store_thm ("awc_BIR_C_fold_ARM8_ngcs",
``!w1 c.
  ((if ((w2n (~(w1:'a word))) + if c then 1 else (0:num)) < dimword (:'a) then
       (w2n (~w1) + if c then 1 else 0)
  else ((w2n (~w1) + if c then 1 else 0)) MOD (dimword (:'a))) <>
  (w2n (~w1) + if c then 1 else 0)) = awc_BIR_C 0w (~w1) c``,

SIMP_TAC std_ss [GSYM awc_BIR_C_fold_ARM8, word_0_n2w]);


val awc_BIR_Z_fold_ARM8 = store_thm ("awc_BIR_Z_fold_ARM8",
``!w1 (w0 : 'a word) c.
     ((n2w (w2n w0 + ((w2n w1 + if c then 1 else 0)))) = (0w:'a word)) <=>
     awc_BIR_Z w0 w1 c``,
SIMP_TAC (std_ss++boolSimps.LIFT_COND_ss++wordsLib.WORD_ss) [awc_BIR_Z_def, GSYM word_add_n2w, n2w_w2n]);


val awc_BIR_Z_fold_ARM8_ngcs = store_thm ("awc_BIR_Z_fold_ARM8_ngcs",
``!(w1 : 'a word) c.
     ((n2w ((w2n (~w1) + if c then 1 else 0))) = (0w:'a word)) <=>
     awc_BIR_Z 0w (~w1) c``,
SIMP_TAC std_ss [GSYM awc_BIR_Z_fold_ARM8, word_0_n2w]);


val awc_BIR_N_fold_ARM8 = store_thm ("awc_BIR_N_fold_ARM8",
``!w1 w0 c. BIT (dimindex (:'a) - 1) ((w2n w0 + ((w2n w1 + if c then 1 else 0)))) =
            awc_BIR_N (w0:'a word) w1 c``,
SIMP_TAC std_ss [awc_BIR_N_def, GSYM word_msb_n2w, GSYM word_add_n2w,
  n2w_w2n, word_msb_neg] >>
SIMP_TAC (std_ss++boolSimps.LIFT_COND_ss++wordsLib.WORD_ss) []);


val awc_BIR_N_fold_ARM8_ngcs = store_thm ("awc_BIR_N_fold_ARM8_ngcs",
``!w1:'a word c. BIT (dimindex (:'a) - 1) ((((w2n (~w1) + if c then 1 else 0)))) =
            awc_BIR_N 0w (~w1) c``,
SIMP_TAC std_ss [GSYM awc_BIR_N_fold_ARM8, word_0_n2w]);


val awc_BIR_RES_fold_ARM8 = store_thm ("awc_BIR_RES_fold_ARM8",
``!w0 w1 c. (n2w (w2n w0 + ((w2n w1 + if c then 1 else 0)))) =
            (w0 + w1 + (if c then 1w else 0w))``,
SIMP_TAC (std_ss++boolSimps.LIFT_COND_ss++wordsLib.WORD_ss) [
  GSYM word_add_n2w, n2w_w2n]);


(*
val awc_BIR_RES_fold_ARM8_SBC_xzr_64 = save_thm ("awc_BIR_RES_fold_ARM8_SBC_xzr",
  GENL [``w1:word64``, ``c:bool``]  (
    CONV_RULE (LAND_CONV (SIMP_CONV (std_ss++wordsLib.WORD_ss) []))
      (ISPECL [``w1:word64``, ``0xFFFFFFFFFFFFFFFFw:word64``, ``c:bool``] awc_BIR_RES_fold_ARM8)
  )
);
*)
val maxword_w2n_thm = save_thm ("maxword_w2n_thm",
  GSYM (EVAL ``w2n (0w:word64 - 1w)``)
);


val awc_BIR_RES_fold_ARM8_ngcs = store_thm ("awc_BIR_RES_fold_ARM8_ngcs",
``!w1 c. (n2w (((w2n w1 + if c then 1 else 0)))) =
            (w1 + (if c then 1w else 0w))``,
SIMP_TAC (std_ss++boolSimps.LIFT_COND_ss++wordsLib.WORD_ss) [
  GSYM word_add_n2w, n2w_w2n]);


val awc_BIR_RES_fold_ARM8_BITS = store_thm ("awc_BIR_RES_fold_ARM8_BITS",
``!(w0:'a word) w1 c.
            (dimindex (:'a) < dimindex (:'b)) ==>
            ((n2w (BITS (dimindex (:'a) -1) 0 (w2n w0 + ((w2n w1 + if c then 1 else 0))))):'b word =
             w2w (w0 + w1 + (if c then 1w else 0w)))``,

REPEAT STRIP_TAC >>
MP_TAC (GSYM wordsTheory.w2w_n2w) >>
ASM_SIMP_TAC arith_ss [awc_BIR_RES_fold_ARM8]);


val awc_BIR_RES_fold_ARM8_ngcs_BITS = store_thm ("awc_BIR_RES_fold_ARM8_ngcs_BITS",
``!(w1:'a word) c.
            (dimindex (:'a) < dimindex (:'b)) ==>
            ((n2w (BITS (dimindex (:'a) -1) 0 (((w2n w1 + if c then 1 else 0))))):'b word =
             w2w (w1 + (if c then 1w else 0w)))``,

REPEAT STRIP_TAC >>
MP_TAC (GSYM wordsTheory.w2w_n2w) >>
ASM_SIMP_TAC arith_ss [awc_BIR_RES_fold_ARM8_ngcs]);


val awc_BIR_RES_FOLD_SUB = store_thm ("awc_BIR_RES_FOLD_SUB",
``!w1:'a word w2 c.
     (w1 + (~w2) + (if c then 1w else 0w)) =
     (w1 - w2 - (if c then 0w else 1w))``,

SIMP_TAC std_ss [WORD_NEG, word_sub_def] >>
SIMP_TAC (std_ss++wordsLib.WORD_ss++boolSimps.LIFT_COND_ss) []);


val awc_BIR_RES_FOLD_SUB_ngcs = store_thm ("awc_BIR_RES_FOLD_SUB_ngcs",
``!w1:'a word w2 c.
     ((~w2) + (if c then 1w else 0w)) =
     ((if c then 0w else -1w) - w2)``,

SIMP_TAC std_ss [WORD_NEG, word_sub_def] >>
SIMP_TAC (std_ss++wordsLib.WORD_ss++boolSimps.LIFT_COND_ss) []);


val awc_BIR_Z_nzcv_BIR_SUB_Z_fold = prove (
  ``!(w0:'a word) w1 c. nzcv_BIR_SUB_Z (w0 - w1) (if c then 0w else 1w) =
                        awc_BIR_Z w0 (~w1) c``,

SIMP_TAC std_ss [GSYM awc_BIR_Z_fold_ARM8, GSYM nzcv_SUB_Z_fold_ARM8,
  awc_BIR_RES_fold_ARM8, awc_BIR_RES_FOLD_SUB]);

val awc_BIR_Z_nzcv_BIR_ADD_Z_fold = prove (
  ``!(w0:'a word) w1 c. nzcv_BIR_ADD_Z (w0 + w1) (if c then 1w else 0w) =
                        awc_BIR_Z w0 w1 c``,
SIMP_TAC std_ss [GSYM awc_BIR_Z_fold_ARM8, GSYM nzcv_ADD_Z_fold_ARM8,
  awc_BIR_RES_fold_ARM8, awc_BIR_RES_FOLD_SUB]);

val awc_BIR_Z_nzcv_BIR_ADD_Z_fold_ngcs = prove (
  ``!(w1:'a word) c. nzcv_BIR_ADD_Z (~w1) (if c then 1w else 0w) =
                     awc_BIR_Z 0w (~w1) c``,

SIMP_TAC std_ss [GSYM awc_BIR_Z_fold_ARM8_ngcs, GSYM nzcv_ADD_Z_fold_ARM8,
  awc_BIR_RES_fold_ARM8_ngcs, awc_BIR_RES_FOLD_SUB_ngcs]);


val awc_BIR_Z_nzcv_BIR_SUB_N_fold = prove (
  ``!(w0:'a word) w1 c. nzcv_BIR_SUB_N (w0 - w1) (if c then 0w else 1w) =
                        awc_BIR_N w0 (~w1) c``,

SIMP_TAC std_ss [GSYM awc_BIR_N_fold_ARM8, GSYM nzcv_SUB_N_fold_ARM8,
  awc_BIR_RES_fold_ARM8, awc_BIR_RES_FOLD_SUB, GSYM word_msb_n2w]);


val awc_BIR_Z_nzcv_BIR_ADD_N_fold = prove (
  ``!(w0:'a word) w1 c. nzcv_BIR_ADD_N (w0 + w1) (if c then 1w else 0w) =
                        awc_BIR_N w0 w1 c``,

SIMP_TAC std_ss [GSYM awc_BIR_N_fold_ARM8, GSYM nzcv_ADD_N_fold_ARM8,
  awc_BIR_RES_fold_ARM8, awc_BIR_RES_FOLD_SUB, GSYM word_msb_n2w]);

val awc_BIR_Z_nzcv_BIR_ADD_N_fold_ngcs = prove (
  ``!(w1:'a word) c. nzcv_BIR_ADD_N (~w1) (if c then 1w else 0w) =
                     awc_BIR_N 0w (~w1) c``,

SIMP_TAC std_ss [GSYM awc_BIR_N_fold_ARM8_ngcs, GSYM nzcv_ADD_N_fold_ARM8,
  awc_BIR_RES_fold_ARM8_ngcs, awc_BIR_RES_FOLD_SUB_ngcs, GSYM word_msb_n2w]);


val awc_BIR_NZCV_FOLDS_ARM8_GEN = save_thm ("awc_BIR_NZCV_FOLDS_ARM8_GEN", let
  val thm0 =
  LIST_CONJ [
    awc_BIR_N_fold_ARM8,
    awc_BIR_N_fold_ARM8_ngcs,
    awc_BIR_Z_fold_ARM8,
    awc_BIR_Z_fold_ARM8_ngcs,
    awc_BIR_C_fold_ARM8,
    awc_BIR_C_fold_ARM8_ngcs,
    awc_BIR_V_fold_ARM8,
    awc_BIR_V_fold_ARM8_ID,
    awc_BIR_V_fold_ARM8_ngcs,
    awc_BIR_RES_fold_ARM8,
    awc_BIR_RES_fold_ARM8_BITS,
    awc_BIR_RES_FOLD_SUB,
    awc_BIR_RES_fold_ARM8_ngcs,
    awc_BIR_RES_fold_ARM8_ngcs_BITS,
    awc_BIR_RES_FOLD_SUB_ngcs,
    awc_BIR_Z_nzcv_BIR_SUB_Z_fold,
    awc_BIR_Z_nzcv_BIR_ADD_Z_fold,
    awc_BIR_Z_nzcv_BIR_ADD_Z_fold_ngcs,
    awc_BIR_Z_nzcv_BIR_SUB_N_fold,
    awc_BIR_Z_nzcv_BIR_ADD_N_fold,
    awc_BIR_Z_nzcv_BIR_ADD_Z_fold_ngcs
  ];

  fun normalise_with thms thm = let
    val thm1 = SIMP_RULE std_ss thms thm
    val thm2 = SIMP_RULE std_ss [thm] thm1
  in CONJ thm thm2 end;

  val thm1 = normalise_with [awc_BIR_RES_fold_ARM8_ngcs, awc_BIR_RES_fold_ARM8] thm0
  val thm2 = normalise_with [awc_BIR_N_fold_ARM8, awc_BIR_N_fold_ARM8_ngcs] thm1
  val thm3 = normalise_with [GSYM arithmeticTheory.ADD_ASSOC] thm2
in thm3 end);



(************************)
(* ARM 8 immediate args *)
(************************)

(* The generic one needs instantiating unluckily because immediate arguments
   are allowed and there are extra simps for these. *)

(* We can ignore the case "n < INT_MIN (:'a)" since
   n is computed from a small immediate and should for all
   relevant cases be that large. *)
val nzcv_SUB_V_fold_ARM8_CONST = store_thm ("nzcv_SUB_V_fold_ARM8_CONST",
``!w0 n. n < dimword (:'a) ==> INT_MIN (:'a) <= n ==>
   (((word_msb w0) /\
    (word_msb w0 <=/=> BIT  (dimindex (:'a) - 1) (w2n w0 + n + 1))) =

   (nzcv_BIR_SUB_V (w0:'a word) (n2w (dimword (:'a) - SUC n))))``,

REPEAT STRIP_TAC >>
ASM_SIMP_TAC arith_ss [GSYM nzcv_SUB_V_fold_ARM8,
  word_1comp_n2w, w2n_n2w, word_msb_n2w_numeric]);


val nzcv_ADD_V_fold_ARM8_CONST = store_thm ("nzcv_ADD_V_fold_ARM8_CONST",
``!(w0 : 'a word) n. n < dimword (:'a) ==> (n < INT_MIN (:'a)) ==>
   ((~(word_msb w0) /\
    (word_msb w0 <=/=> BIT  (dimindex (:'a) - 1) (w2n w0 + n))) =
   nzcv_BIR_ADD_V w0 (n2w n))``,

REPEAT STRIP_TAC >>
ASM_SIMP_TAC arith_ss [GSYM nzcv_ADD_V_fold_ARM8,
  word_1comp_n2w, w2n_n2w, word_msb_n2w_numeric]);



val nzcv_SUB_C_fold_ARM8_CONST = store_thm ("nzcv_SUB_C_fold_ARM8_CONST",
``!w0 n. n < dimword (:'a) ==>
 ( ((if w2n w0 + n + 1 < dimword (:'a) then w2n w0 + n + 1
   else (w2n w0 + n + 1) MOD (dimword (:'a))) <>
  w2n w0 + n + 1) = (nzcv_BIR_SUB_C (w0:'a word) (n2w (dimword (:'a) - SUC n))))``,
SIMP_TAC arith_ss [GSYM nzcv_SUB_C_fold_ARM8,  word_1comp_n2w, w2n_n2w]);


val nzcv_ADD_C_fold_ARM8_CONST = store_thm ("nzcv_ADD_C_fold_ARM8_CONST",
``!w0 n. n < dimword (:'a) ==>
 ( ((if w2n w0 + n < dimword (:'a) then w2n w0 + n
   else (w2n w0 + n) MOD (dimword (:'a))) <>
  w2n w0 + n) = (nzcv_BIR_ADD_C (w0:'a word) (n2w n)))``,
SIMP_TAC arith_ss [GSYM nzcv_ADD_C_fold_ARM8, w2n_n2w]);


(* For Z and N no special constant rewrites are needed, the standard ones
   for ADD always fire. However, we might not want this, since we want to
   introduce nzcv_BIR_SUB_Z and nzcv_BIR_SUB_C.
   So let us rewrite, if constants are two large. *)

val nzcv_ADD_Z_to_SUB = store_thm ("nzcv_ADD_Z_to_SUB",
``!(w0:'a word) n.
         (n < dimword (:'a)) /\ (dimword (:'a) - n < n) ==>
         (nzcv_BIR_ADD_Z w0 (n2w n) <=>
          nzcv_BIR_SUB_Z w0 (n2w (dimword (:'a) - n)))``,

REPEAT STRIP_TAC >>
ASM_SIMP_TAC std_ss [nzcv_BIR_ADD_Z_def, word_2comp_n2w]);


val nzcv_ADD_N_to_SUB = store_thm ("nzcv_ADD_N_to_SUB",
``!(w0:'a word) n.
         (n < dimword (:'a)) /\ (dimword (:'a) - n < n) ==>
         (nzcv_BIR_ADD_N w0 (n2w n) <=>
          nzcv_BIR_SUB_N w0 (n2w (dimword (:'a) - n)))``,

REPEAT STRIP_TAC >>
ASM_SIMP_TAC std_ss [nzcv_BIR_ADD_N_def, word_2comp_n2w]);

(* For 0 it does not matter, which constant is smaller, but SUB is more canonical *)
val nzcv_ADD_ZN_to_SUB_0 = store_thm ("nzcv_ADD_ZN_to_SUB_0",
``(!(w0:'a word). (nzcv_BIR_ADD_Z w0 (n2w 0) <=>  nzcv_BIR_SUB_Z w0 (n2w 0))) /\
  (!(w0:'a word). (nzcv_BIR_ADD_N w0 (n2w 0) <=>  nzcv_BIR_SUB_N w0 (n2w 0)))``,

ASM_SIMP_TAC std_ss [nzcv_BIR_ADD_Z_def, nzcv_BIR_ADD_N_def, word_2comp_n2w,
  ZERO_LT_dimword, n2w_dimword]);



(* Nothing special needed for Z and N *)
val nzcv_ADD_FOLDS_ARM8_CONST_GEN = save_thm ("nzcv_ADD_FOLDS_ARM8_CONST_GEN",
  LIST_CONJ [
        nzcv_ADD_C_fold_ARM8_CONST,
        nzcv_ADD_V_fold_ARM8_CONST]
)


val nzcv_SUB_FOLDS_ARM8_CONST_GEN = save_thm ("nzcv_SUB_FOLDS_ARM8_CONST_GEN",
  LIST_CONJ [
        nzcv_SUB_C_fold_ARM8_CONST,
        nzcv_SUB_V_fold_ARM8_CONST,
        nzcv_ADD_N_to_SUB,
        nzcv_ADD_Z_to_SUB,
        nzcv_ADD_ZN_to_SUB_0]
);




(***************************)
(* ARM 8 32 bit and 64 bit *)
(***************************)

(* What we really need is an instance for 32 and 64 bit words, though*)
val nzcv_FOLDS_ARM8_gen_size = LIST_CONJ [
      nzcv_BIR_SIMPS,
      nzcv_SUB_FOLDS_ARM8_GEN,
      nzcv_SUB_FOLDS_ARM8_CONST_GEN,
      nzcv_ADD_FOLDS_ARM8_GEN,
      nzcv_ADD_FOLDS_ARM8_CONST_GEN,
      awc_BIR_NZCV_FOLDS_ARM8_GEN];


val nzcv_FOLDS_ARM8 = save_thm ("nzcv_FOLDS_ARM8",
SIMP_RULE (std_ss) [arithmeticTheory.ADD_ASSOC] (
SIMP_RULE (std_ss++wordsLib.SIZES_ss) []  (LIST_CONJ [
  maxword_w2n_thm,(* awc_BIR_RES_fold_ARM8_SBC_xzr_64,*)
  INST_TYPE [``:'a`` |-> ``:32``, ``:'b`` |-> ``:64``] nzcv_FOLDS_ARM8_gen_size,
  INST_TYPE [``:'a`` |-> ``:64``, ``:'b`` |-> ``:64``] nzcv_FOLDS_ARM8_gen_size
 ]
)));



(*********)
(* Tests *)
(*********)

(*

open arm8_stepLib

fun test_nzcv_folds_hex s =
  (arm8.diss s, s,
   map (SIMP_RULE std_ss [nzcv_FOLDS_ARM8]) (arm8_step_hex s));

val test_nzcv_folds_code = List.map test_nzcv_folds_hex o arm8AssemblerLib.arm8_code;


test_nzcv_folds_code `CMP w0, #3`;
test_nzcv_folds_code `cmp w0, #324`;
test_nzcv_folds_code `cmp w0, #0`;
test_nzcv_folds_code `cmp w0, w1`;
test_nzcv_folds_code `cmp w0, w0`;
test_nzcv_folds_code `cmp w1, w1`;



test_nzcv_folds_code `CMP x0, #3`;
test_nzcv_folds_code `cmp x0, #324`;
test_nzcv_folds_code `cmp x0, #0`;
test_nzcv_folds_code `cmp x0, x1`;
test_nzcv_folds_code `cmp x0, x0`;
test_nzcv_folds_code `cmp x1, x1`;

test_nzcv_folds_code `cmn w0, #3`
test_nzcv_folds_code `cmn w0, #324`
test_nzcv_folds_code `cmn w0, #0`
test_nzcv_folds_code `cmn w0, w2`
test_nzcv_folds_code `cmp w0, #0`
test_nzcv_folds_code `cmn w1, w1`

test_nzcv_folds_code `ADDS x0, x1, x2`

arm8AssemblerLib.arm8_code `str x0, [x1, #16]`
arm8AssemblerLib.arm8_code `add x0, x1, #1`
arm8AssemblerLib.arm8_code `str x0, [sp, #8]`

test_nzcv_folds_code `subs w0, w1, w2`
test_nzcv_folds_code `adds w0, w1, w1`
test_nzcv_folds_code `bics w0, w1, w2`
test_nzcv_folds_code `bics x0, x1, x2`

test_nzcv_folds_hex "1b000001"

(*
arm8_step_hex "DA1F0000";
arm8_step_hex "DA020000";
*)

test_nzcv_folds_code `sbcs x0, x0, xzr`
test_nzcv_folds_hex "DA1F0000";
test_nzcv_folds_hex "DA020000";

*)



(*********)
(* ARM 0 *)
(*********)

val awc_BIR_C_fold_M0 = store_thm ("awc_BIR_C_fold_M0",
``!w1 w0 c. CARRY_OUT w0 w1 c = awc_BIR_C w0 w1 c``,
REWRITE_TAC[awc_BIR_C_def]);

val awc_BIR_RES_fold_M0 = store_thm ("awc_BIR_RES_fold_M0",
``!w0 w1 c. FST (add_with_carry (w0,w1,c)) =
            w0 + w1 + (if c then 1w else 0w)``,
SIMP_TAC arith_ss [add_with_carry_def, LET_THM,
  awc_BIR_RES_fold_ARM8]);

val awc_BIR_Z_fold_M0 = store_thm ("awc_BIR_Z_fold_M0",
``!w1 w0 c. ((w0 + w1 + (if c then 1w else 0w)) = 0w) <=> awc_BIR_Z w0 w1 c``,
REWRITE_TAC[awc_BIR_Z_def]);

val awc_BIR_V_fold_M0 = store_thm ("awc_BIR_V_fold_M0",
``!w1 w0 c. OVERFLOW w0 w1 c = awc_BIR_V w0 w1 c``,
REWRITE_TAC[awc_BIR_V_def]);

val nzcv_SUB_N_fold_M0 = store_thm ("nzcv_SUB_N_fold_M0",
``!w1:word32 w0. (word_bit 31 (w0 - w1)) = nzcv_BIR_SUB_N w0 w1``,
SIMP_TAC (std_ss++wordsLib.SIZES_ss) [nzcv_BIR_SUB_N_def, nzcv_def, LET_THM, word_msb,
  GSYM word_add_def, word_sub_def])

val nzcv_ADD_N_fold_M0 = store_thm ("nzcv_ADD_N_fold_M0",
``!w1:word32 w0. (word_bit 31 (w0 + w1)) = nzcv_BIR_ADD_N w0 w1``,
SIMP_TAC std_ss [nzcv_BIR_ADD_N_def,
  GSYM nzcv_SUB_N_fold_M0, word_sub_def, WORD_NEG_NEG]);

val nzcv_SUB_Z_fold_M0 = store_thm ("nzcv_SUB_Z_fold_M0",
``!w1 w0. (w0 - w1 = 0w) = nzcv_BIR_SUB_Z w0 w1``,
REWRITE_TAC[nzcv_SUB_Z_fold_ARM8]);

val nzcv_ADD_Z_fold_M0 = store_thm ("nzcv_ADD_Z_fold_M0",
``!w1 w0. (w0 + w1 = 0w) = nzcv_BIR_ADD_Z w0 w1``,
REWRITE_TAC[nzcv_ADD_Z_fold_ARM8]);


val lsrs_C_fold_M0 = store_thm ("lsrs_C_fold_M0",
``!(w1:word8) (w2:word32) c.
  (if w2n w1 = 0 then c else
     w2n w1 <= 32 /\ word_bit (w2n w1 - 1) w2) =
  (if w1 = 0w then c else
    (w1 <=+ 32w /\ word_bit (w2n (w1 - 1w)) w2))
``,

Cases >> rename1 `n1 < dimword _` >>
FULL_SIMP_TAC (arith_ss++wordsLib.SIZES_ss) [w2n_n2w, n2w_11,
  word_ls_n2w, bir_auxiliaryTheory.word_sub_n2w]);


val asrs_C_fold_M0 = store_thm ("asrs_C_fold_M0",
``!(w1:word8) (w2:word32) c.
  (if w2n w1 = 0 then c else
     word_bit ((MIN 32 (w2n w1)) - 1) w2) =
  (if w1 = 0w then c else
    (if w1 <=+ 32w then
        word_bit (w2n (w1 - 1w)) w2
     else word_bit 31 w2))
``,

Cases >> rename1 `n1 < dimword _` >>
FULL_SIMP_TAC (arith_ss++wordsLib.SIZES_ss) [w2n_n2w, n2w_11,
  word_ls_n2w, bir_auxiliaryTheory.word_sub_n2w, arithmeticTheory.MIN_DEF,
  word_msb_def] >>
REPEAT STRIP_TAC >>
Cases_on `n1 <= 32` >> ASM_SIMP_TAC arith_ss []);



val lsls_C_fold_M0 = store_thm ("lsls_C_fold_M0",
``!(w1:word8) (w2:word32) c.
  (if w2n w1 = 0 then c else
     (((w2w w2): 33 word) << w2n w1) ' 32) =
  (if w1 = 0w then c else word_bit (w2n (32w - w1)) w2)
``,

Cases >> rename1 `n1 < dimword _` >>
FULL_SIMP_TAC (arith_ss++wordsLib.SIZES_ss) [w2n_n2w, n2w_11,
  word_ls_n2w, bir_auxiliaryTheory.word_sub_n2w] >>
Cases_on `n1 = 0` >> ASM_SIMP_TAC arith_ss [] >>

ASM_SIMP_TAC (arith_ss++wordsLib.SIZES_ss) [word_lsl_def,
  fcpTheory.FCP_BETA, w2w, word_bit_def] >>
Cases_on `n1 <= 32` >> ASM_SIMP_TAC arith_ss []);


val rors_C_fold_M0 = store_thm ("rors_C_fold_M0",
``!(w1:word8) (w2:word32) c.
  (if w2n w1 = 0 then c else
    word_msb w2) =
  (if (w1 = 0w) then c else word_msb w2)``,

Cases >> rename1 `n1 < dimword _` >>
FULL_SIMP_TAC (arith_ss++wordsLib.SIZES_ss) [w2n_n2w, n2w_11,
  w2w_def]);


val nzcv_FOLDS_M0 = save_thm ("nzcv_FOLDS_M0",
 LIST_CONJ [awc_BIR_V_fold_M0, awc_BIR_C_fold_M0,
            awc_BIR_NZVC_ELIMS, awc_BIR_Z_fold_M0,
            awc_BIR_RES_fold_M0, awc_BIR_RES_FOLD_SUB,
            nzcv_SUB_N_fold_M0, nzcv_ADD_N_fold_M0,
            nzcv_SUB_Z_fold_M0, nzcv_ADD_Z_fold_M0,
            nzcv_BIR_SIMPS,
            awc_BIR_Z_nzcv_BIR_SUB_Z_fold,
            awc_BIR_Z_nzcv_BIR_ADD_Z_fold,
            awc_BIR_Z_nzcv_BIR_SUB_N_fold,
            awc_BIR_Z_nzcv_BIR_ADD_N_fold,

            lsrs_C_fold_M0, asrs_C_fold_M0, lsls_C_fold_M0,
            rors_C_fold_M0
]);


(* Test

open m0_stepLib

val ev = thumb_step_code (true, true);
fun test_nzcv_folds s =
  (map (SIMP_RULE std_ss [nzcv_FOLDS_M0]) (flatten (ev s)));

test_nzcv_folds `adds r2, #0`
test_nzcv_folds `adds r2, #1`
test_nzcv_folds `subs r2, r2`
test_nzcv_folds `cmp r0, #3`
test_nzcv_folds `adcs r0, r1`
test_nzcv_folds `sbcs r0, r1`
test_nzcv_folds `sbcs r0, r0`
test_nzcv_folds `cmn r0, r1`
test_nzcv_folds `cmp r0, #0`

*)

val _ = export_theory();
