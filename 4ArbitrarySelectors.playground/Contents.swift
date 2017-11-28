import Cocoa

// in episode 3, we replaced the selector tables in our list type with dispatch functions that took a
// selector as an argument and returned a method implementation. However, we did not address a big
// shortcoming that we found in episode 2: lists are defined as "something that has a `count` method and
// an `at` method", and anything else - including things that have a `count` method, an `at` method, and
// a `describe` method - is not a list.

// the dispatch tables from episode 2, and the dispatch functions from episode 3, are _total_ functions
// over a limited space of possible selectors. In this episode, we'll expand the space of selectors to
// be any string

typealias Selector = String

// and we'll make method dispatch a _partial_ function so that we don't have to supply all infinity
// methods. As with episode 3, there are multiple possible method signatures for the method at a given
// selector, so we'll build a discriminated union of possible implementation types.

enum IMP {
    case accessor(()->((Selector)->IMP)?)
    case asInteger(()->Int?)
    case methodMissing(()->((Selector)->IMP)?)
    case mutator((((Selector)->IMP))->Void)
    case description(()->String?)
}

// most of these cases exist so that we can move data between this system and the Swift type system,
// with one important exception.

// Notice the repeated signature `(Selector)->IMP`. That comes up a few times: accessors and mutators treat
// that type as their return value and argument respectively, and also it can be returned in the case of
// a missing method, to allow the Selector to be passed to a handler that can forward the message or
// otherwise deal with it.

// My assertion is that what we're going to build in this episode are functions that turn selectors into
// method implementations. They can work with references to other functions of that type. The grand claim
// that this whole series is predicated around is the following type alias:

typealias Object = (Selector) -> IMP

// in other words, an object is nothing other than a function that maps messages onto methods.

// here's the empty object constructor.
func DoesNothing() -> Object {
    var _self : Object! = nil
    func myself (selector: Selector)->IMP {
        return IMP.methodMissing({assertionFailure("method missing: \(selector)"); return nil;})
    }
    _self = myself
    return _self
}

let o : Object = DoesNothing()

// here's something a bit more interesting: an object that captures a Swift `Int` and makes it part of our
// object system. It provides a method for retrieving the `Int`.

func Integer(x: Int, proto: @escaping Object) -> Object {
    var _self : Object! = nil
    let _x = x
    func myself(selector:Selector) -> IMP {
        switch(selector) {
        case "intValue":
            return IMP.asInteger({ return _x })
        case "description":
            return IMP.description({ return "\(_x)" })
        default:
            return IMP.methodMissing({ return proto })
        }
    }
    _self = myself
    return _self
}

let theMeaning = Integer(x:42, proto:o)

// we'll come back to that `proto` parameter shortly. Meanwhile, remember that in the previous episode we
// had to unpack all those enumerated types and discriminated unions. We have to do that here, too. Let's
// build the "message lookup" operator, which returns the method implementation for a given selector.
// If the receiving object doesn't implement the selector, it should return a `methodMissing` implementation
// which can tell us another object to ask.

infix operator ..

func .. (receiver: Object?, _cmd:Selector) -> IMP? {
    if let this = receiver {
        let method = this(_cmd)
        switch(method) {
        case .methodMissing(let f):
            return f().._cmd
        default:
            return method
        }
    }
    else {
        return nil
    }
}

// so now we can look up methods on objects. Like Objective-C, if the receiver is `nil`, then the result
// is `nil` (unlike Objective-C, that `nil` is the empty value of the target type, not a magic way of
// handling a 0)
nil.."intValue"

// notice that the `Integer` we created up there has a `proto` instance variable, and any method it doesn't
// understand gets passed to `proto`. That's because this object system is more like Self or JavaScript than
// Smalltalk or Objective-C: it doesn't have classes, but you can implement shared behaviour by putting it
// in a prototype object (that's prototype in the inheritance sense, not the cloning sense).
// You can build classes out of prototypes, but I'll leave that for you.

// back to the machinery that removes the boilerplate of unboxing all those enums, it could look like this:
func ℹ︎(receiver:Object?)->Int? {
    if let imp = receiver.."intValue" {
        switch(imp) {
        case .asInteger(let f):
            return f()
        default:
            return nil
        }
    } else {
        return nil
    }
}

ℹ︎(receiver: theMeaning)!

