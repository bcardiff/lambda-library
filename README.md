# Lambda Library

This is a sample project to compare how side-effects can be managed and tested in Haskell using different techniques.

Each alternative has it's own `app<N>` and `test<N>` project, and they all share common library code from `src`.

There are some docs describing each alternative

* [Part 1, Introduction](./docs/01-Intro.md)
* [Part 2, Console Handler](./docs/02-Console-Handler.md)
* [Part 3, Task](./docs/03-Task.md)
* [Part 4, Type Classes](./docs/04-Type-Classes.md)
* [Part 5, ReaderT design pattern](./docs/05-ReaderT.md)

## Alternatives

- **app1** uses `IO` functions direcly. The tests replace & capture the STDIN/STDOUT.
- **app2** uses the handler pattern to be able to replace the functions to interact with the console in tests.
- **app3** similar to `app2` but restricts which other side-effects can happen by introducing a `Task` to replace `IO`.
- **app4** uses custom type classes to restrict other side-effects from happening.
- **app5** similar to `app4` but using `ReaderT` to keep the application state

### Additional alternatives based on packages

- **app-bluefin** similar to `app2` and `app3` but uses [`bluefin`](https://hackage.haskell.org/package/bluefin) package as a type level alternative of the handler pattern.
- 🚧 **app-effectful** uses [`effectful`](https://hackage.haskell.org/package/effectful)
  - TBD tests
- **app-heftia** uses [`heftia`](https://hackage.haskell.org/package/heftia-effects)
- 🚧 **app-polysemy**
- ❌ ~~**app-capabilities** similar to `app5` but uses `Capabilities` package~~.
  - ❌ [`Capabilities`](https://hackage.haskell.org/package/Capabilities) packages only works for `base >= 4.5 && 4.6`. We are using 4.17. I wanted to try it out based on [its blog post](https://www.tweag.io/blog/2018-10-04-capability/)

## Running the code

The code was developed with ghc 9.4.8 and cabal 3.10.3.0 as they were the recommended version at time.

```
% ghcup run --ghc 9.4.8 --cabal 3.10.3.0 -- zsh
# or % ghcup run --ghc recommended --cabal recommended -- zsh

% ghc --version
The Glorious Glasgow Haskell Compilation System, version 9.4.8

% cabal --version
cabal-install version 3.10.3.0
compiled using version 3.10.3.0 of the Cabal library
```

Each app and test can be run with `cabal` directly.

```
% cabal run app1
% cabal test app1-test
```
