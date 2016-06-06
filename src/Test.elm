module Test exposing (Test, toRunners, batch, describe, it, unit, fuzz, fuzz2, fuzz3, fuzz4, fuzz5, onFail, runs)

{-|

@docs Test, batch, describe, it, unit, fuzz, fuzz2, fuzz3, fuzz4, fuzz5, toRunners, onFail, runs
-}

import Fuzzer exposing (Fuzzer)
import Assert exposing (Outcome)
import Random.Pcg as Random exposing (Generator)


-- none of the types below will be exported, except Test which will be opaque


type alias Options =
    { onFail : List String
    , runs : Maybe Int
    , doShrink : Maybe Bool
    , seed : Maybe Random.Seed
    }


initialOptions : Options
initialOptions =
    { onFail = [], runs = Nothing, doShrink = Nothing, seed = Nothing }


defaults : { runs : Int, doShrink : Bool, seed : Random.Seed }
defaults =
    { runs = 100, doShrink = False, seed = Random.initialSeed 42 }


{-| A Test is either
   * A list of thunks, each of which returns an Outcome
   * A batch of these tests
-}
type Test
    = Assertions Options (List (Options -> Outcome))
    | Batch Options (List Test)


{-| Turn a `Test` into a list of thunks that can be run to produce outcomes.
-}
toRunners : Random.Seed -> Test -> List (() -> Outcome)
toRunners seed =
    toRunnersHelp { initialOptions | seed = Just seed }


toRunnersHelp : Options -> Test -> List (() -> Outcome)
toRunnersHelp baseOpts test =
    case test of
        Assertions opts thunks ->
            List.map (thunkToOutcome (mergeOptions opts baseOpts)) thunks

        Batch opts suites ->
            List.concatMap (toRunnersHelp (mergeOptions opts baseOpts)) suites


thunkToOutcome : Options -> (Options -> Outcome) -> () -> Outcome
thunkToOutcome opts getAssertion _ =
    getAssertion opts


{-| TODO: docs
-}
onFail : String -> Outcome -> Outcome
onFail str outcome =
    Assert.formatFailures (\_ -> str) outcome


{-| TODO: docs
-}
it : String -> (a -> Outcome) -> a -> Outcome
it str getOutcome arg =
    Assert.addContext str (getOutcome arg)


{-| TODO: docs
-}
runs : Int -> Test -> Test
runs count test =
    case test of
        Assertions opts thunks ->
            Assertions { opts | runs = Maybe.oneOf [ opts.runs, Just count ] } thunks

        Batch opts tests ->
            Batch { opts | runs = Maybe.oneOf [ opts.runs, Just count ] } tests


{-| TODO: docs
-}
unit : List (() -> Outcome) -> Test
unit fns =
    fns
        |> List.map (\fn -> (\_ -> fn ()))
        |> Assertions initialUnitOptions


initialUnitOptions : Options
initialUnitOptions =
    { onFail = [], runs = Just 1, doShrink = Just False, seed = Just defaults.seed }


{-| TODO docs
-}
fuzz :
    Fuzzer a
    -> List (a -> Outcome)
    -> Test
fuzz { generator } fuzzTests =
    Assertions initialOptions (List.map (fuzzToThunk generator) fuzzTests)


{-| TODO docs
-}
fuzz2 :
    Fuzzer a
    -> Fuzzer b
    -> List (a -> b -> Outcome)
    -> Test
fuzz2 fuzzA fuzzB =
    let
        gen =
            Random.map2 (,)
                fuzzA.generator
                fuzzB.generator
    in
        fuzzN (uncurry >> fuzzToThunk gen)


{-| TODO docs
-}
fuzz3 :
    Fuzzer a
    -> Fuzzer b
    -> Fuzzer c
    -> List (a -> b -> c -> Outcome)
    -> Test
fuzz3 fuzzA fuzzB fuzzC =
    let
        gen =
            Random.map3 (,,)
                fuzzA.generator
                fuzzB.generator
                fuzzC.generator
    in
        fuzzN (uncurry3 >> fuzzToThunk gen)


{-| TODO docs
-}
fuzz4 :
    Fuzzer a
    -> Fuzzer b
    -> Fuzzer c
    -> Fuzzer d
    -> List (a -> b -> c -> d -> Outcome)
    -> Test
fuzz4 fuzzA fuzzB fuzzC fuzzD =
    let
        gen =
            Random.map4 (,,,)
                fuzzA.generator
                fuzzB.generator
                fuzzC.generator
                fuzzD.generator
    in
        fuzzN (uncurry4 >> fuzzToThunk gen)


{-| TODO docs
-}
fuzz5 :
    Fuzzer a
    -> Fuzzer b
    -> Fuzzer c
    -> Fuzzer d
    -> Fuzzer e
    -> List (a -> b -> c -> d -> e -> Outcome)
    -> Test
fuzz5 fuzzA fuzzB fuzzC fuzzD fuzzE =
    let
        gen =
            Random.map5 (,,,,)
                fuzzA.generator
                fuzzB.generator
                fuzzC.generator
                fuzzD.generator
                fuzzE.generator
    in
        fuzzN (uncurry5 >> fuzzToThunk gen)


{-| Run a list of tests.

See [`describe`](#describe) for running tests with a descriptive string.
-}
batch : List Test -> Test
batch =
    Batch initialOptions


{-| Run a test and associate the given description.
-}
describe : String -> (a -> Test) -> a -> Test
describe desc getTest arg =
    Batch { initialOptions | onFail = [ desc ] } [ getTest arg ]


uncurry3 : (a -> b -> c -> d) -> ( a, b, c ) -> d
uncurry3 fn ( a, b, c ) =
    fn a b c


uncurry4 : (a -> b -> c -> d -> e) -> ( a, b, c, d ) -> e
uncurry4 fn ( a, b, c, d ) =
    fn a b c d


uncurry5 : (a -> b -> c -> d -> e -> f) -> ( a, b, c, d, e ) -> f
uncurry5 fn ( a, b, c, d, e ) =
    fn a b c d e


mergeOptions : Options -> Options -> Options
mergeOptions child parent =
    { onFail = parent.onFail ++ child.onFail
    , runs = Maybe.oneOf [ child.runs, parent.runs ]
    , doShrink = Maybe.oneOf [ child.doShrink, parent.doShrink ]
    , seed = Maybe.oneOf [ child.seed, parent.seed ]
    }


fuzzToThunk : Generator a -> (a -> Outcome) -> Options -> Outcome
fuzzToThunk generator runAssert opts =
    let
        seed =
            Maybe.withDefault defaults.seed opts.seed

        runs =
            Maybe.withDefault defaults.runs opts.runs

        doShrink =
            Maybe.withDefault defaults.doShrink opts.doShrink

        runWithInput val =
            ( Just (toString val), runAssert val )

        -- testRuns : Generator (List a)
        testRuns =
            generator
                |> Random.list runs
                |> Random.map (List.map runWithInput)

        outcome =
            Random.step testRuns seed
                |> formatOutcomes
    in
        List.foldr Assert.addContext outcome opts.onFail


formatOutcomes : ( List ( Maybe String, Outcome ), Random.Seed ) -> Outcome
formatOutcomes ( assertions, seed ) =
    assertions
        |> List.map formatOutcome
        |> Assert.concatOutcomes


formatOutcome : ( Maybe String, Outcome ) -> Outcome
formatOutcome ( input, outcome ) =
    Assert.formatFailures (prependInput input) outcome


prependInput : Maybe String -> String -> String
prependInput input original =
    case input of
        Nothing ->
            original

        Just str ->
            "Input: " ++ str ++ "\n\n" ++ original


fuzzN : (a -> Options -> Outcome) -> List a -> Test
fuzzN fn fuzzTests =
    fuzzTests
        |> List.map fn
        |> Assertions initialOptions
