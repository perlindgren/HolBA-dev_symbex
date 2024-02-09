signature bir_obs_modelLib =
    sig
        include Abbrev;

        val get_obs_model : string -> { id : string,
                                        obs_hol_type : term,
                                        add_obs : term -> term -> term }
    end

signature OBS_MODEL =
    sig
        val obs_hol_type : Abbrev.term

        (* takes boundary for mremory load and store addresses (min and max) *)
        (* In HOL: (word64 # word64) -> 'a bir_program_t -> obs_hol_type bir_program_t *)
        val add_obs : Abbrev.term -> Abbrev.term -> Abbrev.term
    end
