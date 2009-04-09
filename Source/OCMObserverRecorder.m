//---------------------------------------------------------------------------------------
//  $Id: OCMObserverRecorder.m $
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import <OCMock/OCMConstraint.h>
#import "NSInvocation+OCMAdditions.h"
#import "OCMObserverRecorder.h"

@interface NSObject(HCMatcherDummy)
- (BOOL)matches:(id)item;
@end


@implementation OCMObserverRecorder

//---------------------------------------------------------------------------------------
//  init and dealloc
//---------------------------------------------------------------------------------------

- (void)dealloc
{
	[recordedNotification release];
	[super dealloc];
}


//---------------------------------------------------------------------------------------
//  recording
//---------------------------------------------------------------------------------------

- (void)notificationWithName:(NSString *)name object:(id)sender
{
	recordedNotification = [[NSNotification notificationWithName:name object:sender] retain];
}


//---------------------------------------------------------------------------------------
//  verification
//---------------------------------------------------------------------------------------

- (BOOL)matchesNotification:(NSNotification *)aNotification
{
	return [self argument:[recordedNotification name] matchesArgument:[aNotification name]] &&
	[self argument:[recordedNotification object] matchesArgument:[aNotification object]] &&
	[self argument:[recordedNotification userInfo] matchesArgument:[aNotification userInfo]];
}

- (BOOL)argument:(id)expectedArg matchesArgument:(id)observedArg
{
	if([expectedArg isKindOfClass:[OCMConstraint class]])
	{	
		if([expectedArg evaluate:observedArg] == NO)
			return NO;
	}
	else if([expectedArg conformsToProtocol:objc_getProtocol("HCMatcher")])
	{
		if([expectedArg matches:observedArg] == NO)
			return NO;
	}
	else
	{
		if([expectedArg class] != [observedArg class])
			return NO;
		if(([expectedArg isEqual:observedArg] == NO) &&
		   !((expectedArg == nil) && (observedArg == nil)))
			return NO;
	}
	return YES;
}



@end
