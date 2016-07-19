module LogRunnerExample exposing (..)

{-| HOW TO RUN THIS EXAMPLE

$ elm-make LogRunnerExample.elm --output=elm.js
$ node elm.js

Note that this always uses an initial seed of 42, since it can't do effects.
-}

import Expect
import Test exposing (..)
import Fuzz exposing (..)
import Test.Runner.Log
import Html.App
import Html
import String
import Char


main : Program Never
main =
    Html.App.beginnerProgram
        { model = ()
        , update = \_ _ -> ()
        , view = \() -> Html.text "Check the console for useful output!"
        }
        |> Test.Runner.Log.run (Test.concat [ testOxfordify, testWithoutNums ])


{-| stubbed function under test
-}
oxfordify : a -> b -> c -> String
oxfordify _ _ _ =
    "Alice, Bob, and Claire"


withoutNums : String -> String
withoutNums =
    String.filter (\ch -> not (Char.isDigit ch || ch == '.'))


testWithoutNums : Test
testWithoutNums =
    describe "withoutNums"
        [ fuzzWith { runs = 100 } (tuple3 ( string, float, string )) "adding numbers to strings has no effect" <|
            \( prefix, num, suffix ) ->
                withoutNums (prefix ++ toString num ++ suffix)
                    |> Expect.equal (withoutNums (prefix ++ suffix))
        ]


testOxfordify : Test
testOxfordify =
    describe "oxfordify"
        [ describe "given an empty sentence"
            [ test "returns an empty string" <|
                \() ->
                    oxfordify "This sentence is empty" "." []
                        |> Expect.equal ""
            ]
        , describe "given a sentence with one item"
            [ test "still contains one item" <|
                \() ->
                    oxfordify "This sentence contains " "." [ "one item" ]
                        |> Expect.equal "This sentence contains one item."
            ]
        , describe "given a sentence with multiple items"
            [ test "returns an oxford-style sentence" <|
                \() ->
                    oxfordify "This sentence contains " "." [ "one item", "two item" ]
                        |> Expect.equal "This sentence contains one item and two item."
            , test "returns an oxford-style sentence" <|
                \() ->
                    oxfordify "This sentence contains " "." [ "one item", "two item", "three item" ]
                        |> Expect.equal "This sentence contains one item, two item, and three item."
            ]
        , describe "comparisons"
            [ test "one is greater than two" <|
                \() ->
                    1
                        |> Expect.greaterThan 2
            , test "three is less than one" <|
                \() ->
                    3
                        |> Expect.lessThan 1
            ]
        , describe "a long failure message"
            [ test "long failure!" <|
                \() ->
                    Expect.equal "html, body {\nwidth: 100%;\nheight: 100%;\nbox-sizing: border-box;\npadding: 0;\nmargin: 0;\n}\n\nbody {\nmin-width: 1280px;\noverflow-x: auto;\n}\n\nbody > div {\nwidth: 100%;\nheight: 100%;\n}\n\n.dreamwriterHidden {\ndisplay: none !important;\n}\n\n#dreamwriterPage {\nwidth: 100%;\nheight: 100%;\nbox-sizing: border-box;\nmargin: 0;\npadding: 8px;\nbackground-color: rgb(100, 90, 128);\ncolor: rgb(40, 35, 76);\n}"
                        "html, body {\nwidth: 100%;\nheight: 100%;\nbox-sizing: border-box;\npadding: 0;\nmargin: 0;\n}\n\nbody {\nmin-width: 1280px;\noverflow-x: auto;\n}\n\nbody > div {\nwidth: 100%;\nheight: 100%;\n}\n\n.dreamwriterHidden {\ndisplay: none !important;\n}\n\n#Page {\nwidth: 100%;\nheight: 100%;\nbox-sizing: border-box;\nmargin: 0;\npadding: 8px;\nbackground-color: rgb(100, 90, 128);\ncolor: rgb(40, 35, 76);\n}"
            ]
        ]
