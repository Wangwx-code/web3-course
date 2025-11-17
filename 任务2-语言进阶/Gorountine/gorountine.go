package main

import (
	"fmt"
	"time"
)

func main() {

	go func() {
		for i := 1; i <= 10; i += 2 {
			fmt.Println(i)
		}
	}()

	go func() {
		for i := 2; i <= 10; i += 2 {
			fmt.Println(i)
		}
	}()

	time.Sleep(time.Second * 2)

	taskManager(
		[]func(){func() { time.Sleep(time.Second * 3) }})

	time.Sleep(time.Second * 5)
}

func taskManager(functionList []func()) {
	for i := range functionList {
		go singleTask(functionList[i])
	}
}

func singleTask(function func()) {
	start := time.Now()
	function()
	end := time.Now()
	fmt.Printf("cost: %d seconds\n", end.Sub(start)/time.Second)
}
