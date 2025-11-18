package repository

import (
	"blog/internal/config"
	"blog/internal/model"

	"gorm.io/gorm"
)

type CommentRepository interface {
	Create(comment *model.Comment) error
}

type commentRepository struct {
	db *gorm.DB
}

func (r commentRepository) Create(comment *model.Comment) error {
	return r.db.Create(&comment).Error
}

func NewCommentRepository() CommentRepository {
	db := config.GetDB()
	err := db.AutoMigrate(&model.Comment{})
	if err != nil {
		return nil
	}
	return commentRepository{db}
}
