#pragma once
#include<iostream>

template <typename T,std::size_t Nm>

struct my_array
{
    typedef T                value_type;
    typedef T*               pointer;
    typedef value_type*       iterator;

    value_type* M_instance[Nm?Nm:1]

    iterator begin() {return (&M_instance[0]);}

    iterator end() {return (&M_instance[_Nm]);}
};
