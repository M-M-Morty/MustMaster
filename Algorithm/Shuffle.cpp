#include<cstdio>
#include<cstdlib>
#include<vector>

void swqp(int& a,int& b)
{
    int tmp=a;
    a=b;
    b=tmp;
}

//在当前遍历的元素和最后一个元素之间随机选取一个数，并与第一个元素进行交换。
void RandomShuffle(vector<int>& v)
{
    if(v.size()==0) return;

    for(int i=0;i<v.size();i++)
    {
        int index=i+rand()%(n-i);
        swap(a[index],a[i]);
    } 
}


int main()
{

}
