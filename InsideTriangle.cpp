#include<iostream>
#include<math.h>
#include<stdio.h>

//方法1：面积法
//若点p在三角形ABC内，则三角形ABP的面积+三角形BCP的面积和三角形CAP的面积=三角形ABC的面积
//面积公式:S=(1/2)*|((x2-x1)*(y3-y1))-(x3-x1)*(y2-y1))|

const float eps=0.00001;

struct Vec2d
{
    float x;
    float y;

    Vec2d(){};
    Vec2d(float x_,float y_)
    {
        x=x_;
        y=y_;
    };
    
};

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
    
    Vec2d operator-(const Point& p)
    {
        return Vec2d(x-p.x,y-p.y);
    }
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

bool IsInsideTriangle1(const Point A,const Point B,const Point C,const Point D)
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

//方法2：叉乘法
//设三角形的三个点按照顺时针（或者逆时针）顺序是A,B,C。对于某一点P，求出三个向量PA,PB,PC。
//三个向量两两之间叉乘,结果为t1,t1,t3;若t1,t2,t3符号相同，则点在三角形内部，反之则不在。
float Cross_Product(Vec2d v1,Vec2d v2 )
{
    return v1.x*v2.y-v1.y*v2.x;
}

bool IsInsideTriangle2(Point A,Point B,Point C,Point P)
{
    Vec2d v1=A-P;
    Vec2d v2=B-P;
    Vec2d v3=C-P;
    float t1=Cross_Product(v1,v2);
    float t2=Cross_Product(v2,v3);
    float t3=Cross_Product(v3,v1);
    if(t1<0)
    {
        if(t2<=0&&t3<=0)return true;
        else return false;      
    }
    else
    {
        if(t2>=0&&t3>=0)return true;
        else return false; 
    }
}




//方法三：重心坐标
//对于三角形ABC内的任意一点P（包括边），存在这样三个数a,b,c使得
//P=a*A+b*B+c*C且a+b+c=1,0<=a<=1,0<=b<=1,0<=c<=1。
bool IsInsideTriangle3(Point A,Point B,Point C,Point P)
{
    float a=((A.y-C.y)*P.x+(C.x-A.x)*P.y+(A.x*C.y-C.x*A.y))/
            ((A.y-C.y)*B.x+(C.x-A.x)*B.y+(A.x*C.y-C.x*A.y));
    float b=((A.y-B.y)*P.x+(B.x-A.x)*P.y+(A.x*B.y-B.x*A.y))/
            ((A.y-B.y)*C.x+(B.x-A.x)*C.y+(A.x*B.y-B.x*A.y));
    if(a>=0&&a<=1&&b>=0&&b<=1&&(a+b)<=1) return true;
    return false;
}

int main()
{
    Point A(-1,0),B(1,0),C(0,1),D(-1,0.1);
    std::cout<<IsInsideTriangle1(A,B,C,D)<<std::endl;//方法1
    std::cout<<IsInsideTriangle2(A,B,C,D)<<std::endl;//方法2
    std::cout<<IsInsideTriangle3(A,B,C,D)<<std::endl;//方法3
} 

