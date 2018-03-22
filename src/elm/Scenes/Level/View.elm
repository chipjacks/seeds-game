module Scenes.Level.View exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Scenes.Level.Types as Level exposing (LevelStatus(InProgress))
import Views.Backdrop exposing (backdrop)
import Views.Level.InfoWindow exposing (infoWindow)
import Views.Level.Layout exposing (board, handleStop)
import Views.Level.LineDrag exposing (handleLineDrag)
import Views.Level.TopBar exposing (topBar)


levelView : Level.Model -> Html Level.Msg
levelView model =
    div [ handleStop model, class <| disableIfComplete model ]
        [ topBar model
        , infoWindow model
        , board model
        , handleLineDrag model
        , div [ class "w-100 h-100 fixed z-1 top-0" ] [ backdrop ]
        ]


disableIfComplete : Level.Model -> String
disableIfComplete model =
    if not <| model.levelStatus == InProgress then
        "touch-disabled"
    else
        ""