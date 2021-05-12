/*
 *  Copyright (c) 2014-2020 Erik Doernenburg and contributors
 *
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License. You may obtain
 *  a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 *  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 *  License for the specific language governing permissions and limitations
 *  under the License.
 */

#import <Foundation/Foundation.h>
#import "OCMFunctions.h"

// Use this define to be able to control the default issue treatment from a build.
// It can be overridden by using `OCMIssueTreatmentDefaultEnvironmentVariable`.
#ifndef OCMIssueTreatmentDefault
#define OCMIssueTreatmentDefault OCMIssueTreatmentWarnings
#endif

// Use this to control the default issue treatment through the environment.
// It can be set to 0 for warnings or 1 for errors.
#define OCMIssueTreatmentDefaultEnvironmentVariable @"OCMIssueTreatmentDefault"

// The name of NSExceptions thrown by default when an issue it treated as an error.
OCMOCK_EXTERN NSExceptionName const OCMIssueException;

typedef NS_ENUM(NSUInteger, OCMIssueTreatment)
{
    // Warnings are printed to stderr.
    OCMIssueTreatmentWarnings = 0,
    // Errors are thrown an NSExceptions.
    OCMIssueTreatmentErrors,
};

@interface OCMIssueReporter : NSObject
{
    NSMutableArray *issueTreatmentStack;
}

+ (instancetype)defaultReporter;

- (void)reportIssueInFile:(const char *)file line:(NSUInteger)line format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4);
- (void)reportIssueInFilev:(const char *)file line:(NSUInteger)line format:(NSString *)format arguments:(va_list)args NS_FORMAT_FUNCTION(3,0);
- (void)reportIssueInFile:(const char *)file line:(NSUInteger)line exceptionName:(NSExceptionName)name reason:(NSString *)reason;

// Pushes/Pops an issue treatment on the stack. Push and Pop can only be called from the main thread and must be balanced.
- (void)pushIssueTreatment:(OCMIssueTreatment)treatment;
- (void)popIssueTreatment;

// The current issue treatment on the top of the stack.
- (OCMIssueTreatment)issueTreatment;

@end

#define OCM_REPORT_ISSUE(_format, ...) ([[OCMIssueReporter defaultReporter] reportIssueInFile:__FILE__ line:__LINE__ format:_format, __VA_ARGS__ ])
