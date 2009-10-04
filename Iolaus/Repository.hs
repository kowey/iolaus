--  Copyright (C) 2009 David Roundy
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2, or (at your option)
--  any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; see the file COPYING.  If not, write to
--  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
--  Boston, MA 02110-1301, USA.
{-# LANGUAGE CPP #-}
#include "gadts.h"

module Iolaus.Repository ( get_unrecorded_changes,
                           get_unrecorded, Unrecorded(..),
                           slurp_recorded, slurp_working ) where

import Iolaus.FileName ( fp2fn )
import Iolaus.Diff ( diff )
import Iolaus.Patch ( Prim )
import Iolaus.Ordered ( FL, unsafeCoerceS )
import Iolaus.SlurpDirectory ( Slurpy, empty_slurpy )
import Iolaus.Sealed ( Sealed(..), mapSealM )

import Git.Plumbing ( heads, writetree,
                      updateindex, catCommitTree )
import Git.Helpers ( touchedFiles, slurpTree )

slurp_recorded :: IO (Slurpy C(RecordedState))
slurp_recorded =
    do hs <- heads
       case hs of
         [] -> return empty_slurpy -- no history!
         [Sealed h] -> do s <- catCommitTree h >>= slurpTree (fp2fn ".")
                          return (unsafeCoerceS s)
         _ -> fail "can't yet handle multiple-head case"

slurp_working :: IO (Sealed Slurpy)
slurp_working =
    do touchedFiles >>= updateindex
       writetree >>= mapSealM (slurpTree (fp2fn "."))

data RecordedState = RecordedState

data Unrecorded =
    FORALL(x) Unrecorded (FL Prim C(RecordedState x)) (Slurpy C(x))

get_unrecorded :: IO Unrecorded
get_unrecorded =
    do Sealed new <- slurp_working
       old <- slurp_recorded
       return $ Unrecorded (diff [] old new) new

get_unrecorded_changes :: IO (Sealed (FL Prim C(RecordedState)))
get_unrecorded_changes =
    do Sealed new <- slurp_working
       old <- slurp_recorded
       return $ Sealed $ diff [] old new
