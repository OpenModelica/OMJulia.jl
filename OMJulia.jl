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
using ZMQ
using Compat
using LightXML

type OMCSession
   sendExpression::Function
   ModelicaSystem::Function
   xmlparse::Function
   createcsvdata::Function
   getQuantities::Function
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
   context
   socket
   function OMCSession()
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
      args2="--interactive=zmq"
      args3="+z=julia."
      args4=randstring(10)
      if (Compat.Sys.iswindows())
         omhome=ENV["OPENMODELICAHOME"]
         #ompath=replace(joinpath(omhome,"bin","omc.exe"),"\\","/")
         ompath=joinpath(omhome,"bin")
         #add omc to path if not exist
         ENV["PATH"]=ENV["PATH"]*ompath
         spawn(pipeline(`omc $args2 $args3$args4`))
         portfile=join(["openmodelica.port.julia.",args4])
      else
         if (Compat.Sys.isapple())
            #add omc to path if not exist
            ENV["PATH"]=ENV["PATH"]*"/opt/openmodelica/bin"
            spawn(pipeline(`omc $args2 $args3$args4`))
         else
            spawn(pipeline(`omc $args2 $args3$args4`))
         end
         portfile=join(["openmodelica.",ENV["USER"],".port.julia.",args4])
      end
      sleep(0.5)
      fullpath=joinpath(tempdir(),portfile)
      this.context=ZMQ.Context()
      this.socket =ZMQ.Socket(this.context, REQ)
      ZMQ.connect(this.socket, readstring(fullpath))

      this.sendExpression = function (expr)
         ZMQ.send(this.socket,expr)
         message=ZMQ.recv(this.socket)
         return (unsafe_string(message))
      end

      this.ModelicaSystem = function (filename, modelname)
         this.filepath=filename
         this.modelname=modelname
         filepath=replace(abspath(filename),"\\","/")
         #println(filepath)
         if(isfile(filepath))
            loadmsg=this.sendExpression("loadFile(\""*filepath*"\")")
            if(!parse(loadmsg))
               return this.sendExpression("getErrorString()")
            end
         else
            return println(filename, "! NotFound")
         end
         #this.tempdir=replace(joinpath(pwd(),join(["zz_",randstring(5),".tmp"])),"\\","/")
         #mkdir(this.tempdir)
         this.tempdir=replace(mktempdir(pwd()),"\\","/")
         if(!isdir(this.tempdir))
            return println(this.tempdir, " cannot be created")
         end
         this.sendExpression("cd(\""*this.tempdir*"\")")
         buildmodelexpr=join(["buildModel(",modelname,")"])
         buildModelmsg=this.sendExpression(buildmodelexpr)
         parsebuilexp=parse(buildModelmsg)

         if(!isempty(parsebuilexp.args[2]))
            this.xmlfile=replace(joinpath(this.tempdir,parsebuilexp.args[2]),"\\","/")
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
                  value=this.getSolutions(name)
                  value1=value[1]
                  this.continuouslist[name]=value1[end]
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
         println(this.xmlfile)
         if(isfile(this.xmlfile))
            if (Compat.Sys.iswindows())
               getexefile=replace(joinpath(this.tempdir,join([this.modelname,".exe"])),"\\","/")
            else
               getexefile=replace(joinpath(this.tempdir,this.modelname),"\\","/")
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
                     run(`$getexefile $overridevar $csvinput`)
                  else
                     run(`$getexefile $overridevar`)
                  end
               else
                  if (this.inputFlag=="true")
                     createcsvdata(this)
                     csvinput=join(["-csvInput=",this.csvfile])
                     run(`$getexefile $csvinput`)
                  else
                     run(`$getexefile`)
                  end
               end
               this.resultfile=replace(joinpath(this.tempdir,join([this.modelname,"_res.mat"])),"\\","/")
               this.simulationFlag="True"
            else
               return println("! Simulation Failed")
            end
            ## change to currentworkingdirectory
            cd(this.currentdir)
         end
      end

      this.getSolutions = function(name=nothing)
         if(!isempty(this.resultfile))
            if(name==nothing)
               simresultvars=this.sendExpression("readSimulationResultVars(\"" * this.resultfile * "\")")
               parsesimresultvars=parse(simresultvars)
               return parsesimresultvars.args
            elseif(isa(name,String))
               resultvar=join(["{",name,"}"])
               simres=this.sendExpression("readSimulationResult(\""* this.resultfile * "\","* resultvar *")")
               data=parse(simres)
               this.sendExpression("closeSimulationResultFile()")
               return [convert(Array{Float64,1},plotdata.args) for plotdata in data.args]
            elseif(isa(name,Array))
               resultvar=join(["{",join(name,","),"}"])
               #println(resultvar)
               simres=this.sendExpression("readSimulationResult(\""* this.resultfile * "\","* resultvar *")")
               data=parse(simres)
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
               newval=parse(value[2])
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
                  newval=parse(value[2])
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
                        push!(this.quantitieslist,scalar )
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
end
