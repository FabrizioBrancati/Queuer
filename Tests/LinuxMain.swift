#if os(Linux)

@testable import QueuerTests
import XCTest

XCTMain([
    testCase(ConcurrentOperationTests.allTests),
    testCase(QueuerTests.allTests),
    testCase(URLBuilderTests.allTests),
    testCase(SemaphoreTests.allTests),
    testCase(SynchronousOperationTests.allTests)
])

#endif
