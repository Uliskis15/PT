clear all
close all

%Declaración de Variables

N=20;%Número de ventanas 
lmb=0.04;%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu= 0.00255;%Tasa de subida general
teta= 10^-3;%Tasa de abandono general
gamma=0.006;%Tasa de abandono general de los seeds
cw=N*c;%Tasa de descarga máxima
mw=N*mu;%Tasa de subida máxima
W=zeros(1,N+1);%Vector de poblaciones por ventana de video
W(N+1)=1;%Estado Inicial (0,0,0,0,...,1)
tp=0;%Vector de tiempos promedio por ventana
w_prom=0;%Poblaciones promedio de downloaders
y_prom=0;%Población promedio de seeds
TAb=zeros(1,N+1);%Vector para tasa de abandono
tao_mw=zeros(1,N);%Vector para tasa de abandono

%Comienza el ciclo repetitivo
for iter=1:500
    
    %Caso estado (0,0,0,....,1)
    if W(1:N)==0%Arribo porque las poblaciones de 0 a N son 0 
        
        W(1)=W(1)+1;
        tp=tp+exprnd(lmb);
        
    %Caso estado ~= (0,0,0,....,1)
    else %Determinar evento porque las poblaciones de 0 a N son ~=0
        
        %Generar tasas de arribo y abandono por ventana
        TArr=1/lmb;%Tasa promedio de arribo a la ventana 0
        TAb=teta*W(1:N);
                
        %Abandono para seeds
        Si=W(N+1);
        if Si >= 2
            TAb(N+1)=gamma*(Si-1);
        else
            TAb(N+1)=inf;
        end
        
        %Tranferencia para usuarios en ventanas 0 a N-2        
        tao_cw=cw*W(1:N);%Tasa promedio de descarga en abundancia
             
        for i=1:N-1
            for k=i+1:N
                     tao_mw(i)=tao_mw(i)+(mw*W(i)*(W(k)/sum(W(1:k-1))));%Tasa promedio de descarga en penuria
            end
            tao_mw(i)=tao_mw(i)+(W(N+1)/sum(W(1:N)));
        end
        
        %Tranferencia para usuarios en ventana N-1      
        tao_mw(N)=mw*W(N)*(W(N+1)/sum(W(1:N-1)));%Tasa promedio de descarga en penuria
        
                    
        %Obtener V.A con las tasas de arribo, abandono y transferencia
        tao_min=min(tao_cw,tao_mw);%Tasa promedio de descarga en la ventana i
        
        VEArr=exprnd(TArr);%V.A para arribos
        ab=exprnd(1./TAb);%Vector de V.As para abandonos
        tran=exprnd(1./tao_min);%Vector de V.As para transferencias
                
        %Tiempos infinitos para descartar un abandono o transferencia
        %inválida             
        for idxab=1:N+1%Cambir el vector a infinitos para descartar poblaciones en 0
            if(ab(idxab)==0)
               tab(idxab)=inf;
            else
               tab(idxab)=ab(idxab);
            end
        end
        VEAb=min(tab);% Obtener minimo de ab
        
        for idxtao=1:N%Cambir el vector a infinitos para descartar poblaciones en 0
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
           W(idx)=W(idx)-1;%Decrementar W en idx
           tp=tp+VEAb;%Se suma el tiempo promedio a tp en idx
           
        elseif Evfinal==VEArr
            
            W(1)=W(1)+1;%Incrementar W en 1
            tp=tp+VEArr;%Se suma el tiempo promedio a tp en 1
            
        elseif Evfinal==VETao
           idx=find(tran==VETao);%Encontrar indice donde ab == VEAb
           W(idx)=W(idx)-1;%Decrementar W en idx
           W(idx+1)=W(idx+1)+1;%Incrementar W en idx+1
           tp=tp+VETao;%Se suma el tiempo promedio a tp en idx
        end 
        w_prom=w_prom+(sum(W(1:N))*Evfinal);
        y_prom=y_prom+(W(N+1)*Evfinal);
    end 
    W;
    X_prom=w_prom/tp;
    Y_prom=y_prom/tp;
end