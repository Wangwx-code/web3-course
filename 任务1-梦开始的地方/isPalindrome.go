package main

import (
	"fmt"
	"strconv"
)

func main() {
	fmt.Println(isPalindrome(1221))
}

func isPalindrome(x int) bool {
	var str = strconv.Itoa(x)
	for i, j := 0, len(str)-1; i <= j; i, j = i+1, j-1 {
		var left = str[i]
		var right = str[j]
		if left != right {
			return false
		}
	}
	return true
}
