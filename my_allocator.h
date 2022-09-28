#pragma once

#include<new>        //for placement new
#include<cstddef>    //for ptrdiff_t,size_t
#include<cstdlib>    //for exit()
#include<climits>    //for UINT_MAX
#include<iostream>   //for cerr

namespace MY
{
template<typename T>
class allocator
{
public:
    typedef T           value_type;
    typedef T*          pointer;
    typedef const T*    const_pointer;
    typedef T&          reference;
    typedef const T&    const_reference;
    typedef size_t      size_type;//unsigned int 表示数量大小
    typedef ptrdiff_t   difference_type;//long int 通常用来保存两个指针减法操作的结果

pointer allocate(size_type n);

void deallocate(pointer p);

void construct(pointer p,const T& value);

void destory(pointer p);

pointer address(reference x){return (pointer)&x;}

const_pointer const_address(const_reference x){return (const_pointer)&x;}

size_type max_size() {return (UINT_MAX/sizeof(T))}
};

template<typename T>
inline T* allocate(size_t)
{
    T* tmp=::operator new(size_t*sizeof(T));
    if(tmp==0)
    {
        std::cerr<<"out of memory"<<std::endl;
        exit(1);
    }
    return tmp;
}

template<typename T>
inline void deallocate(T* p)
{
    ::operator delete(p);
}

template<typename T1,typename T2>
inline void construct(T1* p,const T2& value)
{
    new(p) T1(value);
}

template<typename T>
inline void destory(T* p)
{
    p->~T();
}

}