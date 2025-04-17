module Test (main) where

import Books qualified as B
import Control.Monad
import Control.Monad.IO.Class
import Data.IORef
import Eff
import Main (Console (..), dbBooksRepository, main')
import Test.Hspec

writerConsole :: [String] -> Eff (Console ::: es) a -> Eff es (a, [String])
writerConsole inputs inner = do
  inputsRef <- liftIO $ newIORef inputs
  outputsRef <- liftIO $ newIORef []
  let console =
        Console
          { _askString = \prompt -> liftIO $ do
              modifyIORef' outputsRef (prompt :)
              (i : is) <- readIORef inputsRef
              modifyIORef' inputsRef (const is)
              return i
          , _writeString = \s -> liftIO $ do
              modifyIORef' outputsRef (s :)
          }
  a <- using console $ do inner
  outputs <- liftIO $ reverse <$> readIORef outputsRef
  return (a, outputs)

main :: IO ()
main = hspec $ do
  around (B.withDB ":memory:") $ do
    it "Showing a message when no books are found" $ \db -> do
      (_, output) <-
        runEff
          . using (dbBooksRepository db)
          . use (writerConsole ["Pri", ""])
          $ main'

      output
        `shouldBe` [ "Welcome to the Library"
                   , "Search: "
                   , "No books found for: Pri"
                   , "Search: "
                   , "Bye!"
                   ]

    it "User can perform searches and exit" $ \db -> do
      let books =
            [ B.Book {B.title = "Pride and Prejudice", B.author = "Jane Austen"}
            , B.Book {B.title = "1984", B.author = "George Orwell"}
            , B.Book {B.title = "Frankenstein", B.author = "Mary Shelley"}
            ]
      forM_ books $ B.addBook db

      (_, output) <-
        runEff
          . using (dbBooksRepository db)
          . use (writerConsole ["en", "or", ""])
          $ main'

      output
        `shouldBe` [ "Welcome to the Library"
                   , "Search: "
                   , " * Pride and Prejudice, Jane Austen"
                   , " * Frankenstein, Mary Shelley"
                   , "Search: "
                   , " * 1984, George Orwell"
                   , "Search: "
                   , "Bye!"
                   ]
