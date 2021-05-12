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

#import "OCMIssueReporter.h"

NSExceptionName const OCMIssueException = @"OCMIssueException";

@implementation OCMIssueReporter

+ (instancetype)defaultReporter
{
    static dispatch_once_t onceToken;
    static OCMIssueReporter *defaultReporter;
    dispatch_once(&onceToken, ^{
        defaultReporter = [[OCMIssueReporter alloc] init];
        atexit_b(^{
            if([defaultReporter->issueTreatmentStack count] != 1)
            {
                [NSException raise:NSInternalInconsistencyException format:@"Unmatched push/pops on OCMIssueRecorder"];
            }
        });
    });
    return defaultReporter;
}

- (instancetype)init
{
    if((self = [super init]))
    {
        NSDictionary *environment = [[NSProcessInfo processInfo] environment];
        OCMIssueTreatment value;
        NSString *stringValue = [environment objectForKey:OCMIssueTreatmentDefaultEnvironmentVariable];
        if(stringValue)
        {
            value = [stringValue integerValue];
        }
        else
        {
            value = OCMIssueTreatmentDefault;
        }
        if(value > OCMIssueTreatmentErrors)
        {
            [NSException raise:NSInvalidArgumentException format:@"OCMIssueReporter has invalid default issue treatment: %d", (int)value];
        }
        issueTreatmentStack = [[NSMutableArray alloc] init];
        [issueTreatmentStack addObject:[NSNumber numberWithInteger:value]];
    }
    return self;
}

- (void)dealloc
{
    [issueTreatmentStack release];
    [super dealloc];
}

- (void)reportIssueInFile:(const char *)file line:(NSUInteger)line format:(NSString *)format, ...
{
    va_list arguments;
    va_start(arguments, format);
    [self reportIssueInFilev:file line:line format:format arguments:arguments];
    va_end(arguments);
}

- (void)reportIssueInFilev:(const char *)file line:(NSUInteger)line format:(NSString *)format arguments:(va_list)arguments
{
    NSString *description = [[NSString alloc] initWithFormat:format arguments:arguments];
    [self reportIssueInFile:file line:line exceptionName:OCMIssueException reason:description];
    [description release];
}

- (void)reportIssueInFile:(const char *)file line:(NSUInteger)line exceptionName:(NSExceptionName)name reason:(NSString *)reason
{
    OCMIssueTreatment treatment = [self issueTreatment];
    NSString *fullDescription;
    NSString *type;
    switch(treatment)
    {
        case OCMIssueTreatmentWarnings:
            type = @"warning";
            break;

        case OCMIssueTreatmentErrors:
            type = @"error";
            break;

        default:
            [NSException raise:NSInternalInconsistencyException format:@"Unknown issue treatment: %d", (int)treatment];
            break;
    }
    if(file)
    {
        fullDescription = [[NSString alloc] initWithFormat:@"%s:%d:0: %@: %@", file, (int)line, type, reason];
    }
    else
    {
        fullDescription = [[NSString alloc] initWithFormat:@"%@: %@", type, reason];
    }
    switch(treatment)
    {
        case OCMIssueTreatmentWarnings:
            fprintf(stderr, "%s\n", [fullDescription UTF8String]);
            break;

        case OCMIssueTreatmentErrors:
            [NSException raise:name format:@"%@", fullDescription];
            break;

        default:
            [NSException raise:NSInternalInconsistencyException format:@"Unknown issue treatment: %d", (int)treatment];
            break;
    }
}

- (void)pushIssueTreatment:(OCMIssueTreatment)treatment
{
    if(![NSThread isMainThread])
    {
        [NSException raise:NSInternalInconsistencyException format:@"pushIssueTreatment can only be called on main thread"];
    }
    @synchronized(self)
    {
        [issueTreatmentStack addObject:[NSNumber numberWithInteger:treatment]];
    }
}

- (void)popIssueTreatment
{
    if(![NSThread isMainThread])
    {
        [NSException raise:NSInternalInconsistencyException format:@"popIssueTreatment can only be called on main thread"];
    }

    @synchronized(self)
    {
        if([issueTreatmentStack count] == 1)
        {
            [NSException raise:NSInternalInconsistencyException format:@"unbalanced calls to pushIssueTreatment/popIssueTreatment"];
        }
        [issueTreatmentStack removeLastObject];
    }
}

- (OCMIssueTreatment)issueTreatment
{
    OCMIssueTreatment treatment;
    @synchronized(self)
    {
        treatment = [[issueTreatmentStack lastObject] integerValue];
    }
    return treatment;
}
@end
