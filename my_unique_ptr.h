#include<iostream>
using namespace std;

template<typename T>
class my_unique_ptr
{
public:
    explicit my_unique_ptr(T* ptr=nullptr):ptr(ptr){}
    my_unique_ptr(const my_unique_ptr&)=delete;
    my_unique_ptr(my_unique_ptr&& uptr):ptr(uptr.ptr)
    {
        uptr.ptr=nullptr;
    }

    my_unique_ptr& operator=(const my_unique_ptr& ptr)=delete;
    my_unique_ptr& operator=(my_unique_ptr&& uptr)
    {
        if(this!=&uptr)
        {
            if(ptr) delete ptr;
            ptr=uptr.ptr;
            uptr.ptr=nullptr;
        }
        return *this;
    }

    ~my_unique_ptr()
    {
        delete ptr;
    }

    T& operator*()
    {
        return *ptr;
    }

    T* operator->()
    {
        return &(operator*());
    }

    my_unique_ptr& operator++()
    {
        ++ptr;
        return *this;
    }

    my_unique_ptr operator++(int)
    {
        my_unique_ptr tmp=this;
        ++ptr;
        return tmp;
    }

    my_unique_ptr& operator+(int step)
    {
        ptr+=step;
        return *this;
    }

    void reset()
    {
        delete ptr;
    }
private:
    T* ptr;
};