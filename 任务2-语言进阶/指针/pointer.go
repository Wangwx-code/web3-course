package main

import "fmt"

func main() {
	x := 10
	plus10(&x)
	fmt.Println(x)

	slice := []int{1, 2, 3}
	multiply2(slice)
	fmt.Println(slice)
}

func plus10(x *int) {
	*x += 10
}

func multiply2(slice []int) {
	for i := range slice {
		slice[i] *= 2
	}
}
