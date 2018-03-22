module Scenes.Level.State exposing (..)

import Config.Text exposing (failureMessage, getSuccessMessage, randomSuccessMessageIndex)
import Data.Board.Block exposing (..)
import Data.Board.Falling exposing (..)
import Data.Board.Generate exposing (..)
import Data.Board.Map exposing (..)
import Data.Board.Move.Check exposing (addToMove, startMove)
import Data.Board.Move.Square exposing (setAllTilesOfTypeToDragging, triggerMoveIfSquare)
import Data.Board.Moves exposing (currentMoveTileType)
import Data.Board.Shift exposing (shiftBoard)
import Data.Board.Types exposing (..)
import Data.Board.Wall exposing (addWalls)
import Data.InfoWindow as InfoWindow exposing (InfoWindow(..))
import Data.Board.Score exposing (addScoreFromMoves, initialScores, levelComplete)
import Data.Level.Types exposing (LevelData)
import Dict
import Helpers.Effect exposing (sequenceMs, trigger)
import Helpers.OutMsg exposing (noOutMsg, withOutMsg)
import Scenes.Level.Types exposing (..)


-- Init


init : LevelData tutorialConfig -> Model -> ( Model, Cmd Msg )
init levelData model =
    addLevelData levelData model |> generateTiles levelData


generateTiles : LevelData tutorialConfig -> Model -> ( Model, Cmd Msg )
generateTiles levelData model =
    model ! [ handleGenerateTiles levelData model ]


addLevelData : LevelData tutorialConfig -> Model -> Model
addLevelData { tileSettings, walls, boardDimensions, moves } model =
    { model
        | scores = initialScores tileSettings
        , board = addWalls walls model.board
        , boardDimensions = boardDimensions
        , tileSettings = tileSettings
        , levelStatus = InProgress
        , remainingMoves = moves
    }


initialState : Model
initialState =
    { board = Dict.empty
    , scores = Dict.empty
    , isDragging = False
    , remainingMoves = 10
    , moveShape = Nothing
    , tileSettings = []
    , boardDimensions = { y = 8, x = 8 }
    , levelStatus = InProgress
    , successMessageIndex = 0
    , levelInfoWindow = Hidden
    , mouse = { y = 0, x = 0 }
    , window = { height = 0, width = 0 }
    }


generateSuccessMessageIndex : Cmd Msg
generateSuccessMessageIndex =
    randomSuccessMessageIndex RandomSuccessMessageIndex



-- Update


update : Msg -> Model -> ( Model, Cmd Msg, Maybe OutMsg )
update msg model =
    case msg of
        InitTiles walls tiles ->
            noOutMsg
                (model
                    |> handleMakeBoard tiles
                    |> mapBoard (addWalls walls)
                )
                []

        StopMove ->
            case currentMoveTileType model.board of
                Just SeedPod ->
                    noOutMsg model [ growSeedPodsSequence model.moveShape ]

                _ ->
                    noOutMsg model [ removeTilesSequence model.moveShape ]

        SetLeavingTiles ->
            noOutMsg
                (model
                    |> handleAddScore
                    |> mapBlocks setToLeaving
                )
                []

        SetFallingTiles ->
            noOutMsg (mapBoard setFallingTiles model) []

        ShiftBoard ->
            noOutMsg
                (model
                    |> mapBoard shiftBoard
                    |> mapBlocks setFallingToStatic
                    |> mapBlocks setLeavingToEmpty
                )
                []

        SetGrowingSeedPods ->
            noOutMsg (mapBlocks setDraggingToGrowing model) []

        GrowPodsToSeeds ->
            noOutMsg model [ generateRandomSeedType InsertGrowingSeeds model.tileSettings ]

        InsertGrowingSeeds seedType ->
            noOutMsg (handleInsertNewSeeds seedType model) []

        ResetGrowingSeeds ->
            noOutMsg (mapBlocks setGrowingToStatic model) []

        GenerateEnteringTiles ->
            noOutMsg model [ generateEnteringTiles InsertEnteringTiles model.tileSettings model.board ]

        InsertEnteringTiles tiles ->
            noOutMsg (handleInsertEnteringTiles tiles model) []

        ResetEntering ->
            noOutMsg (mapBlocks setEnteringToStatic model) []

        ResetMove ->
            noOutMsg
                (model
                    |> handleResetMove
                    |> handleDecrementRemainingMoves
                )
                []

        StartMove move ->
            noOutMsg (handleStartMove move model) []

        CheckMove move ->
            handleCheckMove move model

        SquareMove ->
            noOutMsg (handleSquareMove model) []

        CheckLevelComplete ->
            handleCheckLevelComplete model

        RandomSuccessMessageIndex i ->
            noOutMsg { model | successMessageIndex = i } []

        ShowInfo info ->
            noOutMsg { model | levelInfoWindow = Visible info } []

        RemoveInfo ->
            noOutMsg { model | levelInfoWindow = InfoWindow.toHiding model.levelInfoWindow } []

        InfoHidden ->
            noOutMsg { model | levelInfoWindow = Hidden } []

        LevelWon ->
            -- outMsg signals to parent component that level has been won
            withOutMsg { model | successMessageIndex = model.successMessageIndex + 1 } [] ExitLevelWithWin

        LevelLost ->
            -- outMsg signals to parent component that level has been lost
            withOutMsg model [] ExitLevelWithLose



-- SEQUENCES


growSeedPodsSequence : Maybe MoveShape -> Cmd Msg
growSeedPodsSequence moveShape =
    sequenceMs
        [ ( initialDelay moveShape, SetGrowingSeedPods )
        , ( 0, ResetMove )
        , ( 800, GrowPodsToSeeds )
        , ( 600, ResetGrowingSeeds )
        ]


removeTilesSequence : Maybe MoveShape -> Cmd Msg
removeTilesSequence moveShape =
    sequenceMs
        [ ( initialDelay moveShape, SetLeavingTiles )
        , ( 0, ResetMove )
        , ( fallDelay moveShape, SetFallingTiles )
        , ( 500, ShiftBoard )
        , ( 0, CheckLevelComplete )
        , ( 0, GenerateEnteringTiles )
        , ( 500, ResetEntering )
        ]


winSequence : Model -> Cmd Msg
winSequence model =
    sequenceMs
        [ ( 500, ShowInfo <| getSuccessMessage model.successMessageIndex )
        , ( 2000, RemoveInfo )
        , ( 1000, InfoHidden )
        , ( 0, LevelWon )
        ]


loseSequence : Cmd Msg
loseSequence =
    sequenceMs
        [ ( 500, ShowInfo failureMessage )
        , ( 2000, RemoveInfo )
        , ( 1000, InfoHidden )
        , ( 0, LevelLost )
        ]


initialDelay : Maybe MoveShape -> Float
initialDelay moveShape =
    if moveShape == Just Square then
        200
    else
        0


fallDelay : Maybe MoveShape -> Float
fallDelay moveShape =
    if moveShape == Just Square then
        500
    else
        350



-- Update Helpers


handleGenerateTiles : LevelData tutorialConfig -> Model -> Cmd Msg
handleGenerateTiles levelData { boardDimensions } =
    generateInitialTiles (InitTiles levelData.walls) levelData.tileSettings boardDimensions


handleMakeBoard : List TileType -> BoardConfig model -> BoardConfig model
handleMakeBoard tileList ({ boardDimensions } as model) =
    { model | board = makeBoard boardDimensions tileList }


handleInsertEnteringTiles : List TileType -> HasBoard model -> HasBoard model
handleInsertEnteringTiles tileList =
    mapBoard <| insertNewEnteringTiles tileList


handleInsertNewSeeds : SeedType -> HasBoard model -> HasBoard model
handleInsertNewSeeds seedType =
    mapBoard <| insertNewSeeds seedType


handleAddScore : Model -> Model
handleAddScore model =
    { model | scores = addScoreFromMoves model.board model.scores }


handleResetMove : Model -> Model
handleResetMove model =
    { model
        | isDragging = False
        , moveShape = Nothing
    }


handleDecrementRemainingMoves : Model -> Model
handleDecrementRemainingMoves model =
    if model.remainingMoves < 1 then
        { model | remainingMoves = 0 }
    else
        { model | remainingMoves = model.remainingMoves - 1 }


handleStartMove : Move -> Model -> Model
handleStartMove move model =
    { model
        | isDragging = True
        , board = startMove move model.board
        , moveShape = Just Line
    }


handleCheckMove : Move -> Model -> ( Model, Cmd Msg, Maybe OutMsg )
handleCheckMove move model =
    let
        newModel =
            model |> handleCheckMove_ move
    in
        noOutMsg newModel [ triggerMoveIfSquare SquareMove newModel.board ]


handleCheckMove_ : Move -> Model -> Model
handleCheckMove_ move model =
    if model.isDragging then
        { model | board = addToMove move model.board }
    else
        model


handleSquareMove : Model -> Model
handleSquareMove model =
    { model
        | moveShape = Just Square
        , board = setAllTilesOfTypeToDragging model.board
    }


handleCheckLevelComplete : Model -> ( Model, Cmd Msg, Maybe OutMsg )
handleCheckLevelComplete model =
    if hasLost model then
        noOutMsg { model | levelStatus = Lose } [ loseSequence ]
    else if hasWon model then
        noOutMsg { model | levelStatus = Win } [ winSequence model ]
    else
        noOutMsg model []


hasLost : Model -> Bool
hasLost { remainingMoves, levelStatus } =
    remainingMoves < 1 && levelStatus == InProgress


hasWon : Model -> Bool
hasWon { scores, levelStatus } =
    levelComplete scores && levelStatus == InProgress