#if os(Linux)

import XCTest
@testable import QueuerTests

XCTMain([
    testCase(ConcurrentOperationTests.allTests),
    testCase(QueuerTests.allTests),
    testCase(RequestOperationTests.allTests),
    testCase(URLBuilderTests.allTests),
    testCase(SemaphoreTests.allTests),
    testCase(SynchronousOperationTests.allTests)
])

#endif
