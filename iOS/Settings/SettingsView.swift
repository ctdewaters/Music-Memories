//
//  Settings.swift
//  Music Memories
//
//  Created by Collin DeWaters on 6/11/19.
//  Copyright © 2019 Collin DeWaters. All rights reserved.
//

#if canImport(SwiftUI)
import SwiftUI
#endif

//MARK: - Settings View

@available(iOS 13.0, *)
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
                Section(header: Text("DYNAMIC MEMORIES").font(.footnote)) {
                    SettingToggle(settingsOption: dynamicMemorySettings.first, binding: $settings.dynamicMemoriesEnabled)
                    if settings.dynamicMemoriesEnabled {
                        SettingDurationPicker(settingsOption: self.dynamicMemorySettings[1], boundUpdatePeriod: self.$settings.dynamicMemoriesUpdatePeriod)
                        SettingToggle(settingsOption: self.dynamicMemorySettings[2], binding: self.$settings.addDynamicMemoriesToLibrary)
                    }
                }
                Section(header: Text("APP INFO").font(.footnote)) {
                    ForEach(appInfo) { option in
                        if option == .logo {
                            SettingLogo()                        .listRowBackground(Color(UIColor.background))
                        }
                        else {
                            SettingInfo(settingsOption: option)
                        }
                    }
                }
            }
            .navigationBarTitle(Text("Settings"), displayMode: .automatic)
            .listStyle(GroupedListStyle())
            
        }
        .accentColor(Color("themeColor"))
    }
}

//MARK: - Setting Toggle
@available(iOS 13.0, *)
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

//MARK: - Setting Duration Picker
@available(iOS 13.0, *)
struct SettingDurationPicker : View {
    
    ///The settings option for this cell.
    var settingsOption: Settings.Option?
    
    @Binding var boundUpdatePeriod: Settings.DynamicMemoriesUpdatePeriod

    var body: some View {
        Picker(selection: $boundUpdatePeriod, label: SettingInfo(settingsOption: self.settingsOption)) {
            ForEach(Settings.allUpdatePeriods) { duration in
                Text("\(duration.rawValue)").tag(duration)
            }
        }
    }
}

//MARK: - Setting Info
@available(iOS 13.0, *)
struct SettingInfo : View {
    ///The settings option for this cell.
    var settingsOption: Settings.Option?
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if settingsOption?.displayIconSystemName != nil {
                Image(systemName: settingsOption!.displayIconSystemName!)
                    .foregroundColor(.white)
                    .frame(width: 33, height: 33, alignment: .center)
                    .background(Color(settingsOption!.displayIconBackgroundColor!))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            VStack(alignment: .leading) {
                Text("\(settingsOption!.isApplicationInfo ? "" : settingsOption?.displayTitle ?? "")")
                    .font(.headline)
                Text("\(settingsOption!.isApplicationInfo ? settingsOption?.displayTitle ?? "" : settingsOption?.subtitle ?? "")")
                    .font(.caption)
            }
        }
            .multilineTextAlignment(.leading)
            .lineLimit(nil)

    }
}

//MARK: - Setting Logo
@available(iOS 13.0, *)
struct SettingLogo : View {
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                Spacer()
                Image("CTDLogo")
                    .resizable()
                    .frame(width: 200, height: 200, alignment: .center)
                Spacer()
            }
        }
    }
}

//MARK: - Previews
#if DEBUG
@available(iOS 13.0, *)
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView().colorScheme(.dark)
            SettingsView().colorScheme(.light)
        }
    }
}
#endif
