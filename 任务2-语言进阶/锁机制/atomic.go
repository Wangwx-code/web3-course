package main

import (
	"fmt"
	"sync/atomic"
	"time"
)

type counterAtomic struct {
	int32
}

func (c *counterAtomic) incr() {
	atomic.AddInt32(&c.int32, 1)
	fmt.Println("incr", c.int32)
}

func main() {
	var c counterAtomic
	for i := 0; i < 10; i++ {
		go func() {
			for j := 0; j < 1000; j++ {
				c.incr()
			}
		}()
	}
	time.Sleep(time.Second * 2)
	fmt.Println(c.int32)
}
