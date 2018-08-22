%MODELO DE APLICA��O DO RX
classdef powerRXApplication < powerApplication
    properties
    end
    methods(Access=public)
        function obj = powerRXApplication(id)
            obj@powerApplication(id);%construindo a estrutura referente � superclasse
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
        %obt�m a corrente de recarga, a corrente de descarga e a tens�o da bateria
        function [Ir,Id,Vb,WPTManager] = getBatteryParams(obj,WPTManager,GlobalTime)
            [~,~,~,WPTManager] = getSystemState(WPTManager,GlobalTime);
            
            Ir = WPTManager.deviceList(obj.id).obj.chargeCurrent;
            Id = WPTManager.deviceList(obj.id).obj.dischargeCurrent;
            Vb = WPTManager.deviceList(obj.id).obj.Vbatt;
        end
    end
end
