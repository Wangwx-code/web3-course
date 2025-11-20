package main

import "fmt"

func main() {
	fmt.Println(removeDuplicates([]int{0, 0, 1, 1, 1, 2, 2, 3, 3, 4}))
}

func removeDuplicates(nums []int) int {
	var m [300]int
	var index = 0
	for i := 0; i < len(nums); i++ {
		var v = nums[i] + 110
		if m[v] == 0 {
			m[v] = 1
			nums[index] = nums[i]
			index++
		}
	}
	return index
}
