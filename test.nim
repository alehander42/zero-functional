import unittest, zero_functional

var a = @[2, 8, -4]
var b = @[0, 1, 2]
var c = @["zero", "one", "two"]

proc f(a: int, b: int): int =
  a + b

proc g(it: int): int =
  if it == 2:
    result = it + 2
  else:
    result = it + 1

suite "valid chains":
  test "basic filter":
    check((a --> filter(it > 0)) == @[2, 8])

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

  test "filter with exists":
    check(not (a --> filter(it > 2) --> exists(it == 4)))

  test "filter with index":
    check((a --> filter(it mod 2 == 0).index(it < 0)) == 2)

  test "foreach":
    var sum = 0
    a --> foreach(sum += it)
    check(sum == 6)

  test "foreach with index":
    var sum_until_it_gt_2 = 0
    check((a --> foreach(sum_until_it_gt_2 += it).index(it > 2)) == 1)
    check(sum_until_it_gt_2 == 10) # loop breaks when condition in index is true

  test "multiple methods":
    var n = zip(a, b) -->
      map(f(it[0], it[1])).
      filter(it mod 4 > 1).
      map(it * 2).
      all(it > 4)
    check(not n)
