package main

import "fmt"

func main() {
	fmt.Println(longestCommonPrefix([]string{"flower", "flower", "flower", "flower"}))
}

func longestCommonPrefix(strs []string) string {
	if len(strs) == 0 {
		return ""
	}
	if len(strs) == 1 {
		return strs[0]
	}
	var str0 = strs[0]
	if len(str0) == 0 {
		return ""
	}
	var index = len(str0)
	for i := 1; i < len(strs); i++ {
		var str = strs[i]
		if len(str) < index {
			index = len(str)
		}
		for j := 0; j < index; j++ {
			if str[j] != str0[j] {
				index = j
				break
			}
		}
	}
	return str0[:index]
}
