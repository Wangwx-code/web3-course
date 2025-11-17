package main

import "fmt"

type Person struct {
	name string
	age  int
}

type Employee struct {
	Person
	id int
}

func (e Employee) printEmp() {
	e.id = e.id + 1
	fmt.Printf("id: %d, name: %s, age: %d\n", e.id, e.name, e.age)
}

func main() {
	emp := Employee{Person{name: "Bob", age: 12}, 0}
	emp.printEmp()
}
