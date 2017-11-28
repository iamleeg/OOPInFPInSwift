import Cocoa

// what we saw in episode 1 was that sets can be defined as a single operation: given an element of
// the set's type, is that element a member of the set? That let us create a polymorphic set type,
// as anything with the signature (Element)->Bool is a set.

// But what if we have more than one operation? Consider a list, which has a count of elements and
// a way to retrieve an element in a given position. Now the definition of a list instance is not a
// single function, it's _two_ functions: the count and the retrieval function. Let's package those
// up into a structure: anything that is an instance of that structure is a list, as far as we're
// concerned.

struct List<T> {
    let count: () -> Int
    let at: (Int) -> T?
}

// the members of the structure are _selectors_: given a list, we can "select" its count method or
// its at method for execution. Here's a constructor for a boring list

func EmptyList<T>() -> List<T>
{
    return List(count: {return 0}, at: {_ in return nil})
}

let noIntegers: List<Int> = EmptyList()

noIntegers.count()
noIntegers.at(0)

// as with sets, we can build lists that close over their constructor parameters as instance variables.
// the easiest way to build a list of arbitrary length is to build one with two members.
func LinkedList<T>(head: T, tail: List<T>) -> List<T>
{
    return List(count: { return 1 + tail.count() },
                at: {index in return (index == 0) ? head : tail.at(index - 1)})
}

let oneTwoThree : List<Int> = LinkedList(head: 1, tail: LinkedList(head: 2, tail: LinkedList(head: 3, tail: EmptyList())))

oneTwoThree.count()
oneTwoThree.at(0)
oneTwoThree.at(1)

