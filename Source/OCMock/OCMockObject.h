//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2008 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockObject : NSProxy
{
	BOOL			isNice;
	BOOL			expectationOrderMatters;
	NSMutableArray	*recorders;
	NSMutableArray	*expectations;
	NSMutableArray	*rejections;
	NSMutableArray	*exceptions;
}

/**
 Creates a mock object that can be used as if it were an instance of the supplied class
 @param aClass class to mock
 @return mock
 */
+ (id)mockForClass:(Class)aClass;
/**
 Creates a mock object that can be used as if it were an instance of an object that implements the supplied protocol
 @param aProtocol protocol to mock
 @return mock
 */
+ (id)mockForProtocol:(Protocol *)aProtocol;
/**
 Creates a mock object that can be used in the same way as anObject. When a method that is not stubbed is invoked it will be forwarded to anObject. When a stubbed method is invoked using a reference to anObject, rather than the mock, it will still be handled by the mock.
 @param anObject the object to partially mock
 @return mock
 */
+ (id)partialMockForObject:(NSObject *)anObject;

/**
 Creates a "nice" mock for the supplied class
 @discussion When a method is called on a mock object that has not been set up with either expect or stub the mock object will raise an exception. This fail-fast mode can be turned off by creating a "nice" mock. While nice mocks will simply ignore all unexpected methods it is possible to disallow specific methods:
 @code
 [[mock reject] someMethod]
 @endcode
 @note In fail-fast mode, if the exception is ignored, it will be rethrown when verify is called. This makes it possible to ensure that unwanted invocations from notifications etc. can be detected.
 @param aClass class to create a "nice" mock of
 @return mock
 */
+ (id)niceMockForClass:(Class)aClass;

/**
 Creates a "nice" mock that conforms to the supplied protocol
 @param aProtocol The protocol to mock
 @return mock
 */
+ (id)niceMockForProtocol:(Protocol *)aProtocol;
/**
 Creates a mock object that can be used to observe notifications. The mock must be registered in order to receive notifications:
 @code
 [notificatonCenter addMockObserver:aMock name:SomeNotification object:nil]
 @endcode
 Expectations can then be set up as follows:
 @code
 [[mock expect] notificationWithName:SomeNotification object:[OCMArg any]]
 @endcode
 @note Currently there is no "nice" mode for observer mocks, they will always raise an exception when an unexpected notification is received.
 @see NSNotificationCenter+OCMAdditions.h
 @return mock
 */
+ (id)observerMock;
/**
 makes a mock object
 @return mock
 */
- (id)init;
/**
 Sets whether the order that you tell the mock the calls you expect matters.
 @param flag @c YES or @c NO to turn this feature on and off
 */
- (void)setExpectationOrderMatters:(BOOL)flag;

/**
 Tells the mock object to add a sub implementation with a chained result to a chained selector
 @code
 [[[mock stub] andReturn:aValue] someMethod:someArgument]
 @endcode
 @see http://ocmock.org/features/
 @return returns self for method chaining
 */
- (id)stub;
/**
 Used for telling the mock that you expect the chained selector to be called.
 @code
 [[mock expect] someMethod:someArgument]
 @endcode
 Tells the mock object that @c someMethod: should be called with an argument that is equal to @c someArgument. After this setup the functionality under test should be invoked followed by @c -verify
 @see @c -verify
 @return self
 */
- (id)expect;
/**
 When using nice mocks it is possible to disallow specific methods:
 @return mock
 */
- (id)reject;
/**
 Used to verify the mock has recieved all the messages you told it to expect
 @discussion The verify method will raise an exception if the expected method has not been invoked.
 */
- (void)verify;
/**
 The partial / class mock can be returned to its original state, i.e. all stubs will be removed
 @discussion This is only necessary if the original state must be restored before the end of the test. The mock automatically calls @c stopMocking during its own deallocation.
 @warning If the mock object that added a stubbed class method is not deallocated the stubbed method will persist across tests. If multiple mock objects manipulate the same class at the same time the behaviour is undefined.
 */
- (void)stopMocking;

// internal use only

- (id)getNewRecorder;
- (BOOL)handleInvocation:(NSInvocation *)anInvocation;
- (void)handleUnRecordedInvocation:(NSInvocation *)anInvocation;
- (BOOL)handleSelector:(SEL)sel;

@end
