clear all
close all

%Declaración de Variables

C=[36 32 28 24 20 16 12];% Número de ventanas
teta=[2 4 6 8 10].*(10^-3);%Tasa de desconexión general
lmb=0.04;%Tasa de conexión 
c=0.00407;%Tasa de descarga general
mu=0.00255;%Tasa de subida general
ms=1.24;%Tasa de subida red CDN
X_prom=zeros(length(C),length(teta));%Matriz de downloaders promedio
CX_prom=zeros(length(C),length(teta));%Matriz de downloaders promedio
IT=1000000;%Número de iteraciones para la simulación

for idxc=1:length(C)
        
   for idxt=1:length(teta) 
            
      cw=C(idxc)*c;%Tasa de descarga promedio de un peer
      mw=C(idxc)*mu;%Tasa de subida promedio de un peer
      Pw=0.5*cw;%Tasa de producción del video
      teta0=(teta(idxt)+Pw);%Tasa de desconexión para peers en la ventana 0
      HV=zeros(1,C(idxc)+1);%Vector de poblaciones por ventana en la hiperventana
      xi_prom=0;%Acumulador para obtener poblaciones por iteración
      cxi_prom=0;%Acumulador para obtener poblaciones por iteración
      x_prom=0;%Variable para promediar las poblaciones por iteración
      cx_prom=0;%Variable para promediar las poblaciones por iteración
      bw_iter=zeros(1,C(idxc));%Variable de ancho de banda total consumido por iteración
      bwp2p_iter=zeros(1,C(idxc));%Variable de ancho de banda consumido de la red P2P por iteración
      bwserv_iter=zeros(1,C(idxc));%Variable de ancho de banda consumido de la red CDN por iteración
      tp=0;%Variable de tiempo de simulación}
      TArr=0;%Tasa de conexión de la población 0
      TAb=zeros(1,C(idxc)+1);%Tasa de desconexión de las poblaciones 0-C
      ttran=0;%Tasa de producción de video      
      tab=zeros(1,C(idxc)+1);%Desconexiones inválidas      
      tiempotran=0;%Tiempo promedio para consumo de ancho de banda
      
      for iter=1:IT  
          tao_mw=zeros(1,C(idxc));%Recursos peers
          tao_serv=zeros(1,C(idxc));%Recursos servidores
          tao_cw=zeros(1,C(idxc));%Tasa máxima de descarga
                    
          %Caso estado (0,0,0,....,0)
          if HV(1:C(idxc))==0%Conexión porque las poblaciones de 0 a C+1 son 0 
             HV(1)=HV(1)+1;%Incremento en una unidad de población en la ventana 0
             tp=tp+exprnd(1/lmb);%Tiempo de simulación en ese estado      
          %Caso estado ~= (0,n,0,....,n)
          else%Determinar que evento ocurrio porque las poblaciones de 0 a C+1 son ~=0
              
             %Generar tasas de conexión, desconexión, transferencia vii y transferencia VSI por ventana
             TArr=1/lmb;
             TAb(1)=teta0*HV(1);%Tasa de desconexión de la población en la ventana 0
             TAb(2:C(idxc)+1)=teta(idxt)*HV(2:C(idxc)+1);%Tasa de desconexión de las ventanas 1 a C
             ttran=1/Pw;%Producción de una nueva ventana             
             
             %Tranferencia para peers en ventanas 0 a C-1
             tao_cw(1:C(idxc))=cw*HV(1:C(idxc));%Tasa máxima de descarga de las poblaciones 0 a C-1
                   
             for i=1:C(idxc)
                 if HV(i)==0
                     tao_mw(i)=1000000;
                 else
                     for k=i+1:C(idxc)+1
                         tao_mw(i)=tao_mw(i)+(mw*HV(i)*(HV(k)/sum(HV(1:k-1))));%Recursos proporcionados por la red p2p
                     end
                 end           
             end
             
             for i=1:C(idxc)
                 if HV(i)==0
                     tao_serv(i)=1000000;
                 else
                     tao_serv(i)=tao_serv(i)+ms*(HV(i)/sum(HV(1:C(idxc))));%Recursos proporcionados por la red CDN
                 end           
             end
             TAO_MW=tao_mw+tao_serv;%Total de recursos para TVS
             
             tao_min=min(tao_cw,TAO_MW);%Tasa efectiva de descarga en la ventana i
         
             %Obtener V.A con las tasas de conexión, desconexión,
             %producción(tranferencia inferior) y transferencia superior            
    
             VEArr=exprnd(TArr);%V.A para las conexiones
             ab=exprnd(1./TAb);%V.A para las desconexiones
             VEPw=exprnd(ttran);%V.A para tranferencias inferiores
             tran=exprnd(1./tao_min);%V.A para transferencias superiores

             %Tiempos infinitos para descartar una desconexión 

             for idxab=1:C(idxc)+1%Cambir el vector a infinitos para descartar poblaciones en 0
                 if(ab(idxab)==0)
                    tab(idxab)=1000000;
                 else
                    tab(idxab)=ab(idxab);
                 end
             end
             VEAb=min(tab);% Obtener minimo de ab
             VETao=min(tran);% Obtener minimo de tran

             %Obtener el evento que ocurrio
             Evsucces1=min(VEArr,VEAb);%minimo entre la conexión y la desconexión
             Evsucces2=min(VEPw,VETao);%minimo entre la producción y la TVS
             Evfinal=min(Evsucces1,Evsucces2);%Evento final que ocurrio

             %Incrementar o decrementar la población de una ventana dependiendo 
             %del evento ocurrido y de la ventana en donde ocurrio

             if Evfinal==VEAb

                idx=find(ab==VEAb);%Encontrar indice donde ab == VEAb
                HV(idx)=HV(idx)-1;%Decrementar HV en idx
                tp=tp+VEAb;%Se suma la V.A del evento ocurrido a tp en idx

             elseif Evfinal==VEArr

                HV(1)=HV(1)+1;%Incrementar HV(1) en 1
                tp=tp+VEArr;%Se suma la V.A del evento ocurrido a tp en idx
                
             elseif Evfinal==VEPw
                for idx=1:C(idxc)%HV(a,b,d,C)->HV(b,d,C,0)
                    HV(idx)=HV(idx+1);
                end    
                HV(C(idxc)+1)=0;
                tp=tp+VEPw;%Se suma la V.A del evento ocurrido a tp en idx

             elseif Evfinal==VETao
                idx=find(tran==VETao);%Encontrar indice donde tran == VETao
                HV(idx)=HV(idx)-1;%Decrementar HV en idx
                HV(idx+1)=HV(idx+1)+1;%Incrementar HV en idx+1
                tp=tp+VETao;%Se suma la V.A del evento ocurrido a tp en idx
                tiempotran=tiempotran+VETao;
                bw_iter=bw_iter+(tao_cw*VETao);
                for ind=1:C(idxc)
                    if tao_cw(ind)>TAO_MW(ind)
                       bwp2p_iter(ind)=bwp2p_iter(ind)+(tao_mw(ind)*VETao);
                       bwserv_iter(ind)=bwserv_iter(ind)+(tao_serv(ind)*VETao);
                    else
                       m=min(tao_cw(ind),tao_mw(ind));
                       bwp2p_iter(ind)=bwp2p_iter(ind)+(m*VETao);
                       bwserv_iter(ind)=bwserv_iter(ind)+((tao_cw(ind)-m)*VETao);
                    end
                end
             end
             xi_prom=xi_prom+(sum(HV(1:C(idxc)+1))*Evfinal); 
             cxi_prom=cxi_prom+(HV(C(idxc)+1)*Evfinal); 
          end
      end 
      x_prom=xi_prom/tp;
      cx_prom=cxi_prom/tp;
     
         %Obtener los promedios de seeds y downloaders para distintos
         %valores  de N y teta 
          X_prom(idxc,idxt)=x_prom;
          CX_prom(idxc,idxt)=cx_prom;

   end        
end

figure(1)
surf(C,teta,transpose(X_prom),'FaceAlpha',0.5)
xticks([12:4:36])
yticks([0.002:0.001:0.01])
zlim([0 8])
ylabel('\theta')
xlabel('C')
zlabel('x')
title('Número de \itDownloaders Promedio')

figure(2)
surf(C,teta,transpose(CX_prom),'FaceAlpha',0.5)
xticks([12:4:36])
yticks([0.002:0.001:0.01])
zlim([0 2])
ylabel('\theta')
xlabel('C')
zlabel('x')
title('Número de \itDownloaders Promedio en la Ventana C')