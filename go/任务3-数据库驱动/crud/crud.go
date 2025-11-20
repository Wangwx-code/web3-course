package main

import (
	"context"
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type Student struct {
	gorm.Model
	Name  string
	Age   uint
	Grade string
}

func main() {
	dsn := "root:deepwise@tcp(127.0.0.1:3306)/metaNode?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("failed to connect database")
	}
	ctx := context.Background()
	err = db.AutoMigrate(&Student{})
	if err != nil {
		println(err)
	}

	err = gorm.G[Student](db).Create(ctx, &Student{Name: "张三", Age: 20, Grade: "三年级"})

	students, err := gorm.G[Student](db).Where("age > ?", 18).Find(ctx)
	fmt.Println(students)

	updates, err := gorm.G[Student](db).Where("id = ?", 1).Updates(ctx, Student{Grade: "四年级"})
	fmt.Println(updates)

	updates, err = gorm.G[Student](db).Where("id = ?", 2).Updates(ctx, Student{Age: 10})
	fmt.Println(updates)

	students, err = gorm.G[Student](db).Find(ctx)
	fmt.Println(students)

	affected, err := gorm.G[Student](db).Where("age < ?", 15).Delete(ctx)
	fmt.Println(affected)
}
