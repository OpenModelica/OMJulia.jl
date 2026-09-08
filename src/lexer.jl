# Generated Lexer for OpenModelica Values.Value output
#
# Do not edit by hand. Regenerate with:
#
#     julia --project=bin bin/generate_lexer.jl

@enum OMToken::UInt8 ERROR WS STRING INT FLOAT IDENT OPERATOR RECORD TRUE FALSE

begin
    function Base.iterate(tokenizer::(Tokenizer){OMToken, D, 1}, state = (1, Int32(1), ERROR)) where D
        data = tokenizer.data
        (start, len, token) = state
        start > sizeof(data) && return nothing
        if token !== ERROR
            return (state, (start + len, Int32(0), ERROR))
        end
        begin
            byte::UInt8 = 0x00
            p::Int = 1
            p_end::Int = sizeof(data)
            is_eof::Bool = true
            cs::Int = 1
        end
        token_start = start
        stop = 0
        token = ERROR
        while true
            p = token_start
            cs = 1
            begin
                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:531 =# GC.@preserve data begin
                        mem = (Automa.SizedMemory)(data)
                        if p > p_end
                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:534 =# @goto exit
                        end
                        if cs == 1
                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_1
                        else
                            if cs == 2
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_2
                            else
                                if cs == 3
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_3
                                else
                                    if cs == 4
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_4
                                    else
                                        if cs == 5
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_5
                                        else
                                            if cs == 6
                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_6
                                            else
                                                if cs == 7
                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_7
                                                else
                                                    if cs == 8
                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_8
                                                    else
                                                        if cs == 9
                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_9
                                                        else
                                                            if cs == 10
                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_10
                                                            else
                                                                if cs == 11
                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_11
                                                                else
                                                                    if cs == 12
                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_12
                                                                    else
                                                                        if cs == 13
                                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_13
                                                                        else
                                                                            if cs == 14
                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_14
                                                                            else
                                                                                if cs == 15
                                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_15
                                                                                else
                                                                                    if cs == 16
                                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_16
                                                                                    else
                                                                                        if cs == 17
                                                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_17
                                                                                        else
                                                                                            if cs == 18
                                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_18
                                                                                            else
                                                                                                if cs == 19
                                                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_19
                                                                                                else
                                                                                                    if cs == 20
                                                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_20
                                                                                                    else
                                                                                                        if cs == 21
                                                                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_21
                                                                                                        else
                                                                                                            if cs == 22
                                                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_22
                                                                                                            else
                                                                                                                if cs == 23
                                                                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_23
                                                                                                                else
                                                                                                                    if cs == 24
                                                                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_24
                                                                                                                    else
                                                                                                                        if cs == 25
                                                                                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_25
                                                                                                                        else
                                                                                                                            if cs == 26
                                                                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_26
                                                                                                                            else
                                                                                                                                if cs == 27
                                                                                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_27
                                                                                                                                else
                                                                                                                                    if cs == 28
                                                                                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_28
                                                                                                                                    else
                                                                                                                                        if cs == 29
                                                                                                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_29
                                                                                                                                        else
                                                                                                                                            if cs == 30
                                                                                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_30
                                                                                                                                            else
                                                                                                                                                if cs == 31
                                                                                                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_31
                                                                                                                                                else
                                                                                                                                                    if cs == 32
                                                                                                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:514 =# @goto state_case_32
                                                                                                                                                    else
                                                                                                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:513 =# @goto exit
                                                                                                                                                    end
                                                                                                                                                end
                                                                                                                                            end
                                                                                                                                        end
                                                                                                                                    end
                                                                                                                                end
                                                                                                                            end
                                                                                                                        end
                                                                                                                    end
                                                                                                                end
                                                                                                            end
                                                                                                        end
                                                                                                    end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        begin
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_1
                                p += 1
                                if p > p_end
                                    cs = 1
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_1
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x47:0x53 || (byte in 0x67:0x71 || (byte in 0x55:0x5a || (byte in 0x75:0x7a || (byte in 0x41:0x45 || (byte in 0x61:0x64 || (byte in 0x5f:0x5f || (byte in 0x73:0x73 || false)))))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte in 0x30:0x39 && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_12_action_1
                                    else
                                        if (byte in 0x28:0x29 || (byte in 0x2c:0x2c || (byte in 0x3b:0x3b || (byte in 0x3d:0x3d || (byte in 0x7b:0x7b || (byte in 0x7d:0x7d || false)))))) && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_11_action_2
                                        else
                                            if (byte in 0x09:0x0a || (byte in 0x20:0x20 || false)) && true
                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_10_action_1
                                            else
                                                if (byte in 0x2b:0x2b || (byte in 0x2d:0x2d || false)) && true
                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_7
                                                else
                                                    if (byte in 0x46:0x46 || (byte in 0x66:0x66 || false)) && true
                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_8_action_1
                                                    else
                                                        if (byte in 0x54:0x54 || (byte in 0x74:0x74 || false)) && true
                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_9_action_1
                                                        else
                                                            if byte == 0x22 && true
                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_2
                                                            else
                                                                if byte == 0x27 && true
                                                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_3
                                                                else
                                                                    if byte == 0x2e && true
                                                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_4
                                                                    else
                                                                        if byte == 0x65 && true
                                                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_5_action_1
                                                                        else
                                                                            if byte == 0x72 && true
                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_6_action_1
                                                                            else
                                                                                cs = -1
                                                                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_13_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                    begin
                                        stop = p
                                        token = OPERATOR
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_13
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_13_action_2
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_13
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_13_action_3
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                    begin
                                        stop = p
                                        token = RECORD
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_13
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_13_action_4
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                    begin
                                        stop = p
                                        token = FALSE
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_13
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_13_action_5
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                    begin
                                        stop = p
                                        token = TRUE
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_13
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_13
                                p += 1
                                if p > p_end
                                    cs = 13
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_13
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x61:0x7a || (byte in 0x30:0x39 || (byte in 0x5f:0x5f || false)))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        cs = -13
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_14
                                p += 1
                                if p > p_end
                                    cs = 14
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_14
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x61:0x7a || (byte in 0x5f:0x5f || false))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x27 && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_3
                                    else
                                        cs = -14
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_12_action_1
                                begin
                                    begin
                                        stop = p
                                        token = INT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_12
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_12
                                p += 1
                                if p > p_end
                                    cs = 12
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_12
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_12_action_1
                                else
                                    if (byte in 0x45:0x45 || (byte in 0x65:0x65 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_16
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_15_action_1
                                        else
                                            cs = -12
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_16
                                p += 1
                                if p > p_end
                                    cs = 16
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_16
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_18_action_1
                                else
                                    if (byte in 0x2b:0x2b || (byte in 0x2d:0x2d || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_17
                                    else
                                        cs = -16
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_18_action_1
                                begin
                                    begin
                                        stop = p
                                        token = FLOAT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_18
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_18
                                p += 1
                                if p > p_end
                                    cs = 18
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_18
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_18_action_1
                                else
                                    cs = -18
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_17
                                p += 1
                                if p > p_end
                                    cs = 17
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_17
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_18_action_1
                                else
                                    cs = -17
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_15_action_1
                                begin
                                    begin
                                        stop = p
                                        token = FLOAT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_15
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_15
                                p += 1
                                if p > p_end
                                    cs = 15
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_15
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_15_action_1
                                else
                                    if (byte in 0x45:0x45 || (byte in 0x65:0x65 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_16
                                    else
                                        cs = -15
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_11_action_1
                                begin
                                    begin
                                        stop = p
                                        token = STRING
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_11
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_11_action_2
                                begin
                                    begin
                                        stop = p
                                        token = OPERATOR
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_11
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_11
                                p += 1
                                if p > p_end
                                    cs = 11
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_11
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                begin
                                    cs = -11
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_10_action_1
                                begin
                                    begin
                                        stop = p
                                        token = WS
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_10
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_10
                                p += 1
                                if p > p_end
                                    cs = 10
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_10
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x09:0x0a || (byte in 0x20:0x20 || false)) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_10_action_1
                                else
                                    cs = -10
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_9_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_9
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_9
                                p += 1
                                if p > p_end
                                    cs = 9
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_9
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x51 || (byte in 0x61:0x71 || (byte in 0x30:0x39 || (byte in 0x53:0x5a || (byte in 0x73:0x7a || (byte in 0x5f:0x5f || false)))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x52:0x52 || (byte in 0x72:0x72 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_19_action_1
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -9
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_19_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_19
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_19
                                p += 1
                                if p > p_end
                                    cs = 19
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_19
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x54 || (byte in 0x61:0x74 || (byte in 0x30:0x39 || (byte in 0x56:0x5a || (byte in 0x76:0x7a || (byte in 0x5f:0x5f || false)))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x55:0x55 || (byte in 0x75:0x75 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_20_action_1
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -19
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_20_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_20
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_20
                                p += 1
                                if p > p_end
                                    cs = 20
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_20
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x46:0x5a || (byte in 0x66:0x7a || (byte in 0x30:0x39 || (byte in 0x41:0x44 || (byte in 0x61:0x64 || (byte in 0x5f:0x5f || false)))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x45:0x45 || (byte in 0x65:0x65 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_5
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -20
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_8_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_8
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_8
                                p += 1
                                if p > p_end
                                    cs = 8
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_8
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x42:0x5a || (byte in 0x62:0x7a || (byte in 0x30:0x39 || (byte in 0x5f:0x5f || false)))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x41:0x41 || (byte in 0x61:0x61 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_21_action_1
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -8
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_21_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_21
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_21
                                p += 1
                                if p > p_end
                                    cs = 21
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_21
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x4d:0x5a || (byte in 0x6d:0x7a || (byte in 0x41:0x4b || (byte in 0x61:0x6b || (byte in 0x30:0x39 || (byte in 0x5f:0x5f || false)))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x4c:0x4c || (byte in 0x6c:0x6c || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_22_action_1
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -21
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_22_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_22
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_22
                                p += 1
                                if p > p_end
                                    cs = 22
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_22
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x52 || (byte in 0x61:0x72 || (byte in 0x30:0x39 || (byte in 0x54:0x5a || (byte in 0x74:0x7a || (byte in 0x5f:0x5f || false)))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x53:0x53 || (byte in 0x73:0x73 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_23_action_1
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -22
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_23_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_23
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_23
                                p += 1
                                if p > p_end
                                    cs = 23
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_23
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x46:0x5a || (byte in 0x66:0x7a || (byte in 0x30:0x39 || (byte in 0x41:0x44 || (byte in 0x61:0x64 || (byte in 0x5f:0x5f || false)))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if (byte in 0x45:0x45 || (byte in 0x65:0x65 || false)) && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_4
                                    else
                                        if byte == 0x2e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                        else
                                            cs = -23
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_7
                                p += 1
                                if p > p_end
                                    cs = 7
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_7
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_12_action_1
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_4
                                    else
                                        cs = -7
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_6_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_6
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_6
                                p += 1
                                if p > p_end
                                    cs = 6
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_6
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x66:0x7a || (byte in 0x30:0x39 || (byte in 0x61:0x64 || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x65 && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_24_action_1
                                        else
                                            cs = -6
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_24_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_24
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_24
                                p += 1
                                if p > p_end
                                    cs = 24
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_24
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x64:0x7a || (byte in 0x30:0x39 || (byte in 0x61:0x62 || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x63 && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_25_action_1
                                        else
                                            cs = -24
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_25_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_25
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_25
                                p += 1
                                if p > p_end
                                    cs = 25
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_25
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x61:0x6e || (byte in 0x70:0x7a || (byte in 0x30:0x39 || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x6f && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_26_action_1
                                        else
                                            cs = -25
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_26_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_26
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_26
                                p += 1
                                if p > p_end
                                    cs = 26
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_26
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x61:0x71 || (byte in 0x30:0x39 || (byte in 0x73:0x7a || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x72 && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_27_action_1
                                        else
                                            cs = -26
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_27_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_27
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_27
                                p += 1
                                if p > p_end
                                    cs = 27
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_27
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x65:0x7a || (byte in 0x30:0x39 || (byte in 0x61:0x63 || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x64 && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_3
                                        else
                                            cs = -27
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_5_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_5
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_5
                                p += 1
                                if p > p_end
                                    cs = 5
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_5
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x61:0x6d || (byte in 0x6f:0x7a || (byte in 0x30:0x39 || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x6e && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_28_action_1
                                        else
                                            cs = -5
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_28_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_28
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_28
                                p += 1
                                if p > p_end
                                    cs = 28
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_28
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x41:0x5a || (byte in 0x65:0x7a || (byte in 0x30:0x39 || (byte in 0x61:0x63 || (byte in 0x5f:0x5f || false))))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_2
                                else
                                    if byte == 0x2e && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                    else
                                        if byte == 0x64 && true
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_13_action_1
                                        else
                                            cs = -28
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                        end
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_4
                                p += 1
                                if p > p_end
                                    cs = 4
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_4
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x30:0x39 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_15_action_1
                                else
                                    cs = -4
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_3
                                p += 1
                                if p > p_end
                                    cs = 3
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_3
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if (byte in 0x5d:0xff || (byte in 0x28:0x5b || (byte in 0x00:0x26 || false))) && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_30
                                else
                                    if byte == 0x5c && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_29
                                    else
                                        cs = -3
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_30
                                p += 1
                                if p > p_end
                                    cs = 30
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_30
                                begin
                                    while p + 30 < p_end
                                        var"##278" = true
                                        for var"##279" = 0:31
                                            var"##277" = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:577 =# @inbounds(getindex(mem, p + var"##279"))
                                            var"##278" &= (var"##277" >= 0x00) & (var"##277" <= 0x26) | ((var"##277" >= 0x28) & (var"##277" <= 0x5b) | ((var"##277" >= 0x5d) & (var"##277" <= 0xff) | false))
                                        end
                                        var"##278" || break
                                        p += 32
                                    end
                                    while true
                                        if p > p_end
                                            cs = 30
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:586 =# @goto exit
                                        end
                                        byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:588 =# @inbounds(getindex(mem, p))
                                        (byte in 0x5d:0xff || (byte in 0x28:0x5b || (byte in 0x00:0x26 || false))) || break
                                        p += 1
                                    end
                                end
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte == 0x27 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_31_action_1
                                else
                                    if byte == 0x5c && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_29
                                    else
                                        cs = -30
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:448 =# @label state_31_action_1
                                begin
                                    begin
                                        stop = p
                                        token = IDENT
                                    end
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:455 =# @goto state_31
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_31
                                p += 1
                                if p > p_end
                                    cs = 31
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_31
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte == 0x2e && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_14
                                else
                                    cs = -31
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_29
                                p += 1
                                if p > p_end
                                    cs = 29
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_29
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x00:0xff && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_30
                                else
                                    cs = -29
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_2
                                p += 1
                                if p > p_end
                                    cs = 2
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_2
                                begin
                                    while p + 30 < p_end
                                        var"##281" = true
                                        for var"##282" = 0:31
                                            var"##280" = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:577 =# @inbounds(getindex(mem, p + var"##282"))
                                            var"##281" &= (var"##280" >= 0x00) & (var"##280" <= 0x21) | ((var"##280" >= 0x23) & (var"##280" <= 0x5b) | ((var"##280" >= 0x5d) & (var"##280" <= 0xff) | false))
                                        end
                                        var"##281" || break
                                        p += 32
                                    end
                                    while true
                                        if p > p_end
                                            cs = 2
                                            #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:586 =# @goto exit
                                        end
                                        byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:588 =# @inbounds(getindex(mem, p))
                                        (byte in 0x5d:0xff || (byte in 0x23:0x5b || (byte in 0x00:0x21 || false))) || break
                                        p += 1
                                    end
                                end
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte == 0x22 && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:493 =# @goto state_11_action_1
                                else
                                    if byte == 0x5c && true
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_32
                                    else
                                        cs = -2
                                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                    end
                                end
                            end
                            begin
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:462 =# @label state_32
                                p += 1
                                if p > p_end
                                    cs = 32
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:466 =# @goto exit
                                end
                                #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:500 =# @label state_case_32
                                ()
                                byte = #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:502 =# @inbounds(getindex(mem, p))
                                if byte in 0x00:0xff && true
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:491 =# @goto state_2
                                else
                                    cs = -32
                                    #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:483 =# @goto exit
                                end
                            end
                        end
                        #= /home/johti17/.julia/packages/Automa/fzRJn/src/codegen.jl:538 =# @label exit
                        if is_eof && (p > p_end && (cs > 4 && (begin
                                                (cs < 69) & isodd(0x0000000004ffe5fb >>> ((cs - 5) & 63))
                                            end || false)))
                            if cs == 5
                            else
                                if cs == 20
                                else
                                    if cs == 25
                                    else
                                        if cs == 12
                                        else
                                            if cs == 24
                                            else
                                                if cs == 28
                                                else
                                                    if cs == 8
                                                    else
                                                        if cs == 23
                                                        else
                                                            if cs == 19
                                                            else
                                                                if cs == 22
                                                                else
                                                                    if cs == 13
                                                                    else
                                                                        if cs == 6
                                                                        else
                                                                            if cs == 21
                                                                            else
                                                                                if cs == 11
                                                                                else
                                                                                    if cs == 10
                                                                                    else
                                                                                        if cs == 27
                                                                                        else
                                                                                            if cs == 31
                                                                                            else
                                                                                                if cs == 26
                                                                                                else
                                                                                                    if cs == 9
                                                                                                    else
                                                                                                        if cs == 18
                                                                                                        else
                                                                                                            if cs == 15
                                                                                                            else
                                                                                                                ()
                                                                                                            end
                                                                                                        end
                                                                                                    end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            cs = 0
                        end
                    end
            end
            cs = 1
            if token !== ERROR
                found_token = (token_start, ((stop - token_start) + 1) % Int32, token)
                if start < token_start
                    error_state = (start, (token_start - start) % Int32, ERROR)
                    return (error_state, found_token)
                else
                    return (found_token, (stop + 1, Int32(0), ERROR))
                end
            else
                if p > p_end
                    error_state = (start, (p - start) % Int32, ERROR)
                    return (error_state, (p_end + 1, Int32(0), ERROR))
                else
                    token_start += 1
                end
            end
        end
    end
end

"""
    tokenize(data::String)

Tokenize OpenModelica `Values.Value` output into the values the parser
consumes. Throws [`LexerError`](@ref) on input that is not valid output.
"""
function tokenize(data::String)
  tokens = Any[]
  for (start, len, token) in Automa.tokenize(OMToken, data)
    stop = start + len - 1
    if token == ERROR
      throw(LexerError("Error while lexing"))
    elseif token == WS
      continue
    elseif token == TRUE
      push!(tokens, true)
    elseif token == FALSE
      push!(tokens, false)
    elseif token == RECORD
      push!(tokens, Record())
    elseif token == OPERATOR
      push!(tokens, Symbol(data[start:stop]))
    elseif token == STRING
      push!(tokens, unescape_string(data[start+1:stop-1]))
    elseif token == IDENT
      push!(tokens, Identifier(unescape_string(data[start:stop])))
    elseif token == INT
      push!(tokens, parse(Int, data[start:stop]))
    elseif token == FLOAT
      push!(tokens, parse(Float64, data[start:stop]))
    end
  end
  return tokens
end
