## Good Make file for go projects

Reference: https://www.mohitkhare.com/blog/go-makefile

This document will keep changing based on experience

1. ```go mod init github.com/kurian-thomas/good-go-make``` : init go project with repository path
2. ```make help``` : help section of make

## Dependcies
1. Adding or upgrading a package, upgrade only works for minor patches

```
Syntax: go get <package_path>@<version>
go get github.com/gin-gonic/gin@v1.9.1
```
updates go.mod to have the package name 
and go.sum to have the respective checksums

To latest: go get github.com/gin-gonic/gin@latest (Not Recomended)

2. for major ver changes of vX, where X >= 2

```
go get <package_path>/vX@<version>

change import paths in the go files

make tidy
```

### Testing
1. Unit tests live side-by-side with the code they test in the same directory.
foo_test.go next to foo.go

package pkg (white-box, full access, private methos valiadtion)
package pkg_test (black-box, cannt access private members)

make unit-test

2. Integration & e2e tests - /test folder in the root, serate running using tags

```
/test/integrations
package integration

/test/e2e
package e2e
```
add tag to files //go:build integration

Run only integration tests
```go test --tags=integration ./test/integration/...```

compiler ignores all *_test.go files
