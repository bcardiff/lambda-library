{-# LANGUAGE RecordWildCards #-}

module Main where

import Books (Book, BookDB)
import Books qualified
import Control.Monad (forM_)
import Control.Monad.Fix (fix)
import Eff
import System.IO

data Console = Console
  { _askString :: forall es. String -> Eff es String
  , _writeString :: forall es. String -> Eff es ()
  }

askString :: (Console :> es) => String -> Eff es String
askString s = request >>= \Console {..} -> _askString s

writeString :: (Console :> es) => String -> Eff es ()
writeString s = request >>= \Console {..} -> _writeString s

stdConsole :: Console
stdConsole =
  Console
    { _askString = \prompt -> liftIO $ do
        putStr prompt
        hFlush stdout
        getLine
    , _writeString = liftIO . putStrLn
    }

data BooksRepository = BooksRepository
  { _findBook :: forall es. String -> Eff es [Book]
  , _addBook :: forall es. Book -> Eff es ()
  }

findBook :: (BooksRepository :> es) => String -> Eff es [Book]
findBook query = request >>= \BooksRepository {..} -> _findBook query

addBook :: (BooksRepository :> es) => Book -> Eff es ()
addBook book = request >>= \BooksRepository {..} -> _addBook book

dbBooksRepository :: BookDB -> BooksRepository
dbBooksRepository db =
  BooksRepository
    { _findBook = liftIO . db.findBook
    , _addBook = liftIO . db.addBook
    }

main :: IO ()
main = do
  Books.withDB "./books.db" $ \db -> do
    runEff $ using (dbBooksRepository db) $ using stdConsole $ do
      main'

main' :: (Console :> es, BooksRepository :> es) => Eff es ()
main' = do
  writeString "Welcome to the Library"
  fix $ \loop -> do
    query <- askString "Search: "
    case query of
      "" ->
        writeString "Bye!"
      _ -> do
        books <- findBook query
        if null books
          then writeString $ "No books found for: " <> query
          else forM_ books prettyPrintBook
        loop
  where
    prettyPrintBook book = writeString $ " * " <> book.title <> ", " <> book.author
