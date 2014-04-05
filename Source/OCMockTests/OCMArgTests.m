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
#if defined(__GNUC__) && !defined(__STRICT_ANSI__)
    /* Should work with constant values and some expressions */
    XCTAssertEqualObjects(OCMOCK_VALUE(YES), @YES);
    XCTAssertEqualObjects(OCMOCK_VALUE(42), @42);
#if !TARGET_OS_IPHONE
    XCTAssertEqualObjects(OCMOCK_VALUE(NSZeroRect), [NSValue valueWithRect:NSZeroRect]);
#endif
    XCTAssertEqualObjects(OCMOCK_VALUE([@"0123456789" rangeOfString:@"56789"]), [NSValue valueWithRange:range]);
#endif
}

@end