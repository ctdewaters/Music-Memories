//
//  Settings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/11/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

import SwiftUI

//MARK: - Settings View
struct SettingsView : View {
    
    @State var settings = Settings.shared
    
    ///The dynamic memory settings.
    let dynamicMemorySettings = Settings.all["Dynamic Memories"]!
    
    ///The app info.
    let appInfo = Settings.all["App Info"]!
    
    @State var boolean = true
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Dynamic Memories").font(.subheadline)) {
                    SettingToggle(settingsOption: dynamicMemorySettings.first, binding: $settings.dynamicMemoriesEnabled)
                    if settings.dynamicMemoriesEnabled {
                        SettingNavigationButton(settingsOption: self.dynamicMemorySettings[1], boundUpdatePeriod: self.$settings.dynamicMemoriesUpdatePeriod)
                        SettingToggle(settingsOption: self.dynamicMemorySettings[2], binding: self.$settings.addDynamicMemoriesToLibrary)
                    }
                }
                Section(header: Text("App Information").font(.subheadline)) {
                    ForEach(appInfo.identified(by: \.displayTitle)) { option in
                        SettingInfo(settingsOption: option)
                    }
                }
            }
                .navigationBarTitle(Text("Settings"), displayMode: .automatic)
                .listStyle(.grouped)
            }.accentColor(Color("themeColor"))
    }
}

//MARK: - Setting Toggle
struct SettingToggle : View {
    ///The settings option for this cell.
    var settingsOption: Settings.Option?
    
    ///The value bound to this view's toggle.
    @Binding var binding: Bool
    
    var body: some View {
        HStack {
            Toggle(isOn: $binding) {
                SettingInfo(settingsOption: self.settingsOption)
            }
        }
    }
}

//MARK: - Setting Navigation Button
struct SettingNavigationButton : View {
    
    ///The settings option for this cell.
    var settingsOption: Settings.Option?
    
    @Binding var boundUpdatePeriod: Settings.DynamicMemoriesUpdatePeriod

    var body: some View {
        NavigationButton(destination: Text("Picker Here"), isDetail: false) {
            SettingInfo(settingsOption: self.settingsOption)
        }
    }
}

//MARK: - Setting Info
struct SettingInfo : View {
    
    ///The settings option for this cell.
    var settingsOption: Settings.Option?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(settingsOption?.displayTitle ?? "")")
                .font(.headline)
            Text("\(settingsOption?.subtitle ?? "")")
                .font(.subheadline)
        }
            .multilineTextAlignment(.leading)
            .lineLimit(nil)

    }
}

//MARK: - Previews
#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView().colorScheme(.dark)
            SettingsView().colorScheme(.light)
        }
    }
}
#endif
