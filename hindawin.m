clear all
close all

%Declaración de Variables

N=[24 36 48 60 72 84 96];% Número de ventanas
teta=[2 3 4 5 6 7 8 9 10].^-3;%Tasa de abandono general
lmb=0.04;%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu= 0.00255;%Tasa de subida general
gamma=0.006;%Tasa de abandono general de los seeds
w_prom=zeros(length(N),length(teta));%Cadena acumulativa para obtener el promedio por iteración 
y_prom=zeros(length(N),length(teta));%Vector de seeds promedio
T_prom=zeros(length(N),length(teta));%Vector de tiempos promedio
IT=100;
for idxn=1:length(N)
        
   for idxt=1:length(teta) 
            
      cw=N(idxn)*c;%Tasa de descarga máxima
      mw=N(idxn)*mu;%Tasa de subida máxima
      W=zeros(1,N(idxn)+1);%Vector de poblaciones por ventana de video
      W(N(idxn)+1)=1;%Estado Inicial (0,0,0,0,...,1)
      tp=zeros(1,N(idxn)+1);%Vector de tiempos promedio por ventana
      wi=zeros(1,N(idxn)+1);%Vector de poblaciones para generar V.A.
      xi_prom=0;%Vector de poblaciones (downloaders) promedio
      t_prom=zeros(1,N(idxn)+1);%Vector de tiempo promedio por iteración
      TAb=zeros(1,N(idxn)+1);%Vector para tasa de abandono
      tao_mw=zeros(1,N(idxn));%Vector para tasa de abandono
            
      for iter=1:IT             
                
          %Caso estado (0,0,0,....,1)
          if W(1:N(idxn))==0%Arribo porque las poblaciones de 0 a N son 0 

             W(1)=W(1)+1;
             tp=tp+exprnd(lmb);
             
          %Caso estado ~= (0,0,0,....,1)
          else %Determinar evento porque las poblaciones de 0 a N son ~=0
             
             %Generar tasas de arribo y abandono por ventana
             TArr=1/lmb;%Tasa promedio de arribo a la ventana 0
             TAb=teta(idxt)*W(1:N(idxn));%Tasas promedio de abando de la ventana 0 a N-1

             %Tasa de abandono para seeds
             if 2<= W(N(idxn)+1)
                TAb(N(idxn)+1)=gamma*(W(N(idxn)+1)-1);
             else
                TAb(N(idxn)+1)=inf;
             end

             %Tranferencia para usuarios en ventanas 0 a N-2        
             tao_cw=cw*W(1:N(idxn)-1);%Tasa promedio de descarga en abundancia
             
             for i=1:N(idxn)-1
                 for k=i+1:N(idxn)
                     tao_mw(i)=tao_mw(i)+(mw*W(i)*(W(k)/sum(W(1:k-1))));%Tasa promedio de descarga en penuria
                 end
                 tao_mw(i)=tao_mw(i)+(W(N(idxn)+1)/sum(W(1:N(idxn))));
             end

             %Transferencia para usuarios en ventana N-1
             tao_cw(N(idxn))=cw*W(N(idxn));%Tasa promedio de descarga en abundancia        
             tao_mw(N(idxn))=mw*W(N(idxn))*(W(N(idxn)+1)/sum(W(1:N(idxn))));%Tasa promedio de descarga en penuria

             %Tiempos infinitos para descartar un abandono o transferencia
             %inválida
             
             for idxab=1:N(idxn)+1%Cambir el vector a infinitos para descartar poblaciones en 0
                if(TAb(idxab)==0)
                    tab(idxab)=inf;
                else
                    tab(idxab)=TAb(idxab);
                end
             end
             
             for idxtao=1:N(idxn)%Cambir el vector a infinitos para descartar poblaciones en 0
                if(tao_cw(idxtao)==0)
                    Rtao_cw(idxtao)=inf;
                else
                    Rtao_cw(idxtao)=tao_cw(idxtao);
                end
             end
             
             for idxtao=1:N(idxn)%Cambir el vector a infinitos para descartar poblaciones en 0
                if(tao_mw(idxtao)==0)
                    Rtao_mw(idxtao)=inf;
                else
                    Rtao_mw(idxtao)=tao_mw(idxtao);
                end
             end
             
             %Obtener V.A con las tasas de arribo, abandono y transferencia
             tao_min=min(Rtao_cw,Rtao_mw);%Tasa promedio de descarga en la ventana i

             VEArr=exprnd(TArr);%V.A para arribos
             ab=exprnd(1./TAb);%Vector de V.As para abandonos
             VEAb=min(ab);% Obtener minimo de ab
             tran=exprnd(1./tao_min);%Vector de V.As para transferencias
             VETao=min(tran);% Obtener minimo de tran

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
             %Acumular las poblaciones de downloaders y seeds por cada
             %iteración
             xi_prom=xi_prom+(sum(W(1:N(idxn)))*Evfinal);
             t_prom=t_prom+tp;
          end          
      end
         %Obtener los promedios de seeds y downloaders para distintos
         %valores  de N y teta 
         x_prom(idxn,idxt)=xi_prom/sum(t_prom);
         T_prom(idxn,idxt)=mean(t_prom);
   end        
end
     
figure(1)
surf(teta,N,x_prom,'FaceAlpha',0.5)
yticks([24:12:96])
xlabel('x10^{-3}           \theta')
ylabel('N')
zlabel('x')
title('Número de leeches en equilibrio')

figure(2)
surf(teta,N,T_prom,'FaceAlpha',0.5)
yticks([24:12:96])
xlim([min(teta) max(teta)])
