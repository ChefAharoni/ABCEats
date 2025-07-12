//
//  RestaurantListItemView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI

struct RestaurantListItemView: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack(spacing: 12) {
            // Grade badge
            gradeBadge
            
            // Restaurant info
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(restaurant.foodType)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(restaurant.displayAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var gradeBadge: some View {
        ZStack {
            Circle()
                .fill(gradeColor)
                .frame(width: 40, height: 40)
            
            Text(restaurant.grade)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private var gradeColor: Color {
        switch restaurant.grade.uppercased() {
        case "A":
            return .green
        case "B":
            return .yellow
        case "C":
            return .red
        default:
            return .gray
        }
    }
} 