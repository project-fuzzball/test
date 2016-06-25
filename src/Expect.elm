module Expect exposing (Expectation, pass, fail, getFailure, equal, notEqual, atMost, lessThan, greaterThan, atLeast, true, false, onFail, all)

{-| Determining whether tests pass or fail.

## Quick Reference

* [`equal`](#equal) `(arg2 == arg1)`
* [`notEqual`](#notEqual) `(arg2 /= arg1)`
* [`lessThan`](#lessThan) `(arg2 < arg1)`
* [`atMost`](#atMost) `(arg2 <= arg1)`
* [`greaterThan`](#greaterThan) `(arg2 > arg1)`
* [`atLeast`](#atLeast) `(arg2 >= arg1)`
* [`true`](#true) `(arg == True)`
* [`false`](#false) `(arg == False)`

## Basic Expectations

@docs Expectation, equal, notEqual, all

## Comparisons

@docs lessThan, atMost, greaterThan, atLeast

## Booleans

@docs true, false

## Customizing

@docs pass, fail, onFail, getFailure
-}

import Test.Expectation
import String


{-| The result of a single test run: either a [`pass`](#pass) or a
[`fail`](#fail).
-}
type alias Expectation =
    Test.Expectation.Expectation


{-| Passes if the arguments are equal.

    Expect.equal 0 (List.length [])

    -- Passes because (0 == 0) is True

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because (0 == 5) is False
    List.length []
        |> Expect.equal 5


    {-

    0
    │
    │ Expect.equal
    │
    5

    -}
-}
equal : a -> a -> Expectation
equal =
    compareWith "Expect.equal" (==)


{-| Passes if the arguments are not equal.

    Expect.notEqual 11 (90 + 10)

    -- Passes because (11 /= 100) is True

Failures only show one value, because the reason for the failure was that
both arguments were equal.

    -- Fails because (100 /= 100) is False
    (90 + 10)
        |> Expect.notEqual 100

    {-

    100
    │
    │ Expect.notEqual
    │
    100

    -}
-}
notEqual : a -> a -> Expectation
notEqual =
    compareWith "Expect.notEqual" (/=)


{-| Passes if the second argument is less than the first.

    Expect.lessThan 1 (List.length [])

    -- Passes because (0 < 1) is True

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because (0 < -1) is False
    List.length []
        |> Expect.lessThan -1


    {-

    0
    │
    │ Expect.lessThan
    │
    -1

    -}
-}
lessThan : comparable -> comparable -> Expectation
lessThan =
    compareWith "Expect.lessThan" (<)


{-| Passes if the second argument is less than or equal to the first.

    Expect.atMost 1 (List.length [])

    -- Passes because (0 <= 1) is True

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because (0 <= -3) is False
    List.length []
        |> Expect.atMost -3

    {-

    0
    │
    │ Expect.atMost
    │
    -3

    -}
-}
atMost : comparable -> comparable -> Expectation
atMost =
    compareWith "Expect.atMost" (<=)


{-| Passes if the second argument is greater than the first.

    Expect.greaterThan -2 List.length []

    -- Passes because (0 > -2) is True

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because (0 > 1) is False
    List.length []
        |> Expect.greaterThan 1

    {-

    0
    │
    │ Expect.greaterThan
    │
    1

    -}
-}
greaterThan : comparable -> comparable -> Expectation
greaterThan =
    compareWith "Expect.greaterThan" (>)


{-| Passes if the second argument is greater than or equal to the first.

    Expect.atLeast -2 (List.length [])

    -- Passes because (0 >= -2) is True

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because (0 >= 3) is False
    List.length []
        |> Expect.atLeast 3

    {-

    0
    │
    │ Expect.atLeast
    │
    3

    -}
-}
atLeast : comparable -> comparable -> Expectation
atLeast =
    compareWith "Expect.atLeast" (>=)


{-| Passes if the argument is 'True', and otherwise fails with the given message.

    Expect.true "Expected the list to be empty." (List.isEmpty [])

    -- Passes because (List.isEmpty []) is True

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because List.isEmpty returns False, but we expect True.
    List.isEmpty [ 42 ]
        |> Expect.true "Expected the list to be empty."

    {-

    Expected the list to be empty.

    -}
-}
true : String -> Bool -> Expectation
true message bool =
    if bool then
        pass
    else
        fail message


{-| Passes if the argument is 'False', and otherwise fails with the given message.

    Expect.false "Expected the list not to be empty." (List.isEmpty [ 42 ])

    -- Passes because (List.isEmpty [ 42 ]) is False

Failures resemble code written in pipeline style, so you can tell
which argument is which:

    -- Fails because (List.isEmpty []) is True
    List.isEmpty []
        |> Expect.false "Expected the list not to be empty."

    {-

    Expected the list not to be empty.

    -}
-}
false : String -> Bool -> Expectation
false message bool =
    if bool then
        fail message
    else
        pass


{-| Always passes.

    import Json.Decode exposing (decodeString, int)
    import Test exposing (test)
    import Expect


    test "Json.Decode.int can decode the number 42." <|
        \() ->
            case decodeString int "42" of
                Ok _ ->
                    Expect.pass

                Err err ->
                    Expect.fail err
-}
pass : Expectation
pass =
    Test.Expectation.Pass


{-| Fails with the given message.

    import Json.Decode exposing (decodeString, int)
    import Test exposing (test)
    import Expect


    test "Json.Decode.int can decode the number 42." <|
        \() ->
            case decodeString int "42" of
                Ok _ ->
                    Expect.pass

                Err err ->
                    Expect.fail err
-}
fail : String -> Expectation
fail =
    Test.Expectation.Fail


{-| Return `Nothing` if the given [`Expectation`](#Expectation) is a [`pass`](#pass),
and `Just` the error message if it is a [`fail`](#fail).

    getFailure (Expect.fail "this failed")
    -- Just "this failed"

    getFailure (Expect.pass)
    -- Nothing
-}
getFailure : Expectation -> Maybe String
getFailure expectation =
    case expectation of
        Test.Expectation.Pass ->
            Nothing

        Test.Expectation.Fail desc ->
            Just desc


{-| If the given expectation fails, replace its failure message with a custom one.

    "something"
        |> Expect.equal "something else"
        |> Expect.onFail "thought those two strings would be the same"
-}
onFail : String -> Expectation -> Expectation
onFail str expectation =
    case expectation of
        Test.Expectation.Pass ->
            expectation

        Test.Expectation.Fail _ ->
            fail str


{-| Translate each element in a list into an [`Expectation`](#Expectation). If
they all pass, return a pass. If any fail, return a fail whose message includes
all the other failure messages.

    [ 0, 1, 2, 3, 4, 5 ]
        |> Expect.all (Expect.lessThan 3)

    {-

    Expected      3

    lessThan  3

    ---

    Expected      4

    lessThan  3

    ---

    Expected      5

    lessThan  3

    -}
-}
all : (a -> Expectation) -> List a -> Expectation
all getExpectation list =
    case List.filterMap (getExpectation >> getFailure) list of
        [] ->
            pass

        failures ->
            failures
                |> String.join "\n\n---\n\n"
                |> fail


reportFailure : String -> String -> String -> String
reportFailure actualCaption expected actual =
    [ expected
    , "╷"
    , "│ " ++ actualCaption
    , "╵"
    , actual
    ]
        |> String.join "\n"


expectedCaption : String
expectedCaption =
    "Expected"


withUnderline : String -> String
withUnderline str =
    str ++ "\n" ++ String.repeat (String.length str) "-"


compactModeLength : Int
compactModeLength =
    64


compareWith : String -> (a -> a -> Bool) -> a -> a -> Expectation
compareWith label compare expected actual =
    if compare actual expected then
        pass
    else
        fail (reportFailure label (toString expected) (toString actual))
