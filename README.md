# RealDeviceMap-UIControl

<strong>The contents of this repo is a proof of concept and is for educational use only!</strong>

RealDeviceMap-UIControl is a Device Controller for the RealDeviceMap-Api (https://github.com/123FLO321/RealDeviceMap).

Install Instructions:

1. Clone repo then checkout uic-ultra branch, `git checkout uic-ultra`
2. Install Homebrew 
`/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
3. Install cococapods `sudo gem install cocoapods`
4. Install setup tools `sudo easy_install setuptools`
5. Install requests `pip2 install requests`
6. Install project podfile `pod install`
7. Open .xcworkspace file
8. Fix signing inside xcode project
9. Run a test build to make sure the app compiles and runs without errors.
10. Exit xcode, Back in terminal `cd manager`
11. Build manager `swift run RDM-UIC-Manager`
12. Wait about 2 minutes, after all of the manager dependencies are downloaded and the terminial is stuck on XcodeBuildservice
13. ctrl+c then `swift run RDM-UIC-Manager` and the manager should start from there.
(Yes, ctrl+c is necessary for a full build...)
If you have any issues, open an issue, PR's are welcome. There is still alot of room for improvement.

RealDeviceMap-UIControl interacts with the iOS Device using Xcode UITesting.<br>
This project shows how to UITest 3rd party apps with optical image processing for none standart UIElements and how to setup and use a Webserver in a Xcode UITest.

Questions? Ask as in Discord: https://discord.gg/q2aXaGP
