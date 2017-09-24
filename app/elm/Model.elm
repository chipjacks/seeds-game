module Model exposing (..)

import Dict exposing (Dict)
import Dom
import Mouse
import Data.Level.Types exposing (Coord, SeedType, TileProbability)
import Scenes.Level.Model as Level
import Window


type alias Model =
    { scene : Scene
    , sceneTransition : Bool
    , transitionBackground : TransitionBackground
    , progress : LevelProgress
    , currentLevel : Maybe LevelProgress
    , infoWindow : InfoWindow
    , hubData : HubData
    , levelModel : Level.Model
    , window : Window.Size
    , mouse : Mouse.Position
    , externalAnimations : String
    }


type Scene
    = Level
    | Hub
    | Title


type InfoWindow
    = Visible LevelProgress
    | Leaving LevelProgress
    | Hidden


type TransitionBackground
    = Orange
    | Blue


type alias LevelProgress =
    ( WorldNumber, LevelNumber )


type alias WorldNumber =
    Int


type alias LevelNumber =
    Int


type alias HubData =
    Dict Int WorldData


type alias WorldData =
    { levels : WorldLevels
    , seedType : SeedType
    , background : String
    , textColor : String
    , textCompleteColor : String
    , textBackgroundColor : String
    }


type alias WorldLevels =
    Dict Int LevelData


type alias LevelData =
    { tileProbabilities : List TileProbability
    , walls : List Coord
    , goal : Int
    }


type Msg
    = SetScene Scene
    | BeginSceneTransition
    | EndSceneTransition
    | RandomBackground TransitionBackground
    | ReceieveExternalAnimations String
    | StartLevel LevelProgress
    | SetCurrentLevel (Maybe LevelProgress)
    | LoadLevelData ( WorldData, LevelData )
    | GoToHub
    | ShowInfo LevelProgress
    | HideInfo
    | SetInfoState InfoWindow
    | IncrementProgress
    | ScrollToHubLevel Int
    | ReceiveHubLevelOffset Float
    | DomNoOp (Result Dom.Error ())
    | LevelMsg Level.Msg
    | WindowSize Window.Size
    | MousePosition Mouse.Position


type alias Style =
    ( String, String )
