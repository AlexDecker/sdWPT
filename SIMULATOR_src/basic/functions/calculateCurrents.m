%sa�das
%eZ: Matriz de imped�ncia efetivamente usada
%RS: resist�ncia da fonte (considerando que todos possuem a mesma fonte, ohms)
%I: Vetor coluna com as correntes nos elementos do sistema (A, uma por anel RLC)

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
%maxPower: pot�ncia m�xima da fonte de tens�o (W)
%groupMarking: groupMarking(i,j) = {1 caso i perten�a ao grupo j e 0 caso contr�rio}.

function [eZ,RS,I]=calculateCurrents(Vt_group,Z,RL_group,RS0,err,maxResistance,ifactor,...
    dfactor,iVel,maxPower,groupMarking)

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
            ||(length(RS0)~=1)||(length(maxResistance)~=1)||(length(maxPower)~=1)...
            ||(maxPower<=0)||(~checkGroupMarking(groupMarking))
        error('calculateCurrents: parameter error');
    end
    
    %passando de espa�o de grupo para espa�o de anel RLC
    V = groupMarking*[Vt_group;zeros(nr_groups,1)];
    
    %montando a matriz de imped�ncia Z do sistema
    Z = composeZMatrix(Z,[zeros(nt_groups,1);RL_group],groupMarking);
    for i=1:n %para evitar problemas com singularidade matricial
    	for j=1:n
		    if real(Z(i,j))>maxResistance
		        Z(i,j)=maxResistance+imag(Z(i,j));
		    end
        end
    end
    
    I = Z\V;
    P = abs(V.'*I);
    
	ttl = 10000;
	
    if P-maxPower<err*maxPower %opera��o normal
        RS = 0;
        eZ = Z;
    else %condi��o de satura��o         
        RS = RS0;
        deltaRS = 0;
        while true
			ttl = ttl-1;

            I = composeZMatrix(Z,[RS*ones(nt_groups,1);zeros(nr_groups,1)],groupMarking)\V;
            
            %c�lculo do erros
            absPerr = abs(V.'*I)-maxPower;%se negativo, diminua a resist�ncia.
            %se positivo, aumente a resist�ncia
			
			%se todos est�o dentro da margem de erro toler�vel
            cond1 = (abs(absPerr)<err*maxPower); 

            cond2 = (absPerr<0); %deve diminuir a resist�ncia
            cond3 = (RS==0); %j� abaixou a resist�ncia ao m�nimo

            cond4 = (absPerr>0); %deve aumentar a resist�ncia
            cond5 = (RS==maxResistance); %j� aumentou a resist�ncia ao m�ximo
            
            %condi��o de parada: resultado aceit�vel ou deve variar e n�o
            %consegue
            if  cond1 || (cond2 && cond3) || (cond4 && cond5)
                eZ = Z+R;
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
		warningMsg('the source is satured',[': asked for ',num2str(P),' W, but the source provided ',num2str(abs(V.'*I)),' W']);
    end
end
