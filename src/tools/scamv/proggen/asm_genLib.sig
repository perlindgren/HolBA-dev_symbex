signature asm_genLib =
sig
    include qc_genLib;

     datatype BranchCond = EQ | NE | LT | GT | HS
     datatype Operand =
              Imm of int
            | Ld  of int option * string
            | Ld2 of string * string
            | Reg of string
     datatype ArmInstruction =
              Load    of Operand * Operand
            | Store   of Operand * Operand
            | Branch  of BranchCond option * Operand
            | Compare of Operand * Operand
            | Nop
            | Add     of Operand * Operand * Operand
	    | Lsl     of Operand * Operand * Operand
		      
    val pp_program : ArmInstruction list -> string list;

    val arb_addr : int Gen;

    val arb_imm : Operand Gen;
    val arb_reg : Operand Gen;
    val arb_armv8_regname : string Gen;
    val arb_operand : Operand Gen;

    val arb_branchcond : BranchCond option Gen;
    val arb_ld : Operand Gen;
    val arb_instruction_noload_nobranch : ArmInstruction Gen;

    val arb_program_load : ArmInstruction list Gen;
    val arb_program_previct1 : ArmInstruction list Gen;
    val arb_program_previct2 : ArmInstruction list Gen;
    val arb_program_previct3 : ArmInstruction list Gen;
    val arb_program_previct4 : ArmInstruction list Gen;
    val arb_program_previct5 : ArmInstruction list Gen;

    val arb_program_xld_br_yld : ArmInstruction list Gen;
    val arb_program_xld_br_yld_mod1 : ArmInstruction list Gen;

    val arb_program_spectre_v1 : ArmInstruction list Gen;
    val arb_program_spectre_v1_mod1 : ArmInstruction list Gen;

    val prog_gen_a_la_qc : ArmInstruction list Gen -> int -> string list;
    val prog_gen_a_la_qc_noresize : ArmInstruction list Gen -> int -> string list;

    val arb_program_glue_spectre : (ArmInstruction list * ArmInstruction list) Gen ->
				   ArmInstruction list Gen -> ArmInstruction list Gen
    val arb_program_spectre : ArmInstruction list Gen
end

