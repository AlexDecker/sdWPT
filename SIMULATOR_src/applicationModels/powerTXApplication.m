%MODELO DE APLICA��O DO TX
classdef powerTXApplication < powerApplication
    properties
    end
    methods(Access=public)
        function obj = powerTXApplication()
           obj@powerTXApplication(0);%construindo a estrutura referente � superclasse (ID=0)
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
    end
end