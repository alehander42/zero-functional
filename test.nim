import unittest, zero_functional, options, lists, macros, strutils

# different lists
let a = @[2, 8, -4]
let b = @[0, 1, 2]
let c = @["zero", "one", "two"]

# different arrays
let aArray = [2, 8, -4]
let bArray = [0, 1, 2]
let cArray = ["zero", "one", "two"]


type 
  # Check working with enum type
  Suit {.pure.} = enum
    diamonds = (0, "D"),
    hearts = (1, "H"), 
    spades = (2, "S"), 
    clubs = (3, "C")

  ## User-defined that supports Iterator and random access. 
  Pack = ref object
    rows: seq[int]
  
  ## same as Pack but without the `add` function
  PackWoAdd = ref object
    rows: seq[int]
  
proc len(pack: Pack) : int = 
  pack.rows.len()
proc `[]`(pack: Pack, idx: int) : int  = 
  pack.rows[idx]
proc add(pack: Pack, t: int)  = 
  pack.rows.add(t)

proc len(pack: PackWoAdd) : int = 
  pack.rows.len()
proc `[]`(pack: PackWoAdd, idx: int) : int  = 
  pack.rows[idx]
  
## init_zf is used to create the user-defined Pack item
proc init_zf(a: Pack): Pack =
  Pack(rows: @[])
proc init_zf(a: PackWoAdd): PackWoAdd =
  PackWoAdd(rows: @[])

proc f(a: int, b: int): int =
  a + b

proc g(it: int): int =
  if it == 2:
    result = it + 2
  else:
    result = it + 1

## Macro that checks that the expression compiles
## Calls "check"
macro accept*(e: untyped): untyped =
  static: 
    assert(compiles(e))
  result = quote:
    check(`e`)

## Checks that the given expression is rejected by the compiler.
template reject*(e) =
  static: assert(not compiles(e))

## This is kind of "TODO" - when an expression does not compile due to a bug
## and it actually should compile, the expression may be surrounded with 
## `check_if_compile'. This macro will complain to use `check` when the expression
## actually gets compilable. 
macro check_if_compiles*(e: untyped): untyped =
  let content = repr(e)
  let msg = "[WARN]: Expression compiles. Use 'check' around '" & `content` & "'"

  result = quote:
    when compiles(check(`e`)):
      stderr.writeLine(`msg`)
      check(`e`)
    else:
      discard


suite "valid chains":

  test "basic filter":
    check(a --> filter(it > 0) == @[2, 8])

  test "basic zip":
    check((zip(a, b, c) --> filter(it[0] > 0 and it[2] == "one")) == @[(8, 1, "one")])

  test "map":
    check((a --> map(it - 1)) == @[1, 7, -5])

  test "filter":
    check((a --> filter(it > 2)) == @[8])

  test "exists":
    check((a --> exists(it > 0)))

  test "all":
    check(not (a --> all(it > 0)))

  test "index":
    check((a --> index(it > 4)) == 1)

  test "find":
    check((a --> find(it > 2)) == some(8))
    check((a --> find(it mod 5 == 0)) == none(int))

  test "indexedMap":
    check((a --> indexedMap(it)) == @[(0, 2), (1, 8), (2, -4)])

  test "fold":
    check((a --> fold(0, a + it)) == 6)

  test "map with filter":
    check((a --> map(it + 2) --> filter(it mod 4 == 0)) == @[4])

  test "map with exists":
    check((a --> map(it + 2) --> exists(it mod 4 == 0)))

  test "map with all":
    check(not (a --> map(it + 2) --> all(it mod 4 == 0)))

  test "map with fold":
    check((a --> map(g(it)) --> fold(0, a + it)) == 10)

  test "map with changed type":
    check((a --> mapSeq($it)) == @["2", "8", "-4"])
  
  test "filter with exists":
    check(not (a --> filter(it > 2) --> exists(it == 4)))

  test "filter with index":
    check((a --> filter(it mod 2 == 0) --> index(it < 0)) == 2)

  test "foreach":
    var sum = 0
    a --> foreach(sum += it)
    check(sum == 6)

  test "foreach with index":
    var sum_until_it_gt_2 = 0
    check((a --> foreach(sum_until_it_gt_2 += it).index(it > 2)) == 1)
    check(sum_until_it_gt_2 == 10) # loop breaks when condition in index is true

  test "foreach change in-place":
    var my_list = @[2,3,4]
    my_list --> foreach(it = idx * it)
    check(my_list == @[0,3,8])

  test "multiple methods":
    let n = zip(a, b) -->
      map(f(it[0], it[1])).
      filter(it mod 4 > 1).
      map(it * 2).
      all(it > 4)
    check(not n)

  test "zip with array":
    check((zip(aArray, bArray) --> map(it[0] + it[1])) == @[2, 9, -2])

  test "array basic filter":
    check((aArray --> filter(it > 0)) == [2, 8, 0])

  test "array basic zip":
    check((zip(aArray, bArray, cArray) --> filter(it[0] > 0 and it[2] == "one")) == @[(8, 1, "one")])

  test "array map":
    check((aArray --> map(it - 1)) == [1, 7, -5])

  test "array filter":
    check((aArray --> filter(it > 2)) == [0, 8, 0])

  test "array filterSeq":
    check((aArray --> filterSeq(it > 2)) == @[8])

  test "array exists":
    check((aArray --> exists(it > 0)))

  test "array all":
    check(not (aArray --> all(it > 0)))

  test "array index":
    check((aArray --> index(it > 4)) == 1)

  test "array find":
    check((aArray --> find(it < 0)) == some(-4))
    check((aArray --> find(it mod 3 == 0)) == none(int))

  test "array indexedMap":
    check((aArray --> indexedMap(it)) == @[(0, 2), (1, 8), (2, -4)])
    check((aArray --> map(it + 2) --> indexedMap(it) --> map(it[0] + it[1])) == @[4, 11, 0])
  
  test "array fold":
    check((aArray --> fold(0, a + it)) == 6)

  test "array map with filter":
    check((aArray --> map(it + 2) --> filter(it mod 4 == 0)) == [4, 0, 0])

  test "array map with exists":
    check((aArray --> map(it + 2) --> exists(it mod 4 == 0)))

  test "array map with all":
    check(not (aArray --> map(it + 2) --> all(it mod 4 == 0)))

  test "array map with fold":
    check((aArray --> map(g(it)) --> fold(0, a + it)) == 10)

  test "array filter with exists":
    check(not (aArray --> filter(it > 2) --> exists(it == 4)))

  test "array filter with index":
    check((aArray --> filter(it mod 2 == 0) --> index(it < 0)) == 2)

  test "array foreach":
    var sum = 0
    aArray --> foreach(sum += it)
    check(sum == 6)

  test "array foreach with index":
    var sum_until_it_gt_2 = 0
    check((aArray --> foreach(sum_until_it_gt_2 += it) --> index(it > 2)) == 1)
    check(sum_until_it_gt_2 == 10) # loop breaks when condition in index is true
  
  test "array with foreach change in-place":
    var my_array = [2,3,4]
    my_array --> foreach(it = idx * it)
    check(my_array == [0,3,8])

  test "array":
    let n = zip(aArray, bArray) -->
      map(f(it[0], it[1])).
      filter(it mod 4 > 1).
      map(it * 2).
      all(it > 4)
    check(not n)

  test "array filterSeq":
    check((aArray --> map(it * 2) --> filterSeq(it > 0)) == @[4, 16])
    check((aArray --> map(it * 2) --> filter(it > 0)) == [4, 16, 0])

  test "array mapSeq":
    check((aArray --> map(it + 2) --> mapSeq(it * 2)) == @[8, 20, -4])

  test "array sub":
    check((aArray--> sub(1)) == [0, 8, -4])
    check((aArray --> sub(1,2)) == [0, 8, 0])
    check((aArray --> sub(1,^1)) == [0, 8, 0])

  test "array subSeq":
    check((aArray --> subSeq(1)) == @[8, -4])
    check((aArray --> subSeq(1,2)) == @[8])
    check((aArray --> subSeq(1,^1)) == @[8])
    
  test "array indexedMap":
    check((aArray --> map(it + 2) --> indexedMap(it) --> map(it[0] + it[1])) == @[4, 11, 0])

  test "seq filterSeq":
    check((a --> filterSeq(it > 0)) == @[2, 8])
    check((a --> filter(it > 0)) == @[2, 8])

  test "seq mapSeq":
    check((a --> mapSeq(it * 2)) == @[4, 16 , -8])

  test "seq indexedMap":
    check((a --> indexedMap(it) --> map(it[0] + it[1])) == @[2, 9, -2])

  test "seq sub":
    check((a --> filter(idx >= 1)) == @[8, -4])
    check((a --> sub(1)) == @[8, -4])
    check((a --> sub(1,2)) == @[8])
    check((a --> sub(1,^1)) == @[8])

  test "enum map":
    check((Suit --> map($it)) == @["D", "H", "S", "C"])


  test "enum filter":
    check((Suit --> filter($it == "H")) == @[Suit.hearts])

  test "enum find":
    check ((Suit --> find($it == "H")) == some(Suit.hearts))
    check ((Suit --> find($it == "X")) == none(Suit))

  test "multi ascending":
    template ascending(s: untyped) : bool = # check if the elements in seq or array are in ascending order
      s --> sub(1) --> all(s[idx]-s[idx-1] > 0)
      # alternative implementation: 
      # s --> all(idx == 0 or s[idx]-s[idx-1] > 0)
    check(ascending(a) == false)
    check(ascending(b) == true)
    check(ascending(aArray) == false)
    check(ascending(bArray) == true)

  test "filter template":
    let stuttered = @[0,1,1,2,2,2,3,3]
    let stutteredArr = [0,0,1,2,3,3]
    template destutter(s: untyped) : untyped =
      s --> filterSeq(idx == 0 or s[idx] != s[idx-1])
    check(destutter(stuttered) == @[0,1,2,3])
    check(destutter(stutteredArr) == @[0,1,2,3])

  test "generic filter":
    let p = Pack(rows: @[0,1,2,3])
    check((p --> filterSeq(it != 0)) == @[1,2,3]) 
    check((p --> filter(it != 0)).rows ==  @[1,2,3])
  test "empty":
    let e : seq[int] = @[]
    let res : seq[int] = @[]
    check((e --> all(false)) == true)
    check((e --> exists(false)) == false)
    check((e --> map(it * 2)) == res)
    check((e --> filter(it > 0) --> map(it * 2)) == res)

  test "flatten":
    let f = @[@[1,2,3],@[4,5],@[6]]
    check((f --> flatten()) == @[1,2,3,4,5,6])

  test "flatten sum":
    check((@[a,b] --> flatten() --> fold(0, a + it)) == 9)

  test "zip flatten":
    check((zip(a,b) --> flatten()) == @[2,0,8,1,-4,2])

  test "change DoublyLinkedList in-place":
    var d = initDoublyLinkedList[int]()
    d.append(1)
    d.append(2)
    d.append(3)
    d --> foreach(it = it * 2) # change d in-place
    check((d --> filterSeq(it > 2)) == @[4, 6]) 
    check((d --> mapSeq(float(it) * 1.5)) == @[3.0, 6.0, 9.0])
  
  test "create DoublyLinkedList":
    var d = initDoublyLinkedList[int]()
    d.append(1)
    d.append(2)
    d.append(3)
    let e : DoublyLinkedList[string] = (d --> map(float(it) * 2.4) --> filter(it < 6.0) --> map($it))
    check((e --> map(it) --> to(seq[string])) == @["2.4", "4.8"])
    check((e --> map($it) --> to(seq)) == @["2.4", "4.8"])
    check((e --> map(it) --> to(seq)) == @["2.4", "4.8"])

  test "combinations":
    ## get indices of items where the difference of the elements is 1
    let items = @[1,5,2,9,8,3,11]
    # ----------- 0 1 2 3 4 5 6
    proc abs1(a: int, b: int) : bool = abs(a-b) == 1 
    let b = items -->
      combinations().
      filter(abs1(c.it[0], c.it[1])).
      map(c.idx) 
    check(b == @[[0, 2], [2, 5], [3, 4]])
    check(b --> all(abs1(items[it[0]], items[it[1]])))

    # the same again, but store it to a new list
    let c = items --> 
      combinations().
      filter(abs1(c.it[0], c.it[1])).
      map(c.idx).
      to(list)
    
    # check that all items in the list and the seq are the same
    check(c --> all(it == b[idx]))

  test "rejected flatten":
    # some things are not possible or won't compile
    let fArray = [[1,2,3], [4,5,6]]
    let fList = fArray --> map(it) --> to(list)
    let fListFlattened = fList --> flatten() --> to(list)
    let fSeq = @[1,2,3,4,5,6]
    
    # flatten defaults to seq output if not explicitly set to the output format (except DoublyLinkedList)
    reject((fArray --> flatten()) == [1,2,3,4,5,6])
    accept((fArray --> flatten()) == fSeq)
    # array dimensions must be explicitly given
    reject((fArray --> flatten() --> to(array)) == [1,2,3,4,5,6]) 
    accept((fArray --> flatten() --> to(array[6,int])) == [1,2,3,4,5,6])
    accept((fArray --> flatten() --> to(array[8,int])) == [1,2,3,4,5,6,0,0]) # if array is too big, the array is filled with default zero

    reject((fList --> flatten()) == fSeq)
    # list is flattened to list by default
    # comparison of DoublyLinkedList does not seem to work directly...
    accept($(fList --> flatten()) == $fListFlattened)

  test "rejected missing add function":
    let p2 = PackWoAdd(rows: @[0,1,2,3])
    # PackWoAdd as iterable does not define the add method (or append) - hence this won't compile
    reject((p2 --> filter(it != 0)).rows ==  @[1,2,3]) 
    # forced to seq -> compiles
    accept((p2 --> filter(it != 0) --> to(seq)) == @[1,2,3])
    # also when using map which will lead to seq output
    accept((p2 --> filter(it != 0) --> map($it)) == @["1","2","3"])
    accept((p2 --> filter(it != 0) --> map(it)) == @[1,2,3])

  test "rejected wrong result type":
    # a contains int and cannot be mapped to seq[string] without $ operator
    reject((a --> filter(it > 2) --> to(seq[string])) == @["8"])

  test "rejected 'to' with an integral result type":
    reject(a --> exists(it < 0) --> to(list))
    accept(a --> map(it) --> to(seq) == a)

  test "SinglyLinkedList reversing elements":
    var l = a --> map(it) --> to(SinglyLinkedList)
    check(l --> map(it).to(seq) == @[-4,8,2])

  test "map with operator access":
    proc gg(): seq[string] =
      @["1","2","3"]
    
    check(gg() --> map(parseInt(it))[0] == 1)
    check(gg() --> map(parseInt(it)) --> map(1.5 * float(it))[2] == 4.5)
    check(a --> index(it == -4) + 1 == 3)
  
