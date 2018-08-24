%abstrai o ambiente em determinado momento.
classdef Environment
    properties
        Coils
        M
        R
        C
        w
        conferable
        miEnv %constante de permeabilidade magn�tica do meio
    end
    methods
        %inicia a lista de coils e a matriz de acoplamento. R � a lista de
        %resist�ncias ohmicas dos RLCs em ordem, V a lista de tens�es das
        %fontes (0 para receptores), w � a frequ�ncia da fonte e C (opcional)
        %� a lista em ordem das capacit�ncias dos circuitos. Na falta de C,
        %� presumida resson�ncia magn�tica. Use conferable como false caso
        %queira usar uma vers�o simplificada para testes
        %(vide envListManagerBAT_tester)
        function obj = Environment(Coils,w,R,conferable,C)
            obj.Coils = Coils;
            obj.w = w;
            obj.R = R;
            if exist('C','var')
                obj.C = C;
            else
                obj.C = [];
            end
            obj.conferable = conferable;
            obj.miEnv = pi*4e-7;%este valor � apenas default e alter�vel via envListManager
        end

        function r = check(obj)
            r = true;
            if(obj.conferable)
            	r = (length(obj.Coils)==length(obj.R))&&(obj.w>0)&&(obj.miEnv>0);
                for i = 1:length(obj.Coils)
                    r = r && check(obj.Coils(i).obj);
                end
            end
        end

        %Os valores desconhecidos de M devem vir com valor -1.
        function obj = evalM(obj,M)
            for i = 1:length(M)
                for j = 1:length(M)
                    if (M(i,j)==-1)
                        if(M(j,i)~=-1)
                            M(i,j)=M(j,i);
                        else
                            disp('Iniciando calculo de acoplamento');
                            M(i,j)=evalMutualInductance(obj.Coils(i).obj, obj.Coils(j).obj);
                        end
                    end
                end
            end
            obj.M=M;
        end

        function Z = generateZENV(obj)
            if(length(obj.R)~=length(obj.M))
                error('R and M sizes dont agree');
            end
            
            if(isempty(obj.Coils))
            	miVector = pi*4e-7*ones(length(obj.M),1);
           	else
		        miVector = zeros(length(obj.M),1);
		        for i=1:length(miVector)
		        	miVector(i) = obj.Coils(i).obj.mi;
		        end
		    end
            
            if(isempty(obj.C))
                obj.C = 1./(obj.w^2*miVector.*diag(obj.M));
            end
            
            Z = diag(obj.R)... %resist�ncia pr�pria
                - (1i)*obj.w*obj.miEnv*(obj.M-diag(diag(obj.M)))...%indut�ncias dos outros
                + (1i)*obj.w*diag(miVector.*diag(obj.M))...%indut�ncia pr�pria
                - (1i)*diag(1./(obj.w*obj.C));%capacit�ncia pr�pria
        end
    end
end
