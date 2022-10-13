#include <assert.h>

char* strcpy(char* dest,const char* src)
{
    char* ret=dest;
    assert(dest!=NULL);
    assert(src!=NULL);
    while(*src!='\0')
        *(dest++)=*(src++);
    *dest='\0';
    return ret;
}

//考虑到内存重叠的字符串拷贝
char* strcpy(char* dest,const char* src)
{
    char* ret=dest;
    assert(dest!=NULL);
    assert(src!=NULL);
}

//字符串尾部拼接
char* strcat(char* dest,const char* src)
{
    char* ret=dest;
    assert(dest!=NULL);
    assert(src!=NULL);
    while(*dest!='\0')
        dest++;
    while (*src!='\0')
    {
        *(dest++)=*(src++);
    }
    *dest='\0';
    return ret; 
}

//字符串比较
int strcmp(const char* s1,const char* s2)
{
    assert(s1!=NULL);
    assert(s2!=NULL);
    while (*s1!='\0'&&*s2!='\0')
    {
        if(*s1>*s2)
            return 1;
        else if(*s1<*s2)
            return -1;
        else
        {
            s1++;
            s2++;
        }
    }
    if(*s1>*s2)
        return 1;
    else if(*s1<*s2)
        return -1;
    else
        return 0;  
}

//查找第一次出现的字符串
char* strstr(char* str1,char* str2)
{
    char* s=str1;
    assert(str1!='\0');
    assert(str2!='\0');
    if(*str2='\0')
        return NULL;
    while(*s!='\0')
    {
        char* s1=s;
        char* s2=str2;
        while (*s1!='\0'&&*s2!='\0'&&*s1==*s2)
            s1++,s2++;
        if(*s2=='\0')
            return s;
        if(*s2!='\0'&&*s1=='\0')
            return NULL;
        s++;
    } 
}

void* memcpy(void* dest,void* src,size_t num)
{
    void* ret=dest;
    size_t i=0;
    assert(src!=NULL);
    assert(dest!=NULL);
    for(i=0;i<num;i++)
    {
        *(char*)dest=*(char*)src;
        dest=(char*)dest+1;
        src=(char*)src+1;
    }
    return ret;
}

//考虑内存重叠的memcpy
void* memmov(void* dest,void* src,size_t num)
{
    char* p1=(char*)dest;
    char* p2=(char*)src;
    if(p1<p2)
    {
        for(size_t i=0;i!=num;++i)
            *(p1++)=*(p2++);
    }
    else
    {
        p1+=num-1;
        p2+=num-1;
        for(size_t i=0;i!=num;++i)
            *(p1--)=*(p2--);
    }
    return dest;
}