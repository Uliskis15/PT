clear all
close all

%Declaración de Variables

N=[96 84 72 60 48 36 24];% Número de ventanas
teta=[2 4 6 8 10].^-3;%Tasa de abandono general
lmb=0.04;%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu=0.00255;%Tasa de subida general
gamma=0.006;%Tasa de abandono general de los seeds
X_prom=zeros(length(N),length(teta));%Matriz de downloaders promedio
Y_prom=zeros(length(N),length(teta));%Matriz de seeds promedio
IT=10000;

for idxn=1:length(N)
        
   for idxt=1:length(teta) 
            
      cw=N(idxn)*c;%Tasa de descarga máxima
      mw=N(idxn)*mu;%Tasa de subida máxima
      W=zeros(1,N(idxn)+1);%Vector de poblaciones por ventana de video
      W(N(idxn)+1)=1;%Estado Inicial (0,0,0,0,...,1)
      wi_prom=0;%Cadena acumulativa para obtener el promedio por iteración 
      yi_prom=0;%Vector de seeds promedio
      tp=0;%Vector de tiempos promedio por ventana
      TAb=zeros(1,N(idxn)+1);%Vector para tasa de abandono
      tab=zeros(1,N(idxn)+1);%Vector para tasa de abandono
      tao_mw=zeros(1,N(idxn));%Vector para tasa de abandono
      TTran=zeros(1,N(idxn));%Vector para tasa de abandono
            
      for iter=1:IT
          
          %Caso estado (0,0,0,....,1)
          if W(1:N(idxn))==0%Arribo porque las poblaciones de 0 a N son 0 
             W(1)=W(1)+1;
             tp=tp+exprnd(1/lmb);      
          %Caso estado ~= (0,0,0,....,1)
          else%Determinar evento porque las poblaciones de 0 a N son ~=0
              
              %Generar tasas de arribo y abandono por ventana
              TArr=1/lmb;%Tasa promedio de arribo a la ventana 0
              TAb=teta(idxt)*W(1:N(idxn));

              %Abandono para seeds
              Si=W(N(idxn)+1);
              if Si >= 2
                 TAb(N(idxn)+1)=gamma*(Si-1);
              else
                 TAb(N(idxn)+1)=inf;
              end

              %Tranferencia para usuarios en ventanas 0 a N-2        
              tao_cw=cw*W(1:N(idxn));%Tasa promedio de descarga en abundancia

              for i=1:N(idxn)-1
                  for k=i+1:N(idxn)
                         tao_mw(i)=tao_mw(i)+(mw*W(i)*(W(k)/sum(W(1:k-1))));%Tasa promedio de descarga en penuria
                  end
                  tao_mw(i)=tao_mw(i)+(W(N(idxn)+1)/sum(W(1:N(idxn))));
              end

              %Tranferencia para usuarios en ventana N-1      
              tao_mw(N(idxn))=mw*W(N(idxn))*(W(N(idxn)+1)/sum(W(1:N(idxn)-1)));%Tasa promedio de descarga en penuria

              %Obtener V.A con las tasas de arribo, abandono y transferencia
              tao_min=min(tao_cw,tao_mw);%Tasa promedio de descarga en la ventana i

              VEArr=exprnd(TArr);%V.A para arribos
              ab=exprnd(1./TAb);%Vector de V.As para abandonos
              tran=exprnd(1./tao_min);%Vector de V.As para transferencias

              %Tiempos infinitos para descartar un abandono o transferencia
              %inválida             
              for idxab=1:N(idxn)+1%Cambir el vector a infinitos para descartar poblaciones en 0
                  if(ab(idxab)==0)
                     tab(idxab)=inf;
                  else
                     tab(idxab)=ab(idxab);
                  end
              end
              VEAb=min(tab);% Obtener minimo de ab

              for idxtao=1:N(idxn)%Cambir el vector a infinitos para descartar poblaciones en 0
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
                wi_prom=wi_prom+(sum(W(1:N(idxn)))*Evfinal);
                yi_prom=yi_prom+(W(N(idxn)+1)*Evfinal);
          end
          w_prom=wi_prom/tp;
          y_prom=yi_prom/tp;          
      end
         %Obtener los promedios de seeds y downloaders para distintos
         %valores  de N y teta 
         X_prom(idxn,idxt)=w_prom;
         Y_prom(idxn,idxt)=y_prom;
   end        
end
     
figure(1)
surf(N,teta,transpose(X_prom),'FaceAlpha',0.5)
xticks([24:12:96])
ylabel('x10^{-3}           \theta')
xlabel('N')
zlabel('x')
title('Número de leeches en equilibrio')

figure(2)
surf(N,teta,transpose(Y_prom),'FaceAlpha',0.5)
xticks([24:12:96])
ylabel('x10^{-3}           \theta')
xlabel('N')
zlabel('y')
title('Número de seeds en equilibrio')
