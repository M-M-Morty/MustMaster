#include <iostream>
#include <memory>
#include <string>

class Product
{
public:
    virtual void show()=0;
};

class productA:public Product
{
    void show()override
    {
        std::cout<<"product A created!"<<std::endl;
    }
};

class productB:public Product
{
    void show()override
    {
        std::cout<<"product B created!"<<std::endl;
    }
};


class simpleFactory
{
public:
    enum PRODUCT_TYPE
    {
        A_PRODUCT,
        B_PRODUCT
    };

    Product* product(PRODUCT_TYPE type)
    {
        switch (type)
        {
        case PRODUCT_TYPE::A_PRODUCT:
            return new productA();
            break;
        case PRODUCT_TYPE::B_PRODUCT:
            return new productB();
            break;
        default:
            break;
        }
    }
};

int main()
{
    simpleFactory factory;
    Product* pro;
    pro=factory.product(simpleFactory::A_PRODUCT);
    pro->show();
    delete pro;

    pro=factory.product(simpleFactory::B_PRODUCT);
    pro->show();
    delete pro;

}