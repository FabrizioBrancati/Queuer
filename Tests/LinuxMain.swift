#if os(Linux)

import XCTest
@testable import QueuerTests

XCTMain([
    testCase(Queuer.allTests)
])

#endif
