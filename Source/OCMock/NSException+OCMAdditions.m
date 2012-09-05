//
//  NSException+OCMAdditions.m
//  OCMock
//
//  Created by Ziad Khoury Hanna on 4/9/12.
//  Copyright (c) 2012 Mulle Kybernetik. All rights reserved.
//

#import "NSException+OCMAdditions.h"
#import <OCMock/OCMockRecorder.h>
#import "OCMObserverRecorder.h"
#import <SenTestingKit/NSException_SenTestFailure.h>

static NSString *OCMFilenameKey;
static NSString *OCMLineNumberKey;
static NSString *OCMDescriptionKey;

@implementation NSException (OCMAdditions)

+ (void)load {
	if (SenTestFailureException) {
		OCMFilenameKey = SenTestFilenameKey;
		OCMLineNumberKey = SenTestLineNumberKey;
		OCMDescriptionKey = SenTestDescriptionKey;
	} else {
		OCMFilenameKey = @"SenTestFilenameKey";
		OCMLineNumberKey = @"SenTestLineNumberKey";
		OCMDescriptionKey = @"SenTestDescriptionKey";
	}
}

+ (NSException *)failureInMockInFile:(NSString *)filename atLine:(int)lineNumber withDescription:(NSString *)formatString, ... {
	va_list args;
	va_start(args, formatString);
	NSString *description = [[NSString alloc] initWithFormat:formatString arguments:args];
	va_end(args);
	
	NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
													 reason:description
												   userInfo:@{
											OCMFilenameKey : filename,
										  OCMLineNumberKey : @(lineNumber),
										 OCMDescriptionKey : description
							  }];
	[description release];
	return exception;
}

+ (NSException *)failureInMockRecorder:(OCMockRecorder *)recorder withDescription:(NSString *)formatString, ... {
	va_list args;
	va_start(args, formatString);
	NSString *description = [[NSString alloc] initWithFormat:formatString arguments:args];
	va_end(args);
	
	NSException *exception = [self failureInMockInFile:recorder.file atLine:recorder.line
									   withDescription:description];
	[description release];
	return exception;
}

+ (NSException *)failureInObserverRecorder:(OCMObserverRecorder *)recorder withDescription:(NSString *)formatString, ... {
	va_list args;
	va_start(args, formatString);
	NSString *description = [[NSString alloc] initWithFormat:formatString arguments:args];
	va_end(args);
	
	NSException *exception = [self failureInMockInFile:recorder.file atLine:recorder.line
									   withDescription:description];
	[description release];
	return exception;
}

@end
