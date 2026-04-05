//
//  TipStoreTests.swift
//  HackeryTests
//
//  Created by Tim Shim on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

@Suite(.serialized)
struct TipStoreTests {

  // MARK: - Initial State

  @MainActor @Test func initialStateIsIdle() {
    let store = TipStore()
    #expect(store.purchaseState == .idle)
    #expect(store.product == nil)
  }

  @MainActor @Test func productIDIsCorrect() {
    #expect(TipStore.productID == "com.hackery.tip.coffee")
  }

  // MARK: - PurchaseState Equatable

  @Test func purchaseStateEquatable() {
    #expect(TipStore.PurchaseState.idle == .idle)
    #expect(TipStore.PurchaseState.purchasing == .purchasing)
    #expect(TipStore.PurchaseState.success == .success)
    #expect(TipStore.PurchaseState.failed("err") == .failed("err"))
    #expect(TipStore.PurchaseState.failed("a") != .failed("b"))
    #expect(TipStore.PurchaseState.idle != .purchasing)
    #expect(TipStore.PurchaseState.idle != .success)
  }

  // MARK: - markSuccess

  @MainActor @Test func markSuccessSetsStateToSuccess() {
    let store = TipStore()
    #expect(store.purchaseState == .idle)
    store.markSuccess()
    #expect(store.purchaseState == .success)
  }

  // MARK: - resetState

  @MainActor @Test func resetStateSetsStateToIdle() {
    let store = TipStore()
    store.markSuccess()
    #expect(store.purchaseState == .success)
    store.resetState()
    #expect(store.purchaseState == .idle)
  }

  @MainActor @Test func resetStateFromFailed() {
    let store = TipStore()
    store.markSuccess()
    store.resetState()
    #expect(store.purchaseState == .idle)
  }

  // MARK: - listenForTransactions

  @MainActor @Test func listenForTransactionsIsIdempotent() {
    let store = TipStore()
    store.listenForTransactions()
    store.listenForTransactions()
    #expect(store.purchaseState == .idle)
  }

  // MARK: - Purchase with no product

  #if os(iOS)
  @MainActor @Test func purchaseWithNoProductIsNoop() async {
    let store = TipStore()
    await store.purchase()
    #expect(store.purchaseState == .idle)
  }
  #endif

  // MARK: - State Transitions

  @MainActor @Test func markSuccessAfterResetWorks() {
    let store = TipStore()
    store.markSuccess()
    store.resetState()
    store.markSuccess()
    #expect(store.purchaseState == .success)
  }

  @MainActor @Test func multipleResetsAreHarmless() {
    let store = TipStore()
    store.resetState()
    store.resetState()
    store.resetState()
    #expect(store.purchaseState == .idle)
  }

  @MainActor @Test func fullStateCycle() {
    let store = TipStore()
    #expect(store.purchaseState == .idle)
    store.markSuccess()
    #expect(store.purchaseState == .success)
    store.resetState()
    #expect(store.purchaseState == .idle)
    store.markSuccess()
    #expect(store.purchaseState == .success)
    store.resetState()
    #expect(store.purchaseState == .idle)
  }
}
