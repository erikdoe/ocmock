//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2013 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import "NSMethodSignature+OCMAdditions.h"
#import "NSMethodSignatureOCMAdditionsTests.h"


@implementation NSMethodSignatureOCMAdditionsTests

- (void)testDeterminesThatSpecialReturnIsNotNeededForNonStruct
{
    const char *types = "i";
   	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
    STAssertFalse([sig usesSpecialStructureReturn], @"Should have determined no need for special (stret) return.");
}

- (void)testDeterminesThatSpecialReturnIsNeededForLargeStruct
{
    // This type should(!) require special returns for all architectures
    const char *types = "{CATransform3D=ffffffffffffffff}";
   	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
    STAssertTrue([sig usesSpecialStructureReturn], @"Should have determined need for special (stret) return.");
}

- (void)testNSMethodSignatureDebugDescriptionWorksTheWayWeExpectIt
{
	const char *types = "{CATransform3D=ffffffffffffffff}";
	NSMethodSignature *sig = [NSMethodSignature signatureWithObjCTypes:types];
	NSString *debugDescription = [sig debugDescription];
	NSRange stretYESRange = [debugDescription rangeOfString:@"is special struct return? YES"];
	NSRange stretNORange = [debugDescription rangeOfString:@"is special struct return? NO"];
	STAssertTrue(stretYESRange.length > 0 || stretNORange.length > 0, @"NSMethodSignature debugDescription has changed; need to change OCPartialMockObject impl");
}


@end