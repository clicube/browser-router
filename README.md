# browser-router

A macOS utility that allows users with multiple Chrome profiles to automatically open URLs from external applications (like Slack) in a specific Chrome profile.

## Overview

This application serves as a browser router for macOS users who manage multiple Google Chrome profiles. When you click on a URL in external applications (such as Slack, email clients, or other apps), this utility ensures that Chrome opens with your pre-configured profile instead of the default behavior.

## How it works

1. **Default Browser Registration**: The app registers itself as the default HTTP/HTTPS handler with macOS
2. **URL Interception**: When external applications try to open URLs, they are intercepted by this utility
3. **Profile-specific Launch**: The app launches Google Chrome with your specified profile configuration using the `--profile-directory` flag
4. **Seamless Experience**: URLs open in your desired Chrome profile without manual intervention

## Configuration

The app uses a TOML configuration file located at:
```
~/Library/Application Support/browser-router/config.toml
```

Example configuration:
```toml
# Specify the name of the Google Chrome profile you want to open in double quotes.
# Example: profile = "Profile 1"
#
# If not specified (comment out this line or leave it empty),
# Chrome will launch with default behavior (last used profile, etc.).

# profile = "Profile 2"
```

The profile name should match the Chrome profile directory name (e.g., "Profile 1", "Profile 2", etc.).

If no profile is specified, Chrome will launch with its default behavior.

## Installation

1. Build the application using Swift Package Manager
2. Run the app once to set it as the default HTTP handler
3. Configure your desired Chrome profile in the generated config file

## Requirements

- macOS 10.15 or later
- Google Chrome installed
- Swift 5.9 or later (for building from source)
