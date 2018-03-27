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

type OMCSession
    sendExpression::Function
	context
	socket
    function OMCSession()
	    this = new() 
		args2="--interactive=zmq"
		args3="+z=julia."
		args4=randstring(10)
		if (Compat.Sys.iswindows())
		   omhome=ENV["OPENMODELICAHOME"]
		   ompath=replace(joinpath(omhome,"bin","omc.exe"),"\\","/")
		   spawn(pipeline(`$ompath $args2 $args3$args4`))
		   sleep(0.2)
		else
		   spawn(pipeline(`omc $args2 $args3$args4`))
		   sleep(0.2)
		end		
		path=join(["openmodelica.port.julia.",args4])
		fullpath=joinpath(tempdir(),path)
		this.context=ZMQ.Context()
        this.socket =ZMQ.Socket(this.context, REQ)
        ZMQ.connect(this.socket, readstring(fullpath))
		
		this.sendExpression = function (expr)
			ZMQ.send(this.socket,expr)
            message=ZMQ.recv(this.socket)
            return (unsafe_string(message))
        end
		
        return this
    end 
  end 	
end 