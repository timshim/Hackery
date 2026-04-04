//
//  TipJarView.swift
//  Hackery
//
//  Created by Claude on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI
import StoreKit

struct TipJarView: View {
  @Environment(TipStore.self) private var tipStore
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        if tipStore.purchaseState == .success {
          thankYouView
        } else {
          headerView
          if let product = tipStore.product {
            buyButton(product)
          }
          if case .failed(let message) = tipStore.purchaseState {
            Text(message)
              .font(.caption)
              .foregroundStyle(.red)
              .multilineTextAlignment(.center)
          }
        }
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      #if os(iOS)
      .background(Color("background"))
      #endif
      .task {
        await tipStore.loadProduct()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") { dismiss() }
        }
      }
      .onChange(of: tipStore.purchaseState) { _, newValue in
        if newValue == .success {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            dismiss()
            tipStore.resetState()
          }
        }
      }
    }
    #if os(visionOS)
    .frame(width: 360, height: 380)
    #endif
    .presentationDetents([.medium])
    .interactiveDismissDisabled(tipStore.purchaseState == .purchasing)
  }

  // MARK: - Header

  private var headerView: some View {
    VStack(spacing: 8) {
      Image(systemName: "cup.and.saucer.fill")
        .font(.system(size: 48))
        .foregroundStyle(.brown)
      Text("Buy Me a Coffee")
        .font(.system(.title2, design: .rounded, weight: .bold))
      Text("If you enjoy Hackery, consider leaving a tip!")
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }

  // MARK: - Buy Button

  private func buyButton(_ product: Product) -> some View {
    Button {
      Task { await tipStore.purchase() }
    } label: {
      HStack {
        Text("Buy Coffee")
          .font(.system(.headline, design: .rounded))
        Text(product.displayPrice)
          .font(.system(.headline, design: .rounded, weight: .semibold))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      #if os(iOS)
      .background(Color("cardBg"), in: RoundedRectangle(cornerRadius: 14))
      #elseif os(visionOS)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
      #endif
    }
    .buttonStyle(.plain)
    .disabled(tipStore.purchaseState == .purchasing)
    .opacity(tipStore.purchaseState == .purchasing ? 0.5 : 1)
  }

  // MARK: - Thank You

  private var thankYouView: some View {
    VStack(spacing: 16) {
      Image(systemName: "heart.fill")
        .font(.system(size: 56))
        .foregroundStyle(.pink)
        .symbolEffect(.bounce, value: tipStore.purchaseState)
      Text("Thank You!")
        .font(.system(.title, design: .rounded, weight: .bold))
      Text("Your support means the world.")
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
    }
  }
}
