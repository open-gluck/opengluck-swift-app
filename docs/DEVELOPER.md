# OpenGlück Developer Infos

Hello, developer! Welcome to your readme.

If you're not a developer -- and by this, we mean, you don't have a paid Apple
Developer account, you might stop reading this file. Installing OpenGlück to
your device without a developer account is cumbersome (you need to reinstall
the app every seven days) so while it's theorically possible, we recomend
against it.

## Compile and Install with XCode

Before you attempt to compile with XCode, copy the `Config.xcconfig`,
`Development.xcconfig` and `Production.xcconfig` files from the `samples/`
folder in the root of the directory.

Then, edit the new file `Config.xcconfig` at the root directory, and update the following values:
- `OPENGLUCK_TARGET_NAME`: see the instructions to choose an unique display name;
- `OPENGLUCK_DEVELOPMENT_TEAM`: your development team ID.

Next, open the XCode workspace, and update the bundle and app name to match the
one you're using.

## Disable WidgetKit Restrictions

When your phone/watch is in developer mode, by default, it still has WidgetKit
restrictions.

You'll need to manually remove them by opening Settings, browse the Developer
submenu, and tick the WidgetKit box.

## Beware of diacritics (prefer `OpenGluck` instead of `OpenGlück`)

### Git, XCode don't support files with diacritics

Please do not use `OpenGlück` in filenames as, unfortunately, tools in 2023
aren't quite ready for getting rid of ASCII filenames (see the need of
[`core.precomposeUnicode`](https://git-scm.com/docs/git-config) in `git`; as of
XCode, it breaks support of breakpoints).

### AppConnect doesn't support files with diacritics

Last but not least, `AppConnect` will reject your app if some of your targets
has diacritics in their name.

### Swift Playgrounds doesn't support typing in diacritics

Nail in the cuffin of diacritics (if needed), Swift Playgrounds doesn't support
typing diacritics with an hardware keyboard (it insist ``` is not a dead key
and types two letters instead of the digraph).
