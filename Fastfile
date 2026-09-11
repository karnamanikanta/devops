# This is the minimum version number required.
fastlane_version "2.226.0"
default_platform :ios
platform :ios do
  before_all do
    # ENV["SLACK_URL"] = "https://hooks.slack.com/services/..."
  end

  private_lane :sanitize_usdk_framework_metadata do
    # Some uSDK packages ship with app-style metadata that can confuse App Store upload validation.
    plist_paths = [
      "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/uSDK.xcframework/ios-arm64/uSDK.framework/Info.plist",
      "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/uSDK.xcframework/ios-arm64_x86_64-simulator/uSDK.framework/Info.plist"
    ]

    plist_paths.each do |plist_path|
      next unless File.exist?(plist_path)

      sh(%Q[/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType FMWK" "#{plist_path}"])
    end
  end
  #--------------------------------------------------------------------Lower_Lanes----------------------------------------------------------------------------

  desc "Create Lowers build, with enterprise certificates"
  desc "Fully parameterized enterprise build for any region"
  lane :enterprise_build do |options|
    ENV["PRODUCTION_BUILD"] = "false"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202402.1.0"

    xcode_select("/Applications/Xcode_26.0.app")

    cocoapods(
      podfile: "./Podfile",
      use_bundle_exec: true,
      silent: false
    )

    available_cores = sh("sysctl -n hw.physicalcpu").strip

    archive_path = "Subway/Archive/#{options[:archive_suffix]}.xcarchive"
    output_folder = "./build/#{options[:archive_suffix]}/"

    gym(
      workspace: "Subway.xcworkspace",
      scheme: options[:scheme],
      skip_profile_detection: true,
      configuration: options[:configuration],
      destination: "generic/platform=iOS",
      archive_path: archive_path,
      export_method: "enterprise",
      export_options: options[:export_options_path],
      codesigning_identity: "iPhone Distribution: DOCTOR'S ASSOCIATES, INC.",
      output_directory: output_folder,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: false,
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )

    sh("find \"#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Archive/#{options[:archive_suffix]}.xcarchive/dSYMs\" -name \"*.dSYM\" | xargs -I {} #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Pods/FirebaseCrashlytics/upload-symbols -gsp #{options[:google_service_plist]} -p ios {}")

    ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/#{options[:archive_suffix]}/#{options[:ipa_source_name]}"
    ipa_dest_folder = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/#{options[:archive_suffix]}/"

    app_version = get_info_plist_value(path: options[:info_plist_path], key: "CFBundleShortVersionString")
    build_number = get_info_plist_value(path: options[:info_plist_path], key: "CFBundleVersion")
    source_branch = ENV['BUILD_SOURCEBRANCH']

    ipa_filename = "SUBWAY_#{options[:region]}_#{options[:archive_suffix]}_#{app_version}_#{build_number}.ipa"
    File.rename(ipa_source_path, "#{ipa_dest_folder}#{ipa_filename}")
    puts "IPArenamedto: #{ipa_dest_folder}"

    firebase_app_distribution(
      service_credentials_file: ENV['SECUREFILEPATH'],
      app: options[:firebase_app_id],
      groups: options[:firebase_groups],
      ipa_path: "#{ipa_dest_folder}#{ipa_filename}",
      release_notes: "App Version: #{app_version}\n" \
                     "Build Number: #{build_number}\n" \
                     "File Name: #{ipa_filename}\n" \
                     "Branch Name: #{source_branch}",
      verbose: true
    )
  end

  #.............................................................production Lanes..........................................................................


  desc "Create an NAProduction_Beta Build, with the enterprise certificates"
  lane :NA_PRODBetaawsQE do
    ENV["PRODUCTION_BUILD"] = "true"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202403.2.0"
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #sh("system_profiler SPHardwareDataType")
    project_file="Subway.xcworkspace"
    cocoapods(
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #available_cores = Etc.nprocessors
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    # Print the available cores for logging purposes
    #puts "Available CPU cores: #{available_cores}"
    gym(
      workspace: "Subway.xcworkspace",
      scheme: "awsQE",
      skip_profile_detection: "true",
      configuration: "awsQE",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/SubwayawsQE.xcarchive",
      export_method: "app-store",
      export_options: "cicd/NA/devops_files/Prod_Beta/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: Doctor's Associates Inc.",
      output_directory: "./build/awsQE/",
      include_symbols: true,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: false,
      #xcodebuild_formatter: "xcpretty",
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )
    File.rename("#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/awsQE/SUBWAY®.ipa", "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/awsQE/subway_awsQE.ipa")
    api_key = app_store_connect_api_key(
    key_id: "24TDDUK499",
    issuer_id: "69a6de77-da94-47e3-e053-5b8c7c11a4d1",
    key_filepath: "cicd/NA/devops_files/Prod_Beta/Applesubway.p8",
    duration: 1200
    )
    pilot(
    api_key: api_key,
    team_id: '1307548',
    ipa: "./build/awsQE/subway_awsQE.ipa",
    app_identifier: 'com.subway.mobile.subwayapp03.beta',
   )
  end

  desc "Create an Production Build, with the appstore certificates and upload dsyms"
  lane :NAproduction do
    ENV["PRODUCTION_BUILD"] = "true"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202403.2.0"
    sanitize_usdk_framework_metadata
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #sh("system_profiler SPHardwareDataType")
    project_file="Subway.xcworkspace"
    cocoapods(
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #available_cores = Etc.nprocessors
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    # Print the available cores for logging purposes
    #puts "Available CPU cores: #{available_cores}"
    gym(
      workspace: "Subway.xcworkspace",
      scheme: "Subway AppStore",
      skip_profile_detection: "true",
      configuration: "AppStore",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/SubwayAppStore.xcarchive",
      export_method: "app-store",
      export_options: "cicd/NA/devops_files/prod/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: Doctor's Associates Inc.",
      output_directory: "./build/SubwayAppStore/",
      include_symbols: true,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: true,
      xcodebuild_formatter: '',
      suppress_xcode_output: true,
      build_timing_summary: false,
      skip_package_dependencies_resolution: true,
      xcargs: "-quiet -jobs #{available_cores} -parallelizeTargets"
    )
    sh("find \"#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Archive/SubwayAppStore.xcarchive/dSYMs\" -name \"*.dSYM\" | xargs -I {} #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Pods/FirebaseCrashlytics/upload-symbols -gsp #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Firebase/NA/Prod/GoogleService-Info.plist -p ios {}")
    api_key = app_store_connect_api_key(
    key_id: "24TDDUK499",
    issuer_id: "69a6de77-da94-47e3-e053-5b8c7c11a4d1",
    key_filepath: "cicd/NA/devops_files/prod/Applesubway.p8",
    duration: 1200
    )
     # Define the path for the IPA file
     ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/SubwayAppStore/SUBWAY®.ipa"
     ipa_dest_folder = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/SubwayAppStore/"
     # Get app version and build number from the Info.plist
     app_version = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/NA-Info.plist", key: "CFBundleShortVersionString")
     build_number = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/NA-Info.plist", key: "CFBundleVersion")
     source_branch = ENV['BUILD_SOURCEBRANCH']
     # Generate the new IPA file name
     ipa_filename = "SUBWAY_NA_PROD_#{app_version}_#{build_number}.ipa"
     # Rename the IPA file to the new filename
     File.rename(ipa_source_path, "#{ipa_dest_folder}#{ipa_filename}")
     puts "IPArenamedto: #{ipa_dest_folder}"

    # Upload the IPA to Firebase App Distribution
     upload_result =firebase_app_distribution(
     service_credentials_file: ENV['SECUREFILEPATH'],
     app: "1:25655352521:ios:467b649832ed6711f60118",
     groups: "Subway-Mobile-Leads-Group,Subway-Mobile-Testing-Group,Subway-International-Tech-Group",
     ipa_path: "#{ipa_dest_folder}#{ipa_filename}",
     release_notes: "App Version: #{app_version}\n" \
                 "Build Number: #{build_number}\n" \
                 "File Name: #{ipa_filename}\n" \
                 "Branch Name: #{source_branch}",
     verbose: true   
     )
    pilot(
    api_key: api_key,
    #team_id: '1307548',
    apple_id: '6451270781',
    ipa: "#{ipa_dest_folder}#{ipa_filename}",
    app_identifier: 'com.subway.mobile.subwayapp03',
    skip_waiting_for_build_processing: true
    )
    
  end

  desc "Create an Beta Testflight Build, with the enterprise certificates"
  lane :Finland_PRODBetaCFAQE1  do
    ENV["PRODUCTION_BUILD"] = "true"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202403.2.0"
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #sh("system_profiler SPHardwareDataType")
    project_file="Subway.xcworkspace"
    cocoapods(
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #available_cores = Etc.nprocessors
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    # Print the available cores for logging purposes
    #puts "Available CPU cores: #{available_cores}"
    project_file="Subway.xcworkspace"
    cocoapods(
    clean_install: true,    podfile: "./Podfile",
    use_bundle_exec: true
    )
    gym(
      workspace: "Subway.xcworkspace",
      scheme: "EMEA CFA QE1",
      skip_profile_detection: "true",
      configuration: "CFA-QE1",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/EMEA CFAQE1.xcarchive",
      export_method: "app-store",
      export_options: "cicd/EMEA_FINLAND/devops_files/prod_beta/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: Doctor's Associates Inc.",
      output_directory: "./build/EMEACFAQE1/",
      include_symbols: true,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: false,
      #xcodebuild_formatter: "xcpretty",
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )
    api_key = app_store_connect_api_key(
    key_id: "24TDDUK499",
    issuer_id: "69a6de77-da94-47e3-e053-5b8c7c11a4d1",
    key_filepath: "cicd/EMEA_FINLAND/devops_files/prod_beta/Applesubway.p8",
    duration: 1200
    )
     # Define the path for the IPA file
     ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/EMEACFAQE1/SUBWAY® EMEA.ipa"
     ipa_dest_folder = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/EMEACFAQE1/"
     # Get app version and build number from the Info.plist
     app_version = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/Finland-Info.plist", key: "CFBundleShortVersionString")
     build_number = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/Finland-Info.plist", key: "CFBundleVersion")
     # Generate the new IPA file name
     ipa_filename = "SUBWAY_Finland_PRODBeta_#{app_version}_#{build_number}.ipa"
     # Rename the IPA file to the new filename
     File.rename(ipa_source_path, "#{ipa_dest_folder}#{ipa_filename}")
    pilot(
    api_key: api_key,
    team_id: '1307548',
    ipa: "#{ipa_dest_folder}#{ipa_filename}",
    app_identifier: 'com.subway.mobile.subwayapp03.beta',
    skip_waiting_for_build_processing: true
    )
  end

  lane :Finlandproduction do
    ENV["PRODUCTION_BUILD"] = "true"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202403.2.0"
    sanitize_usdk_framework_metadata
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #sh("system_profiler SPHardwareDataType")
    project_file="Subway.xcworkspace"
    cocoapods(
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #available_cores = Etc.nprocessors
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    # Print the available cores for logging purposes
    #puts "Available CPU cores: #{available_cores}"
    gym(
      workspace: "Subway.xcworkspace",
      scheme: "FL AppStore",
      skip_profile_detection: "true",
      configuration: "AppStore",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/EMEAAppStore.xcarchive",
      export_method: "app-store",
      export_options: "cicd/EMEA_FINLAND/devops_files/prod/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: Doctor's Associates Inc.",
      output_directory: "./build/EMEAAppStore/",
      include_symbols: true,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: false,
      #xcodebuild_formatter: "xcpretty",
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )
    sh("find \"#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Archive/EMEAAppStore.xcarchive/dSYMs\" -name \"*.dSYM\" | xargs -I {} #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Pods/FirebaseCrashlytics/upload-symbols -gsp #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Firebase/Finland/Prod/GoogleService-Info.plist -p ios {}")
    api_key = app_store_connect_api_key(
    key_id: "24TDDUK499",
    issuer_id: "69a6de77-da94-47e3-e053-5b8c7c11a4d1",
    key_filepath: "cicd/EMEA_FINLAND/devops_files/prod/Applesubway.p8",
    duration: 1200
    )
     # Define the path for the IPA file
     ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/EMEAAppStore/SUBWAY® EMEA.ipa"
     ipa_dest_folder = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/EMEAAppStore/"
     # Get app version and build number from the Info.plist
     app_version = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/Finland-Info.plist", key: "CFBundleShortVersionString")
     build_number = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/Finland-Info.plist", key: "CFBundleVersion")
     source_branch = ENV['BUILD_SOURCEBRANCH']
     # Generate the new IPA file name
     ipa_filename = "SUBWAY_Finland_PROD_#{app_version}_#{build_number}.ipa"
     # Rename the IPA file to the new filename
     File.rename(ipa_source_path, "#{ipa_dest_folder}#{ipa_filename}")
     puts "IPArenamedto: #{ipa_dest_folder}"
     # Upload the IPA to Firebase App Distribution
     upload_result =firebase_app_distribution(
     service_credentials_file: ENV['SECUREFILEPATH'],
     app: "1:25655352521:ios:12adfffe65200c1ef60118",
     groups: "Subway-Mobile-Leads-Group,Subway-Mobile-Testing-Group,Subway-International-Tech-Group",
     ipa_path: "#{ipa_dest_folder}#{ipa_filename}",
     release_notes: "App Version: #{app_version}\n" \
                 "Build Number: #{build_number}\n" \
                 "File Name: #{ipa_filename}\n" \
                 "Branch Name: #{source_branch}",
     verbose: true   
     )
    pilot(
    api_key: api_key,
    apple_id: '6451270781',
    ipa: "#{ipa_dest_folder}#{ipa_filename}",
    app_identifier: 'com.subway.mobile.emea.FL',
    skip_waiting_for_build_processing: true
    )
  end

  lane :TUKIProduction do
    ENV["PRODUCTION_BUILD"] = "true"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202403.2.0"
    sanitize_usdk_framework_metadata
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #sh("system_profiler SPHardwareDataType")
    project_file="Subway.xcworkspace"
    cocoapods(
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #available_cores = Etc.nprocessors
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    # Print the available cores for logging purposes
    #puts "Available CPU cores: #{available_cores}"
    gym(
      workspace: "Subway.xcworkspace",
      scheme: "TUKI AppStore",
      skip_profile_detection: "true",
      configuration: "AppStore",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/TUKIAppStore.xcarchive",
      export_method: "app-store",
      export_options: "cicd/TUKI/devops_files/prod/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: Doctor's Associates Inc.",
      output_directory: "./build/TUKIAppStore/",
      include_symbols: true,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: false,
      #xcodebuild_formatter: "xcpretty",
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )
    sh("find \"#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Archive/TUKIAppStore.xcarchive/dSYMs\" -name \"*.dSYM\" | xargs -I {} #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Pods/FirebaseCrashlytics/upload-symbols -gsp #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Firebase/TUKI/Prod/GoogleService-Info.plist -p ios {}")
    api_key = app_store_connect_api_key(
    key_id: "24TDDUK499",
    issuer_id: "69a6de77-da94-47e3-e053-5b8c7c11a4d1",
    key_filepath: "cicd/TUKI/devops_files/prod/Applesubway.p8",
    duration: 1200
    )
     # Define the path for the IPA file
     ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/TUKIAppStore/Subway - UK & I.ipa"
     ipa_dest_folder = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/TUKIAppStore/"
     # Get app version and build number from the Info.plist
     app_version = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/TUKI-Info.plist", key: "CFBundleShortVersionString")
     build_number = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/TUKI-Info.plist", key: "CFBundleVersion")
     source_branch = ENV['BUILD_SOURCEBRANCH']
     # Generate the new IPA file name
     ipa_filename = "SUBWAY_TUKI_PROD_#{app_version}_#{build_number}.ipa"
     # Rename the IPA file to the new filename
     File.rename(ipa_source_path, "#{ipa_dest_folder}#{ipa_filename}")
     puts "IPArenamedto: #{ipa_dest_folder}"
     # Upload the IPA to Firebase App Distribution
     upload_result =firebase_app_distribution(
     service_credentials_file: ENV['SECUREFILEPATH'],
     app: "1:25655352521:ios:7798c26779f30fbdf60118",
     groups: "Subway-Mobile-Leads-Group,Subway-Mobile-Testing-Group,Subway-International-Tech-Group",
     ipa_path: "#{ipa_dest_folder}#{ipa_filename}",
     release_notes: "App Version: #{app_version}\n" \
                 "Build Number: #{build_number}\n" \
                 "File Name: #{ipa_filename}\n" \
                 "Branch Name: #{source_branch}",
     verbose: true   
     )
    pilot(
    api_key: api_key,
    apple_id: '6479604296',
    ipa: "#{ipa_dest_folder}#{ipa_filename}",
    app_identifier: 'com.subway.mobile.emea.tuki',
    skip_waiting_for_build_processing: true
    )
  end


   lane :GermanyProduction do
    ENV["PRODUCTION_BUILD"] = "true"
    puts "Setting PRODUCTION_BUILD=false for OneTrust version 202403.2.0"
    sanitize_usdk_framework_metadata
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #sh("system_profiler SPHardwareDataType")
    project_file="Subway.xcworkspace"
    cocoapods(
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #available_cores = Etc.nprocessors
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    # Print the available cores for logging purposes
    #puts "Available CPU cores: #{available_cores}"
    gym(
      workspace: "Subway.xcworkspace",
      scheme: "Germany AppStore",
      skip_profile_detection: "true",
      configuration: "AppStore",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/GermanyAppStore.xcarchive",
      export_method: "app-store",
      export_options: "cicd/Germany/devops_files/prod/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: Doctor's Associates Inc.",
      output_directory: "./build/GermanyAppStore/",
      include_symbols: true,
      clean: false,
      derived_data_path: "./build/derivedData",
      silent: false,
      #xcodebuild_formatter: "xcpretty",
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )
    sh("find \"#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Archive/GermanyAppStore.xcarchive/dSYMs\" -name \"*.dSYM\" | xargs -I {} #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Pods/FirebaseCrashlytics/upload-symbols -gsp #{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Subway/Firebase/Germany/Prod/GoogleService-Info.plist -p ios {}")
    api_key = app_store_connect_api_key(
    key_id: "24TDDUK499",
    issuer_id: "69a6de77-da94-47e3-e053-5b8c7c11a4d1",
    key_filepath: "cicd/Germany/devops_files/prod/Applesubway.p8",
    duration: 1200
    )
     # Define the path for the IPA file
     ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/GermanyAppStore/SUBWAY® Germany.ipa"
     ipa_dest_folder = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/GermanyAppStore/"
     # Get app version and build number from the Info.plist
     app_version = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/Germany-Info.plist", key: "CFBundleShortVersionString")
     build_number = get_info_plist_value(path: "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/Source/Germany-Info.plist", key: "CFBundleVersion")
     source_branch = ENV['BUILD_SOURCEBRANCH']
     # Generate the new IPA file name
     ipa_filename = "SUBWAY_Germany_PROD_#{app_version}_#{build_number}.ipa"
     # Rename the IPA file to the new filename
     File.rename(ipa_source_path, "#{ipa_dest_folder}#{ipa_filename}")
     puts "IPArenamedto: #{ipa_dest_folder}"
     # Upload the IPA to Firebase App Distribution
     upload_result =firebase_app_distribution(
     service_credentials_file: ENV['SECUREFILEPATH'],
     app: "1:25655352521:ios:295b988611794b14f60118",
     groups: "Subway-Mobile-Leads-Group,Subway-Mobile-Testing-Group,Subway-International-Tech-Group",
     ipa_path: "#{ipa_dest_folder}#{ipa_filename}",
     release_notes: "App Version: #{app_version}\n" \
                 "Build Number: #{build_number}\n" \
                 "File Name: #{ipa_filename}\n" \
                 "Branch Name: #{source_branch}",
     verbose: true   
     )
    pilot(
    api_key: api_key,
    apple_id: '6479694657',
    ipa: "#{ipa_dest_folder}#{ipa_filename}",
    app_identifier: 'com.subway.mobile.emea.germany',
    skip_waiting_for_build_processing: true
    )
   end

  #######################SonarQube lanes for all iOS regions###################
  desc "Run Unit Tests for SonarQube report for NA region"
  lane :NA_SONARQUBE do
    require 'json'

    # Step 1: Setup environment
    timestamp = Time.now.to_i
    derived_data_path = "/Users/runner/Library/Developer/Xcode/DerivedData/#{timestamp}"
    xcode_select("/Applications/Xcode_26.0.app")

    # Install CocoaPods
    cocoapods(
      clean_install: false,
      podfile: "./Podfile",
      use_bundle_exec: true,
      silent: false
    )

    # Step 2: Get latest available iOS simulator
    #simulators_json = sh("xcrun simctl list devices --json").strip
    #simulators = JSON.parse(simulators_json)["devices"]
    #latest_runtime = simulators.keys.select { |k| k.include?("iOS") }.max_by { |v| v.scan(/\d+/).map(&:to_i) }

    #best_device = simulators[latest_runtime]
    #  .select { |d| d["isAvailable"] && d["name"].include?("iPhone") }
    #  .sort_by { |d| d["name"] }
    #  .last

    #device_udid = best_device["udid"]
    #device_name = best_device["name"]

    #UI.message("Shutting down simulator to ensure clean state: #{device_name}")
    #sh("xcrun simctl shutdown #{device_udid} || true")

    #UI.message("Booting simulator: #{device_name} (#{device_udid})")
    #sh("xcrun simctl boot #{device_udid} || true")
    #sh("xcrun simctl bootstatus #{device_udid} -b")

    #sleep(10) # short delay to stabilize simulator after boot

    # Disable simulator system alerts
    #sh("defaults write com.apple.iphonesimulator AllowClipboardSharing -bool false || true")
    #sh("defaults write com.apple.iphonesimulator AllowPasteboardSharing -bool false || true")

    # Step 3: Run unit tests with code coverage
    scan(
      clean: true,
      workspace: "Subway.xcworkspace",
      scheme: "CFA UAT",
      code_coverage: true,
      build_for_testing: true,
      derived_data_path: derived_data_path,
      output_style: "raw",
      suppress_xcode_output: false,
      #destination: "id=1CF4D1DA-147A-4D51-AAEA-0F1ABB71878B",
      skip_package_dependencies_resolution: true,
      xcargs: "CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -jobs 3 -parallelizeTargets"
    )

    scan(
      workspace: "Subway.xcworkspace",
      scheme: "CFA UAT",
      fail_build: false,
      skip_build: true,
      test_without_building: true,
      derived_data_path: derived_data_path,
      code_coverage: true,
      output_style: "raw",
      suppress_xcode_output: false,
      #destination: "id=1CF4D1DA-147A-4D51-AAEA-0F1ABB71878B",
      skip_package_dependencies_resolution: true,
      number_of_retries: 2,
      xcargs: "-jobs 3 -parallelizeTargets -disable-concurrent-destination-testing"
    )

    # Step 4: Generate SonarQube report
    sh("brew tap a7ex/homebrew-formulae")
    sh("brew install xcresultparser")
    sh("xcresultparser -c -o xml #{derived_data_path}/Logs/Test/*.xcresult > #{ENV['DEFAULTWORKINGDIRECTORY']}/sonarqube-generic-coverage.xml")
  end

  desc "Run Unit Tests for SonarQube report for Finland region"
  lane :FL_SONARQUBE do
        #step 1: Download cocoapods
        timestamp = Time.now.to_i
        derived_data_path = "/Users/runner/Library/Developer/Xcode/DerivedData/#{timestamp}"
        available_cores = sh("sysctl -n hw.physicalcpu").strip
        xcode_select("/Applications/Xcode_26.0.app")
        project_file="Subway.xcworkspace"
        cocoapods(
        clean_install: false,
        podfile: "./Podfile",
        use_bundle_exec: true,
        silent: false
        )
        #working solution
        scan(
          clean: true,
          workspace: "Subway.xcworkspace",
          scheme: "FL CFA UAT",
          skip_build: true,
          output_style: "raw",
          build_for_testing: true,
          derived_data_path: derived_data_path,
          code_coverage: true,
          suppress_xcode_output: false,
          xcodebuild_formatter: '',
          skip_package_dependencies_resolution: true,
          xcargs: "CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -jobs 3 -parallelizeTargets"
        )
      # Step 2: Run the tests using Scan
        scan(
          workspace: "Subway.xcworkspace",
          scheme: "FL CFA UAT",
          fail_build: false,
          skip_build: true,
          output_style: "raw",
          test_without_building: true,
          derived_data_path: derived_data_path,
          code_coverage: true,
          suppress_xcode_output: false,
          skip_package_dependencies_resolution: true,
          number_of_retries: 2,
          xcargs: "-jobs 3 -parallelizeTargets -disable-concurrent-destination-testing"
        )
        #Step 3: Get sq xml report
        sh "brew tap a7ex/homebrew-formulae"
        sh "brew install xcresultparser"
        sh """
            xcresultparser -c -o xml #{derived_data_path}/Logs/Test/*.xcresult > #{ENV['DEFAULTWORKINGDIRECTORY']}/sonarqube-generic-coverage.xml
          """
    end

  desc "Run Unit Tests for SonarQube report for Germany region"
  lane :GERMANY_SONARQUBE do
      #step 1: Download cocoapods
      timestamp = Time.now.to_i
      derived_data_path = "/Users/runner/Library/Developer/Xcode/DerivedData/#{timestamp}"
      available_cores = sh("sysctl -n hw.physicalcpu").strip
      xcode_select("/Applications/Xcode_26.0.app")
      project_file="Subway.xcworkspace"
      cocoapods(
      clean_install: false,
      podfile: "./Podfile",
      use_bundle_exec: true,
      silent: false
      )
      #working solution
      scan(
        clean: true,
        workspace: "Subway.xcworkspace",
        scheme: "Germany CFA UAT",
        skip_build: true,
        output_style: "raw",
        build_for_testing: true,
        derived_data_path: derived_data_path,
        code_coverage: true,
        suppress_xcode_output: false,
        xcodebuild_formatter: '',
        skip_package_dependencies_resolution: true,
        xcargs: "CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -jobs 3 -parallelizeTargets"
      )
      # Step 2: Run the tests using Scan
      scan(
        workspace: "Subway.xcworkspace",
        scheme: "Germany CFA UAT",
        fail_build: false,
        skip_build: true,
        output_style: "raw",
        test_without_building: true,
        derived_data_path: derived_data_path,
        code_coverage: true,
        suppress_xcode_output: false,
        skip_package_dependencies_resolution: true,
        number_of_retries: 2,
        xcargs: "-jobs 3 -parallelizeTargets -disable-concurrent-destination-testing"
      )
      # Step 3: Get sq xml report
      sh "brew tap a7ex/homebrew-formulae"
      sh "brew install xcresultparser"
      sh """
          xcresultparser -c -o xml #{derived_data_path}/Logs/Test/*.xcresult > #{ENV['DEFAULTWORKINGDIRECTORY']}/sonarqube-generic-coverage.xml
        """
    end

  desc "Run Unit Tests for SonarQube report for TUKI region"
  lane :TUKI_SONARQUBE do
    #step 1: Download cocoapods
    timestamp = Time.now.to_i
    derived_data_path = "/Users/runner/Library/Developer/Xcode/DerivedData/#{timestamp}"
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    xcode_select("/Applications/Xcode_26.0.app")
    project_file="Subway.xcworkspace"
    cocoapods(
    clean_install: false,
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    #working solution
    scan(
      clean: true,
      workspace: "Subway.xcworkspace",
      scheme: "TUKI CFA UAT",
      skip_build: true,
      output_style: "raw",
      build_for_testing: true,
      derived_data_path: derived_data_path,
      code_coverage: true,
      suppress_xcode_output: false,
      xcodebuild_formatter: '',
      skip_package_dependencies_resolution: true,
      xcargs: "CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO -jobs 3 -parallelizeTargets"
    )
    # Step 2: Run the tests using Scan
    scan(
      workspace: "Subway.xcworkspace",
      scheme: "TUKI CFA UAT",
      fail_build: false,
      skip_build: true,
      output_style: "raw",
      test_without_building: true,
      derived_data_path: derived_data_path,
      code_coverage: true,
      suppress_xcode_output: false,
      skip_package_dependencies_resolution: true,
      number_of_retries: 2,
      xcargs: "-jobs 3 -parallelizeTargets -disable-concurrent-destination-testing"
    )
    # Step 3: Get sq xml report
    sh "brew tap a7ex/homebrew-formulae"
    sh "brew install xcresultparser"
    sh """
        xcresultparser -c -o xml #{derived_data_path}/Logs/Test/*.xcresult > #{ENV['DEFAULTWORKINGDIRECTORY']}/sonarqube-generic-coverage.xml
      """
  end
  #====================================NA Gated BUILD==================================================#
  desc "Run Unit Tests for SonarQube report for NA region"
  lane :NA_GATEDBUILD do
    #step 1: Download cocoapods
    xcode_select("/Applications/Xcode_26.0.app")
    project_file="Subway.xcworkspace"
    cocoapods(
    clean_install: false,
    podfile: "./Podfile",
    use_bundle_exec: true,
    silent: false
    )
    # Step 2: Run the tests using Scan
    scan(
      workspace: "Subway.xcworkspace",
      scheme: "CFA UAT",
      destination: "platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.2",
      disable_slide_to_type: true,
      code_coverage: true,
      clean: false,
      fail_build: false,
      xcargs: "-parallelizeTargets"
    )
    # Step 3: Get sq xml report
    sh "brew tap a7ex/homebrew-formulae"
    sh "brew install xcresultparser"
    sh """
        xcresultparser -c -o xml /Users/runner/Library/Developer/Xcode/DerivedData/*/Logs/Test/*.xcresult > #{ENV['DEFAULTWORKINGDIRECTORY']}/sonarqube-generic-coverage.xml
      """
  end
  
  ##################################### NA Gated Build ################################################
  desc "Create Gated Build, with the enterprise certificates"
  lane :NA_GATEDBUILDCFAUAT do
    # Switch to Xcode 26.0 using xcode-select
    xcode_select("/Applications/Xcode_26.0.app")
    #download delta cocoapods
    project_file="Subway.xcworkspace"
    cocoapods(
    clean_install: false,
    podfile: "./Podfile",
    use_bundle_exec: true,
    repo_update: false,
    silent: false
    )
    # Get the number of physical CPU cores
    available_cores = sh("sysctl -n hw.physicalcpu").strip
    gym(
      clean: false,
      workspace: "Subway.xcworkspace",
      scheme: "CFA UAT",
      skip_profile_detection: true,
      configuration: "CFA-UAT",
      destination: "generic/platform=iOS",
      archive_path: "Subway/Archive/CFAUAT.xcarchive",
      export_method: "enterprise",
      export_options: "cicd/NA/devops_files/non_prod/ExportOptions.plist",
      codesigning_identity: "iPhone Distribution: DOCTOR'S ASSOCIATES, INC.",
      output_directory: "./build/CFAUAT/",
      include_symbols: false,
      silent: false,
      derived_data_path: "./build/derivedData",
      #xcodebuild_formatter: "xcpretty",
      xcodebuild_formatter: '',
      suppress_xcode_output: false,
      build_timing_summary: true,
      skip_package_dependencies_resolution: true,
      xcargs: "-jobs #{available_cores} -parallelizeTargets"
    )
    ipa_source_path = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/CFAUAT/SUBWAY®.ipa"
    ipa_rename_to = "#{ENV['SYSTEM_DEFAULTWORKINGDIRECTORY']}/Subway/build/CFAUAT/SUBWAY_CFAUAT.ipa"
    File.rename(ipa_source_path, ipa_rename_to)
  end
 end
