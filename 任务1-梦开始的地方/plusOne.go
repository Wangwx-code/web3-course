package main

import "fmt"

func main() {
	fmt.Println(plusOne([]int{1, 2, 3}))
}

func plusOne(digits []int) []int {
	var slice []int
	slice = append(slice, 0)
	slice = append(slice, digits...)
	slice[len(slice)-1]++
	for i := len(slice) - 2; i >= 0; i-- {
		if slice[i+1] < 10 {
			break
		}
		slice[i] += 1
		slice[i+1] -= 10
	}
	if slice[0] == 0 {
		return slice[1:]
	}
	return slice
}
