#include "simplify_emit_args.h"
#include "bf-p4c/common/utils.h"
#include "bf-p4c/midend/path_linearizer.h"

namespace BFN {

void FlattenHeader::flattenType(const IR::Type* type) {
    if (auto st = type->to<IR::Type_StructLike>()) {
        allAnnotations.push_back(st->annotations);
        for (auto f : st->fields) {
            nameSegments.push_back(f->name);
            allAnnotations.push_back(f->annotations);
            flattenType(typeMap->getType(f, true));
            allAnnotations.pop_back();
            nameSegments.pop_back();
        }
        allAnnotations.pop_back();
    } else {  // primitive field types
        auto& newFields = flattenedHeader->fields;
        auto newName = makeName("_");
        auto origName = makeName(".");
        if (origName != newName) {
            LOG2("map " << origName << " to " << newName);
            fieldNameMap.emplace(origName, newName);
        }
        // preserve the original name using an annotation
        auto annotations = mergeAnnotations();
        newFields.push_back(new IR::StructField(IR::ID(newName), annotations, type));
    }
}

cstring FlattenHeader::makeName(cstring sep) const {
    cstring name = "";
    for (auto n : nameSegments) name += sep + n;
    /// removing leading separator
    name = name.substr(1);
    return name;
}

/// Merge all the annotation vectors in allAnnotations into a single
/// one. Duplicates are resolved, with preference given to the ones towards the
/// end of allAnnotations, which correspond to the most "nested" ones.
const IR::Annotations* FlattenHeader::mergeAnnotations() const {
    auto mergedAnnotations = new IR::Annotations();
    for (auto annosIt = allAnnotations.rbegin(); annosIt != allAnnotations.rend(); annosIt++) {
        for (auto anno : (*annosIt)->annotations) {
            // if an annotation with the same name was added previously, skip
            if (mergedAnnotations->getSingle(anno->name)) continue;
            mergedAnnotations->add(anno);
        }
    }
    return mergedAnnotations;
}

bool FlattenHeader::preorder(IR::Type_Header* headerType) {
    LOG3("visiting header " << headerType);
    flattenedHeader = headerType->clone();
    flattenedHeader->fields.clear();
    flattenType(headerType);
    headerType->fields = flattenedHeader->fields;
    return false;
}

cstring FlattenHeader::makeMember(cstring sep) const {
    cstring name = "";
    for (auto n = memberSegments.rbegin(); n != memberSegments.rend(); n++)
        name += sep + *n;
    /// removing leading separator
    name = name.substr(1);
    return name;
}

// The IR for member is structured as
// IR::Member
//   IR::Member
//     IR::Member
//       IR::PathExpression
// Suppose we would like to transform a path from hdr.meta.nested.field to
// hdr.meta.nested_field.
// The IR tree should be transformed to
// IR::Member
//   IR::Member
//     IR::PathExpression
void FlattenHeader::flattenMember(const IR::Member* member) {
    if (memberSegments.size() == 0) {
        flattenedMember = member;
    }
    memberSegments.push_back(member->member);
    if (auto mem = member->expr->to<IR::Member>()) {
        flattenMember(mem);
    }
    auto origName = makeMember(".");
    bool isHeader = member->expr->type->is<IR::Type_Header>();
    LOG3("   check " << (isHeader ? "header " : "struct ") << member->expr << " " << origName);
    if (!isHeader) {
        memberSegments.pop_back();
        return; }
    if (fieldNameMap.count(origName)) {
        const IR::Expression* header;
        if (member->expr->is<IR::PathExpression>())
            header = member->expr->to<IR::PathExpression>();
        else if (member->expr->is<IR::Member>())
            header = member->expr;
        else
            BUG("Unexpected member expression %1%", member->expr);
        auto field = fieldNameMap.at(origName);
        LOG3("     map " << flattenedMember->toString() <<
             " to " << "(" << header << ", " << field << ")");
        replacementMap.emplace(flattenedMember->toString(),
                std::make_tuple(header, field));
    }
    memberSegments.pop_back();
}

bool FlattenHeader::preorder(IR::Member* member) {
    LOG2("preorder "  << member);
    flattenMember(member);
    memberSegments.clear();
    return true;
}

void FlattenHeader::postorder(IR::Member* member) {
    auto mem = member->toString();
    LOG2("postorder " << mem);
    if (replacementMap.count(mem)) {
        LOG2("    replace " << member->expr <<
                "." << member->member <<
                " with " << std::get<0>(replacementMap.at(mem)) <<
                "." << std::get<1>(replacementMap.at(mem)));
        member->expr = std::get<0>(replacementMap.at(mem))->apply(cloner);
        member->member = std::get<1>(replacementMap.at(mem));
    }
}

bool FlattenHeader::preorder(IR::MethodCallExpression* mc) {
    auto method = mc->method->to<IR::Member>();
    if (!method || method->member != "emit") return false;

    auto dname = method->expr->to<IR::PathExpression>();
    if (!dname) return false;

    auto type = dname->type->to<IR::Type_Extern>();
    if (!type) return false;

    if (type->name != "Mirror" && type->name != "Resubmit"
        && type->name != "Digest") return false;

    // HACK(Han): after the P4-14 to TNA refactor, we should
    // derive these indices from the TNA model.
    // Assume the following syntax
    //   mirror.emit(session_id, field_list);
    //   mirror.emit(); - mirror without parameters
    //   resubmit.emit(field_list);
    //   resubmit.emit(); - resubmit without parameters
    //   digest.emit(field_list);
    //   digest.emit(); - digest without parameters
    int field_list_index = (type->name == "Mirror") ? 1 : 0;
    if (mc->arguments->size() == 0)
        return false;

    if (type->name == "Mirror" && mc->arguments->size() != 2) {
        return false;
    }

    auto* arg = mc->arguments->at(field_list_index);
    auto* aexpr = arg->expression;
    if (auto* liste = aexpr->to<IR::ListExpression>()) {
        LOG4("Flattening arguments: " << liste);
        auto* flattened_args = new IR::Vector<IR::Argument>();
        if (type->name == "Mirror")
            flattened_args->push_back(mc->arguments->at(0));
        flattened_args->push_back(new IR::Argument(flatten_list(liste)));
        mc->arguments = flattened_args;
        LOG4("Flattened arguments: " << mc);
    } else if (auto* liste = aexpr->to<IR::StructInitializerExpression>()) {
        LOG4("Flattening arguments: " << liste);
        auto* flattened_args = new IR::Vector<IR::Argument>();
        if (type->name == "Mirror")
            flattened_args->push_back(mc->arguments->at(0));
        auto flattenedList = doFlattenStructInitializer(liste);
        flattened_args->push_back(new IR::Argument(flattenedList));
        mc->arguments = flattened_args;
        LOG4("Flattened arguments: " << mc);
    } else {
        // do not try to simplify reference to header
    }
    return true;
}

void FlattenHeader::explode(const IR::Expression* expression,
    IR::Vector<IR::Expression>* output) {
    if (auto st = expression->type->to<IR::Type_Header>()) {
        for (auto f : st->fields) {
            auto e = new IR::Member(expression, f->name);
            LOG1("visit " << f);
            explode(e, output);
        }
    } else {
        BUG_CHECK(!expression->type->is<IR::Type_StructLike>() &&
            !expression->type->is<IR::Type_Stack>(),
                  "%1%: unexpected type", expression->type);
        output->push_back(expression);
    }
}

/**
 * The name scheme of flattened struct initializer expression is by
 * concatenating the parent name + field name + global count.
 *
 * We should clean up the frontend flattenHeaders pass to not
 * append a digit after each field.
 */
cstring FlattenHeader::makePath(cstring sep) const {
    cstring name = "";
    for (auto n : pathSegments) name += sep + n;
    name = name.substr(1);
    return name;
}

void FlattenHeader::flattenStructInitializer(
        const IR::StructInitializerExpression *expr,
        IR::IndexedVector<IR::NamedExpression> *components) {
    for (auto e : expr->components) {
        pathSegments.push_back(e->name);
        if (const auto* c = e->expression->to<IR::StructInitializerExpression>()) {
            flattenStructInitializer(c, components);
        } else {
            auto newName = makePath("_");
            auto namedExpression = new IR::NamedExpression(IR::ID(newName), e->expression);
            components->push_back(namedExpression);
        }
        pathSegments.pop_back();
    }
}

IR::StructInitializerExpression*
FlattenHeader::doFlattenStructInitializer(const IR::StructInitializerExpression* e) {
    // removing nested StructInitailzierExpression
    auto no_nested_struct = new IR::IndexedVector<IR::NamedExpression>();
    flattenStructInitializer(e, no_nested_struct);
    return new IR::StructInitializerExpression(e->name, *no_nested_struct, e->isHeader);
}

IR::ListExpression* FlattenHeader::flatten_list(const IR::ListExpression* args) {
    IR::Vector<IR::Expression> components;
    for (const auto* expr : args->components) {
        if (const auto* list_arg = expr->to<IR::ListExpression>()) {
            auto* flattened = flatten_list(list_arg);
            for (const auto* comp : flattened->components)
                components.push_back(comp);
        } else {
            components.push_back(expr);
        }
    }
    return new IR::ListExpression(components);
}

const IR::Node *EliminateEmitHeaders::preorder(IR::Argument *arg) {
    const IR::Type *type = nullptr;
    if (auto path = arg->expression->to<IR::PathExpression>()) {
        if (path->type->is<IR::Type_StructLike>())
            type = path->type->to<IR::Type_StructLike>();
        else
            return arg;
    } else if (auto mem = arg->expression->to<IR::Member>()) {
        if (mem->type->is<IR::Type_StructLike>())
            type = mem->type->to<IR::Type_StructLike>();
        else
            return arg; }

    if (!type) return arg;

    auto mc = findContext<IR::MethodCallExpression>();
    if (!mc) return arg;

    auto mi = P4::MethodInstance::resolve(mc, refMap, typeMap, true);
    if (auto em = mi->to<P4::ExternMethod>()) {
        if (em->actualExternType->name != "Digest" &&
            em->actualExternType->name != "Mirror" &&
            em->actualExternType->name != "Resubmit")
            return arg; }

    cstring type_name;
    bool isHeader;
    auto fieldList = IR::IndexedVector<IR::NamedExpression>();
    if (auto header = type->to<IR::Type_Header>()) {
        for (auto f : header->fields) {
            auto mem = new IR::Member(arg->expression, f->name);
            fieldList.push_back(new IR::NamedExpression(f->name, mem)); }
        type_name = header->name;
        isHeader = true;
    } else if (auto st = type->to<IR::Type_Struct>()) {
        for (auto f : st->fields) {
            auto mem = new IR::Member(arg->expression, f->name);
            fieldList.push_back(new IR::NamedExpression(f->name, mem)); }
        type_name = st->name;
        isHeader = false;
    } else {
        ::error(ErrorType::ERR_UNEXPECTED, " type as emit parameter %1%", arg);
    }

    if (fieldList.size() > 0)
        return new IR::Argument(arg->srcInfo,
                new IR::StructInitializerExpression(type_name, fieldList, isHeader));

    return arg;
}

}  // namespace BFN
