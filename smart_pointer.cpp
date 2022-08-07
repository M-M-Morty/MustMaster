//#1可以充当资源引用的wrapper，通过栈空间，完成资源的自动释放
template <typename T>
class smart_ptr
{
public:
    explicit smart_ptr(T* ptr=nullptr)
        :ptr_(ptr){}
    ~smart_ptr()
    {
        delete ptr;
    }
    T* get(){return ptr_;}
private:
    T* ptr_;
};

//#2
template <typename T>
class smart_ptr
{
public:
    explicit smart_ptr(T* ptr=nullptr)
        :ptr_(ptr){}
    ~smart_ptr()
    {
        delete ptr;
    }
    T* get(){return ptr_;}

    T& operator* () const {return *ptr_;}
    T* operator-> () const {return ptr_;}
    operator bool() const {return ptr_;}//转成bool类型前调用的函数，例如在条件判断中
private:
    T* ptr_;
};
