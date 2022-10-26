#include<cstdlib>
#include<iostream>
#include<cmath>

using namespace std;


class point
{
public:
    point(int x,inty):_x(x),_y(y){}
public:
    int _x;
    int _y;
};

float getRand()
{
    return rand()/RAND_MAX;
}

//诀窍在于对半径平方区随机数，可以解决随着半径越大，点出现的概率越小。
point randomPoint(int radius,point center)
{
    int rRadius=sqrt(getRand()*radius*radius);
    float rAngle=getRand()*360.0f;
    x=center.x+radius*cosf(rAngle);
    y=cneter.y+radius*sinf(r.Angle);

    return point(x,y);
}



int main()
{

}
