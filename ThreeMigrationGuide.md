## Texture 3.0 Migration Guide

Got a tip for upgrading? Please open a PR to this document!


### Breaking API Changes

`ASImageCacherCompletion` typedef has a new parameter: `ASImageCacheType cacheType`. Example:


```swift
ASPINRemoteImageDownloader.shared().cachedImage(with: url, callbackQueue: .main) { result in
    …
}
```

Becomes

```swift
ASPINRemoteImageDownloader.shared().cachedImage(with: url, callbackQueue: .main) { result, cacheType in
    …
}
```
