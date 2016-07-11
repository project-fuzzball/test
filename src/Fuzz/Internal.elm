module Fuzz.Internal exposing (Fuzzer(Fuzzer))

import RoseTree exposing (RoseTree)
import Random exposing (Generator)


type Fuzzer a
    = Fuzzer (Generator (RoseTree a))
