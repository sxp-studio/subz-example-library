# SubZ Example Library

A small, real node library for [SubjectiveZero](https://github.com/sxp-studio/subjective-zero) —
here so you can read one before writing your own, and fork it as a starting point.

It is also the library SubjectiveZero's own tests add and update, which is the useful part: it stays
correct because it is exercised, not because someone remembered to check it.

## Add it

**Settings ▸ Library ▸ Add Library**, then paste:

```
https://github.com/sxp-studio/subz-example-library
```

The app downloads the current copy and unpacks it read-only. Its three nodes then sit in the Library
panel beside the built-in ones, and placing one copies its source into your project like any other.

## What a library is

**A folder with node folders in it.** That is the whole format:

```
subz-example-library/
  library.json          the manifest: name, version, author, license
  index.json            one curation entry per node, for search and for agents
  vignette/             one node folder
    node-contract.json    its typed inputs and outputs, and its title
    Node.swift            the implementation, for a Mac project
    Node.js               optional, the same node for a browser project
    CARD.md               optional, prose for an agent deciding whether to reuse it
  chromatic-aberration/
  grainy-gradient/
```

Nothing else is required. A folder with one valid `node-contract.json` in it is a library.

## Make your own

Fork this, replace the node folders, and rewrite `library.json`. Two fields matter most:

- **`license`** — a node gets copied into somebody's project, so a library without one says nothing
  about whether they may use it.
- **`version`** — `MAJOR.MINOR.PATCH`. This is what Check for Updates compares. Bump it when you
  publish, or nobody is offered your changes.

Then push it anywhere with a public https URL. GitHub, GitLab and Codeberg all work as-is; the app
downloads a tarball of the current copy and never runs any version control of its own.

The fastest way to start from inside the app is to ask: *"make me a library called Their Nodes, MIT,
by me"*, then *"save the blur into it"*. That writes the manifest, the node folder and the index
entry correctly the first time.

## About these three nodes

`grainy-gradient` was written for this library. It is a source, so placing it shows something
straight away with nothing wired, and it ships both `Node.swift` and `Node.js` so you can see how one
contract serves two platforms. Its `CARD.md` explains the one thing worth stealing from it: the grain
is what stops the gradient banding, and the obvious noise hash is the wrong one.

`vignette` and `chromatic-aberration` are lifted from SubjectiveZero's built-in library and kept
simple on purpose. Between the three you get both shapes (a source and two effects) and the port
types you are most likely to declare: floats with a slider range, colours, and an XY point.

## The full format

`docs/NODE_LIBRARY.md` in
[sxp-studio/subjective-zero](https://github.com/sxp-studio/subjective-zero/blob/main/docs/NODE_LIBRARY.md)
documents every field, what agents read, and how a node declares a platform it can never run on.

## License

MIT. See `LICENSE`. Copy anything here into anything.
