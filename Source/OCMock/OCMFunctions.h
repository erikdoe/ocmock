//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

@class OCMLocation;


BOOL OCMIsObjectType(const char *objCType);
const char *OCMTypeWithoutQualifiers(const char *objCType);

void OCMReportFailure(OCMLocation *loc, NSString *description);
