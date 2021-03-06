%  Copyright (C) 2002-2003,2009 David Roundy
%
%  This program is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation; either version 2, or (at your option)
%  any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program; see the file COPYING.  If not, write to
%  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
%  Boston, MA 02110-1301, USA.

\begin{code}
{-# OPTIONS_GHC -fno-warn-orphans #-}
module Iolaus.Patch ( Prim, Named, Patchy, Apply, apply,
                      rmfile, addfile, chmod, rmdir, adddir, move,
                      chunkify, binary, chunk,
                      showContextPatch, infopatch, thing, things, is_addfile,
                      Effect, effect, is_adddir,
                      Invert, invert, identity,
                      Commute, commute, merge, list_touched_files, commuteFL,
                      commuteRL, canonize, apply_to_slurpy, patchcontents,
                      patch2patchinfo, summarize, mergeNamed,
                      -- from Permutations
                      module Iolaus.Patch.Permutations,
                    ) where
import Iolaus.Patch.Core ( Named, infopatch,
                         patch2patchinfo, patchcontents )
import Iolaus.Patch.Patchy ( Patchy, Apply, showContextPatch,
                             Invert(invert, identity),
                             thing, things,
                             Commute(merge, commute, list_touched_files),
                             commuteFL, commuteRL, apply )
import Iolaus.Patch.Permutations ( commuteWhatWeCanRL, commuteWhatWeCanFL,
                                   commuteWhatWeCanToRightRLFL,
                                   removeFL )
import Iolaus.Patch.Viewing ( summarize )
import Iolaus.Patch.Apply ( apply_to_slurpy, chunkify )
import Iolaus.Patch.Prim ( Effect(effect), Prim, canonize,
                           rmdir, rmfile, adddir, addfile, chmod,
                           binary, chunk, move, is_adddir, is_addfile )
import Iolaus.Patch.Merge ( mergeNamed )
\end{code}

\input{Iolaus/Patch/Apply.lhs}
\input{Iolaus/Patch/Core.lhs}
\input{Iolaus/Patch/Prim.lhs}
\input{Iolaus/Patch/Commute.lhs}

