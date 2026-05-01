//
//  TipJarView.swift
//  Hackery
//
//  Created by Tim Shim on 4/4/26.
//  Copyright © 2026 Tim Shim. All rights reserved.
//

import SwiftUI
import StoreKit

struct TipJarView: View {
  @Environment(TipStore.self) private var tipStore
  @Environment(EngagementTracker.self) private var engagement
  @Environment(\.dismiss) private var dismiss

  /// Shows the tip jar as a small card centered over existing content instead
  /// of as a sheet, and is called to close it.
  var onClose: (() -> Void)?

  var body: some View {
    #if os(iOS)
    if onClose != nil {
      card
    } else {
      sheet
    }
    #elseif os(visionOS)
    VStack(spacing: 24) {
      if tipStore.purchaseState == .success {
        thankYouView
      } else {
        Image(systemName: "cup.and.heat.waves.fill")
          .font(.system(size: 48))
        if let product = tipStore.product {
          ProductView(id: product.id)
            .productViewStyle(.large)
        }
      }
    }
    .frame(width: 360, height: 380)
    .overlay(alignment: .topLeading) {
      Button { dismiss() } label: {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.secondary)
          .frame(width: 36, height: 36)
          .background(.ultraThinMaterial, in: Circle())
      }
      .buttonStyle(.plain)
      .padding(16)
    }
    .task {
      tipStore.listenForTransactions()
      await tipStore.loadProduct()
    }
    .onChange(of: tipStore.purchaseState) { _, newValue in
      if newValue == .success {
        engagement.recordTip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
          dismiss()
          tipStore.resetState()
        }
      }
    }
    .onInAppPurchaseCompletion { _, result in
      if case .success(.success(_)) = result {
        tipStore.markSuccess()
      }
    }
    #endif
  }

  private func close() {
    if let onClose {
      onClose()
    } else {
      dismiss()
    }
  }

  // MARK: - Presentations

  #if os(iOS)
  private var content: some View {
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
    .task {
      tipStore.listenForTransactions()
      await tipStore.loadProduct()
    }
    .onChange(of: tipStore.purchaseState) { _, newValue in
      if newValue == .success {
        engagement.recordTip()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
          close()
          tipStore.resetState()
        }
      }
    }
  }

  private var sheet: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Spacer()
        content
        Spacer()
      }
      .padding(24)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color("cardBg"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button { close() } label: {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .presentationDetents([.medium])
    .interactiveDismissDisabled(tipStore.purchaseState == .purchasing)
  }

  private var card: some View {
    ZStack {
      // Clear, but still catches taps outside the card to close it.
      Color.clear
        .contentShape(Rectangle())
        .ignoresSafeArea()
        .onTapGesture {
          if tipStore.purchaseState != .purchasing { close() }
        }
      content
        .padding(.horizontal, 24)
        .padding(.top, 44)
        .padding(.bottom, 24)
        .frame(width: 340)
        .background(Color("cardBg"), in: RoundedRectangle(cornerRadius: 28))
        .overlay(alignment: .topLeading) {
          Button { close() } label: {
            Image(systemName: "xmark")
              .font(.system(size: 14, weight: .bold))
              .foregroundStyle(.secondary)
              .frame(width: 36, height: 36)
              .glassEffect(in: .circle)
          }
          .buttonStyle(.plain)
          .disabled(tipStore.purchaseState == .purchasing)
          .accessibilityLabel("Close")
          .padding(12)
        }
    }
    .accessibilityAddTraits(.isModal)
  }
  #endif

  // MARK: - Header

  private var headerView: some View {
    VStack(spacing: 8) {
      Image(systemName: "cup.and.heat.waves.fill")
        .font(.system(size: 48))
      Text("Buy me a coffee")
        .font(.custom("Lato-Bold", size: 22, relativeTo: .title2))
      Text("If you enjoy Hackery, consider leaving a tip!")
        .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
  }

  // MARK: - Buy Button

  #if os(iOS)
  private func buyButton(_ product: Product) -> some View {
    Button {
      Task { await tipStore.purchase() }
    } label: {
      HStack {
        Text("Tip me")
          .font(.custom("Lato-Bold", size: 20, relativeTo: .title3))
          .foregroundStyle(.white)
        // Plain white rather than inverted hierarchical styles, which blend
        // with the green and invert to magenta.
        Text(product.displayPrice)
          .font(.custom("Lato-Bold", size: 20, relativeTo: .title3))
          .foregroundStyle(.white.opacity(0.75))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 18)
      .background(Color.green, in: Capsule())
    }
    .buttonStyle(.plain)
    .disabled(tipStore.purchaseState == .purchasing)
    .opacity(tipStore.purchaseState == .purchasing ? 0.5 : 1)
  }
  #endif

  // MARK: - Thank You

  private var thankYouView: some View {
    VStack(spacing: 16) {
      Image(systemName: "heart.fill")
        .font(.system(size: 56))
        .foregroundStyle(.pink)
        .symbolEffect(.bounce, value: tipStore.purchaseState)
      Text("Thank you!")
        .font(.custom("Lato-Bold", size: 24, relativeTo: .title))
      Text("Your support means the world.")
        .font(.custom("Lato-Regular", size: 15, relativeTo: .subheadline))
        .foregroundStyle(.secondary)
    }
  }
}
