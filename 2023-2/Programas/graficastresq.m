clear all
close all

%Declaración de Variables

C=[36];% Número de ventanas
Q=[12 24 36];
teta=[2].*(10^-3);%Tasa de abandono general
lmb=0.04;%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu=0.00255;%Tasa de subida general
%ms=0.5;%Tasa de subida CDN
X_prom=zeros(length(C),length(teta));%Matriz de downloaders promedio
BW=zeros(length(Q),C);%Cadena acumulativa para obtener el promedio por iteración
BWP2P=zeros(length(Q),C);%Cadena acumulativa para obtener el promedio por iteración
BWSer=zeros(length(Q),C);%Cadena acumulativa para obtener el promedio por iteración
IT=1000000;%Número de iteraciones

for idxq=1:length(Q)
    for idxc=1:length(C)
        
       for idxt=1:length(teta) 

          cw=C(idxc)*c;%Tasa de descarga máxima
          mw=C(idxc)*mu;%Tasa de subida máxima
          ms=40*mw;
          Pw=0.5*cw;%Tasa de producción del video
          teta0=(teta+Pw);%Tasa de abandono para usuarios en ventana 0
          HV=zeros(1,C(idxc)+1);%Vector de poblaciones por ventana de la hiperventana
          xi_prom=0;%Cadena acumulativa para obtener el promedio por iteración
          x_prom=0;%Cadena acumulativa para obtener el promedio por iteración
          tp=0;%Vector de tiempos promedio por ventana
          TAb=zeros(1,C(idxc)+1);%Vector para tasa de abandono
          tab=zeros(1,C(idxc)+1);%Vector para tasa de abandono
          ttran=zeros(1,C(idxc));%Vector para tasa de producción
          TProd=zeros(1,C(idxc));%Vector para tasa de transferencia inferior
          TTran=zeros(1,C(idxc));%Vector para tasa de transferencia superior
          tiempotran=0;

          for iter=1:IT   
              tao_mw=zeros(1,C(idxc));%Vector para tasa de transición peers
              tao_serv=zeros(1,C(idxc));%Vector para tasa de transición servidores
              tao_cw=zeros(1,C(idxc));%Vector para tasa de descarga

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
                 ttran=1/Pw;%Tasa promedio de producción de la ventana 2 a la ventana C+1             

                 %Tranferencia para usuarios en ventanas 0 a C-1
                 tao_cw(1:C(idxc))=cw*HV(1:C(idxc));%Tasa promedio de descarga en abundancia

                 for i=1:C(idxc)
                     if HV(i)==0
                         tao_mw(i)=1000000;
                     else
                         ls=min(i+Q(idxq),C(idxc)+1);
                         for k=i+1:ls
                             tao_mw(i)=tao_mw(i)+(mw*HV(i)*(HV(k)/sum(HV(1:k-1))));%Tasa promedio de descarga en penuria
                         end
                         tao_mw(i)=tao_mw(i);
                     end           
                 end

                 for i=1:C(idxc)
                     if HV(i)==0
                         tao_serv(i)=1000000;
                     else
                         tao_serv(i)=tao_serv(i)+ms*(HV(i)/sum(HV(1:C(idxc))));
                     end           
                 end
                 TAO_MW=tao_mw+tao_serv;

                 tao_min=min(tao_cw,TAO_MW);%Tasa promedio de descarga en la ventana i

                 %Obtener V.A con las tasas de arribo, abandono,
                 %producción(tranferencia inferior) y transferencia superior            

                 VEArr=exprnd(TArr);%V.A para arribos
                 ab=exprnd(1./TAb);%Vector de V.A para abandonos
                 VEPw=exprnd(ttran);%Vector de V.A para tranferencias inferiores
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

    %              for idxpw=1:C(idxc)%Cambir el vector a infinitos para descartar poblaciones en 0
    %                  if(prod(idxpw)==0)
    %                     TProd(idxpw)=1000000;
    %                  else
    %                     TProd(idxpw)=prod(idxpw);
    %                  end
    %              end
    %              VEPw=min(TProd);% Obtener minimo de prod

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
                    for idx=1:C(idxc)
                        HV(idx)=HV(idx+1);%Decrementar W en i
                    end    
                    HV(C(idxc)+1)=0;
                    tp=tp+VEPw;%Se suma el tiempo promedio a tp en idx

                 elseif Evfinal==VETao
                    idx=find(tran==VETao);%Encontrar indice donde ab == VEAb
                    HV(idx)=HV(idx)-1;%Decrementar W en idx
                    HV(idx+1)=HV(idx+1)+1;%Incrementar W en idx+1
                    tp=tp+VETao;%Se suma el tiempo promedio a tp en idx
                    tiempotran=tiempotran+VETao;
                    BW(idxq,:)=BW(idxq,:)+(tao_cw*VETao);
                    for ind=1:C(idxc)
                        if tao_cw(ind)>TAO_MW(ind)
                           BWP2P(idxq,ind)=BWP2P(idxq,ind)+(tao_mw(ind)*VETao);
                           BWSer(idxq,ind)=BWSer(idxq,ind)+(tao_serv(ind)*VETao);
                        else
                           m=min(tao_cw(ind),tao_mw(ind));
                           BWP2P(idxq,ind)=BWP2P(idxq,ind)+(m*VETao);
                           BWSer(idxq,ind)=BWSer(idxq,ind)+((tao_cw(ind)-m)*VETao);
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
Bdc=[sum(BW(1,:)) sum(BW(2,:)) sum(BW(3,:))];
Bdcp2p=[sum(BWP2P(1,:)) sum(BWP2P(2,:)) sum(BWP2P(3,:))];
Bdcser=[sum(BWSer(1,:)) sum(BWSer(2,:)) sum(BWSer(3,:))];

figure(1)
plot(0:C-1,BW(1,:)/tiempotran,'b','LineWidth',1.5)
xlim([0 C])
hold on
plot(0:C-1,BW(2,:)/tiempotran,'m--','LineWidth',1)
plot(0:C-1,BW(3,:)/tiempotran,'c*','LineWidth',0.5)
hold off
legend('Q=12','Q=24','Q=36')
%xticks([0:2:C])
xlabel('C')
ylabel('Ventanas/segundo')
title('Ancho de Banda Total Consumido en el Sistema')

figure(2)
plot(0:C-1,BWP2P(1,:)/tiempotran,'b','LineWidth',1.5)
xlim([0 C])
hold on
plot(0:C-1,BWP2P(2,:)/tiempotran,'m--','LineWidth',1)
plot(0:C-1,BWP2P(3,:)/tiempotran,'c*','LineWidth',0.5)
hold off
legend('Q=12','Q=24','Q=36')
%xticks([0:2:36])
xlabel('C')
ylabel('Ventanas/segundo')
title('Ancho de Banda Consumido de la red P2P')

figure(3)
plot(0:C-1,BWSer(1,:)/tiempotran,'b','LineWidth',1.5)
xlim([0 C])
hold on
plot(0:C-1,BWSer(2,:)/tiempotran,'m--','LineWidth',1)
plot(0:C-1,BWSer(3,:)/tiempotran,'c*','LineWidth',0.5)
hold off
legend('Q=12','Q=24','Q=36')
%xticks([0:2:C])
xlabel('C')
ylabel('Ventanas/segundo')
title('Ancho de Banda Consumido de la red CDN')

figure(4)
plot(Bdc/tiempotran,'b-*','LineWidth',0.5)
xlim([1 3])
hold on
plot(Bdcp2p/tiempotran,'r--','LineWidth',0.5)
plot(Bdcser/tiempotran,'m','LineWidth',0.5)
hold off
legend('BDC','BWP2P','BWServ')
xticks([12 24 36])
xlabel('C')
ylabel('Ventanas/segundo')
title('Anchos de banda del Sistema')