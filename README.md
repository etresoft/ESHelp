# ESHelp
A drop-in replacement for Apple’s Mac help system. 

If you have ever struggled with Apple’s help system, ESHelp will help. ESHelp is designed to address the following issues in Apple’s help system:

1. Anchors usually don’t work
2. No dark mode support
3. Very difficult to debug
4. Uses system-level, shared window
5. Poor, incorrect documentation
6. Share button and sidebar buttons only work with Apple’s remote help service

##There are three parts to this project:
1. **ESXSLHelp** - An example project that builds a help bundle according to Apple’s documentation
2. **AppleHelpDemo** - An example project that uses the ESXSLHelp bundle, again, according to Apple’s documentation
3. **ESHelp** - A framework that provides a drop-in replacement to Apple’s help system
4. **ESHelpDemo** - A demo project showing how to use the ESHelp framework

**Note:** You don’t have to use ESXSLHelp. If you can construct a functional help bundle using some other method, go for it. Any specific ESHelp framework requirements will be listed below.

# ESXSLHelp
**Requires**: ~/bin/myhiutil - A copy of the macOS 10.13 hiutil executable. The version in 10.14 is no longer functional. It can create help bundles, but it can’t read them.

ESXSLHelp is a demo project designed to build a functional help bundle according to [Apple’s documentation](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/ProvidingUserAssitAppleHelp/user_help_intro/user_assistance_intro.html), such as it is. It is almost certainly possible to build a functional help bundle with a different structure, but this is an effort to follow Apple’s documentation as closely as possible. ESXSLHelp is, as you might guess, based on XSL. 

The ESXSLHelp project generates a multilingual (English and French) help bundle. Included in the bundle are two additional files that are required by the ESHelp framework. These are essentially pre-exported data from the help index file. You will need a copy of the hiutil Apple tool from macOS 10.13. One of the issues with Apple’s help is that the hiutil tool can no longer read the very files it generates since macOS 10.14.

# AppleHelpDemo
This is a simple project that uses a help bundle. Its purpose is to demonstrate how difficult this is. This demo project exhibits the following problems:

1. Anchors only work about 15% of the time. I’ve been working on help bundles for several years. This 15% success rate is strangely consistent. I have no clue.
2. No dark mode support. 
3. Very difficult to debug. Your app with embedded help bundle must be installed in /Applications to function. You can debug it, but the system help viewer will only display content found in /Applications.
4. Only basic help book features are used. I’ve tried various other features but found most of them to be non-functional.
5. Share button and sidebar button are designed for Apple’s use only.

# ESHelp
This is a drop-in replacement for NSHelpManager. It requires a help bundle with some additional files. These files must be identified in the help bundle’s Info.plist file with the following keys:

1. **ESHelpHelpIndex** - The localized path to the exported help index data. This is the output from “myhiutil -D -f /path/to/helpindex”. As noted above, myhiutil is the hiutil tool from macOS 10.13.
2. **ESHelpHelpFiles** - The localized path to the exported help files list. This is the output from “myhiutil -v -v -F -f /path/to/helpindex”. As noted above, myhiutil is the hiutil tool from macOS 10.13.
3. **ESHelpSearchResults** - The localized path to the search results HTML template. The runtime logic in the ESHelp framework will replace certain placeholder tags with search results content.

# ESHelpDemo
This is a demo app showing how to use the ESHelp framework.

To install the ESHelp framework in your own project, you would do the following:

1. Build a help bundle. You ESXSLHelp or your own project. You will need to add it to your app’s resources in Xcode. The help bundle must have the files and Info.plist entries described above.
2. Use the ESHelp framework in your Xcode project. Include it as an embedded binary. 
3. Add an ESHelpManager object to the list of objects in Interface Builder.
4. Change the action of the menu bar’s Help menu item to point to the “showHelp:” method of ESHelpManager.
5. Use the “sharedHelpManager” to get a pointer to the ESHelpManager singleton defined in Interface Builder.
6. Use the “showHelp:” and “showHelpAnchor:” methods to display your help.

**Note:** - In theory, you can add the “showHelp:” method to your First Responder (whatever that happens to be). You could then just use the singleton without adding the ESHelpManager to Interface Builder. It works great, until it doesn’t. 

Your help menu item will now display a help window very similar to the system help. It has the following benefits:

1. Anchors work every time.
2. Dark mode support.
3. This is an app window rather than a system window. When your app quits, the help window closes too.
4. Searches in your app will only display help in your app. You won’t get results from potentially competing apps.
5. The search field in the menu bar will work as you expect and display help results in the same window.
6. Since the help bundle is a valid help bundle, your app’s help will be available via search from the system help tool.
7. If you need to debug your appearance, everything works great in debug mode.
8. The sidebar button is replace with a home button to quickly jump back to the top level of help from an anchor, saving a trip to the menu.
9. The share button is functional. Apple’s share services don't work with web archives, so the only thing I can share is the URL. It works, but there is no CSS so it isn't pretty. The share button is disabled by default.
