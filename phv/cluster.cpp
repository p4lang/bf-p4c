#include "cluster.h"
#include "lib/log.h"
#include "lib/stringref.h"
#include "base/logging.h"

bool Cluster::preorder(const IR::Member* expression) {
    // class Member : Operation_Unary
    // toString = expr->toString() + "." + member

    std::cout << ".....Member....." << expression->toString() << std::endl;
    return true;
}

bool Cluster::preorder(const IR::Operation_Unary* expression) {
    const PhvInfo::Field *expr = phv.field(expression->expr);

    std::cout << ".....Unary Operation....." << expression->toString()
	<< '(' << expression->expr->toString() << ')' << std::endl;
    if(expr) {
        std::cout << '(' << std::endl;
        std::cout << *expr;
        std::cout << ')' << std::endl;
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Binary* expression) {
    const PhvInfo::Field *left = phv.field(expression->left);
    const PhvInfo::Field *right = phv.field(expression->right);

    std::cout << ".....Binary Operation....." << expression->toString()
	<< '(' << expression->left->toString() << ',' << expression->right->toString() << ')' << std::endl;
    if(left || right)
    {
        std::cout << '(' << std::endl;
        if(left) std::cout << *left; else std::cout << '-' << std::endl;
        if(right) std:: cout << *right; else std::cout << '-' << std::endl;
        std::cout << ')' << std::endl;
    }

    return true;
}

bool Cluster::preorder(const IR::Operation_Ternary* expression) {
    const PhvInfo::Field *e0 = phv.field(expression->e0);
    const PhvInfo::Field *e1 = phv.field(expression->e1);
    const PhvInfo::Field *e2 = phv.field(expression->e2);

    std::cout << ".....Ternary Operation....." << expression->toString() 
	<< '(' << expression->e0->toString() << ',' << expression->e1->toString() << ',' << expression->e2->toString()
        << ')' << std::endl;
    if(e0 || e1 || e2)
    {
        std::cout << '(' << std::endl;
        if(e0) std::cout << *e0; else std::cout << '-' << std::endl;
        if(e1) std::cout << *e1; else std::cout << '-' << std::endl;
        if(e2) std::cout << *e2; else std::cout << '-' << std::endl;
        std::cout << ')' << std::endl;
    }

    return true;
}

bool Cluster::preorder(const IR::Operation* operation) {

    std::cout << ".....Operation....." << operation->toString() << std::endl;

    return true;
}
