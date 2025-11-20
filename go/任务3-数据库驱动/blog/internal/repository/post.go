package repository

import (
	"blog/internal/config"
	"blog/internal/model"

	"gorm.io/gorm"
)

type PostRepository interface {
	Create(post *model.Post) error
	GetPostByUserId(userId uint) []model.Post
}

type postRepository struct {
	db *gorm.DB
}

func NewPostRepository() PostRepository {
	db := config.GetDB()
	err := db.AutoMigrate(&model.Post{})
	if err != nil {
		return nil
	}
	return postRepository{db}
}

func (r postRepository) Create(post *model.Post) error {
	return r.db.Create(&post).Error
}

func (r postRepository) GetPostByUserId(userId uint) []model.Post {
	var posts []model.Post
	r.db.Where("user_id = ?", userId).Find(&posts)
	return posts
}
