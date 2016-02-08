//
//  Promise.swift
//  SimplePromises
//
//  Created by Zhuo Hong Wei on 8/2/16.
//  Copyright © 2016 Zhuo Hong Wei. All rights reserved.
//

import Foundation

private enum PromiseState {
    case Pending
    case Fulfilled
    case Rejected
}

class Promise<T> {

    private var value: T?
    private var error: ErrorType?
    private var state: PromiseState = .Pending

    private let theLock = NSLock()

    typealias OnFulfilledCallback = T -> ()
    typealias OnRejectedCallback = ErrorType -> ()

    private var onFulfilledCallbacks = [ OnFulfilledCallback ]()
    private var onRejectedCallbacks = [ OnRejectedCallback ]()

    init(resolver: (resolve: T -> (), reject: ErrorType -> ()) throws -> () ) {
        
        let resolve = { (value: T) in
            self.fulfill(value)
        }

        let reject = { (error: ErrorType) in
            self.reject(error)
        }

        do {
            try resolver(resolve: resolve, reject: reject)

        } catch {
            self.reject(error)
        }
    }

    init(resolver: (resolve: Promise<T> -> (), reject: ErrorType -> ()) throws -> () ) {

        let resolve = { (promise: Promise<T>) in

            self.appendCallback({ (value: T) in
                self.fulfill(value)
            })
            
        }

        let reject = { (error: ErrorType) in
            self.reject(error)
        }

        do {
            try resolver(resolve: resolve, reject: reject)

        } catch {
            self.reject(error)
        }
    }

    private func fulfill(value: T) {

        defer {
            theLock.unlock()
        }

        theLock.lock()

        guard self.state == .Pending else {
            return
        }

        self.state = .Fulfilled
        self.value = value

        self.onFulfilledCallbacks.forEach {
            $0(value)
        }
    }

    private func reject(error: ErrorType) {

        defer {
            theLock.unlock()
        }

        theLock.lock()

        guard self.state == .Pending else {
            return
        }

        self.state = .Rejected
        self.error = error

        self.onRejectedCallbacks.forEach {
            $0(error)
        }
    }

    private func appendCallback(callback: OnFulfilledCallback) {

        defer {
            self.theLock.unlock()
        }

        self.theLock.lock()

        self.onFulfilledCallbacks.append(callback)

        guard self.state == .Fulfilled else {
            return
        }

        guard let value = self.value else {
            return
        }
        
        callback(value)
    }

    private func appendCallback(callback: OnRejectedCallback) {

        defer {
            self.theLock.unlock()
        }

        self.theLock.lock()

        self.onRejectedCallbacks.append(callback)

        guard self.state == .Rejected else {
            return
        }

        guard let error = self.error else {
            return
        }

        callback(error)
    }


    func then<U>(onFulfilled: T throws -> U) -> Promise<U> {

        return Promise<U>(resolver: { (resolve: U -> (), reject) -> () in

            let onFulfilledCallback = { (value: T) in
                do {
                    let thenValue = try onFulfilled(value)
                    resolve(thenValue)

                } catch {
                    reject(error)
                }
            }

            self.appendCallback(onFulfilledCallback)

            let onRejectedCallback = { (error: ErrorType) in
                reject(error)
            }

            self.appendCallback(onRejectedCallback)

        })

    }

    func doCatch(onRejected: ErrorType -> ()) -> Promise<T> {

        return Promise<T>(resolver: { (resolve: T -> (), reject) -> () in

            let onFulfilledCallback = { (value: T) in
                resolve(value)
            }

            self.appendCallback(onFulfilledCallback)


            let onRejectedCallback = { (error: ErrorType) in
                onRejected(error)
                reject(error)
            }

            self.appendCallback(onRejectedCallback)

        })

    }

    class func resolve(value: T) -> Promise<T> {
        return Promise(resolver: { (resolve, reject) -> () in
            resolve(value)
        })
    }
    
    class func resolve(promise: Promise<T>) -> Promise<T> {
        return Promise(resolver: { (resolve, reject) -> () in
            resolve(promise)
        })
    }
    
    class func reject(error: ErrorType) -> Promise<T> {
        return Promise(resolver: { (_: T -> (), reject) -> () in
            reject(error)
        })
    }
    
}