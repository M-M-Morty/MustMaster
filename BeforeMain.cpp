#include<iostream>
#include<cstdio>
using std::cout;
using std::endl;

/*
(extern "C"
{
    _attribute((constructor))void before
    {
        printf("before main 1\n");
    }
}
*/

int test1()
{
    cout<<"before main 2"<<endl;
    return 1;
}

static int i=test1();

int a=[]()
{
    cout<<"before main 3"<<endl;
    return 0;
}();


int main(int argc,char** argv)
{
    cout<<"main function"<<endl;
    return 0;
}