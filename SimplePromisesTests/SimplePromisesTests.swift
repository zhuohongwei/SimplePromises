//
//  SimplePromisesTests.swift
//  SimplePromisesTests
//
//  Created by Zhuo Hong Wei on 8/2/16.
//  Copyright © 2016 Zhuo Hong Wei. All rights reserved.
//

import XCTest


private enum FibError: ErrorType {
    case InvalidArgument
}

private func fibn(n: Int) throws -> Int {
    if n < 0 {
        throw FibError.InvalidArgument

    } else if n == 0 {
        return 0

    } else if n == 1 {
        return 1

    } else {
        return try fibn(n - 1) + fibn(n - 2)
    }
}

class SimplePromisesTests: XCTestCase {

    let workQueue = dispatch_queue_create("workQueue", DISPATCH_QUEUE_SERIAL)

    func testAsyncComputation() {

        let asyncComputationExpectation = expectationWithDescription("Computation should happen asynchronously")

        NSLog("Before constructing promise")

        Promise { (resolve: Int -> (), reject) -> () in
            dispatch_async(self.workQueue) {

                do {
                    let answer =  try fibn(20)
                    dispatch_async(dispatch_get_main_queue()) {
                        resolve(answer)
                    }

                } catch {
                    reject(error)
                }

            }
            
        }.then { answer in

            NSLog("Received answer: \(answer)")

            XCTAssert(answer == 6765, "Fib 20 equals 6765")
            asyncComputationExpectation.fulfill()


        }

        NSLog("After constructing promise")

        waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "0 errors")
        }

    }

    func testRejectedPromise() {

        let rejectedPromiseExpectation = expectationWithDescription("Promise should be rejected")

        NSLog("Before constructing promise")

        Promise { (resolve: Int -> (), reject) -> () in
            dispatch_async(self.workQueue) {

                do {
                    let answer =  try fibn(-20)
                    dispatch_async(dispatch_get_main_queue()) {
                        resolve(answer)
                    }

                } catch {
                    reject(error)
                }

            }

        }.then { answer in
            XCTFail()

        }.doCatch { error in
            rejectedPromiseExpectation.fulfill()

        }

        NSLog("After constructing promise")
        
        waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "0 errors")
        }

    }

    func testResolvedPromise() {

        let p = Promise.resolve(10)

        p.then { (num: Int) -> String in
            XCTAssertEqual(num, 10)
            return "\(num)"

        }.then { (aString: String) -> Int in
            XCTAssertEqual(aString, "10")
            return aString.characters.count

        }.doCatch { error in
            XCTFail()

        }.then { (num: Int) in
            XCTAssertEqual(num, 2)
            return
        }

    }
    
}
