//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMLocation;
@class OCClassMockObject;
@class OCPartialMockObject;


BOOL OCMIsObjectType(const char *objCType);
const char *OCMTypeWithoutQualifiers(const char *objCType);

void OCMSetAssociatedMockForClass(OCClassMockObject *mock, Class aClass);
OCClassMockObject *OCMGetAssociatedMockForClass(Class aClass);

void OCMSetAssociatedMockForObject(OCClassMockObject *mock, id anObject);
OCPartialMockObject *OCMGetAssociatedMockForObject(id anObject);

void OCMReportFailure(OCMLocation *loc, NSString *description);
