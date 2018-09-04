%Aplica��o de acordo com o protocolo Qi v1.0

classdef powerTXApplication_Qi < powerTXApplication
    properties
    end
    methods
        function obj = powerTXApplication_Qi(timeSkip,ifactor,iVel,vtBaseVector)
            obj@powerTXApplication();%construindo a estrutura referente � superclasse
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	netManager = setTimer(obj,netManager,0,1000);
        	WPTManager = setSourceVoltages(obj,WPTManager,5,0); 
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)          
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager) 
        	netManager = setTimer(obj,netManager,GlobalTime,1000);
        end
    end
end
