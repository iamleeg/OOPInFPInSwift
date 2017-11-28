import Cocoa

// the Sets in episode one of this series had a single method, the membership test, so were defined
// exactly as a function that implemented the membership test.

// in episode two, Lists had two methods: counting and retrieval, so we used structures to implement
// tables that contained these two methods. This turned out to be quite cumbersome when we wanted
// to extend lists, because we had to create a different table with the two+others methods we now needed
// and some machinery to map between them.

// the functional programming feature for mapping between two things is a "function", so let's stop using
// tables and start using functions. We'll take baby steps, starting by just changing the table into a
// function. The selector mapping for a List could look like this:

enum ListSelectors {
    case count
    case at
}

// now rather than get a table containing _all_ methods, we'll be able to call a function with a selector
// get a _specific_ method. Notice that `count` and `at` have different signatures, so the selector map
// actually needs to be a union type: we need to understand the method signature for a selector

enum MyList<T> {
    case count (() -> Int)
    case at ((Int) -> T?)
}

// now an object can be written as a message dispatch function: given a message containing a selector
// find the method that corresponds to the selector.

func EmptyList<T>(_cmd: ListSelectors) -> MyList<T>
{
    switch _cmd {
    case .count:
        return MyList<T>.count({ return 0 })
    case .at:
        return MyList<T>.at({ _ in return nil })
    }
}

// because Swift requires you to use you're type's good, you need to make sure the type of the thing
// you extract from this discriminated union matches the type you put in. This makes invoking the
// returned method quite cumbersome:

let emptyCountIMP : MyList<Int> = EmptyList(_cmd: .count)
switch emptyCountIMP {
case .count(let f):
    f()
default:
    assertionFailure("Method signature does not match expected type for selector")
}

// Doing that every time would be tedious, so rather than make clients do message lookups and invoke the
// messages themselves over and over, we'll give them a "message send" syntax which takes care of dispatching
// the selector, making sure the method signature matches and invoking the discovered method.
func countOfList<T>(list: ((ListSelectors)->MyList<T>)) -> Int
{
    switch list(.count) {
    case .count(let f):
        return f()
    default:
        assertionFailure("Method signature does not match expected type for selector")
        // unreached
        return 0
    }
}

func objectInListAtIndex<T>(list: ((ListSelectors)->MyList<T>), index: Int) -> T?
{
    switch list(.at) {
    case .at(let f):
        return f(index)
    default:
        assertionFailure("Method signature does not match expected type for selector")
        // unreached
        return nil
    }
}

// so, given a linked list built from this system
func MyLinkedList<T>(head: T, tail: @escaping ((ListSelectors)->MyList<T>)) -> ((ListSelectors) -> MyList<T>)
{
    return {(_cmd) in
        switch _cmd {
        case .count:
            return MyList<T>.count({
                return 1 + countOfList(list: tail)
            })
        case .at:
            return MyList<T>.at({ (i) in
                if i < 0 { return nil }
                if i == 0 { return head }
                return objectInListAtIndex(list: tail, index: i - 1)
            })
        }
    }
}

let unitList = MyLinkedList(head: "Hello",
                            tail: MyLinkedList(head: "World",
                                               tail: EmptyList))

// we can easily use its methods via the type-safe dispatch functions
countOfList(list: unitList)
objectInListAtIndex(list: unitList, index: 1)

