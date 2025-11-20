package main

import (
	"fmt"
	"sort"
)

func main() {
	fmt.Println(twoSum([]int{2, 7, 11, 15}, 9))
}

type Node struct {
	num   int
	index int
}

func twoSum(nums []int, target int) []int {
	nodeList := make([]Node, len(nums))
	for i := 0; i < len(nums); i++ {
		nodeList[i] = Node{num: nums[i], index: i}
	}
	sort.Slice(nodeList, func(i, j int) bool {
		return nodeList[i].num < nodeList[j].num
	})
	i, j := 0, len(nums)-1
	for i < j {
		sum := nodeList[i].num + nodeList[j].num
		if sum == target {
			return []int{nodeList[i].index, nodeList[j].index}
		} else if sum > target {
			j--
		} else {
			i++
		}
	}
	return []int{}
}
