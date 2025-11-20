package main

import (
	"fmt"
	"math"
)

type shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	width, height float64
}

func (r Rectangle) Area() float64 {
	return r.width * r.height
}

func (r Rectangle) Perimeter() float64 {
	return 2 * (r.width + r.height)
}

type Circle struct {
	radius float64
}

func (c Circle) Area() float64 {
	return math.Pi * c.radius * c.radius
}

func (c Circle) Perimeter() float64 {
	return 2 * math.Pi * c.radius
}

func calArea(s shape) float64 {
	return s.Area()
}

func calPerimeter(s shape) float64 {
	return s.Perimeter()
}

func main() {
	rect := Rectangle{width: 10, height: 5}
	circle := Circle{radius: 5}
	fmt.Println(calArea(rect))
	fmt.Println(calPerimeter(rect))
	fmt.Println(calArea(circle))
	fmt.Println(calPerimeter(circle))
}
