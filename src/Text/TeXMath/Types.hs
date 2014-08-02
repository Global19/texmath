{-# LANGUAGE DeriveDataTypeable, TypeSynonymInstances #-}
{-
Copyright (C) 2009 John MacFarlane <jgm@berkeley.edu>

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

{- | Types for representing a structured formula.
-}

module Text.TeXMath.Types (Exp(..), TeXSymbolType(..), ArrayLine,
                           TextType(..), Alignment(..), DisplayType(..),
                           Operator(..), FormType(..), Record(..),
                           Property, Position(..), Env, defaultEnv, InEDelimited)
where

import Data.Generics

data TeXSymbolType = Ord | Op | Bin | Rel | Open | Close | Pun | Accent 
                     | Fence | TOver | TUnder | Alpha | BotAccent | Rad
                     deriving (Show, Read, Eq, Data, Typeable)

data Alignment = AlignLeft | AlignCenter | AlignRight | AlignDefault
                 deriving (Show, Read, Eq, Data, Typeable)

type ArrayLine = [[Exp]]

data Exp =
    ENumber String
  | EGrouped [Exp]
  | EDelimited String String [InEDelimited]
  | EIdentifier String
  | EMathOperator String
  | ESymbol TeXSymbolType String
  | ESpace Double -- ^ Width in em
  | EBinary String Exp Exp
  | ESub Exp Exp
  | ESuper Exp Exp
  | ESubsup Exp Exp Exp
  | EOver Bool Exp Exp  -- ^ Boolean is True if convertible
  | EUnder Bool Exp Exp
  | EUnderover Bool Exp Exp Exp
  | EUnary String Exp
  | EScaled String Exp
  | EArray [Alignment] [ArrayLine]
  | EText TextType String
  | EStyled TextType [Exp]
  deriving (Show, Read, Eq, Data, Typeable)

type InEDelimited = Either Middle Exp
type Middle = String

data DisplayType = DisplayBlock
                 | DisplayInline
                 deriving (Show, Eq)

data TextType = TextNormal
              | TextBold
              | TextItalic
              | TextMonospace
              | TextSansSerif
              | TextDoubleStruck
              | TextScript
              | TextFraktur
              | TextBoldItalic
              | TextSansSerifBold
              | TextSansSerifBoldItalic
              | TextBoldScript
              | TextBoldFraktur
              | TextSansSerifItalic
              deriving (Show, Ord, Read, Eq, Data, Typeable)

data FormType = FPrefix | FPostfix | FInfix deriving (Show, Ord, Eq)

type Property = String

-- | A record of the MathML dictionary as defined
-- <http://www.w3.org/TR/MathML3/appendixc.html in the specification>
data Operator = Operator
                  { oper :: String -- ^ Operator
                  , description :: String -- ^ Plain English Description
                  , form :: FormType -- ^ Whether Prefix, Postfix or Infix
                  , priority :: Int -- ^ Default priority for implicit
                                    --   nesting
                  , lspace :: Int -- ^ Default Left Spacing
                  , rspace :: Int -- ^ Default Right Spacing
                  , properties :: [Property] -- ^ List of MathML properties
                  }
                  deriving (Show)

-- | A record of the Unicode to LaTeX lookup table
-- a full descripton can be seen
-- <http://milde.users.sourceforge.net/LUCR/Math/data/unimathsymbols.txt
-- here>
data Record = Record { uchar :: Char -- ^ Unicode Character
                     , commands :: [(String, String)] -- ^ LaTeX commands (package, command)
                     , category :: TeXSymbolType -- ^ TeX math category
                     , comments :: String -- ^ Plain english description
                     } deriving (Show)

data Position = Under | Over

-- | List of available packages
type Env = [String]

-- | Contains @amsmath@ and @amssymbol@
defaultEnv :: [String]
defaultEnv = ["amsmath", "amssymbol"]
