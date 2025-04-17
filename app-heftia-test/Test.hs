{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeFamilies #-}

module Test (main) where

import Books qualified as B
import Control.Monad
import Control.Monad.Hefty
import Control.Monad.Hefty.Input
import Control.Monad.Hefty.Output
import Data.List
import Data.Maybe
import Main (Console (GetStringInput, PrintLine), main', runReadOnlyBookDB)
import Test.Hspec

runConsolePure :: (FOEs es) => [String] -> Eff (Console ': es) a -> Eff es ([String], a)
runConsolePure inputLines action =
  action
    & reinterpret \case
      GetStringInput prompt -> do
        output prompt
        fromMaybe "" <$> input
      PrintLine line -> output line
    & runInputList inputLines
    & runOutputMonoid singleton

main :: IO ()
main = hspec $ do
  around (B.withDB ":memory:") $ do
    it "Showing a message when no books are found" $ \db -> do
      (outputLines, _) <-
        runEff
          . runReadOnlyBookDB db
          . runConsolePure ["Pri", ""]
          $ main'

      outputLines
        `shouldBe` [ "Welcome to the Library"
                   , "Search: "
                   , "No books found for: Pri"
                   , "Search: "
                   , "Bye!"
                   ]

    it "User can perform searches and exit" $ \db -> do
      let books =
            [ B.Book{B.title = "Pride and Prejudice", B.author = "Jane Austen"}
            , B.Book{B.title = "1984", B.author = "George Orwell"}
            , B.Book{B.title = "Frankenstein", B.author = "Mary Shelley"}
            ]
      forM_ books $ B.addBook db

      (outputLines, _) <-
        runEff
          . runReadOnlyBookDB db
          . runConsolePure ["en", "or", ""]
          $ main'

      outputLines
        `shouldBe` [ "Welcome to the Library"
                   , "Search: "
                   , " * Pride and Prejudice, Jane Austen"
                   , " * Frankenstein, Mary Shelley"
                   , "Search: "
                   , " * 1984, George Orwell"
                   , "Search: "
                   , "Bye!"
                   ]
