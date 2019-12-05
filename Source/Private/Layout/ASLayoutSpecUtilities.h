//
//  ASLayoutSpecUtilities.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <CoreGraphics/CoreGraphics.h>

#import <algorithm>
#import <functional>
#import <type_traits>
#import <vector>

namespace AS {
  // adopted from http://stackoverflow.com/questions/14945223/map-function-with-c11-constructs
  // Takes an iterable, applies a function to every element,
  // and returns a vector of the results
  //
  template <typename T, typename Func>
  auto map(const T &iterable, Func &&func) -> std::vector<decltype(func(std::declval<typename T::value_type>()))>
  {
    // Some convenience type definitions
    typedef decltype(func(std::declval<typename T::value_type>())) value_type;

    // Prepares an output vector of the appropriate size
    std::vector<value_type> res;
    res.reserve(iterable.size());

    // Let std::transform apply `func` to all elements
    // (use perfect forwarding for the function object)
    std::transform(std::begin(iterable), std::end(iterable), std::back_inserter(res),
                   std::forward<Func>(func));

    return res;
  }

  template<typename Func>
  auto map(id<NSFastEnumeration> collection, Func &&func) -> std::vector<decltype(func(std::declval<id>()))>
  {
    std::vector<decltype(func(std::declval<id>()))> to;
    for (id obj in collection) {
      to.push_back(func(obj));
    }
    return to;
  }

  template <typename T, typename Func>
  auto filter(const T &iterable, Func &&func) -> std::vector<typename T::value_type>
  {
    std::vector<typename T::value_type> to;
    for (auto obj : iterable) {
      if (func(obj)) {
        to.push_back(obj);
      }
    }
    return to;
  }
};

inline CGPoint operator+(const CGPoint &p1, const CGPoint &p2)
{
  return { p1.x + p2.x, p1.y + p2.y };
}

inline CGPoint operator-(const CGPoint &p1, const CGPoint &p2)
{
  return { p1.x - p2.x, p1.y - p2.y };
}

inline CGSize operator+(const CGSize &s1, const CGSize &s2)
{
  return { s1.width + s2.width, s1.height + s2.height };
}

inline CGSize operator-(const CGSize &s1, const CGSize &s2)
{
  return { s1.width - s2.width, s1.height - s2.height };
}

inline UIEdgeInsets operator+(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top + e2.top, e1.left + e2.left, e1.bottom + e2.bottom, e1.right + e2.right };
}

inline UIEdgeInsets operator-(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top - e2.top, e1.left - e2.left, e1.bottom - e2.bottom, e1.right - e2.right };
}

inline UIEdgeInsets operator*(const UIEdgeInsets &e1, const UIEdgeInsets &e2)
{
  return { e1.top * e2.top, e1.left * e2.left, e1.bottom * e2.bottom, e1.right * e2.right };
}

inline UIEdgeInsets operator-(const UIEdgeInsets &e)
{
  return { -e.top, -e.left, -e.bottom, -e.right };
}
