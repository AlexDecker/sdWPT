%abstrai o ambiente em determinado momento.
classdef Environment
   properties
       Coils
       M
       R %apenas para manuten��o de compatibilidade
       V %apenas para manuten��o de compatibilidade
       I %apenas para manuten��o de compatibilidade
       w %apenas para manuten��o de compatibilidade
   end
   methods
      %inicia a lista de coils e a matriz de acoplamento. R � a lista de
      %resist�ncias ohmicas dos RLCs em ordem, V a lista de tens�es das
      %fontes (0 para receptores) e w � a frequ�ncia ressonante.
      function obj = Environment(Coils,V,w,R)
         obj.Coils = Coils;
         obj.V = V;
         obj.w = w;
         obj.R = R;
      end
      %Os valores desconhecidos de M devem vir com valor -1.
      function obj = evalM(obj,M)
         for i = 1:length(M)
             for j = 1:length(M)
                 if i==j
                     M(i,j)=0;%self-inductance n�o � calculada aqui.
                 else
                     if (M(i,j)==-1)
                         if(M(j,i)~=-1)
                             M(i,j)=M(j,i);
                         else
                             disp('Iniciando calculo de acoplamento');
                             M(i,j)=evalMutualInductance(obj.Coils(i), obj.Coils(j));
                         end
                     end
                 end
             end
         end
         obj.M=M;
      end
      
      function I = evaluateCurrentsENV(obj)
         Z = generateZENV(obj);
         I = Z\(obj.V.');
      end
      
      
      function I = evalCurrentsWithPowerRestrictionENV(obj,maxP,maxErr,rin)
          Z = generateZENV(obj);
          I = Z\(obj.V.');
          r = rin;
          pot = abs((obj.V').'*I);
          if(pot>maxP)%se ultrapassar a pot�ncia m�xima
              while(abs(pot-maxP)>maxErr)%enquanto n�o se aproxima o suficiente   
                  Z = Z+r*diag([ones(1,6) zeros(1,length(Z)-6)]);%adiciona resist�ncia aos transmissores
                  I = Z\(obj.V.');%corrige o vetor de correntes
                  pot = abs((obj.V').'*I);
                  tstAnt = tst;
                  tst = (pot>maxP);
                  if(tstAnt~=tst)%se tiver passado do alvo
                      r = -r/2;%o incremento diminui para convergir
                  end
              end
          end
      end
      
      function Z = generateZENV(obj)
          if(length(obj.R)~=length(obj.M))
              error('R and M sizes dont agree');
          end
          Z = diag(obj.R)-(1i)*obj.w*obj.M;
      end
   end
end