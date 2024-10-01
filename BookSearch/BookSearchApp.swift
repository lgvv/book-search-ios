import SwiftUI
import TestPkg

@main
struct BookSearchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print(TestPkg.value)
                }
        }
    }
}
