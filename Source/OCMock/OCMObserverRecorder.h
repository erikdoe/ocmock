//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@interface OCMObserverRecorder : NSObject 
{
	NSNotification *recordedNotification;
}

- (void)notificationWithName:(NSString *)name object:(id)sender;

- (BOOL)matchesNotification:(NSNotification *)aNotification;

- (BOOL)argument:(id)expectedArg matchesArgument:(id)observedArg;

@property (copy, nonatomic) NSString *file;
@property (nonatomic) int line;

@end
