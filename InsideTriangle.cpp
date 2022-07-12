#include<iostream>
#include<math.h>

//方法1：面积法
//若点p在三角形ABC内，则三角形ABP的面积+三角形BCP的面积和三角形CAP的面积=三角形ABC的面积
//面积公式:S=(1/2)*|((x2-x1)*(y3-y1))-(x3-x1)*(y2-y1))|

const float eps=0.00001;

struct Point
{
    float x;
    float y;

    Point(){};
    Point(float x_,float y_)
    {
        x=x_;
        y=y_;
    };
    
};

//根据三个顶点的坐标计算三角形的面积
float GetTriangleSquar(const Point pA,const Point pB,const Point pC)
{
    Point AB,BC;
    AB.x=pA.x-pB.x;
    AB.y=pA.y-pB.y;
    BC.x=pB.x-pC.x;
    BC.y=pB.y-pC.y;

    return fabs((AB.x*BC.y-AB.y*BC.x))/2.0f;
}

bool IsInTriangle(const Point A,const Point B,const Point C,const Point D)
{
    float SABC,SADB,SADC,SBDC;
    SABC=GetTriangleSquar(A,B,C);
    SADB=GetTriangleSquar(A,D,B);
    SADC=GetTriangleSquar(A,D,C);
    SBDC=GetTriangleSquar(B,D,C);

    float SumSquar=SADB+SADC+SBDC;

    if(fabs(SABC-SumSquar)<eps)
    {
        return true;
    }
    else
    {
        return false;
    }
}

int main()
{
    Point A(-1,0),B(1,0),C(0,1),D(0,0.5);
    std::cout<<IsInTriangle(A,B,C,D);
}