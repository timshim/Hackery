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
  static let productID = "com.hackery.tip.coffee"

  private(set) var product: Product?
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

  func loadProduct() async {
    guard product == nil else { return }
    do {
      let loaded = try await Product.products(for: [Self.productID])
      product = loaded.first
    } catch {
      product = nil
    }
  }

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

  func resetState() {
    purchaseState = .idle
  }
}
