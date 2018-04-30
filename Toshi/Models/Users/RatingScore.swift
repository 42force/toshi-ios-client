// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

struct RatingScore: Codable {
    static var zero: RatingScore {
        return RatingScore(reputationScore: 0.0, averageRating: 0.0, reviewCount: 0, stars: StarsCount.zero)
    }

    let reputationScore: Double
    let averageRating: Double
    let reviewCount: Int
    let stars: StarsCount

    enum CodingKeys: String, CodingKey {
        case
        averageRating = "average_rating",
        reputationScore = "reputation_score",
        reviewCount = "review_count",
        stars
    }
}
