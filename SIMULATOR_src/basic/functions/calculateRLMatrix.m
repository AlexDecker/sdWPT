%Calcula a resist�ncia equivalente de um conjunto carregador/bateria

%sa�das
%RL_group: resist�ncia equivalente (por grupo)
%It: Vetor coluna com as correntes nos transmissores (por anel RLC)
%Ir: Vetor coluna com as correntes nos receptores (por anel RLC)

%entradas
%Vt_group: Vetor coluna com as tens�es das fontes dos transmissores (considerando grupos)
%Z: Matriz de imped�ncia do sistema (considerando os aneis RLC)
%Ie_group: Corrente esperada dada a opera��o padr�o de recarga de uma bateria
%(vetor coluna com o valor para cada grupo receptor)
%RL0_group: RL inicial (um valor para cada grupo receptor). 
%err: erro percentual admiss�vel entre Ir e Ie
%maxRL: valor m�ximo para RL (escalar)
%ifactor: fator de incremento para a busca de RL. deve ser menor que
%dfactor e maior ou igual a 1
%dfactor: fator de decremento para a busca de RL
%iVel: velocidade inicial para a busca de RL no espa�o se solu��es
%groupMarking: groupMarking(i,j) = {1 caso i perten�a ao grupo j e 0 caso contr�rio}.

function [RL_group,It,Ir]=calculateRLMatrix(Vt_group,Z,Ie_group,RL0_group,err,maxRL,...
	ifactor,dfactor,iVel,groupMarking)
	
    %verifica��es dos par�metros
    s = size(Z);
    s2 = size(groupMarking);
    
    n = s(1);%n�mero de an�is RLC
    n_groups = s2(2); %n�mero de grupos
    nt_groups = length(Vt_group); %n�mero de grupos transmissores
    nr_groups = n_groups-nt_groups; %n�mero de grupos receptores
    
    nt = sum(sum(groupMarking(:,1:nt_groups)));%n�mero de an�is RLC transmissores
    
    if (s(1)~=s(2))||(nt>=n)||(nt_groups>=n_groups)||...
            (length(Ie_group)~=length(RL0_group))||(err<0)||(err>1)||...
            (ifactor>dfactor)||(dfactor<=1)||(iVel<=0)||...
            (length(RL0_group)~=nr_groups)||(sum(RL0_group<0)>0)||...
			(maxRL<=0)||(~checkGroupMarking(groupMarking))
        error('calculateRLMatrix: parameter error');
    end
    
    %limitando os elementos de imped�ncia (para n�o prejudicar a invers�o)
    for i=1:n %para evitar problemas com singularidade matricial
    	for j=1:n
		    if abs(Z(i,j))>maxRL %testa para imped�ncia m�xima
		        Z(i,j)=maxRL/abs(Z(i,j))*Z(i,j);
		    end
        end
    end
    
    %passando de espa�o de grupo para espa�o de anel RLC
    V = groupMarking*[Vt_group;zeros(nr_groups,1)];
    
    RL_group = RL0_group;
    deltaRL = 0*RL0_group;%matriz de 0 com o tamanho de RL0_group
	
	ttl = 10000;
    
    while true
		ttl = ttl-1;
        
        I = composeZMatrix(Z,[zeros(nt_groups,1);RL_group],groupMarking)\V;
        It = I(1:nt);
        Ir = I(nt+1:end);
        
        I_groups = groupMarking'*I;%corrente principal de cada grupo de an�is
        
        %c�lculo dos erros
        absIerr = abs(I_groups(nt+1:end))-abs(Ie_group);%se negativo, aumente a corrente
        %(diminua a resist�ncia). Se positivo, diminua a corrente
        %(aumente a resist�ncia)
        
        %se todos est�o dentro da margem de erro toler�vel
        cond1 = (abs(absIerr)<err*abs(Ie_group)); 
        
        cond2 = (absIerr<0); %os que devem diminuir a resist�ncia
        cond3 = (RL_group==0); %os que j� abaixaram a resist�ncia ao m�nimo
        
        cond4 = (absIerr>0); %os que devem aumentar a resist�ncia
        cond5 = (RL_group==maxRL); %os que j� aumentaram a resist�ncia ao m�ximo
        
        %estado de parada individual: caso esteja dentro da margem de erro
        %toler�vel ou precise aumentar ou diminuir a corrente apesar de n�o
        %ser capaz
        cond = cond1 | (cond2 & cond3) | (cond4 & cond5);
        
        %se todos est�o em estado de parada individual
        if sum(cond)==length(cond)
            break;
        end
		
		if ttl<=0
			warningMsg('(calculating RL): I give up'); 
			break;
		end
        
        for i=1:length(RL_group)
            %definindo a nova varia��o de RL
            if(absIerr(i)<0)%deltaRL deve ser negativo
                if(deltaRL(i)<0)%aumente o m�dulo da varia��o
                    deltaRL(i) = deltaRL(i)*ifactor;
                else
                	%passou da solu��o, diminua o m�dulo da varia��o e troque o sinal
                    if(deltaRL(i)>0)
                        deltaRL(i) = -deltaRL(i)/dfactor;
                    else%recomece (ou comece) da velocidade m�nima
                        deltaRL(i) = -iVel;
                    end
                end
            else
                if(absIerr(i)>0)%deltaRL deve ser positivo
                	%passou da solu��o, diminua o m�dulo da varia��o e troque o sinal
                	if(deltaRL(i)<0)
                       deltaRL(i) = -deltaRL(i)/dfactor;
                    else
                        if(deltaRL(i)>0)%aumente o m�dulo da varia��o
                            deltaRL(i) = deltaRL(i)*ifactor;
                        else%recomece (ou comece) da velocidade m�nima
                            deltaRL(i) = iVel;
                        end
                    end 
                else%deltaRL deve ser nulo
                    deltaRL(i)=0;
                end
            end
            
            RL_group(i) = RL_group(i)+deltaRL(i);
			
            if RL_group(i)<0 %resist�ncia apenas positiva
                RL_group(i)=0;
            end
            if RL_group(i)>maxRL %resist�ncia limitada superiormente
                RL_group(i)=maxRL;
            end
        end
    end
end
