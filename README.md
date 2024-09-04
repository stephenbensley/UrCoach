 <img src="docs/app-icon.png" alt="icon" width="75" height="75">

# Ur Coach

UrCoach is an iOS app for the [Royal Game of Ur](https://en.wikipedia.org/wiki/Royal_Game_of_Ur). The app lets you play against the computer or another human player (by pass-and-play). The computer implements a mathematically optimal strategy. You can learn a lot about the game by watching how the computer AI plays. When playing against the computer, you also have the option of displaying a detailed analysis of your available moves.

### Installation

The app can be downloaded for free from the Apple [App Store](https://apps.apple.com/us/app/queah/id6670455978/). There are no in-app purchases or ads.

### License

The source code for this app has been released under the [MIT License](LICENSE).

### Copyright

© 2024 Stephen E. Bensley

## Building from Source

The app was developed with [Xcode](https://developer.apple.com/xcode/), which is freely available from Apple. After installing Xcode and cloning the repo, open the Xcode [project](UrCoach.xcodeproj) at the root of the repo.

### Dependencies

The app depends on two Swift Packages (both developed by me): [UtiliKit](https://github.com/stephenbensley/UtiliKit) and [CheckersKit](https://github.com/stephenbensley/CheckersKit). These will be resolved automatically when you open the project.

### Additional Steps

The computer AI relies on a precomputed solution. This solution is stored as urSolution.data in the Resources folder. Some of the build targets rely on this solution file being available. The file is ~1.3 GB, so I decided not to commit it to GitHub. It can be easily generated locally by running [Ur Solver](UrSolver).

Since a 1.3 GB file is too large to bundle with the app, the solution is exposed as a web service in [AWS](https://aws.amazon.com). I decided not to reveal my AWS configuration in a public repo, so if you build locally, you will not be able to connect to my service. You have two options:

1. Deploy your own service by following the [Deployment Guide](AWS/Deployment.md). This is easier than it seems, and unless you have a lot of users, you will easily stay within the Free Tier.
2. Build the 'UrCoach (local)' target. This creates a version of the app that bundles the offline solution file instead of calling the web service. The bundle will be huge, but if you're only using this for local testing and debugging, it's a convenient option.
