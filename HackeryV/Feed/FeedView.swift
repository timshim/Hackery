//
//  FeedView.swift
//  HackeryV
//
//  Created by Tim Shim on 6/8/23.
//  Copyright © 2023 Tim Shim. All rights reserved.
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var viewModel: FeedViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoaderView()
                }
                ContentView(viewModel: viewModel)
            }
        }
        .ornament(attachmentAnchor: .scene(.bottom), ornament: {
            ButtonView(tapped: loadTopStories)
                .glassBackgroundEffect()
        })
        .onAppear {
            loadTopStories()
        }
    }
    
    private func loadTopStories() {
        Task {
            await viewModel.loadTopStories()
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: FeedViewModel
    
    let columns = [
        GridItem(.adaptive(minimum: 400), alignment: .top)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, content: {
                ForEach(viewModel.stories, id: \.id) { story in
                    StoryView(story: story)
                        .padding(8)
                        .background(.regularMaterial, in: .rect(cornerRadius: 32))
                        .contentShape(.hoverEffect, .rect(cornerRadius: 32))
                        .hoverEffect()
                        .environmentObject(viewModel)
                        .onTapGesture() {
                            if let url = URL(string: story.url) {
                                UIApplication.shared.open(url)
                            }
                        }
                }
            })
        }
    }
}

struct StoryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(.regularMaterial, in: .rect(cornerRadius: 32))
            .hoverEffect()
    }
}

struct ButtonView: View {
    var tapped: (() -> Void)?
    
    var body: some View {
        Button(action: {
            tapped?()
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .frame(width: 60, height: 60)
                .padding()
        }
        .buttonStyle(.plain)
    }
}

struct LoaderView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}

//struct FeedView_Previews: PreviewProvider {
//    static var previews: some View {
//        FeedView()
//    }
//}

//struct FeedView: View {
//    var body: some View {
//        NavigationSplitView {
//            List {
//                Text("Item")
//            }
//            .navigationTitle("Sidebar")
//        } detail: {
//            VStack {
//                Model3D(named: "Scene", bundle: realityKitContentBundle)
//                    .padding(.bottom, 50)
//
//                Text("Hello, world!")
//            }
//            .navigationTitle("Content")
//            .padding()
//        }
//    }
//}
//
//#Preview {
//    FeedView()
//}
