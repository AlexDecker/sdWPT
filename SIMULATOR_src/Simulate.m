function [LOG_TX,LOG_dev_list,LOG_app_list] = Simulate(ENV_LIST_FILE,NTX,R,W,TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_POWER,DEVICE_LIST,STEP,...
    SHOW_PROGRESS,powerTX,powerRX,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF)
    
    LOG_TX = [];
    LOG_dev_list = [];
    LOG_app_list = [];
	GlobalTime = 0;
	
	%Gera um envList baseado no arquivo especificado
	load(ENV_LIST_FILE);
 
    %Os objetos abaixo cuidam de aspactos f�sicos de WPT
	elManager = envListManager(envList,zeros(NTX,1),W,R,TOTAL_TIME,MAX_ERR,R_MAX,IFACTOR,DFACTOR,INIT_VEL,MAX_POWER);
	Manager = envListManagerBAT(elManager,DEVICE_LIST,STEP,SHOW_PROGRESS);
	
    %inicializando a tens�o dos aparatos transmissores
	Manager = setVt(Manager, zeros(NTX,1), 0);
    
    %O objeto abaixo cuida dos aspectos eventos em redes e timers
    network = networkManager(length(envList(1).Coils)-NTX);
    
    if(powerTX.ID~=0)
        %ID=0 indica que � uma aplica��o de TX
        error('powerTX is not a powerTXApplication');
    end
    %� executada a fun��o de inicializa��o do TX
    [powerTX,network,Manager] = init(powerTX,network,Manager);
    
    %S�o executadas as fun��es de inicializa��o dos RX
    for i=1:length(powerRX);
        if(powerRX(i).ID~=i)
            error('ID of powerRX(i) must be equals to its index in powerRX vector');
        end
        [powerRX(i),network,Manager] = init(powerRX(i),network,Manager);
    end

    while(true)
        %enquanto ainda existirem eventos agendados
		if (emptyEnventList(network))
			disp('No more events to compute');
            break;
		end
        
        %atualiza o tempo global, as mensagens que eventualmente conflitem com o evento, o evento em si e o gerenciador de eventos
		[GlobalTime, conflictingMsgs, event, network] = nextEvent(network);

        if(GlobalTime>TOTAL_TIME)
			disp('TOTAL_TIME achieved');
            break;
        end
        
        if(event.owner==0)%TX
            if(event.isMsg)
                %se for uma mensagem
                
                %apenas um alerta para fins de realismo
                if(powerTX.SEND_OPTIONS.baudRate~=powerRX(event.creator).SEND_OPTIONS.baudRate)
                    warningMsg('BaudRate values do not match');
                end
                
                [I,~,~,Manager] = getSystemState(Manager,GlobalTime);
                Z = getCompleteLastZMatrix(Manager);
                
                %avalia via SINR se a mensagem deve ser enviada
                if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,I,Z,STEP))
                    %fun��o de tratamento de mensagens do destinat�rio
                    [powerTX, network, Manager] = handleMessage(powerTX,event.data,GlobalTime,network,Manager);
                end
            else                
                %se for um evento de timer
                [powerTX, network, Manager] = handleTimer(powerTX,GlobalTime,network,Manager);
            end
        else%RX
            if(event.isMsg)
                %se for uma mensagem
            
                %apenas um alerta para fins de realismo
                if(event.creator==0)
                    if(powerTX.SEND_OPTIONS.baudRate~=powerRX(event.owner).SEND_OPTIONS.baudRate)
                        warningMsg('BaudRate values do not match');
                    end
                else
                    if(powerRX(event.creator).SEND_OPTIONS.baudRate~=powerRX(event.owner).SEND_OPTIONS.baudRate)
                        warningMsg('BaudRate values do not match');
                    end
                end
                
                [I,~,~,Manager] = getSystemState(Manager,GlobalTime);
                Z = getCompleteLastZMatrix(Manager);
                
                %avalia via SINR se a mensagem deve ser enviada
                if(rightDelivered(event,conflictingMsgs,Manager,B_SWIPT,B_RF,A_RF,N_SWIPT,N_RF,I,Z,STEP))
                    [powerRX(owner), network, Manager] = handleMessage(powerRX(event.owner),event.data,GlobalTime,network,Manager);
                end
            else
                %evento de timer
                [powerRX(event.owner), network, Manager] = handleTimer(powerRX(event.owner),GlobalTime,network,Manager);
            end
        end
        
        %Resultados desta execu��o (acesso direto a medi��es, com onisci�ncia)
        [~,~,~,Manager] = getSystemState(Manager,GlobalTime);%atualiza o sistema a cada evento
        cleanWarningMsg();%permite que mensagens se acumulem apenas a cada evento
    end
    
    %recolhendo os logs
    
    LOG_TX = Manager.TRANSMITTER_DATA;
    
	LOG_dev_list = [];
	for i=1:length(Manager.DEVICE_DATA)
		LOG_dev_list = [LOG_dev_list endDataAquisition(Manager.DEVICE_DATA(i))];
	end
	
	LOG_app_list = powerTX.APPLICATION_LOG;
	for i=1:length(powerRX)
		LOG_app_list = [LOG_app_list powerRX(i).APPLICATION_LOG];
	end
	
    disp(['Simulation ended at time ', num2str(GlobalTime)]);
end