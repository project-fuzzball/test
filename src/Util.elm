module Util exposing (..)

{-| This is where I'm sticking Random helper functions I don't want to add to Pcg.
-}

import Random exposing (..)
import Array exposing (Array)
import String


rangeLengthList : Int -> Int -> Generator a -> Generator (List a)
rangeLengthList minLength maxLength generator =
    (int minLength maxLength)
        `andThen` (\len -> list len generator)


rangeLengthArray : Int -> Int -> Generator a -> Generator (Array a)
rangeLengthArray minLength maxLength generator =
    rangeLengthList minLength maxLength generator |> map Array.fromList


rangeLengthString : Int -> Int -> Generator Char -> Generator String
rangeLengthString minLength maxLength charGenerator =
    let
        string stringLength charGenerator =
            map String.fromList (list stringLength charGenerator)
    in
        (int minLength maxLength)
            `andThen` (\len -> string len charGenerator)


{-| An embarrassingly poor stand-in for https://github.com/mgold/elm-random-pcg/blob/2.1.1/src/Random/Pcg.elm#L342-L389
-}
independentSeed : Generator Seed
independentSeed =
    Random.int Random.minInt Random.maxInt
        |> Random.map Random.initialSeed
