---
title: TextureSwiftSupport
layout: docs
permalink: /docs/texture-swift-support.html
prevPage: debug-tool-ASRangeController.html
nextPage: asvisibility.html
---

TextureSwiftSupport is a support library for Texture.<br>
It helps writing the code in Texture with Swift's power.

[TextureSwiftSupport](https://github.com/muukii/TextureSwiftSupport)

## Writing LayoutSpec with DSL style like SwiftUI

With TextureSwiftSupport, we can declare the layout of nodes with the syntax like SwiftUI.
Faster tune layout up, more clarify the nodes how they will be laid out.

<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="swift" class="active swiftButton">Swift</a>
</span>

<div class = "code">
<pre lang="swift" class = "swiftCode">
override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {

  LayoutSpec {

    VStackLayout {

      myNode1

      HStackLayout {
        myNode2
        myNode3
      }

    }
  }
}
</pre>
</div>
</div>

"Faster tune layout up" means, if we want to add the background node to the layout.
We can do just like this.
Using `.background()`

<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="swift" class="active swiftButton">Swift</a>
</span>

<div class = "code">
<pre lang="swift" class = "swiftCode">
override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {

  LayoutSpec {

    VStackLayout {

      myNode1

      HStackLayout {
        myNode2
        myNode3
      }
      .background(gradientNode)

    }
  }
}
</pre>
</div>
</div>




## Modify the layout with method-chain

As the above example said, this library has many modifiers according to ASLayoutSpec.<br>
As much as possible, these properties are similar to Texture and SwiftUI. 

<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="swift" class="active swiftButton">Swift</a>
</span>

<div class = "code">
<pre lang="swift" class = "swiftCode">
override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
  LayoutSpec {
    VStackLayout {

      textNode1
        .padding(.horizontal, 16)
        
      textNode2
        .spacingBefore(16)

      textNode3
        .flexGrow(1)
        .maxWidth(120)
    }
    .background(gradientNode)
  }
}
</pre>
</div>
</div>
