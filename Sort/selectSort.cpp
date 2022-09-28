#include <iostream>
#include <vector>

void swap(int& first,int& second)
{
    int temp=first;
    first=second;
    second=temp;
}

void selectSort(std::vector<int>& v)
{
    for(int i=0;i<v.size()-1;++i)
    {
        int curruentMinIndex=i;
        for(int j=i+1;j<v.size();++j)
        {
            curruentMinIndex=v[j]<v[curruentMinIndex]?j:curruentMinIndex;
        }
        swap(v[curruentMinIndex],v[i]);
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
    selectSort(v);
    for(const auto& i:v )
    {
        std::cout<<i<<' ';
    }
}