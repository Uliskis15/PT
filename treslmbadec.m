clear all
close all

%Declaración de Variables

C=12;% Número de ventanas
teta=4*(10^-3);%Tasa de abandono general
lmb=[0.04 0.08 0.12];%Tasa de arribos 
c=0.00407;%Tasa de descarga general
mu=0.00255;%Tasa de subida general
teta0=3*(10^-3);%Tasa de abandono para usuarios en ventana 0
X_prom=zeros(length(lmb),C+1);%Matriz de downloaders promedio
IT=100000;%Número de iteraciones

cw=C*c;%Tasa de descarga máxima
mw=C*mu;%Tasa de subida máxima
Pw=0.3*cw;%Tasa de producción del video
xi_prom=0;%Cadena acumulativa para obtener el promedio por iteración
tp=0;%Vector de tiempos promedio por ventana
TAb=zeros(1,C+1);%Vector para tasa de abandono
tab=zeros(1,C+1);%Vector para tasa de abandono
tao_cw=zeros(1,C);%Vector para tasa de descarga
tao_mw=zeros(1,C);%Vector para tasa de subida
ttran=zeros(1,C);%Vector para tasa de producción
TProd=zeros(1,C);%Vector para tasa de transferencia inferior
TTran=zeros(1,C);%Vector para tasa de transferencia superior

for idxlmb=1:length(lmb)
    HV=zeros(1,C+1);%Vector de poblaciones por ventana de la hiperventana
    HV(C+1)=1;%Estado Inicial (0,0,0,0,...,1)
    for iter=1:IT
        %Caso estado (0,0,0,....,1)
        if HV(1:C)==0%Arribo porque las poblaciones de 0 a C son 0 
           HV(1)=HV(1)+1;
           tp=tp+exprnd(1/lmb(idxlmb));      
        %Caso estado ~= (0,0,0,....,1)
        else%Determinar evento porque las poblaciones de 0 a C son ~=0

        %Generar tasas de arribo, abandono y transferencia a la ventana inferior por ventana
           TArr=1/lmb(idxlmb);%Tasa promedio de arribo a la ventana 0
           TAb(1)=teta0*HV(1);%Tasa promedio de abandono de la ventana 0
           TAb(2:C)=teta*HV(2:C);%Tasa promedio de abandono de la ventana 1 a C
           ttran=Pw*HV(2:C);%Tasa promedio de producción de la ventana 2 a la ventana C

           Si=HV(C+1);%Población de la ventana C+1 
           %En caso que sea mayor a 2 puede ocurrir un abandono o una
           %transferencia a la ventana inferior. 
           if Si >= 2
              TAb(C+1)=teta*(Si-1);%Tasa de abandono de la ventana C+1
              ttran(C+1)=Pw*HV(C+1);%Tasa de producción de la ventana C+1
           else
              TAb(C+1)=inf;
              ttran(C+1)=inf;
           end

           %Tranferencia para usuarios en ventanas 0 a C-1
           tao_cw(1)=cw*HV(1);%Tasa promedio de descarga en abundancia
           tao_cw(2:C)=(cw-Pw)*HV(2:C);%Tasa promedio de descarga en abundancia


           for i=1:C
               for k=i+1:C
                   tao_mw(i)=tao_mw(i)+(mw*HV(i)*(HV(k)/sum(HV(1:k-1))));%Tasa promedio de descarga en penuria
               end
                   tao_mw(i)=tao_mw(i)+(HV(C+1)/sum(HV(1:C)));
           end


           %Obtener V.A con las tasas de arribo, abandono,
           %producción(tranferencia inferior) y transferencia superior
           tao_min=min(tao_cw,tao_mw);%Tasa promedio de descarga en la ventana i

           VEArr=exprnd(TArr);%V.A para arribos
           ab=exprnd(1./TAb);%Vector de V.A para abandonos
           prod=exprnd(1./ttran);%Vector de V.A para tranferencias inferiores
           tran=exprnd(1./tao_min);%Vector de V.A para transferencias superiores

           %Tiempos infinitos para descartar un abandono o transferencia
           %inválido             
           for idxab=1:C+1%Cambir el vector a infinitos para descartar poblaciones en 0
               if(ab(idxab)==0)
                  tab(idxab)=inf;
               else
                  tab(idxab)=ab(idxab);
               end
           end
           VEAb=min(tab);% Obtener minimo de ab

           for idxpw=1:C%Cambir el vector a infinitos para descartar poblaciones en 0
               if(prod(idxpw)==0)
                  TProd(idxpw)=inf;
               else
                  TProd(idxpw)=prod(idxpw);
               end
           end
           VEPw=min(TProd);% Obtener minimo de prod

           for idxtao=1:C%Cambir el vector a infinitos para descartar poblaciones en 0
               if(tran(idxtao)==0)
                  TTran(idxtao)=inf;
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
           end 
           %xi_prom=xi_prom+(sum(HV(1:C+1))*Evfinal);                
        end
           %HV
           %x_prom=(HV(1:C+1)*Evfinal)./tp;                    
    end
           %Obtener los promedios de seeds y downloaders para distintos
           %valores  de N y teta 
           X_prom(idxlmb,:)=HV(1:C+1)./tp;
           %disp('------');    
end

figure(1)
P11=plot(X_prom(1,:),'-.m');
hold on
P12=plot(X_prom(2,:),'-.r');
P13=plot(X_prom(3,:),'-.b');
xlim ([1 C+1]) 
ylim auto
grid on
xticks([0:2:C+1])
legend([P11 P12 P13],{'\lambda=0.04','\lambda=0.08','\lambda=0.12'})
xlabel('Número de Ventanas')
ylabel('Número de downloaders promedio')
hold off