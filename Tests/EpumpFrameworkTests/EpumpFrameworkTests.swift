import XCTest
import SwiftUI
@testable import EpumpFramework

final class EpumpFrameworkTests: XCTestCase {
    @State var text: String = ""
    func testExample() {
        var body: some View{
            EpumpFramework.MainTextField(placeholder: "Testing", text: $text)
        }
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
