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

export sendExpression,ModelicaSystem,
       ## getMethods
       getParameters,getQuantities,showQuantities,getInputs,getOutputs,getSimulationOptions,getSolutions,getContinuous,getWorkDirectory,
       ## setMethods
       setInputs,setParameters,setSimulationOptions,
       ## simulation
       simulate,
       ## Linearizion
       linearize,getLinearInputs,getLinearOutputs,getLinearStates,getLinearizationOptions,setLinearizationOptions,
       ## sensitivity analysis
       sensitivity

include("parser.jl")

"""
Module constructor which constructs the OMCSession according
to different platform
"""
mutable struct OMCSession
   simulationFlag
   inputFlag
   simulateOptions
   overridevariables
   simoptoverride
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
   omcprocess
   function OMCSession(omc = nothing)
      this = new()
      this.overridevariables=Dict()
      this.simoptoverride=Dict()
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
      this.simulationFlag=false
      this.inputFlag=false
      this.csvfile=""
      this.tempdir=""
      this.linearfile=""
      this.linearFlag=false
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
               this.omcprocess = open(pipeline(`$omc $args2 $args3$args4`))
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
               this.omcprocess = open(pipeline(`$ompath $args2 $args3$args4`))
            end
         end
         portfile=join(["openmodelica.port.julia.",args4])
      else
         if (Compat.Sys.isapple())
            #add omc to path if not exist
            ENV["PATH"]=ENV["PATH"]*"/opt/openmodelica/bin"
            if (omc != nothing)
               this.omcprocess = open(pipeline(`$omc $args2 $args3$args4`))
            else
               this.omcprocess = open(pipeline(`omc $args2 $args3$args4`))
            end
         else
            if (omc != nothing)
               this.omcprocess = open(pipeline(`$omc $args2 $args3$args4`))
            else
               this.omcprocess = open(pipeline(`omc $args2 $args3$args4`))
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
      return this
   end
end

function sendExpression(omc, expr; parsed=true)
   if(process_running(omc.omcprocess))
      ZMQ.send(omc.socket, expr)
      message=ZMQ.recv(omc.socket)
      if parsed
         return Parser.parseOM(unsafe_string(message))
      else
         return unsafe_string(message)
      end
   else
      return "Process Exited, No connection with OMC. Create a new instance of OMCSession"
   end
end

"""
Main function Which constructs the datas and parameters needed for simulation
linearization of a model, The function accepts four aguments. The fourth argument
is library is optional, An example usage is given below
ModelicaSystem(obj,"BouncingBall.mo","BouncingBall",["Modelica", "SystemDynamics"])
"""
function ModelicaSystem(omc,filename, modelname, library=nothing)
   omc.filepath=filename
   omc.modelname=modelname
   filepath=replace(abspath(filename),r"[/\\]+" => "/")
   if(isfile(filepath))
      loadmsg=sendExpression(omc,"loadFile(\""*filepath*"\")")
      if(!loadmsg)
         return sendExpression(omc,"getErrorString()")
      end
   else
      return println(filename, "! NotFound")
   end
   omc.tempdir=replace(joinpath(pwd(),join(["zz_",Random.randstring(5),".tmp"])),r"[/\\]+" => "/")
   mkdir(omc.tempdir)
   omc.tempdir=replace(mktempdir(),r"[/\\]+" => "/")
   if(!isdir(omc.tempdir))
      return println(omc.tempdir, " cannot be created")
   end
   sendExpression(omc,"cd(\""*omc.tempdir*"\")")
   if(library!=nothing)
      if(isa(library,String))
         if(isfile(library))
            libfile=replace(abspath(library),r"[/\\]+" => "/")
            libfilemsg=sendExpression(omc,"loadFile(\""*libfile*"\")")
            if(!libfilemsg)
               return sendExpression(omc,"getErrorString()")
            end
         else
            libname=join(["loadModel(",library,")"])
            sendExpression(omc,libname)
         end
      elseif (isa(library,Array))
         for i in library
            if(isfile(i))
               libfile=replace(abspath(i),r"[/\\]+" => "/")
               libfilemsg=sendExpression(omc,"loadFile(\""*libfile*"\")")
               if(!libfilemsg)
                  return sendExpression(omc,"getErrorString()")
               end
            else
               libname=join(["loadModel(",i,")"])
               sendExpression(omc,libname)
            end
         end
      end
   end
   buildModel(omc)
end

"""
Standard buildModel API which builds the modelica model
"""
function buildModel(omc)
   buildmodelexpr=join(["buildModel(",omc.modelname,")"])
   buildModelmsg=sendExpression(omc,buildmodelexpr)
   #parsebuilexp=Base.Meta.parse(buildModelmsg)
   if(!isempty(buildModelmsg[2]))
      omc.xmlfile=replace(joinpath(omc.tempdir,buildModelmsg[2]),r"[/\\]+" => "/")
      xmlparse(omc)
   else
      return sendExpression(omc,"getErrorString()")
   end
end

"""
This function parses the XML file generated from the buildModel()
and stores the model variable into different categories namely parameter
inputs, outputs, continuous etc..
"""
function xmlparse(omc)
   if(isfile(omc.xmlfile))
      xdoc = parse_file(omc.xmlfile)
      # get the root element
      xroot = root(xdoc)  # an instance of XMLElement
      for c in child_nodes(xroot)  # c is an instance of XMLNode
         if is_elementnode(c)
            e = XMLElement(c)  # this makes an XMLElement instance
            if(name(e)=="DefaultExperiment")
               omc.simulateOptions["startTime"]=attribute(e, "startTime")
               omc.simulateOptions["stopTime"]=attribute(e, "stopTime")
               omc.simulateOptions["stepSize"]=attribute(e, "stepSize")
               omc.simulateOptions["tolerance"]=attribute(e, "tolerance")
               omc.simulateOptions["solver"]=attribute(e, "solver")
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
                  if(omc.linearFlag==false)
                     if(scalar["variability"]=="parameter")
                        omc.parameterlist[scalar["name"]]=scalar["value"]
                     end
                     if(scalar["variability"]=="continuous")
                        omc.continuouslist[scalar["name"]]=scalar["value"]
                     end
                     if(scalar["causality"]=="input")
                        omc.inputlist[scalar["name"]]=scalar["value"]
                     end
                     if(scalar["causality"]=="output")
                        omc.outputlist[scalar["name"]]=scalar["value"]
                     end
                  end
                  if(omc.linearFlag==true)
                     if(scalar["alias"]=="alias")
                        name=scalar["name"]
                        if (name[2] == 'x')
                           #println(name[3:end-1])
                           push!(omc.linearstates,name[4:end-1])
                        end
                        if (name[2] == 'u')
                           push!(omc.linearinputs,name[4:end-1])
                        end
                        if (name[2] == 'y')
                           push!(omc.linearoutputs,name[4:end-1])
                        end
                     end
                  end

                  if(omc.linearFlag==true)
                     push!(omc.linearquantitylist,scalar)
                  else
                     push!(omc.quantitieslist,scalar)
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

"""
standard getXXX() API
function which return list of all variables parsed from xml file
"""
function getQuantities(omc,name=nothing)
   if(name==nothing)
      return omc.quantitieslist
   elseif(isa(name,String))
      return [x for x in omc.quantitieslist if x["name"] == name]
   elseif (isa(name,Array))
      return [x for y in name for x in omc.quantitieslist if x["name"]==y]
   end
end

"""
standard getXXX() API
function same as getQuantities(), but returns all the variables as table
"""
function showQuantities(omc,name=nothing)
   q = getQuantities(omc,name);
   # assuming that the keys of the first dictionary is representative for them all
   sym = map(Symbol,collect(keys(q[1])))
   arr = []
   for d in q
      push!(arr,Dict(zip(sym,values(d))))
   end
   return df_from_dicts(arr)
end


## helper function to return getQuantities as table
function df_from_dicts(arr::AbstractArray; missing_value="missing")
   cols = Set{Symbol}()
   for di in arr union!(cols, keys(di)) end
   df = DataFrame()
   for col=cols
      #df[col] = [get(di, col, missing_value) for di=arr]
      df[!,col] = [get(di, col, missing_value) for di=arr]
   end
   return df
end

"""
standard getXXX() API
function which returns the parameter variables parsed from xmlfile
"""
function getParameters(omc,name=nothing)
   if(name==nothing)
      return omc.parameterlist
   elseif(isa(name,String))
      return get(omc.parameterlist,name,0)
   elseif (isa(name,Array))
      return [get(omc.parameterlist,x,0) for x in name]
   end
end

"""
standard getXXX() API
function which returns the SimulationOption variables parsed from xmlfile
"""
function getSimulationOptions(omc,name=nothing)
   if (name==nothing)
      return omc.simulateOptions
   elseif(isa(name,String))
      return get(omc.simulateOptions,name,0)
   elseif(isa(name,Array))
      return [get(omc.simulateOptions,x,0) for x in name]
   end
end

"""
standard getXXX() API
function which returns the continuous variables parsed from xmlfile
"""
function getContinuous(omc,name=nothing)
   if(omc.simulationFlag==false)
      if (name==nothing)
         return omc.continuouslist
      elseif(isa(name,String))
         return get(omc.continuouslist,name,0)
      elseif(isa(name,Array))
         return [get(omc.continuouslist,x,0) for x in name]
      end
   end
   if(omc.simulationFlag==true)
      if (name==nothing)
         for name in keys(omc.continuouslist)
            ## failing for variables with $ sign
            ## println(name)
            try
               value=getSolutions(omc,name)
               value1=value[1]
               omc.continuouslist[name]=value1[end]
            catch Exception
               println(Exception)
            end
         end
         return omc.continuouslist
      elseif(isa(name,String))
         if(haskey(omc.continuouslist,name))
            value=getSolutions(omc,name)
            value1=value[1]
            omc.continuouslist[name]=value1[end]
            return get(omc.continuouslist,name,0)
         else
            return println(name, "  is not continuous")
         end
      elseif(isa(name,Array))
         continuousvaluelist=Any[]
         for x in name
            if(haskey(omc.continuouslist,x))
               value=getSolutions(omc,x)
               value1=value[1]
               omc.continuouslist[x]=value1[end]
               push!(continuousvaluelist,value1[end])
            else
               return println(x, "  is not continuous")
            end
         end
         return continuousvaluelist
      end
   end
end

"""
standard getXXX() API
function which returns the input variables parsed from xmlfile
"""
function getInputs(omc,name=nothing)
   if (name==nothing)
      return omc.inputlist
   elseif(isa(name,String))
      return get(omc.inputlist,name,0)
   elseif(isa(name,Array))
      return [get(omc.inputlist,x,0) for x in name]
   end
end

"""
standard getXXX() API
function which returns the output variables parsed from xmlfile
"""
function getOutputs(omc,name=nothing)
   if(omc.simulationFlag==false)
      if (name==nothing)
         return omc.outputlist
      elseif(isa(name,String))
         return get(omc.outputlist,name,0)
      elseif(isa(name,Array))
         return [get(omc.outputlist,x,0) for x in name]
      end
   end
   if(omc.simulationFlag==true)
      if (name==nothing)
         for name in keys(omc.outputlist)
            value=getSolutions(omc,name)
            value1=value[1]
            omc.outputlist[name]=value1[end]
         end
         return omc.outputlist
      elseif(isa(name,String))
         if(haskey(omc.outputlist,name))
            value=getSolutions(omc,name)
            value1=value[1]
            omc.outputlist[name]=value1[end]
            return get(omc.outputlist,name,0)
         else
            return println(name, "is not Output")
         end
      elseif(isa(name,Array))
         valuelist=Any[]
         for x in name
            if(haskey(omc.outputlist,x))
               value=getSolutions(omc,x)
               value1=value[1]
               omc.outputlist[x]=value1[end]
               push!(valuelist,value1[end])
            else
               return println(x, "is not Output")
            end
         end
         return valuelist
      end
   end
end

"""
function which simulates the modelica model based on the
different settings made by users. Accepts two arguments
second argument resultfile is optional, An example usage
>> simulate(omc) // default resultfilename is used
>> simulate(omc,resultfile="tmpresult.mat") // user provided result file shall be used
"""
function simulate(omc; resultfile=nothing)
   #println(this.xmlfile)
   if(resultfile == nothing)
      r=""
      omc.resultfile=replace(joinpath(omc.tempdir,join([omc.modelname,"_res.mat"])),r"[/\\]+" => "/")
   else
      r=join(["-r=",resultfile])
      omc.resultfile=replace(joinpath(omc.tempdir,resultfile),r"[/\\]+" => "/")
   end

   if(isfile(omc.xmlfile))
      if (Compat.Sys.iswindows())
         getexefile=replace(joinpath(omc.tempdir,join([omc.modelname,".exe"])),r"[/\\]+" => "/")
      else
         getexefile=replace(joinpath(omc.tempdir,omc.modelname),r"[/\\]+" => "/")
      end
      if(isfile(getexefile))
         ## change to tempdir
         cd(omc.tempdir)
         if(!isempty(omc.overridevariables) | !isempty(omc.simoptoverride))
            overridelist=Any[]
            tmpdict=merge(omc.overridevariables,omc.simoptoverride)
            for k in keys(tmpdict)
               val=join([k,"=",tmpdict[k]])
               push!(overridelist,val)
            end
            overridevar=join(["-override=",join(overridelist,",")])
         else
            overridevar=""
         end
         if (omc.inputFlag==true)
            createcsvdata(omc)
            csvinput=join(["-csvInput=",omc.csvfile])
            #run(pipeline(`$getexefile $overridevar $csvinput`,stdout="log.txt",stderr="error.txt"))
         else
            csvinput=""
            #run(pipeline(`$getexefile $overridevar`,stdout="log.txt",stderr="error.txt"))
         end
         #remove empty args in cmd objects
         cmd=filter!(e->e≠"",[getexefile,overridevar,csvinput,r])
         #println(cmd)
         run(pipeline(`$cmd`,stdout="log.txt",stderr="error.txt"))
         #omc.resultfile=replace(joinpath(omc.tempdir,join([omc.modelname,"_res.mat"])),r"[/\\]+" => "/")
         omc.simulationFlag=true
      else
         return println("! Simulation Failed")
      end
      ## change to currentworkingdirectory
      cd(omc.currentdir)
   end
end

"""
function which converts modelicamodel to FMU
"""
function convertMo2FMU(omc)
   if(!isempty(omc.modelname))
      fmuexpression=join(["translateModelFMU(",omc.modelname,")"])
      sendExpression(omc,fmuexpression)
   else
      println(sendExpression(omc,"getErrorString()"))
   end
end

"""
function which converts FMU to modelicamodel
"""
function convertFmu2Mo(omc,fmupath)
   fmupath=replace(abspath(fmupath),r"[/\\]+" => "/")
   if(isfile(fmupath))
      result=sendExpression(omc,"importFMU(\"" *fmupath* "\")")
      return joinpath(omc.tempdir,result)
   else
      println(fmupath, " ! Fmu not Found")
   end
end

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
function sensitivity(omc,Vp,Vv,Ve=[1e-2])
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
      par0 = [Base.parse(Float64,pp) for pp in getParameters(omc,Vp)]
      # eXcitation parameters parX
      parX = [par0[i]*(1+Ve[i]) for i in 1:nVp]
      # Combine parameter names and parameter values into vector of strings
      Vpar0 = [Vp[i]*"=$(par0[i])" for i in 1:nVp]
      VparX = [Vp[i]*"=$(parX[i])" for i in 1:nVp]
      # Simulate nominal system
      simulate(omc)
      # Get nominal SOLutions of variabVes of interest (Vv), converted to 2D array
      sol0 = getSolutions(omc,Vv)
      # Get vector of eXcited SOLutions (2D arrays), one for each parameter (Vp)
      solX = Vector{Array{Array{Float64,1},1}}()
      #
      for p in VparX
         # change to excited parameter
         setParameters(omc,p)
         # simulate perturbed system
         simulate(omc)
         # get eXcited SOLutions (Vv) as 2D array, and append to list
         push!(solX,getSolutions(omc,Vv))
         # reset parameters to nominal values
         setParameters(omc,Vpar0)
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

"""
standard getXXX() API
Function which reads the result file and return the simulation results to user
which can be used for plotting or further anlaysis
"""
function getSolutions(omc, name=nothing; resultfile=nothing)
   if(resultfile == nothing)
      resfile=omc.resultfile
   else
      resfile=resultfile
   end
   if(!isfile(resfile))
      println("ResultFile does not exist !", abspath(resfile))
      return
   end
   if(!isempty(resfile))
      if(name==nothing)
         simresultvars=sendExpression(omc,"readSimulationResultVars(\"" * resfile * "\")")
         sendExpression(omc,"closeSimulationResultFile()")
         return simresultvars
      elseif(isa(name,String))
         resultvar=join(["{",name,"}"])
         simres=sendExpression(omc,"readSimulationResult(\""* resfile * "\","* resultvar *")")
         sendExpression(omc,"closeSimulationResultFile()")
         return simres
      elseif(isa(name,Array))
         resultvar=join(["{",join(name,","),"}"])
         #println(resultvar)
         simres=sendExpression(omc,"readSimulationResult(\""* resfile * "\","* resultvar *")")
         sendExpression(omc,"closeSimulationResultFile()")
         return simres
      end
   else
      return println("Model not Simulated, Simulate the model to get the results")
   end
end

"""
standard setXXX() API
function which sets new Parameter values for parameter variables defined by users
"""
function setParameters(omc,name)
   if(isa(name,String))
      name=strip_space(name)
      value=split(name,"=")
      #setxmlfileexpr="setInitXmlStartValue(\""* this.xmlfile * "\",\""* value[1]* "\",\""*value[2]*"\",\""*this.xmlfile*"\")"
      #println(haskey(this.parameterlist, value[1]))
      if(haskey(omc.parameterlist,value[1]))
         omc.parameterlist[value[1]]=value[2]
         omc.overridevariables[value[1]]=value[2]
      else
         return println(value[1], "is not a parameter")
      end
      #omc.sendExpression(setxmlfileexpr)
   elseif(isa(name,Array))
      name=strip_space(name)
      for var in name
         value=split(var,"=")
         if(haskey(omc.parameterlist,value[1]))
            omc.parameterlist[value[1]]=value[2]
            omc.overridevariables[value[1]]=value[2]
         else
            return println(value[1], "is not a parameter")
         end
      end
   end
end

"""
standard setXXX() API
function which sets new Simulation Options values defined by users
"""
function setSimulationOptions(omc,name)
   if(isa(name,String))
      name=strip_space(name)
      value=split(name,"=")
      if(haskey(omc.simulateOptions,value[1]))
         omc.simulateOptions[value[1]]=value[2]
         omc.simoptoverride[value[1]]=value[2]
      else
         return println(value[1], "  is not a SimulationOption")
      end
   elseif(isa(name,Array))
      name=strip_space(name)
      for var in name
         value=split(var,"=")
         if(haskey(omc.simulateOptions,value[1]))
            omc.simulateOptions[value[1]]=value[2]
            omc.simoptoverride[value[1]]=value[2]
         else
            return println(value[1], "  is not a SimulationOption")
         end
      end
   end
end

"""
standard setXXX() API
function which sets new input values for input variables defined by users
"""
function setInputs(omc,name)
   if(isa(name,String))
      name=strip_space(name)
      value=split(name,"=")
      if(haskey(omc.inputlist,value[1]))
         newval=Base.Meta.parse(value[2])
         if(isa(newval, Expr))
            omc.inputlist[value[1]]=[v.args for v in newval.args]
         else
            omc.inputlist[value[1]]=value[2]
         end
         omc.inputFlag=true
      else
         return println(value[1], "  is not a Input")
      end
   elseif(isa(name,Array))
      name=strip_space(name)
      for var in name
         value=split(var,"=")
         if(haskey(omc.inputlist,value[1]))
            newval=Base.Meta.parse(value[2])
            if(isa(newval, Expr))
               omc.inputlist[value[1]]=[v.args for v in newval.args]
            else
               omc.inputlist[value[1]]=value[2]
            end
            #omc.overridevariables[value[1]]=value[2]
            omc.inputFlag=true
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

"""
Function which returns the working directory of current OMJulia Session
for each session a temporary directory is created and the simulation results
are generated
"""
function getWorkDirectory(omc)
   return omc.tempdir
end

"""
function which creates the csvinput when user specify new values
for input variables, this function is used in context with setInputs()
"""
function createcsvdata(omc)
   omc.csvfile=joinpath(omc.tempdir,join([omc.modelname,".csv"]))
   file = open(omc.csvfile,"w")
   write(file,join(["time",",",join(keys(omc.inputlist),","),",","end","\n"]))
   csvdata=deepcopy(omc.inputlist)
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
      push!(time,omc.simulateOptions["startTime"])
      push!(time,omc.simulateOptions["stopTime"])
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

"""
function which returns the linearize model of modelica model,
The function returns four matrices A,B,C,D
"""
function linearize(omc)
   sendExpression(omc,"setCommandLineOptions(\"+generateSymbolicLinearization\")")
   overridelist=Any[]
   for k in keys(omc.overridevariables)
      val=join([k,"=",omc.overridevariables[k]])
      push!(overridelist,val)
   end
   overridelinear=Any[]
   for t in keys(omc.linearOptions)
      val=join([t,"=",omc.linearOptions[t]])
      push!(overridelinear,val)
   end

   if (omc.inputFlag==true)
      createcsvdata(omc)
      csvinput=join(["-csvInput=",omc.csvfile])
   else
      csvinput="";
   end
   if (length(overridelist)>0)
      overridevar=join(["-override=",join(overridelist,",")])
   else
      overridevar="";
   end

   linearexpr=join(["linearize(",omc.modelname,",",join(overridelinear,","),",","simflags=","\"",csvinput," ",overridevar,"\"",")"])
   #println(linearexpr)
   sendExpression(omc,linearexpr)
   omc.resultfile=replace(joinpath(omc.tempdir,join([omc.modelname,"_res.mat"])),r"[/\\]+" => "/")
   omc.linearmodelname=join(["linear_",omc.modelname])
   omc.linearfile=joinpath(omc.tempdir,join([omc.linearmodelname,".mo"]))
   if(isfile(omc.linearfile))
      loadmsg=sendExpression(omc,"loadFile(\""*omc.linearfile*"\")")
      if(!loadmsg)
         return sendExpression(omc,"getErrorString()")
      end
      cNames =sendExpression(omc,"getClassNames()")
      buildmodelexpr=join(["buildModel(",cNames[1],")"])
      #println(buildmodelexpr)
      buildModelmsg=sendExpression(omc,buildmodelexpr)
      #parsebuilexp=Base.Meta.parse(buildModelmsg)

      if(!isempty(buildModelmsg[2]))
         omc.linearFlag=true
         omc.xmlfile=replace(joinpath(omc.tempdir,buildModelmsg[2]),r"[/\\]+" => "/")
         omc.linearquantitylist=Any[]
         omc.linearinputs=Any[]
         omc.linearoutputs=Any[]
         omc.linearstates=Any[]
         xmlparse(omc)
         linearMatrix = getLinearMatrix(omc)
         return linearMatrix
      else
         return sendExpression(omc,"getErrorString()")
      end
   else
      errormsg=sendExpression(omc,"getErrorString()")
      println(errormsg)
   end
end

"""
Helper function which constructs the Matices A,B,C,D for linearization
"""
function getLinearMatrix(omc)
   matrix_A=OrderedDict()
   matrix_B=OrderedDict()
   matrix_C=OrderedDict()
   matrix_D=OrderedDict()
   for i in omc.linearquantitylist
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

"""
Helper function which constructs the Matices A,B,C,D for linearization
"""
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

"""
standard getXXX() API
function which returns the LinearizationOptions
"""
function getLinearizationOptions(omc,name=nothing)
   if (name==nothing)
      return omc.linearOptions
   elseif(isa(name,String))
      return get(omc.linearOptions,name,0)
   elseif(isa(name,Array))
      return [get(omc.linearOptions,x,0) for x in name]
   end
end

"""
standard getXXX() API
function which returns the LinearInput variables after the model is linearized
"""
function getLinearInputs(omc)
   if(omc.linearFlag==true)
      return omc.linearinputs
   else
      println("Model is not Linearized")
   end
end

"""
standard getXXX() API
function which returns the LinearOutput variables after the model is linearized
"""
function getLinearOutputs(omc)
   if(omc.linearFlag==true)
      return omc.linearoutputs
   else
      println("Model is not Linearized")
   end
end

"""
standard getXXX() API
function which returns the LinearStates variables after the model is linearized
"""
function getLinearStates(omc)
   if(omc.linearFlag==true)
      return omc.linearstates
   else
      println("Model is not Linearized")
   end
end

"""
standard setXXX() API
function which sets the LinearizationOption values defined by users
"""
function setLinearizationOptions(omc,name)
   if(isa(name,String))
      name=strip_space(name)
      value=split(name,"=")
      if(haskey(omc.linearOptions,value[1]))
         omc.linearOptions[value[1]]=value[2]
      else
         return println(value[1], "  is not a LinearizationOption")
      end
   elseif(isa(name,Array))
      name=strip_space(name)
      for var in name
         value=split(var,"=")
         if(haskey(omc.linearOptions,value[1]))
            omc.linearOptions[value[1]]=value[2]
         else
            return println(value[1], "  is not a LinearizationOption")
         end
      end
   end
end

end
