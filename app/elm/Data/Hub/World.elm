module Data.Hub.World exposing (..)

import Helpers.Dict exposing (indexedDictFrom)
import Scenes.Hub.Types exposing (..)
import Scenes.Level.Types exposing (..)


makeWorldLevels : List LevelData -> WorldLevels
makeWorldLevels =
    indexedDictFrom 1


rain : Probability -> TargetScore -> TileSetting
rain prob targetScore =
    TileSetting Rain prob (Just targetScore)


sun : Probability -> TargetScore -> TileSetting
sun prob targetScore =
    TileSetting Sun prob (Just targetScore)


seed : SeedType -> Probability -> TargetScore -> TileSetting
seed seedType prob targetScore =
    TileSetting (Seed seedType) prob (Just targetScore)


seedPod : Probability -> TileSetting
seedPod prob =
    TileSetting SeedPod prob Nothing
