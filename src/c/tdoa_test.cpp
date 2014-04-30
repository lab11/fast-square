//******************************************************************************
// C program for calculating x,y,z position of mobile given four satellite
// positions and TDOAs to mobile - TEST CASE 1
//******************************************************************************

#include <iostream>
#include <cmath>
using namespace std;

int main(){
double ti=67335898; double tk=86023981; double tj=78283279;  double tl=75092320;
double xi=0;        double xk=0;        double xj=-15338349; double xl=-18785564;
double yi=26566800; double yk=6380000;  double yj=15338349;  double yl=18785564;
double zi=0;        double zk=25789348; double zj=15338349;  double zl=0;

cout<<"ti = "<<ti<<endl;  cout<<"tj = "<<tj<<endl;  cout<<"tk = "<<tk<<endl;
cout<<"tl = "<<tl<<endl;  cout<<"xi = "<<xi<<endl;  cout<<"xj = "<<xj<<endl;
cout<<"xk = "<<xk<<endl;  cout<<"xl = "<<xl<<endl;  cout<<"yi = "<<yi<<endl;
cout<<"yj = "<<yj<<endl;  cout<<"yk = "<<yk<<endl;  cout<<"yl = "<<yl<<endl;
cout<<"zi = "<<zi<<endl;  cout<<"zj = "<<zj<<endl;  cout<<"zk = "<<zk<<endl;
cout<<"zl = "<<zl<<endl;

double xji=xj-xi; double xki=xk-xi; double xjk=xj-xk; double xlk=xl-xk;
double xik=xi-xk; double yji=yj-yi; double yki=yk-yi; double yjk=yj-yk;
double ylk=yl-yk; double yik=yi-yk; double zji=zj-zi; double zki=zk-zi;
double zik=zi-zk; double zjk=zj-zk; double zlk=zl-zk;

double rij=abs((100000*(ti-tj))/333564); double rik=abs((100000*(ti-tk))/333564);
double rkj=abs((100000*(tk-tj))/333564); double rkl=abs((100000*(tk-tl))/333564);

double s9 =rik*xji-rij*xki; double s10=rij*yki-rik*yji; double s11=rik*zji-rij*zki;
double s12=(rik*(rij*rij + xi*xi - xj*xj + yi*yi - yj*yj + zi*zi - zj*zj)
           -rij*(rik*rik + xi*xi - xk*xk + yi*yi - yk*yk + zi*zi - zk*zk))/2;

double s13=rkl*xjk-rkj*xlk; double s14=rkj*ylk-rkl*yjk; double s15=rkl*zjk-rkj*zlk;
double s16=(rkl*(rkj*rkj + xk*xk - xj*xj + yk*yk - yj*yj + zk*zk - zj*zj)
           -rkj*(rkl*rkl + xk*xk - xl*xl + yk*yk - yl*yl + zk*zk - zl*zl))/2;

double a= s9/s10; double b=s11/s10; double c=s12/s10; double d=s13/s14;
double e=s15/s14; double f=s16/s14; double g=(e-b)/(a-d); double h=(f-c)/(a-d);
double i=(a*g)+b; double j=(a*h)+c;
double k=rik*rik+xi*xi-xk*xk+yi*yi-yk*yk+zi*zi-zk*zk+2*h*xki+2*j*yki;
double l=2*(g*xki+i*yki+zki);
double m=4*rik*rik*(g*g+i*i+1)-l*l;
double n=8*rik*rik*(g*(xi-h)+i*(yi-j)+zi)+2*l*k;
double o=4*rik*rik*((xi-h)*(xi-h)+(yi-j)*(yi-j)+zi*zi)-k*k;
double s28=n/(2*m);     double s29=(o/m);       double s30=(s28*s28)-s29;
double root=sqrt(s30);        cout<<endl;
int z1=s28+root;              //cout<<"z1 = "<<z1 <<endl;
int z2=s28-root;              cout<<"z2 = "<<z2 <<endl;
int x1=g*z1+h;                //cout<<"x1 = "<<x1 <<endl;
int x2=g*z2+h;                cout<<"x2 = "<<x2 << endl;
int y1=a*x1+b*z1+c;           //cout<<"y1 = "<<y1 <<endl;
int y2=a*x2+b*z2+c;           cout<<"y2 = "<<y2 << endl;
}
