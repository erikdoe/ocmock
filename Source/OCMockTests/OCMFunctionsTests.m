/*
 *  Copyright (c) 2020-2021 Erik Doernenburg and contributors
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

#import <OCMock/OCMockObject.h>
#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "OCMFunctions.h"
#import "OCMFunctionsPrivate.h"

@interface TestClassForFunctions : NSObject
- (void)setFoo:(NSString *)aString;
@end

@implementation TestClassForFunctions

- (void)setFoo:(NSString *)aString;
{
}

@end

@interface TestClassForSpecialEncodings : NSObject
@end

@implementation TestClassForSpecialEncodings

// Method declarations for testing old style Distributed Object (DO) type qualifiers.
- (void)methodWithInOut:(inout char *)foo
{
}

- (void)methodWithConst:(const char *)foo
{
}

- (void)methodWithIn:(in char *)foo
{
}

- (void)methodWithOut:(out char *)foo
{
}

- (void)methodWithByCopy:(bycopy id)foo
{
}

- (void)methodWithOutByCopy:(out bycopy id *)foo
{
}

- (void)methodWithByRef:(byref id)foo
{
}

- (oneway void)methodWithOneway
{
}

@end

@interface OCMFunctionsTests : XCTestCase
@end

@implementation OCMFunctionsTests

- (void)testObjCTypeWithoutQualifiers
{
    struct
    {
        SEL selector;
        const char *expected;
    } selectorExpectedMap[] =
    {
        {@selector(methodWithInOut:), "*"},  {@selector(methodWithConst:), "*"},
        {@selector(methodWithIn:), "*"},     {@selector(methodWithOut:), "*"},
        {@selector(methodWithByCopy:), "@"}, {@selector(methodWithOutByCopy:), "^@"},
        {@selector(methodWithByRef:), "@"},
    };

    Class classWithSpecialEncodings = [TestClassForSpecialEncodings class];
    for(int i = 0; i < sizeof(selectorExpectedMap) / sizeof(selectorExpectedMap[0]); ++i)
    {
        SEL selector = selectorExpectedMap[i].selector;
        Method method = class_getInstanceMethod(classWithSpecialEncodings, selector);
        XCTAssertNotEqual(method, NULL);
        char *encoding = method_copyArgumentType(method, 2);
        XCTAssertNotEqual(encoding, NULL);
        NSString *expectedString = [NSString stringWithUTF8String:selectorExpectedMap[i].expected];
        XCTAssertNotEqualObjects(expectedString, [NSString stringWithUTF8String:encoding],
                                 @"Selector: `%s` Encoding: `%s`", sel_getName(selector), encoding);
        XCTAssertEqualObjects(expectedString,
                              [NSString stringWithUTF8String:OCMTypeWithoutQualifiers(encoding)],
                              @"Selector: `%s` Encoding: `%s`", sel_getName(selector), encoding);
        free(encoding);
    }

    SEL selector = @selector(methodWithOneway);
    Method method = class_getInstanceMethod(classWithSpecialEncodings, selector);
    XCTAssertNotEqual(method, NULL);
    char *encoding = method_copyReturnType(method);
    XCTAssertNotEqual(encoding, NULL);
    XCTAssertNotEqualObjects(@"v", [NSString stringWithUTF8String:encoding],
                             @"Selector: `%s` Encoding: `%s`", sel_getName(selector), encoding);
    XCTAssertEqualObjects(@"v",
                          [NSString stringWithUTF8String:OCMTypeWithoutQualifiers(encoding)],
                          @"Selector: `%s` Encoding: `%s`", sel_getName(selector), encoding);
    free(encoding);
}

- (void)testIsBlockReturnsFalseForClass
{
    XCTAssertFalse(OCMIsBlock([NSString class]));
}

- (void)testIsBlockReturnsFalseForObject
{
    XCTAssertFalse(OCMIsBlock([NSArray array]));
}

- (void)testIsBlockReturnsFalseForNil
{
    XCTAssertFalse(OCMIsBlock(nil));
}

- (void)testIsBlockReturnsTrueForBlock
{
    XCTAssertTrue(OCMIsBlock(^ { }));
}

- (void)testIsMockSubclassOnlyReturnYesForActualSubclass
{
    id object = [TestClassForFunctions new];
    XCTAssertFalse(OCMIsMockSubclass([object class]));

    id mock __unused = [OCMockObject partialMockForObject:object];
    XCTAssertTrue(OCMIsMockSubclass(object_getClass(object)));

    // adding a KVO observer creates and sets a subclass of the mock subclass
    [object addObserver:self forKeyPath:@"foo" options:NSKeyValueObservingOptionNew context:NULL];
    XCTAssertFalse(OCMIsMockSubclass(object_getClass(object)));

    [object removeObserver:self forKeyPath:@"foo" context:NULL];
}

- (void)testIsSubclassOfMockSubclassReturnYesForSubclasses
{
    id object = [TestClassForFunctions new];
    XCTAssertFalse(OCMIsMockSubclass([object class]));

    id mock __unused = [OCMockObject partialMockForObject:object];
    XCTAssertTrue(OCMIsSubclassOfMockClass(object_getClass(object)));

    // adding a KVO observer creates and sets a subclass of the mock subclass
    [object addObserver:self forKeyPath:@"foo" options:NSKeyValueObservingOptionNew context:NULL];
    XCTAssertTrue(OCMIsSubclassOfMockClass(object_getClass(object)));

    [object removeObserver:self forKeyPath:@"foo" context:NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
}

@end
