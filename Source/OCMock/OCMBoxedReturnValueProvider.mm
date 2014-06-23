/*
 *  Copyright (c) 2009-2014 Erik Doernenburg and contributors
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

#import "OCMBoxedReturnValueProvider.h"
#import <objc/runtime.h>

#if defined(__clang__)
#include <vector>  // for _LIBCPP_ABI_VERSION to detect if using libc++
#endif

#if defined(__clang__) && defined(_LIBCPP_ABI_VERSION)
namespace {
// Default stack size to use when checking for matching opening and closing
// characters (<> and {}). This is used to reduce the number of allocations
// in AdvanceTypeDescriptionPointer function.
const size_t kDefaultStackSize = 32;

// Move to the next pertinent character in a type description. This skips
// all the field expansion that clang includes in the type description when
// compiling with libc++.
//
// See inner comment of -isValueTypeCompatibleWithInvocation: for more details.
// Returns true if the pointer was advanced, false if the type description was
// not correctly parsed.
bool AdvanceTypeDescriptionPointer(const char *&typeDescription) {
	if (!*typeDescription)
		return true;

	++typeDescription;
	if (*typeDescription != '=')
		return true;

	++typeDescription;
	std::vector<char> stack;
	stack.reserve(kDefaultStackSize);
	while (*typeDescription) {
		const char current = *typeDescription;
		if (current == '<' || current == '{') {
			stack.push_back(current);
		} else if (current == '>' || current == '}') {
			if (!stack.empty()) {
				const char opening = stack.back();
				if ((opening == '<' && current != '>') ||
						(opening == '{' && current != '}')) {
					return false;
				}
				stack.pop_back();
			} else {
				return current == '}';
			}
		} else if (current == ',' && stack.empty()) {
			return true;
		}
		++typeDescription;
	}
	return true;
}
}
#endif  // defined(__clang__) && defined(_LIBCPP_ABI_VERSION)

@interface OCMBoxedReturnValueProvider ()

- (BOOL)isValueTypeCompatibleWithInvocation:(NSInvocation *)anInvocation;

@end

@implementation OCMBoxedReturnValueProvider

- (BOOL)isValueTypeCompatibleWithInvocation:(NSInvocation *)anInvocation {
	const char *returnType = [[anInvocation methodSignature] methodReturnType];
	const char *valueType = [(NSValue *)returnValue objCType];

#if defined(__aarch64__) || defined(__x86_64__)
	// ARM64 uses 'B' for BOOLs in method signature but 'c' in NSValue. That case
	// should match.
	if (strcmp(returnType, "B") == 0 && strcmp(valueType, "c") == 0)
		return YES;
#endif  // defined(__aarch64__) || defined(__x86_64__)

#if defined(__clang__) && defined(_LIBCPP_ABI_VERSION)
	// The type representation of the return type of the invocation, and the
	// type representation passed to NSValue are not the same for C++ objects
	// when compiling with libc++ with clang.
	//
	// In that configuration, the C++ class are expanded to list the types of
	// the fields, but the depth of the expansion for templated types is larger
	// for the value stored in the NSValue.
	//
	// For example, when creating a OCMOCK_VALUE with a GURL object (from the
	// Chromium project), then the two types representations are:
	//
	// r^{GURL={basic_string<char, std::__1::char_traits<char>, std::__1::alloca
	// tor<char> >={__compressed_pair<std::__1::basic_string<char, std::__1::cha
	// r_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<c
	// har> >={__rep}}}B{Parsed={Component=ii}{Component=ii}{Component=ii}{Compo
	// nent=ii}{Component=ii}{Component=ii}{Component=ii}{Component=ii}^{Parsed}
	// }{scoped_ptr<GURL, base::DefaultDeleter<GURL> >={scoped_ptr_impl<GURL, ba
	// se::DefaultDeleter<GURL> >={Data=^{GURL}}}}}
	//
	// r^{GURL={basic_string<char, std::__1::char_traits<char>, std::__1::alloca
	// tor<char> >={__compressed_pair<std::__1::basic_string<char, std::__1::cha
	// r_traits<char>, std::__1::allocator<char> >::__rep, std::__1::allocator<c
	// har> >={__rep=(?={__long=II*}{__short=(?=Cc)[11c]}{__raw=[3L]})}}}B{Parse
	// d={Component=ii}{Component=ii}{Component=ii}{Component=ii}{Component=ii}{
	// Component=ii}{Component=ii}{Component=ii}^{Parsed}}{scoped_ptr<GURL, base
	// ::DefaultDeleter<GURL> >={scoped_ptr_impl<GURL, base::DefaultDeleter<GURL
	// > >={Data=^{GURL}}}}}
	//
	// Since those types should be considered equals, we un-expand them during
	// the comparison. For that, we remove everything following an "=" until we
	// meet a non-matched "}" or a ",".

	while (*returnType && *valueType) {
		if (*returnType != *valueType)
			return NO;

		if (!AdvanceTypeDescriptionPointer(returnType))
			return NO;

		if (!AdvanceTypeDescriptionPointer(valueType))
			return NO;
	}

	return !*returnType && !*valueType;
#else
	return strcmp(returnType, valueType) == 0;
#endif  // defined(__clang__) && defined(_LIBCPP_ABI_VERSION)
}

- (void)handleInvocation:(NSInvocation *)anInvocation
{
	if (![self isValueTypeCompatibleWithInvocation:anInvocation]) {
		const char *returnType = [[anInvocation methodSignature] methodReturnType];
		const char *valueType = [(NSValue *)returnValue objCType];
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Return value does not match method signature; signature declares '%s' but value is '%s'.", returnType, valueType] userInfo:nil];
	}
	void *buffer = malloc([[anInvocation methodSignature] methodReturnLength]);
	[returnValue getValue:buffer];
	[anInvocation setReturnValue:buffer];
	free(buffer);
}

@end
