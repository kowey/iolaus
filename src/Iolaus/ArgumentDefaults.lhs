%  Copyright (C) 2003 David Roundy
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
module Iolaus.ArgumentDefaults ( add_default_flags ) where

import Iolaus.Arguments ( Flag,
                          IolausOption( IolausArgOption, IolausNoArgOption,
                                        IolausAbsPathOption,
                                        IolausMultipleChoiceOption ),
                          arein, isin )
import Iolaus.RepoPath ( ioAbsolute )
import Git.Plumbing ( getConfig, ConfigOption(RepositoryOnly, System, Global) )

add_default_flags :: String -> [IolausOption] -> [Flag] -> IO [Flag]
add_default_flags _ [] already = return already
add_default_flags com (o:os) already =
    do x <- find_option [RepositoryOnly] com already o
       y <- find_option [Global] com (already++x) o
       z <- find_option [System] com (already++x++y) o
       xa <- find_option [RepositoryOnly] "all" already o
       ya <- find_option [Global] "all" (already++x) o
       za <- find_option [System] "all" (already++x++y) o
       add_default_flags com os (already++x++y++z++xa++ya++za)

find_option :: [ConfigOption] -> String -> [Flag] -> IolausOption -> IO [Flag]
find_option zz com already (IolausNoArgOption _ [n] o _)
    | o `elem` already = return []
    | otherwise = do x <- getConfig zz ("iolaus."++com++'.':n)
                     case x of
                       Just _ -> return [o]
                       Nothing -> return []
find_option zz com already (IolausArgOption _ [n] o _ _)
    | o `isin` already = return []
    | otherwise = do x <- getConfig zz ("iolaus."++com++'.':n)
                     case x of
                       Just s -> return [o s]
                       Nothing -> return []
find_option zz com already option@(IolausAbsPathOption _ [n] o _ _)
    | [option] `arein` already = return []
    | otherwise = do x <- getConfig zz ("iolaus."++com++'.':n)
                     case x of
                       Just s -> do p <- ioAbsolute s
                                    return [o p]
                       Nothing -> return []
find_option zz com already (IolausMultipleChoiceOption os)
    | os `arein` already = return []
    | otherwise = do x <- mapM (find_option zz com already) os
                     case dropWhile null x of xs:_ -> return xs
                                              [] -> return []
find_option _ com _ (IolausNoArgOption _ ns _ _) =
    fail ("I'm confused about "++com++" in find_option "++show ns)
find_option _ com _ (IolausArgOption _ ns _ _ _) =
    fail ("I'm confused about "++com++" in find_option foo "++show ns)
find_option _ _ _ _ = return []
\end{code}

