module Update exposing (..)

import Data.Hub.Config exposing (hubData)
import Data.Hub.LoadLevel exposing (handleLoadLevel)
import Data.Hub.Progress exposing (getLevelConfig, getLevelNumber, getSelectedProgress, handleIncrementProgress)
import Helpers.Delay exposing (sequenceMs)
import Helpers.Dom exposing (scrollHubToLevel)
import Helpers.Window exposing (getWindowSize, trackMouseDowns, trackMousePosition, trackWindowSize)
import Model exposing (..)
import Scenes.Level.Update as Level


init : ( Model, Cmd Msg )
init =
    initialModel ! [ getWindowSize ]


initialModel : Model
initialModel =
    { scene = Title
    , sceneTransition = False
    , progress = ( 3, 4 )
    , currentLevel = Nothing
    , infoWindow = Hidden
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

        StartLevel progress ->
            let
                levelConfig =
                    getLevelConfig progress model
            in
                model
                    ! [ sequenceMs
                            [ ( 600, SetCurrentLevel <| Just progress )
                            , ( 10, Transition True )
                            , ( 500, SetScene Level )
                            , ( 0, LoadLevelData levelConfig )
                            , ( 2500, Transition False )
                            ]
                      ]

        GoToHub ->
            model
                ! [ sequenceMs
                        [ ( 0, Transition True )
                        , ( 500, SetScene Hub )
                        , ( 100, ScrollToHubLevel <| getLevelNumber model.progress model.hubData )
                        , ( 2400, Transition False )
                        ]
                  ]

        SetInfoState infoWindow ->
            { model | infoWindow = infoWindow } ! []

        ShowInfo levelProgress ->
            { model | infoWindow = Visible levelProgress } ! []

        HideInfo ->
            let
                selectedLevel =
                    getSelectedProgress model |> Maybe.withDefault ( 1, 1 )
            in
                model
                    ! [ sequenceMs
                            [ ( 0, SetInfoState <| Leaving selectedLevel )
                            , ( 1000, SetInfoState Hidden )
                            ]
                      ]

        LoadLevelData levelData ->
            handleLoadLevel levelData model

        IncrementProgress ->
            (model |> handleIncrementProgress) ! []

        ScrollToHubLevel level ->
            model ! [ scrollToHubLevel level ]

        ReceiveHubLevelOffset offset ->
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
        , receiveHubLevelOffset ReceiveHubLevelOffset
        ]
