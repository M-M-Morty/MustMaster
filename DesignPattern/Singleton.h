#include<iostream>
#include<mutex>
using namespace std;


//懒汉模式（线程不安全）:利用局部静态变量
template<typename T>
class SingleTon
{
public:
    static T& GetInstance()
    {
        static T ins;
        return ins;
    }
private:
    Singleton() =default;
    Singleton(const SingleTon& other);
    Singleton& operator=(const SingleTon& other);
};

//懒汉模式（线程不安全）:静态指针+用到时new
template<typename T>
class SingleTTon
{
public:
    
};


//懒汉模式（线程不安全，需要加锁）
class Singleton
{
public:
    static Singleton* GetInstance()
    {
        if(Instance==nullptr)
        {
            std::lock_guard<std::mutex> lock(mutex);
            if(Instance==nullptr)
            {
                Instance=new Singleton();
            }
        }
        return Instance;
    }
    void Destory()
    {
        if(Instance!=nullptr)
        {
            delete Instance;
            Instance=nullptr;
        }
    }

    //或者定义一个内部类并

private:
    Singleton()=default;
    ~Singleton()=default;

    Singleton(const Singleton&) =delete;
    Singleton& operator=(const Singleton&) =delete;
    
private:
    static Singleton* Instance;
    static std::mutex mutex;
};

Singleton* Singleton::Instance=nullptr;
std::mutex Singleton::mutex;


int main()
{
    SingleInstance* ins=SingleInstance::GetInstance();
    return 0;
}

