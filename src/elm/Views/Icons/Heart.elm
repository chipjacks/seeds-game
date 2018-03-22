module Views.Icons.Heart exposing (..)

import Config.Color exposing (..)
import Helpers.Style exposing (ms, svgStyles)
import Svg exposing (Svg)
import Svg.Attributes exposing (..)


heart : Svg msg
heart =
    Svg.svg
        [ viewBox "0 0 57 50"
        , height "100%"
        , width "100%"
        ]
        [ Svg.g []
            [ Svg.path
                [ d "M28.4 6s.2-.4 1-1.2c6.2-6 16.2-6 22.3 0 6.1 6 6.1 16 0 22l-22.4 22c-.2.3-.6.4-1 .4V6z"
                , fill pinkRed
                ]
                []
            , Svg.path
                [ d "M28.4 6s-.2-.4-1-1.2c-6.2-6-16.2-6-22.3 0-6.1 6-6.1 16 0 22l22.3 22c.3.3.6.4 1 .4V6z"
                , fill crimson
                ]
                []
            ]
        ]


type HeartState
    = Breaking
    | Broken


breakingHeart : Svg msg
breakingHeart =
    heartBreak Breaking


brokenHeart : Svg msg
brokenHeart =
    heartBreak Broken


heartBreak : HeartState -> Svg msg
heartBreak heartState =
    let
        ( l, r ) =
            case heartState of
                Breaking ->
                    ( [ "transform-origin: bottom"
                      , breakAnimation "heart-break-left" 200 100
                      ]
                    , [ "transform-origin: bottom"
                      , breakAnimation "heart-break-right" 200 100
                      ]
                    )

                Broken ->
                    ( [ "transform-origin: bottom"
                      , breakAnimation "heart-break-left" 0 0
                      ]
                    , [ "transform-origin: bottom"
                      , breakAnimation "heart-break-right" 0 0
                      ]
                    )
    in
        Svg.svg
            [ viewBox "-5 0 65 49"
            , height "100%"
            , width "100%"
            ]
            [ Svg.g [ fill "none" ]
                [ Svg.path
                    [ d "M28 4.5a15.5 15.5 0 0 1 22 21.9l-22 22c-.3.2-.7.4-1 .4v-8.9l-5.7-9.8 5.7-8.7-5.7-8.3L27 5.7l1-1.2z"
                    , fill lightGray
                    , svgStyles r
                    ]
                    []
                , Svg.path
                    [ d "M26.4 4.5A15.5 15.5 0 0 0 4.5 26.4l22 22c.3.2.6.4 1 .4v-8.9l-5.6-9.8 5.5-8.7-5.5-8.3 5.5-7.4-1-1.2z"
                    , fill silver
                    , svgStyles l
                    ]
                    []
                ]
            ]


breakAnimation : String -> Float -> Float -> String
breakAnimation name delay duration =
    String.join " "
        [ "animation:"
        , ms delay
        , name
        , ms duration
        , "cubic-bezier(0, -2.85, 0.67, 2.83)"
        , "forwards"
        ]