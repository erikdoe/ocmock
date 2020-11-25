/*
 *  Copyright (c) 2020-2021 Erik Doernenburg and contributors
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

#import <objc/runtime.h>
#import <XCTest/XCTest.h>
#import "OCMockObject.h"
#import "OCMockMacros.h"
#import "OCMFunctions.h"
#import "OCMFunctionsPrivate.h"

#pragma mark   Helper classes

@interface TestClassForFunctions : NSObject
- (void)setFoo:(NSString *)aString;
@end

@implementation TestClassForFunctions

- (void)setFoo:(NSString *)aString;
{
}

@end

// Exists solely to supply method signatures to InvocationRecorder.
@interface InvocationImplementor : NSObject
@end

@implementation InvocationImplementor

- (instancetype)foo_initWithCount:(NSNumber *)number ofObjectsInSet:(NSSet<NSString *>*)set
{
    return nil;
}

- (instancetype)initWithCount:(NSNumber *)number ofObjectsInSet:(NSSet<NSString *>*)set
{
    return self;
}

- (NSUInteger)numberFromNameString:(NSString *)nameString inEnglish:(BOOL)inEnglish
{
    return 0;
}

- (void)performBlock:(id(^)(int))block onQueue:(dispatch_queue_t)queue
{
}

- (BOOL)stringWillBeginFormatting:(NSString *)string
{
    return NO;
}

- (NSString *)stringDidEndFormatting:(NSString *)string
{
    return [NSMutableString string];
}

- (void)didFinishPlaybackAndWillInternallyTransitionToNextPlayback:(BOOL)value
{
}

@end

// Records invocations.
@interface InvocationRecorder : NSProxy
@property NSMutableArray<NSInvocation *> *invocations;
@property InvocationImplementor *implementor;
@end

@implementation InvocationRecorder
- (instancetype)init
{
    _invocations = [NSMutableArray array];
    _implementor = [[InvocationImplementor alloc] init];
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation retainArguments];
    [self.invocations addObject:invocation];
    [invocation invokeWithTarget:_implementor];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [self.implementor methodSignatureForSelector:selector];
}
@end

@interface OCMFunctionsTests : XCTestCase
@end


@implementation OCMFunctionsTests

- (void)testIsBlockReturnsFalseForClass
{
    XCTAssertFalse(OCMIsBlock([NSString class]));
}

- (void)testIsBlockReturnsFalseForObject
{
    XCTAssertFalse(OCMIsBlock([NSArray array]));
}

- (void)testIsBlockReturnsFalseForNil
{
    XCTAssertFalse(OCMIsBlock(nil));
}

- (void)testIsBlockReturnsTrueForBlock
{
    XCTAssertTrue(OCMIsBlock(^ { }));
}

- (void)testIsMockSubclassOnlyReturnYesForActualSubclass
{
    id object = [TestClassForFunctions new];
    XCTAssertFalse(OCMIsMockSubclass([object class]));

    id mock __unused = [OCMockObject partialMockForObject:object];
    XCTAssertTrue(OCMIsMockSubclass(object_getClass(object)));

    // adding a KVO observer creates and sets a subclass of the mock subclass
    [object addObserver:self forKeyPath:@"foo" options:NSKeyValueObservingOptionNew context:NULL];
    XCTAssertFalse(OCMIsMockSubclass(object_getClass(object)));

    [object removeObserver:self forKeyPath:@"foo" context:NULL];
}

- (void)testIsSubclassOfMockSubclassReturnYesForSubclasses
{
    id object = [TestClassForFunctions new];
    XCTAssertFalse(OCMIsMockSubclass([object class]));

    id mock __unused = [OCMockObject partialMockForObject:object];
    XCTAssertTrue(OCMIsSubclassOfMockClass(object_getClass(object)));

    // adding a KVO observer creates and sets a subclass of the mock subclass
    [object addObserver:self forKeyPath:@"foo" options:NSKeyValueObservingOptionNew context:NULL];
    XCTAssertTrue(OCMIsSubclassOfMockClass(object_getClass(object)));

    [object removeObserver:self forKeyPath:@"foo" context:NULL];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
}

- (void)testOCMIsBlock
{
    XCTAssertFalse(OCMIsBlock([NSString class]));
    XCTAssertFalse(OCMIsBlock(@""));
    XCTAssertFalse(OCMIsBlock([NSString stringWithFormat:@"%d", 42]));
    XCTAssertFalse(OCMIsBlock(nil));
    XCTAssertTrue(OCMIsBlock(^{}));
}

- (void)testCorrectEqualityForCppProperty
{
    // see https://github.com/erikdoe/ocmock/issues/96
    const char *type1 =
        "r^{GURL={basic_string<char, std::__1::char_traits<char>, std::__1::alloca"
        "tor<char> >={__compressed_pair<std::__1::basic_string<char, std::__1::cha"
        "r_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<c"
        "har> >={__rep}}}B{Parsed={Component=ii}{Component=ii}{Component=ii}{Compo"
        "nent=ii}{Component=ii}{Component=ii}{Component=ii}{Component=ii}^{Parsed}"
        "}{scoped_ptr<GURL, base::DefaultDeleter<GURL> >={scoped_ptr_impl<GURL, ba"
        "se::DefaultDeleter<GURL> >={Data=^{GURL}}}}}";

    const char *type2 =
        "r^{GURL={basic_string<char, std::__1::char_traits<char>, std::__1::alloca"
        "tor<char> >={__compressed_pair<std::__1::basic_string<char, std::__1::cha"
        "r_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<c"
        "har> >={__rep=(?={__long=II*}{__short=(?=Cc)[11c]}{__raw=[3L]})}}}B{Parse"
        "d={Component=ii}{Component=ii}{Component=ii}{Component=ii}{Component=ii}{"
        "Component=ii}{Component=ii}{Component=ii}^{Parsed}}{scoped_ptr<GURL, base"
        "::DefaultDeleter<GURL> >={scoped_ptr_impl<GURL, base::DefaultDeleter<GURL"
        "> >={Data=^{GURL}}}}}";

    const char *type3 =
        "r^{GURL}";

    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type1, type2, NULL, 0));
    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type1, type3, NULL, 0));
    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type2, type1, NULL, 0));
    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type2, type3, NULL, 0));
    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type3, type1, NULL, 0));
    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type3, type2, NULL, 0));
}


- (void)testCorrectEqualityForCppReturnTypesWithVtables
{
    // see https://github.com/erikdoe/ocmock/issues/247
    const char *type1 =
        "^{S=^^?{basic_string<char, std::__1::char_traits<char>, std::__1::allocat"
        "or<char> >={__compressed_pair<std::__1::basic_string<char, std::__1::char"
        "_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<ch"
        "ar> >={__rep}}}}";

    const char *type2 =
        "^{S=^^?{basic_string<char, std::__1::char_traits<char>, std::__1::allocat"
        "or<char> >={__compressed_pair<std::__1::basic_string<char, std::__1::char"
        "_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<ch"
        "ar> >={__rep=(?={__long=QQ*}{__short=(?=Cc)[23c]}{__raw=[3Q]})}}}}";

    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type1, type2, NULL, 0));
}


- (void)testCorrectEqualityForStructureWithUnknownName
{
    // see https://github.com/erikdoe/ocmock/issues/333
    const char *type1 = "{?=dd}";
    const char *type2 = "{CLLocationCoordinate2D=dd}";

    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type1, type2, NULL, 0));
}


- (void)testCorrectEqualityForStructureWithoutName
{
    // see https://github.com/erikdoe/ocmock/issues/342
    const char *type1 = "r^{GURL={basic_string<char, std::__1::char_traits<char"
        ">, std::__1::allocator<char> >={__compressed_pair<std::__1::basic_stri"
        "ng<char, std::__1::char_traits<char>, std::__1::allocator<char> >::__r"
        "ep, std::__1::allocator<char> >={__rep}}}B{Parsed={Component=ii}{Compo"
        "nent=ii}{Component=ii}{Component=ii}{Component=ii}{Component=ii}{Compo"
        "nent=ii}{Component=ii}B^{}}{unique_ptr<GURL, std::__1::default_delete<"
        "GURL> >={__compressed_pair<GURL *, std::__1::default_delete<GURL> >=^{"
        "}}}}";
    const char *type2 = "r^{GURL={basic_string<char, std::__1::char_traits<char"
        ">, std::__1::allocator<char> >={__compressed_pair<std::__1::basic_stri"
        "ng<char, std::__1::char_traits<char>, std::__1::allocator<char> >::__r"
        "ep, std::__1::allocator<char> >={__rep=(?={__long=QQ*}{__short=(?=Cc)["
        "23c]}{__raw=[3Q]})}}}B{Parsed={Component=ii}{Component=ii}{Component=i"
        "i}{Component=ii}{Component=ii}{Component=ii}{Component=ii}{Component=i"
        "i}B^{Parsed}}{unique_ptr<GURL, std::__1::default_delete<GURL> >={__com"
        "pressed_pair<GURL *, std::__1::default_delete<GURL> >=^{GURL}}}}";

    XCTAssertTrue(OCMIsObjCTypeCompatibleWithValueType(type1, type2, NULL, 0));
}
- (void)testSplitSelectorSegmentIntoWords
{
    NSArray<NSString *> *array = OCMSplitSelectorSegmentIntoWords(@"ASongAboutThe26ABCsIsOfTheEssenceButAPersonalIDCardForUser456InRoom26ContainingABC26TimesIsNotAsEasyAs123");
    NSArray<NSString *> *expected = @[ @"A",
                                       @"Song",
                                       @"About",
                                       @"The26",
                                       @"ABCs",
                                       @"Is",
                                       @"Of",
                                       @"The",
                                       @"Essence",
                                       @"But",
                                       @"A",
                                       @"Personal",
                                       @"ID",
                                       @"Card",
                                       @"For",
                                       @"User456",
                                       @"In",
                                       @"Room26",
                                       @"Containing",
                                       @"ABC26",
                                       @"Times",
                                       @"Is",
                                       @"Not",
                                       @"As",
                                       @"Easy",
                                       @"As123" ];
    XCTAssertEqualObjects(array, expected);
    array = OCMSplitSelectorSegmentIntoWords(@"initWithURLsStartingWithHTTPAssumingTheyAreWebBased");
    expected = @[ @"init",
                  @"With",
                  @"URLs",
                  @"Starting",
                  @"With",
                  @"HTTPAssuming",
                  @"They",
                  @"Are",
                  @"Web",
                  @"Based"];
    XCTAssertEqualObjects(array, expected);
}

- (void)testParameterNamesFromSelector
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selectors[6];
    selectors[0] = @selector(gtm_initWithWindow:);
    selectors[1] = @selector(_initWithLikesCount:commentDate:firstCommentGUID:toAssetWithUUID:photosBatchID:mainAssetIsMine:mainAssetIsVideo:inAlbumWithTitle:albumUUID:assetUUIDs:placeholderAssetUUIDs:lowResThumbAssetUUIDs:senderNames:forMultipleAsset:allMultipleAssetIsMine:isMixedType:);
    selectors[2] = @selector(initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bitmapFormat:bytesPerRow:bitsPerPixel:);
    selectors[3] = @selector(getPixel:atX:y:);
    selectors[4] = @selector(doSomething:::);
    selectors[5] = @selector(under_score_this:and_:_while:_also_:_:);
#pragma clang diagnostic pop

    NSArray<NSArray<NSString *>*> *expecteds = @[
        @[
            @"window",
        ],
        @[
            @"likesCount",
            @"commentDate",
            @"commentGUID",
            @"UUID",
            @"batchID",
            @"isMine0",
            @"isVideo",
            @"title",
            @"albumUUID",
            @"assetUUIDs0",
            @"assetUUIDs1",
            @"assetUUIDs2",
            @"senderNames",
            @"multipleAsset",
            @"isMine1",
            @"mixedType",
        ],
        @[
            @"dataPlanes",
            @"pixelsWide",
            @"pixelsHigh",
            @"perSample",
            @"perPixel0",
            @"hasAlpha",
            @"isPlanar",
            @"spaceName",
            @"bitmapFormat",
            @"perRow",
            @"perPixel1",
        ],
        @[
            @"pixel",
            @"x",
            @"y",
        ],
        @[
            @"doSomething",
            @"arg0",
            @"arg1"
        ],
        @[
            @"this",
            @"arg0",
            @"while",
            @"arg1",
            @"arg2",
        ],
    ];
    for(size_t i = 0; i < sizeof(selectors) / sizeof(*selectors); i++)
    {
        XCTAssertEqualObjects(OCMParameterNamesFromSelector(selectors[i]), expecteds[i], @"Failing case %@", NSStringFromSelector(selectors[i]));
    }
}

- (void)testOCMTypeOfObject {
    XCTAssertEqualObjects(OCMTypeOfObject(self), @"OCMFunctionsTests *");
    XCTAssertEqualObjects(OCMTypeOfObject([NSProxy alloc]), @"id");
    XCTAssertEqualObjects(OCMTypeOfObject(@"foo"), @"NSString *");
    XCTAssertEqualObjects(OCMTypeOfObject(nil), @"id");
    XCTAssertEqualObjects(OCMTypeOfObject(Nil), @"id");
    XCTAssertEqualObjects(OCMTypeOfObject(@1), @"NSNumber *");
    XCTAssertEqualObjects(OCMTypeOfObject(@YES), @"NSNumber *");
    XCTAssertEqualObjects(OCMTypeOfObject(@[ ]), @"NSArray<ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject(@[ @"Foo"]), @"NSArray<ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject(@[ @"Foo", @"Bar"]), @"NSArray<ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject(@{}), @"NSDictionary<KeyType*, ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject(@{ @"Foo": @1}), @"NSDictionary<KeyType*, ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject(@{ @"Foo": @1, @"Bar": @2}), @"NSDictionary<KeyType*, ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject([[NSSet alloc] init]), @"NSSet<ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject([NSSet setWithObject:@"foo"]), @"NSSet<ObjectType*> *");
    XCTAssertEqualObjects(OCMTypeOfObject(^{}), @"BlockType");
    XCTAssertEqualObjects(OCMTypeOfObject(OCMProtocolMock(@protocol(NSObject))), @"id<NSObject>");
    XCTAssertEqualObjects(OCMTypeOfObject([NSObject class]), @"Class");
    XCTAssertEqualObjects(OCMTypeOfObject(dispatch_get_main_queue()), @"dispatch_queue_t");
}

- (void)testBlockDeclarationForInvocation {
    id recorder = [[InvocationRecorder alloc] init];
    [recorder foo_initWithCount:@2 ofObjectsInSet:[NSSet setWithObject:@"foo"]];
    (void)[recorder initWithCount:@2 ofObjectsInSet:[NSSet setWithObject:@"foo"]];
    [recorder numberFromNameString:@"twoCows" inEnglish:YES];
    [recorder performBlock:^(int a) { return @"foo"; } onQueue:dispatch_get_main_queue()];
    [recorder stringWillBeginFormatting:@"foo"];
    [recorder stringDidEndFormatting:@"foo"];
    [recorder didFinishPlaybackAndWillInternallyTransitionToNextPlayback:YES];
    NSArray<NSString *> *expectedResults = @[
        @"^id(InvocationImplementor *localSelf, NSNumber *count, NSSet<ObjectType*> *set) { return ... }",
        @"^id(InvocationImplementor *localSelf, NSNumber *count, NSSet<ObjectType*> *set) { return ... }",
        @"^NSUInteger(InvocationImplementor *localSelf, NSString *nameString, BOOL inEnglish) { return ... }",
        @"^void(InvocationImplementor *localSelf, BlockType block, dispatch_queue_t queue) { ... }",
        @"^BOOL(InvocationImplementor *localSelf, NSString *string) { return ... }",
        @"^NSString *(InvocationImplementor *localSelf, NSString *string) { return ... }",
        @"^void(InvocationImplementor *localSelf, BOOL nextPlayback) { ... }",
    ];

    int i = 0;
    for(NSInvocation *invocation in [recorder invocations])
    {
        XCTAssertEqualObjects(OCMBlockDeclarationForInvocation(invocation), expectedResults[i]);
        ++i;
    }
}

@end
