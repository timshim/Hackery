//
//  TipStore.swift
//  Hackery
//
//  Created by Tim Shim on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import StoreKit

@MainActor
@Observable
final class TipStore {
  static let productID = "com.hackery.tip.coffee"

  private(set) var product: Product?
  private(set) var purchaseState: PurchaseState = .idle
#if os(visionOS)
  // Bind this to a SwiftUI sheet/popover that presents StoreView with `storeProducts`.
  var isPresentingStore: Bool = false
  /// Convenience array for StoreKit StoreView on visionOS.
  var storeProducts: [Product] { product.map { [$0] } ?? [] }
#endif

  enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case failed(String)
  }

  private var updateTask: Task<Void, Never>?

  func listenForTransactions() {
    guard updateTask == nil else { return }
    updateTask = Task {
      for await result in Transaction.updates {
        if case .verified(let transaction) = result {
          await transaction.finish()
          self.purchaseState = .success
        }
      }
    }
  }

  func loadProduct() async {
    guard product == nil else { return }
    do {
      let loaded = try await Product.products(for: [Self.productID])
      product = loaded.first
    } catch {
      product = nil
    }
  }
#if os(visionOS)
  func beginVisionPurchase() {
    guard product != nil else { return }
    purchaseState = .purchasing
    isPresentingStore = true
  }
#endif

#if os(iOS)
  func purchase() async {
    guard let product else { return }
    purchaseState = .purchasing
    do {
      let result = try await product.purchase()
      switch result {
      case .success(let verification):
        if case .verified(let transaction) = verification {
          await transaction.finish()
          purchaseState = .success
        } else {
          purchaseState = .failed("Purchase could not be verified.")
        }
      case .userCancelled:
        purchaseState = .idle
      case .pending:
        purchaseState = .idle
      @unknown default:
        purchaseState = .idle
      }
    } catch {
      purchaseState = .failed(error.localizedDescription)
    }
  }
#endif

  func markSuccess() {
    purchaseState = .success
  }

  func resetState() {
    purchaseState = .idle
  }
}

