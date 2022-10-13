#include <iostream>
#include <vector>

void swap(int& first,int& second)
{
    int temp=first;
    first=second;
    second=temp;
}

void bubbleSort(std::vector<int>& v)
{
    for(int i=0;i<v.size()-1;++i)
    {
        for(int j=0;j<v.size()-1-i;++j)
        {
            if(v[j]>v[j+1])
            {
                swap(v[j],v[j+1]);
            }
        }
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
    bubbleSort(v);
    for(const auto& i:v )
    {
        std::cout<<i<<' ';
    }
}