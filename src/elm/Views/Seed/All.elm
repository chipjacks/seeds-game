module Views.Seed.All exposing (renderSeed)

import Data.Board.Types exposing (..)
import Svg exposing (Svg)
import Views.Seed.Circle exposing (chrysanthemum)
import Views.Seed.Mono exposing (greyedOutSeed, rose)
import Views.Seed.Twin exposing (cornflower, lupin, marigold, sunflower)


renderSeed : SeedType -> Svg msg
renderSeed seedType =
    case seedType of
        Sunflower ->
            sunflower

        Chrysanthemum ->
            chrysanthemum

        Cornflower ->
            cornflower

        Lupin ->
            lupin

        Rose ->
            rose

        Marigold ->
            marigold
