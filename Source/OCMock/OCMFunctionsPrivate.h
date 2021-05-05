/*
 *  Copyright (c) 2014-2021 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <Foundation/Foundation.h>

@class OCMLocation;
@class OCClassMockObject;
@class OCPartialMockObject;


BOOL OCMIsClassType(const char *objCType);
BOOL OCMIsBlockType(const char *objCType);
BOOL OCMIsObjectType(const char *objCType);
const char *OCMTypeWithoutQualifiers(const char *objCType);
BOOL OCMEqualTypesAllowingOpaqueStructs(const char *type1, const char *type2);
CFNumberType OCMNumberTypeForObjCType(const char *objcType);
BOOL OCMIsNilValue(const char *objectCType, const void *value, size_t valueSize);

BOOL OCMIsAppleBaseClass(Class cls);
BOOL OCMIsApplePrivateMethod(Class cls, SEL sel);

Class OCMCreateSubclass(Class cls, void *ref);
BOOL OCMIsMockSubclass(Class cls);
void OCMDisposeSubclass(Class cls);

BOOL OCMIsAliasSelector(SEL selector);
SEL OCMAliasForOriginalSelector(SEL selector);
SEL OCMOriginalSelectorForAlias(SEL selector);

void OCMSetAssociatedMockForClass(OCClassMockObject *mock, Class aClass);
OCClassMockObject *OCMGetAssociatedMockForClass(Class aClass, BOOL includeSuperclasses);

void OCMSetAssociatedMockForObject(OCClassMockObject *mock, id anObject);
OCPartialMockObject *OCMGetAssociatedMockForObject(id anObject);

void OCMReportFailure(OCMLocation *loc, NSString *description);

BOOL OCMIsBlock(id potentialBlock);
BOOL OCMIsNonEscapingBlock(id block);

NSString *OCMObjCTypeForArgumentType(const char *argType);
BOOL OCMIsObjCTypeCompatibleWithValueType(const char *objcType, const char *valueType, const void *value, size_t valueSize);

struct OCMBlockDef
{
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;                 // NULL
        unsigned long int size;                     // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);  // IFF (1<<25)
        void (*dispose_helper)(void *src);          // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                      // IFF (1<<30)
    } *descriptor;
};

enum
{
    OCMBlockIsNoEscape                     = (1 << 23),
    OCMBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    OCMBlockDescriptionFlagsHasSignature   = (1 << 30)
};

/*
 * This attempts to generate a decent replacement string for old style ^(NSInvocation *) {} blocks.
 * It analyzes the method signature and the arguments passed to the invocation to attempt to
 * determine argument types and good names for the arguments.
 */
NSString *OCMBlockDeclarationForInvocation(NSInvocation *invocation);

/*
 * Return a suggested list of parameter names for a selector.
 * For example if the selector was `initWithName:forDog:` it would return `@[ @"name", @"dog" ]`.
 * If a good name cannot be determined, it will be `arg`. If there are multiple names that are the
 * same, they will be suffixed with a number, so selector `initWithThings::::` would return
 * `@[ @"things", @"arg0", @"arg1", @"arg2" ]`
 * Note this all works on heuristics based on standard Apple naming conventions. It doesn't
 * guarantee perfection.
 */
NSArray<NSString *> *OCMParameterNamesFromSelector(SEL selector);

/*
 * Given a selector segment like `initWithName`, splits it into words: `@[ @"init", @"With", @"Name" ]`
 * Normally splits on capital letters, but attemps to keep acronyms together, and plurals correct.
 * So `initWithURLsStartingWithHTTPAssumingTheyAreWebBased:` becomes
 * @[ @"init", @"With, @"URLs", @"Starting", @"With", @"HTTP", @"Assuming", @"They", @"Are", @"Web", @"Based"]
 * Doesn't have to be perfect, as it is a best effort to generate good API names.
 */
NSArray<NSString *> *OCMSplitSelectorSegmentIntoWords(NSString *string);

/*
 * Given a selector segment such as `initWithBigName:` attempts to deduce an
 * Objective C style parameter name for the segment (in this case `bigName`).
 * If it can't deal with it, returns an empty string.
 */
NSString *OCMTurnSelectorSegmentIntoParameterName(NSString *);

/*
 * Attempts to deduce a type for `obj` that could be put in a declaration
 * for a method containing obj. This is a best effort.
 */
NSString *OCMTypeOfObject(id obj);
