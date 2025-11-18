package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Name string
}

type Post struct {
	gorm.Model
	UserId uint
	Text   string
}

type Comment struct {
	gorm.Model
	PostId uint
	Text   string
}
