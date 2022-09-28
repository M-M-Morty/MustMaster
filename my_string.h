#pragma once

#include<iostream>
#include<string>

#include<string.h>

class my_string
{
private:
    char* data;
    size_t len;
    void init_data(const char *s)
    {
        data=new char[len+1];
        memcpy(data,s,len);
        data[len]='\0';
    }
public:
    my_string():data(nullptr),len(0){}
    my_string(const char * p):len(strlen(p))
    {
        init_data(p);
    }
    my_string(const my_string& str)
    {
        init_data(str.data);
    }
    my_string(my_string&& str):data(str.data)
    {
        str.len=0;
        str.data=nullptr;
    }

    my_string& operator=(my_string& str)
    {
        if(this!=&str)//判断是否自我复制,否则会先delete自身,导致数据丢失
        {
            if(data) delete data; 
            len=str.len;
            init_data(str.data);
        }
        return *this;
    }
    
    my_string& operator=(my_string&& str)
    {
        if(this!=&str)
        {
            if(data) delete data;
            len=str.len;
            data=str.data;
            str.len=0;
            str.data=nullptr;
        }
        return *this;
    }

    virtual ~my_string()
    {
        if(data)
        {
            delete data;
        }
    }

    bool operator<(const my_string& rhs)const
    {
        return std::string(this->data)<std::string(rhs.data);//调用string自身的运算符重载函数
    }

    bool operator==(const my_string& rhs)const
    {
        return std::string(this->data)==std::string(rhs.data);
    }

    char* get()const {return data;}
} ;

namespace std//对hash类模板进行针对my_string类型的模板特化,返回此类型的hashcode值。
{
    template<>
    struct hash<my_string>
    {
        size_t
        operator()(const my_string& s) const noexcept
        {
            return hash<string>()(string(s.get()));
        }
    };
};