#=
This file is part of OpenModelica.
Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
c/o Linköpings universitet, Department of Computer and Information Science,
SE-58183 Linköping, Sweden.

All rights reserved.

THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
ACCORDING TO RECIPIENTS CHOICE.

The OpenModelica software and the OSMC (Open Source Modelica Consortium)
Public License (OSMC-PL) are obtained from OSMC, either from the above
address, from the URLs: http://www.openmodelica.org or
http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
distribution. GNU version 3 is obtained from:
http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
http://www.opensource.org/licenses/BSD-3-Clause.

This program is distributed WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
CONDITIONS OF OSMC-PL.
=#

module OMJulia
global IS_FILE_OMJULIA = false
using ZMQ
using Compat
using DataStructures
using LightXML
using DataFrames
if(VERSION >=v"1.0")
   using Random
end

export SendExpression

include("parser.jl")

mutable struct OMCSession
   sendExpression::Function
   ModelicaSystem::Function
   xmlparse::Function
   createcsvdata::Function
   getQuantities::Function
   showQuantities::Function
   getParameters::Function
   getSimulationOptions::Function
   getSolutions::Function
   getInputs::Function
   getOutputs::Function
   getContinuous::Function
   setParameters::Function
   setSimulationOptions::Function
   setInputs::Function
   simulate::Function
   linearize::Function
   getLinearizationOptions::Function
   setLinearizationOptions::Function
   getLinearInputs::Function
   getLinearOutputs::Function
   getLinearStates::Function
   sensitivity::Function
   convertMo2FMU::Function
   convertFmu2Mo::Function
   simulationFlag
   inputFlag
   simulateOptions
   overridevariables
   tempdir
   currentdir
   resultfile
   filepath
   modelname
   xmlfile
   csvfile
   quantitieslist
   parameterlist
   inputlist
   outputlist
   continuouslist
   linearOptions
   linearfile
   linearFlag
   linearmodelname
   linearinputs
   linearoutputs
   linearstates
   linearquantitylist
   context
   socket
   function OMCSession(omc = nothing)
      this = new()
      this.overridevariables=Dict()
      this.quantitieslist=Any[]
      this.parameterlist=Dict()
      this.simulateOptions=Dict()
      this.inputlist=Dict()
      this.outputlist=Dict()
      this.continuouslist=Dict()
      this.currentdir=pwd()
      this.filepath=""
      this.modelname=""
      this.resultfile=""
      this.simulationFlag=""
      this.inputFlag="false"
      this.csvfile=""
      this.tempdir=""
      this.linearfile=""
      this.linearFlag="false"
      this.linearmodelname=""
      this.linearOptions=Dict("startTime"=>"0.0", "stopTime"=>"1.0", "numberOfIntervals"=>"500", "stepSize"=>"0.002", "tolerance"=> "1e-6")
      args2="--interactive=zmq"
      args3="+z=julia."
      if(VERSION >= v"1.0")
         args4=Random.randstring(10)
      else
         args4=randstring(10)
      end
      if (Compat.Sys.iswindows())
         #@assert omc == nothing "A Custom omc path for windows is not supported"
         if(omc != nothing)
            ompath=replace(omc,r"[/\\]+" => "/")
            dirpath=dirname(dirname(omc))
            ## create a omc process with OPENMODELICAHOME set to custom directory
            @info("Setting environment variable OPENMODELICAHOME=\"$ompath\" for this session.")
            withenv("OPENMODELICAHOME"=>dirpath) do
              open(pipeline(`$omc $args2 $args3$args4`))
            end
         else
            omhome=""
            try
               omhome=ENV["OPENMODELICAHOME"]
            catch Exception
               println(Exception, "is not set, Please set the environment Variable")
               return
            end
            ompath=replace(joinpath(omhome,"bin","omc.exe"),r"[/\\]+" => "/")
            #ompath=joinpath(omhome,"bin")
            ## create a omc process with default OPENMODELICAHOME set in environment variable
            withenv("OPENMODELICAHOME"=>omhome) do
              open(pipeline(`$ompath $args2 $args3$args4`))
            end
         end
         portfile=join(["openmodelica.port.julia.",args4])
      else
         if (Compat.Sys.isapple())
            #add omc to path if not exist
            ENV["PATH"]=ENV["PATH"]*"/opt/openmodelica/bin"
            if (omc != nothing)
               open(pipeline(`$omc $args2 $args3$args4`))
            else
               open(pipeline(`omc $args2 $args3$args4`))
            end
         else
            if (omc != nothing)
               open(pipeline(`$omc $args2 $args3$args4`))
            else
               open(pipeline(`omc $args2 $args3$args4`))
            end
         end
         portfile=join(["openmodelica.",ENV["USER"],".port.julia.",args4])
      end
      #sleep(5)
      fullpath=joinpath(tempdir(),portfile)
      ## Try to find better approach if possible, as sleep does not work properly across different platform
      filedata=""
      while true
         # Necessary or Julia might optimize away checking isfile every iteration
         global IS_FILE_OMJULIA = isfile(fullpath)
         if(IS_FILE_OMJULIA)
            filedata=read(fullpath,String)
            break
         end
      end
      this.context=ZMQ.Context()
      this.socket =ZMQ.Socket(this.context, REQ)
      ZMQ.connect(this.socket, filedata)

      this.sendExpression = function (expr)
         ZMQ.send(this.socket,expr)
         message=ZMQ.recv(this.socket)
         return (unsafe_string(message))
      end

      this.ModelicaSystem = function (filename, modelname, library=nothing)
         this.filepath=filename
         this.modelname=modelname
         filepath=replace(abspath(filename),r"[/\\]+" => "/")
         if(isfile(filepath))
            loadmsg=this.sendExpression("loadFile(\""*filepath*"\")")
            if(!Base.Meta.parse(loadmsg))
               return this.sendExpression("getErrorString()")
            end
         else
            return println(filename, "! NotFound")
         end
         #this.tempdir=replace(joinpath(pwd(),join(["zz_",Random.randstring(5),".tmp"])),r"[/\\]+" => "/")
         #mkdir(this.tempdir)
         this.tempdir=replace(mktempdir(),r"[/\\]+" => "/")
         if(!isdir(this.tempdir))
            return println(this.tempdir, " cannot be created")
         end
         this.sendExpression("cd(\""*this.tempdir*"\")")
         if(library!=nothing)
            if(isa(library,String))
               if(isfile(library))
                  libfile=replace(abspath(library),r"[/\\]+" => "/")
                  libfilemsg=this.sendExpression("loadFile(\""*libfile*"\")")
                  if(!Base.Meta.parse(libfilemsg))
                     return this.sendExpression("getErrorString()")
                  end
               else
                  libname=join(["loadModel(",library,")"])
                  this.sendExpression(libname)
               end
            elseif (isa(library,Array))
               for i in library
                  if(isfile(i))
                     libfile=replace(abspath(i),r"[/\\]+" => "/")
                     libfilemsg=this.sendExpression("loadFile(\""*libfile*"\")")
                     if(!Base.Meta.parse(libfilemsg))
                        return this.sendExpression("getErrorString()")
                     end
                  else
                     libname=join(["loadModel(",i,")"])
                     this.sendExpression(libname)
                  end
               end
            end
         end
         buildmodelexpr=join(["buildModel(",modelname,")"])
         buildModelmsg=this.sendExpression(buildmodelexpr)
         parsebuilexp=Base.Meta.parse(buildModelmsg)

         if(!isempty(parsebuilexp.args[2]))
            this.xmlfile=replace(joinpath(this.tempdir,parsebuilexp.args[2]),r"[/\\]+" => "/")
            xmlparse(this)
         else
            return this.sendExpression("getErrorString()")
         end
         # ZMQ.send(this.socket,buildmodelexpr)
         # message=ZMQ.recv(this.socket)
         # this.xmlfile=joinpath(pwd(),join([modelname,"_init.xml"]))
         # xmlparse(this)
      end

      this.getQuantities = function(name=nothing)
         if(name==nothing)
            return this.quantitieslist
         elseif(isa(name,String))
            return [x for x in this.quantitieslist if x["name"] == name]
         elseif (isa(name,Array))
            return [x for y in name for x in this.quantitieslist if x["name"]==y]
            # qlist=Any[]
            # for n in name
            # for i in this.quantitieslist
            # if(i["name"]==n)
            # push!(qlist,i)
            # end
            # end
            # end
            # return qlist
         end
      end

      ## helper function to return getQuantities as table
      function df_from_dicts(arr::AbstractArray; missing_value="missing")
         cols = Set{Symbol}()
         for di in arr union!(cols, keys(di)) end
         df = DataFrame()
         for col=cols
            df[col] = [get(di, col, missing_value) for di=arr]
         end
         return df
      end

      ## function which returns getQuantities as table
      this.showQuantities = function(name=nothing)
         q = this.getQuantities(name);
         # assuming that the keys of the first dictionary is representative for them all
         sym = map(Symbol,collect(keys(q[1])))
         arr = []
         for d in q
            push!(arr,Dict(zip(sym,values(d))))
         end
         return df_from_dicts(arr)
      end


      this.getParameters = function (name=nothing)
         if(name==nothing)
            return this.parameterlist
         elseif(isa(name,String))
            return get(this.parameterlist,name,0)
         elseif (isa(name,Array))
            return [get(this.parameterlist,x,0) for x in name]
         end
      end

      this.getSimulationOptions = function (name=nothing)
         if (name==nothing)
            return this.simulateOptions
         elseif(isa(name,String))
            return get(this.simulateOptions,name,0)
         elseif(isa(name,Array))
            return [get(this.simulateOptions,x,0) for x in name]
         end
      end

      this.getContinuous = function (name=nothing)
         if(this.simulationFlag=="")
            if (name==nothing)
               return this.continuouslist
            elseif(isa(name,String))
               return get(this.continuouslist,name,0)
            elseif(isa(name,Array))
               return [get(this.continuouslist,x,0) for x in name]
            end
         end
         if(this.simulationFlag=="True")
            if (name==nothing)
               for name in keys(this.continuouslist)
                  ## failing for variables with $ sign
                  ## println(name)
                  try
                     value=this.getSolutions(name)
                     value1=value[1]
                     this.continuouslist[name]=value1[end]
                  catch Exception
                     println(Exception)
                  end
               end
               return this.continuouslist
            elseif(isa(name,String))
               if(haskey(this.continuouslist,name))
                  value=this.getSolutions(name)
                  value1=value[1]
                  this.continuouslist[name]=value1[end]
                  return get(this.continuouslist,name,0)
               else
                  return println(name, "  is not continuous")
               end
            elseif(isa(name,Array))
               continuousvaluelist=Any[]
               for x in name
                  if(haskey(this.continuouslist,x))
                     value=this.getSolutions(x)
                     value1=value[1]
                     this.continuouslist[x]=value1[end]
                     push!(continuousvaluelist,value1[end])
                  else
                     return println(x, "  is not continuous")
                  end
               end
               return continuousvaluelist
            end
         end
      end

      this.getInputs = function (name=nothing)
         if (name==nothing)
            return this.inputlist
         elseif(isa(name,String))
            return get(this.inputlist,name,0)
         elseif(isa(name,Array))
            return [get(this.inputlist,x,0) for x in name]
         end
      end

      this.getOutputs = function (name=nothing)
         if(this.simulationFlag=="")
            if (name==nothing)
               return this.outputlist
            elseif(isa(name,String))
               return get(this.outputlist,name,0)
            elseif(isa(name,Array))
               return [get(this.outputlist,x,0) for x in name]
            end
         end
         if(this.simulationFlag=="True")
            if (name==nothing)
               for name in keys(this.outputlist)
                  value=this.getSolutions(name)
                  value1=value[1]
                  this.outputlist[name]=value1[end]
               end
               return this.outputlist
            elseif(isa(name,String))
               if(haskey(this.outputlist,name))
                  value=this.getSolutions(name)
                  value1=value[1]
                  this.outputlist[name]=value1[end]
                  return get(this.outputlist,name,0)
               else
                  return println(name, "is not Output")
               end
            elseif(isa(name,Array))
               valuelist=Any[]
               for x in name
                  if(haskey(this.outputlist,x))
                     value=this.getSolutions(x)
                     value1=value[1]
                     this.outputlist[x]=value1[end]
                     push!(valuelist,value1[end])
                  else
                     return println(x, "is not Output")
                  end
               end
               return valuelist
            end
         end
      end

      this.simulate = function()
         #println(this.xmlfile)
         if(isfile(this.xmlfile))
            if (Compat.Sys.iswindows())
               getexefile=replace(joinpath(this.tempdir,join([this.modelname,".exe"])),r"[/\\]+" => "/")
            else
               getexefile=replace(joinpath(this.tempdir,this.modelname),r"[/\\]+" => "/")
            end
            if(isfile(getexefile))
               ## change to tempdir
               cd(this.tempdir)
               if(!isempty(this.overridevariables))
                  overridelist=Any[]
                  for k in keys(this.overridevariables)
                     val=join([k,"=",this.overridevariables[k]])
                     push!(overridelist,val)
                  end
                  overridevar=join(["-override=",join(overridelist,",")])
                  if (this.inputFlag=="true")
                     createcsvdata(this)
                     csvinput=join(["-csvInput=",this.csvfile])
                     run(pipeline(`$getexefile $overridevar $csvinput`,stdout="log.txt",stderr="error.txt"))
                  else
                     run(pipeline(`$getexefile $overridevar`,stdout="log.txt",stderr="error.txt"))
                  end
               else
                  if (this.inputFlag=="true")
                     createcsvdata(this)
                     csvinput=join(["-csvInput=",this.csvfile])
                     run(pipeline(`$getexefile $csvinput`,stdout="log.txt",stderr="error.txt"))
                  else
                     run(pipeline(`$getexefile`,stdout="log.txt",stderr="error.txt"))
                  end
               end
               this.resultfile=replace(joinpath(this.tempdir,join([this.modelname,"_res.mat"])),r"[/\\]+" => "/")
               this.simulationFlag="True"
            else
               return println("! Simulation Failed")
            end
            ## change to currentworkingdirectory
            cd(this.currentdir)
         end
      end

      this.convertMo2FMU=function()
         if(!isempty(this.modelname))
            fmuexpression=join(["translateModelFMU(",this.modelname,")"])
            Base.Meta.parse(this.sendExpression(fmuexpression))
         else
            println(this.sendExpression("getErrorString()"))
         end
      end

      this.convertFmu2Mo=function(fmupath)
         fmupath=replace(abspath(fmupath),r"[/\\]+" => "/")
         if(isfile(fmupath))
            result=this.sendExpression("importFMU(\"" *fmupath* "\")")
            return joinpath(this.tempdir,Base.Meta.parse(result))
         else
            println(fmupath, " ! Fmu not Found")
         end
      end

      this.sensitivity=function(Vp,Vv,Ve=[1e-2])
         """
         Method for computing numeric sensitivity of OpenModelica object

            Arguments:
            ----------
            1st arg: Vp  # Array of strings of Modelica Parameter names
            2nd arg: Vv  # Array of strings of Modelica Variable names
            3rd arg: Ve  # Array of float Excitations of parameters; defaults to scalar 1e-2

            Returns:
            --------
            1st return: VSname # Vector of Sensitivity names
            2nd return: Sarray # Array of sensitivies: vector of elements per parameter,
            each element containing time series per variable
            """
            # Production quality code should check type and form of input arguments
            #
            Ve = map(Float64,Ve) # converting eVements of excitation to floats
            nVp = length(Vp) # number of parameter names
            nVe = length(Ve) # number of excitations in parameters
            # Adjusting size of Ve to that of Vp
            if nVe < nVp
               push!(Ve,Ve[end]*ones(nVp-nVe)...) # extends Ve by adding last eVement of Ve
            elseif nVe > nVp
               Ve = Ve[1:nVp] # truncates Ve to same length as Vp
            end
            # Nominal parameters p0
            par0 = [Base.parse(Float64,pp) for pp in this.getParameters(Vp)]
            # eXcitation parameters parX
            parX = [par0[i]*(1+Ve[i]) for i in 1:nVp]
            # Combine parameter names and parameter values into vector of strings
            Vpar0 = [Vp[i]*"=$(par0[i])" for i in 1:nVp]
            VparX = [Vp[i]*"=$(parX[i])" for i in 1:nVp]
            # Simulate nominal system
            this.simulate()
            # Get nominal SOLutions of variabVes of interest (Vv), converted to 2D array
            sol0 = this.getSolutions(Vv)
            # Get vector of eXcited SOLutions (2D arrays), one for each parameter (Vp)
            solX = Vector{Array{Array{Float64,1},1}}()
            #
            for p in VparX
               # change to excited parameter
               this.setParameters(p)
               # simulate perturbed system
               this.simulate()
               # get eXcited SOLutions (Vv) as 2D array, and append to list
               push!(solX,this.getSolutions(Vv))
               # reset parameters to nominal values
               this.setParameters(Vpar0)
            end
            #
            # Compute sensitivities and add to vector, one 2D array per parameter (Vp)
            VSname = Vector{Vector{String}}()
            VSarray = Vector{Array{Array{Float64,1},1}}() # same shape as solX
            for (i,sol) in enumerate(solX)
               push!(VSarray, ((sol-sol0)/(par0[i]*Ve[i])))
               vsname = Vector{String}()
               for j in 1:nVp
                  push!(vsname, "Sensitivity."*Vp[i]*"."*Vv[j])
               end
               push!(VSname,vsname)
            end
            return VSname, VSarray
         end


         this.getSolutions = function(name=nothing)
            if(!isempty(this.resultfile))
               if(name==nothing)
                  simresultvars=this.sendExpression("readSimulationResultVars(\"" * this.resultfile * "\")")
                  parsesimresultvars=Base.Meta.parse(simresultvars)
                  return parsesimresultvars.args
               elseif(isa(name,String))
                  resultvar=join(["{",name,"}"])
                  simres=this.sendExpression("readSimulationResult(\""* this.resultfile * "\","* resultvar *")")
                  data=Base.Meta.parse(simres)
                  this.sendExpression("closeSimulationResultFile()")
                  return [convert(Array{Float64,1},plotdata.args) for plotdata in data.args]
               elseif(isa(name,Array))
                  resultvar=join(["{",join(name,","),"}"])
                  #println(resultvar)
                  simres=this.sendExpression("readSimulationResult(\""* this.resultfile * "\","* resultvar *")")
                  data=Base.Meta.parse(simres)
                  plotdata=Array{Float64,1}[]
                  for item in data.args
                     push!(plotdata,convert(Array{Float64,1},item.args))
                  end
                  this.sendExpression("closeSimulationResultFile()")
                  return plotdata
               end
            else
               return println("Model not Simulated, Simulate the model to get the results")
            end
         end

         this.setParameters = function (name)
            if(isa(name,String))
               name=strip_space(name)
               value=split(name,"=")
               #setxmlfileexpr="setInitXmlStartValue(\""* this.xmlfile * "\",\""* value[1]* "\",\""*value[2]*"\",\""*this.xmlfile*"\")"
               #println(haskey(this.parameterlist, value[1]))
               if(haskey(this.parameterlist,value[1]))
                  this.parameterlist[value[1]]=value[2]
                  this.overridevariables[value[1]]=value[2]
               else
                  return println(value[1], "is not a parameter")
               end
               #this.sendExpression(setxmlfileexpr)
            elseif(isa(name,Array))
               name=strip_space(name)
               for var in name
                  value=split(var,"=")
                  if(haskey(this.parameterlist,value[1]))
                     this.parameterlist[value[1]]=value[2]
                     this.overridevariables[value[1]]=value[2]
                  else
                     return println(value[1], "is not a parameter")
                  end
               end
            end
         end

         this.setSimulationOptions = function (name)
            if(isa(name,String))
               name=strip_space(name)
               value=split(name,"=")
               if(haskey(this.simulateOptions,value[1]))
                  this.simulateOptions[value[1]]=value[2]
                  this.overridevariables[value[1]]=value[2]
               else
                  return println(value[1], "  is not a SimulationOption")
               end
            elseif(isa(name,Array))
               name=strip_space(name)
               for var in name
                  value=split(var,"=")
                  if(haskey(this.simulateOptions,value[1]))
                     this.simulateOptions[value[1]]=value[2]
                     this.overridevariables[value[1]]=value[2]
                  else
                     return println(value[1], "  is not a SimulationOption")
                  end
               end
            end
         end

         this.setInputs = function (name)
            if(isa(name,String))
               name=strip_space(name)
               value=split(name,"=")
               if(haskey(this.inputlist,value[1]))
                  newval=Base.Meta.parse(value[2])
                  if(isa(newval, Expr))
                     this.inputlist[value[1]]=[v.args for v in newval.args]
                  else
                     this.inputlist[value[1]]=value[2]
                  end
                  this.inputFlag="true"
               else
                  return println(value[1], "  is not a Input")
               end
            elseif(isa(name,Array))
               name=strip_space(name)
               for var in name
                  value=split(var,"=")
                  if(haskey(this.inputlist,value[1]))
                     newval=Base.Meta.parse(value[2])
                     if(isa(newval, Expr))
                        this.inputlist[value[1]]=[v.args for v in newval.args]
                     else
                        this.inputlist[value[1]]=value[2]
                     end
                     #this.overridevariables[value[1]]=value[2]
                     this.inputFlag="true"
                  else
                     return println(value[1], "  is not a Input")
                  end
               end
            end
         end

         function strip_space(name)
            if (isa(name,String))
               return filter(x->!isspace(x),name)
            elseif(isa(name,Array))
               return [filter(x->!isspace(x),s) for s in name]
            end
         end

         function createcsvdata(this)
            this.csvfile=joinpath(this.tempdir,join([this.modelname,".csv"]))
            file = open(this.csvfile,"w")
            write(file,join(["time",",",join(keys(this.inputlist),","),",","end","\n"]))
            csvdata=deepcopy(this.inputlist)
            value=values(csvdata)

            time=Any[]
            for val in value
               if(isa(val,Array))
                  checkflag="true"
                  for v in val
                     push!(time,v[1])
                  end
               end
            end

            if(length(time)==0)
               push!(time,this.simulateOptions["startTime"])
               push!(time,this.simulateOptions["stopTime"])
            end

            previousvalue=Dict()
            for i in sort(time)
               if(isa(i,SubString{String}))
                  write(file,i,",")
               else
                  write(file,join(i,","),",")
               end
               listcount=1
               for val in value
                  if(isa(val,Array))
                     newval=val
                     count=1
                     found="false"
                     for v in newval
                        if(i==v[1])
                           data=eval(v[2])
                           write(file,join(data,","),",")
                           previousvalue[listcount]=data
                           deleteat!(newval,count)
                           found="true"
                           break
                        end
                        count=count+1
                     end
                     if(found=="false")
                        write(file,join(previousvalue[listcount],","),",")
                     end
                  end

                  if(isa(val,String))
                     if(val=="None")
                        val="0"
                     else
                        val=val
                     end
                     write(file,val,",")
                     previousvalue[listcount]=val
                  end

                  if(isa(val,SubString{String}))
                     if(val=="None")
                        val="0"
                     else
                        val=val
                     end
                     write(file,val,",")
                     previousvalue[listcount]=val
                  end
                  listcount=listcount+1
               end
               write(file,"0","\n")
            end
            close(file)
         end

         function writecsvdata(value,csv_file)
            for i in value
               write(csv_file,i,",")
               for j in values(this.inputlist)
                  if(j=="None")
                     write(csv_file,"0",",")
                  else
                     write(csv_file,j,",")
                  end
               end
               write(csv_file,"0","\n")
            end
            #close(csv_file)
         end

         this.linearize = function()
            this.sendExpression("setCommandLineOptions(\"+generateSymbolicLinearization\")")
            overridelist=Any[]
            for k in keys(this.overridevariables)
               val=join([k,"=",this.overridevariables[k]])
               push!(overridelist,val)
            end
            overridelinear=Any[]
            for t in keys(this.linearOptions)
               val=join([t,"=",this.linearOptions[t]])
               push!(overridelinear,val)
            end

            if (this.inputFlag=="true")
               createcsvdata(this)
               csvinput=join(["-csvInput=",this.csvfile])
            else
               csvinput="";
            end
            if (length(overridelist)>0)
               overridevar=join(["-override=",join(overridelist,",")])
            else
               overridevar="";
            end

            linearexpr=join(["linearize(",this.modelname,",",join(overridelinear,","),",","simflags=","\"",csvinput," ",overridevar,"\"",")"])
            #println(linearexpr)
            this.sendExpression(linearexpr)
            this.resultfile=replace(joinpath(this.tempdir,join([this.modelname,"_res.mat"])),r"[/\\]+" => "/")
            this.linearmodelname=join(["linear_",this.modelname])
            this.linearfile=joinpath(this.tempdir,join([this.linearmodelname,".mo"]))
            if(isfile(this.linearfile))
               loadmsg=this.sendExpression("loadFile(\""*this.linearfile*"\")")
               if(!Base.Meta.parse(loadmsg))
                  return this.sendExpression("getErrorString()")
               end
               cNames =this.sendExpression("getClassNames()")
               linearmodelname=Base.Meta.parse(cNames)
               #println(linearmodelname.args[1])
               buildmodelexpr=join(["buildModel(",linearmodelname.args[1],")"])
               buildModelmsg=this.sendExpression(buildmodelexpr)
               parsebuilexp=Base.Meta.parse(buildModelmsg)

               if(!isempty(parsebuilexp.args[2]))
                  this.linearFlag="true"
                  this.xmlfile=replace(joinpath(this.tempdir,parsebuilexp.args[2]),r"[/\\]+" => "/")
                  this.linearquantitylist=Any[]
                  this.linearinputs=Any[]
                  this.linearoutputs=Any[]
                  this.linearstates=Any[]
                  xmlparse(this)
                  linearMatrix = getLinearMatrix(this)
                  return linearMatrix
               else
                  return this.sendExpression("getErrorString()")
               end
            else
               errormsg=this.sendExpression("getErrorString()")
               println(errormsg)
            end
         end

         function getLinearMatrix(this)
            matrix_A=OrderedDict()
            matrix_B=OrderedDict()
            matrix_C=OrderedDict()
            matrix_D=OrderedDict()
            for i in this.linearquantitylist
               name=i["name"]
               value=i["value"]
               if(i["variability"]=="parameter")
                  if(name[1]=='A')
                     matrix_A[name]=value
                  end
                  if(name[1]=='B')
                     matrix_B[name]=value
                  end
                  if(name[1]=='C')
                     matrix_C[name]=value
                  end
                  if(name[1]=='D')
                     matrix_D[name]=value
                  end
               end
            end
            FullLinearMatrix=Array{Float64,2}[]
            tmpMatrix_A=getLinearMatrixValues(matrix_A)
            tmpMatrix_B=getLinearMatrixValues(matrix_B)
            tmpMatrix_C=getLinearMatrixValues(matrix_C)
            tmpMatrix_D=getLinearMatrixValues(matrix_D)
            push!(FullLinearMatrix,tmpMatrix_A)
            push!(FullLinearMatrix,tmpMatrix_B)
            push!(FullLinearMatrix,tmpMatrix_C)
            push!(FullLinearMatrix,tmpMatrix_D)
            return FullLinearMatrix
         end

         function getLinearMatrixValues(matrix_name)
            if (!isempty(matrix_name))
               v=[i for i in keys(matrix_name)]
               dim=Base.Meta.parse(v[end])
               rowcount=dim.args[2]
               colcount=dim.args[3]
               tmpMatrix=Matrix(undef,rowcount,colcount)
               for j in keys(matrix_name)
                  val=Base.Meta.parse(j);
                  row=val.args[2];
                  col=val.args[3];
                  tmpMatrix[row,col]=Base.parse(Float64,matrix_name[j])
               end
               return tmpMatrix
            else
               return Matrix(undef,0,0)
            end
         end

         this.getLinearizationOptions = function()
            return this.linearOptions
         end

         this.getLinearInputs = function()
            if(this.linearFlag=="true")
               return this.linearinputs
            else
               println("Model is not Linearized")
            end
         end

         this.getLinearOutputs = function()
            if(this.linearFlag=="true")
               return this.linearoutputs
            else
               println("Model is not Linearized")
            end
         end

         this.getLinearStates = function()
            if(this.linearFlag=="true")
               return this.linearstates
            else
               println("Model is not Linearized")
            end
         end

         this.setLinearizationOptions = function (name)
            if(isa(name,String))
               name=strip_space(name)
               value=split(name,"=")
               if(haskey(this.linearOptions,value[1]))
                  this.linearOptions[value[1]]=value[2]
               else
                  return println(value[1], "  is not a LinearizationOption")
               end
            elseif(isa(name,Array))
               name=strip_space(name)
               for var in name
                  value=split(var,"=")
                  if(haskey(this.linearOptions,value[1]))
                     this.linearOptions[value[1]]=value[2]
                  else
                     return println(value[1], "  is not a LinearizationOption")
                  end
               end
            end
         end

         function xmlparse(this)
            if(isfile(this.xmlfile))
               xdoc = parse_file(this.xmlfile)
               # get the root element
               xroot = root(xdoc)  # an instance of XMLElement
               for c in child_nodes(xroot)  # c is an instance of XMLNode
                  if is_elementnode(c)
                     e = XMLElement(c)  # this makes an XMLElement instance
                     if(name(e)=="DefaultExperiment")
                        this.simulateOptions["startTime"]=attribute(e, "startTime")
                        this.simulateOptions["stopTime"]=attribute(e, "stopTime")
                        this.simulateOptions["stepSize"]=attribute(e, "stepSize")
                        this.simulateOptions["tolerance"]=attribute(e, "tolerance")
                        this.simulateOptions["solver"]=attribute(e, "solver")
                     end
                     if(name(e)=="ModelVariables")
                        for r in child_elements(e)
                           scalar = Dict()
                           scalar["name"] = attribute(r, "name")
                           scalar["changeable"] = attribute(r,"isValueChangeable")
                           scalar["description"] = attribute(r,"description")
                           scalar["variability"] = attribute(r, "variability")
                           scalar["causality"] = attribute(r,"causality")
                           scalar["alias"] = attribute(r,"alias")
                           scalar["aliasvariable"] = attribute(r,"aliasVariable")
                           subchild=child_elements(r)
                           for s in subchild
                              value = attribute(s, "start")
                              if(value!=nothing)
                                 scalar["value"]=value
                              else
                                 scalar["value"]="None"
                              end
                           end
                           if(scalar["variability"]=="parameter")
                              this.parameterlist[scalar["name"]]=scalar["value"]
                           end
                           if(scalar["variability"]=="continuous")
                              this.continuouslist[scalar["name"]]=scalar["value"]
                           end
                           if(scalar["causality"]=="input")
                              this.inputlist[scalar["name"]]=scalar["value"]
                           end
                           if(scalar["causality"]=="output")
                              this.outputlist[scalar["name"]]=scalar["value"]
                           end

                           if(this.linearFlag=="true")
                              if(scalar["alias"]=="alias")
                                 name=scalar["name"]
                                 if (name[2] == 'x')
                                    #println(name[3:end-1])
                                    push!(this.linearstates,name[4:end-1])
                                 end
                                 if (name[2] == 'u')
                                    push!(this.linearinputs,name[4:end-1])
                                 end
                                 if (name[2] == 'y')
                                    push!(this.linearoutputs,name[4:end-1])
                                 end
                              end
                           end

                           if(this.linearFlag=="true")
                              push!(this.linearquantitylist,scalar)
                           else
                              push!(this.quantitieslist,scalar)
                           end
                        end
                     end
                  end
               end
               #return quantities
            else
               println("file not generated")
               return
            end
         end
         return this
      end
   end

function sendExpression(omc, expr)
   ZMQ.send(omc.socket, expr)
   message=ZMQ.recv(omc.socket)
   return Parser.parseOM(unsafe_string(message))
end

end
