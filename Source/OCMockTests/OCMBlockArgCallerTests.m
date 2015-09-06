//
//  OCMBlockArgCallerTests.m
//  OCMock
//
//  Created by Stephen Fortune on 06/09/2015.
//  Copyright (c) 2015 Mulle Kybernetik. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

struct OCMStruct {
    BOOL prop1;
    NSUInteger prop2;
};

typedef NSObject *OCMTypedefObj;
typedef struct OCMStruct OCMStructTypedef;
typedef BOOL (^OCMBlockTypedef)(NSString *);

@interface OCMStrangeTypes : NSObject 

- (void)doLotsOfParams:(void (^)(NSString *, NSString *, long, NSUInteger, double, NSNumber *, NSIndexPath *))longBlock;
- (void)doReturnValue:(NSString *(^)())returnBlock;
- (void)doInnerBlock:(void(^)(BOOL(^)(NSString *blockArg), OCMBlockTypedef))blockWithBlock;
- (void)doTypedef:(void(^)(OCMTypedefObj, OCMTypedefObj *))typedefBlock;
- (void)doStructs:(void(^)(struct OCMStruct, OCMStructTypedef, struct OCMStruct *, OCMStructTypedef *))structBlock;
- (void)doVoidPtr:(void(^)(void *))voidPtrBlock;

@end

@implementation OCMStrangeTypes

- (void)doLotsOfParams:(void (^)(NSString *, NSString *, long, NSUInteger, double, NSNumber *, NSIndexPath *))longBlock {}
- (void)doReturnValue:(NSString *(^)())returnBlock {}
- (void)doInnerBlock:(void(^)(BOOL(^)(NSString *), OCMBlockTypedef))blockWithBlock {}
- (void)doTypedef:(void(^)(OCMTypedefObj, OCMTypedefObj *))typedefBlock {}
- (void)doStructs:(void(^)(struct OCMStruct, OCMStructTypedef, struct OCMStruct *, OCMStructTypedef *))structBlock {}
- (void)doVoidPtr:(void(^)(void *))voidPtrBlock {}

@end

@interface OCMBlockArgCallerTests : XCTestCase {
    id mock;
}

@end

@implementation OCMBlockArgCallerTests

- (void)setUp {
    [super setUp];
    mock = [OCMockObject mockForClass:[OCMStrangeTypes class]];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMockings {
    
    [[mock stub] doLotsOfParams:[OCMArg invokeBlockWithArgs:@"One", @"Two", OCMOCK_VALUE(3l), OCMOCK_VALUE(4ul), OCMOCK_VALUE(5.0), @6, [NSIndexPath indexPathWithIndex:7], nil]];
    [mock doLotsOfParams:^(NSString *one, NSString *two, long three, NSUInteger four, double five, NSNumber *six, NSIndexPath *seven) {}];
    
    [[mock stub] doReturnValue:[OCMArg invokeBlockWithArgs:nil]];
    [mock doReturnValue:^NSString *{
        return @"Returing this";
    }];
    
    [[mock stub] doInnerBlock:[OCMArg invokeBlockWithArgs:^BOOL (NSString *param) { return YES; }, ^BOOL (NSString *param) { return NO; }, nil]];
    [mock doInnerBlock:^(BOOL (^blockArg)(NSString *param), OCMBlockTypedef blockArg2) {
        NSLog(@"First block arg: %@", blockArg);
        NSLog(@"Second block arg: %@", blockArg2);
    }];
    
    NSObject *obj = [NSObject new];
    [[mock stub] doTypedef:[OCMArg invokeBlockWithArgs:[NSObject new], OCMOCK_VALUE(&obj), nil]];
    [mock doTypedef:^(OCMTypedefObj arg1, __autoreleasing OCMTypedefObj *arg2) {
        
    }];
    
    [[mock stub] doStructs:[OCMArg invokeBlockWithArgs:OCMOCK_VALUE(((struct OCMStruct){ 1, 2 })), OCMOCK_VALUE(((OCMStructTypedef){ 1, 2 })), OCMOCK_VALUE((&(struct OCMStruct){ 1, 2 })), OCMOCK_VALUE((&(OCMStructTypedef){ 1, 2 })), nil]];
    [mock doStructs:^(struct OCMStruct a, OCMStructTypedef b, struct OCMStruct *c, OCMStructTypedef *d) {
        
    }];
    
    OCMStructTypedef stru = { 1, 2 };
    [[mock stub] doVoidPtr:[OCMArg invokeBlockWithArgs:OCMOCK_VALUE(&stru), nil]];
    
    [mock doVoidPtr:^(void *a) {
        
    }];
    
}

@end
