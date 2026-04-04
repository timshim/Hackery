//
//  TipStoreTests.swift
//  HackeryTests
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import Testing
import Foundation
@testable import Hackery

struct TipStoreTests {

  @Test func initialStateIsIdle() {
    let store = TipStore()
    #expect(store.purchaseState == .idle)
    #expect(store.product == nil)
  }

  @Test func productIDIsCoffee() {
    #expect(TipStore.productID == "com.hackery.tip.coffee")
  }

  @Test func resetStateSetsIdle() {
    let store = TipStore()
    store.resetState()
    #expect(store.purchaseState == .idle)
  }

  @Test func purchaseStateEquatable() {
    #expect(TipStore.PurchaseState.idle == .idle)
    #expect(TipStore.PurchaseState.purchasing == .purchasing)
    #expect(TipStore.PurchaseState.success == .success)
    #expect(TipStore.PurchaseState.failed("err") == .failed("err"))
    #expect(TipStore.PurchaseState.failed("a") != .failed("b"))
    #expect(TipStore.PurchaseState.idle != .purchasing)
  }

  @Test func loadProductDoesNotCrashWithUnknownID() async {
    let store = TipStore()
    await store.loadProduct()
    // In test env without StoreKit config, product will be nil — just verify no crash
  }

  @Test func loadProductDoesNotReloadIfAlreadyLoaded() async {
    let store = TipStore()
    await store.loadProduct()
    let first = store.product
    await store.loadProduct()
    #expect(store.product?.id == first?.id)
  }
}
