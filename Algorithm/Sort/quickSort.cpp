#include <iostream>
#include <vector>
//假定排序后的数组从左到右依次递增，取第一个数为基准数，从最右往左遍历，找到第一个小于基准数的数据并复制到最左边；
//再从最左边往右遍历，找到第一个大于基准数的数组并复制到最右边，循环往复直至遍历完所有的数据，当前位置为基准数的中间位置。
int partition(std::vector<int>& arr, int low, int high) {
		int base = arr[low];
		while (low < high) {
			while (low < high && arr[high] >= base) --high;
			arr[low] = arr[high];
			while (low < high && arr[low] <= base) ++low;
			arr[high] = arr[low];
		}
		arr[low] = base;
		return low;
}

void mQuickSort(std::vector<int>&v,int low,int high)
{
    int mid=partition(v,low,high);
    if(low<mid-1) mQuickSort(v,low,mid-1);
    if(mid+1<high) mQuickSort(v,mid+1,high);
}

void quickSort(std::vector<int>& v)
{
    mQuickSort(v,0,v.size()-1);
}



int main()
{
    std::vector<int> v{};
    v.resize(10000);
    for(int i=0;i<10000;++i)
    {
        v[i]=rand();
    }
    quickSort(v);
    for(const auto& i:v )
    {
        std::cout<<i<<' ';
    }
}