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
