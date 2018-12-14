module Scenes.Garden exposing
    ( Model
    , Msg
    , getContext
    , init
    , menuOptions
    , update
    , updateContext
    , view
    )

import Browser.Dom as Dom
import Context exposing (Context)
import Css.Animation as Animation
import Css.Color as Color exposing (rgb)
import Css.Style as Style exposing (..)
import Data.Board.Tile exposing (seedName, seedTypeHash)
import Data.Board.Types exposing (SeedType(..))
import Data.Levels as Levels exposing (WorldConfig)
import Data.Progress as Progress exposing (Progress)
import Data.Window exposing (Window)
import Exit exposing (continue, exit)
import Helpers.Delay exposing (after)
import Html exposing (Html, button, div, label, p, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Task exposing (Task)
import Views.Flowers.All exposing (renderFlower)
import Views.Menu as Menu
import Views.Seed.All exposing (renderSeed)
import Views.Seed.Mono exposing (greyedOutSeed)
import Worlds



-- Model


type alias Model =
    { context : Context }


type Msg
    = ScrollToCurrentCompletedWorld
    | DomNoOp (Result Dom.Error ())
    | ExitToHub



-- Context


getContext : Model -> Context
getContext model =
    model.context


updateContext : (Context -> Context) -> Model -> Model
updateContext f model =
    { model | context = f model.context }


menuOptions : List (Menu.Option Msg)
menuOptions =
    [ Menu.option ExitToHub "Levels"
    ]



-- Init


init : Context -> ( Model, Cmd Msg )
init context =
    ( initialState context, after 500 ScrollToCurrentCompletedWorld )


initialState : Context -> Model
initialState context =
    { context = context }



-- Update


update : Msg -> Model -> Exit.Status ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollToCurrentCompletedWorld ->
            continue model [ scrollToCurrentCompletedWorld model.context.progress ]

        DomNoOp _ ->
            continue model []

        ExitToHub ->
            exit model


scrollToCurrentCompletedWorld : Progress -> Cmd Msg
scrollToCurrentCompletedWorld progress =
    progress
        |> (currentCompletedWorldSeedType >> seedTypeHash)
        |> Dom.getElement
        |> Task.andThen scrollWorldToView
        |> Task.attempt DomNoOp


scrollWorldToView : Dom.Element -> Task Dom.Error ()
scrollWorldToView { element, viewport } =
    let
        yOffset =
            element.y - viewport.height / 2 + element.height / 2
    in
    Dom.setViewportOf "flowers" 0 yOffset


currentCompletedWorldSeedType : Progress -> SeedType
currentCompletedWorldSeedType progress =
    Worlds.list
        |> List.filter (\( _, keys ) -> worldComplete progress keys)
        |> List.reverse
        |> List.head
        |> Maybe.map (Tuple.first >> .seedType)
        |> Maybe.withDefault Sunflower


worldComplete : Progress -> List Levels.Key -> Bool
worldComplete progress levelKeys =
    levelKeys
        |> List.reverse
        |> List.head
        |> Maybe.map (\l -> Levels.completed (Progress.reachedLevel progress) l)
        |> Maybe.withDefault False



-- View


view : Model -> Html Msg
view model =
    div [ class "w-100 z-1" ]
        [ initialOverlay model.context.window
        , div
            [ id "flowers"
            , style [ height <| toFloat model.context.window.height ]
            , class "w-100 fixed overflow-y-scroll momentum-scroll z-2"
            ]
            [ div [ style [ marginTop 50, marginBottom 125 ], class "flex flex-column items-center" ] <| allFlowers model.context.progress
            ]
        , backToLevelsButton
        ]


initialOverlay : Window -> Html msg
initialOverlay window =
    div
        [ style
            [ background Color.lightYellow
            , height <| toFloat window.height
            , Animation.animation "fade-out" 1500 [ Animation.linear, Animation.delay 3000 ]
            ]
        , class "w-100 ttu tracked-ultra f3 z-7 fixed flex items-center justify-center touch-disabled"
        ]
        [ p
            [ style
                [ color Color.darkYellow
                , opacity 0
                , marginBottom 80
                , Animation.animation "fade-in" 1000 [ Animation.linear, Animation.delay 500 ]
                ]
            ]
            [ text "Garden" ]
        ]


backToLevelsButton : Html Msg
backToLevelsButton =
    div [ style [ bottom 40 ], class "fixed tc left-0 right-0 z-5 center" ]
        [ button
            [ style
                [ color Color.white
                , backgroundColor <| rgb 251 214 74
                , paddingHorizontal 20
                , paddingVertical 10
                , borderNone
                ]
            , onClick ExitToHub
            , class "pointer br4 f7 outline-0 tracked-mega"
            ]
            [ text "BACK TO LEVELS" ]
        ]


allFlowers : Progress -> List (Html msg)
allFlowers progress =
    Worlds.list
        |> List.reverse
        |> List.map (worldFlowers progress)


worldFlowers : Progress -> ( WorldConfig, List Levels.Key ) -> Html msg
worldFlowers progress ( { seedType }, levelKeys ) =
    if worldComplete progress levelKeys then
        div
            [ id <| seedTypeHash seedType
            , style
                [ marginTop 50
                , marginBottom 50
                ]
            ]
            [ flowers seedType
            , seeds seedType
            , flowerName seedType
            ]

    else
        div
            [ id <| seedTypeHash seedType
            , style [ marginTop 75, marginBottom 75 ]
            ]
            [ unfinishedWorldSeeds
            , p
                [ style [ color Color.lightGray ]
                , class "f6 tc"
                ]
                [ text "..." ]
            ]


unfinishedWorldSeeds : Html msg
unfinishedWorldSeeds =
    div [ class "flex items-end justify-center" ]
        [ sized 20 greyedOutSeed
        , sized 30 greyedOutSeed
        , sized 20 greyedOutSeed
        ]


flowerName : SeedType -> Html msg
flowerName seedType =
    p [ style [ color Color.darkYellow ], class "tc ttu tracked-ultra" ]
        [ text <| seedName seedType ]


seeds : SeedType -> Html msg
seeds seedType =
    div [ style [ marginTop -20, marginBottom 30 ], class "flex items-end justify-center" ]
        [ seed 20 seedType
        , seed 30 seedType
        , seed 20 seedType
        ]


seed : Float -> SeedType -> Html msg
seed size seedType =
    sized size <| renderSeed seedType


flowers : SeedType -> Html msg
flowers seedType =
    let
        spacing =
            flowerSpacing seedType
    in
    div [ class "flex items-end justify-center relative" ]
        [ div [ style [ marginRight spacing.offsetX ] ] [ flower spacing.small seedType ]
        , div [ style [ marginBottom spacing.offsetY ] ] [ flower spacing.large seedType ]
        , div [ style [ marginLeft spacing.offsetX ] ] [ flower spacing.small seedType ]
        ]


flower : Float -> SeedType -> Html msg
flower size seedType =
    sized size <| renderFlower seedType


sized : Float -> Html msg -> Html msg
sized size element =
    div [ style [ width size, height size ] ] [ element ]



-- Spacing


type alias FlowerSpacing =
    { large : Float
    , small : Float
    , offsetX : Float
    , offsetY : Float
    }


flowerSpacing : SeedType -> FlowerSpacing
flowerSpacing seedType =
    case seedType of
        Sunflower ->
            { large = 150
            , small = 80
            , offsetX = -30
            , offsetY = 20
            }

        Chrysanthemum ->
            { large = 120
            , small = 80
            , offsetX = 0
            , offsetY = 30
            }

        Cornflower ->
            { large = 170
            , small = 100
            , offsetX = -45
            , offsetY = 20
            }

        _ ->
            { large = 150
            , small = 80
            , offsetX = 30
            , offsetY = 20
            }
