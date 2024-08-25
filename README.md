# Classifier

`lib/classifier.ex` implements a simple clustering algorithm for mobile apps based on provided file paths.

### How to run `Classifier`

Enter `iex` session:
```sh
$ iex -S mix
```

Invoke `run/3` function, which takes
- **input file path** - a string,
- **output file path** - a string,
- and **similarity threshold** - a float.

For example:
```ex
Classifier.run("data/input.json", "data/output.json", 0.7)
```

_Note: `data/input.json` is not included in the repo. To run the script provide `input.json` file OR use another **input file path**._

### Ignored paths

- algorithm only compares directory paths ignoring files
- localizations directories (`.lproj`) are ignored
- paths that include `xxx-xx-xxx-view-xxx-xx-xxx.nib` segments are also ignored (as likely generated)

### Similarity formula

Given two sets $A$ and $B$, the similarity $S(A, B)$ is calculated as:

```math
S(A, B) = \frac{| A \cap B |}{\min(|A|, |B|)}
```

where:

- $| A \cap B |$ is the cardinality (number of elements) of the intersection of sets $A$ and $B$.
- $|A|$ is the cardinality of set $A$.
- $|B|$ is the cardinality of set $B$.

##### Explanation

- The **intersection** $| A \cap B |$ represents the number of elements common to both sets $A$ and $B$.
- The **minimum cardinality** $\min(|A|, |B|)$ represents the size of the smaller set between $A$ and $B$.

##### Interpretation

- If the intersection $| A \cap B |$ is large relative to the size of the smaller set, the similarity score $S(A, B)$ will be close to 1, indicating high similarity.
- If there is no intersection (i.e., $|A \cap B|=0$), the similarity score will be 0, indicating no similarity.
- This formula ensures that the similarity score is normalised by the size of the smaller set, making it less sensitive to differences in set sizes.
