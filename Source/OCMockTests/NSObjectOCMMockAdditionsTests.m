#import <XCTest/XCTest.h>
#import "NSObject+OCMMockAdditions.h"

#import "OCClassMockObject.h"
#import "OCPartialMockObject.h"
#import <objc/runtime.h>

@interface NSObjectOCMMockAdditionsTests : XCTestCase

@end

@implementation NSObjectOCMMockAdditionsTests

- (void)testMock
{
    OCClassMockObject *mockStr = [NSString mock];

    XCTAssertEqualObjects(@"OCMockObject[NSString]", [mockStr description], @"Should have received a mock of type OCClassMockObject and class NSString");
}

- (void)testNiceMock
{
    OCClassMockObject *mockStr = [NSString niceMock];

    XCTAssertEqualObjects(@"OCMockObject[NSString]", [mockStr description], @"Should have received a mock of type OCClassMockObject and class NSString");
    BOOL isNice;
    object_getInstanceVariable(mockStr, "isNice", (void*)&isNice);
    XCTAssertTrue(isNice, @"Expected mock to be nice");
}

- (void)testPartialMock
{
    OCPartialMockObject *mockStr = [NSString partialMock];
    
    XCTAssertEqualObjects(@"OCPartialMockObject[__NSCFConstantString]", [mockStr description], @"Should have received a mock of type OCPartialMockObject and class NSString");
}

@end
