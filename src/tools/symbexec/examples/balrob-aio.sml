open HolKernel Parse

open binariesLib;
open binariesCfgLib;
open binariesMemLib;

open bir_symbexec_driverLib;

(*
(* motor_set_l *)

val entry_label = "motor_set_l";
val (lbl_tm, syst_start) = init_func entry_label;
val systs_start = [syst_start];

val stop_lbl_tms = find_func_ends n_dict entry_label;
val systs_after = drive_to n_dict bl_dict_ systs_start stop_lbl_tms;

val sum = merge_to_summary lbl_tm systs_after;
*)


(* motor_set *)

val entry_label = "motor_set";
val lbl_tm      = find_func_lbl_tm entry_label;
val usage       = commonBalrobScriptLib.get_fun_usage entry_label;

val syst_start  = init_summary lbl_tm usage;
val systs_start = [syst_start];

val stop_lbl_tms = find_func_ends n_dict entry_label;
val systs_after = drive_to n_dict bl_dict_ systs_start stop_lbl_tms;

val sum = merge_to_summary lbl_tm systs_after;

