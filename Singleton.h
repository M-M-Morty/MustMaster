#include<iostream>
#include<mutex>
using namespace std;


//饿汉模式（本身线程安全）
class SingleInstance
{
public:
    static SingleInstance* GetInstance()
    {
        static SingleInstance ins;
        return &ins;
    }
    ~SingleInstance(){};
private:
    SingleInstance() =default;
    SingleInstance(const SingleInstance& other)=delete;
    SingleInstance& operator=(const SingleInstance& other)=delete;
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
    ~Singleton()=default;

    void Destory()
    {
        if(Instance!=nullptr)
        {
            delete Instance;
            Instance=nullptr;
        }
    }

private:
    Singleton()=default;

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

