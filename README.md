# Chat App Boilerplate

This project provides a boilerplate template for creating a chat app using Flutter with GetX, Firebase Cloud Messaging (FCM), and Firebase Realtime Database. It consists of a single Dart file and a chat screen, allowing developers to easily customize the sender and receiver IDs to create their own chat application.

## Features

- Simple and intuitive chat screen UI.
- Real-time messaging using Firebase Realtime Database.
- Firebase Cloud Messaging for push notifications on both Android and iOS devices.

## Installation

1. Clone the repository to your local machine.
2. Open the project in your preferred code editor.
3. Ensure you have Flutter and Dart installed on your machine. If not, refer to the official Flutter documentation for installation instructions.
4. Open a terminal or command prompt and navigate to the project directory.
5. Run the following command to fetch the project dependencies:
6. Configure Firebase for your project:
- Create a new Firebase project on the Firebase console (https://console.firebase.google.com/).
- Set up your Android and iOS apps in the Firebase project. Follow the Firebase documentation for detailed instructions on how to do this.
- Download the `google-services.json` file for Android and the `GoogleService-Info.plist` file for iOS.
- Place the respective files in the appropriate locations within the Flutter project (refer to the Flutter documentation for details).
- Make sure the necessary dependencies for Firebase and FCM are added to your `pubspec.yaml` file.

## Usage

1. Open the project in your preferred code editor.
2. In the Dart file, locate the `senderId` and `receiverId` variables.
3. Customize the `senderId` and `receiverId` values to match your desired chat scenario.
4. Run the app on either an Android or iOS device/emulator using the following command:
5. The chat screen will be displayed with the sender and receiver IDs specified. You can start sending messages and testing the functionality.

## Contributing

Contributions to this project are welcome and encouraged! If you encounter any issues, have suggestions for improvements, or would like to add new features, please follow the guidelines below:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make the necessary changes and commit them.
4. Push your branch to your forked repository.
5. Submit a pull request with a clear description of your changes and the problem or feature it addresses.

Please ensure that your contributions adhere to the coding standards and conventions used in the project.

## License

This project is released without any specific license. You are free to use and modify the code in any way you see fit. However, please note that without a license, there are no warranties or guarantees provided, and the project is provided "as is." It is your responsibility to ensure that you comply with any applicable laws and regulations when using this code.
