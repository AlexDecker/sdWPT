%Calcula a resist�ncia equivalente de um conjunto carregador/bateria

%sa�das
%RL: resist�ncia equivalente
%It: Vetor coluna com as correntes nos transmissores
%Ir: Vetor coluna com as correntes nos receptores

%entradas
%Vt: Vetor coluna com as tens�es das fontes dos transmissores
%Z: Matriz de imped�ncia do sistema, com as resist�ncias ohimicas na
%diagonal principal e -jwM nas demais posi��es, sendo j a unidade
%imagin�ria, w a frequ�ncia angular e M a indut�ncia
%Ie: Corrente esperada dada a opera��o padr�o de recarga de uma bateria
%(vetor coluna com o valor para cada receptor)
%RL0: RL inicial. 
%err: erro percentual admiss�vel entre Ir e Ie
%maxRL: valor m�ximo para RL (escalar)
%ifactor: fator de incremento para a busca de RL. deve ser menor que
%dfactor e maior ou igual a 1
%dfactor: fator de decremento para a busca de RL
%iVel: velocidade inicial para a busca de RL no espa�o se solu��es

function [RL,It,Ir]=calculateRLMatrix(Vt,Z,Ie,RL0,err,maxRL,ifactor,dfactor,iVel)
    %verifica��es dos par�metros
    s = size(Z);
    if (s(1)~=s(2))||(length(Vt)>=s(1))||...
            (length(Ie)~=length(RL0))||(err<0)||(err>1)||...
            (ifactor>dfactor)||(dfactor<=1)||(iVel<=0)||...
            (length(RL0)~=length(Z)-length(Vt))||(sum(RL0<0)>0)||...
			(maxRL<=0)
        error('calculateRLMatrix: parameter error');
    end
    
    n = s(1);
    nt = length(Vt);
    nr = n-nt;
    
    RL = RL0;
    deltaRL = 0*RL0;%matriz de 0 com o tamanho de RL0
	
	ttl = 10000;
    
    while true
		ttl = ttl-1;
        R = diag([zeros(nt,1);RL]);
        V = [Vt;zeros(nr,1)];
        I = (Z+R)\V;
        It = I(1:nt);
        Ir = I(nt+1:end);
        %c�lculo dos erros
        absIerr = abs(Ir)-abs(Ie);%se negativo, aumente a corrente
        %(diminua a resist�ncia). Se positivo, diminua a corrente
        %(aumente a resist�ncia)
        
        cond1 = (abs(absIerr)<err*abs(Ie)); %se todos est�o dentro da margem de erro toler�vel
        
        cond2 = (absIerr<0); %os que devem diminuir a resist�ncia
        cond3 = (RL==0); %os que j� abaixaram a resist�ncia ao m�nimo
        
        cond4 = (absIerr>0); %os que devem aumentar a resist�ncia
        cond5 = (RL==maxRL); %os que j� aumentaram a resist�ncia ao m�ximo
        
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
        
        for i=1:length(RL)
            %definindo a nova varia��o de RL
            if(absIerr(i)<0)%deltaRL deve ser negativo
                if(deltaRL(i)<0)%aumente o m�dulo da varia��o
                    deltaRL(i) = deltaRL(i)*ifactor;
                else
                    if(deltaRL(i)>0)%passou da solu��o, diminua o m�dulo da varia��o e troque o sinal
                        deltaRL(i) = -deltaRL(i)/dfactor;
                    else%recomece (ou comece) da velocidade m�nima
                        deltaRL(i) = -iVel;
                    end
                end
            else
                if(absIerr(i)>0)%deltaRL deve ser positivo
                   if(deltaRL(i)<0)%passou da solu��o, diminua o m�dulo da varia��o e troque o sinal
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
            
            RL(i) = RL(i)+deltaRL(i);
			
            if RL(i)<0 %resist�ncia apenas positiva
                RL(i)=0;
            end
            if RL(i)>maxRL %resist�ncia limitada superiormente
                RL(i)=maxRL;
            end
        end
    end
end