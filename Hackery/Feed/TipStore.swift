//
//  TipStore.swift
//  Hackery
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import StoreKit

@Observable
final class TipStore {
  static let productIDs = [
    "com.hackery.tip.small",
    "com.hackery.tip.medium",
    "com.hackery.tip.large",
    "com.hackery.tip.generous"
  ]

  private(set) var products: [Product] = []
  private(set) var purchaseState: PurchaseState = .idle

  enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case failed(String)
  }

  private var updateTask: Task<Void, Never>?

  init() {
    updateTask = Task { [weak self] in
      guard let self else { return }
      for await result in Transaction.updates {
        if case .verified(let transaction) = result {
          await transaction.finish()
          self.purchaseState = .success
        }
      }
    }
  }

  deinit {
    updateTask?.cancel()
  }

  func loadProducts() async {
    guard products.isEmpty else { return }
    do {
      let loaded = try await Product.products(for: Self.productIDs)
      products = loaded.sorted { $0.price < $1.price }
    } catch {
      products = []
    }
  }

  func purchase(_ product: Product) async {
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

  func resetState() {
    purchaseState = .idle
  }
}
