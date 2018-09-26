%Aplica��o de acordo com o protocolo Qi v1.0

classdef powerTXApplication_Qi < powerTXApplication
    properties
    	d0
        vel
        zone1Limit
        zone2Limit
        mi1
        mi2
        
        %varia��o de tempo do timer
        dt
        
        %state:
        %0 - busca desligado (ao entrar nesse estado, desliga o transmissor e liga o timer. No final do timer, vai
        %para 1)
        %1 - busca ligado (ao entrar nesse estado, liga o transmissor e envia um ping via SWIPT broadcast)
        %e liga o timer. se n�o receber uma resposta at� o timer terminar, vai para 0. Se receber, vai para 2)
        %2 - Transmitindo (liga o timer a cada dt, incrementa okUntil em dt a cada mensagem recebida e se globalTime
        %ultrapassar okUntil, vai para o estado 0).
        state
        
        %marca o momento em que o sistema ir� para o estado 0 caso n�o receba outra mensagem pedindo a continuidade
        %da transmiss�o
        okUntil
    end
    methods
        function obj = powerTXApplication_Qi(d0,vel,zone1Limit,zone2Limit,mi1,mi2,dt)
            obj@powerTXApplication();%construindo a estrutura referente � superclasse
            obj.d0 = d0;
            obj.vel = vel;
            obj.zone1Limit = zone1Limit;
            obj.zone2Limit = zone2Limit;
            obj.mi1 = mi1;
            obj.mi2 = mi2;
            
            obj.okUntil = 0;%dummie
            obj.state = -1;%dummie
            obj.dt = dt;
        end

        function [obj,netManager,WPTManager] = init(obj,netManager,WPTManager)
        	%SWIPT, 1000bps, 5W (dummie)
            obj = setSendOptions(obj,0,1000,5);
            
            %se inicia no estado zero
            [obj,WPTManager] = goToStateZero(obj,WPTManager,0);
            
        	netManager = setTimer(obj,netManager,0,obj.dt*10);%dispara o timer
        end

        function [obj,netManager,WPTManager] = handleMessage(obj,data,GlobalTime,netManager,WPTManager)
        	switch(obj.state)
        		case 1
        			%algu�m respondeu o ping. Inicie a transmiss�o propriamente dita
        			disp('Connection established');
        			[obj,WPTManager] = goToStateTwo(obj,WPTManager,GlobalTime);
        		case 2
        			obj.okUntil = GlobalTime+obj.dt; %renova o atestado por mais um ciclo 
        	end         
        end

        function [obj,netManager,WPTManager] = handleTimer(obj,GlobalTime,netManager,WPTManager) 
        	WPTManager = dealEffectivePermeability(obj,GlobalTime,WPTManager);
        	switch(obj.state)
        		case 0
        			%alternando entre estados 0 e 1
        			[obj,WPTManager,netManager] = goToStateOne(obj,WPTManager,netManager,GlobalTime);
        			%chamada para o pr�ximo ciclo
        			netManager = setTimer(obj,netManager,GlobalTime,obj.dt);
        		case 1
	        		%alternando entre estados 0 e 1
        			[obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime);
        			%chamada para o pr�ximo ciclo
        			netManager = setTimer(obj,netManager,GlobalTime,obj.dt*10);
        		case 2
        			%est� transmitindo, mas a mensagem de continuidade de transmiss�qo n�o chegou a tempo
        			if(obj.okUntil<=GlobalTime)
        				%desligue a transmiss�o e volte a buscar
        				disp('Connection lost');
        				[obj,WPTManager] = goToStateZero(obj,WPTManager);
        			end
        			%chamada para o pr�ximo ciclo
        			netManager = setTimer(obj,netManager,GlobalTime,obj.dt*10);
        	end
        end
        
        %tratamento individual de cada estado (ao entrar)
        
        function [obj,WPTManager] = goToStateZero(obj,WPTManager,GlobalTime)
        	obj.state = 0;
        	WPTManager = turnOff(obj,WPTManager,GlobalTime);%desliga o transmissor de pot�ncia
        	%o timer j� � disparado automaticamente
        end
        
        function [obj,WPTManager,netManager] = goToStateOne(obj,WPTManager,netManager,GlobalTime)
        	obj.state = 1;
        	WPTManager = turnOn(obj,WPTManager,GlobalTime);%liga o transmissor de pot�ncia
        	netManager = broadcast(obj,netManager,0,32,GlobalTime);%faz um broadcast com seu id (0, 32 bits)
        	%o timer j� � disparado automaticamente
        end
        
        function [obj,WPTManager] = goToStateTwo(obj,WPTManager,GlobalTime)
        	obj.state = 2;
        	WPTManager = turnOn(obj,WPTManager,GlobalTime);%liga o transmissor de pot�ncia
        	obj.okUntil = GlobalTime + obj.dt;
        end
        
        %simula��o da permeabilidade multi-camada
        
        function WPTManager = dealEffectivePermeability(obj,GlobalTime,WPTManager)
        	distance = obj.d0 + obj.vel*GlobalTime;%estima a dist�ncia das bobinas baseado nos par�metros e no tempo
        	if(distance<obj.zone1Limit)
        		%zona 1 (alta proximidade)
        		WPTManager.ENV.miEnv = obj.mi1;
        	else
        		if(distance<obj.zone2Limit)
        			%zona 2 (proximidade m�dia)
        			WPTManager.ENV.miEnv = (distance-obj.zone1Limit)/(obj.zone2Limit-obj.zone1Limit)*obj.mi2+...
        				(obj.zone2Limit-distance)/(obj.zone2Limit-obj.zone1Limit)*obj.mi2;
        		else
        			%zona 3 (t�rmino da influ�ncia do atrator)
        			WPTManager.ENV.miEnv = obj.mi2;
        		end
        	end 
        end
        
        %encapsulamento das fun��es b�sicas do sistema
        
        function WPTManager = turnOn(obj,WPTManager,GlobalTime)
        	WPTManager = setSourceVoltages(obj,WPTManager,5,GlobalTime);
        end
        
        function WPTManager = turnOff(obj,WPTManager,GlobalTime)
        	WPTManager = setSourceVoltages(obj,WPTManager,0,GlobalTime);
        end
    end
end
