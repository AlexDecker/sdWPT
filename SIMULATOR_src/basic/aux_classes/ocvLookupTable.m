%Dicion�rio que associa open-circuit voltage (OCV) a um dado valor de
%state-of-charge (SOC). Essa fun��o define grande parte do comportamento de
%uma bateria. Para construir o objeto, crie um arquivo txt em que cada
%linha aparece na forma "%f %f\n", que correspondem respectivamente a
%um valor de SOC (entre 0 e 1) e um valor de OCV (em volts). O primeiro
%valor de SOC deve ser 0 e o �ltimo 1 necessariamente. Os valores de SOC
%devem ser crescentes. Insira o arquivo com os dados na pasta
%"battery_data" e apenas informe o nome do arquivo ao construtor do objeto,
%sem informar o caminho.

classdef ocvLookupTable < LookupTable
    
   properties
   end
   
   methods
      function obj = ocvLookupTable(file,plotData)
          obj@LookupTable(['battery_data/',file],false);
          
          if ~check(obj)
              error('ocvLookupTable: error: battery data is incompatible with the model');
          end
          
          if plotData
              ocvPlot(obj);
          end
      end
      
      %a fun��o abaixo utiliza interpola��o linear entre dois pontos
      %conhecidos para descobrir o desconhecido.
      function OCV = getOCVFromSOC(obj,SOC)
          if((SOC>1)||(SOC<0))
              error('ocvLookupTable: error: informed SOC is out of bounds');
          end
          OCV = getYFromX(obj,SOC);
      end
      
      function flag = check(obj)
          flag = false;
          if length(obj.table)<2
              flag = true;
          end
          if obj.table(1,1)~=0
              flag=true;
          end
          if obj.table(end,1)~=1
              flag=true;
          end
          if ~flag%s� � necess�rio verificar se j� n�o tiver conclu�do que
              %est� errado
              for i=2:length(obj.table)
                if(obj.table(i-1,1)>=obj.table(i,1))
                    flag=true;
                    break;
                end
                if(obj.table(i-1,2)>obj.table(i,2))
                    warningMsg('OCV is usually a monotonically increasing function');
                end
              end
          end
      end
      
      function ocvPlot(obj)
          figure;
          plot(obj.table(:,1)*100,obj.table(:,2));
          xlabel('SOC (%)');
          ylabel('OCV (V)');
      end
   end
end
