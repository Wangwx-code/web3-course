package main

import (
	"fmt"
)

func main() {
	fmt.Println(singleNumber([]int{2, 2, 4, 4, 5}))
}

func singleNumber(nums []int) int {
	var result = 0
	num := 0
	for _, num = range nums {
		result = result ^ num
	}
	return result
}
