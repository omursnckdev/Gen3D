# Meshy 3D - AI-Powered 3D Model Generation App

A stunning SwiftUI iOS app that allows users to generate 3D models from text descriptions or images using the Meshy API, with ARKit integration for viewing models in augmented reality.

## Features

### Core Features
- **Text to 3D**: Generate 3D models from text descriptions
- **Image to 3D**: Convert images into 3D models
- **Batch Generation**: Generate multiple models simultaneously
- **Advanced AR Features**: View models in AR with animations and interactions
- **Model Gallery**: Browse, manage, and favorite your 3D models
- **Multiple Export Formats**: GLB, FBX, OBJ, USDZ
- **Real-time Progress Tracking**: Monitor generation progress in real-time

### Monetization
- **Credit System**: Pay-per-use credit system
- **In-App Purchases**: Buy credit packages
- **Subscriptions**: Monthly and yearly plans with better pricing
- **Welcome Bonus**: 10 free credits for new users

### Advanced Features
- **PBR Textures**: Physically-based rendering textures (metallic, roughness, normal maps)
- **Customizable Settings**:
  - Art style selection (Realistic, Sculpture)
  - AI model selection (Meshy-4, Meshy-5, Meshy-6)
  - Polycount control (100 - 100,000)
  - Texture refinement options
- **Advanced AR Capabilities**:
  - Tap to animate models
  - Pinch to scale, drag to move, rotate gestures
  - Multiple object placement
  - Dynamic lighting and shadows
  - Physics simulation
  - AR screenshots
  - Occlusion and plane detection
- **Batch Generation** (Yearly Pro Exclusive):
  - Create multiple models from text or images at once
  - Queue management with progress tracking
  - Batch operations (cancel, retry)
  - Cost estimation for batch jobs
  - Only available for Yearly Pro subscribers
- **Firebase Integration**:
  - Authentication
  - Firestore database
  - Cloud Storage for image uploads
  - Analytics

### UI/UX
- **Neon Theme**: Beautiful purple, blue, and black neon design
- **Dark Mode**: Optimized for dark mode
- **Smooth Animations**: Polished user experience
- **Glow Effects**: Neon glow effects throughout the app

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- CocoaPods
- Firebase project
- Meshy API account

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/textTo3D.git
cd textTo3D
```

### 2. Install Dependencies

```bash
cd MeshyApp
pod install
```

### 3. Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new Firebase project
3. Add an iOS app to your project
4. Download `GoogleService-Info.plist`
5. Replace the template file at `MeshyApp/MeshyApp/Resources/GoogleService-Info.plist`
6. Enable the following Firebase services:
   - **Authentication**: Enable Email/Password sign-in
   - **Firestore Database**: Create a database in production mode
   - **Cloud Storage**: Set up storage bucket
   - **Analytics**: (Optional) Enable analytics

#### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Generations collection
    match /generations/{generationId} {
      allow read, write: if request.auth != null &&
        resource.data.userId == request.auth.uid;
    }

    // Models collection
    match /models/{modelId} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid || resource.data.isPublic == true);
      allow write: if request.auth != null &&
        resource.data.userId == request.auth.uid;
    }
  }
}
```

#### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /uploads/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Meshy API Setup

1. Sign up at [Meshy.ai](https://www.meshy.ai/)
2. Go to [API Settings](https://www.meshy.ai/settings/api)
3. Create an API key
4. **Update the API key** in `MeshyApp/MeshyApp/Services/MeshyAPIService.swift`:

```swift
private let apiKey = "YOUR_MESHY_API_KEY_HERE"
```

**Important**: Replace `msy_RXfyMYJnX171yRZo0Byx6NQQbD16cJJqyIrJ` with your own API key.

### 5. App Store Connect Setup (For In-App Purchases)

1. Create an app in [App Store Connect](https://appstoreconnect.apple.com/)
2. Set up in-app purchases with the following product IDs:

#### Credit Packages
- `com.meshyapp.credits.50` - 50 credits ($4.99)
- `com.meshyapp.credits.100` - 100 credits + 10 bonus ($8.99)
- `com.meshyapp.credits.250` - 250 credits + 50 bonus ($19.99)
- `com.meshyapp.credits.500` - 500 credits + 150 bonus ($34.99)
- `com.meshyapp.credits.1000` - 1000 credits + 400 bonus ($59.99)

#### Subscriptions
- `com.meshyapp.subscription.monthly` - Monthly Pro ($19.99/month)
  - 200 credits per month
  - Priority generation queue
  - Advanced AI models

- `com.meshyapp.subscription.yearly` - Yearly Pro ($179.99/year)
  - 250 credits per month
  - All Monthly Pro features
  - **Batch Generation (Exclusive)**
  - Best value - Save 25%

**Note**: Update product IDs in `PurchaseManager.swift` if you use different identifiers.

### 6. Update Bundle Identifier

1. Open `MeshyApp.xcworkspace` in Xcode
2. Select the project in the navigator
3. Update the Bundle Identifier to match your team/organization
4. Update the bundle identifier in `GoogleService-Info.plist`

### 7. Build and Run

1. Open `MeshyApp.xcworkspace` (not `.xcodeproj`)
2. Select your development team in Signing & Capabilities
3. Choose a simulator or connected device
4. Press `Cmd + R` to build and run

## Project Structure

```
MeshyApp/
├── MeshyApp/
│   ├── MeshyAppApp.swift          # App entry point
│   ├── Models/                     # Data models
│   │   ├── User.swift
│   │   ├── Generation.swift
│   │   └── Model3D.swift
│   ├── Views/                      # SwiftUI views
│   │   ├── ContentView.swift
│   │   ├── AuthenticationView.swift
│   │   ├── HomeView.swift
│   │   ├── TextTo3DView.swift
│   │   ├── ImageTo3DView.swift
│   │   ├── GalleryView.swift
│   │   ├── CreditsView.swift
│   │   ├── ProfileView.swift
│   │   └── BatchGenerationView.swift
│   ├── ViewModels/                 # View models
│   │   ├── GenerationViewModel.swift
│   │   └── GalleryViewModel.swift
│   ├── Services/                   # Business logic
│   │   ├── MeshyAPIService.swift
│   │   ├── AuthenticationService.swift
│   │   ├── FirestoreService.swift
│   │   └── PurchaseManager.swift
│   ├── ARViews/                    # ARKit components
│   │   ├── ARViewContainer.swift
│   │   └── AdvancedARView.swift
│   ├── Utilities/                  # Utilities
│   │   └── NeonTheme.swift
│   ├── Resources/                  # Resources
│   │   └── GoogleService-Info.plist
│   └── Info.plist
└── Podfile
```

## Usage

### Creating a 3D Model from Text

1. Tap the "Create" tab
2. Select "Text to 3D"
3. Enter a description (e.g., "A futuristic spaceship with blue neon lights")
4. Choose art style (Realistic or Sculpture)
5. Select AI model
6. (Optional) Configure advanced options:
   - Enable PBR textures
   - Adjust polycount
   - Add texture prompt
7. Tap "Generate 3D Model"
8. Wait for generation to complete (typically 2-5 minutes)

### Creating a 3D Model from Image

1. Tap the "Create" tab
2. Select "Image to 3D"
3. Choose an image from your photo library
4. Select AI model
5. (Optional) Configure advanced options
6. Tap "Generate 3D Model"
7. Wait for generation to complete

### Viewing in AR (Advanced)

1. Go to the "Gallery" tab
2. Tap on a model
3. Tap "View in AR"
4. Point your camera at a flat surface
5. Tap to place the model
6. **Interactions**:
   - **Tap** on a model to play animations
   - **Pinch** to scale
   - **Drag** to move
   - **Rotate** with two fingers
   - **Long press** to delete a placed object
7. Use the bottom controls for:
   - **Place**: Add more copies of the model
   - **Animate**: Play/stop animations
   - **Photo**: Take AR screenshot
   - **Clear**: Remove all objects
8. Tap the gear icon for settings:
   - Adjust model scale
   - Enable/disable physics
   - Toggle occlusion
   - Configure lighting and shadows

### Batch Generation (Yearly Pro Exclusive)

**Note**: This feature is only available for Yearly Pro subscribers. Free and Monthly Pro users will see an upgrade prompt.

1. Tap the "Create" tab
2. Select "Batch Generation" (marked with crown icon)
3. If not subscribed to Yearly Pro, you'll see an upgrade screen
4. **For Yearly Pro subscribers:**
   - Choose between "Text to 3D" or "Image to 3D" tabs
   - **For Text to 3D**:
     - Enter multiple prompts one by one
     - Each prompt is added to the queue
     - Select art style and AI model for each
   - **For Image to 3D**:
     - Select up to 10 images at once
     - Choose AI model for all images
   - Review the total credit cost
   - Tap "Start All" to begin batch generation
   - Monitor progress for each item in real-time
   - Completed models appear in your gallery

### Managing Credits

1. Go to the "Credits" tab
2. View your current balance
3. Choose between:
   - **Subscriptions**: Monthly recurring credits with better value
   - **Buy Credits**: One-time credit packages
4. Tap on a plan/package to purchase
5. Complete the purchase with Face ID/Touch ID

## Credit Costs

| Operation | Credits |
|-----------|---------|
| Text to 3D (Preview) - Meshy-6 | 20 |
| Text to 3D (Preview) - Other models | 5 |
| Text to 3D (Refine/Texture) | 10 |
| Image to 3D - Meshy-6 (with texture) | 30 |
| Image to 3D - Other models (with texture) | 15 |
| PBR Textures | +10 |

## Troubleshooting

### Firebase Connection Issues

1. Verify `GoogleService-Info.plist` is added to the project
2. Check Firebase console for correct configuration
3. Ensure bundle identifier matches

### Meshy API Errors

1. Verify API key is correct
2. Check your Meshy account has sufficient credits
3. Review API rate limits

### In-App Purchase Issues

1. Use a sandbox tester account
2. Verify product IDs match App Store Connect
3. Check StoreKit configuration file exists

### Build Errors

1. Clean build folder (`Cmd + Shift + K`)
2. Run `pod install` again
3. Restart Xcode

## Security Notes

⚠️ **Important**: Never commit your actual API keys or `GoogleService-Info.plist` to version control!

1. Add to `.gitignore`:
```
GoogleService-Info.plist
*.plist
.env
```

2. Use environment variables for sensitive data in production
3. Implement proper API key rotation
4. Use Firebase App Check for additional security

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Credits

- **Meshy API**: [meshy.ai](https://www.meshy.ai/)
- **Firebase**: [firebase.google.com](https://firebase.google.com/)
- **SwiftUI**: Apple Inc.
- **ARKit**: Apple Inc.

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Firebase and Meshy API documentation
3. Open an issue on GitHub

## Roadmap

- [x] Advanced AR features (animations, interactions)
- [x] Batch generation
- [ ] Social sharing features
- [ ] Model collaboration
- [ ] Model marketplace
- [ ] AI-powered model recommendations
- [ ] Custom model training
- [ ] Cloud rendering for complex models
- [ ] 3D model editing tools

---

Built with ❤️ using SwiftUI and Meshy API
