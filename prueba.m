clear all
close all

A=[1 2 3 4];
r=0;
ms=1.24;

for i=1:length(A)
    k=length(A)/2;
    if i<=k
       r=r+A(i)*(-i);
    else
       r=r+A(i)*(i);
    end
end

for i=1:length(A)
    k=length(A)/2;
    if i<=k
       msi(i)=ms*A(i)*(-i)/r;
    else
       msi(i)=ms*A(i)*(i)/r;
    end
end
x=[1 2 3 4];


for i=1:length(A)
    k=length(A)/2;
    if i<=k
       msi(i)=msi(i)+abs(msi(2));
    else
       msi(i)=msi(i);
    end
end



plot(x,msi)