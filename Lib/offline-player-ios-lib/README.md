# Offline Player lib

Offline player lib is an video player library for fairplay playing.

# Installation
To install the library use [https://cocoapods.org](cocoapods) dependecy manager.
`pod 'offline-player-lib'`

# Usage

The library can handle online and offline video playing. 

## Video player
To playing online video use `ARTPlayerController` as subclass of your current ViewController then initialise the player using the following code :

`self.loadPlayer(withContentId: "_content_id_", withMode: .online / .offline)`

if you set the `mode` to `.online` the player will ready the stream on the fly, otherwise if you use `.offline` mode the player will start the downloading of the movie and then it's done start to play the video. 

You can subscribe to `.downloadFinished` notification in order to be notify when the stream is ready to play.

## Video downloading

Use the `ARTMovieDownloader` to download the video locally and use it to play later. 

To initialise the stream downloader :
```ARTMovieDownloader.init(artStream: ARTStreaming.init(licensesUsername: "username", fairPlayDomainName: "domaine_name", contentId: nil, certPath: "path_to_cert"))```

Note: the cert need to be embedded in the project. You can load it like this:
`let certPath = Bundle.main.path(forResource: "eleisure", ofType: "cer");`

To track the downloading progress you can subscribe to the following notifications:
 - downloadFinished
 - downloadInProgress

Each time when the download tick you will receive in the notification `ARTAssetDownloadProgression` object.

### Features
- pause / resume
- background downloading
- resume background downloading

### last version
0.1.8
