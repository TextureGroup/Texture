/**
 Copyright (c) 2015-2017 Lukas Kubanek
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

extension OrderedDictionary: CustomStringConvertible {
    
    /// A textual representation of the ordered dictionary.
    public var description: String {
        return makeDescription(debug: false)
    }
    
}

extension OrderedDictionary: CustomDebugStringConvertible {
    
    /// A textual representation of the ordered dictionary, suitable for debugging.
    public var debugDescription: String {
        return makeDescription(debug: true)
    }
    
}

extension OrderedDictionary {
    
    fileprivate func makeDescription(debug: Bool) -> String {
        // The implementation of the description is inspired by zwaldowski's implementation of the
        // ordered dictionary. See http://bit.ly/2iqGhrb
        
        if isEmpty { return "[:]" }
        
        let printFunction: (Any, inout String) -> () = {
            if debug {
                return { debugPrint($0, separator: "", terminator: "", to: &$1) }
            } else {
                return { print($0, separator: "", terminator: "", to: &$1) }
            }
        }()
        
        let descriptionForItem: (Any) -> String = { item in
            var description = ""
            printFunction(item, &description)
            return description
        }
        
        let bodyComponents = map { element in
            return descriptionForItem(element.key) + ": " + descriptionForItem(element.value)
        }
        
        let body = bodyComponents.joined(separator: ", ")
        
        return "[\(body)]"
    }
    
}
