# OpenGlück Swift App (iOS, macOS, watchOS, iPadOS, tvOS)

This is the OpenGlück App for Apple platforms (iPhone, Apple Watch, Mac and
Apple TV).

See [opengluck.com](https://www.opengluck.com/) for an overview of OpenGlück,
and how the OpenGlück App (pictured in bottom-right corner below) integrates
with compatible apps:

![Apps](docs/apps.png)

## Complications

All complications sizes for watchOS 10 are supported.

![watchOS](docs/watch.png)

And, if you have a Series 9 or Ultra 2, you can use the *double tap* gesture. I
have mine configured so that a *single double tap* shows the graph, and a
*second double tap* opens the app. Very handy!

(Remember that we're subject to the same limitation than all Apple Watch
widgets. See the FAQ item below for a more detailed explanation.)

# iPhone / iPad

The [OpenGlück app](https://github.com/open-gluck/opengluck-ios) supports all
widgets sizes of iOS 17, including Standby — if you are lucky and have an
iPhone with Always-On, this makes a great nighttime BG reader.

![iPhone](docs/iphone.png)

# macOS

The [native Mac app](https://github.com/open-gluck/opengluck-ios) means you
don't have to reach out for your phone to know your blood glucose.

![macOS](docs/mac.png)

# tvOS

Well, tvOS started more as a joke than anything else. Please let me know if you
have serious uses for it, though, I'd be more than happy to read about it.

![tvOS](docs/tv.png)

# Prerequisites

- a running [OpenGlück server](https://github.com/open-gluck/opengluck-server)
  with a token,
- a compatible app sending data to the server (see the
  [opengluck.com](https://www.opengluck.com/) for a list of compatible apps).
 If you don't have an app sending data to OpenGlück Server, the OpenGlück App
 will have nothing to show you!

# Installation

If you don't have a developer account, you might install this app by joining a
team on TestFlight. Reach out to a developper with the app available on
TestFlight, and ask them to invite you.

If you have a developer account, you can compile the source code yourself and
install on your devices. See [docs/DEVELOPER.md](docs/DEVELOPER.md) for more
info.

# Configuration

You will first need to get your token; to do so, browse your OpenGlück server
and click *API Access*. Note the host and token, then run the app and paste the
required configuration values.

# iOS, iPadOS, macOS

Then, open the app, click *More*, and paste the information.

# watchOS

The watchOS version takes its configuration from the iOS app. First, configure,
iOS as described above, then run the watchOS app. Note that the connection
between the watch and the iPhone uses an Apple framework that is known for
hiccus, in case of trouble, you might need to restart the iOS app while the
watchOS app is running, or maybe restart both your watch and iPhone and start
by running the watchOS app. Please note that only the initial setup is painful,
once you're good, you're good.

# Deeplinks

You can use the following deep-links to open the OpenGlück app in a desired
state:

- [opengluck://records](opengluck://records) open the Records tab
- [opengluck://add-low](opengluck://add-low) interactively add sugar
- [opengluck://add-insulin](opengluck://add-insulin) interactively add insulin

# Developer Info

If you're a developer and interested in joining in the OpenGlück ecosystem,
please browse [docs/DEVELOPER.md](docs/DEVELOPER.md) for more tidbits.

# Limitations

If you chose to install the app using TestFlight, you will be subject to the
usual WidgetKit restrictions on the total amount of times widgets and
complications can refresh. This is something Apple actively enforces, however
OpenGlück is designed to help you out: widget will display an icon when data is
outdated (so that if you see something in a widget/on your watch, you know it's
current), and a single click/tap will launch the app where you will be able to
read live data.

Note you can also use the Contact Trick (see below). This works on all devices
and updates almost in real-time, with the downside that you can always be sure
that the data is fresh.

If you're a registered developer, and installed the app yourself with XCode (ie
not using TestFlight), you can lift WidgetKit restrictions like so.

*Important: WidgetKit Developer Mode is enabled only for apps you build and install on your devices. It has no impacts on apps downloaded from the App Store or Test Flight.*

#### Apple Watch

Open **Settings**, then navigate to **Developer**. In the secret menu, check **WidgetKit Developer Mode**. 

![Friday, 17 Nov 2023 16:51:54](https://github.com/open-gluck/.github/assets/66381046/48170ad1-63e1-4d0b-a0d8-aa66905114bd)

#### iPhone, iPad

Open **Settings**, then navigate to **Developer**. In the secret menu, check **WidgetKit Developer Mode**. 

![Friday, 17 Nov 2023 16:53:33](https://github.com/open-gluck/.github/assets/66381046/d2e180cf-2ded-4693-ad51-0d1df6061e8f)

# Contact Trick

There is a work around the restrictions detailed above, by asking the app to
update the photo of a contact. The trick works because you can add a contact on
a watch face, which will show its profile photo. Since this is an Apple widget,
it is not subject to the same restrictions, which means it updates almost
instanstly.

To enable the Contact Trick:

1. go to the More tab and enable the Contact Trick
2. grant permission to update the contacts
3. manually create a contact whose email address is bg@calendar-trick.opengluck.com
