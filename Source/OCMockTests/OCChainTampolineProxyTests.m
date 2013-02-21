//
//  OCChainTampolineProxyTests.m
//  OCMock
//
//  Created by jc on 25/09/2012.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import "OCChainTampolineProxyTests.h"
#import <OCMock/OCMock.h>
#import "OCChainTampolineProxy.h"

@interface OCChainTampolineProxyTests ()
@property (strong) OCChainTampolineProxy *object;
@property (strong) id registeredObject;
@property (assign) SEL testSelector;
@end

@implementation OCChainTampolineProxyTests
@synthesize object=_object;

- (void) testReturnObject
{
    [self.object setObject:self.registeredObject
               forSelector:self.testSelector];
    STAssertEqualObjects(self.registeredObject,
                         [self.object performSelector:self.testSelector],
                         @"Object was not returned");
}

- (void) testParametersUnimportant
{
    SEL longSel = NSSelectorFromString(@"returnObjectForParam:andAnotherParam:andAnother");
    [self.object setObject:self.registeredObject forSelector:longSel];
    STAssertEqualObjects(self.registeredObject, [self.object performSelector:longSel], @"Object was not returned");
}

- (void) testUnregisteredObject
{
    [self.object setObject:self.registeredObject
               forSelector:self.testSelector];
    STAssertThrows([self.object performSelector:NSSelectorFromString(@"unregisteredSelector")],
                   @"No object registered for this selector; should have thrown");
}

- (void) testRegisteredNone
{
    STAssertThrows([self.object performSelector:NSSelectorFromString(@"unregisteredSelector")],
                   @"No objects registered; should have thrown");
}

- (void) testAlreadyRegistered
{
    [self.object setObject:self.registeredObject forSelector:self.testSelector];
    STAssertThrows([self.object setObject:self.registeredObject forSelector:self.testSelector],
                   @"Object already registered for this selector; should have thrown");
}

#pragma mark -
#pragma mark Building chains

- (void) testChainBuilding
{
    NSUInteger value = 10;
    id returnedObject = nil;
    
    id mock = [OCMockObject mockForClass:[NSBundle class]];
    [[[mock stub] andReturnValue:OCMOCK_VALUE(value)] chainedPropertyWithPath:@"bundleURL.foo.absoluteString.length"
                                                        terminalObjectClass:[NSString class]];
    id verifyMock1 = mock;
    
    // check chain placeholders
    
    // bundleURL (placeholder)
    returnedObject = [mock bundleURL];
    STAssertTrue([returnedObject class] == [OCChainTampolineProxy class], @"Didn't return a chain placeholder");
    
    // foo (placeholder)
    STAssertNotNil([returnedObject objectForSelectorNamed:@"foo"], @"Should have object for -foo");
    returnedObject = [returnedObject performSelector:NSSelectorFromString(@"foo")];
    STAssertTrue([returnedObject class] == [OCChainTampolineProxy class], @"Didn't return a chain placeholder");
    
    // absoluteString (true mock)
    returnedObject = [returnedObject absoluteString];
    STAssertEqualObjects(NSStringFromClass([returnedObject class]), @"OCClassMockObject", @"Didn't return a real mock");
    id verifyMock2 = returnedObject;
    
    // should now returned the stubbed value
    NSUInteger returnedValue = [returnedObject length];
    
    STAssertEquals(value, returnedValue, @"Did not return eventual value");
    
    // check cleared up
    [verifyMock1 verify];
    [verifyMock2 verify];
}


#pragma mark -

- (void) setUp
{
    self.object = [[OCChainTampolineProxy alloc] init];
    self.testSelector = NSSelectorFromString(@"fooSelector");
    self.registeredObject = [NSString string];
}

- (void) tearDown
{
    self.object = nil;
}

@end
