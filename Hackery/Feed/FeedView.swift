//
//  FeedView.swift
//  Hackery
//
//  Created by Tim Shim on 6/10/19.
//  Copyright © 2019 Tim Shim. All rights reserved.
//

import SwiftUI
import SafariServices

struct FeedView: View {
    @EnvironmentObject private var fc: FeedController
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("background")
                    .edgesIgnoringSafeArea(.all)
                List {
                    ForEach(self.fc.stories, id: \.id) { story in
                        ZStack {
                            StoryView(story: story).environmentObject(self.fc)
                            NavigationLink(destination: SafariView(url: URL(string: story.url)!)) {
                                EmptyView()
                            }
                            .frame(width: 0)
                            .opacity(0)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
                        .listRowBackground(Color("background"))
                    
                    }
                    .cornerRadius(10)
                    .padding(.horizontal, 8)
                }
                .padding(.top, 50)
                .edgesIgnoringSafeArea(.top)
                VStack {
                    Spacer()
                    Button(action: {
                        self.fc.reload()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color("titleColor"))
                            .padding(.bottom, 6)
                    }
                    .background(Circle().foregroundColor(Color("cardBg")).frame(width: 60, height: 60))
                    .padding()
                    .shadow(color: Color("shadow"), radius: 20, x: 0, y: 20)
                }
                if fc.isLoading {
                    VStack {
                        Spacer()
                        LoadingView()
                            .frame(width: 60, height: 60, alignment: .center)
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
    
    init() {
        UITableView.appearance().tableFooterView = UIView()
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .clear
        UITableView.appearance().showsVerticalScrollIndicator = false
    }
}

struct MyButtonStyle: ButtonStyle {

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .padding()
      .foregroundColor(.white)
      .background(configuration.isPressed ? Color.red : Color.blue)
      .cornerRadius(8.0)
  }

}


struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
