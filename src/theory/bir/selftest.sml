open HolKernel Parse boolTheory boolLib pairTheory

open HolKernel Parse boolLib bossLib;
open wordsTheory bitstringTheory HolBACoreSimps;
open bir_auxiliaryTheory bir_immTheory bir_valuesTheory;
open bir_exp_immTheory bir_exp_memTheory bir_envTheory;
open bir_expTheory bir_programTheory;
open bir_typing_expTheory bir_typing_progTheory;
open bir_immSyntax bir_valuesSyntax bir_envSyntax bir_exp_memSyntax;
open bir_exp_immSyntax bir_expSyntax;
open bir_programSyntax;
open bir_typing_expSyntax;
open wordsLib;

val _ = print "HolBA bir files successfully loaded.\n";

val _ = Process.exit Process.success;
