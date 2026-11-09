import SwiftUI

/// Small card: label, numeral, caption. Shows "—" when there is no value yet.
struct StatTile: View {
    let label: String
    let value: Int?
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(FPFont.label).foregroundStyle(FPColor.text2)
            Text(value.map { $0.formatted() } ?? "—").font(FPFont.tileNumeral).foregroundStyle(FPColor.text)
            if let caption {
                Text(caption).font(FPFont.caption).foregroundStyle(FPColor.text2)
            }
        }
        .fpCard(radius: FPRadius.tile)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack { StatTile(label: "Today", value: 64, caption: "62 unfolds"); StatTile(label: "Daily average", value: nil) }.padding()
}
