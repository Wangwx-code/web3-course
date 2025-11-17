package main

import (
	"fmt"
	"time"
)

func main() {
	ch := make(chan int, 100)
	go func() {
		for i := 0; i < 100; i++ {
			ch <- i
		}
		fmt.Println("发送完成")
	}()
	time.Sleep(time.Second * 2)

	go func() {
		for i := 0; i < 100; i++ {
			fmt.Println(<-ch)
		}
		fmt.Println("接收完成")
	}()

	time.Sleep(time.Second * 2)
}
