#pragma once

#include<iostream>

template<typename T>
class my_shared_ptr
{
private:
    T* ptr;//底层真实的指针
    int* use_count;//记录对象被几个指针引用

public:
    explicit my_shared_ptr(T* p);//需要一个参数的构造函数
    my_shared_ptr(const my_shared_ptr<T>& orig);//拷贝构造函数
    my_shared_ptr<T>& operator=(const my_shared_ptr<T>& rhs);//拷贝赋值函数
    ~my_shared_ptr();//析构函数

    T operator*();
    T* operator->();
    T* operator+(int i);
    template<typename u>
    friend int operator-(my_shared_ptr<u>& t1,my_shared_ptr<u>& t2);

    int getcount()
    {
        return * use_count;
    }
};

template<typename T>
T my_shared_ptr<T>::operator*()
{
    return *ptr;
}

template<typename T>
T* my_shared_ptr<T>::operator->()//该对象返回底层指针后后面仍会加上->,方便引用对象成员
{
    return ptr;
}

template<typename T>
T* my_shared_ptr<T>::operator+(int i)
{
    T* tmp=ptr+i;
    return tmp;
}


template<typename T>
my_shared_ptr<T>::my_shared_ptr(T* p)
{
    ptr=p;
    try
    {
        use_count=new int(1);
    }
    catch(const std::exception& e)
    {
        std::cerr << e.what() << '\n';
        delete ptr;
        ptr=nullptr;
        delete use_count;
        use_count=nullptr;
    }
}

template<typename T>
my_shared_ptr<T>::my_shared_ptr(const my_shared_ptr<T>& orig)
{
    use_count=orig.use_count;
    ptr=orig.ptr;
    ++(*use_count);
}

template<typename T>
 my_shared_ptr<T>& my_shared_ptr<T>::operator=(const my_shared_ptr<T>& rhs)
 {
     if(--(*use_count)==0)
     {
         delete ptr;
         ptr=nullptr;
         delete use_count;
         use_count=nullptr;
     }
     ptr=rhs.ptr;
     use_count=rhs.use_count;
     ++(*use_count);
 }

 template<typename T>
 my_shared_ptr<T>::~my_shared_ptr()
 {
     if(--(*use_count)==0)
     {
         delete ptr;
         ptr=nullptr;
         delete use_count;
         use_count=nullptr;
     }
 }

template<typename u>
int operator-(my_shared_ptr<u>& t1,my_shared_ptr<u>& t2)
{
    return t1.ptr-t2.ptr;
}
