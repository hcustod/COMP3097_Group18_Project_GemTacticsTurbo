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
        ScreenContainer(
            title: "How To Play",
            subtitle: "Learn the core match-3 loop before you jump into a timed round."
        ) {
            SectionHeader(
                title: "Rules",
                subtitle: "Swap adjacent gems, make matches of three or more, and reach the target score before time or moves run out."
            )

            VStack(spacing: AppSpacing.medium) {
                StatCard(
                    title: "Swap",
                    value: "Adjacent Only",
                    detail: "Tap one gem, then tap a neighboring gem. Invalid swaps animate and do not consume a move."
                )

                StatCard(
                    title: "Match",
                    value: "3 Or More",
                    detail: "Horizontal and vertical matches clear gems, trigger gravity, and can create cascades."
                )

                StatCard(
                    title: "Score",
                    value: "Combos Matter",
                    detail: "Longer matches and deeper cascades award more points, scaled by the selected difficulty."
                )

                StatCard(
                    title: "Win Condition",
                    value: "Hit The Target",
                    detail: "Reach the difficulty target score before the timer reaches zero or you run out of moves."
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
