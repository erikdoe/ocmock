/*
 *  Copyright (c) 2014-2021 Erik Doernenburg and contributors
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



#ifdef OCM_DISABLE_SHORT_SYNTAX
#define OCM_DISABLE_SHORT_QSYNTAX
#endif


#define OCMClassMock(cls) [OCMockObject niceMockForClass:cls]

#define OCMStrictClassMock(cls) [OCMockObject mockForClass:cls]

#define OCMProtocolMock(protocol) [OCMockObject niceMockForProtocol:protocol]

#define OCMStrictProtocolMock(protocol) [OCMockObject mockForProtocol:protocol]

#define OCMPartialMock(obj) [OCMockObject partialMockForObject:obj]

#define OCMObserverMock() [OCMockObject observerMock]


#define OCMStubWithStateClass(MacroStateClass, invocation) \
({ \
    _OCMSilenceWarnings( \
        [MacroStateClass beginStubMacro]; \
        OCMStubRecorder *recorder = nil; \
        @try{ \
            invocation; \
        }@catch(...){ \
            [[MacroStateClass globalState] setInvocationDidThrow:YES]; \
            /* NOLINTNEXTLINE(google-objc-avoid-throwing-exception) */ \
            @throw; \
        }@finally{ \
            recorder = [MacroStateClass endStubMacro]; \
        } \
        recorder; \
    ); \
})

#define OCMStub(invocation) OCMStubWithStateClass(OCMMacroState, invocation)

#define OCMExpectWithStateClass(MacroStateClass, invocation) \
({ \
    _OCMSilenceWarnings( \
        [MacroStateClass beginExpectMacro]; \
        OCMStubRecorder *recorder = nil; \
        @try{ \
            invocation; \
        }@catch(...){ \
            [[MacroStateClass globalState] setInvocationDidThrow:YES]; \
            /* NOLINTNEXTLINE(google-objc-avoid-throwing-exception) */ \
            @throw; \
        }@finally{ \
            recorder = [MacroStateClass endExpectMacro]; \
        } \
        recorder; \
    ); \
})

#define OCMExpect(invocation) OCMExpectWithStateClass(OCMMacroState, invocation)

#define OCMRejectWithStateClass(MacroStateClass, invocation) \
({ \
    _OCMSilenceWarnings( \
        [MacroStateClass beginRejectMacro]; \
        OCMStubRecorder *recorder = nil; \
        @try{ \
            invocation; \
        }@catch(...){ \
            [[MacroStateClass globalState] setInvocationDidThrow:YES]; \
            /* NOLINTNEXTLINE(google-objc-avoid-throwing-exception) */ \
            @throw; \
        }@finally{ \
            recorder = [MacroStateClass endRejectMacro]; \
        } \
        recorder; \
    ); \
})

#define OCMReject(invocation) OCMRejectWithStateClass(OCMMacroState, invocation)



#define OCMClassMethodWithStateClass(MacroStateClass, invocation) \
    _OCMSilenceWarnings( \
        [[MacroStateClass globalState] switchToClassMethod]; \
        invocation; \
    );

#define OCMClassMethod(invocation) OCMClassMethodWithStateClass(OCMMacroState, invocation)


#ifndef OCM_DISABLE_SHORT_SYNTAX
#define ClassMethod(invocation) OCMClassMethod(invocation)
#endif


#define OCMVerifyAll(mock) [(OCMockObject *)mock verifyAtLocation:OCMMakeLocation(self, __FILE__, __LINE__)]

#define OCMVerifyAllWithDelay(mock, delay) [(OCMockObject *)mock verifyWithDelay:delay atLocation:OCMMakeLocation(self, __FILE__, __LINE__)]

#define _OCMVerifyWithStateClass(MacroStateClass, invocation) \
({ \
    _OCMSilenceWarnings( \
        [MacroStateClass beginVerifyMacroAtLocation:OCMMakeLocation(self, __FILE__, __LINE__)]; \
        @try{ \
            invocation; \
        }@catch(...){ \
            [[MacroStateClass globalState] setInvocationDidThrow:YES]; \
            /* NOLINTNEXTLINE(google-objc-avoid-throwing-exception) */ \
            @throw; \
        }@finally{ \
            [MacroStateClass endVerifyMacro]; \
        } \
    ); \
})

#define _OCMVerify(invocation) _OCMVerifyWithStateClass(OCMMacroState, invocation)


#define _OCMVerifyWithQuantifierAndStateClass(MacroStateClass, quantifier, invocation) \
({ \
    _OCMSilenceWarnings( \
        [MacroStateClass beginVerifyMacroAtLocation:OCMMakeLocation(self, __FILE__, __LINE__) withQuantifier:quantifier]; \
        @try{ \
           invocation; \
        }@catch(...){ \
            [[MacroStateClass globalState] setInvocationDidThrow:YES]; \
            /* NOLINTNEXTLINE(google-objc-avoid-throwing-exception) */ \
            @throw; \
        }@finally{ \
            [MacroStateClass endVerifyMacro]; \
        } \
    ); \
})

#define _OCMVerifyWithQuantifier(quantifier, invocation) _OCMVerifyWithQuantifierAndStateClass(OCMMacroState, quantifier, invocation)

// explanation for macros below here: https://stackoverflow.com/questions/3046889/optional-parameters-with-c-macros

#define _OCMVerify_1(A)                 _OCMVerify(A)
#define _OCMVerify_2(A,B)               _OCMVerifyWithQuantifier(A, B)
#define _OCMVerify_X(x,A,B,FUNC, ...)   FUNC
#define OCMVerify(...) _OCMVerify_X(,##__VA_ARGS__, _OCMVerify_2(__VA_ARGS__), _OCMVerify_1(__VA_ARGS__))


#define _OCMSilenceWarnings(macro) \
({ \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wunused-value\"") \
    _Pragma("clang diagnostic ignored \"-Wunused-getter-return-value\"") \
    _Pragma("clang diagnostic ignored \"-Wstrict-selector-match\"") \
    macro \
    _Pragma("clang diagnostic pop") \
})
