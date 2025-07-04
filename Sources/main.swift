import Cocoa
import CoreServices
import TOMLKit // Import TOML parsing library

// --- Define the structure of the configuration file (TOML) ---
struct Config: Codable {
    var profile: String?
}

// --- Structure responsible for managing configuration files ---
struct ConfigManager {
    let fileManager = FileManager.default
    let configURL: URL

    // Configuration file template
    private var template: String {
        """
        # Specify the name of the Google Chrome profile you want to open in double quotes.
        # Example: profile = "Profile 1"
        #
        # If not specified (comment out this line or leave it empty),
        # Chrome will launch with default behavior (last used profile, etc.).
        
        # profile = "Profile 2"
        """
    }

    init?() {
        guard let configDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Application Support")
            .appendingPathComponent("browser-router") else { return nil }
        self.configURL = configDir.appendingPathComponent("config.toml")
    }

    // Ensure the configuration file exists and create a template if it doesn't
    func ensureConfigFileExists() throws {
        let configDirURL = configURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: configDirURL.path) {
            try fileManager.createDirectory(at: configDirURL, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: configURL.path) {
            try template.write(to: configURL, atomically: true, encoding: .utf8)
        }
    }

    // Open the configuration file
    func openInEditor() {
        NSWorkspace.shared.open(configURL)
    }

    // Load configuration
    func readConfig() -> Config {
        do {
            let tomlString = try String(contentsOf: configURL, encoding: .utf8)
            return try TOMLDecoder().decode(Config.self, from: tomlString)
        } catch {
            return Config(profile: nil)
        }
    }
}


// --- Delegate that manages the lifecycle of macOS applications ---
class AppDelegate: NSObject, NSApplicationDelegate {
    private var hasHandledInitialRequest = false

    // Method called when the application finishes launching
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("[App] Application finished launching.")
        
        // Determine the reason for startup immediately after processing startup events
        DispatchQueue.main.async {
            if !self.hasHandledInitialRequest {
                print("[App] Direct launch detected.")
                
                // 1. Attempt to set as default browser (http only)
                self.attemptToSetDefaultHttpHandler()
                
                // 2. Prepare and open the configuration file
                if let configManager = ConfigManager() {
                    do {
                        try configManager.ensureConfigFileExists()
                        configManager.openInEditor()
                    } catch {
                        print("[Error] Could not create or open config file: \(error.localizedDescription)")
                    }
                }

                NSApp.terminate(nil) // Exit after completing tasks
            }
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        self.hasHandledInitialRequest = true
        guard let firstFile = filenames.first else { NSApp.terminate(nil); return }
        self.openInChrome(url: URL(fileURLWithPath: firstFile))
    }

    @objc func handleGetURL(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        self.hasHandledInitialRequest = true
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else { NSApp.terminate(nil); return }
        self.openInChrome(url: url)
    }

    func openInChrome(url: URL) {
        guard let configManager = ConfigManager() else { NSApp.terminate(nil); return }
        let config = configManager.readConfig()
        guard let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") else {
             NSApp.terminate(nil); return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        var arguments: [String] = []
        if let profileName = config.profile, !profileName.isEmpty {
            arguments.append("--profile-directory=\(profileName)")
        }
        arguments.append(url.absoluteString)
        configuration.arguments = arguments
        NSWorkspace.shared.openApplication(at: chromeURL, configuration: configuration) { _, error in
            if error != nil { print("[Error] Failed to open in Chrome.") }
            DispatchQueue.main.async { NSApp.terminate(nil) }
        }
    }
    
    // Method to set HTTP default handler
    func attemptToSetDefaultHttpHandler() {
        let bundleID = "jp.cubik.browserrouter" as CFString
        let httpScheme = "http" as CFString
        print("[Setup] Trying to set self as default handler for http...")
        let status = LSSetDefaultHandlerForURLScheme(httpScheme, bundleID)
        if status == noErr {
            print("[Setup]   ✅ Successfully set as default handler for http.")
        } else {
            print("[Setup]   ❌ Failed to set as default handler for http. OSStatus: \(status)")
        }
    }
}


// --- Application entry point ---
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSAppleEventManager.shared().setEventHandler(
    delegate,
    andSelector: #selector(AppDelegate.handleGetURL(event:withReplyEvent:)),
    forEventClass: AEEventClass(kInternetEventClass),
    andEventID: AEEventID(kAEGetURL)
)
NSApplication.shared.run()
