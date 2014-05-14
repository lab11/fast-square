function ret = TDOALoc4(anchor_loc, anchor_toas)
%Adapted from sample code in:
% Bucher, Ralph, and D. Misra. "A synthesizable vhdl model of the exact 
%   solution for three-dimensional hyperbolic positioning system." Vlsi 
%   Design 15.2 (2002): 507-520.

xi = anchor_loc(1,1);
xj = anchor_loc(2,1);
xk = anchor_loc(3,1);
xl = anchor_loc(4,1);
yi = anchor_loc(1,2);
yj = anchor_loc(2,2);
yk = anchor_loc(3,2);
yl = anchor_loc(4,2);
zi = anchor_loc(1,3);
zj = anchor_loc(2,3);
zk = anchor_loc(3,3);
zl = anchor_loc(4,3);

xji=xj-xi;
xki=xk-xi;
xjk=xj-xk;
xlk=xl-xk;
xik=xi-xk;
yji=yj-yi;
yki=yk-yi;
yjk=yj-yk;
ylk=yl-yk;
yik=yi-yk;
zji=zj-zi;
zki=zk-zi;
zik=zi-zk;
zjk=zj-zk;
zlk=zl-zk;

rij=abs((100000*(anchor_toas(1,:)-anchor_toas(2,:)))/333564); 
rik=abs((100000*(anchor_toas(1,:)-anchor_toas(3,:)))/333564);
rkj=abs((100000*(anchor_toas(3,:)-anchor_toas(2,:)))/333564); 
rkl=abs((100000*(anchor_toas(3,:)-anchor_toas(4,:)))/333564);

s9 =rik*xji-rij*xki; 
s10=rij*yki-rik*yji; 
s11=rik*zji-rij*zki;
s12=(rik*(rij*rij + xi*xi - xj*xj + yi*yi - yj*yj + zi*zi - zj*zj)...
           -rij*(rik*rik + xi*xi - xk*xk + yi*yi - yk*yk + zi*zi - zk*zk))/2;

s13=rkl*xjk-rkj*xlk; 
s14=rkj*ylk-rkl*yjk; 
s15=rkl*zjk-rkj*zlk;
s16=(rkl*(rkj*rkj + xk*xk - xj*xj + yk*yk - yj*yj + zk*zk - zj*zj)...
           -rkj*(rkl*rkl + xk*xk - xl*xl + yk*yk - yl*yl + zk*zk - zl*zl))/2;

a= s9/s10; 
b=s11/s10; 
c=s12/s10; 
d=s13/s14;
e=s15/s14; 
f=s16/s14; 
g=(e-b)/(a-d); 
h=(f-c)/(a-d);
i=(a*g)+b; 
j=(a*h)+c;
k=rik*rik+xi*xi-xk*xk+yi*yi-yk*yk+zi*zi-zk*zk+2*h*xki+2*j*yki;
l=2*(g*xki+i*yki+zki);
m=4*rik*rik*(g*g+i*i+1)-l*l;
n=8*rik*rik*(g*(xi-h)+i*(yi-j)+zi)+2*l*k;
o=4*rik*rik*((xi-h)*(xi-h)+(yi-j)*(yi-j)+zi*zi)-k*k;
s28=n/(2*m);%
s29=(o/m);%
s30=(s28*s28)-s29;%
root=sqrt(s30);%

ret = zeros(2,3);
ret(1,3) = s28+root;%
ret(2,3) = s28-root;%
ret(1,1) = g*ret(1,3)+h;%
ret(2,1) = g*ret(2,3)+h;%
ret(1,2) = a*ret(1,1)+b*ret(1,3)+c;%
ret(2,2) = a*ret(2,1)+b*ret(2,3)+c;%
keyboard;