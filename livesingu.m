clear all
close all

%Declaración de Variables

C=20;%Número de ventanas 
lmb=0.04;%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu= 0.00255;%Tasa de subida general
teta= 10*(10^-3);%Tasa de abandono general
gamma=0.006;%Tasa de abandono general de los seeds
cw=C*c;%Tasa de descarga máxima
mw=C*mu;%Tasa de subida máxima
HV=zeros(1,C+1);%Vector de poblaciones por ventana de video
HV(C+1)=1;%Estado Inicial (0,0,0,0,...,1)
tp=0;%Vector de tiempos promedio por ventana
xi_prom=0;%Poblaciones promedio de downloaders
TAb=zeros(1,C+1);%Vector para tasa de abandono
tao_mw=zeros(1,C);%Vector para tasa de abandono

%Comienza el ciclo repetitivo
for iter=1:50
    
    %Caso estado (0,0,0,....,1)
    if HV(1:C)==0%Arribo porque las poblaciones de 0 a N son 0 
       HV(1)=HV(1)+1;
       tp=tp+exprnd(1/lmb); 
       
    %Caso estado ~= (0,0,0,....,1)
   
    else%Determinar evento porque las poblaciones de 0 a N son ~=0
              
        %Generar tasas de arribo y abandono por ventana
        TArr=1/lmb;%Tasa promedio de arribo a la ventana 0
        TAb=teta*HV(1:C+1);
              
        %Tranferencia para usuarios en ventanas 0 a N-1        
        tao_cw=cw*HV(1:C);%Tasa promedio de descarga en abundancia

        for i=1:C
            for k=i+1:C
                tao_mw(i)=tao_mw(i)+(mw*HV(i)*(HV(k)/sum(HV(1:k-1))));%Tasa promedio de descarga en penuria
            end
            tao_mw(i)=tao_mw(i)+(HV(C+1)/sum(HV(1:C)));
        end

        %Obtener V.A con las tasas de arribo, abandono y transferencia
        tao_min=min(tao_cw,tao_mw);%Tasa promedio de descarga en la ventana i

        VEArr=exprnd(TArr);%V.A para arribos
        ab=exprnd(1./TAb);%Vector de V.As para abandonos
        tran=exprnd(1./tao_min);%Vector de V.As para transferencias

        %Tiempos infinitos para descartar un abandono o transferencia
        %inválida             
        for idxab=1:C+1%Cambir el vector a infinitos para descartar poblaciones en 0
            if(ab(idxab)==0)
               tab(idxab)=inf;
            else
               tab(idxab)=ab(idxab);
            end
        end
        VEAb=min(tab);% Obtener minimo de ab

        for idxtao=1:C%Cambir el vector a infinitos para descartar poblaciones en 0
            if(tran(idxtao)==0)
               TTran(idxtao)=inf;
            else
               TTran(idxtao)=tran(idxtao);
            end
        end
        VETao=min(TTran);% Obtener minimo de tran

        %Obtener el evento que ocurrio
        Evsucces=min(VEArr,VEAb);
        Evfinal=min(Evsucces,VETao);

        %Incrementar o decrementar la población de una ventana dependiendo 
        %del evento ocurrido y de la ventana en donde ocurrio

        if Evfinal==VEAb

           idx=find(ab==VEAb);%Encontrar indice donde ab == VEAb
           HV(idx)=HV(idx)-1;%Decrementar W en idx
           tp=tp+VEAb;%Se suma el tiempo promedio a tp en idx

        elseif Evfinal==VEArr

           HV(1)=HV(1)+1;%Incrementar W en 1
           tp=tp+VEArr;%Se suma el tiempo promedio a tp en 1

        elseif Evfinal==VETao
           idx=find(tran==VETao);%Encontrar indice donde ab == VEAb
           HV(idx)=HV(idx)-1;%Decrementar W en idx
           HV(idx+1)=HV(idx+1)+1;%Incrementar W en idx+1
           tp=tp+VETao;%Se suma el tiempo promedio a tp en idx
        end 
        xi_prom=xi_prom+(sum(HV(1:C+1))*Evfinal);                
    end
    HV
    x_prom=xi_prom/tp;        
end