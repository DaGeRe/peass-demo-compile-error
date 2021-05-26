# Peass Demo Compile Error
Purpose of this project is to test the behavior of [Peass](https://github.com/DaGeRe/peass) while measuring performance over commits containing compilation errors.

## Overview
As demo-project for the measurements by `Peass`, [demo-project-compile-error](https://github.com/mai13drd/demo-project-compile-error) is used. It contains three versions, where `CalleeTest` calls `Callee`:

* 5bd15fd ("Longer sleep in innerMethod - should be detected")
* ec6b3b4 ("Added compile error")
* d564363 ("Initial commit")

In the 2nd version ec6b3b4, `Callee#innerMethod` contains an error which prevents compilation of the `Callee`-class. `Peass` should ignore such commits, looking for the next compilable one. In the case of `demo-project-compile-error`, measurements should take place between the initial commit d564363 and the last one 5bd15fd, ignoring ec6b3b4.

## General Approach
The script `executeAll.sh` clones the `demo-project-compile-error` and `Peass`. Subsequent `demo-project-compile-error` is reset to commit ec6b3b4, containing the compilation error. The steps for measuring performance between commits ec6b3b4 and d564363 are executed. Since there are no two error-free commits to measure between, this fails like expected.

After that, `demo-project-compile-error` is reset to the last commit 5bd15fd. `Peass` should now measure between the two (error-free) commits d564363 and 5bd15fd, ignoring the one commit between them. Unfortunately this fails at the moment.

## Execution
To observe the described behavior, just run `executeAll.sh`.
