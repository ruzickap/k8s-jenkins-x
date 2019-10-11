#!/bin/bash -eu

sed -n '/^```bash.*/,/^```$/p' docs/part-04/README.md | sed '/^```*/d' | sh -x
