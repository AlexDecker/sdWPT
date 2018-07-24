%Evento gen�rico para o network manager
classdef genericEvent
    properties
        id
        isMsg%true para mensagem
        time0%tempo em que o evento � iniciado
        time1%tempo em que o evento � finalizado
        owner%para quem ser� este evento
        creator%quem criou o evento
        data%eventuais dados (para quando for uma mensagem)
        options%op��es quaisquer
    end
    methods
        function obj = genericEvent(id,isMsg,time0,time1,owner,creator,...
        data,options)
            obj.id = id;
            obj.isMsg=isMsg;
            obj.time0=time0;
            obj.time1=time1;
            obj.owner=owner;
            obj.creator=creator;
            obj.data=data;
            obj.options=options;
        end
    end
end