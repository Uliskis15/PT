clear all
close all

x=48;
a=0.1;
k=x/2;
m1=-a/k;
m2=a/k;

for i=1:x+1
    if i<=k
        y(i)=((i-1)*m1)+a;
    elseif i==k+1
        y(i)=0;
    else
        y(i)=((i-1)-k)*m2;
    end
end

plot([0:x],y,'m --','Linewidth',2);