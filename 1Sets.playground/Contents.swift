import Cocoa

// let's define a set as a container in which an object is either present or absent.
// here's a definition of what a set of integers might look like:
typealias IntegerSet = (Int) -> Bool
typealias MySet<T> = (T) -> Bool

// so these two things are both examples, or instances, of the "Set of Integers" idea
let emptySet : MySet<Int> = {(_) in return false}
let universe : MySet<Int> = {(_) in return true}

emptySet(12)
universe(12)

// but they're pretty unexciting. it'd be nice to have some _configurable_ Sets, so we
// can decide what is or is not in a Set. We'll create a function that returns sets, and
// we can configure them by passing parameters to the functions.

func RangeSet(from lower: Int, to upper: Int) -> MySet<Int>
{
    return { (x) in (x >= lower) && (x <= upper)}
}

// notice that instances of RangeSet are implemented as _closures_ over the parameters in
// the constructor.

let threeFourFive : IntegerSet = RangeSet(from: 3, to: 5)

threeFourFive(2)
threeFourFive(3)

let oneAndTwo : IntegerSet = RangeSet(from: 1, to: 2)

// we can build set definitions out of other sets, too
// notice here that the two sets escape the constructor, not the instance: we have
// instance variable encapsulation
func UnionSet<T>(of left: @escaping MySet<T>,
                 and right: @escaping MySet<T>) -> MySet<T>
{
    return { (x) in (left(x) || right(x))}
}

let oneToFive : IntegerSet = UnionSet(of: oneAndTwo, and: threeFourFive)

oneToFive(0)
oneToFive(6)
oneToFive(2)

let twoToFour : IntegerSet = RangeSet(from: 2, to: 4)

func IntersectionSet<T>(of left: @escaping MySet<T>, and right: @escaping MySet<T>) -> MySet<T>
{
    return { (x) in (left(x) && right(x)) }
}

// because our sets are all the same type but respond in the same way, we can use
// different "types" of sets anywhere a set is expected.
// This is polymorphism.
let intersectional = IntersectionSet(of: oneToFive, and: twoToFour)

intersectional(2)
intersectional(1)

