%MODELO DE APLICA��O DO RX
classdef powerRXApplication
   properties
       id
	   APPLICATION_LOG %retornado pela fun��o Simulate ao t�rmino da execu��o
   end
   methods(Access=public)
       function obj = powerRXApplication(id)
           obj.id = id;
		   obj.APPLICATION_LOG = applicationLOG();
       end
       
       function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
       end
       
       function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)           
       end
       
       function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
       end
   end
   %Fun��es auxiliares
   methods(Access=protected)
       %obt�m um escalar 'I' da corrente em fasor.
       function [I,WPTManager] = getI(obj,WPTManager,GlobalTime)
           [Current,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
           I = Current(WPTManager.nt+obj.id);
       end
	   %define um timer para um per�odo 'vTime' no futuro
	   function netManager = setTimer(obj,netManager,globalTime,vTime)
			netManager = setTimer(netManager,obj.id,globalTime,vTime);
	   end
	   %envia uma mensagem 'data' ao dispositivo de id 'dest'
	   function netManager = send(obj,netManager,dest,data,globalTime)
	        netManager = send(netManager,dest,data,globalTime);
	   end
	   %envia uma mensagem 'data' a todos os dispositivos do sistema
	   function netManager = broadcast(obj,netManager,data,globalTime)
		    netManager = broadcast(netManager,obj.id,data,globalTime);
	   end
   end
end