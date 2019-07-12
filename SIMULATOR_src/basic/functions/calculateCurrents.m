%Outputs:
%eZ: effectively used impedance matrix
%RS: resistance of the voltage source (we consider that all active circuits have a single
%source)
%I: column vector with the phasor-notation-currents ps each circuit (A, one for each
%RLC ring)

%entradas
%Vt_group: Vetor coluna com as tens�es das fontes (V, phasor, uma por grupo transmissor)
%Z: Matriz de imped�ncia do sistema (considerando os aneis RLC)
%RL_group: resist�ncia equivalente do sistema sendo carregado (ohms, uma por grupo receptor)
%RS0: RS inicial (escalar, ohms). 0 se n�o tiver algum valor pronto
%err: erro percentual admiss�vel para o limite de pot�ncia
%maxResistance: valor m�ximo para a RS ou a resist�ncia fixa (escalar, ohms)
%ifactor: fator de incremento para a busca de RS. deve ser menor que
%dfactor e maior ou igual a 1
%dfactor: fator de decremento para a busca de RS
%iVel: velocidade inicial para a busca de RS no espa�o se solu��es
%maxActPower: maximum active power for the voltage source (W)
%maxAppPower: maximum apparent power for the voltage source (W)
%groupMarking: groupMarking(i,j) = {1 caso i perten�a ao grupo j e 0 caso contr�rio}.

function [eZ,RS,I]=calculateCurrents(Vt_group,Z,RL_group,RS0,err,maxResistance,ifactor,...
    dfactor,iVel,maxActPower,maxAppPower,groupMarking)

    s = size(Z);
    s2 = size(groupMarking);
    
    n = s(1);%n�mero de an�is RLC
    n_groups = s2(2);%n�mero de grupos
    nt_groups = length(Vt_group);%n�mero de grupos transmissores
    nr_groups = n_groups-nt_groups;%n�mero de grupos receptores
    nt = sum(sum(groupMarking(:,1:nt_groups)));%n�mero de an�is RLC transmissores
    nr = n-nt;
    
    %verifica��es dos par�metros
    if (s(1)~=s(2))||(nt>=n)||(nt_groups>=n_groups)||(err<0)||(err>1)||(length(err)~=1)...
            ||(ifactor>dfactor)||(dfactor<=1)||(length(ifactor)~=1)||(length(dfactor)~=1)...
            ||(iVel<=0)||(length(iVel)~=1)||(length(RL_group)~=nr_groups)||(sum(RL_group<0)>0)...
            ||(length(RS0)~=1)||(length(maxResistance)~=1)||(length(maxActPower)~=1)...
            ||(length(maxAppPower)~=1)||(maxActPower<=0)||(maxAppPower<=0)...
			||(~checkGroupMarking(groupMarking))
        error('calculateCurrents: parameter error');
    end
    
    %passando de espa�o de grupo para espa�o de anel RLC
    V = groupMarking*[Vt_group;zeros(nr_groups,1)];
    
    %montando a matriz de imped�ncia Z do sistema
    Z = composeZMatrix(Z,[zeros(nt_groups,1);RL_group],groupMarking);
    for i=1:n %para evitar problemas com singularidade matricial
    	for j=1:n
		    if abs(Z(i,j))>maxResistance %testa para imped�ncia m�xima
		        Z(i,j)=maxResistance/abs(Z(i,j))*Z(i,j);
		    end
        end
    end
    
    I = Z\V;
    P_act = real(I'*V);%the active power is the real part of the complex power (IEEE Std 1459-2010)
	P_app = abs(I'*V);%the apparent power is the absolute value of the complex power (IEEE Std 1459-2010)
    
	ttl = 10000;
	
    if (P_act-maxActPower<err*maxActPower)&&(P_app-maxAppPower<err*maxAppPower) %opera��o normal
        RS = 0;
        eZ = Z;
    else %condi��o de satura��o         
        RS = RS0;
        deltaRS = 0;
        while true
			ttl = ttl-1;

            eZ = composeZMatrix(Z,[RS*ones(nt_groups,1);zeros(nr_groups,1)],groupMarking);
            I = eZ\V;
            
            %c�lculo do erros
			%se negativo, diminua a resist�ncia.
            %se positivo, aumente a resist�ncia
            absPerr_act = real(I'*V)-maxActPower;
			absPerr_app = abs(I'*V)-maxAppPower;
			
			if maxActPower<maxAppPower
				%if the active power restriction is more restrictive, try to converge to it.
				absPerr = absPerr_act;
				
				cond0 = (abs(absPerr_act)<err*maxActPower); 
				cond1 = (absPerr_app<err*maxAppPower);
				
				cond2 = (absPerr_act<0); %deve diminuir a resist�ncia
				cond4 = (absPerr_act>0); %deve aumentar a resist�ncia
			else
				%otherwise, try to converge to the max apparent power
				absPerr = absPerr_app;
				
				cond0 = (absPerr_act<err*maxActPower); 
				cond1 = (abs(absPerr_app)<err*maxAppPower);
				
				cond2 = (absPerr_app<0); %deve diminuir a resist�ncia
				cond4 = (absPerr_app>0); %deve aumentar a resist�ncia
			end
			
			cond3 = (RS==0); %j� abaixou a resist�ncia ao m�nimo
			cond5 = (RS==maxResistance); %j� aumentou a resist�ncia ao m�ximo
            
            %condi��o de parada: resultado aceit�vel ou deve variar e n�o
            %consegue
            if  (cond0 && cond1) || (cond2 && cond3) || (cond4 && cond5)
                break;
            end
			
			if ttl<=0
				warningMsg('(calculating RS): I give up'); 
				break;
			end

            %definindo a nova varia��o de RS
            if(absPerr<0)%deltaRS deve ser negativo
                if(deltaRS<0)%aumente o m�dulo da varia��o
                    deltaRS = deltaRS*ifactor;
                else
                    if(deltaRS>0)%passou da solu��o, diminua o m�dulo da varia��o e troque o sinal
                        deltaRS = -deltaRS/dfactor;
                    else%recomece (ou comece) da velocidade m�nima
                        deltaRS = -iVel;
                    end
                end
            else
                if(absPerr>0)%deltaRL deve ser positivo
                   if(deltaRS<0)%passou da solu��o, diminua o m�dulo da varia��o e troque o sinal
                       deltaRS = -deltaRS/dfactor;
                    else
                        if(deltaRS>0)%aumente o m�dulo da varia��o
                            deltaRS = deltaRS*ifactor;
                        else%recomece (ou comece) da velocidade m�nima
                            deltaRS = iVel;
                        end
                    end 
                else%deltaRL deve ser nulo
                    deltaRS=0;
                end
            end

            RS = RS+deltaRS;

            if RS<0 %resist�ncia apenas positiva
                RS=0;
            end
            if RS>maxResistance %resist�ncia limitada superiormente
                RS=maxResistance;
            end
        end
		warningMsg('the source is satured',[': asked for ',num2str(P_act),' W of active power and ',num2str(P_app),...
			' W of apparent power, but the source provided ',num2str(real(V.'*I)),' W of active power and ',...
			num2str(abs(V.'*I)),' W of apparent power.']);
    end
end
