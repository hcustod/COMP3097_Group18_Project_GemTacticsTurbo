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
            VStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "Swap",
                    value: "Adjacent"
                )

                StatCard(
                    title: "Match",
                    value: "3+"
                )

                StatCard(
                    title: "Goal",
                    value: "Hit Target"
                )

                StatCard(
                    title: "Limit",
                    value: "Moves & Time"
                )
            }

            SecondaryButton(title: "Home") {
                router.show(.home)
            }
        }
        .navigationTitle("How To Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}
