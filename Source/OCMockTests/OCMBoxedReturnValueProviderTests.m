/*
 *  Copyright (c) 2015-2016 Erik Doernenburg and contributors
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

#import "OCMockBaseTestCase.h"
#import "OCMBoxedReturnValueProvider.h"

@interface OCMBoxedReturnValueProvider(Private)
- (BOOL)isMethodReturnType:(const char *)returnType compatibleWithValueType:(const char *)valueType;
@end

@interface OCMBoxedReturnValueProviderTests : OCMockBaseTestCase

@end

@implementation OCMBoxedReturnValueProviderTests

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

	OCMBoxedReturnValueProvider *boxed = [OCMBoxedReturnValueProvider new];
	XCTAssertTrue([boxed isMethodReturnType:type1 compatibleWithValueType:type2]);
	XCTAssertTrue([boxed isMethodReturnType:type1 compatibleWithValueType:type3]);
	XCTAssertTrue([boxed isMethodReturnType:type2 compatibleWithValueType:type1]);
	XCTAssertTrue([boxed isMethodReturnType:type2 compatibleWithValueType:type3]);
	XCTAssertTrue([boxed isMethodReturnType:type3 compatibleWithValueType:type1]);
	XCTAssertTrue([boxed isMethodReturnType:type3 compatibleWithValueType:type2]);
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

	OCMBoxedReturnValueProvider *boxed = [OCMBoxedReturnValueProvider new];
	XCTAssertTrue([boxed isMethodReturnType:type1 compatibleWithValueType:type2]);
}

@end




