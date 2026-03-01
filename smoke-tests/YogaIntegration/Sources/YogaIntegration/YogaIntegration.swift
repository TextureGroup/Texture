// Copyright (c) Pinterest, Inc.  All rights reserved.
// Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

// Smoke test: verifies that the Yoga trait compiles correctly.
// ASDisplayNode+Yoga.h exposes Yoga-specific API only when YOGA=1.

import AsyncDisplayKit

func smokeTestYoga() {
    let node = ASDisplayNode()

    // Yoga-specific API — only available when the Yoga trait is enabled.
    node.style.flexGrow = 1.0
    node.style.flexShrink = 1.0
    node.style.alignSelf = .center

    node.isLayerBacked = true
}
