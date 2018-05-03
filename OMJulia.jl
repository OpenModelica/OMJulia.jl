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
   getQuantities::Function
   getParameters::Function
   getSimulationOptions::Function
   getSolutions::Function
   setParameters::Function
   setSimulationOptions::Function
   simulate::Function
   simulationFlag
   simulateOptions
   overridevariables
   tempdir
   currentdir
   resultfile
   filepath
   modelname
   xmlfile
   quantitieslist
   parameterlist
   context
   socket
   function OMCSession()
      this = new()
      this.overridevariables=Dict()
      this.quantitieslist=Any[]
      this.parameterlist=Dict()
      this.simulateOptions=Dict()
      this.currentdir=pwd()
      this.filepath=""
      this.modelname=""
      this.resultfile=""
      this.simulationFlag=""
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
         this.tempdir=replace(mktempdir(pwd()),"\\","/")
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
                  #println(overridelist)
                  overridevar=join(["-override=",join(overridelist,",")])
                  #println(overridevar)
                  run(`$getexefile $overridevar`)
               else
                  run(`$getexefile`)
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
               return [plotdata.args for plotdata in data.args]
            elseif(isa(name,Array))
               resultvar=join(["{",join(name,","),"}"])
               #println(resultvar)
               simres=this.sendExpression("readSimulationResult(\""* this.resultfile * "\","* resultvar *")")
               data=parse(simres)
               plotdata=Any[]
               for item in data.args
                  push!(plotdata,item.args)
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
            value=split(name,"=")
            if(haskey(this.simulateOptions,value[1]))
               this.simulateOptions[value[1]]=value[2]
               this.overridevariables[value[1]]=value[2]
            else
               return println(value[1], "is not a SimulationOption")
            end
         elseif(isa(name,Array))
            for var in name
               value=split(var,"=")
               if(haskey(this.simulateOptions,value[1]))
                  this.simulateOptions[value[1]]=value[2]
                  this.overridevariables[value[1]]=value[2]
               else
                  return println(value[1], "is not a SimulationOption")
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
