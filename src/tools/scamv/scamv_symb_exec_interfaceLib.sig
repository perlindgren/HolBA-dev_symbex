signature scamv_symb_exec_interfaceLib =
sig
  val scamv_run_symb_exec :
      Term.term
      -> (Term.term
          * (Term.term * Term.term * Term.term) list option) list
         * Term.term list
end
