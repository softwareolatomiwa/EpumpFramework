import SwiftUI

public struct EpumpFramework {
    public struct MainTextField: View {
        @State var placeholder: String
        @Binding var text: String
        
        /// This is a TextField that is consistent with our design
        /// - Parameters:
        ///   - placeholder: The text you see before you've written anything
        ///   - text: Binding for the text that gets typed into the field
        public init(placeholder: String, text: Binding<String>){
            self._placeholder = State(initialValue: placeholder)
            self._text = text
        }
        
        public var body: some View{
            HStack{
                Image(systemName: "person").foregroundColor(.blue)
                TextField(self.placeholder, text: self.$text)
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.blue)
            }.padding()
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 2))
        }
    }
}
