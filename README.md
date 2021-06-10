# Peass Demo Compile Error
Purpose of this project is to test the behavior of [Peass](https://github.com/DaGeRe/peass) while measuring performance over commits containing compilation errors.

## Overview
As demo-project for the measurements by `Peass`, [demo-project-compile-error](https://github.com/mai13drd/demo-project-compile-error) is used. It contains three versions, where `ExampleTest` eventually calls `Callee.innerMethod`:

* 9968fee ("Removed compileerror, changed Thread.sleep from 1 to 20 ms in Callee.innerMethod")

* 577bb7f ("Added compileerror")

* 6961317 ("Initial commit")

In the 2nd version 577bb7f, `Callee.innerMethod` contains an error which prevents compilation of the `Callee`-class. `Peass` should ignore such commits, looking for the next compilable one. In the case of `demo-project-compile-error`, measurements should take place between the initial commit 6961317 and the last one 9968fee, ignoring 577bb7f.

## General Approach
The script `executeAll.sh` clones the `demo-project-compile-error` and `Peass`. Subsequent `demo-project-compile-error` is reset to commit 577bb7f, containing the compilation error. The steps for measuring performance between commits 577bb7f and 6961317 are executed. Since there are no two error-free commits to measure between, this fails like expected.

After that, `demo-project-compile-error` is reset to the last commit 9968fee. `Peass` should now measure between the two (error-free) commits 6961317 and 9968fee, ignoring the one commit between them.

## Execution
To observe the described behavior, just run `executeAll.sh`. At the end you should see two messages, confirming that Peass worked correctly:

* Slowdown is detected for Callee#innerMethod.

* SOURCE_METHOD_LINE is correct.
