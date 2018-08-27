%Aplica��o que cria eventos apenas para a simula��o n�o acabar antes do tempo limite

classdef powerTXApplication_dummie < powerTXApplication
    properties
    	V %tens�o
    end
    methods
        function obj = powerTXApplication_dummie(V)
            obj@powerTXApplication();%construindo a estrutura referente � superclasse
            obj.V = V;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	netManager = setTimer(netManager,0,0,1000);
        	WPTManager = setSourceVoltages(obj,WPTManager,obj.V,0); 
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager)
        	netManager = setTimer(netManager,0,GlobalTime,1000);
        end
    end
end
