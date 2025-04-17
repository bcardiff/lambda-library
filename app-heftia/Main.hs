{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module Main where

import Books hiding (findBook)
import Books qualified as Book
import Control.Monad
import Control.Monad.Hefty
import System.IO

data Console :: Effect where
  GetStringInput :: String -> Console f String
  PrintLine :: String -> Console f ()
makeEffectF ''Console

runConsoleIO :: (Emb IO :> es) => Eff (Console ': es) a -> Eff es a
runConsoleIO = interpret $ \case
  GetStringInput prompt -> liftIO $ do
    putStr prompt
    hFlush stdout
    getLine
  PrintLine line -> liftIO $ putStrLn line

data ReadOnlyBookDB :: Effect where
  FindBook :: String -> ReadOnlyBookDB f [Book]
makeEffectF ''ReadOnlyBookDB

runReadOnlyBookDB :: (Emb IO :> es) => BookDB -> Eff (ReadOnlyBookDB : es) a -> Eff es a
runReadOnlyBookDB db = interpret $ \case
  FindBook q -> liftIO $ Book.findBook db q

main :: IO ()
main = do
  withDB
    "./books.db"
    ( \db -> do
        runEff
          . runConsoleIO
          . runReadOnlyBookDB db
          $ main'
    )

main' :: (Console :> es, ReadOnlyBookDB :> es) => Eff es ()
main' = do
  printLine "Welcome to the Library"
  loop

loop :: (Console :> es, ReadOnlyBookDB :> es) => Eff es ()
loop = do
  query <- getStringInput "Search: "
  case query of
    "" ->
      printLine "Bye!"
    _ -> do
      books <- findBook query
      if null books
        then
          printLine $ "No books found for: " <> query
        else
          printBookList books
      loop

printBookList :: (Console :> es) => [Book] -> Eff es ()
printBookList books =
  forM_ books (\book -> printLine $ " * " <> book.title <> ", " <> book.author)
