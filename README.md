# Agora UIKit for iOS and macOS

Instantly integrate Agora in your own application or prototype using iOS or macOS.

![floating_view.jpg](media/floating_view.jpg)

## Requirements

- Device
    - Either an iOS device with 12.0 or later
    - Or a macOS computer with 10.14 or later
- Xcode 11 or later
- Cocoapods
- [An Agora developer account](https://www.agora.io/en/blog/how-to-get-started-with-agora?utm_source=github&utm_repo=agora-ios-uikit)

Once you have an Agora developer account and an App ID, you're ready to use this pod.

## Installation

In your iOS or macOS project, add this pod to your repository by adding a file named `Podfile`, with contents similar to this:

```ruby
# Uncomment the next line to define a global platform for your project
# platform :ios, '12.0'

target 'Agora-UIKit-Example' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Uncomment the next line if you want to install for iOS
  # pod 'Agora-UIKit', :git => 'https://github.com/maxxfrazer/Agora-UIKit.git'

  # Uncomment the next line if you want to install for macOS
  # pod 'Agora-AppKit', :git => 'https://github.com/maxxfrazer/Agora-UIKit.git'
end
```

And then install the pods using `pod install --repo-update`

If any of these steps are unclear, look at ["Using Cocoapods" on cocoapods.org](https://guides.cocoapods.org/using/using-cocoapods.html).
The installation will change slightly once this pod is out of pre-release.

## Usage

Once installed, open your application `.xcworkspace` file.

Decide where you want to add your `AgoraVideoViewer`, and in the same file import `Agora_UIKit` or `Agora_AppKit` for iOS and macOS respectively.
Next, create an `AgoraVideoViewer` object and frame it in your scene like you would any other `UIView` or `NSView`. The `AgoraVideoViewer` object must be provided `AgoraConnectionData` and a UIViewController/NSViewController on creation.

AgoraConnectionData has two values for initialising. These are appId and appToken.

An `AgoraVideoViewer` can be created like this:

```swift
import Agora_UIKit

let agoraView = AgoraVideoViewer(
    connectionData: AgoraConnectionData(
        appId: "my-app-id">,
        appToken: "my-channel-token"
    ),
    viewController: self,
    style: .grid
)
```

An alternative style is `.floating`, as seen in the image above.

To join a channel, simply call:

```swift
agoraView.join(channel: "test")
```