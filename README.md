# Biometric SDK for IOS
Guides for integrating the **FaceCapture** SDK (iOS).
[![GitHub Release](https://badgen.net/badge/release/v1.0.15/cyan)]()  


## SDK compatibility

- iOS **13.0+**
- iPhone 
- Xcode **14+** (recommended **15/16**)
- Swift Package Manager

---

## Installation (Swift Package Manager)

### Option A — Xcode UI (recommended)

1. In Xcode: **File ▸ Add Packages…**
2. Paste the package URL:
```
    https://github.com/nubarium/nubarium-face-sdk-ios.git
```
3. Choose the latest stable version (e.g. `from: 1.0.15`).
4. Add the product **FaceCapture** to your app target and finish.

### Option B — `Package.swift`

```swift
import PackageDescription

let package = Package(
 name: "YourApp",
 platforms: [.iOS(.v13)],
 dependencies: [
     .package(url: "https://github.com/nubarium/nubarium-face-sdk-ios.git", from: "1.0.15")
 ],
 targets: [
     .target(
         name: "YourApp",
         dependencies: [
             .product(name: "FaceCapture", package: "nubarium-face-sdk-ios")
         ]
     )
 ]
)
```

Then in your code:
```swift
import FaceCapture
```

**Step 2: Add Permissions**

Add to your **Info.plist** the justification for camera usage:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to perform face capture and liveness detection.</string>
```


---

### Before you begin
- Get the Nubarium Key or API Credentials. It is required to successfully initialize the SDK.
- The codes in this document are example implementations. Make sure to change the `<NUB_USERNAME>`,  `<NUB_PASSWORD>` and other placeholders as needed.
- All the steps in this document are mandatory unless stated otherwise.

## Initializing the IOS SPM

It's recommended to initialize the SDK in the global Application class, you need to add the following code in you viewDidLoad  of application class.

**FaceCapture Initializer**
```swift
        faceCapture = FaceCapture(viewController: self)
```



#### **Step 1: Import Nubarium library**

In your Application class, import the Nubairum library classes:

```swift
import FaceCapture
```

#### **Step 2: Initialize the SDK**

**Local variables**

It requires to declare the component as local variable.

```swift
    private var faceCapture: FaceCapture?
```

In the global Application `onCreate`, create an instance of the component and set the credentials or API Key (either of the 2 methods can be used) and set the configuration.

```swift

       faceCapture = FaceCapture(viewController: self)

        // Callbacks
        faceCapture!.onInitError = onInitError
        faceCapture!.onSuccess = onSuccess
        faceCapture!.onFail = onFail
        faceCapture!.onError = onError

        // Credenciales + initialize
        faceCapture.credentials(<NUB_USERNAME>,<NUB_PASSWORD>);
        faceCapture!.initialize()


```

1. First, you have to set the Credentials or Api Key.
3. Then configure the behavior of the component.
  

#### Step 3: **Setting up the FaceCompoment Result**


It is recommended to use the initialization listener, to detect any fail or save the initialization token.

#### Step 4: Setting the initialization listener

```swift

    func onInitError(error: FaceCaptureInitError, msg: String) {
        print("Init Error ->", error, msg)
    }

    func onSuccess(result: FaceCaptureResult, face: UIImage, area: UIImage, frame: UIImage) {
        
    }

    func onFail(result: FaceCaptureResult, faceCaptureReasonFail: FaceCaptureReasonFail, reason: String) {
        
    }

    func onError(faceCaptureReasonError: FaceCaptureReasonError, message: String) {
        
    }

```


- The `onSuccess()` callback method is invoked if the execution of the component was successful, the method returns the following elements.
  - faceResult : An instance of FaceResult with information like confidence and a attack indicator.
  - faceImage : A bitmap with the face cropped.
  - areaImage: A bitmap of the area where the face was framed
- The `onFail(String reason)` callback method is invoked when the liveness validation failed for the given configuration.
- The `onError(String error)` callback method is invoked when the component throws an error.


### Convert images to base64

The `UIImage` class is overloaded with a utility method that allows you to convert any image into a base64 string.  
You can use it as follows:

```swift
let faceBase64 = face.convertImageToBase64String()
let areaBase64 = area.convertImageToBase64String()
let frameBase64 = frame.convertImageToBase64String()
```

This is useful when you need to transmit or store the `face`, `area`, or `frame` images as text.


#### Step 5: Force UI Language (optional)

By default the SDK follows the device locale. You can override it by setting the `language` property before calling `start()`:

```swift
faceCapture!.language = "es"   // force Spanish
faceCapture!.language = "en"   // force English
faceCapture!.language = nil    // follow device locale (default)
```

| Value | Behavior |
|-------|----------|
| `"es"` | Displays all UI strings in Spanish |
| `"en"` | Displays all UI strings in English |
| `nil`  | Uses the device's current language (default) |

---

#### Step 6: Start component

As in the application the component is declared as a local variable, it can be started in programmatically or in some event such as onClick button.

***With Pre Initialization***

If you want to prevalidate your credentials and prevent a delay in the start event, just initialize the component after declare the properties and event listeners and before start.

```swift
faceCapture.initialize();
```

But you can just call the event start.

```swift
faceCapture.start();
```
