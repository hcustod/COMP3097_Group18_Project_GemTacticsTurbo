//
//  HowToPlayView.swift
//  GemTacticsTurbo
//
//  Created by Henrique Custodio on 3/26/26.
//

import SwiftUI

struct HowToPlayView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        ScreenContainer(title: "How To Play") {
            SectionHeader(title: "Quick Rules")

            VStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "Swap",
                    value: "Adjacent Only"
                )

                StatCard(
                    title: "Match",
                    value: "3 Or More"
                )

                StatCard(
                    title: "Score",
                    value: "Build Combos"
                )

                StatCard(
                    title: "Goal",
                    value: "Hit The Target"
                )
            }

            SecondaryButton(title: "Back to Home") {
                router.show(.home)
            }
        }
        .navigationTitle("How To Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}
