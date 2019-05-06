---
title: Property-Based Testing the Ugly Parts
author: Oskar Wickström
date: May 2019
theme: Boadilla
classoption: dvipsnames
---

## About Me

- Live in Malmö, Sweden
- Work for [Symbiont](https://symbiont.io/)
- Blog at [wickstrom.tech](https://wickstrom.tech)
- Maintain some open source projects
- [Haskell at Work](https://haskell-at-work.com) screencasts
- Spent the last year writing a screencast video editor called _Komposition_

## Agenda

* Introduction to Hedgehog
* Property-Based Testing for the Industry Programmer
* Case Studies from Komposition

# Introduction to Hedgehog

## Hedgehog

* Random generated inputs
* Integrated shrinking
* Great error reporting
* Concurrent test execution
* Generators as values
    - Unlike `Arbitrary` in QuickCheck

## List Reverse with Hedgehog

```{.haskell include=src/examples/Examples.hs snippet=reverse}
```

## List Sort with Hedgehog

```{.haskell include=src/examples/Examples.hs snippet=sort}
```

## Failures

![](images/diff.png)

## Poll

How many of you write sort algorithms in your day job?

## How do I use this in my job?

* What if you're working with:
  * Backends with databases and integrations?
  * Frontends with GUIs and user input?
  * Data pipelines and analytics?
* Hard to write properties
* Fewer examples

# Property-Based Testing for the Industry Programmer{.dark background=images/dog.jpg}

## Testing the "Ugly" Parts

* Not everything will be small pure functions
* Complex interactions between larger modules
* Stateful
* Side-effects

## Designing for Testability

* Regular "writing testable code" guidelines apply:
  - Single responsibility
  - Determinism
  - No global side-effects
  - Low coupling between interface and implementation

## Patterns for Properties

- ["Choosing properties for property-based testing"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/) by Scott Wlaschin
  - "Different paths, same destination"
  - "There and back again"
  - "Some things never change"
  - "The more things change, the more they stay the same"
  - "Solve a smaller problem first"
  - "Hard to prove, easy to verify"
  - "The test oracle"
- Study others' property tests
- Practice!

## Other Interesting Techniques

* State-machine testing
* "Database of inputs"
  - [Testing Our Ruby and Haskell Implementations Side-By-Side](https://blog.mpowered.team/posts/2018-testing-ruby-haskell-implementations.html)

# Case Studies from Komposition{.dark background=images/komposition-bg.png}

## Komposition

<table>
  <tr>
    <td>
- Desktop GUI application
- Modal
- Hierarchical timeline
    - Sequences
    - Parallels
    - Tracks
    - Clips and gaps
- Automatic scene classification
- Automatic sentence classification
    </td>
    <td width="50%">
![Komposition](images/komposition-light.png)
    </td>
  </tr>
</table>

## Complex Features

* Most complex features in Komposition
  - Focus and timeline transformations
  - Video classification
  - Rendering
  - Application logic
* Spend effort on testing those

## Case Studies

1. Timeline Flattening
2. Video Scene Classification
3. Undo/Redo Symmetry

# Hierarchical Timeline{background=#dddddd}

## Clips

![Clips](images/timeline1.png){width=700}

<aside class="notes">
- Clips are put in video and audio tracks within parallels
- Tracks are played in parallel, hence the name
</aside>

## Video Still Frames

![Video Still Frames](images/timeline2.png){width=700}

<aside class="notes">
If the video track is shorter, it will be padded with still frames
</aside>

## Adding Gaps

![Adding Gaps](images/timeline3.png){width=700}

<aside class="notes">
- You can add explicit gaps in video and audio tracks
- These are also filled with still frames for video
</aside>

## Sequences

![Sequences](images/timeline4.png){width=1200}

<aside class="notes">
- Parallels are put in sequences
- Each parallel is played until its end, then the next, and so on
- Multiple parallels can be used to synchronize clips
</aside>

## Timeline

![Timeline](images/timeline5.png){width=1500}

<aside class="notes">
- The top level is the timeline
- The timeline contain sequences
- It's useful for organizing the parts of your screencast
</aside>

# <strong>Case Study 1:</strong> Timeline Flattening

## Timeline Flattening

* Timeline is hierarchical
  - Sequences
  - Parallels
  - Tracks
  - Clips and gaps
* FFmpeg render knows only about two flat tracks
  - Video track
  - Audio track

## Timeline Flattening (Graphical)

![Timeline flattening](images/komposition-flattening.png){width=100%}

## Testing Duration

```{.haskell emphasize=5:5-5:99}
hprop_flat_timeline_has_same_duration_as_hierarchical =
  property $ do
    t <- forAll $ Gen.timeline (Range.exponential 0 20) Gen.parallelWithClips
    let Just flat = Render.flattenTimeline t
    durationOf AdjustedDuration t === durationOf AdjustedDuration flat
````

## Testing Clip Occurence

```{.haskell emphasize=5:5-5:99,6:5-6:99}
hprop_flat_timeline_has_same_clips_as_hierarchical =
  property $ do
    t <- forAll $ Gen.timeline (Range.exponential 0 20) Gen.parallelWithClips
    let Just flat = Render.flattenTimeline t
    timelineVideoClips t === flatVideoClips flat
    timelineAudioClips t === flatAudioClips flat
```

## More on Timeline Flattening

* Other properties
  - How video gaps are padded with still frames
  - Same flat result regardless of grouping (split/join sequences, then flatten)
* Padding with frames from other parallels
  - Frames are only picked from video clips within the parallel
  - Should pick from _any_ video clip within the timeline
  - Write properties to guide my work

# <strong>Case Study 2:</strong> Video Scene Classification

## Video Scene Classification

* Komposition can automatically classify "scenes"
  * **Moving segment:** consecutive non-equal frames
  * **Still segment:** at least _S_ seconds of consecutive near-equal
    frames
* _S_ is a preconfigured threshold for still segment duration
* Edge cases:
  - First segment is always a moving segment
  - Last segment may be shorter

## Visualizing with Color Tinting

![Video classification shown with color tinting](images/color-tinting.gif)

## Testing Video Classification

* Generate high-level representation of _expected output segments_:
    ![Expected output](images/expected-output.png)
* Convert output representation to actual pixel frames:
    ![Pixel frames](images/derived-frames.png)
* Run the classifier on the pixel frames
* Test properties based on:
  - the expected output representation
  - the actual classified output

## Two Properties of Video Classification

1. Classified still segments must be at least _S_ seconds long
   - Ignoring the last segment (which may be a shorter still segment)
2. Classified moving segments must have correct timespans
   - Comparing the generated _expected_ output to the classified
     timespans

## Testing Still Segment Lengths

```{.haskell}
hprop_classifies_still_segments_of_min_length = property $ do

  -- 1. Generate a minimum still segment length/duration
  minStillSegmentFrames <- forAll $ Gen.int (Range.linear 2 (2 * frameRate))
  let minStillSegmentTime = frameCountDuration minStillSegmentFrames

  -- 2. Generate output segments
  segments <- forAll $
    genSegments (Range.linear 1 10)
                (Range.linear 1
                              (minStillSegmentFrames * 2))
                (Range.linear minStillSegmentFrames
                              (minStillSegmentFrames * 2))
                resolution
```

## Testing Still Segment Lengths (cont.)
                
```{.haskell}
  ...

  -- 3. Convert test segments to actual pixel frames
  let pixelFrames = testSegmentsToPixelFrames segments

  -- 4. Run the classifier on the pixel frames
  let counted = classifyMovement minStillSegmentTime (Pipes.each pixelFrames)
                & Pipes.toList
                & countSegments
  ...
```

## Testing Still Segment Lengths (cont.)

```{.haskell}
  ...

  -- 5. Sanity check
  countTestSegmentFrames segments === totalClassifiedFrames counted

  -- 6. Ignore last segment and verify all other segments
  case initMay counted of
    Just rest ->
      traverse_ (assertStillLengthAtLeast minStillSegmentTime) rest
    Nothing -> success
  where
    resolution = 10 :. 10
```

## Success!

```{.text}
> :{
| hprop_classifies_still_segments_of_min_length
|   & Hedgehog.withTests 10000
|   & Hedgehog.check
| :}
  ✓ <interactive> passed 10000 tests.
```

## Testing Moving Segment Timespans

```{.haskell}
hprop_classifies_same_scenes_as_input = property $ do

  -- 1. Generate a minimum still still segment duration
  minStillSegmentFrames <- forAll $ Gen.int (Range.linear 2 (2 * frameRate))
  let minStillSegmentTime = frameCountDuration minStillSegmentFrames

  -- 2. Generate test segments
  segments <- forAll $
    genSegments (Range.linear 1 10)
                (Range.linear 1
                              (minStillSegmentFrames * 2))
                (Range.linear minStillSegmentFrames
                              (minStillSegmentFrames * 2))
                resolution

  ...
```

## Testing Moving Segment Timespans (cont.)

```{.haskell}
  ...

  -- 3. Convert test segments to actual pixel frames
  let pixelFrames = testSegmentsToPixelFrames segments

  -- 4. Convert expected output segments to a list of expected time spans
  --    and the full duration
  let durations = map segmentWithDuration segments
      expectedSegments = movingSceneTimeSpans durations
      fullDuration = foldMap unwrapSegment durations
  
  ...
```

## Testing Moving Segment Timespans (cont.)

```{.haskell}
  ...

  -- 5. Classify movement of frames
  let classifiedFrames =
        Pipes.each pixelFrames
        & classifyMovement minStillSegmentTime
        & Pipes.toList

  -- 6. Classify moving scene time spans
  let classified =
        (Pipes.each classifiedFrames
         & classifyMovingScenes fullDuration)
        >-> Pipes.drain
        & Pipes.runEffect
        & runIdentity
  
  ...
```

## Testing Moving Segment Timespans (cont.)

```{.haskell}
  ...

  -- 7. Check classified time span equivalence
  expectedSegments === classified

  where
    resolution = 10 :. 10
```

## Failure!

![](images/video-classification-failure.png){width=75%}

<aside class="notes">
* Where does 0s–0.6s come from?
  - There's a single moving scene of 10 frames
  - The classified time span should’ve been 0s–1s
* I couldn’t find anything incorrect in the generated data
* The end timestamp 0.6s was consistently showing up in failing examples
    - Found a curious hard-coded value 0.5
</aside>

## Classifier Bugs

```haskell
classifyMovement minStillSegmentTime =
  case ... of
    InStillState{..} ->
      if someDiff > minEqualTimeForStill
        then ...
        else ...
    InMovingState{..} ->
      if someOtherDiff >= minStillSegmentTime
        then ...
        else ...
  where
    minEqualTimeForStill = 0.5
```

<aside class="notes">
* Classifier is a _fold_ over a stream of frames
* This is a stripped down version of the code to highlight one bug:
    - The accumulator holds vectors of previously seen and not-yet-classified frames
    - In the `InStillState` branch it uses the value `minEqualTimeForStill`
    - It should always use `minStillSegmentTime` argument
* Also, it incorrectly classified frames based on that value
  - Frames that should've been classified as "moving" ended up "still"
  - That's why I didn't get 0s–1s in the output
* Why not 0.5s, given the hard-coded value 0.5?
  - There was also an off-by-one bug
  - One frame was classified incorrectly
* The `classifyMovement` function is 30 lines of Haskell code
  - I messed it up in three separate ways at the same time
  - With property tests I quickly found and fixed the bugs
</aside>

## Fixing Bugs

* There were multiple bugs:
  - The specificiation was wrong
  - The generators and tests had errors
  - The implementation had errors
* After fixing bugs, thousands of tests ran successfully
* Tried importing actual recorded video, had great results!

# <strong>Case Study 3:</strong> Integration Testing

## Undo/Redo Symmetry

* Undo/Redo was previously implemented as stacks of previous/future
  states
* Consumed gigabytes of disk space and RAM for projects with many
  edits
* Rewrote the implementation to only store "invertible actions"

## Testing Undo

* Generate an initial state
* Generate a sequence of undoable commands
* Run all commands
* Run undo command for each original command
* Assert that we end up at the initial state

## Actions are Undoable

```{.haskell}
hprop_undo_actions_are_undoable = property $ do

  -- Generate initial timeline and focus
  timelineAndFocus <- forAllWith showTimelineAndFocus $
    Gen.timelineWithFocus (Range.linear 0 10) Gen.parallel

  -- Generate initial application state
  initialState <- forAll (initializeState timelineAndFocus)

  -- Generate a sequence of undoable/redoable commands
  events <- forAll $
    Gen.list (Range.exponential 1 100) genUndoableTimelineEvent

  ...
```

## Actions are Undoable (cont.)

```{.haskell}
  ...

  -- We begin by running 'events' on the original state
  beforeUndos <- runTimelineStubbedWithExit events initialState

  -- Then we run as many undo commands as undoable commands
  afterUndos <- runTimelineStubbedWithExit (undoEvent <$ events) beforeUndos

  -- That should result in a timeline equal to the one we at the
  -- beginning
  timelineToTree (initialState ^. currentTimeline)
    === timelineToTree (afterUndos ^. currentTimeline)
```

## Testing Redo

* Generate an initial state
* Generate a sequence of undoable/redoable commands
* Run all commands
* Run undo _and redo_ commands for each original command
* Assert that we end up at the state before running undos

## Actions are Redoable

```{.haskell}
hprop_undo_actions_are_redoable = property $ do

  -- Generate the initial timeline and focus
  timelineAndFocus <- forAllWith showTimelineAndFocus $
    Gen.timelineWithFocus (Range.linear 0 10) Gen.parallel

  -- Generate the initial application state
  initialState <- forAll (initializeState timelineAndFocus)

  -- Generate a sequence of undoable/redoable commands
  events <- forAll $
    Gen.list (Range.exponential 1 100) genUndoableTimelineEvent
```

## Actions are Redoable (cont.)

```{.haskell}
  -- We begin by running 'events' on the original state
  beforeUndos <- runTimelineStubbedWithExit events initialState

  -- Then we undo and redo all of them
  afterRedos  <-
    runTimelineStubbedWithExit (undoEvent <$ events) beforeUndos
    >>= runTimelineStubbedWithExit (redoEvent <$ events)

  -- That should result in a timeline equal to the one we had before
  -- starting the undos
  timelineToTree (beforeUndos ^. currentTimeline)
    === timelineToTree (afterRedos ^. currentTimeline)
```


## Undo/Redo Test Summary

* These tests made the refactoring possible
* Founds _many_ interim bugs
  - Off-by-one index
  - Inconsistent focus
  - Non-invertible actions
* After the tests passed: ran the GUI, it worked

## Related Tests

* Focus and Timeline Consistency
    - The _focus_ is a data structure that "points" to a part of the
    timeline
    - The timeline and focus must at all points be consistent
    - Approach:
      - Generate a random initial state
      - Generate a random sequence of user commands
      - Check consistency after each command
      - Run all commands until termination

# Wrapping Up

## Summary

* Property-based testing is not only for pure functions!
  - Effectful actions
  - Integration tests
* Process (iterative)
    - Think about the specification first
    - Think about how generators and tests should work
    - Get minimal examples of failures, fix the implementation
* Using them in Komposition:
  - Made refactoring and evolving large parts of the system tractable
    and safer
  - Found existing errors in my thinking, my tests, my implementation
  - It's been a joy

## References

* [What is Property Based Testing?](https://hypothesis.works/articles/what-is-property-based-testing/) by David R. MacIver
* [Experiences with QuickCheck: Testing the Hard Stuff and Staying Sane](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quviq-testing.pdf) by John Hughes
* ["Choosing properties for property-based testing"](https://fsharpforfunandprofit.com/posts/property-based-testing-2/) by Scott Wlaschin

## Thank You!

- "Property-Based Testing in a Screencast Editor" series:
  - [Introduction](https://wickstrom.tech/programming/2019/03/02/property-based-testing-in-a-screencast-editor-introduction.html)
  - [Timeline Flattening](https://wickstrom.tech/programming/2019/03/24/property-based-testing-in-a-screencast-editor-case-study-1.html)
  - [Video Scene Classification](https://wickstrom.tech/programming/2019/04/17/property-based-testing-in-a-screencast-editor-case-study-2.html)
- Komposition: [owickstrom.github.io/komposition/](https://owickstrom.github.io/komposition/)
- Slides: [owickstrom.github.io/property-based-testing-the-ugly-parts/](https://owickstrom.github.io/property-based-testing-the-ugly-parts/)
- Thanks to [John Hughes](https://twitter.com/rjmh) for feedback
- Image credits:
  - [I Have No Idea What I'm Doing](https://knowyourmeme.com/photos/234765-i-have-no-idea-what-im-doing)
