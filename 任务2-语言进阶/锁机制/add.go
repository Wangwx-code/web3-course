package main

import (
	"fmt"
	"sync"
	"time"
)

type counter struct {
	int
	sync.Mutex
}

func (c *counter) incr() {
	c.Mutex.Lock()
	c.int++
	fmt.Println("incr", c.int)
	c.Mutex.Unlock()
}

func main() {
	var c counter
	for i := 0; i < 10; i++ {
		go func() {
			for j := 0; j < 1000; j++ {
				c.incr()
			}
		}()
	}
	time.Sleep(time.Second * 2)
	fmt.Println(c.int)
}
