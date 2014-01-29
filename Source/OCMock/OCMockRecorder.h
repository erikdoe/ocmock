//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2004-2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMockRecorder : NSProxy 
{
	id				signatureResolver;
    BOOL            recordedAsClassMethod;
    BOOL            ignoreNonObjectArgs;
	NSInvocation	*recordedInvocation;
	NSMutableArray	*invocationHandlers;
}

- (id)initWithSignatureResolver:(id)anObject;

- (BOOL)matchesSelector:(SEL)sel;
- (BOOL)matchesInvocation:(NSInvocation *)anInvocation;
- (void)releaseInvocation;
/**
 Tells the mock to return an object for the stubbed selector.
 @code
 [[[mock stub] andReturn:aValue] someMethod:someArgument]
 @endcode
 @note If the method returns a primitive type then @c andReturnValue: must be used with a value argument. It is not possible to pass primitive types directly.
 @param anObject object to return for this stubbed selector
 @return self (for chaining)
 */
- (id)andReturn:(id)anObject;
/**
 Tells the mock to return a value for the stubbed selector
 @discussion If the method returns a primitive type then andReturnValue: must be used with a value argument. It is not possible to pass primitive types directly.
 @code
 [[[mock stub] andReturnValue:@YES] aMethodReturnABoolean:someArgument]
 @endcode
 @param aValue the value to return for this stubbed selector
 @return self (for chaining)
 */
- (id)andReturnValue:(NSValue *)aValue;
/**
 The mock object will throw an exception when a message is sent to the stubbed selector
 @code
 [[[mock stub] andThrow:anException] someMethod:someArgument]
 @endcode
 @param anException the exception object to throw
 @return self (for chaining)
 */
- (id)andThrow:(NSException *)anException;
/**
 The mock object will post a notification when a message is sent to the stubbed selector
 @code
 [[[mock stub] andPost:anException] someMethod:someArgument]
 @endcode
 @param aNotification the notification object to post
 @return self (for chaining)
 */
- (id)andPost:(NSNotification *)aNotification;
/**
 The mock delegates the handling of an invocation to a completely different method
 @code
 [[[mock stub] andCall:@selector(aMethod:) onObject:anObject] someMethod:someArgument]
 @endcode
 @note The signature of the replacement method must be the same as that of the method that is replaced. Arguments will be passed and the return value of the replacement method is returned from the stubbed method.
 @param selector The selector to message on the supplied object
 @param anObject the object to message with the supplied selector
 @return self (for chaining)
 */
- (id)andCall:(SEL)selector onObject:(id)anObject;
#if NS_BLOCKS_AVAILABLE
/**
 If Objective-C blocks are available a block can be used to handle the invocation and set up a return value
 @code
 void (^theBlock)(NSInvocation *) = ^(NSInvocation *invocation) {
 // code that reads and modifies the invocation object
};
[[[mock stub] andDo:theBlock] someMethod:[OCMArg any]];
 @endcode
 @param block a block containing the code you want executed
 @return self (for chaining)
 */
- (id)andDo:(void (^)(NSInvocation *))block; 
#endif

/**
 If using a partial mock it is possible to forward the method to the implementation in the real object
 @code
 [[[mock expect] andForwardToRealObject] someMethod]
 @endcode
 @note can be useful to simply check that a method was called
 @return self (for chaining)
 */
- (id)andForwardToRealObject;
/**
 explicitly stub a class method
 @discussion In cases where a class method should be stubbed but the class also has an instance method with the same name as the class method, the intent to mock the class method must be made explicit.
 @code
 [[[[mock stub] classMethod] andReturn:aValue] aMethod]
 @endcode
 @return self (for chaining)
 */
- (id)classMethod;
/**
 tells the mock to ignore non object arguments
 @discussion Arguments that are neither objects nor pointers or selectors cannot be ignored using an any placeholder. It is possible, though, to tell the mock to ignore all non-object arguments in an invocation
 @code
 [[[mock expect] ignoringNonObjectArgs] someMethodWithIntArgument:0]
 @endcode
 @note If the method has object arguments as well as non-object arguments, the object arguments can still be constrained as usual using the methods on OCMArg.
 @see http://www.mulle-kybernetik.com/forum/viewtopic.php?f=4&t=72
 */
- (id)ignoringNonObjectArgs;

- (NSArray *)invocationHandlers;

@end
