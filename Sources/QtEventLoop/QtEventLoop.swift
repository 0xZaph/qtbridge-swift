// Copyright (C) 2025 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only
#if !canImport(Darwin)
import Synchronization
@_spi(ExperimentalCustomExecutors) @_spi(ExperimentalScheduling) import _Concurrency
import _CQtEventLoop

public final class QtEventLoop: SerialExecutor, @unchecked Sendable {
    public static let shared = QtEventLoop()

    private let sequenceCounter = Atomic<UInt64>(0)

    private struct State {
        var queue = PriorityQueue<UnownedJob>(compare: compareJobsByPriorityAndSequenceNumber)
        var isWakeupPending = false
    }

    private let state = Mutex(State())

    private init() {}

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let seq = sequenceCounter.wrappingAdd(1, ordering: .relaxed).oldValue
        job.sequenceNumber = seq

        let unowned = UnownedJob(job)
        let needsWakeup = state.withLock {
            $0.queue.push(unowned)
            if !$0.isWakeupPending {
                $0.isWakeupPending = true
                return true
            }
            return false
        }

        if needsWakeup {
            qt_event_loop_wake_main({ _ in QtEventLoop.shared.drain() }, nil)
        }
    }

    private func drain() {
        var localQueue: [UnownedJob] = []
        state.withLock {
            while let job = $0.queue.pop() {
                localQueue.append(job)
            }
            $0.isWakeupPending = false
        }

        for job in localQueue {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    public func checkIsolated() {
        precondition(qt_is_main_thread(), "QtEventLoop: Isolation violation (not on UI thread)")
    }

    public func stop() {
        qt_event_loop_quit()
    }
}

// MARK: - Background Thread Pool Executor

public final class QtThreadPoolExecutor: TaskExecutor, @unchecked Sendable {
    public static let shared = QtThreadPoolExecutor()
    private init() {}

    public func asUnownedTaskExecutor() -> UnownedTaskExecutor {
        UnownedTaskExecutor(ordinary: self)
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let priority = qtThreadPoolPriority(for: job.priority)
        let unownedJob = UnownedJob(job)
        let ptr = UnsafeMutableRawPointer(mutating: unsafeBitCast(unownedJob, to: UnsafeRawPointer.self))

        qt_thread_pool_submit({ context in
            guard let context else {
                preconditionFailure("QtThreadPoolExecutor: Received nil context from C bridge")
            }
            let jobToRun = unsafeBitCast(context, to: UnownedJob.self)
            jobToRun.runSynchronously(on: QtThreadPoolExecutor.shared.asUnownedTaskExecutor())
        }, ptr, priority)
    }
}

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999, *)
@_spi(ExperimentalScheduling)
@_spi(ExperimentalCustomExecutors)
extension QtThreadPoolExecutor: SchedulingExecutor {
    public func enqueue<C: Clock>(
        _ job: consuming ExecutorJob,
        after delay: C.Duration,
        tolerance: C.Duration?,
        clock: C
    ) {
        let ms: Int64
        if let _ = clock as? ContinuousClock {
            ms = (delay as! Duration).milliseconds
        } else if let _ = clock as? SuspendingClock {
            ms = (delay as! Duration).milliseconds
        } else {
            fatalError("Custom clocks are not supported")
        }

        if ms <= 0 {
            self.enqueue(job)
            return
        }

        let jobPtr = UnsafeMutableRawPointer(mutating: unsafeBitCast(UnownedJob(job), to: UnsafeRawPointer.self))

        // Note: Int32(clamping:) silently clamps delays beyond ~24 days, which is acceptable.
        qt_event_loop_wake_after({ context in
            guard let context else { return }
            let unownedJob = unsafeBitCast(context, to: UnownedJob.self)
            let priority = qtThreadPoolPriority(for: unownedJob.priority)
            qt_thread_pool_submit({ poolContext in
                guard let poolContext else {
                    preconditionFailure("QtThreadPoolExecutor: Timer routing failed.")
                }
                let jobToRun = unsafeBitCast(poolContext, to: UnownedJob.self)
                jobToRun.runSynchronously(on: QtThreadPoolExecutor.shared.asUnownedTaskExecutor())
            }, context, priority)
        }, jobPtr, Int32(clamping: ms))
    }

    public var asSchedulingExecutor: (any SchedulingExecutor)? { self }
}

// MARK: - Scheduling (Timers)

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999, *)
@_spi(ExperimentalScheduling)
extension QtEventLoop: SchedulingExecutor {
    public func enqueue<C: Clock>(
        _ job: consuming ExecutorJob,
        after delay: C.Duration,
        tolerance: C.Duration?,
        clock: C
    ) {
        let ms: Int64
        if let _ = clock as? ContinuousClock {
            ms = (delay as! Duration).milliseconds
        } else if let _ = clock as? SuspendingClock {
            ms = (delay as! Duration).milliseconds
        } else {
            fatalError("Custom clocks are not supported")
        }

        if ms <= 0 {
            self.enqueue(job)
            return
        }

        let jobPtr = UnsafeMutableRawPointer(mutating: unsafeBitCast(UnownedJob(job), to: UnsafeRawPointer.self))

        // Note: Int32(clamping:) silently clamps delays beyond ~24 days, which is acceptable.
        qt_event_loop_wake_after({ context in
            guard let context else {
                preconditionFailure("QtEventLoop: Timer callback nil context.")
            }
            let job = unsafeBitCast(context, to: UnownedJob.self)
            job.runSynchronously(on: QtEventLoop.shared.asUnownedSerialExecutor())
        }, jobPtr, Int32(clamping: ms))
    }

    public var asSchedulingExecutor: (any SchedulingExecutor)? { self }
}

// MARK: - Executor Factory

@available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999, *)
@_spi(ExperimentalCustomExecutors)
@_spi(ExperimentalScheduling)
extension QtEventLoop: ExecutorFactory, MainExecutor {

    public func run() throws {
        // Never called: QApp.main() is synchronous and drives the event loop
        // via QAppCpp::run() -> QGuiApplication::exec(), so
        // swift_task_asyncMainDrainQueueImpl never reaches this path.
        fatalError("QtEventLoop.run() should never be called in this configuration.")
    }

    public static var mainExecutor: any MainExecutor { QtEventLoop.shared }

    public static var defaultExecutor: any TaskExecutor { QtThreadPoolExecutor.shared }
}

// MARK: - Installation

extension QtEventLoop {
    private nonisolated(unsafe) static var isInstalled = false

    public static func installGlobalExecutor() {
        guard !isInstalled else { return }
        isInstalled = true
        qt_event_loop_prepare_main_thread()
        if #available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, visionOS 9999, *) {
            _Concurrency._createExecutors(factory: QtEventLoop.self)
        }
    }
}

// MARK: - Utilities

fileprivate extension Duration {
    var milliseconds: Int64 {
        let (s, a) = components
        return (s * 1000) + (a / 1_000_000_000_000_000)
    }
}

/// Maps a Swift JobPriority to a QThreadPool queue-ordering hint.
///
/// QThreadPool::start(runnable, priority) takes an arbitrary int where higher
/// values run first. This bucketing mirrors the approach used by
/// Win32ThreadPoolExecutor and avoids passing raw Swift priority values, which
/// are an unstable internal detail.
fileprivate func qtThreadPoolPriority(for priority: JobPriority) -> Int32 {
    if priority.rawValue <= TaskPriority.low.rawValue      { return 0 }
    if priority.rawValue >= TaskPriority.high.rawValue     { return 2 }
    return 1
}

// MARK: - Priority Queue & Sequence tracking

extension ExecutorJob {
    fileprivate var sequenceNumber: UInt64 {
        get {
            return unsafe withUnsafeExecutorPrivateData {
                return unsafe $0.assumingMemoryBound(to: UInt64.self)[0]
            }
        }
        set {
            unsafe withUnsafeExecutorPrivateData {
                unsafe $0.withMemoryRebound(to: UInt64.self) {
                    unsafe $0[0] = newValue
                }
            }
        }
    }
}

fileprivate func compareJobsByPriorityAndSequenceNumber(
    lhs: UnownedJob,
    rhs: UnownedJob
) -> Bool {
    if lhs.priority == rhs.priority {
        let delta = ExecutorJob(lhs).sequenceNumber &- ExecutorJob(rhs).sequenceNumber
        return (delta >> (UInt64.bitWidth - 1)) != 0
    }
    return lhs.priority > rhs.priority
}

fileprivate struct PriorityQueue<T> {
    var storage: [T] = []
    var compare: (borrowing T, borrowing T) -> Bool

    init(compare: @escaping (borrowing T, borrowing T) -> Bool) {
        self.compare = compare
    }

    var count: Int { storage.count }
    var isEmpty: Bool { storage.isEmpty }

    mutating func push(_ value: T) {
        storage.append(value)
        upHeap(ndx: storage.count - 1)
    }

    mutating func pop() -> T? {
        if storage.isEmpty { return nil }
        storage.swapAt(0, storage.count - 1)
        let result = storage.removeLast()
        if !storage.isEmpty { downHeap(ndx: 0) }
        return result
    }

    private mutating func upHeap(ndx: Int) {
        var theNdx = ndx
        while theNdx > 0 {
            let parentNdx = (theNdx - 1) / 2
            if !compare(storage[theNdx], storage[parentNdx]) { break }
            storage.swapAt(theNdx, parentNdx)
            theNdx = parentNdx
        }
    }

    private mutating func downHeap(ndx: Int) {
        var theNdx = ndx
        while true {
            let leftNdx = 2 * theNdx + 1
            if leftNdx >= storage.count { break }
            let rightNdx = 2 * theNdx + 2
            var largestNdx = theNdx

            if compare(storage[leftNdx], storage[largestNdx]) { largestNdx = leftNdx }
            if rightNdx < storage.count && compare(storage[rightNdx], storage[largestNdx]) { largestNdx = rightNdx }
            if largestNdx == theNdx { break }

            storage.swapAt(theNdx, largestNdx)
            theNdx = largestNdx
        }
    }
}
#else
public enum QtEventLoop { public static func installGlobalExecutor() {} }
#endif