module Eff
  ( Eff
  , runEff
  , liftIO
  , unliftIO
  , request
  , locally
  , using
  , usingM
  , use
  , useM
  , (:::) (..)
  , (:>) (..)
  ) where

import Control.Monad.IO.Class

----------------------------------------
-- `Eff` monad, essentially `ReaderT env IO`

newtype Eff es a = MkEff (es -> IO a)

instance Functor (Eff es) where
  fmap f (MkEff ea) = MkEff $ \env -> do
    a <- ea env
    let b = f a
    return b

instance Applicative (Eff es) where
  pure x = MkEff $ \_ -> return x
  MkEff eab <*> MkEff ea = MkEff $ \env -> do
    ab <- eab env
    a <- ea env
    let b = ab a
    return b

instance Monad (Eff es) where
  return = pure
  MkEff ea >>= faeb = MkEff $ \env -> do
    a <- ea env
    let (MkEff eb) = faeb a
    eb env

instance MonadIO (Eff es) where
  liftIO io = MkEff $ const io

runEff :: Eff () a -> IO a
runEff (MkEff run) = run ()

unliftIO :: ((forall a. Eff es a -> IO a) -> IO b) -> Eff es b
unliftIO f = MkEff $ \env -> f (\(MkEff run) -> run env)

request :: (e :> es) => Eff es e
request = extract <$> MkEff return

locally :: (e :> es) => (e -> e) -> Eff es a -> Eff es a
locally f (MkEff run) = MkEff $ \env -> run (alter f env)

using :: e -> Eff (e ::: es) a -> Eff es a
using impl (MkEff run) = MkEff $ \env -> run (impl ::: env)

usingM :: Eff es e -> Eff (e ::: es) a -> Eff es a
usingM implM inner = implM >>= \impl -> using impl inner

use :: (e -> Eff es a) -> e -> Eff es a
use f = f

useM :: Eff es (e -> Eff es a) -> e -> Eff es a
useM fM inner = fM >>= \f -> f inner

----------------------------------------
-- Minimal `Has` class `(:>)` with a custom tuple as heterogeneous lists

data a ::: b = (:::) !a !b

infixr 1 :::

class a :> t where
  {-# MINIMAL extract, alter #-}
  extract :: t -> a
  alter :: (a -> a) -> t -> t

instance a :> a where
  extract a = a
  alter f = f

instance {-# OVERLAPPING #-} a :> (a ::: x) where
  extract (a ::: _) = a
  alter f (a ::: x) = f a ::: x

instance {-# OVERLAPPABLE #-} (a :> r) => a :> (l ::: r) where
  extract (_ ::: r) = extract r
  alter f (l ::: r) = l ::: alter f r
