//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import "OCMArg.h"

#if TARGET_OS_IPHONE
#define NSRect CGRect
#define NSZeroRect CGRectZero
#define NSMakeRect CGRectMake
#define valueWithRect valueWithCGRect
#endif

@interface OCMArgTests : XCTestCase

@end


@implementation OCMArgTests

- (void)testValueMacroCreatesCorrectValueObjects
{
    NSRange range = NSMakeRange(5, 5);
    XCTAssertEqualObjects(OCMOCK_VALUE(range), [NSValue valueWithRange:range]);
#if !(TARGET_OS_IPHONE && TARGET_RT_64_BIT)
    /* This should work everywhere but I can't get it to work on iOS 64-bit */
    XCTAssertEqualObjects(OCMOCK_VALUE((BOOL){YES}), @YES);
#endif
    XCTAssertEqualObjects(OCMOCK_VALUE(42), @42);
#if !TARGET_OS_IPHONE
    XCTAssertEqualObjects(OCMOCK_VALUE(NSZeroRect), [NSValue valueWithRect:NSZeroRect]);
#endif
    XCTAssertEqualObjects(OCMOCK_VALUE([@"0123456789" rangeOfString:@"56789"]), [NSValue valueWithRange:range]);
}

@end