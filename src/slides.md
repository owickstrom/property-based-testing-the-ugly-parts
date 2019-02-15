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

## How do I test X?

* ...

## References

https://fsharpforfunandprofit.com/posts/property-based-testing-2/
  
## Questions?









## Thank You!

- Komposition: [owickstrom.github.io/komposition/](https://owickstrom.github.io/komposition/)
- Slides: [owickstrom.github.io/property-based-testing-the-ugly-parts/](https://owickstrom.github.io/property-based-testing-the-ugly-parts/)
- Image credits:
  - ...
- Thanks to [\@sassela](https://twitter.com/sassela) for great feedback!
