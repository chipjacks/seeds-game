module Update exposing (..)

import Data.Hub.Config exposing (hubData)
import Data.Hub.LoadLevel exposing (handleLoadLevel)
import Data.Hub.Progress exposing (getLevelNumber, handleIncrementProgress)
import Data.Ports exposing (receiveLevelOffset, scrollToLevel)
import Delay
import Helpers.Dom exposing (scrollHubToLevel)
import Helpers.Window exposing (getWindowSize, trackMouseDowns, trackMousePosition, trackWindowSize)
import Model exposing (..)
import Scenes.Level.Update as Level
import Time exposing (millisecond)


init : ( Model, Cmd Msg )
init =
    initialModel ! [ getWindowSize ]


initialModel : Model
initialModel =
    { scene = Title
    , sceneTransition = False
    , progress = ( 3, 2 )
    , currentLevel = Nothing
    , hubData = hubData
    , levelModel = Level.initialState
    , window = { height = 0, width = 0 }
    , mouse = { x = 0, y = 0 }
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetScene scene ->
            { model | scene = scene } ! []

        Transition bool ->
            { model | sceneTransition = bool } ! []

        SetCurrentLevel progress ->
            { model | currentLevel = progress } ! []

        StartLevel progress levelData ->
            model
                ! [ Delay.sequence <|
                        Delay.withUnit millisecond
                            [ ( 0, SetCurrentLevel <| Just progress )
                            , ( 10, Transition True )
                            , ( 500, SetScene Level )
                            , ( 0, LoadLevelData levelData )
                            , ( 2500, Transition False )
                            ]
                  ]

        GoToHub ->
            model
                ! [ Delay.sequence <|
                        Delay.withUnit millisecond
                            [ ( 0, Transition True )
                            , ( 500, SetScene Hub )
                            , ( 100, ScrollToLevel <| getLevelNumber model.progress model.hubData )
                            , ( 2400, Transition False )
                            ]
                  ]

        LoadLevelData levelData ->
            handleLoadLevel levelData model

        IncrementProgress ->
            (model |> handleIncrementProgress) ! []

        ScrollToLevel level ->
            model ! [ scrollToLevel level ]

        ReceiveLevelOffset offset ->
            model ! [ scrollHubToLevel offset model ]

        DomNoOp _ ->
            model ! []

        LevelMsg levelMsg ->
            let
                ( levelModel, levelCmd ) =
                    Level.update levelMsg model.levelModel
            in
                { model | levelModel = levelModel } ! [ levelCmd |> Cmd.map LevelMsg ]

        WindowSize size ->
            { model | window = size } ! []

        MousePosition position ->
            { model | mouse = position } ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ trackWindowSize
        , trackMousePosition model
        , trackMouseDowns
        , receiveLevelOffset ReceiveLevelOffset
        ]
