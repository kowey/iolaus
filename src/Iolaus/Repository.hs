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

module Iolaus.Repository
    ( add_heads, decapitate, push_heads, decapitate_remote,
      get_unrecorded_changes, get_recorded_and_unrecorded,
      get_unrecorded, Unrecorded(..), slurp_recorded, slurp_working,
      checkout_recorded ) where

import Control.Monad ( zipWithM_ )
import System.IO.Unsafe ( unsafeInterleaveIO )

import Iolaus.Diff ( diff )
import Iolaus.Patch ( Prim )
import Iolaus.Flags ( Flag )
import Iolaus.Ordered ( FL, unsafeCoerceS )
import Iolaus.SlurpDirectory ( Slurpy )
import Iolaus.Sealed ( Sealed(..), mapSealM, unseal )

import Git.Plumbing ( Hash, Commit, emptyCommit, heads, remoteHeads,
                      tagNames, maybeParseRev, readTree, checkoutCopy,
                      writetree, updateindex, updateref, sendPack )
import Git.Helpers ( touchedFiles, slurpTree, mergeCommits )
import Git.Dag ( parents, cauterizeHeads )

checkout_recorded :: IO ()
checkout_recorded = do Sealed r <- heads >>= mergeCommits
                       readTree r "index"
                       checkoutCopy "./"

slurp_recorded :: IO (Slurpy C(RecordedState))
slurp_recorded = do Sealed r <- heads >>= mergeCommits
                    slurpTree $ unsafeCoerceS r

slurp_working :: IO (Sealed Slurpy)
slurp_working =
    do touchedFiles >>= updateindex
       writetree >>= mapSealM slurpTree

data RecordedState = RecordedState

data Unrecorded =
    FORALL(x) Unrecorded (FL Prim C(RecordedState x)) (Slurpy C(x))

get_unrecorded :: IO Unrecorded
get_unrecorded =
    do Sealed new <- slurp_working
       old <- slurp_recorded
       return $ Unrecorded (diff [] old new) new

get_recorded_and_unrecorded :: IO (Slurpy C(RecordedState), Unrecorded)
get_recorded_and_unrecorded =
    do Sealed new <- slurp_working
       old <- slurp_recorded
       return (old, Unrecorded (diff [] old new) new)

get_unrecorded_changes :: IO (Sealed (FL Prim C(RecordedState)))
get_unrecorded_changes =
    do Sealed new <- slurp_working
       old <- slurp_recorded
       return $ Sealed $ diff [] old new

mapMlazy :: (a -> IO b) -> [a] -> IO [b]
f `mapMlazy` (x:xs) = do fx <- unsafeInterleaveIO (f x)
                         fxs <- unsafeInterleaveIO (f `mapMlazy` xs)
                         return (fx:fxs)
_ `mapMlazy` [] = return []

add_heads :: [Flag] -> [Sealed (Hash Commit)] -> IO ()
add_heads _ h =
    do hs <- heads
       oldmasters <- mapMlazy maybeParseRev masters
       let hs' = cauterizeHeads (h++hs)
       zipWithM_ (\(mm,oldh) hh -> updateref mm hh oldh)
                 (zip masters oldmasters)
                 (hs'++take (length hs-length hs')
                            (repeat $ Sealed emptyCommit))

decapitate :: [Flag] -> [Sealed (Hash Commit)] -> IO ()
decapitate _ xs =
    do hs <- heads
       oldmasters <- mapMlazy maybeParseRev masters
       let pars = concatMap (unseal parents) xs
           hs' = cauterizeHeads (filter (`notElem` xs) (hs++pars))
       zipWithM_ (\(mm, oldh) hh -> updateref mm hh oldh)
                 (zip masters oldmasters)
                 (hs'++take (length hs-length hs')
                            (repeat $ Sealed emptyCommit))

decapitate_remote :: String -> [Sealed (Hash Commit)] -> IO ()
decapitate_remote repo xs =
    do hs <- remoteHeads repo
       let pars = concatMap (unseal parents) xs
           hs' = cauterizeHeads (filter (`notElem` xs) (hs++pars))
           paddedhs' = hs'++
                       take (length hs-length hs') (repeat (Sealed emptyCommit))
       -- FIXME: sendPack should specify both old and new, so that
       -- locking is done properly...
       sendPack repo (zip paddedhs' masters) []

push_heads :: String -> [Sealed (Hash Commit)] -> IO ()
push_heads repo cs =
    do hs <- remoteHeads repo
       let newhs = cauterizeHeads (hs++cs)
           empties = take (length hs - length newhs) $
                     repeat $ Sealed emptyCommit
       tns <- tagNames
       sendPack repo (zip (newhs++empties) masters) (map snd tns)

masters :: [String]
masters = "refs/heads/master" :
          map (\n -> "refs/heads/master"++show n) [1 :: Int ..]
