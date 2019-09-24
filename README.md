# ESHelp
A drop-in replacement for Apple’s Mac help system. 

If you have ever struggled with Apple’s help system, ESHelp will help. ESHelp is designed to address the following issues in Apple’s help system:

1. Anchors usually don’t work
2. No dark mode support
3. Very difficult to debug
4. Uses system-level, shared window
5. Poor, incorrect documentation

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


# hello, This is Markdown Live Preview

----
## what is Markdown?
see [Wikipedia](https://en.wikipedia.org/wiki/Markdown)

> Markdown is a lightweight markup language, originally created by John Gruber and Aaron Swartz allowing people "to write using an easy-to-read, easy-to-write plain text format, then convert it to structurally valid XHTML (or HTML)".

----
## usage
1. Write markdown text in this textarea.
2. Click 'HTML Preview' button.

----
## markdown quick reference
# headers

*emphasis*

**strong**

* list

>block quote

    code (4 spaces indent)
[links](https://wikipedia.org)

----
## changelog
* 17-Feb-2013 re-design

----
## thanks
* [markdown-js](https://github.com/evilstreak/markdown-js)