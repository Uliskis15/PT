clear all
close all

%Declaración de Variables

C=[24];% Número de ventanas
teta=[2].*(10^-3);%Tasa de abandono general
lmb=0.04;%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu=0.00255;%Tasa de subida general
X_prom=zeros(length(C),length(teta));%Matriz de downloaders promedio
IT=100000;%Número de iteraciones

for idxc=1:length(C)
        
   for idxt=1:length(teta)        
      
      cw=C(idxc)*c;%Tasa de descarga máxima
      mw=C(idxc)*mu;%Tasa de subida de los peers
      ms=[0 10 20 40].*mw;%Tasa de subida de los servidores
      BW=zeros(length(ms),C(idxc));%Cadena acumulativa para obtener el promedio por iteración
      BWP2P=zeros(length(ms),C(idxc));%Cadena acumulativa para obtener el promedio por iteración
      BWSer=zeros(length(ms),C(idxc));%Cadena acumulativa para obtener el promedio por iteración
      
      for idxms=1:length(ms)
          
          Pw=0.5*cw;%Tasa de producción del video
          teta0=(teta+Pw);%Tasa de abandono para usuarios en ventana 0
          HV=zeros(1,C(idxc)+1);%Vector de poblaciones por ventana de la hiperventana
          xi_prom=0;%Cadena acumulativa para obtener el promedio por iteración
          x_prom=0;%Cadena acumulativa para obtener el promedio por iteración
          tp=0;%Vector de tiempos promedio por ventana
          TAb=zeros(1,C(idxc)+1);%Vector para tasa de abandono
          tab=zeros(1,C(idxc)+1);%Vector para tasa de abandono
          tao_cw=zeros(1,C(idxc));%Vector para tasa de descarga
          ttran=zeros(1,C(idxc));%Vector para tasa de producción
          TProd=zeros(1,C(idxc));%Vector para tasa de transferencia inferior
          TTran=zeros(1,C(idxc));%Vector para tasa de transferencia superior
          tiempotran=0;
          

          for iter=1:IT   
              tao_mw=zeros(1,C(idxc));%Vector para tasa de transición peers
              tao_serv=zeros(1,C(idxc));%Vector para tasa de transición servidores

              %Caso estado (0,0,0,....,0)
              if HV(1:C(idxc))==0%Arribo porque las poblaciones de 0 a C+1 son 0 
                 HV(1)=HV(1)+1;
                 tp=tp+exprnd(1/lmb);      
              %Caso estado ~= (0,n,0,....,n)
              else%Determinar evento porque las poblaciones de 0 a C+1 son ~=0

                 %Generar tasas de arribo, abandono y transferencia a la ventana inferior por ventana
                 TArr=1/lmb;%Tasa promedio de arribo a la ventana 0
                 TAb(1)=teta0*HV(1);%Tasa promedio de abandono de la ventana 0
                 TAb(2:C(idxc)+1)=teta(idxt)*HV(2:C(idxc)+1);%Tasa promedio de abandono de la ventana 1 a C+1
                 ttran=Pw*HV(2:C(idxc)+1);%Tasa promedio de producción de la ventana 2 a la ventana C+1             

                 %Tranferencia para usuarios en ventanas 0 a C-1
                 tao_cw(1:C(idxc))=cw*HV(1:C(idxc));%Tasa promedio de descarga en abundancia

                 for i=1:C(idxc)
                     if HV(i)==0
                         tao_mw(i)=1000000;
                     else
                         for k=i+1:C(idxc)+1
                             tao_mw(i)=tao_mw(i)+(mw*HV(i)*(HV(k)/sum(HV(1:k-1))));%Tasa promedio de descarga en penuria
                         end
                         tao_mw(i)=tao_mw(i);
                     end           
                 end

                 for i=1:C(idxc)
                     if HV(i)==0
                         tao_serv(i)=1000000;
                     else
                         tao_serv(i)=tao_serv(i)+ms(idxms)*(HV(i)/sum(HV(1:C(idxc))));
                     end           
                 end
                 TAO_MW=tao_mw+tao_serv;

                 tao_min=min(tao_cw,TAO_MW);%Tasa promedio de descarga en la ventana i

                 %Obtener V.A con las tasas de arribo, abandono,
                 %producción(tranferencia inferior) y transferencia superior            

                 VEArr=exprnd(TArr);%V.A para arribos
                 ab=exprnd(1./TAb);%Vector de V.A para abandonos
                 prod=exprnd(1./ttran);%Vector de V.A para tranferencias inferiores
                 tran=exprnd(1./tao_min);%Vector de V.A para transferencias superiores

                 %Tiempos infinitos para descartar un abandono o transferencia
                 %inválido             
                 for idxab=1:C(idxc)+1%Cambir el vector a infinitos para descartar poblaciones en 0
                     if(ab(idxab)==0)
                        tab(idxab)=1000000;
                     else
                        tab(idxab)=ab(idxab);
                     end
                 end
                 VEAb=min(tab);% Obtener minimo de ab

                 for idxpw=1:C(idxc)%Cambir el vector a infinitos para descartar poblaciones en 0
                     if(prod(idxpw)==0)
                        TProd(idxpw)=1000000;
                     else
                        TProd(idxpw)=prod(idxpw);
                     end
                 end
                 VEPw=min(TProd);% Obtener minimo de prod

                 for idxtao=1:C(idxc)%Cambir el vector a infinitos para descartar poblaciones en 0
                     if(tran(idxtao)==0)
                        TTran(idxtao)=1000000;
                     else
                        TTran(idxtao)=tran(idxtao);
                     end
                 end
                 VETao=min(TTran);% Obtener minimo de tran

                 %Obtener el evento que ocurrio
                 Evsucces1=min(VEArr,VEAb);
                 Evsucces2=min(VEPw,VETao);
                 Evfinal=min(Evsucces1,Evsucces2);

                 %Incrementar o decrementar la población de una ventana dependiendo 
                 %del evento ocurrido y de la ventana en donde ocurrio

                 if Evfinal==VEAb

                    idx=find(ab==VEAb);%Encontrar indice donde ab == VEAb
                    HV(idx)=HV(idx)-1;%Decrementar W en idx
                    tp=tp+VEAb;%Se suma el tiempo promedio a tp en idx

                 elseif Evfinal==VEArr

                    HV(1)=HV(1)+1;%Incrementar W en 1
                    tp=tp+VEArr;%Se suma el tiempo promedio a tp en 1

                 elseif Evfinal==VEPw
                    idx=find(prod==VEPw);%Encontrar indice donde ab == VEAb
                    HV(idx+1)=HV(idx+1)-1;%Decrementar W en idx
                    HV(idx)=HV(idx)+1;%Incrementar W en idx-1
                    tp=tp+VEPw;%Se suma el tiempo promedio a tp en idx

                 elseif Evfinal==VETao
                    idx=find(tran==VETao);%Encontrar indice donde ab == VEAb
                    HV(idx)=HV(idx)-1;%Decrementar W en idx
                    HV(idx+1)=HV(idx+1)+1;%Incrementar W en idx+1
                    tp=tp+VETao;%Se suma el tiempo promedio a tp en idx
                    tiempotran=tiempotran+VETao;
                    BW(idxms,:)=BW(idxms,:)+((tao_cw*VETao)/tiempotran);
                    for ind=1:C(idxc)
                        if tao_cw(ind)>TAO_MW(ind)
                           BWP2P(idxms,ind)=BWP2P(idxms,ind)+(tao_mw(ind)*VETao/tiempotran);
                           BWSer(idxms,ind)=BWSer(idxms,ind)+(tao_serv(ind)*VETao/tiempotran);
                        else
                           m=min(tao_cw(ind),tao_mw(ind));
                           BWP2P(idxms,ind)=BWP2P(idxms,ind)+(m*VETao/tiempotran);
                           BWSer(idxms,ind)=BWSer(idxms,ind)+((tao_cw(ind)-(m*VETao))/tiempotran);
                        end
                    end
                 end
                 xi_prom=xi_prom+(HV(1:C(idxc)+1)*Evfinal); 
              end          
          end 
          x_prom=xi_prom/tp;

             %Obtener los promedios de seeds y downloaders para distintos
             %valores  de N y teta 
    %          X_prom(idxc,idxt)=x_prom;

      end   

   end        
end
figure(1)
G1=surf(transpose(BW),'FaceColor',[0 0.4470 0.7410],'FaceAlpha',0.5);
hold on
G2=surf(transpose(BWP2P),'FaceColor',[0.4940 0.1840 0.5560],'FaceAlpha',0.5);
G3=surf(transpose(BWSer),'FaceColor',[0.6350 0.0780 0.1840],'FaceAlpha',0.5);
% xticks([12:4:36])
% yticks([0.002:0.001:0.01])
%zticks([0:2:20])
%zlim([0 20])
%legend([G1 G2 G3],{'\mu_s=0 C\omega','P\omega=0.5C\omega','P\omega=0.8C\omega'})
ylabel('C')
xlabel('\mu_s')
zlabel('BW')
title('Ancho de Banda Consumido')
hold off


