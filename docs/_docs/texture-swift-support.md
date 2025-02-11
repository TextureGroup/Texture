---
title: TextureSwiftSupport
layout: docs
permalink: /docs/texture-swift-support.html
prevPage: debug-tool-ASRangeController.html
nextPage: asvisibility.html
---
​
TextureSwiftSupport is a syntax sugar library for Texture.<br>
It helps writing code in Texture with Swift's power.
​
[TextureSwiftSupport](https://github.com/muukii/TextureSwiftSupport)
​
## Writing `LayoutSpec`s with SwiftUI-like Syntax
​
With TextureSwiftSupport, we can declare the layout of nodes with syntax similar to SwiftUI.
With a simpler construct, it is clearer how the nodes will be laid out.
​
<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="swift" class="active swiftButton">Swift</a>
</span>
​
<div class = "code">
<pre lang="swift" class = "swiftCode">
override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
​
  LayoutSpec {
​
    VStackLayout {
​
      myNode1
​
      HStackLayout {
        myNode2
        myNode3
      }
​
    }
  }
}
</pre>
</div>
</div>
​
For example, if we want to add the background node to the layout we can just add `.background()`:
​
<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="swift" class="active swiftButton">Swift</a>
</span>
​
<div class = "code">
<pre lang="swift" class = "swiftCode">
override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
​
  LayoutSpec {
​
    VStackLayout {
​
      myNode1
​
      HStackLayout {
        myNode2
        myNode3
      }
      .background(gradientNode)
​
    }
  }
}
</pre>
</div>
</div>
​
​
​
​
## Modifying `LayoutSpec`s with Method Chains
​
As shown above, this library has many other modifiers for `ASLayoutSpec`.<br>
These properties were designed to be semantically relevant with both Texture and SwiftUI. 
​
<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="swift" class="active swiftButton">Swift</a>
</span>
​
<div class = "code">
<pre lang="swift" class = "swiftCode">
override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
  LayoutSpec {
    VStackLayout {
​
      textNode1
        .padding(.horizontal, 16)
        
      textNode2
        .spacingBefore(16)
​
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
