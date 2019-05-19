//
//  ASPropertyMacros.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 5/19/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>

#import <AsyncDisplayKit/ASThread.h>

#include <functional>

namespace AS {
  /**
   * Convenience function to wrap a msg-send in a C++ function. An example use
   * is to invoke `setNeedsDisplay`. The method must take no argument
   * and return no value.
   */
  template <typename T>
  NS_INLINE std::function<void(id, const T&)> ObjCCall(SEL selector) {
    return [selector](id self, __unused const T& old_value) {
      auto castMsgSend = (void(*)(id object, SEL s))objc_msgSend;
      castMsgSend(self, selector);
    };
  }

  NS_INLINE id ObjCCopy(unowned id object) {
    return [object copyWithZone:nullptr];
  }

  template <typename T>
  NS_INLINE T ObjCGetter(Mutex &mutex, std::function<T()> get) {
    mutex.lock();
    T result = get();
    mutex.unlock();
    return result;
  }

  /**
   * The primitive function for locked setters.
   * @param self The object the setter is being called on.
   * @param mutex The mutex to lock for the ivar.
   * @param getter The 
   * @param value The new property value.
   * @param is_equal Optional custom comparison.
   * @param copy Optional custom copy.
   * @param release Optional custom release for old value.
   * @param side_effect Optional function to call before unlocking.
   */
  template <typename T>
  NS_INLINE bool ObjCSetter(unowned id self,
                  Mutex &mutex,
                  std::function<T()> getter,
                  std::function<void(T)> setter,
                  const T &value,
                  std::function<bool(const T& a, const T& b)> is_equal,
                  std::function<T(const T&val)> copy,
                  std::function<void(const T&val)> release,
                  std::function<void(unowned id self, const T &old_value)> side_effect) {
    mutex.lock();
    const T old_value = getter();
    const bool bail = is_equal ? is_equal(old_value, value) : std::equal_to<T>()(old_value, value);
    if (bail) {
      mutex.unlock();
      return false;
    }

    setter(copy ? copy(value) : value);
    if (side_effect) {
      side_effect(self, old_value);
    }
    if (release) {
      release(old_value);
    }
    mutex.unlock();
    return true;
  }
}

#define AS_GETTER(lowerName, mutex, type, expr) \
- (type)lowerName { \
  return AS::ObjCGetter<type>(mutex, [&self]{ return expr; }); \
}

#define AS_SETTER(upperName, lock, type, expr, isEqual, copy, release, sideEffect) \
- (void)set##upperName:(type)newValue { \
  AS::ObjCSetter<type>(self, lock, [&self]{ return expr; }, [&self](type newValue){ expr = newValue; }, newValue, isEqual, copy, release, sideEffect); \
}

#define AS_SETTER_PLUS_METHOD(upperName, lock, type, expr, isEqual, copy, release, method) \
  AS_SETTER(upperName, lock, type, expr, isEqual, copy, release, AS::ObjCCall<type>(@selector(method)))

#define AS_BASIC_SETTER(upperName, lock, type, expr) \
  AS_SETTER(upperName, lock, type, expr, std::equal_to<type>(), nullptr, nullptr, nullptr)

