import SwiftUI

struct NoContact: View {
    @Environment(DeepLinkRouter.self) private var deepLinkRouter
    
    var body: some View {
        Button {
            deepLinkRouter.showContactSection = true
            deepLinkRouter.selectedTab = 2
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text("No added contact")
                        .font(.title3)
                        .foregroundStyle(.destructT)
                    
                    Text("Add at least 1 emergency contact so we can notify them when you need help.")
                        .foregroundStyle(.destructT)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                    
                    
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.destructT)
                
            }
            .frame(maxWidth: .infinity, alignment: .init(horizontal: .leading, vertical: .top))
            .padding(16)
            .background(Color(.destruct))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview("Light") {
    NoContact()
        .environment(DeepLinkRouter.shared)
        .padding(16)
}

#Preview("Dark") {
    NoContact()
        .environment(DeepLinkRouter.shared)
        .preferredColorScheme(.dark)
        .padding(16)
}
