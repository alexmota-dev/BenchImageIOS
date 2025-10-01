//
//  BenchImageIOSApp.swift
//  BenchImageIOS
//
//  Created by Alex Mota on 22/09/25.
//

import SwiftUI

@main
struct BenchImageIOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: BenchImageViewModel())
        }
    }
}
