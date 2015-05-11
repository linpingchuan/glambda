{-# LANGUAGE GADTs, DataKinds, RankNTypes, FlexibleContexts #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  Language.Glambda.Globals
-- Copyright   :  (C) 2015 Richard Eisenberg
-- License     :  BSD-style (see LICENSE)
-- Maintainer  :  Richard Eisenberg (eir@cis.upenn.edu)
-- Stability   :  experimental
--
-- Manages the global variables in Glambda
--
----------------------------------------------------------------------------

module Language.Glambda.Globals (
  Globals, emptyGlobals, extend, lookupGlobal ) where

import Language.Glambda.Exp
import Language.Glambda.Type

import Control.Error
import Control.Monad.Error

import Text.PrettyPrint.HughesPJClass

import Data.Map as Map
import Data.Text

-- | An existential wrapper around 'Exp', storing the expression and
-- its type.
data EExp where
  EExp :: STy ty -> Exp '[] ty -> EExp

-- | The global variable environment maps variables to type-checked
-- expressions
newtype Globals = Globals (Map Text EExp)

-- | An empty global variable environment
emptyGlobals :: Globals
emptyGlobals = Globals Map.empty

-- | Extend a 'Globals' with a new binding
extend :: Text -> STy ty -> Exp '[] ty -> Globals -> Globals
extend var sty exp (Globals globals)
  = Globals $ Map.insert var (EExp sty exp) globals

-- | Lookup a global variable. Fails with 'throwError' if the variable
-- is not bound.
lookupGlobal :: MonadError Doc m
             => Globals -> Text
             -> (forall ty. STy ty -> Exp '[] ty -> m r)
             -> m r
lookupGlobal (Globals globals) var k
  = case Map.lookup var globals of
      Just (EExp sty exp) -> k sty exp
      Nothing             -> throwError $
                             text "Global variable not in scope:" <+>
                               quotes (text $ unpack var)