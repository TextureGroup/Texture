//
//  ASLayoutSpecUtilitiesTests.m
//  AsyncDisplayKitTests
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import "ASLayoutSpecUtilities.h"

@interface ASLayoutSpecUtilitiesTests : XCTestCase

@end

@implementation ASLayoutSpecUtilitiesTests

- (void)testMapVectorPrimitive
{
  std::vector<int> a = {3, 1, 4};
  std::vector<int> b = AS::map(a, ^int(int i) {
    return i * 2;
  });
  std::vector<int> c = {6, 2, 8};
  XCTAssertEqual(b, c);
}

- (void)testMapVectorNSObject
{
  std::vector<NSString *> a = {@"2.16", @"3.14"};
  std::vector<float> b = AS::map(a, ^float(NSString *str) {
    return str.floatValue;
  });
  std::vector<float> c = {2.16, 3.14};
  XCTAssertEqual(b, c);
}

- (void)testMapVectorStruct
{
  struct TestStruct
  {
    NSString *value;
    
    bool operator==(const TestStruct& rhs) const
    {
      return [value isEqualToString:rhs.value];
    }
  };

  std::vector<TestStruct> a = {
    {.value = @"2"},
    {.value = @"1"},
    {.value = @"6"}
  };
  std::vector<NSInteger> b = AS::map(a, ^NSInteger(TestStruct s) {
    return s.value.integerValue;
  });
  std::vector<NSInteger> c = {2, 1, 6};
  XCTAssertEqual(b, c);
}

- (void)testMapVectorClass
{
  class TestClass {
  private:
    NSString *_value;
    
  public:
    TestClass (NSString *value)
    {
      _value = value;
    }
    
    NSString *getValue() const noexcept
    {
      return _value;
    }
    
    void setValue(NSString *value) noexcept
    {
      _value = value;
    }
    
    bool operator==(const TestClass& rhs) const noexcept
    {
      return [getValue() isEqualToString:rhs.getValue()];
    }
  };
  
  std::vector<TestClass> a = {
    TestClass(@"2"),
    TestClass(@"1"),
    TestClass(@"6")
  };
  std::vector<NSInteger> b = AS::map(a, ^NSInteger(TestClass c) {
    return c.getValue().integerValue;
  });
  std::vector<NSInteger> c = {2, 1, 6};
  XCTAssertEqual(b, c);
}

- (void)testMapVectorEmpty
{
  std::vector<NSString *> a = {};
  std::vector<int> b = AS::map(a, ^int(NSString *str) {
    return str.intValue;
  });
  std::vector<int> c = {};
  XCTAssertEqual(b, c);
}

- (void)testMapNSFastEnumeration
{
  struct TestStruct {
    NSString *value;
    
    bool operator==(const TestStruct& rhs) const
    {
      return [value isEqualToString:rhs.value];
    }
  };

  NSArray<NSNumber *> *a = @[@1, @2, @3];
  std::vector<TestStruct> b = AS::map(a, ^TestStruct(NSNumber *num) {
    return {.value = num.stringValue};
  });
  std::vector<TestStruct> c = {
    {.value = @"1"},
    {.value = @"2"},
    {.value = @"3"}
  };
  XCTAssertEqual(b, c);
}

- (void)testMapNSFastEnumerationEmpty
{
  NSArray<NSNumber *> *a = @[];
  std::vector<int> b = AS::map(a, ^int(NSNumber *num) {
    return num.intValue;
  });
  std::vector<int> c = {};
  XCTAssertEqual(b, c);
}

- (void)testFilterVectorPrimitive
{
  std::vector<int> a = {1, 2, 3, 4};
  std::vector<int> b = AS::filter(a, ^BOOL(int num) {
    return num < 3;
  });
  std::vector<int> c = {1, 2};
  XCTAssertEqual(b, c);
}

- (void)testFilterVectorNSObject
{
  std::vector<NSString *> a = {@"9", @"2", @"6"};
  std::vector<NSString *> b = AS::filter(a, ^BOOL(NSString *str) {
    return str.integerValue % 2 == 0;
  });
  std::vector<NSString *> c = {@"2", @"6"};
  XCTAssertEqual(b, c);
}

- (void)testFilterVectorStruct
{
  struct TestStruct {
    NSString *value;
    
    bool operator==(const TestStruct& rhs) const
    {
      return [value isEqualToString:rhs.value];
    }
  };

  std::vector<TestStruct> a = {
    {.value = @"6"},
    {.value = @"8"},
    {.value = @"3"},
    {.value = @"9"}
  };
  std::vector<TestStruct> b = AS::filter(a, ^BOOL(TestStruct s) {
    return s.value.integerValue == 3;
  });
  std::vector<TestStruct> c = {
    {.value = @"3"}
  };
  XCTAssertEqual(b, c);
}

- (void)testFilterVectorClass
{
  class TestClass {
  private:
    NSString *_value;
    
  public:
    TestClass (NSString *value)
    {
      _value = value;
    }
    
    NSString *getValue() const noexcept
    {
      return _value;
    }
    
    void setValue(NSString *value) noexcept
    {
      _value = value;
    }
    
    bool operator==(const TestClass& rhs) const noexcept
    {
      return [getValue() isEqualToString:rhs.getValue()];
    }
  };
  
  std::vector<TestClass> a = {
    TestClass(@"2"),
    TestClass(@"1"),
    TestClass(@"6")
  };
  std::vector<TestClass> b = AS::filter(a, ^BOOL(TestClass c) {
    return c.getValue().integerValue > 1;
  });
  std::vector<TestClass> c = {
    TestClass(@"2"),
    TestClass(@"6")
  };
  XCTAssertEqual(b, c);
}

- (void)testFilterVectorEmpty
{
  std::vector<int> a = {};
  std::vector<int> b = AS::filter(a, ^BOOL(int num) {
    return num < 2;
  });
  std::vector<int> c = {};
  XCTAssertEqual(b, c);
}

@end
