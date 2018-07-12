classdef envListManager
   properties
       envList
       Vt %vetor coluna com a tens�o ac de cada transmissor (V) 
       R %vetor coluna com a resis�ncia de cada Transmissor/Receptor (ohm)
       w %frequ�ncia ressonante angular (rad/s)
       tTime %tempo decorrido do primeiro (time=0) ao �ltimo quadro (s)
       err %erro admiss�vel para a pot�ncia (%)
       maxResistance %teto para qualquer valor de resist�ncia (ohm)
       ifactor %> 1 e < dfactor, usado na busca por RS
       dfactor
       iVel %velocidade inical para a busca de RS
       maxPower %pot�ncia m�xima da fonte dos transmissores
       mostRecentZ %valor mais recente de Z utilizado 
       
       RS %ponto de partida para a busca do pr�ximo vetor RS
   end
   methods
      function obj = envListManager(envList,Vt,w,R,tTime,err,...
              maxResistance,ifactor,dfactor,iVel,maxPower)
          obj.envList = envList;
          obj.Vt = Vt;
          obj.w = w;
          obj.R = R;
          obj.tTime=tTime;
          
          obj.err=err;
          obj.maxResistance=maxResistance;
          obj.ifactor=ifactor;
          obj.dfactor=dfactor;
          obj.iVel=iVel;
          obj.maxPower=maxPower;
          
          obj.mostRecentZ = getZ(obj,0);
          
          obj.RS = 0;
          
          if ~check(obj)
              error('envListManager: parameter error');
          end
      end
      
      %verifica se os par�metros est�o em ordem
      function r = check(obj)
               r = (obj.w>0) && (sum(obj.R<=0)==0) && (obj.tTime>0) &&...
                  (length(obj.R)==length(obj.mostRecentZ)) &&...
                  (length(obj.Vt)<length(obj.R)) && (obj.err>0) && (obj.err<1) &&...
                  (sum(obj.R>obj.maxResistance)==0) && (length(obj.maxResistance)==1) &&...
                  (obj.ifactor>1) && (length(obj.ifactor)==1) && ...
                  (obj.dfactor>obj.ifactor) && (length(obj.dfactor)==1) && ...
                  (obj.iVel>0) && (length(obj.iVel)==1) && ...
                  (obj.maxPower>0) && (length(obj.maxPower)==1);
      end
      
      %os dados de que n�o se t�m informa��o s�o aproximados com uma
      %combina��o linear convexa, na forma
      %dado[time] = dado[i0]*lambda+(1-lambda)*dado[1]
      function [i0,i1,lambda] = getIndexFromTime(obj,time)
          n = length(obj.envList);
          i = 1+(n-1)*time/obj.tTime;
          i0 = floor(i);
          i1 = ceil(i);
          lambda = i1-i;
      end
      
      function Z = getZ(obj,time)%requer onisci�ncia for�ada
          [i0,i1,lambda] = getIndexFromTime(obj,time);
          
          obj.envList(i0).R = obj.R;
          obj.envList(i0).w = obj.w;
          Z0 = generateZENV(obj.envList(i0));
          
          obj.envList(i1).R = obj.R;
          obj.envList(i1).w = obj.w;
          Z1 = generateZENV(obj.envList(i1));
          
          Z = lambda*Z0+(1-lambda)*Z1;%faz a interpola��o linear entre as
          %duas matrizes que se tem informa��o real
      end
      
      %sub-matriz de Z correspondente aos trasmissores
      function Zt = getZt(obj,time)
          Z = getZ(obj,time);
          Zt = Z(1:length(obj.Vt),1:length(obj.Vt));
      end
      
      %RL: resist�ncia equivalente do dispositivo atrelado a cada receptor.
      function [obj,I] = getCurrent(obj,RL,time)%requer onisci�ncia
          if ~check(obj)
              error('envListManager: attribute violation');
          end
          Z = getZ(obj,time);
          [obj.mostRecentZ,obj.RS,I]=calculateCurrents(obj.Vt,Z,RL,obj.RS,...
              obj.err,obj.maxResistance,obj.ifactor,obj.dfactor,...
              obj.iVel,obj.maxPower);
      end
   end
end