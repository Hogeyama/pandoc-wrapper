#!/usr/bin/env stack
-- stack --resolver=lts-8.6 runghc --package=yaml --package=text --package=shelly --package=bytestring
-- vim:ft=haskell:
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import           Shelly                 (shelly, bash_)
import qualified Data.Text              as T
import qualified Data.Text.IO           as T
import qualified Data.Yaml              as Y
import           Data.Yaml              (FromJSON(..), (.:))
import           Data.ByteString        (ByteString)
import qualified Data.ByteString.Char8  as C
import           System.Environment     (getArgs)

main :: IO ()
main = getArgs >>= \case
  [] -> error "usage: FILE OPTIONS"
  src:opts -> pandoc src $ PandocOpts $ map T.pack opts

pandoc :: Prelude.FilePath -> PandocOpts -> IO ()
pandoc src cmdOpts = do
  parsedOpts <- parseOpts src
  runPandoc src $ mergeOpts parsedOpts cmdOpts

runPandoc :: Prelude.FilePath -> PandocOpts -> IO ()
runPandoc src (PandocOpts opts) = do
  let md = T.pack src
  --T.putStrLn $ T.unwords ("pandoc" : md :  opts)
  shelly $ bash_ "pandoc" (md : opts)

parseOpts :: Prelude.FilePath -> IO PandocOpts
parseOpts src = do
  contents <- C.readFile src
  case Y.decode (getYamlPart contents) of
    Nothing -> do
      putStrLn $ "Warning: field `pandoc_opts_` not found, use default options"
      return defaultOpts
    Just ok -> do
      return $ mergeOpts minimalOpts ok

getYamlPart :: ByteString -> ByteString
getYamlPart = C.unlines . takeWhile p2 . tail . dropWhile p1 . C.lines
  where p1 line = not $ "---" `C.isPrefixOf` line
        p2 line = not $ "---" `C.isPrefixOf` line || "..." `C.isPrefixOf` line

data PandocOpts = PandocOpts { getOpts :: [T.Text] }
  deriving (Show)

minimalOpts :: PandocOpts
minimalOpts = PandocOpts ["-s"]

defaultOpts :: PandocOpts
defaultOpts = PandocOpts [
    "-s"
  --, "--latex-engine=xelatex"
  , "-f markdown+lists_without_preceding_blankline+ignore_line_breaks"
  ]

mergeOpts :: PandocOpts -> PandocOpts -> PandocOpts
mergeOpts (PandocOpts o1) (PandocOpts o2) = PandocOpts (o1++o2)

instance FromJSON PandocOpts where
  parseJSON (Y.Object v) = PandocOpts <$> v .: "pandoc_opts_"
  parseJSON _            = fail "field `pandoc_opts_` not found"

