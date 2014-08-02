{-
Copyright (C) 2012 John MacFarlane <jgm@berkeley.edu>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}

{- | Functions for writing a parsed formula as OMML.
-}

module Text.TeXMath.Writers.OMML (writeOMML)
where

import Text.XML.Light
import Text.TeXMath.Types
import Data.Generics (everywhere, mkT)

-- | Transforms an expression tree to an OMML XML Tree
writeOMML :: DisplayType -> [Exp] -> Element
writeOMML dt = container . concatMap (showExp (setProps TextNormal))
            . everywhere (mkT $ handleDownup dt)
    where container = case dt of
                  DisplayBlock  -> \x -> mnode "oMathPara"
                                    [ mnode "oMathParaPr"
                                      $ mnodeA "jc" "center" ()
                                    , mnode "oMath" x ]
                  DisplayInline -> mnode "oMath"

mnode :: Node t => String -> t -> Element
mnode s = node (QName s Nothing (Just "m"))

mnodeA :: Node t => String -> String -> t -> Element
mnodeA s v = add_attr (Attr (QName "val" Nothing (Just "m")) v) . mnode s

str :: [Element] -> String -> Element
str props s = mnode "r" [ mnode "rPr" props
                        , mnode "t" s ]

showBinary :: [Element] -> String -> Exp -> Exp -> Element
showBinary props c x y =
  case c of
       "\\frac" -> mnode "f" [ mnode "fPr" $
                                mnodeA "type" "bar" ()
                             , mnode "num" x'
                             , mnode "den" y']
       "\\dfrac" -> showBinary props "\\frac" x y
       "\\tfrac" -> mnode "f" [ mnode "fPr" $
                                 mnodeA "type" "lin" ()
                              , mnode "num" x'
                              , mnode "den" y']
       "\\sqrt"  -> mnode "rad" [ mnode "radPr" $
                                   mnodeA "degHide" "on" ()
                                , mnode "deg" y'
                                , mnode "e" x']
       "\\stackrel" -> mnode "limUpp" [ mnode "e" y'
                                       , mnode "lim" x']
       "\\overset" -> mnode "limUpp" [ mnode "e" y'
                                     , mnode "lim" x' ]
       "\\underset" -> mnode "limLow" [ mnode "e" y'
                                      , mnode "lim" x' ]
       "\\binom"    -> mnode "d" [ mnode "dPr" $
                                     mnodeA "sepChr" "," ()
                                 , mnode "e" $
                                     mnode "f" [ mnode "fPr" $
                                                   mnodeA "type"
                                                     "noBar" ()
                                               , mnode "num" x'
                                               , mnode "den" y' ]]
       "\\genfrac{}{}{0.0mm}{}" -> mnode "f" [ mnode "fPr" $
                                              mnodeA "type" "noBar" ()
                                             , mnode "num" x'
                                             , mnode "den" y'
                                             ]
       _ -> error $ "Unknown binary operator " ++ c
    where x' = showExp props x
          y' = showExp props y

makeArray :: [Element] -> [Alignment] -> [ArrayLine] -> Element
makeArray props as rs = mnode "m" $ mProps : map toMr rs
  where mProps = mnode "mPr"
                  [ mnodeA "baseJc" "center" ()
                  , mnodeA "plcHide" "on" ()
                  , mnode "mcs" $ map toMc as' ]
        as'    = take (length rs) $ as ++ cycle [AlignDefault]
        toMr r = mnode "mr" $ map (mnode "e" . concatMap (showExp props)) r
        toMc a = mnode "mc" $ mnode "mcPr"
                            $ mnodeA "mcJc" (toAlign a) ()
        toAlign AlignLeft    = "left"
        toAlign AlignRight   = "right"
        toAlign AlignCenter  = "center"
        toAlign AlignDefault = "left"

makeText :: TextType -> String -> Element
makeText a s = str (setProps a) s

setProps :: TextType -> [Element]
setProps tt =
  case tt of
       TextNormal       -> [sty "p"]
       TextBold         -> [sty "b"]
       TextItalic       -> [sty "i"]
       TextMonospace    -> [sty "p", scr "monospace"]
       TextSansSerif    -> [sty "p", scr "sans-serif"]
       TextDoubleStruck -> [sty "p", scr "double-struck"]
       TextScript       -> [sty "p", scr "script"]
       TextFraktur      -> [sty "p", scr "fraktur"]
       TextBoldItalic    -> [sty "i"]
       TextSansSerifBold -> [sty "b", scr "sans-serif"]
       TextBoldScript    -> [sty "b", scr "script"]
       TextBoldFraktur   -> [sty "b", scr "fraktur"]
       TextSansSerifItalic -> [sty "i", scr "sans-serif"]
       TextSansSerifBoldItalic -> [sty "bi", scr "sans-serif"]
   where sty x = mnodeA "sty" x ()
         scr x = mnodeA "scr" x ()

handleDownup :: DisplayType -> [Exp] -> [Exp]
handleDownup dt (exp' : xs) =
  case exp' of
       EOver convertible x y
         | isNary x  ->
             EGrouped [EUnderover convertible x y emptyGroup, next] : rest
         | convertible && dt == DisplayInline -> ESuper x y : xs
       EUnder convertible x y
         | isNary x  ->
             EGrouped [EUnderover convertible x emptyGroup y, next] : rest
         | convertible && dt == DisplayInline -> ESub x y : xs
       EUnderover convertible x y z
         | isNary x  ->
             EGrouped [EUnderover convertible x y z, next] : rest
         | convertible && dt == DisplayInline -> ESubsup x y z : xs
       ESub x y
         | isNary x  -> EGrouped [ESubsup x y emptyGroup, next] : rest
       ESuper x y
         | isNary x  -> EGrouped [ESubsup x emptyGroup y, next] : rest
       ESubsup x y z
         | isNary x  -> EGrouped [ESubsup x y z, next] : rest
       _             -> exp' : next : rest
    where (next, rest) = case xs of
                              (t:ts) -> (t,ts)
                              []     -> (emptyGroup, [])
          emptyGroup = EGrouped []
handleDownup _ []            = []

showExp :: [Element] -> Exp -> [Element]
showExp props e =
 case e of
   ENumber x        -> [str props x]
   EGrouped [EUnderover _ (ESymbol Op s) y z, w] ->
     [makeNary props "undOvr" s y z w]
   EGrouped [ESubsup (ESymbol Op s) y z, w] ->
     [makeNary props "subSup" s y z w]
   EGrouped xs      -> concatMap (showExp props) xs
   EDelimited start end xs ->
                       [mnode "d" [ mnode "dPr"
                                    [ mnodeA "begChr" start ()
                                    , mnodeA "endChr" end ()
                                    , mnode "grow" () ]
                                  , mnode "e" $ concatMap 
                                    (either ((:[]) . str props) (showExp props)) xs
                                  ] ]

   EIdentifier x    -> [str props x]
   EMathOperator x  -> [makeText TextNormal x]  -- TODO revisit, use props?
   ESymbol _ x      -> [str props x]
   ESpace 0.167     -> [str props "\x2009"]
   ESpace 0.222     -> [str props "\x2005"]
   ESpace 0.278     -> [str props "\x2004"]
   ESpace 0.333     -> [str props "\x2004"]
   ESpace 1         -> [str props "\x2001"]
   ESpace 2         -> [str props "\x2001\x2001"]
   ESpace _         -> [] -- this is how the xslt sheet handles all spaces
   EBinary c x y    -> [showBinary props c x y]
   EUnder _ x (ESymbol Accent [c]) | isBarChar c ->
                       [mnode "bar" [ mnode "barPr" $
                                        mnodeA "pos" "bot" ()
                                    , mnode "e" $ showExp props x ]]
   EOver _ x (ESymbol Accent [c]) | isBarChar c ->
                       [mnode "bar" [ mnode "barPr" $
                                        mnodeA "pos" "top" ()
                                    , mnode "e" $ showExp props x ]]
   EOver _ x (ESymbol Accent y) ->
                       [mnode "acc" [ mnode "accPr" $
                                        mnodeA "chr" y ()
                                    , mnode "e" $ showExp props x ]]
   ESub x y         -> [mnode "sSub" [ mnode "e" $ showExp props x
                                     , mnode "sub" $ showExp props y]]
   ESuper x y       -> [mnode "sSup" [ mnode "e" $ showExp props x
                                     , mnode "sup" $ showExp props y]]
   ESubsup x y z    -> [mnode "sSubSup" [ mnode "e" $ showExp props x
                                        , mnode "sub" $ showExp props y
                                        , mnode "sup" $ showExp props z]]
   EUnder _ x y  -> [mnode "limLow" [ mnode "e" $ showExp props x
                                       , mnode "lim" $ showExp props y]]
   EOver _ x y   -> [mnode "limUpp" [ mnode "e" $ showExp props x
                                       , mnode "lim" $ showExp props y]]
   EUnderover c x y z -> showExp props (EUnder c x (EOver c y z))
   EUnary "\\sqrt" x  -> [mnode "rad" [ mnode "radPr" $ mnodeA "degHide" "on" ()
                                      , mnode "deg" ()
                                      , mnode "e" $ showExp props x]]
   EUnary "\\surd" x  -> showExp props $ EUnary "\\sqrt" x
   EUnary "\\phantom" x -> [mnode "phant" [ mnode "phantPr"
                                            [ mnodeA "show" "0" () ]
                                          , mnode "e" $ showExp props x]]
   EUnary _ x       -> showExp props x -- TODO?
   EScaled _ x      -> showExp props x -- no support for scaler?
   EArray as ls     -> [makeArray props as ls]
   EText a s        -> [makeText a s]
   EStyled a es     -> concatMap (showExp (setProps a)) es

isBarChar :: Char -> Bool
isBarChar c = c == '\x203E' || c == '\x00AF'

isNary :: Exp -> Bool
isNary (ESymbol Op _) = True
isNary _ = False

makeNary :: [Element] -> String -> String -> Exp -> Exp -> Exp -> Element
makeNary props t s y z w =
  mnode "nary" [ mnode "naryPr"
                 [ mnodeA "chr" s ()
                 , mnodeA "limLoc" t ()
                 , mnodeA "supHide"
                    (if y == EGrouped [] then "on" else "off") ()
                 , mnodeA "supHide"
                    (if y == EGrouped [] then "on" else "off") ()
                 ]
               , mnode "e" $ showExp props w
               , mnode "sub" $ showExp props y
               , mnode "sup" $ showExp props z ]

