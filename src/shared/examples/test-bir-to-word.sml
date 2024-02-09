open HolKernel Parse boolLib bossLib;

(* Load the dependencies in interactive sessions *)
val _ = if !Globals.interactive then (
  load "../bir_exp_to_wordsLib"; (* ../ *)
  ()) else ();

open bir_exp_to_wordsLib;

val _ = Parse.current_backend := PPBackEnd.vt100_terminal;
val _ = wordsLib.add_word_cast_printer ();
val _ = Globals.show_types := true;

(*
val _ = Globals.linewidth := 100;
val _ = Globals.show_assums := true;
val _ = Globals.show_tags := true;
*)

val bir_exprs = [
  ("32-bits constant",
    ``BExp_Const (Imm32 12345w)``,
    ``(12345w :word32)``),

  ("not equal",
    ``(BExp_UnaryExp BIExp_Not
        (BExp_BinPred BIExp_Equal
          (BExp_Den (BVar "x" (BType_Imm Bit32)))
          (BExp_Const (Imm32 0w))))``,
    ``~if (x :word32) = (0w :word32) then (1w :word1) else (0w :word1)``),

  ("64-bits substraction",
    ``(BExp_BinExp BIExp_Minus
        (BExp_Den (BVar "x" (BType_Imm Bit64)))
        (BExp_Const (Imm64 112w)))``,
    ``(x :word64) - (112w :word64)``),

  ("Less-than predicate",
    ``(BExp_BinPred BIExp_LessThan
        (BExp_Den (BVar "x" (BType_Imm Bit128)))
        (BExp_Const (Imm128 45867w)))``,
    ``if (x :word128) <+ (45867w :word128) then (1w :word1) else (0w :word1)``),

  ("If-then-else with less-than",
    ``(BExp_IfThenElse
        (BExp_BinPred BIExp_LessThan (BExp_Const (Imm64 112w)) (BExp_Const (Imm64 11w)))
        (BExp_Const (Imm64 200w))
        (BExp_Const (Imm64 404w)))``,
    ``if (112w :word64) <+ (11w :word64) then (200w :word64) else (404w :word64)``),

  ("16-bit value store",
    ``(BExp_Store
        (BExp_Den (BVar "memory" (BType_Mem Bit32 Bit8)))
        (BExp_Den (BVar "address" (BType_Imm Bit32)))
        BEnd_BigEndian
        (BExp_Const (Imm16 (42w :word16))))``,
    ``(memory :word32 |-> word8)
        |+ ((address + (1w :word32),
            ((((7 :num) >< (0 :num)) :word16 -> word8) (42w :word16))))
        |+ ((address :word32) + (0w :word32),
            ((((15 :num) >< (8 :num)) :word16 -> word8) (42w :word16)))
        ``),

  ("16-bit value store (little endian)",
    ``(BExp_Store
        (BExp_Den (BVar "memory" (BType_Mem Bit32 Bit8)))
        (BExp_Den (BVar "address" (BType_Imm Bit32)))
        BEnd_LittleEndian
        (BExp_Const (Imm16 (42w :word16))))``,
    ``(memory :word32 |-> word8)
        |+ ((address :word32) + (1w :word32),
            ((((15 :num) >< (8 :num)) :word16 -> word8) (42w :word16)))
        |+ ((address + (0w :word32),
            ((((7 :num) >< (0 :num)) :word16 -> word8) (42w :word16))))
        ``),

  ("128-bit value load",
    ``(BExp_Load
        (BExp_Den (BVar "memory" (BType_Mem Bit64 Bit8)))
        (BExp_Den (BVar "address" (BType_Imm Bit64)))
        BEnd_BigEndian
        Bit128)``,
    ``(word_concat :word8 -> 120 word -> word128 )
       (((memory :word64 |-> word8) ' ((address :word64) + (0w :word64))) :word8)
     ((word_concat :word8 -> 112 word -> 120 word )
       ((memory ' (address + (1w :word64))) :word8)
     ((word_concat :word8 -> 104 word -> 112 word )
       ((memory ' (address + (2w :word64))) :word8)
     ((word_concat :word8 -> word96 -> 104 word )
       ((memory ' (address + (3w :word64))) :word8)
     ((word_concat :word8 -> 88 word -> word96 )
       ((memory ' (address + (4w :word64))) :word8)
     ((word_concat :word8 -> 80 word -> 88 word )
       ((memory ' (address + (5w :word64))) :word8)
     ((word_concat :word8 -> 72 word -> 80 word )
       ((memory ' (address + (6w :word64))) :word8)
     ((word_concat :word8 -> word64 -> 72 word )
       ((memory ' (address + (7w :word64))) :word8)
     ((word_concat :word8 -> 56 word -> word64 )
       ((memory ' (address + (8w :word64))) :word8)
     ((word_concat :word8 -> word48 -> 56 word )
       ((memory ' (address + (9w :word64))) :word8)
     ((word_concat :word8 -> 40 word -> word48 )
       ((memory ' (address + (10w :word64))) :word8)
     ((word_concat :word8 -> word32 -> 40 word )
       ((memory ' (address + (11w :word64))) :word8)
     ((word_concat :word8 -> word24 -> word32 )
       ((memory ' (address + (12w :word64))) :word8)
     ((word_concat :word8 -> word16 -> word24 )
       ((memory ' (address + (13w :word64))) :word8)
     ((word_concat :word8 -> word8 -> word16 )
       ((memory ' (address + (14w :word64))) :word8)
     ((memory ' (address + (15w :word64))) :word8)))))))))))))))``),

  ("128-bit value load (little endian)",
    ``(BExp_Load
        (BExp_Den (BVar "memory" (BType_Mem Bit64 Bit8)))
        (BExp_Den (BVar "address" (BType_Imm Bit64)))
        BEnd_LittleEndian
        Bit128)``,
    ``(word_concat :word8 -> 120 word -> word128 )
       (((memory :word64 |-> word8) ' ((address :word64) + (15w :word64))) :word8)
     ((word_concat :word8 -> 112 word -> 120 word )
       ((memory ' (address + (14w :word64))) :word8)
     ((word_concat :word8 -> 104 word -> 112 word )
       ((memory ' (address + (13w :word64))) :word8)
     ((word_concat :word8 -> word96 -> 104 word )
       ((memory ' (address + (12w :word64))) :word8)
     ((word_concat :word8 -> 88 word -> word96 )
       ((memory ' (address + (11w :word64))) :word8)
     ((word_concat :word8 -> 80 word -> 88 word )
       ((memory ' (address + (10w :word64))) :word8)
     ((word_concat :word8 -> 72 word -> 80 word )
       ((memory ' (address + (9w :word64))) :word8)
     ((word_concat :word8 -> word64 -> 72 word )
       ((memory ' (address + (8w :word64))) :word8)
     ((word_concat :word8 -> 56 word -> word64 )
       ((memory ' (address + (7w :word64))) :word8)
     ((word_concat :word8 -> word48 -> 56 word )
       ((memory ' (address + (6w :word64))) :word8)
     ((word_concat :word8 -> 40 word -> word48 )
       ((memory ' (address + (5w :word64))) :word8)
     ((word_concat :word8 -> word32 -> 40 word )
       ((memory ' (address + (4w :word64))) :word8)
     ((word_concat :word8 -> word24 -> word32 )
       ((memory ' (address + (3w :word64))) :word8)
     ((word_concat :word8 -> word16 -> word24 )
       ((memory ' (address + (2w :word64))) :word8)
     ((word_concat :word8 -> word8 -> word16 )
       ((memory ' (address + (1w :word64))) :word8)
     ((memory ' (address + (0w :word64))) :word8)))))))))))))))``),

  ("Memory constant (128->16) with hol variable for the memory map",
    ``BExp_MemConst Bit128 Bit16 amap``,
    ``amap :word128 |-> word16``),

  ("Cast Unsigned with a 128bit bir variable to 16bit (down)",
    ``BExp_Cast BIExp_UnsignedCast (BExp_Den (BVar "avar" (BType_Imm Bit128))) Bit16``,
    ``(w2w :word128  -> word16 ) (avar :word128)``),

  ("Cast Unsigned with a 16bit bir variable to 128bit (up)",
    ``BExp_Cast BIExp_UnsignedCast (BExp_Den (BVar "avar" (BType_Imm Bit16))) Bit128``,
    ``(w2w :word16  -> word128 ) (avar :word16)``),

  ("Cast Low with a 128bit bir variable to 16bit (down)",
    ``BExp_Cast BIExp_LowCast (BExp_Den (BVar "avar" (BType_Imm Bit128))) Bit16``,
    ``(w2w :word128  -> word16 ) (avar :word128)``),

  ("Cast Low with a 16bit bir variable to 128bit (up)",
    ``BExp_Cast BIExp_LowCast (BExp_Den (BVar "avar" (BType_Imm Bit16))) Bit128``,
    ``(w2w :word16  -> word128 ) (avar :word16)``),

  ("Cast Signed with a 128bit bir variable to 16bit (down)",
    ``BExp_Cast BIExp_SignedCast (BExp_Den (BVar "avar" (BType_Imm Bit128))) Bit16``,
    ``(w2w :word128  -> word16 ) (avar :word128)``),

  ("Cast Signed with a 16bit bir variable to 128bit (up - extend with sign bit)",
    ``BExp_Cast BIExp_SignedCast (BExp_Den (BVar "avar" (BType_Imm Bit16))) Bit128``,
    ``(sw2sw :word16 -> word128) (avar :word16)``),

  ("Cast High with a 128bit bir variable to 16bit (down - take the highest bits)",
    ``BExp_Cast BIExp_HighCast (BExp_Den (BVar "avar" (BType_Imm Bit128))) Bit16``,
    ``(w2wh :word128 -> word16 ) (avar :word128)``),

  ("Cast High with a 16bit bir variable to 128bit (up)",
    ``BExp_Cast BIExp_HighCast (BExp_Den (BVar "avar" (BType_Imm Bit16))) Bit128``,
    ``(w2w :word16 -> word128 ) (avar :word16)``)

(*
  (* TODO: Unsigned and Low casts are straightforward,
           Signed and High cast seems correct now,
           but, can HolSmt actually handle w2wh? I think it cannot, can it?! *)
*)
];

(*
open bir_exp_immTheory;
bir_cast_REWRS;
bir_scast_REWRS;
bir_hcast_REWRS;

val exp = ``
BExp_Cast BIExp_SignedCast (BExp_Const (Imm16 0x8001w)) Bit8
``;
val exp = ``
BExp_Cast BIExp_SignedCast (BExp_Const (Imm8 0x81w)) Bit16
``;
val exp = ``
BExp_Cast BIExp_LowCast (BExp_Const (Imm8 0x81w)) Bit8
``;

(EVAL) ``bir_eval_exp ^exp (BEnv (K NONE))``

(EVAL) ``(sw2sw :word8  -> word16) (0x81w:word8)``
(EVAL) ``(w2w   :word16 -> word8 ) (0x8001w:word16)``
*)

(* Print all BIR expressions as words expressions and check that they are correct. *)
val _ = List.foldl
  (fn ((name, bir_exp, expected), _) =>
    let
      val word_exp = bir2w bir_exp
      val correct = (identical word_exp expected)
      val _ = print (name ^ ":\n")
      val _ = Hol_pp.print_term word_exp
      val _ = if correct then () else (
        print "Expected: \n";
        Hol_pp.print_term expected;
        print "\n";
        raise Fail ("Incorrect result for '" ^ name ^ "'")
        )
      val _ = print "\n"
    in () end) () bir_exprs;

