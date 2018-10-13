module Scenes.Level.State exposing (init, update)

import Browser.Events
import Config.Scale as ScaleConfig exposing (baseTileSizeX, baseTileSizeY, tileScaleFactor)
import Config.Text exposing (failureMessage, getSuccessMessage)
import Data.Board.Block exposing (..)
import Data.Board.Falling exposing (..)
import Data.Board.Generate exposing (..)
import Data.Board.Map exposing (..)
import Data.Board.Move.Check exposing (addMoveToBoard, startMove)
import Data.Board.Move.Square exposing (setAllTilesOfTypeToDragging, triggerMoveIfSquare)
import Data.Board.Moves exposing (currentMoveTileType)
import Data.Board.Score exposing (addScoreFromMoves, initialScores, levelComplete)
import Data.Board.Shift exposing (shiftBoard)
import Data.Board.Types exposing (..)
import Data.Board.Wall exposing (addWalls)
import Data.InfoWindow as InfoWindow
import Data.Level.Types exposing (LevelData)
import Data.Pointer exposing (Pointer)
import Data.Window as Window
import Dict
import Exit exposing (continue, exitWith)
import Helpers.Delay exposing (sequence, trigger)
import Scenes.Level.Types exposing (..)
import Shared
import Task
import Views.Level.Styles exposing (boardHeight, boardOffsetLeft, boardOffsetTop)



-- Init


init : LevelData tutorialConfig -> Shared.Data -> ( LevelModel, Cmd LevelMsg )
init levelData shared =
    let
        model =
            addLevelData levelData <| initialState shared
    in
    ( model
    , handleGenerateTiles levelData model
    )


addLevelData : LevelData tutorialConfig -> LevelModel -> LevelModel
addLevelData { tileSettings, walls, boardDimensions, moves } model =
    { model
        | scores = initialScores tileSettings
        , board = addWalls walls model.board
        , boardDimensions = boardDimensions
        , tileSettings = tileSettings
        , levelStatus = InProgress
        , remainingMoves = moves
    }


initialState : Shared.Data -> LevelModel
initialState shared =
    { shared = shared
    , board = Dict.empty
    , scores = Dict.empty
    , isDragging = False
    , remainingMoves = 10
    , moveShape = Nothing
    , tileSettings = []
    , boardDimensions = { y = 8, x = 8 }
    , levelStatus = InProgress
    , infoWindow = InfoWindow.hidden
    , pointer = { y = 0, x = 0 }
    }



-- Update


update : LevelMsg -> LevelModel -> Exit.With LevelStatus ( LevelModel, Cmd LevelMsg )
update msg model =
    case msg of
        InitTiles walls tiles ->
            continue
                (model
                    |> handleMakeBoard tiles
                    |> mapBoard (addWalls walls)
                )
                []

        StopMove ->
            case currentMoveTileType model.board of
                Just SeedPod ->
                    continue model [ growSeedPodsSequence model.moveShape ]

                _ ->
                    continue model [ removeTilesSequence model.moveShape ]

        SetLeavingTiles ->
            continue
                (model
                    |> handleAddScore
                    |> mapBlocks setToLeaving
                )
                []

        SetFallingTiles ->
            continue (mapBoard setFallingTiles model) []

        ShiftBoard ->
            continue
                (model
                    |> mapBoard shiftBoard
                    |> mapBlocks setFallingToStatic
                    |> mapBlocks setLeavingToEmpty
                )
                []

        SetGrowingSeedPods ->
            continue (mapBlocks setDraggingToGrowing model) []

        GrowPodsToSeeds ->
            continue model [ generateRandomSeedType InsertGrowingSeeds model.tileSettings ]

        InsertGrowingSeeds seedType ->
            continue (handleInsertNewSeeds seedType model) []

        ResetGrowingSeeds ->
            continue (mapBlocks setGrowingToStatic model) []

        GenerateEnteringTiles ->
            continue model [ generateEnteringTiles InsertEnteringTiles model.tileSettings model.board ]

        InsertEnteringTiles tiles ->
            continue (handleInsertEnteringTiles tiles model) []

        ResetEntering ->
            continue (mapBlocks setEnteringToStatic model) []

        ResetMove ->
            continue
                (model
                    |> handleResetMove
                    |> handleDecrementRemainingMoves
                )
                []

        StartMove move pointer ->
            continue (handleStartMove move pointer model) []

        CheckMove pointer ->
            checkMoveFromPosition pointer model

        SquareMove ->
            continue (handleSquareMove model) []

        CheckLevelComplete ->
            handleCheckLevelComplete model

        ShowInfo info ->
            continue { model | infoWindow = InfoWindow.show info } []

        RemoveInfo ->
            continue { model | infoWindow = InfoWindow.leave model.infoWindow } []

        InfoHidden ->
            continue { model | infoWindow = InfoWindow.hidden } []

        LevelWon ->
            exitWith Win model []

        LevelLost ->
            exitWith Lose model []



-- SEQUENCES


growSeedPodsSequence : Maybe MoveShape -> Cmd LevelMsg
growSeedPodsSequence moveShape =
    sequence
        [ ( initialDelay moveShape, SetGrowingSeedPods )
        , ( 0, ResetMove )
        , ( 800, GrowPodsToSeeds )
        , ( 0, CheckLevelComplete )
        , ( 600, ResetGrowingSeeds )
        ]


removeTilesSequence : Maybe MoveShape -> Cmd LevelMsg
removeTilesSequence moveShape =
    sequence
        [ ( initialDelay moveShape, SetLeavingTiles )
        , ( 0, ResetMove )
        , ( fallDelay moveShape, SetFallingTiles )
        , ( 500, ShiftBoard )
        , ( 0, CheckLevelComplete )
        , ( 0, GenerateEnteringTiles )
        , ( 500, ResetEntering )
        ]


winSequence : LevelModel -> Cmd LevelMsg
winSequence model =
    sequence
        [ ( 500, ShowInfo <| getSuccessMessage model.shared.successMessageIndex )
        , ( 2000, RemoveInfo )
        , ( 1000, InfoHidden )
        , ( 0, LevelWon )
        ]


loseSequence : Cmd LevelMsg
loseSequence =
    sequence
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


handleGenerateTiles : LevelData tutorialConfig -> LevelModel -> Cmd LevelMsg
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


handleAddScore : LevelModel -> LevelModel
handleAddScore model =
    { model | scores = addScoreFromMoves model.board model.scores }


handleResetMove : LevelModel -> LevelModel
handleResetMove model =
    { model
        | isDragging = False
        , moveShape = Nothing
    }


handleDecrementRemainingMoves : LevelModel -> LevelModel
handleDecrementRemainingMoves model =
    if model.remainingMoves < 1 then
        { model | remainingMoves = 0 }

    else
        { model | remainingMoves = model.remainingMoves - 1 }


handleStartMove : Move -> Pointer -> LevelModel -> LevelModel
handleStartMove move pointer model =
    { model
        | isDragging = True
        , board = startMove move model.board
        , moveShape = Just Line
        , pointer = pointer
    }


checkMoveFromPosition : Pointer -> LevelModel -> Exit.With LevelStatus ( LevelModel, Cmd LevelMsg )
checkMoveFromPosition pointer levelModel =
    let
        modelWithPosition =
            { levelModel | pointer = pointer }
    in
    case moveFromPosition pointer levelModel of
        Just move ->
            checkMoveWithSquareTrigger move modelWithPosition

        Nothing ->
            continue modelWithPosition []


checkMoveWithSquareTrigger : Move -> LevelModel -> Exit.With LevelStatus ( LevelModel, Cmd LevelMsg )
checkMoveWithSquareTrigger move model =
    let
        newModel =
            model |> handleCheckMove move
    in
    continue newModel [ triggerMoveIfSquare SquareMove newModel.board ]


handleCheckMove : Move -> LevelModel -> LevelModel
handleCheckMove move model =
    if model.isDragging then
        { model | board = addMoveToBoard move model.board }

    else
        model


moveFromPosition : Pointer -> LevelModel -> Maybe Move
moveFromPosition pointer levelModel =
    moveFromCoord levelModel.board <| coordsFromPosition pointer levelModel


moveFromCoord : Board -> Coord -> Maybe Move
moveFromCoord board coord =
    board |> Dict.get coord |> Maybe.map (\b -> ( coord, b ))


coordsFromPosition : Pointer -> LevelModel -> Coord
coordsFromPosition pointer model =
    let
        vm =
            ( model.shared.window, model.boardDimensions )

        positionY =
            toFloat <| pointer.y - boardOffsetTop vm

        positionX =
            toFloat <| pointer.x - boardOffsetLeft vm

        scaleFactorY =
            tileScaleFactor model.shared.window * baseTileSizeY

        scaleFactorX =
            tileScaleFactor model.shared.window * baseTileSizeX
    in
    ( floor <| positionY / scaleFactorY
    , floor <| positionX / scaleFactorX
    )


handleSquareMove : LevelModel -> LevelModel
handleSquareMove model =
    { model
        | moveShape = Just Square
        , board = setAllTilesOfTypeToDragging model.board
    }


handleCheckLevelComplete : LevelModel -> Exit.With LevelStatus ( LevelModel, Cmd LevelMsg )
handleCheckLevelComplete model =
    if hasWon model then
        continue { model | levelStatus = Win } [ winSequence model ]

    else if hasLost model then
        continue { model | levelStatus = Lose } [ loseSequence ]

    else
        continue model []


hasLost : LevelModel -> Bool
hasLost { remainingMoves, levelStatus } =
    remainingMoves < 1 && levelStatus == InProgress


hasWon : LevelModel -> Bool
hasWon { scores, levelStatus } =
    levelComplete scores && levelStatus == InProgress
