//
//  LoadingView.swift
//  Hackery
//
//  Created by Tim Shim on 1/6/20.
//  Copyright © 2020 Tim Shim. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Text("Loading...")
//        GeometryReader { (geometry: GeometryProxy) in
//            ForEach(0..<5) { index in
//                Group {
//                    Circle()
//                        .foregroundColor(Color("loader"))
//                        .frame(width: geometry.size.width / 5, height: geometry.size.height / 5)
//                        .scaleEffect(!self.isAnimating ? 1 - CGFloat(index) / 5 : 0.2 + CGFloat(index) / 5)
//                        .offset(y: geometry.size.width / 10 - geometry.size.height / 2)
//                }
//                .frame(width: geometry.size.width, height: geometry.size.height)
//                .rotationEffect(!self.isAnimating ? .degrees(0) : .degrees(360))
//                .animation(Animation.timingCurve(0.5, 0.15 + Double(index) / 5, 0.25, 1, duration: 1.5)
//                .repeatForever(autoreverses: false))
//            }
//        }
//        .aspectRatio(1, contentMode: .fit)
//        .onAppear {
//            self.isAnimating = true
//        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
