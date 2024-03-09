//
//  CommentButton.swift
//  Hackery
//
//  Created by Tim Shim on 31/5/20.
//  Copyright © 2020 Tim Shim. All rights reserved.
//

import SwiftUI

struct CommentButton: View {
    var count: Int
    
    var body: some View {
        Text(verbatim: "\(count > 100 ? "100+" : "\(count)") \(count == 1 ? "COMMENT" : "COMMENTS")")
            .font(.custom("Lato-Regular", size: 13))
            .foregroundColor(Color("titleColor"))
            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("borderColor"), lineWidth: 1))
    }
}

struct CommentButton_Previews: PreviewProvider {
    static var previews: some View {
        CommentButton(count: 1)
    }
}
