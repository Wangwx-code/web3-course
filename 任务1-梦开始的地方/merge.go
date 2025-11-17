package main

import (
	"fmt"
)

func main() {
	fmt.Println(merge([][]int{{2, 3}, {4, 5}, {6, 7}, {8, 9}, {1, 10}}))
}
func merge(intervals [][]int) [][]int {
	result := make([][]int, 0)
	noMore := true
	for i := 0; i < len(intervals); i++ {
		s, e := intervals[i][0], intervals[i][1]
		flag := false
		for j := 0; j < len(result); j++ {
			start, end := result[j][0], result[j][1]
			if e < start || s > end {
				continue
			}
			result[j][0] = min(start, s)
			result[j][1] = max(end, e)
			flag = true
			noMore = false
		}
		if !flag {
			result = append(result, []int{s, e})
		}
	}
	if !noMore {
		result = merge(result)
	}
	return result
}
