---
title: Property-Based Testing the Ugly Parts
author: Oskar Wickström
date: February 2019
theme: Boadilla
classoption: dvipsnames
---

## About Me

- Live in Malmö, Sweden
- Work for [Symbiont](https://symbiont.io/)
- Blog at [wickstrom.tech](https://wickstrom.tech)
- Maintain some open source projects
- [Haskell at Work](https://haskell-at-work.com) screencasts
- Spent the last year writing a screencast video editor

# Introduction

## Property-based testing

* Testing _properties_ of your system
* Large set of inputs
* Static and dynamic languages
	* QuickCheck
	* Hypothesis
	* test.check
	* Hedgehog

## Simple Examples

* List reverse

    ```haskell
    prop_reverse xs =
      reverse(reverse xs) == xs
    ```
* Natural number arithmetic

	```haskell
	prop_commutative x y =
	  x + y == y + x
	```
* Sorting algorithms

	```haskell
	prop_sort xs =
	  mySuperSort xs == industryStandardSort xs
	```

## Hedgehog

* Random generated inputs
* Integrated shrinking
* Great error reporting
* Concurrent test execution
* Not using type classes(!)

## List Reverse with Hedgehog

```{.haskell include=src/examples/Examples.hs snippet=reverse}
```

## List Sort with Hedgehog

```{.haskell include=src/examples/Examples.hs snippet=sort}
```

## Failures

![](images/diff.png)

## Rhetorical Question

How many of you write sort algorithms in your day job?

## How do I use this in my job?

* What if you're working with:
  * Backends with databases and integrations?
  * Frontends with GUIs and user input?
  * Data pipelines and analytics?
* Hard to write properties
* Fewer examples

# Property-Based Testing for the Busy Programmer{.dark background=images/dog.jpg}

## Testing the "Ugly" Parts

* Not everything will be small pure functions
* Complex interactions between larger modules
* Non-determinism
  - Statefulness
  - Side-effects

## Designing for Testability

* Regular "writing testable code" guidelines apply:
  - Single responsibility
  - Determinism (not necessarily pure!)
* Rich data types
* Low coupling between interface and implementation

## State-Machine Testing

...

# Case Studies from Komposition

## Komposition

...

## Case Studies

1. ...
2. ...
3. ...

# 1. Video Scene Classification


## References

https://fsharpforfunandprofit.com/posts/property-based-testing-2/
  
## Questions?









## Thank You!

- Komposition: [owickstrom.github.io/komposition/](https://owickstrom.github.io/komposition/)
- Slides: [owickstrom.github.io/property-based-testing-the-ugly-parts/](https://owickstrom.github.io/property-based-testing-the-ugly-parts/)
- Image credits:
  - ...
- Thanks to [\@sassela](https://twitter.com/sassela) for great feedback!
