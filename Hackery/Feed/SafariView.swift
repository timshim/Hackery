//
//  SafariView.swift
//  Hackery
//
//  Created by Tim Shim on 31/5/20.
//  Copyright © 2020 Tim Shim. All rights reserved.
//

import SwiftUI
import SafariServices

struct SafariView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    var url: URL
    
    var body: some View {
        SafariViewController(url: url, mode: mode)
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
    }
}

struct SafariViewController: UIViewControllerRepresentable {

    var url: URL
    var mode: Binding<PresentationMode>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = context.coordinator
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {

    }
    
    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        private var parent: SafariViewController

        init(_ safariViewController: SafariViewController) {
            self.parent = safariViewController
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.mode.wrappedValue.dismiss()
        }
    }
}

struct SafariView_Previews: PreviewProvider {
    static var previews: some View {
        SafariView(url: URL(string: "https://google.com")!)
    }
}
