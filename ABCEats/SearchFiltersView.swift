//
//  SearchFiltersView.swift
//  ABCEats
//
//  Created by Amit Aharoni on 7/12/25.
//

import SwiftUI

struct SearchFiltersView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                searchSection
                gradeSection
                boroughSection
                clearFiltersSection
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
    
    private var searchSection: some View {
        Section("Search") {
            TextField("Restaurant name or address", text: $searchViewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var gradeSection: some View {
        Section("Grade") {
            Picker("Grade", selection: $searchViewModel.selectedGrade) {
                ForEach(searchViewModel.availableGrades, id: \.self) { grade in
                    Text(grade).tag(grade as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var boroughSection: some View {
        Section("Borough") {
            Picker("Borough", selection: $searchViewModel.selectedBorough) {
                ForEach(searchViewModel.getAvailableBoroughs(), id: \.self) { borough in
                    Text(borough).tag(borough as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
    
    private var clearFiltersSection: some View {
        Section {
            Button("Clear All Filters") {
                searchViewModel.clearFilters()
            }
            .foregroundColor(.red)
        }
    }
} 