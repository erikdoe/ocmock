//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import "OCMFunctions.h"
#import "OCMLocation.h"
#import "OCClassMockObject.h"
#import "OCPartialMockObject.h"


#pragma mark  Known private API

@interface NSException(OCMKnownExceptionMethods)
+ (NSException *)failureInFile:(NSString *)file atLine:(int)line withDescription:(NSString *)formatString, ...;
@end

@interface NSObject(OCMKnownTestCaseMethods)
- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)file atLine:(NSUInteger)line expected:(BOOL)expected;
- (void)failWithException:(NSException *)exception;
@end


#pragma mark  Functions related to ObjC type system

BOOL OCMIsObjectType(const char *objCType)
{
    objCType = OCMTypeWithoutQualifiers(objCType);

    if(strcmp(objCType, @encode(id)) == 0)
        return YES;

    // if the returnType is a typedef to an object, it has the form ^{OriginClass=#}
    NSString *regexString = @"^\\^\\{(.*)=#.*\\}";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:NULL];
    NSString *type = [NSString stringWithCString:objCType encoding:NSASCIIStringEncoding];
    if([regex numberOfMatchesInString:type options:0 range:NSMakeRange(0, type.length)] > 0)
        return YES;

    return NO;
}


const char *OCMTypeWithoutQualifiers(const char *objCType)
{
    while(strchr("rnNoORV", objCType[0]) != NULL)
        objCType += 1;
    return objCType;
}


#pragma mark  Wrappers around associative references

NSString *OCMClassMethodMockObjectKey = @"OCMClassMethodMockObjectKey";

void OCMSetAssociatedMockForClass(OCClassMockObject *mock, Class aClass)
{
    // TODO: shouldn't we throw an exception if another object is already mocking class methods?
    objc_setAssociatedObject(aClass, OCMClassMethodMockObjectKey, mock, OBJC_ASSOCIATION_ASSIGN);
}

OCClassMockObject *OCMGetAssociatedMockForClass(Class aClass)
{
    OCClassMockObject *mock = nil;
    while((mock == nil) && (aClass != nil))
    {
        mock = objc_getAssociatedObject(aClass, OCMClassMethodMockObjectKey);
        aClass = class_getSuperclass(aClass);
    }
    if(mock == nil)
        [NSException raise:NSInternalInconsistencyException format:@"No mock for class %@", NSStringFromClass(aClass)];
    return mock;
}


NSString *OCMPartialMockObjectKey = @"OCMPartialMockObjectKey";

void OCMSetAssociatedMockForObject(OCClassMockObject *mock, id anObject)
{
     // TODO: shouldn't we throw an exception if another object is already mocking methods?
    objc_setAssociatedObject(anObject, OCMPartialMockObjectKey, mock, OBJC_ASSOCIATION_ASSIGN);
}

OCPartialMockObject *OCMGetAssociatedMockForObject(id anObject)
{
    OCPartialMockObject *mock = objc_getAssociatedObject(anObject, OCMPartialMockObjectKey);
    if(mock == nil)
        [NSException raise:NSInternalInconsistencyException format:@"No partial mock for object %p", anObject];
    return mock;
}


#pragma mark  Functions related to IDE error reporting

void OCMReportFailure(OCMLocation *loc, NSString *description)
{
    id testCase = [loc testCase];
    if((testCase != nil) && [testCase respondsToSelector:@selector(recordFailureWithDescription:inFile:atLine:expected:)])
    {
        [testCase recordFailureWithDescription:description inFile:[loc file] atLine:[loc line] expected:NO];
    }
    else if((testCase != nil) && [testCase respondsToSelector:@selector(failWithException:)])
    {
        NSException *exception = nil;
        if([NSException instancesRespondToSelector:@selector(failureInFile:atLine:withDescription:)])
        {
            exception = [NSException failureInFile:[loc file] atLine:(int)[loc line] withDescription:description];
        }
        else
        {
            NSString *reason = [NSString stringWithFormat:@"%@:%lu %@", [loc file], (unsigned long)[loc line], description];
            exception = [NSException exceptionWithName:@"OCMockTestFailure" reason:reason userInfo:nil];
        }
        [testCase failWithException:exception];
    }
    else if(loc != nil)
    {
        NSLog(@"%@:%lu %@", [loc file], (unsigned long)[loc line], description);
        NSString *reason = [NSString stringWithFormat:@"%@:%lu %@", [loc file], (unsigned long)[loc line], description];
        [[NSException exceptionWithName:@"OCMockTestFailure" reason:reason userInfo:nil] raise];

    }
    else
    {
        NSLog(@"%@", description);
        [[NSException exceptionWithName:@"OCMockTestFailure" reason:description userInfo:nil] raise];
    }

}