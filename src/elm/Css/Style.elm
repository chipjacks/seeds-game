module Css.Style exposing
    ( Style
    , background
    , backgroundColor
    , backgroundImage
    , border
    , borderNone
    , borderRadiusBottomLeft
    , borderRadiusTopLeft
    , bottom
    , classes
    , color
    , compose
    , displayStyle
    , empty
    , height
    , left
    , leftAuto
    , leftPill
    , marginAuto
    , marginBottom
    , marginLeft
    , marginRight
    , marginTop
    , maxWidth
    , opacity
    , paddingAll
    , paddingBottom
    , paddingHorizontal
    , paddingLeft
    , paddingRight
    , paddingTop
    , paddingVertical
    , property
    , renderStyles_
    , rightAuto
    , rightPill
    , showIf
    , stroke
    , style
    , styles
    , svgStyle
    , svgStyles
    , top
    , transform
    , transformOrigin
    , width
    , widthHeight
    )

import Css.Color as Color
import Css.Transform as Transform exposing (Transform)
import Css.Unit exposing (..)
import Html exposing (Attribute, Html)
import Html.Attributes
import Svg
import Svg.Attributes


type Style
    = Property String String
    | Raw String


property : String -> String -> Style
property =
    Property


compose : List Style -> Style
compose =
    Raw << renderStyles_



-- Html


styles : List (List Style) -> Html.Attribute msg
styles =
    Html.Attributes.attribute "style" << renderStyles_ << List.concat


style : List Style -> Html.Attribute msg
style =
    Html.Attributes.attribute "style" << renderStyles_



-- Svg


svgStyles : List Style -> Svg.Attribute msg
svgStyles =
    Svg.Attributes.style << renderStyles_


svgStyle : Style -> Svg.Attribute msg
svgStyle =
    Svg.Attributes.style << styleToString_



-- Render Styles to Raw String


renderStyles_ : List Style -> String
renderStyles_ =
    List.filter isNonEmpty
        >> List.map styleToString_
        >> String.join ";"


styleToString_ : Style -> String
styleToString_ s =
    case s of
        Property prop val ->
            prop ++ ":" ++ val

        Raw val ->
            val


isNonEmpty : Style -> Bool
isNonEmpty s =
    case s of
        Property prop val ->
            nonEmpty prop && nonEmpty val

        Raw _ ->
            True


nonEmpty : String -> Bool
nonEmpty =
    String.trim >> String.isEmpty >> not



-- Properties


empty : Style
empty =
    property "" ""


transform : List Transform -> Style
transform transforms =
    property "transform" <| Transform.render transforms


transformOrigin : String -> Style
transformOrigin =
    property "transform-origin"


paddingAll : Float -> Style
paddingAll n =
    property "padding" <| px n


paddingHorizontal : Float -> Style
paddingHorizontal n =
    compose
        [ paddingLeft n
        , paddingRight n
        ]


paddingVertical : Float -> Style
paddingVertical n =
    compose
        [ paddingTop n
        , paddingBottom n
        ]


paddingLeft : Float -> Style
paddingLeft n =
    property "padding-left" <| px n


paddingRight : Float -> Style
paddingRight n =
    property "padding-right" <| px n


paddingTop : Float -> Style
paddingTop n =
    property "padding-top" <| px n


paddingBottom : Float -> Style
paddingBottom n =
    property "padding-bottom" <| px n


marginRight : Float -> Style
marginRight n =
    property "margin-right" <| px n


marginTop : Float -> Style
marginTop n =
    property "margin-top" <| px n


marginLeft : Float -> Style
marginLeft n =
    property "margin-left" <| px n


marginBottom : Float -> Style
marginBottom n =
    property "margin-bottom" <| px n


marginAuto : Style
marginAuto =
    property "margin" "auto"


leftAuto : Style
leftAuto =
    property "margin-left" "auto"


rightAuto : Style
rightAuto =
    property "margin-right" "auto"


top : Float -> Style
top n =
    property "top" <| px n


bottom : Float -> Style
bottom n =
    property "bottom" <| px n


left : Float -> Style
left n =
    property "left" <| px n


color : String -> Style
color c =
    property "color" c


borderNone : Style
borderNone =
    property "border" "none"


border : Float -> Color.Color -> Style
border n c =
    property "border" <| String.join " " [ px n, "solid", c ]


rightPill : Style
rightPill =
    compose
        [ borderRadiusTopRight 9999
        , borderRadiusBottomRight 9999
        ]


leftPill : Style
leftPill =
    compose
        [ borderRadiusTopLeft 9999
        , borderRadiusBottomLeft 9999
        ]


borderRadiusTopRight : Float -> Style
borderRadiusTopRight n =
    property "border-top-right-radius" <| px n


borderRadiusBottomRight : Float -> Style
borderRadiusBottomRight n =
    property "border-bottom-right-radius" <| px n


borderRadiusBottomLeft : Float -> Style
borderRadiusBottomLeft n =
    property "border-bottom-left-radius" <| px n


borderRadiusTopLeft : Float -> Style
borderRadiusTopLeft n =
    property "border-top-left-radius" <| px n


backgroundImage : String -> Style
backgroundImage url =
    property "background-image" <| "url(" ++ url ++ ")"


backgroundColor : String -> Style
backgroundColor =
    property "background-color"


background : String -> Style
background =
    property "background"


widthHeight : Float -> List Style
widthHeight n =
    [ width n
    , height n
    ]


width : Float -> Style
width n =
    property "width" <| px n


maxWidth : Float -> Style
maxWidth n =
    property "max-width" <| px n


height : Float -> Style
height h =
    property "height" <| px h


displayStyle : String -> Style
displayStyle d =
    property "display" <| d


opacity : Float -> Style
opacity o =
    property "opacity" <| String.fromFloat o


stroke : String -> Style
stroke =
    property "stroke"



-- Class Helpers


classes : List String -> Html.Attribute msg
classes =
    Html.Attributes.class << String.join " "


showIf : Bool -> Html.Attribute msg
showIf predicate =
    Html.Attributes.classList
        [ ( "o-0", not predicate )
        , ( "o-100", predicate )
        ]