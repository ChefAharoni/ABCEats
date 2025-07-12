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
                Section("Search") {
                    TextField("Restaurant name or address", text: $searchViewModel.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section("Grade") {
                    Picker("Grade", selection: $searchViewModel.selectedGrade) {
                        ForEach(searchViewModel.availableGrades, id: \.self) { grade in
                            Text(grade).tag(grade)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Borough") {
                    Picker("Borough", selection: $searchViewModel.selectedBorough) {
                        ForEach(searchViewModel.availableBoroughs, id: \.self) { borough in
                            Text(borough).tag(borough)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Food Type") {
                    Picker("Food Type", selection: $searchViewModel.selectedFoodType) {
                        ForEach(searchViewModel.availableFoodTypes, id: \.self) { foodType in
                            Text(foodType).tag(foodType)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Zip Code") {
                    TextField("Zip Code", text: $searchViewModel.selectedZipCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Clear All Filters") {
                        searchViewModel.clearFilters()
                    }
                    .foregroundColor(.red)
                }
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
} 