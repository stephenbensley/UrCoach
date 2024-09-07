 <img src="docs/app-icon.png" alt="icon" width="75" height="75">

# Ur Coach

UrCoach is an iOS app for the [Royal Game of Ur](https://en.wikipedia.org/wiki/Royal_Game_of_Ur). The app lets you play against the computer or another human player (by pass-and-play). The computer implements a mathematically optimal strategy. You can learn a lot about the game by watching how the computer AI plays. When playing against the computer, you also have the option of displaying a detailed analysis of your available moves.

### Installation

The app can be downloaded for free from the Apple [App Store](https://apps.apple.com/us/app/id6670455978/). There are no in-app purchases or ads.

### Privacy

This app does not collect or share any personal information. For complete details, read the [Privacy Policy](https://stephenbensley.github.io/UrCoach/privacy.html)

### License

The source code for this app has been released under the [MIT License](LICENSE).

### Copyright

© 2024 Stephen E. Bensley

## Building from Source

The app was developed with [Xcode](https://developer.apple.com/xcode/), which is freely available from Apple. After installing Xcode and cloning the repo, open the Xcode [project](UrCoach.xcodeproj) at the root of the repo. The Git tags correspond to App Store releases. Checkout the most recent tag to ensure a stable build.

### Dependencies

The app depends on two Swift Packages (both developed by me): [UtiliKit](https://github.com/stephenbensley/UtiliKit) and [CheckersKit](https://github.com/stephenbensley/CheckersKit). These should be resolved automatically when you open and build the project.

### Additional Steps

The computer AI relies on a precomputed solution. This solution is stored as urSolution.data in the Resources folder. Some of the build targets rely on this solution file being available. The file is ~1.3 GB, so I decided not to commit it to GitHub. It can be generated locally by running [Ur Solver](UrSolver).

Since a 1.3 GB file is too large to bundle with the app, the solution is exposed as a web service in [AWS](https://aws.amazon.com). I decided not to reveal my AWS configuration in a public repo, so if you build locally, you will not be able to connect to my service. You have two options:

1. Deploy your own service by following the [Deployment Guide](AWS/Deployment.md). This is easier than it seems, and unless you have a lot of users, you will easily stay within the Free Tier.
2. Build the 'UrCoach (local)' target. The bundle will be huge, but if you're only using this for local testing and debugging, it's a convenient option.

### Targets

The Xcode project has the following targets:

- CoreTests: Unit tests for the core game logic.
- DynamoDBGen: A command-line MacOS app that converts the solution file to a series of files in the [DynamoDB JSON](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/S3DataImport.Format.html) import format.
- Tournament: A command-line MacOS app that runs tournaments between three strategies: random, a simple heuristic-based strategy, and the optimal strategy.
- UrCoach: The shipping version of the iOS app.
- UrCoach (local): A version of the iOS app that bundles the offline solution file instead of calling the web service.
- UrSolver: A MacOS app that solves the Royal Game of Ur. Make sure you build the Release configuration; Debug will be very slow. The Release configuration can solve the game in a few hours on an M3 iMac.
