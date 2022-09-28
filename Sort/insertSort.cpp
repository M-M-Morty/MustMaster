#include <iostream>
#include <vector>


void insertSort(std::vector<int>& v)
{
    for(int i=1;i<v.size();++i)
    {
        int InSertValue=v[i],InsertIndex=i;
        for(;InsertIndex>0&&v[InsertIndex-1]>InSertValue;--InsertIndex)
        {
            v[InsertIndex]=v[InsertIndex-1];
        }
        v[InsertIndex]=InSertValue;
    }
}



int main()
{
    std::vector<int> v{};
    v.resize(10000);
    for(int i=0;i<10000;++i)
    {
        v[i]=rand();
    }
    insertSort(v);
    for(const auto& i:v )
    {
        std::cout<<i<<' ';
    }
}