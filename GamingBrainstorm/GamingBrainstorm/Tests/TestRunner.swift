//
//  TestRunner.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation

#if TEST_RUNNER
@main
struct TestRunner {
    static func main() {
        let success = GameEngineTests.runAllTests()
        exit(success ? 0 : 1)
    }
}
#endif
