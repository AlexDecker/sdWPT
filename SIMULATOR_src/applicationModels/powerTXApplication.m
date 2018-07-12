%MODELO DE APLICA��O DO TX
classdef powerTXApplication
   properties
       APPLICATION_LOG %retornado pela fun��o Simulate ao t�rmino da execu��o
   end
   methods(Access=public)
       function obj = powerTXApplication()
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
       %obt�m um vetor 'I' de correntes em fasores.
	   function [It,WPTManager] = getCurrents(obj,WPTManager,GlobalTime)
           [Current,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
           It = Current(1:WPTManager.nt);
       end
	   %define as tens�es 'Vt' das fontes dos transmissores em fasores
	   function WPTManager = setSourceVoltages(obj,WPTManager,Vt,GlobalTime)
	   WPTManager = setVt(WPTManager, Vt, GlobalTime);
	   end
	   %define um timer para um per�odo 'vTime' no futuro
	   function netManager = setTimer(obj,netManager,globalTime,vTime)
			netManager = setTimer(netManager,0,globalTime,vTime);
	   end
	   %envia uma mensagem 'data' ao dispositivo de id 'dest'
	   function netManager = send(obj,netManager,dest,data,globalTime)
	        netManager = send(netManager,dest,data,globalTime);
	   end
	   %envia uma mensagem 'data' a todos os dispositivos do sistema
	   function netManager = broadcast(obj,netManager,data,globalTime)
		    netManager = broadcast(netManager,0,data,globalTime);
       end
   end
end